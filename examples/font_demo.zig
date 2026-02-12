const std = @import("std");
const builtin = @import("builtin");
const jok = @import("jok");
const font = jok.font;
const j2d = jok.j2d;
const geom = j2d.geom;
const physfs = jok.vendor.physfs;

var batchpool: j2d.BatchPool(64, false) = undefined;
var loaded_font: *font.Font = undefined;
var saved_atlas_16: *font.Atlas = undefined;
var saved_atlas_20: *font.Atlas = undefined;
var saved_atlas_30: *font.Atlas = undefined;
var saved_atlas_128: *font.Atlas = undefined;

pub fn init(ctx: jok.Context) !void {
    std.log.info("game init", .{});

    if (!builtin.cpu.arch.isWasm()) {
        try physfs.mount("assets", "", true);
        try physfs.mount(physfs.getBaseDir(), "", true);
    }
    try physfs.setWriteDir(physfs.getBaseDir());

    batchpool = try @TypeOf(batchpool).init(ctx);
    loaded_font = try font.Font.create(ctx, if (ctx.cfg().jok_enable_physfs) "clacon2.ttf" else "assets/clacon2.ttf");

    const font_size = 16;
    const vmetrics = loaded_font.getVMetrics(font_size);
    const height = @as(u32, @intFromFloat(vmetrics.ascent - vmetrics.descent));
    const output = "jok is here!";
    for (0..height) |j| {
        const ypos = @as(f32, @floatFromInt(j));
        var xpos: f32 = 0;
        for (output) |c| {
            const glyph = loaded_font.findGlyphIndex(c).?;
            const map = try loaded_font.createGlyphBitmap(ctx.allocator(), glyph, font_size);
            defer map.destroy();
            const metrics = loaded_font.getGlyphMetrics(glyph, font_size);
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

    saved_atlas_16 = try loaded_font.createAtlas(ctx, 16, null, .{ .keep_pixels = true });
    saved_atlas_20 = try loaded_font.createAtlas(ctx, 20, null, .{ .keep_pixels = true });
    saved_atlas_30 = try loaded_font.createAtlas(ctx, 30, null, .{ .keep_pixels = true });
    saved_atlas_128 = try loaded_font.createAtlas(ctx, 128, null, .{ .keep_pixels = true });

    var t = std.Io.Clock.awake.now(ctx.io());
    try saved_atlas_16.save(ctx, "atlas_16.png", .{});
    try saved_atlas_20.save(ctx, "atlas_20.png", .{});
    try saved_atlas_30.save(ctx, "atlas_30.png", .{});
    try saved_atlas_128.save(ctx, "atlas_128.png", .{});
    std.debug.print("Atlas save time: {D}\n", .{
        @as(i64, @intCast(t.durationTo(std.Io.Clock.awake.now(ctx.io())).nanoseconds)),
    });

    saved_atlas_16.destroy();
    saved_atlas_20.destroy();
    saved_atlas_30.destroy();
    saved_atlas_128.destroy();

    t = std.Io.Clock.awake.now(ctx.io());
    saved_atlas_16 = try font.Atlas.loadFromPath(ctx, "atlas_16.png");
    saved_atlas_20 = try font.Atlas.loadFromPath(ctx, "atlas_20.png");
    saved_atlas_30 = try font.Atlas.loadFromPath(ctx, "atlas_30.png");
    saved_atlas_128 = try font.Atlas.loadFromPath(ctx, "atlas_128.png");
    std.debug.print("Atlas load time: {D}\n", .{
        @as(i64, @intCast(t.durationTo(std.Io.Clock.awake.now(ctx.io())).nanoseconds)),
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
    var pos = geom.Point{ .x = 20, .y = 20 };
    var area = try saved_atlas_20.getBoundingBox(
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
            .atlas = saved_atlas_20,
            .pos = pos,
            .align_type = .left,
        },
    );
    pos.y = saved_atlas_20.getVPosOfNextLine(pos.y) + 10;
    area = try saved_atlas_20.getBoundingBox(
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
            .atlas = saved_atlas_20,
            .pos = pos,
            .align_type = .left,
            .align_width = 120,
        },
    );
    try b.line(
        .{
            .p0 = pos.sub(.{ 0, 40 }),
            .p1 = pos.add(.{ 0, 70 }),
        },
        .purple,
        .{},
    );

    // Right-Aligned text
    pos = .{ .x = size.getWidthFloat() - 50, .y = 30 };
    area = try saved_atlas_30.getBoundingBox(
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
            .atlas = saved_atlas_30,
            .pos = pos,
            .align_type = .right,
            .ignore_unexist = false,
        },
    );
    pos.y = saved_atlas_30.getVPosOfNextLine(pos.y) + 10;
    area = try saved_atlas_30.getBoundingBox(
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
            .atlas = saved_atlas_30,
            .pos = pos,
            .align_type = .right,
            .align_width = 150,
        },
    );
    try b.line(
        .{
            .p0 = pos.sub(.{ 0, 50 }),
            .p1 = pos.add(.{ 0, 130 }),
        },
        .purple,
        .{},
    );

    // Middle-Aligned text
    pos = .{ .x = 380, .y = 150 };
    area = try saved_atlas_30.getBoundingBox(
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
            .atlas = saved_atlas_30,
            .pos = pos,
            .align_type = .middle,
        },
    );
    pos.y = saved_atlas_30.getVPosOfNextLine(pos.y) + 10;
    area = try saved_atlas_30.getBoundingBox(
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
            .atlas = saved_atlas_30,
            .pos = pos,
            .align_type = .middle,
            .align_width = 150,
        },
    );
    try b.line(
        .{
            .p0 = pos.sub(.{ 0, 50 }),
            .p1 = pos.add(.{ 0, 130 }),
        },
        .purple,
        .{},
    );

    // Y-Position showcasing
    const metrics = loaded_font.getGlyphMetrics(
        loaded_font.findGlyphIndex('Q').?,
        128,
    );
    const q_pos = geom.Point{ .x = 100, .y = 450 };
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
            .atlas = saved_atlas_128,
            .pos = q_pos,
            .ypos_type = .baseline,
        },
    );
    try b.text("baseline", .{}, .{
        .pos = q_pos.add(.{ metrics.advance_width / 2, -105 }),
        .atlas = saved_atlas_16,
        .tint_color = .purple,
        .ypos_type = .bottom,
        .align_type = .middle,
    });
    try b.text(
        "Q",
        .{},
        .{
            .atlas = saved_atlas_128,
            .pos = q_pos.add(.{ metrics.advance_width, 0 }),
            .ypos_type = .top,
        },
    );
    try b.text("top", .{}, .{
        .pos = q_pos.add(.{ metrics.advance_width * 1.5, -5 }),
        .atlas = saved_atlas_16,
        .tint_color = .purple,
        .ypos_type = .bottom,
        .align_type = .middle,
    });
    try b.text(
        "Q",
        .{},
        .{
            .atlas = saved_atlas_128,
            .pos = q_pos.add(.{ metrics.advance_width * 2, 0 }),
            .ypos_type = .bottom,
        },
    );
    try b.text("bottom", .{}, .{
        .pos = q_pos.add(.{ metrics.advance_width * 2.5, -130 }),
        .atlas = saved_atlas_16,
        .tint_color = .purple,
        .ypos_type = .bottom,
        .align_type = .middle,
    });
    try b.text(
        "Q",
        .{},
        .{
            .atlas = saved_atlas_128,
            .pos = q_pos.add(.{ metrics.advance_width * 3, 0 }),
            .ypos_type = .middle,
        },
    );
    try b.text("middle", .{}, .{
        .pos = q_pos.add(.{ metrics.advance_width * 3.5, -65 }),
        .atlas = saved_atlas_16,
        .tint_color = .purple,
        .ypos_type = .bottom,
        .align_type = .middle,
    });
    try b.line(
        .{
            .p0 = q_pos.sub(.{ metrics.advance_width, 0 }),
            .p1 = q_pos.add(.{ metrics.advance_width * 5, 0 }),
        },
        .purple,
        .{ .thickness = 2.0 },
    );
    try b.text("Y-POSITION", .{}, .{
        .pos = q_pos.add(.{ metrics.advance_width * 5, -5 }),
        .atlas = saved_atlas_16,
        .tint_color = .purple,
        .ypos_type = .bottom,
    });
}

pub fn quit(ctx: jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});
    batchpool.deinit();
    saved_atlas_16.destroy();
    saved_atlas_20.destroy();
    saved_atlas_30.destroy();
    saved_atlas_128.destroy();
    loaded_font.destroy();
}
