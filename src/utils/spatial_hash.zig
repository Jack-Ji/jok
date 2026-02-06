//! Generic spatial hash table for fast spatial queries and broad-phase collision detection.
//!
//! A spatial hash divides space into a uniform grid of cells. Objects are placed into
//! cells based on their position, allowing for very fast spatial queries.
//!
//! Features:
//! - O(1) insertion, removal, and update
//! - Fast spatial queries for nearby objects
//! - Fixed memory footprint (no dynamic subdivision)
//! - Simple and predictable performance
//! - Optional collision sizes for precise filtering (size + position => rect)
//! - Point-only usage avoids dedup and keeps queries very fast
//!
//! Advantages over quad trees:
//! - Simpler implementation
//! - More predictable performance
//! - Better for uniformly distributed objects
//! - No tree rebalancing needed
//!
//! Use cases:
//! - Broad-phase collision detection for many objects
//! - Spatial indexing for uniform distributions
//! - Grid-based games
//! - Particle systems
//!
//! Example usage:
//! ```zig
//! const MySpatialHash = SpatialHash(u32, .{
//!     .size = .{ .width = 10, .height = 10 },
//! });
//!
//! var hash = try MySpatialHash.create(allocator, .{
//!     .x = 0, .y = 0, .width = 1000, .height = 1000
//! });
//! defer hash.destroy();
//!
//! try hash.put(object_id, position, .{});
//! try hash.update(object_id, new_position);
//! var results = std.array_list.Managed(u32).init(allocator);
//! try hash.query(search_rect, 0, &results, .{});
//! try hash.query(search_rect, 0, &results, .{ .precise = true });
//! ```

const std = @import("std");
const assert = std.debug.assert;
const testing = std.testing;
const jok = @import("../jok.zig");
const j2d = jok.j2d;

/// Errors that can occur during spatial hash operations
pub const Error = error{
    /// Spatial region dimensions don't divide evenly by grid size
    InvalidRect,
    /// Object already exists in the hash
    AlreadyExists,
    /// Object position is outside the spatial bounds
    NotSeeable,
};

/// Configuration options for spatial hash
pub const SpatialOption = struct {
    size: jok.Size = .{ .width = 10, .height = 10 },
};

/// Options for put operation
pub const PutOption = struct {
    /// Optional collision size (size + pos => rect)
    size: ?jok.Size = null,
};

/// Options for query operation
pub const QueryOption = struct {
    /// Enable precise filtering by sizes (default: false)
    precise: bool = false,
};

