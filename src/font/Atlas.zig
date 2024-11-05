const std = @import("std");
const assert = std.debug.assert;
const unicode = std.unicode;
const json = std.json;
const jok = @import("../jok.zig");
const truetype = jok.stb.truetype;
const Sprite = jok.j2d.Sprite;
const Atlas = @This();

pub const Error = error{
    InvalidFormat,
    NoPixelData,
};

const max_atlas_data_size = 1 << 26;
const magic_atlas_header = [_]u8{ 'a', 't', 'l', 'a', 's', '@', 'j', 'o', 'k' };

pub const CharRange = struct {
    codepoint_begin: u32,
    codepoint_end: u32,
    packedchar: []truetype.stbtt_packedchar,
};

allocator: std.mem.Allocator,
tex: jok.Texture,
pixels: ?[]const u8,
ranges: []CharRange,
vmetric_ascent: f32,
vmetric_descent: f32,
vmetric_line_gap: f32,
codepoint_search: std.AutoHashMap(u32, u32),

pub fn destroy(self: *Atlas) void {
    self.tex.destroy();
    if (self.pixels) |px| self.allocator.free(px);
    for (self.ranges) |r| {
        self.allocator.free(r.packedchar);
    }
    self.allocator.free(self.ranges);
    self.codepoint_search.deinit();
    self.allocator.destroy(self);
}

/// Save atlas as jpng
pub fn save(
    self: Atlas,
    ctx: jok.Context,
    path: [*:0]const u8,
    opt: jok.utils.gfx.jpng.SaveOption,
) !void {
    if (self.pixels == null) return error.NoPixelData;
    var arena = std.heap.ArenaAllocator.init(self.allocator);
    defer arena.deinit();
    const databuf = try arena.allocator().alloc(u8, max_atlas_data_size);
    var bufstream = std.io.fixedBufferStream(databuf);

    // Magic header
    try bufstream.writer().writeAll(&magic_atlas_header);

    // Serialize atlas info
    var json_root = json.Value{
        .object = json.ObjectMap.init(arena.allocator()),
    };
    var vranges = json.Value{
        .array = try json.Array.initCapacity(
            arena.allocator(),
            self.ranges.len,
        ),
    };
    for (self.ranges) |r| {
        var vr = json.Value{
            .array = try json.Array.initCapacity(
                arena.allocator(),
                3,
            ),
        };
        vr.array.appendAssumeCapacity(.{
            .integer = @intCast(r.codepoint_begin),
        });
        vr.array.appendAssumeCapacity(.{
            .integer = @intCast(r.codepoint_end),
        });
        var vchars = json.Value{
            .array = try json.Array.initCapacity(
                arena.allocator(),
                r.packedchar.len,
            ),
        };
        for (r.packedchar) |c| {
            var vchar = json.Value{
                .array = try json.Array.initCapacity(arena.allocator(), 9),
            };
            vchar.array.appendAssumeCapacity(.{
                .integer = @intCast(c.x0),
            });
            vchar.array.appendAssumeCapacity(.{
                .integer = @intCast(c.y0),
            });
            vchar.array.appendAssumeCapacity(.{
                .integer = @intCast(c.x1),
            });
            vchar.array.appendAssumeCapacity(.{
                .integer = @intCast(c.y1),
            });
            vchar.array.appendAssumeCapacity(.{
                .float = @floatCast(c.xoff),
            });
            vchar.array.appendAssumeCapacity(.{
                .float = @floatCast(c.yoff),
            });
            vchar.array.appendAssumeCapacity(.{
                .float = @floatCast(c.xadvance),
            });
            vchar.array.appendAssumeCapacity(.{
                .float = @floatCast(c.xoff2),
            });
            vchar.array.appendAssumeCapacity(.{
                .float = @floatCast(c.yoff2),
            });
            vchars.array.appendAssumeCapacity(vchar);
        }
        vr.array.appendAssumeCapacity(vchars);
        vranges.array.appendAssumeCapacity(vr);
    }
    try json_root.object.put("ranges", vranges);
    try json_root.object.put("ascent", .{
        .float = self.vmetric_ascent,
    });
    try json_root.object.put("descent", .{
        .float = self.vmetric_descent,
    });
    try json_root.object.put("line_gap", .{
        .float = self.vmetric_line_gap,
    });
    var stream = json.writeStream(bufstream.writer(), .{});
    try json_root.jsonStringify(&stream);

    // Save to disk
    const info = try self.tex.query();
    try jok.utils.gfx.jpng.save(
        ctx,
        self.pixels.?,
        info.width,
        info.height,
        path,
        bufstream.getWritten(),
        opt,
    );
}

