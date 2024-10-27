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

const max_points = 1000;
const radius1: f32 = 45;
const radius2: f32 = 5;
const radius3: f32 = 3;
const colors = [7]jok.Color{
    jok.Color.red,
    jok.Color.green,
    jok.Color.blue,
    jok.Color.magenta,
    jok.Color.cyan,
    jok.Color.yellow,
    jok.Color.rgb(255, 128, 255),
};
var points_angular_velocity: [7]f32 = undefined;
var points_row: [7]jok.Point = undefined;
var points_col: [7]jok.Point = undefined;
var curves: [49]j2d.Polyline = undefined;

pub fn init(ctx: jok.Context) !void {
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
    // step
    for (0..7) |i| {
        const rotation = std.math.degreesToRadians(points_angular_velocity[i] * ctx.deltaSeconds());
        var trs = j2d.AffineTransform.init();
        trs.rotateByPoint(.{
            .x = @floatFromInt(100 * (i + 1) + 50),
            .y = 50,
        }, rotation);
        points_row[i] = trs.transformPoint(points_row[i]);

        trs.setToIdentity();
        trs.rotateByPoint(.{
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
    try ctx.renderer().clear(jok.Color.rgb(50, 50, 50));
    ctx.displayStats(.{});

    j2d.begin(.{});
    defer j2d.end();
    for (0..7) |i| {
        try j2d.circle(.{ .x = @floatFromInt(100 * (i + 1) + 50), .y = 50 }, radius1, colors[i], .{});
        try j2d.circle(.{ .x = 50, .y = @floatFromInt(100 * (i + 1) + 50) }, radius1, colors[i], .{});
        try j2d.circleFilled(points_row[i], radius2, jok.Color.white, .{});
        try j2d.circleFilled(points_col[i], radius2, jok.Color.white, .{});
        try j2d.line(
            points_row[i].add(.{ .x = 0, .y = -800 }),
            points_row[i].add(.{ .x = 0, .y = 800 }),
            jok.Color.rgba(30, 30, 30, 128),
            .{},
        );
        try j2d.line(
            points_col[i].add(.{ .x = -800, .y = 0 }),
            points_col[i].add(.{ .x = 800, .y = 0 }),
            jok.Color.rgba(30, 30, 30, 128),
            .{},
        );
    }
    for (0..7) |j| {
        for (0..7) |i| {
            const idx = j * 7 + i;
            try j2d.polyline(curves[idx], colors[i], .{});
            try j2d.circleFilled(
                .{ .x = points_row[i].x, .y = points_col[j].y },
                radius3,
                jok.Color.white,
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
}
