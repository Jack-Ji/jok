const std = @import("std");
const jok = @import("jok");
const sdl = @import("sdl");
const j2d = jok.j2d;

var sheet: *j2d.SpriteSheet = undefined;
var as: *j2d.AnimationSystem = undefined;
const velocity = 100;
var animation: []const u8 = "player_down";
var pos = sdl.PointF{ .x = 200, .y = 200 };
var flip_h = false;

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
    as = try j2d.AnimationSystem.create(ctx.allocator);
    const player = sheet.getSpriteByName("player").?;
    try as.add(
        "player_left_right",
        &[_]j2d.Sprite{
            player.getSubSprite(4 * 16, 0, 16, 16),
            player.getSubSprite(5 * 16, 0, 16, 16),
            player.getSubSprite(3 * 16, 0, 16, 16),
        },
        6,
        false,
    );
    try as.add(
        "player_up",
        &[_]j2d.Sprite{
            player.getSubSprite(7 * 16, 0, 16, 16),
            player.getSubSprite(8 * 16, 0, 16, 16),
            player.getSubSprite(6 * 16, 0, 16, 16),
        },
        6,
        false,
    );
    try as.add(
        "player_down",
        &[_]j2d.Sprite{
            player.getSubSprite(1 * 16, 0, 16, 16),
            player.getSubSprite(2 * 16, 0, 16, 16),
            player.getSubSprite(0 * 16, 0, 16, 16),
        },
        6,
        false,
    );

    try ctx.renderer.setColorRGB(77, 77, 77);
}

pub fn event(ctx: *jok.Context, e: sdl.Event) !void {
    _ = ctx;
    _ = e;
}

pub fn update(ctx: *jok.Context) !void {
    var force_replay = false;
    if (ctx.isKeyPressed(.up)) {
        pos.y -= velocity * ctx.delta_seconds;
        animation = "player_up";
        flip_h = false;
        force_replay = true;
    } else if (ctx.isKeyPressed(.down)) {
        pos.y += velocity * ctx.delta_seconds;
        animation = "player_down";
        flip_h = false;
        force_replay = true;
    } else if (ctx.isKeyPressed(.right)) {
        pos.x += velocity * ctx.delta_seconds;
        animation = "player_left_right";
        flip_h = true;
        force_replay = true;
    } else if (ctx.isKeyPressed(.left)) {
        pos.x -= velocity * ctx.delta_seconds;
        animation = "player_left_right";
        flip_h = false;
        force_replay = true;
    }
    if (force_replay and try as.isOver(animation)) {
        try as.reset(animation);
    }
    as.update(ctx.delta_seconds);
}

pub fn draw(ctx: *jok.Context) !void {
    try j2d.begin(.{});
    try j2d.addSprite(
        sheet.getSpriteByName("player").?,
        .{
            .pos = .{ .x = 0, .y = 50 },
            .tint_color = sdl.Color.rgb(100, 100, 100),
            .scale = .{ .x = 4, .y = 4 },
        },
    );
    try j2d.addSprite(
        try as.getCurrentFrame(animation),
        .{
            .pos = pos,
            .flip_h = flip_h,
            .scale = .{ .x = 5, .y = 5 },
        },
    );
    try j2d.end();

    _ = try jok.font.debugDraw(
        ctx.renderer,
        .{ .pos = .{ .x = 300, .y = 0 } },
        "Press up/down/left/right to move character around",
        .{},
    );
}

pub fn quit(ctx: *jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});
    sheet.destroy();
    as.destroy();
}
