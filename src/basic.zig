//! Basic geometric types and color utilities for the jok game engine.
//!
//! This module provides fundamental 2D geometric primitives (Point, Size, Rectangle, Circle, etc.)
//! and color types (Color, ColorF) used throughout the engine. All types are designed for
//! efficient graphics operations and include common geometric operations like intersection
//! testing, containment checks, and transformations.
//!
//! Key types:
//! - Point: 2D floating-point coordinate
//! - Size: 2D unsigned integer dimensions
//! - Region: Integer-based rectangular area
//! - Rectangle: Floating-point rectangular area
//! - Circle: Circle defined by center and radius
//! - Ellipse: Ellipse defined by center and radii
//! - Triangle: Triangle defined by three points
//! - Color: 8-bit RGBA color
//! - ColorF: Floating-point RGBA color
//! - Vertex: Vertex with position, color, and texture coordinates

const std = @import("std");
const assert = std.debug.assert;
const math = std.math;
const jok = @import("jok.zig");
const Vector = jok.j2d.Vector;
const twoFloats = jok.utils.twoFloats;
const sdl = jok.vendor.sdl;
const zmath = jok.vendor.zmath;
const minAndMax = jok.utils.math.minAndMax;

/// 2D point with floating-point coordinates.
/// Used for positions, offsets, and 2D vectors in screen space.
pub const Point = extern struct {
    /// Origin point (0, 0)
    pub const origin = Point{ .x = 0, .y = 0 };
    /// Unit point (1, 1)
    pub const unit = Point{ .x = 1, .y = 1 };
    /// Up direction (0, -1) - negative Y is up in screen coordinates
    pub const up = Point{ .x = 0, .y = -1 };
    /// Down direction (0, 1)
    pub const down = Point{ .x = 0, .y = 1 };
    /// Left direction (-1, 0)
    pub const left = Point{ .x = -1, .y = 0 };
    /// Right direction (1, 0)
    pub const right = Point{ .x = 1, .y = 0 };
    /// Top-left anchor point (0, 0) - for normalized coordinates
    pub const anchor_top_left = Point{ .x = 0, .y = 0 };
    /// Top-right anchor point (1, 0) - for normalized coordinates
    pub const anchor_top_right = Point{ .x = 1, .y = 0 };
    /// Bottom-left anchor point (0, 1) - for normalized coordinates
    pub const anchor_bottom_left = Point{ .x = 0, .y = 1 };
    /// Bottom-right anchor point (1, 1) - for normalized coordinates
    pub const anchor_bottom_right = Point{ .x = 1, .y = 1 };
    /// Center anchor point (0.5, 0.5) - for normalized coordinates
    pub const anchor_center = Point{ .x = 0.5, .y = 0.5 };

    x: f32,
    y: f32,

    /// Convert point to a 2-element array [x, y]
    pub inline fn toArray(p: Point) [2]f32 {
        return .{ p.x, p.y };
    }

    /// Convert point to a j2d.Vector
    pub inline fn toVector(p: Point) Vector {
        return Vector.new(p.x, p.y);
    }

    /// Convert point to Size by rounding coordinates to integers
    pub inline fn toSize(p: Point) Size {
        return .{
            .width = @intFromFloat(@round(p.x)),
            .height = @intFromFloat(@round(p.y)),
        };
    }

    /// Calculate angle in radians from origin to this point
    pub inline fn angle(p: Point) f32 {
        return math.atan2(p.y, p.x);
    }

    /// Calculate angle in degrees from origin to this point
    pub inline fn angleDegree(p: Point) f32 {
        return math.radiansToDegrees(math.atan2(p.y, p.x));
    }

    /// Add two values to this point. Accepts Point, tuple, or array.
    pub inline fn add(p0: Point, two_floats: anytype) Point {
        const x, const y = twoFloats(two_floats);
        return .{
            .x = p0.x + x,
            .y = p0.y + y,
        };
    }

    /// Subtract two values from this point. Accepts Point, tuple, or array.
    pub inline fn sub(p0: Point, two_floats: anytype) Point {
        const x, const y = twoFloats(two_floats);
        return .{
            .x = p0.x - x,
            .y = p0.y - y,
        };
    }

    /// Multiply this point component-wise. Accepts Point, tuple, or array.
    pub inline fn mul(p0: Point, two_floats: anytype) Point {
        const x, const y = twoFloats(two_floats);
        return .{
            .x = p0.x * x,
            .y = p0.y * y,
        };
    }

    /// Scale this point uniformly by a scalar value
    pub inline fn scale(p0: Point, s: f32) Point {
        return .{
            .x = p0.x * s,
            .y = p0.y * s,
        };
    }

    /// Check if two points are approximately equal (within tolerance of 0.000001)
    pub inline fn isSame(p0: Point, p1: Point) bool {
        const tolerance = 0.000001;
        return std.math.approxEqAbs(f32, p0.x, p1.x, tolerance) and
            std.math.approxEqAbs(f32, p0.y, p1.y, tolerance);
    }

    /// Calculate squared distance between two points (faster than distance)
    pub inline fn distance2(p0: Point, p1: Point) f32 {
        return (p0.x - p1.x) * (p0.x - p1.x) + (p0.y - p1.y) * (p0.y - p1.y);
    }

    /// Calculate Euclidean distance between two points
    pub inline fn distance(p0: Point, p1: Point) f32 {
        return @sqrt(distance2(p0, p1));
    }
};

