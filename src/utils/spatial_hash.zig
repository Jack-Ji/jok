const std = @import("std");
const assert = std.debug.assert;
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
        positions: std.AutoHashMap(ObjectType, jok.Rectangle),
        dedup_set: std.AutoHashMap(ObjectType, void), // for query deduplication
        temp_cells: std.ArrayList(u32),
        spatial_rect: jok.Rectangle,
        spatial_unit: jok.Size,

        pub fn create(allocator: std.mem.Allocator, rect: jok.Region) !*HashTable {
            if (rect.width % opt.size.width != 0 or rect.height % opt.size.height != 0) {
                return error.InvalidRect;
            }

            var sh = try allocator.create(HashTable);
            errdefer allocator.destroy(sh);

            sh.* = .{
                .allocator = allocator,
                .buckets = undefined,
                .positions = std.AutoHashMap(ObjectType, jok.Rectangle).init(allocator),
                .dedup_set = std.AutoHashMap(ObjectType, void).init(allocator),
                .temp_cells = .empty,
                .spatial_rect = rect.toRect(),
                .spatial_unit = .{
                    .width = rect.width / opt.size.width,
                    .height = rect.height / opt.size.height,
                },
            };
            for (&sh.buckets) |*b| {
                b.* = std.ArrayList(ObjectType).initCapacity(allocator, 16) catch unreachable;
            }
            return sh;
        }

        pub fn destroy(self: *HashTable) void {
            self.temp_cells.deinit(self.allocator);
            self.dedup_set.deinit();
            self.positions.deinit();
            for (&self.buckets) |*b| b.deinit(self.allocator);
            self.allocator.destroy(self);
        }

        pub fn put(self: *HashTable, obj: ObjectType, bounds: jok.Rectangle) !void {
            if (!self.spatial_rect.hasIntersection(bounds)) {
                return error.NotSeeable;
            }
            if (self.positions.get(obj) != null) return error.AlreadyExists;

            try self.fillIntersectingCells(bounds);
            for (self.temp_cells.items) |cell_idx| {
                try self.buckets[cell_idx].append(self.allocator, obj);
            }
            try self.positions.put(obj, bounds);
        }

        pub fn update(self: *HashTable, obj: ObjectType, new_bounds: jok.Rectangle) !void {
            if (!self.spatial_rect.hasIntersection(new_bounds)) {
                self.remove(obj);
                return;
            }

            const old_bounds_opt = self.positions.get(obj);
            if (old_bounds_opt == null) {
                // not exist → insert
                return self.put(obj, new_bounds);
            }

            // Full update needed
            const old_bounds = old_bounds_opt.?;
            try self.fillIntersectingCells(old_bounds);
            for (self.temp_cells.items) |cell_idx| {
                const bucket = &self.buckets[cell_idx];
                for (0..bucket.items.len) |i| {
                    if (bucket.items[i] == obj) {
                        _ = bucket.swapRemove(i);
                        break;
                    }
                }
            }
            try self.fillIntersectingCells(new_bounds);
            for (self.temp_cells.items) |cell_idx| {
                try self.buckets[cell_idx].append(self.allocator, obj);
            }
            try self.positions.put(obj, new_bounds);
        }

        pub fn remove(self: *HashTable, obj: ObjectType) void {
            if (self.positions.fetchRemove(obj)) |kv| {
                self.fillIntersectingCells(kv.value) catch unreachable;
                for (self.temp_cells.items) |cell_idx| {
                    const bucket = &self.buckets[cell_idx];
                    for (0..bucket.items.len) |i| {
                        if (bucket.items[i] == obj) {
                            _ = bucket.swapRemove(i);
                            break;
                        }
                    }
                }
            }
        }

        pub fn clear(self: *HashTable) void {
            for (&self.buckets) |*b| b.clearRetainingCapacity();
            self.positions.clearRetainingCapacity();
            self.dedup_set.clearRetainingCapacity();
        }

        pub fn query(self: *HashTable, rect: jok.Rectangle, padding: f32, results: *std.array_list.Managed(ObjectType)) !void {
            self.dedup_set.clearRetainingCapacity();

            const query_rect = rect.padded(padding);
            try self.fillIntersectingCells(query_rect);

            for (self.temp_cells.items) |cell_idx| {
                for (self.buckets[cell_idx].items) |obj| {
                    if (self.dedup_set.contains(obj)) continue;
                    try self.dedup_set.put(obj, {});
                    try results.append(obj);
                }
            }
        }

        // // Returns number of cells written into temp_cells
        // (caller must clear or ignore previous content)
        fn fillIntersectingCells(self: *HashTable, bounds: jok.Rectangle) !void {
            self.temp_cells.clearRetainingCapacity();

            // Early exit if no intersection
            if (!self.spatial_rect.hasIntersection(bounds)) return;

            // Get the actual overlapping rectangle
            const inter = self.spatial_rect.intersectRect(bounds) orelse return;

            // Compute grid indices — standard way: floor for min, ceil for max
            // No extra -1 after ceil!
            const left = @max(0, @as(i32, @intFromFloat(@floor((inter.x - self.spatial_rect.x) / self.spatial_unit.getWidthFloat()))));
            const top = @max(0, @as(i32, @intFromFloat(@floor((inter.y - self.spatial_rect.y) / self.spatial_unit.getHeightFloat()))));
            const right = @min(@as(i32, opt.size.width) - 1, @as(i32, @intFromFloat(@ceil((inter.x + inter.width - self.spatial_rect.x) / self.spatial_unit.getWidthFloat()))));
            const bottom = @min(@as(i32, opt.size.height) - 1, @as(i32, @intFromFloat(@ceil((inter.y + inter.height - self.spatial_rect.y) / self.spatial_unit.getHeightFloat()))));

            // No cells to process
            if (left > right or top > bottom) return;

            // Pre-allocate exact amount needed
            const needed = @as(usize, @intCast((right - left + 1) * (bottom - top + 1)));
            try self.temp_cells.ensureTotalCapacity(self.allocator, needed);

            // Fill the list
            var y: i32 = top;
            while (y <= bottom) : (y += 1) {
                var x: i32 = left;
                while (x <= right) : (x += 1) {
                    const idx = @as(u32, @intCast(y * @as(i32, opt.size.width) + x));
                    self.temp_cells.appendAssumeCapacity(idx);
                }
            }
        }
    };
}

