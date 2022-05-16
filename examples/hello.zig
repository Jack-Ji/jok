const std = @import("std");
const sdl = @import("sdl");
const jok = @import("jok");

var tex: sdl.Texture = undefined;

fn init(ctx: *jok.Context) anyerror!void {
    _ = ctx;
    std.log.info("game init", .{});

    tex = try jok.gfx.utils.createTextureFromFile(
        ctx.renderer,
        "assets/images/jok.png",
        .static,
        false,
    );
}

fn loop(ctx: *jok.Context) anyerror!void {
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

    try ctx.renderer.copy(
        tex,
        null,
        null,
    );
}

fn quit(ctx: *jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});
}

pub fn main() anyerror!void {
    try jok.run(.{
        .initFn = init,
        .loopFn = loop,
        .quitFn = quit,
    });
}
