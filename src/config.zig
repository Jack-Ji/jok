//! Game configuration system for the jok engine.
//!
//! This module provides compile-time configuration for game applications.
//! Configuration options are specified as public declarations in the game module
//! with names starting with "jok_". The engine validates these options at compile time.
//!
//! Example usage:
//! ```zig
//! pub const jok_window_title = "My Game";
//! pub const jok_window_size = jok.config.WindowSize{ .custom = .{ .width = 1280, .height = 720 } };
//! pub const jok_fps_limit = jok.config.FpsLimit{ .manual = 60 };
//! ```

const std = @import("std");
const builtin = @import("builtin");
const jok = @import("jok.zig");

/// Main configuration structure for the jok engine.
/// All fields have sensible defaults and can be overridden by the game module.
pub const Config = struct {
    /// Logging level
    jok_log_level: std.log.Level = std.log.default_level,

    /// FPS limiting mode
    jok_fps_limit: FpsLimit = .{ .manual = 60 },

    /// Assets accessing method (use PhysicsFS for virtual file system)
    jok_enable_physfs: bool = true,

    /// Type of renderer (software, accelerated, or GPU with shaders)
    jok_renderer_type: RendererType = if (builtin.cpu.arch.isWasm()) .accelerated else .gpu,

    /// Clearing color of framebuffer (background color)
    jok_framebuffer_color: jok.Color = .black,

    /// Canvas size (null means same as framebuffer size)
    jok_canvas_size: ?jok.Size = null,
    /// Canvas texture scaling mode
    jok_canvas_scale_mode: jok.Texture.ScaleMode = .linear,
    /// Use integer scaling for pixel-perfect rendering
    jok_canvas_integer_scaling: bool = false,

    /// Headless mode (no window, for servers/testing)
    jok_headless: bool = false,

    /// Window title
    jok_window_title: [:0]const u8 = "mygame",
    /// Initial window size
    jok_window_size: WindowSize = .{ .custom = .{ .width = 800, .height = 600 } },
    /// Minimum window size (null = no limit)
    jok_window_min_size: ?jok.Size = null,
    /// Maximum window size (null = no limit)
    jok_window_max_size: ?jok.Size = null,
    /// Allow window resizing
    jok_window_resizable: bool = false,
    /// Remove window borders
    jok_window_borderless: bool = false,
    /// Keep window on top of other windows
    jok_window_always_on_top: bool = false,
    /// Show IME (Input Method Editor) UI for text input
    jok_window_ime_ui: bool = false,
    /// Mouse cursor behavior mode
    jok_window_mouse_mode: MouseMode = .normal,
    /// Enable high DPI support for retina/4K displays
    jok_window_high_pixel_density: bool = true,

    /// Exit game when ESC key is pressed
    jok_exit_on_recv_esc: bool = true,
    /// Exit game when receiving quit event (window close button)
    jok_exit_on_recv_quit: bool = true,

    /// Kill application on catching errors from callbacks (enabled in debug mode)
    jok_kill_on_error: bool = builtin.mode == .Debug,

    /// Detect memory leaks on shutdown (enabled in debug mode)
    jok_check_memory_leak: bool = builtin.mode == .Debug,

    /// Allow ImGui to load/save ini file for UI state persistence
    jok_imgui_ini_file: bool = false,

    /// Prebuild atlas size for debug font (in pixels)
    jok_prebuild_atlas: u32 = 16,

    /// Enable detailed frame statistics collection
    jok_detailed_frame_stats: bool = true,
};

/// Initial size and mode of the game window.
pub const WindowSize = union(enum) {
    /// Start maximized
    maximized,
    /// Start in fullscreen mode
    fullscreen,
    /// Custom window size
    custom: jok.Size,
};

/// Renderer backend type.
pub const RendererType = enum {
    /// Software renderer (CPU-based, many limitations)
    software,
    /// Hardware-accelerated renderer (GPU-based, no shader support)
    accelerated,
    /// GPU renderer with full shader support (recommended)
    gpu,

    /// Get string representation of renderer type
    pub inline fn str(self: @This()) []const u8 {
        return switch (self) {
            .software => "software",
            .accelerated => "accelerated",
            .gpu => "gpu",
        };
    }
};

/// FPS (frames per second) limiting mode.
/// Controls how the engine regulates frame rate.
pub const FpsLimit = union(enum) {
    /// No limit - render as fast as possible (may cause high CPU/GPU usage)
    none,
    /// Automatic - use VSync to cap frame rate to display refresh rate
    auto,
    /// Manual - cap to specified FPS with fixed time step
    manual: u32,

    /// Get string representation of FPS limit mode
    pub inline fn str(self: @This()) []const u8 {
        return switch (self) {
            .none => "none",
            .auto => "auto",
            .manual => "manual",
        };
    }
};

