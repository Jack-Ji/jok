const std = @import("std");
const assert = std.debug.assert;
const jok = @import("../jok.zig");
const j2d = jok.j2d;

pub const Error = error{
    AlreadyExists,
    NotSeeable,
};

pub const TreeOption = struct {
    preferred_size_of_leaf: u32 = 8, // Maximum number of objects within a leaf
    min_width_of_leaf: u32 = 64, // Minimum width of rectangle
    enable_sort: bool = false, // Do quick sort if possible
};

pub fn QuadTree(comptime ObjectType: type, opt: TreeOption) type {
    const type_info = @typeInfo(ObjectType);
    const is_searchable = type_info == .int or (type_info == .pointer and type_info.pointer.size == .one);

    return struct {
        const Tree = @This();
        pub const TreeNode = union(enum) {
            pub const Node = struct {
                rect: jok.Rectangle,
                children: [4]*TreeNode, // NW, NE, SW, SE
            };
            pub const Leaf = struct {
                rect: jok.Rectangle,
                objs: std.ArrayList(ObjectType),

                fn getSubRect(self: Leaf, child_idx: u32) jok.Rectangle {
                    const w = self.rect.width / 2.0;
                    const h = self.rect.height / 2.0;
                    return switch (child_idx) {
                        0 => .{ .x = self.rect.x, .y = self.rect.y, .width = w, .height = h }, // NW
                        1 => .{ .x = self.rect.x + w, .y = self.rect.y, .width = w, .height = h }, // NE
                        2 => .{ .x = self.rect.x, .y = self.rect.y + h, .width = w, .height = h }, // SW
                        3 => .{ .x = self.rect.x + w, .y = self.rect.y + h, .width = w, .height = h }, // SE
                        else => unreachable,
                    };
                }
            };

            node: Node,
            leaf: Leaf,

            pub inline fn getRect(self: TreeNode) jok.Rectangle {
                return if (self == .node) self.node.rect else self.leaf.rect;
            }
        };

        allocator: std.mem.Allocator,
        arena: std.heap.ArenaAllocator,
        node_pool: std.heap.MemoryPool(TreeNode),
        root: *TreeNode,
        positions: std.AutoHashMap(ObjectType, jok.Rectangle),
        dedup_set: std.AutoHashMap(ObjectType, void),

        /// Initialize new tree
        pub fn create(allocator: std.mem.Allocator, rect: jok.Rectangle) !*Tree {
            assert(rect.area() > 0);

            var tree = try allocator.create(Tree);
            errdefer allocator.destroy(tree);

            tree.* = .{
                .allocator = allocator,
                .arena = std.heap.ArenaAllocator.init(allocator),
                .node_pool = try std.heap.MemoryPool(TreeNode).initCapacity(allocator, 1024),
                .root = undefined,
                .positions = std.AutoHashMap(ObjectType, jok.Rectangle).init(allocator),
                .dedup_set = std.AutoHashMap(ObjectType, void).init(allocator),
            };
            errdefer {
                tree.node_pool.deinit(allocator);
                tree.arena.deinit();
            }

            tree.root = try tree.node_pool.create(allocator);
            tree.root.* = .{
                .leaf = .{
                    .rect = rect,
                    .objs = try std.ArrayList(ObjectType).initCapacity(
                        tree.arena.allocator(),
                        opt.preferred_size_of_leaf * 2,
                    ),
                },
            };
            return tree;
        }

        /// Destroy tree
        pub fn destroy(self: *Tree) void {
            self.dedup_set.deinit();
            self.positions.deinit();
            self.node_pool.deinit(self.allocator);
            self.arena.deinit();
            self.allocator.destroy(self);
        }

        /// Add an object into tree
        pub fn put(self: *Tree, o: ObjectType, bounds: jok.Rectangle) !void {
            if (self.positions.get(o) != null) return error.AlreadyExists;
            if (!self.root.getRect().hasIntersection(bounds)) return error.NotSeeable;
            try self.positions.put(o, bounds);
            errdefer _ = self.positions.remove(o);
            try self.insert(self.root, o, bounds);
            return;
        }

        /// Remove an object from tree
        pub fn remove(self: *Tree, o: ObjectType) void {
            const kv = self.positions.fetchRemove(o) orelse return;
            self.searchAndRemove(self.root, o, kv.value);
        }

        /// Update position (bounds) of object
        /// WARNING: it hurts performance when called on too many objects per frame, use at your discretion
        pub fn update(self: *Tree, o: ObjectType, new_bounds: jok.Rectangle) !void {
            self.remove(o);
            if (!self.root.getRect().hasIntersection(new_bounds)) {
                return;
            }
            try self.positions.put(o, new_bounds);
            errdefer _ = self.positions.remove(o);
            try self.insert(self.root, o, new_bounds);
        }

        /// Query for objects which could potentially interfect with given rectangle
        pub fn query(self: *Tree, rect: jok.Rectangle, padding: f32, results: *std.array_list.Managed(ObjectType)) !void {
            self.dedup_set.clearRetainingCapacity();

            var stack = try std.ArrayList(*const TreeNode).initCapacity(self.allocator, 16);
            defer stack.deinit(self.allocator);

            try stack.append(self.allocator, self.root);
            while (stack.pop()) |node_ptr| {
                const node = node_ptr.*;
                if (!rect.padded(padding).hasIntersection(node.getRect())) continue;
                if (node == .leaf) {
                    for (node.leaf.objs.items) |obj| {
                        if (self.dedup_set.contains(obj)) continue;
                        try self.dedup_set.put(obj, {});
                        try results.append(obj);
                    }
                } else {
                    inline for (node.node.children) |child| try stack.append(self.allocator, child);
                }
            }
        }

        /// Clear the map
        pub fn clear(self: *Tree) void {
            const rect = self.root.getRect();
            _ = self.node_pool.reset(self.allocator, .retain_capacity);
            _ = self.arena.reset(.retain_capacity);
            self.positions.clearRetainingCapacity();

            const new_root = self.node_pool.create(self.allocator) catch unreachable;
            new_root.* = .{
                .leaf = .{
                    .rect = rect,
                    .objs = std.ArrayList(ObjectType).initCapacity(
                        self.arena.allocator(),
                        opt.preferred_size_of_leaf * 2,
                    ) catch unreachable,
                },
            };
            self.root = new_root;
        }

        /// Draw quadtree on screen
        pub const DrawOption = struct {
            query: ?jok.Rectangle = null,
            rect_color: jok.Color = .black,
            query_color: jok.Color = .red,
            thickness: f32 = 2.0,
            depth: f32 = 0.5,
        };
        pub fn draw(self: Tree, b: *j2d.Batch, draw_opt: DrawOption) !void {
            var stack = try std.ArrayList(*const TreeNode).initCapacity(self.allocator, 10);
            defer stack.deinit(self.allocator);
            try stack.append(self.allocator, self.root);
            while (stack.pop()) |node| {
                if (node.* == .leaf) {
                    var color: jok.Color = draw_opt.rect_color;
                    var depth: f32 = draw_opt.depth;
                    if (draw_opt.query) |r| {
                        if (r.hasIntersection(node.leaf.rect)) {
                            color = draw_opt.query_color;
                            depth -= 0.1;
                        }
                    }
                    try b.rect(
                        node.leaf.rect,
                        color,
                        .{ .thickness = draw_opt.thickness, .depth = depth },
                    );
                } else {
                    inline for (node.node.children) |c| try stack.append(self.allocator, c);
                }
            }
        }

        fn insert(self: *Tree, tree_node: *TreeNode, o: ObjectType, bounds: jok.Rectangle) !void {
            if (tree_node.* == .node) {
                inline for (tree_node.node.children) |n| {
                    if (bounds.hasIntersection(n.getRect())) {
                        try self.insert(n, o, bounds);
                    }
                }
            } else {
                // Append object to leaf
                try tree_node.leaf.objs.append(self.arena.allocator(), o);
                if (is_searchable and opt.enable_sort) {
                    // Comparable object is sorted to enable fast search
                    std.sort.pdq(ObjectType, tree_node.leaf.objs.items, {}, std.sort.asc(ObjectType));
                }

                // Expand tree if possible
                const too_many = @as(u32, @intCast(tree_node.leaf.objs.items.len)) > opt.preferred_size_of_leaf;
                const wide_enough = tree_node.leaf.rect.width >= @as(f32, @floatFromInt(2 * opt.min_width_of_leaf));
                const tall_enough = tree_node.leaf.rect.height >= @as(f32, @floatFromInt(2 * opt.min_width_of_leaf));
                if (too_many and wide_enough and tall_enough) {
                    var new_tree_node: TreeNode = .{
                        .node = .{
                            .rect = tree_node.leaf.rect,
                            .children = .{
                                self.newLeaf(tree_node.leaf.getSubRect(0)) catch unreachable, // NW
                                self.newLeaf(tree_node.leaf.getSubRect(1)) catch unreachable, // NE
                                self.newLeaf(tree_node.leaf.getSubRect(2)) catch unreachable, // SW
                                self.newLeaf(tree_node.leaf.getSubRect(3)) catch unreachable, // SE
                            },
                        },
                    };

                    // Redistribute objects for children
                    // Since the objects are already sorted, no need to sort for children again
                    for (tree_node.leaf.objs.items) |co| {
                        const co_bounds = self.positions.get(co).?;
                        inline for (new_tree_node.node.children) |n| {
                            if (n.leaf.rect.hasIntersection(co_bounds)) {
                                try n.leaf.objs.append(self.arena.allocator(), co);
                            }
                        }
                    }

                    tree_node.leaf.objs.deinit(self.arena.allocator());
                    tree_node.* = new_tree_node;
                }
            }
        }

        fn newLeaf(self: *Tree, rect: jok.Rectangle) !*TreeNode {
            const tree_node = try self.node_pool.create(self.allocator);
            tree_node.* = .{
                .leaf = .{
                    .rect = rect,
                    .objs = try std.ArrayList(ObjectType).initCapacity(
                        self.arena.allocator(),
                        opt.preferred_size_of_leaf * 2,
                    ),
                },
            };
            return tree_node;
        }

        fn shouldCollapse(self: *Tree, parent: *TreeNode) bool {
            if (parent.* != .node) return false;

            self.dedup_set.clearRetainingCapacity();
            var count: u32 = 0;
            inline for (parent.node.children) |child| {
                if (child.* != .leaf) return false;
                for (child.leaf.objs.items) |obj| {
                    if (self.dedup_set.contains(obj)) continue;
                    self.dedup_set.put(obj, {}) catch continue;
                    count += 1;
                }
            }
            return count <= @max(4, opt.preferred_size_of_leaf / 2);
        }

        fn searchAndRemove(self: *Tree, tree_node: *TreeNode, o: ObjectType, bounds: jok.Rectangle) void {
            const S = struct {
                fn compare(target: ObjectType, _o: ObjectType) std.math.Order {
                    if (is_searchable and opt.enable_sort) {
                        return if (target == _o) .eq else if (target > _o) .gt else .lt;
                    } else unreachable;
                }
            };

            if (tree_node.* == .node) {
                inline for (tree_node.node.children) |child| {
                    if (bounds.hasIntersection(child.getRect())) {
                        self.searchAndRemove(child, o, bounds);
                    }
                }

                // Shrink the tree, collect objects into parent
                if (self.shouldCollapse(tree_node)) {
                    self.dedup_set.clearRetainingCapacity();

                    var new_tree_node: TreeNode = .{
                        .leaf = .{
                            .rect = tree_node.node.rect,
                            .objs = std.ArrayList(ObjectType).initCapacity(
                                self.arena.allocator(),
                                opt.preferred_size_of_leaf * 2,
                            ) catch unreachable,
                        },
                    };
                    inline for (tree_node.node.children) |c| {
                        for (c.leaf.objs.items) |_o| {
                            if (self.dedup_set.contains(_o)) continue;
                            self.dedup_set.put(_o, {}) catch continue;
                            new_tree_node.leaf.objs.append(self.arena.allocator(), _o) catch continue;
                        }
                        c.leaf.objs.deinit(self.arena.allocator());
                        self.node_pool.destroy(c);
                    }
                    if (is_searchable and opt.enable_sort) {
                        std.sort.pdq(ObjectType, new_tree_node.leaf.objs.items, {}, std.sort.asc(ObjectType));
                    }
                    tree_node.* = new_tree_node;
                }
            } else {
                const idx: usize = if (is_searchable and opt.enable_sort)
                    std.sort.binarySearch(
                        ObjectType,
                        tree_node.leaf.objs.items,
                        o,
                        S.compare,
                    ).?
                else for (tree_node.leaf.objs.items, 0..) |_o, i| {
                    if (_o == o) break i;
                } else unreachable;
                _ = tree_node.leaf.objs.orderedRemove(idx);
            }
        }
    };
}

