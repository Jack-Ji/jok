const std = @import("std");
const assert = std.debug.assert;
const math = std.math;
const sdl = @import("sdl");
const jok = @import("../../jok.zig");
const @"3d" = jok.gfx.@"3d";
const zmath = @"3d".zmath;
const Camera = @"3d".Camera;
const Self = @This();

// sdl renderer
rd: sdl.Renderer,

// pixels for rasterization
pixels: []u32,

pub fn init(ctx: *jok.Context) Self {
    return .{
        .rd = ctx.renderer,
    };
}

fn pixel(self: Self, p: sdl.Point) !void {
    try self.rd.drawPoint(@as(i32, p.x), @as(i32, p.y));
}

fn line(self: Self, p1: sdl.Point, p2: sdl.Point) !void {
    try self.rd.drawLine(@as(i32, p1.x), @as(i32, p1.y), @as(i32, p2.x), @as(i32, p2.y));
}
