const std = @import("std");
const builtin = @import("builtin");
const sdl = @import("sdl");
const context = @import("context.zig");
const jok = @import("jok.zig");
const deps = jok.deps;
const config = jok.config;
const zmesh = deps.zmesh;
const zaudio = deps.zaudio;
const imgui = deps.imgui;
const bos = @import("build_options");
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
            \\    pub fn init(ctx: *jok.Context) anyerror!void
            \\    pub fn event(ctx: *jok.Context, e: sdl.Event) anyerror!void
            \\    pub fn update(ctx: *jok.Context) anyerror!void
            \\    pub fn draw(ctx: *jok.Context) anyerror!void
            \\    pub fn quit(ctx: *jok.Context) void
        );
    }
    switch (@typeInfo(@typeInfo(@TypeOf(game.init)).Fn.return_type.?)) {
        .ErrorUnion => |info| if (info.payload != void) {
            @compileError("`init` must return anyerror!void");
        },
        else => @compileError("`init` must return anyerror!void"),
    }
    switch (@typeInfo(@typeInfo(@TypeOf(game.event)).Fn.return_type.?)) {
        .ErrorUnion => |info| if (info.payload != void) {
            @compileError("`event` must return anyerror!void");
        },
        else => @compileError("`init` must return anyerror!void"),
    }
    switch (@typeInfo(@typeInfo(@TypeOf(game.update)).Fn.return_type.?)) {
        .ErrorUnion => |info| if (info.payload != void) {
            @compileError("`update` must return anyerror!void");
        },
        else => @compileError("`update` must return anyerror!void"),
    }
    switch (@typeInfo(@typeInfo(@TypeOf(game.draw)).Fn.return_type.?)) {
        .ErrorUnion => |info| if (info.payload != void) {
            @compileError("`draw` must return anyerror!void");
        },
        else => @compileError("`draw` must return anyerror!void"),
    }
    switch (@typeInfo(@typeInfo(@TypeOf(game.quit)).Fn.return_type.?)) {
        .Void => {},
        else => @compileError("`quit` must return void"),
    }
}

/// Check system information
fn checkSys() !void {
    const target = builtin.target;
    var sdl_version: sdl.c.SDL_version = undefined;
    sdl.c.SDL_GetVersion(&sdl_version);
    const ram_size = sdl.c.SDL_GetSystemRAM();

    // Print system info
    context.log.info(
        \\System info:
        \\    Build Mode  : {s}
        \\    Zig Version : {d}.{d}.{d}
        \\    CPU         : {s}
        \\    ABI         : {s}
        \\    SDL         : {}.{}.{}
        \\    Platform    : {s}
        \\    Memory      : {d}MB
    ,
        .{
            std.meta.tagName(builtin.mode),
            builtin.zig_version.major,
            builtin.zig_version.minor,
            builtin.zig_version.patch,
            std.meta.tagName(target.cpu.arch),
            std.meta.tagName(target.abi),
            sdl_version.major,
            sdl_version.minor,
            sdl_version.patch,
            std.meta.tagName(target.os.tag),
            ram_size,
        },
    );

    if (sdl_version.major < 2 or (sdl_version.minor == 0 and sdl_version.patch < 18)) {
        context.log.err("Need SDL least version >= 2.0.18", .{});
        return sdl.makeError();
    }

    if (config.exit_on_recv_esc) {
        context.log.info("Press ESC to exit game", .{});
    }
}

/// Initialize modules
fn initModules(ctx: *context.Context) !void {
    zmesh.init(ctx.allocator);

    if (bos.use_imgui) {
        try imgui.init(ctx);
    }

    if (bos.use_zaudio) {
        zaudio.init(ctx.allocator);
    }

    if (config.enable_default_2d_primitive) {
        try jok.j2d.primitive.init(ctx);
    }

    if (config.enable_default_3d_primitive) {
        try jok.j3d.primitive.init(ctx, null);
    }
}

/// Deinitialize modules
fn deinitModules() void {
    if (config.enable_default_3d_primitive) {
        jok.j3d.primitive.deinit();
    }

    if (config.enable_default_2d_primitive) {
        jok.j2d.primitive.deinit();
    }

    if (bos.use_zaudio) {
        zaudio.deinit();
    }

    if (bos.use_imgui) {
        imgui.deinit();
    }

    zmesh.deinit();
}

/// Logging level, used by std.log
pub const log_level = config.log_level;

pub fn main() anyerror!void {
    try checkSys();

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
        window_flags.dim = .minimized;
    }
    if (config.enable_maximized) {
        window_flags.dim = .maximized;
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
        ctx.allocator = a;
    } else {
        gpa = AllocatorType{};
        ctx.allocator = gpa.?.allocator();
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
    ctx.toggleAlwaysOnTop(config.enable_always_on_top);

    // Apply mouse mode
    switch (config.mouse_mode) {
        .normal => {},
        .hide => {
            _ = sdl.c.SDL_ShowCursor(sdl.c.SDL_DISABLE);
        },
        .relative => {
            _ = sdl.c.SDL_SetRelativeMouseMode(sdl.c.SDL_TRUE);
        },
    }

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

    // Init modules
    try initModules(&ctx);
    defer deinitModules();

    // Init game object
    try game.init(&ctx);
    defer game.quit(&ctx);

    // Init common time-related vars
    ctx._pc_freq = @intToFloat(f64, sdl.c.SDL_GetPerformanceFrequency());
    ctx._last_pc = sdl.c.SDL_GetPerformanceCounter();

    // Game loop
    while (!ctx.quit) {
        // Event processing
        while (sdl.pollEvent()) |e| {
            if (bos.use_imgui) {
                _ = imgui.processEvent(e);
            }

            if (e == .key_up and e.key_up.scancode == .escape and
                config.exit_on_recv_esc)
            {
                ctx.kill();
            } else if (e == .quit and config.exit_on_recv_quit) {
                ctx.kill();
            } else {
                game.event(&ctx, e) catch |err| {
                    context.log.err("got error in `event`: {}", .{err});
                    if (@errorReturnTrace()) |trace| {
                        std.debug.dumpStackTrace(trace.*);
                        break;
                    }
                };
            }
        }

        // Internal loop
        ctx.internalLoop(config.fps_limit, game.update, game.draw);

        // Update frame stats and display
        if (ctx.updateFrameStats() and config.enable_framestat_display) {
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
