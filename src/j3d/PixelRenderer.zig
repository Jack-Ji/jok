const std = @import("std");
const assert = std.debug.assert;
const math = std.math;
const sdl = @import("sdl");
const jok = @import("../jok.zig");
const j3d = jok.j3d;
const zmath = j3d.zmath;
const Camera = j3d.Camera;
const Self = @This();

arena: std.heap.ArenaAllocator,
renderer: sdl.Renderer,
tex: sdl.Texture,
pixel_format: sdl.PixelFormatEnum,
width: i32,
height: i32,
color_buffer: []u32 = undefined,

pub fn init(ctx: jok.Context, size: ?sdl.Size) !Self {
    const pixel_format = jok.utils.gfx.getFormatByEndian();
    const fb_size = ctx.getFramebufferSize();
    const actual_size = size orelse sdl.Size{
        .width = @intCast(c_int, fb_size.w),
        .height = @intCast(c_int, fb_size.h),
    };
    const width = @intCast(usize, actual_size.width);
    const height = @intCast(usize, actual_size.height);
    var self = Self{
        .arena = std.heap.ArenaAllocator.init(ctx.allocator),
        .renderer = ctx.renderer,
        .pixel_format = pixel_format,
        .tex = try sdl.createTexture(ctx.renderer, pixel_format, .streaming, width, height),
        .width = @intCast(i32, width),
        .height = @intCast(i32, height),
    };
    self.color_buffer = try self.arena.allocator().alloc(u32, width * height);
    return self;
}

pub fn deinit(self: *Self) void {
    self.tex.destroy();
    self.arena.deinit();
    self.* = undefined;
}

/// Clear the scene
pub const ClearOption = struct {
    clear_color: sdl.Color = sdl.Color.black,
};
pub fn clear(self: *Self, opt: ClearOption) void {
    std.mem.set(u32, self.color_buffer, self.mapRGBA(
        opt.clear_color.r,
        opt.clear_color.g,
        opt.clear_color.b,
        opt.clear_color.a,
    ));
}

/// Draw the scene
pub fn draw(self: Self, pos: ?sdl.Rectangle) !void {
    try self.tex.update(std.mem.sliceAsBytes(self.color_buffer), @intCast(usize, self.width * 4), null);
    try self.renderer.copy(self.tex, pos, null);
}

/// Add line
pub fn line(self: *Self, _x0: i32, _y0: i32, _x1: i32, _y1: i32, color: sdl.Color) !void {
    var x0 = _x0;
    var y0 = _y0;
    var x1 = _x1;
    var y1 = _y1;
    var steep = false;
    if (try math.absInt(x0 - x1) < try math.absInt(y0 - y1)) {
        std.mem.swap(i32, &x0, &y0);
        std.mem.swap(i32, &x1, &y1);
        steep = true;
    }
    if (x0 > x1) {
        std.mem.swap(i32, &x0, &x1);
        std.mem.swap(i32, &y0, &y1);
    }

    var dx = x1 - x0;
    var dy = y1 - y0;
    var derror2 = try math.absInt(dy) * 2;
    var error2 = @as(i32, 0);
    var x = x0;
    var y = y0;
    while (x <= x1) : (x += 1) {
        if (steep) {
            try self.pixel(y, x, color);
        } else {
            try self.pixel(x, y, color);
        }
        error2 += derror2;
        if (error2 > dx) {
            y += if (y1 > y0) 1 else -1;
            error2 -= dx * 2;
        }
    }
}

/// Add pixel
pub fn pixel(self: *Self, x: i32, y: i32, color: sdl.Color) !void {
    if (self.posToIndex(x, y)) |idx| {
        self.color_buffer[idx] = self.mapRGBA(color.r, color.g, color.b, color.a);
    }
}

//-------------------------------------------------------------------------------
//
// Internal functions
//
//-------------------------------------------------------------------------------
inline fn posToIndex(self: Self, x: i32, y: i32) ?u32 {
    if (x < 0 or x >= self.width or y < 0 or y >= self.height) return null;
    return @intCast(u32, x + y * self.width);
}

inline fn mapRGBA(self: Self, _r: u8, _g: u8, _b: u8, _a: u8) u32 {
    const r = @intCast(u32, _r);
    const g = @intCast(u32, _g);
    const b = @intCast(u32, _b);
    const a = @intCast(u32, _a);
    return switch (self.pixel_format) {
        .rgba8888 => (r << 24) | (g << 16) | (b << 8) | a,
        .abgr8888 => (a << 24) | (b << 16) | (g << 8) | r,
        else => unreachable,
    };
}
