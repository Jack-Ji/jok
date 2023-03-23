const std = @import("std");
const jok = @import("jok");
const sdl = jok.sdl;
const imgui = jok.imgui;
const font = jok.font;
const zmath = jok.zmath;
const zmesh = jok.zmesh;
const j2d = jok.j2d;
const j3d = jok.j3d;

var lighting: bool = true;
var wireframe: bool = false;
var playtime: f32 = 1.0;
var camera: j3d.Camera = undefined;
var mesh1: *j3d.Mesh = undefined;
var mesh2: *j3d.Mesh = undefined;
var mesh3: *j3d.Mesh = undefined;

pub fn init(ctx: jok.Context) !void {
    std.log.info("game init", .{});

    camera = j3d.Camera.fromPositionAndTarget(
        .{
            .perspective = .{
                .fov = jok.utils.math.degreeToRadian(70),
                .aspect_ratio = ctx.getAspectRatio(),
                .near = 0.1,
                .far = 1000,
            },
        },
        [_]f32{ 7, 4.1, 7 },
        [_]f32{ 0, 0, 0 },
        null,
    );

    mesh1 = try j3d.Mesh.fromGltf(
        ctx.allocator(),
        ctx.renderer(),
        "assets/models/CesiumMan.glb",
        .{},
    );
    mesh2 = try j3d.Mesh.fromGltf(
        ctx.allocator(),
        ctx.renderer(),
        "assets/models/RiggedSimple.glb",
        .{},
    );
    mesh3 = try j3d.Mesh.fromGltf(
        ctx.allocator(),
        ctx.renderer(),
        "assets/models/Fox/Fox.gltf",
        .{},
    );

    try ctx.renderer().setColorRGB(77, 77, 77);
    ctx.refresh();
}

pub fn event(ctx: jok.Context, e: sdl.Event) !void {
    _ = ctx;
    _ = e;
}

pub fn update(ctx: jok.Context) !void {
    // camera movement
    const distance = ctx.deltaSeconds() * 5;
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

    if (imgui.begin("Control Panel", .{})) {
        _ = imgui.checkbox("lighting", .{ .v = &lighting });
        _ = imgui.checkbox("wireframe", .{ .v = &wireframe });
        if (imgui.dragFloat("playtime", .{
            .v = &playtime,
            .speed = 0.01,
        })) {
            ctx.refresh();
        }
    }
    imgui.end();
}

pub fn draw(ctx: jok.Context) !void {
    try j3d.begin(.{
        .camera = camera,
        .sort_by_depth = true,
        .wireframe_color = if (wireframe) sdl.Color.green else null,
    });
    try j3d.addMesh(
        mesh1,
        zmath.scalingV(zmath.f32x4s(3)),
        .{
            .rdopt = .{
                .lighting = if (lighting) .{} else null,
            },
            .animation_name = "default",
            .animation_playtime = playtime,
        },
    );
    try j3d.addMesh(
        mesh2,
        zmath.translation(-4, 0, 0),
        .{
            .rdopt = .{
                .color = sdl.Color.cyan,
                .lighting = if (lighting) .{} else null,
            },
        },
    );
    try j3d.addMesh(
        mesh3,
        zmath.mul(
            zmath.rotationY(-std.math.pi / 6.0),
            zmath.mul(
                zmath.scalingV(zmath.f32x4s(0.03)),
                zmath.translation(4, 0, 0),
            ),
        ),
        .{
            .rdopt = .{
                .lighting = if (lighting) .{} else null,
            },
        },
    );
    try j3d.addAxises(.{ .radius = 0.01, .length = 0.5 });
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
    mesh1.destroy();
    mesh2.destroy();
    mesh3.destroy();
}
