/// Easing System
/// https://easings.net
const std = @import("std");
const math = std.math;
const assert = std.debug.assert;
const jok = @import("../jok.zig");
const signal = @import("signal.zig");

pub const EasingType = enum(u8) {
    linear,
    in_sin,
    out_sin,
    in_out_sin,
    in_quad,
    out_quad,
    in_out_quad,
    in_cubic,
    out_cubic,
    in_out_cubic,
    in_quart,
    out_quart,
    in_out_quart,
    in_quint,
    out_quint,
    in_out_quint,
    in_expo,
    out_expo,
    in_out_expo,
    in_circ,
    out_circ,
    in_out_circ,
    in_back,
    out_back,
    in_out_back,
    in_elastic,
    out_elastic,
    in_out_elastic,
    in_bounce,
    out_bounce,
    in_out_bounce,
};

const DummyMutex = struct {
    fn lock(_: *DummyMutex) void {}
    fn unlock(_: *DummyMutex) void {}
};

pub fn EasingSystem(comptime T: type) type {
    return struct {
        pub const EasingValue = struct {
            node: std.DoublyLinkedList.Node = .{},
            state: VarState,
            easing_fn: EasingFn,
            easing_apply_fn: EasingApplyFn,
            wait_total: f32,
            waited: f32,
            life_total: f32,
            life_passed: f32,
            v: *T,
            from: T,
            to: T,
            finish: ?Finish,
            data: ?*anyopaque,
        };
        pub const Finish = struct {
            callback: *const fn (EasingValue, data2: ?*anyopaque) void,
            data: ?*anyopaque = null,
        };
        pub const EasingSignal = signal.Signal(&.{*const EasingValue});
        pub const EasingApplyFn = *const fn (t: f32, from: T, to: T, data: ?*anyopaque) T;
        const VarState = enum {
            new,
            easing,
            deleted,
        };
        const EasingPool = std.heap.MemoryPool(EasingValue);
        const EasingSearchMap = std.AutoHashMap(*const T, *EasingValue);
        const Self = @This();

        allocator: std.mem.Allocator,
        pool: EasingPool,
        vars: std.DoublyLinkedList,
        search_tree: EasingSearchMap,
        sig: *EasingSignal, // Notify finished easing job

        pub fn create(allocator: std.mem.Allocator) !*Self {
            const self = try allocator.create(Self);
            self.* = .{
                .allocator = allocator,
                .pool = .empty,
                .vars = .{},
                .search_tree = EasingSearchMap.init(allocator),
                .sig = try EasingSignal.create(allocator),
            };
            return self;
        }

        pub fn destroy(self: *Self) void {
            self.pool.deinit(self.allocator);
            self.search_tree.deinit();
            self.sig.destroy();
            self.allocator.destroy(self);
        }

        pub fn update(self: *Self, _delta_time: f32) void {
            if (self.vars.len() == 0) return;

            // Change newly added nodes' state to easing, and remove deleted node
            var node = self.vars.first;
            while (node) |n| {
                var ev: *EasingValue = @fieldParentPtr("node", node.?);
                node = n.next;
                if (ev.state == .new) {
                    ev.state = .easing;
                    continue;
                }
                if (ev.state == .deleted) {
                    self.vars.remove(&ev.node);
                    self.pool.destroy(ev);
                    continue;
                }
            }

            // Apply easing to vars
            node = self.vars.first;
            while (self.vars.len() != 0 and node != null) {
                var ev: *EasingValue = @fieldParentPtr("node", node.?);
                node = node.?.next;
                if (ev.state == .new) break;
                if (ev.state != .easing) continue;

                // Check if wait enough
                var delta_time = _delta_time;
                if (ev.waited < ev.wait_total) {
                    const need_wait = ev.wait_total - ev.waited;
                    if (need_wait > delta_time) {
                        ev.waited += delta_time;
                        continue;
                    }
                    delta_time -= need_wait;
                    ev.waited = ev.wait_total;
                }

                // Apply ease function
                ev.life_passed += delta_time;
                const t = ev.easing_fn(@min(1.0, ev.life_passed / ev.life_total));
                ev.v.* = ev.easing_apply_fn(t, ev.from, ev.to, ev.data);

                // Remove if it's done
                if (ev.life_passed >= ev.life_total) {
                    // Remove node from var list
                    // Release memory until subscribers are done
                    self.vars.remove(&ev.node);
                    _ = self.search_tree.remove(ev.v);
                    defer self.pool.destroy(ev);

                    // Notify subscribers
                    if (ev.finish) |fs| {
                        fs.callback(ev.*, fs.data);
                    }
                    self.sig.emit(.{ev});
                }
            }
        }

        pub const AddOption = struct {
            wait_time: f32 = 0,
            finish: ?Finish = null,
            data: ?*anyopaque = null,
        };
        pub fn add(
            self: *Self,
            v: *T,
            easing_fn: EasingFn,
            easing_apply_fn: EasingApplyFn,
            life: f32,
            from: ?T,
            to: T,
            opt: AddOption,
        ) !void {
            assert(life > 0);
            assert(opt.wait_time >= 0);

            // Remove old easing if exists
            self.remove(v);

            const ev = try self.pool.create(self.allocator);
            ev.* = .{
                .state = .new,
                .easing_fn = easing_fn,
                .easing_apply_fn = easing_apply_fn,
                .wait_total = opt.wait_time,
                .waited = 0,
                .life_total = life,
                .life_passed = 0,
                .v = v,
                .from = from orelse v.*,
                .to = to,
                .finish = opt.finish,
                .data = opt.data,
            };
            errdefer self.pool.destroy(ev);
            try self.search_tree.put(v, ev);
            self.vars.append(&ev.node);
        }

        pub fn has(self: *Self, v: *const T) bool {
            return self.search_tree.get(v) != null;
        }

        pub fn remove(self: *Self, v: *const T) void {
            if (self.search_tree.fetchRemove(v)) |kv| {
                // Q: Why not remove node from list immediately?
                // A: If we do, it would be impossible to correctly iterate
                // through vars in `update`. Cause user might call `remove`
                // function though callback/signal.
                kv.value.state = .deleted;
            }
        }

        pub fn clear(self: *Self) void {
            _ = self.pool.reset(self.allocator, .retain_capacity);
            self.search_tree.clearRetainingCapacity();
            self.vars = .{};
        }
    };
}

