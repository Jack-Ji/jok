const std = @import("std");
const jok = @import("jok");
const sdl = jok.sdl;
const imgui = jok.imgui;
const font = jok.font;
const zmath = jok.zmath;
const zmesh = jok.zmesh;
const j2d = jok.j2d;
const j3d = jok.j3d;

var lighting: bool = true;
var wireframe: bool = false;
var animation_name1: ?[]const u8 = null;
var animation_name2: ?[]const u8 = null;
var animation_name3: ?[]const u8 = null;
var animation_playtime1: f32 = 0.0;
var animation_playtime2: f32 = 0.0;
var animation_playtime3: f32 = 0.0;
var camera: j3d.Camera = undefined;
var mesh1: *j3d.Mesh = undefined;
var mesh2: *j3d.Mesh = undefined;
var mesh3: *j3d.Mesh = undefined;

pub fn init(ctx: jok.Context) !void {
    std.log.info("game init", .{});

    camera = j3d.Camera.fromPositionAndTarget(
        .{
            .perspective = .{
                .fov = jok.utils.math.degreeToRadian(70),
                .aspect_ratio = ctx.getAspectRatio(),
                .near = 0.1,
                .far = 1000,
            },
        },
        [_]f32{ 7, 4.1, 7 },
        [_]f32{ 0, 0, 0 },
        null,
    );

    mesh1 = try j3d.Mesh.fromGltf(
        ctx.allocator(),
        ctx.renderer(),
        "assets/models/CesiumMan.glb",
        .{},
    );
    mesh2 = try j3d.Mesh.fromGltf(
        ctx.allocator(),
        ctx.renderer(),
        "assets/models/RiggedSimple.glb",
        .{},
    );
    mesh3 = try j3d.Mesh.fromGltf(
        ctx.allocator(),
        ctx.renderer(),
        "assets/models/Fox/Fox.gltf",
        .{},
    );

    try ctx.renderer().setColorRGB(77, 77, 77);
    ctx.refresh();
}

pub fn event(ctx: jok.Context, e: sdl.Event) !void {
    _ = ctx;
    _ = e;
}

pub fn update(ctx: jok.Context) !void {
    // camera movement
    const distance = ctx.deltaSeconds() * 5;
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

    var buf: [256]u8 = undefined;
    if (imgui.begin("Control Panel", .{})) {
        _ = imgui.checkbox("lighting", .{ .v = &lighting });
        _ = imgui.checkbox("wireframe", .{ .v = &wireframe });

        imgui.separatorText("Play Animation");

        if (imgui.beginCombo("CesiumMan", .{
            .preview_value = try std.fmt.bufPrintZ(&buf, "{s}", .{
                animation_name1 orelse "none",
            }),
        })) {
            if (imgui.selectable("none", .{ .selected = animation_name1 == null })) {
                animation_name1 = null;
            }
            var it = mesh1.animations.keyIterator();
            while (it.next()) |name| {
                if (imgui.selectable(
                    try std.fmt.bufPrintZ(&buf, "{s}", .{name.*}),
                    .{
                        .selected = std.mem.eql(u8, name.*, animation_name1 orelse "none"),
                    },
                )) {
                    animation_name1 = name.*;
                }
            }
            imgui.endCombo();
        }

        if (imgui.beginCombo("RiggedSimple", .{
            .preview_value = try std.fmt.bufPrintZ(&buf, "{s}", .{
                animation_name2 orelse "none",
            }),
        })) {
            if (imgui.selectable("none", .{ .selected = animation_name2 == null })) {
                animation_name2 = null;
            }
            var it = mesh2.animations.keyIterator();
            while (it.next()) |name| {
                if (imgui.selectable(
                    try std.fmt.bufPrintZ(&buf, "{s}", .{name.*}),
                    .{
                        .selected = std.mem.eql(u8, name.*, animation_name2 orelse "none"),
                    },
                )) {
                    animation_name2 = name.*;
                }
            }
            imgui.endCombo();
        }

        if (imgui.beginCombo("Fox", .{
            .preview_value = try std.fmt.bufPrintZ(&buf, "{s}", .{
                animation_name3 orelse "none",
            }),
        })) {
            if (imgui.selectable("none", .{ .selected = animation_name3 == null })) {
                animation_name3 = null;
            }
            var it = mesh3.animations.keyIterator();
            while (it.next()) |name| {
                if (imgui.selectable(
                    try std.fmt.bufPrintZ(&buf, "{s}", .{name.*}),
                    .{
                        .selected = std.mem.eql(u8, name.*, animation_name3 orelse "none"),
                    },
                )) {
                    animation_name3 = name.*;
                }
            }
            imgui.endCombo();
        }
    }
    imgui.end();

    if (animation_name1) |a| {
        const duration = mesh1.getAnimation(a).?.duration;
        animation_playtime1 += ctx.deltaSeconds();
        if (animation_playtime1 > duration) {
            animation_playtime1 -= duration;
        }
    }
    if (animation_name2) |a| {
        const duration = mesh2.getAnimation(a).?.duration;
        animation_playtime2 += ctx.deltaSeconds();
        if (animation_playtime2 > duration) {
            animation_playtime2 -= duration;
        }
    }
    if (animation_name3) |a| {
        const duration = mesh3.getAnimation(a).?.duration;
        animation_playtime3 += ctx.deltaSeconds();
        if (animation_playtime3 > duration) {
            animation_playtime3 -= duration;
        }
    }
}

pub fn draw(ctx: jok.Context) !void {
    try j3d.begin(.{
        .camera = camera,
        .sort_by_depth = true,
        .wireframe_color = if (wireframe) sdl.Color.green else null,
    });
    try j3d.addMesh(
        mesh1,
        zmath.scalingV(zmath.f32x4s(3)),
        .{
            .rdopt = .{
                .lighting = if (lighting) .{} else null,
            },
            .animation_name = animation_name1,
            .animation_playtime = animation_playtime1,
        },
    );
    try j3d.addMesh(
        mesh2,
        zmath.translation(-4, 0, 0),
        .{
            .rdopt = .{
                .color = sdl.Color.cyan,
                .lighting = if (lighting) .{} else null,
            },
            .animation_name = animation_name2,
            .animation_playtime = animation_playtime2,
        },
    );
    try j3d.addMesh(
        mesh3,
        zmath.mul(
            zmath.rotationY(-std.math.pi / 6.0),
            zmath.mul(
                zmath.scalingV(zmath.f32x4s(0.03)),
                zmath.translation(4, 0, 0),
            ),
        ),
        .{
            .rdopt = .{
                .lighting = if (lighting) .{} else null,
            },
            .animation_name = animation_name3,
            .animation_playtime = animation_playtime3,
        },
    );
    try j3d.addAxises(.{ .radius = 0.01, .length = 0.5 });
    try j3d.end();

    _ = try font.debugDraw(
        ctx,
        .{ .pos = .{ .x = 200, .y = 10 } },
        "Press WSAD and up/down/left/right to move camera around the view",
        .{},
    );
    _ = try font.debugDraw(
        ctx,
        .{ .pos = .{ .x = 200, .y = 28 } },
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
    mesh1.destroy();
    mesh2.destroy();
    mesh3.destroy();
}
