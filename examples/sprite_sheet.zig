const std = @import("std");
const jok = @import("jok");
const sdl = @import("sdl");
const font = jok.font;
const gfx = jok.gfx.@"2d";

var sheet: *gfx.SpriteSheet = undefined;
var sb: *gfx.SpriteBatch = undefined;
var camera: gfx.Camera = undefined;

pub fn init(ctx: *jok.Context) anyerror!void {
    std.log.info("game init", .{});

    // create sprite sheet
    const size = ctx.getFramebufferSize();
    sheet = try gfx.SpriteSheet.fromPicturesInDir(
        ctx,
        "assets/images",
        size.w,
        size.h,
        1,
        true,
        .{},
    );
    //sheet = try gfx.SpriteSheet.fromSheetFiles(
    //    ctx.allocator,
    //    ctx.renderer,
    //    "sheet",
    //);
    sb = try gfx.SpriteBatch.init(
        ctx,
        10,
        1000,
    );

    camera = gfx.Camera.fromViewport(ctx.renderer.getViewport());
}

pub fn loop(ctx: *jok.Context) anyerror!void {
    const bounds = gfx.Camera.CoordLimit{
        .min_x = -10,
        .min_y = -10,
        .max_x = 1200,
        .max_y = 700,
    };

    while (ctx.pollEvent()) |e| {
        switch (e) {
            .key_up => |key| {
                switch (key.scancode) {
                    .escape => ctx.kill(),
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
            .quit => ctx.kill(),
            else => {},
        }
    }

    try ctx.renderer.setColorRGB(77, 77, 77);
    try ctx.renderer.clear();
    try ctx.renderer.copy(
        sheet.tex,
        camera.translateRectangle(sdl.Rectangle{ .x = 0, .y = 0, .width = 200, .height = 200 }),
        null,
    );

    sb.begin(.{ .depth_sort = .back_to_forth });
    const sprite = try sheet.getSpriteByName("ogre");
    try sb.drawSprite(sprite, .{
        .pos = .{ .x = 400, .y = 300 },
        .camera = camera,
        .scale_w = 2,
        .scale_h = 2,
        .flip_h = true,
        .flip_v = true,
        //.rotate_degree = @floatCast(f32, ctx.tick) * 30,
    });
    try sb.drawSprite(sprite, .{
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
    sheet.deinit();
    sb.deinit();
}
