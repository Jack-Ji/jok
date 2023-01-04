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
    quad,
    line,
};

var primtype: PrimitiveType = .rectangle;
var antialiased: bool = true;
var filling: bool = false;
var color: [4]f32 = .{ 1.0, 1.0, 1.0, 0.5 };
var thickness: f32 = 0;
var anchor: [2]f32 = .{ 0, 0 };
var rotate_angle: f32 = 0;
var rounding: f32 = 0;
var offset: [2]f32 = undefined;

pub fn init(ctx: *jok.Context) !void {
    std.log.info("game init", .{});

    const fb = ctx.getFramebufferSize();
    offset[0] = @intToFloat(f32, fb.w) / 2;
    offset[1] = @intToFloat(f32, fb.h) / 2;

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
        _ = imgui.radioButtonStatePtr("rectangle", .{ .v = selection, .v_button = 0 });
        imgui.sameLine(.{});
        _ = imgui.radioButtonStatePtr("quad", .{ .v = selection, .v_button = 1 });
        imgui.sameLine(.{});
        _ = imgui.radioButtonStatePtr("line", .{ .v = selection, .v_button = 2 });
        imgui.separator();
        _ = imgui.checkbox("antialiased", .{ .v = &antialiased });
        imgui.sameLine(.{});
        _ = imgui.checkbox("filling", .{ .v = &filling });
        imgui.separator();
        _ = imgui.colorEdit4("color", .{ .col = &color });
        _ = imgui.dragFloat("thickness", .{ .v = &thickness, .max = 100 });
        _ = imgui.dragFloat("rounding", .{ .v = &rounding, .max = 50 });
        _ = imgui.dragFloat2("anchor", .{ .v = &anchor });
        _ = imgui.dragFloat("rotate", .{ .v = &rotate_angle });
        _ = imgui.dragFloat2("offset", .{ .v = &offset });
    }
    imgui.end();

    const rgba = sdl.Color.rgba(
        @floatToInt(u8, 255 * color[0]),
        @floatToInt(u8, 255 * color[1]),
        @floatToInt(u8, 255 * color[2]),
        @floatToInt(u8, 255 * color[3]),
    );
    const trs = primitive.TransformOption{
        .anchor = .{ .x = anchor[0], .y = anchor[1] },
        .rotate = rotate_angle,
        .offset = .{ .x = offset[0], .y = offset[1] },
    };

    primitive.clear(.{ .antialiased = antialiased });
    switch (primtype) {
        .rectangle => {
            if (filling) {
                primitive.addRectFilled(
                    .{ .x = -100, .y = -100, .width = 200, .height = 200 },
                    rgba,
                    .{
                        .trs = trs,
                        .rounding = rounding,
                    },
                );
            } else {
                primitive.addRect(
                    .{ .x = -100, .y = -100, .width = 200, .height = 200 },
                    rgba,
                    .{
                        .trs = trs,
                        .thickness = thickness,
                        .rounding = rounding,
                    },
                );
            }
        },
        .quad => {
            if (filling) {
                primitive.addQuadFilled(
                    .{ .x = -100, .y = -100 },
                    .{ .x = 100, .y = -100 },
                    .{ .x = 100, .y = 100 },
                    .{ .x = -100, .y = 100 },
                    rgba,
                    .{
                        .trs = trs,
                    },
                );
            } else {
                primitive.addQuad(
                    .{ .x = -100, .y = -100 },
                    .{ .x = 100, .y = -100 },
                    .{ .x = 100, .y = 100 },
                    .{ .x = -100, .y = 100 },
                    rgba,
                    .{
                        .trs = trs,
                        .thickness = thickness,
                    },
                );
            }
        },
        .line => {
            primitive.addLine(
                .{ .x = -100, .y = -100 },
                .{ .x = 100, .y = 100 },
                rgba,
                .{
                    .trs = trs,
                    .thickness = thickness,
                },
            );
        },
    }
    primitive.addLine(
        .{ .x = -10, .y = -10 },
        .{ .x = 10, .y = 10 },
        sdl.Color.red,
        .{
            .trs = .{
                .offset = .{
                    .x = anchor[0] + offset[0],
                    .y = anchor[1] + offset[1],
                },
            },
        },
    );
    primitive.addLine(
        .{ .x = -10, .y = 10 },
        .{ .x = 10, .y = -10 },
        sdl.Color.red,
        .{
            .trs = .{
                .offset = .{
                    .x = anchor[0] + offset[0],
                    .y = anchor[1] + offset[1],
                },
            },
        },
    );
    try primitive.draw();
}

pub fn quit(ctx: *jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});
}
