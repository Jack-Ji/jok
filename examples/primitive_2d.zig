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
    triangle,
    circle,
    ngon,
    polyline,
    polygon,
    bezier_cubic,
    bezier_quad,
    custom_path,
};

var primtype: PrimitiveType = .rectangle;
var antialiased: bool = true;
var filling: bool = false;
var color: [4]f32 = .{ 1.0, 1.0, 1.0, 0.5 };
var thickness: f32 = 0;
var scale: [2]f32 = .{ 1, 1 };
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
        imgui.sameLine(.{});
        _ = imgui.radioButtonStatePtr("triangle", .{ .v = selection, .v_button = 3 });
        imgui.sameLine(.{});
        _ = imgui.radioButtonStatePtr("circle", .{ .v = selection, .v_button = 4 });
        _ = imgui.radioButtonStatePtr("ngon", .{ .v = selection, .v_button = 5 });
        imgui.sameLine(.{});
        _ = imgui.radioButtonStatePtr("polyline", .{ .v = selection, .v_button = 6 });
        imgui.sameLine(.{});
        _ = imgui.radioButtonStatePtr("polygon", .{ .v = selection, .v_button = 7 });
        imgui.sameLine(.{});
        _ = imgui.radioButtonStatePtr("bezier_cubic", .{ .v = selection, .v_button = 8 });
        imgui.sameLine(.{});
        _ = imgui.radioButtonStatePtr("bezier_quad", .{ .v = selection, .v_button = 9 });
        _ = imgui.radioButtonStatePtr("custom_path", .{ .v = selection, .v_button = 10 });
        imgui.separator();
        _ = imgui.checkbox("antialiased", .{ .v = &antialiased });
        imgui.sameLine(.{});
        _ = imgui.checkbox("filling", .{ .v = &filling });
        imgui.separator();
        _ = imgui.colorEdit4("color", .{ .col = &color });
        _ = imgui.dragFloat("thickness", .{ .v = &thickness, .max = 100 });
        _ = imgui.dragFloat("rounding", .{ .v = &rounding, .max = 50 });
        _ = imgui.dragFloat2("scale", .{ .v = &scale, .speed = 0.1 });
        _ = imgui.dragFloat2("anchor", .{ .v = &anchor });
        _ = imgui.dragFloat("rotate (deg)", .{ .v = &rotate_angle });
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
        .scale = .{ .x = scale[0], .y = scale[1] },
        .anchor = .{ .x = anchor[0], .y = anchor[1] },
        .rotate_degree = rotate_angle,
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
        .triangle => {
            if (filling) {
                primitive.addTriangleFilled(
                    .{ .x = 0, .y = -100 },
                    .{ .x = -100, .y = 100 },
                    .{ .x = 100, .y = 100 },
                    rgba,
                    .{
                        .trs = trs,
                    },
                );
            } else {
                primitive.addTriangle(
                    .{ .x = 0, .y = -100 },
                    .{ .x = -100, .y = 100 },
                    .{ .x = 100, .y = 100 },
                    rgba,
                    .{
                        .trs = trs,
                        .thickness = thickness,
                    },
                );
            }
        },
        .circle => {
            if (filling) {
                primitive.addCircleFilled(
                    .{ .x = 0, .y = 0 },
                    100,
                    rgba,
                    .{
                        .trs = trs,
                    },
                );
            } else {
                primitive.addCircle(
                    .{ .x = 0, .y = 0 },
                    100,
                    rgba,
                    .{
                        .trs = trs,
                        .thickness = thickness,
                    },
                );
            }
        },
        .ngon => {
            if (filling) {
                primitive.addNgonFilled(
                    .{ .x = 0, .y = 0 },
                    100,
                    rgba,
                    6,
                    .{
                        .trs = trs,
                    },
                );
            } else {
                primitive.addNgon(
                    .{ .x = 0, .y = 0 },
                    100,
                    rgba,
                    6,
                    .{
                        .trs = trs,
                        .thickness = thickness,
                    },
                );
            }
        },
        .polyline => {
            primitive.addPolyline(
                &[_]sdl.PointF{
                    .{ .x = -100, .y = -100 },
                    .{ .x = -50, .y = -150 },
                    .{ .x = 50, .y = -120 },
                    .{ .x = 100, .y = 20 },
                    .{ .x = 50, .y = 80 },
                    .{ .x = 0, .y = 100 },
                    .{ .x = -100, .y = 130 },
                },
                rgba,
                .{
                    .trs = trs,
                    .thickness = thickness,
                },
            );
        },
        .polygon => {
            if (filling) {
                primitive.addConvexPolyFilled(
                    &[_]sdl.PointF{
                        .{ .x = -100, .y = -100 },
                        .{ .x = -50, .y = -150 },
                        .{ .x = 50, .y = -120 },
                        .{ .x = 100, .y = 20 },
                        .{ .x = 50, .y = 80 },
                        .{ .x = 0, .y = 100 },
                        .{ .x = -100, .y = 130 },
                    },
                    rgba,
                    .{
                        .trs = trs,
                    },
                );
            } else {
                primitive.addPolyline(
                    &[_]sdl.PointF{
                        .{ .x = -100, .y = -100 },
                        .{ .x = -50, .y = -150 },
                        .{ .x = 50, .y = -120 },
                        .{ .x = 100, .y = 20 },
                        .{ .x = 50, .y = 80 },
                        .{ .x = 0, .y = 100 },
                        .{ .x = -100, .y = 130 },
                    },
                    rgba,
                    .{
                        .trs = trs,
                        .thickness = thickness,
                        .closed = true,
                    },
                );
            }
        },
        .bezier_cubic => {
            primitive.addBezierCubic(
                .{ .x = -100, .y = 0 },
                .{ .x = -50, .y = -150 },
                .{ .x = 100, .y = 120 },
                .{ .x = 50, .y = 200 },
                rgba,
                .{
                    .trs = trs,
                    .thickness = thickness,
                },
            );
        },
        .bezier_quad => {
            primitive.addBezierQuadratic(
                .{ .x = -100, .y = 0 },
                .{ .x = -50, .y = -150 },
                .{ .x = 50, .y = 200 },
                rgba,
                .{
                    .trs = trs,
                    .thickness = thickness,
                },
            );
        },
        .custom_path => {
            primitive.path.begin(.{ .trs = trs });
            primitive.path.lineTo(.{ .x = -50, .y = 0 });
            primitive.path.lineTo(.{ .x = -40, .y = -30 });
            primitive.path.lineTo(.{ .x = 40, .y = -30 });
            primitive.path.lineTo(.{ .x = 60, .y = 0 });
            if (filling) {
                primitive.path.fill(rgba);
            } else {
                primitive.path.stroke(rgba, .{
                    .thickness = thickness,
                    .closed = true,
                });
            }

            primitive.path.begin(.{ .trs = trs });
            primitive.path.lineTo(.{ .x = -80, .y = 0 });
            primitive.path.lineTo(.{ .x = 90, .y = 0 });
            primitive.path.lineTo(.{ .x = 100, .y = 20 });
            primitive.path.lineTo(.{ .x = -80, .y = 20 });
            if (filling) {
                primitive.path.fill(rgba);
            } else {
                primitive.path.stroke(rgba, .{
                    .thickness = thickness,
                    .closed = true,
                });
            }

            primitive.path.begin(.{ .trs = trs });
            primitive.path.arcTo(.{ .x = -50, .y = 35 }, 15, 0, 360, .{});
            if (filling) {
                primitive.path.fill(rgba);
            } else {
                primitive.path.stroke(rgba, .{
                    .thickness = thickness,
                    .closed = true,
                });
            }

            primitive.path.begin(.{ .trs = trs });
            primitive.path.arcTo(.{ .x = 70, .y = 35 }, 15, 0, 360, .{});
            if (filling) {
                primitive.path.fill(rgba);
            } else {
                primitive.path.stroke(rgba, .{
                    .thickness = thickness,
                    .closed = true,
                });
            }
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
