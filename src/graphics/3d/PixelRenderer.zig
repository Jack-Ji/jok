const std = @import("std");
const assert = std.debug.assert;
const math = std.math;
const sdl = @import("sdl");
const jok = @import("../../jok.zig");
const @"3d" = jok.gfx.@"3d";
const zmath = @"3d".zmath;
const Camera = @"3d".Camera;
const Self = @This();

/// sdl renderer
rd: sdl.Renderer,

pub fn init(ctx: *jok.Context) Self {
    return .{
        .rd = ctx.renderer,
    };
}

fn pixel(self: Self, rd: sdl.Renderer, p: sdl.Point) !void {
    _ = self;
    try rd.drawPoint(@as(i32, p.x), @as(i32, p.y));
}

fn line(self: Self, rd: sdl.Renderer, pos1: sdl.Point, pos2: sdl.Point) !void {
    _ = self;
    try rd.drawLine(@as(i32, pos1.x), @as(i32, pos1.y), @as(i32, pos2.x), @as(i32, pos2.y));
}
