const std = @import("std");
const sdl = @import("sdl");
const jok = @import("jok");
const j3d = jok.j3d;
const zmath = j3d.zmath;

var prd: j3d.PixelRenderer = undefined;

pub fn init(ctx: *jok.Context) !void {
    std.log.info("game init", .{});

    prd = try j3d.PixelRenderer.init(ctx.allocator, ctx.renderer, null);
}

pub fn event(ctx: *jok.Context, e: sdl.Event) !void {
    _ = ctx;
    _ = e;
}

pub fn update(ctx: *jok.Context) !void {
    _ = ctx;
}

pub fn draw(ctx: *jok.Context) !void {
    prd.clear(.{});
    try prd.line(30, 40, 200, 450, sdl.Color.red);
    try prd.triangle(100, 50, 300, 150, 200, 390, sdl.Color.green);
    try prd.triangle(300, 150, 200, 390, 400, 100, sdl.Color.yellow);
    try prd.draw(ctx.renderer, null);
}

pub fn quit(ctx: *jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});

    prd.deinit();
}
