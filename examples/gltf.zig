const std = @import("std");
const jok = @import("jok");
const sdl = jok.sdl;
const imgui = jok.imgui;
const font = jok.font;
const zmath = jok.zmath;
const zmesh = jok.zmesh;
const j3d = jok.j3d;

var lighting: bool = true;
var wireframe: bool = false;
var camera: j3d.Camera = undefined;
var mesh1: *j3d.Mesh = undefined;
var mesh2: *j3d.Mesh = undefined;
var mesh3: *j3d.Mesh = undefined;
var animation1_1: *j3d.Animation = undefined;
var animation2_1: *j3d.Animation = undefined;
var animation3_1: *j3d.Animation = undefined;
var animation3_2: *j3d.Animation = undefined;
var animation3_3: *j3d.Animation = undefined;
var animation1: ?*j3d.Animation = null;
var animation2: ?*j3d.Animation = null;
var animation3: ?*j3d.Animation = null;
var animation3_old: ?*j3d.Animation = null;
var animation_playtime1: f32 = 0.0;
var animation_playtime2: f32 = 0.0;
var animation_playtime3: f32 = 0.0;
var animation_transition3: f32 = 0.0;

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
    animation1_1 = try j3d.Animation.create(ctx.allocator(), mesh1.getAnimation("default").?);
    animation2_1 = try j3d.Animation.create(ctx.allocator(), mesh2.getAnimation("default").?);
    animation3_1 = try j3d.Animation.create(ctx.allocator(), mesh3.getAnimation("Walk").?);
    animation3_2 = try j3d.Animation.create(ctx.allocator(), mesh3.getAnimation("Survey").?);
    animation3_3 = try j3d.Animation.create(ctx.allocator(), mesh3.getAnimation("Run").?);

    try ctx.renderer().setColorRGB(77, 77, 77);
}

pub fn event(ctx: jok.Context, e: sdl.Event) !void {
    if (imgui.io.getWantCaptureMouse()) return;

    switch (e) {
        .mouse_motion => |me| {
            const mouse_state = ctx.getMouseState();
            if (!mouse_state.buttons.getPressed(.left)) {
                return;
            }

            camera.rotateAroundBy(
                null,
                @as(f32, @floatFromInt(me.delta_x)) * 0.01,
                @as(f32, @floatFromInt(me.delta_y)) * 0.01,
            );
        },
        .mouse_wheel => |me| {
            camera.zoomBy(@as(f32, @floatFromInt(me.delta_y)) * -0.1);
        },
        else => {},
    }
}

