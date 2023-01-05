const std = @import("std");
const sdl = @import("sdl");
const jok = @import("jok");

pub fn init(ctx: *jok.Context) !void {
    _ = ctx;
    std.log.info("game init", .{});
}

pub fn event(ctx: *jok.Context, e: sdl.Event) !void {
    _ = ctx;
    _ = e;
}

pub fn update(ctx: *jok.Context) !void {
    _ = ctx;
}

pub fn draw(ctx: *jok.Context) !void {
    const fb_size = ctx.getFramebufferSize();

    jok.j2d.primitive.clear(.{});
    jok.j2d.primitive.addQuadFilled(
        .{ .x = -100, .y = -100 },
        .{ .x = 100, .y = -100 },
        .{ .x = 100, .y = 100 },
        .{ .x = -100, .y = 100 },
        sdl.Color.rgb(
            @floatToInt(u8, 128 + 128 * std.math.sin(ctx.tick)),
            @floatToInt(u8, std.math.max(0, 255 * std.math.sin(ctx.tick))),
            @floatToInt(u8, 128 + 128 * std.math.cos(ctx.tick)),
        ),
        .{
            .trs = .{
                .scale = .{
                    .x = @floatCast(f32, 1.3 + std.math.sin(ctx.tick)),
                    .y = @floatCast(f32, 1.3 + std.math.sin(ctx.tick)),
                },
                .rotate_degree = @floatCast(f32, ctx.tick * 30),
                .offset = .{
                    .x = @intToFloat(f32, fb_size.w) / 2,
                    .y = @intToFloat(f32, fb_size.h) / 2,
                },
            },
        },
    );
    try jok.j2d.primitive.draw();

    _ = try jok.font.debugDraw(
        ctx.renderer,
        .{
            .pos = .{
                .x = @intToFloat(f32, fb_size.w) / 2,
                .y = @intToFloat(f32, fb_size.h) / 2,
            },
            .font_size = 50,
            .color = sdl.Color.rgb(
                255,
                @floatToInt(u8, std.math.max(0, 255 * std.math.cos(ctx.tick))),
                0,
            ),
        },
        "Hello Jok!",
        .{},
    );
}

pub fn quit(ctx: *jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});
}