/// Load atlas from jpng file
pub fn load(ctx: jok.Context, path: [*:0]const u8) !*Atlas {
    const loaded = try jok.utils.gfx.jpng.load(ctx, path, .static);
    defer ctx.allocator().free(loaded.data);
    errdefer loaded.tex.destroy();
    if (loaded.data.len <= magic_atlas_header.len and
        !std.mem.eql(u8, &magic_atlas_header, loaded.data[0..magic_atlas_header.len]))
    {
        return error.InvalidFormat;
    }

    // Load atlas info
    const allocator = ctx.allocator();
    var parsed = try json.parseFromSlice(
        json.Value,
        allocator,
        loaded.data[magic_atlas_header.len..],
        .{},
    );
    defer parsed.deinit();
    if (parsed.value != .object) {
        return error.InvalidFormat;
    }
    const vranges = parsed.value.object.get("ranges").?;
    assert(vranges.array.items.len > 0);
    var ranges = try allocator.alloc(
        CharRange,
        vranges.array.items.len,
    );
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

    for (vranges.array.items, 0..) |vr, i| {
        ranges[i].codepoint_begin = @intCast(vr.array.items[0].integer);
        ranges[i].codepoint_end = @intCast(vr.array.items[1].integer);
        assert(ranges[i].codepoint_end >= ranges[i].codepoint_begin);
        const chars_num = ranges[i].codepoint_end - ranges[i].codepoint_begin + 1;
        ranges[i].packedchar = try allocator.alloc(truetype.stbtt_packedchar, chars_num);
        for (vr.array.items[2].array.items, 0..) |vchars, j| {
            ranges[i].packedchar[j].x0 = @intCast(vchars.array.items[0].integer);
            ranges[i].packedchar[j].y0 = @intCast(vchars.array.items[1].integer);
            ranges[i].packedchar[j].x1 = @intCast(vchars.array.items[2].integer);
            ranges[i].packedchar[j].y1 = @intCast(vchars.array.items[3].integer);
            ranges[i].packedchar[j].xoff = @floatCast(vchars.array.items[4].float);
            ranges[i].packedchar[j].yoff = @floatCast(vchars.array.items[5].float);
            ranges[i].packedchar[j].xadvance = @floatCast(vchars.array.items[6].float);
            ranges[i].packedchar[j].xoff2 = @floatCast(vchars.array.items[7].float);
            ranges[i].packedchar[j].yoff2 = @floatCast(vchars.array.items[8].float);
        }
    }
    const ascent: f32 = @floatCast(parsed.value.object.get("ascent").?.float);
    const descent: f32 = @floatCast(parsed.value.object.get("descent").?.float);
    const line_gap: f32 = @floatCast(parsed.value.object.get("line_gap").?.float);

    const atlas = try allocator.create(Atlas);
    atlas.* = .{
        .allocator = allocator,
        .tex = loaded.tex,
        .pixels = null,
        .ranges = ranges,
        .vmetric_ascent = ascent,
        .vmetric_descent = descent,
        .vmetric_line_gap = line_gap,
        .codepoint_search = std.AutoHashMap(u32, u32).init(allocator),
    };
    return atlas;
}

/// Calculate next line's y coordinate
pub fn getVPosOfNextLine(self: Atlas, current_ypos: f32) f32 {
    return current_ypos + @round(self.vmetric_ascent - self.vmetric_descent + self.vmetric_line_gap);
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
        .baseline => -self.vmetric_ascent,
        .top => 0,
        .bottom => self.vmetric_descent - self.vmetric_ascent,
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
            .aligned => @round(self.vmetric_ascent - self.vmetric_descent),
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
        .baseline => -self.vmetric_ascent,
        .top => 0,
        .bottom => self.vmetric_descent - self.vmetric_ascent,
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
            .aligned => @round(self.vmetric_ascent - self.vmetric_descent),
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
        for (self.ranges, 0..) |range, idx| {
            if (codepoint < range.codepoint_begin or codepoint > range.codepoint_end) continue;
            self.codepoint_search.put(codepoint, @intCast(idx)) catch unreachable;
            break :BLK @as(u32, @intCast(idx));
        } else {
            return null;
        }
    };
    const range = self.ranges[idx];
    var quad: truetype.stbtt_aligned_quad = undefined;
    const info = self.tex.query() catch unreachable;
    truetype.stbtt_GetPackedQuad(
        range.packedchar.ptr,
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
        .top => self.vmetric_ascent,
        .bottom => self.vmetric_descent,
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
