const std = @import("std");
const math = std.math;
const sdl = @import("sdl");
const jok = @import("jok");
const j2d = jok.j2d;
const j3d = jok.j3d;
const zmath = jok.zmath;
const font = jok.font;
const imgui = jok.imgui;

var rand: std.rand.DefaultPrng = undefined;
var tex0: sdl.Texture = undefined;
var tex1: sdl.Texture = undefined;
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
    2.75,
);
const emitter2 = j3d.ParticleSystem.Effect.FireEmitter(
    20,
    50,
    3,
    sdl.Color.black,
    sdl.Color.white,
    2.75,
);

pub fn init(ctx: *jok.Context) !void {
    std.log.info("game init", .{});

    rand = std.rand.DefaultPrng.init(@intCast(u64, std.time.timestamp()));
    tex0 = try jok.utils.gfx.createTextureFromFile(
        ctx.renderer,
        "assets/images/white-circle.png",
        .static,
        false,
    );
    tex1 = try jok.utils.gfx.createTextureFromFile(
        ctx.renderer,
        "assets/images/ogre.png",
        .static,
        false,
    );
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
    emitter1.draw_data = .{
        .sprite = .{
            .size = .{ .x = 5, .y = 5 },
            .texture = tex0,
        },
    };
    emitter2.draw_data = .{
        .sprite = .{
            .size = .{ .x = 5, .y = 5 },
            .texture = tex1,
        },
    };
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
        10000,
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
    const distance = ctx.delta_seconds * 100;
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

    ps.update(ctx.delta_seconds);
}

pub fn draw(ctx: *jok.Context) !void {
    try j3d.begin(.{ .camera = camera, .sort_by_depth = sort_by_depth });
    try j3d.addPlane(
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
    try j3d.addEffects(ps);
    try j3d.end();

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

    imgui.sdl.newFrame(ctx.*);
    defer imgui.sdl.draw();
    if (imgui.begin("Control", .{})) {
        _ = imgui.checkbox("sort by depth", .{ .v = &sort_by_depth });
    }
    imgui.end();
}

pub fn quit(ctx: *jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});
    ps.destroy();
}
