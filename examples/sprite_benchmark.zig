const std = @import("std");
const sdl = @import("sdl");
const jok = @import("jok");
const gfx = jok.gfx.@"2d";

pub const jok_fps_limit = jok.config.FpsLimit{ .manual = 120 };

const Actor = struct {
    sprite: gfx.Sprite,
    pos: sdl.PointF,
    velocity: sdl.PointF,
};

var sheet: *gfx.SpriteSheet = undefined;
var sb: *gfx.SpriteBatch = undefined;
var characters: std.ArrayList(Actor) = undefined;
var rand_gen: std.rand.DefaultPrng = undefined;
var delta_tick: f32 = 0;

pub fn init(ctx: *jok.Context) anyerror!void {
    std.log.info("game init", .{});

    const size = ctx.getFramebufferSize();

    // create sprite sheet
    sheet = try gfx.SpriteSheet.init(
        ctx,
        &[_]gfx.SpriteSheet.ImageSource{
            .{
                .name = "ogre",
                .image = .{
                    .file_path = "assets/images/ogre.png",
                },
            },
        },
        size.w,
        size.h,
        1,
        false,
    );
    sb = try gfx.SpriteBatch.init(
        ctx,
        10,
        1000000,
    );
    characters = try std.ArrayList(Actor).initCapacity(
        ctx.allocator,
        1000000,
    );
    rand_gen = std.rand.DefaultPrng.init(@intCast(u64, std.time.timestamp()));

    try ctx.renderer.setColorRGB(77, 77, 77);
}

pub fn loop(ctx: *jok.Context) anyerror!void {
    delta_tick = (delta_tick + ctx.delta_tick) / 2;

    while (ctx.pollEvent()) |e| {
        switch (e) {
            .key_up => |key| {
                switch (key.scancode) {
                    .escape => ctx.kill(),
                    else => {},
                }
            },
            .mouse_button_up => |me| {
                if (me.button != .left) {
                    continue;
                }
                var rd = rand_gen.random();
                const mouse_state = ctx.getMouseState();
                const pos = sdl.PointF{
                    .x = @intToFloat(f32, mouse_state.x),
                    .y = @intToFloat(f32, mouse_state.y),
                };
                var i: u32 = 0;
                while (i < 1000) : (i += 1) {
                    const angle = rd.float(f32) * 2 * std.math.pi;
                    try characters.append(.{
                        .sprite = try sheet.getSpriteByName("ogre"),
                        .pos = pos,
                        .velocity = .{
                            .x = 300 * @cos(angle),
                            .y = 300 * @sin(angle),
                        },
                    });
                }
            },
            .quit => ctx.kill(),
            else => {},
        }
    }

    const size = ctx.getFramebufferSize();
    for (characters.items) |*c| {
        const curpos = c.pos;
        if (curpos.x < 0)
            c.velocity.x = @fabs(c.velocity.x);
        if (curpos.x + c.sprite.width > @intToFloat(f32, size.w))
            c.velocity.x = -@fabs(c.velocity.x);
        if (curpos.y < 0)
            c.velocity.y = @fabs(c.velocity.y);
        if (curpos.y + c.sprite.height > @intToFloat(f32, size.h))
            c.velocity.y = -@fabs(c.velocity.y);
        c.pos.x += c.velocity.x * ctx.delta_tick;
        c.pos.y += c.velocity.y * ctx.delta_tick;
    }

    try ctx.renderer.clear();
    sb.begin(.{});
    for (characters.items) |c| {
        try sb.drawSprite(c.sprite, .{
            .pos = c.pos,
        });
    }
    try sb.end();

    _ = try jok.font.debugDraw(
        ctx.renderer,
        .{ .pos = .{ .x = 0, .y = 0 } },
        "# of sprites: {d}",
        .{characters.items.len},
    );
}

pub fn quit(ctx: *jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});
    sheet.deinit();
    sb.deinit();
    characters.deinit();
}
