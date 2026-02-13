//! Pathfinding algorithms for graph-based navigation.
//!
//! This module provides A* and Dijkstra pathfinding algorithms that work
//! with any graph structure implementing the required interface.
//!
//! Graph Interface Requirements:
//! Your graph struct must implement:
//! - `iterateNeigh(id: usize) Iterator` - Returns iterator for neighbor nodes
//! - `gcost(from: usize, to: usize) usize` - Returns actual cost between nodes
//! - `hcost(from: usize, to: usize) usize` - Returns heuristic cost estimate
//!
//! The Iterator must have a `next() ?usize` method.
//!
//! Algorithm Selection:
//! - For Dijkstra: Return 0 from hcost (no heuristic)
//! - For A*: Return distance estimate from hcost (e.g., Manhattan, Euclidean)

const std = @import("std");
const math = std.math;

// A searchable graph struct must have following methods:
//
//     // Used to get id of nodes
//     pub const Iterator = {
//         pub fn next(*@This()) ?usize
//     };
//
//     // Used to get iterator for traversing neighbours of a node
//     pub fn iterateNeigh(self: @This(), id: usize) Iterator
//
//     // Used to calculate graph cost betwen 2 nodes
//     pub fn gcost(self: @This(), from: usize, to: usize) usize
//
//     // Used to calculate heuristic cost betwen 2 nodes
//     pub fn hcost(self: @This(), from: usize, to: usize) usize
inline fn verifyGraphStruct(graph: anytype) void {
    const gtype = @TypeOf(graph);
    if (!@hasDecl(gtype, "iterateNeigh") or
        !@hasDecl(gtype, "gcost") or
        !@hasDecl(gtype, "hcost"))
    {
        @compileError("Please verify the graph struct according to above demands.");
    }
    switch (@typeInfo(@typeInfo(@TypeOf(gtype.iterateNeigh)).@"fn".return_type.?)) {
        .@"struct" => if (!std.meta.hasMethod(@typeInfo(@TypeOf(gtype.iterateNeigh)).@"fn".return_type.?, "next")) {
            @compileError("`iterateNeigh` must return a valid iterator");
        },
        else => @compileError("`iterateNeigh` must return Iterator"),
    }
    if (@typeInfo(@TypeOf(gtype.gcost)).@"fn".return_type.? != usize) {
        @compileError("`gcost` must return usize");
    }
    if (@typeInfo(@TypeOf(gtype.hcost)).@"fn".return_type.? != usize) {
        @compileError("`hcost` must return usize");
    }
}

/// Calculate shortest path using Dijkstra or A* algorithm
/// Returns null if no path exists, otherwise returns path from 'from' to 'to'
/// The algorithm used depends on the hcost implementation:
/// - hcost returns 0: Dijkstra's algorithm (guaranteed shortest path)
/// - hcost returns estimate: A* algorithm (faster but requires good heuristic)
pub fn calculatePath(allocator: std.mem.Allocator, graph: anytype, from: usize, to: usize) !?std.array_list.Managed(usize) {
    verifyGraphStruct(graph);

    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    var nodes = NodeMap.init(arena.allocator());
    var frontier = NodeQueue.init(arena.allocator(), &nodes);

    try nodes.put(from, .{});
    try frontier.add(from);
    while (frontier.count() != 0) {
        const current = frontier.remove();
        if (current == to) break;

        var it = graph.iterateNeigh(current);
        while (it.next()) |next| {
            const new_gcost = nodes.get(current).?.gcost + graph.gcost(current, next);
            const neighbour = nodes.get(next);
            if (neighbour == null or new_gcost < neighbour.?.gcost) {
                try nodes.put(next, .{
                    .from = current,
                    .gcost = new_gcost,
                    .hcost = graph.hcost(next, to),
                });
                try frontier.add(next);
            }
        }
    } else {
        return null;
    }

    var pos = to;
    var path = try std.array_list.Managed(usize).initCapacity(allocator, 10);
    try path.append(pos);
    if (from != to) {
        while (true) {
            const node = nodes.get(pos).?;
            pos = node.from;
            try path.append(pos);
            if (pos == from) break;
        }
        std.mem.reverse(usize, path.items);
    }
    return path;
}

const invalid_node = math.maxInt(usize);
const Node = struct {
    from: usize = invalid_node,
    gcost: usize = 0,
    hcost: usize = 0,
};
const NodeMap = std.AutoHashMap(usize, Node);
const NodeQueue = std.PriorityQueue(usize, *const NodeMap, compareNode);
fn compareNode(map: *const NodeMap, n1: usize, n2: usize) math.Order {
    const node1 = map.get(n1).?;
    const node2 = map.get(n2).?;
    return math.order(node1.gcost + node1.hcost, node2.gcost + node2.hcost);
}

