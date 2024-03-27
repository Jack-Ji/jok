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
        ctx,
        svg.pixels,
        svg.format,
        .static,
        svg.width,
        svg.height,
    );
}

pub fn event(ctx: jok.Context, e: sdl.Event) !void {
    _ = ctx;
    _ = e;
}

pub fn update(ctx: jok.Context) !void {
    _ = ctx;
}

pub fn draw(ctx: jok.Context) !void {
    ctx.clear(sdl.Color.rgb(100, 100, 100));

    j2d.begin(.{});
    defer j2d.end();
    try j2d.image(
        tex,
        .{
            .x = ctx.getCanvasSize().x / 2,
            .y = ctx.getCanvasSize().y / 2,
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
}

pub fn quit(ctx: jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});

    svg.destroy();
    tex.destroy();
}
