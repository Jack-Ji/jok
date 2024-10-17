const std = @import("std");
const jok = @import("jok");
const physfs = jok.physfs;
const j2d = jok.j2d;

var sheet: *j2d.SpriteSheet = undefined;
var scene: *j2d.Scene = undefined;
var ogre1: *j2d.Scene.Object = undefined;
var ogre2: *j2d.Scene.Object = undefined;

pub fn init(ctx: jok.Context) !void {
    std.log.info("game init", .{});

    try physfs.mount("assets", "", true);

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
    try ctx.renderer().clear(jok.Color.rgb(77, 77, 77));

    ogre1.setRenderOptions(.{
        .pos = .{ .x = 400, .y = 300 },
        .tint_color = jok.Color.rgb(255, 0, 0),
        .scale = .{
            .x = 4 + 2 * @cos(ctx.seconds()),
            .y = 4 + 2 * @sin(ctx.seconds()),
        },
        .rotate_degree = ctx.seconds() * 30,
        .anchor_point = .{ .x = 0.5, .y = 0.5 },
    });

    j2d.begin(.{ .depth_sort = .back_to_forth });
    defer j2d.end();
    try j2d.image(
        sheet.tex,
        .{ .x = 0, .y = 0 },
        .{},
    );
    try j2d.scene(scene);
}

pub fn quit(ctx: jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});
    sheet.destroy();
    scene.destroy(true);
}
