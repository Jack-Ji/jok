const std = @import("std");
const assert = std.debug.assert;
const unicode = std.unicode;
const jok = @import("../jok.zig");
const truetype = jok.stb.truetype;
const Sprite = jok.j2d.Sprite;
const Atlas = @This();

pub const CharRange = struct {
    codepoint_begin: u32,
    codepoint_end: u32,
    packedchar: std.ArrayList(truetype.stbtt_packedchar),
};

allocator: std.mem.Allocator,
tex: jok.Texture,
ranges: std.ArrayList(CharRange),
codepoint_search: std.AutoHashMap(u32, u8),
scale: f32,
vmetric_ascent: f32,
vmetric_descent: f32,
vmetric_line_gap: f32,

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
    _pos: jok.Point,
    ypos_type: YPosType,
    box_type: BoxType,
) !jok.Rectangle {
    const yoffset = switch (ypos_type) {
        .baseline => -self.vmetric_ascent * self.scale,
        .top => 0,
        .bottom => (self.vmetric_descent - self.vmetric_ascent) * self.scale,
    };
    var pos = _pos;
    var rect = jok.Rectangle{
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
        const codepoint = @as(u32, @intCast(try unicode.utf8Decode(text[i .. i + size])));
        if (self.getVerticesOfCodePoint(pos, ypos_type, jok.Color.white, codepoint)) |cs| {
            switch (box_type) {
                .aligned => {
                    rect.width = cs.next_x - rect.x;
                },
                .drawed => {
                    if (cs.vs[0].pos.y < rect.y) rect.y = cs.vs[0].pos.y;
                    if (cs.vs[3].pos.y - rect.y > rect.height) rect.height = cs.vs[3].pos.y - rect.y;
                    rect.width = cs.vs[1].pos.x - rect.x;
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
    _pos: jok.Point,
    ypos_type: YPosType,
    box_type: BoxType,
    color: jok.Color,
    vattrib: *std.ArrayList(jok.Vertex),
    vindices: *std.ArrayList(u32),
) !jok.Rectangle {
    const yoffset = switch (ypos_type) {
        .baseline => -self.vmetric_ascent * self.scale,
        .top => 0,
        .bottom => (self.vmetric_descent - self.vmetric_ascent) * self.scale,
    };
    var pos = _pos;
    var rect = jok.Rectangle{
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
        const codepoint = @as(u32, @intCast(try unicode.utf8Decode(text[i .. i + size])));
        if (self.getVerticesOfCodePoint(pos, ypos_type, color, codepoint)) |cs| {
            const base_index = @as(u32, @intCast(vattrib.items.len));
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
                    if (cs.vs[0].pos.y < rect.y) rect.y = cs.vs[0].pos.y;
                    if (cs.vs[3].pos.y - rect.y > rect.height) rect.height = cs.vs[3].pos.y - rect.y;
                    rect.width = cs.vs[1].pos.x - rect.x;
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
    pos: jok.Point,
    ypos_type: YPosType,
    color: jok.Color,
    codepoint: u32,
) ?struct { vs: [4]jok.Vertex, next_x: f32 } {
    var xpos = pos.x;
    var ypos = pos.y;
    const pxpos = &xpos;
    const pypos = &ypos;

    const idx = self.codepoint_search.get(codepoint) orelse BLK: {
        for (self.ranges.items, 0..) |range, idx| {
            if (codepoint < range.codepoint_begin or codepoint > range.codepoint_end) continue;
            self.codepoint_search.put(codepoint, @intCast(idx)) catch unreachable;
            break :BLK @as(u8, @intCast(idx));
        } else {
            return null;
        }
    };
    const range = self.ranges.items[idx];
    var quad: truetype.stbtt_aligned_quad = undefined;
    const info = self.tex.query() catch unreachable;
    truetype.stbtt_GetPackedQuad(
        range.packedchar.items.ptr,
        @intCast(info.width),
        @intCast(info.height),
        @intCast(codepoint - range.codepoint_begin),
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
        .vs = [_]jok.Vertex{
            .{
                .pos = .{ .x = quad.x0, .y = quad.y0 + yoffset },
                .color = color,
                .texcoord = .{ .x = quad.s0, .y = quad.t0 },
            },
            .{
                .pos = .{ .x = quad.x1, .y = quad.y0 + yoffset },
                .color = color,
                .texcoord = .{ .x = quad.s1, .y = quad.t0 },
            },
            .{
                .pos = .{ .x = quad.x1, .y = quad.y1 + yoffset },
                .color = color,
                .texcoord = .{ .x = quad.s1, .y = quad.t1 },
            },
            .{
                .pos = .{ .x = quad.x0, .y = quad.y1 + yoffset },
                .color = color,
                .texcoord = .{ .x = quad.s0, .y = quad.t1 },
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
        jok.Color.white,
        codepoint,
    )) |cs| {
        return Sprite{
            .width = cs.vs[1].pos.x - cs.vs[0].pos.x,
            .height = cs.vs[3].pos.y - cs.vs[0].pos.y,
            .uv0 = cs.vs[0].texcoord,
            .uv1 = cs.vs[2].texcoord,
            .tex = self.tex,
        };
    } else {
        return null;
    }
}
