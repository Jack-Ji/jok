const std = @import("std");
const assert = std.debug.assert;
const unicode = std.unicode;
const sdl = @import("sdl");
const jok = @import("../../jok.zig");
const gfx = jok.gfx;
const truetype = jok.deps.stb.truetype;
const Self = @This();

/// memory allocator
allocator: std.mem.Allocator,

/// font file's data
font_data: ?[]const u8,

/// internal font information
font_info: truetype.stbtt_fontinfo,

/// accept 20M font file at most
const max_font_size = 20 * (1 << 20);

/// init Font instance with truetype file
pub fn init(allocator: std.mem.Allocator, path: [:0]const u8) !*Self {
    const dir = std.fs.cwd();

    var self = try allocator.create(Self);
    self.allocator = allocator;
    self.font_data = try dir.readFileAlloc(allocator, path, max_font_size);

    // extract font info
    var rc = truetype.stbtt_InitFont(
        &self.font_info,
        self.font_data.?.ptr,
        truetype.stbtt_GetFontOffsetForIndex(self.font_data.?.ptr, 0),
    );
    assert(rc > 0);

    return self;
}

/// init Font instance with truetype data
/// WARNING: font data must be valid as long as Font instance
pub fn fromTrueTypeData(allocator: std.mem.Allocator, data: []const u8) !*Self {
    var self = try allocator.create(Self);
    self.allocator = allocator;
    self.font_data = null;

    // extract font info
    var rc = truetype.stbtt_InitFont(
        &self.font_info,
        data.ptr,
        truetype.stbtt_GetFontOffsetForIndex(data.ptr, 0),
    );
    assert(rc > 0);

    return self;
}

pub fn deinit(self: *Self) void {
    if (self.font_data) |data| {
        self.allocator.free(data);
    }
    self.allocator.destroy(self);
}

pub fn createAtlas(
    self: Self,
    renderer: sdl.Renderer,
    font_size: u32,
    codepoint_ranges: []const [2]u32,
    atlas_size: ?u32,
) !Atlas {
    return Atlas.init(self.allocator, renderer, &self.font_info, font_size, codepoint_ranges, atlas_size);
}