/// Generic spatial hash table data structure
/// ObjectType: Type of objects to store
/// opt: Configuration options (grid dimensions)
pub fn SpatialHash(comptime ObjectType: type, opt: SpatialOption) type {
    assert(opt.size.width > 0 and opt.size.height > 0);

    return struct {
        const HashTable = @This();

        /// Bucket storage: single index for point objects, ArrayList for sized objects
        const BucketStorage = union(enum) {
            single: u32,
            multi: std.ArrayList(u32),

            fn deinit(self: *BucketStorage, allocator: std.mem.Allocator) void {
                if (self.* == .multi) {
                    self.multi.deinit(allocator);
                }
            }
        };

        const Entry = struct {
            buckets: BucketStorage,
            pos: jok.Point,
        };

        allocator: std.mem.Allocator,
        arena: std.heap.ArenaAllocator,
        buckets: [opt.size.width * opt.size.height]std.ArrayList(ObjectType),
        positions: std.AutoHashMap(ObjectType, Entry),
        sizes: std.AutoHashMap(ObjectType, jok.Size),
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
                .arena = std.heap.ArenaAllocator.init(allocator),
                .buckets = undefined,
                .positions = std.AutoHashMap(ObjectType, Entry).init(allocator),
                .sizes = std.AutoHashMap(ObjectType, jok.Size).init(allocator),
                .spatial_rect = rect.toRect(),
                .spatial_unit = .{
                    .width = rect.width / opt.size.width,
                    .height = rect.height / opt.size.height,
                },
            };
            for (sh.buckets[0..]) |*b| {
                b.* = std.ArrayList(ObjectType).initCapacity(sh.arena.allocator(), 10) catch unreachable;
            }
            return sh;
        }

        pub fn destroy(self: *HashTable) void {
            // Clean up multi-bucket lists in entries
            var it = self.positions.iterator();
            while (it.next()) |entry| {
                entry.value_ptr.buckets.deinit(self.allocator);
            }

            self.positions.deinit();
            self.sizes.deinit();
            self.arena.deinit();
            self.allocator.destroy(self);
        }

        pub fn put(self: *HashTable, obj: u32, pos: jok.Point, put_opt: PutOption) !void {
            if (self.positions.get(obj) != null) return error.AlreadyExists;

            if (put_opt.size) |size| {
                // Add object with collision size
                // Calculate bounding rectangle
                const w = size.getWidthFloat();
                const h = size.getHeightFloat();
                const rect: jok.Rectangle = .{
                    .x = pos.x - w * 0.5,
                    .y = pos.y - h * 0.5,
                    .width = w,
                    .height = h,
                };

                // Get all overlapping buckets
                var bucket_list = try self.getBucketsForRect(rect, self.allocator);
                if (bucket_list.items.len == 0) {
                    bucket_list.deinit(self.allocator);
                    return error.NotSeeable;
                }

                // Add object to all overlapping buckets
                for (bucket_list.items) |k| {
                    self.buckets[k].append(self.arena.allocator(), obj) catch unreachable;
                }

                // Store entry and size
                self.positions.put(obj, .{ .buckets = .{ .multi = bucket_list }, .pos = pos }) catch unreachable;
                self.sizes.put(obj, size) catch unreachable;
            } else {
                // Add object without size (point-based) - use single bucket, no allocation
                if (self.hash(pos)) |k| {
                    self.buckets[k].append(self.arena.allocator(), obj) catch unreachable;
                    self.positions.put(obj, .{ .buckets = .{ .single = k }, .pos = pos }) catch unreachable;
                } else {
                    return error.NotSeeable;
                }
            }
        }

        pub fn update(self: *HashTable, obj: u32, pos: jok.Point) !void {
            if (self.positions.get(obj)) |entry| {
                // Check if object has size
                if (self.sizes.get(obj)) |size| {
                    // Sized object: must have multi buckets
                    assert(entry.buckets == .multi);

                    // Sized object: recalculate all overlapping buckets
                    const w = size.getWidthFloat();
                    const h = size.getHeightFloat();
                    const rect: jok.Rectangle = .{
                        .x = pos.x - w * 0.5,
                        .y = pos.y - h * 0.5,
                        .width = w,
                        .height = h,
                    };

                    var new_bucket_list = try self.getBucketsForRect(rect, self.allocator);
                    if (new_bucket_list.items.len == 0) {
                        new_bucket_list.deinit(self.allocator);
                        self.remove(obj);
                        return;
                    }

                    // Check if buckets have actually changed
                    var buckets_changed = false;
                    if (entry.buckets.multi.items.len != new_bucket_list.items.len) {
                        buckets_changed = true;
                    } else {
                        // Check if all bucket indices are the same (order doesn't matter)
                        for (new_bucket_list.items) |new_k| {
                            var found = false;
                            for (entry.buckets.multi.items) |old_k| {
                                if (new_k == old_k) {
                                    found = true;
                                    break;
                                }
                            }
                            if (!found) {
                                buckets_changed = true;
                                break;
                            }
                        }
                    }

                    if (!buckets_changed) {
                        // Buckets haven't changed, just update position
                        new_bucket_list.deinit(self.allocator);
                        self.positions.put(obj, .{ .buckets = entry.buckets, .pos = pos }) catch unreachable;
                        return;
                    }

                    // Remove from old buckets
                    for (entry.buckets.multi.items) |k| {
                        for (0..self.buckets[k].items.len) |i| {
                            if (self.buckets[k].items[i] == obj) {
                                _ = self.buckets[k].swapRemove(i);
                                break;
                            }
                        }
                    }

                    // Add to new buckets
                    for (new_bucket_list.items) |k| {
                        self.buckets[k].append(self.arena.allocator(), obj) catch unreachable;
                    }

                    // Clean up old bucket list and update entry
                    if (self.positions.fetchRemove(obj)) |kv| {
                        var buckets = kv.value.buckets;
                        buckets.deinit(self.allocator);
                    }
                    self.positions.put(obj, .{ .buckets = .{ .multi = new_bucket_list }, .pos = pos }) catch unreachable;
                } else {
                    // Non-sized object: must have single bucket
                    assert(entry.buckets == .single);

                    const nk = self.hash(pos);
                    if (nk == null) {
                        self.remove(obj);
                        return;
                    }

                    if (entry.buckets.single == nk.?) {
                        self.positions.put(obj, .{ .buckets = entry.buckets, .pos = pos }) catch unreachable;
                        return; // Still in same section, no need to update
                    }

                    for (0..self.buckets[entry.buckets.single].items.len) |i| {
                        if (self.buckets[entry.buckets.single].items[i] == obj) {
                            _ = self.buckets[entry.buckets.single].swapRemove(i);
                            break;
                        }
                    } else unreachable;

                    self.buckets[nk.?].append(self.arena.allocator(), obj) catch unreachable;
                    self.positions.put(obj, .{ .buckets = .{ .single = nk.? }, .pos = pos }) catch unreachable;
                }
            } else {
                assert(self.sizes.get(obj) == null);
                if (!self.spatial_rect.containsPoint(pos)) return;
                try self.put(obj, pos, .{});
            }
        }

        /// Update position and replace the attached collision size (size + pos => rect).
        /// If the object moves outside bounds, it is removed.
        pub fn remove(self: *HashTable, obj: u32) void {
            if (self.positions.fetchRemove(obj)) |kv| {
                // Remove from all buckets
                switch (kv.value.buckets) {
                    .single => |k| {
                        for (0..self.buckets[k].items.len) |i| {
                            if (self.buckets[k].items[i] == obj) {
                                _ = self.buckets[k].swapRemove(i);
                                break;
                            }
                        }
                    },
                    .multi => |bucket_list| {
                        for (bucket_list.items) |k| {
                            for (0..self.buckets[k].items.len) |i| {
                                if (self.buckets[k].items[i] == obj) {
                                    _ = self.buckets[k].swapRemove(i);
                                    break;
                                }
                            }
                        }
                    },
                }
                // Clean up bucket storage
                var buckets = kv.value.buckets;
                buckets.deinit(self.allocator);
            }
            _ = self.sizes.remove(obj);
        }

        pub fn query(self: HashTable, rect: jok.Rectangle, padding: f32, results: *std.array_list.Managed(ObjectType), query_opt: QueryOption) !void {
            const padded = rect.padded(padding);
            const start_len = results.items.len;

            if (self.spatial_rect.intersectRect(padded)) |r| {
                // Dedup is only needed when objects can span multiple buckets (sized objects).
                const needs_dedup = self.sizes.count() > 0;
                var seen = if (needs_dedup) std.AutoHashMap(ObjectType, void).init(self.allocator) else null;
                defer if (seen) |*s| s.deinit();

                const min_x_i: i32 = @intFromFloat(@floor((r.x - self.spatial_rect.x) / self.spatial_unit.getWidthFloat()));
                const min_y_i: i32 = @intFromFloat(@floor((r.y - self.spatial_rect.y) / self.spatial_unit.getHeightFloat()));
                const max_x_i: i32 = @as(i32, @intFromFloat(@ceil((r.x - self.spatial_rect.x + r.width) / self.spatial_unit.getWidthFloat()))) - 1;
                const max_y_i: i32 = @as(i32, @intFromFloat(@ceil((r.y - self.spatial_rect.y + r.height) / self.spatial_unit.getHeightFloat()))) - 1;

                const start_y_i = @max(@as(i32, 0), min_y_i);
                const end_y_i = @min(@as(i32, opt.size.height - 1), max_y_i);
                const start_x_i = @max(@as(i32, 0), min_x_i);
                const end_x_i = @min(@as(i32, opt.size.width - 1), max_x_i);
                if (end_y_i < start_y_i or end_x_i < start_x_i) return;

                const start_y: u32 = @intCast(start_y_i);
                const end_y: u32 = @intCast(end_y_i);
                const start_x: u32 = @intCast(start_x_i);
                const end_x: u32 = @intCast(end_x_i);

                var y = start_y;
                while (y <= end_y) : (y += 1) {
                    const row_start = y * opt.size.width + start_x;
                    const row_end = y * opt.size.width + end_x;

                    var k = row_start;
                    while (k <= row_end) : (k += 1) {
                        if (seen) |*s| {
                            for (self.buckets[k].items) |obj| {
                                if (!s.contains(obj)) {
                                    try s.put(obj, {});
                                    try results.append(obj);
                                }
                            }
                        } else {
                            try results.appendSlice(self.buckets[k].items);
                        }
                    }
                }
            }

            // Apply precise filtering if requested
            if (query_opt.precise) {
                var write_idx = start_len;
                var read_idx = start_len;
                while (read_idx < results.items.len) : (read_idx += 1) {
                    const obj = results.items[read_idx];
                    if (self.positions.get(obj)) |entry| {
                        if (self.sizes.get(obj)) |size| {
                            const w = size.getWidthFloat();
                            const h = size.getHeightFloat();
                            const orect: jok.Rectangle = .{
                                .x = entry.pos.x - w * 0.5,
                                .y = entry.pos.y - h * 0.5,
                                .width = w,
                                .height = h,
                            };
                            if (!orect.hasIntersection(padded)) continue;
                        } else if (!padded.containsPoint(entry.pos)) continue;
                    } else unreachable; // Object must exist in positions since we just queried it
                    results.items[write_idx] = obj;
                    write_idx += 1;
                }
                results.items.len = write_idx;
            }
        }

        /// Clear all objects from the spatial hash
        pub fn clear(self: *HashTable) void {
            // Clean up bucket lists in entries (these use main allocator)
            var it = self.positions.iterator();
            while (it.next()) |entry| {
                entry.value_ptr.buckets.deinit(self.allocator);
            }

            // Reset arena - frees all bucket contents in O(1)
            _ = self.arena.reset(.retain_capacity);

            // Reinitialize buckets with arena allocator
            for (self.buckets[0..]) |*b| {
                b.* = std.ArrayList(ObjectType).initCapacity(self.arena.allocator(), 10) catch unreachable;
            }
            self.positions.clearRetainingCapacity();
            self.sizes.clearRetainingCapacity();
        }

        /// Draw spatial hash grid on screen
        pub const DrawOption = struct {
            query: ?jok.Rectangle = null,
            rect_color: jok.Color = .black,
            query_color: jok.Color = .red,
            thickness: f32 = 2.0,
            depth: f32 = 0.5,
        };

        pub fn draw(self: HashTable, b: *j2d.Batch, draw_opt: DrawOption) !void {
            // Draw grid cells
            var y: u32 = 0;
            while (y < opt.size.height) : (y += 1) {
                var x: u32 = 0;
                while (x < opt.size.width) : (x += 1) {
                    const bucket_idx = y * opt.size.width + x;

                    // Skip empty cells unless they intersect with query
                    const has_objects = self.buckets[bucket_idx].items.len > 0;

                    const cell_rect = jok.Rectangle{
                        .x = self.spatial_rect.x + @as(f32, @floatFromInt(x * self.spatial_unit.width)),
                        .y = self.spatial_rect.y + @as(f32, @floatFromInt(y * self.spatial_unit.height)),
                        .width = @floatFromInt(self.spatial_unit.width),
                        .height = @floatFromInt(self.spatial_unit.height),
                    };

                    var should_draw = has_objects;
                    var color: jok.Color = draw_opt.rect_color;
                    var depth: f32 = draw_opt.depth;

                    // Highlight cells that intersect with query rectangle
                    if (draw_opt.query) |qr| {
                        if (cell_rect.hasIntersection(qr)) {
                            should_draw = true;
                            color = draw_opt.query_color;
                            depth -= 0.1;
                        }
                    }

                    if (should_draw) {
                        try b.rect(
                            cell_rect,
                            color,
                            .{ .thickness = draw_opt.thickness, .depth = depth },
                        );
                    }
                }
            }
        }

        fn hash(self: HashTable, pos: jok.Point) ?u32 {
            if (!self.spatial_rect.containsPoint(pos)) return null;
            return @as(u32, @intFromFloat(pos.y - self.spatial_rect.y)) / self.spatial_unit.height * opt.size.width +
                @as(u32, @intFromFloat(pos.x - self.spatial_rect.x)) / self.spatial_unit.width;
        }

        /// Get all bucket indices that a rectangle overlaps
        fn getBucketsForRect(self: HashTable, rect: jok.Rectangle, allocator: std.mem.Allocator) !std.ArrayList(u32) {
            var bucket_list = try std.ArrayList(u32).initCapacity(allocator, 10);
            errdefer bucket_list.deinit(allocator);

            if (self.spatial_rect.intersectRect(rect)) |r| {
                const min_x_i: i32 = @intFromFloat(@floor((r.x - self.spatial_rect.x) / self.spatial_unit.getWidthFloat()));
                const min_y_i: i32 = @intFromFloat(@floor((r.y - self.spatial_rect.y) / self.spatial_unit.getHeightFloat()));
                const max_x_i: i32 = @as(i32, @intFromFloat(@ceil((r.x - self.spatial_rect.x + r.width) / self.spatial_unit.getWidthFloat()))) - 1;
                const max_y_i: i32 = @as(i32, @intFromFloat(@ceil((r.y - self.spatial_rect.y + r.height) / self.spatial_unit.getHeightFloat()))) - 1;

                const start_y_i = @max(@as(i32, 0), min_y_i);
                const end_y_i = @min(@as(i32, opt.size.height - 1), max_y_i);
                const start_x_i = @max(@as(i32, 0), min_x_i);
                const end_x_i = @min(@as(i32, opt.size.width - 1), max_x_i);
                if (end_y_i < start_y_i or end_x_i < start_x_i) return bucket_list;

                const start_y: u32 = @intCast(start_y_i);
                const end_y: u32 = @intCast(end_y_i);
                const start_x: u32 = @intCast(start_x_i);
                const end_x: u32 = @intCast(end_x_i);

                var y = start_y;
                while (y <= end_y) : (y += 1) {
                    const row_start = y * opt.size.width + start_x;
                    const row_end = y * opt.size.width + end_x;

                    var k = row_start;
                    while (k <= row_end) : (k += 1) {
                        try bucket_list.append(allocator, k);
                    }
                }
            }

            return bucket_list;
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
    try sh.put(id, .{ .x = 123, .y = 89 }, .{});

    var results = std.array_list.Managed(u32).init(testing.allocator);
    defer results.deinit();

    try sh.query(.{ .x = 122, .y = 88, .width = 2, .height = 2 }, 0, &results, .{});

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

    try sh.put(id, .{ .x = 100, .y = 100 }, .{});
    try testing.expectError(error.AlreadyExists, sh.put(id, .{ .x = 200, .y = 200 }, .{}));
}

