const std = @import("std");
const jok = @import("jok");
const sdl = @import("sdl");
const font = jok.font;
const j2d = jok.j2d;

var sheet: *j2d.SpriteSheet = undefined;

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

    try ctx.renderer.setColorRGB(77, 77, 77);
}

pub fn event(ctx: *jok.Context, e: sdl.Event) !void {
    _ = ctx;
    _ = e;
}

pub fn update(ctx: *jok.Context) !void {
    _ = ctx;
}

pub fn draw(ctx: *jok.Context) !void {
    try ctx.renderer.copy(
        sheet.tex,
        null,
        null,
    );

    try j2d.begin(.{ .depth_sort = .back_to_forth });
    const sprite = sheet.getSpriteByName("ogre").?;
    try j2d.addSprite(sprite, .{
        .pos = .{ .x = 400, .y = 300 },
        .scale = .{ .x = 2, .y = 2 },
        .flip_h = true,
        .flip_v = true,
        //.rotate_degree = @floatCast(f32, ctx.tick) * 30,
    });
    try j2d.addSprite(sprite, .{
        .pos = .{ .x = 400, .y = 300 },
        .tint_color = sdl.Color.rgb(255, 0, 0),
        .scale = .{
            .x = 4 + 2 * @cos(@floatCast(f32, ctx.tick)),
            .y = 4 + 2 * @sin(@floatCast(f32, ctx.tick)),
        },
        .rotate_degree = @floatCast(f32, ctx.tick) * 30,
        .anchor_point = .{ .x = 0.5, .y = 0.5 },
        .depth = 0.6,
    });
    try j2d.end();
}

pub fn quit(ctx: *jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});
    sheet.destroy();
}
