const std = @import("std");
const sdl = @import("sdl");
const jok = @import("jok");
const gfx = jok.gfx.@"2d";

var rd: std.rand.DefaultPrng = undefined;
var sheet: *gfx.SpriteSheet = undefined;
var sb: *gfx.SpriteBatch = undefined;
var ps: *gfx.ParticleSystem = undefined;

// fire effect
const emitter1 = gfx.ParticleSystem.Effect.FireEmitter(
    50,
    3,
    sdl.Color.red,
    sdl.Color.yellow,
    2.75,
);
const emitter2 = gfx.ParticleSystem.Effect.FireEmitter(
    50,
    3,
    sdl.Color.red,
    sdl.Color.green,
    2.75,
);

fn init(ctx: *jok.Context) anyerror!void {
    _ = ctx;
    std.log.info("game init", .{});

    rd = std.rand.DefaultPrng.init(@intCast(u64, std.time.timestamp()));
    sheet = try gfx.SpriteSheet.init(
        ctx.default_allocator,
        ctx.renderer,
        &[_]gfx.SpriteSheet.ImageSource{
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
    sb = try gfx.SpriteBatch.init(
        ctx.default_allocator,
        1,
        10000,
    );
    ps = try gfx.ParticleSystem.init(ctx.default_allocator);
    emitter1.sprite = try sheet.getSpriteByName("particle");
    emitter2.sprite = try sheet.getSpriteByName("particle");
    try ps.addEffect(
        rd.random(),
        8000,
        emitter1.emit,
        gfx.Vector.new(400, 500),
        60,
        40,
        0.016,
    );
    try ps.addEffect(
        rd.random(),
        2000,
        emitter2.emit,
        gfx.Vector.new(200, 500),
        60,
        10,
        0.016,
    );
}

fn loop(ctx: *jok.Context) anyerror!void {
    if (ctx.isKeyPressed(.up)) ps.effects.items[0].origin = ps.effects.items[0].origin.add(gfx.Vector.new(0, -10));
    if (ctx.isKeyPressed(.down)) ps.effects.items[0].origin = ps.effects.items[0].origin.add(gfx.Vector.new(0, 10));
    if (ctx.isKeyPressed(.left)) ps.effects.items[0].origin = ps.effects.items[0].origin.add(gfx.Vector.new(-10, 0));
    if (ctx.isKeyPressed(.right)) ps.effects.items[0].origin = ps.effects.items[0].origin.add(gfx.Vector.new(10, 0));

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

    try ctx.renderer.clear();
    ps.update(ctx.delta_tick);
    sb.begin(.{ .blend_method = .additive });
    try ps.draw(sb);
    try sb.end(ctx.renderer);
}

fn quit(ctx: *jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});
    sheet.deinit();
    sb.deinit();
    ps.deinit();
}

pub fn main() anyerror!void {
    try jok.run(.{
        .initFn = init,
        .loopFn = loop,
        .quitFn = quit,
    });
}
