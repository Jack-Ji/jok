const std = @import("std");
const jok = @import("jok");
const physfs = jok.physfs;
const font = jok.font;
const zmath = jok.zmath;
const imgui = jok.imgui;
const j2d = jok.j2d;
const j3d = jok.j3d;
const easing = jok.utils.easing;

pub const jok_window_size = jok.config.WindowSize{
    .custom = .{ .width = 1280, .height = 720 },
};

var camera: j3d.Camera = undefined;
var text_draw_pos: jok.Point = undefined;
var text_speed: jok.Point = undefined;
var screenshot_time: i64 = -1;
var screenshot_tex: ?jok.Texture = null;
var screenshot_pos: jok.Point = undefined;
var screenshot_size: jok.Point = undefined;
var screenshot_tint_color: jok.Color = undefined;
var point_easing_system: *easing.EasingSystem(jok.Point) = undefined;
var color_easing_system: *easing.EasingSystem(jok.Color) = undefined;
var show_stats: bool = true;

pub fn init(ctx: jok.Context) !void {
    std.log.info("game init", .{});

    try physfs.setWriteDir(physfs.getPrefDir(ctx));

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
    text_draw_pos = .{
        .x = csz.getWidthFloat() / 2,
        .y = csz.getHeightFloat() / 2,
    };
    text_speed = .{
        .x = 100,
        .y = 100,
    };
    point_easing_system = try easing.EasingSystem(jok.Point).create(ctx.allocator());
    color_easing_system = try easing.EasingSystem(jok.Color).create(ctx.allocator());
}

pub fn event(ctx: jok.Context, e: jok.Event) !void {
    const S = struct {
        var fullscreen = false;
    };

    switch (e) {
        .key_down => |k| {
            if (k.scancode == .f1) {
                S.fullscreen = !S.fullscreen;
                try ctx.window().setFullscreen(if (S.fullscreen) .true_fullscreen else .none);
            } else if (k.scancode == .f2) {
                const csz = ctx.getCanvasSize();
                const pixels = try ctx.renderer().getPixels(ctx.allocator(), null);
                defer pixels.destroy();
                try jok.utils.gfx.savePixelsToFile(
                    ctx,
                    pixels.pixels,
                    pixels.width,
                    pixels.height,
                    "screenshot.png",
                    .{},
                );
                screenshot_tex = try pixels.createTexture(ctx.renderer(), .{});
                screenshot_time = std.time.timestamp();
                try point_easing_system.add(
                    &screenshot_pos,
                    .in_out_circ,
                    easing.easePoint,
                    1,
                    .{ .x = 0, .y = 0 },
                    .{ .x = csz.getWidthFloat() * 0.75, .y = 0 },
                );
                try point_easing_system.add(
                    &screenshot_size,
                    .out_bounce,
                    easing.easePoint,
                    1,
                    .{ .x = csz.getWidthFloat(), .y = csz.getHeightFloat() },
                    .{ .x = csz.getWidthFloat() / 5, .y = csz.getHeightFloat() / 5 },
                );
                try color_easing_system.add(
                    &screenshot_tint_color,
                    .in_out_quad,
                    easing.easeColor,
                    1,
                    .{ .r = 0, .g = 0, .b = 0, .a = 0 },
                    jok.Color.white,
                );
            } else if (k.scancode == .f3) {
                show_stats = !show_stats;
            } else if (k.scancode == .f4) {
                ctx.window().setPosition(.center);
            }
        },
        else => {},
    }
}

pub fn update(ctx: jok.Context) !void {
    point_easing_system.update(ctx.deltaSeconds());
    color_easing_system.update(ctx.deltaSeconds());
}

