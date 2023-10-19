const std = @import("std");
const assert = std.debug.assert;
const math = std.math;
const builtin = @import("builtin");
const jok = @import("jok");
const sdl = jok.sdl;
const imgui = jok.imgui;
const znoise = jok.znoise;
const zmath = jok.zmath;
const zmesh = jok.zmesh;
const font = jok.font;
const j3d = jok.j3d;
const Camera = j3d.Camera;

pub const jok_window_resizable = true;

var lighting: bool = true;
var wireframe: bool = false;
var light_pos1: [3]f32 = undefined;
var light_pos2: [3]f32 = undefined;
var camera: Camera = undefined;
var terran: zmesh.Shape = undefined;

var noise_gen = znoise.FnlGenerator{
    .fractal_type = .fbm,
    .frequency = 2.0,
    .octaves = 5,
    .lacunarity = 2.02,
};
fn uvToPos(uv: *const [2]f32, position: *[3]f32, userdata: ?*anyopaque) callconv(.C) void {
    _ = userdata;
    position[0] = uv[0];
    position[1] = 0.25 * noise_gen.noise2(uv[0], uv[1]);
    position[2] = uv[1];
}

pub fn init(ctx: jok.Context) !void {
    std.log.info("game init", .{});

    camera = Camera.fromPositionAndTarget(
        .{
            .perspective = .{
                .fov = jok.utils.math.degreeToRadian(70),
                .aspect_ratio = ctx.getAspectRatio(),
                .near = 0.1,
                .far = 1000,
            },
        },
        [_]f32{ 60, 46, 30 },
        [_]f32{ 0, 0, 0 },
        null,
    );
    terran = zmesh.Shape.initParametric(
        uvToPos,
        50,
        50,
        null,
    );
    terran.translate(-0.5, 0, -0.5);
    terran.invert(0, 0);
    terran.scale(100, 20, 100);
    terran.computeNormals();

    try ctx.renderer().setColorRGB(77, 77, 77);
}

pub fn event(ctx: jok.Context, e: sdl.Event) !void {
    _ = ctx;
    _ = e;
}

pub fn update(ctx: jok.Context) !void {
    // camera movement
    const distance = ctx.deltaSeconds() * 20;
    if (ctx.isKeyPressed(.w)) {
        camera.moveBy(.forward, distance);
    }
    if (ctx.isKeyPressed(.s)) {
        camera.moveBy(.backward, distance);
    }
    if (ctx.isKeyPressed(.a)) {
        camera.moveBy(.left, distance);
    }
    if (ctx.isKeyPressed(.d)) {
        camera.moveBy(.right, distance);
    }
    if (ctx.isKeyPressed(.left)) {
        camera.rotateBy(0, -std.math.pi / 180.0);
    }
    if (ctx.isKeyPressed(.right)) {
        camera.rotateBy(0, std.math.pi / 180.0);
    }
    if (ctx.isKeyPressed(.up)) {
        camera.rotateBy(std.math.pi / 180.0, 0);
    }
    if (ctx.isKeyPressed(.down)) {
        camera.rotateBy(-std.math.pi / 180.0, 0);
    }

    if (imgui.begin("Control Panel", .{})) {
        _ = imgui.checkbox("lighting", .{ .v = &lighting });
        _ = imgui.checkbox("wireframe", .{ .v = &wireframe });
    }
    imgui.end();
}

