const std = @import("std");
const assert = std.debug.assert;
const math = std.math;

/// Map `v` from [from, to] to [map_from, map_to]
pub inline fn mapf(v: f32, from: f32, to: f32, map_from: f32, map_to: f32) f32 {
    if (math.approxEqAbs(f32, from, to, math.epsilon(f32))) return from;
    const v1 = std.math.clamp(v, from, to);
    return map_from + (map_to - map_from) * (v1 - from) / (to - from);
}

/// Convert radian to degree
pub inline fn radianToDegree(r: f32) f32 {
    return r * 180.0 / std.math.pi;
}

/// Convert degree to radian
pub inline fn degreeToRadian(d: f32) f32 {
    return d * std.math.pi / 180.0;
}
