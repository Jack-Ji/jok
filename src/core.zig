const std = @import("std");
const builtin = @import("builtin");
const sdl = @import("sdl");
const jok = @import("jok.zig");
const event = jok.event;
const audio = jok.audio;

const log = std.log.scoped(.jok);

var perf_counter_freq: f64 = undefined;

/// Application context
pub const Context = struct {
    /// Default allocator
    default_allocator: std.mem.Allocator = undefined,

    /// Internal window
    window: sdl.Window,

    /// Renderer
    renderer: sdl.Renderer = undefined,

    /// Audio engine
    audio: *audio.Engine = undefined,

    /// Quit switch
    quit: bool = false,

    /// Resizable mode
    resizable: bool = undefined,

    /// Fullscreen mode
    fullscreen: bool = undefined,

    /// Relative mouse mode
    relative_mouse: bool = undefined,

    /// Number of seconds since launch/last-frame
    tick: f64 = 0,
    delta_tick: f32 = 0,
    last_perf_counter: u64 = 0,

    /// Frames stats
    fps: f32 = 0,
    average_cpu_time: f32 = 0,
    fps_refresh_time: f64 = 0,
    frame_counter: u32 = 0,
    frame_number: u64 = 0,

    /// Text buffer for rendering console font
    text_buf: [512]u8 = undefined,

    /// Update frame stats
    pub fn updateStats(self: *Context) bool {
        const counter = sdl.c.SDL_GetPerformanceCounter();
        self.delta_tick = @floatCast(
            f32,
            @intToFloat(f64, counter - self.last_perf_counter) / perf_counter_freq,
        );
        self.last_perf_counter = counter;
        self.tick += self.delta_tick;
        if ((self.tick - self.fps_refresh_time) >= 1.0) {
            const t = self.tick - self.fps_refresh_time;
            self.fps = @floatCast(
                f32,
                @intToFloat(f64, self.frame_counter) / t,
            );
            self.average_cpu_time = (1.0 / self.fps) * 1000.0;
            self.fps_refresh_time = self.tick;
            self.frame_counter = 0;
            return true;
        }
        self.frame_counter += 1;
        self.frame_number += 1;
        return false;
    }

    /// Kill app
    pub fn kill(self: *Context) void {
        self.quit = true;
    }

    /// Poll event
    pub fn pollEvent(self: *Context) ?event.Event {
        _ = self;
        while (sdl.pollEvent()) |e| {
            if (event.Event.init(e)) |ze| {
                return ze;
            }
        }
        return null;
    }

    /// Toggle resizable
    pub fn toggleResizable(self: *Context, on_off: ?bool) void {
        if (on_off) |state| {
            self.resizable = state;
        } else {
            self.resizable = !self.resizable;
        }
        _ = sdl.c.SDL_SetWindowResizable(
            self.window.ptr,
            if (self.resizable) sdl.c.SDL_TRUE else sdl.c.SDL_FALSE,
        );
    }

    /// Toggle fullscreen
    pub fn toggleFullscreeen(self: *Context, on_off: ?bool) void {
        if (on_off) |state| {
            self.fullscreen = state;
        } else {
            self.fullscreen = !self.fullscreen;
        }
        _ = sdl.c.SDL_SetWindowFullscreen(
            self.window.ptr,
            if (self.fullscreen) sdl.c.SDL_WINDOW_FULLSCREEN_DESKTOP else 0,
        );
    }

    /// Toggle relative mouse mode
    pub fn toggleRelativeMouseMode(self: *Context, on_off: ?bool) void {
        if (on_off) |state| {
            self.relative_mouse = state;
        } else {
            self.relative_mouse = !self.relative_mouse;
        }
        _ = sdl.c.SDL_SetRelativeMouseMode(
            if (self.relative_mouse) sdl.c.SDL_TRUE else sdl.c.SDL_FALSE,
        );
    }

    /// Get position of window
    pub fn getPosition(self: Context) struct { x: u32, y: u32 } {
        var x: u32 = undefined;
        var y: u32 = undefined;
        sdl.c.SDL_GetWindowPosition(
            self.window.ptr,
            @ptrCast(*c_int, &x),
            @ptrCast(*c_int, &y),
        );
        return .{ .x = x, .y = y };
    }

    /// Get size of window
    pub fn getWindowSize(self: Context) struct { w: u32, h: u32 } {
        var w: u32 = undefined;
        var h: u32 = undefined;
        sdl.c.SDL_GetWindowSize(
            self.window.ptr,
            @ptrCast(*c_int, &w),
            @ptrCast(*c_int, &h),
        );
        return .{ .w = w, .h = h };
    }

    /// Get size of framebuffer
    pub fn getFramebufferSize(self: Context) struct { w: u32, h: u32 } {
        const fsize = self.renderer.getOutputSize() catch unreachable;
        return .{
            .w = @intCast(u32, fsize.width_pixels),
            .h = @intCast(u32, fsize.height_pixels),
        };
    }

    /// Get pixel ratio
    pub fn getPixelRatio(self: Context) f32 {
        const wsize = self.getWindowSize();
        const fsize = self.renderer.getOutputSize() catch unreachable;
        return @intToFloat(f32, fsize.width_pixels) / @intToFloat(f32, wsize.w);
    }

    /// Get key status
    pub fn isKeyPressed(self: Context, key: sdl.Scancode) bool {
        _ = self;
        const state = sdl.c.SDL_GetKeyboardState(null);
        return state[@enumToInt(key)] == 1;
    }

    /// Get mouse state
    pub fn getMouseState(self: Context) sdl.MouseState {
        _ = self;
        return sdl.getMouseState();
    }

    /// Move mouse to given position (relative to window)
    pub fn setMousePosition(self: Context, xrel: f32, yrel: f32) void {
        var w: i32 = undefined;
        var h: i32 = undefined;
        sdl.c.SDL_GetWindowSize(self.window.ptr, &w, &h);
        sdl.c.SDL_WarpMouseInWindow(
            self.window.ptr,
            @floatToInt(i32, @intToFloat(f32, w) * xrel),
            @floatToInt(i32, @intToFloat(f32, h) * yrel),
        );
    }
};

