const std = @import("std");
const sdl = @import("sdl");
const jok = @import("jok");
const j2d = jok.j2d;

var rd: std.rand.DefaultPrng = undefined;
var sheet: *j2d.SpriteSheet = undefined;
var sb: *j2d.SpriteBatch = undefined;
var ps: *j2d.ParticleSystem = undefined;

// fire effect
const emitter1 = j2d.ParticleSystem.Effect.FireEmitter(
    50,
    3,
    sdl.Color.red,
    sdl.Color.yellow,
    2.75,
);
const emitter2 = j2d.ParticleSystem.Effect.FireEmitter(
    50,
    3,
    sdl.Color.red,
    sdl.Color.green,
    2.75,
);

pub fn init(ctx: *jok.Context) !void {
    std.log.info("game init", .{});

    rd = std.rand.DefaultPrng.init(@intCast(u64, std.time.timestamp()));
    sheet = try j2d.SpriteSheet.init(
        ctx,
        &[_]j2d.SpriteSheet.ImageSource{
            .{
                .name = "particle",
                .image = .{
                    .file_path = "assets/images/white-circle.png",
                },
            },
        },
        100,
        100,
        1,
        false,
    );
    sb = try j2d.SpriteBatch.init(
        ctx,
        1,
        10000,
    );
    ps = try j2d.ParticleSystem.init(ctx.allocator);
    emitter1.sprite = try sheet.getSpriteByName("particle");
    emitter2.sprite = try sheet.getSpriteByName("particle");
    try ps.addEffect(
        rd.random(),
        8000,
        emitter1.emit,
        j2d.Vector.new(400, 500),
        60,
        40,
        0.016,
    );
    try ps.addEffect(
        rd.random(),
        2000,
        emitter2.emit,
        j2d.Vector.new(200, 500),
        60,
        10,
        0.016,
    );
}

pub fn event(ctx: *jok.Context, e: sdl.Event) !void {
    _ = ctx;
    _ = e;
}

pub fn update(ctx: *jok.Context) !void {
    if (ctx.isKeyPressed(.up)) ps.effects.items[0].origin = ps.effects.items[0].origin.add(j2d.Vector.new(0, -10));
    if (ctx.isKeyPressed(.down)) ps.effects.items[0].origin = ps.effects.items[0].origin.add(j2d.Vector.new(0, 10));
    if (ctx.isKeyPressed(.left)) ps.effects.items[0].origin = ps.effects.items[0].origin.add(j2d.Vector.new(-10, 0));
    if (ctx.isKeyPressed(.right)) ps.effects.items[0].origin = ps.effects.items[0].origin.add(j2d.Vector.new(10, 0));

    ps.update(ctx.delta_tick);
}

pub fn draw(ctx: *jok.Context) !void {
    _ = ctx;

    sb.begin(.{ .blend_method = .additive });
    try ps.draw(sb);
    try sb.end();
}

pub fn quit(ctx: *jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});
    sheet.deinit();
    sb.deinit();
    ps.deinit();
}