const testing = std.testing;
const expect = testing.expect;
const expectEqual = testing.expectEqual;
const expectError = testing.expectError;

test "QuadTree: basic creation and destruction" {
    const allocator = testing.allocator;
    const rect = jok.Rectangle{ .x = 0, .y = 0, .width = 1000, .height = 1000 };

    const TreeType = QuadTree(u32, .{});
    const tree = try TreeType.create(allocator, rect);
    defer tree.destroy();

    try expectEqual(rect.x, tree.root.getRect().x);
    try expectEqual(rect.y, tree.root.getRect().y);
    try expectEqual(rect.width, tree.root.getRect().width);
    try expectEqual(rect.height, tree.root.getRect().height);
    try expect(tree.root.* == .leaf);
}

test "QuadTree: add single object (small rect)" {
    const allocator = testing.allocator;
    const rect = jok.Rectangle{ .x = 0, .y = 0, .width = 1000, .height = 1000 };

    const TreeType = QuadTree(u32, .{});
    const tree = try TreeType.create(allocator, rect);
    defer tree.destroy();

    const obj: u32 = 42;
    const bounds = jok.Rectangle{ .x = 90, .y = 90, .width = 20, .height = 20 };

    try tree.put(obj, bounds);
    try expectEqual(@as(usize, 1), tree.positions.count());
    try expect(tree.root.* == .leaf);
    try expectEqual(@as(usize, 1), tree.root.leaf.objs.items.len);
}