/// 2D size with unsigned integer dimensions.
/// Used for pixel-based dimensions like window size, texture size, etc.
pub const Size = extern struct {
    width: u32,
    height: u32,

    /// Convert size to Point with floating-point coordinates
    pub inline fn toPoint(s: Size) Point {
        return .{ .x = @floatFromInt(s.width), .y = @floatFromInt(s.height) };
    }

    /// Convert size to Region at specified position
    pub inline fn toRegion(s: Size, x: u32, y: u32) jok.Region {
        return .{
            .x = x,
            .y = y,
            .width = s.width,
            .height = s.height,
        };
    }

    /// Convert size to Rectangle at specified position
    pub inline fn toRect(s: Size, pos: jok.Point) jok.Rectangle {
        return .{
            .x = pos.x,
            .y = pos.y,
            .width = @floatFromInt(s.width),
            .height = @floatFromInt(s.height),
        };
    }

    /// Get width as floating-point value
    pub inline fn getWidthFloat(s: Size) f32 {
        return @as(f32, @floatFromInt(s.width));
    }

    /// Get height as floating-point value
    pub inline fn getHeightFloat(s: Size) f32 {
        return @as(f32, @floatFromInt(s.height));
    }

    /// Check if two sizes are exactly equal
    pub inline fn isSame(s0: Size, s1: Size) bool {
        return s0.width == s1.width and s0.height == s1.height;
    }

    /// Calculate area (width * height)
    pub inline fn area(s: Size) u32 {
        return s.width * s.height;
    }
};

/// Integer-based rectangular region.
/// Used for pixel-perfect operations like texture regions, viewport regions, etc.
pub const Region = extern struct {
    x: u32,
    y: u32,
    width: u32,
    height: u32,

    /// Convert region to Rectangle with floating-point coordinates
    pub inline fn toRect(r: Region) Rectangle {
        return .{
            .x = @floatFromInt(r.x),
            .y = @floatFromInt(r.y),
            .width = @floatFromInt(r.width),
            .height = @floatFromInt(r.height),
        };
    }

    /// Check if two regions are exactly equal
    pub inline fn isSame(r0: Region, r1: Region) bool {
        return r0.x == r1.x and r0.y == r1.y and
            r0.width == r1.width and r0.height == r1.height;
    }

    /// Calculate area (width * height)
    pub inline fn area(r: Region) u32 {
        return r.width * r.height;
    }
};

/// Floating-point rectangular area.
/// Used for general-purpose rectangular regions with sub-pixel precision.
/// Supports intersection testing, containment checks, and transformations.
pub const Rectangle = extern struct {
    x: f32,
    y: f32,
    width: f32,
    height: f32,

    /// Convert rectangle to Region by rounding coordinates to integers
    pub inline fn toRegion(r: Rectangle) Region {
        return .{
            .x = @intFromFloat(@round(r.x)),
            .y = @intFromFloat(@round(r.y)),
            .width = @intFromFloat(@round(r.width)),
            .height = @intFromFloat(@round(r.height)),
        };
    }

    /// Get position (top-left corner) as Point
    pub inline fn getPos(r: Rectangle) jok.Point {
        return .{ .x = r.x, .y = r.y };
    }

    /// Get size as Point
    pub inline fn getSize(r: Rectangle) jok.Point {
        return .{ .x = r.width, .y = r.height };
    }

    /// Get top-left corner position
    pub inline fn getTopLeft(r: Rectangle) jok.Point {
        return .{ .x = r.x, .y = r.y };
    }

    /// Get top-right corner position
    pub inline fn getTopRight(r: Rectangle) jok.Point {
        return .{ .x = r.x + r.width, .y = r.y };
    }

    /// Get bottom-left corner position
    pub inline fn getBottomLeft(r: Rectangle) jok.Point {
        return .{ .x = r.x, .y = r.y + r.height };
    }

    /// Get bottom-right corner position
    pub inline fn getBottomRight(r: Rectangle) jok.Point {
        return .{ .x = r.x + r.width, .y = r.y + r.height };
    }

    /// Get center position
    pub inline fn getCenter(r: Rectangle) jok.Point {
        return .{ .x = r.x + r.width * 0.5, .y = r.y + r.height * 0.5 };
    }

    /// Translate rectangle by offset. Accepts Point, tuple, or array.
    pub inline fn translate(r: Rectangle, two_floats: anytype) Rectangle {
        const x, const y = twoFloats(two_floats);
        return .{
            .x = r.x + x,
            .y = r.y + y,
            .width = r.width,
            .height = r.height,
        };
    }

    /// Scale rectangle size. Accepts Point, tuple, or array.
    pub inline fn scale(r: Rectangle, two_floats: anytype) Rectangle {
        const x, const y = twoFloats(two_floats);
        return .{
            .x = r.x,
            .y = r.y,
            .width = r.width * x,
            .height = r.height * y,
        };
    }

    /// Create a padded rectangle (expands in all directions by padding amount)
    pub inline fn padded(r: Rectangle, padding: f32) Rectangle {
        return .{
            .x = r.x - padding,
            .y = r.y - padding,
            .width = r.width + 2 * padding,
            .height = r.height + 2 * padding,
        };
    }

    /// Check if two rectangles are approximately equal (within tolerance of 0.000001)
    pub inline fn isSame(r0: Rectangle, r1: Rectangle) bool {
        const tolerance = 0.000001;
        return std.math.approxEqAbs(f32, r0.x, r1.x, tolerance) and
            std.math.approxEqAbs(f32, r0.y, r1.y, tolerance) and
            std.math.approxEqAbs(f32, r0.width, r1.width, tolerance) and
            std.math.approxEqAbs(f32, r0.height, r1.height, tolerance);
    }

    /// Calculate area (width * height)
    pub inline fn area(r: Rectangle) f32 {
        return r.width * r.height;
    }

    /// Check if this rectangle intersects with another rectangle
    pub inline fn hasIntersection(r: Rectangle, b: Rectangle) bool {
        return sdl.SDL_HasRectIntersectionFloat(@ptrCast(&r), @ptrCast(&b));
    }

    /// Calculate intersection of two rectangles. Returns null if no intersection.
    pub inline fn intersectRect(r: Rectangle, b: Rectangle) ?Rectangle {
        var result: Rectangle = undefined;
        if (sdl.SDL_GetRectIntersectionFloat(@ptrCast(&r), @ptrCast(&b), @ptrCast(&result))) {
            return result;
        }
        return null;
    }

    /// Calculate intersection of rectangle with a line segment.
    /// Returns clipped line endpoints if intersection exists, null otherwise.
    pub inline fn intersectLine(r: Rectangle, _p0: Point, _p1: Point) ?@Tuple(&.{ Point, Point }) {
        var p0: Point = _p0;
        var p1: Point = _p1;
        if (sdl.SDL_GetRectAndLineIntersectionFloat(@ptrCast(&r), &p0.x, &p0.y, &p1.x, &p1.y)) {
            return .{ p0, p1 };
        }
        return null;
    }

    /// Check if this rectangle intersects with a circle
    pub inline fn intersectCircle(r: Rectangle, c: Circle) bool {
        return c.intersectRect(r);
    }

    /// Check if this rectangle intersects with a triangle
    pub inline fn intersectTriangle(r: Rectangle, tri: Triangle) bool {
        return tri.intersectRect(r);
    }

    /// Check if rectangle contains a point
    pub inline fn containsPoint(r: Rectangle, p: Point) bool {
        return p.x >= r.x and p.x < r.x + r.width and
            p.y >= r.y and p.y < r.y + r.height;
    }

    /// Check if rectangle fully contains another rectangle
    pub inline fn containsRect(r: Rectangle, b: Rectangle) bool {
        return b.x >= r.x and b.x + b.width <= r.x + r.width and
            b.y >= r.y and b.y + b.height <= r.y + r.height;
    }

    /// Check if rectangle contains a line segment (both endpoints)
    pub inline fn containsLine(r: Rectangle, p0: Point, p1: Point) bool {
        return r.containsPoint(p0) and r.containsPoint(p1);
    }

    /// Check if rectangle fully contains a circle
    pub inline fn containsCircle(r: Rectangle, c: Circle) bool {
        return r.containsRect(.{
            .x = c.center.x - c.radius,
            .y = c.center.y - c.radius,
            .width = c.radius * 2,
            .height = c.radius * 2,
        });
    }

    /// Check if rectangle fully contains a triangle
    pub inline fn containsTriangle(r: Rectangle, tri: Triangle) bool {
        return r.containsPoint(tri.p0) and r.containsPoint(tri.p1) and r.containsPoint(tri.p2);
    }
};

