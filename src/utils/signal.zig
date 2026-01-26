//! Signal/slot pattern implementation for event-driven programming.
//!
//! This module provides a type-safe signal/slot system similar to Qt's signals,
//! allowing decoupled communication between components.
//!
//! Features:
//! - Type-safe signal emissions and connections
//! - Support for multiple subscribers
//! - Optional context (userdata) for callbacks
//! - Pre-bound arguments
//! - Conditional filtering of signals
//! - One-shot connections
//! - Automatic cleanup of disconnected slots
//!
//! Example usage:
//! ```zig
//! const MySignal = Signal(&.{ u32, []const u8 });
//! var sig = try MySignal.create(allocator);
//! defer sig.destroy();
//!
//! fn onEvent(value: u32, message: []const u8) void {
//!     std.debug.print("Event: {} - {s}\n", .{value, message});
//! }
//!
//! _ = try sig.connect(onEvent, .{});
//! sig.emit(.{ 42, "Hello" });
//! ```

const std = @import("std");
const builtin = std.builtin;

/// Create a signal type with the given parameter types
/// Returns a struct type that can emit signals with those parameters
pub fn Signal(comptime types: []const type) type {
    var params: [types.len + 1]type = undefined;
    var attrs: [types.len + 1]builtin.Type.Fn.Param.Attributes = undefined;
    params[0] = ?*anyopaque;
    attrs[0] = .{};
    for (0..types.len) |i| {
        params[i + 1] = types[i];
        attrs[i + 1] = .{};
    }

    const _FuncType = @Fn(params[1..], attrs[1..], void, .{});
    const _FuncWithContextType = @Fn(params[0..], attrs[0..], void, .{});

    return struct {
        const SignalSystem = @This();

        /// Tuple type containing all signal arguments
        pub const ArgsType = @Tuple(types);
        /// Function type without context: fn(args...) void
        pub const FuncType = *const _FuncType; // fn (args...) void
        /// Function type with context: fn(ctx: ?*anyopaque, args...) void
        pub const FuncWithContextType = *const _FuncWithContextType; // fn (ctx: ?*anyopaque, args...) void
        /// Filter function to conditionally process signals
        pub const FilterFunc = *const fn (args: ArgsType) bool; // fn (args) bool
        /// Options for connecting a slot to the signal
        pub const ConnectOption = struct {
            args: ?ArgsType = null, // Pre-bound arguments
            filter: ?FilterFunc = null, // Filter args of signals, only take effect when args isn't pre-bound
            once: bool = false, // Only triggered once
        };
        /// Handle for managing a signal connection
        pub const Connection = struct {
            sig: *SignalSystem,
            id: u64,

            /// Disconnect this connection from the signal
            pub fn disconnect(self: @This()) void {
                for (self.sig.connected.items) |*s| {
                    if (s.id == self.id and s.sf != null) {
                        s.sf = null;
                        return;
                    }
                }
            }
        };

        const SlotFunc = union(enum) {
            func: FuncType,
            func_with_context: FuncWithContextType,
        };
        const Slot = struct {
            id: u64,
            sf: ?SlotFunc,
            ctx: ?*anyopaque,
            args: ?ArgsType,
            filter: ?FilterFunc,
            once: bool,
        };

        allocator: std.mem.Allocator,
        connected: std.ArrayList(Slot),
        id_alloc: u64,

        /// Create a new signal
        pub fn create(allocator: std.mem.Allocator) !*@This() {
            const s = try allocator.create(@This());
            s.* = .{
                .allocator = allocator,
                .connected = .empty,
                .id_alloc = 1,
            };
            return s;
        }

        /// Destroy the signal and free resources
        pub fn destroy(self: *@This()) void {
            self.connected.deinit(self.allocator);
            self.allocator.destroy(self);
        }

        /// Connect a function to this signal
        /// Returns a Connection handle that can be used to disconnect later
        pub fn connect(self: *@This(), fp: FuncType, opt: ConnectOption) !Connection {
            const id = self.id_alloc;
            try self.connected.append(self.allocator, .{
                .id = id,
                .sf = .{ .func = fp },
                .ctx = null,
                .args = opt.args,
                .filter = opt.filter,
                .once = opt.once,
            });
            self.id_alloc +%= 1;
            return .{ .sig = self, .id = id };
        }

        /// Connect a function with context (userdata) to this signal
        /// The context will be passed as the first argument to the callback
        pub fn connectWithContext(self: *@This(), fp: FuncWithContextType, ctx: ?*anyopaque, opt: ConnectOption) !Connection {
            const id = self.id_alloc;
            try self.connected.append(self.allocator, .{
                .id = id,
                .sf = .{ .func_with_context = fp },
                .ctx = ctx,
                .args = opt.args,
                .filter = opt.filter,
                .once = opt.once,
            });
            self.id_alloc +%= 1;
            return .{ .sig = self, .id = id };
        }

        /// Clear all connections from this signal
        pub fn clear(self: *@This()) void {
            self.connected.clearRetainingCapacity();
        }

        /// Emit the signal with the given arguments
        /// All connected slots will be invoked with these arguments
        pub fn emit(self: *@This(), args: ArgsType) void {
            var count = self.connected.items.len;
            var idx: usize = 0;
            while (count > 0 and idx < self.connected.items.len) : (count -= 1) {
                const slot = self.connected.items[idx];
                if (slot.sf) |sf| {
                    if (slot.filter != null and slot.args == null) { // Only do conditional emitting when args isn't bound
                        if (!slot.filter.?(args)) {
                            idx += 1;
                            continue;
                        }
                    }
                    switch (sf) {
                        .func => |fp| _ = @call(.auto, fp, slot.args orelse args),
                        .func_with_context => |fp| _ = @call(.auto, fp, .{slot.ctx} ++ (slot.args orelse args)),
                    }
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

    // connection without context
    _ = try sig.connect(S.fun1, .{
        .filter = struct {
            fn filter(args: MySignal.ArgsType) bool {
                return args[0] % 2 == 0;
            }
        }.filter,
    });
    _ = try sig.connect(S.fun2, .{});
    var con = try sig.connect(S.fun3, .{});
    _ = try sig.connect(S.fun4, .{ .args = .{ 1, 1, 1 }, .once = true });
    sig.emit(.{ 10, 20, 30 });
    try std.testing.expectEqual(63, S.counter);
    con.disconnect();
    sig.emit(.{ 10, 20, 30 });
    sig.emit(.{ 9, 0, 0 });
    try std.testing.expectEqual(93, S.counter);
    sig.clear();
    sig.emit(.{ 10, 20, 30 });
    try std.testing.expectEqual(93, S.counter);

    // connection with context
    const O = struct {
        counter: usize = 0,

        fn fun1(o: *@This(), a: u32, _: u64, _: u8) void {
            o.counter += a;
        }
        fn fun2(o: *@This(), _: u32, b: u64, _: u8) void {
            o.counter += b;
        }
        fn fun3(o: *@This(), _: u32, _: u64, c: u8) void {
            o.counter += c;
        }
        fn fun4(o: *@This(), a: u32, b: u64, c: u8) void {
            o.counter += a + b + c;
        }
    };
    var o = O{};
    _ = try sig.connectWithContext(@ptrCast(&O.fun1), &o, .{});
    _ = try sig.connectWithContext(@ptrCast(&O.fun2), &o, .{});
    con = try sig.connectWithContext(@ptrCast(&O.fun3), &o, .{});
    _ = try sig.connectWithContext(@ptrCast(&O.fun4), &o, .{ .args = .{ 1, 1, 1 }, .once = true });
    sig.emit(.{ 10, 20, 30 });
    try std.testing.expectEqual(63, o.counter);
    con.disconnect();
    sig.emit(.{ 10, 20, 30 });
    try std.testing.expectEqual(93, o.counter);
    sig.clear();
    sig.emit(.{ 10, 20, 30 });
    try std.testing.expectEqual(93, o.counter);
}
