/// Easing system
/// Checkout link: https://easings.net
const std = @import("std");
const math = std.math;
const assert = std.debug.assert;
const jok = @import("../jok.zig");
const sdl = jok.sdl;
const zmath = jok.zmath;

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

pub fn EasingSystem(comptime T: type) type {
    return struct {
        const EasingApplyFn = *const fn (x: f32, from: T, to: T) T;
        const EasingValue = struct {
            easing_fn: EasingFn,
            easing_apply_fn: EasingApplyFn,
            life_total: f32,
            life_passed: f32,
            v: *T,
            from: T,
            to: T,
        };
        const Self = @This();

        allocator: std.mem.Allocator,
        vars: std.ArrayList(EasingValue),

        pub fn create(allocator: std.mem.Allocator) !*Self {
            const self = try allocator.create(Self);
            self.* = .{
                .allocator = allocator,
                .vars = std.ArrayList(EasingValue).init(allocator),
            };
            return self;
        }

        pub fn destroy(self: *Self) void {
            self.vars.deinit();
            self.allocator.destroy(self);
        }

        pub fn count(self: *const Self) usize {
            return self.vars.items.len;
        }

        pub fn update(self: *Self, delta_time: f32) void {
            if (self.vars.items.len == 0) return;

            var i: usize = 0;
            while (i < self.vars.items.len) {
                var ev = &self.vars.items[i];
                ev.life_passed += delta_time;
                const x = ev.easing_fn(@min(1.0, ev.life_passed / ev.life_total));
                ev.v.* = ev.easing_apply_fn(x, ev.from, ev.to);
                if (ev.life_passed >= ev.life_total) {
                    _ = self.vars.swapRemove(i);
                } else {
                    i += 1;
                }
            }
        }

        pub fn add(
            self: *Self,
            v: *T,
            easing_type: EasingType,
            easing_apply_fn: EasingApplyFn,
            life: f32,
            from: ?T,
            to: T,
        ) !void {
            assert(life > 0);
            try self.vars.append(.{
                .easing_fn = getEasingFn(easing_type),
                .easing_apply_fn = easing_apply_fn,
                .life_total = life,
                .life_passed = 0,
                .v = v,
                .from = from orelse v.*,
                .to = to,
            });
        }
    };
}

pub fn EaseScalar(comptime T: type) type {
    return struct {
        pub fn ease(x: f32, from: T, to: T) T {
            return switch (T) {
                f32 => from + (to - from) * x,
                f64 => from + (to - from) * @as(f64, @floatCast(x)),
                c_int, i8, i16, i32, i64 => from + @as(T, @intFromFloat(@as(f32, @floatFromInt(to - from)) * x)),
                u8, u16, u32, u64 => from + @as(T, @intFromFloat(@as(f32, @floatFromInt(@as(i64, to) - @as(i64, from))) * x)),
                else => unreachable,
            };
        }
    };
}

pub fn EaseVector(comptime N: u32, comptime T: type) type {
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

        pub fn ease(x: f32, from: Vec, to: Vec) Vec {
            return switch (T) {
                f32 => from + (to - from) * @as(Vec, @splat(x)),
                f64 => from + (to - from) * @as(Vec, @splat(@as(f64, x))),
                c_int, i8, i16, i32, i64, u8, u16, u32, u64 => BLK: {
                    const from_f64 = convert(T, f64, from);
                    const to_f64 = convert(T, f64, to);
                    const result_f64 = from_f64 + (to_f64 - from_f64) * @as(@Vector(N, f64), @splat(@as(f64, x)));
                    break :BLK convert(f64, T, result_f64);
                },
                else => unreachable,
            };
        }
    };
}

pub fn easePointF(x: f32, from: sdl.PointF, to: sdl.PointF) sdl.PointF {
    const es = EaseScalar(f32);
    return .{
        .x = es.ease(x, from.x, to.x),
        .y = es.ease(x, from.y, to.y),
    };
}

pub fn easeColor(x: f32, _from: sdl.Color, _to: sdl.Color) sdl.Color {
    const es = EaseVector(4, u8);
    const from = @Vector(4, u8){ _from.r, _from.g, _from.b, _from.a };
    const to = @Vector(4, u8){ _to.r, _to.g, _to.b, _to.a };
    const c = es.ease(x, from, to);
    return .{ .r = c[0], .g = c[1], .b = c[2], .a = c[3] };
}

///////////////////////////////////////////////////////////////////////
///
/// Different kinds of easing functions (x goes from 0 to 1)
///
///////////////////////////////////////////////////////////////////////

const EasingFn = *const fn (f32) f32;