test "put - outside rect → NotSeeable" {
    var sh = try SpatialHash(u32, .{}).create(
        testing.allocator,
        .{ .x = 0, .y = 0, .width = 640, .height = 360 },
    );
    defer sh.destroy();

    try testing.expectError(error.NotSeeable, sh.put(1, .{ .x = -10, .y = 100 }, .{}));
    try testing.expectError(error.NotSeeable, sh.put(2, .{ .x = 100, .y = -1 }, .{}));
    try testing.expectError(error.NotSeeable, sh.put(3, .{ .x = 641, .y = 100 }, .{}));
    try testing.expectError(error.NotSeeable, sh.put(4, .{ .x = 100, .y = 361 }, .{}));
}

test "update - move between buckets" {
    var sh = try SpatialHash(u32, .{}).create(
        testing.allocator,
        .{ .x = 0, .y = 0, .width = 640, .height = 360 },
    );
    defer sh.destroy();

    const id: u32 = 999;

    try sh.put(id, .{ .x = 50, .y = 50 }, .{}); // bucket ~0,0
    try sh.update(id, .{ .x = 550, .y = 250 }); // bucket ~8,6 ish

    var results_old = std.array_list.Managed(u32).init(testing.allocator);
    defer results_old.deinit();
    try sh.query(.{ .x = 0, .y = 0, .width = 100, .height = 100 }, 0, &results_old, .{});
    try testing.expectEqual(@as(usize, 0), results_old.items.len);

    var results_new = std.array_list.Managed(u32).init(testing.allocator);
    defer results_new.deinit();
    try sh.query(.{ .x = 540, .y = 240, .width = 20, .height = 20 }, 0, &results_new, .{});

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
    try sh.put(id, .{ .x = 123, .y = 234 }, .{});

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
    try sh.put(id, .{ .x = 300, .y = 180 }, .{});

    sh.remove(id);

    var results = std.array_list.Managed(u32).init(testing.allocator);
    defer results.deinit();
    try sh.query(.{ .x = 0, .y = 0, .width = 640, .height = 360 }, 0, &results, .{});

    try testing.expectEqual(@as(usize, 0), results.items.len);
}