/// Application configurations
pub const Game = struct {
    /// Custom memory allocator
    allocator: ?std.mem.Allocator = null,

    /// Default memory allocator settings
    enable_mem_leak_checks: bool = true,
    enable_mem_detail_logs: bool = false,

    /// Called once before rendering loop starts
    initFn: fn (ctx: *Context) anyerror!void,

    /// Called every frame
    loopFn: fn (ctx: *Context) anyerror!void,

    /// Called before life ends
    quitFn: fn (ctx: *Context) void,

    /// Window's title
    title: [:0]const u8 = "jok",

    /// Whether fallback to software renderer
    enable_software_renderer: bool = true,

    /// Position of window
    pos_x: sdl.WindowPosition = .default,
    pos_y: sdl.WindowPosition = .default,

    /// Width/height of window
    width: u32 = 800,
    height: u32 = 600,

    /// Mimimum size of window
    min_size: ?struct { w: u32, h: u32 } = null,

    /// Maximumsize of window
    max_size: ?struct { w: u32, h: u32 } = null,

    // Resizable switch
    enable_resizable: bool = false,

    /// Display switch
    enable_fullscreen: bool = false,

    /// Borderless window
    enable_borderless: bool = false,

    /// Minimize window
    enable_minimized: bool = false,

    /// Maximize window
    enable_maximized: bool = false,

    /// Relative mouse mode switch
    enable_relative_mouse_mode: bool = false,

    /// Vsync switch
    enable_vsync: bool = true,

    /// Display framestat on title
    enable_framestat_display: bool = true,
};

/// Entrance point, never return until application is killed
pub fn run(comptime g: Game) !void {
    try sdl.init(sdl.InitFlags.everything);
    defer sdl.quit();

    // Create window
    var flags = sdl.WindowFlags{
        .allow_high_dpi = true,
        .mouse_capture = true,
        .mouse_focus = true,
    };
    if (g.enable_borderless) {
        flags.borderless = true;
    }
    if (g.enable_minimized) {
        flags.minimized = true;
    }
    if (g.enable_maximized) {
        flags.maximized = true;
    }
    var ctx: Context = .{
        .window = try sdl.createWindow(
            g.title,
            g.pos_x,
            g.pos_y,
            g.width,
            g.height,
            flags,
        ),
    };
    const AllocatorType = std.heap.GeneralPurposeAllocator(.{
        .safety = if (g.enable_mem_leak_checks) true else false,
        .verbose_log = if (g.enable_mem_detail_logs) true else false,
        .enable_memory_limit = true,
    });
    var gpa: ?AllocatorType = null;
    if (g.allocator) |a| {
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
    if (g.min_size) |size| {
        sdl.c.SDL_SetWindowMinimumSize(
            ctx.window.ptr,
            @intCast(c_int, size.w),
            @intCast(c_int, size.h),
        );
    }
    if (g.max_size) |size| {
        sdl.c.SDL_SetWindowMaximumSize(
            ctx.window.ptr,
            @intCast(c_int, size.w),
            @intCast(c_int, size.h),
        );
    }
    ctx.toggleResizable(g.enable_resizable);
    ctx.toggleFullscreeen(g.enable_fullscreen);
    ctx.toggleRelativeMouseMode(g.enable_relative_mouse_mode);

    // Create hardware accelerated renderer
    // Fallback to software renderer if allowed
    ctx.renderer = sdl.createRenderer(
        ctx.window,
        null,
        .{
            .accelerated = true,
            .present_vsync = g.enable_vsync,
            .target_texture = true,
        },
    ) catch blk: {
        if (g.enable_software_renderer) {
            log.warn("hardware accelerated renderer isn't supported, fallback to software backend", .{});
            break :blk try sdl.createRenderer(
                ctx.window,
                null,
                .{
                    .software = true,
                    .present_vsync = g.enable_vsync,
                    .target_texture = true,
                },
            );
        }
    };
    defer ctx.renderer.destroy();

    // Allocate audio engine
    ctx.audio = try audio.Engine.init(ctx.default_allocator, .{});
    defer ctx.audio.deinit();

    // Init before loop
    perf_counter_freq = @intToFloat(f64, sdl.c.SDL_GetPerformanceFrequency());
    try g.initFn(&ctx);
    defer g.quitFn(&ctx);
    _ = ctx.updateStats();

    // Game loop
    while (!ctx.quit) {
        if (ctx.updateStats() and g.enable_framestat_display) {
            var buf: [128]u8 = undefined;
            _ = std.fmt.bufPrintZ(
                &buf,
                "{s} | FPS:{d:.1} AVG-CPU:{d:.1}ms VSYNC:{s} MEM:{d} bytes",
                .{
                    g.title,
                    ctx.fps,
                    ctx.average_cpu_time,
                    if (g.enable_vsync) "ON" else "OFF",
                    if (gpa) |a| a.total_requested_bytes else 0,
                },
            ) catch unreachable;
            sdl.c.SDL_SetWindowTitle(ctx.window.ptr, &buf);
        }
        g.loopFn(&ctx) catch |e| {
            log.err("got error in loop: {}", .{e});
            if (@errorReturnTrace()) |trace| {
                std.debug.dumpStackTrace(trace.*);
                break;
            }
        };
        ctx.renderer.present();
    }
}
