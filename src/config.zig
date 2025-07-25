const std = @import("std");
const builtin = @import("builtin");
const jok = @import("jok.zig");

pub const Config = struct {
    /// Logging level
    jok_log_level: std.log.Level = std.log.default_level,

    /// FPS limiting
    jok_fps_limit: FpsLimit = .{ .manual = 60 },

    /// Assets accessing method
    jok_enable_physfs: bool = true,

    /// Clearing color of framebuffer
    jok_framebuffer_color: jok.Color = .black,

    /// Canvas size (default to framebuffer's size)
    jok_canvas_size: ?jok.Size = null,

    /// Whether enable post-processing
    jok_enable_post_processing: bool = false,

    /// Headless mode
    jok_headless: bool = false,

    /// Window attributes
    jok_window_title: [:0]const u8 = "mygame",
    jok_window_size: WindowSize = .{ .custom = .{ .width = 800, .height = 600 } },
    jok_window_min_size: ?jok.Size = null,
    jok_window_max_size: ?jok.Size = null,
    jok_window_resizable: bool = false,
    jok_window_borderless: bool = false,
    jok_window_always_on_top: bool = false,
    jok_window_ime_ui: bool = false,
    jok_window_mouse_mode: MouseMode = .normal,
    jok_window_highdpi: bool = false,

    /// Exit event processing
    jok_exit_on_recv_esc: bool = true,
    jok_exit_on_recv_quit: bool = true,

    /// Whether detect memory-leak on shutdown
    jok_check_memory_leak: bool = builtin.mode == .Debug,

    /// Whether let imgui load/save ini file
    jok_imgui_ini_file: bool = false,

    /// Prebuild atlas for debug font
    jok_prebuild_atlas: u32 = 16,

    /// Whether enable detailed frame statistics
    jok_detailed_frame_stats: bool = true,
};

/// Initial size of window
pub const WindowSize = union(enum) {
    maximized,
    fullscreen,
    custom: struct { width: u32, height: u32 },
};

/// Graphics flushing method
pub const FpsLimit = union(enum) {
    none, // No limit, draw as fast as we can
    auto, // Enable vsync when hardware acceleration is available, default to 30 fps otherwise
    manual: u32, // Capped to given fps, fixed time step

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
    // Fullscreen: hide cursor, relative mode
    // Windowed: show cursor
    normal,

    // Fullscreen: hide cursor
    // Windowed: hide cursor
    hide_in_window,

    // Fullscreen: hide cursor, relative mode
    // Windowed: hide cursor, relative mode
    hide_always,
};

/// Validate and init setup configurations
pub fn init(comptime game: anytype) Config {
    @setEvalBranchQuota(10000);

    var cfg = Config{};
    const options = [_]struct { name: []const u8, desc: []const u8 }{
        .{ .name = "jok_log_level", .desc = "logging level" },
        .{ .name = "jok_fps_limit", .desc = "fps limit setting" },
        .{ .name = "jok_enable_physfs", .desc = "whether use physfs to access game assets" },
        .{ .name = "jok_framebuffer_color", .desc = "clearing color of framebuffer" },
        .{ .name = "jok_canvas_size", .desc = "size of canvas" },
        .{ .name = "jok_enable_post_processing", .desc = "whether enable post-processing facility" },
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
        .{ .name = "jok_window_highdpi", .desc = "whether enable high dpi support" },
        .{ .name = "jok_exit_on_recv_esc", .desc = "whether exit game when esc is pressed" },
        .{ .name = "jok_exit_on_recv_quit", .desc = "whether exit game when getting quit event" },
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
