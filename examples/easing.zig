const std = @import("std");
const jok = @import("jok");
const sdl = jok.sdl;
const j2d = jok.j2d;
const easing = jok.utils.easing;

pub const jok_window_size = jok.config.WindowSize{
    .custom = .{ .width = 800, .height = 800 },
};

var point_easing_system: *easing.EasingSystem(sdl.PointF) = undefined;
var blocks: [31]EasingBlock = undefined;
var easing_over_time_accu: f32 = 0;

const EasingBlock = struct {
    pos: sdl.PointF,

    fn draw(self: @This()) !void {
        try j2d.rectRoundedFilled(.{
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
            @enumFromInt(@as(u8, @intCast(i))),
            easing.easePointF,
            2,
            .{
                .x = 150,
                .y = 1 + @as(f32, @floatFromInt(i)) * 25,
            },
            .{
                .x = 680,
                .y = 1 + @as(f32, @floatFromInt(i)) * 25,
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
                    @enumFromInt(@as(u8, @intCast(i))),
                    easing.easePointF,
                    2,
                    .{
                        .x = 150,
                        .y = 1 + @as(f32, @floatFromInt(i)) * 25,
                    },
                    .{
                        .x = 680,
                        .y = 1 + @as(f32, @floatFromInt(i)) * 25,
                    },
                );
            }
            easing_over_time_accu = 0;
        }
    }
}

pub fn draw(ctx: jok.Context) !void {
    ctx.clear(null);

    j2d.begin(.{});
    defer j2d.end();
    for (blocks, 0..) |b, i| {
        try j2d.rectFilled(
            .{
                .x = 150,
                .y = @as(f32, @floatFromInt(i)) * 25,
                .width = 550,
                .height = 25,
            },
            sdl.Color.rgb(
                @as(u8, @intCast(i)) * 4,
                @as(u8, @intCast(i)) * 4,
                @as(u8, @intCast(i)) * 4,
            ),
            .{},
        );
        try j2d.text(
            .{
                .atlas = try jok.font.DebugFont.getAtlas(ctx, 16),
                .pos = .{ .x = 10, .y = @as(f32, @floatFromInt(i)) * 25 },
            },
            "{s}",
            .{@tagName(@as(easing.EasingType, @enumFromInt(@as(u8, @intCast(i)))))},
        );
        try b.draw();
        try j2d.line(
            .{ .x = 0, .y = @as(f32, @floatFromInt(i)) * 25 + 20 },
            .{ .x = 750, .y = @as(f32, @floatFromInt(i)) * 25 + 20 },
            sdl.Color.white,
            .{},
        );
    }
}

pub fn quit(ctx: jok.Context) void {
    _ = ctx;

    point_easing_system.destroy();
}
