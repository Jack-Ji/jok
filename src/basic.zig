const jok = @import("jok.zig");
const sdl = jok.sdl;

pub const Point = extern struct {
    x: f32,
    y: f32,
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
};

pub const Rectangle = extern struct {
    x: f32,
    y: f32,
    width: f32,
    height: f32,

    pub fn hasIntersection(r: Rectangle, b: Rectangle) bool {
        if (sdl.SDL_HasIntersectionF(@ptrCast(&r), @ptrCast(&b)) == 1) {
            return true;
        }
        return false;
    }

    pub fn intersectRect(r: Rectangle, b: Rectangle) ?Rectangle {
        var result: Rectangle = undefined;
        if (sdl.SDL_IntersectFRect(@ptrCast(&r), @ptrCast(&b), @ptrCast(&result)) == 1) {
            return result;
        }
        return null;
    }

    pub fn intersectRectAndLine(r: Rectangle, p0: *Point, p1: *Point) bool {
        if (sdl.SDL_IntersectFRectAndLine(@ptrCast(&r), &p0.x, &p0.y, &p1.x, &p1.y) == 1) {
            return true;
        }
        return false;
    }
};

pub const Color = extern struct {
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

    pub fn rgb(r: u8, g: u8, b: u8) Color {
        return Color{ .r = r, .g = g, .b = b };
    }

    pub fn rgba(r: u8, g: u8, b: u8, a: u8) Color {
        return Color{ .r = r, .g = g, .b = b, .a = a };
    }
};

pub const Vertex = extern struct {
    pos: Point,
    color: Color,
    texcoord: Point = undefined,
};
