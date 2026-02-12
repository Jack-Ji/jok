//! Generic quad tree for efficient spatial partitioning and collision detection.
//!
//! A quad tree is a tree data structure where each internal node has exactly four children.
//! It's used to partition 2D space by recursively subdividing it into four quadrants.
//!
//! Features:
//! - Efficient spatial queries (find objects in a region)
//! - Dynamic insertion and removal of objects
//! - Automatic subdivision when capacity is exceeded
//! - Optional sorting for deterministic iteration
//! - Configurable leaf size and minimum dimensions
//! - Optional collision sizes for precise filtering (size + position => rect)
//! - Sized objects may span multiple leaves, which adds bookkeeping cost
//!
//! Use cases:
//! - Broad-phase collision detection
//! - Spatial indexing for large numbers of objects
//! - Frustum culling
//! - Nearest neighbor searches
//!
//! Example usage:
//! ```zig
//! const MyQuadTree = QuadTree(u32, .{
//!     .preferred_size_of_leaf = 8,
//!     .min_width_of_leaf = 64,
//! });
//!
//! var tree = try MyQuadTree.create(allocator, .{
//!     .x = 0, .y = 0, .width = 1024, .height = 1024
//! });
//! defer tree.destroy();
//!
//! try tree.put(object_id, position, .{});
//! var results = std.array_list.Managed(u32).init(allocator);
//! try tree.query(search_rect, 0, &results, .{});
//! try tree.query(search_rect, 0, &results, .{ .precise = true });
//! ```

const std = @import("std");
const assert = std.debug.assert;
const jok = @import("../jok.zig");
const j2d = jok.j2d;
const Point = j2d.geom.Point;
const Size = j2d.geom.Size;
const Rectangle = j2d.geom.Rectangle;

/// Errors that can occur during quad tree operations
pub const Error = error{
    /// Object already exists in the tree
    AlreadyExists,
    /// Object position is outside the tree bounds
    NotSeeable,
};

/// Configuration options for quad tree behavior
pub const TreeOption = struct {
    preferred_size_of_leaf: u32 = 8, // Maximum number of objects within a leaf
    min_width_of_leaf: u32 = 64, // Minimum width of rectangle
    enable_sort: bool = false, // Do quick sort if possible
};

/// Options for put operation
pub const PutOption = struct {
    /// Optional collision size (size + pos => rect)
    size: ?Size = null,
};

/// Options for query operation
pub const QueryOption = struct {
    /// Enable precise filtering by sizes (default: false)
    precise: bool = false,
};

