const std = @import("std");
const builtin = @import("builtin");
const jok = @import("jok");
const physfs = jok.physfs;
const j2d = jok.j2d;

var batchpool: j2d.BatchPool(64, false) = undefined;
var sheet: *j2d.SpriteSheet = undefined;
var scene: *j2d.Scene = undefined;
var ogre1: *j2d.Scene.Object = undefined;
var ogre2: *j2d.Scene.Object = undefined;

pub fn init(ctx: jok.Context) !void {
    std.log.info("game init", .{});

    if (!builtin.cpu.arch.isWasm()) {
        try physfs.mount("assets", "", true);
    }

    batchpool = try @TypeOf(batchpool).init(ctx);

    // create sprite sheet
    const size = ctx.getCanvasSize();
    sheet = try j2d.SpriteSheet.fromPicturesInDir(
        ctx,
        "images",
        @intFromFloat(size.getWidthFloat()),
        @intFromFloat(size.getHeightFloat()),
        .{},
    );
    scene = try j2d.Scene.create(ctx.allocator());
    ogre1 = try j2d.Scene.Object.create(ctx.allocator(), .{
        .sprite = sheet.getSpriteByName("ogre").?,
        .render_opt = .{
            .pos = .{ .x = 400, .y = 300 },
        },
    }, null);
    ogre2 = try j2d.Scene.Object.create(ctx.allocator(), .{
        .sprite = sheet.getSpriteByName("ogre").?,
        .render_opt = .{
            .pos = .{ .x = 0, .y = 0 },
            .scale = .{ .x = 0.5, .y = 0.5 },
        },
    }, null);
    try ogre1.addChild(ogre2);
    try scene.root.addChild(ogre1);
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

    ogre1.setRenderOptions(.{
        .pos = .{ .x = 400, .y = 300 },
        .tint_color = .rgb(255, 0, 0),
        .scale = .{
            .x = 4 + 2 * @cos(ctx.seconds()),
            .y = 4 + 2 * @sin(ctx.seconds()),
        },
        .rotate_angle = ctx.seconds() / 2,
        .anchor_point = .{ .x = 0.5, .y = 0.5 },
    });

    var b = try batchpool.new(.{ .depth_sort = .back_to_forth });
    defer b.submit();
    try b.image(
        sheet.tex,
        .{ .x = 0, .y = 0 },
        .{},
    );
    try b.scene(scene);
}

pub fn quit(ctx: jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});
    sheet.destroy();
    scene.destroy(true);
    batchpool.deinit();
}
