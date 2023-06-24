const std = @import("std");
const assert = std.debug.assert;
const unicode = std.unicode;
const jok = @import("../jok.zig");
const sdl = jok.sdl;
const truetype = jok.stb.truetype;
const Sprite = jok.j2d.Sprite;
const codepoint_ranges = @import("codepoint_ranges.zig");
const Atlas = @This();

const CharRange = struct {
    codepoint_begin: u32,
    codepoint_end: u32,
    packedchar: std.ArrayList(truetype.stbtt_packedchar),
};

const default_map_size = 2048;

allocator: std.mem.Allocator,
tex: sdl.Texture,
ranges: std.ArrayList(CharRange),
codepoint_search: std.AutoHashMap(u32, u8),
scale: f32,
vmetric_ascent: f32,
vmetric_descent: f32,
vmetric_line_gap: f32,

/// Create font atlas
pub fn create(
    allocator: std.mem.Allocator,
    renderer: sdl.Renderer,
    font_info: *const truetype.stbtt_fontinfo,
    font_size: u32,
    _cp_ranges: ?[]const [2]u32,
    map_size: ?u32,
) !*Atlas {
    const cp_ranges = _cp_ranges orelse &codepoint_ranges.default;
    assert(cp_ranges.len > 0);

    var ranges = try std.ArrayList(CharRange).initCapacity(allocator, cp_ranges.len);
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
    for (cp_ranges, 0..) |cs, i| {
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
            @floatFromInt(f32, font_size),
            @intCast(c_int, cs[0]),
            @intCast(c_int, cs[1] - cs[0] + 1),
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
    const scale = truetype.stbtt_ScaleForPixelHeight(font_info, @floatFromInt(f32, font_size));
    truetype.stbtt_GetFontVMetrics(font_info, &ascent, &descent, &line_gap);

    var atlas = try allocator.create(Atlas);
    atlas.* = .{
        .allocator = allocator,
        .tex = tex,
        .ranges = ranges,
        .codepoint_search = std.AutoHashMap(u32, u8).init(allocator),
        .scale = scale,
        .vmetric_ascent = @floatFromInt(f32, ascent),
        .vmetric_descent = @floatFromInt(f32, descent),
        .vmetric_line_gap = @floatFromInt(f32, line_gap),
    };
    return atlas;
}

pub fn destroy(self: *Atlas) void {
    self.tex.destroy();
    for (self.ranges.items) |r| {
        r.packedchar.deinit();
    }
    self.ranges.deinit();
    self.codepoint_search.deinit();
    self.allocator.destroy(self);
}

/// Calculate next line's y coordinate
pub fn getVPosOfNextLine(self: Atlas, current_ypos: f32) f32 {
    return current_ypos + @round((self.vmetric_ascent - self.vmetric_descent + self.vmetric_line_gap) * self.scale);
}

/// Position type of y axis (determine where text will be aligned to vertically)
pub const YPosType = enum { baseline, top, bottom };

/// Type of text's bounding rectangle
pub const BoxType = enum { aligned, drawed };

/// Get bounding box of text
pub fn getBoundingBox(
    self: *Atlas,
    text: []const u8,
    _pos: sdl.PointF,
    ypos_type: YPosType,
    box_type: BoxType,
) !sdl.RectangleF {
    const yoffset = switch (ypos_type) {
        .baseline => -self.vmetric_ascent * self.scale,
        .top => 0,
        .bottom => (self.vmetric_descent - self.vmetric_ascent) * self.scale,
    };
    var pos = _pos;
    var rect = sdl.RectangleF{
        .x = pos.x,
        .y = switch (box_type) {
            .aligned => pos.y + yoffset,
            .drawed => std.math.floatMax(f32),
        },
        .width = 0,
        .height = switch (box_type) {
            .aligned => @round((self.vmetric_ascent - self.vmetric_descent) * self.scale),
            .drawed => 0,
        },
    };

    if (text.len == 0) return rect;

    var i: u32 = 0;
    while (i < text.len) {
        const size = try unicode.utf8ByteSequenceLength(text[i]);
        const codepoint = @intCast(u32, try unicode.utf8Decode(text[i .. i + size]));
        if (self.getVerticesOfCodePoint(pos, ypos_type, sdl.Color.white, codepoint)) |cs| {
            switch (box_type) {
                .aligned => {
                    rect.width = cs.next_x - rect.x;
                },
                .drawed => {
                    if (cs.vs[0].position.y < rect.y) rect.y = cs.vs[0].position.y;
                    if (cs.vs[3].position.y - rect.y > rect.height) rect.height = cs.vs[3].position.y - rect.y;
                    rect.width = cs.vs[1].position.x - rect.x;
                },
            }
            pos.x = cs.next_x;
        }
        i += size;
    }

    return rect;
}

/// Append draw data for rendering utf8 string, return bounding box
pub fn appendDrawDataFromUTF8String(
    self: *Atlas,
    text: []const u8,
    _pos: sdl.PointF,
    ypos_type: YPosType,
    box_type: BoxType,
    color: sdl.Color,
    vattrib: *std.ArrayList(sdl.Vertex),
    vindices: *std.ArrayList(u32),
) !sdl.RectangleF {
    const yoffset = switch (ypos_type) {
        .baseline => -self.vmetric_ascent * self.scale,
        .top => 0,
        .bottom => (self.vmetric_descent - self.vmetric_ascent) * self.scale,
    };
    var pos = _pos;
    var rect = sdl.RectangleF{
        .x = pos.x,
        .y = switch (box_type) {
            .aligned => pos.y + yoffset,
            .drawed => std.math.floatMax(f32),
        },
        .width = 0,
        .height = switch (box_type) {
            .aligned => @round((self.vmetric_ascent - self.vmetric_descent) * self.scale),
            .drawed => 0,
        },
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
            switch (box_type) {
                .aligned => {
                    rect.width = cs.next_x - rect.x;
                },
                .drawed => {
                    if (cs.vs[0].position.y < rect.y) rect.y = cs.vs[0].position.y;
                    if (cs.vs[3].position.y - rect.y > rect.height) rect.height = cs.vs[3].position.y - rect.y;
                    rect.width = cs.vs[1].position.x - rect.x;
                },
            }
            pos.x = cs.next_x;
        }
        i += size;
    }

    return rect;
}

