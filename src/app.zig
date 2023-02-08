const std = @import("std");
const builtin = @import("builtin");
const sdl = @import("sdl");
const jok = @import("jok");
const config = jok.config;
const imgui = jok.imgui;
const game = @import("game");

// Validate exposed game api
comptime {
    if (!@hasDecl(game, "init") or
        !@hasDecl(game, "event") or
        !@hasDecl(game, "update") or
        !@hasDecl(game, "draw") or
        !@hasDecl(game, "quit"))
    {
        @compileError(
            \\You must provide following 5 public api in your game code:
            \\    pub fn init(ctx: *jok.Context) !void
            \\    pub fn event(ctx: *jok.Context, e: sdl.Event) !void
            \\    pub fn update(ctx: *jok.Context) !void
            \\    pub fn draw(ctx: *jok.Context) !void
            \\    pub fn quit(ctx: *jok.Context) void
        );
    }
    switch (@typeInfo(@typeInfo(@TypeOf(game.init)).Fn.return_type.?)) {
        .ErrorUnion => |info| if (info.payload != void) {
            @compileError("`init` must return !void");
        },
        else => @compileError("`init` must return !void"),
    }
    switch (@typeInfo(@typeInfo(@TypeOf(game.event)).Fn.return_type.?)) {
        .ErrorUnion => |info| if (info.payload != void) {
            @compileError("`event` must return !void");
        },
        else => @compileError("`init` must return !void"),
    }
    switch (@typeInfo(@typeInfo(@TypeOf(game.update)).Fn.return_type.?)) {
        .ErrorUnion => |info| if (info.payload != void) {
            @compileError("`update` must return !void");
        },
        else => @compileError("`update` must return !void"),
    }
    switch (@typeInfo(@typeInfo(@TypeOf(game.draw)).Fn.return_type.?)) {
        .ErrorUnion => |info| if (info.payload != void) {
            @compileError("`draw` must return !void");
        },
        else => @compileError("`draw` must return !void"),
    }
    switch (@typeInfo(@typeInfo(@TypeOf(game.quit)).Fn.return_type.?)) {
        .Void => {},
        else => @compileError("`quit` must return void"),
    }
}

