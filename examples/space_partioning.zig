const std = @import("std");
const jok = @import("jok");
const j2d = jok.j2d;
const geom = j2d.geom;
const utils = jok.utils;
const zgui = jok.vendor.zgui;

pub const jok_window_size = jok.config.WindowSize{
    .custom = .{ .width = 1200, .height = 900 },
};

const maximum_obj_size = 5000;

const PartitionType = enum {
    quad_tree,
    spatial_hash,
};

const SpatialPartition = union(PartitionType) {
    quad_tree: *utils.QuadTree(u32, .{}),
    spatial_hash: *utils.SpatialHash(u32, .{}),

    fn create(allocator: std.mem.Allocator, ptype: PartitionType, rect: geom.Rectangle) !SpatialPartition {
        return switch (ptype) {
            .quad_tree => .{ .quad_tree = try utils.QuadTree(u32, .{}).create(allocator, rect) },
            .spatial_hash => .{ .spatial_hash = try utils.SpatialHash(u32, .{}).create(allocator, .{
                .x = @intFromFloat(rect.x),
                .y = @intFromFloat(rect.y),
                .width = @intFromFloat(rect.width),
                .height = @intFromFloat(rect.height),
            }) },
        };
    }

    fn destroy(self: *SpatialPartition) void {
        switch (self.*) {
            .quad_tree => |qt| qt.destroy(),
            .spatial_hash => |sh| sh.destroy(),
        }
    }

    fn clear(self: *SpatialPartition) void {
        switch (self.*) {
            .quad_tree => |qt| qt.clear(),
            .spatial_hash => |sh| sh.clear(),
        }
    }

    fn put(self: *SpatialPartition, obj: u32, pos: geom.Point, size: ?geom.Size) !void {
        switch (self.*) {
            .quad_tree => |qt| {
                if (size) |s| {
                    try qt.put(obj, pos, .{ .size = s });
                } else {
                    try qt.put(obj, pos, .{});
                }
            },
            .spatial_hash => |sh| {
                if (size) |s| {
                    try sh.put(obj, pos, .{ .size = s });
                } else {
                    try sh.put(obj, pos, .{});
                }
            },
        }
    }

    fn update(self: *SpatialPartition, obj: u32, pos: geom.Point) !void {
        switch (self.*) {
            .quad_tree => |qt| try qt.update(obj, pos),
            .spatial_hash => |sh| try sh.update(obj, pos),
        }
    }

    fn remove(self: *SpatialPartition, obj: u32) void {
        switch (self.*) {
            .quad_tree => |qt| qt.remove(obj),
            .spatial_hash => |sh| sh.remove(obj),
        }
    }

    fn query(self: *SpatialPartition, rect: geom.Rectangle, padding: f32, results: *std.array_list.Managed(u32), precise: bool) !void {
        switch (self.*) {
            .quad_tree => |qt| try qt.query(rect, padding, results, .{ .precise = precise }),
            .spatial_hash => |sh| try sh.query(rect, padding, results, .{ .precise = precise }),
        }
    }

    fn draw(self: *SpatialPartition, b: *j2d.Batch, query_rect: ?geom.Rectangle) !void {
        switch (self.*) {
            .quad_tree => |qt| try qt.draw(b, .{ .query = query_rect }),
            .spatial_hash => |sh| try sh.draw(b, .{ .query = query_rect }),
        }
    }
};

var rng: std.Random.DefaultPrng = undefined;
var batchpool: j2d.BatchPool(64, false) = undefined;
var partition: SpatialPartition = undefined;
var partition_type: PartitionType = .quad_tree;
var objs: std.ArrayList(Object) = undefined;
var move_in_tree: bool = false;
var use_sizes: bool = false;
var do_query: bool = false;
var precise_query: bool = false;
var query_size: geom.Size = undefined;
var query_result: std.array_list.Managed(u32) = undefined;

const Object = struct {
    pos: geom.Point,
    velocity: geom.Point,
    size: geom.Size,

    fn draw(o: Object, b: *j2d.Batch, color: ?jok.Color, show_size: bool) !void {
        if (show_size) {
            // Draw as rectangle with size
            const rect = geom.Rectangle{
                .x = o.pos.x - o.size.getWidthFloat() * 0.5,
                .y = o.pos.y - o.size.getHeightFloat() * 0.5,
                .width = o.size.getWidthFloat(),
                .height = o.size.getHeightFloat(),
            };
            try b.rectFilled(rect, color orelse .blue, .{});
        } else {
            // Draw as point (circle)
            try b.circleFilled(.{ .center = o.pos, .radius = 5 }, color orelse .blue, .{});
        }
    }
};

