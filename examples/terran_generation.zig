const std = @import("std");
const assert = std.debug.assert;
const math = std.math;
const builtin = @import("builtin");
const sdl = @import("sdl");
const jok = @import("jok");
const imgui = jok.imgui;
const znoise = jok.znoise;
const zmath = jok.zmath;
const zmesh = jok.zmesh;
const font = jok.font;
const j3d = jok.j3d;
const Camera = j3d.Camera;

pub const jok_window_resizable = true;
pub const jok_window_width: u32 = 800;
pub const jok_window_height: u32 = 600;

var wireframe: bool = false;
var light_pos: [3]f32 = .{ 0, 10, 0 };
var light_color: [3]f32 = .{ 1, 1, 1 };
var camera: Camera = undefined;
var shape: zmesh.Shape = undefined;

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
        [_]f32{ 15, 15, 15 },
        [_]f32{ 0, 0, 0 },
        null,
    );
    shape = zmesh.Shape.initParametric(
        uvToPos,
        50,
        50,
        null,
    );
    shape.translate(-0.5, -0.0, -0.5);
    shape.invert(0, 0);
    shape.scale(20, 20, 20);
    shape.computeNormals();

    try ctx.renderer.setColorRGB(77, 77, 77);
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
        _ = imgui.checkbox("wireframe", .{ .v = &wireframe });
        _ = imgui.dragFloat3("light position", .{ .v = &light_pos, .min = 1, .max = 20, .speed = 0.1 });
    }
    imgui.end();

    var lighting_opt = j3d.lighting.LightingOption{};
    lighting_opt.lights[0] = .{
        .point = .{
            .position = zmath.f32x4(light_pos[0], light_pos[1], light_pos[2], 1),
            .attenuation_linear = 0.002,
            .attenuation_quadratic = 0.0002,
        },
    };
    try j3d.begin(.{
        .camera = camera,
        .sort_by_depth = true,
        .wireframe_color = if (wireframe) sdl.Color.green else null,
    });
    try j3d.addShape(
        shape,
        zmath.identity(),
        null,
        .{
            .lighting = lighting_opt,
        },
    );
    try j3d.addSubdividedSphere(
        zmath.mul(
            zmath.scaling(0.2, 0.2, 0.2),
            zmath.translation(light_pos[0], light_pos[1], light_pos[2]),
        ),
        .{
            .rdopt = .{},
        },
    );
    try j3d.end();

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

    shape.deinit();
}
