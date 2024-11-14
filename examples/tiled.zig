const std = @import("std");
const jok = @import("jok");
const physfs = jok.physfs;
const tiled = jok.utils.tiled;

pub fn init(ctx: jok.Context) !void {
    // your init code

    try physfs.mount("assets", "", true);

    const loaded = try tiled.loadTMX(ctx, "tiled/sample_urban.tmx");
    defer loaded.deinit();
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
    // your drawing code
    _ = ctx;
}

pub fn quit(ctx: jok.Context) void {
    // your deinit code
    _ = ctx;
}
