const std = @import("std");
const jok = @import("jok");
const physfs = jok.physfs;
const font = jok.font;
const j2d = jok.j2d;

var batchpool: j2d.BatchPool(64, false) = undefined;
var saved_atlas: *font.Atlas = undefined;

pub fn init(ctx: jok.Context) !void {
    std.log.info("game init", .{});

    try physfs.mount(physfs.getBaseDir(), "", true);
    try physfs.setWriteDir(physfs.getBaseDir());

    batchpool = try @TypeOf(batchpool).init(ctx);

    const font_size = 16;
    const vmetrics = font.DebugFont.font.getVMetrics(font_size);
    const height = @as(u32, @intFromFloat(vmetrics.ascent - vmetrics.descent));
    const output = "jok is here!";
    for (0..height) |j| {
        const ypos = @as(f32, @floatFromInt(j));
        var xpos: f32 = 0;
        for (output) |c| {
            const glyph = font.DebugFont.font.findGlyphIndex(c).?;
            const map = try font.DebugFont.font.createGlyphBitmap(ctx.allocator(), glyph, font_size);
            defer map.destroy();
            const metrics = font.DebugFont.font.getGlyphMetrics(glyph, font_size);
            const bbox = metrics.getBBox(.{ .x = xpos, .y = 0 }, .top);
            for (0..@as(usize, @intFromFloat(metrics.advance_width))) |k| {
                const x = xpos + @as(f32, @floatFromInt(k));
                const char = if (bbox.containsPoint(.{ .x = x, .y = ypos }))
                    ".-*%#@"[std.math.clamp(map.getValue(@intFromFloat(x - bbox.x), @intFromFloat(ypos - bbox.y)), 0, 5)]
                else
                    '.';
                std.debug.print("{c}", .{char});
            }
            xpos += metrics.advance_width;
        }
        std.debug.print("\n", .{});
    }

    var atlas = try font.DebugFont.font.createAtlas(
        ctx,
        80,
        null,
        .{ .keep_pixels = true },
    );
    try atlas.save(ctx, "atlas.png");
    atlas.destroy();
    saved_atlas = try font.Atlas.load(ctx, "atlas.png");
}

pub fn event(ctx: jok.Context, e: jok.Event) !void {
    _ = ctx;
    _ = e;
}

pub fn update(ctx: jok.Context) !void {
    _ = ctx;
}

pub fn draw(ctx: jok.Context) !void {
    try ctx.renderer().clear(null);

    const size = ctx.getCanvasSize();
    const rect_color = jok.Color.rgba(0, 128, 0, 120);

    var b = try batchpool.new(.{ .depth_sort = .back_to_forth });
    defer b.submit();
    var atlas = try font.DebugFont.getAtlas(ctx, 20);
    try b.text(
        "ABCDEFGHIJKL abcdefghijkl",
        .{},
        .{
            .atlas = atlas,
            .pos = .{ .x = 0, .y = 0 },
            .ypos_type = .top,
            .tint_color = jok.Color.cyan,
        },
    );
    var area = try atlas.getBoundingBox(
        "ABCDEFGHIJKL abcdefghijkl",
        .{ .x = 0, .y = 0 },
        .top,
        .aligned,
    );
    try b.rectFilled(area, rect_color, .{});

    try b.text(
        "Hello,",
        .{},
        .{
            .atlas = saved_atlas,
            .pos = .{ .x = 0, .y = size.getHeightFloat() / 2 },
            .ypos_type = .bottom,
            .ignore_unexist = false,
        },
    );
    area = try saved_atlas.getBoundingBox(
        "Hello,",
        .{ .x = 0, .y = size.getHeightFloat() / 2 },
        .bottom,
        .aligned,
    );
    try b.rectFilled(area, rect_color, .{});

    try b.text(
        "jok!",
        .{},
        .{
            .atlas = saved_atlas,
            .pos = .{
                .x = area.x + area.width,
                .y = size.getHeightFloat() / 2,
            },
            .tint_color = jok.Color.rgb(
                @intFromFloat(128 + @sin(ctx.seconds()) * 127),
                @intFromFloat(128 + @cos(ctx.seconds()) * 127),
                @intFromFloat(128 + @sin(ctx.seconds()) * 127),
            ),
            .scale = .{
                .x = 4 + 3 * @sin(ctx.seconds()),
                .y = 4 + 3 * @cos(ctx.seconds()),
            },
            .rotate_degree = ctx.seconds() * 30,
            .depth = 0,
        },
    );

    try b.text(
        "ABCDE abcde",
        .{},
        .{
            .atlas = saved_atlas,
            .pos = .{ .x = 0, .y = size.getHeightFloat() },
            .ypos_type = .bottom,
            .tint_color = jok.Color.red,
        },
    );
    area = try saved_atlas.getBoundingBox(
        "ABCDE abcde",
        .{ .x = 0, .y = size.getHeightFloat() },
        .bottom,
        .aligned,
    );
    try b.rectFilled(area, rect_color, .{});

    atlas = try font.DebugFont.getAtlas(ctx, 128);
    const metrics = font.DebugFont.font.getGlyphMetrics(
        font.DebugFont.font.findGlyphIndex('Q').?,
        128,
    );
    const q_pos = jok.Point{
        .x = (size.getWidthFloat() - 128) / 2,
        .y = (size.getHeightFloat() - 128) / 2,
    };
    try b.rectFilled(
        metrics.getSpace(q_pos, .baseline),
        jok.Color.rgba(255, 0, 0, 128),
        .{},
    );
    try b.rectFilled(
        metrics.getBBox(q_pos, .baseline),
        jok.Color.rgba(0, 255, 0, 128),
        .{},
    );
    try b.rectFilled(
        metrics.getSpace(q_pos.add(.{ .x = metrics.advance_width, .y = 0 }), .top),
        jok.Color.rgba(255, 0, 0, 128),
        .{},
    );
    try b.rectFilled(
        metrics.getBBox(q_pos.add(.{ .x = metrics.advance_width, .y = 0 }), .top),
        jok.Color.rgba(0, 255, 0, 128),
        .{},
    );
    try b.rectFilled(
        metrics.getSpace(q_pos.add(.{ .x = metrics.advance_width * 2, .y = 0 }), .bottom),
        jok.Color.rgba(255, 0, 0, 128),
        .{},
    );
    try b.rectFilled(
        metrics.getBBox(q_pos.add(.{ .x = metrics.advance_width * 2, .y = 0 }), .bottom),
        jok.Color.rgba(0, 255, 0, 128),
        .{},
    );
    try b.text(
        "Q",
        .{},
        .{
            .atlas = atlas,
            .pos = q_pos,
            .ypos_type = .baseline,
        },
    );
    try b.text(
        "Q",
        .{},
        .{
            .atlas = atlas,
            .pos = q_pos.add(.{ .x = metrics.advance_width, .y = 0 }),
            .ypos_type = .top,
        },
    );
    try b.text(
        "Q",
        .{},
        .{
            .atlas = atlas,
            .pos = q_pos.add(.{ .x = metrics.advance_width * 2, .y = 0 }),
            .ypos_type = .bottom,
        },
    );
}

pub fn quit(ctx: jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});
    batchpool.deinit();
    saved_atlas.destroy();
}