/// useful codepoint ranges
pub const CodepointRanges = struct {
    pub const default = [_][2]u32{
        .{ 0x0020, 0x00FF },
    };

    pub const korean = [_][2]u32{
        .{ 0x0020, 0x00FF }, // Basic Latin + Latin Supplement
        .{ 0x3131, 0x3163 }, // Korean alphabets
        .{ 0xAC00, 0xD7A3 }, // Korean characters
        .{ 0xFFFD, 0xFFFD }, // Invalid
    };

    pub const chineseFull = [_][2]u32{
        .{ 0x0020, 0x00FF }, // Basic Latin + Latin Supplement
        .{ 0x2000, 0x206F }, // General Punctuation
        .{ 0x3000, 0x30FF }, // CJK Symbols and Punctuations, Hiragana, Katakana
        .{ 0x31F0, 0x31FF }, // Katakana Phonetic Extensions
        .{ 0xFF00, 0xFFEF }, // Half-width characters
        .{ 0xFFFD, 0xFFFD }, // Invalid
        .{ 0x4e00, 0x9FAF }, // CJK Ideograms
    };

    pub const chineseCommon = genRanges(
        &[_][2]u32{
            .{ 0x0020, 0x00FF }, // Basic Latin + Latin Supplement
            .{ 0x2000, 0x206F }, // General Punctuation
            .{ 0x3000, 0x30FF }, // CJK Symbols and Punctuations, Hiragana, Katakana
            .{ 0x31F0, 0x31FF }, // Katakana Phonetic Extensions
            .{ 0xFF00, 0xFFEF }, // Half-width characters
            .{ 0xFFFD, 0xFFFD }, // Invalid
        },
        0x4E00,
        &[_]u32{
            0,  1,  2,  4,  1,  1,  1,  1,  2,  1,  3,  2,  1,  2,  2,  1,  1,   1,   1,  1,  5,  2,  1,  2,  3,  3,   3,   2,  2,  4,  1,  1,  1,  2,  1,  5,   2,  3,  1,  2,  1,   2,  1,  1,   2,  1,  1,  2,   2,  1,   4,  1,  1,  1,  1,   5,   10,  1,   2,   19, 2,  1,   2,  1,   2,   1,  2,  1,  2,
            1,  5,  1,  6,  3,  2,  1,  2,  2,  1,  1,  1,  4,  8,  5,  1,  1,   4,   1,  1,  3,  1,  2,  1,  5,  1,   2,   1,  1,  1,  10, 1,  1,  5,  2,  4,   6,  1,  4,  2,  2,   2,  12, 2,   1,  1,  6,  1,   1,  1,   4,  1,  1,  4,  6,   5,   1,   4,   2,   2,  4,  10,  7,  1,   1,   4,  2,  4,  2,
            1,  4,  3,  6,  10, 12, 5,  7,  2,  14, 2,  9,  1,  1,  6,  7,  10,  4,   7,  13, 1,  5,  4,  8,  4,  1,   1,   2,  28, 5,  6,  1,  1,  5,  2,  5,   20, 2,  2,  9,  8,   11, 2,  9,   17, 1,  8,  6,   8,  27,  4,  6,  9,  20, 11,  27,  6,   68,  2,   2,  1,  1,   1,  2,   1,   2,  2,  7,  6,
            11, 3,  3,  1,  1,  3,  1,  2,  1,  1,  1,  1,  1,  3,  1,  1,  8,   3,   4,  1,  5,  7,  2,  1,  4,  4,   8,   4,  2,  1,  2,  1,  1,  4,  5,  6,   3,  6,  2,  12, 3,   1,  3,  9,   2,  4,  3,  4,   1,  5,   3,  3,  1,  3,  7,   1,   5,   1,   1,   1,  1,  2,   3,  4,   5,   2,  3,  2,  6,
            1,  1,  2,  1,  7,  1,  7,  3,  4,  5,  15, 2,  2,  1,  5,  3,  22,  19,  2,  1,  1,  1,  1,  2,  5,  1,   1,   1,  6,  1,  1,  12, 8,  2,  9,  18,  22, 4,  1,  1,  5,   1,  16, 1,   2,  7,  10, 15,  1,  1,   6,  2,  4,  1,  2,   4,   1,   6,   1,   1,  3,  2,   4,  1,   6,   4,  5,  1,  2,
            1,  1,  2,  1,  10, 3,  1,  3,  2,  1,  9,  3,  2,  5,  7,  2,  19,  4,   3,  6,  1,  1,  1,  1,  1,  4,   3,   2,  1,  1,  1,  2,  5,  3,  1,  1,   1,  2,  2,  1,  1,   2,  1,  1,   2,  1,  3,  1,   1,  1,   3,  7,  1,  4,  1,   1,   2,   1,   1,   2,  1,  2,   4,  4,   3,   8,  1,  1,  1,
            2,  1,  3,  5,  1,  3,  1,  3,  4,  6,  2,  2,  14, 4,  6,  6,  11,  9,   1,  15, 3,  1,  28, 5,  2,  5,   5,   3,  1,  3,  4,  5,  4,  6,  14, 3,   2,  3,  5,  21, 2,   7,  20, 10,  1,  2,  19, 2,   4,  28,  28, 2,  3,  2,  1,   14,  4,   1,   26,  28, 42, 12,  40, 3,   52,  79, 5,  14, 17,
            3,  2,  2,  11, 3,  4,  6,  3,  1,  8,  2,  23, 4,  5,  8,  10, 4,   2,   7,  3,  5,  1,  1,  6,  3,  1,   2,   2,  2,  5,  28, 1,  1,  7,  7,  20,  5,  3,  29, 3,  17,  26, 1,  8,   4,  27, 3,  6,   11, 23,  5,  3,  4,  6,  13,  24,  16,  6,   5,   10, 25, 35,  7,  3,   2,   3,  3,  14, 3,
            6,  2,  6,  1,  4,  2,  3,  8,  2,  1,  1,  3,  3,  3,  4,  1,  1,   13,  2,  2,  4,  5,  2,  1,  14, 14,  1,   2,  2,  1,  4,  5,  2,  3,  1,  14,  3,  12, 3,  17, 2,   16, 5,  1,   2,  1,  8,  9,   3,  19,  4,  2,  2,  4,  17,  25,  21,  20,  28,  75, 1,  10,  29, 103, 4,   1,  2,  1,  1,
            4,  2,  4,  1,  2,  3,  24, 2,  2,  2,  1,  1,  2,  1,  3,  8,  1,   1,   1,  2,  1,  1,  3,  1,  1,  1,   6,   1,  5,  3,  1,  1,  1,  3,  4,  1,   1,  5,  2,  1,  5,   6,  13, 9,   16, 1,  1,  1,   1,  3,   2,  3,  2,  4,  5,   2,   5,   2,   2,   3,  7,  13,  7,  2,   2,   1,  1,  1,  1,
            2,  3,  3,  2,  1,  6,  4,  9,  2,  1,  14, 2,  14, 2,  1,  18, 3,   4,   14, 4,  11, 41, 15, 23, 15, 23,  176, 1,  3,  4,  1,  1,  1,  1,  5,  3,   1,  2,  3,  7,  3,   1,  1,  2,   1,  2,  4,  4,   6,  2,   4,  1,  9,  7,  1,   10,  5,   8,   16,  29, 1,  1,   2,  2,   3,   1,  3,  5,  2,
            4,  5,  4,  1,  1,  2,  2,  3,  3,  7,  1,  6,  10, 1,  17, 1,  44,  4,   6,  2,  1,  1,  6,  5,  4,  2,   10,  1,  6,  9,  2,  8,  1,  24, 1,  2,   13, 7,  8,  8,  2,   1,  4,  1,   3,  1,  3,  3,   5,  2,   5,  10, 9,  4,  9,   12,  2,   1,   6,   1,  10, 1,   1,  7,   7,   4,  10, 8,  3,
            1,  13, 4,  3,  1,  6,  1,  3,  5,  2,  1,  2,  17, 16, 5,  2,  16,  6,   1,  4,  2,  1,  3,  3,  6,  8,   5,   11, 11, 1,  3,  3,  2,  4,  6,  10,  9,  5,  7,  4,  7,   4,  7,  1,   1,  4,  2,  1,   3,  6,   8,  7,  1,  6,  11,  5,   5,   3,   24,  9,  4,  2,   7,  13,  5,   1,  8,  82, 16,
            61, 1,  1,  1,  4,  2,  2,  16, 10, 3,  8,  1,  1,  6,  4,  2,  1,   3,   1,  1,  1,  4,  3,  8,  4,  2,   2,   1,  1,  1,  1,  1,  6,  3,  5,  1,   1,  4,  6,  9,  2,   1,  1,  1,   2,  1,  7,  2,   1,  6,   1,  5,  4,  4,  3,   1,   8,   1,   3,   3,  1,  3,   2,  2,   2,   2,  3,  1,  6,
            1,  2,  1,  2,  1,  3,  7,  1,  8,  2,  1,  2,  1,  5,  2,  5,  3,   5,   10, 1,  2,  1,  1,  3,  2,  5,   11,  3,  9,  3,  5,  1,  1,  5,  9,  1,   2,  1,  5,  7,  9,   9,  8,  1,   3,  3,  3,  6,   8,  2,   3,  2,  1,  1,  32,  6,   1,   2,   15,  9,  3,  7,   13, 1,   3,   10, 13, 2,  14,
            1,  13, 10, 2,  1,  3,  10, 4,  15, 2,  15, 15, 10, 1,  3,  9,  6,   9,   32, 25, 26, 47, 7,  3,  2,  3,   1,   6,  3,  4,  3,  2,  8,  5,  4,  1,   9,  4,  2,  2,  19,  10, 6,  2,   3,  8,  1,  2,   2,  4,   2,  1,  9,  4,  4,   4,   6,   4,   8,   9,  2,  3,   1,  1,   1,   1,  3,  5,  5,
            1,  3,  8,  4,  6,  2,  1,  4,  12, 1,  5,  3,  7,  13, 2,  5,  8,   1,   6,  1,  2,  5,  14, 6,  1,  5,   2,   4,  8,  15, 5,  1,  23, 6,  62, 2,   10, 1,  1,  8,  1,   2,  2,  10,  4,  2,  2,  9,   2,  1,   1,  3,  2,  3,  1,   5,   3,   3,   2,   1,  3,  8,   1,  1,   1,   11, 3,  1,  1,
            4,  3,  7,  1,  14, 1,  2,  3,  12, 5,  2,  5,  1,  6,  7,  5,  7,   14,  11, 1,  3,  1,  8,  9,  12, 2,   1,   11, 8,  4,  4,  2,  6,  10, 9,  13,  1,  1,  3,  1,  5,   1,  3,  2,   4,  4,  1,  18,  2,  3,   14, 11, 4,  29, 4,   2,   7,   1,   3,   13, 9,  2,   2,  5,   3,   5,  20, 7,  16,
            8,  5,  72, 34, 6,  4,  22, 12, 12, 28, 45, 36, 9,  7,  39, 9,  191, 1,   1,  1,  4,  11, 8,  4,  9,  2,   3,   22, 1,  1,  1,  1,  4,  17, 1,  7,   7,  1,  11, 31, 10,  2,  4,  8,   2,  3,  2,  1,   4,  2,   16, 4,  32, 2,  3,   19,  13,  4,   9,   1,  5,  2,   14, 8,   1,   1,  3,  6,  19,
            6,  5,  1,  16, 6,  2,  10, 8,  5,  1,  2,  3,  1,  5,  5,  1,  11,  6,   6,  1,  3,  3,  2,  6,  3,  8,   1,   1,  4,  10, 7,  5,  7,  7,  5,  8,   9,  2,  1,  3,  4,   1,  1,  3,   1,  3,  3,  2,   6,  16,  1,  4,  6,  3,  1,   10,  6,   1,   3,   15, 2,  9,   2,  10,  25,  13, 9,  16, 6,
            2,  2,  10, 11, 4,  3,  9,  1,  2,  6,  6,  5,  4,  30, 40, 1,  10,  7,   12, 14, 33, 6,  3,  6,  7,  3,   1,   3,  1,  11, 14, 4,  9,  5,  12, 11,  49, 18, 51, 31, 140, 31, 2,  2,   1,  5,  1,  8,   1,  10,  1,  4,  4,  3,  24,  1,   10,  1,   3,   6,  6,  16,  3,  4,   5,   2,  1,  4,  2,
            57, 10, 6,  22, 2,  22, 3,  7,  22, 6,  10, 11, 36, 18, 16, 33, 36,  2,   5,  5,  1,  1,  1,  4,  10, 1,   4,   13, 2,  7,  5,  2,  9,  3,  4,  1,   7,  43, 3,  7,  3,   9,  14, 7,   9,  1,  11, 1,   1,  3,   7,  4,  18, 13, 1,   14,  1,   3,   6,   10, 73, 2,   2,  30,  6,   1,  11, 18, 19,
            13, 22, 3,  46, 42, 37, 89, 7,  3,  16, 34, 2,  2,  3,  9,  1,  7,   1,   1,  1,  2,  2,  4,  10, 7,  3,   10,  3,  9,  5,  28, 9,  2,  6,  13, 7,   3,  1,  3,  10, 2,   7,  2,  11,  3,  6,  21, 54,  85, 2,   1,  4,  2,  2,  1,   39,  3,   21,  2,   2,  5,  1,   1,  1,   4,   1,  1,  3,  4,
            15, 1,  3,  2,  4,  4,  2,  3,  8,  2,  20, 1,  8,  7,  13, 4,  1,   26,  6,  2,  9,  34, 4,  21, 52, 10,  4,   4,  1,  5,  12, 2,  11, 1,  7,  2,   30, 12, 44, 2,  30,  1,  1,  3,   6,  16, 9,  17,  39, 82,  2,  2,  24, 7,  1,   7,   3,   16,  9,   14, 44, 2,   1,  2,   1,   2,  3,  5,  2,
            4,  1,  6,  7,  5,  3,  2,  6,  1,  11, 5,  11, 2,  1,  18, 19, 8,   1,   3,  24, 29, 2,  1,  3,  5,  2,   2,   1,  13, 6,  5,  1,  46, 11, 3,  5,   1,  1,  5,  8,  2,   10, 6,  12,  6,  3,  7,  11,  2,  4,   16, 13, 2,  5,  1,   1,   2,   2,   5,   2,  28, 5,   2,  23,  10,  8,  4,  4,  22,
            39, 95, 38, 8,  14, 9,  5,  1,  13, 5,  4,  3,  13, 12, 11, 1,  9,   1,   27, 37, 2,  5,  4,  4,  63, 211, 95,  2,  2,  2,  1,  3,  5,  2,  1,  1,   2,  2,  1,  1,  1,   3,  2,  4,   1,  2,  1,  1,   5,  2,   2,  1,  1,  2,  3,   1,   3,   1,   1,   1,  3,  1,   4,  2,   1,   3,  6,  1,  1,
            3,  7,  15, 5,  3,  2,  5,  3,  9,  11, 4,  2,  22, 1,  6,  3,  8,   7,   1,  4,  28, 4,  16, 3,  3,  25,  4,   4,  27, 27, 1,  4,  1,  2,  2,  7,   1,  3,  5,  2,  28,  8,  2,  14,  1,  8,  6,  16,  25, 3,   3,  3,  14, 3,  3,   1,   1,   2,   1,   4,  6,  3,   8,  4,   1,   1,  1,  2,  3,
            6,  10, 6,  2,  3,  18, 3,  2,  5,  5,  4,  3,  1,  5,  2,  5,  4,   23,  7,  6,  12, 6,  4,  17, 11, 9,   5,   1,  1,  10, 5,  12, 1,  1,  11, 26,  33, 7,  3,  6,  1,   17, 7,  1,   5,  12, 1,  11,  2,  4,   1,  8,  14, 17, 23,  1,   2,   1,   7,   8,  16, 11,  9,  6,   5,   2,  6,  4,  16,
            2,  8,  14, 1,  11, 8,  9,  1,  1,  1,  9,  25, 4,  11, 19, 7,  2,   15,  2,  12, 8,  52, 7,  5,  19, 2,   16,  4,  36, 8,  1,  16, 8,  24, 26, 4,   6,  2,  9,  5,  4,   36, 3,  28,  12, 25, 15, 37,  27, 17,  12, 59, 38, 5,  32,  127, 1,   2,   9,   17, 14, 4,   1,  2,   1,   1,  8,  11, 50,
            4,  14, 2,  19, 16, 4,  17, 5,  4,  5,  26, 12, 45, 2,  23, 45, 104, 30,  12, 8,  3,  10, 2,  2,  3,  3,   1,   4,  20, 7,  2,  9,  6,  15, 2,  20,  1,  3,  16, 4,  11,  15, 6,  134, 2,  5,  59, 1,   2,  2,   2,  1,  9,  17, 3,   26,  137, 10,  211, 59, 1,  2,   4,  1,   4,   1,  1,  1,  2,
            6,  2,  3,  1,  1,  2,  3,  2,  3,  1,  3,  4,  4,  2,  3,  3,  1,   4,   3,  1,  7,  2,  2,  3,  1,  2,   1,   3,  3,  3,  2,  2,  3,  2,  1,  3,   14, 6,  1,  3,  2,   9,  6,  15,  27, 9,  34, 145, 1,  1,   2,  1,  1,  1,  1,   2,   1,   1,   1,   1,  2,  2,   2,  3,   1,   2,  1,  1,  1,
            2,  3,  5,  8,  3,  5,  2,  4,  1,  3,  2,  2,  2,  12, 4,  1,  1,   1,   10, 4,  5,  1,  20, 4,  16, 1,   15,  9,  5,  12, 2,  9,  2,  5,  4,  2,   26, 19, 7,  1,  26,  4,  30, 12,  15, 42, 1,  6,   8,  172, 1,  1,  4,  2,  1,   1,   11,  2,   2,   4,  2,  1,   2,  1,   10,  8,  1,  2,  1,
            4,  5,  1,  2,  5,  1,  8,  4,  1,  3,  4,  2,  1,  6,  2,  1,  3,   4,   1,  2,  1,  1,  1,  1,  12, 5,   7,   2,  4,  3,  1,  1,  1,  3,  3,  6,   1,  2,  2,  3,  3,   3,  2,  1,   2,  12, 14, 11,  6,  6,   4,  12, 2,  8,  1,   7,   10,  1,   35,  7,  4,  13,  15, 4,   3,   23, 21, 28, 52,
            5,  26, 5,  6,  1,  7,  10, 2,  7,  53, 3,  2,  1,  1,  1,  2,  163, 532, 1,  10, 11, 1,  3,  3,  4,  8,   2,   8,  6,  2,  2,  23, 22, 4,  2,  2,   4,  2,  1,  3,  1,   3,  3,  5,   9,  8,  2,  1,   2,  8,   1,  10, 2,  12, 21,  20,  15,  105, 2,   3,  1,  1,   3,  2,   3,   1,  1,  2,  5,
            1,  4,  15, 11, 19, 1,  1,  1,  1,  5,  4,  5,  1,  1,  2,  5,  3,   5,   12, 1,  2,  5,  1,  11, 1,  1,   15,  9,  1,  4,  5,  3,  26, 8,  2,  1,   3,  1,  1,  15, 19,  2,  12, 1,   2,  5,  2,  7,   2,  19,  2,  20, 6,  26, 7,   5,   2,   2,   7,   34, 21, 13,  70, 2,   128, 1,  1,  2,  1,
            1,  2,  1,  1,  3,  2,  2,  2,  15, 1,  4,  1,  3,  4,  42, 10, 6,   1,   49, 85, 8,  1,  2,  1,  1,  4,   4,   2,  3,  6,  1,  5,  7,  4,  3,  211, 4,  1,  2,  1,  2,   5,  1,  2,   4,  2,  2,  6,   5,  6,   10, 3,  4,  48, 100, 6,   2,   16,  296, 5,  27, 387, 2,  2,   3,   7,  16, 8,  5,
            38, 15, 39, 21, 9,  10, 3,  7,  59, 13, 27, 21, 47, 5,  21, 6,
        },
    );

    pub const japanese = genRanges(
        &[_][2]u32{
            .{ 0x0020, 0x00FF }, // Basic Latin + Latin Supplement
            .{ 0x3000, 0x30FF }, // CJK Symbols and Punctuations, Hiragana, Katakana
            .{ 0x31F0, 0x31FF }, // Katakana Phonetic Extensions
            .{ 0xFF00, 0xFFEF }, // Half-width characters
            .{ 0xFFFD, 0xFFFD }, // Invalid
        },
        0x4E00,
        &[_]f32{
            0,  1,  2,  4,  1,   1,   1,  1,  2,  1,  3,  3,  2,  2,  1,  5,  3,  5,  7,  5,  6,  1,   2,  1,  7,  2,  6,   3,  1,  8,  1,  1,  4,  1,  1,  18, 2,  11, 2,  6,  2,  1,  2,  1,  5,     1,  2,  1,  3,   1,  2,  1,  2,  3,  3,  1,  1,  2,  3,  1,  1,  1,  12, 7,  9,  1,  4,  5,  1,
            1,  2,  1,  10, 1,   1,   9,  2,  2,  4,  5,  6,  9,  3,  1,  1,  1,  1,  9,  3,  18, 5,   2,  2,  2,  2,  1,   6,  3,  7,  1,  1,  1,  1,  2,  2,  4,  2,  1,  23, 2,  10, 4,  3,  5,     2,  4,  10, 2,   4,  13, 1,  6,  1,  9,  3,  1,  1,  6,  6,  7,  6,  3,  1,  2,  11, 3,  2,  2,
            3,  2,  15, 2,  2,   5,   4,  3,  6,  4,  1,  2,  5,  2,  12, 16, 6,  13, 9,  13, 2,  1,   1,  7,  16, 4,  7,   1,  19, 1,  5,  1,  2,  2,  7,  7,  8,  2,  6,  5,  4,  9,  18, 7,  4,     5,  9,  13, 11,  8,  15, 2,  1,  1,  1,  2,  1,  2,  2,  1,  2,  2,  8,  2,  9,  3,  3,  1,  1,
            4,  4,  1,  1,  1,   4,   9,  1,  4,  3,  5,  5,  2,  7,  5,  3,  4,  8,  2,  1,  13, 2,   3,  3,  1,  14, 1,   1,  4,  5,  1,  3,  6,  1,  5,  2,  1,  1,  3,  3,  3,  3,  1,  1,  2,     7,  6,  6,  7,   1,  4,  7,  6,  1,  1,  1,  1,  1,  12, 3,  3,  9,  5,  2,  6,  1,  5,  6,  1,
            2,  3,  18, 2,  4,   14,  4,  1,  3,  6,  1,  1,  6,  3,  5,  5,  3,  2,  2,  2,  2,  12,  3,  1,  4,  2,  3,   2,  3,  11, 1,  7,  4,  1,  2,  1,  3,  17, 1,  9,  1,  24, 1,  1,  4,     2,  2,  4,  1,   2,  7,  1,  1,  1,  3,  1,  2,  2,  4,  15, 1,  1,  2,  1,  1,  2,  1,  5,  2,
            5,  20, 2,  5,  9,   1,   10, 8,  7,  6,  1,  1,  1,  1,  1,  1,  6,  2,  1,  2,  8,  1,   1,  1,  1,  5,  1,   1,  3,  1,  1,  1,  1,  3,  1,  1,  12, 4,  1,  3,  1,  1,  1,  1,  1,     10, 3,  1,  7,   5,  13, 1,  2,  3,  4,  6,  1,  1,  30, 2,  9,  9,  1,  15, 38, 11, 3,  1,  8,
            24, 7,  1,  9,  8,   10,  2,  1,  9,  31, 2,  13, 6,  2,  9,  4,  49, 5,  2,  15, 2,  1,   10, 2,  1,  1,  1,   2,  2,  6,  15, 30, 35, 3,  14, 18, 8,  1,  16, 10, 28, 12, 19, 45, 38,    1,  3,  2,  3,   13, 2,  1,  7,  3,  6,  5,  3,  4,  3,  1,  5,  7,  8,  1,  5,  3,  18, 5,  3,
            6,  1,  21, 4,  24,  9,   24, 40, 3,  14, 3,  21, 3,  2,  1,  2,  4,  2,  3,  1,  15, 15,  6,  5,  1,  1,  3,   1,  5,  6,  1,  9,  7,  3,  3,  2,  1,  4,  3,  8,  21, 5,  16, 4,  5,     2,  10, 11, 11,  3,  6,  3,  2,  9,  3,  6,  13, 1,  2,  1,  1,  1,  1,  11, 12, 6,  6,  1,  4,
            2,  6,  5,  2,  1,   1,   3,  3,  6,  13, 3,  1,  1,  5,  1,  2,  3,  3,  14, 2,  1,  2,   2,  2,  5,  1,  9,   5,  1,  1,  6,  12, 3,  12, 3,  4,  13, 2,  14, 2,  8,  1,  17, 5,  1,     16, 4,  2,  2,   21, 8,  9,  6,  23, 20, 12, 25, 19, 9,  38, 8,  3,  21, 40, 25, 33, 13, 4,  3,
            1,  4,  1,  2,  4,   1,   2,  5,  26, 2,  1,  1,  2,  1,  3,  6,  2,  1,  1,  1,  1,  1,   1,  2,  3,  1,  1,   1,  9,  2,  3,  1,  1,  1,  3,  6,  3,  2,  1,  1,  6,  6,  1,  8,  2,     2,  2,  1,  4,   1,  2,  3,  2,  7,  3,  2,  4,  1,  2,  1,  2,  2,  1,  1,  1,  1,  1,  3,  1,
            2,  5,  4,  10, 9,   4,   9,  1,  1,  1,  1,  1,  1,  5,  3,  2,  1,  6,  4,  9,  6,  1,   10, 2,  31, 17, 8,   3,  7,  5,  40, 1,  7,  7,  1,  6,  5,  2,  10, 7,  8,  4,  15, 39, 25,    6,  28, 47, 18,  10, 7,  1,  3,  1,  1,  2,  1,  1,  1,  3,  3,  3,  1,  1,  1,  3,  4,  2,  1,
            4,  1,  3,  6,  10,  7,   8,  6,  2,  2,  1,  3,  3,  2,  5,  8,  7,  9,  12, 2,  15, 1,   1,  4,  1,  2,  1,   1,  1,  3,  2,  1,  3,  3,  5,  6,  2,  3,  2,  10, 1,  4,  2,  8,  1,     1,  1,  11, 6,   1,  21, 4,  16, 3,  1,  3,  1,  4,  2,  3,  6,  5,  1,  3,  1,  1,  3,  3,  4,
            6,  1,  1,  10, 4,   2,   7,  10, 4,  7,  4,  2,  9,  4,  3,  1,  1,  1,  4,  1,  8,  3,   4,  1,  3,  1,  6,   1,  4,  2,  1,  4,  7,  2,  1,  8,  1,  4,  5,  1,  1,  2,  2,  4,  6,     2,  7,  1,  10,  1,  1,  3,  4,  11, 10, 8,  21, 4,  6,  1,  3,  5,  2,  1,  2,  28, 5,  5,  2,
            3,  13, 1,  2,  3,   1,   4,  2,  1,  5,  20, 3,  8,  11, 1,  3,  3,  3,  1,  8,  10, 9,   2,  10, 9,  2,  3,   1,  1,  2,  4,  1,  8,  3,  6,  1,  7,  8,  6,  11, 1,  4,  29, 8,  4,     3,  1,  2,  7,   13, 1,  4,  1,  6,  2,  6,  12, 12, 2,  20, 3,  2,  3,  6,  4,  8,  9,  2,  7,
            34, 5,  1,  18, 6,   1,   1,  4,  4,  5,  7,  9,  1,  2,  2,  4,  3,  4,  1,  7,  2,  2,   2,  6,  2,  3,  25,  5,  3,  6,  1,  4,  6,  7,  4,  2,  1,  4,  2,  13, 6,  4,  4,  3,  1,     5,  3,  4,  4,   3,  2,  1,  1,  4,  1,  2,  1,  1,  3,  1,  11, 1,  6,  3,  1,  7,  3,  6,  2,
            8,  8,  6,  9,  3,   4,   11, 3,  2,  10, 12, 2,  5,  11, 1,  6,  4,  5,  3,  1,  8,  5,   4,  6,  6,  3,  5,   1,  1,  3,  2,  1,  2,  2,  6,  17, 12, 1,  10, 1,  6,  12, 1,  6,  6,     19, 9,  6,  16,  1,  13, 4,  4,  15, 7,  17, 6,  11, 9,  15, 12, 6,  7,  2,  1,  2,  2,  15, 9,
            3,  21, 4,  6,  49,  18,  7,  3,  2,  3,  1,  6,  8,  2,  2,  6,  2,  9,  1,  3,  6,  4,   4,  1,  2,  16, 2,   5,  2,  1,  6,  2,  3,  5,  3,  1,  2,  5,  1,  2,  1,  9,  3,  1,  8,     6,  4,  8,  11,  3,  1,  1,  1,  1,  3,  1,  13, 8,  4,  1,  3,  2,  2,  1,  4,  1,  11, 1,  5,
            2,  1,  5,  2,  5,   8,   6,  1,  1,  7,  4,  3,  8,  3,  2,  7,  2,  1,  5,  1,  5,  2,   4,  7,  6,  2,  8,   5,  1,  11, 4,  5,  3,  6,  18, 1,  2,  13, 3,  3,  1,  21, 1,  1,  4,     1,  4,  1,  1,   1,  8,  1,  2,  2,  7,  1,  2,  4,  2,  2,  9,  2,  1,  1,  1,  4,  3,  6,  3,
            12, 5,  1,  1,  1,   5,   6,  3,  2,  4,  8,  2,  2,  4,  2,  7,  1,  8,  9,  5,  2,  3,   2,  1,  3,  2,  13,  7,  14, 6,  5,  1,  1,  2,  1,  4,  2,  23, 2,  1,  1,  6,  3,  1,  4,     1,  15, 3,  1,   7,  3,  9,  14, 1,  3,  1,  4,  1,  1,  5,  8,  1,  3,  8,  3,  8,  15, 11, 4,
            14, 4,  4,  2,  5,   5,   1,  7,  1,  6,  14, 7,  7,  8,  5,  15, 4,  8,  6,  5,  6,  2,   1,  13, 1,  20, 15,  11, 9,  2,  5,  6,  2,  11, 2,  6,  2,  5,  1,  5,  8,  4,  13, 19, 25,    4,  1,  1,  11,  1,  34, 2,  5,  9,  14, 6,  2,  2,  6,  1,  1,  14, 1,  3,  14, 13, 1,  6,  12,
            21, 14, 14, 6,  32,  17,  8,  32, 9,  28, 1,  2,  4,  11, 8,  3,  1,  14, 2,  5,  15, 1,   1,  1,  1,  3,  6,   4,  1,  3,  4,  11, 3,  1,  1,  11, 30, 1,  5,  1,  4,  1,  5,  8,  1,     1,  3,  2,  4,   3,  17, 35, 2,  6,  12, 17, 3,  1,  6,  2,  1,  1,  12, 2,  7,  3,  3,  2,  1,
            16, 2,  8,  3,  6,   5,   4,  7,  3,  3,  8,  1,  9,  8,  5,  1,  2,  1,  3,  2,  8,  1,   2,  9,  12, 1,  1,   2,  3,  8,  3,  24, 12, 4,  3,  7,  5,  8,  3,  3,  3,  3,  3,  3,  1,     23, 10, 3,  1,   2,  2,  6,  3,  1,  16, 1,  16, 22, 3,  10, 4,  11, 6,  9,  7,  7,  3,  6,  2,
            2,  2,  4,  10, 2,   1,   1,  2,  8,  7,  1,  6,  4,  1,  3,  3,  3,  5,  10, 12, 12, 2,   3,  12, 8,  15, 1,   1,  16, 6,  6,  1,  5,  9,  11, 4,  11, 4,  2,  6,  12, 1,  17, 5,  13,    1,  4,  9,  5,   1,  11, 2,  1,  8,  1,  5,  7,  28, 8,  3,  5,  10, 2,  17, 3,  38, 22, 1,  2,
            18, 12, 10, 4,  38,  18,  1,  4,  44, 19, 4,  1,  8,  4,  1,  12, 1,  4,  31, 12, 1,  14,  7,  75, 7,  5,  10,  6,  6,  13, 3,  2,  11, 11, 3,  2,  5,  28, 15, 6,  18, 18, 5,  6,  4,     3,  16, 1,  7,   18, 7,  36, 3,  5,  3,  1,  7,  1,  9,  1,  10, 7,  2,  4,  2,  6,  2,  9,  7,
            4,  3,  32, 12, 3,   7,   10, 2,  23, 16, 3,  1,  12, 3,  31, 4,  11, 1,  3,  8,  9,  5,   1,  30, 15, 6,  12,  3,  2,  2,  11, 19, 9,  14, 2,  6,  2,  3,  19, 13, 17, 5,  3,  3,  25,    3,  14, 1,  1,   1,  36, 1,  3,  2,  19, 3,  13, 36, 9,  13, 31, 6,  4,  16, 34, 2,  5,  4,  2,
            3,  3,  5,  1,  1,   1,   4,  3,  1,  17, 3,  2,  3,  5,  3,  1,  3,  2,  3,  5,  6,  3,   12, 11, 1,  3,  1,   2,  26, 7,  12, 7,  2,  14, 3,  3,  7,  7,  11, 25, 25, 28, 16, 4,  36,    1,  2,  1,  6,   2,  1,  9,  3,  27, 17, 4,  3,  4,  13, 4,  1,  3,  2,  2,  1,  10, 4,  2,  4,
            6,  3,  8,  2,  1,   18,  1,  1,  24, 2,  2,  4,  33, 2,  3,  63, 7,  1,  6,  40, 7,  3,   4,  4,  2,  4,  15,  18, 1,  16, 1,  1,  11, 2,  41, 14, 1,  3,  18, 13, 3,  2,  4,  16, 2,     17, 7,  15, 24,  7,  18, 13, 44, 2,  2,  3,  6,  1,  1,  7,  5,  1,  7,  1,  4,  3,  3,  5,  10,
            8,  2,  3,  1,  8,   1,   1,  27, 4,  2,  1,  12, 1,  2,  1,  10, 6,  1,  6,  7,  5,  2,   3,  7,  11, 5,  11,  3,  6,  6,  2,  3,  15, 4,  9,  1,  1,  2,  1,  2,  11, 2,  8,  12, 8,     5,  4,  2,  3,   1,  5,  2,  2,  1,  14, 1,  12, 11, 4,  1,  11, 17, 17, 4,  3,  2,  5,  5,  7,
            3,  1,  5,  9,  9,   8,   2,  5,  6,  6,  13, 13, 2,  1,  2,  6,  1,  2,  2,  49, 4,  9,   1,  2,  10, 16, 7,   8,  4,  3,  2,  23, 4,  58, 3,  29, 1,  14, 19, 19, 11, 11, 2,  7,  5,     1,  3,  4,  6,   2,  18, 5,  12, 12, 17, 17, 3,  3,  2,  4,  1,  6,  2,  3,  4,  3,  1,  1,  1,
            1,  5,  1,  1,  9,   1,   3,  1,  3,  6,  1,  8,  1,  1,  2,  6,  4,  14, 3,  1,  4,  11,  4,  1,  3,  32, 1,   2,  4,  13, 4,  1,  2,  4,  2,  1,  3,  1,  11, 1,  4,  2,  1,  4,  4,     6,  3,  5,  1,   6,  5,  7,  6,  3,  23, 3,  5,  3,  5,  3,  3,  13, 3,  9,  10, 1,  12, 10, 2,
            3,  18, 13, 7,  160, 52,  4,  2,  2,  3,  2,  14, 5,  4,  12, 4,  6,  4,  1,  20, 4,  11,  6,  2,  12, 27, 1,   4,  1,  2,  2,  7,  4,  5,  2,  28, 3,  7,  25, 8,  3,  19, 3,  6,  10,    2,  2,  1,  10,  2,  5,  4,  1,  3,  4,  1,  5,  3,  2,  6,  9,  3,  6,  2,  16, 3,  3,  16, 4,
            5,  5,  3,  2,  1,   2,   16, 15, 8,  2,  6,  21, 2,  4,  1,  22, 5,  8,  1,  1,  21, 11,  2,  1,  11, 11, 19,  13, 12, 4,  2,  3,  2,  3,  6,  1,  8,  11, 1,  4,  2,  9,  5,  2,  1,     11, 2,  9,  1,   1,  2,  14, 31, 9,  3,  4,  21, 14, 4,  8,  1,  7,  2,  2,  2,  5,  1,  4,  20,
            3,  3,  4,  10, 1,   11,  9,  8,  2,  1,  4,  5,  14, 12, 14, 2,  17, 9,  6,  31, 4,  14,  1,  20, 13, 26, 5,   2,  7,  3,  6,  13, 2,  4,  2,  19, 6,  2,  2,  18, 9,  3,  5,  12, 12,    14, 4,  6,  2,   3,  6,  9,  5,  22, 4,  5,  25, 6,  4,  8,  5,  2,  6,  27, 2,  35, 2,  16, 3,
            7,  8,  8,  6,  6,   5,   9,  17, 2,  20, 6,  19, 2,  13, 3,  1,  1,  1,  4,  17, 12, 2,   14, 7,  1,  4,  18,  12, 38, 33, 2,  10, 1,  1,  2,  13, 14, 17, 11, 50, 6,  33, 20, 26, 74,    16, 23, 45, 50,  13, 38, 33, 6,  6,  7,  4,  4,  2,  1,  3,  2,  5,  8,  7,  8,  9,  3,  11, 21,
            9,  13, 1,  3,  10,  6,   7,  1,  2,  2,  18, 5,  5,  1,  9,  9,  2,  68, 9,  19, 13, 2,   5,  1,  4,  4,  7,   4,  13, 3,  9,  10, 21, 17, 3,  26, 2,  1,  5,  2,  4,  5,  4,  1,  7,     4,  7,  3,  4,   2,  1,  6,  1,  1,  20, 4,  1,  9,  2,  2,  1,  3,  3,  2,  3,  2,  1,  1,  1,
            20, 2,  3,  1,  6,   2,   3,  6,  2,  4,  8,  1,  3,  2,  10, 3,  5,  3,  4,  4,  3,  4,   16, 1,  6,  1,  10,  2,  4,  2,  1,  1,  2,  10, 11, 2,  2,  3,  1,  24, 31, 4,  10, 10, 2,     5,  12, 16, 164, 15, 4,  16, 7,  9,  15, 19, 17, 1,  2,  1,  1,  5,  1,  1,  1,  1,  1,  3,  1,
            4,  3,  1,  3,  1,   3,   1,  2,  1,  1,  3,  3,  7,  2,  8,  1,  2,  2,  2,  1,  3,  4,   3,  7,  8,  12, 92,  2,  10, 3,  1,  3,  14, 5,  25, 16, 42, 4,  7,  7,  4,  2,  21, 5,  27,    26, 27, 21, 25,  30, 31, 2,  1,  5,  13, 3,  22, 5,  6,  6,  11, 9,  12, 1,  5,  9,  7,  5,  5,
            22, 60, 3,  5,  13,  1,   1,  8,  1,  1,  3,  3,  2,  1,  9,  3,  3,  18, 4,  1,  2,  3,   7,  6,  3,  1,  2,   3,  9,  1,  3,  1,  3,  2,  1,  3,  1,  1,  1,  2,  1,  11, 3,  1,  6,     9,  1,  3,  2,   3,  1,  2,  1,  5,  1,  1,  4,  3,  4,  1,  2,  2,  4,  4,  1,  7,  2,  1,  2,
            2,  3,  5,  13, 18,  3,   4,  14, 9,  9,  4,  16, 3,  7,  5,  8,  2,  6,  48, 28, 3,  1,   1,  4,  2,  14, 8,   2,  9,  2,  1,  15, 2,  4,  3,  2,  10, 16, 12, 8,  7,  1,  1,  3,  1,     1,  1,  2,  7,   4,  1,  6,  4,  38, 39, 16, 23, 7,  15, 15, 3,  2,  12, 7,  21, 37, 27, 6,  5,
            4,  8,  2,  10, 8,   8,   6,  5,  1,  2,  1,  3,  24, 1,  16, 17, 9,  23, 10, 17, 6,  1,   51, 55, 44, 13, 294, 9,  3,  6,  2,  4,  2,  2,  15, 1,  1,  1,  13, 21, 17, 68, 14, 8,  9,     4,  1,  4,  9,   3,  11, 7,  1,  1,  1,  5,  6,  3,  2,  1,  1,  1,  2,  3,  8,  1,  2,  2,  4,
            1,  5,  5,  2,  1,   4,   3,  7,  13, 4,  1,  4,  1,  3,  1,  1,  1,  5,  5,  10, 1,  6,   1,  5,  2,  1,  5,   2,  4,  1,  4,  5,  7,  3,  18, 2,  9,  11, 32, 4,  3,  3,  2,  4,  7,     11, 16, 9,  11,  8,  13, 38, 32, 8,  4,  2,  1,  1,  2,  1,  2,  4,  4,  1,  1,  1,  4,  1,  21,
            3,  11, 1,  16, 1,   1,   6,  1,  3,  2,  4,  9,  8,  57, 7,  44, 1,  3,  3,  13, 3,  10,  1,  1,  7,  5,  2,   7,  21, 47, 63, 3,  15, 4,  7,  1,  16, 1,  1,  2,  8,  2,  3,  42, 15,    4,  1,  29, 7,   22, 10, 3,  78, 16, 12, 20, 18, 4,  67, 11, 5,  1,  3,  15, 6,  21, 31, 32, 27,
            18, 13, 71, 35, 5,   142, 4,  10, 1,  2,  50, 19, 33, 16, 35, 37, 16, 19, 27, 7,  1,  133, 19, 1,  4,  8,  7,   20, 1,  4,  4,  1,  10, 3,  1,  6,  1,  2,  51, 5,  40, 15, 24, 43, 22928, 11, 1,  13, 154, 70, 3,  1,  1,  7,  4,  10, 1,  2,  1,  1,  2,  1,  2,  1,  2,  2,  1,  1,  2,
            1,  1,  1,  1,  1,   2,   1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  2,  1,  1,   1,  3,  2,  1,  1,   1,  1,  2,  1,  1,
        },
    );

    fn genRanges(
        comptime base_ranges: []const [2]u32,
        comptime base_codepoint: u32,
        comptime offsets: []const u32,
    ) [base_ranges.len + offsets.len][2]u32 {
        var ranges: [base_ranges.len + offsets.len][2]u32 = undefined;
        std.mem.copy([2]u32, ranges[0..], base_ranges);
        unpackAccumulativeOffsets(
            base_codepoint,
            offsets,
            ranges[base_ranges.len..],
        );
        return ranges;
    }

    fn unpackAccumulativeOffsets(
        comptime _base_codepoint: u32,
        comptime offsets: []const u32,
        comptime results: [][2]u32,
    ) void {
        @setEvalBranchQuota(10000);
        assert(offsets.len == results.len);
        var base_codepoint = _base_codepoint;
        for (offsets) |off, i| {
            base_codepoint += off;
            results[i][0] = base_codepoint;
            results[i][1] = base_codepoint;
        }
    }
};

