const std = @import("std");
const jok = @import("jok");
const font = jok.font;
const zmath = jok.zmath;
const zmesh = jok.zmesh;
const imgui = jok.imgui;
const j3d = jok.j3d;
const Camera = j3d.Camera;
const Scene = j3d.Scene;
const Mesh = j3d.Mesh;

var batchpool: j3d.BatchPool(64, false) = undefined;
var camera: Camera = undefined;
var sphere: zmesh.Shape = undefined;
var scene: *Scene = undefined;
var earth_orbit: *Scene.Object = undefined;
var moon_orbit: *Scene.Object = undefined;
var sun: *Scene.Object = undefined;
var earth: *Scene.Object = undefined;
var moon: *Scene.Object = undefined;

pub fn init(ctx: jok.Context) !void {
    std.log.info("game init", .{});

    batchpool = try @TypeOf(batchpool).init(ctx);
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
    );
    sphere = zmesh.Shape.initSubdividedSphere(2);
    sphere.computeNormals();

    // Init solar system
    scene = try Scene.create(ctx.allocator());
    earth_orbit = try Scene.Object.create(ctx.allocator(), .{ .position = .{} });
    moon_orbit = try Scene.Object.create(ctx.allocator(), .{ .position = .{} });
    sun = try Scene.Object.create(ctx.allocator(), .{
        .mesh = .{
            .transform = zmath.scalingV(zmath.f32x4s(0.6)),
            .mesh = try Mesh.fromShape(ctx.allocator(), sphere, .{}),
            .color = .rgb(255, 255, 0),
            .disable_lighting = true,
        },
    });
    earth = try Scene.Object.create(ctx.allocator(), .{
        .mesh = .{
            .transform = zmath.scalingV(zmath.f32x4s(0.2)),
            .mesh = try Mesh.fromShape(ctx.allocator(), sphere, .{}),
            .color = .rgb(0, 0, 255),
        },
    });
    moon = try Scene.Object.create(ctx.allocator(), .{
        .mesh = .{
            .transform = zmath.scalingV(zmath.f32x4s(0.06)),
            .mesh = try Mesh.fromShape(ctx.allocator(), sphere, .{}),
            .color = .rgb(192, 192, 192),
        },
    });
    try scene.root.addChild(sun);
    try scene.root.addChild(earth_orbit);
    try earth_orbit.addChild(earth);
    try earth_orbit.addChild(moon_orbit);
    try moon_orbit.addChild(moon);
}

pub fn event(ctx: jok.Context, e: jok.Event) !void {
    _ = ctx;
    _ = e;
}

pub fn update(ctx: jok.Context) !void {
    // camera movement
    const distance = ctx.deltaSeconds() * 2;
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
    if (kbd.isPressed(.left)) {
        camera.rotateBy(0, -std.math.pi / 180.0);
    }
    if (kbd.isPressed(.right)) {
        camera.rotateBy(0, std.math.pi / 180.0);
    }
    if (kbd.isPressed(.up)) {
        camera.rotateBy(std.math.pi / 180.0, 0);
    }
    if (kbd.isPressed(.down)) {
        camera.rotateBy(-std.math.pi / 180.0, 0);
    }

    earth_orbit.setTransform(
        zmath.mul(zmath.translation(2, 0, 0), zmath.rotationY(ctx.seconds())),
    );
    moon_orbit.setTransform(
        zmath.mul(zmath.translation(0.3, 0, 0), zmath.rotationY(ctx.seconds() * 12)),
    );
}

pub fn draw(ctx: jok.Context) !void {
    try ctx.renderer().clear(.rgb(80, 80, 80));

    var lighting_opt = j3d.lighting.LightingOption{};
    lighting_opt.lights[0] = j3d.lighting.Light{
        .point = .{
            .position = zmath.f32x4s(0),
            .attenuation_linear = 0,
            .attenuation_quadratic = 0,
        },
    };

    var b = try batchpool.new(.{ .camera = camera, .triangle_sort = .simple });
    defer b.submit();
    try b.scene(scene, .{ .lighting = lighting_opt });

    ctx.debugPrint(
        "Press WSAD and up/down/left/right to move camera around the view",
        .{ .pos = .{ .x = 20, .y = 10 } },
    );
    ctx.debugPrint(
        imgui.format(
            "Camera: pos({d:.3},{d:.3},{d:.3}) dir({d:.3},{d:.3},{d:.3})",
            .{
                // zig fmt: off
            camera.position[0],camera.position[1],camera.position[2],
            camera.dir[0],camera.dir[1],camera.dir[2],
        },
        ),
        .{.pos=.{ .x = 20, .y = 28 }},
    );
}

pub fn quit(ctx: jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});

    sphere.deinit();
    scene.destroy(true);
    batchpool.deinit();
}
