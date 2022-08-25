const std = @import("std");
const sdl = @import("sdl");
const jok = @import("jok");
const gfx = jok.gfx.@"3d";
const font = jok.gfx.@"2d".font;
const primitive = gfx.primitive;

var camera: gfx.Camera = undefined;
var cube: gfx.zmesh.Shape = undefined;
var tex: sdl.Texture = undefined;
var texcoords = [_][2]f32{
    .{ 0, 1 },
    .{ 0, 0 },
    .{ 1, 0 },
    .{ 1, 1 },
    .{ 1, 1 },
    .{ 0, 1 },
    .{ 0, 0 },
    .{ 1, 0 },
};

pub fn init(ctx: *jok.Context) anyerror!void {
    std.log.info("game init", .{});

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
    cube = gfx.zmesh.Shape.initCube();
    cube.computeNormals();
    cube.texcoords = texcoords[0..];
    tex = try jok.gfx.utils.createTextureFromFile(
        ctx.renderer,
        "assets/images/image5.jpg",
        .static,
        false,
    );
    try primitive.init(ctx);
    try ctx.renderer.setColorRGB(77, 77, 77);
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

    primitive.clear();
    try primitive.drawShape(
        cube,
        gfx.zmath.mul(
            gfx.zmath.translation(-0.5, -0.5, -0.5),
            gfx.zmath.mul(
                gfx.zmath.scaling(0.5, 0.5, 0.5),
                gfx.zmath.rotationY(@floatCast(f32, ctx.tick) * std.math.pi),
            ),
        ),
        camera,
        null,
        .{},
    );
    try primitive.flush(.{ .texture = tex });

    primitive.clear();
    try primitive.drawShape(
        cube,
        gfx.zmath.mul(
            gfx.zmath.translation(-0.5, -0.5, -0.5),
            gfx.zmath.rotationY(@floatCast(f32, ctx.tick) * std.math.pi / 3.0),
        ),
        camera,
        null,
        .{},
    );
    try primitive.flush(.{ .wireframe = true });

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
    primitive.deinit();
}

