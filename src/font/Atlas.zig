const std = @import("std");
const assert = std.debug.assert;
const unicode = std.unicode;
const json = std.json;
const math = std.math;
const ascii = std.ascii;
const jok = @import("../jok.zig");
const truetype = jok.vendor.stb.truetype;
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
kerning_table: std.AutoHashMap(u64, f32),
codepoint_search: std.AutoHashMap(u32, u32),

pub fn destroy(self: *Atlas) void {
    self.tex.destroy();
    if (self.pixels) |px| self.allocator.free(px);
    for (self.ranges) |r| {
        self.allocator.free(r.packedchar);
    }
    self.allocator.free(self.ranges);
    self.kerning_table.deinit();
    self.codepoint_search.deinit();
    self.allocator.destroy(self);
}

/// Save atlas as jpng
pub fn save(
    self: Atlas,
    ctx: jok.Context,
    path: [:0]const u8,
    opt: jok.utils.gfx.jpng.SaveOption,
) !void {
    if (self.pixels == null) return error.NoPixelData;
    var arena = std.heap.ArenaAllocator.init(self.allocator);
    defer arena.deinit();
    const databuf = try arena.allocator().alloc(u8, max_atlas_data_size);
    var bufwriter = std.Io.Writer.fixed(databuf);

    // Magic header
    try bufwriter.writeAll(&magic_atlas_header);

    // Serialize atlas info
    var json_root = json.Value{
        .object = json.ObjectMap.init(arena.allocator()),
    };
    var char_ranges = json.Value{
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
        char_ranges.array.appendAssumeCapacity(vr);
    }
    var kerning_values = json.Value{
        .array = try json.Array.initCapacity(
            arena.allocator(),
            self.kerning_table.count(),
        ),
    };
    var it = self.kerning_table.iterator();
    while (it.next()) |p| {
        var vr = json.Value{
            .array = try json.Array.initCapacity(arena.allocator(), 2),
        };
        vr.array.appendAssumeCapacity(.{ .integer = @intCast(p.key_ptr.*) });
        vr.array.appendAssumeCapacity(.{ .float = @floatCast(p.value_ptr.*) });
        kerning_values.array.appendAssumeCapacity(vr);
    }
    try json_root.object.put("char_ranges", char_ranges);
    try json_root.object.put("ascent", .{
        .float = self.vmetric_ascent,
    });
    try json_root.object.put("descent", .{
        .float = self.vmetric_descent,
    });
    try json_root.object.put("line_gap", .{
        .float = self.vmetric_line_gap,
    });
    try json_root.object.put("kerning_table", kerning_values);
    var stream = json.Stringify{
        .writer = &bufwriter,
        .options = .{},
    };
    try json_root.jsonStringify(&stream);

    // Save to disk
    const info = try self.tex.query();
    try jok.utils.gfx.jpng.save(
        ctx,
        self.pixels.?,
        info.width,
        info.height,
        path,
        bufwriter.buffered(),
        opt,
    );
}

