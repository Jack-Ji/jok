//! Application configurations
const std = @import("std");
const sdl = @import("sdl");
const jok = @import("jok.zig");
const game = @import("game");

// Validate setup configurations
comptime {
    const config_names = [_][]const u8{
        "jok_allocator",
        "jok_mem_leak_checks",
        "jok_mem_detail_logs",
        "jok_software_renderer",
        "jok_window_title",
        "jok_window_pos_x",
        "jok_window_pos_y",
        "jok_window_width",
        "jok_window_height",
        "jok_window_min_size",
        "jok_window_max_size",
        "jok_window_resizable",
        "jok_window_fullscreen",
        "jok_window_borderless",
        "jok_window_minimized",
        "jok_window_maximized",
        "jok_window_always_on_top",
        "jok_mouse_mode",
        "jok_fps_limit",
        "jok_framestat_display",
    };
    const game_struct = @typeInfo(game).Struct;
    for (game_struct.decls) |f| {
        if (!f.is_pub or !std.mem.startsWith(u8, f.name, "jok_")) {
            continue;
        }
        for (config_names) |n| {
            if (std.mem.eql(u8, n, f.name)) {
                break;
            }
        } else {
            @compileError("Invalid config option: " ++ f.name ++
                \\
                \\Supported configurations:
                \\    jok_allocator (std.mem.Allocator): default memory allocator.
                \\    jok_mem_leak_checks (bool): whether default memory allocator check memleak when exiting.
                \\    jok_mem_detail_logs (bool): whether default memory allocator print detailed memory alloc/free logs.
                \\    jok_software_renderer (bool): whether fallback to software renderer.
                \\    jok_window_title ([:0]const u8): title of window.
                \\    jok_window_pos_x (sdl.WindowPosition): horizontal position of window.
                \\    jok_window_pos_y (sdl.WindowPosition): vertical position of window.
                \\    jok_window_width (u32): width of window.
                \\    jok_window_height (u32): height of window.
                \\    jok_window_min_size (sdl.Size).: minimum size of window.
                \\    jok_window_max_size (sdl.Size): maximum size of window.
                \\    jok_window_resizable (bool): whether window is resizable.
                \\    jok_window_fullscreen (bool): whether use fullscreen mode.
                \\    jok_window_borderless (bool): whether window is borderless.
                \\    jok_window_minimized (bool): whether window is minimized when startup.
                \\    jok_window_maximized (bool): whether window is maximized when startup.
                \\    jok_window_always_on_top (bool): whether window is locked to most front layer.
                \\    jok_mouse_mode (config.MouseMode): mouse mode setting.
                \\    jok_fps_limit (config.FpsLimit): fps limit setting.
                \\    jok_framestat_display (bool): whether refresh and display frame statistics on title-bar of window. 
            );
        }
    }
}

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
    relative,
};

/// Default memory allocator
pub const allocator: ?std.mem.Allocator = if (@hasDecl(game, "jok_allocator"))
    game.jok_allocator
else
    null;

/// Default memory allocator settings
pub const enable_mem_leak_checks = if (@hasDecl(game, "jok_mem_leak_checks"))
    game.jok_mem_leak_checks
else
    true;
pub const enable_mem_detail_logs = if (@hasDecl(game, "jok_mem_detail_logs"))
    game.jok_mem_detail_logs
else
    false;

/// Whether fallback to software renderer
pub const enable_software_renderer: bool = if (@hasDecl(game, "jok_software_renderer"))
    game.jok_software_renderer
else
    true;

/// Window's title
pub const title: [:0]const u8 = if (@hasDecl(game, "jok_window_title"))
    game.jok_window_title
else
    "jok";

/// Position of window
pub const pos_x: sdl.WindowPosition = if (@hasDecl(game, "jok_window_pos_x"))
    game.jok_window_pos_x
else
    .default;
pub const pos_y: sdl.WindowPosition = if (@hasDecl(game, "jok_window_pos_y"))
    game.jok_window_pos_y
else
    .default;

/// Width/height of window
pub const width: u32 = if (@hasDecl(game, "jok_window_width"))
    game.jok_window_width
else
    800;
pub const height: u32 = if (@hasDecl(game, "jok_window_height"))
    game.jok_window_height
else
    600;

/// Mimimum size of window
pub const min_size: ?sdl.Size = if (@hasDecl(game, "jok_window_min_size"))
    game.jok_window_min_size
else
    null;

/// Maximumsize of window
pub const max_size: ?sdl.Size = if (@hasDecl(game, "jok_window_max_size"))
    game.jok_window_max_size
else
    null;

// Resizable switch
pub const enable_resizable = if (@hasDecl(game, "jok_window_resizable"))
    game.jok_window_resizable
else
    false;

/// Display switch
pub const enable_fullscreen = if (@hasDecl(game, "jok_window_fullscreen"))
    game.jok_window_fullscreen
else
    false;

/// Borderless window
pub const enable_borderless = if (@hasDecl(game, "jok_window_borderless"))
    game.jok_window_borderless
else
    false;

/// Minimize window
pub const enable_minimized = if (@hasDecl(game, "jok_window_minimized"))
    game.jok_window_minimized
else
    false;

/// Maximize window
pub const enable_maximized = if (@hasDecl(game, "jok_window_maximized"))
    game.jok_window_maximized
else
    false;

/// Window always on top
pub const enable_always_on_top = if (@hasDecl(game, "jok_window_always_on_top"))
    game.jok_window_always_on_top
else
    false;

/// Mouse mode
pub const mouse_mode: MouseMode = if (@hasDecl(game, "jok_mouse_mode"))
    game.jok_mouse_mode
else
    .normal;

/// FPS limiting (auto means vsync)
pub const fps_limit: FpsLimit = if (@hasDecl(game, "jok_fps_limit"))
    game.jok_fps_limit
else
    .auto;

/// Display frame stats on title bar
pub const enable_framestat_display = if (@hasDecl(game, "jok_framestat_display"))
    game.jok_framestat_display
else
    true;
