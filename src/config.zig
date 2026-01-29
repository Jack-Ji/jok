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
    const game_struct = @typeInfo(game).@"struct";

    // First pass: validate all jok_ declarations exist in Config
    for (game_struct.decls) |game_decl| {
        if (!std.mem.startsWith(u8, game_decl.name, "jok_")) {
            continue;
        }

        // Check if this field exists in Config
        var found = false;
        inline for (@typeInfo(Config).@"struct".fields) |cfg_field| {
            if (std.mem.eql(u8, cfg_field.name, game_decl.name)) {
                found = true;
                break;
            }
        }

        if (!found) {
            // Build error message listing all supported options
            @compileError("Validation of setup options failed, invalid option name: `" ++ game_decl.name ++ "`\n" ++
                "Supported options:\n" ++
                buildSupportedOptionsList());
        }
    }

    // Second pass: assign values
    inline for (@typeInfo(Config).@"struct".fields) |cfg_field| {
        if (@hasDecl(game, cfg_field.name)) {
            const CfgFieldType = cfg_field.type;
            const GameFieldType = @TypeOf(@field(game, cfg_field.name));
            const cfg_type = @typeInfo(CfgFieldType);
            const game_type = @typeInfo(GameFieldType);

            if (CfgFieldType == GameFieldType or
                (cfg_type == .int and game_type == .comptime_int) or
                (cfg_type == .optional and cfg_type.optional.child == GameFieldType) or
                (cfg_type == .@"union" and cfg_type.@"union".tag_type == GameFieldType))
            {
                @field(cfg, cfg_field.name) = @field(game, cfg_field.name);
            } else {
                @compileError("Invalid type for option `" ++
                    cfg_field.name ++ "`: expecting " ++ @typeName(CfgFieldType) ++ ", got " ++ @typeName(GameFieldType));
            }
        }
    }

    return cfg;
}

fn buildSupportedOptionsList() []const u8 {
    comptime {
        // Verify all fields have descriptions
        for (@typeInfo(Config).@"struct".fields) |field| {
            const desc = getFieldDescription(field.name);
            if (std.mem.eql(u8, desc, "unknown option")) {
                @compileError("Missing description for config option: " ++ field.name ++
                    ". Please add it to getFieldDescription() function.");
            }
        }

        var list: []const u8 = "";
        for (@typeInfo(Config).@"struct".fields) |field| {
            const desc = getFieldDescription(field.name);
            list = list ++ "\t" ++ field.name ++ ": " ++ desc ++ "\n";
        }
        return list;
    }
}

fn getFieldDescription(comptime field_name: []const u8) []const u8 {
    return if (std.mem.eql(u8, field_name, "jok_log_level"))
        "logging level"
    else if (std.mem.eql(u8, field_name, "jok_fps_limit"))
        "fps limit setting"
    else if (std.mem.eql(u8, field_name, "jok_enable_physfs"))
        "whether use physfs to access game assets"
    else if (std.mem.eql(u8, field_name, "jok_renderer_type"))
        "type of renderer"
    else if (std.mem.eql(u8, field_name, "jok_framebuffer_color"))
        "clearing color of framebuffer"
    else if (std.mem.eql(u8, field_name, "jok_canvas_size"))
        "size of canvas"
    else if (std.mem.eql(u8, field_name, "jok_canvas_scale_mode"))
        "Default scaling mode for canvas"
    else if (std.mem.eql(u8, field_name, "jok_canvas_integer_scaling"))
        "Use integer scaling for canvas"
    else if (std.mem.eql(u8, field_name, "jok_headless"))
        "headless mode"
    else if (std.mem.eql(u8, field_name, "jok_window_title"))
        "title of window"
    else if (std.mem.eql(u8, field_name, "jok_window_size"))
        "size of window"
    else if (std.mem.eql(u8, field_name, "jok_window_min_size"))
        "minimum size of window"
    else if (std.mem.eql(u8, field_name, "jok_window_max_size"))
        "maximum size of window"
    else if (std.mem.eql(u8, field_name, "jok_window_resizable"))
        "whether window is resizable"
    else if (std.mem.eql(u8, field_name, "jok_window_borderless"))
        "whether window is borderless"
    else if (std.mem.eql(u8, field_name, "jok_window_ime_ui"))
        "whether show ime ui"
    else if (std.mem.eql(u8, field_name, "jok_window_always_on_top"))
        "whether window is locked to most front layer"
    else if (std.mem.eql(u8, field_name, "jok_window_mouse_mode"))
        "mouse mode setting"
    else if (std.mem.eql(u8, field_name, "jok_window_high_pixel_density"))
        "whether window is aware of high-pixel display"
    else if (std.mem.eql(u8, field_name, "jok_exit_on_recv_esc"))
        "whether exit game when esc is pressed"
    else if (std.mem.eql(u8, field_name, "jok_exit_on_recv_quit"))
        "whether exit game when getting quit event"
    else if (std.mem.eql(u8, field_name, "jok_kill_on_error"))
        "whether kill application when user callbacks returned error"
    else if (std.mem.eql(u8, field_name, "jok_check_memory_leak"))
        "whether detect memory-leak on shutdown"
    else if (std.mem.eql(u8, field_name, "jok_imgui_ini_file"))
        "whether let imgui load/save ini file"
    else if (std.mem.eql(u8, field_name, "jok_prebuild_atlas"))
        "whether prebuild atlas for debug font"
    else if (std.mem.eql(u8, field_name, "jok_detailed_frame_stats"))
        "whether enable detailed frame statistics"
    else
        "unknown option";
}
