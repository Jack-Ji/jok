const std = @import("std");
const builtin = @import("builtin");
const jok = @import("jok");
const physfs = jok.physfs;
const font = jok.font;
const j2d = jok.j2d;

var batchpool: j2d.BatchPool(64, false) = undefined;
var saved_atlas: *font.Atlas = undefined;

pub fn init(ctx: jok.Context) !void {
    std.log.info("game init", .{});

    if (!builtin.cpu.arch.isWasm()) {
        try physfs.mount(physfs.getBaseDir(), "", true);
    }
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
        40,
        &font.codepoint_ranges.chinese_full,
        .{ .keep_pixels = true },
    );
    var t = std.time.nanoTimestamp();
    try atlas.save(ctx, "atlas.png", .{});
    std.debug.print("Atlas save time: {s}\n", .{std.fmt.fmtDuration(
        @intCast(std.time.nanoTimestamp() - t),
    )});
    atlas.destroy();
    t = std.time.nanoTimestamp();
    saved_atlas = try font.Atlas.load(ctx, "atlas.png");
    std.debug.print("Atlas load time: {s}\n", .{std.fmt.fmtDuration(
        @intCast(std.time.nanoTimestamp() - t),
    )});
}

pub fn event(ctx: jok.Context, e: jok.Event) !void {
    _ = ctx;
    _ = e;
}

pub fn update(ctx: jok.Context) !void {
    _ = ctx;
}

