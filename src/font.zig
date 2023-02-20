const std = @import("std");
const assert = std.debug.assert;
const sdl = @import("sdl");
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

    var atlases: std.AutoHashMap(u32, *Atlas) = undefined;
    var vattrib: std.ArrayList(sdl.Vertex) = undefined;
    var vindices: std.ArrayList(u32) = undefined;

    pub fn init(allocator: std.mem.Allocator) !void {
        font = try Font.fromTrueTypeData(allocator, font_data);
        atlases = std.AutoHashMap(u32, *Atlas).init(allocator);
        vattrib = try std.ArrayList(sdl.Vertex).initCapacity(allocator, 100);
        vindices = try std.ArrayList(u32).initCapacity(allocator, 100);
    }

    pub fn deinit() void {
        font.destroy();
        var it = atlases.iterator();
        while (it.next()) |a| a.value_ptr.*.destroy();
        atlases.deinit();
        vattrib.deinit();
        vindices.deinit();
    }

    pub fn getAtlas(ctx: *const jok.Context, font_size: u32) !*Atlas {
        return atlases.get(font_size) orelse BLK: {
            var a = try font.createAtlas(
                ctx.renderer,
                font_size,
                &[_][2]u32{.{ 0x0020, 0x00FF }},
                1024,
            );
            try atlases.put(font_size, a);
            break :BLK a;
        };
    }
};

/// Draw debug text using builtin font
pub const DrawOption = struct {
    pos: sdl.PointF,
    ypos_type: Atlas.YPosType = .top,
    box_type: Atlas.BoxType = .aligned,
    color: sdl.Color = sdl.Color.white,
    font_size: u32 = 16,
};
pub const DrawResult = struct {
    area: sdl.RectangleF,
    next_line_ypos: f32,
};
pub fn debugDraw(ctx: *const jok.Context, opt: DrawOption, comptime fmt: []const u8, args: anytype) !DrawResult {
    var atlas = try DebugFont.getAtlas(ctx, opt.font_size);
    const text = jok.imgui.format(fmt, args);
    const area = try atlas.appendDrawDataFromUTF8String(
        text,
        opt.pos,
        opt.ypos_type,
        opt.box_type,
        opt.color,
        &DebugFont.vattrib,
        &DebugFont.vindices,
    );
    try ctx.renderer.drawGeometry(atlas.tex, DebugFont.vattrib.items, DebugFont.vindices.items);
    defer DebugFont.vattrib.clearRetainingCapacity();
    defer DebugFont.vindices.clearRetainingCapacity();
    return DrawResult{
        .area = area,
        .next_line_ypos = atlas.getVPosOfNextLine(opt.pos.y),
    };
}
