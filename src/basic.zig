const std = @import("std");
const assert = std.debug.assert;
const math = std.math;
const jok = @import("jok.zig");
const sdl = jok.sdl;
const zmath = jok.zmath;
const minAndMax = jok.utils.math.minAndMax;

pub const Point = extern struct {
    pub const origin = Point{ .x = 0, .y = 0 };
    pub const unit = Point{ .x = 1, .y = 1 };
    pub const up = Point{ .x = 0, .y = -1 };
    pub const down = Point{ .x = 0, .y = 1 };
    pub const left = Point{ .x = -1, .y = 0 };
    pub const right = Point{ .x = 1, .y = 0 };
    pub const anchor_top_left = Point{ .x = 0, .y = 0 };
    pub const anchor_top_right = Point{ .x = 1, .y = 0 };
    pub const anchor_bottom_left = Point{ .x = 0, .y = 1 };
    pub const anchor_bottom_right = Point{ .x = 1, .y = 1 };
    pub const anchor_center = Point{ .x = 0.5, .y = 0.5 };

    x: f32,
    y: f32,

    pub inline fn toArray(p: Point) [2]f32 {
        return .{ p.x, p.y };
    }

    pub inline fn toSize(p: Point) Size {
        return .{
            .width = @intCast(@round(p.x)),
            .height = @intCast(@round(p.y)),
        };
    }

    pub inline fn angle(p: Point) f32 {
        return math.atan2(p.y, p.x);
    }

    pub inline fn angleDegree(p: Point) f32 {
        return math.radiansToDegrees(math.atan2(p.y, p.x));
    }

    pub inline fn add(p0: Point, v: [2]f32) Point {
        return .{
            .x = p0.x + v[0],
            .y = p0.y + v[1],
        };
    }

    pub inline fn sub(p0: Point, v: [2]f32) Point {
        return .{
            .x = p0.x - v[0],
            .y = p0.y - v[1],
        };
    }

    pub inline fn mul(p0: Point, v: [2]f32) Point {
        return .{
            .x = p0.x * v[0],
            .y = p0.y * v[1],
        };
    }

    pub inline fn scale(p0: Point, s: f32) Point {
        return .{
            .x = p0.x * s,
            .y = p0.y * s,
        };
    }

    pub inline fn isSame(p0: Point, p1: Point) bool {
        const tolerance = 0.000001;
        return std.math.approxEqAbs(f32, p0.x, p1.x, tolerance) and
            std.math.approxEqAbs(f32, p0.y, p1.y, tolerance);
    }

    pub inline fn distance2(p0: Point, p1: Point) f32 {
        return (p0.x - p1.x) * (p0.x - p1.x) + (p0.y - p1.y) * (p0.y - p1.y);
    }

    pub inline fn distance(p0: Point, p1: Point) f32 {
        return @sqrt(distance2(p0, p1));
    }
};

pub const Size = extern struct {
    width: u32,
    height: u32,

    pub inline fn toPoint(s: Size) Point {
        return .{ .x = @floatFromInt(s.width), .y = @floatFromInt(s.height) };
    }

    pub inline fn getWidthFloat(s: Size) f32 {
        return @as(f32, @floatFromInt(s.width));
    }

    pub inline fn getHeightFloat(s: Size) f32 {
        return @as(f32, @floatFromInt(s.height));
    }

    pub inline fn isSame(s0: Size, s1: Size) bool {
        return s0.width == s1.width and s0.height == s1.height;
    }

    pub inline fn area(s: Size) u32 {
        return s.width * s.height;
    }
};

pub const Region = extern struct {
    x: u32,
    y: u32,
    width: u32,
    height: u32,

    pub inline fn toRect(r: Region) Rectangle {
        return .{
            .x = @floatFromInt(r.x),
            .y = @floatFromInt(r.y),
            .width = @floatFromInt(r.width),
            .height = @floatFromInt(r.height),
        };
    }

    pub inline fn isSame(r0: Region, r1: Region) bool {
        return r0.x == r1.x and r0.y == r1.y and
            r0.width == r1.width and r0.height == r1.height;
    }

    pub inline fn area(r: Region) u32 {
        return r.width * r.height;
    }
};