test "pathfind" {
    const Graph = struct {
        const Iterator = struct {
            ns: [8]usize,
            size: usize,
            idx: usize = 0,

            pub fn next(self: *@This()) ?usize {
                if (self.idx == self.size) return null;
                const n = self.ns[self.idx];
                self.idx += 1;
                return n;
            }
        };
        const Pos = struct { x: usize, y: usize };

        map: [10][10]u8,

        inline fn id2pos(id: usize) Pos {
            return .{ .x = id % 10, .y = id / 10 };
        }
        inline fn pos2id(pos: Pos) usize {
            return pos.y * 10 + pos.x;
        }

        pub fn iterateNeigh(self: @This(), id: usize) Iterator {
            var ns: [8]usize = undefined;
            var size: usize = 0;
            const x: isize = @intCast(id2pos(id).x);
            const y: isize = @intCast(id2pos(id).y);
            const xs = [_]isize{ x - 1, x, x + 1, x - 1, x + 1, x - 1, x, x + 1 };
            const ys = [_]isize{ y - 1, y - 1, y - 1, y, y, y + 1, y + 1, y + 1 };
            for (0..8) |i| {
                const nx = xs[i];
                const ny = ys[i];
                if (nx >= 0 and nx < 10 and ny >= 0 and ny < 10 and
                    self.map[@as(usize, @intCast(ny))][@as(usize, @intCast(nx))] == 1)
                {
                    ns[size] = pos2id(.{
                        .x = @intCast(nx),
                        .y = @intCast(ny),
                    });
                    size += 1;
                }
            }
            return .{
                .ns = ns,
                .size = size,
            };
        }

        pub fn gcost(self: @This(), from: usize, to: usize) usize {
            _ = self;
            const p1 = id2pos(from);
            const p2 = id2pos(to);
            const dx = if (p1.x > p2.x) p1.x - p2.x else p2.x - p1.x;
            const dy = if (p1.y > p2.y) p1.y - p2.y else p2.y - p1.y;
            return if (dx > 1 and dy > 1) dx + dy else 1;
        }

        pub fn hcost(self: @This(), from: usize, to: usize) usize {
            return self.gcost(from, to);
        }
    };

    // Unreachable map
    var graph = Graph{
        .map = .{
            [10]u8{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 },
            [10]u8{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 },
            [10]u8{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 },
            [10]u8{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 },
            [10]u8{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 },
            [10]u8{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
            [10]u8{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
            [10]u8{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
            [10]u8{ 0, 0, 0, 0, 0, 0, 0, 0, 1, 1 },
            [10]u8{ 0, 0, 0, 0, 0, 0, 0, 0, 1, 1 },
        },
    };
    const allocator = std.testing.allocator;
    var path = try calculatePath(
        allocator,
        graph,
        Graph.pos2id(.{ .x = 0, .y = 0 }),
        Graph.pos2id(.{ .x = 9, .y = 9 }),
    );
    try std.testing.expectEqual(path, null);

    // Easy to reach map
    graph = Graph{
        .map = .{
            [10]u8{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 },
            [10]u8{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 },
            [10]u8{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 },
            [10]u8{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 },
            [10]u8{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 },
            [10]u8{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 },
            [10]u8{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 },
            [10]u8{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 },
            [10]u8{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 },
            [10]u8{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 },
        },
    };
    path = try calculatePath(
        allocator,
        graph,
        Graph.pos2id(.{ .x = 0, .y = 0 }),
        Graph.pos2id(.{ .x = 9, .y = 9 }),
    );
    try std.testing.expectEqual(path.?.items.len, 10);
    try std.testing.expectEqual(path.?.items[0], Graph.pos2id(.{ .x = 0, .y = 0 }));
    try std.testing.expectEqual(path.?.items[1], Graph.pos2id(.{ .x = 1, .y = 1 }));
    try std.testing.expectEqual(path.?.items[2], Graph.pos2id(.{ .x = 2, .y = 2 }));
    try std.testing.expectEqual(path.?.items[3], Graph.pos2id(.{ .x = 3, .y = 3 }));
    try std.testing.expectEqual(path.?.items[4], Graph.pos2id(.{ .x = 4, .y = 4 }));
    try std.testing.expectEqual(path.?.items[5], Graph.pos2id(.{ .x = 5, .y = 5 }));
    try std.testing.expectEqual(path.?.items[6], Graph.pos2id(.{ .x = 6, .y = 6 }));
    try std.testing.expectEqual(path.?.items[7], Graph.pos2id(.{ .x = 7, .y = 7 }));
    try std.testing.expectEqual(path.?.items[8], Graph.pos2id(.{ .x = 8, .y = 8 }));
    try std.testing.expectEqual(path.?.items[9], Graph.pos2id(.{ .x = 9, .y = 9 }));
    path.?.deinit();

    // Hard to reach map
    graph = Graph{
        .map = .{
            [10]u8{ 1, 1, 1, 0, 0, 0, 0, 0, 0, 0 },
            [10]u8{ 0, 0, 1, 0, 0, 0, 1, 0, 0, 0 },
            [10]u8{ 0, 0, 1, 0, 0, 1, 0, 1, 0, 0 },
            [10]u8{ 1, 0, 1, 0, 1, 0, 0, 0, 1, 0 },
            [10]u8{ 0, 1, 1, 1, 0, 0, 0, 0, 1, 0 },
            [10]u8{ 1, 1, 1, 0, 0, 0, 0, 0, 0, 1 },
            [10]u8{ 1, 1, 1, 0, 1, 1, 0, 0, 0, 1 },
            [10]u8{ 1, 1, 1, 0, 0, 1, 1, 0, 0, 1 },
            [10]u8{ 1, 1, 1, 1, 1, 1, 1, 1, 0, 1 },
            [10]u8{ 1, 1, 1, 1, 1, 1, 1, 1, 0, 1 },
        },
    };
    path = try calculatePath(
        allocator,
        graph,
        Graph.pos2id(.{ .x = 0, .y = 0 }),
        Graph.pos2id(.{ .x = 9, .y = 9 }),
    );
    try std.testing.expectEqual(path.?.items.len, 17);
    try std.testing.expectEqual(path.?.items[0], Graph.pos2id(.{ .x = 0, .y = 0 }));
    try std.testing.expectEqual(path.?.items[1], Graph.pos2id(.{ .x = 1, .y = 0 }));
    try std.testing.expectEqual(path.?.items[2], Graph.pos2id(.{ .x = 2, .y = 1 }));
    try std.testing.expectEqual(path.?.items[3], Graph.pos2id(.{ .x = 2, .y = 2 }));
    try std.testing.expectEqual(path.?.items[4], Graph.pos2id(.{ .x = 2, .y = 3 }));
    try std.testing.expectEqual(path.?.items[5], Graph.pos2id(.{ .x = 3, .y = 4 }));
    try std.testing.expectEqual(path.?.items[6], Graph.pos2id(.{ .x = 4, .y = 3 }));
    try std.testing.expectEqual(path.?.items[7], Graph.pos2id(.{ .x = 5, .y = 2 }));
    try std.testing.expectEqual(path.?.items[8], Graph.pos2id(.{ .x = 6, .y = 1 }));
    try std.testing.expectEqual(path.?.items[9], Graph.pos2id(.{ .x = 7, .y = 2 }));
    try std.testing.expectEqual(path.?.items[10], Graph.pos2id(.{ .x = 8, .y = 3 }));
    try std.testing.expectEqual(path.?.items[11], Graph.pos2id(.{ .x = 8, .y = 4 }));
    try std.testing.expectEqual(path.?.items[12], Graph.pos2id(.{ .x = 9, .y = 5 }));
    try std.testing.expectEqual(path.?.items[13], Graph.pos2id(.{ .x = 9, .y = 6 }));
    try std.testing.expectEqual(path.?.items[14], Graph.pos2id(.{ .x = 9, .y = 7 }));
    try std.testing.expectEqual(path.?.items[15], Graph.pos2id(.{ .x = 9, .y = 8 }));
    try std.testing.expectEqual(path.?.items[16], Graph.pos2id(.{ .x = 9, .y = 9 }));
    path.?.deinit();
}

test "pathfind supports directed graphs" {
    const Graph = struct {
        const Iterator = struct {
            ns: [2]usize = .{ 0, 0 },
            len: usize = 0,
            idx: usize = 0,

            pub fn next(self: *@This()) ?usize {
                if (self.idx >= self.len) return null;
                defer self.idx += 1;
                return self.ns[self.idx];
            }
        };

        pub fn iterateNeigh(_: @This(), id: usize) Iterator {
            return switch (id) {
                0 => .{ .ns = .{ 1, 2 }, .len = 2 },
                1 => .{ .ns = .{ 2, 0 }, .len = 1 },
                else => .{},
            };
        }

        pub fn gcost(_: @This(), from: usize, to: usize) usize {
            _ = from;
            _ = to;
            return 1;
        }

        pub fn hcost(_: @This(), from: usize, to: usize) usize {
            _ = from;
            _ = to;
            return 0;
        }
    };

    const allocator = std.testing.allocator;
    var path = try calculatePath(allocator, Graph{}, 0, 2);
    defer path.?.deinit();

    try std.testing.expect(path != null);
    try std.testing.expectEqual(@as(usize, 2), path.?.items.len);
    try std.testing.expectEqual(@as(usize, 0), path.?.items[0]);
    try std.testing.expectEqual(@as(usize, 2), path.?.items[1]);
}
