const std = @import("std");
const jok = @import("jok");
const physfs = jok.physfs;
const font = jok.font;
const zmath = jok.zmath;
const imgui = jok.imgui;
const j2d = jok.j2d;
const j3d = jok.j3d;
const zmesh = jok.zmesh;
const easing = jok.utils.easing;

pub const jok_window_size = jok.config.WindowSize{
    .custom = .{ .width = 1280, .height = 720 },
};

var batchpool_2d: j2d.BatchPool(64, false) = undefined;
var batchpool_3d: j3d.BatchPool(64, false) = undefined;
var camera: j3d.Camera = undefined;
var shape_icosahedron: zmesh.Shape = undefined;
var shape_torus: zmesh.Shape = undefined;
var shape_parametric_sphere: zmesh.Shape = undefined;
var shape_tetrahedron: zmesh.Shape = undefined;
var text_draw_pos: jok.Point = undefined;
var text_speed: jok.Point = undefined;
var screenshot_time: i64 = -1;
var screenshot_tex: ?jok.Texture = null;
var screenshot_pos: jok.Point = undefined;
var screenshot_size: jok.Point = undefined;
var screenshot_tint_color: jok.ColorF = undefined;
var point_easing_system: *easing.EasingSystem(jok.Point) = undefined;
var color_easing_system: *easing.EasingSystem(jok.ColorF) = undefined;
var show_stats: bool = true;
var suppress: bool = true;

pub fn init(ctx: jok.Context) !void {
    std.log.info("game init", .{});

    try physfs.setWriteDir(physfs.getPrefDir("myorg", "mygame"));

    batchpool_2d = try @TypeOf(batchpool_2d).init(ctx);
    batchpool_3d = try @TypeOf(batchpool_3d).init(ctx);

    const csz = ctx.getCanvasSize();
    camera = j3d.Camera.fromPositionAndTarget(
        .{
            .perspective = .{
                .fov = std.math.pi / 4.0,
                .aspect_ratio = ctx.getAspectRatio(),
                .near = 0.1,
                .far = 100,
            },
        },
        .{ 0, 0, 10 },
        .{ 0, 0, 0 },
    );
    shape_icosahedron = zmesh.Shape.initIcosahedron();
    shape_icosahedron.computeNormals();
    shape_torus = zmesh.Shape.initTorus(15, 20, 0.2);
    shape_torus.computeNormals();
    shape_parametric_sphere = zmesh.Shape.initParametricSphere(15, 15);
    shape_parametric_sphere.computeNormals();
    shape_tetrahedron = zmesh.Shape.initTetrahedron();
    shape_tetrahedron.computeNormals();
    text_draw_pos = csz.toPoint().scale(0.5);
    text_speed = .{ .x = 100, .y = 100 };
    point_easing_system = try easing.EasingSystem(jok.Point).create(ctx.allocator());
    color_easing_system = try easing.EasingSystem(jok.ColorF).create(ctx.allocator());
}

pub fn event(ctx: jok.Context, e: jok.Event) !void {
    const S = struct {
        var fullscreen = false;
    };

    switch (e) {
        .key_down => |k| {
            if (k.scancode == .f1) {
                S.fullscreen = !S.fullscreen;
                try ctx.window().setFullscreen(S.fullscreen);
            } else if (k.scancode == .f2) {
                const csz = ctx.getCanvasSize();
                const pixels = try ctx.renderer().getPixels(null);
                defer pixels.destroy();
                screenshot_tex = try pixels.createTexture(ctx.renderer(), .{});
                screenshot_time = std.time.timestamp();
                try point_easing_system.add(
                    &screenshot_pos,
                    .in_out_circ,
                    easing.easePoint,
                    1,
                    .origin,
                    .{ .x = csz.getWidthFloat() * 0.75, .y = 0 },
                    .{},
                );
                try point_easing_system.add(
                    &screenshot_size,
                    .out_bounce,
                    easing.easePoint,
                    1,
                    csz.toPoint(),
                    csz.toPoint().scale(0.2),
                    .{},
                );
                try color_easing_system.add(
                    &screenshot_tint_color,
                    .in_out_quad,
                    easing.easeColorF,
                    1,
                    .none,
                    .white,
                    .{},
                );
            } else if (k.scancode == .f3) {
                show_stats = !show_stats;
            } else if (k.scancode == .f4) {
                try ctx.window().setPosition(.center);
            }
        },
        else => {},
    }
}

pub fn update(ctx: jok.Context) !void {
    if (jok.io.getKeyboardState().isPressed(.f5)) {
        ctx.supressDraw();
    }
    point_easing_system.update(ctx.deltaSeconds());
    color_easing_system.update(ctx.deltaSeconds());
}

