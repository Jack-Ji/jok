const std = @import("std");
const assert = std.debug.assert;
const math = std.math;
const builtin = @import("builtin");
const sdl = @import("sdl");
const jok = @import("jok");
const imgui = jok.imgui;
const primitive = jok.j2d.primitive;

pub const jok_window_resizable = true;

const PrimitiveType = enum(i32) {
    rectangle,
};

var primtype: PrimitiveType = .rectangle;
var color: [4]f32 = .{ 1.0, 1.0, 1.0, 0.5 };
var size: f32 = 15;
var thickness: f32 = 0;
var rotate_angle: f32 = 0;
var rotate_anchor: [2]f32 = .{ 500, 500 };

pub fn init(ctx: *jok.Context) !void {
    std.log.info("game init", .{});

    try ctx.renderer.setColorRGB(77, 77, 77);
    try ctx.renderer.setDrawBlendMode(.blend);
}

pub fn event(ctx: *jok.Context, e: sdl.Event) !void {
    _ = ctx;
    _ = e;
}

pub fn update(ctx: *jok.Context) !void {
    _ = ctx;
}

pub fn draw(ctx: *jok.Context) !void {
    imgui.sdl.newFrame(ctx.*);
    defer imgui.sdl.draw();

    if (imgui.begin("Control Panel", .{})) {
        var selection: *i32 = @ptrCast(*i32, &primtype);
        _ = imgui.radioButtonStatePtr("square", .{ .v = selection, .v_button = 0 });
        imgui.separator();
        _ = imgui.colorEdit4("color", .{ .col = &color });
        _ = imgui.dragFloat("size", .{ .v = &size, .max = 1000 });
        _ = imgui.dragFloat("thickness", .{ .v = &thickness, .max = 100 });
        _ = imgui.dragFloat("rotate", .{ .v = &rotate_angle });
        _ = imgui.dragFloat2("anchor", .{ .v = &rotate_anchor });
    }
    imgui.end();

    primitive.clear();
    switch (primtype) {
        .rectangle => {
            primitive.addRect(
                .{ .x = 100, .y = 100, .width = 50, .height = 50 },
                sdl.Color.rgba(
                    @floatToInt(u8, 255 * color[0]),
                    @floatToInt(u8, 255 * color[1]),
                    @floatToInt(u8, 255 * color[2]),
                    @floatToInt(u8, 255 * color[3]),
                ),
                .{
                    .trs = .{
                        .rotate = rotate_angle,
                        .anchor = .{ .x = rotate_anchor[0], .y = rotate_anchor[1] },
                    },
                    .thickness = thickness,
                },
            );
        },
    }
    try primitive.draw();
}

pub fn quit(ctx: *jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});
}