pub fn EaseScalarLinearly(comptime T: type) type {
    return struct {
        pub fn ease(t: f32, from: T, to: T, _: ?*anyopaque) T {
            return switch (T) {
                f32 => @mulAdd(f32, to - from, t, from),
                f64 => @mulAdd(f64, to - from, @as(f64, @floatCast(t)), from),
                c_int, i8, i16, i32, i64 => @intFromFloat(@mulAdd(f32, @as(f32, @floatFromInt(to - from)), t, @as(f32, @floatFromInt(from)))),
                u8, u16, u32, u64 => @intFromFloat(@mulAdd(f32, @as(f32, @floatFromInt(to)) - @as(f32, @floatFromInt(from)), t, @as(f32, @floatFromInt(from)))),
                else => unreachable,
            };
        }
    };
}

pub fn EaseVectorLinearly(comptime N: u32, comptime T: type) type {
    const Vec = @Vector(N, T);

    return struct {
        fn convert(comptime T1: type, comptime T2: type, v: @Vector(N, T1)) @Vector(N, T2) {
            var result: @Vector(N, T2) = @splat(@as(T2, 0));
            comptime var i: u32 = 0;
            inline while (i < N) : (i += 1) {
                switch (T1) {
                    f32, f64 => switch (T2) {
                        f32, f64 => result[i] = @as(T2, v[i]),
                        c_int, i8, i16, i32, i64, u8, u16, u32, u64 => result[i] = @as(T2, @intFromFloat(v[i])),
                        else => unreachable,
                    },
                    c_int, i8, i16, i32, i64, u8, u16, u32, u64 => switch (T2) {
                        f32, f64 => result[i] = @as(T2, @floatFromInt(v[i])),
                        c_int, i8, i16, i32, i64, u8, u16, u32, u64 => result[i] = @as(T2, v[i]),
                        else => unreachable,
                    },
                    else => unreachable,
                }
            }
            return result;
        }

        pub fn ease(t: f32, from: Vec, to: Vec, _: ?*anyopaque) Vec {
            return switch (T) {
                f32 => @mulAdd(Vec, to - from, @as(Vec, @splat(t)), from),
                f64 => @mulAdd(Vec, to - from, @as(Vec, @splat(@as(f64, @floatCast(t)))), from),
                c_int, i8, i16, i32, i64, u8, u16, u32, u64 => BLK: {
                    const VecN = @Vector(N, f64);
                    const from_f64 = convert(T, f64, from);
                    const to_f64 = convert(T, f64, to);
                    const result_f64 = @mulAdd(VecN, to_f64 - from_f64, @as(VecN, @splat(@as(f64, t))), from_f64);
                    break :BLK convert(f64, T, result_f64);
                },
                else => unreachable,
            };
        }
    };
}

pub fn easePointLinearly(t: f32, from: jok.Point, to: jok.Point, data: ?*anyopaque) jok.Point {
    const es = EaseScalarLinearly(f32);
    return .{
        .x = es.ease(t, from.x, to.x, data),
        .y = es.ease(t, from.y, to.y, data),
    };
}