/// Circle defined by center point and radius.
/// Supports intersection and containment testing with other geometric primitives.
pub const Circle = extern struct {
    center: Point = .origin,
    radius: f32 = 1,

    /// Translate circle by offset. Accepts Point, tuple, or array.
    pub inline fn translate(c: Circle, two_floats: anytype) Circle {
        return .{
            .center = c.center.add(two_floats),
            .radius = c.radius,
        };
    }

    /// Check if circle contains a point
    pub inline fn containsPoint(c: Circle, p: Point) bool {
        const v: @Vector(2, f32) = .{ c.center.x - p.x, c.center.y - p.y };
        return @reduce(.Add, v * v) < c.radius * c.radius;
    }

    /// Check if this circle intersects with another circle
    pub inline fn intersectCircle(c0: Circle, c1: Circle) bool {
        const r = c0.radius + c1.radius;
        return c0.center.distance2(c1.center) < r * r;
    }

    /// Check if circle intersects with a rectangle
    pub inline fn intersectRect(c: Circle, r: Rectangle) bool {
        const cx1 = c.center.x - c.radius;
        const cx2 = c.center.x + c.radius;
        const cy1 = c.center.y - c.radius;
        const cy2 = c.center.y + c.radius;
        const rx1 = r.x;
        const rx2 = r.x + r.width;
        const ry1 = r.y;
        const ry2 = r.y + r.height;
        if (cx2 <= rx1 or cx1 >= rx2) return false;
        if (cy2 <= ry1 or cy1 >= ry2) return false;
        return true;
    }

    /// Get the bounding rectangle that fully contains this circle
    pub inline fn getBoundingRect(c: Circle) jok.Rectangle {
        return .{
            .x = c.center.x - c.radius,
            .y = c.center.y - c.radius,
            .width = c.radius * 2,
            .height = c.radius * 2,
        };
    }
};

/// Ellipse defined by center point and radii (x and y).
/// Uses focal point method for containment testing.
pub const Ellipse = struct {
    center: Point = .origin,
    /// Radii in x and y directions
    radius: Point = .unit,

    /// Translate ellipse by offset. Accepts Point, tuple, or array.
    pub inline fn translate(e: Ellipse, two_floats: anytype) Ellipse {
        return .{
            .center = e.center.add(two_floats),
            .radius = e.radius,
        };
    }

    /// Get squared focal radius (distance from center to focus point)
    pub inline fn getFocalRadius2(e: Ellipse) f32 {
        return if (e.radius.x > e.radius.y)
            e.radius.x * e.radius.x - e.radius.y * e.radius.y
        else
            e.radius.y * e.radius.y - e.radius.x * e.radius.x;
    }

    /// Get focal radius (distance from center to focus point)
    pub inline fn getFocalRadius(e: Ellipse) f32 {
        return @sqrt(e.getFocalRadius2());
    }

    /// Check if ellipse contains a point using focal point method
    pub inline fn containsPoint(e: Ellipse, p: Point) bool {
        const fr = e.getFocalRadius();
        var d1: f32 = undefined;
        var d2: f32 = undefined;
        var a: f32 = undefined;
        if (e.radius.x > e.radius.y) {
            d1 = @sqrt((p.x - fr) * (p.x - fr) + p.y * p.y);
            d2 = @sqrt((p.x + fr) * (p.x + fr) + p.y * p.y);
            a = e.radius.x;
        } else {
            d1 = @sqrt((p.y - fr) * (p.y - fr) + p.x * p.x);
            d2 = @sqrt((p.y + fr) * (p.y + fr) + p.x * p.x);
            a = e.radius.y;
        }
        return d1 + d2 <= 2 * a;
    }
};

