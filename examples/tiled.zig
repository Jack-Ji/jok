const std = @import("std");
const builtin = @import("builtin");
const jok = @import("jok");
const physfs = jok.physfs;
const j2d = jok.j2d;
const tiled = jok.utils.tiled;

var batchpool: j2d.BatchPool(64, false) = undefined;
var map: *tiled.TiledMap = undefined;

pub fn init(ctx: jok.Context) !void {
    // your init code

    if (!builtin.cpu.arch.isWasm()) {
        try physfs.mount("assets", "", true);
    }

    batchpool = try @TypeOf(batchpool).init(ctx);
    map = try tiled.loadTMX(ctx, "tiled/tmx/sample_urban.tmx");
}

pub fn event(ctx: jok.Context, e: jok.Event) !void {
    // your event processing code
    _ = ctx;
    _ = e;
}

pub fn update(ctx: jok.Context) !void {
    // your game state updating code
    _ = ctx;
}

pub fn draw(ctx: jok.Context) !void {
    try ctx.renderer().clear(map.bgcolor);

    const mouse_pos = jok.io.getMouseState().pos;

    var b = try batchpool.new(.{});
    defer b.submit();
    try map.render(b);
    for (map.layers) |l| {
        if (l != .tile_layer) continue;
        if (l.tile_layer.getTileByPos(mouse_pos)) |t| {
            try b.rectFilled(
                t.rect,
                .rgba(0, 255, 255, 200),
                .{},
            );
            break;
        }
    }
}

pub fn quit(ctx: jok.Context) void {
    // your deinit code
    _ = ctx;
    map.destroy();
    batchpool.deinit();
}