pub fn easeColorLinearly(t: f32, _from: jok.Color, _to: jok.Color, data: ?*anyopaque) jok.Color {
    const es = EaseVectorLinearly(4, u8);
    const from = @Vector(4, u8){ _from.r, _from.g, _from.b, _from.a };
    const to = @Vector(4, u8){ _to.r, _to.g, _to.b, _to.a };
    const c = es.ease(t, from, to, data);
    return .{ .r = c[0], .g = c[1], .b = c[2], .a = c[3] };
}

pub fn easeColorfLinearly(t: f32, _from: jok.ColorF, _to: jok.ColorF, data: ?*anyopaque) jok.ColorF {
    const es = EaseVectorLinearly(4, f32);
    const from = @Vector(4, f32){ _from.r, _from.g, _from.b, _from.a };
    const to = @Vector(4, f32){ _to.r, _to.g, _to.b, _to.a };
    const c = es.ease(t, from, to, data);
    return .{ .r = c[0], .g = c[1], .b = c[2], .a = c[3] };
}

pub fn easeArrayLinearly(t: f32, comptime N: usize, _from: [N]f32, _to: [N]f32, data: ?*anyopaque) [N]f32 {
    const es = EaseVectorLinearly(N, f32);
    const from: @Vector(N, f32) = _from;
    const to: @Vector(N, f32) = _to;
    return es.ease(t, from, to, data);
}

///////////////////////////////////////////////////////////////////////
///
/// Different kinds of easing functions (t goes from 0 to 1)
///
///////////////////////////////////////////////////////////////////////

pub const EasingFn = *const fn (f32) f32;

pub fn getEasingFn(t: EasingType) EasingFn {
    return switch (t) {
        .linear => linear,
        .in_sin => sin.in,
        .out_sin => sin.out,
        .in_out_sin => sin.inOut,
        .in_quad => quad.in,
        .out_quad => quad.out,
        .in_out_quad => quad.inOut,
        .in_cubic => cubic.in,
        .out_cubic => cubic.out,
        .in_out_cubic => cubic.inOut,
        .in_quart => quart.in,
        .out_quart => quart.out,
        .in_out_quart => quart.inOut,
        .in_quint => quint.in,
        .out_quint => quint.out,
        .in_out_quint => quint.inOut,
        .in_expo => expo.in,
        .out_expo => expo.out,
        .in_out_expo => expo.inOut,
        .in_circ => circ.in,
        .out_circ => circ.out,
        .in_out_circ => circ.inOut,
        .in_back => back.in,
        .out_back => back.out,
        .in_out_back => back.inOut,
        .in_elastic => elastic.in,
        .out_elastic => elastic.out,
        .in_out_elastic => elastic.inOut,
        .in_bounce => bounce.in,
        .out_bounce => bounce.out,
        .in_out_bounce => bounce.inOut,
    };
}

pub fn linear(t: f32) f32 {
    return t;
}

pub const sin = struct {
    pub fn in(t: f32) f32 {
        return 1 - math.cos((t * math.pi) / 2);
    }

    pub fn out(t: f32) f32 {
        return math.sin((t * math.pi) / 2);
    }

    pub fn inOut(t: f32) f32 {
        return -(math.cos(math.pi * t) - 1) / 2;
    }
};

pub const quad = struct {
    pub fn in(t: f32) f32 {
        return t * t;
    }

    pub fn out(t: f32) f32 {
        return 1 - (1 - t) * (1 - t);
    }

    pub fn inOut(t: f32) f32 {
        return if (t < 0.5)
            2 * t * t
        else
            1 - math.pow(f32, -2 * t + 2, 2) / 2;
    }
};

pub const cubic = struct {
    pub fn in(t: f32) f32 {
        return t * t * t;
    }

    pub fn out(t: f32) f32 {
        return 1 - math.pow(f32, 1 - t, 3);
    }

    pub fn inOut(t: f32) f32 {
        return if (t < 0.5)
            4 * t * t * t
        else
            1 - math.pow(f32, -2 * t + 2, 3) / 2;
    }
};

pub const quart = struct {
    pub fn in(t: f32) f32 {
        return t * t * t * t;
    }

    pub fn out(t: f32) f32 {
        return 1 - math.pow(f32, 1 - t, 4);
    }

    pub fn inOut(t: f32) f32 {
        return if (t < 0.5)
            8 * t * t * t * t
        else
            1 - math.pow(f32, -2 * t + 2, 4) / 2;
    }
};

pub const quint = struct {
    pub fn in(t: f32) f32 {
        return t * t * t * t * t;
    }

    pub fn out(t: f32) f32 {
        return 1 - math.pow(f32, 1 - t, 5);
    }

    pub fn inOut(t: f32) f32 {
        return if (t < 0.5)
            16 * t * t * t * t * t
        else
            1 - math.pow(f32, -2 * t + 2, 5) / 2;
    }
};

