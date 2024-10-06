const std = @import("std");
const assert = std.debug.assert;
const Atlas = @import("Atlas.zig");
const jok = @import("../jok.zig");
const sdl = jok.sdl;
const physfs = jok.physfs;
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
    cp_ranges: ?[]const [2]u32,
    atlas_size: ?u32,
) !*Atlas {
    return Atlas.create(ctx, &self.font_info, font_size, cp_ranges, atlas_size);
}