test "query - large rect covering multiple rows & columns" {
    var sh = try SpatialHash(u32, .{}).create(
        testing.allocator,
        .{ .x = 0, .y = 0, .width = 640, .height = 360 },
    );
    defer sh.destroy();

    // Place objects in 4 different cells forming a square
    try sh.put(10, .{ .x = 100, .y = 100 }, .{}); // top-left
    try sh.put(20, .{ .x = 200, .y = 100 }, .{}); // top-right
    try sh.put(30, .{ .x = 100, .y = 200 }, .{}); // bottom-left
    try sh.put(40, .{ .x = 200, .y = 200 }, .{}); // bottom-right

    var results = std.array_list.Managed(u32).init(testing.allocator);
    defer results.deinit();

    // Query covering all 4
    try sh.query(.{ .x = 90, .y = 90, .width = 120, .height = 120 }, 0, &results, .{});

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

    try sh.put(1, .{ .x = 50, .y = 50 }, .{});
    try sh.put(2, .{ .x = 550, .y = 300 }, .{});

    sh.clear();

    var results = std.array_list.Managed(u32).init(testing.allocator);
    defer results.deinit();
    try sh.query(.{ .x = 0, .y = 0, .width = 640, .height = 360 }, 0, &results, .{});
    try testing.expectEqual(@as(usize, 0), results.items.len);

    // Should be able to add again
    try sh.put(3, .{ .x = 300, .y = 180 }, .{});
}

