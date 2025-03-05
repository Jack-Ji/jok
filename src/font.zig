const std = @import("std");
const assert = std.debug.assert;
const jok = @import("jok.zig");

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
                .{},
            );
            if (atlases.count() == 0) debug_Size = font_size;
            try atlases.put(font_size, a);
            break :BLK a;
        };
    }
};

test "font" {}
