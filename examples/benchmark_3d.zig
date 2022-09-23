const std = @import("std");
const sdl = @import("sdl");
const jok = @import("jok");
const font = jok.font;
const gfx = jok.gfx.@"3d";
const zmath = gfx.zmath;
const primitive = gfx.primitive;

pub const jok_fps_limit = jok.config.FpsLimit.none;

var camera: gfx.Camera = undefined;
var cube: gfx.zmesh.Shape = undefined;
var aabb: [6]f32 = undefined;
var tex: sdl.Texture = undefined;
var translations: std.ArrayList(zmath.Mat) = undefined;
var rotation_axises: std.ArrayList(zmath.Vec) = undefined;
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
        [_]f32{ 8, 9, -9 },
        [_]f32{ 0, 0, 0 },
        null,
    );
    cube = gfx.zmesh.Shape.initCube();
    cube.computeAabb(&aabb);
    cube.computeNormals();
    cube.texcoords = texcoords[0..];
    try primitive.init(ctx, null);

    tex = try jok.gfx.utils.createTextureFromFile(
        ctx.renderer,
        "assets/images/image5.jpg",
        .static,
        false,
    );

    var rng = std.rand.DefaultPrng.init(@intCast(u64, std.time.timestamp()));
    translations = std.ArrayList(zmath.Mat).init(ctx.allocator);
    rotation_axises = std.ArrayList(zmath.Vec).init(ctx.allocator);
    var i: u32 = 0;
    while (i < 10000) : (i += 1) {
        try translations.append(zmath.translation(
            -5 + rng.random().float(f32) * 10,
            -5 + rng.random().float(f32) * 10,
            -5 + rng.random().float(f32) * 10,
        ));
        try rotation_axises.append(zmath.f32x4(
            -1 + rng.random().float(f32) * 2,
            -1 + rng.random().float(f32) * 2,
            -1 + rng.random().float(f32) * 2,
            0,
        ));
    }
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

    try ctx.renderer.setColorRGB(77, 77, 77);
    try ctx.renderer.clear();

    primitive.clear();
    for (translations.items) |tr, i| {
        try primitive.addShape(
            cube,
            zmath.mul(
                zmath.translation(-0.5, -0.5, -0.5),
                zmath.mul(
                    zmath.mul(
                        zmath.scaling(0.1, 0.1, 0.1),
                        zmath.matFromAxisAngle(rotation_axises.items[i], std.math.pi / 3.0 * @floatCast(f32, ctx.tick)),
                    ),
                    tr,
                ),
            ),
            camera,
            aabb,
            .{ .renderer = ctx.renderer },
        );
    }
    try primitive.render(ctx.renderer, .{ .texture = tex });

    _ = try font.debugDraw(
        ctx.renderer,
        .{ .pos = .{ .x = 200, .y = 10 } },
        "Press WSAD and up/down/left/right to move camera around the view",
        .{},
    );
}

pub fn quit(ctx: *jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});

    cube.deinit();
    primitive.deinit();
    translations.deinit();
    rotation_axises.deinit();
}
