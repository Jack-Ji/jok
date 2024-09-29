const std = @import("std");
const jok = @import("jok");
const sdl = jok.sdl;
const physfs = jok.physfs;
const j2d = jok.j2d;

var sheet: *j2d.SpriteSheet = undefined;

pub fn init(ctx: jok.Context) !void {
    std.log.info("game init", .{});

    try physfs.mount("assets", "", true);

    // create sprite sheet
    const size = ctx.getCanvasSize();
    sheet = try j2d.SpriteSheet.fromPicturesInDir(
        ctx,
        "images",
        @intFromFloat(size.x),
        @intFromFloat(size.y),
        .{ .keep_packed_pixels = true },
    );
    //sheet = try j2d.SpriteSheet.fromSheetFiles(
    //    ctx.allocator,
    //    ctx.renderer,
    //    "sheet",
    //);
}

pub fn event(ctx: jok.Context, e: sdl.Event) !void {
    _ = ctx;
    _ = e;
}

pub fn update(ctx: jok.Context) !void {
    _ = ctx;
}

pub fn draw(ctx: jok.Context) !void {
    ctx.clear(sdl.Color.rgb(77, 77, 77));

    const sprite = sheet.getSpriteByName("ogre").?;
    j2d.begin(.{ .depth_sort = .back_to_forth });
    defer j2d.end();
    try j2d.image(
        sheet.tex,
        .{ .x = 0, .y = 0 },
        .{ .depth = 1 },
    );
    try j2d.sprite(sprite, .{
        .pos = .{ .x = 400, .y = 300 },
        .scale = .{ .x = 2, .y = 2 },
        .flip_h = true,
        .flip_v = true,
        //.rotate_degree = ctx.seconds() * 30,
    });
    try j2d.sprite(sprite, .{
        .pos = .{ .x = 400, .y = 300 },
        .tint_color = sdl.Color.rgb(255, 0, 0),
        .scale = .{
            .x = 4 + 2 * @cos(ctx.seconds()),
            .y = 4 + 2 * @sin(ctx.seconds()),
        },
        .rotate_degree = ctx.seconds() * 30,
        .anchor_point = .{ .x = 0.5, .y = 0.5 },
        .depth = 0.6,
    });
}

pub fn quit(ctx: jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});
    sheet.destroy();
}
