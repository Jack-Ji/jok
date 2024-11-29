const std = @import("std");
const assert = std.debug.assert;
const jok = @import("../jok.zig");
const sdl = jok.sdl;
const log = std.log.scoped(.jok);

/// Generic timer for scheduling async calls
pub fn GenericTimer(comptime fun: anytype) type {
    const FunType = @TypeOf(fun);
    const ArgsType = std.meta.ArgsTuple(FunType);
    const ReturnType = @typeInfo(FunType).@"fn".return_type.?;
    if (@typeInfo(FunType).@"fn".params[0].type.? != u32) {
        @compileError("timer callback must accept interval `u32` as first argument");
    }
    if (ReturnType != u32) {
        @compileError("timer callback must return next interval `u32`");
    }

    return struct {
        allocator: std.mem.Allocator,
        fp: *const FunType,
        args: ArgsType,
        timer_id: ?sdl.SDL_TimerID = null,
        controller: ?*TimerController = null,
        node: ?*TimerController.TimerList.Node = null,

        pub fn create(
            allocator: std.mem.Allocator,
            _fp: *const FunType,
            _args: ArgsType,
            controller: ?*TimerController,
        ) !*@This() {
            const self = try allocator.create(@This());
            self.* = .{
                .allocator = allocator,
                .fp = _fp,
                .args = _args,
            };
            errdefer allocator.destroy(self);
            if (controller) |c| {
                self.controller = c;
                self.node = try c.addTimer(self.timer());
            } else {
                self.timer_id = sdl.SDL_AddTimer(
                    self.args[0],
                    call,
                    @ptrCast(self),
                );
                assert(self.timer_id.? > 0);
            }
            return self;
        }

        pub fn destroy(self: *@This()) void {
            if (self.controller) |c| {
                assert(self.node != null);
                c.removeNode(self.node.?);
            } else {
                assert(self.timer_id != null);
                _ = sdl.SDL_RemoveTimer(self.timer_id.?);
            }
            self.allocator.destroy(self);
        }

        fn timer(self: *@This()) Timer {
            return .{
                .ptr = @ptrCast(self),
                .vtable = &.{
                    .destroySelf = destroySelf,
                    .getInterval = getInterval,
                    .doCallback = doCallback,
                },
            };
        }

        fn call(_: u32, ptr: ?*anyopaque) callconv(.C) u32 {
            const self: *@This() = @ptrCast(@alignCast(ptr));
            self.args[0] = @call(.auto, self.fp, self.args);
            if (self.args[0] == 0) {
                self.destroy();
            }
            return self.args[0];
        }

        //////////////////////// Timer API ////////////////////////
        fn destroySelf(ctx: *anyopaque) void {
            const self: *@This() = @ptrCast(@alignCast(ctx));
            self.destroy();
        }

        fn getInterval(ctx: *anyopaque) u32 {
            const self: *@This() = @ptrCast(@alignCast(ctx));
            return self.args[0];
        }

        fn doCallback(ctx: *anyopaque) u32 {
            const self: *@This() = @ptrCast(@alignCast(ctx));
            const next_interval = @call(.auto, self.fp, self.args);
            self.args[0] = next_interval;
            return next_interval;
        }
    };
}

/// Timer controller for updating timers' states (NOTE: it's not thread-safe!)
/// Use it when you want to invoke timers' callbacks in particular threads (e.g. main-thread)
pub const TimerController = struct {
    const TimerData = struct {
        ms: u32,
        timer: Timer,
    };
    const TimerList = std.DoublyLinkedList(TimerData);

    allocator: std.mem.Allocator,
    tlist: TimerList,

    pub fn create(allocator: std.mem.Allocator) !*TimerController {
        const c = try allocator.create(TimerController);
        c.* = .{
            .allocator = allocator,
            .tlist = .{},
        };
        return c;
    }

    pub fn destroy(c: *TimerController) void {
        while (c.tlist.first) |n| {
            n.data.timer.destroy();
        }
        c.allocator.destroy(c);
    }

    pub fn update(c: *TimerController, delta_seconds: f32) void {
        var delta_ms: u32 = @intFromFloat(delta_seconds * 1000);

        // Update timers' left time
        var node = c.tlist.first;
        while (node) |n| {
            if (n.data.ms >= delta_ms) {
                n.data.ms -= delta_ms;
                break;
            } else {
                n.data.ms = 0;
                delta_ms -= n.data.ms;
            }
            node = n.next;
        }

        // Call expired timers' callbacks
        while (c.tlist.first) |n| {
            if (n.data.ms != 0) break;
            const ms = n.data.timer.doCallback();
            if (ms == 0) {
                n.data.timer.destroy();
            } else {
                c.tlist.remove(n);
                n.data.ms = ms;
                c.addNode(n);
            }
            node = n.next;
        }
    }

    fn addTimer(c: *TimerController, timer: Timer) !*TimerList.Node {
        const new_node = try c.allocator.create(TimerList.Node);
        new_node.data = .{
            .ms = timer.getInterval(),
            .timer = timer,
        };
        c.addNode(new_node);
        return new_node;
    }

    fn addNode(c: *TimerController, new_node: *TimerList.Node) void {
        // Find suitable insert position
        var accu_ms: u32 = 0;
        var node = c.tlist.first;
        while (node) |n| {
            accu_ms += n.data.ms;
            if (accu_ms >= new_node.data.ms) break;
            node = n.next;
        }

        // Insert new node
        if (node) |n| {
            assert(new_node.data.ms <= accu_ms);
            accu_ms -= n.data.ms;
            new_node.data.ms -= accu_ms;
            n.data.ms -= new_node.data.ms;
            c.tlist.insertBefore(n, new_node);
        } else {
            assert(new_node.data.ms >= accu_ms);
            new_node.data.ms -= accu_ms;
            c.tlist.append(new_node);
        }
    }

    fn removeNode(c: *TimerController, node: *TimerList.Node) void {
        if (node.next) |n| {
            n.data.ms += node.data.ms;
        }
        c.tlist.remove(node);
        c.allocator.destroy(node);
    }
};

const Timer = struct {
    ptr: *anyopaque = undefined,
    vtable: *const VTable = undefined,

    const VTable = struct {
        /// destory itself
        destroySelf: *const fn (ctx: *anyopaque) void,

        /// Get interval of timer
        getInterval: *const fn (ctx: *anyopaque) u32,

        /// Do callback and return next interval (milliseconds), 0 means timer isn't useful anymore
        doCallback: *const fn (ctx: *anyopaque) u32,
    };

    fn destroy(t: Timer) void {
        return t.vtable.destroySelf(t.ptr);
    }

    fn getInterval(t: Timer) u32 {
        return t.vtable.getInterval(t.ptr);
    }

    fn doCallback(t: Timer) u32 {
        return t.vtable.doCallback(t.ptr);
    }
};
