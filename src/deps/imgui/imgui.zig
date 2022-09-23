const std = @import("std");
const assert = std.debug.assert;
const jok = @import("../../jok.zig");
const sdl = @import("sdl");
const sdlrenderer_impl = @import("sdlrenderer_impl.zig");
const sdl_impl = @import("sdl_impl.zig");
pub const c = @import("c.zig");

pub const Error = error{
    InitBackendFailed,
    InitPlotExtFailed,
    InitNodesExtFailed,
};

/// Export friendly api
pub usingnamespace @import("api.zig");

/// Icon font: font-awesome
pub const fontawesome = @import("fonts/fontawesome.zig");

/// Export 3rd-party extensions
pub const ext = @import("ext/ext.zig");

/// Internal static vars
var imgui_ctx: ?*c.ImGuiContext = null;
var plot_ctx: ?*ext.plot.ImPlotContext = null;
var nodes_ctx: ?*ext.nodes.ImNodesContext = null;

/// Initialize sdl2 backend
pub fn init(ctx: *jok.Context) !void {
    imgui_ctx = c.igCreateContext(null);
    assert(imgui_ctx != null);
    try sdl_impl.init(ctx);
    try sdlrenderer_impl.init(ctx);

    plot_ctx = ext.plot.createContext();
    if (plot_ctx == null) {
        return error.InitPlotExtFailed;
    }

    nodes_ctx = ext.nodes.createContext();
    if (nodes_ctx == null) {
        return error.InitNodesExtFailed;
    }

    const pixel_ratio = ctx.getPixelRatio();
    var style = c.igGetStyle();
    assert(style != null);
    c.ImGuiStyle_ScaleAllSizes(style, pixel_ratio);

    // Load clacon as default font
    _ = try loadFontFromMemory(jok.font.clacon, 16, null);
}

/// Release allocated resources
pub fn deinit() void {
    assert(imgui_ctx != null);
    ext.nodes.destroyContext(nodes_ctx.?);
    ext.plot.destroyContext(plot_ctx.?);
    sdlrenderer_impl.deinit();
    sdl_impl.deinit();
}

/// Process i/o event
pub fn processEvent(e: sdl.Event) bool {
    assert(imgui_ctx != null);
    return sdl_impl.processEvent(e);
}

/// Begin frame
pub fn beginFrame() void {
    assert(imgui_ctx != null);
    sdl_impl.newFrame();
    sdlrenderer_impl.newFrame();
    c.igNewFrame();
}

/// End frame
pub fn endFrame() void {
    assert(imgui_ctx != null);
    c.igRender();
    sdlrenderer_impl.render(@ptrCast(*c.ImDrawData, c.igGetDrawData()));
}

/// Load fontawesome
pub fn loadFontAwesome(size: f32, regular: bool, monospaced: bool) !*c.ImFont {
    assert(imgui_ctx != null);
    var font_atlas = c.igGetIO().*.Fonts;
    _ = c.ImFontAtlas_AddFontDefault(
        font_atlas,
        null,
    );

    var ranges = [3]c.ImWchar{
        fontawesome.ICON_MIN_FA,
        fontawesome.ICON_MAX_FA,
        0,
    };
    var cfg = c.ImFontConfig_ImFontConfig();
    defer c.ImFontConfig_destroy(cfg);
    cfg.*.PixelSnapH = true;
    cfg.*.MergeMode = true;
    if (monospaced) {
        cfg.*.GlyphMinAdvanceX = size;
    }
    const ttf: []const u8 = if (regular)
        fontawesome.regular_ttf
    else
        fontawesome.solid_ttf;
    const font = c.ImFontAtlas_AddFontFromMemoryTTF(
        font_atlas,
        ttf.ptr,
        @intCast(c_int, ttf.len),
        size,
        cfg,
        &ranges,
    );
    if (font == null) {
        std.debug.panic("load font awesome failed!", .{});
    }
    if (!c.ImFontAtlas_Build(font_atlas)) {
        std.debug.panic("build font atlas failed!", .{});
    }
    return font;
}

/// Load font data from memory
fn loadFontFromMemory(
    font_data: []const u8,
    size: f32,
    addional_ranges: ?[*c]const c.ImWchar,
) !*c.ImFont {
    assert(imgui_ctx != null);
    var font_atlas = c.igGetIO().*.Fonts;

    var default_ranges = c.ImFontAtlas_GetGlyphRangesDefault(font_atlas);
    var font = c.ImFontAtlas_AddFontFromMemoryTTF(
        font_atlas,
        font_data.ptr,
        @intCast(c_int, font_data.len),
        size,
        null,
        default_ranges,
    );
    if (font == null) {
        std.debug.panic("load font from memory failed!", .{});
    }

    if (addional_ranges) |ranges| {
        var cfg = c.ImFontConfig_ImFontConfig();
        defer c.ImFontConfig_destroy(cfg);
        cfg.*.MergeMode = true;
        font = c.ImFontAtlas_AddFontFromMemoryTTF(
            font_atlas,
            font_data.ptr,
            @intCast(c_int, font_data.len),
            size,
            cfg,
            ranges,
        );
        if (font == null) {
            std.debug.panic("load font from memory failed!", .{});
        }
    }

    if (!c.ImFontAtlas_Build(font_atlas)) {
        std.debug.panic("build font atlas failed!", .{});
    }
    return font;
}

/// Load font from storage
pub fn loadFontFromFile(
    path: []const u8,
    size: f32,
    addional_ranges: ?[*c]const c.ImWchar,
) !*c.ImFont {
    const allocator = std.heap.c_allocator;
    const max_file_size = 10 * (1 << 20);
    var font_data = try std.fs.cwd().readFileAlloc(allocator, path, max_file_size);
    defer allocator.free(font_data);
    return loadFontFromMemory(font_data, size, addional_ranges);
}

/// Determine whether next character in given buffer is renderable
pub fn isCharRenderable(buf: []const u8) bool {
    var char: c_uint = undefined;
    _ = c.igImTextCharFromUtf8(&char, buf.ptr, buf.ptr + buf.len);
    if (char == 0) {
        return false;
    }
    return c.ImFont_FindGlyphNoFallback(
        c.igGetFont(),
        @intCast(c.ImWchar, char),
    ) != null;
}
