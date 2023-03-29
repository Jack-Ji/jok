const std = @import("std");
const jok = @import("jok");
const sdl = jok.sdl;
const j2d = jok.j2d;

pub const jok_fps_limit: jok.config.FpsLimit = .none;

const Actor = struct {
    sprite: j2d.Sprite,
    pos: sdl.PointF,
    velocity: sdl.PointF,
};

var sheet: *j2d.SpriteSheet = undefined;
var characters: std.ArrayList(Actor) = undefined;
var rand_gen: std.rand.DefaultPrng = undefined;
var delta_tick: f32 = 0;

pub fn init(ctx: jok.Context) !void {
    std.log.info("game init", .{});

    const size = ctx.getFramebufferSize();

    // create sprite sheet
    sheet = try j2d.SpriteSheet.create(
        ctx,
        &[_]j2d.SpriteSheet.ImageSource{
            .{
                .name = "ogre",
                .image = .{
                    .file_path = "assets/images/ogre.png",
                },
            },
        },
        @floatToInt(u32, size.x),
        @floatToInt(u32, size.y),
        1,
        false,
    );
    characters = try std.ArrayList(Actor).initCapacity(
        ctx.allocator(),
        1000000,
    );
    rand_gen = std.rand.DefaultPrng.init(@intCast(u64, std.time.timestamp()));

    try ctx.renderer().setColorRGB(77, 77, 77);
}

pub fn event(ctx: jok.Context, e: sdl.Event) !void {
    _ = ctx;
    _ = e;
}

pub fn update(ctx: jok.Context) !void {
    const mouse = ctx.getMouseState();
    if (mouse.buttons.getPressed(.left)) {
        var rd = rand_gen.random();
        const pos = sdl.PointF{
            .x = @intToFloat(f32, mouse.x),
            .y = @intToFloat(f32, mouse.y),
        };
        var i: u32 = 0;
        while (i < 10) : (i += 1) {
            const angle = rd.float(f32) * 2 * std.math.pi;
            try characters.append(.{
                .sprite = sheet.getSpriteByName("ogre").?,
                .pos = pos,
                .velocity = .{
                    .x = 300 * @cos(angle),
                    .y = 300 * @sin(angle),
                },
            });
        }
    }

    delta_tick = (delta_tick + ctx.deltaSeconds()) / 2;
    const size = ctx.getFramebufferSize();
    for (characters.items) |*c| {
        const curpos = c.pos;
        if (curpos.x < 0)
            c.velocity.x = @fabs(c.velocity.x);
        if (curpos.x + c.sprite.width > size.x)
            c.velocity.x = -@fabs(c.velocity.x);
        if (curpos.y < 0)
            c.velocity.y = @fabs(c.velocity.y);
        if (curpos.y + c.sprite.height > size.y)
            c.velocity.y = -@fabs(c.velocity.y);
        c.pos.x += c.velocity.x * ctx.deltaSeconds();
        c.pos.y += c.velocity.y * ctx.deltaSeconds();
    }
}

pub fn draw(ctx: jok.Context) !void {
    try j2d.begin(.{});
    for (characters.items) |c| {
        try j2d.sprite(c.sprite, .{
            .pos = c.pos,
        });
    }
    try j2d.end();

    _ = try jok.font.debugDraw(
        ctx,
        .{ .pos = .{ .x = 0, .y = 0 } },
        "# of sprites: {d}",
        .{characters.items.len},
    );
}

pub fn quit(ctx: jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});
    sheet.destroy();
    characters.deinit();
}