pub const Rectangle = extern struct {
    x: f32,
    y: f32,
    width: f32,
    height: f32,

    pub inline fn toRegion(r: Rectangle) Region {
        return .{
            .x = @intCast(@round(r.x)),
            .y = @intCast(@round(r.y)),
            .width = @intCast(@round(r.width)),
            .height = @intCast(@round(r.height)),
        };
    }

    pub inline fn getPos(r: Rectangle) jok.Point {
        return .{ .x = r.x, .y = r.y };
    }

    pub inline fn getSize(r: Rectangle) jok.Point {
        return .{ .x = r.width, .y = r.height };
    }

    pub inline fn getTopLeft(r: Rectangle) jok.Point {
        return .{ .x = r.x, .y = r.y };
    }

    pub inline fn getTopRight(r: Rectangle) jok.Point {
        return .{ .x = r.x + r.width - 1, .y = r.y };
    }

    pub inline fn getBottomLeft(r: Rectangle) jok.Point {
        return .{ .x = r.x, .y = r.y + r.height - 1 };
    }

    pub inline fn getBottomRight(r: Rectangle) jok.Point {
        return .{ .x = r.x + r.width - 1, .y = r.y + r.height - 1 };
    }

    pub inline fn getCenter(r: Rectangle) jok.Point {
        return .{ .x = @floor(r.x + r.width * 0.5), .y = @floor(r.y + r.height * 0.5) };
    }

    pub inline fn translate(r: Rectangle, v: [2]f32) Rectangle {
        return .{
            .x = r.x + v[0],
            .y = r.y + v[1],
            .width = r.width,
            .height = r.height,
        };
    }

    pub inline fn scale(r: Rectangle, v: [2]f32) Rectangle {
        return .{
            .x = r.x,
            .y = r.y,
            .width = r.width * v[0],
            .height = r.height * v[1],
        };
    }

    pub inline fn isSame(r0: Rectangle, r1: Rectangle) bool {
        const tolerance = 0.000001;
        return std.math.approxEqAbs(f32, r0.x, r1.x, tolerance) and
            std.math.approxEqAbs(f32, r0.y, r1.y, tolerance) and
            std.math.approxEqAbs(f32, r0.width, r1.width, tolerance) and
            std.math.approxEqAbs(f32, r0.height, r1.height, tolerance);
    }

    pub inline fn area(r: Rectangle) f32 {
        return r.width * r.height;
    }

    pub inline fn hasIntersection(r: Rectangle, b: Rectangle) bool {
        if (sdl.c.SDL_HasRectIntersectionFloat(@ptrCast(&r), @ptrCast(&b)) == 1) {
            return true;
        }
        return false;
    }

    pub inline fn intersectRect(r: Rectangle, b: Rectangle) ?Rectangle {
        var result: Rectangle = undefined;
        if (sdl.c.SDL_GetRectIntersectionFloat(@ptrCast(&r), @ptrCast(&b), @ptrCast(&result)) == 1) {
            return result;
        }
        return null;
    }

    pub inline fn intersectLine(r: Rectangle, _p0: Point, _p1: Point) ?std.meta.Tuple(&.{ Point, Point }) {
        var p0: Point = _p0;
        var p1: Point = _p1;
        if (sdl.c.SDL_GetRectAndLineIntersectionFloat(@ptrCast(&r), &p0.x, &p0.y, &p1.x, &p1.y) == 1) {
            return .{ p0, p1 };
        }
        return null;
    }

    pub inline fn intersectCircle(r: Rectangle, c: Circle) bool {
        return c.intersectRect(r);
    }

    pub inline fn containsPoint(r: Rectangle, p: Point) bool {
        return p.x >= r.x and p.x < r.x + r.width and
            p.y >= r.y and p.y < r.y + r.height;
    }

    pub inline fn containsRect(r: Rectangle, b: Rectangle) bool {
        return b.x >= r.x and b.x + b.width <= r.x + r.width and
            b.y >= r.y and b.y + b.height <= r.y + r.height;
    }
};

