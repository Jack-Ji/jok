const std = @import("std");
const assert = std.debug.assert;
const unicode = std.unicode;
const sdl = @import("sdl");
const jok = @import("../jok.zig");
const truetype = jok.stb.truetype;
const Atlas = @This();

const CharRange = struct {
    codepoint_begin: u32,
    codepoint_end: u32,
    packedchar: std.ArrayList(truetype.stbtt_packedchar),
};

const default_map_size = 8192;

tex: sdl.Texture,
ranges: std.ArrayList(CharRange),
scale: f32,
vmetric_ascent: f32,
vmetric_descent: f32,
vmetric_line_gap: f32,

/// Create font atlas
pub fn init(
    allocator: std.mem.Allocator,
    renderer: sdl.Renderer,
    font_info: *const truetype.stbtt_fontinfo,
    font_size: u32,
    codepoint_ranges: []const [2]u32,
    map_size: ?u32,
) !Atlas {
    assert(codepoint_ranges.len > 0);

    var ranges = try std.ArrayList(CharRange).initCapacity(allocator, codepoint_ranges.len);
    errdefer ranges.deinit();
    const atlas_size = map_size orelse default_map_size;
    const stb_pixels = try allocator.alloc(u8, atlas_size * atlas_size);
    defer allocator.free(stb_pixels);
    const real_pixels = try allocator.alloc(u8, atlas_size * atlas_size * 4);
    defer allocator.free(real_pixels);

    // Generate atlas
    var pack_ctx = std.mem.zeroes(truetype.stbtt_pack_context);
    var rc = truetype.stbtt_PackBegin(
        &pack_ctx,
        stb_pixels.ptr,
        @intCast(c_int, atlas_size),
        @intCast(c_int, atlas_size),
        0,
        1,
        null,
    );
    assert(rc > 0);
    for (codepoint_ranges) |cs, i| {
        assert(cs[1] >= cs[0]);
        ranges.appendAssumeCapacity(
            .{
                .codepoint_begin = cs[0],
                .codepoint_end = cs[1],
                .packedchar = try std.ArrayList(truetype.stbtt_packedchar)
                    .initCapacity(allocator, cs[1] - cs[0] + 1),
            },
        );
        _ = truetype.stbtt_PackFontRange(
            &pack_ctx,
            font_info.data,
            0,
            @intToFloat(f32, font_size),
            @intCast(c_int, cs[0]),
            @intCast(c_int, cs[1] - cs[0] + 1),
            ranges.items[i].packedchar.items.ptr,
        );
    }
    truetype.stbtt_PackEnd(&pack_ctx);
    for (stb_pixels) |px, i| {
        real_pixels[i * 4] = px;
        real_pixels[i * 4 + 1] = px;
        real_pixels[i * 4 + 2] = px;
        real_pixels[i * 4 + 3] = px;
    }

    // Create texture
    var tex = try jok.utils.gfx.createTextureFromPixels(
        renderer,
        real_pixels,
        jok.utils.gfx.getFormatByEndian(),
        .static,
        atlas_size,
        atlas_size,
    );
    try tex.setScaleMode(.linear);

    var ascent: c_int = undefined;
    var descent: c_int = undefined;
    var line_gap: c_int = undefined;
    const scale = truetype.stbtt_ScaleForPixelHeight(font_info, @intToFloat(f32, font_size));
    truetype.stbtt_GetFontVMetrics(font_info, &ascent, &descent, &line_gap);

    return Atlas{
        .tex = tex,
        .ranges = ranges,
        .scale = scale,
        .vmetric_ascent = @intToFloat(f32, ascent),
        .vmetric_descent = @intToFloat(f32, descent),
        .vmetric_line_gap = @intToFloat(f32, line_gap),
    };
}

pub fn deinit(self: *Atlas) void {
    self.tex.destroy();
    for (self.ranges.items) |r| {
        r.packedchar.deinit();
    }
    self.ranges.deinit();
}

/// Calculate next line's y coordinate
pub fn getVPosOfNextLine(self: Atlas, current_ypos: f32) f32 {
    return current_ypos + @round((self.vmetric_ascent - self.vmetric_descent + self.vmetric_line_gap) * self.scale);
}

/// Position type of y axis (determine where text will be aligned to vertically)
pub const YPosType = enum { baseline, top, bottom };

