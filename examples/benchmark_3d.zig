const std = @import("std");
const jok = @import("jok");
const sdl = jok.sdl;
const font = jok.font;
const j3d = jok.j3d;
const zmath = jok.zmath;
const zmesh = jok.zmesh;

pub const jok_fps_limit: jok.config.FpsLimit = .none;
pub const jok_window_resizable = true;

var camera: j3d.Camera = undefined;
var cube: zmesh.Shape = undefined;
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

pub fn init(ctx: jok.Context) !void {
    std.log.info("game init", .{});

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
    );
    cube = zmesh.Shape.initCube();
    cube.computeNormals();
    cube.texcoords = texcoords[0..];
    aabb = cube.computeAabb();

    tex = try jok.utils.gfx.createTextureFromFile(
        ctx.renderer(),
        "assets/images/image5.jpg",
        .static,
        false,
    );

    var rng = std.rand.DefaultPrng.init(@intCast(std.time.timestamp()));
    translations = std.ArrayList(zmath.Mat).init(ctx.allocator());
    rotation_axises = std.ArrayList(zmath.Vec).init(ctx.allocator());
    var i: u32 = 0;
    while (i < 5000) : (i += 1) {
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

    try ctx.renderer().setColorRGB(77, 77, 77);
}

pub fn event(ctx: jok.Context, e: sdl.Event) !void {
    _ = ctx;
    _ = e;
}

pub fn update(ctx: jok.Context) !void {
    // camera movement
    const distance = ctx.deltaSeconds() * 2;
    const angle = std.math.pi * ctx.deltaSeconds() / 2;
    if (ctx.isKeyPressed(.w)) {
        camera.moveBy(.forward, distance);
    }
    if (ctx.isKeyPressed(.s)) {
        camera.moveBy(.backward, distance);
    }
    if (ctx.isKeyPressed(.a)) {
        camera.moveBy(.left, distance);
    }
    if (ctx.isKeyPressed(.d)) {
        camera.moveBy(.right, distance);
    }
    if (ctx.isKeyPressed(.left)) {
        camera.rotateBy(0, -angle);
    }
    if (ctx.isKeyPressed(.right)) {
        camera.rotateBy(0, angle);
    }
    if (ctx.isKeyPressed(.up)) {
        camera.rotateBy(angle, 0);
    }
    if (ctx.isKeyPressed(.down)) {
        camera.rotateBy(-angle, 0);
    }
}

pub fn draw(ctx: jok.Context) !void {
    try ctx.renderer().clear();

    ctx.displayStats(.{});

    try j3d.begin(.{ .camera = camera, .triangle_sort = .simple });
    for (translations.items, 0..) |tr, i| {
        const model = zmath.mul(
            zmath.translation(-0.5, -0.5, -0.5),
            zmath.mul(
                zmath.mul(
                    zmath.scaling(0.1, 0.1, 0.1),
                    zmath.matFromAxisAngle(
                        rotation_axises.items[i],
                        std.math.pi / 3.0 * ctx.seconds(),
                    ),
                ),
                tr,
            ),
        );
        try j3d.shape(
            cube,
            model,
            aabb,
            .{ .texture = tex },
        );
    }
    try j3d.end();

    try font.debugDraw(
        ctx,
        .{ .pos = .{ .x = 20, .y = 10 } },
        "Press WSAD and up/down/left/right to move camera around the view",
        .{},
    );
}

pub fn quit(ctx: jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});

    cube.deinit();
    translations.deinit();
    rotation_axises.deinit();
}
