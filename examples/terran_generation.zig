const std = @import("std");
const assert = std.debug.assert;
const math = std.math;
const builtin = @import("builtin");
const sdl = @import("sdl");
const jok = @import("jok");
const imgui = jok.deps.imgui;
const zmath = jok.zmath;
const znoise = jok.znoise;
const gfx = jok.gfx.@"3d";
const zmesh = gfx.zmesh;
const primitive = gfx.primitive;
const Camera = gfx.Camera;
const Renderer = gfx.Renderer;

pub const jok_window_resizable = true;
pub const jok_window_width = 1600;
pub const jok_window_height = 900;

var wireframe: bool = false;
var sun_pos: [3]f32 = .{ 0, 10, 0 };
var sun_color: [3]f32 = .{ 1, 1, 1 };
var camera: Camera = undefined;
var shape: zmesh.Shape = undefined;
var rd: Renderer = undefined;

var noise_gen = znoise.FnlGenerator{
    .fractal_type = .fbm,
    .frequency = 2.0,
    .octaves = 5,
    .lacunarity = 2.02,
};
fn uvToPos(uv: *const [2]f32, position: *[3]f32, userdata: ?*anyopaque) callconv(.C) void {
    _ = userdata;
    position[0] = uv[0];
    position[1] = 0.25 * noise_gen.noise2(uv[0], uv[1]);
    position[2] = uv[1];
}

pub fn init(ctx: *jok.Context) anyerror!void {
    std.log.info("game init", .{});

    camera = Camera.fromPositionAndTarget(
        .{
            .perspective = .{
                .fov = jok.gfx.utils.degreeToRadian(70),
                .aspect_ratio = ctx.getAspectRatio(),
                .near = 0.1,
                .far = 100,
            },
        },
        [_]f32{ 15, 15, 15 },
        [_]f32{ 0, 0, 0 },
        null,
    );
    shape = zmesh.Shape.initParametric(
        uvToPos,
        50,
        50,
        null,
    );
    shape.translate(-0.5, -0.0, -0.5);
    shape.invert(0, 0);
    shape.scale(20, 20, 20);
    shape.computeNormals();
    rd = Renderer.init(ctx.allocator);

    try imgui.init(ctx);
    try primitive.init(ctx);
    try ctx.renderer.setColorRGB(77, 77, 77);
    try ctx.renderer.setDrawBlendMode(.blend);
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
        _ = imgui.processEvent(e);

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

    imgui.beginFrame();
    if (imgui.begin("Control Panel", null, null)) {
        _ = imgui.checkbox("wireframe", &wireframe);
        _ = imgui.dragFloat3("sun position", &sun_pos, .{ .v_max = 20, .v_speed = 0.1 });
        _ = imgui.dragFloat3("sun color", &sun_color, .{ .v_max = 1, .v_speed = 0.1 });
    }
    imgui.end();
    imgui.endFrame();

    rd.clear(true);
    try rd.appendMesh(
        ctx.renderer,
        zmath.identity(),
        camera,
        shape.indices,
        shape.positions,
        shape.normals.?,
        null,
        null,
        .{
            .lighting = .{
                .sun_pos = sun_pos,
                .sun_color = .{
                    .r = @floatToInt(u8, sun_color[0] * 255),
                    .g = @floatToInt(u8, sun_color[1] * 255),
                    .b = @floatToInt(u8, sun_color[2] * 255),
                    .a = 255,
                },
            },
            .cull_faces = false,
        },
    );
    if (wireframe) {
        try rd.drawWireframe(ctx.renderer, sdl.Color.green);
    } else {
        try rd.draw(ctx.renderer, null);
    }

    primitive.clear();
    try primitive.drawSubdividedSphere(
        zmath.mul(
            zmath.scaling(0.2, 0.2, 0.2),
            zmath.translation(sun_pos[0], sun_pos[1], sun_pos[2]),
        ),
        camera,
        .{
            .common = .{
                .color = sdl.Color.rgb(
                    @floatToInt(u8, sun_color[0] * 255),
                    @floatToInt(u8, sun_color[1] * 255),
                    @floatToInt(u8, sun_color[2] * 255),
                ),
            },
        },
    );
    try primitive.flush(.{});
}

pub fn quit(ctx: *jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});

    rd.deinit();
    shape.deinit();
    imgui.deinit();
    primitive.deinit();
}