pub fn draw(ctx: jok.Context) !void {
    try ctx.renderer().clear(.black);
    if (show_stats) ctx.displayStats(.{});

    imgui.setNextWindowPos(.{ .x = 50, .y = 200, .cond = .once });
    if (imgui.begin("canvas", .{})) {
        imgui.image(ctx.canvas().ptr, .{
            .w = ctx.getAspectRatio() * 100,
            .h = 100,
        });
    }
    imgui.end();

    const csz = ctx.getCanvasSize();
    const center_x: f32 = @floatFromInt(csz.width / 2);
    const center_y: f32 = @floatFromInt(csz.height / 2);

    {
        var b = try batchpool_2d.new(.{});
        defer b.submit();

        var i: u32 = 0;
        while (i < 100) : (i += 1) {
            const row = @as(f32, @floatFromInt(i / 10)) - 5;
            const col = @as(f32, @floatFromInt(i % 10)) - 5;
            const offset_origin = zmath.f32x4(row * 50, col * 50, 0, 1);
            const rotate_m = zmath.matFromAxisAngle(
                zmath.f32x4(center_x, center_y, 1, 0),
                ctx.seconds(),
            );
            const translate_m = zmath.translation(center_x, center_y, 0);
            const offset_transformed = zmath.mul(zmath.mul(offset_origin, rotate_m), translate_m);

            try b.pushTransform();
            defer b.popTransform();
            b.setIdentity();
            b.scaleAroundWorldOrigin(.{
                (1.3 + std.math.sin(ctx.seconds())),
                (1.3 + std.math.sin(ctx.seconds())),
            });
            b.rotateByWorldOrigin(ctx.seconds());
            b.translate(.{
                offset_transformed[0],
                offset_transformed[1],
            });
            try b.rectFilledMultiColor(
                .{ .x = -10, .y = -10, .width = 20, .height = 20 },
                .white,
                .red,
                .green,
                .blue,
                .{},
            );
        }

        text_draw_pos.x += text_speed.x * ctx.deltaSeconds();
        text_draw_pos.y += text_speed.y * ctx.deltaSeconds();
        const atlas = try font.DebugFont.getAtlas(ctx, 50);
        try b.text(
            "Hello Jok!",
            .{},
            .{
                .atlas = atlas,
                .pos = .{ .x = text_draw_pos.x, .y = text_draw_pos.y },
                .tint_color = .red,
            },
        );
        const area = try atlas.getBoundingBox(
            "Hello Jok!",
            .{ .x = text_draw_pos.x, .y = text_draw_pos.y },
            .{},
        );
        if (area.x < 0) {
            text_speed.x = @abs(text_speed.x);
        }
        if (area.x + area.width > @as(f32, @floatFromInt(csz.width))) {
            text_speed.x = -@abs(text_speed.x);
        }
        if (area.y < 0) {
            text_speed.y = @abs(text_speed.y);
        }
        if (area.y + area.height > @as(f32, @floatFromInt(csz.height))) {
            text_speed.y = -@abs(text_speed.y);
        }
    }

    {
        var b = try batchpool_3d.new(.{ .camera = camera, .triangle_sort = .simple });
        defer b.submit();

        const color = jok.ColorF.rgb(
            0.5 + 0.5 * std.math.sin(ctx.seconds()),
            0.4,
            0.5 + 0.5 * std.math.cos(ctx.seconds()),
        );

        b.rotateY(ctx.seconds());
        try b.pushTransform();

        b.translate(.{ -3, 3, 0 });
        try b.shape(
            shape_icosahedron,
            null,
            .{ .lighting = .{}, .color = color },
        );

        b.popTransform();
        try b.pushTransform();
        b.translate(.{ 3, 3, 0 });
        try b.shape(
            shape_torus,
            null,
            .{ .lighting = .{}, .color = color },
        );

        b.popTransform();
        try b.pushTransform();
        b.translate(.{ 3, -3, 0 });
        try b.shape(
            shape_parametric_sphere,
            null,
            .{ .lighting = .{}, .color = color },
        );

        b.popTransform();
        b.translate(.{ -3, -3, 0 });
        try b.shape(
            shape_tetrahedron,
            null,
            .{ .lighting = .{}, .color = color },
        );
    }

    if (screenshot_tex) |tex| {
        if (std.time.timestamp() - screenshot_time < 5) {
            var b = try batchpool_2d.new(.{});
            defer b.submit();

            try b.rectRoundedFilled(
                .{
                    .x = screenshot_pos.x,
                    .y = screenshot_pos.y,
                    .width = screenshot_size.x,
                    .height = screenshot_size.y,
                },
                .rgba(255, 255, 255, 200),
                .{},
            );
            try b.imageRounded(
                tex,
                .{
                    .x = screenshot_pos.x + 5,
                    .y = screenshot_pos.y + 5,
                },
                .{
                    .size = .{
                        .width = @intFromFloat(screenshot_size.x - 10),
                        .height = @intFromFloat(screenshot_size.y - 10),
                    },
                    .tint_color = screenshot_tint_color.toColor(),
                },
            );
        } else {
            tex.destroy();
            screenshot_tex = null;
        }
    }

    ctx.debugPrint("Press F1 to toggle fullscreen", .{});
    ctx.debugPrint("Press F2 to take screenshot", .{ .pos = .{ .x = 0, .y = 17 } });
    ctx.debugPrint("Press F3 to toggle frame statistics", .{ .pos = .{ .x = 0, .y = 34 } });
    ctx.debugPrint("Press F4 to center the window", .{ .pos = .{ .x = 0, .y = 51 } });
    ctx.debugPrint("Press F5 to suppress rendering", .{ .pos = .{ .x = 0, .y = 68 } });
}

pub fn quit(ctx: jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});

    shape_icosahedron.deinit();
    shape_torus.deinit();
    shape_parametric_sphere.deinit();
    shape_tetrahedron.deinit();
    if (screenshot_tex) |tex| tex.destroy();
    point_easing_system.destroy();
    color_easing_system.destroy();
    batchpool_2d.deinit();
    batchpool_3d.deinit();
}
