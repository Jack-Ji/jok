const std = @import("std");
const sdl = @import("sdl");
const jok = @import("jok");

var tex: sdl.Texture = undefined;

pub fn init(ctx: *jok.Context) anyerror!void {
    _ = ctx;
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
