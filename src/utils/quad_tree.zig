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
                size: u32,
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
        positions: std.AutoHashMap(ObjectType, jok.Point),

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
                .positions = std.AutoHashMap(ObjectType, jok.Point).init(allocator),
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
            self.positions.deinit();
            self.node_pool.deinit(self.allocator);
            self.arena.deinit();
            self.allocator.destroy(self);
        }

        /// Add an object into tree
        pub fn put(self: *Tree, o: ObjectType, pos: jok.Point) !void {
            if (self.positions.get(o) != null) return error.AlreadyExists;
            if (!self.root.getRect().containsPoint(pos)) return error.NotSeeable;
            try self.positions.put(o, pos);
            errdefer _ = self.positions.remove(o);
            try self.insert(self.root, o, pos);
            return;
        }

        /// Remove an object from tree
        pub fn remove(self: *Tree, o: ObjectType) void {
            const kv = self.positions.fetchRemove(o) orelse return;
            self.searchAndRemove(null, self.root, o, kv.value);
        }

        /// Update position of object
        pub fn update(self: *Tree, o: ObjectType, new_pos: jok.Point) !void {
            if (!self.root.getRect().containsPoint(new_pos)) return error.NotSeeable;
            if (self.positions.get(o)) |p| {
                const leaf = self.searchLeaf(p);
                if (leaf.rect.containsPoint(new_pos)) {
                    try self.positions.put(o, new_pos);
                } else {
                    self.remove(o);
                    try self.put(o, new_pos);
                }
            } else {
                try self.put(o, new_pos);
            }
        }

        /// Query for objects which could potentially interfect with given rectangle
        pub fn query(self: *Tree, rect: jok.Rectangle, padding: f32, results: *std.array_list.Managed(ObjectType)) !void {
            var stack = try std.ArrayList(*const TreeNode).initCapacity(self.allocator, 10);
            defer stack.deinit(self.allocator);
            try stack.append(self.allocator, self.root);
            while (stack.pop()) |node| {
                if (!rect.padded(padding).hasIntersection(node.getRect())) continue;
                if (node.* == .leaf) {
                    for (node.leaf.objs.items) |o| try results.append(o);
                } else {
                    inline for (node.node.children) |c| try stack.append(self.allocator, c);
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

        fn insert(self: *Tree, tree_node: *TreeNode, o: ObjectType, pos: jok.Point) !void {
            if (tree_node.* == .node) {
                for (tree_node.node.children) |n| {
                    if (n.getRect().containsPoint(pos)) {
                        try self.insert(n, o, pos);
                        tree_node.node.size += 1;
                        return;
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
                if (@as(u32, @intCast(tree_node.leaf.objs.items.len)) > opt.preferred_size_of_leaf and
                    tree_node.leaf.rect.width >= @as(f32, @floatFromInt(2 * opt.min_width_of_leaf)))
                {
                    var new_tree_node: TreeNode = .{
                        .node = .{
                            .rect = tree_node.leaf.rect,
                            .children = .{
                                self.newLeaf(tree_node.leaf.getSubRect(0)) catch unreachable, // NW
                                self.newLeaf(tree_node.leaf.getSubRect(1)) catch unreachable, // NE
                                self.newLeaf(tree_node.leaf.getSubRect(2)) catch unreachable, // SW
                                self.newLeaf(tree_node.leaf.getSubRect(3)) catch unreachable, // SE
                            },
                            .size = @intCast(tree_node.leaf.objs.items.len),
                        },
                    };

                    // Redistribute objects for children
                    // Since the objects are already sorted, no need to sort for children again
                    for (tree_node.leaf.objs.items) |co| {
                        const obj_pos = self.positions.get(co).?;
                        for (new_tree_node.node.children) |n| {
                            if (n.leaf.rect.containsPoint(obj_pos)) {
                                n.leaf.objs.append(self.arena.allocator(), co) catch unreachable;
                                break;
                            }
                        } else unreachable;
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

        fn searchLeaf(self: *const Tree, pos: jok.Point) *const TreeNode.Leaf {
            var current = self.root;
            while (current.* == .node) {
                for (current.node.children) |child| {
                    if (child.getRect().containsPoint(pos)) {
                        current = child;
                        break;
                    }
                } else unreachable;
            }
            assert(current.leaf.rect.containsPoint(pos));
            return &current.leaf;
        }

        fn searchAndRemove(self: *Tree, parent: ?*TreeNode, tree_node: *TreeNode, o: ObjectType, pos: jok.Point) void {
            const S = struct {
                fn compare(target: ObjectType, _o: ObjectType) std.math.Order {
                    if (is_searchable and opt.enable_sort) {
                        return if (target == _o) .eq else if (target > _o) .gt else .lt;
                    } else unreachable;
                }
            };

            if (tree_node.* == .node) {
                for (tree_node.node.children) |n| {
                    if (n.getRect().containsPoint(pos)) {
                        self.searchAndRemove(tree_node, n, o, pos);
                        break;
                    }
                } else unreachable;
            } else {
                assert(tree_node.leaf.rect.containsPoint(pos));

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

            if (parent) |p| {
                p.node.size -= 1;
                if (p.node.size < opt.preferred_size_of_leaf / 2) {
                    // Shrink the tree, collect objects into parent
                    var new_tree_node: TreeNode = .{
                        .leaf = .{
                            .rect = p.node.rect,
                            .objs = std.ArrayList(ObjectType).initCapacity(
                                self.arena.allocator(),
                                opt.preferred_size_of_leaf * 2,
                            ) catch unreachable,
                        },
                    };
                    for (p.node.children) |c| {
                        for (c.leaf.objs.items) |_o| {
                            new_tree_node.leaf.objs.append(
                                self.arena.allocator(),
                                _o,
                            ) catch unreachable;
                        }
                        c.leaf.objs.deinit(self.arena.allocator());
                        self.node_pool.destroy(c);
                    }
                    if (is_searchable and opt.enable_sort) {
                        std.sort.pdq(ObjectType, new_tree_node.leaf.objs.items, {}, std.sort.asc(ObjectType));
                    }
                    p.* = new_tree_node;
                }
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

test "QuadTree: add single object" {
    const allocator = testing.allocator;
    const rect = jok.Rectangle{ .x = 0, .y = 0, .width = 1000, .height = 1000 };

    const TreeType = QuadTree(u32, .{});
    const tree = try TreeType.create(allocator, rect);
    defer tree.destroy();

    const obj: u32 = 42;
    const pos = jok.Point{ .x = 100, .y = 100 };

    try tree.put(obj, pos);
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
    const pos = jok.Point{ .x = 100, .y = 100 };

    try tree.put(obj, pos);
    try expectError(Error.AlreadyExists, tree.put(obj, pos));
}

test "QuadTree: add object outside bounds returns error" {
    const allocator = testing.allocator;
    const rect = jok.Rectangle{ .x = 0, .y = 0, .width = 1000, .height = 1000 };

    const TreeType = QuadTree(u32, .{});
    const tree = try TreeType.create(allocator, rect);
    defer tree.destroy();

    const obj: u32 = 42;
    const pos = jok.Point{ .x = 1500, .y = 100 };

    try expectError(Error.NotSeeable, tree.put(obj, pos));
}

test "QuadTree: remove object" {
    const allocator = testing.allocator;
    const rect = jok.Rectangle{ .x = 0, .y = 0, .width = 1000, .height = 1000 };

    const TreeType = QuadTree(u32, .{});
    const tree = try TreeType.create(allocator, rect);
    defer tree.destroy();

    const obj: u32 = 42;
    const pos = jok.Point{ .x = 100, .y = 100 };

    try tree.put(obj, pos);
    try expectEqual(@as(usize, 1), tree.positions.count());

    tree.remove(obj);
    try expectEqual(@as(usize, 0), tree.positions.count());
    try expectEqual(@as(usize, 0), tree.root.leaf.objs.items.len);
}

test "QuadTree: remove non-existent object is safe" {
    const allocator = testing.allocator;
    const rect = jok.Rectangle{ .x = 0, .y = 0, .width = 1000, .height = 1000 };

    const TreeType = QuadTree(u32, .{});
    const tree = try TreeType.create(allocator, rect);
    defer tree.destroy();

    // Should not crash
    tree.remove(999);
    try expectEqual(@as(usize, 0), tree.positions.count());
}

test "QuadTree: tree subdivision on exceeding leaf capacity" {
    const allocator = testing.allocator;
    const rect = jok.Rectangle{ .x = 0, .y = 0, .width = 1000, .height = 1000 };

    const TreeType = QuadTree(u32, .{ .preferred_size_of_leaf = 4 });
    const tree = try TreeType.create(allocator, rect);
    defer tree.destroy();

    // Add objects to same quadrant to force subdivision
    var i: u32 = 0;
    while (i < 10) : (i += 1) {
        const pos = jok.Point{
            .x = 100 + @as(f32, @floatFromInt(i)) * 10,
            .y = 100 + @as(f32, @floatFromInt(i)) * 10,
        };
        try tree.put(i, pos);
    }

    // Tree should have subdivided
    try expect(tree.root.* == .node);
    try expectEqual(@as(u32, 10), tree.root.node.size);
}

test "QuadTree: objects distributed across quadrants" {
    const allocator = testing.allocator;
    const rect = jok.Rectangle{ .x = 0, .y = 0, .width = 1000, .height = 1000 };

    const TreeType = QuadTree(u32, .{ .preferred_size_of_leaf = 2 });
    const tree = try TreeType.create(allocator, rect);
    defer tree.destroy();

    // Add objects to different quadrants
    try tree.put(1, jok.Point{ .x = 100, .y = 100 }); // NW
    try tree.put(2, jok.Point{ .x = 600, .y = 100 }); // NE
    try tree.put(3, jok.Point{ .x = 100, .y = 600 }); // SW
    try tree.put(4, jok.Point{ .x = 600, .y = 600 }); // SE
    try tree.put(5, jok.Point{ .x = 150, .y = 150 }); // NW
    try tree.put(6, jok.Point{ .x = 650, .y = 150 }); // NE

    try expect(tree.root.* == .node);
    try expectEqual(@as(u32, 6), tree.root.node.size);
}

test "QuadTree: query empty tree" {
    const allocator = testing.allocator;
    const rect = jok.Rectangle{ .x = 0, .y = 0, .width = 1000, .height = 1000 };

    const TreeType = QuadTree(u32, .{});
    const tree = try TreeType.create(allocator, rect);
    defer tree.destroy();

    const query_rect = jok.Rectangle{ .x = 100, .y = 100, .width = 200, .height = 200 };
    var results = std.array_list.Managed(u32).init(allocator);
    defer results.deinit();
    try tree.query(query_rect, 0, &results);

    try expectEqual(@as(usize, 0), results.items.len);
}

test "QuadTree: query returns correct objects" {
    const allocator = testing.allocator;
    const rect = jok.Rectangle{ .x = 0, .y = 0, .width = 1000, .height = 1000 };

    const TreeType = QuadTree(u32, .{});
    const tree = try TreeType.create(allocator, rect);
    defer tree.destroy();

    // Add objects at various positions
    try tree.put(1, jok.Point{ .x = 100, .y = 100 });
    try tree.put(2, jok.Point{ .x = 500, .y = 500 });
    try tree.put(3, jok.Point{ .x = 900, .y = 900 });

    // Query that intersects with the entire tree (since root is still a leaf)
    // This should return all objects
    const query_rect1 = jok.Rectangle{ .x = 0, .y = 0, .width = 1000, .height = 1000 };
    var results1 = std.array_list.Managed(u32).init(allocator);
    defer results1.deinit();
    try tree.query(query_rect1, 0, &results1);

    try expectEqual(@as(usize, 3), results1.items.len);

    // Query that intersects the leaf (which contains all objects)
    // Even a small query will return all objects in the leaf
    const query_rect2 = jok.Rectangle{ .x = 50, .y = 50, .width = 100, .height = 100 };
    var results2 = std.array_list.Managed(u32).init(allocator);
    defer results2.deinit();
    try tree.query(query_rect2, 0, &results2);

    // Since the tree hasn't subdivided, the query returns all objects in the intersecting leaf
    try expectEqual(@as(usize, 3), results2.items.len);
}

test "QuadTree: query after subdivision" {
    const allocator = testing.allocator;
    const rect = jok.Rectangle{ .x = 0, .y = 0, .width = 1000, .height = 1000 };

    const TreeType = QuadTree(u32, .{ .preferred_size_of_leaf = 2 });
    const tree = try TreeType.create(allocator, rect);
    defer tree.destroy();

    // Add enough objects to force subdivision, all in NW quadrant
    try tree.put(0, jok.Point{ .x = 100, .y = 100 });
    try tree.put(1, jok.Point{ .x = 150, .y = 100 });
    try tree.put(2, jok.Point{ .x = 200, .y = 100 });

    // Also add objects to other quadrants
    try tree.put(10, jok.Point{ .x = 600, .y = 100 }); // NE
    try tree.put(11, jok.Point{ .x = 650, .y = 150 }); // NE
    try tree.put(20, jok.Point{ .x = 100, .y = 600 }); // SW
    try tree.put(30, jok.Point{ .x = 600, .y = 600 }); // SE

    // Tree should be subdivided now
    try expect(tree.root.* == .node);

    // Query only NW quadrant - should only get objects from that quadrant
    const query_rect1 = jok.Rectangle{ .x = 0, .y = 0, .width = 300, .height = 300 };
    var results1 = std.array_list.Managed(u32).init(allocator);
    defer results1.deinit();
    try tree.query(query_rect1, 0, &results1);

    try expect(results1.items.len == 3);
    // Verify they're the NW objects
    var found_nw = false;
    for (results1.items) |obj| {
        if (obj == 0 or obj == 1 or obj == 2) found_nw = true;
    }
    try expect(found_nw);

    // Query only SE quadrant
    const query_rect2 = jok.Rectangle{ .x = 501, .y = 501, .width = 500, .height = 500 };
    var results2 = std.array_list.Managed(u32).init(allocator);
    defer results2.deinit();
    try tree.query(query_rect2, 0, &results2);

    try expect(results2.items.len == 1);
    try expectEqual(@as(u32, 30), results2.items[0]);

    // Query that spans multiple quadrants
    const query_rect3 = jok.Rectangle{ .x = 501, .y = 0, .width = 400, .height = 400 };
    var results3 = std.array_list.Managed(u32).init(allocator);
    defer results3.deinit();
    try tree.query(query_rect3, 0, &results3);

    // Should get objects from NE quadrant
    try expect(results3.items.len == 2);
}

test "QuadTree: clear resets tree" {
    const allocator = testing.allocator;
    const rect = jok.Rectangle{ .x = 0, .y = 0, .width = 1000, .height = 1000 };

    const TreeType = QuadTree(u32, .{ .preferred_size_of_leaf = 2 });
    const tree = try TreeType.create(allocator, rect);
    defer tree.destroy();

    // Add objects
    var i: u32 = 0;
    while (i < 10) : (i += 1) {
        const pos = jok.Point{
            .x = 100 + @as(f32, @floatFromInt(i)) * 50,
            .y = 100,
        };
        try tree.put(i, pos);
    }

    try expect(tree.positions.count() > 0);

    // Clear
    tree.clear();

    // Verify tree is reset
    try expectEqual(@as(usize, 0), tree.positions.count());
    try expect(tree.root.* == .leaf);
    try expectEqual(@as(usize, 0), tree.root.leaf.objs.items.len);

    // Should be able to add objects again
    try tree.put(100, jok.Point{ .x = 100, .y = 100 });
    try expectEqual(@as(usize, 1), tree.positions.count());
}

test "QuadTree: tree shrinking after removals" {
    const allocator = testing.allocator;
    const rect = jok.Rectangle{ .x = 0, .y = 0, .width = 1000, .height = 1000 };

    const TreeType = QuadTree(u32, .{ .preferred_size_of_leaf = 4 });
    const tree = try TreeType.create(allocator, rect);
    defer tree.destroy();

    // Add enough objects to force subdivision
    var i: u32 = 0;
    while (i < 10) : (i += 1) {
        const pos = jok.Point{
            .x = 100 + @as(f32, @floatFromInt(i)) * 50,
            .y = 100,
        };
        try tree.put(i, pos);
    }

    try expect(tree.root.* == .node);

    // Remove most objects
    i = 0;
    while (i < 9) : (i += 1) {
        tree.remove(i);
    }

    // Tree should shrink back to leaf
    try expect(tree.root.* == .leaf);
    try expectEqual(@as(usize, 1), tree.root.leaf.objs.items.len);
}

test "QuadTree: with sorted integers" {
    const allocator = testing.allocator;
    const rect = jok.Rectangle{ .x = 0, .y = 0, .width = 1000, .height = 1000 };

    const TreeType = QuadTree(u32, .{ .enable_sort = true });
    const tree = try TreeType.create(allocator, rect);
    defer tree.destroy();

    // Add objects in non-sorted order
    try tree.put(50, jok.Point{ .x = 100, .y = 100 });
    try tree.put(10, jok.Point{ .x = 150, .y = 100 });
    try tree.put(30, jok.Point{ .x = 200, .y = 100 });
    try tree.put(20, jok.Point{ .x = 250, .y = 100 });

    // Objects should be sorted in leaf
    try expect(tree.root.* == .leaf);
    const items = tree.root.leaf.objs.items;
    try expectEqual(@as(u32, 10), items[0]);
    try expectEqual(@as(u32, 20), items[1]);
    try expectEqual(@as(u32, 30), items[2]);
    try expectEqual(@as(u32, 50), items[3]);

    // Removal should still work with sorted array
    tree.remove(20);
    try expectEqual(@as(usize, 3), tree.root.leaf.objs.items.len);
}

test "QuadTree: pointer types" {
    const allocator = testing.allocator;
    const rect = jok.Rectangle{ .x = 0, .y = 0, .width = 1000, .height = 1000 };

    const Object = struct {
        id: u32,
        value: f32,
    };

    var obj1 = Object{ .id = 1, .value = 1.5 };
    var obj2 = Object{ .id = 2, .value = 2.5 };

    const TreeType = QuadTree(*Object, .{});
    const tree = try TreeType.create(allocator, rect);
    defer tree.destroy();

    try tree.put(&obj1, jok.Point{ .x = 100, .y = 100 });
    try tree.put(&obj2, jok.Point{ .x = 200, .y = 200 });

    try expectEqual(@as(usize, 2), tree.positions.count());

    // Query should find both objects
    const query_rect = jok.Rectangle{ .x = 0, .y = 0, .width = 300, .height = 300 };
    var results = std.array_list.Managed(*Object).init(allocator);
    defer results.deinit();
    try tree.query(query_rect, 0, &results);

    try expectEqual(@as(usize, 2), results.items.len);
}

test "QuadTree: minimum width constraint" {
    const allocator = testing.allocator;
    const rect = jok.Rectangle{ .x = 0, .y = 0, .width = 200, .height = 200 };

    const TreeType = QuadTree(u32, .{
        .preferred_size_of_leaf = 2,
        .min_width_of_leaf = 150, // Prevents subdivision
    });
    const tree = try TreeType.create(allocator, rect);
    defer tree.destroy();

    // Try to add more than preferred_size_of_leaf
    var i: u32 = 0;
    while (i < 10) : (i += 1) {
        const pos = jok.Point{
            .x = 50 + @as(f32, @floatFromInt(i)) * 5,
            .y = 50,
        };
        try tree.put(i, pos);
    }

    // Should not subdivide due to min_width constraint
    try expect(tree.root.* == .leaf);
    try expectEqual(@as(usize, 10), tree.root.leaf.objs.items.len);
}

test "QuadTree: stress test with many objects" {
    const allocator = testing.allocator;
    const rect = jok.Rectangle{ .x = 0, .y = 0, .width = 10000, .height = 10000 };

    const TreeType = QuadTree(u32, .{});
    const tree = try TreeType.create(allocator, rect);
    defer tree.destroy();

    // Add 1000 objects
    var i: u32 = 0;
    while (i < 1000) : (i += 1) {
        const pos = jok.Point{
            .x = @mod(@as(f32, @floatFromInt(i)) * 73.2, 10000),
            .y = @mod(@as(f32, @floatFromInt(i)) * 41.7, 10000),
        };
        try tree.put(i, pos);
    }

    try expectEqual(@as(usize, 1000), tree.positions.count());

    // Query a small region
    const query_rect = jok.Rectangle{ .x = 1000, .y = 1000, .width = 500, .height = 500 };
    var results = std.array_list.Managed(u32).init(allocator);
    defer results.deinit();
    try tree.query(query_rect, 0, &results);

    // Should find some but not all objects
    try expect(results.items.len > 0);
    try expect(results.items.len < 1000);

    // Remove half the objects
    i = 0;
    while (i < 500) : (i += 1) {
        tree.remove(i);
    }

    try expectEqual(@as(usize, 500), tree.positions.count());
}

test "QuadTree: boundary cases" {
    const allocator = testing.allocator;
    const rect = jok.Rectangle{ .x = 0, .y = 0, .width = 1000, .height = 1000 };

    const TreeType = QuadTree(u32, .{ .preferred_size_of_leaf = 2 });
    const tree = try TreeType.create(allocator, rect);
    defer tree.destroy();

    // Objects at exact boundaries
    try tree.put(1, jok.Point{ .x = 0, .y = 0 });
    try tree.put(2, jok.Point{ .x = 999.9, .y = 999.9 });
    try tree.put(3, jok.Point{ .x = 501, .y = 501 });

    try expectEqual(@as(usize, 3), tree.positions.count());

    // Query at boundaries
    const query_rect = jok.Rectangle{ .x = 0, .y = 0, .width = 1, .height = 1 };
    var results = std.array_list.Managed(u32).init(allocator);
    defer results.deinit();
    try tree.query(query_rect, 0, &results);

    try expectEqual(@as(usize, 1), results.items.len);
}

test "QuadTree: update - in-place update within same leaf" {
    const allocator = testing.allocator;
    const rect = jok.Rectangle{ .x = 0, .y = 0, .width = 1000, .height = 1000 };
    const TreeType = QuadTree(u32, .{ .preferred_size_of_leaf = 8 });
    const tree = try TreeType.create(allocator, rect);
    defer tree.destroy();

    const obj: u32 = 42;
    const old_pos = jok.Point{ .x = 100, .y = 100 };
    const new_pos = jok.Point{ .x = 120, .y = 120 }; // still within the same leaf

    try tree.put(obj, old_pos);
    try expectEqual(@as(usize, 1), tree.positions.count());

    // Perform update (should use in-place path)
    try tree.update(obj, new_pos);

    // Verify position updated and tree structure unchanged (still a leaf)
    try expectEqual(@as(usize, 1), tree.positions.count());
    try expect(tree.root.* == .leaf);
    try expectEqual(@as(usize, 1), tree.root.leaf.objs.items.len);

    const updated_pos = tree.positions.get(obj).?;
    try expectEqual(new_pos.x, updated_pos.x);
    try expectEqual(new_pos.y, updated_pos.y);
}

test "QuadTree: update - move across leaves" {
    const allocator = testing.allocator;
    const rect = jok.Rectangle{ .x = 0, .y = 0, .width = 1000, .height = 1000 };
    const TreeType = QuadTree(u32, .{ .preferred_size_of_leaf = 4 }); // small capacity to force subdivision
    const tree = try TreeType.create(allocator, rect);
    defer tree.destroy();

    // Add objects to force subdivision in NW quadrant
    var i: u32 = 0;
    while (i < 10) : (i += 1) {
        const pos = jok.Point{ .x = 100 + @as(f32, @floatFromInt(i)) * 10, .y = 100 + @as(f32, @floatFromInt(i)) * 10 };
        try tree.put(i, pos);
    }
    try expect(tree.root.* == .node); // confirm subdivision occurred

    // Select an object in NW quadrant
    const obj: u32 = 5;
    try expect(tree.positions.get(obj) != null);

    // Move to SE quadrant (cross-leaf movement)
    const new_pos = jok.Point{ .x = 800, .y = 800 };

    try tree.update(obj, new_pos);

    // Verify position updated successfully
    const updated_pos = tree.positions.get(obj).?;
    try expectEqual(new_pos.x, updated_pos.x);
    try expectEqual(new_pos.y, updated_pos.y);

    // Verify total object count remains correct
    try expectEqual(@as(usize, 10), tree.positions.count());
}

test "QuadTree: update - move to same position (should be no-op)" {
    const allocator = testing.allocator;
    const rect = jok.Rectangle{ .x = 0, .y = 0, .width = 1000, .height = 1000 };
    const TreeType = QuadTree(u32, .{});
    const tree = try TreeType.create(allocator, rect);
    defer tree.destroy();

    const obj: u32 = 100;
    const pos = jok.Point{ .x = 500, .y = 500 };

    try tree.put(obj, pos);

    // Update to the exact same position
    try tree.update(obj, pos);

    // Position should remain unchanged
    const current_pos = tree.positions.get(obj).?;
    try expectEqual(pos.x, current_pos.x);
    try expectEqual(pos.y, current_pos.y);
}

test "QuadTree: update - object does not exist yet" {
    const allocator = testing.allocator;
    const rect = jok.Rectangle{ .x = 0, .y = 0, .width = 1000, .height = 1000 };
    const TreeType = QuadTree(u32, .{});
    const tree = try TreeType.create(allocator, rect);
    defer tree.destroy();

    const obj: u32 = 999;
    const new_pos = jok.Point{ .x = 300, .y = 300 };

    // Update non-existent object (current implementation will add it)
    try tree.update(obj, new_pos);

    // Verify object was added
    try expectEqual(@as(usize, 1), tree.positions.count());
    try expect(tree.positions.get(obj) != null);
}

test "QuadTree: update - attempt to move outside tree bounds" {
    const allocator = testing.allocator;
    const rect = jok.Rectangle{ .x = 0, .y = 0, .width = 1000, .height = 1000 };
    const TreeType = QuadTree(u32, .{});
    const tree = try TreeType.create(allocator, rect);
    defer tree.destroy();

    const obj: u32 = 42;
    try tree.put(obj, jok.Point{ .x = 100, .y = 100 });

    const outside_pos = jok.Point{ .x = 1500, .y = 500 };

    // Should return NotSeeable error
    try expectError(error.NotSeeable, tree.update(obj, outside_pos));

    // Position should remain unchanged
    const current_pos = tree.positions.get(obj).?;
    try expectEqual(@as(f32, 100), current_pos.x);
    try expectEqual(@as(f32, 100), current_pos.y);
}