const testing = std.testing;
const expect = testing.expect;
const expectEqual = testing.expectEqual;
const expectError = testing.expectError;
const expectEqualSlices = testing.expectEqualSlices;

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

test "put & query - small rect in exact one cell" {
    var sh = try SpatialHash(u32, .{}).create(
        testing.allocator,
        .{ .x = 0, .y = 0, .width = 640, .height = 360 },
    );
    defer sh.destroy();

    const id: u32 = 777;
    try sh.put(id, .{ .x = 120, .y = 80, .width = 10, .height = 10 });

    var results = std.array_list.Managed(u32).init(testing.allocator);
    defer results.deinit();

    try sh.query(.{ .x = 115, .y = 75, .width = 20, .height = 20 }, 0, &results);

    try expectEqual(@as(usize, 1), results.items.len);
    try expectEqual(id, results.items[0]);
}

test "query with padding > 0 includes neighboring cells" {
    var sh = try SpatialHash(u32, .{}).create(
        testing.allocator,
        .{ .x = 0, .y = 0, .width = 640, .height = 360 },
    );
    defer sh.destroy();

    try sh.put(1, .{ .x = 100, .y = 100, .width = 10, .height = 10 });
    var results = std.array_list.Managed(u32).init(testing.allocator);
    defer results.deinit();

    // query far from object but with large padding
    try sh.query(.{ .x = 150, .y = 150, .width = 1, .height = 1 }, 60, &results);
    try expect(results.items.len > 0);
}

