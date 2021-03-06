const std = @import("std");
const builtin = @import("builtin");
const sdl = @import("sdl");
const context = @import("context.zig");
const jok = @import("jok.zig");
const config = jok.config;
const event = jok.event;
const audio = jok.audio;
const p3d = jok.gfx.@"3d".primitive;
const p2d = jok.gfx.@"2d".primitive;

// Import game object's declarations
const game = @import("game");
usingnamespace @import("game");

// Do compile-time checking
comptime {
    if (!@hasDecl(game, "init") or !@hasDecl(game, "loop") or !@hasDecl(game, "loop")) {
        @compileError(
            \\You must provide following 3 public api in your game code:
            \\    pub fn init(ctx: *jok.Context) anyerror!void
            \\    pub fn loop(ctx: *jok.Context) anyerror!void
            \\    pub fn quit(ctx: *jok.Context) void
        );
    }
    switch (@typeInfo(@typeInfo(@TypeOf(game.init)).Fn.return_type.?)) {
        .ErrorUnion => |info| if (info.payload != void) {
            @compileError("`init` must return anyerror!void");
        },
        else => @compileError("`init` must return anyerror!void"),
    }
    switch (@typeInfo(@typeInfo(@TypeOf(game.loop)).Fn.return_type.?)) {
        .ErrorUnion => |info| if (info.payload != void) {
            @compileError("`loop` must return anyerror!void");
        },
        else => @compileError("`loop` must return anyerror!void"),
    }
    switch (@typeInfo(@typeInfo(@TypeOf(game.quit)).Fn.return_type.?)) {
        .Void => {},
        else => @compileError("`quit` must return void"),
    }
}

/// Entrance point, never return until application is killed
pub fn main() anyerror!void {
    // Initialize SDL library
    var sdl_flags = sdl.InitFlags.everything;
    try sdl.init(sdl_flags);
    defer sdl.quit();

    // Create window
    var window_flags = sdl.WindowFlags{
        .allow_high_dpi = true,
        .mouse_capture = true,
        .mouse_focus = true,
    };
    if (config.enable_borderless) {
        window_flags.borderless = true;
    }
    if (config.enable_minimized) {
        window_flags.minimized = true;
    }
    if (config.enable_maximized) {
        window_flags.maximized = true;
    }
    var ctx: context.Context = .{
        .window = try sdl.createWindow(
            config.title,
            config.pos_x,
            config.pos_y,
            config.width,
            config.height,
            window_flags,
        ),
    };
    const AllocatorType = std.heap.GeneralPurposeAllocator(.{
        .safety = if (config.enable_mem_leak_checks) true else false,
        .verbose_log = if (config.enable_mem_detail_logs) true else false,
        .enable_memory_limit = true,
    });
    var gpa: ?AllocatorType = null;
    if (config.allocator) |a| {
        ctx.default_allocator = a;
    } else {
        gpa = AllocatorType{};
        ctx.default_allocator = gpa.?.allocator();
    }
    defer {
        if (gpa) |*a| {
            if (a.deinit()) {
                @panic("memory leaks happened!");
            }
        }
        ctx.window.destroy();
    }

    // Apply window options
    if (config.min_size) |size| {
        sdl.c.SDL_SetWindowMinimumSize(
            ctx.window.ptr,
            size.w,
            size.h,
        );
    }
    if (config.max_size) |size| {
        sdl.c.SDL_SetWindowMaximumSize(
            ctx.window.ptr,
            size.w,
            size.h,
        );
    }
    ctx.toggleResizable(config.enable_resizable);
    ctx.toggleFullscreeen(config.enable_fullscreen);
    ctx.toggleRelativeMouseMode(config.enable_relative_mouse_mode);

    // Create hardware accelerated renderer
    // Fallback to software renderer if allowed
    ctx.renderer = sdl.createRenderer(
        ctx.window,
        null,
        .{
            .accelerated = true,
            .present_vsync = config.fps_limit == .auto,
            .target_texture = true,
        },
    ) catch blk: {
        if (config.enable_software_renderer) {
            context.log.warn("hardware accelerated renderer isn't supported, fallback to software backend", .{});
            break :blk try sdl.createRenderer(
                ctx.window,
                null,
                .{
                    .software = true,
                    .present_vsync = config.fps_limit == .auto, // Doesn't matter actually, vsync won't work anyway
                    .target_texture = true,
                },
            );
        }
    };
    const rdinfo = try ctx.renderer.getInfo();
    ctx.is_software = ((rdinfo.flags & sdl.c.SDL_RENDERER_SOFTWARE) != 0);
    defer ctx.renderer.destroy();

    // Allocate audio engine
    ctx.audio = try audio.Engine.init(ctx.default_allocator, .{});
    defer ctx.audio.deinit();

    // Init builtin primitive renderers
    if (config.enable_3d_primitive) p3d.init(ctx.default_allocator);
    if (config.enable_2d_primitive) p2d.init(ctx.default_allocator);
    defer {
        if (config.enable_3d_primitive) p3d.deinit();
        if (config.enable_2d_primitive) p2d.deinit();
    }

    // Init before loop
    try game.init(&ctx);
    defer game.quit(&ctx);

    // Game loop
    context.perf_counter_freq = @intToFloat(f64, sdl.c.SDL_GetPerformanceFrequency());
    ctx.last_perf_counter = sdl.c.SDL_GetPerformanceCounter();
    while (!ctx.quit) {
        // Clear batched data of builtin primitive renders
        if (config.enable_3d_primitive) p3d.clear();
        if (config.enable_2d_primitive) p2d.clear();

        // Run game loop
        game.loop(&ctx) catch |e| {
            context.log.err("got error in loop: {}", .{e});
            if (@errorReturnTrace()) |trace| {
                std.debug.dumpStackTrace(trace.*);
                break;
            }
        };

        // Send draw commands with builtin primitive renderers
        if (config.enable_3d_primitive) try p3d.flush(ctx.renderer);
        if (config.enable_2d_primitive) try p2d.flush(ctx.renderer);

        // Sync with gpu and present rendering result
        ctx.present(config.fps_limit);

        // Update frame stats and display
        if (ctx.updateFrameStats() and config.enable_framestat_display) {
            var buf: [128]u8 = undefined;
            const txt = std.fmt.bufPrintZ(
                &buf,
                "{s} | FPS: {d:.1}, {s} | AVG-CPU: {d:.1}ms | RENDERER: {s} | MEM: {d:.2}kb",
                .{
                    config.title,
                    ctx.fps,
                    config.fps_limit.str(),
                    ctx.average_cpu_time,
                    ctx.getRendererName(),
                    if (gpa) |a| @intToFloat(f64, a.total_requested_bytes) / 1024.0 else 0,
                },
            ) catch unreachable;
            sdl.c.SDL_SetWindowTitle(ctx.window.ptr, txt.ptr);
        }
    }
}
