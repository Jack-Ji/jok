const std = @import("std");
const assert = std.debug.assert;
const math = std.math;
const builtin = @import("builtin");
const jok = @import("jok");
const physfs = jok.physfs;
const imgui = jok.imgui;
const zmath = jok.zmath;
const j3d = jok.j3d;
const Camera = j3d.Camera;

pub const jok_window_resizable = true;

var wireframe: bool = true;
var camera: Camera = undefined;
var slices: i32 = 1;
var stacks: i32 = 1;
var tex: jok.Texture = undefined;

pub fn init(ctx: jok.Context) !void {
    std.log.info("game init", .{});

    try physfs.mount("assets", "", true);

    camera = Camera.fromPositionAndTarget(
        .{
            .perspective = .{
                .fov = std.math.degreesToRadians(70),
                .aspect_ratio = ctx.getAspectRatio(),
                .near = 0.1,
                .far = 100,
            },
        },
        [_]f32{ 0, 7, -8 },
        [_]f32{ 0, 0, 0 },
    );

    tex = try ctx.renderer().createTextureFromFile(
        ctx.allocator(),
        "images/image5.jpg",
        .static,
        true,
    );
}

pub fn event(ctx: jok.Context, e: jok.Event) !void {
    _ = ctx;
    _ = e;
}

pub fn update(ctx: jok.Context) !void {
    // camera movement
    const distance = ctx.deltaSeconds() * 2;
    const kbd = jok.io.getKeyboardState();
    if (kbd.isPressed(.w)) {
        camera.moveBy(.forward, distance);
    }
    if (kbd.isPressed(.s)) {
        camera.moveBy(.backward, distance);
    }
    if (kbd.isPressed(.a)) {
        camera.moveBy(.left, distance);
    }
    if (kbd.isPressed(.d)) {
        camera.moveBy(.right, distance);
    }
    if (kbd.isPressed(.left)) {
        camera.rotateBy(0, -std.math.pi / 180.0);
    }
    if (kbd.isPressed(.right)) {
        camera.rotateBy(0, std.math.pi / 180.0);
    }
    if (kbd.isPressed(.up)) {
        camera.rotateBy(std.math.pi / 180.0, 0);
    }
    if (kbd.isPressed(.down)) {
        camera.rotateBy(-std.math.pi / 180.0, 0);
    }
}

pub fn draw(ctx: jok.Context) !void {
    try ctx.renderer().clear(jok.Color.rgb(77, 77, 77));

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
    const plane_opt = j3d.PlaneOption{
        .rdopt = .{
            .cull_faces = false,
            .texture = tex,
        },
        .slices = @intCast(slices),
        .stacks = @intCast(stacks),
    };

    j3d.begin(.{ .camera = camera });
    try j3d.plane(mat, plane_opt);
    j3d.end();

    if (wireframe) {
        j3d.begin(.{
            .camera = camera,
            .wireframe_color = jok.Color.green,
        });
        try j3d.plane(mat, plane_opt);
        j3d.end();
    }
}

pub fn quit(ctx: jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});
}
