const std = @import("std");
const jok = @import("jok");
const sdl = @import("sdl");
const gfx = jok.gfx.@"2d";

var sheet: *gfx.SpriteSheet = undefined;
var sprite: gfx.Sprite = undefined;
var sprite_batch: *gfx.SpriteBatch = undefined;
var camera: gfx.Camera = undefined;

fn init(ctx: *jok.Context) anyerror!void {
    _ = ctx;
    std.log.info("game init", .{});

    // create sprite sheet
    const size = ctx.getFramebufferSize();
    sheet = try gfx.SpriteSheet.fromPicturesInDir(
        ctx.default_allocator,
        ctx.renderer,
        "assets/images",
        size.w,
        size.h,
        1,
        true,
        .{},
    );
    //sheet = try gfx.SpriteSheet.fromSheetFiles(
    //    ctx.default_allocator,
    //    ctx.renderer,
    //    "sheet",
    //);
    sprite = try sheet.createSprite("ogre");
    sprite_batch = try gfx.SpriteBatch.init(
        ctx.default_allocator,
        10,
        1000,
    );

    camera = gfx.Camera.fromViewport(ctx.renderer.getViewport());
}

fn loop(ctx: *jok.Context) anyerror!void {
    const bounds = gfx.Camera.CoordLimit{
        .min_x = -10,
        .min_y = -10,
        .max_x = 1200,
        .max_y = 700,
    };

    while (ctx.pollEvent()) |e| {
        switch (e) {
            .keyboard_event => |key| {
                if (key.trigger_type == .up) {
                    switch (key.scan_code) {
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
                }
            },
            .quit_event => ctx.kill(),
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

    sprite_batch.begin(.{ .depth_sort = .back_to_forth });
    try sprite_batch.drawSprite(sprite, .{
        .pos = .{ .x = 400, .y = 300 },
        .camera = camera,
        .scale_w = 2,
        .scale_h = 2,
        //.rotate_degree = @floatCast(f32, ctx.tick) * 30,
    });
    try sprite_batch.drawSprite(sprite, .{
        .pos = .{ .x = 400, .y = 300 },
        .camera = camera,
        .tint_color = sdl.Color.rgb(255, 0, 0),
        .scale_w = 4 + 2 * @cos(@floatCast(f32, ctx.tick)),
        .scale_h = 4 + 2 * @sin(@floatCast(f32, ctx.tick)),
        .rotate_degree = @floatCast(f32, ctx.tick) * 30,
        .anchor_point = .{ .x = 0.5, .y = 0.5 },
        .depth = 0.6,
    });
    try sprite_batch.end(ctx.renderer);

    var buf: [128]u8 = undefined;
    var txt = try std.fmt.bufPrint(&buf, "fps: {d:.1}", .{ctx.fps});
    var result = try gfx.font.debugDraw(
        ctx.renderer,
        txt,
        .{ .pos = .{ .x = 300, .y = 0 }, .color = sdl.Color.white },
    );
    txt = try std.fmt.bufPrint(&buf, "press z to zoom out, x to zoom in, current zoom value: {d:.1}", .{camera.zoom});
    result = try gfx.font.debugDraw(
        ctx.renderer,
        txt,
        .{ .pos = .{ .x = 300, .y = result.next_line_ypos }, .color = sdl.Color.white },
    );
    txt = try std.fmt.bufPrint(&buf, "camera pos: {d:.0},{d:.0}", .{ camera.pos.x, camera.pos.y });
    result = try gfx.font.debugDraw(
        ctx.renderer,
        txt,
        .{ .pos = .{ .x = 300, .y = result.next_line_ypos }, .color = sdl.Color.white },
    );
    txt = try std.fmt.bufPrint(&buf, "camera half-size: {d:.0},{d:.0}", .{ camera.half_size.x, camera.half_size.y });
    _ = try gfx.font.debugDraw(
        ctx.renderer,
        txt,
        .{ .pos = .{ .x = 300, .y = result.next_line_ypos }, .color = sdl.Color.white },
    );
}

fn quit(ctx: *jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});
    sheet.deinit();
    sprite_batch.deinit();
}

pub fn main() anyerror!void {
    try jok.run(.{
        .initFn = init,
        .loopFn = loop,
        .quitFn = quit,
    });
}
