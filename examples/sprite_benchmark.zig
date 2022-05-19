const std = @import("std");
const sdl = @import("sdl");
const jok = @import("jok");
const gfx = jok.gfx.@"2d";

const Actor = struct {
    sprite: gfx.Sprite,
    pos: sdl.PointF,
    velocity: sdl.PointF,
};

var sheet: *gfx.SpriteSheet = undefined;
var sprite_batch: *gfx.SpriteBatch = undefined;
var characters: std.ArrayList(Actor) = undefined;
var all_names: std.ArrayList([]const u8) = undefined;
var rand_gen: std.rand.DefaultPrng = undefined;
var delta_tick: f32 = 0;

fn init(ctx: *jok.Context) anyerror!void {
    _ = ctx;
    std.log.info("game init", .{});

    const size = ctx.getFramebufferSize();

    // create sprite sheet
    sheet = try gfx.SpriteSheet.fromPicturesInDir(
        ctx.default_allocator,
        ctx.renderer,
        "assets/images",
        size.w,
        size.h,
        1,
        false,
        .{ .accept_jpg = false },
    );
    sprite_batch = try gfx.SpriteBatch.init(
        ctx.default_allocator,
        10,
        1000000,
    );
    characters = try std.ArrayList(Actor).initCapacity(
        ctx.default_allocator,
        1000000,
    );
    all_names = try std.ArrayList([]const u8).initCapacity(
        ctx.default_allocator,
        10000,
    );
    var it = sheet.search_tree.iterator();
    while (it.next()) |k| {
        try all_names.append(k.key_ptr.*);
    }
    rand_gen = std.rand.DefaultPrng.init(@intCast(u64, std.time.timestamp()));

    try ctx.renderer.setColorRGB(77, 77, 77);
}

fn loop(ctx: *jok.Context) anyerror!void {
    delta_tick = (delta_tick + ctx.delta_tick) / 2;

    while (ctx.pollEvent()) |e| {
        switch (e) {
            .keyboard_event => |key| {
                if (key.trigger_type == .up) {
                    switch (key.scan_code) {
                        .escape => ctx.kill(),
                        else => {},
                    }
                }
            },
            .mouse_event => |me| {
                switch (me.data) {
                    .button => |click| {
                        if (click.btn != .left) {
                            continue;
                        }
                        var rd = rand_gen.random();
                        if (click.clicked) {
                            const pos = sdl.PointF{
                                .x = @intToFloat(f32, click.x),
                                .y = @intToFloat(f32, click.y),
                            };
                            var i: u32 = 0;
                            while (i < 1000) : (i += 1) {
                                const index = rd.uintLessThan(usize, all_names.items.len);
                                const angle = rd.float(f32) * 2 * std.math.pi;
                                const name = all_names.items[index];
                                try characters.append(.{
                                    .sprite = try sheet.createSprite(name),
                                    .pos = pos,
                                    .velocity = .{
                                        .x = 5 * @cos(angle),
                                        .y = 5 * @sin(angle),
                                    },
                                });
                            }
                        }
                    },
                    else => {},
                }
            },
            .quit_event => ctx.kill(),
            else => {},
        }
    }

    const size = ctx.getFramebufferSize();
    for (characters.items) |*c| {
        const curpos = c.pos;
        if (curpos.x < 0 or curpos.x + c.sprite.width > @intToFloat(f32, size.w))
            c.velocity.x = -c.velocity.x;
        if (curpos.y < 0 or curpos.y + c.sprite.height > @intToFloat(f32, size.h))
            c.velocity.y = -c.velocity.y;
        c.pos.x += c.velocity.x;
        c.pos.y += c.velocity.y;
    }

    try ctx.renderer.clear();
    sprite_batch.begin(.{});
    for (characters.items) |c| {
        try sprite_batch.drawSprite(c.sprite, .{
            .pos = c.pos,
        });
    }
    try sprite_batch.end(ctx.renderer);

    _ = try gfx.font.debugDraw(
        ctx.renderer,
        .{ .pos = .{ .x = 0, .y = 0 }, .color = sdl.Color.white },
        "# of sprites: {d}",
        .{characters.items.len},
    );
}

fn quit(ctx: *jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});
    sheet.deinit();
    sprite_batch.deinit();
    characters.deinit();
    all_names.deinit();
}

pub fn main() anyerror!void {
    try jok.run(.{
        .initFn = init,
        .loopFn = loop,
        .quitFn = quit,
        .width = 800,
        .height = 600,
    });
}