test "put - already exists → error" {
    var sh = try SpatialHash(u32, .{}).create(
        testing.allocator,
        .{ .x = 0, .y = 0, .width = 640, .height = 360 },
    );
    defer sh.destroy();

    const id: u32 = 42;
    try sh.put(id, .{ .x = 100, .y = 100, .width = 20, .height = 20 });

    try expectError(error.AlreadyExists, sh.put(id, .{ .x = 200, .y = 200, .width = 30, .height = 30 }));
}

test "put - completely outside → NotSeeable" {
    var sh = try SpatialHash(u32, .{}).create(
        testing.allocator,
        .{ .x = 0, .y = 0, .width = 640, .height = 360 },
    );
    defer sh.destroy();

    try expectError(error.NotSeeable, sh.put(1, .{ .x = -50, .y = 100, .width = 30, .height = 30 }));
    try expectError(error.NotSeeable, sh.put(2, .{ .x = 700, .y = 100, .width = 30, .height = 30 }));
    try expectError(error.NotSeeable, sh.put(3, .{ .x = 300, .y = -50, .width = 30, .height = 30 }));
    try expectError(error.NotSeeable, sh.put(4, .{ .x = 300, .y = 400, .width = 30, .height = 30 }));
}

test "put - partially outside is allowed" {
    var sh = try SpatialHash(u32, .{}).create(
        testing.allocator,
        .{ .x = 0, .y = 0, .width = 640, .height = 360 },
    );
    defer sh.destroy();

    try sh.put(99, .{ .x = 620, .y = 340, .width = 40, .height = 40 });
    // should be placed in the last few cells only

    var results = std.array_list.Managed(u32).init(testing.allocator);
    defer results.deinit();

    try sh.query(.{ .x = 600, .y = 320, .width = 80, .height = 80 }, 0, &results);
    try expect(results.items.len > 0);
    try expectEqual(@as(u32, 99), results.items[0]);
}

test "update - move between buckets" {
    var sh = try SpatialHash(u32, .{}).create(
        testing.allocator,
        .{ .x = 0, .y = 0, .width = 640, .height = 360 },
    );
    defer sh.destroy();

    const id: u32 = 999;
    try sh.put(id, .{ .x = 50, .y = 50, .width = 20, .height = 20 });

    // move to different region
    try sh.update(id, .{ .x = 550, .y = 250, .width = 30, .height = 30 });

    var results_old = std.array_list.Managed(u32).init(testing.allocator);
    defer results_old.deinit();
    try sh.query(.{ .x = 0, .y = 0, .width = 100, .height = 100 }, 0, &results_old);
    try expectEqual(@as(usize, 0), results_old.items.len);

    var results_new = std.array_list.Managed(u32).init(testing.allocator);
    defer results_new.deinit();
    try sh.query(.{ .x = 540, .y = 240, .width = 50, .height = 50 }, 0, &results_new);
    try expectEqual(@as(usize, 1), results_new.items.len);
    try expectEqual(id, results_new.items[0]);
}

test "update - small movement stays in same cell(s)" {
    var sh = try SpatialHash(u32, .{}).create(
        testing.allocator,
        .{ .x = 0, .y = 0, .width = 640, .height = 360 },
    );
    defer sh.destroy();

    const id: u32 = 1234;
    const old_bounds = jok.Rectangle{ .x = 123, .y = 234, .width = 15, .height = 15 };
    try sh.put(id, old_bounds);

    // small shift, still fully inside same cells
    const new_bounds = jok.Rectangle{ .x = 125, .y = 236, .width = 15, .height = 15 };
    try sh.update(id, new_bounds);

    // should still be queryable
    var results = std.array_list.Managed(u32).init(testing.allocator);
    defer results.deinit();
    try sh.query(.{ .x = 120, .y = 230, .width = 20, .height = 20 }, 0, &results);
    try expectEqual(@as(usize, 1), results.items.len);
    try expectEqual(id, results.items[0]);
}