/// Triangle defined by three points.
/// Supports area calculation, bounding box, barycentric coordinates, and intersection testing.
pub const Triangle = extern struct {
    p0: Point,
    p1: Point,
    p2: Point,

    /// Translate triangle by offset. Accepts Point, tuple, or array.
    pub inline fn translate(tri: Triangle, two_floats: anytype) Triangle {
        return .{
            .p0 = tri.p0.add(two_floats),
            .p1 = tri.p1.add(two_floats),
            .p2 = tri.p2.add(two_floats),
        };
    }

    /// Calculate triangle area using cross product formula
    pub inline fn area(tri: Triangle) f32 {
        const x1 = tri.p0.x;
        const y1 = tri.p0.y;
        const x2 = tri.p1.x;
        const y2 = tri.p1.y;
        const x3 = tri.p2.x;
        const y3 = tri.p2.y;
        return @abs(x1 * y2 + x2 * y3 + x3 * y1 - x2 * y1 - x3 * y2 - x1 * y3) / 2;
    }

    /// Get axis-aligned bounding rectangle
    pub inline fn boundingRect(tri: Triangle) Rectangle {
        const min_max_x = minAndMax(tri.p0.x, tri.p1.x, tri.p2.x);
        const min_max_y = minAndMax(tri.p0.y, tri.p1.y, tri.p2.y);
        return .{
            .x = min_max_x[0],
            .y = min_max_y[0],
            .width = min_max_x[1] - min_max_x[0],
            .height = min_max_y[1] - min_max_y[0],
        };
    }

    /// Calculate barycentric coordinates for a point relative to this triangle.
    /// Returns [u, v, w] where u+v+w=1. Point is inside triangle if all values >= 0.
    /// See: https://blackpawn.com/texts/pointinpoly
    pub inline fn barycentricCoord(tri: Triangle, point: Point) [3]f32 {
        const v0 = zmath.f32x4(tri.p2.x - tri.p0.x, tri.p2.y - tri.p0.y, 0, 0);
        const v1 = zmath.f32x4(tri.p1.x - tri.p0.x, tri.p1.y - tri.p0.y, 0, 0);
        const v2 = zmath.f32x4(point.x - tri.p0.x, point.y - tri.p0.y, 0, 0);
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

    /// Test whether a point is in triangle using barycentric coordinates
    pub inline fn containsPoint(tri: Triangle, point: Point) bool {
        const p = tri.barycentricCoord(point);
        return p[0] >= 0 and p[1] >= 0 and p[2] >= 0;
    }

    /// Check if this triangle fully contains another triangle
    pub inline fn containsTriangle(tri0: Triangle, tri1: Triangle) bool {
        return tri0.containsPoint(tri1.p0) and
            tri0.containsPoint(tri1.p1) and
            tri0.containsPoint(tri1.p2);
    }

    /// Check if this triangle intersects with another triangle using Separating Axis Theorem (SAT)
    pub inline fn intersectTriangle(tri0: Triangle, tri1: Triangle) bool {
        const S = struct {
            const Range = @Tuple(&[_]type{ f32, f32 });

            inline fn getRange(v: zmath.Vec, tri: Triangle) Range {
                const tm = zmath.loadMat34(&[_]f32{
                    tri.p0.x, tri.p1.x, tri.p2.x, 0,
                    tri.p0.y, tri.p1.y, tri.p2.y, 0,
                    0,        0,        0,        0,
                });
                const xs = zmath.mul(v, tm);
                return minAndMax(xs[0], xs[1], xs[2]);
            }

            inline fn areRangesApart(r0: Range, r1: Range) bool {
                return r0[0] >= r1[1] or r0[1] <= r1[0];
            }
        };

        const v0 = zmath.f32x4(tri0.p0.y - tri0.p1.y, tri0.p1.x - tri0.p0.x, 0, 0);
        const v1 = zmath.f32x4(tri0.p0.y - tri0.p2.y, tri0.p2.x - tri0.p0.x, 0, 0);
        const v2 = zmath.f32x4(tri0.p2.y - tri0.p1.y, tri0.p1.x - tri0.p2.x, 0, 0);
        const v3 = zmath.f32x4(tri1.p0.y - tri1.p1.y, tri1.p1.x - tri1.p0.x, 0, 0);
        const v4 = zmath.f32x4(tri1.p0.y - tri1.p2.y, tri1.p2.x - tri1.p0.x, 0, 0);
        const v5 = zmath.f32x4(tri1.p2.y - tri1.p1.y, tri1.p1.x - tri1.p2.x, 0, 0);
        for ([_]zmath.Vec{ v0, v1, v2, v3, v4, v5 }) |v| {
            const r0 = S.getRange(v, tri0);
            const r1 = S.getRange(v, tri1);
            if (S.areRangesApart(r0, r1)) {
                return false;
            }
        }
        return true;
    }

    /// Check if triangle intersects with a rectangle
    pub inline fn intersectRect(tri: Triangle, r: Rectangle) bool {
        if (r.containsPoint(tri.p0) or r.containsPoint(tri.p1) or r.containsPoint(tri.p2)) {
            return true;
        }
        if (tri.boundingRect().intersectRect(r) == null) {
            return false;
        }
        if (tri.intersectTriangle(
            .{ .p0 = r.getTopLeft(), .p1 = r.getTopRight(), .p2 = r.getBottomLeft() },
        ) or tri.intersectTriangle(
            .{ .p0 = r.getTopLeft(), .p1 = r.getTopRight(), .p2 = r.getBottomRight() },
        )) {
            return true;
        }
        return false;
    }
};

/// 8-bit RGBA color type.
/// Values range from 0-255 for each component. Alpha defaults to 255 (fully opaque).
/// Provides conversion to/from various color formats including HSL, RGBA32, and ColorF.
pub const Color = extern struct {
    /// Transparent black (0, 0, 0, 0)
    pub const none = rgba(0x00, 0x00, 0x00, 0x00);
    /// Opaque black
    pub const black = rgb(0x00, 0x00, 0x00);
    /// Opaque white
    pub const white = rgb(0xFF, 0xFF, 0xFF);
    /// Opaque red
    pub const red = rgb(0xFF, 0x00, 0x00);
    /// Opaque green
    pub const green = rgb(0x00, 0xFF, 0x00);
    /// Opaque blue
    pub const blue = rgb(0x00, 0x00, 0xFF);
    /// Opaque magenta
    pub const magenta = rgb(0xFF, 0x00, 0xFF);
    /// Opaque cyan
    pub const cyan = rgb(0x00, 0xFF, 0xFF);
    /// Opaque yellow
    pub const yellow = rgb(0xFF, 0xFF, 0x00);
    /// Opaque purple
    pub const purple = rgb(255, 128, 255);

    r: u8,
    g: u8,
    b: u8,
    a: u8 = 255,

    /// Create opaque color from RGB components (0-255)
    pub inline fn rgb(r: u8, g: u8, b: u8) Color {
        assert(r <= 255 and g <= 255 and b <= 255);
        return Color{ .r = r, .g = g, .b = b };
    }

    /// Create color from RGBA components (0-255)
    pub inline fn rgba(r: u8, g: u8, b: u8, a: u8) Color {
        assert(r <= 255 and g <= 255 and b <= 255 and a <= 255);
        return Color{ .r = r, .g = g, .b = b, .a = a };
    }

    /// Convert from floating-point color (0.0-1.0 range)
    pub inline fn fromColorF(_c: ColorF) Color {
        var c: @Vector(4, f32) = .{ _c.r, _c.g, _c.b, _c.a };
        const multiplier: @Vector(4, f32) = @splat(255.0);
        c *= multiplier;
        return Color{
            .r = @intFromFloat(c[0]),
            .g = @intFromFloat(c[1]),
            .b = @intFromFloat(c[2]),
            .a = @intFromFloat(c[3]),
        };
    }

    /// Convert to floating-point color (0.0-1.0 range)
    pub inline fn toColorF(c: Color) ColorF {
        return .{ .r = u8tof32[c.r], .g = u8tof32[c.g], .b = u8tof32[c.b], .a = u8tof32[c.a] };
    }

    inline fn getPixelFormatDetails() [*c]const sdl.SDL_PixelFormatDetails {
        const S = struct {
            var pixel_format: ?[*c]const sdl.SDL_PixelFormatDetails = null;
        };
        if (S.pixel_format == null) {
            S.pixel_format = sdl.SDL_GetPixelFormatDetails(sdl.SDL_PIXELFORMAT_RGBA32);
        }
        return S.pixel_format.?;
    }

    /// Convert from 32-bit RGBA integer format
    pub inline fn fromRGBA32(i: u32) Color {
        var c: Color = undefined;
        sdl.SDL_GetRGBA(i, getPixelFormatDetails(), null, &c.r, &c.g, &c.b, &c.a);
        return c;
    }

    /// Convert to 32-bit RGBA integer format
    pub inline fn toRGBA32(c: Color) u32 {
        return sdl.SDL_MapRGBA(getPixelFormatDetails(), null, c.r, c.g, c.b, c.a);
    }

    /// Convert from HSL color space. Input: [hue (0-1), saturation (0-1), lightness (0-1), alpha (0-1)]
    pub inline fn fromHSL(hsl: [4]f32) Color {
        var c = zmath.hslToRgb(zmath.loadArr4(hsl));
        const multiplier: @Vector(4, f32) = @splat(255.0);
        c *= multiplier;
        return .{
            .r = @intFromFloat(c[0]),
            .g = @intFromFloat(c[1]),
            .b = @intFromFloat(c[2]),
            .a = @intFromFloat(c[3]),
        };
    }

    /// Convert to HSL color space. Output: [hue (0-1), saturation (0-1), lightness (0-1), alpha (0-1)]
    pub inline fn toHSL(c: Color) [4]f32 {
        const hsl = zmath.rgbToHsl(
            zmath.f32x4(u8tof32[c.r], u8tof32[c.g], u8tof32[c.b], u8tof32[c.a]),
        );
        return zmath.vecToArr4(hsl);
    }

    /// Convert from ImGui's internal color format (ABGR packed as u32)
    pub inline fn fromInternalColor(c: u32) Color {
        return .{
            .r = @intCast(c & 0xff),
            .g = @intCast((c >> 8) & 0xff),
            .b = @intCast((c >> 16) & 0xff),
            .a = @intCast((c >> 24) & 0xff),
        };
    }

    /// Convert to ImGui's internal color format (ABGR packed as u32)
    pub inline fn toInternalColor(c: Color) u32 {
        return @as(u32, c.r) |
            (@as(u32, c.g) << 8) |
            (@as(u32, c.b) << 16) |
            (@as(u32, c.a) << 24);
    }

    /// Linear interpolation between two colors. t should be in range [0, 1].
    pub inline fn lerp(c0: Color, c1: Color, t: f32) Color {
        assert(t >= 0 and t <= 1);
        return c0.toColorF().lerp(c1.toColorF(), t).toColor();
    }

    /// Modulate (multiply) two colors component-wise
    pub inline fn mod(c0: Color, c1: Color) Color {
        return c0.toColorF().mod(c1.toColorF()).toColor();
    }

    /// Parse a hex string color literal.
    /// Allowed formats: RGB, RGBA, #RGB, #RGBA, RRGGBB, #RRGGBB, RRGGBBAA, #RRGGBBAA
    /// Examples: "F00" (red), "#FF0000" (red), "FF0000FF" (red with full alpha)
    pub fn parse(str: []const u8) !Color {
        switch (str.len) {
            // RGB
            3 => {
                const r = try std.fmt.parseInt(u8, str[0..1], 16);
                const g = try std.fmt.parseInt(u8, str[1..2], 16);
                const b = try std.fmt.parseInt(u8, str[2..3], 16);

                return rgb(
                    r | (r << 4),
                    g | (g << 4),
                    b | (b << 4),
                );
            },

            // #RGB, RGBA
            4 => {
                if (str[0] == '#')
                    return parse(str[1..]);

                const r = try std.fmt.parseInt(u8, str[0..1], 16);
                const g = try std.fmt.parseInt(u8, str[1..2], 16);
                const b = try std.fmt.parseInt(u8, str[2..3], 16);
                const a = try std.fmt.parseInt(u8, str[3..4], 16);

                // bit-expand the patters to a uniform range
                return rgba(
                    r | (r << 4),
                    g | (g << 4),
                    b | (b << 4),
                    a | (a << 4),
                );
            },

            // #RGBA
            5 => return parse(str[1..]),

            // RRGGBB
            6 => {
                const r = try std.fmt.parseInt(u8, str[0..2], 16);
                const g = try std.fmt.parseInt(u8, str[2..4], 16);
                const b = try std.fmt.parseInt(u8, str[4..6], 16);

                return rgb(r, g, b);
            },

            // #RRGGBB
            7 => return parse(str[1..]),

            // RRGGBBAA
            8 => {
                const r = try std.fmt.parseInt(u8, str[0..2], 16);
                const g = try std.fmt.parseInt(u8, str[2..4], 16);
                const b = try std.fmt.parseInt(u8, str[4..6], 16);
                const a = try std.fmt.parseInt(u8, str[6..8], 16);

                return rgba(r, g, b, a);
            },

            // #RRGGBBAA
            9 => return parse(str[1..]),

            else => return error.UnknownFormat,
        }
    }
};

const u8tof32: [256]f32 = calcU8Table();

fn calcU8Table() [256]f32 {
    var cs: [256]f32 = undefined;
    inline for (0..256) |i| {
        cs[i] = @as(f32, @floatFromInt(i)) / 255.0;
    }
    return cs;
}

/// Floating-point RGBA color type.
/// Values range from 0.0-1.0 for each component. Alpha defaults to 1.0 (fully opaque).
/// Provides higher precision than Color and is used internally for color calculations.
pub const ColorF = extern struct {
    /// Transparent black (0, 0, 0, 0)
    pub const none = rgba(0, 0, 0, 0);
    /// Opaque black
    pub const black = rgb(0, 0, 0);
    /// Opaque white
    pub const white = rgb(1, 1, 1);
    /// Opaque red
    pub const red = rgb(1, 0, 0);
    /// Opaque green
    pub const green = rgb(0, 1, 0);
    /// Opaque blue
    pub const blue = rgb(0, 0, 1);
    /// Opaque magenta
    pub const magenta = rgb(1, 0, 1);
    /// Opaque cyan
    pub const cyan = rgb(0, 1, 1);
    /// Opaque yellow
    pub const yellow = rgb(1, 1, 0);
    /// Opaque purple
    pub const purple = rgb(1, 0.5, 1);

    r: f32,
    g: f32,
    b: f32,
    a: f32 = 1,

    /// Create opaque color from RGB components (0.0-1.0)
    pub inline fn rgb(r: f32, g: f32, b: f32) ColorF {
        assert(r >= 0 and r <= 1);
        assert(g >= 0 and g <= 1);
        assert(b >= 0 and b <= 1);
        return ColorF{ .r = r, .g = g, .b = b };
    }

    /// Create color from RGBA components (0.0-1.0)
    pub inline fn rgba(r: f32, g: f32, b: f32, a: f32) ColorF {
        assert(r >= 0 and r <= 1);
        assert(g >= 0 and g <= 1);
        assert(b >= 0 and b <= 1);
        assert(a >= 0 and a <= 1);
        return ColorF{ .r = r, .g = g, .b = b, .a = a };
    }

    /// Convert from 8-bit color (0-255 range)
    pub inline fn fromColor(c: Color) ColorF {
        return ColorF{ .r = u8tof32[c.r], .g = u8tof32[c.g], .b = u8tof32[c.b], .a = u8tof32[c.a] };
    }

    /// Convert to 8-bit color (0-255 range)
    pub inline fn toColor(_c: ColorF) Color {
        var c: @Vector(4, f32) = .{ _c.r, _c.g, _c.b, _c.a };
        const multiplier: @Vector(4, f32) = @splat(255.0);
        c *= multiplier;
        return .{
            .r = @intFromFloat(c[0]),
            .g = @intFromFloat(c[1]),
            .b = @intFromFloat(c[2]),
            .a = @intFromFloat(c[3]),
        };
    }

    /// Convert from 32-bit RGBA integer format
    pub inline fn fromRGBA32(i: u32) ColorF {
        return fromColor(Color.fromRGBA32(i));
    }

    /// Convert to 32-bit RGBA integer format
    pub inline fn toRGBA32(c: ColorF) u32 {
        return c.toColor().toRGBA32();
    }

    /// Convert from HSL color space. Input: [hue (0-1), saturation (0-1), lightness (0-1), alpha (0-1)]
    pub inline fn fromHSL(hsl: [4]f32) ColorF {
        const _rgba = zmath.hslToRgb(zmath.loadArr4(hsl));
        return .{ .r = _rgba[0], .g = _rgba[1], .b = _rgba[2], .a = _rgba[3] };
    }

    /// Convert to HSL color space. Output: [hue (0-1), saturation (0-1), lightness (0-1), alpha (0-1)]
    pub inline fn toHSL(c: ColorF) [4]f32 {
        const hsl = zmath.rgbToHsl(zmath.f32x4(c.r, c.g, c.b, c.a));
        return zmath.vecToArr4(hsl);
    }

    /// Convert from ImGui's internal color format (ABGR packed as u32)
    pub inline fn fromInternalColor(c: u32) ColorF {
        return fromColor(Color.fromInternalColor(c));
    }

    /// Convert to ImGui's internal color format (ABGR packed as u32)
    pub inline fn toInternalColor(c: ColorF) u32 {
        return c.toColor().toInternalColor();
    }

    /// Linear interpolation between two colors. t should be in range [0, 1].
    pub inline fn lerp(_c0: ColorF, _c1: ColorF, t: f32) ColorF {
        assert(t >= 0 and t <= 1);
        const c0 = zmath.f32x4(_c0.r, _c0.g, _c0.b, _c0.a);
        const c1 = zmath.f32x4(_c1.r, _c1.g, _c1.b, _c1.a);
        const c = zmath.lerp(c0, c1, t);
        return .{ .r = c[0], .g = c[1], .b = c[2], .a = c[3] };
    }

    /// Modulate (multiply) two colors component-wise
    pub inline fn mod(c0: ColorF, c1: ColorF) ColorF {
        return .{
            .r = c0.r * c1.r,
            .g = c0.g * c1.g,
            .b = c0.b * c1.b,
            .a = c0.a * c1.a,
        };
    }
};

/// Vertex structure for rendering.
/// Contains position, color, and optional texture coordinates.
/// Used by the rendering system for drawing textured and colored geometry.
pub const Vertex = extern struct {
    /// Vertex position in 2D space
    pos: Point,
    /// Vertex color (floating-point RGBA)
    color: ColorF,
    /// Texture coordinates (UV mapping). Undefined if not using textures.
    texcoord: Point = undefined,
};

test "basic" {
    const testing = std.testing;
    const expect = testing.expect;
    const expectEqual = testing.expectEqual;
    const expectApproxEqAbs = testing.expectApproxEqAbs;

    // Point tests
    {
        const p = Point{ .x = 1.0, .y = 2.0 };
        try expectEqual(p.toArray(), [_]f32{ 1.0, 2.0 });
        try expectEqual(p.toSize(), Size{ .width = 1, .height = 2 });
        try expectApproxEqAbs(p.angle(), math.atan2(@as(f32, 2.0), @as(f32, 1.0)), 0.000001);
        try expectApproxEqAbs(p.angleDegree(), std.math.radiansToDegrees(math.atan2(@as(f32, 2.0), @as(f32, 1.0))), 0.000001);
        try expectEqual(p.add(.{ 3.0, 4.0 }), Point{ .x = 4.0, .y = 6.0 });
        try expectEqual(p.sub(.{ 0.5, 1.0 }), Point{ .x = 0.5, .y = 1.0 });
        try expectEqual(p.mul(.{ 2.0, 3.0 }), Point{ .x = 2.0, .y = 6.0 });
        try expectEqual(p.scale(2.0), Point{ .x = 2.0, .y = 4.0 });
        try expect(p.isSame(p));
        try expect(!p.isSame(.{ .x = 1.000002, .y = 2.0 }));
        try expectApproxEqAbs(p.distance2(.origin), 5.0, 0.000001);
        try expectApproxEqAbs(p.distance(.origin), std.math.sqrt(5.0), 0.000001);
    }

    // Size tests
    {
        const s = Size{ .width = 10, .height = 20 };
        try expectEqual(s.toPoint(), Point{ .x = 10.0, .y = 20.0 });
        try expectApproxEqAbs(s.getWidthFloat(), 10.0, 0.000001);
        try expectApproxEqAbs(s.getHeightFloat(), 20.0, 0.000001);
        try expect(s.isSame(s));
        try expect(!s.isSame(.{ .width = 10, .height = 21 }));
        try expectEqual(s.area(), 200);
    }

    // Region tests
    {
        const r = Region{ .x = 5, .y = 10, .width = 15, .height = 25 };
        try expectEqual(r.toRect(), Rectangle{ .x = 5.0, .y = 10.0, .width = 15.0, .height = 25.0 });
        try expect(r.isSame(r));
        try expect(!r.isSame(.{ .x = 5, .y = 10, .width = 15, .height = 26 }));
        try expectEqual(r.area(), 375);
    }

    // Rectangle tests (skipping SDL-dependent functions for unit test safety)
    {
        const rect = Rectangle{ .x = 0.0, .y = 0.0, .width = 10.0, .height = 20.0 };
        try expectEqual(rect.toRegion(), Region{ .x = 0, .y = 0, .width = 10, .height = 20 });
        try expectEqual(rect.getPos(), Point{ .x = 0.0, .y = 0.0 });
        try expectEqual(rect.getSize(), Point{ .x = 10.0, .y = 20.0 });
        try expectEqual(rect.getTopLeft(), Point{ .x = 0.0, .y = 0.0 });
        try expectEqual(rect.getTopRight(), Point{ .x = 10.0, .y = 0.0 });
        try expectEqual(rect.getBottomLeft(), Point{ .x = 0.0, .y = 20.0 });
        try expectEqual(rect.getBottomRight(), Point{ .x = 10.0, .y = 20.0 });
        try expectEqual(rect.getCenter(), Point{ .x = 5.0, .y = 10.0 });
        try expectEqual(rect.translate(.{ 1.0, 2.0 }), Rectangle{ .x = 1.0, .y = 2.0, .width = 10.0, .height = 20.0 });
        try expectEqual(rect.scale(.{ 2.0, 0.5 }), Rectangle{ .x = 0.0, .y = 0.0, .width = 20.0, .height = 10.0 });
        try expect(rect.isSame(rect));
        try expectApproxEqAbs(rect.area(), 200.0, 0.000001);
        try expect(rect.containsPoint(.{ .x = 5.0, .y = 10.0 }));
        try expect(!rect.containsPoint(.{ .x = 10.0, .y = 10.0 }));
        const inner = Rectangle{ .x = 1.0, .y = 1.0, .width = 5.0, .height = 5.0 };
        try expect(rect.containsRect(inner));
        try expect(!rect.containsRect(.{ .x = -1.0, .y = 0.0, .width = 11.0, .height = 20.0 }));
    }

    // Circle tests
    {
        const c = Circle{ .center = .{ .x = 0.0, .y = 0.0 }, .radius = 5.0 };
        try expectEqual(c.translate(.{ 1.0, 2.0 }), Circle{ .center = .{ .x = 1.0, .y = 2.0 }, .radius = 5.0 });
        try expect(c.containsPoint(.{ .x = 0.0, .y = 0.0 }));
        try expect(!c.containsPoint(.{ .x = 6.0, .y = 0.0 }));
        const c2 = Circle{ .center = .{ .x = 4.0, .y = 0.0 }, .radius = 2.0 };
        try expect(c.intersectCircle(c2));
        try expect(!c.intersectCircle(.{ .center = .{ .x = 10.0, .y = 0.0 }, .radius = 2.0 }));
        const rect = Rectangle{ .x = -3.0, .y = -3.0, .width = 6.0, .height = 6.0 };
        try expect(c.intersectRect(rect));
        try expect(!c.intersectRect(.{ .x = 6.0, .y = 0.0, .width = 1.0, .height = 1.0 }));
    }

    // Ellipse tests
    {
        const e = Ellipse{ .center = .origin, .radius = .{ .x = 5.0, .y = 3.0 } };
        try expectEqual(e.translate(.{ 1.0, 2.0 }), Ellipse{ .center = .{ .x = 1.0, .y = 2.0 }, .radius = .{ .x = 5.0, .y = 3.0 } });
        try expectApproxEqAbs(e.getFocalRadius2(), 16.0, 0.000001);
        try expectApproxEqAbs(e.getFocalRadius(), 4.0, 0.000001);
        try expect(e.containsPoint(.origin));
        try expect(!e.containsPoint(.{ .x = 6.0, .y = 0.0 })); // approximate
    }

    // Triangle tests
    {
        const tri = Triangle{
            .p0 = .{ .x = 0.0, .y = 0.0 },
            .p1 = .{ .x = 4.0, .y = 0.0 },
            .p2 = .{ .x = 2.0, .y = 3.0 },
        };
        try expectEqual(tri.translate(.{ 1.0, 1.0 }), Triangle{
            .p0 = .{ .x = 1.0, .y = 1.0 },
            .p1 = .{ .x = 5.0, .y = 1.0 },
            .p2 = .{ .x = 3.0, .y = 4.0 },
        });
        try expectApproxEqAbs(tri.area(), 6.0, 0.000001);
        try expectEqual(tri.boundingRect(), Rectangle{ .x = 0.0, .y = 0.0, .width = 4.0, .height = 3.0 });
        const bc = tri.barycentricCoord(.{ .x = 2.0, .y = 1.0 });
        try expectApproxEqAbs(bc[0], 1.0 / 3.0, 0.000001);
        try expectApproxEqAbs(bc[1], 1.0 / 3.0, 0.000001);
        try expectApproxEqAbs(bc[2], 1.0 / 3.0, 0.000001);
        try expect(tri.containsPoint(.{ .x = 2.0, .y = 1.0 }));
        try expect(!tri.containsPoint(.{ .x = 5.0, .y = 1.0 }));
        const small_tri = Triangle{
            .p0 = .{ .x = 1.0, .y = 0.5 },
            .p1 = .{ .x = 2.0, .y = 0.5 },
            .p2 = .{ .x = 1.5, .y = 1.0 },
        };
        try expect(tri.containsTriangle(small_tri));
        try expect(!tri.containsTriangle(.{
            .p0 = .{ .x = -1.0, .y = 0.0 },
            .p1 = .{ .x = 0.0, .y = 0.0 },
            .p2 = .{ .x = -0.5, .y = 1.0 },
        }));
        const other_tri = Triangle{
            .p0 = .{ .x = 1.0, .y = 1.0 },
            .p1 = .{ .x = 3.0, .y = 1.0 },
            .p2 = .{ .x = 2.0, .y = 2.0 },
        };
        try expect(tri.intersectTriangle(other_tri));
        try expect(!tri.intersectTriangle(.{
            .p0 = .{ .x = 5.0, .y = 0.0 },
            .p1 = .{ .x = 9.0, .y = 0.0 },
            .p2 = .{ .x = 7.0, .y = 3.0 },
        }));
        const rect = Rectangle{ .x = -1.0, .y = -1.0, .width = 6.0, .height = 6.0 };
        try expect(tri.intersectRect(rect));
        try expect(!tri.intersectRect(.{ .x = 5.0, .y = -1.0, .width = 1.0, .height = 6.0 }));
    }
}
