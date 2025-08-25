const std = @import("std");
const builtin = @import("builtin");
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
        timer_id: ?sdl.c.SDL_TimerID = null,
        controller: ?*TimerController = null,
        td: ?*TimerController.TimerData = null,

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
                self.td = try c.addTimer(self.timer());
            } else if (!builtin.is_test) {
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
                assert(self.td != null);
                c.removeNode(self.td.?);
            } else if (!builtin.is_test) {
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

        fn call(_: u32, ptr: ?*anyopaque) callconv(.c) u32 {
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

/// Timer controller for updating timers' states (Be warned: it's not thread-safe!)
/// Use it when you want to invoke timers' callbacks in particular thread (e.g. main-thread)
pub const TimerController = struct {
    const TimerData = struct {
        node: std.DoublyLinkedList.Node = .{},
        ms: u32,
        timer: Timer,
    };

    allocator: std.mem.Allocator,
    tlist: std.DoublyLinkedList,

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
            const data: *TimerData = @fieldParentPtr("node", n);
            data.timer.destroy();
        }
        c.allocator.destroy(c);
    }

    pub fn update(c: *TimerController, delta_seconds: f32) void {
        var delta_ms: u32 = @intFromFloat(delta_seconds * 1000);

        // Update timers' state
        var node = c.tlist.first;
        while (node) |n| {
            var data: *TimerData = @fieldParentPtr("node", n);
            if (data.ms >= delta_ms) {
                data.ms -= delta_ms;
                break;
            } else {
                data.ms = 0;
                delta_ms -= data.ms;
            }
            node = n.next;
        }

        // Call expired timers' callbacks
        while (c.tlist.first) |n| {
            var data: *TimerData = @fieldParentPtr("node", n);
            if (data.ms != 0) break;
            const ms = data.timer.doCallback();
            if (ms == 0) {
                data.timer.destroy();
            } else {
                c.tlist.remove(n);
                data.ms = ms;
                c.addNode(data);
            }
            node = n.next;
        }
    }

    fn addTimer(c: *TimerController, timer: Timer) !*TimerData {
        const td = try c.allocator.create(TimerData);
        td.* = .{
            .ms = timer.getInterval(),
            .timer = timer,
        };
        c.addNode(td);
        return td;
    }

    fn addNode(c: *TimerController, td: *TimerData) void {
        // Find suitable insert position
        var accu_ms: u32 = 0;
        var node = c.tlist.first;
        while (node) |n| {
            const data: *TimerData = @fieldParentPtr("node", n);
            accu_ms += data.ms;
            if (accu_ms >= td.ms) break;
            node = n.next;
        }

        // Insert new node
        if (node) |n| {
            assert(td.ms <= accu_ms);
            var data: *TimerData = @fieldParentPtr("node", n);
            accu_ms -= data.ms;
            td.ms -= accu_ms;
            data.ms -= td.ms;
            c.tlist.insertBefore(n, &td.node);
        } else {
            assert(td.ms >= accu_ms);
            td.ms -= accu_ms;
            c.tlist.append(&td.node);
        }
    }

    fn removeNode(c: *TimerController, td: *TimerData) void {
        if (td.node.next) |n| {
            var data: *TimerData = @fieldParentPtr("node", n);
            data.ms += td.ms;
        }
        c.tlist.remove(&td.node);
        c.allocator.destroy(td);
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

test "timer" {
    const S = struct {
        var sum: usize = 0;

        fn fun(interval: u32, a: u64) u32 {
            sum += a;
            return interval - 1;
        }
    };
    var controller = try TimerController.create(std.testing.allocator);
    defer controller.destroy();
    _ = try GenericTimer(S.fun).create(
        std.testing.allocator,
        S.fun,
        .{ 10, 100 },
        controller,
    );
    _ = try GenericTimer(S.fun).create(
        std.testing.allocator,
        S.fun,
        .{ 5, 10 },
        controller,
    );
    controller.update(0.010);
    controller.update(0.009);
    controller.update(0.008);
    controller.update(0.007);
    try std.testing.expectEqual(440, S.sum);
}
