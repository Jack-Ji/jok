const std = @import("std");
const jok = @import("jok");
const physfs = jok.physfs;
const j2d = jok.j2d;
const tiled = jok.utils.tiled;

var batchpool: j2d.BatchPool(64, false) = undefined;
var map: tiled.TiledMap = undefined;

pub fn init(ctx: jok.Context) !void {
    // your init code

    try physfs.mount("assets", "", true);

    batchpool = try @TypeOf(batchpool).init(ctx);
    map = try tiled.loadTMX(ctx, "tiled/sample_urban.tmx");
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

    var b = try batchpool.new(.{});
    defer b.submit();
    try map.render(b);
}

pub fn quit(ctx: jok.Context) void {
    // your deinit code
    _ = ctx;
    map.deinit();
    batchpool.deinit();
}
