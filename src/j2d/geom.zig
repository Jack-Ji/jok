//! 2D geometry primitives with intersection and raycast support.
//!
//! Primitives:
//! - Point: 2D floating-point coordinate
//! - Size: 2D unsigned integer dimensions
//! - Region: Integer-based rectangular area
//! - Rectangle: Floating-point rectangular area
//! - Circle: Circle defined by center and radius
//! - Ellipse: Ellipse defined by center and radius
//! - Triangle: Triangle defined by three points
//! - Line: Line segment defined by two endpoints
//! - Ray: Ray defined by origin and direction

const std = @import("std");
const assert = std.debug.assert;
const math = std.math;
const Vector = @import("Vector.zig");
const jok = @import("../jok.zig");
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

    /// Convert point to a Vector
    pub inline fn toVector(p: Point) Vector {
        return Vector.new(p.x, p.y);
    }

    /// Convert point to Size by rounding coordinates to integers.
    /// Asserts that coordinates are non-negative.
    pub inline fn toSize(p: Point) Size {
        assert(p.x >= 0 and p.y >= 0);
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

    /// Dot product of two points (treated as 2D vectors)
    pub inline fn dot(p0: Point, p1: Point) f32 {
        return p0.x * p1.x + p0.y * p1.y;
    }

    /// 2D cross product (z-component of the 3D cross product).
    /// Returns a positive value if p1 is clockwise from p0,
    /// negative if counter-clockwise, and zero if collinear.
    pub inline fn cross(p0: Point, p1: Point) f32 {
        return p0.y * p1.x - p0.x * p1.y;
    }

    /// Normalize the vector represented by point
    pub inline fn norm(p: Point) Point {
        const len = @sqrt(p.dot(p));
        assert(len > 0);
        return .{
            .x = p.x / len,
            .y = p.y / len,
        };
    }

    /// Check if two points are approximately equal
    pub inline fn isSame(p0: Point, p1: Point) bool {
        const tolerance = 1e-6;
        return std.math.approxEqAbs(f32, p0.x, p1.x, tolerance) and
            std.math.approxEqAbs(f32, p0.y, p1.y, tolerance);
    }

    /// Calculate squared distance between two points (faster than distance)
    pub inline fn distance2(p0: Point, p1: Point) f32 {
        const d = p0.sub(p1);
        return d.dot(d);
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
    pub inline fn toRegion(s: Size, x: u32, y: u32) Region {
        return .{
            .x = x,
            .y = y,
            .width = s.width,
            .height = s.height,
        };
    }

    /// Convert size to Rectangle at specified position
    pub inline fn toRect(s: Size, pos: Point) Rectangle {
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

    /// Convert rectangle to Region by rounding coordinates to integers.
    /// Asserts that all values are non-negative.
    pub inline fn toRegion(r: Rectangle) Region {
        assert(r.x >= 0 and r.y >= 0 and r.width >= 0 and r.height >= 0);
        return .{
            .x = @intFromFloat(@round(r.x)),
            .y = @intFromFloat(@round(r.y)),
            .width = @intFromFloat(@round(r.width)),
            .height = @intFromFloat(@round(r.height)),
        };
    }

    /// Get position (top-left corner) as Point
    pub inline fn getPos(r: Rectangle) Point {
        return .{ .x = r.x, .y = r.y };
    }

    /// Get size as Point
    pub inline fn getSizeF(r: Rectangle) Point {
        return .{ .x = r.width, .y = r.height };
    }

    /// Get top-left corner position
    pub inline fn getTopLeft(r: Rectangle) Point {
        return .{ .x = r.x, .y = r.y };
    }

    /// Get top-right corner position
    pub inline fn getTopRight(r: Rectangle) Point {
        return .{ .x = r.x + r.width, .y = r.y };
    }

    /// Get bottom-left corner position
    pub inline fn getBottomLeft(r: Rectangle) Point {
        return .{ .x = r.x, .y = r.y + r.height };
    }

    /// Get bottom-right corner position
    pub inline fn getBottomRight(r: Rectangle) Point {
        return .{ .x = r.x + r.width, .y = r.y + r.height };
    }

    /// Get center position
    pub inline fn getCenter(r: Rectangle) Point {
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

    /// Check if two rectangles are approximately equal
    pub inline fn isSame(r0: Rectangle, r1: Rectangle) bool {
        const tolerance = 1e-6;
        return std.math.approxEqAbs(f32, r0.x, r1.x, tolerance) and
            std.math.approxEqAbs(f32, r0.y, r1.y, tolerance) and
            std.math.approxEqAbs(f32, r0.width, r1.width, tolerance) and
            std.math.approxEqAbs(f32, r0.height, r1.height, tolerance);
    }

    /// Calculate area (width * height)
    pub inline fn area(r: Rectangle) f32 {
        return r.width * r.height;
    }

    /// Intersection dispatcher: test intersection with any supported geometry type.
    /// Supported targets: Rectangle, Circle, Ellipse, Triangle, Line, Point.
    pub fn intersect(r: Rectangle, target: anytype) bool {
        return switch (@TypeOf(target)) {
            Rectangle => r.hasIntersection(target),
            Circle => r.intersectCircle(target),
            Ellipse => r.intersectEllipse(target),
            Triangle => r.intersectTriangle(target),
            Line => r.intersectLine(target.p0, target.p1) != null,
            Point => r.containsPoint(target),
            else => @compileError("Rectangle.intersect: unsupported target type " ++ @typeName(@TypeOf(target))),
        };
    }

    /// Check if this rectangle intersects with another rectangle
    pub fn hasIntersection(r: Rectangle, b: Rectangle) bool {
        return sdl.SDL_HasRectIntersectionFloat(@ptrCast(&r), @ptrCast(&b));
    }

    /// Calculate intersection of two rectangles. Returns null if no intersection.
    pub fn intersectRect(r: Rectangle, b: Rectangle) ?Rectangle {
        var result: Rectangle = undefined;
        if (sdl.SDL_GetRectIntersectionFloat(@ptrCast(&r), @ptrCast(&b), @ptrCast(&result))) {
            return result;
        }
        return null;
    }

    /// Calculate intersection of rectangle with a line segment.
    /// Returns clipped line endpoints if intersection exists, null otherwise.
    pub fn intersectLine(r: Rectangle, _p0: Point, _p1: Point) ?[2]Point {
        var p0: Point = _p0;
        var p1: Point = _p1;
        if (sdl.SDL_GetRectAndLineIntersectionFloat(@ptrCast(&r), &p0.x, &p0.y, &p1.x, &p1.y)) {
            return .{ p0, p1 };
        }
        return null;
    }

    /// Check if this rectangle intersects with a circle
    pub fn intersectCircle(r: Rectangle, c: Circle) bool {
        return c.intersectRect(r);
    }

    /// Check if this rectangle intersects with a triangle
    pub fn intersectTriangle(r: Rectangle, tri: Triangle) bool {
        return tri.intersectRect(r);
    }

    /// Check if this rectangle intersects with an ellipse
    pub fn intersectEllipse(r: Rectangle, e: Ellipse) bool {
        return e.intersectRect(r);
    }

    /// Check if rectangle contains a point
    pub fn containsPoint(r: Rectangle, p: Point) bool {
        return p.x >= r.x and p.x < r.x + r.width and
            p.y >= r.y and p.y < r.y + r.height;
    }

    /// Check if rectangle fully contains another rectangle
    pub fn containsRect(r: Rectangle, b: Rectangle) bool {
        return b.x >= r.x and b.x + b.width <= r.x + r.width and
            b.y >= r.y and b.y + b.height <= r.y + r.height;
    }

    /// Check if rectangle contains a line segment (both endpoints)
    pub fn containsLine(r: Rectangle, p0: Point, p1: Point) bool {
        return r.containsPoint(p0) and r.containsPoint(p1);
    }

    /// Check if rectangle fully contains a circle
    pub fn containsCircle(r: Rectangle, c: Circle) bool {
        return r.containsRect(.{
            .x = c.center.x - c.radius,
            .y = c.center.y - c.radius,
            .width = c.radius * 2,
            .height = c.radius * 2,
        });
    }

    /// Check if rectangle fully contains a triangle
    pub fn containsTriangle(r: Rectangle, tri: Triangle) bool {
        return r.containsPoint(tri.p0) and r.containsPoint(tri.p1) and r.containsPoint(tri.p2);
    }
};

/// Circle defined by center point and radius.
/// Supports intersection and containment testing with other geometric primitives.
pub const Circle = extern struct {
    center: Point = .origin,
    radius: f32 = 1,

    /// Translate circle by offset. Accepts Point, tuple, or array.
    pub fn translate(c: Circle, two_floats: anytype) Circle {
        return .{
            .center = c.center.add(two_floats),
            .radius = c.radius,
        };
    }

    /// Get the bounding rectangle that fully contains this circle
    pub fn getBoundingRect(c: Circle) Rectangle {
        return .{
            .x = c.center.x - c.radius,
            .y = c.center.y - c.radius,
            .width = c.radius * 2,
            .height = c.radius * 2,
        };
    }

    /// Intersection dispatcher: test intersection with any supported geometry type.
    /// Supported targets: Rectangle, Circle, Triangle, Line, Point.
    pub fn intersect(c: Circle, target: anytype) bool {
        return switch (@TypeOf(target)) {
            Rectangle => c.intersectRect(target),
            Circle => c.intersectCircle(target),
            Ellipse => c.intersectEllipse(target),
            Triangle => c.intersectTriangle(target),
            Line => c.intersectLine(target),
            Point => c.containsPoint(target),
            else => @compileError("Circle.intersect: unsupported target type " ++ @typeName(@TypeOf(target))),
        };
    }

    /// Check if circle contains a point
    pub fn containsPoint(c: Circle, p: Point) bool {
        const v: @Vector(2, f32) = .{ c.center.x - p.x, c.center.y - p.y };
        return @reduce(.Add, v * v) < c.radius * c.radius;
    }

    /// Check if this circle intersects with another circle
    pub fn intersectCircle(c0: Circle, c1: Circle) bool {
        const r = c0.radius + c1.radius;
        return c0.center.distance2(c1.center) <= r * r;
    }

    /// Check if circle intersects with a rectangle using closest-point algorithm
    pub fn intersectRect(c: Circle, r: Rectangle) bool {
        // Find the closest point on the rectangle to the circle center
        const closest_x = math.clamp(c.center.x, r.x, r.x + r.width);
        const closest_y = math.clamp(c.center.y, r.y, r.y + r.height);
        const dx = c.center.x - closest_x;
        const dy = c.center.y - closest_y;
        return dx * dx + dy * dy <= c.radius * c.radius;
    }

    /// Check if circle intersects with a line segment using closest-point algorithm
    pub fn intersectLine(c: Circle, l: Line) bool {
        return l.intersectCircle(c);
    }

    /// Check if circle intersects with a triangle.
    /// Tests circle against each triangle edge and checks if center is inside triangle.
    pub fn intersectTriangle(c: Circle, tri: Triangle) bool {
        // If the circle center is inside the triangle, they intersect
        if (tri.containsPoint(c.center)) return true;
        // Check if any triangle edge intersects the circle
        const edges = [3]Line{
            .{ .p0 = tri.p0, .p1 = tri.p1 },
            .{ .p0 = tri.p1, .p1 = tri.p2 },
            .{ .p0 = tri.p2, .p1 = tri.p0 },
        };
        for (edges) |edge| {
            if (edge.intersectCircle(c)) return true;
        }
        return false;
    }

    /// Check if circle intersects with an ellipse
    pub fn intersectEllipse(c: Circle, e: Ellipse) bool {
        return e.intersectCircle(c);
    }
};

/// Ellipse defined by center point and radius (x and y).
/// Supports containment testing and focal point calculations.
pub const Ellipse = extern struct {
    center: Point = .origin,
    /// Radii in x and y directions
    radius: Point = .unit,

    /// Translate ellipse by offset. Accepts Point, tuple, or array.
    pub fn translate(e: Ellipse, two_floats: anytype) Ellipse {
        return .{
            .center = e.center.add(two_floats),
            .radius = e.radius,
        };
    }

    /// Get the bounding rectangle that fully contains this ellipse
    pub fn getBoundingRect(e: Ellipse) Rectangle {
        return .{
            .x = e.center.x - e.radius.x,
            .y = e.center.y - e.radius.y,
            .width = e.radius.x * 2,
            .height = e.radius.y * 2,
        };
    }

    /// Get squared focal radius (distance from center to focus point)
    pub fn getFocalRadius2(e: Ellipse) f32 {
        return if (e.radius.x > e.radius.y)
            e.radius.x * e.radius.x - e.radius.y * e.radius.y
        else
            e.radius.y * e.radius.y - e.radius.x * e.radius.x;
    }

    /// Get focal radius (distance from center to focus point)
    pub fn getFocalRadius(e: Ellipse) f32 {
        return @sqrt(e.getFocalRadius2());
    }

    /// Check if ellipse contains a point using normalized form:
    /// (dx/rx)^2 + (dy/ry)^2 < 1
    pub fn containsPoint(e: Ellipse, p: Point) bool {
        const dx = (p.x - e.center.x) / e.radius.x;
        const dy = (p.y - e.center.y) / e.radius.y;
        return dx * dx + dy * dy < 1;
    }

    /// Intersection dispatcher: test intersection with any supported geometry type.
    /// Supported targets: Rectangle, Circle, Ellipse, Triangle, Line, Point.
    pub fn intersect(e: Ellipse, target: anytype) bool {
        return switch (@TypeOf(target)) {
            Rectangle => e.intersectRect(target),
            Circle => e.intersectCircle(target),
            Ellipse => e.intersectEllipse(target),
            Triangle => e.intersectTriangle(target),
            Line => e.intersectLine(target),
            Point => e.containsPoint(target),
            else => @compileError("Ellipse.intersect: unsupported target type " ++ @typeName(@TypeOf(target))),
        };
    }

    /// Check if ellipse intersects with a line segment.
    /// Transforms line into normalized ellipse space and solves quadratic.
    pub fn intersectLine(e: Ellipse, l: Line) bool {
        // Transform line endpoints into normalized space where ellipse becomes unit circle
        const x0 = (l.p0.x - e.center.x) / e.radius.x;
        const y0 = (l.p0.y - e.center.y) / e.radius.y;
        const x1 = (l.p1.x - e.center.x) / e.radius.x;
        const y1 = (l.p1.y - e.center.y) / e.radius.y;
        // Check if either endpoint is inside the ellipse
        if (x0 * x0 + y0 * y0 <= 1) return true;
        if (x1 * x1 + y1 * y1 <= 1) return true;
        // Parametric line: P(t) = P0 + t*(P1-P0), t in [0,1]
        // Solve |P(t)|^2 = 1 for intersection with unit circle
        const dx = x1 - x0;
        const dy = y1 - y0;
        const a = dx * dx + dy * dy;
        if (a < 1e-12) return false; // degenerate line
        const b = 2 * (x0 * dx + y0 * dy);
        const c = x0 * x0 + y0 * y0 - 1;
        const disc = b * b - 4 * a * c;
        if (disc < 0) return false;
        const sqrt_disc = @sqrt(disc);
        const t0 = (-b - sqrt_disc) / (2 * a);
        const t1 = (-b + sqrt_disc) / (2 * a);
        return t0 <= 1 and t1 >= 0;
    }

    /// Check if ellipse intersects with a circle.
    pub fn intersectCircle(e: Ellipse, c: Circle) bool {
        // Treat circle as an ellipse with equal radii
        return e.intersectEllipse(.{
            .center = c.center,
            .radius = .{ .x = c.radius, .y = c.radius },
        });
    }

    /// Check if ellipse intersects with a rectangle.
    pub fn intersectRect(e: Ellipse, r: Rectangle) bool {
        // Quick bounding-rect rejection
        const eb = e.getBoundingRect();
        if (eb.x >= r.x + r.width or eb.x + eb.width <= r.x or
            eb.y >= r.y + r.height or eb.y + eb.height <= r.y)
        {
            return false;
        }
        // Check if ellipse center is inside rectangle
        if (r.containsPoint(e.center)) return true;
        // Check if any rectangle corner is inside ellipse
        if (e.containsPoint(r.getTopLeft())) return true;
        if (e.containsPoint(r.getTopRight())) return true;
        if (e.containsPoint(r.getBottomLeft())) return true;
        if (e.containsPoint(r.getBottomRight())) return true;
        // Check if any rectangle edge intersects the ellipse
        const edges = [4]Line{
            .{ .p0 = r.getTopLeft(), .p1 = r.getTopRight() },
            .{ .p0 = r.getTopRight(), .p1 = r.getBottomRight() },
            .{ .p0 = r.getBottomRight(), .p1 = r.getBottomLeft() },
            .{ .p0 = r.getBottomLeft(), .p1 = r.getTopLeft() },
        };
        for (edges) |edge| {
            if (e.intersectLine(edge)) return true;
        }
        return false;
    }

    /// Check if ellipse intersects with a triangle.
    pub fn intersectTriangle(e: Ellipse, tri: Triangle) bool {
        // If the ellipse center is inside the triangle, they intersect
        if (tri.containsPoint(e.center)) return true;
        // If any triangle vertex is inside the ellipse, they intersect
        if (e.containsPoint(tri.p0)) return true;
        if (e.containsPoint(tri.p1)) return true;
        if (e.containsPoint(tri.p2)) return true;
        // Check if any triangle edge intersects the ellipse
        const edges = [3]Line{
            .{ .p0 = tri.p0, .p1 = tri.p1 },
            .{ .p0 = tri.p1, .p1 = tri.p2 },
            .{ .p0 = tri.p2, .p1 = tri.p0 },
        };
        for (edges) |edge| {
            if (e.intersectLine(edge)) return true;
        }
        return false;
    }

    /// Check if this ellipse intersects with another ellipse.
    /// Uses normalized-space approach: transforms both ellipses so that
    /// the first becomes a unit circle, then tests the second.
    pub fn intersectEllipse(e0: Ellipse, e1: Ellipse) bool {
        // Transform e1 center into e0's normalized space (where e0 is unit circle)
        const cx = (e1.center.x - e0.center.x) / e0.radius.x;
        const cy = (e1.center.y - e0.center.y) / e0.radius.y;
        // e1 radii in normalized space
        const rx = e1.radius.x / e0.radius.x;
        const ry = e1.radius.y / e0.radius.y;
        // If e1 center is inside unit circle, they intersect
        if (cx * cx + cy * cy < 1) return true;
        // If unit circle center (origin) is inside transformed e1, they intersect
        if (cx * cx / (rx * rx) + cy * cy / (ry * ry) < 1) return true;
        // Sample points on the transformed e1 boundary and check against unit circle.
        // Also sample points on unit circle and check against transformed e1.
        // Use enough samples to catch thin overlaps.
        const n = 64;
        for (0..n) |i| {
            const angle = @as(f32, @floatFromInt(i)) * (2.0 * math.pi / @as(f32, @floatFromInt(n)));
            const cos_a = @cos(angle);
            const sin_a = @sin(angle);
            // Point on transformed e1 boundary
            const px = cx + rx * cos_a;
            const py = cy + ry * sin_a;
            if (px * px + py * py <= 1) return true;
            // Point on unit circle boundary
            const ux = cos_a;
            const uy = sin_a;
            const dx = ux - cx;
            const dy = uy - cy;
            if (dx * dx / (rx * rx) + dy * dy / (ry * ry) <= 1) return true;
        }
        return false;
    }
};

/// Triangle defined by three points.
/// Supports area calculation, bounding box, barycentric coordinates, and intersection testing.
pub const Triangle = extern struct {
    p0: Point,
    p1: Point,
    p2: Point,

    /// Translate triangle by offset. Accepts Point, tuple, or array.
    pub fn translate(tri: Triangle, two_floats: anytype) Triangle {
        return .{
            .p0 = tri.p0.add(two_floats),
            .p1 = tri.p1.add(two_floats),
            .p2 = tri.p2.add(two_floats),
        };
    }

    /// Calculate triangle area using cross product formula
    pub fn area(tri: Triangle) f32 {
        return @abs(tri.p1.sub(tri.p0).cross(tri.p2.sub(tri.p0))) / 2;
    }

    /// Get axis-aligned bounding rectangle
    pub fn getBoundingRect(tri: Triangle) Rectangle {
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
    pub fn barycentricCoord(tri: Triangle, point: Point) [3]f32 {
        const v0 = zmath.f32x4(tri.p2.x - tri.p0.x, tri.p2.y - tri.p0.y, 0, 0);
        const v1 = zmath.f32x4(tri.p1.x - tri.p0.x, tri.p1.y - tri.p0.y, 0, 0);
        const v2 = zmath.f32x4(point.x - tri.p0.x, point.y - tri.p0.y, 0, 0);
        const dot00 = zmath.dot2(v0, v0)[0];
        const dot01 = zmath.dot2(v0, v1)[0];
        const dot02 = zmath.dot2(v0, v2)[0];
        const dot11 = zmath.dot2(v1, v1)[0];
        const dot12 = zmath.dot2(v1, v2)[0];
        const denom = dot00 * dot11 - dot01 * dot01;
        if (@abs(denom) <= 1e-12) {
            return .{ -1, -1, -1 };
        }
        const inv_denom = 1.0 / denom;
        const u = (dot11 * dot02 - dot01 * dot12) * inv_denom;
        const v = (dot00 * dot12 - dot01 * dot02) * inv_denom;
        return .{ u, v, 1 - u - v };
    }

    /// Intersection dispatcher: test intersection with any supported geometry type.
    /// Supported targets: Rectangle, Circle, Triangle, Line, Point.
    pub fn intersect(tri: Triangle, target: anytype) bool {
        return switch (@TypeOf(target)) {
            Rectangle => tri.intersectRect(target),
            Circle => tri.intersectCircle(target),
            Ellipse => tri.intersectEllipse(target),
            Triangle => tri.intersectTriangle(target),
            Line => tri.intersectLine(target),
            Point => tri.containsPoint(target),
            else => @compileError("Triangle.intersect: unsupported target type " ++ @typeName(@TypeOf(target))),
        };
    }

    /// Test whether a point is in triangle using barycentric coordinates
    pub fn containsPoint(tri: Triangle, point: Point) bool {
        if (tri.isDegenerate()) return false;
        const p = tri.barycentricCoord(point);
        return p[0] > 0 and p[1] > 0 and p[2] > 0;
    }

    /// Check if this triangle fully contains another triangle
    pub fn containsTriangle(tri0: Triangle, tri1: Triangle) bool {
        if (tri0.isDegenerate() or tri1.isDegenerate()) return false;
        return tri0.containsPoint(tri1.p0) and
            tri0.containsPoint(tri1.p1) and
            tri0.containsPoint(tri1.p2);
    }

    /// Check if this triangle intersects with another triangle using Separating Axis Theorem (SAT)
    pub fn intersectTriangle(tri0: Triangle, tri1: Triangle) bool {
        if (tri0.isDegenerate() or tri1.isDegenerate()) return false;
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

        if (tri0.getBoundingRect().intersectRect(tri1.getBoundingRect()) == null) {
            return false;
        }

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

    /// Check if triangle intersects with a rectangle using Separating Axis Theorem (SAT).
    /// Tests 5 potential separating axes: 2 from rectangle (x,y axes) and 3 from triangle edges.
    pub fn intersectRect(tri: Triangle, r: Rectangle) bool {
        if (tri.isDegenerate()) return false;
        // Early exit: check bounding box intersection first
        const tri_rect = tri.getBoundingRect();
        if (tri_rect.x >= r.x + r.width or tri_rect.x + tri_rect.width <= r.x or
            tri_rect.y >= r.y + r.height or tri_rect.y + tri_rect.height <= r.y)
        {
            return false;
        }

        // Check if any triangle vertex is inside the rectangle
        if (r.containsPoint(tri.p0) or r.containsPoint(tri.p1) or r.containsPoint(tri.p2)) {
            return true;
        }

        // Check if any rectangle corner is inside the triangle
        if (tri.containsPoint(r.getTopLeft()) or tri.containsPoint(r.getTopRight()) or
            tri.containsPoint(r.getBottomLeft()) or tri.containsPoint(r.getBottomRight()))
        {
            return true;
        }

        // SAT: Test triangle edge normals as separating axes
        // For each edge, project both shapes onto the edge's normal and check for overlap
        const edges = [_][2]Point{
            .{ tri.p0, tri.p1 },
            .{ tri.p1, tri.p2 },
            .{ tri.p2, tri.p0 },
        };

        for (edges) |edge| {
            // Edge normal (perpendicular to edge)
            const n = Point{ .x = edge[1].y - edge[0].y, .y = edge[0].x - edge[1].x };

            // Project triangle vertices onto normal
            const t0 = tri.p0.dot(n);
            const t1 = tri.p1.dot(n);
            const t2 = tri.p2.dot(n);
            const tri_min = @min(t0, @min(t1, t2));
            const tri_max = @max(t0, @max(t1, t2));

            // Project rectangle corners onto normal
            const tl = r.getTopLeft();
            const br = r.getBottomRight();
            const r0 = tl.dot(n);
            const r1 = (Point{ .x = br.x, .y = tl.y }).dot(n);
            const r2 = (Point{ .x = tl.x, .y = br.y }).dot(n);
            const r3 = br.dot(n);
            const rect_min = @min(r0, @min(r1, @min(r2, r3)));
            const rect_max = @max(r0, @max(r1, @max(r2, r3)));

            // Check for separation on this axis
            if (tri_max <= rect_min or rect_max <= tri_min) {
                return false;
            }
        }

        return true;
    }

    /// Check if triangle intersects with a circle
    pub fn intersectCircle(tri: Triangle, c: Circle) bool {
        return c.intersectTriangle(tri);
    }

    /// Check if triangle intersects with a line
    pub fn intersectLine(tri: Triangle, l: Line) bool {
        return l.intersectTriangle(tri);
    }

    /// Check if triangle intersects with an ellipse
    pub fn intersectEllipse(tri: Triangle, e: Ellipse) bool {
        return e.intersectTriangle(tri);
    }

    inline fn isDegenerate(tri: Triangle) bool {
        const area2 = tri.p1.sub(tri.p0).cross(tri.p2.sub(tri.p0));
        return @abs(area2) <= 1e-8;
    }
};

/// Line segment defined by two endpoints.
pub const Line = extern struct {
    p0: Point,
    p1: Point,

    /// Translate line by offset. Accepts Point, tuple, or array.
    pub fn translate(l: Line, two_floats: anytype) Line {
        return .{
            .p0 = l.p0.add(two_floats),
            .p1 = l.p1.add(two_floats),
        };
    }

    /// Get the direction vector (normalized) from p0 to p1
    pub fn direction(l: Line) Point {
        return l.p1.sub(l.p0).norm();
    }

    /// Get the squared length of the line segment
    pub fn length2(l: Line) f32 {
        return l.p0.distance2(l.p1);
    }

    /// Get the length of the line segment
    pub fn length(l: Line) f32 {
        return l.p0.distance(l.p1);
    }

    /// Get the midpoint of the line segment
    pub fn midpoint(l: Line) Point {
        return .{
            .x = (l.p0.x + l.p1.x) * 0.5,
            .y = (l.p0.y + l.p1.y) * 0.5,
        };
    }

    /// Interpolate along the line segment. t=0 returns p0, t=1 returns p1.
    pub fn lerp(l: Line, t: f32) Point {
        return .{
            .x = l.p0.x + (l.p1.x - l.p0.x) * t,
            .y = l.p0.y + (l.p1.y - l.p0.y) * t,
        };
    }

    /// Get the closest point on this line segment to a given point.
    /// Returns the parameter t (clamped to [0,1]) and the closest point.
    pub fn closestPoint(l: Line, p: Point) struct { t: f32, point: Point } {
        const d = l.p1.sub(l.p0);
        const len2 = d.dot(d);
        if (len2 == 0) return .{ .t = 0, .point = l.p0 };
        const t = math.clamp(p.sub(l.p0).dot(d) / len2, 0, 1);
        return .{ .t = t, .point = l.lerp(t) };
    }

    /// Get the bounding rectangle that fully contains this line
    pub fn getBoundingRect(l: Line) Rectangle {
        const min_x = @min(l.p0.x, l.p1.x);
        const min_y = @min(l.p0.y, l.p1.y);
        const max_x = @max(l.p0.x, l.p1.x);
        const max_y = @max(l.p0.y, l.p1.y);
        return .{
            .x = min_x,
            .y = min_y,
            .width = max_x - min_x,
            .height = max_y - min_y,
        };
    }

    /// Intersection dispatcher: test intersection with any supported geometry type.
    /// Supported targets: Rectangle, Circle, Triangle, Line.
    pub fn intersect(l: Line, target: anytype) bool {
        return switch (@TypeOf(target)) {
            Rectangle => l.intersectRect(target),
            Circle => l.intersectCircle(target),
            Ellipse => l.intersectEllipse(target),
            Triangle => l.intersectTriangle(target),
            Line => l.intersectLine(target) != null,
            Point => l.containsPoint(target),
            else => @compileError("Line.intersect: unsupported target type " ++ @typeName(@TypeOf(target))),
        };
    }

    /// Check if this line segment intersects another line segment.
    /// Returns the intersection point if they intersect, null otherwise.
    pub fn intersectLine(l0: Line, l1: Line) ?Point {
        const d0 = l0.p1.sub(l0.p0);
        const d1 = l1.p1.sub(l1.p0);
        const denom = d0.cross(d1);
        if (@abs(denom) < 1e-10) return null; // parallel or coincident
        const d = l1.p0.sub(l0.p0);
        const t = d.cross(d1) / denom;
        const u = d.cross(d0) / denom;
        if (t >= 0 and t <= 1 and u >= 0 and u <= 1) {
            return l0.lerp(t);
        }
        return null;
    }

    /// Check if this line segment intersects a circle.
    /// Uses closest-point-on-segment approach.
    pub fn intersectCircle(l: Line, c: Circle) bool {
        const cp = l.closestPoint(c.center);
        return cp.point.distance2(c.center) <= c.radius * c.radius;
    }

    /// Check if this line segment intersects a rectangle.
    pub fn intersectRect(l: Line, r: Rectangle) bool {
        return r.intersectLine(l.p0, l.p1) != null;
    }

    /// Check if this line segment intersects a triangle.
    /// Tests intersection against each triangle edge.
    pub fn intersectTriangle(l: Line, tri: Triangle) bool {
        const edges = [3]Line{
            .{ .p0 = tri.p0, .p1 = tri.p1 },
            .{ .p0 = tri.p1, .p1 = tri.p2 },
            .{ .p0 = tri.p2, .p1 = tri.p0 },
        };
        for (edges) |edge| {
            if (l.intersectLine(edge) != null) return true;
        }
        // Also check if the line is fully inside the triangle
        return tri.containsPoint(l.p0);
    }

    /// Check if this line segment intersects an ellipse
    pub fn intersectEllipse(l: Line, e: Ellipse) bool {
        return e.intersectLine(l);
    }

    /// Check if a point belongs to the line segment
    pub fn containsPoint(l: Line, p: Point) bool {
        const dir = l.direction();
        const angle = p.sub(l.p0).norm().dot(dir);
        const proj = p.sub(l.p0).dot(dir);
        return math.approxEqAbs(f32, angle, 1.0, 1e-6) and proj > 0 and proj < l.length();
    }
};

/// Ray defined by an origin point and a direction vector.
pub const Ray = struct {
    origin: Point,
    dir: Point,

    /// Result of a ray intersection test.
    /// Contains the ray parameter, intersection point, and surface normal.
    pub const Hit = struct {
        /// Ray parameter at intersection (distance along ray direction)
        t: f32,
        /// The intersection point
        point: Point,
        /// Surface normal at the intersection point (unit vector)
        normal: Point,
    };

    /// Create a ray from two points (origin and a point the ray passes through)
    pub fn init(p0: Point, p1: Point) Ray {
        assert(!p0.isSame(p1));
        return .{
            .origin = p0,
            .dir = p1.sub(p0).toVector().norm().toPoint(),
        };
    }

    /// Get a point along the ray at parameter t. Returns origin + dir * t.
    pub fn at(r: Ray, t: f32) Point {
        return r.origin.add(r.dir.scale(t));
    }

    pub fn raycast(r: Ray, target: anytype) ?Hit {
        return switch (@TypeOf(target)) {
            Line => r.raycastLine(target),
            Circle => r.raycastCircle(target),
            Ellipse => r.raycastEllipse(target),
            Rectangle => r.raycastRect(target),
            Triangle => r.raycastTriangle(target),
            else => @compileError("Unsupported target type for raycast: " ++ @typeName(@TypeOf(target))),
        };
    }

    /// Cast this ray against a line segment.
    /// Returns a Hit if the ray intersects the segment, null otherwise.
    fn raycastLine(r: Ray, l: Line) ?Hit {
        assert(r.dir.x != 0 or r.dir.y != 0);
        const d = l.p1.sub(l.p0);
        const denom = r.dir.cross(d);
        if (@abs(denom) < 1e-10) return null;
        const o = l.p0.sub(r.origin);
        const t = o.cross(d) / denom;
        const u = o.cross(r.dir) / denom;
        if (t >= 0 and u >= 0 and u <= 1) {
            // Normal is perpendicular to the line segment, facing the ray origin
            var n = Point{ .x = -d.y, .y = d.x };
            const len = @sqrt(n.dot(n));
            if (len > 0) {
                n = n.scale(1.0 / len);
            }
            // Ensure normal faces toward ray origin
            if (n.dot(r.dir) > 0) {
                n = .{ .x = -n.x, .y = -n.y };
            }
            return .{
                .t = t,
                .point = r.at(t),
                .normal = n,
            };
        }
        return null;
    }

    /// Cast this ray against a circle.
    /// Returns the nearest Hit if the ray intersects the circle, null otherwise.
    fn raycastCircle(r: Ray, c: Circle) ?Hit {
        assert(r.dir.x != 0 or r.dir.y != 0);
        const o = r.origin.sub(c.center);
        const a = r.dir.dot(r.dir);
        const b = 2 * o.dot(r.dir);
        const cc = o.dot(o) - c.radius * c.radius;
        const disc = b * b - 4 * a * cc;
        if (disc < 0) return null;
        const sqrt_disc = @sqrt(disc);
        const t0 = (-b - sqrt_disc) / (2 * a);
        const t1 = (-b + sqrt_disc) / (2 * a);
        const t = if (t0 >= 0) t0 else if (t1 >= 0) t1 else return null;
        const p = r.at(t);
        var normal = p.sub(c.center).norm();
        // Ensure normal faces toward ray origin
        if (normal.dot(r.dir) > 0) {
            normal = .{ .x = -normal.x, .y = -normal.y };
        }
        return .{ .t = t, .point = p, .normal = normal };
    }

    /// Cast this ray against a rectangle.
    /// Returns the nearest Hit if the ray intersects the rectangle, null otherwise.
    fn raycastRect(r: Ray, rect: Rectangle) ?Hit {
        assert(r.dir.x != 0 or r.dir.y != 0);
        const edges = [4]Line{
            .{ .p0 = rect.getTopLeft(), .p1 = rect.getTopRight() },
            .{ .p0 = rect.getTopRight(), .p1 = rect.getBottomRight() },
            .{ .p0 = rect.getBottomRight(), .p1 = rect.getBottomLeft() },
            .{ .p0 = rect.getBottomLeft(), .p1 = rect.getTopLeft() },
        };
        var best: ?Hit = null;
        for (edges) |edge| {
            if (r.raycastLine(edge)) |hit| {
                if (best == null or hit.t < best.?.t) {
                    best = hit;
                }
            }
        }
        return best;
    }

    /// Cast this ray against a triangle.
    /// Returns the nearest Hit if the ray intersects the triangle, null otherwise.
    fn raycastTriangle(r: Ray, tri: Triangle) ?Hit {
        assert(r.dir.x != 0 or r.dir.y != 0);
        const edges = [3]Line{
            .{ .p0 = tri.p0, .p1 = tri.p1 },
            .{ .p0 = tri.p1, .p1 = tri.p2 },
            .{ .p0 = tri.p2, .p1 = tri.p0 },
        };
        var best: ?Hit = null;
        for (edges) |edge| {
            if (r.raycastLine(edge)) |hit| {
                if (best == null or hit.t < best.?.t) {
                    best = hit;
                }
            }
        }
        return best;
    }

    /// Cast this ray against an ellipse.
    /// Transforms into normalized space where ellipse becomes unit circle, then solves quadratic.
    fn raycastEllipse(r: Ray, e: Ellipse) ?Hit {
        assert(r.dir.x != 0 or r.dir.y != 0);
        // Transform ray into normalized space where ellipse is a unit circle
        const o = Point{
            .x = (r.origin.x - e.center.x) / e.radius.x,
            .y = (r.origin.y - e.center.y) / e.radius.y,
        };
        const d = Point{
            .x = r.dir.x / e.radius.x,
            .y = r.dir.y / e.radius.y,
        };
        const a = d.dot(d);
        const b = 2 * o.dot(d);
        const c = o.dot(o) - 1;
        const disc = b * b - 4 * a * c;
        if (disc < 0) return null;
        const sqrt_disc = @sqrt(disc);
        const t0 = (-b - sqrt_disc) / (2 * a);
        const t1 = (-b + sqrt_disc) / (2 * a);
        // Find nearest valid t in normalized space, then convert back
        const tn = if (t0 >= 0) t0 else if (t1 >= 0) t1 else return null;
        // Intersection point in normalized space
        const pn = Point{ .x = o.x + d.x * tn, .y = o.y + d.y * tn };
        // Map back to world space for the intersection point
        const p = Point{
            .x = pn.x * e.radius.x + e.center.x,
            .y = pn.y * e.radius.y + e.center.y,
        };
        // Normal on ellipse: gradient of (x/rx)^2 + (y/ry)^2 = (2x/rx^2, 2y/ry^2)
        var normal = Point{
            .x = (p.x - e.center.x) / (e.radius.x * e.radius.x),
            .y = (p.y - e.center.y) / (e.radius.y * e.radius.y),
        };
        normal = normal.norm();
        // Ensure normal faces toward ray origin
        if (normal.dot(r.dir) > 0) {
            normal = .{ .x = -normal.x, .y = -normal.y };
        }
        // Compute world-space t: distance along original ray direction
        const world_t = p.sub(r.origin).dot(r.dir) / r.dir.dot(r.dir);
        return .{ .t = world_t, .point = p, .normal = normal };
    }
};

test "geom" {
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

    // Rectangle tests
    {
        const rect = Rectangle{ .x = 0.0, .y = 0.0, .width = 10.0, .height = 20.0 };
        try expectEqual(rect.toRegion(), Region{ .x = 0, .y = 0, .width = 10, .height = 20 });
        try expectEqual(rect.getPos(), Point{ .x = 0.0, .y = 0.0 });
        try expectEqual(rect.getSizeF(), Point{ .x = 10.0, .y = 20.0 });
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

        // padded
        const padded = rect.padded(2.0);
        try expect(padded.isSame(.{ .x = -2.0, .y = -2.0, .width = 14.0, .height = 24.0 }));

        // containsLine
        try expect(rect.containsLine(.{ .x = 1.0, .y = 1.0 }, .{ .x = 5.0, .y = 5.0 }));
        try expect(!rect.containsLine(.{ .x = -1.0, .y = 0.0 }, .{ .x = 5.0, .y = 5.0 }));

        // containsCircle
        try expect(rect.containsCircle(.{ .center = .{ .x = 5.0, .y = 10.0 }, .radius = 2.0 }));
        try expect(!rect.containsCircle(.{ .center = .{ .x = 0.0, .y = 0.0 }, .radius = 5.0 }));

        // containsTriangle
        try expect(rect.containsTriangle(.{
            .p0 = .{ .x = 1.0, .y = 1.0 },
            .p1 = .{ .x = 5.0, .y = 1.0 },
            .p2 = .{ .x = 3.0, .y = 5.0 },
        }));
        try expect(!rect.containsTriangle(.{
            .p0 = .{ .x = -1.0, .y = -1.0 },
            .p1 = .{ .x = 5.0, .y = 1.0 },
            .p2 = .{ .x = 3.0, .y = 5.0 },
        }));

        // SDL-dependent: hasIntersection
        try expect(rect.hasIntersection(.{ .x = 5.0, .y = 5.0, .width = 10.0, .height = 10.0 }));
        try expect(!rect.hasIntersection(.{ .x = 20.0, .y = 20.0, .width = 5.0, .height = 5.0 }));

        // SDL-dependent: intersectRect
        const isect = rect.intersectRect(.{ .x = 5.0, .y = 10.0, .width = 20.0, .height = 30.0 });
        try expect(isect != null);
        try expect(isect.?.isSame(.{ .x = 5.0, .y = 10.0, .width = 5.0, .height = 10.0 }));
        try expect(rect.intersectRect(.{ .x = 20.0, .y = 20.0, .width = 5.0, .height = 5.0 }) == null);

        // SDL-dependent: intersectLine
        const line_isect = rect.intersectLine(.{ .x = -5.0, .y = 10.0 }, .{ .x = 20.0, .y = 10.0 });
        try expect(line_isect != null);
        const clipped_p0, const clipped_p1 = line_isect.?;
        try expectApproxEqAbs(clipped_p0.x, 0.0, 0.000001);
        try expectApproxEqAbs(clipped_p1.x, 10.0, 0.000001);
        // line fully outside
        try expect(rect.intersectLine(.{ .x = -5.0, .y = -5.0 }, .{ .x = -1.0, .y = -5.0 }) == null);

        // SDL-dependent: intersectCircle (via Rectangle)
        try expect(rect.intersectCircle(.{ .center = .{ .x = 5.0, .y = 10.0 }, .radius = 1.0 }));
        try expect(!rect.intersectCircle(.{ .center = .{ .x = 50.0, .y = 50.0 }, .radius = 1.0 }));

        // SDL-dependent: intersectTriangle (via Rectangle)
        try expect(rect.intersectTriangle(.{
            .p0 = .{ .x = 5.0, .y = 5.0 },
            .p1 = .{ .x = 15.0, .y = 5.0 },
            .p2 = .{ .x = 10.0, .y = 15.0 },
        }));
        try expect(!rect.intersectTriangle(.{
            .p0 = .{ .x = 50.0, .y = 50.0 },
            .p1 = .{ .x = 55.0, .y = 50.0 },
            .p2 = .{ .x = 52.0, .y = 55.0 },
        }));
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

        // getBoundingRect
        try expect(c.getBoundingRect().isSame(.{ .x = -5.0, .y = -5.0, .width = 10.0, .height = 10.0 }));

        // intersectLine
        const line_through = Line{ .p0 = .{ .x = -10.0, .y = 0.0 }, .p1 = .{ .x = 10.0, .y = 0.0 } };
        try expect(c.intersectLine(line_through));
        try expect(!c.intersectLine(.{ .p0 = .{ .x = -10.0, .y = 10.0 }, .p1 = .{ .x = 10.0, .y = 10.0 } }));

        // intersectTriangle
        const tri_overlap = Triangle{
            .p0 = .{ .x = 3.0, .y = -3.0 },
            .p1 = .{ .x = 10.0, .y = -3.0 },
            .p2 = .{ .x = 6.0, .y = 3.0 },
        };
        try expect(c.intersectTriangle(tri_overlap));
        // triangle fully outside
        try expect(!c.intersectTriangle(.{
            .p0 = .{ .x = 10.0, .y = 10.0 },
            .p1 = .{ .x = 12.0, .y = 10.0 },
            .p2 = .{ .x = 11.0, .y = 12.0 },
        }));
        // circle center inside triangle
        const big_tri = Triangle{
            .p0 = .{ .x = -10.0, .y = -10.0 },
            .p1 = .{ .x = 10.0, .y = -10.0 },
            .p2 = .{ .x = 0.0, .y = 10.0 },
        };
        try expect(c.intersectTriangle(big_tri));
    }

    // Ellipse tests
    {
        const e = Ellipse{ .center = .origin, .radius = .{ .x = 5.0, .y = 3.0 } };
        try expectEqual(e.translate(.{ 1.0, 2.0 }), Ellipse{ .center = .{ .x = 1.0, .y = 2.0 }, .radius = .{ .x = 5.0, .y = 3.0 } });
        try expectApproxEqAbs(e.getFocalRadius2(), 16.0, 0.000001);
        try expectApproxEqAbs(e.getFocalRadius(), 4.0, 0.000001);
        try expect(e.containsPoint(.origin));
        try expect(!e.containsPoint(.{ .x = 6.0, .y = 0.0 })); // approximate
        try expect(e.intersectLine(.{ .p0 = .{ .x = -10.0, .y = 0.0 }, .p1 = .{ .x = 10.0, .y = 0.0 } }));
        try expect(!e.intersectLine(.{ .p0 = .{ .x = -10.0, .y = 5.0 }, .p1 = .{ .x = 10.0, .y = 5.0 } }));
        try expect(e.intersectCircle(.{ .center = .{ .x = 6.0, .y = 0.0 }, .radius = 2.0 }));
        try expect(!e.intersectCircle(.{ .center = .{ .x = 20.0, .y = 0.0 }, .radius = 2.0 }));
        try expect(e.intersectRect(.{ .x = 3.0, .y = -1.0, .width = 4.0, .height = 2.0 }));
        try expect(!e.intersectRect(.{ .x = 20.0, .y = 20.0, .width = 2.0, .height = 2.0 }));
        try expect(e.intersectTriangle(.{
            .p0 = .{ .x = 4.0, .y = -1.0 },
            .p1 = .{ .x = 8.0, .y = 0.0 },
            .p2 = .{ .x = 4.0, .y = 1.0 },
        }));
        try expect(!e.intersectTriangle(.{
            .p0 = .{ .x = 20.0, .y = 20.0 },
            .p1 = .{ .x = 22.0, .y = 20.0 },
            .p2 = .{ .x = 21.0, .y = 22.0 },
        }));
        try expect(e.intersectEllipse(.{ .center = .{ .x = 6.0, .y = 0.0 }, .radius = .{ .x = 2.5, .y = 1.0 } }));
        try expect(!e.intersectEllipse(.{ .center = .{ .x = 20.0, .y = 0.0 }, .radius = .{ .x = 1.0, .y = 1.0 } }));
        try expect(e.intersect(Point{ .x = 0.0, .y = 0.0 }));
        try expect(!e.intersect(Point{ .x = 10.0, .y = 0.0 }));
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
        try expectEqual(tri.getBoundingRect(), Rectangle{ .x = 0.0, .y = 0.0, .width = 4.0, .height = 3.0 });
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

        // intersectLine
        try expect(tri.intersectLine(.{ .p0 = .{ .x = 1.0, .y = -1.0 }, .p1 = .{ .x = 1.0, .y = 4.0 } })); // crosses edge
        try expect(tri.intersectLine(.{ .p0 = .{ .x = 1.0, .y = 0.5 }, .p1 = .{ .x = 3.0, .y = 0.5 } })); // fully inside
        try expect(!tri.intersectLine(.{ .p0 = .{ .x = 5.0, .y = 0.0 }, .p1 = .{ .x = 6.0, .y = 1.0 } })); // outside

        // intersectCircle
        try expect(tri.intersectCircle(.{ .center = .{ .x = 2.0, .y = 1.0 }, .radius = 0.5 })); // circle inside
        try expect(tri.intersectCircle(.{ .center = .{ .x = -0.5, .y = 0.0 }, .radius = 1.0 })); // overlaps edge
        try expect(!tri.intersectCircle(.{ .center = .{ .x = -2.0, .y = -2.0 }, .radius = 0.5 })); // far away
    }

    // Line tests
    {
        const l = Line{ .p0 = .{ .x = 0.0, .y = 0.0 }, .p1 = .{ .x = 4.0, .y = 0.0 } };
        try expectEqual(l.translate(.{ 1.0, 2.0 }), Line{ .p0 = .{ .x = 1.0, .y = 2.0 }, .p1 = .{ .x = 5.0, .y = 2.0 } });
        try expectEqual(l.direction(), Point{ .x = 1.0, .y = 0.0 });
        try expectApproxEqAbs(l.length2(), 16.0, 0.000001);
        try expectApproxEqAbs(l.length(), 4.0, 0.000001);
        try expectEqual(l.midpoint(), Point{ .x = 2.0, .y = 0.0 });
        try expectEqual(l.lerp(0.0), Point{ .x = 0.0, .y = 0.0 });
        try expectEqual(l.lerp(1.0), Point{ .x = 4.0, .y = 0.0 });
        try expectEqual(l.lerp(0.5), Point{ .x = 2.0, .y = 0.0 });

        // closestPoint
        const cp = l.closestPoint(.{ .x = 2.0, .y = 3.0 });
        try expectApproxEqAbs(cp.t, 0.5, 0.000001);
        try expectApproxEqAbs(cp.point.x, 2.0, 0.000001);
        try expectApproxEqAbs(cp.point.y, 0.0, 0.000001);
        // closestPoint clamped to p0
        const cp0 = l.closestPoint(.{ .x = -5.0, .y = 0.0 });
        try expectApproxEqAbs(cp0.t, 0.0, 0.000001);
        // closestPoint clamped to p1
        const cp1 = l.closestPoint(.{ .x = 10.0, .y = 0.0 });
        try expectApproxEqAbs(cp1.t, 1.0, 0.000001);
        // closestPoint on zero-length line
        const zero_line = Line{ .p0 = .{ .x = 1.0, .y = 1.0 }, .p1 = .{ .x = 1.0, .y = 1.0 } };
        const cpz = zero_line.closestPoint(.{ .x = 5.0, .y = 5.0 });
        try expectApproxEqAbs(cpz.t, 0.0, 0.000001);

        // getBoundingRect
        try expect(l.getBoundingRect().isSame(.{ .x = 0.0, .y = 0.0, .width = 4.0, .height = 0.0 }));
        const diag = Line{ .p0 = .{ .x = 1.0, .y = 3.0 }, .p1 = .{ .x = 5.0, .y = 1.0 } };
        try expect(diag.getBoundingRect().isSame(.{ .x = 1.0, .y = 1.0, .width = 4.0, .height = 2.0 }));

        // intersectLine
        const l2 = Line{ .p0 = .{ .x = 2.0, .y = -2.0 }, .p1 = .{ .x = 2.0, .y = 2.0 } };
        const isect = l.intersectLine(l2);
        try expect(isect != null);
        try expectApproxEqAbs(isect.?.x, 2.0, 0.000001);
        try expectApproxEqAbs(isect.?.y, 0.0, 0.000001);
        // parallel lines don't intersect
        const l3 = Line{ .p0 = .{ .x = 0.0, .y = 1.0 }, .p1 = .{ .x = 4.0, .y = 1.0 } };
        try expect(l.intersectLine(l3) == null);
        // non-overlapping segments don't intersect
        const l4 = Line{ .p0 = .{ .x = 2.0, .y = 1.0 }, .p1 = .{ .x = 2.0, .y = 5.0 } };
        try expect(l.intersectLine(l4) == null);

        // intersectCircle
        const c = Circle{ .center = .{ .x = 2.0, .y = 1.0 }, .radius = 2.0 };
        try expect(l.intersectCircle(c));
        try expect(!l.intersectCircle(.{ .center = .{ .x = 2.0, .y = 10.0 }, .radius = 1.0 }));

        // intersectRect
        try expect(l.intersectRect(.{ .x = 1.0, .y = -1.0, .width = 2.0, .height = 2.0 }));
        try expect(!l.intersectRect(.{ .x = 1.0, .y = 5.0, .width = 2.0, .height = 2.0 }));

        // intersectTriangle
        const tri = Triangle{
            .p0 = .{ .x = 1.0, .y = -1.0 },
            .p1 = .{ .x = 3.0, .y = -1.0 },
            .p2 = .{ .x = 2.0, .y = 1.0 },
        };
        try expect(l.intersectTriangle(tri));
        try expect(!l.intersectTriangle(.{
            .p0 = .{ .x = 10.0, .y = 10.0 },
            .p1 = .{ .x = 12.0, .y = 10.0 },
            .p2 = .{ .x = 11.0, .y = 12.0 },
        }));
        // line fully inside triangle
        const big_tri = Triangle{
            .p0 = .{ .x = -10.0, .y = -10.0 },
            .p1 = .{ .x = 10.0, .y = -10.0 },
            .p2 = .{ .x = 0.0, .y = 10.0 },
        };
        try expect(l.intersectTriangle(big_tri));

        // intersectEllipse
        const e = Ellipse{ .center = .{ .x = 2.0, .y = 0.0 }, .radius = .{ .x = 2.0, .y = 1.0 } };
        try expect(l.intersectEllipse(e));
        try expect(!l.intersectEllipse(.{ .center = .{ .x = 2.0, .y = 5.0 }, .radius = .{ .x = 2.0, .y = 1.0 } }));
    }

    // Ray tests
    {
        const r = Ray{ .origin = .{ .x = 0.0, .y = 0.0 }, .dir = .{ .x = 1.0, .y = 0.0 } };

        // init
        const r2 = Ray.init(.{ .x = 1.0, .y = 2.0 }, .{ .x = 3.0, .y = 4.0 });
        try expectApproxEqAbs(r2.origin.x, 1.0, 0.000001);
        try expectApproxEqAbs(r2.origin.y, 2.0, 0.000001);
        try expectApproxEqAbs(r2.dir.x, 0.70710678, 0.000001);
        try expectApproxEqAbs(r2.dir.y, 0.70710678, 0.000001);

        // at
        try expectEqual(r.at(0.0), Point{ .x = 0.0, .y = 0.0 });
        try expectEqual(r.at(5.0), Point{ .x = 5.0, .y = 0.0 });

        // intersectLine
        const seg = Line{ .p0 = .{ .x = 3.0, .y = -2.0 }, .p1 = .{ .x = 3.0, .y = 2.0 } };
        const hit = r.raycast(seg);
        try expect(hit != null);
        try expectApproxEqAbs(hit.?.t, 3.0, 0.000001);
        try expectApproxEqAbs(hit.?.point.x, 3.0, 0.000001);
        try expectApproxEqAbs(hit.?.point.y, 0.0, 0.000001);
        // normal should face toward ray origin (negative x direction)
        try expectApproxEqAbs(hit.?.normal.x, -1.0, 0.000001);
        try expectApproxEqAbs(hit.?.normal.y, 0.0, 0.000001);
        // ray misses segment behind it
        const seg_behind = Line{ .p0 = .{ .x = -3.0, .y = -2.0 }, .p1 = .{ .x = -3.0, .y = 2.0 } };
        try expect(r.raycast(seg_behind) == null);
        // parallel ray and segment
        const seg_par = Line{ .p0 = .{ .x = 0.0, .y = 1.0 }, .p1 = .{ .x = 5.0, .y = 1.0 } };
        try expect(r.raycast(seg_par) == null);

        // intersectCircle
        const c = Circle{ .center = .{ .x = 5.0, .y = 0.0 }, .radius = 1.0 };
        const chit = r.raycast(c);
        try expect(chit != null);
        try expectApproxEqAbs(chit.?.t, 4.0, 0.000001);
        try expectApproxEqAbs(chit.?.point.x, 4.0, 0.000001);
        try expectApproxEqAbs(chit.?.point.y, 0.0, 0.000001);
        // normal at hit point should point toward ray origin
        try expectApproxEqAbs(chit.?.normal.x, -1.0, 0.000001);
        try expectApproxEqAbs(chit.?.normal.y, 0.0, 0.000001);
        // ray misses circle
        try expect(r.raycast(Circle{ .center = .{ .x = 5.0, .y = 10.0 }, .radius = 1.0 }) == null);
        // ray origin inside circle - should still hit (exit point)
        const c_around = Circle{ .center = .{ .x = 0.0, .y = 0.0 }, .radius = 2.0 };
        const chit2 = r.raycast(c_around);
        try expect(chit2 != null);
        try expectApproxEqAbs(chit2.?.t, 2.0, 0.000001);

        // raycast Rectangle
        const rect = Rectangle{ .x = 3.0, .y = -1.0, .width = 2.0, .height = 2.0 };
        const rhit = r.raycast(rect);
        try expect(rhit != null);
        try expectApproxEqAbs(rhit.?.t, 3.0, 0.000001);
        try expectApproxEqAbs(rhit.?.point.x, 3.0, 0.000001);
        try expectApproxEqAbs(rhit.?.point.y, 0.0, 0.000001);
        try expectApproxEqAbs(rhit.?.normal.x, -1.0, 0.000001);
        try expectApproxEqAbs(rhit.?.normal.y, 0.0, 0.000001);
        // ray misses rectangle
        try expect(r.raycast(Rectangle{ .x = 3.0, .y = 5.0, .width = 2.0, .height = 2.0 }) == null);
        // ray origin inside rectangle
        @setEvalBranchQuota(2000);
        const inner_rect = Rectangle{ .x = -1.0, .y = -1.0, .width = 4.0, .height = 2.0 };
        const rhit2 = r.raycast(inner_rect);
        try expect(rhit2 != null);
        try expectApproxEqAbs(rhit2.?.point.x, 3.0, 0.000001);

        // raycast Triangle
        const tri = Triangle{ .p0 = .{ .x = 4.0, .y = -2.0 }, .p1 = .{ .x = 4.0, .y = 2.0 }, .p2 = .{ .x = 8.0, .y = 0.0 } };
        const thit = r.raycast(tri);
        try expect(thit != null);
        try expectApproxEqAbs(thit.?.t, 4.0, 0.000001);
        try expectApproxEqAbs(thit.?.point.x, 4.0, 0.000001);
        try expectApproxEqAbs(thit.?.point.y, 0.0, 0.000001);
        // ray misses triangle
        const tri_miss = Triangle{ .p0 = .{ .x = 4.0, .y = 5.0 }, .p1 = .{ .x = 6.0, .y = 5.0 }, .p2 = .{ .x = 5.0, .y = 7.0 } };
        try expect(r.raycast(tri_miss) == null);
        // ray origin inside triangle
        const tri_around = Triangle{ .p0 = .{ .x = -2.0, .y = -2.0 }, .p1 = .{ .x = -2.0, .y = 2.0 }, .p2 = .{ .x = 4.0, .y = 0.0 } };
        const thit2 = r.raycast(tri_around);
        try expect(thit2 != null);
        try expectApproxEqAbs(thit2.?.point.x, 4.0, 0.000001);

        // raycast Ellipse
        const e = Ellipse{ .center = .{ .x = 5.0, .y = 0.0 }, .radius = .{ .x = 2.0, .y = 1.0 } };
        const ehit = r.raycast(e);
        try expect(ehit != null);
        try expectApproxEqAbs(ehit.?.t, 3.0, 0.000001);
        try expectApproxEqAbs(ehit.?.point.x, 3.0, 0.000001);
        try expectApproxEqAbs(ehit.?.point.y, 0.0, 0.000001);
        try expectApproxEqAbs(ehit.?.normal.x, -1.0, 0.000001);
        try expectApproxEqAbs(ehit.?.normal.y, 0.0, 0.000001);
        // ray origin inside ellipse
        const inner_e = Ellipse{ .center = .{ .x = 0.0, .y = 0.0 }, .radius = .{ .x = 2.0, .y = 1.0 } };
        const ehit2 = r.raycast(inner_e);
        try expect(ehit2 != null);
        try expectApproxEqAbs(ehit2.?.t, 2.0, 0.000001);
    }

    // Point: toVector round-trip
    {
        const p = Point{ .x = 3.5, .y = -2.0 };
        const v = p.toVector();
        const back = v.toPoint();
        try expect(p.isSame(back));
    }

    // Point: add/sub/mul with Point argument (not just tuple)
    {
        const a = Point{ .x = 1.0, .y = 2.0 };
        const b = Point{ .x = 3.0, .y = 4.0 };
        try expectEqual(a.add(b), Point{ .x = 4.0, .y = 6.0 });
        try expectEqual(a.sub(b), Point{ .x = -2.0, .y = -2.0 });
        try expectEqual(a.mul(b), Point{ .x = 3.0, .y = 8.0 });
        // with array
        try expectEqual(a.add([2]f32{ 3.0, 4.0 }), Point{ .x = 4.0, .y = 6.0 });
    }

    // Point.isSame: x matches but y differs
    {
        const a = Point{ .x = 1.0, .y = 2.0 };
        try expect(!a.isSame(.{ .x = 1.0, .y = 2.1 }));
        // negative coordinates
        try expect((Point{ .x = -1.0, .y = -2.0 }).isSame(.{ .x = -1.0, .y = -2.0 }));
    }

    // Size: toRegion, toRect
    {
        const s = Size{ .width = 10, .height = 20 };
        const reg = s.toRegion(5, 15);
        try expectEqual(reg, Region{ .x = 5, .y = 15, .width = 10, .height = 20 });
        const rect = s.toRect(.{ .x = 1.5, .y = 2.5 });
        try expect(rect.isSame(.{ .x = 1.5, .y = 2.5, .width = 10.0, .height = 20.0 }));
    }

    // Size.isSame: width differs but height matches
    {
        const s = Size{ .width = 10, .height = 20 };
        try expect(!s.isSame(.{ .width = 11, .height = 20 }));
    }

    // Region.isSame: each field differs individually
    {
        const r = Region{ .x = 5, .y = 10, .width = 15, .height = 25 };
        try expect(!r.isSame(.{ .x = 6, .y = 10, .width = 15, .height = 25 }));
        try expect(!r.isSame(.{ .x = 5, .y = 11, .width = 15, .height = 25 }));
        try expect(!r.isSame(.{ .x = 5, .y = 10, .width = 16, .height = 25 }));
    }

    // Rectangle.isSame: false case and near-tolerance
    {
        const r = Rectangle{ .x = 1.0, .y = 2.0, .width = 3.0, .height = 4.0 };
        try expect(!r.isSame(.{ .x = 1.1, .y = 2.0, .width = 3.0, .height = 4.0 }));
        // near tolerance - should still be same
        try expect(r.isSame(.{ .x = 1.0000005, .y = 2.0, .width = 3.0, .height = 4.0 }));
    }

    // Rectangle.containsPoint: point on top-left edge (inclusive)
    {
        const rect = Rectangle{ .x = 0.0, .y = 0.0, .width = 10.0, .height = 20.0 };
        try expect(rect.containsPoint(.{ .x = 0.0, .y = 0.0 })); // top-left corner (>= check)
        try expect(!rect.containsPoint(.{ .x = 10.0, .y = 0.0 })); // right edge (< check)
        try expect(!rect.containsPoint(.{ .x = 0.0, .y = 20.0 })); // bottom edge (< check)
        try expect(rect.containsPoint(.{ .x = 0.0, .y = 19.999 })); // just inside bottom
    }

    // Rectangle.translate/scale with Point argument
    {
        const rect = Rectangle{ .x = 1.0, .y = 2.0, .width = 3.0, .height = 4.0 };
        try expectEqual(rect.translate(Point{ .x = 5.0, .y = 6.0 }), Rectangle{ .x = 6.0, .y = 8.0, .width = 3.0, .height = 4.0 });
        try expectEqual(rect.scale(Point{ .x = 2.0, .y = 3.0 }), Rectangle{ .x = 1.0, .y = 2.0, .width = 6.0, .height = 12.0 });
    }

    // Rectangle.intersectRect: one fully inside another
    {
        const outer = Rectangle{ .x = 0.0, .y = 0.0, .width = 10.0, .height = 10.0 };
        const inner = Rectangle{ .x = 2.0, .y = 2.0, .width = 3.0, .height = 3.0 };
        const isect = outer.intersectRect(inner);
        try expect(isect != null);
        try expect(isect.?.isSame(inner));
    }

    // Circle.containsPoint: point on boundary (should be false, uses <)
    {
        const c = Circle{ .center = .{ .x = 0.0, .y = 0.0 }, .radius = 5.0 };
        try expect(!c.containsPoint(.{ .x = 5.0, .y = 0.0 }));
        try expect(!c.containsPoint(.{ .x = 0.0, .y = 5.0 }));
        // just inside
        try expect(c.containsPoint(.{ .x = 4.999, .y = 0.0 }));
        // just outside
        try expect(!c.containsPoint(.{ .x = 5.001, .y = 0.0 }));
    }

    // Circle.intersectCircle: exactly touching (distance == r0+r1, uses <=)
    {
        const c0 = Circle{ .center = .{ .x = 0.0, .y = 0.0 }, .radius = 3.0 };
        const c1 = Circle{ .center = .{ .x = 5.0, .y = 0.0 }, .radius = 2.0 };
        try expect(c0.intersectCircle(c1)); // exactly touching
        // one circle fully inside another
        const c_inner = Circle{ .center = .{ .x = 1.0, .y = 0.0 }, .radius = 1.0 };
        try expect(c0.intersectCircle(c_inner));
    }

    // Circle.intersectRect: circle fully inside rectangle
    {
        const c = Circle{ .center = .{ .x = 5.0, .y = 5.0 }, .radius = 1.0 };
        try expect(c.intersectRect(.{ .x = 0.0, .y = 0.0, .width = 10.0, .height = 10.0 }));
    }

    // Ellipse.getBoundingRect
    {
        const e = Ellipse{ .center = .{ .x = 3.0, .y = 4.0 }, .radius = .{ .x = 5.0, .y = 2.0 } };
        try expect(e.getBoundingRect().isSame(.{ .x = -2.0, .y = 2.0, .width = 10.0, .height = 4.0 }));
    }

    // Ellipse.getFocalRadius: ry > rx branch
    {
        const e = Ellipse{ .center = .origin, .radius = .{ .x = 3.0, .y = 5.0 } };
        try expectApproxEqAbs(e.getFocalRadius2(), 16.0, 0.000001); // 25 - 9
        try expectApproxEqAbs(e.getFocalRadius(), 4.0, 0.000001);
    }

    // Ellipse.getFocalRadius: equal radius (circle, focal radius = 0)
    {
        const e = Ellipse{ .center = .origin, .radius = .{ .x = 3.0, .y = 3.0 } };
        try expectApproxEqAbs(e.getFocalRadius2(), 0.0, 0.000001);
        try expectApproxEqAbs(e.getFocalRadius(), 0.0, 0.000001);
    }

    // Ellipse.containsPoint: along y-axis, on boundary
    {
        const e = Ellipse{ .center = .origin, .radius = .{ .x = 5.0, .y = 3.0 } };
        try expect(e.containsPoint(.{ .x = 0.0, .y = 2.0 })); // inside along y
        try expect(!e.containsPoint(.{ .x = 0.0, .y = 3.0 })); // on boundary (uses <)
        try expect(!e.containsPoint(.{ .x = 0.0, .y = 3.001 })); // just outside
    }

    // Triangle.barycentricCoord: vertex and outside point
    {
        const tri = Triangle{
            .p0 = .{ .x = 0.0, .y = 0.0 },
            .p1 = .{ .x = 4.0, .y = 0.0 },
            .p2 = .{ .x = 2.0, .y = 3.0 },
        };
        // at vertex p1: u=0, v=1, w=0
        const bc1 = tri.barycentricCoord(tri.p1);
        try expectApproxEqAbs(bc1[1], 1.0, 0.001);
        try expectApproxEqAbs(bc1[0], 0.0, 0.001);
        try expectApproxEqAbs(bc1[2], 0.0, 0.001);
        // outside point: at least one negative
        const bc_out = tri.barycentricCoord(.{ .x = -1.0, .y = -1.0 });
        try expect(bc_out[0] < 0 or bc_out[1] < 0 or bc_out[2] < 0);
    }

    // Triangle.containsPoint: point on edge (should be false, uses > 0)
    {
        const tri = Triangle{
            .p0 = .{ .x = 0.0, .y = 0.0 },
            .p1 = .{ .x = 4.0, .y = 0.0 },
            .p2 = .{ .x = 2.0, .y = 3.0 },
        };
        try expect(!tri.containsPoint(.{ .x = 2.0, .y = 0.0 })); // midpoint of edge p0-p1
        try expect(!tri.containsPoint(tri.p0)); // vertex
    }

    // Triangle.intersectTriangle: one fully inside another
    {
        const big = Triangle{
            .p0 = .{ .x = 0.0, .y = 0.0 },
            .p1 = .{ .x = 10.0, .y = 0.0 },
            .p2 = .{ .x = 5.0, .y = 10.0 },
        };
        const small = Triangle{
            .p0 = .{ .x = 4.0, .y = 1.0 },
            .p1 = .{ .x = 6.0, .y = 1.0 },
            .p2 = .{ .x = 5.0, .y = 3.0 },
        };
        try expect(big.intersectTriangle(small));
    }

    // Triangle.intersectRect: rect fully inside triangle
    {
        const tri = Triangle{
            .p0 = .{ .x = 0.0, .y = 0.0 },
            .p1 = .{ .x = 20.0, .y = 0.0 },
            .p2 = .{ .x = 10.0, .y = 20.0 },
        };
        try expect(tri.intersectRect(.{ .x = 8.0, .y = 2.0, .width = 4.0, .height = 4.0 }));
    }

    // Line.direction: vertical and diagonal
    {
        const vert = Line{ .p0 = .{ .x = 0.0, .y = 0.0 }, .p1 = .{ .x = 0.0, .y = 5.0 } };
        try expect(vert.direction().isSame(.{ .x = 0.0, .y = 1.0 }));
        const diag = Line{ .p0 = .{ .x = 0.0, .y = 0.0 }, .p1 = .{ .x = 1.0, .y = 1.0 } };
        const d = diag.direction();
        const inv_sqrt2 = 1.0 / @sqrt(2.0);
        try expectApproxEqAbs(d.x, inv_sqrt2, 0.000001);
        try expectApproxEqAbs(d.y, inv_sqrt2, 0.000001);
    }

    // Line.intersectLine: T-intersection (endpoint touching midpoint)
    {
        const l0 = Line{ .p0 = .{ .x = 0.0, .y = 0.0 }, .p1 = .{ .x = 4.0, .y = 0.0 } };
        const l1 = Line{ .p0 = .{ .x = 2.0, .y = -2.0 }, .p1 = .{ .x = 2.0, .y = 0.0 } };
        const isect = l0.intersectLine(l1);
        try expect(isect != null);
        try expectApproxEqAbs(isect.?.x, 2.0, 0.000001);
        try expectApproxEqAbs(isect.?.y, 0.0, 0.000001);
    }

    // Ray.raycast(Line): ray hitting endpoint of segment
    {
        const r = Ray{ .origin = .{ .x = 0.0, .y = 0.0 }, .dir = .{ .x = 1.0, .y = 0.0 } };
        const seg = Line{ .p0 = .{ .x = 5.0, .y = -1.0 }, .p1 = .{ .x = 5.0, .y = 0.0 } };
        const hit = r.raycast(seg);
        try expect(hit != null);
        try expectApproxEqAbs(hit.?.t, 5.0, 0.000001);
    }

    // Point.toSize: rounding behavior
    {
        const p = Point{ .x = 1.4, .y = 2.6 };
        try expectEqual(p.toSize(), Size{ .width = 1, .height = 3 });
        const p2 = Point{ .x = 0.5, .y = 1.5 };
        try expectEqual(p2.toSize(), Size{ .width = 1, .height = 2 }); // round half away from zero
    }

    // Rectangle.toRegion: rounding behavior
    {
        const r = Rectangle{ .x = 0.4, .y = 1.6, .width = 2.5, .height = 3.3 };
        const reg = r.toRegion();
        try expectEqual(reg, Region{ .x = 0, .y = 2, .width = 3, .height = 3 });
    }

    // Rectangle.padded: negative padding (shrink)
    {
        const rect = Rectangle{ .x = 0.0, .y = 0.0, .width = 10.0, .height = 10.0 };
        const shrunk = rect.padded(-2.0);
        try expect(shrunk.isSame(.{ .x = 2.0, .y = 2.0, .width = 6.0, .height = 6.0 }));
    }

    // Degenerate triangle: collinear points
    {
        const degen = Triangle{
            .p0 = .{ .x = 0.0, .y = 0.0 },
            .p1 = .{ .x = 2.0, .y = 0.0 },
            .p2 = .{ .x = 4.0, .y = 0.0 },
        };
        try expect(degen.isDegenerate());
        try expectApproxEqAbs(degen.area(), 0.0, 0.000001);
        // barycentricCoord returns {-1,-1,-1} for degenerate triangle
        const bc = degen.barycentricCoord(.{ .x = 1.0, .y = 0.0 });
        try expectApproxEqAbs(bc[0], -1.0, 0.000001);
        try expectApproxEqAbs(bc[1], -1.0, 0.000001);
        try expectApproxEqAbs(bc[2], -1.0, 0.000001);
        // containsPoint should return false for degenerate triangle
        try expect(!degen.containsPoint(.{ .x = 1.0, .y = 0.0 }));
    }

    // Ray: diagonal direction
    {
        const inv_sqrt2 = 1.0 / @sqrt(2.0);
        const r = Ray{ .origin = .{ .x = 0.0, .y = 0.0 }, .dir = .{ .x = inv_sqrt2, .y = inv_sqrt2 } };
        const p = r.at(std.math.sqrt(2.0));
        try expectApproxEqAbs(p.x, 1.0, 0.000001);
        try expectApproxEqAbs(p.y, 1.0, 0.000001);

        // diagonal ray hitting a circle
        const c = Circle{ .center = .{ .x = 3.0, .y = 3.0 }, .radius = 1.0 };
        const hit = r.raycast(c);
        try expect(hit != null);
        // hit point should be on the circle surface, distance from center == radius
        const dx = hit.?.point.x - 3.0;
        const dy = hit.?.point.y - 3.0;
        try expectApproxEqAbs(@sqrt(dx * dx + dy * dy), 1.0, 0.001);
    }

    // Ray: origin inside circle - normal direction
    {
        const r = Ray{ .origin = .{ .x = 0.0, .y = 0.0 }, .dir = .{ .x = 1.0, .y = 0.0 } };
        const c = Circle{ .center = .{ .x = 0.0, .y = 0.0 }, .radius = 5.0 };
        const hit = r.raycast(c);
        try expect(hit != null);
        try expectApproxEqAbs(hit.?.t, 5.0, 0.000001);
        try expectApproxEqAbs(hit.?.point.x, 5.0, 0.000001);
        // normal should face toward ray origin (against ray direction)
        try expectApproxEqAbs(hit.?.normal.x, -1.0, 0.000001);
        try expectApproxEqAbs(hit.?.normal.y, 0.0, 0.000001);
    }

    // intersect dispatcher tests
    {
        const rect = Rectangle{ .x = 0.0, .y = 0.0, .width = 10.0, .height = 10.0 };
        const c = Circle{ .center = .{ .x = 5.0, .y = 5.0 }, .radius = 2.0 };
        const e = Ellipse{ .center = .{ .x = 5.0, .y = 5.0 }, .radius = .{ .x = 3.0, .y = 2.0 } };
        const tri = Triangle{
            .p0 = .{ .x = 1.0, .y = 1.0 },
            .p1 = .{ .x = 5.0, .y = 1.0 },
            .p2 = .{ .x = 3.0, .y = 5.0 },
        };
        const l = Line{ .p0 = .{ .x = -1.0, .y = 5.0 }, .p1 = .{ .x = 11.0, .y = 5.0 } };
        const p_in = Point{ .x = 5.0, .y = 5.0 };
        const p_out = Point{ .x = 50.0, .y = 50.0 };

        // Rectangle.intersect
        try expect(rect.intersect(Rectangle{ .x = 5.0, .y = 5.0, .width = 10.0, .height = 10.0 }));
        try expect(!rect.intersect(Rectangle{ .x = 20.0, .y = 20.0, .width = 5.0, .height = 5.0 }));
        try expect(rect.intersect(c));
        try expect(rect.intersect(e));
        try expect(!rect.intersect(Circle{ .center = .{ .x = 50.0, .y = 50.0 }, .radius = 1.0 }));
        try expect(!rect.intersect(Ellipse{ .center = .{ .x = 50.0, .y = 50.0 }, .radius = .{ .x = 2.0, .y = 1.0 } }));
        try expect(rect.intersect(tri));
        try expect(rect.intersect(l));
        try expect(!rect.intersect(Line{ .p0 = .{ .x = -5.0, .y = -5.0 }, .p1 = .{ .x = -1.0, .y = -5.0 } }));
        try expect(rect.intersect(p_in));
        try expect(!rect.intersect(p_out));

        // Circle.intersect
        try expect(c.intersect(rect));
        try expect(c.intersect(Circle{ .center = .{ .x = 6.0, .y = 5.0 }, .radius = 1.0 }));
        try expect(!c.intersect(Circle{ .center = .{ .x = 50.0, .y = 50.0 }, .radius = 1.0 }));
        try expect(c.intersect(tri));
        try expect(c.intersect(l));
        try expect(!c.intersect(Line{ .p0 = .{ .x = 50.0, .y = 50.0 }, .p1 = .{ .x = 51.0, .y = 51.0 } }));
        try expect(c.intersect(p_in));
        try expect(!c.intersect(p_out));
        try expect(c.intersect(e));
        try expect(!c.intersect(Ellipse{ .center = .{ .x = 50.0, .y = 50.0 }, .radius = .{ .x = 2.0, .y = 1.0 } }));

        // Ellipse.intersect
        try expect(e.intersect(rect));
        try expect(e.intersect(c));
        try expect(e.intersect(Ellipse{ .center = .{ .x = 7.0, .y = 5.0 }, .radius = .{ .x = 2.0, .y = 1.0 } }));
        try expect(!e.intersect(Ellipse{ .center = .{ .x = 50.0, .y = 50.0 }, .radius = .{ .x = 2.0, .y = 1.0 } }));
        try expect(e.intersect(tri));
        try expect(e.intersect(l));
        try expect(!e.intersect(Line{ .p0 = .{ .x = 50.0, .y = 50.0 }, .p1 = .{ .x = 51.0, .y = 51.0 } }));
        try expect(e.intersect(p_in));
        try expect(!e.intersect(p_out));

        // Triangle.intersect
        try expect(tri.intersect(rect));
        try expect(tri.intersect(c));
        try expect(tri.intersect(Triangle{
            .p0 = .{ .x = 2.0, .y = 2.0 },
            .p1 = .{ .x = 4.0, .y = 2.0 },
            .p2 = .{ .x = 3.0, .y = 4.0 },
        }));
        try expect(!tri.intersect(Triangle{
            .p0 = .{ .x = 50.0, .y = 50.0 },
            .p1 = .{ .x = 55.0, .y = 50.0 },
            .p2 = .{ .x = 52.0, .y = 55.0 },
        }));
        try expect(tri.intersect(Point{ .x = 3.0, .y = 2.0 }));
        try expect(!tri.intersect(p_out));
        try expect(tri.intersect(l));
        try expect(!tri.intersect(Line{ .p0 = .{ .x = 50.0, .y = 50.0 }, .p1 = .{ .x = 51.0, .y = 51.0 } }));

        // Line.intersect
        try expect(l.intersect(rect));
        try expect(l.intersect(c));
        try expect(l.intersect(tri));
        try expect(!l.intersect(Triangle{
            .p0 = .{ .x = 50.0, .y = 50.0 },
            .p1 = .{ .x = 55.0, .y = 50.0 },
            .p2 = .{ .x = 52.0, .y = 55.0 },
        }));
        try expect(l.intersect(Line{ .p0 = .{ .x = 5.0, .y = 0.0 }, .p1 = .{ .x = 5.0, .y = 10.0 } }));
        try expect(!l.intersect(Line{ .p0 = .{ .x = 0.0, .y = 6.0 }, .p1 = .{ .x = 20.0, .y = 6.0 } }));
    }
}
