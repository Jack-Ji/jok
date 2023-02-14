const std = @import("std");
const math = std.math;
const sdl = @import("sdl");
const jok = @import("jok");
const j2d = jok.j2d;

pub const jok_window_width: u32 = 1024;
pub const jok_window_height: u32 = 768;

var path: j2d.Path = undefined;

pub fn init(ctx: *jok.Context) !void {
    std.log.info("game init", .{});

    path = j2d.Path.begin(ctx.allocator);
}

pub fn event(ctx: *jok.Context, e: sdl.Event) !void {
    _ = ctx;
    _ = e;
}

pub fn update(ctx: *jok.Context) !void {
    _ = ctx;
}

pub fn draw(ctx: *jok.Context) !void {
    const statechange = math.sin(ctx.seconds) * 0.2;
    const scale = @intToFloat(f32, ctx.getFramebufferSize().h) / 4;

    path.reset();
    var i: usize = 0;
    while (i < 360 * 4 + 1) : (i += 1) {
        var point = sdl.PointF{ .x = 0, .y = 0 };
        var j: usize = 0;
        while (j < 5) : (j += 1) {
            const angle = jok.utils.math.degreeToRadian(@intToFloat(f32, i) / 4 * math.pow(f32, @as(f32, 3.0), @intToFloat(f32, j)));
            const off = math.pow(f32, 0.4 + statechange, @intToFloat(f32, j));
            point.x += math.cos(angle) * off;
            point.y += math.sin(angle) * off;
        }
        try path.lineTo(point);
    }
    path.end(.stroke, .{ .closed = true });

    var transform = j2d.AffineTransform.init();
    transform.scale(.{ .x = scale, .y = scale });
    transform.translate(.{
        .x = @intToFloat(f32, ctx.getFramebufferSize().w / 2),
        .y = @intToFloat(f32, ctx.getFramebufferSize().h / 2),
    });
    try j2d.begin(.{ .transform = transform });
    try j2d.addPath(path, .{});
    try j2d.end();
}

pub fn quit(ctx: *jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});

    path.deinit();
}
