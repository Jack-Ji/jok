const std = @import("std");
const builtin = @import("builtin");
const jok = @import("jok");
const font = jok.font;
const j3d = jok.j3d;
const physfs = jok.vendor.physfs;
const zgui = jok.vendor.zgui;
const zmath = jok.vendor.zmath;
const zmesh = jok.vendor.zmesh;

pub const jok_window_size = jok.config.WindowSize{
    .custom = .{ .width = 1280, .height = 720 },
};

var batchpool: j3d.BatchPool(64, false) = undefined;
var lighting: bool = true;
var wireframe: bool = false;
var shading_method: i32 = 0;
var camera: j3d.Camera = undefined;
var mesh1: *j3d.Mesh = undefined;
var mesh2: *j3d.Mesh = undefined;
var mesh3: *j3d.Mesh = undefined;
var mesh4: *j3d.Mesh = undefined;
var mesh5: *j3d.Mesh = undefined;
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

    if (!builtin.cpu.arch.isWasm()) {
        try physfs.mount("assets", "", true);
    }

    batchpool = try @TypeOf(batchpool).init(ctx);

    camera = j3d.Camera.fromPositionAndTarget(
        .{
            .perspective = .{
                .fov = std.math.degreesToRadians(70),
                .aspect_ratio = ctx.getAspectRatio(),
                .near = 0.1,
                .far = 1000,
            },
        },
        [_]f32{ 7, 4.1, 7 },
        [_]f32{ 0, 0, 0 },
    );

    var t = try std.Io.Clock.awake.now(ctx.io());
    mesh1 = try j3d.Mesh.fromGltf(ctx, "models/CesiumMan.glb", .{});
    mesh2 = try j3d.Mesh.fromGltf(ctx, "models/RiggedSimple.glb", .{});
    mesh3 = try j3d.Mesh.fromGltf(ctx, "models/Fox/Fox.gltf", .{});
    mesh4 = try j3d.Mesh.fromObj(ctx, "models/akira.obj", "models/akira.mtl", .{});
    mesh5 = try j3d.Mesh.fromObj(ctx, "models/prime_truckin.obj", "models/prime_truckin.mtl", .{});
    std.debug.print("Models load time: {D}\n", .{
        @as(i64, @intCast(t.durationTo(try std.Io.Clock.awake.now(ctx.io())).nanoseconds)),
    });

    animation1_1 = try j3d.Animation.create(ctx.allocator(), mesh1.getAnimation("default").?);
    animation2_1 = try j3d.Animation.create(ctx.allocator(), mesh2.getAnimation("default").?);
    animation3_1 = try j3d.Animation.create(ctx.allocator(), mesh3.getAnimation("Walk").?);
    animation3_2 = try j3d.Animation.create(ctx.allocator(), mesh3.getAnimation("Survey").?);
    animation3_3 = try j3d.Animation.create(ctx.allocator(), mesh3.getAnimation("Run").?);
}

pub fn event(ctx: jok.Context, e: jok.Event) !void {
    const S = struct {
        var is_viewing: bool = false;
        const mouse_speed: f32 = 0.0025;
    };

    if (zgui.io.getWantCaptureMouse()) return;

    switch (e) {
        .mouse_motion => |me| {
            if (S.is_viewing) {
                camera.rotateBy(
                    S.mouse_speed * me.delta.y,
                    S.mouse_speed * me.delta.x,
                );
                return;
            }

            if (me.button_state.isPressed(.left)) {
                camera.rotateAroundBy(
                    null,
                    me.delta.x * 0.01,
                    me.delta.y * 0.01,
                );
                return;
            }
        },
        .mouse_wheel => |me| {
            camera.zoomBy(me.delta_y * -0.1);
        },
        .mouse_button_down => |me| {
            if (me.button == .right) {
                try ctx.window().setRelativeMouseMode(true);
                S.is_viewing = true;
            }
        },
        .mouse_button_up => |me| {
            if (me.button == .right) {
                try ctx.window().setRelativeMouseMode(false);
                S.is_viewing = false;
            }
        },
        else => {},
    }
}