/// Generic quad tree data structure
/// ObjectType: Type of objects to store (must be int or single-item pointer)
/// opt: Configuration options for tree behavior
pub fn QuadTree(comptime ObjectType: type, opt: TreeOption) type {
    const type_info = @typeInfo(ObjectType);
    const is_searchable = type_info == .int or (type_info == .pointer and type_info.pointer.size == .one);

    return struct {
        const Tree = @This();
        pub const TreeNode = union(enum) {
            pub const Node = struct {
                rect: Rectangle,
                children: [4]*TreeNode, // NW, NE, SW, SE
                size: u32,
            };
            pub const Leaf = struct {
                rect: Rectangle,
                objs: std.ArrayList(ObjectType),

                fn getSubRect(self: Leaf, child_idx: u32) Rectangle {
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

            pub inline fn getRect(self: TreeNode) Rectangle {
                return if (self == .node) self.node.rect else self.leaf.rect;
            }
        };

        allocator: std.mem.Allocator,
        arena: std.heap.ArenaAllocator,
        node_pool: std.heap.MemoryPool(TreeNode),
        root: *TreeNode,
        positions: std.AutoHashMap(ObjectType, Point),
        sizes: std.AutoHashMap(ObjectType, Size),
        leaves: std.AutoHashMap(ObjectType, std.ArrayList(*TreeNode.Leaf)),

        /// Initialize new tree
        pub fn create(allocator: std.mem.Allocator, rect: Rectangle) !*Tree {
            assert(rect.area() > 0);

            var tree = try allocator.create(Tree);
            errdefer allocator.destroy(tree);

            tree.* = .{
                .allocator = allocator,
                .arena = std.heap.ArenaAllocator.init(allocator),
                .node_pool = try std.heap.MemoryPool(TreeNode).initCapacity(allocator, 1024),
                .root = undefined,
                .positions = std.AutoHashMap(ObjectType, Point).init(allocator),
                .sizes = std.AutoHashMap(ObjectType, Size).init(allocator),
                .leaves = std.AutoHashMap(ObjectType, std.ArrayList(*TreeNode.Leaf)).init(allocator),
            };
            errdefer {
                tree.node_pool.deinit(allocator);
                tree.arena.deinit();
                tree.sizes.deinit();
                tree.leaves.deinit();
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
            // Clean up leaf lists
            var it = self.leaves.iterator();
            while (it.next()) |entry| {
                entry.value_ptr.deinit(self.allocator);
            }

            self.positions.deinit();
            self.sizes.deinit();
            self.leaves.deinit();
            self.node_pool.deinit(self.allocator);
            self.arena.deinit();
            self.allocator.destroy(self);
        }

        /// Add an object into tree
        pub fn put(self: *Tree, o: ObjectType, pos: Point, put_opt: PutOption) !void {
            if (self.positions.get(o) != null) return error.AlreadyExists;

            if (put_opt.size) |size| {
                // Add object with collision size
                // Calculate bounding rectangle
                const w = size.getWidthFloat();
                const h = size.getHeightFloat();
                const rect: Rectangle = .{
                    .x = pos.x - w * 0.5,
                    .y = pos.y - h * 0.5,
                    .width = w,
                    .height = h,
                };

                if (!self.root.getRect().hasIntersection(rect)) return error.NotSeeable;

                // Find all leaves that intersect the rectangle
                var leaf_list = try std.ArrayList(*TreeNode.Leaf).initCapacity(self.allocator, 4);
                errdefer leaf_list.deinit(self.allocator);
                try self.findIntersectingLeaves(self.root, rect, &leaf_list);

                if (leaf_list.items.len == 0) {
                    leaf_list.deinit(self.allocator);
                    return error.NotSeeable;
                }

                // Insert into all intersecting leaves
                try self.positions.put(o, pos);
                errdefer _ = self.positions.remove(o);

                for (leaf_list.items) |leaf| {
                    try leaf.objs.append(self.arena.allocator(), o);
                    if (is_searchable and opt.enable_sort) {
                        std.sort.pdq(ObjectType, leaf.objs.items, {}, std.sort.asc(ObjectType));
                    }
                }

                // Store leaf list and size
                try self.leaves.put(o, leaf_list);
                self.sizes.put(o, size) catch unreachable;

                // Check if any of the leaves need subdivision
                // We need to find the parent nodes and trigger subdivision
                try self.checkAndSubdivideForSizedObject(self.root, null, rect);
            } else {
                // Add object without size (point-based)
                if (!self.root.getRect().containsPoint(pos)) return error.NotSeeable;
                try self.positions.put(o, pos);
                errdefer _ = self.positions.remove(o);
                try self.insert(self.root, o, pos);
            }
        }

        /// Remove an object from tree
        pub fn remove(self: *Tree, o: ObjectType) void {
            _ = self.sizes.remove(o);
            const kv = self.positions.fetchRemove(o) orelse return;

            // Check if object has tracked leaves (sized object)
            if (self.leaves.fetchRemove(o)) |leaf_kv| {
                // Remove from all tracked leaves
                for (leaf_kv.value.items) |leaf| {
                    const idx: usize = if (is_searchable and opt.enable_sort)
                        std.sort.binarySearch(
                            ObjectType,
                            leaf.objs.items,
                            o,
                            struct {
                                fn compare(target: ObjectType, _o: ObjectType) std.math.Order {
                                    return if (target == _o) .eq else if (target > _o) .gt else .lt;
                                }
                            }.compare,
                        ).?
                    else for (leaf.objs.items, 0..) |_o, i| {
                        if (_o == o) break i;
                    } else unreachable;
                    _ = leaf.objs.orderedRemove(idx);
                }
                // Clean up leaf list
                var leaves_list = leaf_kv.value;
                leaves_list.deinit(self.allocator);
            } else {
                // Non-sized object: use existing searchAndRemove logic
                self.searchAndRemove(null, self.root, o, kv.value);
            }
        }

        /// Update position of object
        pub fn update(self: *Tree, o: ObjectType, new_pos: Point) !void {
            if (self.positions.get(o)) |p| {
                // Check if object has size
                if (self.sizes.get(o)) |size| {
                    // Sized object: recalculate overlapping leaves
                    const w = size.getWidthFloat();
                    const h = size.getHeightFloat();
                    const rect: Rectangle = .{
                        .x = new_pos.x - w * 0.5,
                        .y = new_pos.y - h * 0.5,
                        .width = w,
                        .height = h,
                    };

                    if (!self.root.getRect().hasIntersection(rect)) {
                        self.remove(o);
                        return;
                    }

                    // Find new intersecting leaves
                    var new_leaf_list = try std.ArrayList(*TreeNode.Leaf).initCapacity(self.allocator, 4);
                    errdefer new_leaf_list.deinit(self.allocator);
                    try self.findIntersectingLeaves(self.root, rect, &new_leaf_list);

                    if (new_leaf_list.items.len == 0) {
                        new_leaf_list.deinit(self.allocator);
                        self.remove(o);
                        return;
                    }

                    // Remove from old leaves based on previous position/size to avoid stale pointers
                    const old_w = size.getWidthFloat();
                    const old_h = size.getHeightFloat();
                    const old_rect: Rectangle = .{
                        .x = p.x - old_w * 0.5,
                        .y = p.y - old_h * 0.5,
                        .width = old_w,
                        .height = old_h,
                    };
                    var old_leaf_list = try std.ArrayList(*TreeNode.Leaf).initCapacity(self.allocator, 4);
                    defer old_leaf_list.deinit(self.allocator);
                    try self.findIntersectingLeaves(self.root, old_rect, &old_leaf_list);
                    for (old_leaf_list.items) |leaf| {
                        const idx: usize = if (is_searchable and opt.enable_sort)
                            std.sort.binarySearch(
                                ObjectType,
                                leaf.objs.items,
                                o,
                                struct {
                                    fn compare(target: ObjectType, _o: ObjectType) std.math.Order {
                                        return if (target == _o) .eq else if (target > _o) .gt else .lt;
                                    }
                                }.compare,
                            ).?
                        else for (leaf.objs.items, 0..) |_o, i| {
                            if (_o == o) break i;
                        } else unreachable;
                        _ = leaf.objs.orderedRemove(idx);
                    }

                    // Add to new leaves
                    for (new_leaf_list.items) |leaf| {
                        try leaf.objs.append(self.arena.allocator(), o);
                        if (is_searchable and opt.enable_sort) {
                            std.sort.pdq(ObjectType, leaf.objs.items, {}, std.sort.asc(ObjectType));
                        }
                    }

                    // Clean up old leaf list and update
                    if (self.leaves.fetchRemove(o)) |kv| {
                        var old_list = kv.value;
                        old_list.deinit(self.allocator);
                    }
                    try self.leaves.put(o, new_leaf_list);
                    try self.positions.put(o, new_pos);
                } else {
                    // Non-sized object: use existing logic
                    if (!self.root.getRect().containsPoint(new_pos)) {
                        self.remove(o);
                        return;
                    }

                    const leaf = self.searchLeaf(p);
                    if (leaf.rect.containsPoint(new_pos)) {
                        try self.positions.put(o, new_pos);
                    } else {
                        self.remove(o);
                        try self.put(o, new_pos, .{});
                    }
                }
            } else {
                if (!self.root.getRect().containsPoint(new_pos)) return;
                try self.put(o, new_pos, .{});
            }
        }

        /// Update position and replace the attached collision size (size + pos => rect).
        /// Query for objects which could potentially interfect with given rectangle
        pub fn query(self: *Tree, rect: Rectangle, padding: f32, results: *std.array_list.Managed(ObjectType), query_opt: QueryOption) !void {
            const padded = rect.padded(padding);
            const start_len = results.items.len;

            // Create hash set for deduplication
            var seen = std.AutoHashMap(ObjectType, void).init(self.allocator);
            defer seen.deinit();

            var stack = try std.ArrayList(*const TreeNode).initCapacity(self.allocator, 10);
            defer stack.deinit(self.allocator);
            try stack.append(self.allocator, self.root);
            while (stack.pop()) |node| {
                if (!padded.hasIntersection(node.getRect())) continue;
                if (node.* == .leaf) {
                    for (node.leaf.objs.items) |o| {
                        if (!seen.contains(o)) {
                            try seen.put(o, {});
                            try results.append(o);
                        }
                    }
                } else {
                    inline for (node.node.children) |c| try stack.append(self.allocator, c);
                }
            }

            // Apply precise filtering if requested
            if (query_opt.precise) {
                var write_idx = start_len;
                var read_idx = start_len;
                while (read_idx < results.items.len) : (read_idx += 1) {
                    const obj = results.items[read_idx];
                    if (self.positions.get(obj)) |p| {
                        if (self.sizes.get(obj)) |size| {
                            const w = size.getWidthFloat();
                            const h = size.getHeightFloat();
                            const orect: Rectangle = .{
                                .x = p.x - w * 0.5,
                                .y = p.y - h * 0.5,
                                .width = w,
                                .height = h,
                            };
                            if (!orect.hasIntersection(padded)) continue;
                        } else if (!padded.containsPoint(p)) continue;
                    } else unreachable; // Object must exist in positions since we just queried it
                    results.items[write_idx] = obj;
                    write_idx += 1;
                }
                results.items.len = write_idx;
            }
        }

        /// Clear the map
        pub fn clear(self: *Tree) void {
            // Clean up leaf lists
            var it = self.leaves.iterator();
            while (it.next()) |entry| {
                entry.value_ptr.deinit(self.allocator);
            }

            const rect = self.root.getRect();
            _ = self.node_pool.reset(self.allocator, .retain_capacity);
            _ = self.arena.reset(.retain_capacity);
            self.positions.clearRetainingCapacity();
            self.sizes.clearRetainingCapacity();
            self.leaves.clearRetainingCapacity();

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
            query: ?Rectangle = null,
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

        fn insert(self: *Tree, tree_node: *TreeNode, o: ObjectType, pos: Point) !void {
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
                    try self.subdivideLeaf(tree_node, null);
                }
            }
        }

        fn newLeaf(self: *Tree, rect: Rectangle) !*TreeNode {
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

        fn searchLeaf(self: *const Tree, pos: Point) *const TreeNode.Leaf {
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

        /// Find all leaves that intersect with the given rectangle
        fn findIntersectingLeaves(self: *Tree, node: *TreeNode, rect: Rectangle, results: *std.ArrayList(*TreeNode.Leaf)) !void {
            if (!node.getRect().hasIntersection(rect)) return;

            if (node.* == .leaf) {
                try results.append(self.allocator, &node.leaf);
            } else {
                for (node.node.children) |child| {
                    try self.findIntersectingLeaves(child, rect, results);
                }
            }
        }

        /// Check if leaves intersecting with the given rectangle need subdivision
        /// This is called after inserting a sized object to trigger subdivision
        fn checkAndSubdivideForSizedObject(self: *Tree, node: *TreeNode, parent: ?*TreeNode, rect: Rectangle) !void {
            if (!node.getRect().hasIntersection(rect)) return;

            if (node.* == .leaf) {
                // Check if this leaf needs subdivision
                if (@as(u32, @intCast(node.leaf.objs.items.len)) > opt.preferred_size_of_leaf and
                    node.leaf.rect.width >= @as(f32, @floatFromInt(2 * opt.min_width_of_leaf)))
                {
                    // Subdivide this leaf
                    try self.subdivideLeaf(node, parent);
                }
            } else {
                // Recursively check children
                for (node.node.children) |child| {
                    try self.checkAndSubdivideForSizedObject(child, node, rect);
                }
            }
        }

        /// Subdivide a leaf node into 4 children
        fn subdivideLeaf(self: *Tree, tree_node: *TreeNode, parent: ?*TreeNode) !void {
            assert(tree_node.* == .leaf);

            // Store pointer to old leaf before we replace it
            const old_leaf_ptr = &tree_node.leaf;
            var point_count: u32 = 0;

            var new_tree_node: TreeNode = .{
                .node = .{
                    .rect = tree_node.leaf.rect,
                    .children = .{
                        try self.newLeaf(tree_node.leaf.getSubRect(0)), // NW
                        try self.newLeaf(tree_node.leaf.getSubRect(1)), // NE
                        try self.newLeaf(tree_node.leaf.getSubRect(2)), // SW
                        try self.newLeaf(tree_node.leaf.getSubRect(3)), // SE
                    },
                    .size = 0,
                },
            };

            // Redistribute objects for children
            for (tree_node.leaf.objs.items) |co| {
                const obj_pos = self.positions.get(co).?;

                // Check if this is a sized object
                if (self.sizes.get(co)) |size| {
                    // Sized object: find all intersecting child leaves and add to each
                    const w = size.getWidthFloat();
                    const h = size.getHeightFloat();
                    const obj_rect = Rectangle{
                        .x = obj_pos.x - w * 0.5,
                        .y = obj_pos.y - h * 0.5,
                        .width = w,
                        .height = h,
                    };

                    for (new_tree_node.node.children) |n| {
                        if (n.leaf.rect.hasIntersection(obj_rect)) {
                            n.leaf.objs.append(self.arena.allocator(), co) catch unreachable;
                        }
                    }
                } else {
                    // Non-sized object: use point-based placement
                    for (new_tree_node.node.children) |n| {
                        if (n.leaf.rect.containsPoint(obj_pos)) {
                            n.leaf.objs.append(self.arena.allocator(), co) catch unreachable;
                            break;
                        }
                    } else unreachable;
                    point_count += 1;
                }
            }

            new_tree_node.node.size = point_count;
            tree_node.leaf.objs.deinit(self.arena.allocator());
            tree_node.* = new_tree_node;

            // Update ALL objects in the leaves map that reference the old leaf
            // This must be done after tree_node.* = new_tree_node because old_leaf_ptr is now invalid
            var leaves_iter = self.leaves.iterator();
            while (leaves_iter.next()) |entry| {
                const obj = entry.key_ptr.*;
                const leaf_list = entry.value_ptr;

                // Check if this object's leaf list contains the old leaf pointer
                var found_idx: ?usize = null;
                for (leaf_list.items, 0..) |leaf_ptr, idx| {
                    if (leaf_ptr == old_leaf_ptr) {
                        found_idx = idx;
                        break;
                    }
                }

                if (found_idx) |idx| {
                    // Remove the old leaf pointer
                    _ = leaf_list.swapRemove(idx);

                    // Add new leaf pointers based on object's position and size
                    const obj_pos = self.positions.get(obj).?;
                    const size = self.sizes.get(obj).?;
                    const w = size.getWidthFloat();
                    const h = size.getHeightFloat();
                    const obj_rect = Rectangle{
                        .x = obj_pos.x - w * 0.5,
                        .y = obj_pos.y - h * 0.5,
                        .width = w,
                        .height = h,
                    };

                    for (new_tree_node.node.children) |n| {
                        if (n.leaf.rect.hasIntersection(obj_rect)) {
                            leaf_list.append(self.allocator, &n.leaf) catch unreachable;
                        }
                    }
                }
            }

            // Update parent's size if it exists
            if (parent) |p| {
                if (p.* == .node) {
                    // Parent size is already correct, no need to update
                }
            }
        }

        fn searchAndRemove(self: *Tree, parent: ?*TreeNode, tree_node: *TreeNode, o: ObjectType, pos: Point) void {
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
                    const parent_rect = p.node.rect;
                    var objs = std.ArrayList(ObjectType).initCapacity(
                        self.arena.allocator(),
                        opt.preferred_size_of_leaf * 2,
                    ) catch unreachable;
                    var seen = std.AutoHashMap(ObjectType, void).init(self.allocator);
                    defer seen.deinit();

                    var sized_to_update = std.AutoHashMap(ObjectType, void).init(self.allocator);
                    defer sized_to_update.deinit();

                    // Remove subtree leaf pointers from sized-object leaf lists
                    var leaves_iter = self.leaves.iterator();
                    while (leaves_iter.next()) |entry| {
                        const obj = entry.key_ptr.*;
                        var leaf_list = entry.value_ptr;
                        var removed = false;
                        var i: usize = 0;
                        while (i < leaf_list.items.len) {
                            const leaf_ptr = leaf_list.items[i];
                            if (parent_rect.containsRect(leaf_ptr.rect)) {
                                _ = leaf_list.swapRemove(i);
                                removed = true;
                                continue;
                            }
                            i += 1;
                        }
                        if (removed) {
                            sized_to_update.put(obj, {}) catch unreachable;
                        }
                    }

                    // Collect unique objects from subtree and destroy children
                    for (p.node.children) |c| {
                        self.collectAndDestroy(c, &objs, &seen);
                    }

                    var new_tree_node: TreeNode = .{
                        .leaf = .{
                            .rect = parent_rect,
                            .objs = objs,
                        },
                    };
                    if (is_searchable and opt.enable_sort) {
                        std.sort.pdq(ObjectType, new_tree_node.leaf.objs.items, {}, std.sort.asc(ObjectType));
                    }
                    p.* = new_tree_node;

                    // Update sized-object leaf lists to point at the new parent leaf
                    var sized_it = sized_to_update.iterator();
                    while (sized_it.next()) |entry| {
                        const obj = entry.key_ptr.*;
                        if (self.leaves.getEntry(obj)) |leaf_entry| {
                            leaf_entry.value_ptr.append(self.allocator, &p.leaf) catch unreachable;
                        } else unreachable;
                    }
                }
            }
        }

        fn collectAndDestroy(
            self: *Tree,
            node: *TreeNode,
            objs: *std.ArrayList(ObjectType),
            seen: *std.AutoHashMap(ObjectType, void),
        ) void {
            if (node.* == .leaf) {
                for (node.leaf.objs.items) |o| {
                    if (!seen.contains(o)) {
                        seen.put(o, {}) catch unreachable;
                        objs.append(self.arena.allocator(), o) catch unreachable;
                    }
                }
                node.leaf.objs.deinit(self.arena.allocator());
                self.node_pool.destroy(node);
            } else {
                for (node.node.children) |c| {
                    self.collectAndDestroy(c, objs, seen);
                }
                self.node_pool.destroy(node);
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
    const rect = Rectangle{ .x = 0, .y = 0, .width = 1000, .height = 1000 };

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
    const rect = Rectangle{ .x = 0, .y = 0, .width = 1000, .height = 1000 };

    const TreeType = QuadTree(u32, .{});
    const tree = try TreeType.create(allocator, rect);
    defer tree.destroy();

    const obj: u32 = 42;
    const pos = Point{ .x = 100, .y = 100 };

    try tree.put(obj, pos, .{});
    try expectEqual(@as(usize, 1), tree.positions.count());
    try expect(tree.root.* == .leaf);
    try expectEqual(@as(usize, 1), tree.root.leaf.objs.items.len);
}

test "QuadTree: add duplicate object returns error" {
    const allocator = testing.allocator;
    const rect = Rectangle{ .x = 0, .y = 0, .width = 1000, .height = 1000 };

    const TreeType = QuadTree(u32, .{});
    const tree = try TreeType.create(allocator, rect);
    defer tree.destroy();

    const obj: u32 = 42;
    const pos = Point{ .x = 100, .y = 100 };

    try tree.put(obj, pos, .{});
    try expectError(Error.AlreadyExists, tree.put(obj, pos, .{}));
}

test "QuadTree: add object outside bounds returns error" {
    const allocator = testing.allocator;
    const rect = Rectangle{ .x = 0, .y = 0, .width = 1000, .height = 1000 };

    const TreeType = QuadTree(u32, .{});
    const tree = try TreeType.create(allocator, rect);
    defer tree.destroy();

    const obj: u32 = 42;
    const pos = Point{ .x = 1500, .y = 100 };

    try expectError(Error.NotSeeable, tree.put(obj, pos, .{}));
}

test "QuadTree: remove object" {
    const allocator = testing.allocator;
    const rect = Rectangle{ .x = 0, .y = 0, .width = 1000, .height = 1000 };

    const TreeType = QuadTree(u32, .{});
    const tree = try TreeType.create(allocator, rect);
    defer tree.destroy();

    const obj: u32 = 42;
    const pos = Point{ .x = 100, .y = 100 };

    try tree.put(obj, pos, .{});
    try expectEqual(@as(usize, 1), tree.positions.count());

    tree.remove(obj);
    try expectEqual(@as(usize, 0), tree.positions.count());
    try expectEqual(@as(usize, 0), tree.root.leaf.objs.items.len);
}

test "QuadTree: remove non-existent object is safe" {
    const allocator = testing.allocator;
    const rect = Rectangle{ .x = 0, .y = 0, .width = 1000, .height = 1000 };

    const TreeType = QuadTree(u32, .{});
    const tree = try TreeType.create(allocator, rect);
    defer tree.destroy();

    // Should not crash
    tree.remove(999);
    try expectEqual(@as(usize, 0), tree.positions.count());
}

test "QuadTree: tree subdivision on exceeding leaf capacity" {
    const allocator = testing.allocator;
    const rect = Rectangle{ .x = 0, .y = 0, .width = 1000, .height = 1000 };

    const TreeType = QuadTree(u32, .{ .preferred_size_of_leaf = 4 });
    const tree = try TreeType.create(allocator, rect);
    defer tree.destroy();

    // Add objects to same quadrant to force subdivision
    var i: u32 = 0;
    while (i < 10) : (i += 1) {
        const pos = Point{
            .x = 100 + @as(f32, @floatFromInt(i)) * 10,
            .y = 100 + @as(f32, @floatFromInt(i)) * 10,
        };
        try tree.put(i, pos, .{});
    }

    // Tree should have subdivided
    try expect(tree.root.* == .node);
    try expectEqual(@as(u32, 10), tree.root.node.size);
}

test "QuadTree: objects distributed across quadrants" {
    const allocator = testing.allocator;
    const rect = Rectangle{ .x = 0, .y = 0, .width = 1000, .height = 1000 };

    const TreeType = QuadTree(u32, .{ .preferred_size_of_leaf = 2 });
    const tree = try TreeType.create(allocator, rect);
    defer tree.destroy();

    // Add objects to different quadrants
    try tree.put(1, Point{ .x = 100, .y = 100 }, .{}); // NW
    try tree.put(2, Point{ .x = 600, .y = 100 }, .{}); // NE
    try tree.put(3, Point{ .x = 100, .y = 600 }, .{}); // SW
    try tree.put(4, Point{ .x = 600, .y = 600 }, .{}); // SE
    try tree.put(5, Point{ .x = 150, .y = 150 }, .{}); // NW
    try tree.put(6, Point{ .x = 650, .y = 150 }, .{}); // NE

    try expect(tree.root.* == .node);
    try expectEqual(@as(u32, 6), tree.root.node.size);
}

test "QuadTree: query empty tree" {
    const allocator = testing.allocator;
    const rect = Rectangle{ .x = 0, .y = 0, .width = 1000, .height = 1000 };

    const TreeType = QuadTree(u32, .{});
    const tree = try TreeType.create(allocator, rect);
    defer tree.destroy();

    const query_rect = Rectangle{ .x = 100, .y = 100, .width = 200, .height = 200 };
    var results = std.array_list.Managed(u32).init(allocator);
    defer results.deinit();
    try tree.query(query_rect, 0, &results, .{});

    try expectEqual(@as(usize, 0), results.items.len);
}

test "QuadTree: query returns correct objects" {
    const allocator = testing.allocator;
    const rect = Rectangle{ .x = 0, .y = 0, .width = 1000, .height = 1000 };

    const TreeType = QuadTree(u32, .{});
    const tree = try TreeType.create(allocator, rect);
    defer tree.destroy();

    // Add objects at various positions
    try tree.put(1, Point{ .x = 100, .y = 100 }, .{});
    try tree.put(2, Point{ .x = 500, .y = 500 }, .{});
    try tree.put(3, Point{ .x = 900, .y = 900 }, .{});

    // Query that intersects with the entire tree (since root is still a leaf)
    // This should return all objects
    const query_rect1 = Rectangle{ .x = 0, .y = 0, .width = 1000, .height = 1000 };
    var results1 = std.array_list.Managed(u32).init(allocator);
    defer results1.deinit();
    try tree.query(query_rect1, 0, &results1, .{});

    try expectEqual(@as(usize, 3), results1.items.len);

    // Query that intersects the leaf (which contains all objects)
    // Even a small query will return all objects in the leaf
    const query_rect2 = Rectangle{ .x = 50, .y = 50, .width = 100, .height = 100 };
    var results2 = std.array_list.Managed(u32).init(allocator);
    defer results2.deinit();
    try tree.query(query_rect2, 0, &results2, .{});

    // Since the tree hasn't subdivided, the query returns all objects in the intersecting leaf
    try expectEqual(@as(usize, 3), results2.items.len);
}

test "QuadTree: query after subdivision" {
    const allocator = testing.allocator;
    const rect = Rectangle{ .x = 0, .y = 0, .width = 1000, .height = 1000 };

    const TreeType = QuadTree(u32, .{ .preferred_size_of_leaf = 2 });
    const tree = try TreeType.create(allocator, rect);
    defer tree.destroy();

    // Add enough objects to force subdivision, all in NW quadrant
    try tree.put(0, Point{ .x = 100, .y = 100 }, .{});
    try tree.put(1, Point{ .x = 150, .y = 100 }, .{});
    try tree.put(2, Point{ .x = 200, .y = 100 }, .{});

    // Also add objects to other quadrants
    try tree.put(10, Point{ .x = 600, .y = 100 }, .{}); // NE
    try tree.put(11, Point{ .x = 650, .y = 150 }, .{}); // NE
    try tree.put(20, Point{ .x = 100, .y = 600 }, .{}); // SW
    try tree.put(30, Point{ .x = 600, .y = 600 }, .{}); // SE

    // Tree should be subdivided now
    try expect(tree.root.* == .node);

    // Query only NW quadrant - should only get objects from that quadrant
    const query_rect1 = Rectangle{ .x = 0, .y = 0, .width = 300, .height = 300 };
    var results1 = std.array_list.Managed(u32).init(allocator);
    defer results1.deinit();
    try tree.query(query_rect1, 0, &results1, .{});

    try expect(results1.items.len == 3);
    // Verify they're the NW objects
    var found_nw = false;
    for (results1.items) |obj| {
        if (obj == 0 or obj == 1 or obj == 2) found_nw = true;
    }
    try expect(found_nw);

    // Query only SE quadrant
    const query_rect2 = Rectangle{ .x = 501, .y = 501, .width = 500, .height = 500 };
    var results2 = std.array_list.Managed(u32).init(allocator);
    defer results2.deinit();
    try tree.query(query_rect2, 0, &results2, .{});

    try expect(results2.items.len == 1);
    try expectEqual(@as(u32, 30), results2.items[0]);

    // Query that spans multiple quadrants
    const query_rect3 = Rectangle{ .x = 501, .y = 0, .width = 400, .height = 400 };
    var results3 = std.array_list.Managed(u32).init(allocator);
    defer results3.deinit();
    try tree.query(query_rect3, 0, &results3, .{});

    // Should get objects from NE quadrant
    try expect(results3.items.len == 2);
}

test "QuadTree: clear resets tree" {
    const allocator = testing.allocator;
    const rect = Rectangle{ .x = 0, .y = 0, .width = 1000, .height = 1000 };

    const TreeType = QuadTree(u32, .{ .preferred_size_of_leaf = 2 });
    const tree = try TreeType.create(allocator, rect);
    defer tree.destroy();

    // Add objects
    var i: u32 = 0;
    while (i < 10) : (i += 1) {
        const pos = Point{
            .x = 100 + @as(f32, @floatFromInt(i)) * 50,
            .y = 100,
        };
        try tree.put(i, pos, .{});
    }

    try expect(tree.positions.count() > 0);

    // Clear
    tree.clear();

    // Verify tree is reset
    try expectEqual(@as(usize, 0), tree.positions.count());
    try expect(tree.root.* == .leaf);
    try expectEqual(@as(usize, 0), tree.root.leaf.objs.items.len);

    // Should be able to add objects again
    try tree.put(100, Point{ .x = 100, .y = 100 }, .{});
    try expectEqual(@as(usize, 1), tree.positions.count());
}

test "QuadTree: tree shrinking after removals" {
    const allocator = testing.allocator;
    const rect = Rectangle{ .x = 0, .y = 0, .width = 1000, .height = 1000 };

    const TreeType = QuadTree(u32, .{ .preferred_size_of_leaf = 4 });
    const tree = try TreeType.create(allocator, rect);
    defer tree.destroy();

    // Add enough objects to force subdivision
    var i: u32 = 0;
    while (i < 10) : (i += 1) {
        const pos = Point{
            .x = 100 + @as(f32, @floatFromInt(i)) * 50,
            .y = 100,
        };
        try tree.put(i, pos, .{});
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

test "QuadTree: sized objects survive shrink" {
    const allocator = testing.allocator;
    const rect = Rectangle{ .x = 0, .y = 0, .width = 1000, .height = 1000 };

    const TreeType = QuadTree(u32, .{ .preferred_size_of_leaf = 4 });
    const tree = try TreeType.create(allocator, rect);
    defer tree.destroy();

    // Add a sized object spanning multiple leaves
    try tree.put(999, Point{ .x = 200, .y = 200 }, .{ .size = .{ .width = 300, .height = 300 } });

    // Add enough point objects to force subdivision
    var i: u32 = 0;
    while (i < 5) : (i += 1) {
        const pos = Point{
            .x = 100 + @as(f32, @floatFromInt(i)) * 10,
            .y = 100,
        };
        try tree.put(i, pos, .{});
    }
    try expect(tree.root.* == .node);

    // Remove point objects to force shrink
    i = 0;
    while (i < 5) : (i += 1) {
        tree.remove(i);
    }
    try expect(tree.root.* == .leaf);

    // Sized object should remain valid and updatable
    try tree.update(999, Point{ .x = 250, .y = 250 });
    try expect(tree.positions.get(999) != null);

    tree.remove(999);
    try expect(tree.positions.get(999) == null);
}

test "QuadTree: sized objects survive repeated subdivide/shrink" {
    const allocator = testing.allocator;
    const rect = Rectangle{ .x = 0, .y = 0, .width = 1000, .height = 1000 };

    const TreeType = QuadTree(u32, .{ .preferred_size_of_leaf = 4 });
    const tree = try TreeType.create(allocator, rect);
    defer tree.destroy();

    try tree.put(1000, Point{ .x = 250, .y = 250 }, .{ .size = .{ .width = 300, .height = 300 } });

    var cycle: u32 = 0;
    while (cycle < 3) : (cycle += 1) {
        var i: u32 = 0;
        while (i < 6) : (i += 1) {
            const pos = Point{
                .x = 100 + @as(f32, @floatFromInt(i)) * 10,
                .y = 100 + @as(f32, @floatFromInt(i)) * 10,
            };
            try tree.put(i, pos, .{});
        }
        try expect(tree.root.* == .node);

        i = 0;
        while (i < 6) : (i += 1) {
            tree.remove(i);
        }
        try expect(tree.root.* == .leaf);

        try tree.update(1000, Point{ .x = 260 + @as(f32, @floatFromInt(cycle)) * 5, .y = 260 });
        try expect(tree.positions.get(1000) != null);
    }

    tree.remove(1000);
    try expect(tree.positions.get(1000) == null);
}

test "QuadTree: with sorted integers" {
    const allocator = testing.allocator;
    const rect = Rectangle{ .x = 0, .y = 0, .width = 1000, .height = 1000 };

    const TreeType = QuadTree(u32, .{ .enable_sort = true });
    const tree = try TreeType.create(allocator, rect);
    defer tree.destroy();

    // Add objects in non-sorted order
    try tree.put(50, Point{ .x = 100, .y = 100 }, .{});
    try tree.put(10, Point{ .x = 150, .y = 100 }, .{});
    try tree.put(30, Point{ .x = 200, .y = 100 }, .{});
    try tree.put(20, Point{ .x = 250, .y = 100 }, .{});

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
    const rect = Rectangle{ .x = 0, .y = 0, .width = 1000, .height = 1000 };

    const Object = struct {
        id: u32,
        value: f32,
    };

    var obj1 = Object{ .id = 1, .value = 1.5 };
    var obj2 = Object{ .id = 2, .value = 2.5 };

    const TreeType = QuadTree(*Object, .{});
    const tree = try TreeType.create(allocator, rect);
    defer tree.destroy();

    try tree.put(&obj1, Point{ .x = 100, .y = 100 }, .{});
    try tree.put(&obj2, Point{ .x = 200, .y = 200 }, .{});

    try expectEqual(@as(usize, 2), tree.positions.count());

    // Query should find both objects
    const query_rect = Rectangle{ .x = 0, .y = 0, .width = 300, .height = 300 };
    var results = std.array_list.Managed(*Object).init(allocator);
    defer results.deinit();
    try tree.query(query_rect, 0, &results, .{});

    try expectEqual(@as(usize, 2), results.items.len);
}

test "QuadTree: minimum width constraint" {
    const allocator = testing.allocator;
    const rect = Rectangle{ .x = 0, .y = 0, .width = 200, .height = 200 };

    const TreeType = QuadTree(u32, .{
        .preferred_size_of_leaf = 2,
        .min_width_of_leaf = 150, // Prevents subdivision
    });
    const tree = try TreeType.create(allocator, rect);
    defer tree.destroy();

    // Try to add more than preferred_size_of_leaf
    var i: u32 = 0;
    while (i < 10) : (i += 1) {
        const pos = Point{
            .x = 50 + @as(f32, @floatFromInt(i)) * 5,
            .y = 50,
        };
        try tree.put(i, pos, .{});
    }

    // Should not subdivide due to min_width constraint
    try expect(tree.root.* == .leaf);
    try expectEqual(@as(usize, 10), tree.root.leaf.objs.items.len);
}

test "QuadTree: stress test with many objects" {
    const allocator = testing.allocator;
    const rect = Rectangle{ .x = 0, .y = 0, .width = 10000, .height = 10000 };

    const TreeType = QuadTree(u32, .{});
    const tree = try TreeType.create(allocator, rect);
    defer tree.destroy();

    // Add 1000 objects
    var i: u32 = 0;
    while (i < 1000) : (i += 1) {
        const pos = Point{
            .x = @mod(@as(f32, @floatFromInt(i)) * 73.2, 10000),
            .y = @mod(@as(f32, @floatFromInt(i)) * 41.7, 10000),
        };
        try tree.put(i, pos, .{});
    }

    try expectEqual(@as(usize, 1000), tree.positions.count());

    // Query a small region
    const query_rect = Rectangle{ .x = 1000, .y = 1000, .width = 500, .height = 500 };
    var results = std.array_list.Managed(u32).init(allocator);
    defer results.deinit();
    try tree.query(query_rect, 0, &results, .{});

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
    const rect = Rectangle{ .x = 0, .y = 0, .width = 1000, .height = 1000 };

    const TreeType = QuadTree(u32, .{ .preferred_size_of_leaf = 2 });
    const tree = try TreeType.create(allocator, rect);
    defer tree.destroy();

    // Objects at exact boundaries
    try tree.put(1, Point{ .x = 0, .y = 0 }, .{});
    try tree.put(2, Point{ .x = 999.9, .y = 999.9 }, .{});
    try tree.put(3, Point{ .x = 501, .y = 501 }, .{});

    try expectEqual(@as(usize, 3), tree.positions.count());

    // Query at boundaries
    const query_rect = Rectangle{ .x = 0, .y = 0, .width = 1, .height = 1 };
    var results = std.array_list.Managed(u32).init(allocator);
    defer results.deinit();
    try tree.query(query_rect, 0, &results, .{});

    try expectEqual(@as(usize, 1), results.items.len);
}

test "QuadTree: update - in-place update within same leaf" {
    const allocator = testing.allocator;
    const rect = Rectangle{ .x = 0, .y = 0, .width = 1000, .height = 1000 };
    const TreeType = QuadTree(u32, .{ .preferred_size_of_leaf = 8 });
    const tree = try TreeType.create(allocator, rect);
    defer tree.destroy();

    const obj: u32 = 42;
    const old_pos = Point{ .x = 100, .y = 100 };
    const new_pos = Point{ .x = 120, .y = 120 }; // still within the same leaf

    try tree.put(obj, old_pos, .{});
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
    const rect = Rectangle{ .x = 0, .y = 0, .width = 1000, .height = 1000 };
    const TreeType = QuadTree(u32, .{ .preferred_size_of_leaf = 4 }); // small capacity to force subdivision
    const tree = try TreeType.create(allocator, rect);
    defer tree.destroy();

    // Add objects to force subdivision in NW quadrant
    var i: u32 = 0;
    while (i < 10) : (i += 1) {
        const pos = Point{ .x = 100 + @as(f32, @floatFromInt(i)) * 10, .y = 100 + @as(f32, @floatFromInt(i)) * 10 };
        try tree.put(i, pos, .{});
    }
    try expect(tree.root.* == .node); // confirm subdivision occurred

    // Select an object in NW quadrant
    const obj: u32 = 5;
    try expect(tree.positions.get(obj) != null);

    // Move to SE quadrant (cross-leaf movement)
    const new_pos = Point{ .x = 800, .y = 800 };

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
    const rect = Rectangle{ .x = 0, .y = 0, .width = 1000, .height = 1000 };
    const TreeType = QuadTree(u32, .{});
    const tree = try TreeType.create(allocator, rect);
    defer tree.destroy();

    const obj: u32 = 100;
    const pos = Point{ .x = 500, .y = 500 };

    try tree.put(obj, pos, .{});

    // Update to the exact same position
    try tree.update(obj, pos);

    // Position should remain unchanged
    const current_pos = tree.positions.get(obj).?;
    try expectEqual(pos.x, current_pos.x);
    try expectEqual(pos.y, current_pos.y);
}

test "QuadTree: update - object does not exist yet" {
    const allocator = testing.allocator;
    const rect = Rectangle{ .x = 0, .y = 0, .width = 1000, .height = 1000 };
    const TreeType = QuadTree(u32, .{});
    const tree = try TreeType.create(allocator, rect);
    defer tree.destroy();

    const obj: u32 = 999;
    const new_pos = Point{ .x = 300, .y = 300 };

    // Update non-existent object (current implementation will add it)
    try tree.update(obj, new_pos);

    // Verify object was added
    try expectEqual(@as(usize, 1), tree.positions.count());
    try expect(tree.positions.get(obj) != null);
}

test "QuadTree: update - attempt to move outside tree bounds" {
    const allocator = testing.allocator;
    const rect = Rectangle{ .x = 0, .y = 0, .width = 1000, .height = 1000 };
    const TreeType = QuadTree(u32, .{});
    const tree = try TreeType.create(allocator, rect);
    defer tree.destroy();

    const obj: u32 = 42;
    try tree.put(obj, Point{ .x = 100, .y = 100 }, .{});

    const outside_pos = Point{ .x = 1500, .y = 500 };

    // Should remove the obj
    try tree.update(obj, outside_pos);
    try expectEqual(null, tree.positions.get(obj));
}

test "QuadTree: query with precise option - filters by attached size" {
    const allocator = testing.allocator;
    const rect = Rectangle{ .x = 0, .y = 0, .width = 1000, .height = 1000 };
    const TreeType = QuadTree(u32, .{});
    const tree = try TreeType.create(allocator, rect);
    defer tree.destroy();

    try tree.put(1, .{ .x = 2.5, .y = 2.5 }, .{ .size = .{ .width = 5, .height = 5 } });
    try tree.put(2, .{ .x = 60, .y = 10 }, .{}); // Same leaf, outside query rect

    var results = std.array_list.Managed(u32).init(allocator);
    defer results.deinit();

    try tree.query(.{ .x = 0, .y = 0, .width = 5, .height = 5 }, 0, &results, .{ .precise = true });

    try expectEqual(@as(usize, 1), results.items.len);
    try expectEqual(@as(u32, 1), results.items[0]);
}

test "QuadTree: update with size - size override and stable across move" {
    const allocator = testing.allocator;
    const rect = Rectangle{ .x = 0, .y = 0, .width = 1000, .height = 1000 };
    const TreeType = QuadTree(u32, .{});
    const tree = try TreeType.create(allocator, rect);
    defer tree.destroy();

    const size = Size{ .width = 10, .height = 10 };
    try tree.put(1, .{ .x = 45, .y = 45 }, .{ .size = size });

    try tree.update(1, .{ .x = 60, .y = 55 });
    try expect(tree.sizes.get(1).?.isSame(.{ .width = 10, .height = 10 }));

    try tree.update(1, .{ .x = 70, .y = 60 });
    tree.sizes.put(1, .{ .width = 3, .height = 4 }) catch unreachable;
    try expect(tree.sizes.get(1).?.isSame(.{ .width = 3, .height = 4 }));
}

test "QuadTree: query with precise option - falls back to position for objects without size" {
    const allocator = testing.allocator;
    const rect = Rectangle{ .x = 0, .y = 0, .width = 1000, .height = 1000 };
    const TreeType = QuadTree(u32, .{});
    const tree = try TreeType.create(allocator, rect);
    defer tree.destroy();

    try tree.put(1, .{ .x = 10, .y = 10 }, .{});
    try tree.put(2, .{ .x = 100, .y = 100 }, .{});

    var results = std.array_list.Managed(u32).init(allocator);
    defer results.deinit();

    try tree.query(.{ .x = 0, .y = 0, .width = 20, .height = 20 }, 0, &results, .{ .precise = true });

    try expectEqual(@as(usize, 1), results.items.len);
    try expectEqual(@as(u32, 1), results.items[0]);
}

test "QuadTree: query with padding expands search area" {
    const allocator = testing.allocator;
    const rect = Rectangle{ .x = 0, .y = 0, .width = 1000, .height = 1000 };

    const TreeType = QuadTree(u32, .{ .preferred_size_of_leaf = 2 });
    const tree = try TreeType.create(allocator, rect);
    defer tree.destroy();

    // Force subdivision
    try tree.put(1, Point{ .x = 100, .y = 100 }, .{});
    try tree.put(2, Point{ .x = 150, .y = 100 }, .{});
    try tree.put(3, Point{ .x = 200, .y = 100 }, .{});
    try tree.put(10, Point{ .x = 600, .y = 600 }, .{});

    // Query that misses object 10 without padding
    var results1 = std.array_list.Managed(u32).init(allocator);
    defer results1.deinit();
    try tree.query(.{ .x = 0, .y = 0, .width = 300, .height = 300 }, 0, &results1, .{});
    for (results1.items) |o| try expect(o != 10);

    // Query with large padding should reach SE quadrant
    var results2 = std.array_list.Managed(u32).init(allocator);
    defer results2.deinit();
    try tree.query(.{ .x = 0, .y = 0, .width = 300, .height = 300 }, 400, &results2, .{});
    var found_10 = false;
    for (results2.items) |o| {
        if (o == 10) found_10 = true;
    }
    try expect(found_10);
}

test "QuadTree: sized object spanning all four quadrants" {
    const allocator = testing.allocator;
    const rect = Rectangle{ .x = 0, .y = 0, .width = 1000, .height = 1000 };

    const TreeType = QuadTree(u32, .{ .preferred_size_of_leaf = 2 });
    const tree = try TreeType.create(allocator, rect);
    defer tree.destroy();

    // Force subdivision by adding point objects to different quadrants
    try tree.put(1, Point{ .x = 100, .y = 100 }, .{});
    try tree.put(2, Point{ .x = 600, .y = 100 }, .{});
    try tree.put(3, Point{ .x = 100, .y = 600 }, .{});
    try tree.put(4, Point{ .x = 600, .y = 600 }, .{});
    try tree.put(5, Point{ .x = 150, .y = 150 }, .{});
    try tree.put(6, Point{ .x = 650, .y = 150 }, .{});

    try expect(tree.root.* == .node);

    // Add a large sized object centered at the middle, spanning all quadrants
    try tree.put(99, Point{ .x = 500, .y = 500 }, .{ .size = .{ .width = 600, .height = 600 } });

    // Query each quadrant should find the sized object
    var results_nw = std.array_list.Managed(u32).init(allocator);
    defer results_nw.deinit();
    try tree.query(.{ .x = 250, .y = 250, .width = 50, .height = 50 }, 0, &results_nw, .{});
    var found_99 = false;
    for (results_nw.items) |o| {
        if (o == 99) found_99 = true;
    }
    try expect(found_99);

    var results_se = std.array_list.Managed(u32).init(allocator);
    defer results_se.deinit();
    try tree.query(.{ .x = 700, .y = 700, .width = 50, .height = 50 }, 0, &results_se, .{});
    found_99 = false;
    for (results_se.items) |o| {
        if (o == 99) found_99 = true;
    }
    try expect(found_99);

    // Remove the sized object
    tree.remove(99);
    try expectEqual(@as(usize, 6), tree.positions.count());
    try expectEqual(null, tree.sizes.get(99));
}

test "QuadTree: sized object outside bounds returns NotSeeable" {
    const allocator = testing.allocator;
    const rect = Rectangle{ .x = 0, .y = 0, .width = 1000, .height = 1000 };

    const TreeType = QuadTree(u32, .{});
    const tree = try TreeType.create(allocator, rect);
    defer tree.destroy();

    // Object centered far outside with small size
    try expectError(Error.NotSeeable, tree.put(1, Point{ .x = 2000, .y = 2000 }, .{ .size = .{ .width = 10, .height = 10 } }));
}

test "QuadTree: sized object partially outside bounds is accepted" {
    const allocator = testing.allocator;
    const rect = Rectangle{ .x = 0, .y = 0, .width = 1000, .height = 1000 };

    const TreeType = QuadTree(u32, .{});
    const tree = try TreeType.create(allocator, rect);
    defer tree.destroy();

    // Object centered at edge, half inside half outside
    try tree.put(1, Point{ .x = 0, .y = 500 }, .{ .size = .{ .width = 100, .height = 100 } });
    try expectEqual(@as(usize, 1), tree.positions.count());
}

test "QuadTree: update sized object to out of bounds removes it" {
    const allocator = testing.allocator;
    const rect = Rectangle{ .x = 0, .y = 0, .width = 1000, .height = 1000 };

    const TreeType = QuadTree(u32, .{});
    const tree = try TreeType.create(allocator, rect);
    defer tree.destroy();

    try tree.put(1, Point{ .x = 500, .y = 500 }, .{ .size = .{ .width = 50, .height = 50 } });
    try expectEqual(@as(usize, 1), tree.positions.count());

    // Move far outside
    try tree.update(1, Point{ .x = 5000, .y = 5000 });
    try expectEqual(null, tree.positions.get(1));
}

test "QuadTree: clear with sized objects" {
    const allocator = testing.allocator;
    const rect = Rectangle{ .x = 0, .y = 0, .width = 1000, .height = 1000 };

    const TreeType = QuadTree(u32, .{ .preferred_size_of_leaf = 2 });
    const tree = try TreeType.create(allocator, rect);
    defer tree.destroy();

    // Add mix of point and sized objects
    try tree.put(1, Point{ .x = 100, .y = 100 }, .{});
    try tree.put(2, Point{ .x = 600, .y = 100 }, .{});
    try tree.put(3, Point{ .x = 100, .y = 600 }, .{});
    try tree.put(10, Point{ .x = 500, .y = 500 }, .{ .size = .{ .width = 200, .height = 200 } });

    try expectEqual(@as(usize, 4), tree.positions.count());
    try expect(tree.sizes.count() > 0);

    tree.clear();

    try expectEqual(@as(usize, 0), tree.positions.count());
    try expectEqual(@as(usize, 0), tree.sizes.count());
    try expectEqual(@as(usize, 0), tree.leaves.count());
    try expect(tree.root.* == .leaf);

    // Re-add after clear
    try tree.put(20, Point{ .x = 300, .y = 300 }, .{ .size = .{ .width = 50, .height = 50 } });
    try expectEqual(@as(usize, 1), tree.positions.count());
}

test "QuadTree: query deduplicates sized objects spanning multiple leaves" {
    const allocator = testing.allocator;
    const rect = Rectangle{ .x = 0, .y = 0, .width = 1000, .height = 1000 };

    const TreeType = QuadTree(u32, .{ .preferred_size_of_leaf = 2 });
    const tree = try TreeType.create(allocator, rect);
    defer tree.destroy();

    // Force subdivision
    try tree.put(1, Point{ .x = 100, .y = 100 }, .{});
    try tree.put(2, Point{ .x = 600, .y = 100 }, .{});
    try tree.put(3, Point{ .x = 100, .y = 600 }, .{});
    try tree.put(4, Point{ .x = 600, .y = 600 }, .{});
    try tree.put(5, Point{ .x = 150, .y = 150 }, .{});
    try tree.put(6, Point{ .x = 650, .y = 150 }, .{});

    // Add sized object spanning multiple leaves
    try tree.put(99, Point{ .x = 500, .y = 500 }, .{ .size = .{ .width = 800, .height = 800 } });

    // Query the whole tree - object 99 should appear exactly once
    var results = std.array_list.Managed(u32).init(allocator);
    defer results.deinit();
    try tree.query(.{ .x = 0, .y = 0, .width = 1000, .height = 1000 }, 0, &results, .{});

    var count_99: usize = 0;
    for (results.items) |o| {
        if (o == 99) count_99 += 1;
    }
    try expectEqual(@as(usize, 1), count_99);
}

test "QuadTree: precise query filters sized object that doesn't actually intersect" {
    const allocator = testing.allocator;
    const rect = Rectangle{ .x = 0, .y = 0, .width = 1000, .height = 1000 };

    const TreeType = QuadTree(u32, .{});
    const tree = try TreeType.create(allocator, rect);
    defer tree.destroy();

    // Small sized object in top-left corner
    try tree.put(1, Point{ .x = 10, .y = 10 }, .{ .size = .{ .width = 10, .height = 10 } });
    // Point object far away but in same leaf (no subdivision)
    try tree.put(2, Point{ .x = 900, .y = 900 }, .{});

    // Query bottom-right area - without precise, both are in same leaf so both returned
    var results_broad = std.array_list.Managed(u32).init(allocator);
    defer results_broad.deinit();
    try tree.query(.{ .x = 800, .y = 800, .width = 200, .height = 200 }, 0, &results_broad, .{});
    try expectEqual(@as(usize, 2), results_broad.items.len);

    // With precise, only object 2 (point at 900,900) should match
    var results_precise = std.array_list.Managed(u32).init(allocator);
    defer results_precise.deinit();
    try tree.query(.{ .x = 800, .y = 800, .width = 200, .height = 200 }, 0, &results_precise, .{ .precise = true });
    try expectEqual(@as(usize, 1), results_precise.items.len);
    try expectEqual(@as(u32, 2), results_precise.items[0]);
}

test "QuadTree: update non-existent object with in-bounds position adds it" {
    const allocator = testing.allocator;
    const rect = Rectangle{ .x = 0, .y = 0, .width = 1000, .height = 1000 };

    const TreeType = QuadTree(u32, .{});
    const tree = try TreeType.create(allocator, rect);
    defer tree.destroy();

    try tree.update(42, Point{ .x = 500, .y = 500 });
    try expectEqual(@as(usize, 1), tree.positions.count());

    // Verify it's queryable
    var results = std.array_list.Managed(u32).init(allocator);
    defer results.deinit();
    try tree.query(.{ .x = 400, .y = 400, .width = 200, .height = 200 }, 0, &results, .{});
    try expectEqual(@as(usize, 1), results.items.len);
    try expectEqual(@as(u32, 42), results.items[0]);
}

test "QuadTree: update non-existent object with out-of-bounds position is no-op" {
    const allocator = testing.allocator;
    const rect = Rectangle{ .x = 0, .y = 0, .width = 1000, .height = 1000 };

    const TreeType = QuadTree(u32, .{});
    const tree = try TreeType.create(allocator, rect);
    defer tree.destroy();

    try tree.update(42, Point{ .x = 5000, .y = 5000 });
    try expectEqual(@as(usize, 0), tree.positions.count());
}

test "QuadTree: multiple put-remove-put cycles" {
    const allocator = testing.allocator;
    const rect = Rectangle{ .x = 0, .y = 0, .width = 1000, .height = 1000 };

    const TreeType = QuadTree(u32, .{ .preferred_size_of_leaf = 4 });
    const tree = try TreeType.create(allocator, rect);
    defer tree.destroy();

    var cycle: u32 = 0;
    while (cycle < 5) : (cycle += 1) {
        var i: u32 = 0;
        while (i < 10) : (i += 1) {
            const pos = Point{
                .x = 100 + @as(f32, @floatFromInt(i)) * 50,
                .y = 100 + @as(f32, @floatFromInt(cycle)) * 50,
            };
            try tree.put(i + cycle * 100, pos, .{});
        }

        i = 0;
        while (i < 10) : (i += 1) {
            tree.remove(i + cycle * 100);
        }

        try expectEqual(@as(usize, 0), tree.positions.count());
    }
}

test "QuadTree: sized object added before subdivision, then subdivision occurs" {
    const allocator = testing.allocator;
    const rect = Rectangle{ .x = 0, .y = 0, .width = 1000, .height = 1000 };

    const TreeType = QuadTree(u32, .{ .preferred_size_of_leaf = 4 });
    const tree = try TreeType.create(allocator, rect);
    defer tree.destroy();

    // Add sized object first (tree is still a single leaf)
    try tree.put(100, Point{ .x = 500, .y = 500 }, .{ .size = .{ .width = 200, .height = 200 } });

    // Now add enough point objects to force subdivision
    var i: u32 = 0;
    while (i < 8) : (i += 1) {
        const pos = Point{
            .x = 100 + @as(f32, @floatFromInt(i)) * 10,
            .y = 100,
        };
        try tree.put(i, pos, .{});
    }

    try expect(tree.root.* == .node);

    // Sized object should still be queryable
    var results = std.array_list.Managed(u32).init(allocator);
    defer results.deinit();
    try tree.query(.{ .x = 450, .y = 450, .width = 100, .height = 100 }, 0, &results, .{});
    var found_100 = false;
    for (results.items) |o| {
        if (o == 100) found_100 = true;
    }
    try expect(found_100);

    // Remove sized object should work cleanly
    tree.remove(100);
    try expectEqual(null, tree.positions.get(100));
    try expectEqual(null, tree.sizes.get(100));
}

test "QuadTree: query non-intersecting region returns empty" {
    const allocator = testing.allocator;
    const rect = Rectangle{ .x = 100, .y = 100, .width = 500, .height = 500 };

    const TreeType = QuadTree(u32, .{});
    const tree = try TreeType.create(allocator, rect);
    defer tree.destroy();

    try tree.put(1, Point{ .x = 300, .y = 300 }, .{});

    // Query completely outside tree bounds
    var results = std.array_list.Managed(u32).init(allocator);
    defer results.deinit();
    try tree.query(.{ .x = 0, .y = 0, .width = 50, .height = 50 }, 0, &results, .{});
    try expectEqual(@as(usize, 0), results.items.len);
}

test "QuadTree: tree with non-zero origin" {
    const allocator = testing.allocator;
    const rect = Rectangle{ .x = 500, .y = 500, .width = 1000, .height = 1000 };

    const TreeType = QuadTree(u32, .{ .preferred_size_of_leaf = 2 });
    const tree = try TreeType.create(allocator, rect);
    defer tree.destroy();

    // Objects within the offset bounds
    try tree.put(1, Point{ .x = 600, .y = 600 }, .{});
    try tree.put(2, Point{ .x = 1200, .y = 600 }, .{});
    try tree.put(3, Point{ .x = 600, .y = 1200 }, .{});
    try tree.put(4, Point{ .x = 1200, .y = 1200 }, .{});

    try expectEqual(@as(usize, 4), tree.positions.count());

    // Object at origin (0,0) should be rejected
    try expectError(Error.NotSeeable, tree.put(5, Point{ .x = 0, .y = 0 }, .{}));

    // Query within bounds
    var results = std.array_list.Managed(u32).init(allocator);
    defer results.deinit();
    try tree.query(.{ .x = 550, .y = 550, .width = 100, .height = 100 }, 0, &results, .{});
    try expectEqual(@as(usize, 1), results.items.len);
    try expectEqual(@as(u32, 1), results.items[0]);
}

test "QuadTree: update sized object position across leaves" {
    const allocator = testing.allocator;
    const rect = Rectangle{ .x = 0, .y = 0, .width = 1000, .height = 1000 };

    const TreeType = QuadTree(u32, .{ .preferred_size_of_leaf = 2 });
    const tree = try TreeType.create(allocator, rect);
    defer tree.destroy();

    // Force subdivision
    try tree.put(1, Point{ .x = 100, .y = 100 }, .{});
    try tree.put(2, Point{ .x = 600, .y = 100 }, .{});
    try tree.put(3, Point{ .x = 100, .y = 600 }, .{});
    try tree.put(4, Point{ .x = 600, .y = 600 }, .{});
    try tree.put(5, Point{ .x = 150, .y = 150 }, .{});
    try tree.put(6, Point{ .x = 650, .y = 150 }, .{});

    // Add sized object in NW
    try tree.put(50, Point{ .x = 200, .y = 200 }, .{ .size = .{ .width = 50, .height = 50 } });

    // Move it to SE
    try tree.update(50, Point{ .x = 800, .y = 800 });

    // Should be findable in SE
    var results = std.array_list.Managed(u32).init(allocator);
    defer results.deinit();
    try tree.query(.{ .x = 750, .y = 750, .width = 100, .height = 100 }, 0, &results, .{});
    var found_50 = false;
    for (results.items) |o| {
        if (o == 50) found_50 = true;
    }
    try expect(found_50);

    // Should NOT be in NW anymore
    var results_nw = std.array_list.Managed(u32).init(allocator);
    defer results_nw.deinit();
    try tree.query(.{ .x = 175, .y = 175, .width = 50, .height = 50 }, 0, &results_nw, .{ .precise = true });
    for (results_nw.items) |o| {
        try expect(o != 50);
    }
}

test "QuadTree: query appends to existing results" {
    const allocator = testing.allocator;
    const rect = Rectangle{ .x = 0, .y = 0, .width = 1000, .height = 1000 };

    const TreeType = QuadTree(u32, .{});
    const tree = try TreeType.create(allocator, rect);
    defer tree.destroy();

    try tree.put(1, Point{ .x = 100, .y = 100 }, .{});

    var results = std.array_list.Managed(u32).init(allocator);
    defer results.deinit();

    // Pre-populate results
    try results.append(999);

    try tree.query(.{ .x = 0, .y = 0, .width = 200, .height = 200 }, 0, &results, .{});

    // Should have the pre-existing item plus the query result
    try expectEqual(@as(usize, 2), results.items.len);
    try expectEqual(@as(u32, 999), results.items[0]);
    try expectEqual(@as(u32, 1), results.items[1]);
}

test "QuadTree: precise query appends to existing results correctly" {
    const allocator = testing.allocator;
    const rect = Rectangle{ .x = 0, .y = 0, .width = 1000, .height = 1000 };

    const TreeType = QuadTree(u32, .{});
    const tree = try TreeType.create(allocator, rect);
    defer tree.destroy();

    try tree.put(1, Point{ .x = 100, .y = 100 }, .{});
    try tree.put(2, Point{ .x = 900, .y = 900 }, .{});

    var results = std.array_list.Managed(u32).init(allocator);
    defer results.deinit();

    // Pre-populate
    try results.append(888);

    // Precise query for small area - should keep pre-existing and add only matching
    try tree.query(.{ .x = 50, .y = 50, .width = 100, .height = 100 }, 0, &results, .{ .precise = true });

    // Pre-existing 888 should be preserved, plus object 1 which is in range
    try expectEqual(@as(u32, 888), results.items[0]);
    // Object 1 at (100,100) is within query rect [50,150)x[50,150)
    var found_1 = false;
    for (results.items[1..]) |o| {
        if (o == 1) found_1 = true;
    }
    try expect(found_1);
}
