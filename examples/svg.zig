const std = @import("std");
const jok = @import("jok");
const sdl = jok.sdl;
const font = jok.font;
const j2d = jok.j2d;

var svg: jok.svg.SvgBitmap = undefined;
var tex: sdl.Texture = undefined;

pub fn init(ctx: jok.Context) !void {
    std.log.info("game init", .{});

    svg = try jok.svg.createBitmapFromFile(
        ctx.allocator(),
        "assets/tiger.svg",
        .{},
    );

    tex = try jok.utils.gfx.createTextureFromPixels(
        ctx.renderer(),
        svg.pixels,
        svg.format,
        .static,
        svg.width,
        svg.height,
    );

    try ctx.renderer().setColorRGB(100, 100, 100);
}

pub fn event(ctx: jok.Context, e: sdl.Event) !void {
    _ = ctx;
    _ = e;
}

pub fn update(ctx: jok.Context) !void {
    _ = ctx;
}

pub fn draw(ctx: jok.Context) !void {
    try ctx.renderer().clear();

    try j2d.begin(.{});
    try j2d.image(
        tex,
        .{
            .x = ctx.getFramebufferSize().x / 2,
            .y = ctx.getFramebufferSize().y / 2,
        },
        .{
            .rotate_degree = ctx.seconds() * 60,
            .scale = .{
                .x = 0.8 + @cos(ctx.seconds()) * 0.5,
                .y = 0.8 + @cos(ctx.seconds()) * 0.5,
            },
            .anchor_point = .{ .x = 0.5, .y = 0.5 },
        },
    );
    try j2d.end();
}

pub fn quit(ctx: jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});

    svg.destroy();
    tex.destroy();
}
