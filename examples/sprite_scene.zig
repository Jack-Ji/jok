const std = @import("std");
const jok = @import("jok");
const sdl = @import("sdl");
const j2d = jok.j2d;

var sheet: *j2d.SpriteSheet = undefined;
var sb: *j2d.SpriteBatch = undefined;
var scene: *j2d.Scene = undefined;
var camera: j2d.Camera = undefined;
var ogre1: *j2d.Scene.Object = undefined;
var ogre2: *j2d.Scene.Object = undefined;

pub fn init(ctx: *jok.Context) anyerror!void {
    std.log.info("game init", .{});

    // create sprite sheet
    const size = ctx.getFramebufferSize();
    sheet = try j2d.SpriteSheet.fromPicturesInDir(
        ctx,
        "assets/images",
        size.w,
        size.h,
        1,
        true,
        .{},
    );
    sb = try j2d.SpriteBatch.init(
        ctx,
        10,
        1000,
    );
    scene = try j2d.Scene.init(ctx.allocator, sb);
    ogre1 = try j2d.Scene.Object.init(ctx.allocator, .{
        .sprite = try sheet.getSpriteByName("ogre"),
        .render_opt = .{
            .pos = .{ .x = 400, .y = 300 },
        },
    }, null);
    ogre2 = try j2d.Scene.Object.init(ctx.allocator, .{
        .sprite = try sheet.getSpriteByName("ogre"),
        .render_opt = .{
            .pos = .{ .x = 0, .y = 0 },
            .scale_w = 0.5,
            .scale_h = 0.5,
        },
    }, null);
    try ogre1.addChild(ogre2);
    try scene.root.addChild(ogre1);

    camera = j2d.Camera.fromViewport(ctx.renderer.getViewport());
    try ctx.renderer.setColorRGB(77, 77, 77);
}

pub fn event(ctx: *jok.Context, e: sdl.Event) anyerror!void {
    _ = ctx;
    _ = e;
}

pub fn update(ctx: *jok.Context) anyerror!void {
    try ctx.renderer.copy(
        sheet.tex,
        sdl.Rectangle{ .x = 0, .y = 0, .width = 200, .height = 200 },
        null,
    );

    ogre1.setRenderOptions(.{
        .pos = .{ .x = 400, .y = 300 },
        .tint_color = sdl.Color.rgb(255, 0, 0),
        .scale_w = 4 + 2 * @cos(@floatCast(f32, ctx.tick)),
        .scale_h = 4 + 2 * @sin(@floatCast(f32, ctx.tick)),
        .rotate_degree = @floatCast(f32, ctx.tick) * 30,
        .anchor_point = .{ .x = 0.5, .y = 0.5 },
    });

    scene.sb.begin(.{ .depth_sort = .back_to_forth });
    try scene.draw(camera);
    try scene.sb.end();
}

pub fn quit(ctx: *jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});
    sheet.deinit();
    sb.deinit();
    scene.deinit(true);
}