pub const expo = struct {
    pub fn in(t: f32) f32 {
        return if (math.approxEqAbs(f32, t, 0, math.floatEps(f32)))
            0
        else
            math.pow(f32, 2, 10 * t - 10);
    }

    pub fn out(t: f32) f32 {
        return if (math.approxEqAbs(f32, t, 1, math.floatEps(f32)))
            1
        else
            1 - math.pow(f32, 2, -10 * t);
    }

    pub fn inOut(t: f32) f32 {
        return if (math.approxEqAbs(f32, t, 0, math.floatEps(f32)))
            0
        else if (math.approxEqAbs(f32, t, 1, math.floatEps(f32)))
            1
        else if (t < 0.5)
            math.pow(f32, 2, 20 * t - 10) / 2
        else
            (2 - math.pow(f32, 2, -20 * t + 10)) / 2;
    }
};

pub const circ = struct {
    pub fn in(t: f32) f32 {
        return 1.0 - math.sqrt(1.0 - math.pow(f32, t, 2));
    }

    pub fn out(t: f32) f32 {
        return math.sqrt(1.0 - math.pow(f32, t - 1, 2));
    }

    pub fn inOut(t: f32) f32 {
        return if (t < 0.5)
            (1.0 - math.sqrt(1.0 - math.pow(f32, 2 * t, 2))) / 2
        else
            (math.sqrt(1.0 - math.pow(f32, -2 * t + 2, 2)) + 1) / 2;
    }
};

pub const back = struct {
    pub fn in(t: f32) f32 {
        const c1 = 1.70158;
        const c3 = c1 + 1;
        return c3 * t * t * t - c1 * t * t;
    }

    pub fn out(t: f32) f32 {
        const c1 = 1.70158;
        const c3 = c1 + 1;
        return 1.0 + c3 * math.pow(f32, t - 1, 3) + c1 * math.pow(f32, t - 1, 2);
    }

    pub fn inOut(t: f32) f32 {
        const c1 = 1.70158;
        const c2 = c1 * 1.525;
        return if (t < 0.5)
            (math.pow(f32, 2 * t, 2) * ((c2 + 1) * 2 * t - c2)) / 2
        else
            (math.pow(f32, 2 * t - 2, 2) * ((c2 + 1) * (t * 2 - 2) + c2) + 2) / 2;
    }
};

pub const elastic = struct {
    pub fn in(t: f32) f32 {
        const c4 = (2.0 * math.pi) / 3.0;
        return if (math.approxEqAbs(f32, t, 0, math.floatEps(f32)))
            0
        else if (math.approxEqAbs(f32, t, 1, math.floatEps(f32)))
            1
        else
            -math.pow(f32, 2, 10 * t - 10) * math.sin((t * 10 - 10.75) * c4);
    }

    pub fn out(t: f32) f32 {
        const c4 = (2.0 * math.pi) / 3.0;
        return if (math.approxEqAbs(f32, t, 0, math.floatEps(f32)))
            0
        else if (math.approxEqAbs(f32, t, 1, math.floatEps(f32)))
            1
        else
            math.pow(f32, 2, -10 * t) * math.sin((t * 10 - 0.75) * c4) + 1;
    }

    pub fn inOut(t: f32) f32 {
        const c5 = (2.0 * math.pi) / 4.5;
        return if (math.approxEqAbs(f32, t, 0, math.floatEps(f32)))
            0
        else if (math.approxEqAbs(f32, t, 1, math.floatEps(f32)))
            1
        else if (t < 0.5)
            -(math.pow(f32, 2, 20 * t - 10) * math.sin((20 * t - 11.125) * c5)) / 2
        else
            (math.pow(f32, 2, -20 * t + 10) * math.sin((20 * t - 11.125) * c5)) / 2 + 1;
    }
};

pub const bounce = struct {
    pub fn in(t: f32) f32 {
        return 1 - out(1 - t);
    }

    pub fn out(t: f32) f32 {
        const n1 = 7.5625;
        const d1 = 2.75;
        if (t < 1.0 / d1) {
            return n1 * t * t;
        } else if (t < 2.0 / d1) {
            const _x = t - 1.5 / d1;
            return n1 * _x * _x + 0.75;
        } else if (t < 2.5 / d1) {
            const _x = t - 2.25 / d1;
            return n1 * _x * _x + 0.9375;
        } else {
            const _x = t - 2.625 / d1;
            return n1 * _x * _x + 0.984375;
        }
    }

    pub fn inOut(t: f32) f32 {
        return if (t < 0.5)
            (1.0 - out(1.0 - 2.0 * t)) / 2.0
        else
            (1.0 + out(2.0 * t - 1.0)) / 2.0;
    }
};
