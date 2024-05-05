const std = @import("std");
const jok = @import("jok");
const sdl = jok.sdl;
const font = jok.font;
const zmath = jok.zmath;
const imgui = jok.imgui;
const j2d = jok.j2d;
const pathfind = jok.utils.pathfind;

const cell_size = 10;
const graph_width = 800 / cell_size;
const graph_height = 600 / cell_size;
const Graph = struct {
    const Iterator = struct {
        ps: [8]usize,
        cur: usize,
        size: usize,

        pub fn next(self: *Iterator) ?usize {
            if (self.cur >= self.size) return null;
            const idx = self.ps[self.cur];
            self.cur += 1;
            return idx;
        }
    };

    map: [graph_height][graph_width]bool,

    pub fn init(rnd: std.Random) Graph {
        var g = Graph{ .map = undefined };
        for (0..graph_height) |i| {
            for (0..graph_width) |j| {
                g.map[i][j] = rnd.intRangeAtMost(usize, 1, 10) < 9;
            }
        }
        return g;
    }

    pub fn iterateNeigh(self: Graph, id: usize) Iterator {
        const x: isize = @intCast(id % graph_width);
        const y: isize = @intCast(id / graph_width);
        var it = Iterator{
            .ps = undefined,
            .cur = 0,
            .size = 0,
        };
        const xs = [_]isize{ x - 1, x + 1, x, x };
        const ys = [_]isize{ y, y, y - 1, y + 1 };
        for (0..4) |i| {
            if (self.isReachable(xs[i], ys[i])) {
                const nid: usize = @intCast(ys[i] * graph_width + xs[i]);
                it.ps[it.size] = nid;
                it.size += 1;
                searched_blocks.set(nid);
            }
        }
        return it;
    }

    pub fn gcost(self: Graph, from: usize, to: usize) usize {
        _ = self;
        const from_x = from % graph_width;
        const from_y = from / graph_width;
        const to_x = to % graph_width;
        const to_y = to / graph_width;
        const dx = if (from_x > to_x) from_x - to_x else to_x - from_x;
        const dy = if (from_y > to_y) from_y - to_y else to_y - from_y;
        return dx + dy;
    }

    pub fn hcost(self: Graph, from: usize, to: usize) usize {
        return self.gcost(from, to);
    }

    inline fn isReachable(self: Graph, x: isize, y: isize) bool {
        return x >= 0 and x < graph_width and
            y >= 0 and y < graph_height and
            self.map[@as(usize, @intCast(y))][@as(usize, @intCast(x))];
    }
};

var rng: std.Random.DefaultPrng = undefined;
var graph: Graph = undefined;
var source: usize = 0;
var source_update_time: f32 = 0;
var path: ?std.ArrayList(usize) = null;
var walk_idx: usize = undefined;
var searched_blocks: std.DynamicBitSet = undefined;

pub fn init(ctx: jok.Context) !void {
    rng = std.Random.DefaultPrng.init(@intCast(std.time.timestamp()));
    graph = Graph.init(rng.random());
    LOOP: for (0..graph_height) |i| {
        for (0..graph_width) |j| {
            if (graph.map[i][j]) {
                source = i * graph_width + j;
                break :LOOP;
            }
        }
    }
    searched_blocks = try std.DynamicBitSet.initEmpty(ctx.allocator(), 10000);
}

pub fn event(ctx: jok.Context, e: sdl.Event) !void {
    if (e == .mouse_button_down) {
        const x: usize = @intCast(@divTrunc(e.mouse_button_down.x, cell_size));
        const y: usize = @intCast(@divTrunc(e.mouse_button_down.y, cell_size));
        const dst = y * graph_width + x;
        if (path) |p| p.deinit();
        searched_blocks.setRangeValue(.{ .start = 0, .end = 10000 }, false);
        path = try pathfind.calculatePath(
            ctx.allocator(),
            graph,
            source,
            dst,
        );
        walk_idx = 1;
    }
}

pub fn update(ctx: jok.Context) !void {
    _ = ctx;
}

pub fn draw(ctx: jok.Context) !void {
    ctx.clear(null);

    j2d.begin(.{});
    defer j2d.end();
    for (0..graph_height) |i| {
        for (0..graph_width) |j| {
            if (graph.map[i][j]) {
                try j2d.rectFilled(.{
                    .x = @floatFromInt(cell_size * j),
                    .y = @floatFromInt(cell_size * i),
                    .width = cell_size,
                    .height = cell_size,
                }, sdl.Color.white, .{});
            }
        }
    }
    {
        var it = searched_blocks.iterator(.{});
        while (it.next()) |id| {
            const x = id % graph_width;
            const y = id / graph_width;
            try j2d.rectFilled(.{
                .x = @floatFromInt(cell_size * x),
                .y = @floatFromInt(cell_size * y),
                .width = cell_size,
                .height = cell_size,
            }, sdl.Color.rgb(200, 255, 200), .{});
        }
    }
    {
        const x = source % graph_width;
        const y = source / graph_width;
        try j2d.circleFilled(.{
            .x = @floatFromInt(cell_size * x + cell_size / 2),
            .y = @floatFromInt(cell_size * y + cell_size / 2),
        }, 5, sdl.Color.blue, .{});
    }
    if (path) |p| {
        const dst = p.items[p.items.len - 1];
        try j2d.circleFilled(.{
            .x = @floatFromInt(dst % graph_width * cell_size + cell_size / 2),
            .y = @floatFromInt(dst / graph_width * cell_size + cell_size / 2),
        }, 5, sdl.Color.red, .{});

        if (source != dst) {
            source_update_time -= ctx.deltaSeconds();
            if (source_update_time < 0) {
                source_update_time = 0.06;
                source = p.items[walk_idx];
                walk_idx += 1;
            }
            var last_x = p.items[walk_idx - 1] % graph_width;
            var last_y = p.items[walk_idx - 1] / graph_width;
            for (p.items[walk_idx..]) |id| {
                const x = id % graph_width;
                const y = id / graph_width;
                try j2d.line(
                    .{
                        .x = @floatFromInt(cell_size * last_x + cell_size / 2),
                        .y = @floatFromInt(cell_size * last_y + cell_size / 2),
                    },
                    .{
                        .x = @floatFromInt(cell_size * x + cell_size / 2),
                        .y = @floatFromInt(cell_size * y + cell_size / 2),
                    },
                    sdl.Color.magenta,
                    .{},
                );
                last_x = x;
                last_y = y;
            }
        }
    }
}

pub fn quit(ctx: jok.Context) void {
    _ = ctx;
    searched_blocks.deinit();
    if (path) |p| p.deinit();
}
