const std = @import("std");
const assert = std.debug.assert;
const testing = std.testing;
const jok = @import("../jok.zig");

pub const Error = error{
    InvalidRect,
    AlreadyExists,
    NotSeeable,
};

pub const SpatialOption = struct {
    size: jok.Size = .{ .width = 10, .height = 10 },
};

pub fn SpatialHash(comptime ObjectType: type, opt: SpatialOption) type {
    return struct {
        const HashTable = @This();

        allocator: std.mem.Allocator,
        buckets: [opt.size.width * opt.size.height]std.ArrayList(ObjectType),
        positions: std.AutoHashMap(ObjectType, u32),
        spatial_rect: jok.Rectangle,
        spatial_unit: jok.Size,

        pub fn create(allocator: std.mem.Allocator, rect: jok.Region) !*HashTable {
            assert(rect.area() > 0);

            if (rect.width % opt.size.width != 0 or rect.height % opt.size.height != 0) {
                return error.InvalidRect;
            }

            var sh = try allocator.create(HashTable);
            sh.* = .{
                .allocator = allocator,
                .buckets = undefined,
                .positions = std.AutoHashMap(ObjectType, u32).init(allocator),
                .spatial_rect = rect.toRect(),
                .spatial_unit = .{
                    .width = rect.width / opt.size.width,
                    .height = rect.height / opt.size.height,
                },
            };
            for (sh.buckets[0..]) |*b| {
                b.* = std.ArrayList(ObjectType).initCapacity(allocator, 10) catch unreachable;
            }
            return sh;
        }

        pub fn destroy(self: *HashTable) void {
            for (self.buckets[0..]) |*b| b.deinit(self.allocator);
            self.positions.deinit();
            self.allocator.destroy(self);
        }

        pub fn put(self: *HashTable, obj: u32, pos: jok.Point) !void {
            if (self.positions.get(obj) != null) return error.AlreadyExists;
            if (self.hash(pos)) |k| {
                self.buckets[k].append(self.allocator, obj) catch unreachable;
                self.positions.put(obj, k) catch unreachable;
            } else {
                return error.NotSeeable;
            }
        }

        pub fn update(self: *HashTable, obj: u32, pos: jok.Point) !void {
            const nk = self.hash(pos);
            if (nk == null) {
                self.remove(obj);
                return;
            }

            if (self.positions.get(obj)) |k| {
                if (k == nk.?) return; // Still in same section, no need to update

                for (0..self.buckets[k].items.len) |i| {
                    if (self.buckets[k].items[i] == obj) {
                        _ = self.buckets[k].swapRemove(i);
                        break;
                    }
                } else unreachable;
            }
            self.buckets[nk.?].append(self.allocator, obj) catch unreachable;
            self.positions.put(obj, nk.?) catch unreachable;
        }

        pub fn remove(self: *HashTable, obj: u32) void {
            if (self.positions.get(obj)) |k| {
                for (0..self.buckets[k].items.len) |i| {
                    if (self.buckets[k].items[i] == obj) {
                        _ = self.buckets[k].swapRemove(i);
                        break;
                    }
                } else unreachable;
            }
        }

        pub fn query(self: HashTable, rect: jok.Rectangle, padding: f32, results: *std.array_list.Managed(ObjectType)) !void {
            if (self.spatial_rect.intersectRect(rect.padded(padding))) |r| {
                const min_x: u32 = @intFromFloat(@floor((r.x - self.spatial_rect.x) / self.spatial_unit.getWidthFloat()));
                const min_y: u32 = @intFromFloat(@floor((r.y - self.spatial_rect.y) / self.spatial_unit.getHeightFloat()));
                const max_x: u32 = @intFromFloat(@ceil((r.x - self.spatial_rect.x + r.width) / self.spatial_unit.getWidthFloat()));
                const max_y: u32 = @intFromFloat(@ceil((r.y - self.spatial_rect.y + r.height) / self.spatial_unit.getHeightFloat()));

                const start_y = @max(0, min_y);
                const end_y = @min(opt.size.height - 1, max_y);

                const start_x = @max(0, min_x);
                const end_x = @min(opt.size.width - 1, max_x);

                var y = start_y;
                while (y <= end_y) : (y += 1) {
                    const row_start = y * opt.size.width + start_x;
                    const row_end = y * opt.size.width + end_x;

                    var k = row_start;
                    while (k <= row_end) : (k += 1) {
                        try results.appendSlice(self.buckets[k].items);
                    }
                }
            }
        }

        pub fn clear(self: *HashTable) void {
            for (self.buckets[0..]) |*b| b.clearRetainingCapacity();
            self.positions.clearRetainingCapacity();
        }

        fn hash(self: HashTable, pos: jok.Point) ?u32 {
            if (!self.spatial_rect.containsPoint(pos)) return null;
            return @as(u32, @intFromFloat(pos.y - self.spatial_rect.y)) / self.spatial_unit.height * opt.size.width +
                @as(u32, @intFromFloat(pos.x - self.spatial_rect.x)) / self.spatial_unit.width;
        }
    };
}

test "init & deinit - no leak, no UB" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var sh = try SpatialHash(u32, .{}).create(
        allocator,
        .{ .x = 0, .y = 0, .width = 640, .height = 360 },
    );
    defer sh.destroy();
}

test "put & query - single point exact cell" {
    var sh = try SpatialHash(u32, .{}).create(
        testing.allocator,
        .{ .x = 0, .y = 0, .width = 640, .height = 360 },
    );
    defer sh.destroy();

    const id: u32 = 777;
    try sh.put(id, .{ .x = 123, .y = 89 });

    var results = std.array_list.Managed(u32).init(testing.allocator);
    defer results.deinit();

    try sh.query(.{ .x = 122, .y = 88, .width = 2, .height = 2 }, 0, &results);

    try testing.expectEqual(@as(usize, 1), results.items.len);
    try testing.expectEqual(id, results.items[0]);
}

