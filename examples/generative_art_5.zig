// Enspired by https://www.reddit.com/r/woahdude/comments/anh3os/lissajous_curve_table/
const std = @import("std");
const jok = @import("jok");
const j2d = jok.j2d;

pub const jok_window_size = jok.config.WindowSize.maximized;
pub const jok_window_resizable = true;
pub const jok_canvas_size = jok.Size{
    .width = 800,
    .height = 800,
};

const max_points = 800;
const radius1: f32 = 45;
const radius2: f32 = 5;
const radius3: f32 = 3;
const thickness: f32 = 2;
const colors = [7]jok.Color{
    .red,
    .green,
    .blue,
    .magenta,
    .cyan,
    .yellow,
    .purple,
};
var batchpool: j2d.BatchPool(64, false) = undefined;
var points_angular_velocity: [7]f32 = undefined;
var points_row: [7]jok.Point = undefined;
var points_col: [7]jok.Point = undefined;
var curves: [49]j2d.Polyline = undefined;

pub fn init(ctx: jok.Context) !void {
    batchpool = try @TypeOf(batchpool).init(ctx);
    for (0..7) |i| {
        points_angular_velocity[i] = @floatFromInt((i + 1) * 30);
        points_row[i] = .{
            .x = @floatFromInt(100 * (i + 1) + 95),
            .y = 50,
        };
        points_col[i] = .{
            .x = 95,
            .y = @floatFromInt(100 * (i + 1) + 50),
        };
    }

    for (&curves) |*c| {
        c.* = j2d.Polyline.begin(ctx.allocator());
    }
}

pub fn event(ctx: jok.Context, e: jok.Event) !void {
    _ = ctx;
    _ = e;
}

pub fn update(ctx: jok.Context) !void {
    for (0..7) |i| {
        const rotation = std.math.degreesToRadians(points_angular_velocity[i] * ctx.deltaSeconds());
        var trs = j2d.AffineTransform.init().rotateByPoint(.{
            .x = @floatFromInt(100 * (i + 1) + 50),
            .y = 50,
        }, rotation);
        points_row[i] = trs.transformPoint(points_row[i]);

        trs = j2d.AffineTransform.init().rotateByPoint(.{
            .x = 50,
            .y = @floatFromInt(100 * (i + 1) + 50),
        }, rotation);
        points_col[i] = trs.transformPoint(points_col[i]);
    }

    for (0..7) |j| {
        for (0..7) |i| {
            const idx = j * 7 + i;
            curves[idx].reset(false);
            defer curves[idx].end();
            try curves[idx].point(.{
                .x = points_row[i].x,
                .y = points_col[j].y,
            });
            if (curves[idx].points.items.len > max_points) {
                _ = curves[idx].points.orderedRemove(0);
            }
        }
    }
}

pub fn draw(ctx: jok.Context) !void {
    try ctx.renderer().clear(.rgb(50, 50, 50));
    ctx.displayStats(.{});

    var b = try batchpool.new(.{});
    defer b.submit();
    for (0..7) |i| {
        try b.line(
            points_row[i].add(.{ .x = 0, .y = -800 }),
            points_row[i].add(.{ .x = 0, .y = 800 }),
            .rgba(30, 30, 30, 128),
            .{},
        );
        try b.line(
            points_col[i].add(.{ .x = -800, .y = 0 }),
            points_col[i].add(.{ .x = 800, .y = 0 }),
            .rgba(30, 30, 30, 128),
            .{},
        );
        try b.circle(
            .{
                .center = .{ .x = @floatFromInt(100 * (i + 1) + 50), .y = 50 },
                .radius = radius1,
            },
            colors[i],
            .{ .thickness = thickness },
        );
        try b.circle(
            .{
                .center = .{ .x = 50, .y = @floatFromInt(100 * (i + 1) + 50) },
                .radius = radius1,
            },
            colors[i],
            .{ .thickness = thickness },
        );
        try b.circleFilled(.{ .center = points_row[i], .radius = radius2 }, .white, .{});
        try b.circleFilled(.{ .center = points_col[i], .radius = radius2 }, .white, .{});
    }
    for (0..7) |j| {
        for (0..7) |i| {
            const idx = j * 7 + i;
            try b.polyline(curves[idx], colors[i], .{ .thickness = thickness });
            try b.circleFilled(
                .{
                    .center = .{ .x = points_row[i].x, .y = points_col[j].y },
                    .radius = radius3,
                },
                .white,
                .{},
            );
        }
    }
}

pub fn quit(ctx: jok.Context) void {
    _ = ctx;

    for (&curves) |*c| {
        c.deinit();
    }
    batchpool.deinit();
}
