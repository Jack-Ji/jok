const std = @import("std");
const assert = std.debug.assert;
const math = std.math;
const builtin = @import("builtin");
const jok = @import("jok");
const font = jok.font;
const j3d = jok.j3d;
const Camera = j3d.Camera;
const zgui = jok.vendor.zgui;
const znoise = jok.vendor.znoise;
const zmath = jok.vendor.zmath;
const zmesh = jok.vendor.zmesh;

pub const jok_window_resizable = true;

var batchpool: j3d.BatchPool(64, false) = undefined;
var vsync: bool = false;
var lighting: bool = true;
var wireframe: bool = false;
var shading_method: i32 = 0;
var light_pos1: [3]f32 = undefined;
var light_pos2: [3]f32 = undefined;
var camera: Camera = undefined;
var terran: zmesh.Shape = undefined;
var cube: zmesh.Shape = undefined;
var parametric_sphere: zmesh.Shape = undefined;
var subdivided_sphere: zmesh.Shape = undefined;
var hemisphere: zmesh.Shape = undefined;
var cone: zmesh.Shape = undefined;
var cylinder: zmesh.Shape = undefined;
var disk: zmesh.Shape = undefined;
var torus: zmesh.Shape = undefined;
var icosahedron: zmesh.Shape = undefined;
var dodecahedron: zmesh.Shape = undefined;
var octahedron: zmesh.Shape = undefined;
var tetrahedron: zmesh.Shape = undefined;
var rock: zmesh.Shape = undefined;

var noise_gen = znoise.FnlGenerator{
    .fractal_type = .fbm,
    .frequency = 2.0,
    .octaves = 5,
    .lacunarity = 2.02,
};
fn uvToPos(uv: *const [2]f32, position: *[3]f32, userdata: ?*anyopaque) callconv(.c) void {
    _ = userdata;
    position[0] = uv[0];
    position[1] = 0.25 * noise_gen.noise2(uv[0], uv[1]);
    position[2] = uv[1];
}

pub fn init(ctx: jok.Context) !void {
    std.log.info("game init", .{});

    batchpool = try @TypeOf(batchpool).init(ctx);
    camera = Camera.fromPositionAndTarget(
        .{
            .perspective = .{
                .fov = std.math.degreesToRadians(70),
                .aspect_ratio = ctx.getAspectRatio(),
                .near = 0.1,
                .far = 1000,
            },
        },
        [_]f32{ 60, 46, 30 },
        [_]f32{ 0, 0, 0 },
    );
    terran = .initParametric(
        uvToPos,
        50,
        50,
        null,
    );
    terran.translate(-0.5, 0, -0.5);
    terran.invert(0, 0);
    terran.scale(100, 20, 100);
    terran.computeNormals();
    cube = .initCube();
    cube.computeNormals();
    parametric_sphere = .initParametricSphere(15, 15);
    parametric_sphere.computeNormals();
    subdivided_sphere = .initSubdividedSphere(2);
    subdivided_sphere.computeNormals();
    hemisphere = .initHemisphere(15, 15);
    hemisphere.computeNormals();
    cone = .initCone(15, 40);
    cone.computeNormals();
    cylinder = .initCylinder(20, 1);
    cylinder.computeNormals();
    disk = .initDisk(
        1,
        20,
        &.{ 0, 0, 0 },
        &.{ 0, 0, 1 },
    );
    disk.computeNormals();
    torus = .initTorus(15, 20, 0.2);
    torus.computeNormals();
    icosahedron = .initIcosahedron();
    icosahedron.computeNormals();
    dodecahedron = .initDodecahedron();
    dodecahedron.computeNormals();
    octahedron = .initOctahedron();
    octahedron.computeNormals();
    tetrahedron = .initTetrahedron();
    tetrahedron.computeNormals();
    rock = .initRock(3, 1);
    rock.computeNormals();
}

pub fn event(ctx: jok.Context, e: jok.Event) !void {
    const S = struct {
        var fullscreen = false;
        var is_viewing: bool = false;
        const mouse_speed: f32 = 0.0025;
    };

    switch (e) {
        .key_down => |k| {
            if (k.scancode == .f1) {
                S.fullscreen = !S.fullscreen;
                try ctx.window().setFullscreen(S.fullscreen);
            }
        },
        .mouse_button_down => |me| {
            if (me.button == .right) {
                try ctx.window().setRelativeMouseMode(true);
                S.is_viewing = true;
            }
        },
        .mouse_button_up => |me| {
            if (me.button == .right) {
                try ctx.window().setRelativeMouseMode(false);
                S.is_viewing = false;
            }
        },
        .mouse_motion => |me| {
            if (S.is_viewing) {
                camera.rotateBy(
                    S.mouse_speed * me.delta.y,
                    S.mouse_speed * me.delta.x,
                );
            }
        },
        .window_resized => {
            camera.frustum = j3d.Camera.ViewFrustum{
                .perspective = .{
                    .fov = std.math.degreesToRadians(70),
                    .aspect_ratio = ctx.getAspectRatio(),
                    .near = 0.1,
                    .far = 1000,
                },
            };
        },
        else => {},
    }
}

