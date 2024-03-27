const std = @import("std");
const jok = @import("jok");
const sdl = jok.sdl;
const font = jok.font;
const j2d = jok.j2d;

pub fn init(ctx: jok.Context) !void {
    _ = ctx;
    std.log.info("game init", .{});
}

pub fn event(ctx: jok.Context, e: sdl.Event) !void {
    _ = ctx;
    _ = e;
}

pub fn update(ctx: jok.Context) !void {
    _ = ctx;
}

pub fn draw(ctx: jok.Context) !void {
    ctx.clear(null);

    const size = ctx.getCanvasSize();
    const rect_color = sdl.Color.rgba(0, 128, 0, 120);
    var area: sdl.RectangleF = undefined;
    var atlas: *font.Atlas = undefined;

    j2d.begin(.{ .depth_sort = .back_to_forth });
    defer j2d.end();
    atlas = try font.DebugFont.getAtlas(ctx, 20);
    try j2d.text(
        .{
            .atlas = atlas,
            .pos = .{ .x = 0, .y = 0 },
            .ypos_type = .top,
            .tint_color = sdl.Color.cyan,
        },
        "ABCDEFGHIJKL abcdefghijkl",
        .{},
    );
    area = try atlas.getBoundingBox(
        "ABCDEFGHIJKL abcdefghijkl",
        .{ .x = 0, .y = 0 },
        .top,
        .aligned,
    );
    try j2d.rectFilled(area, rect_color, .{});

    atlas = try font.DebugFont.getAtlas(ctx, 80);
    try j2d.text(
        .{
            .atlas = atlas,
            .pos = .{ .x = 0, .y = size.y / 2 },
            .ypos_type = .bottom,
        },
        "Hello,",
        .{},
    );
    area = try atlas.getBoundingBox(
        "Hello,",
        .{ .x = 0, .y = size.y / 2 },
        .bottom,
        .aligned,
    );
    try j2d.rectFilled(area, rect_color, .{});

    try j2d.text(
        .{
            .atlas = atlas,
            .pos = .{
                .x = area.x + area.width,
                .y = size.y / 2,
            },
            .tint_color = sdl.Color.rgb(
                @intFromFloat(128 + @sin(ctx.seconds()) * 127),
                @intFromFloat(128 + @cos(ctx.seconds()) * 127),
                @intFromFloat(128 + @sin(ctx.seconds()) * 127),
            ),
            .scale = .{
                .x = 4 + 3 * @sin(ctx.seconds()),
                .y = 4 + 3 * @cos(ctx.seconds()),
            },
            .rotate_degree = ctx.seconds() * 30,
            .depth = 0,
        },
        "jok!",
        .{},
    );

    atlas = try font.DebugFont.getAtlas(ctx, 32);
    try j2d.text(
        .{
            .atlas = atlas,
            .pos = .{ .x = 0, .y = size.y },
            .ypos_type = .bottom,
            .tint_color = sdl.Color.red,
        },
        "ABCDEFGHIJKL abcdefghijkl",
        .{},
    );
    area = try atlas.getBoundingBox(
        "ABCDEFGHIJKL abcdefghijkl",
        .{ .x = 0, .y = size.y },
        .bottom,
        .aligned,
    );
    try j2d.rectFilled(area, rect_color, .{});
}

pub fn quit(ctx: jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});
}
