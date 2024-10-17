const std = @import("std");
const jok = @import("jok");
const physfs = jok.physfs;
const j2d = jok.j2d;

var sheet: *j2d.SpriteSheet = undefined;
var as: *j2d.AnimationSystem = undefined;
const velocity = 100;
var animation: []const u8 = "player_down";
var pos = jok.Point{ .x = 200, .y = 200 };
var flip_h = false;

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
    as = try j2d.AnimationSystem.create(ctx.allocator());
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
}

pub fn event(ctx: jok.Context, e: jok.Event) !void {
    _ = ctx;
    _ = e;
}

pub fn update(ctx: jok.Context) !void {
    var force_replay = false;
    const kbd = jok.io.getKeyboardState();
    if (kbd.isPressed(.up)) {
        pos.y -= velocity * ctx.deltaSeconds();
        animation = "player_up";
        flip_h = false;
        force_replay = true;
    } else if (kbd.isPressed(.down)) {
        pos.y += velocity * ctx.deltaSeconds();
        animation = "player_down";
        flip_h = false;
        force_replay = true;
    } else if (kbd.isPressed(.right)) {
        pos.x += velocity * ctx.deltaSeconds();
        animation = "player_left_right";
        flip_h = true;
        force_replay = true;
    } else if (kbd.isPressed(.left)) {
        pos.x -= velocity * ctx.deltaSeconds();
        animation = "player_left_right";
        flip_h = false;
        force_replay = true;
    }
    if (force_replay and try as.isOver(animation)) {
        try as.reset(animation);
    }
    as.update(ctx.deltaSeconds());
}

pub fn draw(ctx: jok.Context) !void {
    try ctx.renderer().clear(jok.Color.rgb(77, 77, 77));

    j2d.begin(.{});
    defer j2d.end();
    try j2d.sprite(
        sheet.getSpriteByName("player").?,
        .{
            .pos = .{ .x = 0, .y = 50 },
            .tint_color = jok.Color.rgb(100, 100, 100),
            .scale = .{ .x = 4, .y = 4 },
        },
    );
    try j2d.sprite(
        try as.getCurrentFrame(animation),
        .{
            .pos = pos,
            .flip_h = flip_h,
            .scale = .{ .x = 5, .y = 5 },
        },
    );

    jok.font.debugDraw(
        ctx,
        .{ .x = 300, .y = 0 },
        "Press up/down/left/right to move character around",
        .{},
    );
}

pub fn quit(ctx: jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});
    sheet.destroy();
    as.destroy();
}
