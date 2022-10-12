const std = @import("std");
const sdl = @import("sdl");
const jok = @import("jok.zig");
const game = @import("game");

// Validate setup configurations
comptime {
    const config_options = [_]struct { name: []const u8, T: type }{
        .{ .name = "jok_allocator", .T = std.mem.Allocator },
        .{ .name = "jok_mem_leak_checks", .T = bool },
        .{ .name = "jok_mem_detail_logs", .T = bool },
        .{ .name = "jok_software_renderer", .T = bool },
        .{ .name = "jok_window_title", .T = [:0]const u8 },
        .{ .name = "jok_window_pos_x", .T = sdl.WindowPosition },
        .{ .name = "jok_window_pos_y", .T = sdl.WindowPosition },
        .{ .name = "jok_window_width", .T = u32 },
        .{ .name = "jok_window_height", .T = u32 },
        .{ .name = "jok_window_min_size", .T = sdl.Size },
        .{ .name = "jok_window_max_size", .T = sdl.Size },
        .{ .name = "jok_window_resizable", .T = bool },
        .{ .name = "jok_window_fullscreen", .T = bool },
        .{ .name = "jok_window_borderless", .T = bool },
        .{ .name = "jok_window_minimized", .T = bool },
        .{ .name = "jok_window_maximized", .T = bool },
        .{ .name = "jok_window_always_on_top", .T = bool },
        .{ .name = "jok_mouse_mode", .T = MouseMode },
        .{ .name = "jok_fps_limit", .T = FpsLimit },
        .{ .name = "jok_enable_default_2d_primitive", .T = bool },
        .{ .name = "jok_enable_default_3d_primitive", .T = bool },
    };
    const game_struct = @typeInfo(game).Struct;
    for (game_struct.decls) |f| {
        if (!std.mem.startsWith(u8, f.name, "jok_")) {
            continue;
        }
        if (!f.is_pub) {
            @compileError("Validation of setup options failed, option `" ++ f.name ++ "` need to be public!");
        }
        for (config_options) |o| {
            if (std.mem.eql(u8, o.name, f.name)) {
                const FieldType = @TypeOf(@field(game, f.name));
                if (o.T != FieldType) {
                    @compileError("Validation of setup options failed, invalid type for option `" ++
                        f.name ++ "`, expecting " ++ @typeName(o.T) ++ ", get " ++ @typeName(FieldType));
                }
                break;
            }
        } else {
            @compileError("Validation of setup options failed, invalid option name: `" ++ f.name ++ "`" ++
                \\
                \\Supported options:
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
                \\    jok_enable_default_2d_primitive (bool): whether init j2d.primitive with default option.
                \\    jok_enable_default_3d_primitive (bool): whether init j3d.primitive with default option.
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

/// Init j2d.primitive with default renderer
pub const enable_default_2d_primitive = if (@hasDecl(game, "jok_enable_default_2d_primitive"))
    game.jok_enable_default_2d_primitive
else
    true;

/// Init j3d.primitive with default renderer
pub const enable_default_3d_primitive = if (@hasDecl(game, "jok_enable_default_3d_primitive"))
    game.jok_enable_default_3d_primitive
else
    true;
