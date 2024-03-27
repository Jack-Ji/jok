const std = @import("std");
const jok = @import("jok.zig");
const sdl = jok.sdl;

pub const Config = struct {
    /// Logging level
    jok_log_level: std.log.Level = std.log.default_level,

    /// FPS limiting
    jok_fps_limit: FpsLimit = .{ .manual = 60 },

    /// Default memory allocator
    jok_allocator: ?std.mem.Allocator = null,

    /// Default memory allocator settings
    jok_mem_leak_checks: bool = true,
    jok_mem_detail_logs: bool = false,

    /// Whether use pure-software renderer (NOTE: SDL might ignore this setting when GPU is available)
    jok_software_renderer: bool = false,

    /// Whether fallback to software renderer when gpu isn't found
    jok_software_renderer_fallback: bool = true,

    /// Window's title
    jok_window_title: [:0]const u8 = "jok",

    /// Position of window
    jok_window_pos_x: sdl.WindowPosition = .default,
    jok_window_pos_y: sdl.WindowPosition = .default,

    /// Size of window
    jok_window_size: WindowSize = .{ .custom = .{ .width = 800, .height = 600 } },

    /// Size of canvas (default to framebuffer's size)
    jok_canvas_size: ?sdl.Size = null,

    /// Mimimum size of window
    jok_window_min_size: ?sdl.Size = null,

    /// Maximumsize of window
    jok_window_max_size: ?sdl.Size = null,

    // Resizable switch
    jok_window_resizable: bool = false,

    /// Borderless window
    jok_window_borderless: bool = false,

    /// Window always on top
    jok_window_always_on_top: bool = false,

    /// Whether show IME UI
    jok_window_ime_ui: bool = false,

    /// Mouse mode
    jok_mouse_mode: MouseMode = .normal,

    /// Exit game when get esc event
    jok_exit_on_recv_esc: bool = true,

    /// Exit game when get quit event
    jok_exit_on_recv_quit: bool = true,

    /// Whether let imgui load/save ini file
    jok_imgui_ini_file: bool = false,

    /// Prebuild atlas for debug font
    jok_prebuild_atlas: u32 = 16,

    /// Whether enable detailed frame statistics
    jok_detailed_frame_stats: bool = true,

    /// Whether enable high dpi support
    jok_high_dpi_support: bool = false,
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
    normal,
    hide,
};

/// Memory allocator type
pub const AllocatorType = std.heap.GeneralPurposeAllocator(.{});

/// Validate and init setup configurations
pub fn init(comptime game: anytype) Config {
    @setEvalBranchQuota(10000);

    var cfg = Config{};
    const options = [_]struct { name: []const u8, desc: []const u8 }{
        .{ .name = "jok_log_level", .desc = "logging level" },
        .{ .name = "jok_fps_limit", .desc = "fps limit setting" },
        .{ .name = "jok_allocator", .desc = "default memory allocator" },
        .{ .name = "jok_mem_leak_checks", .desc = "whether default memory allocator check memleak when exiting" },
        .{ .name = "jok_mem_detail_logs", .desc = "whether default memory allocator print detailed memory alloc/free logs" },
        .{ .name = "jok_software_renderer", .desc = "whether use software renderer" },
        .{ .name = "jok_software_renderer_fallback", .desc = "whether fallback to software renderer when hardware acceleration isn't available" },
        .{ .name = "jok_window_title", .desc = "title of window" },
        .{ .name = "jok_window_pos_x", .desc = "horizontal position of window" },
        .{ .name = "jok_window_pos_y", .desc = "vertical position of window" },
        .{ .name = "jok_window_size", .desc = "size of window" },
        .{ .name = "jok_canvas_size", .desc = "size of canvas" },
        .{ .name = "jok_window_min_size", .desc = "minimum size of window" },
        .{ .name = "jok_window_max_size", .desc = "maximum size of window" },
        .{ .name = "jok_window_resizable", .desc = "whether window is resizable" },
        .{ .name = "jok_window_borderless", .desc = "whether window is borderless" },
        .{ .name = "jok_window_ime_ui", .desc = "whether show ime ui" },
        .{ .name = "jok_window_always_on_top", .desc = "whether window is locked to most front layer" },
        .{ .name = "jok_mouse_mode", .desc = "mouse mode setting" },
        .{ .name = "jok_exit_on_recv_esc", .desc = "whether exit game when esc is pressed" },
        .{ .name = "jok_exit_on_recv_quit", .desc = "whether exit game when getting quit event" },
        .{ .name = "jok_imgui_ini_file", .desc = "whether let imgui load/save ini file" },
        .{ .name = "jok_prebuild_atlas", .desc = "whether prebuild atlas for debug font" },
        .{ .name = "jok_detailed_frame_stats", .desc = "whether enable detailed frame statistics" },
        .{ .name = "jok_high_dpi_support", .desc = "whether enable high dpi support" },
    };
    const game_struct = @typeInfo(game).Struct;
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
                    (cfg_type == .Int and game_type == .ComptimeInt) or
                    (cfg_type == .Optional and cfg_type.Optional.child == GameFieldType) or
                    (cfg_type == .Union and cfg_type.Union.tag_type == GameFieldType))
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
