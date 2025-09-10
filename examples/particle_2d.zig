const std = @import("std");
const builtin = @import("builtin");
const jok = @import("jok");
const physfs = jok.physfs;
const j2d = jok.j2d;

var batchpool: j2d.BatchPool(64, false) = undefined;
var rd: std.Random.DefaultPrng = undefined;
var sheet: *j2d.SpriteSheet = undefined;
var font: *jok.font.Font = undefined;
var atlas: *jok.font.Atlas = undefined;
var ps: *j2d.ParticleSystem = undefined;

// fire effect
const emitter1 = j2d.ParticleSystem.Effect.FireEmitter(
    50,
    200,
    3,
    .red,
    .yellow,
    2.75,
);
const emitter2 = j2d.ParticleSystem.Effect.FireEmitter(
    50,
    200,
    3,
    .red,
    .green,
    2.75,
);

pub fn init(ctx: jok.Context) !void {
    std.log.info("game init", .{});

    if (!builtin.cpu.arch.isWasm()) {
        try physfs.mount("assets", "/", true);
    }

    batchpool = try @TypeOf(batchpool).init(ctx);
    rd = std.Random.DefaultPrng.init(@intCast(std.time.timestamp()));
    sheet = try j2d.SpriteSheet.create(
        ctx,
        &[_]j2d.SpriteSheet.ImageSource{
            .{
                .name = "particle",
                .image = .{
                    .file_path = "images/white-circle.png",
                },
            },
        },
        100,
        100,
        .{},
    );
    font = try jok.font.Font.fromTrueTypeData(
        ctx.allocator(),
        jok.font.DebugFont.font_data,
    );
    atlas = try font.createAtlas(ctx, 60, null, .{});
    ps = try j2d.ParticleSystem.create(ctx.allocator());
    emitter1.sprite = sheet.getSpriteByName("particle");
    emitter2.sprite = atlas.getSpriteOfCodePoint('*');
    try ps.addEffect(
        rd.random(),
        8000,
        emitter1.emit,
        j2d.Vector.new(400, 500),
        60,
        40,
        0.016,
        .{},
    );
    try ps.addEffect(
        rd.random(),
        2000,
        emitter2.emit,
        j2d.Vector.new(200, 500),
        60,
        10,
        0.016,
        .{},
    );
}

pub fn event(ctx: jok.Context, e: jok.Event) !void {
    _ = ctx;
    _ = e;
}

pub fn update(ctx: jok.Context) !void {
    const kbd = jok.io.getKeyboardState();
    if (kbd.isPressed(.up)) ps.effects.items[0].origin = ps.effects.items[0].origin.add(j2d.Vector.new(0, -10));
    if (kbd.isPressed(.down)) ps.effects.items[0].origin = ps.effects.items[0].origin.add(j2d.Vector.new(0, 10));
    if (kbd.isPressed(.left)) ps.effects.items[0].origin = ps.effects.items[0].origin.add(j2d.Vector.new(-10, 0));
    if (kbd.isPressed(.right)) ps.effects.items[0].origin = ps.effects.items[0].origin.add(j2d.Vector.new(10, 0));

    ps.update(ctx.deltaSeconds());
}

pub fn draw(ctx: jok.Context) !void {
    try ctx.renderer().clear(.black);
    ctx.displayStats(.{});

    var b = try batchpool.new(.{ .blend_mode = .additive });
    defer b.submit();
    try b.effects(ps);
}

pub fn quit(ctx: jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});
    atlas.destroy();
    font.destroy();
    sheet.destroy();
    ps.destroy();
    batchpool.deinit();
}
