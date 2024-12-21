const std = @import("std");
const math = std.math;
const jok = @import("jok");
const j2d = jok.j2d;

pub const jok_window_size = jok.config.WindowSize{
    .custom = .{ .width = 1024, .height = 768 },
};

var batchpool: j2d.BatchPool(64, false) = undefined;
var path: j2d.Path = undefined;

pub fn init(ctx: jok.Context) !void {
    std.log.info("game init", .{});

    batchpool = try @TypeOf(batchpool).init(ctx);
    path = j2d.Path.begin(ctx.allocator());
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

    const statechange = math.sin(ctx.seconds()) * 0.2;
    const scale = ctx.getCanvasSize().getHeightFloat() / 4;

    path.reset(true);
    var i: usize = 0;
    while (i < 360 * 4 + 1) : (i += 1) {
        var point = jok.Point{ .x = 0, .y = 0 };
        var j: usize = 0;
        while (j < 5) : (j += 1) {
            const angle = std.math.degreesToRadians(
                @as(f32, @floatFromInt(i)) / 4 * math.pow(f32, 3.0, @as(f32, @floatFromInt(j))),
            );
            const off = math.pow(f32, 0.4 + statechange, @as(f32, @floatFromInt(j)));
            point.x += math.cos(angle) * off;
            point.y += math.sin(angle) * off;
        }
        try path.lineTo(point);
    }
    path.end(.stroke, .{ .closed = true });

    var b = try batchpool.new(.{});
    defer b.submit();
    b.trs = j2d.AffineTransform.init()
        .scale(.{ .x = scale, .y = scale })
        .translate(.{
        .x = ctx.getCanvasSize().getWidthFloat() / 2,
        .y = ctx.getCanvasSize().getHeightFloat() / 2,
    });
    try b.path(path, .{});
}

pub fn quit(ctx: jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});

    path.deinit();
    batchpool.deinit();
}