test "QuadTree: add duplicate object returns error" {
    const allocator = testing.allocator;
    const rect = jok.Rectangle{ .x = 0, .y = 0, .width = 1000, .height = 1000 };

    const TreeType = QuadTree(u32, .{});
    const tree = try TreeType.create(allocator, rect);
    defer tree.destroy();

    const obj: u32 = 42;
    const bounds = jok.Rectangle{ .x = 100, .y = 100, .width = 10, .height = 10 };

    try tree.put(obj, bounds);
    try expectError(error.AlreadyExists, tree.put(obj, bounds));
}

test "QuadTree: add object completely outside returns error" {
    const allocator = testing.allocator;
    const rect = jok.Rectangle{ .x = 0, .y = 0, .width = 1000, .height = 1000 };

    const TreeType = QuadTree(u32, .{});
    const tree = try TreeType.create(allocator, rect);
    defer tree.destroy();

    const obj: u32 = 42;
    const bounds = jok.Rectangle{ .x = 1500, .y = 100, .width = 50, .height = 50 };

    try expectError(error.NotSeeable, tree.put(obj, bounds));
}

test "QuadTree: add object partially outside is allowed" {
    const allocator = testing.allocator;
    const rect = jok.Rectangle{ .x = 0, .y = 0, .width = 1000, .height = 1000 };

    const TreeType = QuadTree(u32, .{});
    const tree = try TreeType.create(allocator, rect);
    defer tree.destroy();

    const obj: u32 = 999;
    const bounds = jok.Rectangle{ .x = 950, .y = 950, .width = 100, .height = 100 }; // overlaps edge

    try tree.put(obj, bounds);
    try expectEqual(@as(usize, 1), tree.positions.count());
}

