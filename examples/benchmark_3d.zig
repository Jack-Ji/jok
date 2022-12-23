const std = @import("std");
const sdl = @import("sdl");
const jok = @import("jok");
const font = jok.font;
const j3d = jok.j3d;
const zmath = j3d.zmath;
const imgui = jok.deps.imgui;
const zjobs = jok.deps.zjobs;

pub const jok_fps_limit: jok.config.FpsLimit = .none;

var jobs: zjobs.JobQueue(.{}) = undefined;
var prd: *j3d.ParallelTriangleRenderer = undefined;
var rd: j3d.TriangleRenderer = undefined;
var camera: j3d.Camera = undefined;
var cube: j3d.zmesh.Shape = undefined;
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
var parallel_rendering: bool = false;

pub fn init(ctx: *jok.Context) !void {
    std.log.info("game init", .{});

    jobs = zjobs.JobQueue(.{}).init();
    jobs.start();

    prd = try j3d.ParallelTriangleRenderer.init(ctx.allocator, &jobs);
    rd = j3d.TriangleRenderer.init(ctx.allocator);

    camera = j3d.Camera.fromPositionAndTarget(
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
    cube = j3d.zmesh.Shape.initCube();
    cube.computeNormals();
    cube.texcoords = texcoords[0..];
    aabb = cube.computeAabb();

    tex = try jok.utils.gfx.createTextureFromFile(
        ctx.renderer,
        "assets/images/image5.jpg",
        .static,
        false,
    );

    var rng = std.rand.DefaultPrng.init(@intCast(u64, std.time.timestamp()));
    translations = std.ArrayList(zmath.Mat).init(ctx.allocator);
    rotation_axises = std.ArrayList(zmath.Vec).init(ctx.allocator);
    var i: u32 = 0;
    while (i < 1000) : (i += 1) {
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

    try ctx.renderer.setColorRGB(77, 77, 77);
}

pub fn event(ctx: *jok.Context, e: sdl.Event) !void {
    _ = ctx;
    _ = e;
}

pub fn update(ctx: *jok.Context) !void {
    // camera movement
    const distance = ctx.delta_tick * 2;
    const angle = std.math.pi * ctx.delta_tick / 2;
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
        camera.rotate(0, -angle);
    }
    if (ctx.isKeyPressed(.right)) {
        camera.rotate(0, angle);
    }
    if (ctx.isKeyPressed(.up)) {
        camera.rotate(angle, 0);
    }
    if (ctx.isKeyPressed(.down)) {
        camera.rotate(-angle, 0);
    }
}

pub fn draw(ctx: *jok.Context) !void {
    if (parallel_rendering) {
        prd.clear(true);
        for (translations.items) |tr, i| {
            const model = zmath.mul(
                zmath.translation(-0.5, -0.5, -0.5),
                zmath.mul(
                    zmath.mul(
                        zmath.scaling(0.1, 0.1, 0.1),
                        zmath.matFromAxisAngle(rotation_axises.items[i], std.math.pi / 3.0 * @floatCast(f32, ctx.tick)),
                    ),
                    tr,
                ),
            );
            try prd.addShapeData(
                ctx.renderer,
                model,
                camera,
                cube.indices,
                cube.positions,
                cube.normals.?,
                null,
                cube.texcoords.?,
                .{ .aabb = aabb },
            );
        }
        try prd.draw(ctx.renderer, tex);
    } else {
        rd.clear(true);
        for (translations.items) |tr, i| {
            const model = zmath.mul(
                zmath.translation(-0.5, -0.5, -0.5),
                zmath.mul(
                    zmath.mul(
                        zmath.scaling(0.1, 0.1, 0.1),
                        zmath.matFromAxisAngle(rotation_axises.items[i], std.math.pi / 3.0 * @floatCast(f32, ctx.tick)),
                    ),
                    tr,
                ),
            );
            try rd.addShapeData(
                ctx.renderer,
                model,
                camera,
                cube.indices,
                cube.positions,
                cube.normals.?,
                null,
                cube.texcoords.?,
                .{ .aabb = aabb },
            );
        }
        try rd.draw(ctx.renderer, tex);
    }

    _ = try font.debugDraw(
        ctx.renderer,
        .{ .pos = .{ .x = 200, .y = 10 } },
        "Press WSAD and up/down/left/right to move camera around the view",
        .{},
    );

    imgui.sdl.newFrame(ctx.*);
    defer imgui.sdl.draw();

    if (imgui.begin("Control Panel", .{})) {
        _ = imgui.checkbox("parallel rendering", .{ .v = &parallel_rendering });
    }
    imgui.end();
}

pub fn quit(ctx: *jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});

    jobs.deinit();
    prd.deinit();
    rd.deinit();
    cube.deinit();
    translations.deinit();
    rotation_axises.deinit();
}
