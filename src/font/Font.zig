const std = @import("std");
const assert = std.debug.assert;
const Atlas = @import("Atlas.zig");
const jok = @import("../jok.zig");
const physfs = jok.physfs;
const truetype = jok.stb.truetype;
const codepoint_ranges = @import("codepoint_ranges.zig");
const log = std.log.scoped(.jok);
const Font = @This();

pub const Error = error{
    NoEnoughSpace,
};

// Accept 20M font file at most
const max_font_size = 20 * (1 << 20);

// Memory allocator
allocator: std.mem.Allocator,

// Font file's data
font_data: ?[]const u8,

// Internal font information
font_info: truetype.stbtt_fontinfo,

/// Create Font instance with truetype file
pub fn create(ctx: jok.Context, path: [*:0]const u8) !*Font {
    const allocator = ctx.allocator();
    var self = try allocator.create(Font);
    self.allocator = allocator;
    errdefer allocator.destroy(self);

    if (ctx.cfg().jok_enable_physfs) {
        const handle = try physfs.open(path, .read);
        defer handle.close();

        self.font_data = try handle.readAllAlloc(allocator);
    } else {
        self.font_data = try std.fs.cwd().readFileAlloc(
            std.mem.sliceTo(path, 0),
            allocator,
            .limited(1 << 30),
        );
    }

    // Extract font info
    const rc = truetype.stbtt_InitFont(
        &self.font_info,
        self.font_data.?.ptr,
        truetype.stbtt_GetFontOffsetForIndex(self.font_data.?.ptr, 0),
    );
    assert(rc > 0);

    return self;
}

/// Create Font instance with truetype data
/// WARNING: font data must be valid as long as Font instance
pub fn fromTrueTypeData(allocator: std.mem.Allocator, data: []const u8) !*Font {
    var self = try allocator.create(Font);
    self.allocator = allocator;
    self.font_data = null;

    // Extract font info
    const rc = truetype.stbtt_InitFont(
        &self.font_info,
        data.ptr,
        truetype.stbtt_GetFontOffsetForIndex(data.ptr, 0),
    );
    assert(rc > 0);

    return self;
}

pub fn destroy(self: *Font) void {
    if (self.font_data) |data| {
        self.allocator.free(data);
    }
    self.allocator.destroy(self);
}

pub const AtlasOption = struct {
    size: jok.Size = .{ .width = 2048, .height = 2048 },
    keep_pixels: bool = false,
};
pub fn createAtlas(
    self: Font,
    ctx: jok.Context,
    font_size: u32,
    _cp_ranges: ?[]const [2]u32,
    opt: AtlasOption,
) !*Atlas {
    const cp_ranges = _cp_ranges orelse &codepoint_ranges.default;
    assert(cp_ranges.len > 0);

    const allocator = ctx.allocator();
    const stb_pixels = try allocator.alloc(u8, opt.size.area());
    defer allocator.free(stb_pixels);
    var ranges = try allocator.alloc(Atlas.CharRange, cp_ranges.len);
    @memset(ranges, Atlas.CharRange{
        .codepoint_begin = 0,
        .codepoint_end = 0,
        .packedchar = &.{},
    });
    errdefer {
        for (ranges) |r| {
            if (r.packedchar.len > 0) {
                allocator.free(r.packedchar);
            }
        }
        allocator.free(ranges);
    }

    // Generate atlas
    {
        var pack_ctx = std.mem.zeroes(truetype.stbtt_pack_context);
        const rc = truetype.stbtt_PackBegin(
            &pack_ctx,
            stb_pixels.ptr,
            @intCast(opt.size.width),
            @intCast(opt.size.height),
            0,
            1,
            null,
        );
        assert(rc > 0);
        defer truetype.stbtt_PackEnd(&pack_ctx);

        for (cp_ranges, 0..) |cs, i| {
            assert(cs[1] >= cs[0]);
            const chars_num = cs[1] - cs[0] + 1;
            ranges[i] = .{
                .codepoint_begin = cs[0],
                .codepoint_end = cs[1],
                .packedchar = try allocator.alloc(
                    truetype.stbtt_packedchar,
                    chars_num,
                ),
            };
            if (truetype.stbtt_PackFontRange(
                &pack_ctx,
                self.font_info.data,
                0,
                @floatFromInt(font_size),
                @intCast(cs[0]),
                @intCast(chars_num),
                ranges[i].packedchar.ptr,
            ) == 0) {
                log.err("Create atlas failed, need more space to pack pixels!", .{});
                return error.NoEnoughSpace;
            }
        }
    }

    // Create texture
    const real_pixels = try allocator.alloc(u8, opt.size.area() * 4);
    defer if (!opt.keep_pixels) allocator.free(real_pixels);
    errdefer if (opt.keep_pixels) allocator.free(real_pixels);
    for (stb_pixels, 0..) |px, i| {
        real_pixels[i * 4] = px;
        real_pixels[i * 4 + 1] = px;
        real_pixels[i * 4 + 2] = px;
        real_pixels[i * 4 + 3] = px;
    }
    const tex = try ctx.renderer().createTexture(
        opt.size,
        real_pixels,
        .{ .access = .static },
    );
    errdefer tex.destroy();

    // Get kerning pairs (only consider basic Latin)
    var kerning_table = std.AutoHashMap(u64, f32).init(allocator);
    errdefer kerning_table.deinit();
    for (0..0x7f) |cp1| {
        for (0..0x7f) |cp2| {
            if (cp1 == cp2) continue;
            const v = self.getKerningInPixels(@floatFromInt(font_size), @intCast(cp1), @intCast(cp2));
            if (v != 0) {
                const k = @as(u64, cp1) << 32 | cp2;
                try kerning_table.put(k, v);
            }
        }
    }

    const vmetrics = self.getVMetrics(font_size);
    const atlas = try allocator.create(Atlas);
    atlas.* = .{
        .allocator = allocator,
        .tex = tex,
        .pixels = if (opt.keep_pixels) real_pixels else null,
        .ranges = ranges,
        .vmetric_ascent = vmetrics.ascent,
        .vmetric_descent = vmetrics.descent,
        .vmetric_line_gap = vmetrics.line_gap,
        .kerning_table = kerning_table,
        .codepoint_search = std.AutoHashMap(u32, u32).init(allocator),
    };
    return atlas;
}

