const std = @import("std");
const jok = @import("jok");
const sdl = jok.sdl;
const font = jok.font;
const j2d = jok.j2d;

const Tile = struct {
    pos: sdl.PointF,
    sprite: j2d.Sprite,
};

var sheet: *j2d.SpriteSheet = undefined;
var sps: [4]j2d.Sprite = undefined;
var map: [10][10]Tile = undefined;
var iso_transform: jok.utils.math.IsometricTransform = undefined;
var scale: f32 = undefined;

pub fn init(ctx: jok.Context) !void {
    std.log.info("game init", .{});

    sheet = try j2d.SpriteSheet.fromPicturesInDir(ctx, "assets/images/iso", 1024, 1024, .{});
    sps[0] = sheet.getSpriteByName("tile1").?;
    sps[1] = sheet.getSpriteByName("tile2").?;
    sps[2] = sheet.getSpriteByName("tile3").?;
    sps[3] = sheet.getSpriteByName("tile4").?;

    var rng = std.Random.DefaultPrng.init(@intCast(std.time.timestamp()));
    for (0..10) |y| {
        for (0..10) |x| {
            map[y][x] = .{
                .pos = .{ .x = @floatFromInt(x), .y = @floatFromInt(y) },
                .sprite = sps[rng.random().intRangeAtMost(usize, 0, 3)],
            };
        }
    }

    const csz = ctx.getCanvasSize();
    scale = 0.5;
    iso_transform = jok.utils.math.IsometricTransform.init(
        .{ .width = @intFromFloat(sps[0].width), .height = @intFromFloat(sps[0].height) },
        .{
            .xy_offset = .{ .x = csz.x / 2, .y = 100 },
            .scale = scale,
        },
    );
}

pub fn event(ctx: jok.Context, e: sdl.Event) !void {
    _ = ctx;
    _ = e;
}

pub fn update(ctx: jok.Context) !void {
    _ = ctx;
}

pub fn draw(ctx: jok.Context) !void {
    ctx.clear(null);

    const mouse = ctx.getMouseState();
    const mouse_pos_in_iso_space = iso_transform.transformToIso(.{
        .x = @floatFromInt(mouse.x),
        .y = @floatFromInt(mouse.y),
    });

    j2d.begin(.{});
    defer j2d.end();

    for (0..10) |y| {
        for (0..10) |x| {
            var tint_color = sdl.Color.white;

            // BUG: this might be wrong
            if (mouse_pos_in_iso_space.x > @as(f32, @floatFromInt(x)) and
                mouse_pos_in_iso_space.x < @as(f32, @floatFromInt(x + 1)) and
                mouse_pos_in_iso_space.y > @as(f32, @floatFromInt(y)) and
                mouse_pos_in_iso_space.y < @as(f32, @floatFromInt(y + 1)))
            {
                tint_color = sdl.Color.red;
            }

            const tile = map[y][x];
            const zoffset = @sin(ctx.seconds() + @as(f32, @floatFromInt(x + y))) * 10;
            try j2d.sprite(
                tile.sprite,
                .{
                    .pos = iso_transform.transformToScreen(tile.pos, zoffset),
                    .scale = .{ .x = scale, .y = scale },
                    .tint_color = tint_color,
                },
            );
        }
    }
}

pub fn quit(ctx: jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});

    sheet.destroy();
}
