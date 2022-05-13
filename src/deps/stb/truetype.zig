pub const stbtt__buf = extern struct {
    data: [*c]u8,
    cursor: c_int,
    size: c_int,
};
pub const stbtt_bakedchar = extern struct {
    x0: c_ushort,
    y0: c_ushort,
    x1: c_ushort,
    y1: c_ushort,
    xoff: f32,
    yoff: f32,
    xadvance: f32,
};
pub extern fn stbtt_BakeFontBitmap(data: [*c]const u8, offset: c_int, pixel_height: f32, pixels: [*c]u8, pw: c_int, ph: c_int, first_char: c_int, num_chars: c_int, chardata: [*c]stbtt_bakedchar) c_int;
pub const stbtt_aligned_quad = extern struct {
    x0: f32,
    y0: f32,
    s0: f32,
    t0: f32,
    x1: f32,
    y1: f32,
    s1: f32,
    t1: f32,
};
pub extern fn stbtt_GetBakedQuad(chardata: [*c]const stbtt_bakedchar, pw: c_int, ph: c_int, char_index: c_int, xpos: [*c]f32, ypos: [*c]f32, q: [*c]stbtt_aligned_quad, opengl_fillrule: c_int) void;
pub extern fn stbtt_GetScaledFontVMetrics(fontdata: [*c]const u8, index: c_int, size: f32, ascent: [*c]f32, descent: [*c]f32, lineGap: [*c]f32) void;
pub const stbtt_packedchar = extern struct {
    x0: c_ushort,
    y0: c_ushort,
    x1: c_ushort,
    y1: c_ushort,
    xoff: f32,
    yoff: f32,
    xadvance: f32,
    xoff2: f32,
    yoff2: f32,
};
pub const struct_stbtt_pack_context = extern struct {
    user_allocator_context: ?*anyopaque,
    pack_info: ?*anyopaque,
    width: c_int,
    height: c_int,
    stride_in_bytes: c_int,
    padding: c_int,
    skip_missing: c_int,
    h_oversample: c_uint,
    v_oversample: c_uint,
    pixels: [*c]u8,
    nodes: ?*anyopaque,
};
pub const stbtt_pack_context = struct_stbtt_pack_context;
pub const struct_stbtt_fontinfo = extern struct {
    userdata: ?*anyopaque,
    data: [*c]u8,
    fontstart: c_int,
    numGlyphs: c_int,
    loca: c_int,
    head: c_int,
    glyf: c_int,
    hhea: c_int,
    hmtx: c_int,
    kern: c_int,
    gpos: c_int,
    svg: c_int,
    index_map: c_int,
    indexToLocFormat: c_int,
    cff: stbtt__buf,
    charstrings: stbtt__buf,
    gsubrs: stbtt__buf,
    subrs: stbtt__buf,
    fontdicts: stbtt__buf,
    fdselect: stbtt__buf,
};
pub const stbtt_fontinfo = struct_stbtt_fontinfo;
pub const struct_stbrp_rect = opaque {};
pub const stbrp_rect = struct_stbrp_rect;
pub extern fn stbtt_PackBegin(spc: [*c]stbtt_pack_context, pixels: [*c]u8, width: c_int, height: c_int, stride_in_bytes: c_int, padding: c_int, alloc_context: ?*anyopaque) c_int;
pub extern fn stbtt_PackEnd(spc: [*c]stbtt_pack_context) void;
pub extern fn stbtt_PackFontRange(spc: [*c]stbtt_pack_context, fontdata: [*c]const u8, font_index: c_int, font_size: f32, first_unicode_char_in_range: c_int, num_chars_in_range: c_int, chardata_for_range: [*c]stbtt_packedchar) c_int;
pub const stbtt_pack_range = extern struct {
    font_size: f32,
    first_unicode_codepoint_in_range: c_int,
    array_of_unicode_codepoints: [*c]c_int,
    num_chars: c_int,
    chardata_for_range: [*c]stbtt_packedchar,
    h_oversample: u8,
    v_oversample: u8,
};
pub extern fn stbtt_PackFontRanges(spc: [*c]stbtt_pack_context, fontdata: [*c]const u8, font_index: c_int, ranges: [*c]stbtt_pack_range, num_ranges: c_int) c_int;
pub extern fn stbtt_PackSetOversampling(spc: [*c]stbtt_pack_context, h_oversample: c_uint, v_oversample: c_uint) void;
pub extern fn stbtt_PackSetSkipMissingCodepoints(spc: [*c]stbtt_pack_context, skip: c_int) void;
pub extern fn stbtt_GetPackedQuad(chardata: [*c]const stbtt_packedchar, pw: c_int, ph: c_int, char_index: c_int, xpos: [*c]f32, ypos: [*c]f32, q: [*c]stbtt_aligned_quad, align_to_integer: c_int) void;
pub extern fn stbtt_PackFontRangesGatherRects(spc: [*c]stbtt_pack_context, info: [*c]const stbtt_fontinfo, ranges: [*c]stbtt_pack_range, num_ranges: c_int, rects: ?*stbrp_rect) c_int;
pub extern fn stbtt_PackFontRangesPackRects(spc: [*c]stbtt_pack_context, rects: ?*stbrp_rect, num_rects: c_int) void;
pub extern fn stbtt_PackFontRangesRenderIntoRects(spc: [*c]stbtt_pack_context, info: [*c]const stbtt_fontinfo, ranges: [*c]stbtt_pack_range, num_ranges: c_int, rects: ?*stbrp_rect) c_int;
pub extern fn stbtt_GetNumberOfFonts(data: [*c]const u8) c_int;
pub extern fn stbtt_GetFontOffsetForIndex(data: [*c]const u8, index: c_int) c_int;
pub extern fn stbtt_InitFont(info: [*c]stbtt_fontinfo, data: [*c]const u8, offset: c_int) c_int;
pub extern fn stbtt_FindGlyphIndex(info: [*c]const stbtt_fontinfo, unicode_codepoint: c_int) c_int;
pub extern fn stbtt_ScaleForPixelHeight(info: [*c]const stbtt_fontinfo, pixels: f32) f32;
pub extern fn stbtt_ScaleForMappingEmToPixels(info: [*c]const stbtt_fontinfo, pixels: f32) f32;
pub extern fn stbtt_GetFontVMetrics(info: [*c]const stbtt_fontinfo, ascent: [*c]c_int, descent: [*c]c_int, lineGap: [*c]c_int) void;
pub extern fn stbtt_GetFontVMetricsOS2(info: [*c]const stbtt_fontinfo, typoAscent: [*c]c_int, typoDescent: [*c]c_int, typoLineGap: [*c]c_int) c_int;
pub extern fn stbtt_GetFontBoundingBox(info: [*c]const stbtt_fontinfo, x0: [*c]c_int, y0: [*c]c_int, x1: [*c]c_int, y1: [*c]c_int) void;
pub extern fn stbtt_GetCodepointHMetrics(info: [*c]const stbtt_fontinfo, codepoint: c_int, advanceWidth: [*c]c_int, leftSideBearing: [*c]c_int) void;
pub extern fn stbtt_GetCodepointKernAdvance(info: [*c]const stbtt_fontinfo, ch1: c_int, ch2: c_int) c_int;
pub extern fn stbtt_GetCodepointBox(info: [*c]const stbtt_fontinfo, codepoint: c_int, x0: [*c]c_int, y0: [*c]c_int, x1: [*c]c_int, y1: [*c]c_int) c_int;
pub extern fn stbtt_GetGlyphHMetrics(info: [*c]const stbtt_fontinfo, glyph_index: c_int, advanceWidth: [*c]c_int, leftSideBearing: [*c]c_int) void;
pub extern fn stbtt_GetGlyphKernAdvance(info: [*c]const stbtt_fontinfo, glyph1: c_int, glyph2: c_int) c_int;
pub extern fn stbtt_GetGlyphBox(info: [*c]const stbtt_fontinfo, glyph_index: c_int, x0: [*c]c_int, y0: [*c]c_int, x1: [*c]c_int, y1: [*c]c_int) c_int;
pub const struct_stbtt_kerningentry = extern struct {
    glyph1: c_int,
    glyph2: c_int,
    advance: c_int,
};
pub const stbtt_kerningentry = struct_stbtt_kerningentry;
pub extern fn stbtt_GetKerningTableLength(info: [*c]const stbtt_fontinfo) c_int;
pub extern fn stbtt_GetKerningTable(info: [*c]const stbtt_fontinfo, table: [*c]stbtt_kerningentry, table_length: c_int) c_int;
pub const STBTT_vmove: c_int = 1;
pub const STBTT_vline: c_int = 2;
pub const STBTT_vcurve: c_int = 3;
pub const STBTT_vcubic: c_int = 4;
const enum_unnamed_1 = c_uint;
pub const stbtt_vertex = extern struct {
    x: c_short,
    y: c_short,
    cx: c_short,
    cy: c_short,
    cx1: c_short,
    cy1: c_short,
    type: u8,
    padding: u8,
};
pub extern fn stbtt_IsGlyphEmpty(info: [*c]const stbtt_fontinfo, glyph_index: c_int) c_int;
pub extern fn stbtt_GetCodepointShape(info: [*c]const stbtt_fontinfo, unicode_codepoint: c_int, vertices: [*c][*c]stbtt_vertex) c_int;
pub extern fn stbtt_GetGlyphShape(info: [*c]const stbtt_fontinfo, glyph_index: c_int, vertices: [*c][*c]stbtt_vertex) c_int;
pub extern fn stbtt_FreeShape(info: [*c]const stbtt_fontinfo, vertices: [*c]stbtt_vertex) void;
pub extern fn stbtt_GetCodepointSVG(info: [*c]const stbtt_fontinfo, unicode_codepoint: c_int, svg: [*c][*c]const u8) c_int;
pub extern fn stbtt_GetGlyphSVG(info: [*c]const stbtt_fontinfo, gl: c_int, svg: [*c][*c]const u8) c_int;
pub extern fn stbtt_FreeBitmap(bitmap: [*c]u8, userdata: ?*anyopaque) void;
pub extern fn stbtt_GetCodepointBitmap(info: [*c]const stbtt_fontinfo, scale_x: f32, scale_y: f32, codepoint: c_int, width: [*c]c_int, height: [*c]c_int, xoff: [*c]c_int, yoff: [*c]c_int) [*c]u8;
pub extern fn stbtt_GetCodepointBitmapSubpixel(info: [*c]const stbtt_fontinfo, scale_x: f32, scale_y: f32, shift_x: f32, shift_y: f32, codepoint: c_int, width: [*c]c_int, height: [*c]c_int, xoff: [*c]c_int, yoff: [*c]c_int) [*c]u8;
pub extern fn stbtt_MakeCodepointBitmap(info: [*c]const stbtt_fontinfo, output: [*c]u8, out_w: c_int, out_h: c_int, out_stride: c_int, scale_x: f32, scale_y: f32, codepoint: c_int) void;
pub extern fn stbtt_MakeCodepointBitmapSubpixel(info: [*c]const stbtt_fontinfo, output: [*c]u8, out_w: c_int, out_h: c_int, out_stride: c_int, scale_x: f32, scale_y: f32, shift_x: f32, shift_y: f32, codepoint: c_int) void;
pub extern fn stbtt_MakeCodepointBitmapSubpixelPrefilter(info: [*c]const stbtt_fontinfo, output: [*c]u8, out_w: c_int, out_h: c_int, out_stride: c_int, scale_x: f32, scale_y: f32, shift_x: f32, shift_y: f32, oversample_x: c_int, oversample_y: c_int, sub_x: [*c]f32, sub_y: [*c]f32, codepoint: c_int) void;
pub extern fn stbtt_GetCodepointBitmapBox(font: [*c]const stbtt_fontinfo, codepoint: c_int, scale_x: f32, scale_y: f32, ix0: [*c]c_int, iy0: [*c]c_int, ix1: [*c]c_int, iy1: [*c]c_int) void;
pub extern fn stbtt_GetCodepointBitmapBoxSubpixel(font: [*c]const stbtt_fontinfo, codepoint: c_int, scale_x: f32, scale_y: f32, shift_x: f32, shift_y: f32, ix0: [*c]c_int, iy0: [*c]c_int, ix1: [*c]c_int, iy1: [*c]c_int) void;
pub extern fn stbtt_GetGlyphBitmap(info: [*c]const stbtt_fontinfo, scale_x: f32, scale_y: f32, glyph: c_int, width: [*c]c_int, height: [*c]c_int, xoff: [*c]c_int, yoff: [*c]c_int) [*c]u8;
pub extern fn stbtt_GetGlyphBitmapSubpixel(info: [*c]const stbtt_fontinfo, scale_x: f32, scale_y: f32, shift_x: f32, shift_y: f32, glyph: c_int, width: [*c]c_int, height: [*c]c_int, xoff: [*c]c_int, yoff: [*c]c_int) [*c]u8;
pub extern fn stbtt_MakeGlyphBitmap(info: [*c]const stbtt_fontinfo, output: [*c]u8, out_w: c_int, out_h: c_int, out_stride: c_int, scale_x: f32, scale_y: f32, glyph: c_int) void;
pub extern fn stbtt_MakeGlyphBitmapSubpixel(info: [*c]const stbtt_fontinfo, output: [*c]u8, out_w: c_int, out_h: c_int, out_stride: c_int, scale_x: f32, scale_y: f32, shift_x: f32, shift_y: f32, glyph: c_int) void;
pub extern fn stbtt_MakeGlyphBitmapSubpixelPrefilter(info: [*c]const stbtt_fontinfo, output: [*c]u8, out_w: c_int, out_h: c_int, out_stride: c_int, scale_x: f32, scale_y: f32, shift_x: f32, shift_y: f32, oversample_x: c_int, oversample_y: c_int, sub_x: [*c]f32, sub_y: [*c]f32, glyph: c_int) void;
pub extern fn stbtt_GetGlyphBitmapBox(font: [*c]const stbtt_fontinfo, glyph: c_int, scale_x: f32, scale_y: f32, ix0: [*c]c_int, iy0: [*c]c_int, ix1: [*c]c_int, iy1: [*c]c_int) void;
pub extern fn stbtt_GetGlyphBitmapBoxSubpixel(font: [*c]const stbtt_fontinfo, glyph: c_int, scale_x: f32, scale_y: f32, shift_x: f32, shift_y: f32, ix0: [*c]c_int, iy0: [*c]c_int, ix1: [*c]c_int, iy1: [*c]c_int) void;
pub const stbtt__bitmap = extern struct {
    w: c_int,
    h: c_int,
    stride: c_int,
    pixels: [*c]u8,
};
pub extern fn stbtt_Rasterize(result: [*c]stbtt__bitmap, flatness_in_pixels: f32, vertices: [*c]stbtt_vertex, num_verts: c_int, scale_x: f32, scale_y: f32, shift_x: f32, shift_y: f32, x_off: c_int, y_off: c_int, invert: c_int, userdata: ?*anyopaque) void;
pub extern fn stbtt_FreeSDF(bitmap: [*c]u8, userdata: ?*anyopaque) void;
pub extern fn stbtt_GetGlyphSDF(info: [*c]const stbtt_fontinfo, scale: f32, glyph: c_int, padding: c_int, onedge_value: u8, pixel_dist_scale: f32, width: [*c]c_int, height: [*c]c_int, xoff: [*c]c_int, yoff: [*c]c_int) [*c]u8;
pub extern fn stbtt_GetCodepointSDF(info: [*c]const stbtt_fontinfo, scale: f32, codepoint: c_int, padding: c_int, onedge_value: u8, pixel_dist_scale: f32, width: [*c]c_int, height: [*c]c_int, xoff: [*c]c_int, yoff: [*c]c_int) [*c]u8;
pub extern fn stbtt_FindMatchingFont(fontdata: [*c]const u8, name: [*c]const u8, flags: c_int) c_int;
pub extern fn stbtt_CompareUTF8toUTF16_bigendian(s1: [*c]const u8, len1: c_int, s2: [*c]const u8, len2: c_int) c_int;
pub extern fn stbtt_GetFontNameString(font: [*c]const stbtt_fontinfo, length: [*c]c_int, platformID: c_int, encodingID: c_int, languageID: c_int, nameID: c_int) [*c]const u8;
pub const STBTT_PLATFORM_ID_UNICODE: c_int = 0;
pub const STBTT_PLATFORM_ID_MAC: c_int = 1;
pub const STBTT_PLATFORM_ID_ISO: c_int = 2;
pub const STBTT_PLATFORM_ID_MICROSOFT: c_int = 3;
const enum_unnamed_2 = c_uint;
pub const STBTT_UNICODE_EID_UNICODE_1_0: c_int = 0;
pub const STBTT_UNICODE_EID_UNICODE_1_1: c_int = 1;
pub const STBTT_UNICODE_EID_ISO_10646: c_int = 2;
pub const STBTT_UNICODE_EID_UNICODE_2_0_BMP: c_int = 3;
pub const STBTT_UNICODE_EID_UNICODE_2_0_FULL: c_int = 4;
const enum_unnamed_3 = c_uint;
pub const STBTT_MS_EID_SYMBOL: c_int = 0;
pub const STBTT_MS_EID_UNICODE_BMP: c_int = 1;
pub const STBTT_MS_EID_SHIFTJIS: c_int = 2;
pub const STBTT_MS_EID_UNICODE_FULL: c_int = 10;
const enum_unnamed_4 = c_uint;
pub const STBTT_MAC_EID_ROMAN: c_int = 0;
pub const STBTT_MAC_EID_ARABIC: c_int = 4;
pub const STBTT_MAC_EID_JAPANESE: c_int = 1;
pub const STBTT_MAC_EID_HEBREW: c_int = 5;
pub const STBTT_MAC_EID_CHINESE_TRAD: c_int = 2;
pub const STBTT_MAC_EID_GREEK: c_int = 6;
pub const STBTT_MAC_EID_KOREAN: c_int = 3;
pub const STBTT_MAC_EID_RUSSIAN: c_int = 7;
const enum_unnamed_5 = c_uint;
pub const STBTT_MS_LANG_ENGLISH: c_int = 1033;
pub const STBTT_MS_LANG_ITALIAN: c_int = 1040;
pub const STBTT_MS_LANG_CHINESE: c_int = 2052;
pub const STBTT_MS_LANG_JAPANESE: c_int = 1041;
pub const STBTT_MS_LANG_DUTCH: c_int = 1043;
pub const STBTT_MS_LANG_KOREAN: c_int = 1042;
pub const STBTT_MS_LANG_FRENCH: c_int = 1036;
pub const STBTT_MS_LANG_RUSSIAN: c_int = 1049;
pub const STBTT_MS_LANG_GERMAN: c_int = 1031;
pub const STBTT_MS_LANG_SPANISH: c_int = 1033;
pub const STBTT_MS_LANG_HEBREW: c_int = 1037;
pub const STBTT_MS_LANG_SWEDISH: c_int = 1053;
const enum_unnamed_6 = c_uint;
pub const STBTT_MAC_LANG_ENGLISH: c_int = 0;
pub const STBTT_MAC_LANG_JAPANESE: c_int = 11;
pub const STBTT_MAC_LANG_ARABIC: c_int = 12;
pub const STBTT_MAC_LANG_KOREAN: c_int = 23;
pub const STBTT_MAC_LANG_DUTCH: c_int = 4;
pub const STBTT_MAC_LANG_RUSSIAN: c_int = 32;
pub const STBTT_MAC_LANG_FRENCH: c_int = 1;
pub const STBTT_MAC_LANG_SPANISH: c_int = 6;
pub const STBTT_MAC_LANG_GERMAN: c_int = 2;
pub const STBTT_MAC_LANG_SWEDISH: c_int = 5;
pub const STBTT_MAC_LANG_HEBREW: c_int = 10;
pub const STBTT_MAC_LANG_CHINESE_SIMPLIFIED: c_int = 33;
pub const STBTT_MAC_LANG_ITALIAN: c_int = 3;
pub const STBTT_MAC_LANG_CHINESE_TRAD: c_int = 19;
pub const stbtt_vertex_type = c_short;
pub const STBTT_MACSTYLE_DONTCARE = @as(c_int, 0);
pub const STBTT_MACSTYLE_BOLD = @as(c_int, 1);
pub const STBTT_MACSTYLE_ITALIC = @as(c_int, 2);
pub const STBTT_MACSTYLE_UNDERSCORE = @as(c_int, 4);
pub const STBTT_MACSTYLE_NONE = @as(c_int, 8);
