const std = @import("std");
const sdl = @import("sdl");
const jok = @import("jok");
const font = jok.font;
const zmath = jok.zmath;
const zmesh = jok.zmesh;
const j3d = jok.j3d;
const Camera = j3d.Camera;
const Scene = j3d.Scene;

var camera: Camera = undefined;
var sphere: zmesh.Shape = undefined;
var scene: *Scene = undefined;
var earth_orbit: *Scene.Object = undefined;
var moon_orbit: *Scene.Object = undefined;
var sun: *Scene.Object = undefined;
var earth: *Scene.Object = undefined;
var moon: *Scene.Object = undefined;

pub fn init(ctx: *jok.Context) !void {
    std.log.info("game init", .{});

    camera = Camera.fromPositionAndTarget(
        .{
            .perspective = .{
                .fov = std.math.pi / 4.0,
                .aspect_ratio = ctx.getAspectRatio(),
                .near = 0.1,
                .far = 100,
            },
        },
        [_]f32{ 0, 6, -6 },
        [_]f32{ 0, 0, 0 },
        null,
    );
    sphere = zmesh.Shape.initSubdividedSphere(2);
    sphere.computeNormals();

    // Init solar system
    scene = try Scene.create(ctx.allocator);
    earth_orbit = try Scene.Object.create(ctx.allocator, .{ .position = .{} });
    moon_orbit = try Scene.Object.create(ctx.allocator, .{ .position = .{} });
    sun = try Scene.Object.create(ctx.allocator, .{
        .mesh = .{
            .transform = zmath.scalingV(zmath.f32x4s(0.6)),
            .shape = sphere,
            .color = sdl.Color.rgb(255, 255, 0),
            .disable_lighting = true,
        },
    });
    earth = try Scene.Object.create(ctx.allocator, .{
        .mesh = .{
            .transform = zmath.scalingV(zmath.f32x4s(0.2)),
            .shape = sphere,
            .color = sdl.Color.rgb(0, 0, 255),
        },
    });
    moon = try Scene.Object.create(ctx.allocator, .{
        .mesh = .{
            .transform = zmath.scalingV(zmath.f32x4s(0.06)),
            .shape = sphere,
            .color = sdl.Color.rgb(192, 192, 192),
        },
    });
    try scene.root.addChild(sun);
    try scene.root.addChild(earth_orbit);
    try earth_orbit.addChild(earth);
    try earth_orbit.addChild(moon_orbit);
    try moon_orbit.addChild(moon);

    try ctx.renderer.setColorRGB(80, 80, 80);
}

pub fn event(ctx: *jok.Context, e: sdl.Event) !void {
    _ = ctx;
    _ = e;
}

pub fn update(ctx: *jok.Context) !void {
    // camera movement
    const distance = ctx.delta_seconds * 2;
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

    earth_orbit.setTransform(zmath.mul(zmath.translation(2, 0, 0), zmath.rotationY(ctx.seconds)));
    moon_orbit.setTransform(zmath.mul(zmath.translation(0.3, 0, 0), zmath.rotationY(@floatCast(f32, ctx.seconds * 12))));
}

pub fn draw(ctx: *jok.Context) !void {
    var lighting_opt = j3d.lighting.LightingOption{};
    lighting_opt.lights[0] = j3d.lighting.Light{
        .point = .{
            .position = zmath.f32x4s(0),
            .attenuation_linear = 0,
            .attenuation_quadratic = 0,
        },
    };

    try j3d.begin(.{ .camera = camera, .sort_by_depth = true });
    try j3d.addScene(scene, .{ .lighting = lighting_opt });
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

    sphere.deinit();
    scene.destroy(true);
}

