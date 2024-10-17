const std = @import("std");
const jok = @import("jok");
const j2d = jok.j2d;

const Cell = struct {
    rect: jok.Rectangle,
    alive: bool,
    color: jok.Color,
};

const cell_size = 5;
const map_width = 800 / cell_size;
const map_height = 600 / cell_size;
const Map = [map_height][map_width]Cell;

var map_a: Map = undefined;
var map_b: Map = undefined;
var map: *Map = undefined;
var time: f32 = 0;

pub fn init(ctx: jok.Context) !void {
    _ = ctx;

    var rng = std.Random.DefaultPrng.init(@intCast(std.time.milliTimestamp()));
    map = &map_a;
    for (0..map_height) |y| {
        for (0..map_width) |x| {
            const alive = rng.random().boolean();
            map[y][x] = .{
                .rect = .{
                    .x = @floatFromInt(x * cell_size),
                    .y = @floatFromInt(y * cell_size),
                    .width = @floatFromInt(cell_size),
                    .height = @floatFromInt(cell_size),
                },
                .alive = alive,
                .color = if (alive) jok.Color.white else jok.Color.black,
            };
        }
    }
}

pub fn event(ctx: jok.Context, e: jok.Event) !void {
    _ = ctx;
    _ = e;
}

pub fn update(ctx: jok.Context) !void {
    if (ctx.seconds() - time > 0.1) {
        time = ctx.seconds();

        var next = if (map == &map_a) &map_b else &map_a;
        for (0..map_height) |_y| {
            for (0..map_width) |_x| {
                const y: isize = @intCast(_y);
                const x: isize = @intCast(_x);
                const c = map[_y][_x];

                // Scan 8 neighbours
                const dy = [_]isize{ -1, -1, -1, 0, 0, 1, 1, 1 };
                const dx = [_]isize{ -1, 0, 1, -1, 1, -1, 0, 1 };
                var alive_neighbour: usize = 0;
                for (0..8) |i| {
                    const nx = x + dx[i];
                    const ny = y + dy[i];
                    if (nx < 0 or ny < 0 or nx >= map_width or ny >= map_height) continue;
                    if (map[@as(usize, @intCast(ny))][@as(usize, @intCast(nx))].alive) alive_neighbour += 1;
                }

                // Update according to conway's rule:
                // 1. Any live cell with fewer than two live neighbours dies, as if by underpopulation.
                // 2. Any live cell with two or three live neighbours lives on to the next generation.
                // 3. Any live cell with more than three live neighbours dies, as if by overpopulation.
                // 4. Any dead cell with exactly three live neighbours becomes a live cell, as if by reproduction.
                next[_y][_x] = c;
                switch (alive_neighbour) {
                    0, 1, 4, 5, 6, 7, 8 => {
                        next[_y][_x].alive = false;
                        next[_y][_x].color = jok.Color.black;
                    },
                    2 => {
                        // nothing to do here
                    },
                    3 => {
                        if (!c.alive) {
                            next[_y][_x].alive = true;
                            next[_y][_x].color = jok.Color.white;
                        }
                    },
                    else => unreachable,
                }
            }
        }
        map = next;
    }
}

pub fn draw(ctx: jok.Context) !void {
    try ctx.renderer().clear(null);

    j2d.begin(.{});
    defer j2d.end();
    for (map[0..]) |row| {
        for (row[0..]) |c| {
            try j2d.rectFilled(c.rect, c.color, .{});
        }
    }
}

pub fn quit(ctx: jok.Context) void {
    _ = ctx;
}
