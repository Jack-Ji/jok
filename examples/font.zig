const std = @import("std");
const sdl = @import("sdl");
const jok = @import("jok");
const gfx = jok.gfx.@"2d";

fn init(ctx: *jok.Context) anyerror!void {
    _ = ctx;
    std.log.info("game init", .{});
}

fn loop(ctx: *jok.Context) anyerror!void {
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

    try ctx.renderer.setColor(sdl.Color.rgb(128, 77, 77));
    try ctx.renderer.clear();
    _ = try gfx.Font.debugDraw(
        ctx.renderer,
        "你好！ABCDEFGHIJKL abcdefghijkl",
        .{
            .pos = sdl.PointF{ .x = 0, .y = 0 },
            .ypos_type = .top,
        },
    );
    _ = try gfx.Font.debugDraw(
        ctx.renderer,
        "你好！ABCDEFGHIJKL abcdefghijkl",
        .{
            .pos = sdl.PointF{ .x = 0, .y = @intToFloat(f32, size.h) },
            .ypos_type = .bottom,
            .color = sdl.Color.red,
            .font_size = 32,
        },
    );
}

fn quit(ctx: *jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});
}

pub fn main() anyerror!void {
    try jok.run(.{
        .initFn = init,
        .loopFn = loop,
        .quitFn = quit,
    });
}