test "put - already exists → error" {
    var sh = try SpatialHash(u32, .{}).create(
        testing.allocator,
        .{ .x = 0, .y = 0, .width = 640, .height = 360 },
    );
    defer sh.destroy();

    const id: u32 = 42;

    try sh.put(id, .{ .x = 100, .y = 100 });
    try testing.expectError(error.AlreadyExists, sh.put(id, .{ .x = 200, .y = 200 }));
}

test "put - outside rect → NotSeeable" {
    var sh = try SpatialHash(u32, .{}).create(
        testing.allocator,
        .{ .x = 0, .y = 0, .width = 640, .height = 360 },
    );
    defer sh.destroy();

    try testing.expectError(error.NotSeeable, sh.put(1, .{ .x = -10, .y = 100 }));
    try testing.expectError(error.NotSeeable, sh.put(2, .{ .x = 100, .y = -1 }));
    try testing.expectError(error.NotSeeable, sh.put(3, .{ .x = 641, .y = 100 }));
    try testing.expectError(error.NotSeeable, sh.put(4, .{ .x = 100, .y = 361 }));
}

test "update - move between buckets" {
    var sh = try SpatialHash(u32, .{}).create(
        testing.allocator,
        .{ .x = 0, .y = 0, .width = 640, .height = 360 },
    );
    defer sh.destroy();

    const id: u32 = 999;

    try sh.put(id, .{ .x = 50, .y = 50 }); // bucket ~0,0
    try sh.update(id, .{ .x = 550, .y = 250 }); // bucket ~8,6 ish

    var results_old = std.array_list.Managed(u32).init(testing.allocator);
    defer results_old.deinit();
    try sh.query(.{ .x = 0, .y = 0, .width = 100, .height = 100 }, 0, &results_old);
    try testing.expectEqual(@as(usize, 0), results_old.items.len);

    var results_new = std.array_list.Managed(u32).init(testing.allocator);
    defer results_new.deinit();
    try sh.query(.{ .x = 540, .y = 240, .width = 20, .height = 20 }, 0, &results_new);

    try testing.expectEqual(@as(usize, 1), results_new.items.len);
    try testing.expectEqual(id, results_new.items[0]);
}

test "update - same bucket → no-op" {
    var sh = try SpatialHash(u32, .{}).create(
        testing.allocator,
        .{ .x = 0, .y = 0, .width = 640, .height = 360 },
    );
    defer sh.destroy();

    const id: u32 = 1234;
    try sh.put(id, .{ .x = 123, .y = 234 });

    // Save bucket index
    const old_bucket = sh.hash(.{ .x = 123, .y = 234 }).?;

    try sh.update(id, .{ .x = 125, .y = 238 }); // still same cell

    const new_bucket = sh.hash(.{ .x = 125, .y = 238 }).?;
    try testing.expectEqual(old_bucket, new_bucket);
}

test "remove - existing" {
    var sh = try SpatialHash(u32, .{}).create(
        testing.allocator,
        .{ .x = 0, .y = 0, .width = 640, .height = 360 },
    );
    defer sh.destroy();

    const id: u32 = 5678;
    try sh.put(id, .{ .x = 300, .y = 180 });

    sh.remove(id);

    var results = std.array_list.Managed(u32).init(testing.allocator);
    defer results.deinit();
    try sh.query(.{ .x = 0, .y = 0, .width = 640, .height = 360 }, 0, &results);

    try testing.expectEqual(@as(usize, 0), results.items.len);
}

test "query - large rect covering multiple rows & columns" {
    var sh = try SpatialHash(u32, .{}).create(
        testing.allocator,
        .{ .x = 0, .y = 0, .width = 640, .height = 360 },
    );
    defer sh.destroy();

    // Place objects in 4 different cells forming a square
    try sh.put(10, .{ .x = 100, .y = 100 }); // top-left
    try sh.put(20, .{ .x = 200, .y = 100 }); // top-right
    try sh.put(30, .{ .x = 100, .y = 200 }); // bottom-left
    try sh.put(40, .{ .x = 200, .y = 200 }); // bottom-right

    var results = std.array_list.Managed(u32).init(testing.allocator);
    defer results.deinit();

    // Query covering all 4
    try sh.query(.{ .x = 90, .y = 90, .width = 120, .height = 120 }, 0, &results);

    try testing.expectEqual(@as(usize, 4), results.items.len);

    // Order is not guaranteed → sort or use set
    std.mem.sort(u32, results.items, {}, std.sort.asc(u32));

    try testing.expectEqualSlices(u32, &[_]u32{ 10, 20, 30, 40 }, results.items);
}

test "clear - resets everything" {
    var sh = try SpatialHash(u32, .{}).create(
        testing.allocator,
        .{ .x = 0, .y = 0, .width = 640, .height = 360 },
    );
    defer sh.destroy();

    try sh.put(1, .{ .x = 50, .y = 50 });
    try sh.put(2, .{ .x = 550, .y = 300 });

    sh.clear();

    var results = std.array_list.Managed(u32).init(testing.allocator);
    defer results.deinit();
    try sh.query(.{ .x = 0, .y = 0, .width = 640, .height = 360 }, 0, &results);
    try testing.expectEqual(@as(usize, 0), results.items.len);

    // Should be able to add again
    try sh.put(3, .{ .x = 300, .y = 180 });
}