pub fn draw(ctx: jok.Context) !void {
    try ctx.renderer().clear(.none);

    const size = ctx.getCanvasSize();
    const rect_color = jok.Color.rgba(0, 128, 0, 120);

    var b = try batchpool.new(.{});
    defer b.submit();
    var atlas = try font.DebugFont.getAtlas(ctx, 20);
    var area = try atlas.getBoundingBox(
        "Left Aligned: ABCDEFGHIJKL abcdefghijkl",
        .{ .x = 0, .y = 50 },
        .{
            .ypos_type = .top,
            .align_type = .left,
        },
    );
    try b.rectFilled(area, rect_color, .{});
    try b.text(
        "Left Aligned: ABCDEFGHIJKL abcdefghijkl",
        .{},
        .{
            .atlas = atlas,
            .pos = .{ .x = 0, .y = 50 },
            .ypos_type = .top,
        },
    );

    area = try saved_atlas.getBoundingBox(
        "Right Aligned: Hello,",
        .{ .x = size.getWidthFloat(), .y = 150 },
        .{
            .ypos_type = .bottom,
            .align_type = .right,
        },
    );
    try b.rectFilled(area, rect_color, .{});
    try b.text(
        "Right Aligned: Hello,",
        .{},
        .{
            .atlas = saved_atlas,
            .pos = .{ .x = size.getWidthFloat(), .y = 150 },
            .ypos_type = .bottom,
            .align_type = .right,
            .ignore_unexist = false,
        },
    );

    try b.text(
        "jok!",
        .{},
        .{
            .atlas = saved_atlas,
            .pos = .{ .x = area.x + area.width, .y = 150 },
            .align_type = .right,
            .tint_color = .rgb(
                @intFromFloat(128 + @sin(ctx.seconds()) * 127),
                @intFromFloat(128 + @cos(ctx.seconds()) * 127),
                @intFromFloat(128 + @sin(ctx.seconds()) * 127),
            ),
            .scale = .{
                .x = 3 + 2 * @sin(ctx.seconds()),
                .y = 3 + 2 * @cos(ctx.seconds()),
            },
        },
    );

    area = try saved_atlas.getBoundingBox(
        "Middle Aligned: ABCDE abcde",
        .{ .x = size.getWidthFloat() / 2, .y = 200 },
        .{ .align_type = .middle },
    );
    try b.rectFilled(area, rect_color, .{});
    try b.text(
        "Middle Aligned: ABCDE abcde",
        .{},
        .{
            .atlas = saved_atlas,
            .pos = .{ .x = size.getWidthFloat() / 2, .y = 200 },
            .align_type = .middle,
            .tint_color = .red,
        },
    );

    atlas = try font.DebugFont.getAtlas(ctx, 128);
    const metrics = font.DebugFont.font.getGlyphMetrics(
        font.DebugFont.font.findGlyphIndex('Q').?,
        128,
    );
    const q_pos = jok.Point{ .x = 100, .y = 450 };
    try b.rectFilled(
        metrics.getSpace(q_pos, .baseline),
        .rgba(200, 0, 0, 128),
        .{},
    );
    try b.rectFilled(
        metrics.getBBox(q_pos, .baseline),
        .rgba(0, 200, 0, 200),
        .{},
    );
    try b.rectFilled(
        metrics.getSpace(q_pos.add(.{ .x = metrics.advance_width, .y = 0 }), .top),
        .rgba(200, 0, 0, 128),
        .{},
    );
    try b.rectFilled(
        metrics.getBBox(q_pos.add(.{ .x = metrics.advance_width, .y = 0 }), .top),
        .rgba(0, 200, 0, 200),
        .{},
    );
    try b.rectFilled(
        metrics.getSpace(q_pos.add(.{ .x = metrics.advance_width * 2, .y = 0 }), .bottom),
        .rgba(200, 0, 0, 128),
        .{},
    );
    try b.rectFilled(
        metrics.getBBox(q_pos.add(.{ .x = metrics.advance_width * 2, .y = 0 }), .bottom),
        .rgba(0, 200, 0, 200),
        .{},
    );
    try b.rectFilled(
        metrics.getSpace(q_pos.add(.{ .x = metrics.advance_width * 3, .y = 0 }), .middle),
        .rgba(200, 0, 0, 128),
        .{},
    );
    try b.rectFilled(
        metrics.getBBox(q_pos.add(.{ .x = metrics.advance_width * 3, .y = 0 }), .middle),
        .rgba(0, 200, 0, 200),
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
    try b.text("baseline", .{}, .{
        .pos = q_pos.add(.{ .x = metrics.advance_width / 2, .y = -105 }),
        .atlas = try font.DebugFont.getAtlas(ctx, 16),
        .tint_color = .purple,
        .ypos_type = .bottom,
        .align_type = .middle,
    });
    try b.text(
        "Q",
        .{},
        .{
            .atlas = atlas,
            .pos = q_pos.add(.{ .x = metrics.advance_width, .y = 0 }),
            .ypos_type = .top,
        },
    );
    try b.text("top", .{}, .{
        .pos = q_pos.add(.{ .x = metrics.advance_width * 1.5, .y = -5 }),
        .atlas = try font.DebugFont.getAtlas(ctx, 16),
        .tint_color = .purple,
        .ypos_type = .bottom,
        .align_type = .middle,
    });
    try b.text(
        "Q",
        .{},
        .{
            .atlas = atlas,
            .pos = q_pos.add(.{ .x = metrics.advance_width * 2, .y = 0 }),
            .ypos_type = .bottom,
        },
    );
    try b.text("bottom", .{}, .{
        .pos = q_pos.add(.{ .x = metrics.advance_width * 2.5, .y = -130 }),
        .atlas = try font.DebugFont.getAtlas(ctx, 16),
        .tint_color = .purple,
        .ypos_type = .bottom,
        .align_type = .middle,
    });
    try b.text(
        "Q",
        .{},
        .{
            .atlas = atlas,
            .pos = q_pos.add(.{ .x = metrics.advance_width * 3, .y = 0 }),
            .ypos_type = .middle,
        },
    );
    try b.text("middle", .{}, .{
        .pos = q_pos.add(.{ .x = metrics.advance_width * 3.5, .y = -65 }),
        .atlas = try font.DebugFont.getAtlas(ctx, 16),
        .tint_color = .purple,
        .ypos_type = .bottom,
        .align_type = .middle,
    });
    try b.line(
        q_pos.sub(.{ .x = metrics.advance_width, .y = 0 }),
        q_pos.add(.{ .x = metrics.advance_width * 5, .y = 0 }),
        .purple,
        .{ .thickness = 2.0 },
    );
    try b.text("Y-POSITION", .{}, .{
        .pos = q_pos.add(.{ .x = metrics.advance_width * 5, .y = -5 }),
        .atlas = try font.DebugFont.getAtlas(ctx, 16),
        .tint_color = .purple,
        .ypos_type = .bottom,
    });
}

pub fn quit(ctx: jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});
    batchpool.deinit();
    saved_atlas.destroy();
}