fn getEasingFn(t: EasingType) EasingFn {
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

fn linear(x: f32) f32 {
    return x;
}

const sin = struct {
    fn in(x: f32) f32 {
        return 1 - math.cos((x * math.pi) / 2);
    }

    fn out(x: f32) f32 {
        return math.sin((x * math.pi) / 2);
    }

    fn inOut(x: f32) f32 {
        return -(math.cos(math.pi * x) - 1) / 2;
    }
};

const quad = struct {
    fn in(x: f32) f32 {
        return x * x;
    }

    fn out(x: f32) f32 {
        return 1 - (1 - x) * (1 - x);
    }

    fn inOut(x: f32) f32 {
        return if (x < 0.5)
            2 * x * x
        else
            1 - math.pow(f32, -2 * x + 2, 2) / 2;
    }
};

const cubic = struct {
    fn in(x: f32) f32 {
        return x * x * x;
    }

    fn out(x: f32) f32 {
        return 1 - math.pow(f32, 1 - x, 3);
    }

    fn inOut(x: f32) f32 {
        return if (x < 0.5)
            4 * x * x * x
        else
            1 - math.pow(f32, -2 * x + 2, 3) / 2;
    }
};

const quart = struct {
    fn in(x: f32) f32 {
        return x * x * x * x;
    }

    fn out(x: f32) f32 {
        return 1 - math.pow(f32, 1 - x, 4);
    }

    fn inOut(x: f32) f32 {
        return if (x < 0.5)
            8 * x * x * x * x
        else
            1 - math.pow(f32, -2 * x + 2, 4) / 2;
    }
};

const quint = struct {
    fn in(x: f32) f32 {
        return x * x * x * x * x;
    }

    fn out(x: f32) f32 {
        return 1 - math.pow(f32, 1 - x, 5);
    }

    fn inOut(x: f32) f32 {
        return if (x < 0.5)
            16 * x * x * x * x * x
        else
            1 - math.pow(f32, -2 * x + 2, 5) / 2;
    }
};

const expo = struct {
    fn in(x: f32) f32 {
        return if (math.approxEqAbs(f32, x, 0, math.floatEps(f32)))
            0
        else
            math.pow(f32, 2, 10 * x - 10);
    }

    fn out(x: f32) f32 {
        return if (math.approxEqAbs(f32, x, 1, math.floatEps(f32)))
            1
        else
            1 - math.pow(f32, 2, -10 * x);
    }

    fn inOut(x: f32) f32 {
        return if (math.approxEqAbs(f32, x, 0, math.floatEps(f32)))
            0
        else if (math.approxEqAbs(f32, x, 1, math.floatEps(f32)))
            1
        else if (x < 0.5)
            math.pow(f32, 2, 20 * x - 10) / 2
        else
            (2 - math.pow(f32, 2, -20 * x + 10)) / 2;
    }
};

const circ = struct {
    fn in(x: f32) f32 {
        return 1.0 - math.sqrt(1.0 - math.pow(f32, x, 2));
    }

    fn out(x: f32) f32 {
        return math.sqrt(1.0 - math.pow(f32, x - 1, 2));
    }

    fn inOut(x: f32) f32 {
        return if (x < 0.5)
            (1.0 - math.sqrt(1.0 - math.pow(f32, 2 * x, 2))) / 2
        else
            (math.sqrt(1.0 - math.pow(f32, -2 * x + 2, 2)) + 1) / 2;
    }
};

const back = struct {
    fn in(x: f32) f32 {
        const c1 = 1.70158;
        const c3 = c1 + 1;
        return c3 * x * x * x - c1 * x * x;
    }

    fn out(x: f32) f32 {
        const c1 = 1.70158;
        const c3 = c1 + 1;
        return 1.0 + c3 * math.pow(f32, x - 1, 3) + c1 * math.pow(f32, x - 1, 2);
    }

    fn inOut(x: f32) f32 {
        const c1 = 1.70158;
        const c2 = c1 * 1.525;
        return if (x < 0.5)
            (math.pow(f32, 2 * x, 2) * ((c2 + 1) * 2 * x - c2)) / 2
        else
            (math.pow(f32, 2 * x - 2, 2) * ((c2 + 1) * (x * 2 - 2) + c2) + 2) / 2;
    }
};

const elastic = struct {
    fn in(x: f32) f32 {
        const c4 = (2.0 * math.pi) / 3.0;
        return if (math.approxEqAbs(f32, x, 0, math.floatEps(f32)))
            0
        else if (math.approxEqAbs(f32, x, 1, math.floatEps(f32)))
            1
        else
            -math.pow(f32, 2, 10 * x - 10) * math.sin((x * 10 - 10.75) * c4);
    }

    fn out(x: f32) f32 {
        const c4 = (2.0 * math.pi) / 3.0;
        return if (math.approxEqAbs(f32, x, 0, math.floatEps(f32)))
            0
        else if (math.approxEqAbs(f32, x, 1, math.floatEps(f32)))
            1
        else
            math.pow(f32, 2, -10 * x) * math.sin((x * 10 - 0.75) * c4) + 1;
    }

    fn inOut(x: f32) f32 {
        const c5 = (2.0 * math.pi) / 4.5;
        return if (math.approxEqAbs(f32, x, 0, math.floatEps(f32)))
            0
        else if (math.approxEqAbs(f32, x, 1, math.floatEps(f32)))
            1
        else if (x < 0.5)
            -(math.pow(f32, 2, 20 * x - 10) * math.sin((20 * x - 11.125) * c5)) / 2
        else
            (math.pow(f32, 2, -20 * x + 10) * math.sin((20 * x - 11.125) * c5)) / 2 + 1;
    }
};

const bounce = struct {
    fn in(x: f32) f32 {
        return 1 - out(1 - x);
    }

    fn out(x: f32) f32 {
        const n1 = 7.5625;
        const d1 = 2.75;
        if (x < 1.0 / d1) {
            return n1 * x * x;
        } else if (x < 2.0 / d1) {
            const _x = x - 1.5 / d1;
            return n1 * _x * _x + 0.75;
        } else if (x < 2.5 / d1) {
            const _x = x - 2.25 / d1;
            return n1 * _x * _x + 0.9375;
        } else {
            const _x = x - 2.625 / d1;
            return n1 * _x * _x + 0.984375;
        }
    }

    fn inOut(x: f32) f32 {
        return if (x < 0.5)
            (1.0 - out(1.0 - 2.0 * x)) / 2.0
        else
            (1.0 + out(2.0 * x - 1.0)) / 2.0;
    }
};
