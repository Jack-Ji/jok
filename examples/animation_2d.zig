const std = @import("std");
const builtin = @import("builtin");
const jok = @import("jok");
const physfs = jok.physfs;
const j2d = jok.j2d;

var batchpool: j2d.BatchPool(64, false) = undefined;
var sheet: *j2d.SpriteSheet = undefined;
var as: *j2d.AnimationSystem = undefined;
const velocity = 100;
var animation: []const u8 = "player_down";
var pos = jok.Point{ .x = 200, .y = 200 };
var flip_h = false;

fn animation_over(name: []const u8) void {
    _ = name;
    as.setStop("player_circle_bg", true) catch unreachable;
}

pub fn init(ctx: jok.Context) !void {
    std.log.info("game init", .{});

    if (!builtin.cpu.arch.isWasm()) {
        try physfs.mount("assets", "", true);
    }

    batchpool = try @TypeOf(batchpool).init(ctx);

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
    try as.sig.connect(animation_over);
    const player = sheet.getSpriteByName("player").?;
    try as.addSimple(
        "player_left_right",
        &.{
            .{ .sp = player.getSubSprite(4 * 16, 0, 16, 16) },
            .{ .sp = player.getSubSprite(5 * 16, 0, 16, 16) },
            .{ .sp = player.getSubSprite(3 * 16, 0, 16, 16) },
        },
        6,
        .{},
    );
    try as.addSimple(
        "player_up",
        &.{
            .{ .sp = player.getSubSprite(7 * 16, 0, 16, 16) },
            .{ .sp = player.getSubSprite(8 * 16, 0, 16, 16) },
            .{ .sp = player.getSubSprite(6 * 16, 0, 16, 16) },
        },
        6,
        .{},
    );
    try as.addSimple(
        "player_down",
        &.{
            .{ .sp = player.getSubSprite(1 * 16, 0, 16, 16) },
            .{ .sp = player.getSubSprite(2 * 16, 0, 16, 16) },
            .{ .sp = player.getSubSprite(0 * 16, 0, 16, 16) },
        },
        6,
        .{},
    );
    var dcmds: [20]j2d.AnimationSystem.Frame.Data = undefined;
    for (0..dcmds.len) |i| {
        dcmds[i] = .{
            .dcmd = .{
                .cmd = .{
                    .circle = .{
                        .p = .origin,
                        .radius = @floatFromInt(@abs(100 - @as(i32, @intCast(i)) * 10)),
                        .color = jok.Color.rgb(@intCast(i * 50 % 255), @intCast(i * 50 % 255), 0).toInternalColor(),
                        .num_segments = 20,
                        .thickness = 6,
                    },
                },
                .depth = 0.5,
            },
        };
    }
    try as.addSimple(
        "player_circle_bg",
        &dcmds,
        10,
        .{ .loop = true },
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
        try as.setStop("player_circle_bg", false);
    }
    as.update(ctx.deltaSeconds());
}

pub fn draw(ctx: jok.Context) !void {
    try ctx.renderer().clear(.rgb(77, 77, 77));

    var b = try batchpool.new(.{});
    defer b.submit();
    try b.sprite(
        sheet.getSpriteByName("player").?,
        .{
            .pos = .{ .x = 0, .y = 50 },
            .tint_color = .rgb(100, 100, 100),
            .scale = .{ .x = 4, .y = 4 },
        },
    );
    if (!try as.isStopped("player_circle_bg")) {
        try b.pushTransform();
        defer b.popTransform();
        b.trs = j2d.AffineTransform.init().translate(pos.toArray());
        try b.pushDrawCommand(((try as.getCurrentFrame("player_circle_bg")).dcmd));
    }
    try b.sprite(
        (try as.getCurrentFrame(animation)).sp,
        .{
            .pos = pos,
            .flip_h = flip_h,
            .scale = .{ .x = 5, .y = 5 },
            .anchor_point = .anchor_center,
        },
    );

    ctx.debugPrint(
        "Press up/down/left/right to move character around",
        .{ .pos = .{ .x = 300, .y = 0 } },
    );
}

pub fn quit(ctx: jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});
    sheet.destroy();
    as.destroy();
    batchpool.deinit();
}