test "QuadTree: remove object" {
    const allocator = testing.allocator;
    const rect = jok.Rectangle{ .x = 0, .y = 0, .width = 1000, .height = 1000 };

    const TreeType = QuadTree(u32, .{});
    const tree = try TreeType.create(allocator, rect);
    defer tree.destroy();

    const obj: u32 = 42;
    const bounds = jok.Rectangle{ .x = 100, .y = 100, .width = 20, .height = 20 };

    try tree.put(obj, bounds);
    try expectEqual(@as(usize, 1), tree.positions.count());

    tree.remove(obj);
    try expectEqual(@as(usize, 0), tree.positions.count());
    try expectEqual(@as(usize, 0), tree.root.leaf.objs.items.len);
}

test "QuadTree: tree subdivision on exceeding leaf capacity (same quadrant)" {
    const allocator = testing.allocator;
    const rect = jok.Rectangle{ .x = 0, .y = 0, .width = 1000, .height = 1000 };

    const TreeType = QuadTree(u32, .{ .preferred_size_of_leaf = 4 });
    const tree = try TreeType.create(allocator, rect);
    defer tree.destroy();

    var i: u32 = 0;
    while (i < 10) : (i += 1) {
        const bounds = jok.Rectangle{
            .x = 100 + @as(f32, @floatFromInt(i)) * 5,
            .y = 100 + @as(f32, @floatFromInt(i)) * 5,
            .width = 10,
            .height = 10,
        };
        try tree.put(i, bounds);
    }

    try expect(tree.root.* == .node);
}

