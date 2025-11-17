const std = @import("std");
const builtin = std.builtin;
const assert = std.debug.assert;
const log = std.log.scoped(.jok);

/// Signal Type
pub fn Signal(comptime types: []const type) type {
    var params: [types.len]builtin.Type.Fn.Param = undefined;
    for (&params, 0..) |*p, i| {
        p.* = .{
            .is_generic = false,
            .is_noalias = false,
            .type = types[i],
        };
    }
    const funInfo = builtin.Type{
        .@"fn" = .{
            .calling_convention = .auto,
            .is_generic = false,
            .is_var_args = false,
            .return_type = void,
            .params = &params,
        },
    };
    const ArgsType = std.meta.Tuple(types);
    const FunType = @Type(funInfo);
    const Slot = struct {
        fp: ?*const FunType,
        args: ?ArgsType,
        once: bool,
    };

    return struct {
        allocator: std.mem.Allocator,
        connected: std.ArrayList(Slot),

        pub fn create(allocator: std.mem.Allocator) !*@This() {
            const s = try allocator.create(@This());
            s.* = .{
                .allocator = allocator,
                .connected = .empty,
            };
            return s;
        }

        pub fn destroy(self: *@This()) void {
            self.connected.deinit(self.allocator);
            self.allocator.destroy(self);
        }

        pub fn connect(self: *@This(), fp: *const FunType, args: ?ArgsType) !void {
            try self.connected.append(self.allocator, .{
                .fp = fp,
                .args = args,
                .once = false,
            });
        }

        pub fn connectOnce(self: *@This(), fp: *const FunType, args: ?ArgsType) !void {
            try self.connected.append(self.allocator, .{
                .fp = fp,
                .args = args,
                .once = true,
            });
        }

        pub fn disconnect(self: *@This(), _fp: *const FunType, args: ?ArgsType) void {
            for (self.connected.items) |*s| {
                if (s.fp) |fp| {
                    if (fp == _fp and std.meta.eql(s.args, args)) {
                        s.fp = null; // marked as dead
                    }
                }
            }
        }

        pub fn clear(self: *@This()) void {
            self.connected.clearRetainingCapacity();
        }

        pub inline fn emit(self: *@This(), args: ArgsType) void {
            var count = self.connected.items.len;
            var idx: usize = 0;
            while (count > 0 and idx < self.connected.items.len) : (count -= 1) {
                const slot = self.connected.items[idx];
                if (slot.fp) |fp| {
                    _ = @call(.auto, fp, slot.args orelse args);
                    if (slot.once) {
                        _ = self.connected.orderedRemove(idx); // only trigger once
                    } else {
                        idx += 1;
                    }
                } else {
                    _ = self.connected.orderedRemove(idx); // cleanup dead
                }
            }
        }
    };
}

test "signal" {
    const S = struct {
        var counter: usize = 0;

        fn fun1(a: u32, _: u64, _: u8) void {
            counter += a;
        }
        fn fun2(_: u32, b: u64, _: u8) void {
            counter += b;
        }
        fn fun3(_: u32, _: u64, c: u8) void {
            counter += c;
        }
        fn fun4(a: u32, b: u64, c: u8) void {
            counter += a + b + c;
        }
    };
    const MySignal = Signal(&.{ u32, u64, u8 });
    const sig = try MySignal.create(std.testing.allocator);
    defer sig.destroy();
    try sig.connect(S.fun1, null);
    try sig.connect(S.fun2, null);
    try sig.connect(S.fun3, null);
    try sig.connectOnce(S.fun4, .{ 1, 1, 1 });
    sig.emit(.{ 10, 20, 30 });
    try std.testing.expectEqual(63, S.counter);

    sig.disconnect(S.fun3, null);
    sig.emit(.{ 10, 20, 30 });
    try std.testing.expectEqual(93, S.counter);
}
