const std = @import("std");
const sdl = @import("sdl");
const jok = @import("jok");
const font = jok.font;

pub fn init(ctx: *jok.Context) anyerror!void {
    std.log.info("game init", .{});

    try ctx.renderer.setColorRGB(100, 100, 100);
}

pub fn event(ctx: *jok.Context, e: sdl.Event) anyerror!void {
    _ = ctx;
    _ = e;
}

pub fn update(ctx: *jok.Context) anyerror!void {
    _ = ctx;
}

pub fn draw(ctx: *jok.Context) anyerror!void {
    defer ctx.renderer.setColorRGB(100, 100, 100) catch unreachable;

    const size = ctx.getFramebufferSize();

    try ctx.renderer.setColorRGBA(0, 128, 0, 120);
    try ctx.renderer.setDrawBlendMode(.blend);

    var result = try font.debugDraw(
        ctx.renderer,
        .{
            .pos = sdl.PointF{ .x = 0, .y = 0 },
            .ypos_type = .top,
            .color = sdl.Color.cyan,
        },
        "ABCDEFGHIJKL abcdefghijkl",
        .{},
    );
    try ctx.renderer.fillRectF(result.area);

    result = try font.debugDraw(
        ctx.renderer,
        .{
            .pos = sdl.PointF{ .x = 0, .y = @intToFloat(f32, size.h) / 2 },
            .font_size = 80,
            .ypos_type = .bottom,
        },
        "Hello,",
        .{},
    );
    try ctx.renderer.fillRectF(result.area);

    result = try font.debugDraw(
        ctx.renderer,
        .{
            .pos = sdl.PointF{ .x = result.area.x + result.area.width, .y = @intToFloat(f32, size.h) / 2 },
            .font_size = 80,
            .ypos_type = .top,
        },
        "jok!",
        .{},
    );
    try ctx.renderer.fillRectF(result.area);

    result = try font.debugDraw(
        ctx.renderer,
        .{
            .pos = sdl.PointF{ .x = 0, .y = @intToFloat(f32, size.h) },
            .ypos_type = .bottom,
            .color = sdl.Color.red,
            .font_size = 32,
        },
        "ABCDEFGHIJKL abcdefghijkl",
        .{},
    );
    try ctx.renderer.fillRectF(result.area);
}

pub fn quit(ctx: *jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});
}