test "query with precise option - filters by attached size" {
    var sh = try SpatialHash(u32, .{}).create(
        testing.allocator,
        .{ .x = 0, .y = 0, .width = 640, .height = 360 },
    );
    defer sh.destroy();

    try sh.put(1, .{ .x = 2.5, .y = 2.5 }, .{ .size = .{ .width = 5, .height = 5 } });
    try sh.put(2, .{ .x = 60, .y = 10 }, .{}); // Same bucket, outside query rect

    var results = std.array_list.Managed(u32).init(testing.allocator);
    defer results.deinit();

    try sh.query(.{ .x = 0, .y = 0, .width = 5, .height = 5 }, 0, &results, .{ .precise = true });

    try testing.expectEqual(@as(usize, 1), results.items.len);
    try testing.expectEqual(@as(u32, 1), results.items[0]);
}

test "update with size - size override and stable across move" {
    var sh = try SpatialHash(u32, .{}).create(
        testing.allocator,
        .{ .x = 0, .y = 0, .width = 640, .height = 360 },
    );
    defer sh.destroy();

    const size = jok.Size{ .width = 10, .height = 10 };
    try sh.put(1, .{ .x = 45, .y = 45 }, .{ .size = size });

    // Update without providing size -> size remains
    try sh.update(1, .{ .x = 60, .y = 55 });
    try testing.expect(sh.sizes.get(1).?.isSame(.{ .width = 10, .height = 10 }));

    // Override size explicitly
    try sh.update(1, .{ .x = 70, .y = 60 });
    sh.sizes.put(1, .{ .width = 3, .height = 4 }) catch unreachable;
    try testing.expect(sh.sizes.get(1).?.isSame(.{ .width = 3, .height = 4 }));
}