pub fn update(ctx: jok.Context) !void {
    // camera movement
    const distance = ctx.deltaSeconds() * 20;
    const kbd = jok.io.getKeyboardState();
    if (kbd.isPressed(.w)) {
        camera.moveBy(.forward, distance);
    }
    if (kbd.isPressed(.s)) {
        camera.moveBy(.backward, distance);
    }
    if (kbd.isPressed(.a)) {
        camera.moveBy(.left, distance);
    }
    if (kbd.isPressed(.d)) {
        camera.moveBy(.right, distance);
    }
}

pub fn draw(ctx: jok.Context) !void {
    try ctx.renderer().clear(.rgb(77, 77, 77));
    ctx.displayStats(.{});

    if (zgui.begin("Control Panel", .{})) {
        zgui.textUnformatted("shading method");
        zgui.sameLine(.{});
        _ = zgui.radioButtonStatePtr("gouraud", .{
            .v = &shading_method,
            .v_button = 0,
        });
        zgui.sameLine(.{});
        _ = zgui.radioButtonStatePtr("flat", .{
            .v = &shading_method,
            .v_button = 1,
        });
        _ = zgui.checkbox("lighting", .{ .v = &lighting });
        _ = zgui.checkbox("wireframe", .{ .v = &wireframe });
        if (zgui.checkbox("vsync", .{ .v = &vsync })) {
            try ctx.renderer().setVsync(@intFromBool(vsync));
        }
    }
    zgui.end();

    var lighting_opt: ?j3d.lighting.LightingOption = .{};
    if (lighting) {
        light_pos1[0] = math.sin(ctx.seconds()) * 40;
        light_pos1[1] = 30;
        light_pos1[2] = 0;
        const v = zmath.mul(
            zmath.f32x4(-40, 40, 0, 1),
            zmath.rotationY(ctx.seconds()),
        );
        light_pos2[0] = v[0];
        light_pos2[1] = v[1];
        light_pos2[2] = v[2];
        lighting_opt.?.lights_num = 2;
        lighting_opt.?.lights[0] = .{
            .spot = .{
                .position = zmath.f32x4(light_pos1[0], light_pos1[1], light_pos1[2], 1),
                .direction = zmath.f32x4(0, -1, 0, 0),
                .attenuation_linear = 0.002,
                .attenuation_quadratic = 0.001,
            },
        };
        lighting_opt.?.lights[1] = .{
            .point = .{
                .diffuse = zmath.f32x4(1.0, 1.0, 0.7, 1),
                .position = zmath.f32x4(light_pos2[0], light_pos2[1], light_pos2[2], 1),
                .attenuation_linear = 0.002,
                .attenuation_quadratic = 0.001,
            },
        };
    } else {
        lighting_opt = null;
    }

    var b = try batchpool.new(.{
        .camera = camera,
        .triangle_sort = .simple,
        .wireframe_color = if (wireframe) .green else null,
    });
    defer b.submit();
    try b.shape(
        terran,
        null,
        .{
            .lighting = lighting_opt,
            .color = .rgb(0.5, 0.6, 0.7),
            .shading_method = @enumFromInt(shading_method),
        },
    );

    b.scale(.{ 5, 5, 5 });
    try b.pushTransform();

    b.translate(.{ 30, 5, 10 });
    try b.shape(
        cube,
        null,
        .{
            .lighting = lighting_opt,
            .color = .red,
            .shading_method = @enumFromInt(shading_method),
        },
    );

    b.popTransform();
    try b.pushTransform();
    b.translate(.{ -30, 10, -20 });
    try b.shape(
        parametric_sphere,
        null,
        .{
            .lighting = lighting_opt,
            .color = .green,
            .shading_method = @enumFromInt(shading_method),
        },
    );

    b.popTransform();
    try b.pushTransform();
    b.translate(.{ -20, 10, -20 });
    try b.shape(
        subdivided_sphere,
        null,
        .{
            .lighting = lighting_opt,
            .color = .green,
            .shading_method = @enumFromInt(shading_method),
        },
    );

    b.popTransform();
    try b.pushTransform();
    b.translate(.{ -15, 5, -10 });
    try b.shape(
        hemisphere,
        null,
        .{
            .lighting = lighting_opt,
            .color = .green,
            .shading_method = @enumFromInt(shading_method),
        },
    );

    b.trs = zmath.mul(
        zmath.mul(
            zmath.scaling(5, 5, 20),
            zmath.rotationX(-math.pi * 0.5),
        ),
        zmath.translation(15, 5, -10),
    );
    try b.shape(
        cone,
        null,
        .{
            .lighting = lighting_opt,
            .color = .blue,
            .shading_method = @enumFromInt(shading_method),
        },
    );

    b.trs = zmath.mul(
        zmath.mul(
            zmath.scaling(5, 5, 20),
            zmath.rotationX(-math.pi * 0.5),
        ),
        zmath.translation(15, 5, -25),
    );
    try b.shape(
        cylinder,
        null,
        .{
            .cull_faces = false,
            .lighting = lighting_opt,
            .color = .magenta,
            .shading_method = @enumFromInt(shading_method),
        },
    );

    b.trs = zmath.mul(
        zmath.mul(
            zmath.scaling(5, 5, 1),
            zmath.rotationX(-math.pi * 0.6),
        ),
        zmath.translation(15, 8, 9),
    );
    try b.shape(
        disk,
        null,
        .{
            .cull_faces = false,
            .lighting = lighting_opt,
            .color = .yellow,
            .shading_method = @enumFromInt(shading_method),
        },
    );

    b.trs = zmath.mul(
        zmath.scaling(8, 8, 8),
        zmath.translation(-5, 15, 25),
    );
    try b.shape(
        torus,
        null,
        .{
            .lighting = lighting_opt,
            .color = .white,
            .shading_method = @enumFromInt(shading_method),
        },
    );

    b.trs = zmath.mul(
        zmath.scaling(8, 8, 8),
        zmath.translation(-30, 15, 35),
    );
    try b.shape(
        icosahedron,
        null,
        .{
            .lighting = lighting_opt,
            .color = .rgb(0.6, 0.6, 0.7),
            .shading_method = @enumFromInt(shading_method),
        },
    );

    b.trs = zmath.mul(
        zmath.scaling(8, 8, 8),
        zmath.translation(-20, 10, 15),
    );
    try b.shape(
        dodecahedron,
        null,
        .{
            .lighting = lighting_opt,
            .color = .rgb(0.7, 0.6, 0.7),
            .shading_method = @enumFromInt(shading_method),
        },
    );

    b.trs = zmath.mul(
        zmath.scaling(8, 8, 8),
        zmath.translation(36, 10, 0),
    );
    try b.shape(
        octahedron,
        null,
        .{
            .lighting = lighting_opt,
            .color = .rgb(0.7, 0.3, 0.4),
            .shading_method = @enumFromInt(shading_method),
        },
    );

    b.trs = zmath.mul(
        zmath.scaling(12, 12, 12),
        zmath.translation(14, 5, 28),
    );
    try b.shape(
        tetrahedron,
        null,
        .{
            .lighting = lighting_opt,
            .color = .rgb(0.9, 0.9, 0.2),
            .shading_method = @enumFromInt(shading_method),
        },
    );

    b.trs = zmath.mul(
        zmath.scaling(6, 6, 6),
        zmath.translation(35, 5, 35),
    );
    try b.shape(
        rock,
        null,
        .{
            .lighting = lighting_opt,
            .color = .yellow,
            .shading_method = @enumFromInt(shading_method),
        },
    );
    if (lighting) {
        b.trs = zmath.translation(light_pos1[0], light_pos1[1], light_pos1[2]);
        try b.shape(
            subdivided_sphere,
            null,
            .{
                .color = .rgb(
                    lighting_opt.?.lights[0].spot.diffuse[0],
                    lighting_opt.?.lights[0].spot.diffuse[1],
                    lighting_opt.?.lights[0].spot.diffuse[2],
                ),
            },
        );

        b.trs = zmath.translation(light_pos2[0], light_pos2[1], light_pos2[2]);
        try b.shape(
            subdivided_sphere,
            null,
            .{
                .color = .rgb(
                    lighting_opt.?.lights[1].point.diffuse[0],
                    lighting_opt.?.lights[1].point.diffuse[1],
                    lighting_opt.?.lights[1].point.diffuse[2],
                ),
            },
        );

        b.trs = zmath.mul(
            zmath.mul(
                zmath.scaling(15, 15, 30),
                zmath.rotationX(-math.pi * 0.5),
            ),
            zmath.translation(light_pos1[0], 0, light_pos1[2]),
        );
        try b.shape(
            cone,
            null,
            .{
                .color = .rgba(
                    lighting_opt.?.lights[0].spot.diffuse[0],
                    lighting_opt.?.lights[0].spot.diffuse[1],
                    lighting_opt.?.lights[0].spot.diffuse[2],
                    0.03,
                ),
            },
        );
    }

    ctx.debugPrint(
        "Press WSAD to move around, drag mouse while pressing right-button to rotate the view",
        .{ .pos = .{ .x = 20, .y = 10 } },
    );
    ctx.debugPrint(
        zgui.format(
            "Camera: pos({d:.3},{d:.3},{d:.3}) dir({d:.3},{d:.3},{d:.3})",
            .{
                camera.position[0], camera.position[1], camera.position[2],
                camera.dir[0],      camera.dir[1],      camera.dir[2],
            },
        ),
        .{ .pos = .{ .x = 20, .y = 28 } },
    );
}

pub fn quit(ctx: jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});

    terran.deinit();
    cube.deinit();
    parametric_sphere.deinit();
    subdivided_sphere.deinit();
    hemisphere.deinit();
    cone.deinit();
    cylinder.deinit();
    disk.deinit();
    torus.deinit();
    icosahedron.deinit();
    dodecahedron.deinit();
    octahedron.deinit();
    tetrahedron.deinit();
    rock.deinit();
    batchpool.deinit();
}