pub fn init(ctx: jok.Context) !void {
    std.log.info("game init", .{});

    const now = std.Io.Clock.awake.now(ctx.io());
    rng = std.Random.DefaultPrng.init(@intCast(now.toMilliseconds()));
    batchpool = try @TypeOf(batchpool).init(ctx);
    partition = try SpatialPartition.create(ctx.allocator(), partition_type, ctx.getCanvasSize().toRect(.origin));
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
            .size = .{
                .width = @intFromFloat(10 + rd.float(f32) * 30),
                .height = @intFromFloat(10 + rd.float(f32) * 30),
            },
        });
    }

    if (!move_in_tree) partition.clear();
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
            partition.update(@intCast(i), c.pos) catch |e| {
                if (e != error.NotSeeable) @panic("oops");
            };
        } else {
            const obj_size = if (use_sizes) c.size else null;
            partition.put(@intCast(i), c.pos, obj_size) catch |e| {
                if (e != error.NotSeeable) @panic("oops");
            };
        }
    }
}

pub fn draw(ctx: jok.Context) !void {
    try ctx.renderer().clear(.white);
    ctx.displayStats(.{});

    zgui.setNextWindowPos(.{ .x = 50, .y = 200, .cond = .once });
    if (zgui.begin("Space Partitioning", .{ .flags = .{ .always_auto_resize = true } })) {
        // Partition type selector
        const old_type = partition_type;
        if (zgui.comboFromEnum("Partition Type", &partition_type)) {
            if (partition_type != old_type) {
                // Switch partition type
                partition.destroy();
                partition = try SpatialPartition.create(ctx.allocator(), partition_type, ctx.getCanvasSize().toRect(.origin));

                // Re-insert all existing objects into the new partition
                for (objs.items, 0..) |obj, idx| {
                    const obj_size = if (use_sizes) obj.size else null;
                    partition.put(@intCast(idx), obj.pos, obj_size) catch |e| {
                        if (e != error.NotSeeable and e != error.AlreadyExists) {
                            std.log.err("Failed to re-insert object {}: {}", .{ idx, e });
                        }
                    };
                }
            }
        }

        zgui.separator();

        if (zgui.button("Clear Objects", .{})) {
            objs.clearRetainingCapacity();
            partition.clear();
        }
        if (zgui.button("Clear 1/2 Objects", .{})) {
            const obj_size = objs.items.len / 2;
            while (objs.items.len > obj_size) {
                _ = objs.pop();
                partition.remove(@intCast(objs.items.len));
            }
        }
        _ = zgui.checkbox("Move In Tree", .{ .v = &move_in_tree });
        _ = zgui.checkbox("Use Object Sizes", .{ .v = &use_sizes });

        zgui.separator();
        _ = zgui.checkbox("Test Query", .{ .v = &do_query });
        if (do_query) {
            _ = zgui.checkbox("Precise Query", .{ .v = &precise_query });
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
    var query_rect: ?geom.Rectangle = null;
    if (do_query) {
        const mouse = jok.io.getMouseState(ctx);
        query_rect = .{
            .x = mouse.pos.x - query_size.getWidthFloat() * 0.5,
            .y = mouse.pos.y - query_size.getHeightFloat() * 0.5,
            .width = query_size.getWidthFloat(),
            .height = query_size.getHeightFloat(),
        };
        try partition.query(query_rect.?, 0, &query_result, precise_query);
    }

    var b = try batchpool.new(.{ .depth_sort = .back_to_front });
    defer b.submit();
    try partition.draw(b, query_rect);
    for (objs.items, 0..) |o, i| {
        for (query_result.items) |j| {
            if (i == @as(usize, @intCast(j))) {
                try o.draw(b, .red, use_sizes);
                break;
            }
        } else try o.draw(b, null, use_sizes);
    }
    if (do_query) {
        try b.rectFilled(query_rect.?, .rgba(50, 0, 0, 100), .{});
    }
}

pub fn quit(ctx: jok.Context) void {
    std.log.info("game quit", .{});
    query_result.deinit();
    objs.deinit(ctx.allocator());
    partition.destroy();
    batchpool.deinit();
}
