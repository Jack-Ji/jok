const std = @import("std");
const jok = @import("../jok.zig");
const assert = std.debug.assert;
const math = std.math;
const minAndMax = @import("math.zig").minAndMax;
const zmath = jok.zmath;

/// Calculate Barycentric coordinate, checkout link https://blackpawn.com/texts/pointinpoly
pub inline fn barycentricCoord(tri: [3]jok.Point, point: jok.Point) [3]f32 {
    const v0 = zmath.f32x4(tri[2].x - tri[0].x, tri[2].y - tri[0].y, 0, 0);
    const v1 = zmath.f32x4(tri[1].x - tri[0].x, tri[1].y - tri[0].y, 0, 0);
    const v2 = zmath.f32x4(point.x - tri[0].x, point.y - tri[0].y, 0, 0);
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
pub inline fn isPointInTriangle(tri: [3]jok.Point, point: jok.Point) bool {
    const p = barycentricCoord(tri, point);
    return p[0] >= 0 and p[1] >= 0 and p[2] >= 0;
}

/// Test whether point is in circle
pub inline fn isPointInCircle(center: jok.Point, radius: f32, point: jok.Point) bool {
    const v: @Vector(2, f32) = .{ center.x - point.x, center.y - point.y };
    return @reduce(.Add, v * v) < radius * radius;
}

/// Test whether point is in rectangle
pub inline fn isPointInRectangle(rect: jok.Rectangle, point: jok.Point) bool {
    const right_bottom = jok.Point{
        .x = rect.x + rect.width,
        .y = rect.y + rect.height,
    };
    return point.x > rect.x and rect.x < right_bottom.x and
        point.y > rect.y and rect.y < right_bottom.y;
}

/// Test whether triangle tr0 is contained by tr1
pub inline fn isTriangleInTriangle(tri0: [3]jok.Point, tri1: [3]jok.Point) bool {
    return isPointInTriangle(tri1, tri0[0]) and
        isPointInTriangle(tri1, tri0[1]) and
        isPointInTriangle(tri1, tri0[2]);
}

/// Test whether two triangles intersect
pub inline fn areTrianglesIntersect(tri0: [3]jok.Point, tri1: [3]jok.Point) bool {
    const S = struct {
        const Range = std.meta.Tuple(&[_]type{ f32, f32 });

        inline fn getRange(v: zmath.Vec, tri: [3]jok.Point) Range {
            const tm = zmath.loadMat34(&[_]f32{
                tri[0].x, tri[1].x, tri[2].x, 0,
                tri[0].y, tri[1].y, tri[2].y, 0,
                0,        0,        0,        0,
            });
            const xs = zmath.mul(v, tm);
            return minAndMax(xs[0], xs[1], xs[2]);
        }

        inline fn areRangesApart(r0: Range, r1: Range) bool {
            return r0[0] >= r1[1] or r0[1] <= r1[0];
        }
    };

    const v0 = zmath.f32x4(tri0[0].y - tri0[1].y, tri0[1].x - tri0[0].x, 0, 0);
    const v1 = zmath.f32x4(tri0[0].y - tri0[2].y, tri0[2].x - tri0[0].x, 0, 0);
    const v2 = zmath.f32x4(tri0[2].y - tri0[1].y, tri0[1].x - tri0[2].x, 0, 0);
    const v3 = zmath.f32x4(tri1[0].y - tri1[1].y, tri1[1].x - tri1[0].x, 0, 0);
    const v4 = zmath.f32x4(tri1[0].y - tri1[2].y, tri1[2].x - tri1[0].x, 0, 0);
    const v5 = zmath.f32x4(tri1[2].y - tri1[1].y, tri1[1].x - tri1[2].x, 0, 0);
    for ([_]zmath.Vec{ v0, v1, v2, v3, v4, v5 }) |v| {
        const r0 = S.getRange(v, tri0);
        const r1 = S.getRange(v, tri1);
        if (S.areRangesApart(r0, r1)) {
            return false;
        }
    }
    return true;
}

/// Test whether two line intersect
pub inline fn areLinesIntersect(line0: [2]jok.Point, line1: [2]jok.Point) bool {
    if (@max(line0[0].x, line0[1].x) < @min(line1[0].x, line1[1].x) or
        @min(line0[0].x, line0[1].x) > @max(line1[0].x, line1[1].x) or
        @max(line0[0].y, line0[1].y) < @min(line1[0].y, line1[1].y) or
        @min(line0[0].y, line0[1].y) > @max(line1[0].y, line1[1].y))
    {
        return false;
    }

    const v0 = zmath.f32x4(line0[1].x - line0[0].x, line0[1].y - line0[0].y, 0, 0);
    const v0_v1_0 = zmath.f32x4(line1[1].x - line0[0].x, line1[1].y - line0[0].y, 0, 0);
    const v0_v1_1 = zmath.f32x4(line1[0].x - line0[0].x, line1[0].y - line0[0].y, 0, 0);
    const v1 = zmath.f32x4(line1[1].x - line1[0].x, line1[1].y - line1[0].y, 0, 0);
    const v1_v0_0 = zmath.f32x4(line0[1].x - line1[0].x, line0[1].y - line1[0].y, 0, 0);
    const v1_v0_1 = zmath.f32x4(line0[0].x - line1[0].x, line0[0].y - line1[0].y, 0, 0);
    return zmath.dot3(zmath.cross3(v0, v0_v1_0), zmath.cross3(v0, v0_v1_1))[0] <= 0 and
        zmath.dot3(zmath.cross3(v1, v1_v0_0), zmath.cross3(v1, v1_v0_1))[0] <= 0;
}

/// Test whether two rectangle intersect
/// Moved from SDL2 to here for convernience
pub inline fn areRectanglesIntersect(r1: jok.Rectangle, r2: jok.Rectangle) bool {
    return r1.hasIntersection(r2);
}

/// Test whether line and rectangle intersect
/// Moved from SDL2 to here for convernience
pub inline fn areLineAndRectangleIntersect(r1: jok.Rectangle, line: []jok.Point) bool {
    assert(line.len == 2);
    return r1.intersectRectAndLine(&line[0].x, &line[0].y, &line[1].x, &line[1].y);
}

/// Get area of triangle
pub inline fn triangleArea(tri: [3]jok.Point) f32 {
    const x1 = tri[0].x;
    const y1 = tri[0].y;
    const x2 = tri[1].x;
    const y2 = tri[1].y;
    const x3 = tri[2].x;
    const y3 = tri[2].y;
    return @abs(x1 * y2 + x2 * y3 + x3 * y1 - x2 * y1 - x3 * y2 - x1 * y3) / 2;
}

/// Get bounding rect of triangle
pub inline fn triangleRect(tri: [3]jok.Point) jok.Rectangle {
    const min_max_x = minAndMax(tri[0].x, tri[1].x, tri[2].x);
    const min_max_y = minAndMax(tri[0].y, tri[1].y, tri[2].y);
    return .{
        .x = min_max_x[0],
        .y = min_max_y[0],
        .width = min_max_x[1] - min_max_x[0],
        .height = min_max_y[1] - min_max_y[0],
    };
}

/// Get bounding rect of points
pub inline fn getBoundingRect(ps: []jok.Point) jok.Rectangle {
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
