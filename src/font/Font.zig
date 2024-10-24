const std = @import("std");
const assert = std.debug.assert;
const Atlas = @import("Atlas.zig");
const jok = @import("../jok.zig");
const physfs = jok.physfs;
const truetype = jok.stb.truetype;
const codepoint_ranges = @import("codepoint_ranges.zig");
const Font = @This();

// Accept 20M font file at most
const max_font_size = 20 * (1 << 20);

// Default atlas size
const default_atlas_size = 1024;

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
        self.font_data = try std.fs.cwd().readFileAlloc(allocator, std.mem.sliceTo(path, 0), 1 << 30);
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

pub fn createAtlas(
    self: Font,
    ctx: jok.Context,
    font_size: u32,
    _cp_ranges: ?[]const [2]u32,
    size: ?u32,
) !*Atlas {
    const cp_ranges = _cp_ranges orelse &codepoint_ranges.default;
    assert(cp_ranges.len > 0);

    var ranges = try std.ArrayList(Atlas.CharRange).initCapacity(ctx.allocator(), cp_ranges.len);
    errdefer ranges.deinit();
    const atlas_size = size orelse default_atlas_size;
    const stb_pixels = try ctx.allocator().alloc(u8, atlas_size * atlas_size);
    defer ctx.allocator().free(stb_pixels);
    const real_pixels = try ctx.allocator().alloc(u8, atlas_size * atlas_size * 4);
    defer ctx.allocator().free(real_pixels);

    // Generate atlas
    var pack_ctx = std.mem.zeroes(truetype.stbtt_pack_context);
    const rc = truetype.stbtt_PackBegin(
        &pack_ctx,
        stb_pixels.ptr,
        @intCast(atlas_size),
        @intCast(atlas_size),
        0,
        1,
        null,
    );
    assert(rc > 0);
    for (cp_ranges, 0..) |cs, i| {
        assert(cs[1] >= cs[0]);
        ranges.appendAssumeCapacity(
            .{
                .codepoint_begin = cs[0],
                .codepoint_end = cs[1],
                .packedchar = try std.ArrayList(truetype.stbtt_packedchar)
                    .initCapacity(ctx.allocator(), cs[1] - cs[0] + 1),
            },
        );
        _ = truetype.stbtt_PackFontRange(
            &pack_ctx,
            self.font_info.data,
            0,
            @floatFromInt(font_size),
            @intCast(cs[0]),
            @intCast(cs[1] - cs[0] + 1),
            ranges.items[i].packedchar.items.ptr,
        );
    }
    truetype.stbtt_PackEnd(&pack_ctx);
    for (stb_pixels, 0..) |px, i| {
        real_pixels[i * 4] = px;
        real_pixels[i * 4 + 1] = px;
        real_pixels[i * 4 + 2] = px;
        real_pixels[i * 4 + 3] = px;
    }

    // Create texture
    const tex = try ctx.renderer().createTexture(
        .{ .width = atlas_size, .height = atlas_size },
        real_pixels,
        .{ .access = .static },
    );
    errdefer tex.destroy();

    const scale = self.getScale(font_size);
    const vmetrics = self.getVMetrics();
    const atlas = try ctx.allocator().create(Atlas);
    atlas.* = .{
        .allocator = ctx.allocator(),
        .tex = tex,
        .ranges = ranges,
        .codepoint_search = std.AutoHashMap(u32, u8).init(ctx.allocator()),
        .scale = scale,
        .vmetric_ascent = vmetrics.ascent,
        .vmetric_descent = vmetrics.descent,
        .vmetric_line_gap = vmetrics.line_gap,
    };
    return atlas;
}

pub fn findGlyphIndex(self: Font, cp: u32) ?u32 {
    const idx = truetype.stbtt_FindGlyphIndex(&self.font_info, @intCast(cp));
    return if (idx == 0) null else @intCast(idx);
}

pub fn getScale(self: Font, font_size: u32) f32 {
    return truetype.stbtt_ScaleForPixelHeight(&self.font_info, @floatFromInt(font_size));
}

pub fn getVMetrics(self: Font) struct {
    ascent: f32,
    descent: f32,
    line_gap: f32,
} {
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
        .ascent = @floatFromInt(ascent),
        .descent = @floatFromInt(descent),
        .line_gap = @floatFromInt(line_gap),
    };
}

pub fn getGlyphHMetrics(self: Font, glyph_index: u32) struct {
    advance_width: f32,
    left_side_bearing: f32,
} {
    var advance_width: c_int = undefined;
    var left_side_bearing: c_int = undefined;
    truetype.stbtt_GetGlyphHMetrics(
        &self.font_info,
        @intCast(glyph_index),
        &advance_width,
        &left_side_bearing,
    );
    return .{
        .advance_width = @floatFromInt(advance_width),
        .left_side_bearing = @floatFromInt(left_side_bearing),
    };
}

pub fn getGlyphBox(self: Font, glyph_index: u32) jok.Rectangle {
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
        .x = @floatFromInt(x0),
        .y = @floatFromInt(y0),
        .width = @floatFromInt(x1 - x0 + 1),
        .height = @floatFromInt(y1 - y0 + 1),
    };
}

pub fn getGlyphBitmap(self: Font, allocator: std.mem.Allocator, glyph_index: u32, scale_x: f32, scale_y: f32) !struct {
    allocator: std.mem.Allocator,
    bitmap: []u8,
    width: u32,
    height: u32,

    pub fn destroy(map: @This()) void {
        map.allocator.free(self.bitmap);
    }
} {
    var x0: c_int = undefined;
    var y0: c_int = undefined;
    var x1: c_int = undefined;
    var y1: c_int = undefined;
    _ = truetype.stbtt_GetGlyphBitmapBox(
        &self.font_info,
        @intCast(glyph_index),
        scale_x,
        scale_y,
        &x0,
        &y0,
        &x1,
        &y1,
    );

    const width: u32 = @intCast(x1 - x0);
    const height: u32 = @intCast(y1 - y0);
    const bitmap = try allocator.alloc(u8, width * height);
    _ = truetype.stbtt_MakeGlyphBitmap(
        &self.font_info,
        bitmap.ptr,
        @intCast(width),
        @intCast(height),
        @intCast(width),
        scale_x,
        scale_y,
        @intCast(glyph_index),
    );
    return .{
        .allocator = allocator,
        .bitmap = bitmap,
        .width = width,
        .height = height,
    };
}
