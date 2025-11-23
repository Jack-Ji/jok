const std = @import("std");
const builtin = @import("builtin");
const jok = @import("jok");
const font = jok.font;
const j2d = jok.j2d;
const physfs = jok.vendor.physfs;

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
        30,
        &font.codepoint_ranges.chinese_full,
        .{ .keep_pixels = true },
    );

    var thread = std.Io.Threaded.init_single_threaded;
    const io = thread.ioBasic();
    var t = try std.Io.Clock.awake.now(io);
    try atlas.save(ctx, "atlas.png", .{});
    std.debug.print("Atlas save time: {D}\n", .{
        @as(i64, @intCast(t.durationTo(try std.Io.Clock.awake.now(io)).nanoseconds)),
    });
    atlas.destroy();
    t = try std.Io.Clock.awake.now(io);
    saved_atlas = try font.Atlas.loadFromPath(ctx, "atlas.png");
    std.debug.print("Atlas load time: {D}\n", .{
        @as(i64, @intCast(t.durationTo(try std.Io.Clock.awake.now(io)).nanoseconds)),
    });
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

    // Left-Aligned text
    var atlas = try font.DebugFont.getAtlas(ctx, 20);
    var pos = jok.Point{ .x = 20, .y = 20 };
    var area = try atlas.getBoundingBox(
        "Left Aligned Text",
        pos,
        .{
            .align_type = .left,
        },
    );
    try b.rectFilled(area, rect_color, .{});
    try b.text(
        "Left Aligned Text",
        .{},
        .{
            .atlas = atlas,
            .pos = pos,
            .align_type = .left,
        },
    );
    pos.y = atlas.getVPosOfNextLine(pos.y) + 10;
    area = try atlas.getBoundingBox(
        "Left Aligned Text with width",
        pos,
        .{
            .align_type = .left,
            .align_width = 120,
        },
    );
    try b.rectFilled(area, rect_color, .{});
    try b.text(
        "Left Aligned Text with width",
        .{},
        .{
            .atlas = atlas,
            .pos = pos,
            .align_type = .left,
            .align_width = 120,
        },
    );
    try b.line(
        pos.sub(.{ 0, 40 }),
        pos.add(.{ 0, 70 }),
        .purple,
        .{},
    );

    // Right-Aligned text
    pos = .{ .x = size.getWidthFloat() - 50, .y = 30 };
    area = try saved_atlas.getBoundingBox(
        "Right Aligned Text",
        pos,
        .{
            .align_type = .right,
        },
    );
    try b.rectFilled(area, rect_color, .{});
    try b.text(
        "Right Aligned Text",
        .{},
        .{
            .atlas = saved_atlas,
            .pos = pos,
            .align_type = .right,
            .ignore_unexist = false,
        },
    );
    pos.y = saved_atlas.getVPosOfNextLine(pos.y) + 10;
    area = try saved_atlas.getBoundingBox(
        "Right Aligned Text with width",
        pos,
        .{
            .align_type = .right,
            .align_width = 150,
        },
    );
    try b.rectFilled(area, rect_color, .{});
    try b.text(
        "Right Aligned Text with width",
        .{},
        .{
            .atlas = saved_atlas,
            .pos = pos,
            .align_type = .right,
            .align_width = 150,
        },
    );
    try b.line(
        pos.sub(.{ 0, 50 }),
        pos.add(.{ 0, 130 }),
        .purple,
        .{},
    );

    // Middle-Aligned text
    pos = .{ .x = 380, .y = 150 };
    area = try saved_atlas.getBoundingBox(
        "Middle Aligned Text",
        pos,
        .{
            .align_type = .middle,
        },
    );
    try b.rectFilled(area, rect_color, .{});
    try b.text(
        "Middle Aligned Text",
        .{},
        .{
            .atlas = saved_atlas,
            .pos = pos,
            .align_type = .middle,
        },
    );
    pos.y = saved_atlas.getVPosOfNextLine(pos.y) + 10;
    area = try saved_atlas.getBoundingBox(
        "Middle Aligned Text with width",
        pos,
        .{
            .align_type = .middle,
            .align_width = 150,
        },
    );
    try b.rectFilled(area, rect_color, .{});
    try b.text(
        "Middle Aligned Text with width",
        .{},
        .{
            .atlas = saved_atlas,
            .pos = pos,
            .align_type = .middle,
            .align_width = 150,
        },
    );
    try b.line(
        pos.sub(.{ 0, 50 }),
        pos.add(.{ 0, 130 }),
        .purple,
        .{},
    );

    // Y-Position showcasing
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
        metrics.getSpace(q_pos.add(.{ metrics.advance_width, 0 }), .top),
        .rgba(200, 0, 0, 128),
        .{},
    );
    try b.rectFilled(
        metrics.getBBox(q_pos.add(.{ metrics.advance_width, 0 }), .top),
        .rgba(0, 200, 0, 200),
        .{},
    );
    try b.rectFilled(
        metrics.getSpace(q_pos.add(.{ metrics.advance_width * 2, 0 }), .bottom),
        .rgba(200, 0, 0, 128),
        .{},
    );
    try b.rectFilled(
        metrics.getBBox(q_pos.add(.{ metrics.advance_width * 2, 0 }), .bottom),
        .rgba(0, 200, 0, 200),
        .{},
    );
    try b.rectFilled(
        metrics.getSpace(q_pos.add(.{ metrics.advance_width * 3, 0 }), .middle),
        .rgba(200, 0, 0, 128),
        .{},
    );
    try b.rectFilled(
        metrics.getBBox(q_pos.add(.{ metrics.advance_width * 3, 0 }), .middle),
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
        .pos = q_pos.add(.{ metrics.advance_width / 2, -105 }),
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
            .pos = q_pos.add(.{ metrics.advance_width, 0 }),
            .ypos_type = .top,
        },
    );
    try b.text("top", .{}, .{
        .pos = q_pos.add(.{ metrics.advance_width * 1.5, -5 }),
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
            .pos = q_pos.add(.{ metrics.advance_width * 2, 0 }),
            .ypos_type = .bottom,
        },
    );
    try b.text("bottom", .{}, .{
        .pos = q_pos.add(.{ metrics.advance_width * 2.5, -130 }),
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
            .pos = q_pos.add(.{ metrics.advance_width * 3, 0 }),
            .ypos_type = .middle,
        },
    );
    try b.text("middle", .{}, .{
        .pos = q_pos.add(.{ metrics.advance_width * 3.5, -65 }),
        .atlas = try font.DebugFont.getAtlas(ctx, 16),
        .tint_color = .purple,
        .ypos_type = .bottom,
        .align_type = .middle,
    });
    try b.line(
        q_pos.sub(.{ metrics.advance_width, 0 }),
        q_pos.add(.{ metrics.advance_width * 5, 0 }),
        .purple,
        .{ .thickness = 2.0 },
    );
    try b.text("Y-POSITION", .{}, .{
        .pos = q_pos.add(.{ metrics.advance_width * 5, -5 }),
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
