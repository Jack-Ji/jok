const std = @import("std");
const jok = @import("jok");
const sdl = @import("sdl");
const gfx = jok.gfx.@"2d";

var sheet: *gfx.SpriteSheet = undefined;
var sprite: gfx.Sprite = undefined;
var sprite_batch: *gfx.SpriteBatch = undefined;

fn init(ctx: *jok.Context) anyerror!void {
    _ = ctx;
    std.log.info("game init", .{});

    const size = ctx.getFramebufferSize();

    // create sprite sheet
    sheet = try gfx.SpriteSheet.fromPicturesInDir(
        ctx.default_allocator,
        ctx.renderer,
        "assets/images",
        size.w,
        size.h,
        false,
        .{},
    );
    //sheet = try SpriteSheet.fromSheetFiles(
    //    ctx.default_allocator,
    //    "sheet",
    //);
    sprite = try sheet.createSprite("ogre");
    sprite_batch = try gfx.SpriteBatch.init(
        ctx.default_allocator,
        10,
        1000,
    );
}

fn loop(ctx: *jok.Context) anyerror!void {
    while (ctx.pollEvent()) |e| {
        switch (e) {
            .keyboard_event => |key| {
                if (key.trigger_type == .up) {
                    switch (key.scan_code) {
                        .escape => ctx.kill(),
                        .f2 => try sheet.saveToFiles("sheet"),
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
    try ctx.renderer.setDrawBlendMode(.blend);
    try ctx.renderer.copy(
        sheet.tex,
        sdl.Rectangle{ .x = 0, .y = 0, .width = 200, .height = 200 },
        null,
    );

    sprite_batch.begin(.{ .depth_sort = .back_to_forth });
    try sprite_batch.drawSprite(sprite, .{
        .pos = .{ .x = 400, .y = 300 },
        .scale_w = 2,
        .scale_h = 2,
        .rotate_degree = @floatCast(f32, ctx.tick) * 30,
    });
    try sprite_batch.drawSprite(sprite, .{
        .pos = .{ .x = 400, .y = 300 },
        .anchor_point = .{ .x = 0.5, .y = 0.5 },
        .rotate_degree = @floatCast(f32, ctx.tick) * 30,
        .scale_w = 4 + 2 * @cos(@floatCast(f32, ctx.tick)),
        .scale_h = 4 + 2 * @sin(@floatCast(f32, ctx.tick)),
        .color = sdl.Color.rgb(255, 0, 0),
        .depth = 0.6,
    });
    try sprite_batch.end(ctx.renderer);
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
