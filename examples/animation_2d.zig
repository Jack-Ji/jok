const std = @import("std");
const jok = @import("jok");
const sdl = @import("sdl");
const gfx = jok.gfx.@"2d";

var sheet: *gfx.SpriteSheet = undefined;
var sb: *gfx.SpriteBatch = undefined;
var as: *gfx.AnimationSystem = undefined;

pub fn init(ctx: *jok.Context) anyerror!void {
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
    sb = try gfx.SpriteBatch.init(
        ctx.default_allocator,
        10,
        1000,
    );
    as = try gfx.AnimationSystem.init(ctx.default_allocator);
    const player = try sheet.getSpriteByName("player");
    try as.add(
        "player_left_right",
        try gfx.AnimationSystem.Animation.init(
            ctx.default_allocator,
            &[_]gfx.Sprite{
                player.getSubSprite(4 * 16, 0, 16, 16),
                player.getSubSprite(3 * 16, 0, 16, 16),
                player.getSubSprite(5 * 16, 0, 16, 16),
                player.getSubSprite(3 * 16, 0, 16, 16),
            },
            6,
            false,
        ),
    );
    try as.add(
        "player_up",
        try gfx.AnimationSystem.Animation.init(
            ctx.default_allocator,
            &[_]gfx.Sprite{
                player.getSubSprite(7 * 16, 0, 16, 16),
                player.getSubSprite(6 * 16, 0, 16, 16),
                player.getSubSprite(8 * 16, 0, 16, 16),
                player.getSubSprite(6 * 16, 0, 16, 16),
            },
            6,
            false,
        ),
    );
    try as.add(
        "player_down",
        try gfx.AnimationSystem.Animation.init(
            ctx.default_allocator,
            &[_]gfx.Sprite{
                player.getSubSprite(1 * 16, 0, 16, 16),
                player.getSubSprite(0 * 16, 0, 16, 16),
                player.getSubSprite(2 * 16, 0, 16, 16),
                player.getSubSprite(0 * 16, 0, 16, 16),
            },
            6,
            false,
        ),
    );
}

pub fn loop(ctx: *jok.Context) anyerror!void {
    const S = struct {
        const velocity = 100;
        var animation: []const u8 = "player_down";
        var pos = sdl.PointF{ .x = 200, .y = 200 };
        var flip_h = false;
        var force_replay = false;
    };

    if (ctx.isKeyPressed(.up)) {
        S.pos.y -= S.velocity * ctx.delta_tick;
        S.animation = "player_up";
        S.flip_h = false;
        S.force_replay = true;
    } else if (ctx.isKeyPressed(.down)) {
        S.pos.y += S.velocity * ctx.delta_tick;
        S.animation = "player_down";
        S.flip_h = false;
        S.force_replay = true;
    } else if (ctx.isKeyPressed(.right)) {
        S.pos.x += S.velocity * ctx.delta_tick;
        S.animation = "player_left_right";
        S.flip_h = true;
        S.force_replay = true;
    } else if (ctx.isKeyPressed(.left)) {
        S.pos.x -= S.velocity * ctx.delta_tick;
        S.animation = "player_left_right";
        S.flip_h = false;
        S.force_replay = true;
    } else {
        S.force_replay = false;
    }

    while (ctx.pollEvent()) |e| {
        switch (e) {
            .keyboard_event => |key| {
                if (key.trigger_type == .up) {
                    switch (key.scan_code) {
                        .escape => ctx.kill(),
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

    sb.begin(.{});
    try sb.drawSprite(
        try sheet.getSpriteByName("player"),
        .{
            .pos = .{ .x = 0, .y = 50 },
            .tint_color = sdl.Color.rgb(100, 100, 100),
            .scale_w = 4,
            .scale_h = 4,
        },
    );
    try as.play(
        S.animation,
        ctx.delta_tick,
        sb,
        .{
            .pos = S.pos,
            .flip_h = S.flip_h,
            .scale_w = 5,
            .scale_h = 5,
        },
        S.force_replay,
    );
    try sb.end(ctx.renderer);

    _ = try gfx.font.debugDraw(
        ctx.renderer,
        .{ .pos = .{ .x = 300, .y = 0 } },
        "Press up/down/left/right to move character around",
        .{},
    );
}

pub fn quit(ctx: *jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});
    sheet.deinit();
    sb.deinit();
    as.deinit();
}
