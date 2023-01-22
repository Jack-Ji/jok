const std = @import("std");
const math = std.math;
const sdl = @import("sdl");
const jok = @import("jok");
const j2d = jok.j2d;
const j3d = jok.j3d;
const font = jok.font;

var rand: std.rand.DefaultPrng = undefined;
var sheet: *j2d.SpriteSheet = undefined;
var rd: *j3d.TriangleRenderer = undefined;
var ps: *j3d.ParticleSystem = undefined;
var camera: j3d.Camera = undefined;

// fire effect
const emitter1 = j3d.ParticleSystem.Effect.FireEmitter(
    20,
    100,
    3,
    sdl.Color.red,
    sdl.Color.yellow,
    2.75,
);
const emitter2 = j3d.ParticleSystem.Effect.FireEmitter(
    20,
    100,
    3,
    sdl.Color.red,
    sdl.Color.green,
    2.75,
);

pub fn init(ctx: *jok.Context) !void {
    std.log.info("game init", .{});

    rand = std.rand.DefaultPrng.init(@intCast(u64, std.time.timestamp()));
    sheet = try j2d.SpriteSheet.create(
        ctx,
        &[_]j2d.SpriteSheet.ImageSource{
            .{
                .name = "particle",
                .image = .{
                    .file_path = "assets/images/white-circle.png",
                },
            },
        },
        100,
        100,
        1,
        false,
    );
    rd = try j3d.TriangleRenderer.create(ctx.allocator);
    ps = try j3d.ParticleSystem.create(ctx.allocator);
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
        null,
    );
    const sp = try sheet.getSpriteByName("particle");
    emitter1.draw_data = .{
        .sprite = .{
            .size = .{ .x = 5, .y = 5 },
            .uv = .{ sp.uv0, sp.uv1 },
            .texture = sheet.tex,
        },
    };
    emitter2.draw_data = emitter1.draw_data;
    try ps.addEffect(
        rand.random(),
        8000,
        emitter1.emit,
        j3d.Vector.new(0, 0, 0),
        60,
        40,
        0.016,
    );
    try ps.addEffect(
        rand.random(),
        2000,
        emitter2.emit,
        j3d.Vector.new(60, 0, 0),
        60,
        10,
        0.016,
    );
}

pub fn event(ctx: *jok.Context, e: sdl.Event) !void {
    _ = ctx;
    _ = e;
}

pub fn update(ctx: *jok.Context) !void {
    const distance = ctx.delta_tick * 100;
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

    ps.update(ctx.delta_tick);
}

pub fn draw(ctx: *jok.Context) !void {
    j3d.primitive.clear(.{});
    try j3d.primitive.addPlane(
        j3d.zmath.mul(
            j3d.zmath.mul(
                j3d.zmath.rotationX(-math.pi * 0.5),
                j3d.zmath.translation(-0.5, -1.1, 0.5),
            ),
            j3d.zmath.scaling(200, 1, 200),
        ),
        camera,
        .{
            .common = .{
                .color = sdl.Color.rgba(100, 100, 100, 200),
                .lighting = .{},
            },
        },
    );
    try j3d.primitive.draw();

    rd.clear(true);
    try ps.draw(ctx.renderer, rd, camera);
    try rd.draw(ctx.renderer);

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
    sheet.destroy();
    rd.destroy();
    ps.destroy();
}
