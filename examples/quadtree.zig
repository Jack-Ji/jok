const std = @import("std");
const jok = @import("jok");
const j2d = jok.j2d;
const utils = jok.utils;
const zgui = jok.vendor.zgui;

pub const jok_window_size = jok.config.WindowSize{
    .custom = .{ .width = 1200, .height = 900 },
};

const maximum_obj_size = 5000;

var rng: std.Random.DefaultPrng = undefined;
var batchpool: j2d.BatchPool(64, false) = undefined;
var qtree: *utils.QuadTree(u32, .{}) = undefined;
var objs: std.ArrayList(Object) = undefined;
var move_in_tree: bool = false;
var do_query: bool = false;
var query_size: jok.Size = undefined;
var query_result: std.array_list.Managed(u32) = undefined;

const Object = struct {
    pos: jok.Point,
    velocity: jok.Point,

    fn draw(o: Object, b: *j2d.Batch, color: ?jok.Color) !void {
        try b.circleFilled(.{ .center = o.pos, .radius = 5 }, color orelse .blue, .{});
    }
};

pub fn init(ctx: jok.Context) !void {
    std.log.info("game init", .{});

    const now = std.Io.Clock.awake.now(ctx.io());
    rng = std.Random.DefaultPrng.init(@intCast(now.toMilliseconds()));
    batchpool = try @TypeOf(batchpool).init(ctx);
    qtree = try utils.QuadTree(u32, .{}).create(ctx.allocator(), ctx.getCanvasSize().toRect(.origin));
    objs = try std.ArrayList(Object).initCapacity(ctx.allocator(), 1024);
    query_size = .{ .width = 10, .height = 10 };
    query_result = try std.array_list.Managed(u32).initCapacity(ctx.allocator(), 100);
}

pub fn event(ctx: jok.Context, e: jok.Event) !void {
    _ = ctx;
    _ = e;
}

pub fn update(ctx: jok.Context) !void {
    if (objs.items.len < maximum_obj_size) {
        var rd = rng.random();
        const angle = rd.float(f32) * std.math.pi * 0.5;
        try objs.append(ctx.allocator(), .{
            .pos = .origin,
            .velocity = .{
                .x = 300 * @cos(angle),
                .y = 300 * @sin(angle),
            },
        });
    }

    if (!move_in_tree) qtree.clear();
    const size = ctx.getCanvasSize();
    for (objs.items, 0..) |*c, i| {
        const curpos = c.pos;
        if (curpos.x < 0)
            c.velocity.x = @abs(c.velocity.x);
        if (curpos.x > size.getWidthFloat())
            c.velocity.x = -@abs(c.velocity.x);
        if (curpos.y < 0)
            c.velocity.y = @abs(c.velocity.y);
        if (curpos.y > size.getHeightFloat())
            c.velocity.y = -@abs(c.velocity.y);
        c.pos = c.pos.add(c.velocity.scale(ctx.deltaSeconds()));

        if (move_in_tree) {
            qtree.update(@intCast(i), c.pos) catch |e| {
                if (e != error.NotSeeable) @panic("oops");
            };
        } else {
            qtree.put(@intCast(i), c.pos) catch |e| {
                if (e != error.NotSeeable) @panic("oops");
            };
        }
    }
}

pub fn draw(ctx: jok.Context) !void {
    try ctx.renderer().clear(.white);
    ctx.displayStats(.{});

    zgui.setNextWindowPos(.{ .x = 50, .y = 200, .cond = .once });
    if (zgui.begin("test", .{})) {
        if (zgui.button("Clear Objects", .{})) {
            objs.clearRetainingCapacity();
            qtree.clear();
        }
        if (zgui.button("Clear 1/2 Objects", .{})) {
            const size = objs.items.len / 2;
            while (objs.items.len > size) {
                _ = objs.pop();
                qtree.remove(@intCast(objs.items.len));
            }
        }
        _ = zgui.checkbox("Move In Tree", .{ .v = &move_in_tree });

        zgui.separator();
        _ = zgui.checkbox("Test Query", .{ .v = &do_query });
        if (do_query) {
            _ = zgui.dragInt("Query width", .{
                .v = @ptrCast(&query_size.width),
                .min = 10,
                .max = 200,
            });
            _ = zgui.dragInt("Query height", .{
                .v = @ptrCast(&query_size.height),
                .min = 10,
                .max = 200,
            });
        }
    }
    zgui.end();

    query_result.clearRetainingCapacity();
    var query_rect: jok.Rectangle = undefined;
    if (do_query) {
        const mouse = jok.io.getMouseState(ctx);
        query_rect = .{
            .x = mouse.pos.x - query_size.getWidthFloat() * 0.5,
            .y = mouse.pos.y - query_size.getHeightFloat() * 0.5,
            .width = query_size.getWidthFloat(),
            .height = query_size.getHeightFloat(),
        };
        try qtree.query(query_rect, 0, &query_result);
    }

    var b = try batchpool.new(.{ .depth_sort = .back_to_forth });
    defer b.submit();
    try qtree.draw(b, .{ .query = query_rect });
    for (objs.items, 0..) |o, i| {
        for (query_result.items) |j| {
            if (i == @as(usize, @intCast(j))) {
                try o.draw(b, .red);
                break;
            }
        } else try o.draw(b, null);
    }
    if (do_query) {
        try b.rectFilled(query_rect, .rgba(50, 0, 0, 100), .{});
    }
}

pub fn quit(ctx: jok.Context) void {
    std.log.info("game quit", .{});
    query_result.deinit();
    objs.deinit(ctx.allocator());
    qtree.destroy();
    batchpool.deinit();
}
