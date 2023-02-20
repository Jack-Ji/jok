const std = @import("std");
const jok = @import("jok");
const sdl = @import("sdl");
const j2d = jok.j2d;

var sheet: *j2d.SpriteSheet = undefined;
var scene: *j2d.Scene = undefined;
var ogre1: *j2d.Scene.Object = undefined;
var ogre2: *j2d.Scene.Object = undefined;

pub fn init(ctx: jok.Context) !void {
    std.log.info("game init", .{});

    // create sprite sheet
    const size = ctx.getFramebufferSize();
    sheet = try j2d.SpriteSheet.fromPicturesInDir(
        ctx,
        "assets/images",
        @floatToInt(u32, size.x),
        @floatToInt(u32, size.y),
        1,
        true,
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

    try ctx.renderer().setColorRGB(77, 77, 77);
}

pub fn event(ctx: jok.Context, e: sdl.Event) !void {
    _ = ctx;
    _ = e;
}

pub fn update(ctx: jok.Context) !void {
    _ = ctx;
}

pub fn draw(ctx: jok.Context) !void {
    ogre1.setRenderOptions(.{
        .pos = .{ .x = 400, .y = 300 },
        .tint_color = sdl.Color.rgb(255, 0, 0),
        .scale = .{
            .x = 4 + 2 * @cos(ctx.seconds()),
            .y = 4 + 2 * @sin(ctx.seconds()),
        },
        .rotate_degree = ctx.seconds() * 30,
        .anchor_point = .{ .x = 0.5, .y = 0.5 },
    });

    try j2d.begin(.{ .depth_sort = .back_to_forth });
    try j2d.addImage(
        sheet.tex,
        .{ .x = 0, .y = 0 },
        .{},
    );
    try j2d.addScene(scene);
    try j2d.end();
}

pub fn quit(ctx: jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});
    sheet.destroy();
    scene.destroy(true);
}