pub fn getKerningInPixels(self: Font, font_size: f32, cp1: u32, cp2: u32) f32 {
    const kern_scale = truetype.stbtt_ScaleForPixelHeight(&self.font_info, font_size);
    return @as(f32, @floatFromInt(
        truetype.stbtt_GetCodepointKernAdvance(&self.font_info, @intCast(cp1), @intCast(cp2)),
    )) * kern_scale;
}

pub fn getVMetrics(self: Font, font_size: u32) struct {
    ascent: f32,
    descent: f32,
    line_gap: f32,
} {
    const scale = truetype.stbtt_ScaleForPixelHeight(&self.font_info, @floatFromInt(font_size));
    var ascent: c_int = undefined;
    var descent: c_int = undefined;
    var line_gap: c_int = undefined;
    truetype.stbtt_GetFontVMetrics(
        &self.font_info,
        &ascent,
        &descent,
        &line_gap,
    );
    return .{
        .ascent = @as(f32, @floatFromInt(ascent)) * scale,
        .descent = @as(f32, @floatFromInt(descent)) * scale,
        .line_gap = @as(f32, @floatFromInt(line_gap)) * scale,
    };
}

pub fn findGlyphIndex(self: Font, cp: u32) ?u32 {
    const idx = truetype.stbtt_FindGlyphIndex(&self.font_info, @intCast(cp));
    return if (idx == 0) null else @intCast(idx);
}

pub const GlyphMetrics = struct {
    // For detailed description of font metrics, read follwing page:
    // https://freetype.org/freetype2/docs/glyphs/glyphs-3.html
    //
    //      y         -------------------------------     .--- Top-right of bbox
    //     ^           ^                                 /
    //     |           |     @@@@@@@@@@@@@@@@@@@@@@@@@@@@
    //    -+----> x    |     @    =#@@%**+==+**%@@#=    @
    //     |           |     @  -*@@@*-        -*%@@#:  @
    //                 |     @ .%@@%*            +%@@@= @
    //                 |     @:@@@@%:            :#@@@%+@<------- Bounding-Box
    //                 |     @@@@@%+              =@@@@#@
    //              Ascent   @@@@@%-              -@@@@%@
    //                 |     @@@@@%:              :@@@@@@
    //                 |     @@@@@%:              -@@@@@@
    //      Leftside --+--.  @@@@@%-     ...      -@@@@%@    |
    //      bearing    |  |  @%@@@%=  =*%@@@@**.  =@@@@#@    |
    //                 |  v  @-@@@@#:+@%+. .+%@%=:#@@@%=@    |
    //                 |<--->@ :#@@@=%@:     :%@#+@@@%= @    |
    //                 |     @  :*@@@@%:      *@@@@@+:  @    |
    //                 v     @    =*@@@%+.  .-#@@@*-    @    |
    //      Baseline --+-----@---------#@@@@@@%@@@------@----+-----------------
    //                /^     @                 %@@@=    @    |
    //               / |<-.  @                  @@@@=   @    |
    //              /  v  |  @                   @@@@@  @    |
    //             /  ----+--@@@@@@@@@@@@@@@@@@@@@@@@@@@@    |
    //            /    |  |   \                              |
    //   origin__/     |<-+----*---------------------------->|
    //                 |  |     \         ^                  |
    //                    |      \        |
    //                    |       \       `---------- Advance width
    //                    |        \
    //                   Descent    `---- Bottom-left of bbox
    //

    // Deepest vertical size, globally same
    ascent: f32,
    descent: f32,

    // Total width of glyph (including white space)
    advance_width: f32,

    // Where glyph begin to show on X-axis
    leftside_bearing: f32,

    // Bounding box (relative to origin)
    bottom_left: jok.Point,
    top_right: jok.Point,

    /// Get space occupied by glyph (including blank space)
    pub inline fn getSpace(metrics: GlyphMetrics, pos: jok.Point, ypos_type: Atlas.YPosType) jok.Rectangle {
        const height = metrics.ascent - metrics.descent;
        return switch (ypos_type) {
            .baseline => .{
                .x = pos.x,
                .y = pos.y - metrics.ascent,
                .width = metrics.advance_width,
                .height = height,
            },
            .top => .{
                .x = pos.x,
                .y = pos.y,
                .width = metrics.advance_width,
                .height = height,
            },
            .bottom => .{
                .x = pos.x,
                .y = pos.y - (metrics.ascent - metrics.descent),
                .width = metrics.advance_width,
                .height = height,
            },
            .middle => .{
                .x = pos.x,
                .y = pos.y - (metrics.ascent - metrics.descent) / 2,
                .width = metrics.advance_width,
                .height = height,
            },
        };
    }

    /// Get space occupied by glyph
    pub inline fn getBBox(metrics: GlyphMetrics, pos: jok.Point, ypos_type: Atlas.YPosType) jok.Rectangle {
        const width = metrics.top_right.x - metrics.bottom_left.x;
        const height = metrics.top_right.y - metrics.bottom_left.y;
        return switch (ypos_type) {
            .baseline => .{
                .x = pos.x + metrics.leftside_bearing,
                .y = pos.y - metrics.top_right.y,
                .width = width,
                .height = height,
            },
            .top => .{
                .x = pos.x + metrics.leftside_bearing,
                .y = pos.y + metrics.ascent - metrics.top_right.y,
                .width = width,
                .height = height,
            },
            .bottom => .{
                .x = pos.x + metrics.leftside_bearing,
                .y = pos.y + metrics.descent - metrics.top_right.y,
                .width = width,
                .height = height,
            },
            .middle => .{
                .x = pos.x + metrics.leftside_bearing,
                .y = pos.y - (metrics.ascent - metrics.descent) / 2 + metrics.ascent - metrics.top_right.y,
                .width = width,
                .height = height,
            },
        };
    }
};

