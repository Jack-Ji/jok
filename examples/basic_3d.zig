const std = @import("std");
const sdl = @import("sdl");
const jok = @import("jok");
const gfx = jok.gfx.@"3d";
const font = jok.gfx.@"2d".font;

var camera: gfx.Camera = undefined;
var renderer: gfx.Renderer = undefined;
var cube: gfx.zmesh.Shape = undefined;
var tex: sdl.Texture = undefined;

pub fn init(ctx: *jok.Context) anyerror!void {
    std.log.info("game init", .{});

    gfx.zmesh.init(ctx.default_allocator);

    camera = gfx.Camera.fromPositionAndTarget(
        .{
            //.orthographic = .{
            //    .width = 2 * ctx.getAspectRatio(),
            //    .height = 2,
            //    .near = 0.1,
            //    .far = 100,
            //},
            .perspective = .{
                .fov = std.math.pi / 4.0,
                .aspect_ratio = ctx.getAspectRatio(),
                .near = 0.1,
                .far = 100,
            },
        },
        [_]f32{ 0, 1, -2 },
        [_]f32{ 0, 0, 0 },
        null,
    );
    renderer = gfx.Renderer.init(ctx.default_allocator);
    cube = gfx.zmesh.Shape.initCube();
    tex = try jok.gfx.utils.createTextureFromFile(
        ctx.renderer,
        "assets/images/image5.jpg",
        .static,
        false,
    );
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
        switch (e) {
            .keyboard_event => |key| {
                if (key.trigger_type == .up) {
                    switch (key.scan_code) {
                        .escape => ctx.kill(),
                        else => {},
                    }
                }
            },
            .quit_event => ctx.kill(),
            else => {},
        }
    }

    try ctx.renderer.setColorRGB(77, 77, 77);
    try ctx.renderer.clear();

    renderer.clear(true);
    try renderer.appendVertex(
        ctx.renderer,
        gfx.zmath.mul(
            gfx.zmath.translation(-0.5, -0.5, -0.5),
            gfx.zmath.mul(
                gfx.zmath.scaling(0.5, 0.5, 0.5),
                //gfx.zmath.rotationY(@floatCast(f32, ctx.tick) * std.math.pi),
                gfx.zmath.rotationY(0),
            ),
        ),
        &camera,
        cube.indices,
        cube.positions,
        null,
        &[_][2]f32{
            .{ 0, 1 },
            .{ 0, 0 },
            .{ 1, 0 },
            .{ 1, 1 },
            .{ 1, 1 },
            .{ 0, 1 },
            .{ 0, 0 },
            .{ 1, 0 },
        },
        .{},
    );
    try renderer.draw(ctx.renderer, tex);

    renderer.clear(true);
    try renderer.appendVertex(
        ctx.renderer,
        gfx.zmath.mul(
            gfx.zmath.translation(-0.5, -0.5, -0.5),
            gfx.zmath.rotationY(@floatCast(f32, ctx.tick) * std.math.pi / 3.0),
        ),
        &camera,
        cube.indices,
        cube.positions,
        null,
        null,
        .{},
    );
    try ctx.renderer.setColor(sdl.Color.green);
    try renderer.drawWireframe(ctx.renderer);

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

    cube.deinit();
    gfx.zmesh.deinit();
    renderer.deinit();
}

