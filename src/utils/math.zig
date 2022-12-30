const std = @import("std");
const jok = @import("../jok.zig");
const assert = std.debug.assert;
const math = std.math;
const zmath = jok.zmath;

/// Map `v` from [from, to] to [map_from, map_to]
pub inline fn mapf(v: f32, from: f32, to: f32, map_from: f32, map_to: f32) f32 {
    if (math.approxEqAbs(f32, from, to, math.epsilon(f32))) return from;
    const v1 = math.clamp(v, from, to);
    return map_from + (map_to - map_from) * (v1 - from) / (to - from);
}

/// Convert radian to degree
pub inline fn radianToDegree(r: f32) f32 {
    return r * 180.0 / math.pi;
}

/// Convert degree to radian
pub inline fn degreeToRadian(d: f32) f32 {
    return d * math.pi / 180.0;
}

/// Get min and max of 3 value
pub inline fn minAndMax(_x: anytype, _y: anytype, _z: anytype) std.meta.Tuple(&[_]type{
    @TypeOf(_x, _y, _z),
    @TypeOf(_x, _y, _z),
}) {
    var x = _x;
    var y = _y;
    var z = _z;
    if (x > y) std.mem.swap(@TypeOf(_x, _y, _z), &x, &y);
    if (x > z) std.mem.swap(@TypeOf(_x, _y, _z), &x, &z);
    if (y > z) std.mem.swap(@TypeOf(_x, _y, _z), &y, &z);
    return .{ x, z };
}

/// Test whether a point is in triangle
/// Using Barycentric Technique, checkout link https://blackpawn.com/texts/pointinpoly
pub inline fn isPointInTriangle(tri: [3][2]f32, point: [2]f32) bool {
    @setEvalBranchQuota(10000);

    const v0 = zmath.f32x4(
        tri[2][0] - tri[0][0],
        tri[2][1] - tri[0][1],
        0,
        0,
    );
    const v1 = zmath.f32x4(
        tri[1][0] - tri[0][0],
        tri[1][1] - tri[0][1],
        0,
        0,
    );
    const v2 = zmath.f32x4(
        point[0] - tri[0][0],
        point[1] - tri[0][1],
        0,
        0,
    );
    const dot00 = zmath.dot2(v0, v0)[0];
    const dot01 = zmath.dot2(v0, v1)[0];
    const dot02 = zmath.dot2(v0, v2)[0];
    const dot11 = zmath.dot2(v1, v1)[0];
    const dot12 = zmath.dot2(v1, v2)[0];
    const inv_denom = 1.0 / (dot00 * dot11 - dot01 * dot01);
    const u = (dot11 * dot02 - dot01 * dot12) * inv_denom;
    const v = (dot00 * dot12 - dot01 * dot02) * inv_denom;
    return u >= 0 and v >= 0 and (u + v < 1);
}
