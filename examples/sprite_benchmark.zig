const std = @import("std");
const builtin = @import("builtin");
const jok = @import("jok");
const j2d = jok.j2d;
const geom = j2d.geom;
const physfs = jok.vendor.physfs;

const Actor = struct {
    sprite: j2d.Sprite,
    pos: geom.Point,
    velocity: geom.Point,
    rot: f32,
    rot_speed: f32,
    tint_color: jok.Color,
};

const names = [_][]const u8{
    "ogre",
    "quicksilver_dragon",
    "rock_troll",
    "rock_troll_monk_ghost",
    "sphinx",
};

var batchpool: j2d.BatchPool(64, false) = undefined;
var sheet: *j2d.SpriteSheet = undefined;
var characters: std.array_list.Managed(Actor) = undefined;
var rand_gen: std.Random.DefaultPrng = undefined;

pub fn init(ctx: jok.Context) !void {
    std.log.info("game init", .{});

    if (!builtin.cpu.arch.isWasm()) {
        try physfs.mount("assets", "/", true);
    }

    batchpool = try @TypeOf(batchpool).init(ctx);

    const csz = ctx.getCanvasSize();

    // create sprite sheet
    sheet = try j2d.SpriteSheet.fromPicturesInDir(
        ctx,
        if (ctx.cfg().jok_enable_physfs) "images" else "assets/images",
        csz.width,
        csz.height,
        .{},
    );
    characters = try .initCapacity(ctx.allocator(), 50000);
    rand_gen = std.Random.DefaultPrng.init(@intCast(std.Io.Clock.awake.now(ctx.io()).toSeconds()));
}

pub fn event(ctx: jok.Context, e: jok.Event) !void {
    _ = ctx;
    _ = e;
}

pub fn update(ctx: jok.Context) !void {
    const mouse = jok.io.getMouseState(ctx);
    if (mouse.buttons.isPressed(.left) and characters.items.len != characters.capacity) {
        var rd = rand_gen.random();
        var i: u32 = 0;
        while (i < 100) : (i += 1) {
            const angle = rd.float(f32) * 2 * std.math.pi;
            const select = rd.intRangeLessThan(u32, 0, names.len);
            try characters.append(.{
                .sprite = sheet.getSpriteByName(names[select]).?,
                .pos = mouse.pos,
                .velocity = .{
                    .x = rd.float(f32) * 300 * @cos(angle),
                    .y = rd.float(f32) * 300 * @sin(angle),
                },
                .rot = 0,
                .rot_speed = rd.float(f32) * 2 * std.math.pi,
                .tint_color = .rgb(
                    rd.uintLessThan(u8, 255),
                    rd.uintLessThan(u8, 255),
                    rd.uintLessThan(u8, 255),
                ),
            });
        }
    }

    const size = ctx.getCanvasSize();
    for (characters.items) |*c| {
        const curpos = c.pos;
        if (curpos.x < 0)
            c.velocity.x = @abs(c.velocity.x);
        if (curpos.x > size.getWidthFloat())
            c.velocity.x = -@abs(c.velocity.x);
        if (curpos.y < 0)
            c.velocity.y = @abs(c.velocity.y);
        if (curpos.y > size.getHeightFloat())
            c.velocity.y = -@abs(c.velocity.y);
        c.pos = c.pos.add(c.velocity.scale(ctx.deltaSeconds()));
        c.rot += c.rot_speed * ctx.deltaSeconds();
    }
}

pub fn draw(ctx: jok.Context) !void {
    try ctx.renderer().clear(.rgb(77, 77, 77));
    ctx.displayStats(.{});

    var b = try batchpool.new(.{});
    defer b.submit();
    for (characters.items) |c| {
        try b.sprite(c.sprite, .{
            .pos = c.pos,
            .anchor_point = .anchor_center,
            .rotate_angle = c.rot,
            .tint_color = c.tint_color,
        });
    }
    try b.text(
        "# of sprites: {d}",
        .{characters.items.len},
        .{
            .atlas = try jok.font.DebugFont.getAtlas(ctx, 16),
        },
    );
}

pub fn quit(ctx: jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});
    sheet.destroy();
    characters.deinit();
    batchpool.deinit();
}