// Validate setup configurations
comptime {
    const config_options = [_]struct { name: []const u8, T: type, desc: []const u8 }{
        .{ .name = "jok_log_level", .T = std.log.Level, .desc = "logging level" },
        .{ .name = "jok_fps_limit", .T = config.FpsLimit, .desc = "fps limit setting" },
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
        .{ .name = "jok_mouse_mode", .T = config.MouseMode, .desc = "mouse mode setting" },
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

/// Options for zig executable
pub const std_options = struct {
    pub const log_level = if (@hasDecl(game, "jok_log_level"))
        game.jok_log_level
    else
        std.log.default_level;
};

/// Setup runtime configurations
fn setupConfigurations() void {
    if (@hasDecl(game, "jok_log_level")) {
        config.log_level = game.jok_log_level;
    }
    if (@hasDecl(game, "jok_fps_limit")) {
        config.fps_limit = game.jok_fps_limit;
    }
    if (@hasDecl(game, "jok_framestat_display")) {
        config.enable_framestat_display = game.jok_framestat_display;
    }
    if (@hasDecl(game, "jok_allocator")) {
        config.allocator = game.jok_allocator;
    }
    if (@hasDecl(game, "jok_mem_leak_checks")) {
        config.enable_mem_leak_checks = game.jok_mem_leak_checks;
    }
    if (@hasDecl(game, "jok_mem_detail_logs")) {
        config.enable_mem_detail_logs = game.jok_mem_detail_logs;
    }
    if (@hasDecl(game, "jok_software_renderer")) {
        config.enable_software_renderer = game.jok_software_renderer;
    }
    if (@hasDecl(game, "jok_window_title")) {
        config.title = game.jok_window_title;
    }
    if (@hasDecl(game, "jok_window_pos_x")) {
        config.pos_x = game.jok_window_pos_x;
    }
    if (@hasDecl(game, "jok_window_pos_y")) {
        config.pos_y = game.jok_window_pos_y;
    }
    if (@hasDecl(game, "jok_window_width")) {
        config.width = game.jok_window_width;
    }
    if (@hasDecl(game, "jok_window_height")) {
        config.height = game.jok_window_height;
    }
    if (@hasDecl(game, "jok_window_min_size")) {
        config.min_size = game.jok_window_min_size;
    }
    if (@hasDecl(game, "jok_window_max_size")) {
        config.max_size = game.jok_window_max_size;
    }
    if (@hasDecl(game, "jok_window_resizable")) {
        config.enable_resizable = game.jok_window_resizable;
    }
    if (@hasDecl(game, "jok_window_fullscreen")) {
        config.enable_fullscreen = game.jok_window_fullscreen;
    }
    if (@hasDecl(game, "jok_window_borderless")) {
        config.enable_borderless = game.jok_window_borderless;
    }
    if (@hasDecl(game, "jok_window_minimized")) {
        config.enable_minimized = game.jok_window_minimized;
    }
    if (@hasDecl(game, "jok_window_maximized")) {
        config.enable_maximized = game.jok_window_maximized;
    }
    if (@hasDecl(game, "jok_window_always_on_top")) {
        config.enable_always_on_top = game.jok_window_always_on_top;
    }
    if (@hasDecl(game, "jok_mouse_mode")) {
        config.mouse_mode = game.jok_mouse_mode;
    }
    if (@hasDecl(game, "jok_exit_on_recv_esc")) {
        config.exit_on_recv_esc = game.jok_exit_on_recv_esc;
    }
    if (@hasDecl(game, "jok_exit_on_recv_quit")) {
        config.exit_on_recv_quit = game.jok_exit_on_recv_esc;
    }
}

pub fn main() !void {
    setupConfigurations();

    // Init memory allocator
    const AllocatorType = std.heap.GeneralPurposeAllocator(.{
        .safety = if (@hasDecl(game, "jok_mem_leak_checks") and
            game.enable_mem_leak_checks)
            true
        else
            false,
        .verbose_log = if (@hasDecl(game, "jok_mem_detail_logs") and
            game.enable_mem_detail_logs)
            true
        else
            false,
        .enable_memory_limit = true,
    });
    var gpa: ?AllocatorType = null;
    var allocator = if (config.allocator) |a| a else BLK: {
        gpa = AllocatorType{};
        break :BLK gpa.?.allocator();
    };
    defer if (gpa) |*a| {
        if (a.deinit()) {
            @panic("jok: memory leaks happened!");
        }
    };

    // Init application context
    var ctx = try jok.Context.init(allocator);
    defer ctx.deinit();

    // Init game object
    try game.init(&ctx);
    defer game.quit(&ctx);

    // Start Game loop
    var last_time = ctx.seconds;
    while (!ctx.quit) {
        ctx.tick(game.event, game.update, game.draw);

        if (ctx.seconds - last_time > 1 and config.enable_framestat_display) {
            last_time = ctx.seconds;
            var buf: [128]u8 = undefined;
            const txt = std.fmt.bufPrintZ(
                &buf,
                "{s} | {d}x{d} | FPS: {d:.1}, {s} | AVG-CPU: {d:.1}ms | MEM: {:.3} | RD: {s} | B-MODE: {s}",
                .{
                    config.title,
                    ctx.getWindowSize().w,
                    ctx.getWindowSize().h,
                    ctx.fps,
                    config.fps_limit.str(),
                    ctx.average_cpu_time,
                    std.fmt.fmtIntSizeBin(if (gpa) |a| a.total_requested_bytes else 0),
                    ctx.getRendererName(),
                    if (builtin.mode == .Debug) "debug" else "release",
                },
            ) catch unreachable;
            sdl.c.SDL_SetWindowTitle(ctx.window.ptr, txt.ptr);
        }
    }
}
