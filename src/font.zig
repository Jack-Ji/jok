const std = @import("std");
const assert = std.debug.assert;
const unicode = std.unicode;
const jok = @import("jok.zig");
const imgui = jok.imgui;

/// Wrapper of truetype font
pub const Font = @import("font/Font.zig");

/// Font-atlas for generating vertex data
pub const Atlas = @import("font/Atlas.zig");

/// Regularly used codepoints
pub const codepoint_ranges = @import("font/codepoint_ranges.zig");

/// Embedded font data
pub const DebugFont = struct {
    pub const font_data = @embedFile("font/clacon2.ttf");
    pub var font: *Font = undefined;

    var arena: std.heap.ArenaAllocator = undefined;
    var atlases: std.AutoHashMap(u32, *Atlas) = undefined;
    var vattrib: std.ArrayList(jok.Vertex) = undefined;
    var vindices: std.ArrayList(u32) = undefined;
    var debug_Size: u32 = undefined;

    pub fn init(allocator: std.mem.Allocator) !void {
        arena = std.heap.ArenaAllocator.init(allocator);
        font = try Font.fromTrueTypeData(arena.allocator(), font_data);
        atlases = std.AutoHashMap(u32, *Atlas).init(arena.allocator());
        vattrib = try std.ArrayList(jok.Vertex).initCapacity(arena.allocator(), 100);
        vindices = try std.ArrayList(u32).initCapacity(arena.allocator(), 100);
    }

    pub fn deinit() void {
        var it = atlases.iterator();
        while (it.next()) |e| {
            e.value_ptr.*.destroy();
        }
        arena.deinit();
    }

    pub fn getAtlas(ctx: jok.Context, font_size: u32) !*Atlas {
        return atlases.get(font_size) orelse BLK: {
            const a = try font.createAtlas(
                ctx,
                font_size,
                &[_][2]u32{.{ 0x0020, 0x00FF }},
                1024,
            );
            if (atlases.count() == 0) debug_Size = font_size;
            try atlases.put(font_size, a);
            break :BLK a;
        };
    }
};

/// Draw debug text using builtin font
/// NOTE: This function render immediately, if you want to batch drawcalls or need more control,
/// consider using j2d.text.
pub fn debugDraw(ctx: jok.Context, pos: jok.Point, comptime fmt: []const u8, args: anytype) void {
    const S = struct {
        var vertices: ?std.ArrayList(jok.Vertex) = null;
        var indices: std.ArrayList(u32) = undefined;
    };
    if (S.vertices) |*vs| {
        vs.clearRetainingCapacity();
        S.indices.clearRetainingCapacity();
    } else {
        S.vertices = std.ArrayList(jok.Vertex).init(DebugFont.arena.allocator());
        S.indices = std.ArrayList(u32).init(DebugFont.arena.allocator());
    }

    const atlas = DebugFont.getAtlas(
        ctx,
        @intFromFloat(@as(f32, @floatFromInt(DebugFont.debug_Size)) * ctx.getDpiScale()),
    ) catch unreachable;
    const txt = imgui.format(fmt, args);
    _ = atlas.appendDrawDataFromUTF8String(
        txt,
        pos,
        .top,
        .aligned,
        jok.Color.white,
        &S.vertices.?,
        &S.indices,
    ) catch unreachable;
    ctx.renderer().drawTriangles(atlas.tex, S.vertices.?.items, S.indices.items) catch unreachable;
}

test "font" {}