/// Get bounds (width and height)  of text
pub fn getRectangle(
    self: Atlas,
    text: []const u8,
    _pos: sdl.PointF,
    ypos_type: YPosType,
) !sdl.RectangleF {
    var pos = _pos;
    var rect = sdl.RectangleF{
        .x = pos.x,
        .y = std.math.floatMax(f32),
        .width = 0,
        .height = 0,
    };

    if (text.len == 0) return rect;

    var i: u32 = 0;
    while (i < text.len) {
        const size = try unicode.utf8ByteSequenceLength(text[i]);
        const codepoint = @intCast(u32, try unicode.utf8Decode(text[i .. i + size]));
        if (self.getVerticesOfCodePoint(pos, ypos_type, sdl.Color.white, codepoint)) |cs| {
            if (cs.vs[0].position.y < rect.y) rect.y = cs.vs[0].position.y;
            if (cs.vs[3].position.y - rect.y > rect.height) rect.height = cs.vs[3].position.y - rect.y;
            pos.x = cs.next_x;
        }
        i += size;
    }

    rect.width = pos.x - rect.x;
    return rect;
}

/// Append draw data for rendering utf8 string, return drawing area
pub fn appendDrawDataFromUTF8String(
    self: Atlas,
    text: []const u8,
    _pos: sdl.PointF,
    ypos_type: YPosType,
    color: sdl.Color,
    vattrib: *std.ArrayList(sdl.Vertex),
    vindices: *std.ArrayList(u32),
) !sdl.RectangleF {
    var pos = _pos;
    var rect = sdl.RectangleF{
        .x = pos.x,
        .y = std.math.floatMax(f32),
        .width = 0,
        .height = 0,
    };

    if (text.len == 0) return rect;

    var i: u32 = 0;
    while (i < text.len) {
        const size = try unicode.utf8ByteSequenceLength(text[i]);
        const codepoint = @intCast(u32, try unicode.utf8Decode(text[i .. i + size]));
        if (self.getVerticesOfCodePoint(pos, ypos_type, color, codepoint)) |cs| {
            const base_index = @intCast(u32, vattrib.items.len);
            try vattrib.appendSlice(&cs.vs);
            try vindices.appendSlice(&[_]u32{
                base_index,
                base_index + 1,
                base_index + 2,
                base_index,
                base_index + 2,
                base_index + 3,
            });
            if (cs.vs[0].position.y < rect.y) rect.y = cs.vs[0].position.y;
            if (cs.vs[3].position.y - rect.y > rect.height) rect.height = cs.vs[3].position.y - rect.y;
            pos.x = cs.next_x;
        }
        i += size;
    }

    rect.width = pos.x - rect.x;
    return rect;
}

/// Search coordinates of codepoint (in the order of left-top/right-top/right-bottom/left-bottom)
pub inline fn getVerticesOfCodePoint(
    self: Atlas,
    pos: sdl.PointF,
    ypos_type: YPosType,
    color: sdl.Color,
    codepoint: u32,
) ?struct { vs: [4]sdl.Vertex, next_x: f32 } {
    var xpos = pos.x;
    var ypos = pos.y;
    var pxpos = &xpos;
    var pypos = &ypos;

    // TODO: use simple loop searching for now, may need optimization
    for (self.ranges.items) |range| {
        if (codepoint < range.codepoint_begin or codepoint > range.codepoint_end) continue;

        var quad: truetype.stbtt_aligned_quad = undefined;
        const info = self.tex.query() catch unreachable;
        truetype.stbtt_GetPackedQuad(
            range.packedchar.items.ptr,
            @intCast(c_int, info.width),
            @intCast(c_int, info.height),
            @intCast(c_int, codepoint - range.codepoint_begin),
            pxpos,
            pypos,
            &quad,
            0,
        );
        const yoffset = switch (ypos_type) {
            .baseline => 0,
            .top => self.vmetric_ascent * self.scale,
            .bottom => self.vmetric_descent * self.scale,
        };
        return .{
            .vs = [_]sdl.Vertex{
                .{
                    .position = .{ .x = quad.x0, .y = quad.y0 + yoffset },
                    .color = color,
                    .tex_coord = .{ .x = quad.s0, .y = quad.t0 },
                },
                .{
                    .position = .{ .x = quad.x1, .y = quad.y0 + yoffset },
                    .color = color,
                    .tex_coord = .{ .x = quad.s1, .y = quad.t0 },
                },
                .{
                    .position = .{ .x = quad.x1, .y = quad.y1 + yoffset },
                    .color = color,
                    .tex_coord = .{ .x = quad.s1, .y = quad.t1 },
                },
                .{
                    .position = .{ .x = quad.x0, .y = quad.y1 + yoffset },
                    .color = color,
                    .tex_coord = .{ .x = quad.s0, .y = quad.t1 },
                },
            },
            .next_x = xpos,
        };
    } else {
        return null;
    }
}
