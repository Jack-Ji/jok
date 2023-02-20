const std = @import("std");
const sdl = @import("sdl");
const jok = @import("jok");
const font = jok.font;
const zmath = jok.zmath;
const j2d = jok.j2d;
const j3d = jok.j3d;

var camera: j3d.Camera = undefined;
var text_draw_pos: sdl.PointF = undefined;
var text_speed: sdl.PointF = undefined;

pub fn init(ctx: jok.Context) !void {
    std.log.info("game init", .{});

    const fb_size = ctx.getFramebufferSize();

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
        null,
    );
    text_draw_pos = .{
        .x = fb_size.x / 2,
        .y = fb_size.y / 2,
    };
    text_speed = .{
        .x = 100,
        .y = 100,
    };
}

pub fn event(ctx: jok.Context, e: sdl.Event) !void {
    switch (e) {
        .key_down => |k| {
            if (k.scancode == .f1)
                ctx.toggleFullscreeen(null);
        },
        else => {},
    }
}

pub fn update(ctx: jok.Context) !void {
    _ = ctx;
}

pub fn draw(ctx: jok.Context) !void {
    const fb_size = ctx.getFramebufferSize();
    const center_x = fb_size.x / 2;
    const center_y = fb_size.y / 2;

    try j2d.begin(.{});
    var i: u32 = 0;
    while (i < 100) : (i += 1) {
        const row = @intToFloat(f32, i / 10) - 5;
        const col = @intToFloat(f32, i % 10) - 5;
        const offset_origin = jok.zmath.f32x4(row * 50, col * 50, 0, 1);
        const rotate_m = jok.zmath.matFromAxisAngle(
            jok.zmath.f32x4(center_x, center_y, 1, 0),
            ctx.seconds(),
        );
        const translate_m = jok.zmath.translation(center_x, center_y, 0);
        const offset_transformed = jok.zmath.mul(jok.zmath.mul(offset_origin, rotate_m), translate_m);

        j2d.getTransform().setToIdentity();
        j2d.getTransform().scale(.{
            .x = 1.3 + std.math.sin(ctx.seconds()),
            .y = 1.3 + std.math.sin(ctx.seconds()),
        });
        j2d.getTransform().rotateByOrgin(ctx.seconds());
        j2d.getTransform().translate(.{
            .x = offset_transformed[0],
            .y = offset_transformed[1],
        });
        try j2d.addRectFilledMultiColor(
            .{ .x = -10, .y = -10, .width = 20, .height = 20 },
            sdl.Color.white,
            sdl.Color.red,
            sdl.Color.green,
            sdl.Color.blue,
            .{},
        );
    }
    try j2d.end();

    const color = sdl.Color.rgb(
        @floatToInt(u8, 128 + 127 * std.math.sin(ctx.seconds())),
        100,
        @floatToInt(u8, 128 + 127 * std.math.cos(ctx.seconds())),
    );
    try j3d.begin(.{ .camera = camera, .sort_by_depth = true });
    try j3d.addIcosahedron(
        zmath.mul(
            zmath.rotationY(ctx.seconds()),
            zmath.translation(-3, 3, 0),
        ),
        .{ .rdopt = .{ .lighting = .{}, .color = color } },
    );
    try j3d.addTorus(
        zmath.mul(
            zmath.rotationY(ctx.seconds()),
            zmath.translation(3, 3, 0),
        ),
        .{ .rdopt = .{ .lighting = .{}, .color = color } },
    );
    try j3d.addParametricSphere(
        zmath.mul(
            zmath.rotationY(ctx.seconds()),
            zmath.translation(3, -3, 0),
        ),
        .{ .rdopt = .{ .lighting = .{}, .color = color } },
    );
    try j3d.addTetrahedron(
        zmath.mul(
            zmath.rotationY(ctx.seconds()),
            zmath.translation(-3, -3, 0),
        ),
        .{ .rdopt = .{ .lighting = .{}, .color = color } },
    );
    try j3d.end();

    text_draw_pos.x += text_speed.x * ctx.deltaSeconds();
    text_draw_pos.y += text_speed.y * ctx.deltaSeconds();
    const draw_result = try font.debugDraw(
        ctx,
        .{
            .pos = .{ .x = text_draw_pos.x, .y = text_draw_pos.y },
            .font_size = 50,
            .color = sdl.Color.rgb(
                255,
                @floatToInt(u8, std.math.max(0, 255 * std.math.cos(ctx.seconds()))),
                0,
            ),
        },
        "Hello Jok!",
        .{},
    );
    if (draw_result.area.x < 0) {
        text_speed.x = @fabs(text_speed.x);
    }
    if (draw_result.area.x + draw_result.area.width > fb_size.x) {
        text_speed.x = -@fabs(text_speed.x);
    }
    if (draw_result.area.y < 0) {
        text_speed.y = @fabs(text_speed.y);
    }
    if (draw_result.area.y + draw_result.area.height > fb_size.y) {
        text_speed.y = -@fabs(text_speed.y);
    }
    _ = try font.debugDraw(
        ctx,
        .{ .pos = .{ .x = 0, .y = 0 } },
        "Press F1 to toggle fullscreen",
        .{},
    );
}

pub fn quit(ctx: jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});
}
