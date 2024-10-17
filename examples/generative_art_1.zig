const std = @import("std");
const math = std.math;
const jok = @import("jok");
const zmath = jok.zmath;
const j2d = jok.j2d;

const radius = 400;
pub const jok_window_size = jok.config.WindowSize{
    .custom = .{ .width = 2 * radius, .height = 2 * radius },
};

var rot: f32 = 0.3;
const ntex = 50;
const render_interval = 2.0 / @as(f32, ntex);
var targets = std.DoublyLinkedList(jok.Texture){};
var render_time: f32 = render_interval;
var clear_color: ?jok.Color = jok.Color.rgba(0, 0, 0, 0);

pub fn init(ctx: jok.Context) !void {
    for (0..ntex) |_| {
        var node = try ctx.allocator().create(std.DoublyLinkedList(jok.Texture).Node);
        node.data = try ctx.renderer().createTarget(.{});
        targets.append(node);
    }
}

pub fn event(ctx: jok.Context, e: jok.Event) !void {
    _ = ctx;
    _ = e;
}

pub fn update(ctx: jok.Context) !void {
    _ = ctx;
}

pub fn draw(ctx: jok.Context) !void {
    try ctx.renderer().clear(clear_color);

    // Swap oldest to newest if needed
    render_time -= ctx.deltaSeconds();
    if (render_time < 0) {
        render_time = render_interval;
        targets.append(targets.popFirst().?);
        clear_color = jok.Color.rgba(0, 0, 0, 0);
    } else {
        clear_color = null;
    }

    // Render to last texture
    {
        const csz = ctx.getCanvasSize();
        const ncircle = 20;
        rot += 0.3;
        if (rot > 360.0) rot = 0.3;

        j2d.begin(.{
            .offscreen_target = targets.last.?.data,
            .offscreen_clear_color = clear_color,
        });
        defer j2d.end();

        for (0..ncircle) |i| {
            var tr = j2d.AffineTransform.init();
            tr.translate(.{ .x = csz.getWidthFloat() / 2, .y = csz.getHeightFloat() / 2 });
            tr.translateX(jok.utils.math.linearMap(
                math.sin(ctx.seconds()),
                -1,
                1,
                -radius,
                radius,
            ));
            tr.rotateByPoint(
                .{ .x = csz.getWidthFloat() / 2, .y = csz.getHeightFloat() / 2 },
                jok.utils.math.degreeToRadian(rot + 360.0 * @as(f32, @floatFromInt(i)) / @as(f32, @floatFromInt(ncircle))),
            );
            j2d.setTransform(tr);
            try j2d.circleFilled(.{ .x = 0, .y = 0 }, 10, jok.Color.green, .{});
        }
    }

    // Draw layers (from oldest to newest)
    j2d.begin(.{});
    defer j2d.end();
    var node = targets.first;
    var idx: u32 = 0;
    while (node) |n| {
        const c = @as(u8, @intFromFloat(
            jok.utils.math.linearMap(@floatFromInt(idx), 0, ntex, 0, 255),
        ));
        try j2d.image(n.data, .{ .x = 0, .y = 0 }, .{
            .tint_color = jok.Color.rgba(255, 255, 255, c),
        });
        idx += 1;
        node = n.next;
    }
}

pub fn quit(ctx: jok.Context) void {
    while (targets.pop()) |n| {
        ctx.allocator().destroy(n);
    }
}
