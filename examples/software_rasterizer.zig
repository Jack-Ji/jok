const std = @import("std");
const sdl = @import("sdl");
const jok = @import("jok");
const imgui = jok.deps.imgui;
const font = jok.font;
const j3d = jok.j3d;
const zmath = j3d.zmath;
const zmesh = j3d.zmesh;
const Camera = j3d.Camera;

var prd: j3d.PixelRenderer = undefined;
var camera: Camera = undefined;
var shape: zmesh.Shape = undefined;
var cullface: bool = false;
var wireframe: bool = true;

pub fn init(ctx: *jok.Context) !void {
    std.log.info("game init", .{});

    prd = try j3d.PixelRenderer.init(ctx.allocator, ctx.renderer, null);
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
    shape = zmesh.Shape.initParametricSphere(50, 50);
    shape.scale(10, 10, 10);
    shape.computeNormals();
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
    prd.clear(.{});
    try prd.appendShape(
        zmath.identity(),
        camera,
        shape.indices,
        shape.positions,
        shape.normals.?,
        null,
        null,
        .{
            .cull_faces = cullface,
            .wireframe = wireframe,
        },
    );
    try prd.line(30, 40, 200, 450, sdl.Color.red);
    try prd.triangle(100, 50, 300, 150, 200, 390, sdl.Color.green);
    try prd.triangle(300, 150, 200, 390, 400, 100, sdl.Color.yellow);
    try prd.draw(ctx.renderer, null);

    imgui.sdl.newFrame(ctx.*);
    defer imgui.sdl.draw();

    if (imgui.begin("Control Panel", .{})) {
        _ = imgui.checkbox("cullface", .{ .v = &cullface });
        _ = imgui.checkbox("wireframe", .{ .v = &wireframe });
    }
    imgui.end();

    _ = try font.debugDraw(
        ctx.renderer,
        .{ .pos = .{ .x = 200, .y = 10 }, .color = sdl.Color.green },
        "Press WSAD and up/down/left/right to move camera around the view",
        .{},
    );
    _ = try font.debugDraw(
        ctx.renderer,
        .{ .pos = .{ .x = 200, .y = 28 }, .color = sdl.Color.green },
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

    prd.deinit();
    shape.deinit();
}