test "QuadTree: object spanning multiple quadrants causes duplication" {
    const allocator = testing.allocator;
    const rect = jok.Rectangle{ .x = 0, .y = 0, .width = 1000, .height = 1000 };

    const TreeType = QuadTree(u32, .{ .preferred_size_of_leaf = 2 });
    const tree = try TreeType.create(allocator, rect);
    defer tree.destroy();

    // Center object that overlaps all 4 quadrants
    try tree.put(999, jok.Rectangle{ .x = 490, .y = 490, .width = 20, .height = 20 });

    // Force subdivision by adding more objects
    try tree.put(1, jok.Rectangle{ .x = 100, .y = 100, .width = 10, .height = 10 });
    try tree.put(2, jok.Rectangle{ .x = 600, .y = 100, .width = 10, .height = 10 });
    try tree.put(3, jok.Rectangle{ .x = 100, .y = 600, .width = 10, .height = 10 });
    try tree.put(4, jok.Rectangle{ .x = 600, .y = 600, .width = 10, .height = 10 });

    try expect(tree.root.* == .node);

    // Query whole area → should see 999 only once even though duplicated in leaves
    const query_rect = jok.Rectangle{ .x = 0, .y = 0, .width = 1000, .height = 1000 };
    var results = std.array_list.Managed(u32).init(allocator);
    defer results.deinit();
    try tree.query(query_rect, 0, &results);

    try expectEqual(@as(usize, 5), results.items.len); // 1,2,3,4 + 999
    var count_999: usize = 0;
    for (results.items) |id| {
        if (id == 999) count_999 += 1;
    }
    try expectEqual(@as(usize, 1), count_999);
}

test "QuadTree: query returns correct objects after subdivision" {
    const allocator = testing.allocator;
    const rect = jok.Rectangle{ .x = 0, .y = 0, .width = 1000, .height = 1000 };

    const TreeType = QuadTree(u32, .{ .preferred_size_of_leaf = 2 });
    const tree = try TreeType.create(allocator, rect);
    defer tree.destroy();

    try tree.put(10, jok.Rectangle{ .x = 100, .y = 100, .width = 50, .height = 50 }); // NW
    try tree.put(20, jok.Rectangle{ .x = 600, .y = 100, .width = 50, .height = 50 }); // NE
    try tree.put(30, jok.Rectangle{ .x = 100, .y = 600, .width = 50, .height = 50 }); // SW
    try tree.put(40, jok.Rectangle{ .x = 600, .y = 600, .width = 50, .height = 50 }); // SE

    // Force some subdivision
    var i: u32 = 0;
    while (i < 5) : (i += 1) {
        try tree.put(100 + i, jok.Rectangle{ .x = 120 + @as(f32, @floatFromInt(i)) * 10, .y = 120, .width = 10, .height = 10 });
    }

    // Query NW area
    var results = std.array_list.Managed(u32).init(allocator);
    defer results.deinit();
    try tree.query(jok.Rectangle{ .x = 0, .y = 0, .width = 300, .height = 300 }, 0, &results);

    try expect(results.items.len >= 1);
    var found_10 = false;
    for (results.items) |id| {
        if (id == 10) found_10 = true;
    }
    try expect(found_10);
}

