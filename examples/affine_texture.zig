const std = @import("std");
const assert = std.debug.assert;
const math = std.math;
const builtin = @import("builtin");
const sdl = @import("sdl");
const jok = @import("jok");
const imgui = jok.imgui;
const zmath = jok.zmath;
const j3d = jok.j3d;
const Camera = j3d.Camera;

pub const jok_window_resizable = true;
pub const jok_window_width: u32 = 800;
pub const jok_window_height: u32 = 600;

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
}

pub fn draw(ctx: jok.Context) !void {
    imgui.sdl.newFrame(ctx);
    defer imgui.sdl.draw();

    if (imgui.begin("Control Panel", .{})) {
        _ = imgui.checkbox("wireframe", .{ .v = &wireframe });
        _ = imgui.inputInt("slices", .{ .v = &slices });
        _ = imgui.inputInt("stacks", .{ .v = &stacks });
        slices = math.clamp(slices, 1, 100);
        stacks = math.clamp(stacks, 1, 100);
    }
    imgui.end();

    const mat = zmath.mul(
        zmath.mul(
            zmath.rotationX(math.pi * 0.5),
            zmath.translation(-0.5, -1.1, -0.5),
        ),
        zmath.scaling(10, 1, 10),
    );
    const plane_opt = j3d.PlaneDrawOption{
        .rdopt = .{
            .cull_faces = false,
            .texture = tex,
        },
        .slices = @intCast(u32, slices),
        .stacks = @intCast(u32, stacks),
    };

    try j3d.begin(.{ .camera = camera });
    try j3d.addPlane(mat, plane_opt);
    try j3d.end();

    try j3d.begin(.{
        .camera = camera,
        .wireframe_color = sdl.Color.green,
    });
    try j3d.addPlane(mat, plane_opt);
    try j3d.end();
}

pub fn quit(ctx: jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});
}
