const std = @import("std");
const builtin = @import("builtin");
const jok = @import("jok");
const j2d = jok.j2d;
const font = jok.font;
const physfs = jok.vendor.physfs;

const GRID_SIZE = 4;
const TILE_SIZE = 100;
const TILE_MARGIN = 10;
const BOARD_OFFSET_X = 50;
const BOARD_OFFSET_Y = 100;
const WIN_VALUE = 2048;

const GameState = struct {
    grid: [GRID_SIZE][GRID_SIZE]u32 = std.mem.zeroes([GRID_SIZE][GRID_SIZE]u32),
    score: u32 = 0,
    game_over: bool = false,
    won: bool = false,
};

const Direction = enum { left, right, up, down };

var batchpool: j2d.BatchPool(64, false) = undefined;
var game_state = GameState{};
var rng: std.Random.DefaultPrng = undefined;

const BOARD_BG = jok.Color{ .r = 187, .g = 173, .b = 160, .a = 255 };
const GAME_BG = jok.Color{ .r = 250, .g = 248, .b = 239, .a = 255 };
const EMPTY_TILE = jok.Color{ .r = 205, .g = 193, .b = 180, .a = 255 };

fn valueToColor(v: u32) jok.Color {
    return switch (v) {
        0 => EMPTY_TILE,
        2 => .{ .r = 238, .g = 228, .b = 218, .a = 255 },
        4 => .{ .r = 237, .g = 224, .b = 200, .a = 255 },
        8 => .{ .r = 242, .g = 177, .b = 121, .a = 255 },
        16 => .{ .r = 245, .g = 149, .b = 99, .a = 255 },
        32 => .{ .r = 246, .g = 124, .b = 95, .a = 255 },
        64 => .{ .r = 246, .g = 94, .b = 59, .a = 255 },
        128 => .{ .r = 237, .g = 207, .b = 114, .a = 255 },
        256 => .{ .r = 237, .g = 204, .b = 97, .a = 255 },
        512 => .{ .r = 237, .g = 200, .b = 80, .a = 255 },
        1024 => .{ .r = 237, .g = 197, .b = 63, .a = 255 },
        2048 => .{ .r = 237, .g = 194, .b = 46, .a = 255 },
        else => .{ .r = 60, .g = 58, .b = 50, .a = 255 },
    };
}

fn textColor(v: u32) jok.Color {
    return if (v >= 8) .{ .r = 249, .g = 246, .b = 242, .a = 255 } else .{ .r = 119, .g = 110, .b = 101, .a = 255 };
}

fn getTileRect(r: usize, c: usize) jok.Rectangle {
    return .{
        .x = BOARD_OFFSET_X + @as(f32, @floatFromInt(c)) * (TILE_SIZE + TILE_MARGIN),
        .y = BOARD_OFFSET_Y + @as(f32, @floatFromInt(r)) * (TILE_SIZE + TILE_MARGIN),
        .width = TILE_SIZE,
        .height = TILE_SIZE,
    };
}

fn addRandomTile() void {
    var empties: [GRID_SIZE * GRID_SIZE]struct { r: usize, c: usize } = undefined;
    var count: usize = 0;
    for (0..GRID_SIZE) |r| {
        for (0..GRID_SIZE) |c| {
            if (game_state.grid[r][c] == 0) {
                empties[count] = .{ .r = r, .c = c };
                count += 1;
            }
        }
    }
    if (count > 0) {
        const pos = empties[rng.random().uintLessThan(usize, count)];
        game_state.grid[pos.r][pos.c] = if (rng.random().float(f32) < 0.9) 2 else 4;
    }
}

fn canMove() bool {
    for (0..GRID_SIZE) |r| {
        for (0..GRID_SIZE) |c| {
            if (game_state.grid[r][c] == 0) return true;
            if (c + 1 < GRID_SIZE and game_state.grid[r][c] == game_state.grid[r][c + 1]) return true;
            if (r + 1 < GRID_SIZE and game_state.grid[r][c] == game_state.grid[r + 1][c]) return true;
        }
    }
    return false;
}

fn slideRow(row: []u32, rev: bool) bool {
    var temp: [GRID_SIZE]u32 = undefined;
    var merged = [_]bool{false} ** GRID_SIZE;
    var moved = false;

    for (0..GRID_SIZE) |i| temp[i] = if (rev) row[GRID_SIZE - 1 - i] else row[i];

    for (0..GRID_SIZE - 1) |i| if (temp[i] != 0) for (i + 1..GRID_SIZE) |j| {
        if (temp[j] == 0) continue;
        if (temp[i] == temp[j] and !merged[i]) {
            temp[i] *= 2;
            game_state.score += temp[i];
            temp[j] = 0;
            merged[i] = true;
            moved = true;
            if (temp[i] == WIN_VALUE) game_state.won = true;
        }
        break;
    };

    var w: usize = 0;
    for (0..GRID_SIZE) |i| {
        if (temp[i] != 0) {
            if (i != w) moved = true;
            temp[w] = temp[i];
            w += 1;
        }
    }
    while (w < GRID_SIZE) : (w += 1) temp[w] = 0;

    for (0..GRID_SIZE) |i| row[if (rev) GRID_SIZE - 1 - i else i] = temp[i];
    return moved;
}

