const std = @import("std");
const sdl = @import("sdl");
const jok = @import("jok.zig");

/// Logging level
pub var jok_log_level: std.log.Level = std.log.default_level;

/// FPS limiting (auto means vsync)
pub var jok_fps_limit: FpsLimit = .auto;

/// Display frame stats on title bar
pub var jok_framestat_display = true;

/// Default memory allocator
pub var jok_allocator: ?std.mem.Allocator = null;

/// Default memory allocator settings
pub var jok_mem_leak_checks = true;
pub var jok_mem_detail_logs = false;

/// Whether fallback to software renderer
pub var jok_software_renderer: bool = true;

/// Window's title
pub var jok_window_title: [:0]const u8 = "jok";

/// Position of window
pub var jok_window_pos_x: sdl.WindowPosition = .default;
pub var jok_window_pos_y: sdl.WindowPosition = .default;

/// Width/height of window
pub var jok_window_width: u32 = 800;
pub var jok_window_height: u32 = 600;

/// Mimimum size of window
pub var jok_window_min_size: ?sdl.Size = null;

/// Maximumsize of window
pub var jok_window_max_size: ?sdl.Size = null;

// Resizable switch
pub var jok_window_resizable = false;

/// Display switch
pub var jok_window_fullscreen = false;

/// Borderless window
pub var jok_window_borderless = false;

/// Minimize window
pub var jok_window_minimized = false;

/// Maximize window
pub var jok_window_maximized = false;

/// Window always on top
pub var jok_window_always_on_top = false;

/// Mouse mode
pub var jok_mouse_mode: MouseMode = .normal;

/// Exit game when get esc event
pub var jok_exit_on_recv_esc = true;

/// Exit game when get quit event
pub var jok_exit_on_recv_quit = false;

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

/// Validate and init setup configurations
pub fn init(comptime game: anytype) void {
    comptime {
        const config_options = [_]struct { name: []const u8, T: type, desc: []const u8 }{
            .{ .name = "jok_log_level", .T = std.log.Level, .desc = "logging level" },
            .{ .name = "jok_fps_limit", .T = FpsLimit, .desc = "fps limit setting" },
            .{ .name = "jok_framestat_display", .T = bool, .desc = "whether refresh and display frame statistics on title-bar of window" },
            .{ .name = "jok_allocator", .T = std.mem.Allocator, .desc = "default memory allocator" },
            .{ .name = "jok_mem_leak_checks", .T = bool, .desc = "whether default memory allocator check memleak when exiting" },
            .{ .name = "jok_mem_detail_logs", .T = bool, .desc = "whether default memory allocator print detailed memory alloc/free logs" },
            .{ .name = "jok_software_renderer", .T = bool, .desc = "whether fallback to software renderer when hardware acceleration isn't available" },
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
            .{ .name = "jok_exit_on_recv_esc", .T = bool, .desc = "whether exit game when esc is pressed" },
            .{ .name = "jok_exit_on_recv_quit", .T = bool, .desc = "whether exit game when getting quit event" },
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
                    } else {
                        @field(@This(), o.name) = @field(game, o.name);
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
}
