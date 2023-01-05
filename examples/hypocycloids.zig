const std = @import("std");
const math = std.math;
const sdl = @import("sdl");
const jok = @import("jok");
const primitive = jok.j2d.primitive;

pub const jok_window_width: u32 = 1024;
pub const jok_window_height: u32 = 768;

var pts: std.ArrayList(sdl.PointF) = undefined;

pub fn init(ctx: *jok.Context) !void {
    std.log.info("game init", .{});

    pts = std.ArrayList(sdl.PointF).init(ctx.allocator);
}

pub fn event(ctx: *jok.Context, e: sdl.Event) !void {
    _ = ctx;
    _ = e;
}

pub fn update(ctx: *jok.Context) !void {
    _ = ctx;
}

pub fn draw(ctx: *jok.Context) !void {
    const statechange = math.sin(@floatCast(f32, ctx.tick)) * 0.2;
    const scale = @intToFloat(f32, ctx.getFramebufferSize().h) / 4;

    pts.clearRetainingCapacity();
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
        try pts.append(point);
    }

    primitive.clear(.{});
    primitive.addPolyline(pts.items, sdl.Color.white, .{
        .trs = .{
            .scale = .{ .x = scale, .y = scale },
            .offset = .{
                .x = @intToFloat(f32, ctx.getFramebufferSize().w / 2),
                .y = @intToFloat(f32, ctx.getFramebufferSize().h / 2),
            },
        },
        .closed = true,
    });
    try primitive.draw();
}

pub fn quit(ctx: *jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});

    pts.deinit();
}
