const std = @import("std");
const sdl = @import("sdl");
const jok = @import("../jok.zig");
const assert = std.debug.assert;
const math = std.math;
const zmath = jok.zmath;

/// Linearly map `v` from [from, to] to [map_from, map_to]
pub inline fn linearMap(_v: f32, from: f32, to: f32, map_from: f32, map_to: f32) f32 {
    const v = if (from < to) math.clamp(_v, from, to) else math.clamp(_v, to, from);
    return map_from + (map_to - map_from) * (v - from) / (to - from);
}

/// Smoothly map from [from, to] to [map_from, map_to], checkout link https://en.wikipedia.org/wiki/Smoothstep
pub inline fn smoothMap(_v: f32, from: f32, to: f32, map_from: f32, map_to: f32) f32 {
    const v = if (from < to) math.clamp(_v, from, to) else math.clamp(_v, to, from);
    var step = (v - from) / (to - from);
    step = step * step * (3 - 2 * step); // smooth to [0, 1], using equation: 3x^2 - 2x^3
    return map_from + (map_to - map_from) * step;
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

/// Calculate Barycentric coordinate, checkout link https://blackpawn.com/texts/pointinpoly
pub inline fn barycentricCoord(tri: [3][2]f32, point: [2]f32) [3]f32 {
    const v0 = zmath.f32x4(tri[2][0] - tri[0][0], tri[2][1] - tri[0][1], 0, 0);
    const v1 = zmath.f32x4(tri[1][0] - tri[0][0], tri[1][1] - tri[0][1], 0, 0);
    const v2 = zmath.f32x4(point[0] - tri[0][0], point[1] - tri[0][1], 0, 0);
    const dot00 = zmath.dot2(v0, v0)[0];
    const dot01 = zmath.dot2(v0, v1)[0];
    const dot02 = zmath.dot2(v0, v2)[0];
    const dot11 = zmath.dot2(v1, v1)[0];
    const dot12 = zmath.dot2(v1, v2)[0];
    const inv_denom = 1.0 / (dot00 * dot11 - dot01 * dot01);
    const u = (dot11 * dot02 - dot01 * dot12) * inv_denom;
    const v = (dot00 * dot12 - dot01 * dot02) * inv_denom;
    return .{ u, v, 1 - u - v };
}

/// Test whether a point is in triangle
pub inline fn isPointInTriangle(tri: [3][2]f32, point: [2]f32) bool {
    const p = barycentricCoord(tri, point);
    return p[0] >= 0 and p[1] >= 0 and p[2] >= 0;
}

/// Test whether two triangles intersect
pub inline fn areTrianglesIntersect(tri0: [3][2]f32, tri1: [3][2]f32) bool {
    const S = struct {
        const Range = std.meta.Tuple(&[_]type{ f32, f32 });

        inline fn getRange(v: zmath.Vec, tri: [3][2]f32) Range {
            const tm = zmath.loadMat34(&[_]f32{
                tri[0][0], tri[1][0], tri[2][0], 0,
                tri[0][1], tri[1][1], tri[2][1], 0,
                0,         0,         0,         0,
            });
            const xs = zmath.mul(v, tm);
            return minAndMax(xs[0], xs[1], xs[2]);
        }

        inline fn areRangesApart(r0: Range, r1: Range) bool {
            return r0[0] >= r1[1] or r0[1] <= r1[0];
        }
    };

    const v0 = zmath.f32x4(tri0[0][1] - tri0[1][1], tri0[1][0] - tri0[0][0], 0, 0);
    const v1 = zmath.f32x4(tri0[0][1] - tri0[2][1], tri0[2][0] - tri0[0][0], 0, 0);
    const v2 = zmath.f32x4(tri0[2][1] - tri0[1][1], tri0[1][0] - tri0[2][0], 0, 0);
    const v3 = zmath.f32x4(tri1[0][1] - tri1[1][1], tri1[1][0] - tri1[0][0], 0, 0);
    const v4 = zmath.f32x4(tri1[0][1] - tri1[2][1], tri1[2][0] - tri1[0][0], 0, 0);
    const v5 = zmath.f32x4(tri1[2][1] - tri1[1][1], tri1[1][0] - tri1[2][0], 0, 0);
    for ([_]zmath.Vec{ v0, v1, v2, v3, v4, v5 }) |v| {
        const r0 = S.getRange(v, tri0);
        const r1 = S.getRange(v, tri1);
        if (S.areRangesApart(r0, r1)) {
            return false;
        }
    }
    return true;
}

/// Get area of triangle
pub inline fn triangleArea(tri: [3][2]f32) f32 {
    const x1 = tri[0][0];
    const y1 = tri[0][1];
    const x2 = tri[1][0];
    const y2 = tri[1][1];
    const x3 = tri[2][0];
    const y3 = tri[2][1];
    return @fabs(x1 * y2 + x2 * y3 + x3 * y1 - x2 * y1 - x3 * y2 - x1 * y3) / 2;
}

/// Get bouding rect of triangle
pub inline fn triangleRect(tri: [3][2]f32) sdl.RectangleF {
    const min_max_x = minAndMax(tri[0][0], tri[1][0], tri[2][0]);
    const min_max_y = minAndMax(tri[0][1], tri[1][1], tri[2][1]);
    return .{
        .x = min_max_x[0],
        .y = min_max_y[0],
        .width = min_max_x[1] - min_max_x[0],
        .height = min_max_y[1] - min_max_y[0],
    };
}

/// Get bouding rect of points
pub inline fn getBoundingRect(ps: []sdl.PointF) sdl.RectangleF {
    var min_x = math.f32_max;
    var min_y = math.f32_max;
    var max_x = math.f32_min;
    var max_y = math.f32_min;
    for (ps) |p| {
        if (min_x > p.x) min_x = p.x;
        if (min_y > p.y) min_y = p.y;
        if (max_x < p.x) max_x = p.x;
        if (max_y < p.y) max_y = p.y;
    }
    return .{
        .x = min_x,
        .y = min_y,
        .width = max_x - min_x,
        .height = max_y - min_y,
    };
}
