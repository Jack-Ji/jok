const std = @import("std");
const math = std.math;
const jok = @import("jok");
const font = jok.font;
const zmath = jok.zmath;
const j2d = jok.j2d;

const rect_size = 400;
const rect_num = 1000;
pub const jok_window_size = jok.config.WindowSize{
    .custom = .{ .width = 2 * rect_size, .height = 2 * rect_size },
};

pub fn init(ctx: jok.Context) !void {
    _ = ctx;
}

pub fn event(ctx: jok.Context, e: jok.Event) !void {
    _ = ctx;
    _ = e;
}

pub fn update(ctx: jok.Context) !void {
    _ = ctx;
}

pub fn draw(ctx: jok.Context) !void {
    try ctx.renderer().clear(null);

    const fb_size = ctx.getCanvasSize();
    const rect = jok.Rectangle{
        .x = -rect_size / 2,
        .y = -rect_size / 2,
        .width = rect_size,
        .height = rect_size,
    };
    const scale_step = jok.utils.math.linearMap(
        math.sin(ctx.seconds()),
        -1,
        1,
        0.71,
        0.99,
    );
    const angle_step =
        math.asin(1 / (scale_step * math.sqrt(2.0))) - math.pi / 4.0;

    j2d.begin(.{});
    defer j2d.end();
    var i: u32 = 0;
    while (i < rect_num) : (i += 1) {
        const step = @as(f32, @floatFromInt(i));
        var transform = j2d.AffineTransform.init();
        transform.scale(.{
            .x = math.pow(f32, scale_step, step),
            .y = math.pow(f32, scale_step, step),
        });

        // top-left
        {
            var tr = transform.clone();
            tr.rotateByOrigin(-angle_step * step);
            tr.translate(.{
                .x = fb_size.getWidthFloat() / 4,
                .y = fb_size.getHeightFloat() / 4,
            });
            j2d.setTransform(tr);
            try j2d.rect(rect, jok.Color.white, .{});
        }

        // top-right
        {
            var tr = transform.clone();
            tr.rotateByOrigin(angle_step * step);
            tr.translate(.{
                .x = fb_size.getWidthFloat() * 3 / 4,
                .y = fb_size.getHeightFloat() / 4,
            });
            j2d.setTransform(tr);
            try j2d.rect(rect, jok.Color.white, .{});
        }

        // bottom-right
        {
            var tr = transform.clone();
            tr.rotateByOrigin(-angle_step * step);
            tr.translate(.{
                .x = fb_size.getWidthFloat() * 3 / 4,
                .y = fb_size.getHeightFloat() * 3 / 4,
            });
            j2d.setTransform(tr);
            try j2d.rect(rect, jok.Color.white, .{});
        }

        // bottom-left
        {
            var tr = transform.clone();
            tr.rotateByOrigin(angle_step * step);
            tr.translate(.{
                .x = fb_size.getWidthFloat() / 4,
                .y = fb_size.getHeightFloat() * 3 / 4,
            });
            j2d.setTransform(tr);
            try j2d.rect(rect, jok.Color.white, .{});
        }
    }
}

pub fn quit(ctx: jok.Context) void {
    _ = ctx;
}
