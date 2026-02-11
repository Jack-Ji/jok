//! Font rendering and management.
//!
//! This module provides TrueType font loading and rendering capabilities through
//! stb_truetype. It supports font atlases for efficient text rendering and includes
//! an embedded debug font for development.
//!
//! Features:
//! - TrueType font loading from files or embedded data
//! - Font atlas generation with customizable codepoint ranges
//! - Kerning support for proper text spacing
//! - Embedded debug font (Clacon2)
//! - Atlas serialization/deserialization
//!
//! The font system uses texture atlases to efficiently render text by packing
//! multiple glyphs into a single texture.

const std = @import("std");
const assert = std.debug.assert;
const jok = @import("jok.zig");

/// Wrapper of TrueType font.
///
/// Provides font loading and atlas generation capabilities.
pub const Font = @import("font/Font.zig");

/// Font atlas for generating vertex data.
///
/// Manages a texture atlas containing pre-rendered glyphs for efficient text rendering.
pub const Atlas = @import("font/Atlas.zig");

/// Regularly used codepoint ranges.
///
/// Provides predefined character ranges like ASCII, Latin-1, CP437, etc.
pub const codepoint_ranges = @import("font/codepoint_ranges.zig");

/// Embedded debug font for development and debugging.
///
/// Provides a built-in monospace font (Clacon2) that can be used without
/// loading external font files. Useful for debug output and development.
pub const DebugFont = struct {
    /// Embedded font data (Clacon2 TrueType font)
    pub const font_data = @embedFile("font/Orbitron-Bold.ttf");
    /// Font instance (initialized by init())
    pub var font: *Font = undefined;

    var arena: std.heap.ArenaAllocator = undefined;
    var atlases: std.AutoHashMap(u32, *Atlas) = undefined;

    /// Initialize the debug font system.
    ///
    /// **WARNING: This function is automatically called by jok.Context during initialization.**
    /// **DO NOT call this function directly from game code.**
    /// The debug font is accessible via `ctx.debugPrint()` and `ctx.getDebugAtlas()` after context creation.
    ///
    /// Must be called before using the debug font.
    ///
    /// Parameters:
    ///   allocator: Memory allocator for font resources
    pub fn init(allocator: std.mem.Allocator) !void {
        arena = .init(allocator);
        font = try Font.fromTrueTypeData(arena.allocator(), font_data);
        atlases = .init(arena.allocator());
    }

    /// Deinitialize the debug font system and free resources.
    ///
    /// **WARNING: This function is automatically called by jok.Context during cleanup.**
    /// **DO NOT call this function directly from game code.**
    pub fn deinit() void {
        var it = atlases.iterator();
        while (it.next()) |e| {
            e.value_ptr.*.destroy();
        }
        arena.deinit();
    }

    /// Get or create an atlas for the specified font size.
    ///
    /// Atlases are cached, so requesting the same size multiple times
    /// returns the same atlas instance.
    ///
    /// Parameters:
    ///   ctx: Application context
    ///   font_size: Font size in pixels
    ///
    /// Returns: Font atlas for the requested size
    pub fn getAtlas(ctx: jok.Context, font_size: u32) !*Atlas {
        return atlases.get(font_size) orelse blk: {
            const a = try font.createAtlas(
                ctx,
                font_size,
                &codepoint_ranges.cp437,
                .{},
            );
            try atlases.put(font_size, a);
            break :blk a;
        };
    }
};

test "font" {}