test "query with precise option - falls back to position for objects without size" {
    var sh = try SpatialHash(u32, .{}).create(
        testing.allocator,
        .{ .x = 0, .y = 0, .width = 640, .height = 360 },
    );
    defer sh.destroy();

    try sh.put(1, .{ .x = 10, .y = 10 }, .{});
    try sh.put(2, .{ .x = 100, .y = 100 }, .{});

    var results = std.array_list.Managed(u32).init(testing.allocator);
    defer results.deinit();

    try sh.query(.{ .x = 0, .y = 0, .width = 20, .height = 20 }, 0, &results, .{ .precise = true });

    try testing.expectEqual(@as(usize, 1), results.items.len);
    try testing.expectEqual(@as(u32, 1), results.items[0]);
}

test "query - rect ending on cell boundary doesn't include next cell" {
    var sh = try SpatialHash(u32, .{ .size = .{ .width = 10, .height = 10 } }).create(
        testing.allocator,
        .{ .x = 0, .y = 0, .width = 100, .height = 100 },
    );
    defer sh.destroy();

    try sh.put(1, .{ .x = 5, .y = 5 }, .{});   // cell (0,0)
    try sh.put(2, .{ .x = 15, .y = 5 }, .{});  // cell (1,0)

    var results = std.array_list.Managed(u32).init(testing.allocator);
    defer results.deinit();

    // Query exactly first cell (x in [0,10))
    try sh.query(.{ .x = 0, .y = 0, .width = 10, .height = 10 }, 0, &results, .{});

    try testing.expectEqual(@as(usize, 1), results.items.len);
    try testing.expectEqual(@as(u32, 1), results.items[0]);
}

