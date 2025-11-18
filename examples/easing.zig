const std = @import("std");
const jok = @import("jok");
const j2d = jok.j2d;
const easing = jok.utils.easing;

pub const jok_window_size = jok.config.WindowSize{
    .custom = .{ .width = 800, .height = 800 },
};

const PointEase = easing.EasingSystem(jok.Point);

var batchpool: j2d.BatchPool(64, false) = undefined;
var point_easing_system: *PointEase = undefined;
var blocks: [31]EasingBlock = undefined;

const EasingBlock = struct {
    id: u32,
    pos: jok.Point,

    fn draw(self: @This(), batch: *j2d.Batch) !void {
        try batch.rectRoundedFilled(.{
            .x = self.pos.x,
            .y = self.pos.y,
            .width = 20,
            .height = 20,
        }, .white, .{});
    }

    fn startEasing(self: *@This(), es: *PointEase) !void {
        try es.add(
            &self.pos,
            easing.getEasingFn(@enumFromInt(@as(u8, @intCast(self.id)))),
            easing.easePoint,
            2,
            .{
                .x = 150,
                .y = 1 + @as(f32, @floatFromInt(self.id)) * 25,
            },
            .{
                .x = 680,
                .y = 1 + @as(f32, @floatFromInt(self.id)) * 25,
            },
            .{ .wait_time = 1 },
        );
    }
};

fn finishEase(ev: *const PointEase.EasingValue) void {
    point_easing_system.add(
        ev.v,
        ev.easing_fn,
        ev.easing_apply_fn,
        ev.life_total,
        ev.to,
        ev.from,
        .{ .wait_time = 1 },
    ) catch unreachable;
}

pub fn init(ctx: jok.Context) !void {
    batchpool = try @TypeOf(batchpool).init(ctx);
    point_easing_system = try PointEase.create(ctx.allocator());
    _ = try point_easing_system.sig.connect(finishEase, .{});
    for (&blocks, 0..) |*b, i| {
        b.* = .{
            .id = @intCast(i),
            .pos = .{
                .x = 150,
                .y = 1 + @as(f32, @floatFromInt(i)) * 25,
            },
        };
        try b.startEasing(point_easing_system);
    }
}

pub fn event(ctx: jok.Context, e: jok.Event) !void {
    _ = ctx;
    _ = e;
}

pub fn update(ctx: jok.Context) !void {
    point_easing_system.update(ctx.deltaSeconds());
}

pub fn draw(ctx: jok.Context) !void {
    try ctx.renderer().clear(.none);

    var b = try batchpool.new(.{});
    defer b.submit();
    for (blocks, 0..) |eb, i| {
        try b.rectFilled(
            .{
                .x = 150,
                .y = @as(f32, @floatFromInt(i)) * 25,
                .width = 550,
                .height = 25,
            },
            .rgb(
                @as(u8, @intCast(i)) * 4,
                @as(u8, @intCast(i)) * 4,
                @as(u8, @intCast(i)) * 4,
            ),
            .{},
        );
        try b.text(
            "{s}",
            .{@tagName(@as(easing.EasingType, @enumFromInt(@as(u8, @intCast(i)))))},
            .{
                .atlas = try jok.font.DebugFont.getAtlas(ctx, 16),
                .pos = .{ .x = 10, .y = @as(f32, @floatFromInt(i)) * 25 },
            },
        );
        try eb.draw(b);
        try b.line(
            .{ .x = 0, .y = @as(f32, @floatFromInt(i)) * 25 + 20 },
            .{ .x = 750, .y = @as(f32, @floatFromInt(i)) * 25 + 20 },
            .white,
            .{},
        );
    }
}

pub fn quit(ctx: jok.Context) void {
    _ = ctx;
    point_easing_system.destroy();
    batchpool.deinit();
}
