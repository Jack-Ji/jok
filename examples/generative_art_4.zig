// Directly ported from ebitengine's doomfire example
const std = @import("std");
const jok = @import("jok");

pub const jok_canvas_size = jok.Size{
    .width = 100,
    .height = 50,
};

const palette = [_]jok.Color{
    jok.Color.rgb(7, 7, 7), //  0
    jok.Color.rgb(31, 7, 7), //  1
    jok.Color.rgb(47, 15, 7), //  2
    jok.Color.rgb(71, 15, 7), //  3
    jok.Color.rgb(87, 23, 7), //  4
    jok.Color.rgb(103, 31, 7), //  5
    jok.Color.rgb(119, 31, 7), //  6
    jok.Color.rgb(143, 39, 7), //  7
    jok.Color.rgb(159, 47, 7), //  8
    jok.Color.rgb(175, 63, 7), //  9
    jok.Color.rgb(191, 71, 7), // 10
    jok.Color.rgb(199, 71, 7), // 11
    jok.Color.rgb(223, 79, 7), // 12
    jok.Color.rgb(223, 87, 7), // 13
    jok.Color.rgb(223, 87, 7), // 14
    jok.Color.rgb(215, 95, 7), // 15
    jok.Color.rgb(215, 95, 7), // 16
    jok.Color.rgb(215, 103, 15), // 17
    jok.Color.rgb(207, 111, 15), // 18
    jok.Color.rgb(207, 119, 15), // 19
    jok.Color.rgb(207, 127, 15), // 20
    jok.Color.rgb(207, 135, 23), // 21
    jok.Color.rgb(199, 135, 23), // 22
    jok.Color.rgb(199, 143, 23), // 23
    jok.Color.rgb(199, 151, 31), // 24
    jok.Color.rgb(191, 159, 31), // 25
    jok.Color.rgb(191, 159, 31), // 26
    jok.Color.rgb(191, 167, 39), // 27
    jok.Color.rgb(191, 167, 39), // 28
    jok.Color.rgb(191, 175, 47), // 29
    jok.Color.rgb(183, 175, 47), // 30
    jok.Color.rgb(183, 183, 47), // 31
    jok.Color.rgb(183, 183, 55), // 32
    jok.Color.rgb(207, 207, 111), // 33
    jok.Color.rgb(223, 223, 159), // 34
    jok.Color.rgb(239, 239, 199), // 35
    jok.Color.rgb(255, 255, 255), // 36
};

var screen_size: u32 = undefined;
var screen_width: u32 = undefined;
var screen_height: u32 = undefined;
var doomfire: jok.Texture = undefined;
var indices: []u8 = undefined;
var pixeldata: jok.Texture.PixelData = undefined;
var rng: std.Random.DefaultPrng = undefined;

pub fn init(ctx: jok.Context) !void {
    const csz = ctx.getCanvasSize();
    screen_width = csz.width;
    screen_height = csz.height;
    screen_size = screen_width * screen_height;
    doomfire = try ctx.renderer().createTexture(csz, null, .{ .access = .streaming });
    indices = try ctx.allocator().alloc(u8, screen_size);
    @memset(indices, 36);
    @memset(indices[0..screen_width], 0);
    pixeldata = try doomfire.createPixelData(ctx.allocator(), null);
    rng = std.Random.DefaultPrng.init(@intCast(std.time.milliTimestamp()));
}

pub fn event(ctx: jok.Context, e: jok.Event) !void {
    _ = ctx;
    _ = e;
}

pub fn update(ctx: jok.Context) !void {
    _ = ctx;

    for (0..screen_height) |y| {
        for (0..screen_width) |x| {
            const idx = y * screen_width + x;
            const below = idx + screen_width;
            if (below >= screen_size) continue;

            const d = rng.random().intRangeLessThan(u8, 0, 3);
            if (idx < d) continue;

            const newi = if (indices[below] < d) 0 else indices[below] - d;
            indices[idx - d] = newi;
        }
    }
}

pub fn draw(ctx: jok.Context) !void {
    for (0..screen_size) |i| {
        pixeldata.setPixelByIndex(@intCast(i), palette[indices[i]]);
    }
    try doomfire.update(pixeldata);
    try ctx.renderer().drawTexture(doomfire, null, null);

    ctx.displayStats(.{});
}

pub fn quit(ctx: jok.Context) void {
    doomfire.destroy();
    pixeldata.destroy();
    ctx.allocator().free(indices);
}
