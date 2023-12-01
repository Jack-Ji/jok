const std = @import("std");
const math = std.math;
const jok = @import("jok");
const sdl = jok.sdl;
const j2d = jok.j2d;
const j3d = jok.j3d;
const zmath = jok.zmath;
const font = jok.font;
const imgui = jok.imgui;

var rand: std.rand.DefaultPrng = undefined;
var sheet: *j2d.SpriteSheet = undefined;
var ps: *j3d.ParticleSystem = undefined;
var camera: j3d.Camera = undefined;
var sort_by_depth: bool = false;

// fire effect
const emitter1 = j3d.ParticleSystem.Effect.FireEmitter(
    20,
    50,
    3,
    sdl.Color.red,
    sdl.Color.yellow,
    1.75,
);
const emitter2 = j3d.ParticleSystem.Effect.FireEmitter(
    20,
    50,
    3,
    sdl.Color.black,
    sdl.Color.white,
    2.75,
);

pub fn init(ctx: jok.Context) !void {
    std.log.info("game init", .{});

    rand = std.rand.DefaultPrng.init(@intCast(std.time.timestamp()));
    sheet = try j2d.SpriteSheet.create(
        ctx,
        &.{
            .{
                .name = "white-circle",
                .image = .{
                    .file_path = "assets/images/white-circle.png",
                },
            },
            .{
                .name = "ogre",
                .image = .{
                    .file_path = "assets/images/ogre.png",
                },
            },
        },
        500,
        500,
        1,
        false,
    );
    ps = try j3d.ParticleSystem.create(ctx.allocator());
    camera = j3d.Camera.fromPositionAndTarget(
        .{
            .perspective = .{
                .fov = jok.utils.math.degreeToRadian(45),
                .aspect_ratio = ctx.getAspectRatio(),
                .near = 0.1,
                .far = 1000,
            },
        },
        .{ 150, 150, 150 },
        .{ 0, 0, 0 },
    );
    emitter1.draw_data = j3d.ParticleSystem.DrawData.fromSprite(
        sheet.getSpriteByName("white-circle").?,
        .{ .x = 0.2, .y = 0.2 },
    );
    emitter2.draw_data = j3d.ParticleSystem.DrawData.fromSprite(
        sheet.getSpriteByName("ogre").?,
        .{ .x = 0.2, .y = 0.2 },
    );
    try ps.addEffect(
        rand.random(),
        5000,
        emitter1.emit,
        j3d.Vector.new(0, 0, 0),
        60,
        40,
        0.016,
    );
    try ps.addEffect(
        rand.random(),
        5000,
        emitter2.emit,
        j3d.Vector.new(60, 0, 0),
        60,
        10,
        0.016,
    );
}

pub fn event(ctx: jok.Context, e: sdl.Event) !void {
    _ = ctx;
    _ = e;
}

pub fn update(ctx: jok.Context) !void {
    const distance = ctx.deltaSeconds() * 100;
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
        camera.rotateBy(0, -std.math.pi / 180.0);
    }
    if (ctx.isKeyPressed(.right)) {
        camera.rotateBy(0, std.math.pi / 180.0);
    }
    if (ctx.isKeyPressed(.up)) {
        camera.rotateBy(std.math.pi / 180.0, 0);
    }
    if (ctx.isKeyPressed(.down)) {
        camera.rotateBy(-std.math.pi / 180.0, 0);
    }

    ps.update(ctx.deltaSeconds());
}

pub fn draw(ctx: jok.Context) !void {
    ctx.displayStats(.{});

    if (imgui.begin("Control", .{})) {
        _ = imgui.checkbox("sort by depth", .{ .v = &sort_by_depth });
    }
    imgui.end();

    try j3d.begin(.{
        .camera = camera,
        .triangle_sort = if (sort_by_depth) .simple else .none,
    });
    try j3d.plane(
        zmath.mul(
            zmath.mul(
                zmath.rotationX(-math.pi * 0.5),
                zmath.translation(-0.5, -1.1, 0.5),
            ),
            zmath.scaling(200, 1, 200),
        ),
        .{
            .rdopt = .{
                .color = sdl.Color.rgba(100, 100, 100, 200),
                .lighting = .{},
            },
        },
    );
    try j3d.effects(ps);
    try j3d.end();

    try font.debugDraw(
        ctx,
        .{ .pos = .{ .x = 20, .y = 10 } },
        "Press WSAD and up/down/left/right to move camera around the view",
        .{},
    );
    try font.debugDraw(
        ctx,
        .{ .pos = .{ .x = 20, .y = 28 } },
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
    ps.destroy();
    sheet.destroy();
}
