const std = @import("std");
const sdl = @import("sdl");
const jok = @import("jok");

var tex: sdl.Texture = undefined;

pub fn init(ctx: *jok.Context) anyerror!void {
    std.log.info("game init", .{});

    tex = try jok.gfx.utils.createTextureFromFile(
        ctx.renderer,
        "assets/images/jok.png",
        .static,
        false,
    );
    try tex.setBlendMode(.blend);
}

pub fn loop(ctx: *jok.Context) anyerror!void {
    while (ctx.pollEvent()) |e| {
        switch (e) {
            .key_up => |key| {
                switch (key.scancode) {
                    .escape => ctx.kill(),
                    else => {},
                }
            },
            .quit => ctx.kill(),
            else => {},
        }
    }

    try ctx.renderer.setColorRGB(77, 77, 77);
    try ctx.renderer.clear();
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