/// Load atlas from jpng file
pub fn load(ctx: jok.Context, path: [:0]const u8) !*Atlas {
    const S = struct {
        inline fn getFloat(v: json.Value) f32 {
            return switch (v) {
                .integer => |i| @floatFromInt(i),
                .float => |f| @floatCast(f),
                else => unreachable,
            };
        }
        inline fn getInt(v: json.Value, T: type) T {
            return switch (v) {
                .integer => |i| @intCast(i),
                else => unreachable,
            };
        }
    };

    const loaded = try jok.utils.gfx.jpng.loadTexture(ctx, path, .static, false);
    defer ctx.allocator().free(loaded.data);
    errdefer loaded.tex.destroy();
    if (loaded.data.len < magic_atlas_header.len + 2 or
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
    const char_ranges = parsed.value.object.get("char_ranges").?;
    assert(char_ranges.array.items.len > 0);
    var ranges = try allocator.alloc(
        CharRange,
        char_ranges.array.items.len,
    );
    @memset(ranges, Atlas.CharRange{
        .codepoint_begin = 0,
        .codepoint_end = 0,
        .packedchar = &.{},
    });
    const kerning_pairs = parsed.value.object.get("kerning_table").?;
    var kerning_table = std.AutoHashMap(u64, f32).init(allocator);
    errdefer {
        kerning_table.deinit();
        for (ranges) |r| {
            if (r.packedchar.len > 0) {
                allocator.free(r.packedchar);
            }
        }
        allocator.free(ranges);
    }

    // char sprites
    for (char_ranges.array.items, 0..) |vr, i| {
        ranges[i].codepoint_begin = @intCast(vr.array.items[0].integer);
        ranges[i].codepoint_end = @intCast(vr.array.items[1].integer);
        assert(ranges[i].codepoint_end >= ranges[i].codepoint_begin);
        const chars_num = ranges[i].codepoint_end - ranges[i].codepoint_begin + 1;
        ranges[i].packedchar = try allocator.alloc(truetype.stbtt_packedchar, chars_num);
        for (vr.array.items[2].array.items, 0..) |vchars, j| {
            ranges[i].packedchar[j].x0 = S.getInt(vchars.array.items[0], c_ushort);
            ranges[i].packedchar[j].y0 = S.getInt(vchars.array.items[1], c_ushort);
            ranges[i].packedchar[j].x1 = S.getInt(vchars.array.items[2], c_ushort);
            ranges[i].packedchar[j].y1 = S.getInt(vchars.array.items[3], c_ushort);
            ranges[i].packedchar[j].xoff = S.getFloat(vchars.array.items[4]);
            ranges[i].packedchar[j].yoff = S.getFloat(vchars.array.items[5]);
            ranges[i].packedchar[j].xadvance = S.getFloat(vchars.array.items[6]);
            ranges[i].packedchar[j].xoff2 = S.getFloat(vchars.array.items[7]);
            ranges[i].packedchar[j].yoff2 = S.getFloat(vchars.array.items[8]);
        }
    }
    const ascent: f32 = S.getFloat(parsed.value.object.get("ascent").?);
    const descent: f32 = S.getFloat(parsed.value.object.get("descent").?);
    const line_gap: f32 = S.getFloat(parsed.value.object.get("line_gap").?);

    // kerning table
    for (kerning_pairs.array.items) |vk| {
        const merged_cp: u64 = S.getInt(vk.array.items[0], u64);
        const kvalue: f32 = S.getFloat(vk.array.items[1]);
        try kerning_table.put(merged_cp, kvalue);
    }

    const atlas = try allocator.create(Atlas);
    atlas.* = .{
        .allocator = allocator,
        .tex = loaded.tex,
        .pixels = null,
        .ranges = ranges,
        .vmetric_ascent = ascent,
        .vmetric_descent = descent,
        .vmetric_line_gap = line_gap,
        .kerning_table = kerning_table,
        .codepoint_search = std.AutoHashMap(u32, u32).init(allocator),
    };
    return atlas;
}

/// Get font size used to bake the atlas
pub inline fn getFontSizeInPixels(self: Atlas) f32 {
    return self.vmetric_ascent - self.vmetric_descent;
}

/// Calculate next line's y coordinate
pub inline fn getVPosOfNextLine(self: Atlas, current_ypos: f32) f32 {
    return current_ypos + @round(self.getFontSizeInPixels() + self.vmetric_line_gap);
}

/// Get kerning value between 2 codepoints
pub inline fn getKerningInPixels(self: Atlas, cp1: u32, cp2: u32) f32 {
    const k = @as(u64, cp1) << 32 | cp2;
    return self.kerning_table.get(k) orelse 0;
}

/// Position type of y axis (determine where text will be aligned vertically)
pub const YPosType = enum { baseline, top, bottom, middle };

/// Type of text's horizontal alignment
pub const AlignType = enum { left, middle, right };

/// Type of text's bounding rectangle
pub const BoxType = enum { aligned, drawed };

/// BBox parameters
pub const BBox = struct {
    ypos_type: YPosType = .top,
    align_type: AlignType = .left,
    align_width: ?u32 = null,
    auto_hyphen: bool = false,
    box_type: BoxType = .aligned,
    kerning: bool = false,
    scale: jok.Point = .unit,
};

/// Get bounding box of text
pub fn getBoundingBox(self: *Atlas, text: []const u8, _pos: jok.Point, opt: BBox) !jok.Rectangle {
    const yoffset = switch (opt.ypos_type) {
        .baseline => -self.vmetric_ascent,
        .top => 0,
        .bottom => -self.getFontSizeInPixels(),
        .middle => -self.getFontSizeInPixels() * 0.5,
    };
    const align_width = if (opt.align_width) |w| @as(f32, @floatFromInt(w)) else math.inf(f32);
    var pos = _pos;
    var rect = jok.Rectangle{
        .x = pos.x,
        .y = switch (opt.box_type) {
            .aligned => pos.y + yoffset,
            .drawed => std.math.floatMax(f32),
        },
        .width = 0,
        .height = switch (opt.box_type) {
            .aligned => self.getFontSizeInPixels(),
            .drawed => 0,
        },
    };

    if (text.len == 0) return rect;

    var wrapped = false;
    var line_count: u32 = 1;
    var last_codepoint: u32 = 0;
    var last_size: u32 = 0;
    var total_width: f32 = 0;
    var i: u32 = 0;
    while (i < text.len) {
        const size = try unicode.utf8ByteSequenceLength(text[i]);
        var codepoint: u32 = @intCast(try unicode.utf8Decode(text[i .. i + size]));

        // Kerning adjustment
        pos.x += if (opt.kerning and last_codepoint > 0)
            self.getKerningInPixels(last_codepoint, codepoint)
        else
            0;

        if (wrapped or pos.x - rect.x >= align_width) {
            // Wrapping text
            wrapped = false;
            pos = .{ .x = rect.x, .y = self.getVPosOfNextLine(pos.y) };
            line_count += 1;
            rect.height += @round(self.getFontSizeInPixels() + self.vmetric_line_gap);
        } else if (opt.align_width != null and i < text.len - 1) {
            // Add hyphen at the end of line when possible
            if (opt.auto_hyphen and last_size == 1 and size == 1 and
                ascii.isAlphabetic(@intCast(codepoint)) and
                (ascii.isAlphabetic(@intCast(last_codepoint)) or ascii.isWhitespace(@intCast(last_codepoint))))
            {
                // Check if this is last character of the line
                const new_x = pos.x + (self.getVerticesOfCodePoint(
                    pos,
                    opt.ypos_type,
                    .white,
                    codepoint,
                ).?.next_x - pos.x);
                if (new_x - rect.x >= align_width) {
                    wrapped = true;
                    codepoint = if (ascii.isWhitespace(@intCast(last_codepoint))) ' ' else '-';
                }
            }
        }

        // Save state and step to next codepoint
        if (!wrapped) {
            i += size;
            last_codepoint = codepoint;
            last_size = size;
            if (size == 1 and codepoint == '\n') {
                wrapped = true;
                continue;
            }
        }

        // Calculate size of current codepoint
        if (self.getVerticesOfCodePoint(
            pos,
            opt.ypos_type,
            .white,
            codepoint,
        )) |cs| {
            switch (opt.box_type) {
                .aligned => {
                    rect.width = @max(cs.next_x - rect.x, rect.width);
                },
                .drawed => {
                    if (line_count == 1 and cs.vs[0].pos.y < rect.y) rect.y = cs.vs[0].pos.y;
                    if (cs.vs[3].pos.y - rect.y > rect.height) rect.height = cs.vs[3].pos.y - rect.y;
                    rect.width = @max(cs.vs[1].pos.x - rect.x, rect.width);
                },
            }
            pos.x = cs.next_x;
            total_width = @max(cs.next_x - rect.x, rect.width);
        }
    }

    var scaled_rect = rect.scale(opt.scale.toArray());
    const scaled_total_width = total_width * opt.scale.x;
    if (opt.align_type == .middle) {
        scaled_rect.x -= scaled_total_width / 2;
    } else if (opt.align_type == .right) {
        scaled_rect.x -= scaled_total_width;
    }

    return scaled_rect;
}

pub const AppendOption = struct {
    ypos_type: YPosType = .top,
    box_type: BoxType = .aligned,
    kerning: bool = false,
};

/// Append draw data for rendering utf8 string, return bounding box
pub fn appendDrawDataFromUTF8String(
    self: *Atlas,
    text: []const u8,
    _pos: jok.Point,
    color: jok.Color,
    vattrib: *std.array_list.Managed(jok.Vertex),
    vindices: *std.array_list.Managed(u32),
    opt: AppendOption,
) !jok.Rectangle {
    const yoffset = switch (opt.ypos_type) {
        .baseline => -self.vmetric_ascent,
        .top => 0,
        .bottom => self.getFontSizeInPixels(),
        .middle => self.getFontSizeInPixels() * 0.5,
    };
    var pos = _pos;
    var rect = jok.Rectangle{
        .x = pos.x,
        .y = switch (opt.box_type) {
            .aligned => pos.y + yoffset,
            .drawed => std.math.floatMax(f32),
        },
        .width = 0,
        .height = switch (opt.box_type) {
            .aligned => self.getFontSizeInPixels(),
            .drawed => 0,
        },
    };

    if (text.len == 0) return rect;

    var last_codepoint: u32 = 0;
    var i: u32 = 0;
    while (i < text.len) {
        const size = try unicode.utf8ByteSequenceLength(text[i]);
        const codepoint = @as(u32, @intCast(try unicode.utf8Decode(text[i .. i + size])));
        pos.x += if (opt.kerning and last_codepoint > 0)
            self.getKerningInPixels(last_codepoint, codepoint)
        else
            0;
        if (self.getVerticesOfCodePoint(pos, opt.ypos_type, color, codepoint)) |cs| {
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
            switch (opt.box_type) {
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
        last_codepoint = codepoint;
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
        .middle => (self.vmetric_ascent + self.vmetric_descent) / 2,
    };
    return .{
        .vs = [_]jok.Vertex{
            .{
                .pos = .{ .x = quad.x0, .y = quad.y0 + yoffset },
                .color = color.toColorF(),
                .texcoord = .{ .x = quad.s0, .y = quad.t0 },
            },
            .{
                .pos = .{ .x = quad.x1, .y = quad.y0 + yoffset },
                .color = color.toColorF(),
                .texcoord = .{ .x = quad.s1, .y = quad.t0 },
            },
            .{
                .pos = .{ .x = quad.x1, .y = quad.y1 + yoffset },
                .color = color.toColorF(),
                .texcoord = .{ .x = quad.s1, .y = quad.t1 },
            },
            .{
                .pos = .{ .x = quad.x0, .y = quad.y1 + yoffset },
                .color = color.toColorF(),
                .texcoord = .{ .x = quad.s0, .y = quad.t1 },
            },
        },
        .next_x = xpos,
    };
}

/// Get sprite of codepoint
pub fn getSpriteOfCodePoint(self: *Atlas, codepoint: u32) ?Sprite {
    if (self.getVerticesOfCodePoint(.origin, .top, .white, codepoint)) |cs| {
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
