const std = @import("std");
const assert = std.debug.assert;
const math = std.math;
const builtin = @import("builtin");
const jok = @import("jok");
const sdl = jok.sdl;
const imgui = jok.imgui;
const zmath = jok.zmath;
const j3d = jok.j3d;
const Camera = j3d.Camera;

pub const jok_window_resizable = true;

var wireframe: bool = true;
var camera: Camera = undefined;
var slices: i32 = 1;
var stacks: i32 = 1;
var tex: sdl.Texture = undefined;

pub fn init(ctx: jok.Context) !void {
    std.log.info("game init", .{});

    camera = Camera.fromPositionAndTarget(
        .{
            .perspective = .{
                .fov = jok.utils.math.degreeToRadian(70),
                .aspect_ratio = ctx.getAspectRatio(),
                .near = 0.1,
                .far = 100,
            },
        },
        [_]f32{ 0, 7, -8 },
        [_]f32{ 0, 0, 0 },
        null,
    );

    tex = try jok.utils.gfx.createTextureFromFile(
        ctx.renderer(),
        "assets/images/image5.jpg",
        .static,
        true,
    );

    try ctx.renderer().setColorRGB(77, 77, 77);
}

pub fn event(ctx: jok.Context, e: sdl.Event) !void {
    _ = ctx;
    _ = e;
}

pub fn update(ctx: jok.Context) !void {
    // camera movement
    const distance = ctx.deltaSeconds() * 2;
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

    if (imgui.begin("Control Panel", .{})) {
        _ = imgui.checkbox("wireframe", .{ .v = &wireframe });
        _ = imgui.inputInt("slices", .{ .v = &slices });
        _ = imgui.inputInt("stacks", .{ .v = &stacks });
        slices = math.clamp(slices, 1, 100);
        stacks = math.clamp(stacks, 1, 100);
    }
    imgui.end();
}

pub fn draw(ctx: jok.Context) !void {
    _ = ctx;

    const mat = zmath.mul(
        zmath.mul(
            zmath.rotationX(math.pi * 0.5),
            zmath.translation(-0.5, -1.1, -0.5),
        ),
        zmath.scaling(10, 1, 10),
    );
    const plane_opt = j3d.PlaneOption{
        .rdopt = .{
            .cull_faces = false,
            .texture = tex,
        },
        .slices = @intCast(slices),
        .stacks = @intCast(stacks),
    };

    try j3d.begin(.{ .camera = camera });
    try j3d.plane(mat, plane_opt);
    try j3d.end();

    if (wireframe) {
        try j3d.begin(.{
            .camera = camera,
            .wireframe_color = sdl.Color.green,
        });
        try j3d.plane(mat, plane_opt);
        try j3d.end();
    }
}

pub fn quit(ctx: jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});
}