pub fn draw(ctx: jok.Context) !void {
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

    try j3d.begin(.{
        .camera = camera,
        .triangle_sort = .single_pass,
        .wireframe_color = if (wireframe) sdl.Color.green else null,
    });
    try j3d.shape(
        terran,
        zmath.identity(),
        null,
        .{
            .lighting = lighting_opt,
            .color = sdl.Color.rgb(130, 160, 190),
        },
    );
    try j3d.cube(
        zmath.mul(
            zmath.scaling(5, 5, 5),
            zmath.translation(30, 5, 10),
        ),
        .{
            .rdopt = .{
                .lighting = lighting_opt,
                .color = sdl.Color.red,
            },
        },
    );
    try j3d.parametricSphere(
        zmath.mul(
            zmath.scaling(5, 5, 5),
            zmath.translation(-30, 10, -20),
        ),
        .{
            .rdopt = .{
                .lighting = lighting_opt,
                .color = sdl.Color.green,
            },
        },
    );
    try j3d.subdividedSphere(
        zmath.mul(
            zmath.scaling(5, 5, 5),
            zmath.translation(-20, 10, -20),
        ),
        .{
            .rdopt = .{
                .lighting = lighting_opt,
                .color = sdl.Color.green,
            },
        },
    );
    try j3d.hemisphere(
        zmath.mul(
            zmath.scaling(5, 5, 5),
            zmath.translation(-15, 5, -10),
        ),
        .{
            .rdopt = .{
                .lighting = lighting_opt,
                .color = sdl.Color.green,
            },
        },
    );
    try j3d.cone(
        zmath.mul(
            zmath.mul(
                zmath.scaling(5, 5, 20),
                zmath.rotationX(-math.pi * 0.5),
            ),
            zmath.translation(15, 5, -10),
        ),
        .{
            .rdopt = .{
                .lighting = lighting_opt,
                .color = sdl.Color.blue,
            },
        },
    );
    try j3d.cylinder(
        zmath.mul(
            zmath.mul(
                zmath.scaling(5, 5, 20),
                zmath.rotationX(-math.pi * 0.5),
            ),
            zmath.translation(15, 5, -25),
        ),
        .{
            .rdopt = .{
                .cull_faces = false,
                .lighting = lighting_opt,
                .color = sdl.Color.magenta,
            },
        },
    );
    try j3d.disk(
        zmath.mul(
            zmath.mul(
                zmath.scaling(5, 5, 1),
                zmath.rotationX(-math.pi * 0.6),
            ),
            zmath.translation(15, 8, 9),
        ),
        .{
            .rdopt = .{
                .cull_faces = false,
                .lighting = lighting_opt,
                .color = sdl.Color.yellow,
            },
        },
    );
    try j3d.torus(
        zmath.mul(
            zmath.scaling(8, 8, 8),
            zmath.translation(-5, 15, 25),
        ),
        .{
            .rdopt = .{
                .lighting = lighting_opt,
                .color = sdl.Color.white,
            },
        },
    );
    try j3d.icosahedron(
        zmath.mul(
            zmath.scaling(8, 8, 8),
            zmath.translation(-30, 15, 35),
        ),
        .{
            .rdopt = .{
                .lighting = lighting_opt,
                .color = sdl.Color.rgb(150, 160, 190),
            },
        },
    );
    try j3d.dodecahedron(
        zmath.mul(
            zmath.scaling(8, 8, 8),
            zmath.translation(-20, 10, 15),
        ),
        .{
            .rdopt = .{
                .lighting = lighting_opt,
                .color = sdl.Color.rgb(180, 170, 190),
            },
        },
    );
    try j3d.octahedron(
        zmath.mul(
            zmath.scaling(8, 8, 8),
            zmath.translation(36, 10, 0),
        ),
        .{
            .rdopt = .{
                .lighting = lighting_opt,
                .color = sdl.Color.rgb(180, 70, 90),
            },
        },
    );
    try j3d.tetrahedron(
        zmath.mul(
            zmath.scaling(12, 12, 12),
            zmath.translation(14, 5, 28),
        ),
        .{
            .rdopt = .{
                .lighting = lighting_opt,
                .color = sdl.Color.rgb(230, 230, 50),
            },
        },
    );
    try j3d.rock(
        zmath.mul(
            zmath.scaling(6, 6, 6),
            zmath.translation(35, 5, 35),
        ),
        .{
            .rdopt = .{
                .lighting = lighting_opt,
                .color = sdl.Color.yellow,
            },
            .seed = 100,
            .sub_num = 2,
        },
    );
    try j3d.axises(.{
        .pos = .{ 0, 5, 0 },
        .radius = 0.3,
        .length = 15,
    });
    if (lighting) {
        try j3d.subdividedSphere(
            zmath.translation(light_pos1[0], light_pos1[1], light_pos1[2]),
            .{
                .rdopt = .{
                    .color = sdl.Color.rgb(
                        @intFromFloat(lighting_opt.?.lights[0].spot.diffuse[0] * 255),
                        @intFromFloat(lighting_opt.?.lights[0].spot.diffuse[1] * 255),
                        @intFromFloat(lighting_opt.?.lights[0].spot.diffuse[2] * 255),
                    ),
                },
            },
        );
        try j3d.subdividedSphere(
            zmath.translation(light_pos2[0], light_pos2[1], light_pos2[2]),
            .{
                .rdopt = .{
                    .color = sdl.Color.rgb(
                        @intFromFloat(lighting_opt.?.lights[1].point.diffuse[0] * 255),
                        @intFromFloat(lighting_opt.?.lights[1].point.diffuse[1] * 255),
                        @intFromFloat(lighting_opt.?.lights[1].point.diffuse[2] * 255),
                    ),
                },
            },
        );
    }
    try j3d.end();

    _ = try font.debugDraw(
        ctx,
        .{ .pos = .{ .x = 200, .y = 10 } },
        "Press WSAD and up/down/left/right to move camera around the view",
        .{},
    );
    _ = try font.debugDraw(
        ctx,
        .{ .pos = .{ .x = 200, .y = 28 } },
        "Camera: pos({d:.3},{d:.3},{d:.3}) dir({d:.3},{d:.3},{d:.3})",
        .{
            // zig fmt: off
            camera.position[0],camera.position[1],camera.position[2],
            camera.dir[0],camera.dir[1],camera.dir[2],
        },
    );
}

pub fn quit(ctx: jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});

    terran.deinit();
}
