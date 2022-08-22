const std = @import("std");
const assert = std.debug.assert;
const math = std.math;
const builtin = @import("builtin");
const sdl = @import("sdl");
const jok = @import("jok");
const imgui = jok.deps.imgui;
const gfx = jok.gfx.@"3d";
const primitive = gfx.primitive;

pub const jok_window_resizable = true;

pub fn init(ctx: *jok.Context) anyerror!void {
    std.log.info("game init", .{});

    try imgui.init(ctx);
    try primitive.init(ctx);
    try ctx.renderer.setColorRGB(77, 77, 77);
    try ctx.renderer.setDrawBlendMode(.blend);
}

pub fn loop(ctx: *jok.Context) anyerror!void {
    while (ctx.pollEvent()) |e| {
        _ = imgui.processEvent(e);

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

    try ctx.renderer.clear();

    imgui.beginFrame();
    if (imgui.begin("Control Panel", null, null)) {}
    imgui.end();
    imgui.endFrame();

    try primitive.drawCube(2, .{});
    try primitive.flush();
}

pub fn quit(ctx: *jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});

    imgui.deinit();
    primitive.deinit();
}
