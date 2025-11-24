const std = @import("std");
const builtin = @import("builtin");
const jok = @import("jok");
const j2d = jok.j2d;
const physfs = jok.vendor.physfs;

var batchpool: j2d.BatchPool(64, false) = undefined;
var rd: std.Random.DefaultPrng = undefined;
var sheet: *j2d.SpriteSheet = undefined;
var font: *jok.font.Font = undefined;
var atlas: *jok.font.Atlas = undefined;
var ps: *j2d.ParticleSystem = undefined;
var emitter1: j2d.ParticleSystem.FireEmitter = undefined;
var emitter2: j2d.ParticleSystem.FireEmitter = undefined;
var e1: *j2d.ParticleSystem.Effect = undefined;
var e2: *j2d.ParticleSystem.Effect = undefined;

// fire effect
pub fn init(ctx: jok.Context) !void {
    std.log.info("game init", .{});

    if (!builtin.cpu.arch.isWasm()) {
        try physfs.mount("assets", "/", true);
    }

    batchpool = try @TypeOf(batchpool).init(ctx);
    var thread = std.Io.Threaded.init_single_threaded;
    const io = thread.ioBasic();
    rd = std.Random.DefaultPrng.init(@intCast((try std.Io.Clock.awake.now(io)).toSeconds()));
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
    emitter1 = j2d.ParticleSystem.FireEmitter{
        .draw_data = .{ .sprite = sheet.getSpriteByName("particle").? },
    };
    emitter2 = j2d.ParticleSystem.FireEmitter{
        .draw_data = .{ .sprite = atlas.getSpriteOfCodePoint('*').? },
    };
    e1 = try ps.add("fire1", emitter1.emitter(), .{ .origin = .{ .x = 400, .y = 300 } });
    e2 = try ps.add("fire2", emitter2.emitter(), .{ .origin = .{ .x = 200, .y = 500 } });
}

pub fn event(ctx: jok.Context, e: jok.Event) !void {
    _ = ctx;
    _ = e;
}

pub fn update(ctx: jok.Context) !void {
    const kbd = jok.io.getKeyboardState();
    if (kbd.isPressed(.up)) e1.origin = e1.origin.add(j2d.Vector.new(0, -10));
    if (kbd.isPressed(.down)) e1.origin = e1.origin.add(j2d.Vector.new(0, 10));
    if (kbd.isPressed(.left)) e1.origin = e1.origin.add(j2d.Vector.new(-10, 0));
    if (kbd.isPressed(.right)) e1.origin = e1.origin.add(j2d.Vector.new(10, 0));

    ps.update(ctx.deltaSeconds());
}

pub fn draw(ctx: jok.Context) !void {
    try ctx.renderer().clear(.black);
    ctx.displayStats(.{});

    var b = try batchpool.new(.{ .blend_mode = .additive });
    defer b.submit();
    try b.effect(e1, .{});
    if (ps.get("fire2")) |e| try b.effect(e, .{});
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