/// Search coordinates of codepoint (in the order of left-top/right-top/right-bottom/left-bottom)
pub inline fn getVerticesOfCodePoint(
    self: *Atlas,
    pos: sdl.PointF,
    ypos_type: YPosType,
    color: sdl.Color,
    codepoint: u32,
) ?struct { vs: [4]sdl.Vertex, next_x: f32 } {
    var xpos = pos.x;
    var ypos = pos.y;
    var pxpos = &xpos;
    var pypos = &ypos;

    const idx = self.codepoint_search.get(codepoint) orelse BLK: {
        for (self.ranges.items, 0..) |range, idx| {
            if (codepoint < range.codepoint_begin or codepoint > range.codepoint_end) continue;
            self.codepoint_search.put(codepoint, @intCast(u8, idx)) catch unreachable;
            break :BLK @intCast(u8, idx);
        } else {
            return null;
        }
    };
    const range = self.ranges.items[idx];
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
}

/// Get sprite of codepoint
pub fn getSpriteOfCodePoint(self: *Atlas, codepoint: u32) ?Sprite {
    if (self.getVerticesOfCodePoint(
        .{ .x = 0, .y = 0 },
        .top,
        sdl.Color.white,
        codepoint,
    )) |cs| {
        return Sprite{
            .width = cs.vs[1].position.x - cs.vs[0].position.x,
            .height = cs.vs[3].position.y - cs.vs[0].position.y,
            .uv0 = cs.vs[0].tex_coord,
            .uv1 = cs.vs[2].tex_coord,
            .tex = self.tex,
        };
    } else {
        return null;
    }
}
