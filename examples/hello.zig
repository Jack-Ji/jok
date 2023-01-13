const std = @import("std");
const sdl = @import("sdl");
const jok = @import("jok");

var camera: jok.j3d.Camera = undefined;
var text_rect: sdl.RectangleF = undefined;
var text_speed: sdl.PointF = undefined;

pub fn init(ctx: *jok.Context) !void {
    std.log.info("game init", .{});

    const fb_size = ctx.getFramebufferSize();

    camera = jok.j3d.Camera.fromPositionAndTarget(
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
    text_rect = .{
        .x = @intToFloat(f32, fb_size.w) / 2,
        .y = @intToFloat(f32, fb_size.h) / 2,
        .width = 0,
        .height = 0,
    };
    text_speed = .{
        .x = 100,
        .y = 100,
    };
}

pub fn event(ctx: *jok.Context, e: sdl.Event) !void {
    _ = ctx;
    _ = e;
}

pub fn update(ctx: *jok.Context) !void {
    _ = ctx;
}

pub fn draw(ctx: *jok.Context) !void {
    const fb_size = ctx.getFramebufferSize();
    const center_x = @intToFloat(f32, fb_size.w) / 2;
    const center_y = @intToFloat(f32, fb_size.h) / 2;

    jok.j2d.primitive.clear(.{});
    var i: u32 = 0;
    while (i < 100) : (i += 1) {
        const row = @intToFloat(f32, i / 10) - 5;
        const col = @intToFloat(f32, i % 10) - 5;
        const offset_origin = jok.zmath.f32x4(row * 50, col * 50, 0, 1);
        const rotate_m = jok.zmath.matFromAxisAngle(
            jok.zmath.f32x4(center_x, center_y, 1, 0),
            @floatCast(f32, ctx.tick),
        );
        const translate_m = jok.zmath.translation(center_x, center_y, 0);
        const offset_transformed = jok.zmath.mul(jok.zmath.mul(offset_origin, rotate_m), translate_m);
        jok.j2d.primitive.addQuadFilled(
            .{ .x = -10, .y = -10 },
            .{ .x = 10, .y = -10 },
            .{ .x = 10, .y = 10 },
            .{ .x = -10, .y = 10 },
            sdl.Color.rgb(
                @floatToInt(u8, 128 + 128 * std.math.sin(ctx.tick)),
                @floatToInt(u8, @intToFloat(f32, i) + std.math.max(0, 155 * std.math.sin(ctx.tick))),
                @floatToInt(u8, 128 + 128 * std.math.cos(ctx.tick)),
            ),
            .{
                .trs = .{
                    .scale = .{
                        .x = @floatCast(f32, 1.3 + std.math.sin(ctx.tick)),
                        .y = @floatCast(f32, 1.3 + std.math.sin(ctx.tick)),
                    },
                    .rotate_degree = @floatCast(f32, ctx.tick * 30),
                    .offset = .{
                        .x = offset_transformed[0],
                        .y = offset_transformed[1],
                    },
                },
            },
        );
    }
    try jok.j2d.primitive.draw();

    const color = sdl.Color.rgb(
        @floatToInt(u8, 128 + 128 * std.math.sin(ctx.tick)),
        100,
        @floatToInt(u8, 128 + 128 * std.math.cos(ctx.tick)),
    );
    jok.j3d.primitive.clear(.{});
    try jok.j3d.primitive.addIcosahedron(
        jok.zmath.mul(
            jok.zmath.rotationY(@floatCast(f32, ctx.tick)),
            jok.zmath.translation(-3, 3, 0),
        ),
        camera,
        .{ .lighting = .{}, .color = color },
    );
    try jok.j3d.primitive.addTorus(
        jok.zmath.mul(
            jok.zmath.rotationY(@floatCast(f32, ctx.tick)),
            jok.zmath.translation(3, 3, 0),
        ),
        camera,
        .{ .common = .{ .lighting = .{}, .color = color } },
    );
    try jok.j3d.primitive.addParametricSphere(
        jok.zmath.mul(
            jok.zmath.rotationY(@floatCast(f32, ctx.tick)),
            jok.zmath.translation(3, -3, 0),
        ),
        camera,
        .{ .common = .{ .lighting = .{}, .color = color } },
    );
    try jok.j3d.primitive.addTetrahedron(
        jok.zmath.mul(
            jok.zmath.rotationY(@floatCast(f32, ctx.tick)),
            jok.zmath.translation(-3, -3, 0),
        ),
        camera,
        .{ .lighting = .{}, .color = color },
    );
    try jok.j3d.primitive.draw();

    text_rect.x += text_speed.x * ctx.delta_tick;
    text_rect.y += text_speed.y * ctx.delta_tick;
    if (text_rect.x < 0) {
        text_speed.x = @fabs(text_speed.x);
    }
    if (text_rect.x + text_rect.width > @intToFloat(f32, fb_size.w)) {
        text_speed.x = -@fabs(text_speed.x);
    }
    if (text_rect.y < 0) {
        text_speed.y = @fabs(text_speed.y);
    }
    if (text_rect.y + text_rect.height > @intToFloat(f32, fb_size.h)) {
        text_speed.y = -@fabs(text_speed.y);
    }
    const draw_result = try jok.font.debugDraw(
        ctx.renderer,
        .{
            .pos = .{ .x = text_rect.x, .y = text_rect.y },
            .font_size = 50,
            .color = sdl.Color.rgb(
                255,
                @floatToInt(u8, std.math.max(0, 255 * std.math.cos(ctx.tick))),
                0,
            ),
        },
        "Hello Jok!",
        .{},
    );
    text_rect.width = draw_result.area.width;
    text_rect.height = draw_result.area.height;
}

pub fn quit(ctx: *jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});
}
