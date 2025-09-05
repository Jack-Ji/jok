const std = @import("std");
const builtin = @import("builtin");
const jok = @import("jok");
const physfs = jok.physfs;
const j2d = jok.j2d;

var batchpool: j2d.BatchPool(64, false) = undefined;
var sheet1: *j2d.SpriteSheet = undefined;
var sheet2: *j2d.SpriteSheet = undefined;
var sheet3: *j2d.SpriteSheet = undefined;

pub fn init(ctx: jok.Context) !void {
    std.log.info("game init", .{});

    if (!builtin.cpu.arch.isWasm()) {
        try physfs.mount("assets", "", true);
    }
    try physfs.mount(physfs.getBaseDir(), "", true);
    try physfs.setWriteDir(physfs.getBaseDir());

    batchpool = try @TypeOf(batchpool).init(ctx);

    // create sprite sheet1
    const size = ctx.getCanvasSize();
    sheet1 = try j2d.SpriteSheet.fromPicturesInDir(
        ctx,
        if (ctx.cfg().jok_enable_physfs) "images" else "assets/images",
        @intFromFloat(size.getWidthFloat()),
        @intFromFloat(size.getHeightFloat()),
        .{ .keep_packed_pixels = true },
    );
    try sheet1.save(ctx, "sheet1.png", .{});

    sheet2 = try j2d.SpriteSheet.load(ctx, "sheet1.png");

    sheet3 = try j2d.SpriteSheet.fromSinglePicture(
        ctx,
        if (ctx.cfg().jok_enable_physfs) "images/image9.jpg" else "assets/images/image9.jpg",
        &.{
            .{
                .name = "cute",
                .rect = .{ .x = 0, .y = 0, .width = 50, .height = 50 },
            },
        },
    );
}

pub fn event(ctx: jok.Context, e: jok.Event) !void {
    _ = ctx;
    _ = e;
}

pub fn update(ctx: jok.Context) !void {
    _ = ctx;
}

pub fn draw(ctx: jok.Context) !void {
    try ctx.renderer().clear(.rgb(77, 77, 77));

    const sprite = sheet2.getSpriteByName("ogre").?;
    var b = try batchpool.new(.{ .depth_sort = .back_to_forth });
    defer b.submit();
    try b.image(sheet2.tex, .origin, .{ .depth = 1 });
    try b.sprite(sprite, .{
        .pos = .{ .x = 400, .y = 300 },
        .scale = .{ .x = 2, .y = 2 },
        .flip_h = true,
        .flip_v = true,
    });
    try b.sprite(sprite, .{
        .pos = .{ .x = 400, .y = 300 },
        .tint_color = .rgb(255, 0, 0),
        .scale = .{
            .x = 4 + 2 * @cos(ctx.seconds()),
            .y = 4 + 2 * @sin(ctx.seconds()),
        },
        .rotate_angle = ctx.seconds() / 2,
        .anchor_point = .anchor_center,
        .depth = 0.6,
    });
    try b.sprite(sheet3.getSpriteByName("cute").?, .{
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
    batchpool.deinit();
}
