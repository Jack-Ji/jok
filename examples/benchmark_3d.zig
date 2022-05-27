const std = @import("std");
const sdl = @import("sdl");
const jok = @import("jok");
const gfx = jok.gfx.@"3d";
const font = jok.gfx.@"2d".font;

var camera: gfx.Camera = undefined;
var renderer: gfx.Renderer = undefined;
var cube: gfx.zmesh.Shape = undefined;
var tex: sdl.Texture = undefined;
var translations: std.ArrayList(gfx.zmath.Mat) = undefined;
var rotation_axises: std.ArrayList(gfx.zmath.Vec) = undefined;

fn init(ctx: *jok.Context) anyerror!void {
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
        gfx.zmath.f32x4(8, 9, -9, 1),
        gfx.zmath.f32x4(0, 0, 0, 0),
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

    var rng = std.rand.DefaultPrng.init(@intCast(u64, std.time.timestamp()));
    translations = std.ArrayList(gfx.zmath.Mat).init(ctx.default_allocator);
    rotation_axises = std.ArrayList(gfx.zmath.Vec).init(ctx.default_allocator);
    var i: u32 = 0;
    while (i < 2) : (i += 1) {
        try translations.append(gfx.zmath.translation(
            -5 + rng.random().float(f32) * 10,
            -5 + rng.random().float(f32) * 10,
            -5 + rng.random().float(f32) * 10,
        ));
        try rotation_axises.append(gfx.zmath.f32x4(
            -1 + rng.random().float(f32) * 2,
            -1 + rng.random().float(f32) * 2,
            -1 + rng.random().float(f32) * 2,
            0,
        ));
    }
}

fn loop(ctx: *jok.Context) anyerror!void {
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

    renderer.clearVertex(true);
    for (translations.items) |tr, i| {
        try renderer.appendVertex(
            ctx.renderer,
            gfx.zmath.mul(
                gfx.zmath.translation(-0.5, -0.5, -0.5),
                gfx.zmath.mul(
                    gfx.zmath.mul(
                        gfx.zmath.scaling(0.1, 0.1, 0.1),
                        gfx.zmath.matFromAxisAngle(rotation_axises.items[i], std.math.pi / 3.0 * @floatCast(f32, ctx.tick)),
                    ),
                    tr,
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
            true,
        );
    }
    try renderer.draw(ctx.renderer, tex);

    _ = try font.debugDraw(
        ctx.renderer,
        .{ .pos = .{ .x = 200, .y = 10 } },
        "Press WSAD and up/down/left/right to move camera around the view",
        .{},
    );
}

fn quit(ctx: *jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});

    cube.deinit();
    gfx.zmesh.deinit();
    renderer.deinit();
    translations.deinit();
    rotation_axises.deinit();
}

pub fn main() anyerror!void {
    try jok.run(.{
        .initFn = init,
        .loopFn = loop,
        .quitFn = quit,
    });
}