pub fn update(ctx: jok.Context) !void {
    // camera movement
    const distance = ctx.deltaSeconds() * 5;
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
    try ctx.renderer().clear(.rgb(77, 77, 77));
    ctx.displayStats(.{});

    if (zgui.begin("Control Panel", .{})) {
        zgui.textUnformatted("shading method");
        zgui.sameLine(.{});
        _ = zgui.radioButtonStatePtr("gouraud", .{
            .v = &shading_method,
            .v_button = 0,
        });
        zgui.sameLine(.{});
        _ = zgui.radioButtonStatePtr("flat", .{
            .v = &shading_method,
            .v_button = 1,
        });
        _ = zgui.checkbox("lighting", .{ .v = &lighting });
        _ = zgui.checkbox("wireframe", .{ .v = &wireframe });

        zgui.separatorText("Play Animation");

        if (zgui.beginCombo("CesiumMan", .{
            .preview_value = zgui.formatZ("{s}", .{
                if (animation1) |a| a.getName() else "none",
            }),
        })) {
            if (zgui.selectable("none", .{ .selected = animation1 == null })) {
                animation1 = null;
            }
            if (zgui.selectable(
                zgui.formatZ("{s}", .{animation1_1.getName()}),
                .{ .selected = animation1 == animation1_1 },
            )) {
                animation1 = animation1_1;
                animation_playtime1 = 0;
            }
            zgui.endCombo();
        }

        if (zgui.beginCombo("RiggedSimple", .{
            .preview_value = zgui.formatZ("{s}", .{
                if (animation2) |a| a.getName() else "none",
            }),
        })) {
            if (zgui.selectable("none", .{ .selected = animation2 == null })) {
                animation2 = null;
            }
            if (zgui.selectable(
                zgui.formatZ("{s}", .{animation2_1.getName()}),
                .{ .selected = animation2 == animation2_1 },
            )) {
                animation2 = animation2_1;
                animation_playtime2 = 0;
            }
            zgui.endCombo();
        }

        if (zgui.beginCombo("Fox", .{
            .preview_value = zgui.formatZ("{s}", .{
                if (animation3) |a| a.getName() else "none",
            }),
        })) {
            if (zgui.selectable("none", .{ .selected = animation3 == null })) {
                animation3 = null;
            }
            if (zgui.selectable(
                zgui.formatZ("{s}", .{animation3_1.getName()}),
                .{ .selected = animation3 == animation3_1 },
            )) {
                animation3_old = animation3;
                animation3 = animation3_1;
                animation_playtime3 = 0;
                animation_transition3 = 0;
            }
            if (zgui.selectable(
                zgui.formatZ("{s}", .{animation3_2.getName()}),
                .{ .selected = animation3 == animation3_2 },
            )) {
                animation3_old = animation3;
                animation3 = animation3_2;
                animation_playtime3 = 0;
                animation_transition3 = 0;
            }
            if (zgui.selectable(
                zgui.formatZ("{s}", .{animation3_3.getName()}),
                .{ .selected = animation3 == animation3_3 },
            )) {
                animation3_old = animation3;
                animation3 = animation3_3;
                animation_playtime3 = 0;
                animation_transition3 = 0;
            }
            zgui.endCombo();
        }
    }
    zgui.end();

    var b = try batchpool.new(.{
        .camera = camera,
        .triangle_sort = .simple,
        .wireframe_color = if (wireframe) .green else null,
    });
    defer b.submit();
    b.scale(.{ 3, 3, 3 });
    b.rotateY(std.math.pi);
    if (animation1) |a| {
        try b.animation(
            a,
            .{
                .shading_method = @enumFromInt(shading_method),
                .lighting = if (lighting) .{} else null,
                .playtime = animation_playtime1,
            },
        );
    } else {
        try b.mesh(
            mesh1,
            .{
                .shading_method = @enumFromInt(shading_method),
                .lighting = if (lighting) .{} else null,
            },
        );
    }

    b.setIdentity();
    b.rotateY(std.math.pi);
    b.translate(.{ -4, 0, 0 });
    if (animation2) |a| {
        try b.animation(
            a,
            .{
                .color = .cyan,
                .shading_method = @enumFromInt(shading_method),
                .lighting = if (lighting) .{} else null,
                .playtime = animation_playtime2,
            },
        );
    } else {
        try b.mesh(
            mesh2,
            .{
                .color = .cyan,
                .shading_method = @enumFromInt(shading_method),
                .lighting = if (lighting) .{} else null,
            },
        );
    }

    b.setIdentity();
    b.rotateY(std.math.pi);
    b.scale(.{ 0.03, 0.03, 0.03 });
    b.translate(.{ 4, 0, 0 });
    if (animation3) |a| {
        try b.animation(
            a,
            .{
                .shading_method = @enumFromInt(shading_method),
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
        try b.mesh(
            mesh3,
            .{
                .shading_method = @enumFromInt(shading_method),
                .lighting = if (lighting) .{} else null,
            },
        );
    }

    b.setIdentity();
    b.scale(.{ 0.5, 0.5, 0.5 });
    b.rotateY(ctx.seconds());
    b.translate(.{ -3, -3, 3 });
    try b.mesh(
        mesh4,
        .{
            .shading_method = @enumFromInt(shading_method),
            .lighting = if (lighting) .{} else null,
        },
    );

    b.setIdentity();
    b.rotateY(ctx.seconds());
    b.translate(.{ 3, -3, 3 });
    try b.mesh(
        mesh5,
        .{
            .shading_method = @enumFromInt(shading_method),
            .lighting = if (lighting) .{} else null,
        },
    );

    ctx.debugPrint(
        "Press WSAD to move around, drag mouse while pressing right-button to rotate the view",
        .{ .pos = .{ .x = 20, .y = 10 } },
    );
    ctx.debugPrint(
        "Drag mouse while pressing left-button to rotate around the models",
        .{ .pos = .{ .x = 20, .y = 30 } },
    );
    ctx.debugPrint(
        zgui.format(
            "Camera: pos({d:.3},{d:.3},{d:.3}) dir({d:.3},{d:.3},{d:.3})",
            .{
                // zig fmt: off
            camera.position[0],camera.position[1],camera.position[2],
            camera.dir[0],camera.dir[1],camera.dir[2],
        },
        ),
        .{.pos=.{ .x = 20, .y = 50 }},
    );
}

pub fn quit(ctx: jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});
    mesh1.destroy();
    mesh2.destroy();
    mesh3.destroy();
    mesh4.destroy();
    mesh5.destroy();
    animation1_1.destroy();
    animation2_1.destroy();
    animation3_1.destroy();
    animation3_2.destroy();
    animation3_3.destroy();
    batchpool.deinit();
}
