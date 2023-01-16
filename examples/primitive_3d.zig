const std = @import("std");
const assert = std.debug.assert;
const math = std.math;
const builtin = @import("builtin");
const sdl = @import("sdl");
const jok = @import("jok");
const imgui = jok.imgui;
const zmath = jok.zmath;
const font = jok.font;
const primitive = jok.j3d.primitive;
const Camera = jok.j3d.Camera;

pub const jok_window_resizable = true;

const PrimitiveType = enum(i32) {
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
    hemisphere,
    rock,
};

var primtype: PrimitiveType = .cube;
var welding: bool = false;
var wireframe: bool = false;
var color: [4]f32 = .{ 1.0, 1.0, 1.0, 1.0 };
var cull_faces = true;
var scale: [3]f32 = .{ 1, 1, 1 };
var rotate: [3]f32 = .{ 0, 0, 0 };
var translate: [3]f32 = .{ 0, 0, 0 };
var camera: Camera = undefined;

pub fn init(ctx: *jok.Context) !void {
    std.log.info("game init", .{});

    camera = Camera.fromPositionAndTarget(
        .{
            .perspective = .{
                .fov = jok.utils.math.degreeToRadian(70),
                .aspect_ratio = ctx.getAspectRatio(),
                .near = 0.1,
                .far = 100,
            },
        },
        [_]f32{ 3, 3, 3 },
        [_]f32{ 0, 0, 0 },
        null,
    );
}

pub fn event(ctx: *jok.Context, e: sdl.Event) !void {
    _ = ctx;
    _ = e;
}

pub fn update(ctx: *jok.Context) !void {
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
}

pub fn draw(ctx: *jok.Context) !void {
    imgui.sdl.newFrame(ctx.*);
    defer imgui.sdl.draw();

    if (imgui.begin("Control Panel", .{})) {
        var selection: *i32 = @ptrCast(*i32, &primtype);
        _ = imgui.radioButtonStatePtr("cube", .{ .v = selection, .v_button = 0 });
        imgui.sameLine(.{});
        _ = imgui.radioButtonStatePtr("subdivided_sphere", .{ .v = selection, .v_button = 1 });
        imgui.sameLine(.{});
        _ = imgui.radioButtonStatePtr("parametric_sphere", .{ .v = selection, .v_button = 2 });
        imgui.sameLine(.{});
        _ = imgui.radioButtonStatePtr("cone", .{ .v = selection, .v_button = 3 });
        imgui.sameLine(.{});
        _ = imgui.radioButtonStatePtr("cylinder", .{ .v = selection, .v_button = 4 });
        _ = imgui.radioButtonStatePtr("disk", .{ .v = selection, .v_button = 5 });
        imgui.sameLine(.{});
        _ = imgui.radioButtonStatePtr("torus", .{ .v = selection, .v_button = 6 });
        imgui.sameLine(.{});
        _ = imgui.radioButtonStatePtr("icosahedron", .{ .v = selection, .v_button = 7 });
        imgui.sameLine(.{});
        _ = imgui.radioButtonStatePtr("dodecahedron", .{ .v = selection, .v_button = 8 });
        imgui.sameLine(.{});
        _ = imgui.radioButtonStatePtr("octahedron", .{ .v = selection, .v_button = 9 });
        _ = imgui.radioButtonStatePtr("tetrahedron", .{ .v = selection, .v_button = 10 });
        imgui.sameLine(.{});
        _ = imgui.radioButtonStatePtr("hemisphere", .{ .v = selection, .v_button = 11 });
        imgui.sameLine(.{});
        _ = imgui.radioButtonStatePtr("rock", .{ .v = selection, .v_button = 12 });
        imgui.separator();
        _ = imgui.checkbox("welding", .{ .v = &welding });
        imgui.sameLine(.{});
        _ = imgui.checkbox("wireframe", .{ .v = &wireframe });
        imgui.sameLine(.{});
        _ = imgui.checkbox("cull faces", .{ .v = &cull_faces });
        _ = imgui.colorEdit4("color", .{ .col = &color });
        _ = imgui.dragFloat3("scale", .{ .v = &scale, .min = 1, .max = 10, .speed = 0.1 });
        _ = imgui.dragFloat3("rotate", .{ .v = &rotate, .min = 1, .max = 10, .speed = 0.1 });
        _ = imgui.dragFloat3("translate", .{ .v = &translate, .min = 1, .max = 10, .speed = 0.1 });
    }
    imgui.end();

    const common_draw_opt = primitive.CommonDrawOption{
        .color = .{
            .r = @floatToInt(u8, color[0] * 255),
            .g = @floatToInt(u8, color[1] * 255),
            .b = @floatToInt(u8, color[2] * 255),
            .a = @floatToInt(u8, color[3] * 255),
        },
        .cull_faces = cull_faces,
        .lighting = .{},
        .weld_threshold = if (welding) 0.001 else null,
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
    primitive.clear(.{});
    try primitive.addPlane(
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
        .cube => try primitive.addCube(model, camera, common_draw_opt),
        .subdivided_sphere => try primitive.addSubdividedSphere(model, camera, .{ .common = common_draw_opt }),
        .parametric_sphere => try primitive.addParametricSphere(model, camera, .{ .common = common_draw_opt }),
        .cone => try primitive.addCone(model, camera, .{ .common = common_draw_opt }),
        .cylinder => try primitive.addCylinder(model, camera, .{ .common = common_draw_opt }),
        .disk => try primitive.addDisk(model, camera, .{ .common = common_draw_opt }),
        .torus => try primitive.addTorus(model, camera, .{ .common = common_draw_opt }),
        .icosahedron => try primitive.addIcosahedron(model, camera, common_draw_opt),
        .dodecahedron => try primitive.addDodecahedron(model, camera, common_draw_opt),
        .octahedron => try primitive.addOctahedron(model, camera, common_draw_opt),
        .tetrahedron => try primitive.addTetrahedron(model, camera, common_draw_opt),
        .hemisphere => try primitive.addHemisphere(model, camera, .{ .common = common_draw_opt }),
        .rock => try primitive.addRock(model, camera, .{ .common = common_draw_opt }),
    }
    if (wireframe) {
        try primitive.drawWireframe(sdl.Color.green);
    } else {
        try primitive.draw();
    }

    _ = try font.debugDraw(
        ctx.renderer,
        .{
            .pos = camera.getScreenPosition(ctx.renderer, model, [3]f32{ 0, 0, 0 }),
            .color = sdl.Color.red,
            .font_size = 30,
        },
        "Model is here!",
        .{},
    );
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
}