test "update - large rect now spans more cells" {
    var sh = try SpatialHash(u32, .{}).create(
        testing.allocator,
        .{ .x = 0, .y = 0, .width = 640, .height = 360 },
    );
    defer sh.destroy();

    const id: u32 = 555;
    try sh.put(id, .{ .x = 300, .y = 150, .width = 20, .height = 20 });

    // grow to span 4 cells
    try sh.update(id, .{ .x = 290, .y = 140, .width = 60, .height = 60 });

    var results = std.array_list.Managed(u32).init(testing.allocator);
    defer results.deinit();
    try sh.query(.{ .x = 280, .y = 130, .width = 80, .height = 80 }, 0, &results);

    try expectEqual(@as(usize, 1), results.items.len);
    try expectEqual(id, results.items[0]);
}

test "remove - existing object spanning multiple cells" {
    var sh = try SpatialHash(u32, .{}).create(
        testing.allocator,
        .{ .x = 0, .y = 0, .width = 640, .height = 360 },
    );
    defer sh.destroy();

    const id: u32 = 5678;
    try sh.put(id, .{ .x = 290, .y = 140, .width = 60, .height = 60 });

    sh.remove(id);

    var results = std.array_list.Managed(u32).init(testing.allocator);
    defer results.deinit();
    try sh.query(.{ .x = 0, .y = 0, .width = 640, .height = 360 }, 0, &results);
    try expectEqual(@as(usize, 0), results.items.len);
}

test "query - large rect covering multiple rows & columns" {
    var sh = try SpatialHash(u32, .{}).create(
        testing.allocator,
        .{ .x = 0, .y = 0, .width = 640, .height = 360 },
    );
    defer sh.destroy();

    // Place objects in different regions
    try sh.put(10, .{ .x = 100, .y = 100, .width = 20, .height = 20 });
    try sh.put(20, .{ .x = 500, .y = 100, .width = 20, .height = 20 });
    try sh.put(30, .{ .x = 100, .y = 300, .width = 20, .height = 20 });
    try sh.put(40, .{ .x = 500, .y = 300, .width = 20, .height = 20 });

    // one object spanning center
    try sh.put(99, .{ .x = 280, .y = 140, .width = 80, .height = 80 });

    var results = std.array_list.Managed(u32).init(testing.allocator);
    defer results.deinit();

    try sh.query(.{ .x = 90, .y = 90, .width = 460, .height = 220 }, 0, &results);

    try expectEqual(@as(usize, 5), results.items.len);

    std.mem.sort(u32, results.items, {}, std.sort.asc(u32));
    try expectEqualSlices(u32, &[_]u32{ 10, 20, 30, 40, 99 }, results.items);
}

test "clear - resets everything" {
    var sh = try SpatialHash(u32, .{}).create(
        testing.allocator,
        .{ .x = 0, .y = 0, .width = 640, .height = 360 },
    );
    defer sh.destroy();

    try sh.put(1, .{ .x = 50, .y = 50, .width = 30, .height = 30 });
    try sh.put(2, .{ .x = 550, .y = 300, .width = 40, .height = 40 });

    sh.clear();

    var results = std.array_list.Managed(u32).init(testing.allocator);
    defer results.deinit();

    try sh.query(.{ .x = 0, .y = 0, .width = 640, .height = 360 }, 0, &results);
    try expectEqual(@as(usize, 0), results.items.len);

    // can add again
    try sh.put(3, .{ .x = 300, .y = 180, .width = 25, .height = 25 });
}

test "cell inclusion - exact right edge" {
    var sh = try SpatialHash(u32, .{ .size = .{ .width = 10, .height = 10 } }).create(
        testing.allocator,
        .{ .x = 0, .y = 0, .width = 640, .height = 640 },
    );
    defer sh.destroy();

    // Cell size = 64×64
    // Object exactly touches x=256 (boundary between cell 3 and 4)
    try sh.put(1, .{ .x = 192, .y = 100, .width = 64, .height = 10 });

    var results = std.array_list.Managed(u32).init(testing.allocator);
    defer results.deinit();

    // Query that should catch cell 4
    try sh.query(.{ .x = 250, .y = 90, .width = 20, .height = 30 }, 0, &results);

    try expect(results.items.len > 0);
    try expectEqual(@as(u32, 1), results.items[0]);
}

