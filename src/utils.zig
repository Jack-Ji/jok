const std = @import("std");
const assert = std.debug.assert;
const math = std.math;

/// Map `v` from [from, to] to [map_from, map_to]
pub fn mapf(v: f32, from: f32, to: f32, map_from: f32, map_to: f32) f32 {
    if (math.approxEqAbs(f32, from, to, math.epsilon(f32))) return from;
    const v1 = std.math.clamp(v, from, to);
    return map_from + (map_to - map_from) * (v1 - from) / (to - from);
}
