const std = @import("std");
const assert = std.debug.assert;
const math = std.math;
const builtin = @import("builtin");
const sdl = @import("sdl");
const jok = @import("jok");
const imgui = jok.deps.imgui;
const zmath = jok.zmath;
const j3d = jok.j3d;
const primitive = j3d.primitive;
const Camera = j3d.Camera;

pub const jok_window_resizable = true;
pub const jok_window_width: u32 = 1600;
pub const jok_window_height: u32 = 900;

var wireframe: bool = true;
var camera: Camera = undefined;
var slices: u32 = 1;
var stacks: u32 = 1;
var tex: sdl.Texture = undefined;

pub fn init(ctx: *jok.Context) anyerror!void {
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
        ctx.renderer,
        "assets/images/image5.jpg",
        .static,
        true,
    );

    try ctx.renderer.setColorRGB(77, 77, 77);
    try ctx.renderer.setDrawBlendMode(.blend);
}

pub fn event(ctx: *jok.Context, e: sdl.Event) anyerror!void {
    _ = ctx;
    _ = e;
}

pub fn update(ctx: *jok.Context) anyerror!void {
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

    imgui.beginFrame();
    defer imgui.endFrame();
    if (imgui.begin("Control Panel", null, null)) {
        _ = imgui.checkbox("wireframe", &wireframe);
        _ = imgui.inputInt("slices", @ptrCast(*c_int, &slices), .{});
        _ = imgui.inputInt("stacks", @ptrCast(*c_int, &stacks), .{});
        slices = math.clamp(slices, 1, 100);
        stacks = math.clamp(stacks, 1, 100);
    }
    imgui.end();

    primitive.clear();
    try primitive.addPlane(
        zmath.mul(
            zmath.mul(
                zmath.rotationX(math.pi * 0.5),
                zmath.translation(-0.5, -1.1, -0.5),
            ),
            zmath.scaling(10, 1, 10),
        ),
        camera,
        .{
            .common = .{
                .renderer = ctx.renderer,
                .cull_faces = false,
            },
            .slices = slices,
            .stacks = stacks,
        },
    );
    try primitive.render(ctx.renderer, .{ .texture = tex });
    if (wireframe) try primitive.render(ctx.renderer, .{
        .wireframe = true,
        .wireframe_color = .{ .r = 0, .g = 255, .b = 0, .a = 100 },
    });
}

pub fn quit(ctx: *jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});
}