test "exact boundary touching - must include both cells" {
    const cell_w: f32 = 64;
    const grid_w: u32 = 10;
    const total_width = cell_w * @as(f32, @floatFromInt(grid_w)); // 640

    var sh = try SpatialHash(u32, .{ .size = .{ .width = grid_w, .height = 10 } }).create(
        testing.allocator,
        .{ .x = 0, .y = 0, .width = total_width, .height = 640 },
    );
    defer sh.destroy();

    // Object starts in cell 2 (128–192), width exactly reaches 256 (start of cell 4)
    // x=192, width=64 → right edge = 256
    const obj_bounds = jok.Rectangle{ .x = 192, .y = 100, .width = 64, .height = 10 };

    try sh.put(42, obj_bounds);

    // Query only the right half — should still see the object
    var results = std.array_list.Managed(u32).init(testing.allocator);
    defer results.deinit();

    try sh.query(.{ .x = 250, .y = 90, .width = 20, .height = 30 }, // touches only cell 4 area
        0, &results);

    try testing.expect(results.items.len == 1);
    try testing.expectEqual(@as(u32, 42), results.items[0]);
}

test "exact boundary - tight query on next cell only" {
    const cell_size: f32 = 64;
    const grid_w: u32 = 10;
    const total_w = cell_size * @as(f32, @floatFromInt(grid_w)); // 640

    var sh = try SpatialHash(u32, .{ .size = .{ .width = grid_w, .height = 10 } }).create(
        testing.allocator,
        .{ .x = 0, .y = 0, .width = total_w, .height = 640 },
    );
    defer sh.destroy();

    // Object: left=192 (cell 3 start=192), width=64 → right=256 exactly (cell 4 start)
    try sh.put(42, .{ .x = 192, .y = 100, .width = 64, .height = 10 });

    // Query **only** touches cell 4 (x=256 to 270)
    var results = std.array_list.Managed(u32).init(testing.allocator);
    defer results.deinit();

    try sh.query(.{ .x = 256, .y = 95, .width = 14, .height = 20 }, // strictly inside cell 4
        0, &results);

    try testing.expectEqual(@as(usize, 1), results.items.len);
    try testing.expectEqual(@as(u32, 42), results.items[0]);
}

test "stress: many objects + updates" {
    const cell_w: f32 = 64;
    const grid_w: u32 = 10;
    const total_width = cell_w * @as(f32, @floatFromInt(grid_w)); // 640

    var sh = try SpatialHash(u32, .{ .size = .{ .width = grid_w, .height = 10 } }).create(
        testing.allocator,
        .{ .x = 0, .y = 0, .width = total_width, .height = 640 },
    );
    defer sh.destroy();

    var prng = std.Random.DefaultPrng.init(0);
    const rand = prng.random();

    var ids: [5000]u32 = undefined;
    for (&ids, 0..) |*id, i| id.* = @intCast(i);

    for (ids) |id| {
        const x = rand.float(f32) * 600;
        const y = rand.float(f32) * 320;
        try sh.put(id, .{ .x = x, .y = y, .width = 20, .height = 20 });
    }

    // random updates
    for (0..1000) |_| {
        const id = ids[rand.uintLessThan(usize, ids.len)];
        const x = rand.float(f32) * 600;
        const y = rand.float(f32) * 320;
        try sh.update(id, .{ .x = x, .y = y, .width = 20 + rand.float(f32) * 40, .height = 20 + rand.float(f32) * 40 });
    }

    // query whole area
    var results = std.array_list.Managed(u32).init(testing.allocator);
    defer results.deinit();
    try sh.query(sh.spatial_rect, 0, &results);
    try expect(results.items.len > 4000); // approximate
}
