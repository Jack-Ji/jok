const std = @import("std");
const sdl = @import("sdl");
const jok = @import("jok");

var font: *jok.font.Font = undefined;
var atlas: jok.font.Atlas = undefined;
var sb: *jok.j2d.SpriteBatch = undefined;

pub fn init(ctx: *jok.Context) !void {
    std.log.info("game init", .{});

    font = try jok.font.Font.fromTrueTypeData(ctx.allocator, jok.font.clacon_font_data);
    atlas = try font.initAtlas(ctx.renderer, 60, &jok.font.codepoint_ranges.default, null);
    sb = try jok.j2d.SpriteBatch.create(
        ctx,
        2,
        10000,
    );

    try ctx.renderer.setColorRGB(100, 100, 100);
}

pub fn event(ctx: *jok.Context, e: sdl.Event) !void {
    _ = ctx;
    _ = e;
}

pub fn update(ctx: *jok.Context) !void {
    _ = ctx;
}

pub fn draw(ctx: *jok.Context) !void {
    defer ctx.renderer.setColorRGB(100, 100, 100) catch unreachable;

    const size = ctx.getFramebufferSize();

    try ctx.renderer.setColorRGBA(0, 128, 0, 120);

    var result = try jok.font.debugDraw(
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

    result = try jok.font.debugDraw(
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

    result = try jok.font.debugDraw(
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

    result = try jok.font.debugDraw(
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

    sb.begin(.{});
    try sb.addText(
        .{
            .atlas = atlas,
            .pos = .{
                .x = @intToFloat(f32, size.w) / 2,
                .y = @intToFloat(f32, size.h) / 2,
            },
            .tint_color = sdl.Color.rgb(
                @floatToInt(u8, 128 + @sin(ctx.tick * 10) * 127),
                @floatToInt(u8, 128 + @cos(ctx.tick * 10) * 127),
                @floatToInt(u8, 128 + @sin(ctx.tick * 10) * 127),
            ),
        },
        " @_@",
        .{},
    );
    try sb.end();
}

pub fn quit(ctx: *jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});

    sb.destroy();
    atlas.deinit();
    font.destroy();
}