/// font atlas
pub const Atlas = struct {
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

    /// create font atlas
    fn init(
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

        // generate atlas
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

        // create texture
        var tex = try gfx.utils.createTextureFromPixels(
            renderer,
            real_pixels,
            gfx.utils.getFormatByEndian(),
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

    pub fn deinit(self: Atlas) void {
        self.tex.deinit();
        for (self.ranges.items) |r| {
            r.packedchar.deinit();
        }
        self.ranges.deinit();
    }

    pub fn getVPosOfNextLine(self: Atlas, current_ypos: f32) f32 {
        return current_ypos + @round((self.vmetric_ascent - self.vmetric_descent + self.vmetric_line_gap) * self.scale);
    }

    /// append draw data for rendering utf8 string, return drawing area
    pub const YPosType = enum { baseline, top, bottom };
    pub fn appendDrawDataFromUTF8String(
        self: Atlas,
        text: []const u8,
        pos: sdl.PointF,
        ypos_type: YPosType,
        color: sdl.Color,
        vattrib: *std.ArrayList(sdl.Vertex),
        vindices: *std.ArrayList(u32),
    ) !sdl.RectangleF {
        var xpos = pos.x;
        var ypos = pos.y;
        var pxpos = &xpos;
        var pypos = &ypos;
        var rect = sdl.RectangleF{ .x = pos.x, .y = std.math.floatMax(f32), .width = 0, .height = 0 };

        if (text.len == 0) return rect;

        var i: u32 = 0;
        while (i < text.len) {
            var size = try unicode.utf8ByteSequenceLength(text[i]);
            var codepoint = @intCast(u32, try unicode.utf8Decode(text[i .. i + size]));

            // TODO: use simple loop searching for now, may need optimization
            for (self.ranges.items) |range| {
                if (codepoint < range.codepoint_begin or codepoint > range.codepoint_end) continue;

                var quad: truetype.stbtt_aligned_quad = undefined;
                const info = try self.tex.query();
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
                const base_index = @intCast(u32, vattrib.items.len);
                try vattrib.appendSlice(&[_]sdl.Vertex{
                    .{
                        .position = .{ .x = quad.x0, .y = quad.y0 + yoffset },
                        .color = color,
                        .tex_coord = .{ .x = quad.s0, .y = quad.t0 },
                    },
                    .{
                        .position = .{ .x = quad.x0, .y = quad.y1 + yoffset },
                        .color = color,
                        .tex_coord = .{ .x = quad.s0, .y = quad.t1 },
                    },
                    .{
                        .position = .{ .x = quad.x1, .y = quad.y1 + yoffset },
                        .color = color,
                        .tex_coord = .{ .x = quad.s1, .y = quad.t1 },
                    },
                    .{
                        .position = .{ .x = quad.x1, .y = quad.y0 + yoffset },
                        .color = color,
                        .tex_coord = .{ .x = quad.s1, .y = quad.t0 },
                    },
                });
                try vindices.appendSlice(&[_]u32{
                    base_index,
                    base_index + 1,
                    base_index + 2,
                    base_index,
                    base_index + 2,
                    base_index + 3,
                });
                if (quad.y0 + yoffset < rect.y) rect.y = quad.y0 + yoffset;
                if (quad.y1 + yoffset - rect.y > rect.height) rect.height = quad.y1 + yoffset - rect.y;
                break;
            }
            i += size;
        }

        rect.width = pxpos.* - rect.x;
        return rect;
    }
};

/// draw debug text using builtin font
pub const DrawOption = struct {
    pos: sdl.PointF,
    ypos_type: Atlas.YPosType = .top,
    color: sdl.Color = sdl.Color.black,
    font_size: u32 = 16,
};
pub const DrawResult = struct {
    area: sdl.RectangleF,
    next_line_ypos: f32,
};
pub fn debugDraw(renderer: sdl.Renderer, text: []const u8, opt: DrawOption) !DrawResult {
    const S = struct {
        const allocator = std.heap.c_allocator;
        const font_data = @embedFile("clacon2.ttf");
        const max_text_size = 1000;
        var font: ?*Self = null;
        var atlases: std.AutoHashMap(u32, Atlas) = undefined;
        var vattrib: std.ArrayList(sdl.Vertex) = undefined;
        var vindices: std.ArrayList(u32) = undefined;
    };

    if (text.len == 0) return DrawResult{
        .area = .{ .x = opt.pos.x, .y = opt.pos.y, .width = 0, .height = 0 },
        .next_line_ypos = 0,
    };

    // initialize font data and atlases as needed
    if (S.font == null) {
        S.font = fromTrueTypeData(S.allocator, S.font_data) catch unreachable;
        S.atlases = std.AutoHashMap(u32, Atlas).init(S.allocator);
        S.vattrib = std.ArrayList(sdl.Vertex).initCapacity(S.allocator, S.max_text_size * 4) catch unreachable;
        S.vindices = std.ArrayList(u32).initCapacity(S.allocator, S.max_text_size * 6) catch unreachable;
    }
    var atlas: Atlas = undefined;
    if (S.atlases.get(opt.font_size)) |a| {
        atlas = a;
    } else {
        atlas = S.font.?.createAtlas(
            renderer,
            opt.font_size,
            &[_][2]u32{
                .{ 0x0020, 0x00FF }, // Basic Latin + Latin Supplement
                .{ 0x2500, 0x25FF }, // Special marks (block, line, triangle etc)
                .{ 0x2801, 0x28FF }, // Braille
                .{ 0x16A0, 0x16F0 }, // Runic
            },
            2048,
        ) catch unreachable;
        try S.atlases.put(opt.font_size, atlas);
    }

    defer S.vattrib.clearRetainingCapacity();
    defer S.vindices.clearRetainingCapacity();

    assert(text.len < S.max_text_size);
    const area = try atlas.appendDrawDataFromUTF8String(
        text,
        opt.pos,
        opt.ypos_type,
        opt.color,
        &S.vattrib,
        &S.vindices,
    );
    try renderer.drawGeometry(atlas.tex, S.vattrib.items, S.vindices.items);
    return DrawResult{
        .area = area,
        .next_line_ypos = atlas.getVPosOfNextLine(opt.pos.y),
    };
}