fn move(dir: Direction) bool {
    var moved = false;
    switch (dir) {
        .left, .right => |d| {
            for (0..GRID_SIZE) |r| {
                moved = slideRow(game_state.grid[r][0..], d == .right) or moved;
            }
        },
        .up, .down => |d| for (0..GRID_SIZE) |c| {
            var col: [GRID_SIZE]u32 = undefined;
            for (0..GRID_SIZE) |r| col[r] = game_state.grid[r][c];
            if (slideRow(&col, d == .down)) {
                moved = true;
                for (0..GRID_SIZE) |r| game_state.grid[r][c] = col[r];
            }
        },
    }
    return moved;
}

fn resetGame() void {
    game_state = GameState{};
    addRandomTile();
    addRandomTile();
}

// --- Jok ---
pub fn init(ctx: jok.Context) !void {
    const window = ctx.window();
    try window.setTitle("2048 - Jok Example");

    try window.setSize(.{
        .width = BOARD_OFFSET_X * 2 + GRID_SIZE * (TILE_SIZE + TILE_MARGIN) + TILE_MARGIN,
        .height = BOARD_OFFSET_Y + GRID_SIZE * (TILE_SIZE + TILE_MARGIN) + TILE_MARGIN + 140,
    });

    if (!builtin.cpu.arch.isWasm()) try physfs.mount(physfs.getBaseDir(), "", true);
    try physfs.setWriteDir(physfs.getBaseDir());

    batchpool = try @TypeOf(batchpool).init(ctx);
    rng = std.Random.DefaultPrng.init(@intCast(std.Io.Clock.awake.now(ctx.io()).toSeconds()));
    resetGame();
}

pub fn event(ctx: jok.Context, e: jok.Event) !void {
    _ = ctx;
    switch (e) {
        .key_down => |k| {
            if (k.keycode == .r) return resetGame();
            if (game_state.game_over) return;
            const d: ?Direction = switch (k.keycode) {
                .left, .a => .left,
                .right, .d => .right,
                .up, .w => .up,
                .down, .s => .down,
                else => null,
            };
            if (d) |dir| {
                if (move(dir)) {
                    addRandomTile();
                    if (!canMove()) {
                        game_state.game_over = true;
                    }
                }
            }
        },
        else => {},
    }
}

pub fn update(ctx: jok.Context) !void {
    _ = ctx;
}

pub fn draw(ctx: jok.Context) !void {
    try ctx.renderer().clear(GAME_BG);
    var b = try batchpool.new(.{});
    defer b.submit();
    const atlas = try font.DebugFont.getAtlas(ctx, 32);

    const board_rect = jok.Rectangle{
        .x = BOARD_OFFSET_X - TILE_MARGIN,
        .y = BOARD_OFFSET_Y - TILE_MARGIN,
        .width = GRID_SIZE * (TILE_SIZE + TILE_MARGIN) + TILE_MARGIN,
        .height = GRID_SIZE * (TILE_SIZE + TILE_MARGIN) + TILE_MARGIN,
    };
    try b.rectFilled(board_rect, BOARD_BG, .{});

    for (0..GRID_SIZE) |r| {
        for (0..GRID_SIZE) |c| {
            const v = game_state.grid[r][c];
            const rect = getTileRect(r, c);
            try b.rectFilled(rect, valueToColor(v), .{});
            if (v > 0) {
                var buf: [16]u8 = undefined;
                const txt = std.fmt.bufPrintZ(&buf, "{d}", .{v}) catch "?";
                try b.text("{s}", .{txt}, .{
                    .atlas = atlas,
                    .pos = .{ .x = rect.x + rect.width / 2, .y = rect.y + rect.height / 2 - 10 },
                    .align_type = .middle,
                    .tint_color = textColor(v),
                });
            }
        }
    }

    var buf: [32]u8 = undefined;
    const score_txt = std.fmt.bufPrintZ(&buf, "Score: {d}", .{game_state.score}) catch "?";
    try b.text("{s}", .{score_txt}, .{
        .atlas = atlas,
        .pos = .{ .x = BOARD_OFFSET_X, .y = 30 },
        .align_type = .left,
        .tint_color = .{ .r = 50, .g = 50, .b = 50, .a = 255 },
    });

    const status_y = BOARD_OFFSET_Y + GRID_SIZE * (TILE_SIZE + TILE_MARGIN) + 30;
    if (game_state.won and !game_state.game_over)
        try b.text("You Win! Keep playing?", .{}, .{
            .atlas = atlas,
            .pos = .{ .x = BOARD_OFFSET_X, .y = status_y },
            .align_type = .left,
            .tint_color = .{ .r = 50, .g = 50, .b = 50, .a = 255 },
        });
    if (game_state.game_over)
        try b.text("Game Over! Press R to restart", .{}, .{
            .atlas = atlas,
            .pos = .{ .x = BOARD_OFFSET_X, .y = status_y },
            .align_type = .left,
            .tint_color = .{ .r = 200, .g = 0, .b = 0, .a = 255 },
        });

    try b.text("Use WASD or Arrow Keys to move", .{}, .{
        .atlas = atlas,
        .pos = .{ .x = BOARD_OFFSET_X, .y = status_y + 40 },
        .align_type = .left,
        .tint_color = .{ .r = 80, .g = 80, .b = 80, .a = 255 },
    });
}

pub fn quit(ctx: jok.Context) void {
    _ = ctx;
    batchpool.deinit();
}