pub const Circle = extern struct {
    center: Point = .origin,
    radius: f32 = 1,

    pub inline fn translate(c: Circle, v: [2]f32) Circle {
        return .{
            .center = c.center.add(v),
            .radius = c.radius,
        };
    }

    pub inline fn containsPoint(c: Circle, p: Point) bool {
        const v: @Vector(2, f32) = .{ c.center.x - p.x, c.center.y - p.y };
        return @reduce(.Add, v * v) < c.radius * c.radius;
    }

    pub inline fn intersectCircle(c0: Circle, c1: Circle) bool {
        const r = c0.radius + c1.radius;
        return c0.center.distance2(c1.center) < r * r;
    }

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
};

pub const Ellipse = struct {
    center: Point = .origin,
    radius: Point = .unit,

    pub inline fn translate(e: Ellipse, v: [2]f32) Circle {
        return .{
            .center = e.center.add(v),
            .radius = e.radius,
        };
    }

    pub inline fn getFocalRadius2(e: Ellipse) f32 {
        return if (e.radius.x > e.radius.y)
            e.radius.x * e.radius.x - e.radius.y * e.radius.y
        else
            e.radius.y * e.radius.y - e.radius.x * e.radius.x;
    }

    pub inline fn getFocalRadius(e: Ellipse) f32 {
        return @sqrt(e.getFocalRadius2());
    }

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

pub const Triangle = extern struct {
    p0: Point,
    p1: Point,
    p2: Point,

    pub inline fn translate(tri: Triangle, v: [2]f32) Triangle {
        return .{
            .p0 = tri.p0.add(v),
            .p1 = tri.p1.add(v),
            .p2 = tri.p2.add(v),
        };
    }

    pub inline fn area(tri: Triangle) f32 {
        const x1 = tri.p0.x;
        const y1 = tri.p0.y;
        const x2 = tri.p1.x;
        const y2 = tri.p1.y;
        const x3 = tri.p2.x;
        const y3 = tri.p2.y;
        return @abs(x1 * y2 + x2 * y3 + x3 * y1 - x2 * y1 - x3 * y2 - x1 * y3) / 2;
    }

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

    /// Calculate Barycentric coordinate, checkout link https://blackpawn.com/texts/pointinpoly
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

    /// Test whether a point is in triangle
    pub inline fn containsPoint(tri: Triangle, point: Point) bool {
        const p = tri.barycentricCoord(point);
        return p[0] >= 0 and p[1] >= 0 and p[2] >= 0;
    }

    pub inline fn containsTriangle(tri0: Triangle, tri1: Triangle) bool {
        return tri0.containsPoint(tri1.p0) and
            tri0.containsPoint(tri1.p1) and
            tri0.containsPoint(tri1.p2);
    }

    pub inline fn intersectTriangle(tri0: Triangle, tri1: Triangle) bool {
        const S = struct {
            const Range = std.meta.Tuple(&[_]type{ f32, f32 });

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
};

pub const Color = extern struct {
    pub const ParseError = error{
        UnknownFormat,
    };
    pub const none = rgba(0x00, 0x00, 0x00, 0x00);
    pub const black = rgb(0x00, 0x00, 0x00);
    pub const white = rgb(0xFF, 0xFF, 0xFF);
    pub const red = rgb(0xFF, 0x00, 0x00);
    pub const green = rgb(0x00, 0xFF, 0x00);
    pub const blue = rgb(0x00, 0x00, 0xFF);
    pub const magenta = rgb(0xFF, 0x00, 0xFF);
    pub const cyan = rgb(0x00, 0xFF, 0xFF);
    pub const yellow = rgb(0xFF, 0xFF, 0x00);
    pub const purple = rgb(255, 128, 255);

    r: u8,
    g: u8,
    b: u8,
    a: u8 = 255,

    pub inline fn rgb(r: u8, g: u8, b: u8) Color {
        return Color{ .r = r, .g = g, .b = b };
    }

    pub inline fn rgba(r: u8, g: u8, b: u8, a: u8) Color {
        return Color{ .r = r, .g = g, .b = b, .a = a };
    }

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

    pub inline fn toColorF(_c: Color) ColorF {
        var c: @Vector(4, f32) = .{
            @floatFromInt(_c.r),
            @floatFromInt(_c.g),
            @floatFromInt(_c.b),
            @floatFromInt(_c.a),
        };
        const multiplier: @Vector(4, f32) = @splat(1.0 / 255.0);
        c *= multiplier;
        return .{ .r = c[0], .g = c[1], .b = c[2], .a = c[3] };
    }

    inline fn getPixelFormatDetails() [*c]sdl.c.SDL_PixelFormatDetails {
        const S = struct {
            var pixel_format: ?[*c]sdl.c.SDL_PixelFormatDetails = null;
        };
        if (S.pixel_format == null) {
            S.pixel_format = sdl.c.SDL_GetPixelFormatDetails(sdl.c.SDL_PIXELFORMAT_RGBA32);
        }
        return S.pixel_format.?;
    }

    pub inline fn fromRGBA32(i: u32) Color {
        var c: Color = undefined;
        sdl.c.SDL_GetRGBA(i, getPixelFormatDetails(), &c.r, &c.g, &c.b, &c.a);
        return c;
    }

    pub inline fn toRGBA32(c: Color) u32 {
        return sdl.c.SDL_MapRGBA(getPixelFormatDetails(), c.r, c.g, c.b, c.a);
    }

    /// Convert from HSL
    pub inline fn fromHSL(hsl: [4]f32) Color {
        const c = zmath.hslToRgb(
            zmath.loadArr4(hsl),
        );
        const multiplier: @Vector(4, f32) = @splat(255.0);
        c *= multiplier;
        return .{
            .r = @intFromFloat(c[0]),
            .g = @intFromFloat(c[1]),
            .b = @intFromFloat(c[2]),
            .a = @intFromFloat(c[3]),
        };
    }

    /// Convert to HSL
    pub inline fn toHSL(c: Color) [4]f32 {
        const hsl = zmath.rgbToHsl(
            zmath.f32x4(
                @as(f32, @floatFromInt(c.r)) / 255,
                @as(f32, @floatFromInt(c.g)) / 255,
                @as(f32, @floatFromInt(c.b)) / 255,
                @as(f32, @floatFromInt(c.a)) / 255,
            ),
        );
        return zmath.vecToArr4(hsl);
    }

    /// Convert from ImGui's color type
    pub inline fn fromInternalColor(c: u32) Color {
        return .{
            .r = @as(u8, @intCast(c & 0xff)),
            .g = @as(u8, @intCast((c >> 8) & 0xff)),
            .b = @as(u8, @intCast((c >> 16) & 0xff)),
            .a = @as(u8, @intCast((c >> 24) & 0xff)),
        };
    }

    /// Convert to ImGui's color type
    pub inline fn toInternalColor(c: Color) u32 {
        return @as(u32, c.r) |
            (@as(u32, c.g) << 8) |
            (@as(u32, c.b) << 16) |
            (@as(u32, c.a) << 24);
    }

    pub inline fn lerp(c0: Color, c1: Color, t: f32) Color {
        assert(t >= 0 and t <= 1);
        return c0.toColorF().lerp(c1.toColorF(), t).toColor();
    }

    pub inline fn mod(c0: Color, c1: Color) Color {
        return .{
            .r = @intFromFloat(@as(f32, @floatFromInt(c0.r)) * @as(f32, @floatFromInt(c1.r)) / 255.0),
            .g = @intFromFloat(@as(f32, @floatFromInt(c0.g)) * @as(f32, @floatFromInt(c1.g)) / 255.0),
            .b = @intFromFloat(@as(f32, @floatFromInt(c0.b)) * @as(f32, @floatFromInt(c1.b)) / 255.0),
            .a = @intFromFloat(@as(f32, @floatFromInt(c0.a)) * @as(f32, @floatFromInt(c1.a)) / 255.0),
        };
    }

    /// parses a hex string color literal.
    /// allowed formats are:
    /// - `RGB`
    /// - `RGBA`
    /// - `#RGB`
    /// - `#RGBA`
    /// - `RRGGBB`
    /// - `#RRGGBB`
    /// - `RRGGBBAA`
    /// - `#RRGGBBAA`
    pub fn parse(str: []const u8) ParseError!Color {
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

pub const ColorF = extern struct {
    pub const none = rgba(0, 0, 0, 0);
    pub const black = rgb(0, 0, 0);
    pub const white = rgb(1, 1, 1);
    pub const red = rgb(1, 0, 0);
    pub const green = rgb(0, 1, 0);
    pub const blue = rgb(0, 0, 1);
    pub const magenta = rgb(1, 0, 1);
    pub const cyan = rgb(0, 1, 1);
    pub const yellow = rgb(1, 1, 0);
    pub const purple = rgb(1, 0.5, 1);

    r: f32,
    g: f32,
    b: f32,
    a: f32 = 1,

    pub inline fn rgb(r: f32, g: f32, b: f32) ColorF {
        return ColorF{ .r = r, .g = g, .b = b };
    }

    pub inline fn rgba(r: f32, g: f32, b: f32, a: f32) ColorF {
        return ColorF{ .r = r, .g = g, .b = b, .a = a };
    }

    pub inline fn fromColor(_c: Color) ColorF {
        var c: @Vector(4, f32) = .{
            @floatFromInt(_c.r),
            @floatFromInt(_c.g),
            @floatFromInt(_c.b),
            @floatFromInt(_c.a),
        };
        const multiplier: @Vector(4, f32) = @splat(1.0 / 255.0);
        c *= multiplier;
        return ColorF{ .r = c[0], .g = c[1], .b = c[2], .a = c[3] };
    }

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

    pub inline fn fromRGBA32(i: u32) ColorF {
        return fromColor(Color.fromRGBA32(i));
    }

    pub inline fn toRGBA32(c: ColorF) u32 {
        return c.toColor().toRGBA32();
    }

    /// Convert from HSL
    pub inline fn fromHSL(hsl: [4]f32) ColorF {
        const _rgba = zmath.hslToRgb(
            zmath.loadArr4(hsl),
        );
        return .{ .r = _rgba[0], .g = _rgba[1], .b = _rgba[2], .a = _rgba[3] };
    }

    /// Convert to HSL
    pub inline fn toHSL(c: ColorF) [4]f32 {
        const hsl = zmath.rgbToHsl(
            zmath.f32x4(c.r, c.g, c.b, c.a),
        );
        return zmath.vecToArr4(hsl);
    }

    /// Convert from ImGui's color type
    pub inline fn fromInternalColor(c: u32) ColorF {
        return fromColor(Color.fromInternalColor(c));
    }

    /// Convert to ImGui's color type
    pub inline fn toInternalColor(c: ColorF) u32 {
        return c.toColor().toInternalColor();
    }

    pub inline fn lerp(_c0: ColorF, _c1: ColorF, t: f32) ColorF {
        assert(t >= 0 and t <= 1);
        const c0 = zmath.f32x4(_c0.r, _c0.g, _c0.b, _c0.a);
        const c1 = zmath.f32x4(_c1.r, _c1.g, _c1.b, _c1.a);
        const c = zmath.lerp(c0, c1, t);
        return .{ .r = c[0], .g = c[1], .b = c[2], .a = c[3] };
    }

    pub inline fn mod(c0: ColorF, c1: ColorF) ColorF {
        return .{
            .r = c0.r * c1.r,
            .g = c0.g * c1.g,
            .b = c0.b * c1.b,
            .a = c0.a * c1.a,
        };
    }
};

pub const Vertex = extern struct {
    pos: Point,
    color: ColorF,
    texcoord: Point = undefined,
};
