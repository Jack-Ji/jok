const std = @import("std");
const jok = @import("jok.zig");
const sdl = jok.sdl;
const zmath = jok.zmath;
const minAndMax = jok.utils.math.minAndMax;

pub const Point = extern struct {
    x: f32,
    y: f32,

    pub inline fn add(p0: Point, p1: Point) Point {
        return .{
            .x = p0.x + p1.x,
            .y = p0.y + p1.y,
        };
    }

    pub inline fn sub(p0: Point, p1: Point) Point {
        return .{
            .x = p0.x - p1.x,
            .y = p0.y - p1.y,
        };
    }

    pub inline fn mul(p0: Point, p1: Point) Point {
        return .{
            .x = p0.x * p1.x,
            .y = p0.y * p1.y,
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

    pub inline fn isSame(r0: Region, r1: Region) bool {
        return r0.x == r1.x and r0.y == r1.y and
            r0.width == r1.width and r0.height == r1.height;
    }

    pub inline fn area(r: Region) f32 {
        return r.width * r.height;
    }
};

pub const Rectangle = extern struct {
    x: f32,
    y: f32,
    width: f32,
    height: f32,

    pub inline fn translate(r: Rectangle, x: f32, y: f32) Rectangle {
        return .{
            .x = r.x + x,
            .y = r.y + y,
            .width = r.width,
            .height = r.height,
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
        if (sdl.SDL_HasIntersectionF(@ptrCast(&r), @ptrCast(&b)) == 1) {
            return true;
        }
        return false;
    }

    pub inline fn intersectRect(r: Rectangle, b: Rectangle) ?Rectangle {
        var result: Rectangle = undefined;
        if (sdl.SDL_IntersectFRect(@ptrCast(&r), @ptrCast(&b), @ptrCast(&result)) == 1) {
            return result;
        }
        return null;
    }

    pub inline fn intersectLine(r: Rectangle, p0: *Point, p1: *Point) bool {
        if (sdl.SDL_IntersectFRectAndLine(@ptrCast(&r), &p0.x, &p0.y, &p1.x, &p1.y) == 1) {
            return true;
        }
        return false;
    }

    pub inline fn intersectCircle(r: Rectangle, c: Circle) bool {
        return c.intersectRect(r);
    }

    pub inline fn containsPoint(r: Rectangle, p: Point) bool {
        return p.x >= r.x and p.x < r.x + r.width and
            p.y >= r.y and p.y < r.y + r.height;
    }

    pub inline fn containsRect(r: Rectangle, b: Rectangle) bool {
        return b.x >= r.x and b.x + b.width < r.x + r.width and
            b.y >= r.y and b.y + b.height < r.y + r.height;
    }
};

pub const Circle = extern struct {
    center: Point,
    radius: f32,

    pub inline fn translate(c: Circle, x: f32, y: f32) Circle {
        return .{
            .center = c.center.add(.{ .x = x, .y = y }),
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
        if (c.containsPoint(.{ .x = r.x, .y = r.y }) or
            c.containsPoint(.{ .x = r.x + r.width, .y = r.y }) or
            c.containsPoint(.{ .x = r.x + r.width, .y = r.y + r.height }) or
            c.containsPoint(.{ .x = r.x, .y = r.y + r.height }))
        {
            return true;
        }
        return false;
    }

    pub inline fn intersectTriangle(c: Circle, t: Triangle) bool {
        if (c.containsPoint(t.p0) or c.containsPoint(t.p1) or c.containsPoint(t.p2)) {
            return true;
        }
        return false;
    }
};

pub const Ellipse = struct {
    center: Point,
    radius: Point,

    pub inline fn translate(e: Ellipse, x: f32, y: f32) Circle {
        return .{
            .center = e.center.add(.{ .x = x, .y = y }),
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

    pub inline fn intersectRect(e: Ellipse, r: Rectangle) bool {
        if (e.containsPoint(.{ .x = r.x, .y = r.y }) or
            e.containsPoint(.{ .x = r.x + r.width, .y = r.y }) or
            e.containsPoint(.{ .x = r.x + r.width, .y = r.y + r.height }) or
            e.containsPoint(.{ .x = r.x, .y = r.y + r.height }))
        {
            return true;
        }
        return false;
    }

    pub inline fn intersectTriangle(e: Ellipse, t: Triangle) bool {
        if (e.containsPoint(t.p0) or e.containsPoint(t.p1) or e.containsPoint(t.p2)) {
            return true;
        }
        return false;
    }
};

pub const Triangle = extern struct {
    p0: Point,
    p1: Point,
    p2: Point,

    pub inline fn translate(tri: Triangle, x: f32, y: f32) Triangle {
        return .{
            .p0 = tri.p0.add(.{ .x = x, .y = y }),
            .p1 = tri.p1.add(.{ .x = x, .y = y }),
            .p2 = tri.p2.add(.{ .x = x, .y = y }),
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
        InvalidCharacter,
        Overflow,
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

    inline fn getPixelFormat() [*c]sdl.SDL_PixelFormat {
        const S = struct {
            var pixel_format: ?[*c]sdl.SDL_PixelFormat = null;
        };
        if (S.pixel_format == null) {
            S.pixel_format = sdl.SDL_AllocFormat(sdl.SDL_PIXELFORMAT_RGBA32);
        }
        return S.pixel_format.?;
    }

    pub inline fn fromRGBA32(i: u32) Color {
        var c: Color = undefined;
        sdl.SDL_GetRGBA(i, getPixelFormat(), &c.r, &c.g, &c.b, &c.a);
        return c;
    }

    pub inline fn toRGBA32(c: Color) u32 {
        return sdl.SDL_MapRGBA(getPixelFormat(), c.r, c.g, c.b, c.a);
    }

    /// Convert from HSL
    pub inline fn fromHSL(hsl: [4]f32) Color {
        const _rgba = zmath.hslToRgb(
            zmath.loadArr4(hsl),
        );
        return .{
            .r = @intFromFloat(_rgba[0] * 255),
            .g = @intFromFloat(_rgba[1] * 255),
            .b = @intFromFloat(_rgba[2] * 255),
            .a = @intFromFloat(_rgba[3] * 255),
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
            .r = @as(u8, c & 0xff),
            .g = @as(u8, (c >> 8) & 0xff),
            .b = @as(u8, (c >> 16) & 0xff),
            .a = @as(u8, (c >> 24) & 0xff),
        };
    }

    /// Convert to ImGui's color type
    pub inline fn toInternalColor(c: Color) u32 {
        return @as(u32, c.r) |
            (@as(u32, c.g) << 8) |
            (@as(u32, c.b) << 16) |
            (@as(u32, c.a) << 24);
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

pub const Vertex = extern struct {
    pos: Point,
    color: Color,
    texcoord: Point = undefined,
};
