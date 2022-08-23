const std = @import("std");
const assert = std.debug.assert;
const math = std.math;
const builtin = @import("builtin");
const sdl = @import("sdl");
const jok = @import("jok");
const imgui = jok.deps.imgui;
const zmath = jok.zmath;
const gfx = jok.gfx.@"3d";
const primitive = gfx.primitive;
const Camera = gfx.Camera;

pub const jok_window_resizable = true;

const PrimitiveType = enum(c_int) {
    cube,
    sphere,
};

var primtype: PrimitiveType = .cube;
var wireframe: bool = false;
var color: [4]f32 = .{ 1.0, 1.0, 1.0, 0.8 };
var scale: [3]f32 = .{ 1, 1, 1 };
var rotate: [3]f32 = .{ 0, 0, 0 };
var translate: [3]f32 = .{ 0, 0, 0 };
var camera: Camera = undefined;

pub fn init(ctx: *jok.Context) anyerror!void {
    std.log.info("game init", .{});

    camera = Camera.fromPositionAndTarget(
        .{
            .perspective = .{
                .fov = jok.gfx.utils.degreeToRadian(70),
                .aspect_ratio = ctx.getAspectRatio(),
                .near = 0.1,
                .far = 100,
            },
        },
        [_]f32{ 0, 10, -10 },
        [_]f32{ 0, 0, 0 },
        null,
    );

    try imgui.init(ctx);
    try primitive.init(ctx);
    try ctx.renderer.setColorRGB(77, 77, 77);
    try ctx.renderer.setDrawBlendMode(.blend);
}

pub fn loop(ctx: *jok.Context) anyerror!void {
    // camera movement
    const distance = ctx.delta_tick * 2;
    if (ctx.isKeyPressed(.w)) {
        camera.move(.forward, distance);
    }
    if (ctx.isKeyPressed(.s)) {
        camera.move(.backward, distance);
    }
    if (ctx.isKeyPressed(.a)) {
        camera.move(.left, distance);
    }
    if (ctx.isKeyPressed(.d)) {
        camera.move(.right, distance);
    }
    if (ctx.isKeyPressed(.left)) {
        camera.rotate(0, -std.math.pi / 180.0);
    }
    if (ctx.isKeyPressed(.right)) {
        camera.rotate(0, std.math.pi / 180.0);
    }
    if (ctx.isKeyPressed(.up)) {
        camera.rotate(std.math.pi / 180.0, 0);
    }
    if (ctx.isKeyPressed(.down)) {
        camera.rotate(-std.math.pi / 180.0, 0);
    }

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
    if (imgui.begin("Control Panel", null, null)) {
        var selection: *c_int = @ptrCast(*c_int, &primtype);
        _ = imgui.radioButton_IntPtr("cube", selection, 0);
        _ = imgui.radioButton_IntPtr("sphere", selection, 1);
        imgui.separator();
        _ = imgui.checkbox("wireframe", &wireframe);
        _ = imgui.colorEdit4("color", &color, null);
        _ = imgui.dragFloat3("scale", &scale, .{ .v_max = 10, .v_speed = 0.1 });
        _ = imgui.dragFloat3("rotate", &rotate, .{ .v_max = 10, .v_speed = 0.1 });
        _ = imgui.dragFloat3("translate", &translate, .{ .v_max = 10, .v_speed = 0.1 });
    }
    imgui.end();
    imgui.endFrame();

    const common_draw_opt = primitive.CommonDrawOption{
        .color = .{
            .r = @floatToInt(u8, color[0] * 255),
            .g = @floatToInt(u8, color[1] * 255),
            .b = @floatToInt(u8, color[2] * 255),
            .a = @floatToInt(u8, color[3] * 255),
        },
    };
    const model = zmath.mul(
        zmath.mul(
            zmath.mul(
                zmath.mul(
                    zmath.scaling(scale[0], scale[1], scale[2]),
                    zmath.rotationX(rotate[0]),
                ),
                zmath.rotationY(rotate[1]),
            ),
            zmath.rotationZ(rotate[2]),
        ),
        zmath.translation(translate[0], translate[1], translate[2]),
    );
    primitive.clear();
    switch (primtype) {
        .cube => {
            try primitive.drawCube(camera, model, common_draw_opt);
        },
        .sphere => {
            try primitive.drawSubdividedSphere(camera, model, .{ .common = common_draw_opt });
        },
    }
    try primitive.flush(.{ .wireframe = wireframe });
}

pub fn quit(ctx: *jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});

    imgui.deinit();
    primitive.deinit();
}
