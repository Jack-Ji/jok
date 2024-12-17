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
            .calling_convention = .Unspecified,
            .is_generic = false,
            .is_var_args = false,
            .return_type = void,
            .params = &params,
        },
    };
    const FunType = @Type(funInfo);
    const ArgsType = std.meta.Tuple(types);

    return struct {
        allocator: std.mem.Allocator,
        connected: std.AutoHashMap(*const FunType, void),

        pub fn create(allocator: std.mem.Allocator) !*@This() {
            const s = try allocator.create(@This());
            s.* = .{
                .allocator = allocator,
                .connected = std.AutoHashMap(*const FunType, void).init(allocator),
            };
            return s;
        }

        pub fn destroy(self: *@This()) void {
            self.connected.deinit();
            self.allocator.destroy(self);
        }

        pub fn connect(self: *@This(), fp: *const FunType) !void {
            try self.connected.put(fp, {});
        }

        pub fn disconnect(self: *@This(), fp: *const FunType) void {
            _ = self.connected.remove(fp);
        }

        pub fn clear(self: *@This()) void {
            self.connected.clearRetainingCapacity();
        }

        pub fn emit(self: @This(), args: ArgsType) void {
            if (self.connected.count() == 0) return;
            var it = self.connected.keyIterator();
            while (it.next()) |fpp| {
                _ = @call(.auto, fpp.*, args);
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
    };
    const MySignal = Signal(&.{ u32, u64, u8 });
    const sig = try MySignal.create(std.testing.allocator);
    defer sig.destroy();
    try sig.connect(S.fun1);
    try sig.connect(S.fun2);
    try sig.connect(S.fun3);
    sig.emit(.{ 10, 20, 30 });
    try std.testing.expectEqual(60, S.counter);

    sig.disconnect(S.fun3);
    sig.emit(.{ 10, 20, 30 });
    try std.testing.expectEqual(90, S.counter);
}
