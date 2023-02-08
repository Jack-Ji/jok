const std = @import("std");
const sdl = @import("sdl");
const jok = @import("jok.zig");

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

/// Mouse mode
pub const MouseMode = enum {
    normal,
    hide,
};

/// Logging level - jok_log_level
pub var log_level: std.log.Level = std.log.default_level;

/// FPS limiting (auto means vsync) - jok_fps_limit
pub var fps_limit: FpsLimit = .auto;

/// Display frame stats on title bar - jok_framestat_display
pub var enable_framestat_display = true;

/// Default memory allocator - jok_allocator
pub var allocator: ?std.mem.Allocator = null;

/// Default memory allocator settings - jok_mem_leak_checks/jok_mem_detail_logs
pub var enable_mem_leak_checks = true;
pub var enable_mem_detail_logs = false;

/// Whether fallback to software renderer - jok_software_renderer
pub var enable_software_renderer: bool = true;

/// Window's title - jok_window_title
pub var title: [:0]const u8 = "jok";

/// Position of window - jok_window_pos_x/jok_window_pos_y
pub var pos_x: sdl.WindowPosition = .default;
pub var pos_y: sdl.WindowPosition = .default;

/// Width/height of window - jok_window_width/jok_window_height
pub var width: u32 = 800;
pub var height: u32 = 600;

/// Mimimum size of window - jok_window_min_size
pub var min_size: ?sdl.Size = null;

/// Maximumsize of window - jok_window_max_size
pub var max_size: ?sdl.Size = null;

// Resizable switch - jok_window_resizable
pub var enable_resizable = false;

/// Display switch - jok_window_fullscreen
pub var enable_fullscreen = false;

/// Borderless window - jok_window_borderless
pub var enable_borderless = false;

/// Minimize window - jok_window_minimized
pub var enable_minimized = false;

/// Maximize window - jok_window_maximized
pub var enable_maximized = false;

/// Window always on top - jok_window_always_on_top
pub var enable_always_on_top = false;

/// Mouse mode - jok_mouse_mode
pub var mouse_mode: MouseMode = .normal;

/// Exit game when get esc event - jok_exit_on_recv_esc
pub var exit_on_recv_esc = true;

/// Exit game when get quit event - jok_exit_on_recv_quit
pub var exit_on_recv_quit = false;
