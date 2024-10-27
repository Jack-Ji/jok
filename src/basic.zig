const std = @import("std");
const jok = @import("jok.zig");
const sdl = jok.sdl;

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

    pub inline fn intersectRectAndLine(r: Rectangle, p0: *Point, p1: *Point) bool {
        if (sdl.SDL_IntersectFRectAndLine(@ptrCast(&r), &p0.x, &p0.y, &p1.x, &p1.y) == 1) {
            return true;
        }
        return false;
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

pub const Color = extern struct {
    var pixel_format: *sdl.SDL_PixelFormat = undefined;

    pub const none = rgba(0x00, 0x00, 0x00, 0x00);
    pub const black = rgb(0x00, 0x00, 0x00);
    pub const white = rgb(0xFF, 0xFF, 0xFF);
    pub const red = rgb(0xFF, 0x00, 0x00);
    pub const green = rgb(0x00, 0xFF, 0x00);
    pub const blue = rgb(0x00, 0x00, 0xFF);
    pub const magenta = rgb(0xFF, 0x00, 0xFF);
    pub const cyan = rgb(0x00, 0xFF, 0xFF);
    pub const yellow = rgb(0xFF, 0xFF, 0x00);

    r: u8,
    g: u8,
    b: u8,
    a: u8 = 255,

    pub fn init() void {
        pixel_format = @ptrCast(sdl.SDL_AllocFormat(sdl.SDL_PIXELFORMAT_RGBA32));
    }

    pub inline fn rgb(r: u8, g: u8, b: u8) Color {
        return Color{ .r = r, .g = g, .b = b };
    }

    pub inline fn rgba(r: u8, g: u8, b: u8, a: u8) Color {
        return Color{ .r = r, .g = g, .b = b, .a = a };
    }

    pub inline fn fromRGBA32(i: u32) Color {
        var c: Color = undefined;
        sdl.SDL_GetRGBA(i, @ptrCast(pixel_format), &c.r, &c.g, &c.b, &c.a);
        return c;
    }

    pub inline fn toRGBA32(c: Color) u32 {
        return sdl.SDL_MapRGBA(@ptrCast(pixel_format), c.r, c.g, c.b, c.a);
    }
};

pub const Vertex = extern struct {
    pos: Point,
    color: Color,
    texcoord: Point = undefined,
};
