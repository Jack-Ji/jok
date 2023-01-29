const std = @import("std");
const jok = @import("jok");
const sdl = @import("sdl");
const font = jok.font;
const j2d = jok.j2d;

var sheet: *j2d.SpriteSheet = undefined;
var sb: *j2d.SpriteBatch = undefined;
var camera: j2d.Camera = undefined;

pub fn init(ctx: *jok.Context) !void {
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
    //sheet = try j2d.SpriteSheet.fromSheetFiles(
    //    ctx.allocator,
    //    ctx.renderer,
    //    "sheet",
    //);
    sb = try j2d.SpriteBatch.create(
        ctx,
        10,
        1000,
    );

    camera = j2d.Camera.fromViewport(ctx.renderer.getViewport());

    try ctx.renderer.setColorRGB(77, 77, 77);
}

pub fn event(ctx: *jok.Context, e: sdl.Event) !void {
    _ = ctx;
    const bounds = j2d.Camera.CoordLimit{
        .min_x = -10,
        .min_y = -10,
        .max_x = 1200,
        .max_y = 700,
    };

    switch (e) {
        .key_up => |key| {
            switch (key.scancode) {
                .f2 => try sheet.saveToFiles("sheet"),
                .left => camera.move(-10, 0, bounds),
                .right => camera.move(10, 0, bounds),
                .up => camera.move(0, -10, bounds),
                .down => camera.move(0, 10, bounds),
                .z => camera.setZoom(std.math.min(2, camera.zoom + 0.1), bounds),
                .x => camera.setZoom(std.math.max(0.1, camera.zoom - 0.1), bounds),
                else => {},
            }
        },
        else => {},
    }
}

pub fn update(ctx: *jok.Context) !void {
    _ = ctx;
}

pub fn draw(ctx: *jok.Context) !void {
    try ctx.renderer.copy(
        sheet.tex,
        camera.translateRectangle(sdl.Rectangle{ .x = 0, .y = 0, .width = 200, .height = 200 }),
        null,
    );

    sb.begin(.{ .depth_sort = .back_to_forth });
    const sprite = sheet.getSpriteByName("ogre").?;
    try sb.addSprite(sprite, .{
        .pos = .{ .x = 400, .y = 300 },
        .camera = camera,
        .scale_w = 2,
        .scale_h = 2,
        .flip_h = true,
        .flip_v = true,
        //.rotate_degree = @floatCast(f32, ctx.tick) * 30,
    });
    try sb.addSprite(sprite, .{
        .pos = .{ .x = 400, .y = 300 },
        .camera = camera,
        .tint_color = sdl.Color.rgb(255, 0, 0),
        .scale_w = 4 + 2 * @cos(@floatCast(f32, ctx.tick)),
        .scale_h = 4 + 2 * @sin(@floatCast(f32, ctx.tick)),
        .rotate_degree = @floatCast(f32, ctx.tick) * 30,
        .anchor_point = .{ .x = 0.5, .y = 0.5 },
        .depth = 0.6,
    });
    try sb.end();

    var result = try font.debugDraw(
        ctx.renderer,
        .{ .pos = .{ .x = 300, .y = 0 } },
        "press z to zoom out, x to zoom in, current zoom value: {d:.1}",
        .{camera.zoom},
    );
    result = try font.debugDraw(
        ctx.renderer,
        .{ .pos = .{ .x = 300, .y = result.next_line_ypos } },
        "camera pos: {d:.0},{d:.0}",
        .{ camera.pos.x, camera.pos.y },
    );
    _ = try font.debugDraw(
        ctx.renderer,
        .{ .pos = .{ .x = 300, .y = result.next_line_ypos } },
        "camera half-size: {d:.0},{d:.0}",
        .{ camera.half_size.x, camera.half_size.y },
    );
}

pub fn quit(ctx: *jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});
    sheet.destroy();
    sb.destroy();
}
