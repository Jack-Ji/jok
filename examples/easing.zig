const std = @import("std");
const jok = @import("jok");
const sdl = jok.sdl;
const j2d = jok.j2d;
const easing = jok.utils.easing;

pub const jok_window_height = 800;

var point_easing_system: *easing.EasingSystem(sdl.PointF) = undefined;
var blocks: [31]EasingBlock = undefined;
var easing_over_time_accu: f32 = 0;

const EasingBlock = struct {
    pos: sdl.PointF,

    fn draw(self: @This()) !void {
        try j2d.addRectRoundedFilled(.{
            .x = self.pos.x,
            .y = self.pos.y,
            .width = 20,
            .height = 20,
        }, sdl.Color.white, .{});
    }
};

pub fn init(ctx: jok.Context) !void {
    point_easing_system =
        try easing.EasingSystem(sdl.PointF).create(ctx.allocator());
    for (&blocks, 0..) |*b, i| {
        try point_easing_system.add(
            &b.pos,
            @intToEnum(easing.EasingType, @intCast(u8, i)),
            easing.easePointF,
            2,
            .{
                .x = 150,
                .y = 1 + @intToFloat(f32, i) * 25,
            },
            .{
                .x = 680,
                .y = 1 + @intToFloat(f32, i) * 25,
            },
        );
    }
}

pub fn event(ctx: jok.Context, e: sdl.Event) !void {
    _ = ctx;
    _ = e;
}

pub fn update(ctx: jok.Context) !void {
    point_easing_system.update(ctx.deltaSeconds());
    if (point_easing_system.count() == 0) {
        easing_over_time_accu += ctx.deltaSeconds();
        if (easing_over_time_accu > 1) {
            for (&blocks, 0..) |*b, i| {
                try point_easing_system.add(
                    &b.pos,
                    @intToEnum(easing.EasingType, @intCast(u8, i)),
                    easing.easePointF,
                    2,
                    .{
                        .x = 150,
                        .y = 1 + @intToFloat(f32, i) * 25,
                    },
                    .{
                        .x = 680,
                        .y = 1 + @intToFloat(f32, i) * 25,
                    },
                );
            }
            easing_over_time_accu = 0;
        }
    }
}

pub fn draw(ctx: jok.Context) !void {
    try j2d.begin(.{});
    for (blocks, 0..) |b, i| {
        try j2d.addRectFilled(
            .{
                .x = 150,
                .y = @intToFloat(f32, i) * 25,
                .width = 550,
                .height = 25,
            },
            sdl.Color.rgb(
                @intCast(u8, i) * 4,
                @intCast(u8, i) * 4,
                @intCast(u8, i) * 4,
            ),
            .{},
        );
        try j2d.addText(
            .{
                .atlas = try jok.font.DebugFont.getAtlas(ctx, 16),
                .pos = .{ .x = 10, .y = @intToFloat(f32, i) * 25 },
            },
            "{s}",
            .{@tagName(@intToEnum(easing.EasingType, @intCast(u8, i)))},
        );
        try b.draw();
        try j2d.addLine(
            .{ .x = 0, .y = @intToFloat(f32, i) * 25 + 20 },
            .{ .x = 750, .y = @intToFloat(f32, i) * 25 + 20 },
            sdl.Color.white,
            .{},
        );
    }
    try j2d.end();
}

pub fn quit(ctx: jok.Context) void {
    _ = ctx;

    point_easing_system.destroy();
}
