const std = @import("std");
const sdl = @import("sdl");
const jok = @import("jok.zig");
const game = @import("game");

// Validate setup configurations
comptime {
    const config_options = [_]struct { name: []const u8, T: type, desc: []const u8 }{
        .{ .name = "jok_log_level", .T = std.log.Level, .desc = "logging level" },
        .{ .name = "jok_fps_limit", .T = FpsLimit, .desc = "fps limit setting" },
        .{ .name = "jok_framestat_display", .T = bool, .desc = "whether refresh and display frame statistics on title-bar of window" },
        .{ .name = "jok_allocator", .T = std.mem.Allocator, .desc = "default memory allocator" },
        .{ .name = "jok_mem_leak_checks", .T = bool, .desc = "whether default memory allocator check memleak when exiting" },
        .{ .name = "jok_mem_detail_logs", .T = bool, .desc = "whether default memory allocator print detailed memory alloc/free logs" },
        .{ .name = "jok_software_renderer", .T = bool, .desc = "whether fallback to software renderer" },
        .{ .name = "jok_window_title", .T = [:0]const u8, .desc = "title of window" },
        .{ .name = "jok_window_pos_x", .T = sdl.WindowPosition, .desc = "horizontal position of window" },
        .{ .name = "jok_window_pos_y", .T = sdl.WindowPosition, .desc = "vertical position of window" },
        .{ .name = "jok_window_width", .T = u32, .desc = "width of window" },
        .{ .name = "jok_window_height", .T = u32, .desc = "height of window" },
        .{ .name = "jok_window_min_size", .T = sdl.Size, .desc = "minimum size of window" },
        .{ .name = "jok_window_max_size", .T = sdl.Size, .desc = "maximum size of window" },
        .{ .name = "jok_window_resizable", .T = bool, .desc = "whether window is resizable" },
        .{ .name = "jok_window_fullscreen", .T = bool, .desc = "whether use fullscreen mode" },
        .{ .name = "jok_window_borderless", .T = bool, .desc = "whether window is borderless" },
        .{ .name = "jok_window_minimized", .T = bool, .desc = "whether window is minimized when startup" },
        .{ .name = "jok_window_maximized", .T = bool, .desc = "whether window is maximized when startup" },
        .{ .name = "jok_window_always_on_top", .T = bool, .desc = "whether window is locked to most front layer" },
        .{ .name = "jok_mouse_mode", .T = MouseMode, .desc = "mouse mode setting" },
        .{ .name = "jok_default_2d_primitive", .T = bool, .desc = "whether init j2d" },
        .{ .name = "jok_default_3d_primitive", .T = bool, .desc = "whether init j3d" },
        .{ .name = "jok_exit_on_recv_esc", .T = bool, .desc = "whether exit game when get esc event" },
        .{ .name = "jok_exit_on_recv_quit", .T = bool, .desc = "whether exit game when get quit event" },
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
            var buf: [2048]u8 = undefined;
            var off: usize = 0;
            var bs = std.fmt.bufPrint(&buf, "Validation of setup options failed, invalid option name: `" ++ f.name ++ "`", .{}) catch unreachable;
            off += bs.len;
            bs = std.fmt.bufPrint(buf[off..], "\nSupported options:", .{}) catch unreachable;
            off += bs.len;
            inline for (config_options) |o| {
                bs = std.fmt.bufPrint(buf[off..], "\n\t" ++ o.name ++ " (" ++ @typeName(o.T) ++ "): " ++ o.desc ++ ".", .{}) catch unreachable;
                off += bs.len;
            }
            @compileError(buf[0..off]);
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

/// Logging level
pub const log_level: std.log.Level = if (@hasDecl(game, "jok_log_level"))
    game.jok_log_level
else
    std.log.default_level;

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

/// Init j2d.primitive with default renderer
pub const enable_default_2d_primitive = if (@hasDecl(game, "jok_default_2d_primitive"))
    game.jok_default_2d_primitive
else
    true;

/// Init j3d.primitive with default renderer
pub const enable_default_3d_primitive = if (@hasDecl(game, "jok_default_3d_primitive"))
    game.jok_default_3d_primitive
else
    true;

/// Exit game when get esc event
pub const exit_on_recv_esc = if (@hasDecl(game, "jok_exit_on_recv_esc"))
    game.jok_exit_on_recv_esc
else
    true;

/// Exit game when get quit event
pub const exit_on_recv_quit = if (@hasDecl(game, "jok_exit_on_recv_quit"))
    game.jok_exit_on_recv_esc
else
    false;
