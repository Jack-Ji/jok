const std = @import("std");
const assert = std.debug.assert;
const math = std.math;
const builtin = @import("builtin");
const sdl = @import("sdl");
const jok = @import("jok");
const imgui = jok.deps.imgui;
const primitive = jok.j2d.primitive;

pub const jok_window_resizable = true;

const PrimitiveType = enum(i32) {
    etriangle,
    square,
    circle,
    arc,
    line,
    polyline,
};

var primtype: PrimitiveType = .etriangle;
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
        _ = imgui.radioButtonStatePtr("etriangle", .{ .v = selection, .v_button = 0 });
        _ = imgui.radioButtonStatePtr("square", .{ .v = selection, .v_button = 1 });
        _ = imgui.radioButtonStatePtr("circle", .{ .v = selection, .v_button = 2 });
        _ = imgui.radioButtonStatePtr("arc", .{ .v = selection, .v_button = 3 });
        _ = imgui.radioButtonStatePtr("line", .{ .v = selection, .v_button = 4 });
        _ = imgui.radioButtonStatePtr("polyline", .{ .v = selection, .v_button = 5 });
        imgui.separator();
        _ = imgui.colorEdit4("color", .{ .col = &color });
        _ = imgui.dragFloat("size", .{ .v = &size, .max = 1000 });
        _ = imgui.dragFloat("thickness", .{ .v = &thickness, .max = 100 });
        _ = imgui.dragFloat("rotate_angle", .{ .v = &rotate_angle });
        _ = imgui.dragFloat2("rotate_anchor", .{ .v = &rotate_anchor });
    }
    imgui.end();

    var ms = ctx.getMouseState();
    const draw_pos = sdl.PointF{ .x = @intToFloat(f32, ms.x), .y = @intToFloat(f32, ms.y) };
    const anchor_pos = sdl.PointF{ .x = rotate_anchor[0], .y = rotate_anchor[1] };
    const common_draw_opt = primitive.CommonDrawOption{
        .thickness = thickness,
        .rotate_degree = rotate_angle,
        .anchor_pos = anchor_pos,
        .color = .{
            .r = @floatToInt(u8, color[0] * 255),
            .g = @floatToInt(u8, color[1] * 255),
            .b = @floatToInt(u8, color[2] * 255),
            .a = @floatToInt(u8, color[3] * 255),
        },
    };
    primitive.clear();
    switch (primtype) {
        .etriangle => {
            try primitive.addEquilateralTriangle(draw_pos, size, common_draw_opt);
        },
        .square => {
            try primitive.addSquare(draw_pos, size, .{ .common = common_draw_opt, .round = size / 2 });
        },
        .circle => {
            try primitive.addCircle(draw_pos, size, .{ .common = common_draw_opt });
        },
        .arc => {
            try primitive.addArc(draw_pos, size, math.pi / 4.0, math.pi, .{ .common = common_draw_opt });
        },
        .line => {
            try primitive.addLine(
                .{ .x = draw_pos.x - size, .y = draw_pos.y - size },
                .{ .x = draw_pos.x + size, .y = draw_pos.y + size },
                common_draw_opt,
            );
        },
        .polyline => {
            try primitive.addPolyline(
                &[_]sdl.PointF{
                    .{ .x = draw_pos.x, .y = draw_pos.y },
                    .{ .x = draw_pos.x + 50, .y = draw_pos.y + 50 },
                    .{ .x = draw_pos.x + 60, .y = draw_pos.y + 80 },
                    .{ .x = draw_pos.x + 20, .y = draw_pos.y + 100 },
                    .{ .x = draw_pos.x + 10, .y = draw_pos.y + 150 },
                    .{ .x = draw_pos.x - 80, .y = draw_pos.y + 200 },
                    .{ .x = draw_pos.x - 50, .y = draw_pos.y + 50 },
                    .{ .x = draw_pos.x - 60, .y = draw_pos.y + 10 },
                    .{ .x = draw_pos.x, .y = draw_pos.y },
                    .{ .x = draw_pos.x + 50, .y = draw_pos.y + 50 },
                },
                common_draw_opt,
            );
        },
    }
    try primitive.addCircle(
        .{ .x = rotate_anchor[0], .y = rotate_anchor[1] },
        3,
        .{ .common = .{ .color = sdl.Color.cyan } },
    );
    try primitive.draw(ctx.renderer, .{});
}

pub fn quit(ctx: *jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});
}
