const std = @import("std");
const sdl = @import("sdl");
const jok = @import("jok");

var tex: sdl.Texture = undefined;

pub fn init(ctx: *jok.Context) anyerror!void {
    std.log.info("game init", .{});

    tex = try jok.utils.gfx.createTextureFromFile(
        ctx.renderer,
        "assets/images/jok.png",
        .static,
        false,
    );
    try tex.setBlendMode(.blend);
    try ctx.renderer.setColorRGB(77, 77, 77);
}

pub fn event(ctx: *jok.Context, e: sdl.Event) anyerror!void {
    _ = ctx;
    _ = e;
}

pub fn update(ctx: *jok.Context) anyerror!void {
    _ = ctx;
}

pub fn draw(ctx: *jok.Context) anyerror!void {
    try ctx.renderer.copy(
        tex,
        null,
        null,
    );
}

pub fn quit(ctx: *jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});
}