test "update - inserts missing object when inside bounds" {
    var sh = try SpatialHash(u32, .{}).create(
        testing.allocator,
        .{ .x = 0, .y = 0, .width = 640, .height = 360 },
    );
    defer sh.destroy();

    try sh.update(123, .{ .x = 100, .y = 100 });

    var results = std.array_list.Managed(u32).init(testing.allocator);
    defer results.deinit();
    try sh.query(.{ .x = 90, .y = 90, .width = 20, .height = 20 }, 0, &results, .{});
    try testing.expectEqual(@as(usize, 1), results.items.len);
    try testing.expectEqual(@as(u32, 123), results.items[0]);
}

test "sized object spans multiple buckets" {
    var sh = try SpatialHash(u32, .{ .size = .{ .width = 10, .height = 10 } }).create(
        testing.allocator,
        .{ .x = 0, .y = 0, .width = 100, .height = 100 },
    );
    defer sh.destroy();

    try sh.put(1, .{ .x = 10, .y = 10 }, .{ .size = .{ .width = 15, .height = 15 } });

    var results = std.array_list.Managed(u32).init(testing.allocator);
    defer results.deinit();
    try sh.query(.{ .x = 0, .y = 0, .width = 20, .height = 20 }, 0, &results, .{});
    try testing.expectEqual(@as(usize, 1), results.items.len);
    try testing.expectEqual(@as(u32, 1), results.items[0]);
}
