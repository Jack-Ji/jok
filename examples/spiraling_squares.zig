const std = @import("std");
const math = std.math;
const sdl = @import("sdl");
const jok = @import("jok");
const font = jok.font;
const zmath = jok.zmath;
const j2d = jok.j2d;

const rect_size = 400;
const rect_num = 1000;
pub const jok_window_width: u32 = 2 * rect_size;
pub const jok_window_height: u32 = 2 * rect_size;

pub fn init(ctx: *jok.Context) !void {
    _ = ctx;
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
    const scale_step = jok.utils.math.mapf(
        @floatCast(f32, math.sin(ctx.seconds)),
        -1,
        1,
        0.71,
        0.99,
    );
    const angle_step =
        math.asin(1 / (scale_step * math.sqrt(2.0))) - math.pi / 4.0;

    try j2d.begin(.{});
    var i: u32 = 0;
    while (i < rect_num) : (i += 1) {
        const step = @intToFloat(f32, i);
        var transform = j2d.AffineTransform.init();
        transform.scale(.{
            .x = math.pow(f32, scale_step, step),
            .y = math.pow(f32, scale_step, step),
        });

        // top-left
        {
            var tr = transform.clone();
            tr.rotateByOrgin(-angle_step * step);
            tr.translate(.{
                .x = @intToFloat(f32, fb_size.w / 4),
                .y = @intToFloat(f32, fb_size.h / 4),
            });
            j2d.setTransform(tr);
            try j2d.addQuad(
                .{ .x = -rect_size / 2, .y = -rect_size / 2 },
                .{ .x = rect_size / 2, .y = -rect_size / 2 },
                .{ .x = rect_size / 2, .y = rect_size / 2 },
                .{ .x = -rect_size / 2, .y = rect_size / 2 },
                sdl.Color.white,
                .{},
            );
        }

        // top-right
        {
            var tr = transform.clone();
            tr.rotateByOrgin(angle_step * step);
            tr.translate(.{
                .x = @intToFloat(f32, fb_size.w * 3 / 4),
                .y = @intToFloat(f32, fb_size.h / 4),
            });
            j2d.setTransform(tr);
            try j2d.addQuad(
                .{ .x = -rect_size / 2, .y = -rect_size / 2 },
                .{ .x = rect_size / 2, .y = -rect_size / 2 },
                .{ .x = rect_size / 2, .y = rect_size / 2 },
                .{ .x = -rect_size / 2, .y = rect_size / 2 },
                sdl.Color.white,
                .{},
            );
        }

        // bottom-right
        {
            var tr = transform.clone();
            tr.rotateByOrgin(-angle_step * step);
            tr.translate(.{
                .x = @intToFloat(f32, fb_size.w * 3 / 4),
                .y = @intToFloat(f32, fb_size.h * 3 / 4),
            });
            j2d.setTransform(tr);
            try j2d.addQuad(
                .{ .x = -rect_size / 2, .y = -rect_size / 2 },
                .{ .x = rect_size / 2, .y = -rect_size / 2 },
                .{ .x = rect_size / 2, .y = rect_size / 2 },
                .{ .x = -rect_size / 2, .y = rect_size / 2 },
                sdl.Color.white,
                .{},
            );
        }

        // bottom-left
        {
            var tr = transform.clone();
            tr.rotateByOrgin(angle_step * step);
            tr.translate(.{
                .x = @intToFloat(f32, fb_size.w / 4),
                .y = @intToFloat(f32, fb_size.h * 3 / 4),
            });
            j2d.setTransform(tr);
            try j2d.addQuad(
                .{ .x = -rect_size / 2, .y = -rect_size / 2 },
                .{ .x = rect_size / 2, .y = -rect_size / 2 },
                .{ .x = rect_size / 2, .y = rect_size / 2 },
                .{ .x = -rect_size / 2, .y = rect_size / 2 },
                sdl.Color.white,
                .{},
            );
        }
    }
    try j2d.end();
}

pub fn quit(ctx: *jok.Context) void {
    _ = ctx;
}
