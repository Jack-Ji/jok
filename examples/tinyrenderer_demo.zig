const std = @import("std");
const sdl = @import("sdl");
const jok = @import("jok");
const j3d = jok.j3d;
const zmath = j3d.zmath;

var prd: j3d.PixelRenderer = undefined;

pub fn init(ctx: *jok.Context) !void {
    std.log.info("game init", .{});

    prd = try j3d.PixelRenderer.init(ctx.*, null);
}

pub fn event(ctx: *jok.Context, e: sdl.Event) !void {
    _ = ctx;
    _ = e;
}

pub fn update(ctx: *jok.Context) !void {
    _ = ctx;
}

pub fn draw(ctx: *jok.Context) !void {
    _ = ctx;

    prd.clear(.{});
    try prd.line(30, 40, 200, 450, sdl.Color.red);
    try prd.triangle(100, 50, 300, 150, 200, 390, sdl.Color.green);
    try prd.draw(null);
}

pub fn quit(ctx: *jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});

    prd.deinit();
}
