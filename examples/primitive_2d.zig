const std = @import("std");
const assert = std.debug.assert;
const builtin = @import("builtin");
const sdl = @import("sdl");
const jok = @import("jok");
const imgui = jok.deps.imgui;
const gfx = jok.gfx.@"2d";
const primitive = gfx.primitive;

pub const jok_window_resizable = true;

const PrimitiveType = enum(c_int) {
    etriangle,
    square,
    circle,
    line,
};

var primtype: PrimitiveType = .etriangle;
var color: [4]f32 = .{ 1.0, 1.0, 1.0, 0.5 };
var size: f32 = 15;
var rotate_angle: f32 = 0;
var rotate_anchor: [2]f32 = .{ 500, 500 };

pub fn init(ctx: *jok.Context) anyerror!void {
    std.log.info("game init", .{});

    try imgui.init(ctx);
    try ctx.renderer.setColorRGB(77, 77, 77);
    try ctx.renderer.setDrawBlendMode(.blend);
}

pub fn loop(ctx: *jok.Context) anyerror!void {
    var clicked = false;
    while (ctx.pollEvent()) |e| {
        _ = imgui.processEvent(e);

        switch (e) {
            .keyboard_event => |key| {
                if (key.trigger_type == .up) {
                    switch (key.scan_code) {
                        .escape => ctx.kill(),
                        else => {},
                    }
                }
            },
            .mouse_event => |me| {
                if (me.data != .button or
                    me.data.button.btn != .left) continue;
                if (me.data.button.clicked) clicked = true;
            },
            .quit_event => ctx.kill(),
            else => {},
        }
    }

    try ctx.renderer.clear();
    imgui.beginFrame();
    defer imgui.endFrame();

    if (imgui.begin("Control Panel", null, null)) {
        var selection: *c_int = @ptrCast(*c_int, &primtype);
        _ = imgui.radioButton_IntPtr("etriangle", selection, 0);
        _ = imgui.radioButton_IntPtr("square", selection, 1);
        _ = imgui.radioButton_IntPtr("circle", selection, 2);
        _ = imgui.radioButton_IntPtr("line", selection, 3);
        imgui.separator();
        _ = imgui.colorEdit4("color", &color, null);
        _ = imgui.dragFloat("size", &size, .{});
        _ = imgui.dragFloat("rotate_angle", &rotate_angle, .{});
        _ = imgui.dragFloat2("rotate_anchor", &rotate_anchor, .{});
    }
    imgui.end();

    var ms = ctx.getMouseState();
    const draw_pos = sdl.PointF{ .x = @intToFloat(f32, ms.x), .y = @intToFloat(f32, ms.y) };
    const anchor_pos = sdl.PointF{ .x = rotate_anchor[0], .y = rotate_anchor[1] };
    const common_draw_opt = primitive.CommonDrawOption{
        .rotate_degree = rotate_angle,
        .anchor_pos = anchor_pos,
        .color = .{
            .r = @floatToInt(u8, color[0] * 255),
            .g = @floatToInt(u8, color[1] * 255),
            .b = @floatToInt(u8, color[2] * 255),
            .a = @floatToInt(u8, color[3] * 255),
        },
    };
    switch (primtype) {
        .etriangle => {
            try gfx.primitive.drawEquilateralTriangle(draw_pos, size, common_draw_opt);
        },
        .square => {
            try gfx.primitive.drawSquare(draw_pos, size, common_draw_opt);
        },
        .circle => {
            try gfx.primitive.drawCircle(draw_pos, size, .{ .common_opt = common_draw_opt });
        },
        .line => {
            try gfx.primitive.drawLine(
                .{ .x = draw_pos.x - size, .y = draw_pos.y - size },
                .{ .x = draw_pos.x + size, .y = draw_pos.y + size },
                .{ .common_opt = common_draw_opt, .thickness = size / 10 },
            );
        },
    }
    try gfx.primitive.drawCircle(
        .{ .x = rotate_anchor[0], .y = rotate_anchor[1] },
        3,
        .{ .common_opt = .{ .color = sdl.Color.cyan } },
    );
}

pub fn quit(ctx: *jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});

    imgui.deinit();
}
