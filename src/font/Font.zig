const std = @import("std");
const assert = std.debug.assert;
const sdl = @import("sdl");
const Atlas = @import("Atlas.zig");
const jok = @import("../jok.zig");
const truetype = jok.stb.truetype;
const Font = @This();

// Memory allocator
allocator: std.mem.Allocator,

// Font file's data
font_data: ?[]const u8,

// Internal font information
font_info: truetype.stbtt_fontinfo,

// Accept 20M font file at most
const max_font_size = 20 * (1 << 20);

/// Init Font instance with truetype file
pub fn init(allocator: std.mem.Allocator, path: [:0]const u8) !Font {
    const dir = std.fs.cwd();
    var self = Font{
        .allocator = allocator,
        .font_data = try dir.readFileAlloc(allocator, path, max_font_size),
        .font_info = undefined,
    };

    // Extract font info
    var rc = truetype.stbtt_InitFont(
        &self.font_info,
        self.font_data.?.ptr,
        truetype.stbtt_GetFontOffsetForIndex(self.font_data.?.ptr, 0),
    );
    assert(rc > 0);

    return self;
}

/// Init Font instance with truetype data
/// WARNING: font data must be valid as long as Font instance is alive
pub fn fromTrueTypeData(allocator: std.mem.Allocator, data: []const u8) !Font {
    var self = Font{
        .allocator = allocator,
        .font_data = null,
        .font_info = undefined,
    };

    // Extract font info
    var rc = truetype.stbtt_InitFont(
        &self.font_info,
        data.ptr,
        truetype.stbtt_GetFontOffsetForIndex(data.ptr, 0),
    );
    assert(rc > 0);

    return self;
}

pub fn deinit(self: *Font) void {
    if (self.font_data) |data| {
        self.allocator.free(data);
    }
    self.* = undefined;
}

pub fn createAtlas(
    self: Font,
    renderer: sdl.Renderer,
    font_size: u32,
    codepoint_ranges: []const [2]u32,
    atlas_size: ?u32,
) !Atlas {
    return Atlas.init(self.allocator, renderer, &self.font_info, font_size, codepoint_ranges, atlas_size);
}
