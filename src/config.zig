//! Application configurations
const std = @import("std");
const sdl = @import("sdl");
const jok = @import("jok.zig");
const root = @import("root");

/// Graphics flushing method
pub const FpsLimit = union(enum) {
    none, // No limit, draw as fast as we can
    auto, // Enable vsync when hardware acceleration is available, default to 30 fps otherwise
    manual: u32, // Capped to given fps

    pub inline fn str(self: @This()) []const u8 {
        return switch (self) {
            .none => "none",
            .auto => "auto",
            .manual => "manual",
        };
    }
};

/// Default memory allocator
pub const allocator: ?std.mem.Allocator = if (@hasDecl(root, "jok_allocator"))
    root.jok_allocator
else
    null;

/// Default memory allocator settings
pub const enable_mem_leak_checks = if (@hasDecl(root, "jok_mem_leak_checks"))
    root.jok_mem_leak_checks
else
    true;
pub const enable_mem_detail_logs = if (@hasDecl(root, "jok_mem_detail_logs"))
    root.jok_mem_detail_logs
else
    false;

/// Window's title
pub const title: [:0]const u8 = if (@hasDecl(root, "jok_title"))
    root.jok_title
else
    "jok";

/// Whether fallback to software renderer
pub const enable_software_renderer: bool = if (@hasDecl(root, "jok_software_renderer"))
    root.jok_software_renderer
else
    true;

/// Position of window
pub const pos_x: sdl.WindowPosition = if (@hasDecl(root, "jok_window_pos_x"))
    root.jok_window_pos_x
else
    .default;
pub const pos_y: sdl.WindowPosition = if (@hasDecl(root, "jok_window_pos_y"))
    root.jok_window_pos_y
else
    .default;

/// Width/height of window
pub const width: u32 = if (@hasDecl(root, "jok_window_width"))
    root.jok_window_width
else
    800;
pub const height: u32 = if (@hasDecl(root, "jok_window_height"))
    root.jok_window_height
else
    600;

/// Mimimum size of window
pub const min_size: ?sdl.Size = if (@hasDecl(root, "jok_window_min_size"))
    root.jok_window_min_size
else
    null;

/// Maximumsize of window
pub const max_size: ?sdl.Size = if (@hasDecl(root, "jok_window_max_size"))
    root.jok_window_max_size
else
    null;

// Resizable switch
pub const enable_resizable = if (@hasDecl(root, "jok_window_resizable"))
    root.jok_window_resizable
else
    false;

/// Display switch
pub const enable_fullscreen = if (@hasDecl(root, "jok_window_fullscreen"))
    root.jok_window_fullscreen
else
    false;

/// Borderless window
pub const enable_borderless = if (@hasDecl(root, "jok_window_borderless"))
    root.jok_window_borderless
else
    false;

/// Minimize window
pub const enable_minimized = if (@hasDecl(root, "jok_window_minimized"))
    root.jok_window_minimized
else
    false;

/// Maximize window
pub const enable_maximized = if (@hasDecl(root, "jok_window_maximized"))
    root.jok_window_maximized
else
    false;

/// Relative mouse mode switch
pub const enable_relative_mouse_mode = if (@hasDecl(root, "jok_relative_mouse_mode"))
    root.jok_relative_mouse_mode
else
    false;

/// Display frame stats on title bar
pub const enable_framestat_display = if (@hasDecl(root, "jok_framestat_display"))
    root.jok_framestat_display
else
    true;

/// FPS limiting (auto means vsync)
pub const fps_limit: FpsLimit = if (@hasDecl(root, "jok_fps_limit"))
    root.jok_fps_limit
else
    .auto;

/// 3D primitive rendering
pub const enable_3d_primitive = if (@hasDecl(root, "jok_3d_primitive"))
    root.jok_3d_primitive
else
    true;

/// 2D primitive rendering
pub const enable_2d_primitive = if (@hasDecl(root, "jok_2d_primitive"))
    root.jok_2d_primitive
else
    true;
