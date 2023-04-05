const std = @import("std");
const math = std.math;
const jok = @import("jok");
const sdl = jok.sdl;
const font = jok.font;
const zmath = jok.zmath;
const j2d = jok.j2d;

const radius = 400;
pub const jok_window_size = jok.config.WindowSize{
    .custom = .{ .width = 2 * radius, .height = 2 * radius },
};

var rot: f32 = 0.3;
const ntex = 50;
const render_interval = 2.0 / @as(f32, ntex);
var targets = std.TailQueue(sdl.Texture){};
var render_time: f32 = render_interval;
var clear_color: ?sdl.Color = sdl.Color.rgba(0, 0, 0, 0);

pub fn init(ctx: jok.Context) !void {
    for (0..ntex) |_| {
        var node = try ctx.allocator().create(std.TailQueue(sdl.Texture).Node);
        node.data = try jok.utils.gfx.createTextureAsTarget(ctx.renderer(), null);
        targets.append(node);
    }
}

pub fn event(ctx: jok.Context, e: sdl.Event) !void {
    _ = ctx;
    _ = e;
}

pub fn update(ctx: jok.Context) !void {
    _ = ctx;
}

pub fn draw(ctx: jok.Context) !void {
    // Swap oldest to newest if needed
    render_time -= ctx.deltaSeconds();
    if (render_time < 0) {
        render_time = render_interval;
        targets.append(targets.popFirst().?);
        clear_color = sdl.Color.rgba(0, 0, 0, 0);
    } else {
        clear_color = null;
    }

    // Render to last texture
    _ = try jok.utils.gfx.renderToTexture(
        ctx.renderer(),
        struct {
            seconds: f32,

            pub fn draw(self: @This(), _: sdl.Renderer, size: sdl.PointF) !void {
                const ncircle = 20;
                rot += 0.3;
                if (rot > 360.0) rot = 0.3;

                try j2d.begin(.{});
                for (0..ncircle) |i| {
                    var tr = j2d.AffineTransform.init();
                    tr.translate(.{ .x = size.x / 2, .y = size.y / 2 });
                    tr.translateX(jok.utils.math.linearMap(
                        math.sin(self.seconds),
                        -1,
                        1,
                        -radius,
                        radius,
                    ));
                    tr.rotateByPoint(
                        .{ .x = size.x / 2, .y = size.y / 2 },
                        jok.utils.math.degreeToRadian(rot + 360.0 * @intToFloat(f32, i) / @intToFloat(f32, ncircle)),
                    );
                    j2d.setTransform(tr);
                    try j2d.circleFilled(.{ .x = 0, .y = 0 }, 10, sdl.Color.green, .{});
                }
                try j2d.end();
            }
        }{ .seconds = ctx.seconds() },
        .{
            .target = targets.last.?.data,
            .clear_color = clear_color,
        },
    );

    // Draw layers (from oldest to newest)
    try j2d.begin(.{});
    var node = targets.first;
    var idx: u32 = 0;
    while (node) |n| {
        const c = @floatToInt(
            u8,
            jok.utils.math.linearMap(@intToFloat(f32, idx), 0, ntex, 0, 255),
        );
        try j2d.image(n.data, .{ .x = 0, .y = 0 }, .{
            .tint_color = sdl.Color.rgba(255, 255, 255, c),
        });
        idx += 1;
        node = n.next;
    }
    try j2d.end();
}

pub fn quit(ctx: jok.Context) void {
    var node = targets.first;
    while (node) |n| {
        node = n.next;
        ctx.allocator().destroy(n);
    }
}
