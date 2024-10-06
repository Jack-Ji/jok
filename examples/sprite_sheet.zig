const std = @import("std");
const jok = @import("jok");
const sdl = jok.sdl;
const physfs = jok.physfs;
const j2d = jok.j2d;

var sheet1: *j2d.SpriteSheet = undefined;
var sheet2: *j2d.SpriteSheet = undefined;
var sheet3: *j2d.SpriteSheet = undefined;

pub fn init(ctx: jok.Context) !void {
    std.log.info("game init", .{});

    try physfs.mount("assets", "", true);
    try physfs.mount(physfs.getBaseDir(), "", true);
    try physfs.setWriteDir(physfs.getBaseDir());

    // create sprite sheet1
    const size = ctx.getCanvasSize();
    sheet1 = try j2d.SpriteSheet.fromPicturesInDir(
        ctx,
        "images",
        @intFromFloat(size.x),
        @intFromFloat(size.y),
        .{ .keep_packed_pixels = true },
    );
    try sheet1.save(ctx, "sheet1");

    sheet2 = try j2d.SpriteSheet.load(
        ctx,
        "sheet1",
    );

    sheet3 = try j2d.SpriteSheet.fromSinglePicture(
        ctx,
        "images/image9.jpg",
        &.{
            .{
                .name = "cute",
                .rect = .{ .x = 0, .y = 0, .width = 50, .height = 50 },
            },
        },
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
    ctx.clear(sdl.Color.rgb(77, 77, 77));

    const sprite = sheet2.getSpriteByName("ogre").?;
    j2d.begin(.{ .depth_sort = .back_to_forth });
    defer j2d.end();
    try j2d.image(
        sheet2.tex,
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
    try j2d.sprite(sheet3.getSpriteByName("cute").?, .{
        .pos = .{ .x = 50, .y = 400 },
        .scale = .{ .x = 2, .y = 2 },
    });
}

pub fn quit(ctx: jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});
    sheet1.destroy();
    sheet2.destroy();
    sheet3.destroy();
}
