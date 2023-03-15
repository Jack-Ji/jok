const std = @import("std");
const jok = @import("jok.zig");
const sdl = jok.sdl;

pub const Config = struct {
    /// Logging level
    jok_log_level: std.log.Level = std.log.default_level,

    /// FPS limiting (auto means vsync)
    jok_fps_limit: FpsLimit = .auto,

    /// Whether let user control graphics refreshing
    jok_manual_refreshing: bool = false,

    /// Display frame stats on title bar
    jok_framestat_display: bool = true,

    /// Default memory allocator
    jok_allocator: ?std.mem.Allocator = null,

    /// Default memory allocator settings
    jok_mem_leak_checks: bool = true,
    jok_mem_detail_logs: bool = false,

    /// Whether fallback to software renderer
    jok_software_renderer: bool = true,

    /// Window's title
    jok_window_title: [:0]const u8 = "jok",

    /// Position of window
    jok_window_pos_x: sdl.WindowPosition = .default,
    jok_window_pos_y: sdl.WindowPosition = .default,

    /// Width/height of window
    jok_window_width: u32 = 800,
    jok_window_height: u32 = 600,

    /// Mimimum size of window
    jok_window_min_size: ?sdl.Size = null,

    /// Maximumsize of window
    jok_window_max_size: ?sdl.Size = null,

    // Resizable switch
    jok_window_resizable: bool = false,

    /// Display switch
    jok_window_fullscreen: bool = false,

    /// Borderless window
    jok_window_borderless: bool = false,

    /// Minimize window
    jok_window_minimized: bool = false,

    /// Maximize window
    jok_window_maximized: bool = false,

    /// Window always on top
    jok_window_always_on_top: bool = false,

    /// Whether show IME UI
    jok_window_ime_ui: bool = false,

    /// Mouse mode
    jok_mouse_mode: MouseMode = .normal,

    /// Exit game when get esc event
    jok_exit_on_recv_esc: bool = true,

    /// Exit game when get quit event
    jok_exit_on_recv_quit: bool = false,

    /// Whether let IMGUI load/save ini file
    jok_imgui_ini_file: bool = false,

    /// Prebuild atlas for debug font
    jok_prebuild_atlas: ?u32 = 16,
};

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

/// Memory allocator type
pub const AllocatorType = std.heap.GeneralPurposeAllocator(.{});

/// Validate and init setup configurations
pub fn init(comptime game: anytype) Config {
    var cfg = Config{};
    const options = [_]struct { name: []const u8, desc: []const u8 }{
        .{ .name = "jok_log_level", .desc = "logging level" },
        .{ .name = "jok_fps_limit", .desc = "fps limit setting" },
        .{ .name = "jok_manual_refreshing", .desc = "whether let user control graphics refreshing" },
        .{ .name = "jok_framestat_display", .desc = "whether refresh and display frame statistics on title-bar of window" },
        .{ .name = "jok_allocator", .desc = "default memory allocator" },
        .{ .name = "jok_mem_leak_checks", .desc = "whether default memory allocator check memleak when exiting" },
        .{ .name = "jok_mem_detail_logs", .desc = "whether default memory allocator print detailed memory alloc/free logs" },
        .{ .name = "jok_software_renderer", .desc = "whether fallback to software renderer when hardware acceleration isn't available" },
        .{ .name = "jok_window_title", .desc = "title of window" },
        .{ .name = "jok_window_pos_x", .desc = "horizontal position of window" },
        .{ .name = "jok_window_pos_y", .desc = "vertical position of window" },
        .{ .name = "jok_window_width", .desc = "width of window" },
        .{ .name = "jok_window_height", .desc = "height of window" },
        .{ .name = "jok_window_min_size", .desc = "minimum size of window" },
        .{ .name = "jok_window_max_size", .desc = "maximum size of window" },
        .{ .name = "jok_window_resizable", .desc = "whether window is resizable" },
        .{ .name = "jok_window_fullscreen", .desc = "whether use fullscreen mode" },
        .{ .name = "jok_window_borderless", .desc = "whether window is borderless" },
        .{ .name = "jok_window_minimized", .desc = "whether window is minimized when startup" },
        .{ .name = "jok_window_maximized", .desc = "whether window is maximized when startup" },
        .{ .name = "jok_window_ime_ui", .desc = "whether show ime ui" },
        .{ .name = "jok_window_always_on_top", .desc = "whether window is locked to most front layer" },
        .{ .name = "jok_mouse_mode", .desc = "mouse mode setting" },
        .{ .name = "jok_exit_on_recv_esc", .desc = "whether exit game when esc is pressed" },
        .{ .name = "jok_exit_on_recv_quit", .desc = "whether exit game when getting quit event" },
        .{ .name = "jok_imgui_ini_file", .desc = "whether let IMGUI load/save ini file" },
        .{ .name = "jok_prebuild_atlas", .desc = "whether prebuild atlas for debug font" },
    };
    const game_struct = @typeInfo(game).Struct;
    for (game_struct.decls) |f| {
        if (!std.mem.startsWith(u8, f.name, "jok_")) {
            continue;
        }
        if (!f.is_pub) {
            @compileError("Validation of setup options failed, option `" ++ f.name ++ "` need to be public!");
        }
        for (options) |o| {
            if (std.mem.eql(u8, o.name, f.name)) {
                const CfgFieldType = @TypeOf(@field(cfg, f.name));
                const GameFieldType = @TypeOf(@field(game, f.name));
                const cfg_type = @typeInfo(CfgFieldType);
                const game_type = @typeInfo(GameFieldType);
                if (CfgFieldType == GameFieldType or
                    (cfg_type == .Int and game_type == .ComptimeInt) or
                    (cfg_type == .Optional and cfg_type.Optional.child == GameFieldType))
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
                bs = std.fmt.bufPrint(buf[off..], "\n\t" ++ o.name ++ " (" ++ @typeName(o.T) ++ "): " ++ o.desc ++ ".", .{}) catch unreachable;
                off += bs.len;
            }
            @compileError(buf[0..off]);
        }
    }

    return cfg;
}