pub fn getGlyphMetrics(self: Font, glyph_index: u32, font_size: u32) GlyphMetrics {
    const vmetrics = self.getVMetrics(font_size);
    const scale = truetype.stbtt_ScaleForPixelHeight(&self.font_info, @floatFromInt(font_size));
    var advance_width: c_int = undefined;
    var leftside_bearing: c_int = undefined;
    truetype.stbtt_GetGlyphHMetrics(
        &self.font_info,
        @intCast(glyph_index),
        &advance_width,
        &leftside_bearing,
    );

    var x0: c_int = undefined;
    var y0: c_int = undefined;
    var x1: c_int = undefined;
    var y1: c_int = undefined;
    _ = truetype.stbtt_GetGlyphBox(
        &self.font_info,
        @intCast(glyph_index),
        &x0,
        &y0,
        &x1,
        &y1,
    );
    return .{
        .ascent = vmetrics.ascent,
        .descent = vmetrics.descent,
        .advance_width = @as(f32, @floatFromInt(advance_width)) * scale,
        .leftside_bearing = @as(f32, @floatFromInt(leftside_bearing)) * scale,
        .bottom_left = .{
            .x = @as(f32, @floatFromInt(x0)) * scale,
            .y = @as(f32, @floatFromInt(y0)) * scale,
        },
        .top_right = .{
            .x = @as(f32, @floatFromInt(x1)) * scale,
            .y = @as(f32, @floatFromInt(y1)) * scale,
        },
    };
}

pub const GlyphBitmap = struct {
    allocator: std.mem.Allocator,
    bitmap: []u8,
    width: u32,
    height: u32,

    pub fn destroy(map: GlyphBitmap) void {
        map.allocator.free(map.bitmap);
    }

    pub inline fn getValue(map: GlyphBitmap, x: u32, y: u32) u8 {
        assert(x < map.width);
        assert(y < map.height);
        return map.bitmap[y * map.width + x];
    }
};

pub fn createGlyphBitmap(self: Font, allocator: std.mem.Allocator, glyph_index: u32, font_size: u32) !GlyphBitmap {
    const scale = truetype.stbtt_ScaleForPixelHeight(&self.font_info, @floatFromInt(font_size));
    var x0: c_int = undefined;
    var y0: c_int = undefined;
    var x1: c_int = undefined;
    var y1: c_int = undefined;
    _ = truetype.stbtt_GetGlyphBitmapBox(
        &self.font_info,
        @intCast(glyph_index),
        scale,
        scale,
        &x0,
        &y0,
        &x1,
        &y1,
    );
    const width = x1 - x0;
    const height = y1 - y0;
    const bitmap = try allocator.alloc(u8, @intCast(width * height));
    @memset(bitmap, 0);
    _ = truetype.stbtt_MakeGlyphBitmap(
        &self.font_info,
        bitmap.ptr,
        width,
        height,
        width,
        scale,
        scale,
        @intCast(glyph_index),
    );
    return .{
        .allocator = allocator,
        .bitmap = bitmap,
        .width = @intCast(width),
        .height = @intCast(height),
    };
}
