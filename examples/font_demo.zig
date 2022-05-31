const std = @import("std");
const sdl = @import("sdl");
const jok = @import("jok");
const gfx = jok.gfx.@"2d";

pub fn init(ctx: *jok.Context) anyerror!void {
    _ = ctx;
    std.log.info("game init", .{});
}

pub fn loop(ctx: *jok.Context) anyerror!void {
    while (ctx.pollEvent()) |e| {
        switch (e) {
            .keyboard_event => |key| {
                if (key.trigger_type == .up) {
                    switch (key.scan_code) {
                        .escape => ctx.kill(),
                        else => {},
                    }
                }
            },
            .quit_event => ctx.kill(),
            else => {},
        }
    }

    const size = ctx.getFramebufferSize();

    try ctx.renderer.setColorRGB(100, 100, 100);
    try ctx.renderer.clear();

    try ctx.renderer.setColorRGBA(0, 128, 0, 120);
    try ctx.renderer.setDrawBlendMode(.blend);

    var result = try gfx.font.debugDraw(
        ctx.renderer,
        .{
            .pos = sdl.PointF{ .x = 0, .y = 0 },
            .ypos_type = .top,
            .color = sdl.Color.cyan,
        },
        "你好！ABCDEFGHIJKL abcdefghijkl",
        .{},
    );
    try ctx.renderer.fillRectF(result.area);

    result = try gfx.font.debugDraw(
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

    result = try gfx.font.debugDraw(
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

    result = try gfx.font.debugDraw(
        ctx.renderer,
        .{
            .pos = sdl.PointF{ .x = 0, .y = @intToFloat(f32, size.h) },
            .ypos_type = .bottom,
            .color = sdl.Color.red,
            .font_size = 32,
        },
        "你好！ABCDEFGHIJKL abcdefghijkl",
        .{},
    );
    try ctx.renderer.fillRectF(result.area);
}

pub fn quit(ctx: *jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});
}
