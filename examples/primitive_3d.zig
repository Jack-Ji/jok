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
const font = jok.gfx.@"2d".font;
const Camera = gfx.Camera;

pub const jok_window_resizable = true;
pub const jok_window_width = 1600;
pub const jok_window_height = 900;

const PrimitiveType = enum(c_int) {
    cube,
    subdivided_sphere,
    parametric_sphere,
    cone,
    cylinder,
    disk,
    torus,
    icosahedron,
    dodecahedron,
    octahedron,
    tetrahedron,
};

var primtype: PrimitiveType = .cube;
var wireframe: bool = false;
var color: [4]f32 = .{ 1.0, 1.0, 1.0, 1.0 };
var cull_faces = true;
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
        [_]f32{ 3, 3, 3 },
        [_]f32{ 0, 0, 0 },
        null,
    );

    try imgui.init(ctx);
    try primitive.init(ctx);
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
        _ = imgui.radioButton_IntPtr("subdivided_sphere", selection, 1);
        _ = imgui.radioButton_IntPtr("parametric_sphere", selection, 2);
        _ = imgui.radioButton_IntPtr("cone", selection, 3);
        _ = imgui.radioButton_IntPtr("cylinder", selection, 4);
        _ = imgui.radioButton_IntPtr("disk", selection, 5);
        _ = imgui.radioButton_IntPtr("torus", selection, 6);
        _ = imgui.radioButton_IntPtr("icosahedron", selection, 7);
        _ = imgui.radioButton_IntPtr("dodecahedron", selection, 8);
        _ = imgui.radioButton_IntPtr("octahedron", selection, 9);
        _ = imgui.radioButton_IntPtr("tetrahedron", selection, 10);
        imgui.separator();
        _ = imgui.checkbox("wireframe", &wireframe);
        _ = imgui.checkbox("cull faces", &cull_faces);
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
        .cull_faces = cull_faces,
        .lighting = .{},
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
    try primitive.drawPlane(
        zmath.mul(
            zmath.mul(
                zmath.rotationX(-math.pi * 0.5),
                zmath.translation(-0.5, -1.1, 0.5),
            ),
            zmath.scaling(10, 1, 10),
        ),
        camera,
        .{
            .common = .{
                .color = sdl.Color.rgba(100, 100, 100, 200),
                .lighting = common_draw_opt.lighting,
            },
        },
    );
    switch (primtype) {
        .cube => {
            try primitive.drawCube(model, camera, common_draw_opt);
        },
        .subdivided_sphere => {
            try primitive.drawSubdividedSphere(model, camera, .{ .common = common_draw_opt });
        },
        .parametric_sphere => {
            try primitive.drawParametricSphere(model, camera, .{ .common = common_draw_opt });
        },
        .cone => {
            try primitive.drawCone(model, camera, .{ .common = common_draw_opt });
        },
        .cylinder => {
            try primitive.drawCylinder(model, camera, .{ .common = common_draw_opt });
        },
        .disk => {
            try primitive.drawDisk(model, camera, .{ .common = common_draw_opt });
        },
        .torus => {
            try primitive.drawTorus(model, camera, .{ .common = common_draw_opt });
        },
        .icosahedron => {
            try primitive.drawIcosahedron(model, camera, common_draw_opt);
        },
        .dodecahedron => {
            try primitive.drawDodecahedron(model, camera, common_draw_opt);
        },
        .octahedron => {
            try primitive.drawOctahedron(model, camera, common_draw_opt);
        },
        .tetrahedron => {
            try primitive.drawTetrahedron(model, camera, common_draw_opt);
        },
    }
    try primitive.flush(.{ .wireframe = wireframe });

    _ = try font.debugDraw(
        ctx.renderer,
        .{ .pos = .{ .x = 200, .y = 10 } },
        "Press WSAD and up/down/left/right to move camera around the view",
        .{},
    );
    _ = try font.debugDraw(
        ctx.renderer,
        .{ .pos = .{ .x = 200, .y = 28 } },
        "Camera: pos({d:.3},{d:.3},{d:.3}) dir({d:.3},{d:.3},{d:.3})",
        .{
            // zig fmt: off
            camera.position[0],camera.position[1],camera.position[2],
            camera.dir[0],camera.dir[1],camera.dir[2],
        },
    );
}

pub fn quit(ctx: *jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});

    imgui.deinit();
    primitive.deinit();
}