pub fn update(ctx: jok.Context) !void {
    // camera movement
    const distance = ctx.deltaSeconds() * 5;
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
        _ = imgui.checkbox("lighting", .{ .v = &lighting });
        _ = imgui.checkbox("wireframe", .{ .v = &wireframe });

        imgui.separatorText("Play Animation");

        if (imgui.beginCombo("CesiumMan", .{
            .preview_value = imgui.formatZ("{s}", .{
                if (animation1) |a| a.getName() else "none",
            }),
        })) {
            if (imgui.selectable("none", .{ .selected = animation1 == null })) {
                animation1 = null;
            }
            if (imgui.selectable(
                imgui.formatZ("{s}", .{animation1_1.getName()}),
                .{ .selected = animation1 == animation1_1 },
            )) {
                animation1 = animation1_1;
                animation_playtime1 = 0;
            }
            imgui.endCombo();
        }

        if (imgui.beginCombo("RiggedSimple", .{
            .preview_value = imgui.formatZ("{s}", .{
                if (animation2) |a| a.getName() else "none",
            }),
        })) {
            if (imgui.selectable("none", .{ .selected = animation2 == null })) {
                animation2 = null;
            }
            if (imgui.selectable(
                imgui.formatZ("{s}", .{animation2_1.getName()}),
                .{ .selected = animation2 == animation2_1 },
            )) {
                animation2 = animation2_1;
                animation_playtime2 = 0;
            }
            imgui.endCombo();
        }

        if (imgui.beginCombo("Fox", .{
            .preview_value = imgui.formatZ("{s}", .{
                if (animation3) |a| a.getName() else "none",
            }),
        })) {
            if (imgui.selectable("none", .{ .selected = animation3 == null })) {
                animation3 = null;
            }
            if (imgui.selectable(
                imgui.formatZ("{s}", .{animation3_1.getName()}),
                .{ .selected = animation3 == animation3_1 },
            )) {
                animation3_old = animation3;
                animation3 = animation3_1;
                animation_playtime3 = 0;
                animation_transition3 = 0;
            }
            if (imgui.selectable(
                imgui.formatZ("{s}", .{animation3_2.getName()}),
                .{ .selected = animation3 == animation3_2 },
            )) {
                animation3_old = animation3;
                animation3 = animation3_2;
                animation_playtime3 = 0;
                animation_transition3 = 0;
            }
            if (imgui.selectable(
                imgui.formatZ("{s}", .{animation3_3.getName()}),
                .{ .selected = animation3 == animation3_3 },
            )) {
                animation3_old = animation3;
                animation3 = animation3_3;
                animation_playtime3 = 0;
                animation_transition3 = 0;
            }
            imgui.endCombo();
        }
    }
    imgui.end();

    if (animation1) |a| {
        animation_playtime1 += ctx.deltaSeconds();
        if (animation_playtime1 > a.getDuration()) {
            animation_playtime1 -= a.getDuration();
        }
    }
    if (animation2) |a| {
        animation_playtime2 += ctx.deltaSeconds();
        if (animation_playtime2 > a.getDuration()) {
            animation_playtime2 -= a.getDuration();
        }
    }
    if (animation3) |a| {
        animation_transition3 += ctx.deltaSeconds() / 0.5;
        animation_playtime3 += ctx.deltaSeconds();
        if (animation_playtime3 > a.getDuration()) {
            animation_playtime3 -= a.getDuration();
        }
    }
}

pub fn draw(ctx: jok.Context) !void {
    try j3d.begin(.{
        .camera = camera,
        .triangle_sort = .simple,
        .wireframe_color = if (wireframe) sdl.Color.green else null,
    });
    if (animation1) |a| {
        try j3d.animation(
            a,
            zmath.scalingV(zmath.f32x4s(3)),
            .{
                .lighting = if (lighting) .{} else null,
                .playtime = animation_playtime1,
            },
        );
    } else {
        try j3d.mesh(
            mesh1,
            zmath.scalingV(zmath.f32x4s(3)),
            .{
                .lighting = if (lighting) .{} else null,
            },
        );
    }
    if (animation2) |a| {
        try j3d.animation(
            a,
            zmath.translation(-4, 0, 0),
            .{
                .color = sdl.Color.cyan,
                .lighting = if (lighting) .{} else null,
                .playtime = animation_playtime2,
            },
        );
    } else {
        try j3d.mesh(
            mesh2,
            zmath.translation(-4, 0, 0),
            .{
                .color = sdl.Color.cyan,
                .lighting = if (lighting) .{} else null,
            },
        );
    }
    if (animation3) |a| {
        try j3d.animation(
            a,
            zmath.mul(
                zmath.rotationY(-std.math.pi / 6.0),
                zmath.mul(
                    zmath.scalingV(zmath.f32x4s(0.03)),
                    zmath.translation(4, 0, 0),
                ),
            ),
            .{
                .lighting = if (lighting) .{} else null,
                .transition = if (animation3_old) |ao|
                    .{
                        .from = ao,
                        .progress = animation_transition3,
                    }
                else
                    null,
                .playtime = animation_playtime3,
            },
        );
    } else {
        try j3d.mesh(
            mesh3,
            zmath.mul(
                zmath.rotationY(-std.math.pi / 6.0),
                zmath.mul(
                    zmath.scalingV(zmath.f32x4s(0.03)),
                    zmath.translation(4, 0, 0),
                ),
            ),
            .{
                .lighting = if (lighting) .{} else null,
            },
        );
    }
    try j3d.axises(.{ .radius = 0.01, .length = 0.5 });
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
    animation1_1.destroy();
    animation2_1.destroy();
    animation3_1.destroy();
    animation3_2.destroy();
    animation3_3.destroy();
}