pub fn draw(ctx: jok.Context) !void {
    try ctx.renderer().clear(null);
    if (show_stats) ctx.displayStats(.{});

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
        j2d.begin(.{});
        defer j2d.end();

        var i: u32 = 0;
        while (i < 100) : (i += 1) {
            const row = @as(f32, @floatFromInt(i / 10)) - 5;
            const col = @as(f32, @floatFromInt(i % 10)) - 5;
            const offset_origin = jok.zmath.f32x4(row * 50, col * 50, 0, 1);
            const rotate_m = jok.zmath.matFromAxisAngle(
                jok.zmath.f32x4(center_x, center_y, 1, 0),
                ctx.seconds(),
            );
            const translate_m = jok.zmath.translation(center_x, center_y, 0);
            const offset_transformed = jok.zmath.mul(jok.zmath.mul(offset_origin, rotate_m), translate_m);

            j2d.getTransform().setToIdentity();
            j2d.getTransform().scale(.{
                .x = (1.3 + std.math.sin(ctx.seconds())) * ctx.getDpiScale(),
                .y = (1.3 + std.math.sin(ctx.seconds())) * ctx.getDpiScale(),
            });
            j2d.getTransform().rotateByOrigin(ctx.seconds());
            j2d.getTransform().translate(.{
                .x = offset_transformed[0],
                .y = offset_transformed[1],
            });
            try j2d.rectFilledMultiColor(
                .{ .x = -10, .y = -10, .width = 20, .height = 20 },
                jok.Color.white,
                jok.Color.red,
                jok.Color.green,
                jok.Color.blue,
                .{},
            );
        }

        j2d.getTransform().setToIdentity();
        text_draw_pos.x += text_speed.x * ctx.deltaSeconds();
        text_draw_pos.y += text_speed.y * ctx.deltaSeconds();
        const atlas = try font.DebugFont.getAtlas(ctx, 50);
        try j2d.text(
            .{
                .atlas = atlas,
                .pos = .{ .x = text_draw_pos.x, .y = text_draw_pos.y },
                .tint_color = jok.Color.red,
            },
            "Hello Jok!",
            .{},
        );
        const area = try atlas.getBoundingBox(
            "Hello Jok!",
            .{ .x = text_draw_pos.x, .y = text_draw_pos.y },
            .top,
            .aligned,
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
        const color = jok.Color.rgb(
            @intFromFloat(128 + 127 * std.math.sin(ctx.seconds())),
            100,
            @intFromFloat(128 + 127 * std.math.cos(ctx.seconds())),
        );
        j3d.begin(.{ .camera = camera, .triangle_sort = .simple });
        defer j3d.end();
        try j3d.icosahedron(
            zmath.mul(
                zmath.rotationY(ctx.seconds()),
                zmath.translation(-3, 3, 0),
            ),
            .{ .rdopt = .{ .lighting = .{}, .color = color } },
        );
        try j3d.torus(
            zmath.mul(
                zmath.rotationY(ctx.seconds()),
                zmath.translation(3, 3, 0),
            ),
            .{ .rdopt = .{ .lighting = .{}, .color = color } },
        );
        try j3d.parametricSphere(
            zmath.mul(
                zmath.rotationY(ctx.seconds()),
                zmath.translation(3, -3, 0),
            ),
            .{ .rdopt = .{ .lighting = .{}, .color = color } },
        );
        try j3d.tetrahedron(
            zmath.mul(
                zmath.rotationY(ctx.seconds()),
                zmath.translation(-3, -3, 0),
            ),
            .{ .rdopt = .{ .lighting = .{}, .color = color } },
        );
    }

    if (screenshot_tex) |tex| {
        if (std.time.timestamp() - screenshot_time < 5) {
            j2d.begin(.{});
            defer j2d.end();
            try j2d.rectRoundedFilled(
                .{
                    .x = screenshot_pos.x,
                    .y = screenshot_pos.y,
                    .width = screenshot_size.x,
                    .height = screenshot_size.y,
                },
                jok.Color.rgba(255, 255, 255, 200),
                .{},
            );
            try j2d.imageRounded(
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
                    .tint_color = screenshot_tint_color,
                },
            );
        } else {
            tex.destroy();
            screenshot_tex = null;
        }
    }

    font.debugDraw(
        ctx,
        .{ .x = 0, .y = 0 },
        "Press F1 to toggle fullscreen",
        .{},
    );
    font.debugDraw(
        ctx,
        .{ .x = 0, .y = 17 * ctx.getDpiScale() },
        "Press F2 to take screenshot",
        .{},
    );
    font.debugDraw(
        ctx,
        .{ .x = 0, .y = 34 * ctx.getDpiScale() },
        "Press F3 to toggle frame statistics",
        .{},
    );
    font.debugDraw(
        ctx,
        .{ .x = 0, .y = 51 * ctx.getDpiScale() },
        "Press F4 to center the window",
        .{},
    );
}

pub fn quit(ctx: jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});

    if (screenshot_tex) |tex| tex.destroy();
    point_easing_system.destroy();
    color_easing_system.destroy();
}