test "QuadTree: update moves object across quadrants" {
    const allocator = testing.allocator;
    const rect = jok.Rectangle{ .x = 0, .y = 0, .width = 1000, .height = 1000 };

    const TreeType = QuadTree(u32, .{ .preferred_size_of_leaf = 4 });
    const tree = try TreeType.create(allocator, rect);
    defer tree.destroy();

    // Add several objects to force subdivision
    var i: u32 = 0;
    while (i < 12) : (i += 1) {
        const x = 100 + @as(f32, @floatFromInt(i)) * 20;
        try tree.put(i, jok.Rectangle{ .x = x, .y = 100, .width = 15, .height = 15 });
    }

    try expect(tree.root.* == .node);

    // Update one object to move it far away
    const obj_to_move: u32 = 5;
    const new_bounds = jok.Rectangle{ .x = 800, .y = 800, .width = 30, .height = 30 };

    try tree.update(obj_to_move, new_bounds);

    // Check it still exists
    try expect(tree.positions.get(obj_to_move) != null);

    // Query new area → should find it
    var results = std.array_list.Managed(u32).init(allocator);
    defer results.deinit();
    try tree.query(jok.Rectangle{ .x = 750, .y = 750, .width = 200, .height = 200 }, 0, &results);

    var found = false;
    for (results.items) |id| {
        if (id == obj_to_move) found = true;
    }
    try expect(found);
}

test "QuadTree: update to same bounds is no-op (implementation detail)" {
    const allocator = testing.allocator;
    const rect = jok.Rectangle{ .x = 0, .y = 0, .width = 1000, .height = 1000 };

    const TreeType = QuadTree(u32, .{});
    const tree = try TreeType.create(allocator, rect);
    defer tree.destroy();

    const obj: u32 = 777;
    const bounds = jok.Rectangle{ .x = 400, .y = 400, .width = 50, .height = 50 };

    try tree.put(obj, bounds);

    try tree.update(obj, bounds); // same bounds

    try expectEqual(@as(usize, 1), tree.positions.count());
}

test "QuadTree: update outside tree remove silently" {
    const allocator = testing.allocator;
    const rect = jok.Rectangle{ .x = 0, .y = 0, .width = 1000, .height = 1000 };

    const TreeType = QuadTree(u32, .{});
    const tree = try TreeType.create(allocator, rect);
    defer tree.destroy();

    const obj: u32 = 123;
    try tree.put(obj, jok.Rectangle{ .x = 100, .y = 100, .width = 20, .height = 20 });

    const bad_bounds = jok.Rectangle{ .x = 1200, .y = 1200, .width = 50, .height = 50 };
    try tree.update(obj, bad_bounds);
    try expect(!tree.positions.contains(obj));
}

test "QuadTree: clear resets tree" {
    const allocator = testing.allocator;
    const rect = jok.Rectangle{ .x = 0, .y = 0, .width = 1000, .height = 1000 };

    const TreeType = QuadTree(u32, .{ .preferred_size_of_leaf = 3 });
    const tree = try TreeType.create(allocator, rect);
    defer tree.destroy();

    var i: u32 = 0;
    while (i < 15) : (i += 1) {
        try tree.put(i, jok.Rectangle{
            .x = 100 + @as(f32, @floatFromInt(i)) * 30,
            .y = 150,
            .width = 20,
            .height = 20,
        });
    }

    try expect(tree.positions.count() > 0);
    try expect(tree.root.* == .node);

    tree.clear();

    try expectEqual(@as(usize, 0), tree.positions.count());
    try expect(tree.root.* == .leaf);
    try expectEqual(@as(usize, 0), tree.root.leaf.objs.items.len);
}