/// Mouse cursor behavior mode.
/// Controls cursor visibility and capture in different window states.
pub const MouseMode = enum {
    /// Normal mode:
    /// - Fullscreen: hide cursor, enable relative mode (FPS-style)
    /// - Windowed: show cursor
    normal,

    /// Hide in window mode:
    /// - Fullscreen: hide cursor
    /// - Windowed: hide cursor
    hide_in_window,

    /// Always hide mode:
    /// - Fullscreen: hide cursor, enable relative mode
    /// - Windowed: hide cursor, enable relative mode
    hide_always,
};

/// Validate and initialize configuration from game module.
/// This function is called at compile time to extract configuration options
/// from the game module and validate their types.
pub fn init(comptime game: anytype) Config {
    @setEvalBranchQuota(10000);

    var cfg = Config{};
    const options = [_]struct { name: []const u8, desc: []const u8 }{
        .{ .name = "jok_log_level", .desc = "logging level" },
        .{ .name = "jok_fps_limit", .desc = "fps limit setting" },
        .{ .name = "jok_enable_physfs", .desc = "whether use physfs to access game assets" },
        .{ .name = "jok_renderer_type", .desc = "type of renderer" },
        .{ .name = "jok_framebuffer_color", .desc = "clearing color of framebuffer" },
        .{ .name = "jok_canvas_size", .desc = "size of canvas" },
        .{ .name = "jok_canvas_scale_mode", .desc = "Default scaling mode for canvas" },
        .{ .name = "jok_canvas_integer_scaling", .desc = "Use integer scaling for canvas" },
        .{ .name = "jok_headless", .desc = "headless mode" },
        .{ .name = "jok_window_title", .desc = "title of window" },
        .{ .name = "jok_window_size", .desc = "size of window" },
        .{ .name = "jok_window_min_size", .desc = "minimum size of window" },
        .{ .name = "jok_window_max_size", .desc = "maximum size of window" },
        .{ .name = "jok_window_resizable", .desc = "whether window is resizable" },
        .{ .name = "jok_window_borderless", .desc = "whether window is borderless" },
        .{ .name = "jok_window_ime_ui", .desc = "whether show ime ui" },
        .{ .name = "jok_window_always_on_top", .desc = "whether window is locked to most front layer" },
        .{ .name = "jok_window_mouse_mode", .desc = "mouse mode setting" },
        .{ .name = "jok_window_high_pixel_density", .desc = "whether window is aware of high-pixel display" },
        .{ .name = "jok_exit_on_recv_esc", .desc = "whether exit game when esc is pressed" },
        .{ .name = "jok_exit_on_recv_quit", .desc = "whether exit game when getting quit event" },
        .{ .name = "jok_kill_on_error", .desc = "whether kill application when user callbacks returned error" },
        .{ .name = "jok_check_memory_leak", .desc = "whether detect memory-leak on shutdown" },
        .{ .name = "jok_imgui_ini_file", .desc = "whether let imgui load/save ini file" },
        .{ .name = "jok_prebuild_atlas", .desc = "whether prebuild atlas for debug font" },
        .{ .name = "jok_detailed_frame_stats", .desc = "whether enable detailed frame statistics" },
    };
    const game_struct = @typeInfo(game).@"struct";
    for (game_struct.decls) |f| {
        if (!std.mem.startsWith(u8, f.name, "jok_")) {
            continue;
        }
        for (options) |o| {
            if (std.meta.fieldIndex(Config, f.name) == null) continue;

            const CfgFieldType = @TypeOf(@field(cfg, f.name));
            const GameFieldType = @TypeOf(@field(game, f.name));
            const cfg_type = @typeInfo(CfgFieldType);
            const game_type = @typeInfo(GameFieldType);
            if (std.mem.eql(u8, o.name, f.name)) {
                if (CfgFieldType == GameFieldType or
                    (cfg_type == .int and game_type == .comptime_int) or
                    (cfg_type == .optional and cfg_type.optional.child == GameFieldType) or
                    (cfg_type == .@"union" and cfg_type.@"union".tag_type == GameFieldType))
                {
                    @field(cfg, f.name) = @field(game, o.name);
                } else {
                    @compileError("Validation of setup options failed, invalid type for option `" ++
                        f.name ++ "`, expecting " ++ @typeName(CfgFieldType) ++ ", get " ++ @typeName(GameFieldType));
                }
                break;
            }
        } else {
            var buf: [2048]u8 = undefined;
            var off: usize = 0;
            var bs = std.fmt.bufPrint(&buf, "Validation of setup options failed, invalid option name: `" ++ f.name ++ "`", .{}) catch unreachable;
            off += bs.len;
            bs = std.fmt.bufPrint(buf[off..], "\nSupported options:", .{}) catch unreachable;
            off += bs.len;
            inline for (options) |o| {
                bs = std.fmt.bufPrint(buf[off..], "\n\t" ++ o.name ++
                    " (" ++ @typeName(@TypeOf(@field(cfg, o.name))) ++ "): " ++ o.desc ++ ".", .{}) catch unreachable;
                off += bs.len;
            }
            @compileError(buf[0..off]);
        }
    }

    return cfg;
}
