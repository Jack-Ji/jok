const std = @import("std");
const assert = std.debug.assert;
const builtin = @import("builtin");
const sdl = @import("sdl");
const bos = @import("build_options");
const config = @import("config.zig");
const jok = @import("jok.zig");
const zmesh = jok.zmesh;
const imgui = jok.imgui;
const zaudio = jok.zaudio;

const log = std.log.scoped(.jok);

/// Application context
pub const Context = struct {
    // Default allocator
    allocator: std.mem.Allocator,

    // Internal window
    window: sdl.Window = undefined,

    // Renderer
    renderer: sdl.Renderer = undefined,
    is_software: bool = false,

    // Quit switch
    quit: bool = false,

    // Resizable mode
    resizable: bool = undefined,

    // Fullscreen mode
    fullscreen: bool = undefined,

    // Whether always on top
    always_on_top: bool = undefined,

    // Elapsed time of game
    seconds: f32 = 0,

    // Delta time between update/draw
    delta_seconds: f32 = 0,

    // Frames stats
    fps: f32 = 0,
    average_cpu_time: f32 = 0,

    _last_pc: u64 = 0,
    _accumulated_pc: u64 = 0,
    _pc_freq: f64 = 0,

    _frame_count: u32 = 0,
    _last_fps_refresh_time: f32 = 0,

    pub fn init(allocator: std.mem.Allocator) !Context {
        try checkSys();
        var self = Context{
            .allocator = allocator,
        };
        try self.initSDL();
        imgui.sdl.init(self);
        zmesh.init(self.allocator);
        try jok.j2d.init(self.allocator, self.renderer);
        try jok.j3d.init(self.allocator, self.renderer);
        if (bos.use_zaudio) {
            zaudio.init(self.allocator);
        }
        self._pc_freq = @intToFloat(f64, sdl.c.SDL_GetPerformanceFrequency());
        self._last_pc = sdl.c.SDL_GetPerformanceCounter();
        return self;
    }

    pub fn deinit(self: *Context) void {
        if (bos.use_zaudio) {
            zaudio.deinit();
        }
        jok.j3d.deinit();
        jok.j2d.deinit();
        zmesh.deinit();
        imgui.sdl.deinit();
        self.deinitSDL();
        self.* = undefined;
    }

    /// Ticking of application
    pub fn tick(
        self: *Context,
        comptime eventFn: *const fn (*Context, sdl.Event) anyerror!void,
        comptime updateFn: *const fn (*Context) anyerror!void,
        comptime drawFn: *const fn (*Context) anyerror!void,
    ) void {
        while (sdl.pollNativeEvent()) |e| {
            _ = imgui.sdl.processEvent(e);
            const we = sdl.Event.from(e);
            if (config.jok_exit_on_recv_esc and we == .key_up and
                we.key_up.scancode == .escape)
            {
                self.kill();
            } else if (config.jok_exit_on_recv_quit and we == .quit) {
                self.kill();
            } else {
                eventFn(self, we) catch |err| {
                    log.err("got error in `event`: {}", .{err});
                    if (@errorReturnTrace()) |trace| {
                        std.debug.dumpStackTrace(trace.*);
                        break;
                    }
                };
            }
        }

        self.internalLoop(updateFn, drawFn);
        self.updateFrameStats();
    }

    /// Internal game loop
    inline fn internalLoop(
        self: *Context,
        comptime updateFn: *const fn (*Context) anyerror!void,
        comptime drawFn: *const fn (*Context) anyerror!void,
    ) void {
        const fps_pc_threshold: u64 = switch (config.jok_fps_limit) {
            .none => 0,
            .auto => if (self.is_software) @divTrunc(@floatToInt(u64, self._pc_freq), 30) else 0,
            .manual => |fps| @floatToInt(u64, self._pc_freq) / @intCast(u64, fps),
        };
        const max_accumulated = @floatToInt(u64, self._pc_freq * 0.5);

        // Update game
        if (fps_pc_threshold > 0) {
            while (true) {
                const pc = sdl.c.SDL_GetPerformanceCounter();
                self._accumulated_pc += pc - self._last_pc;
                self._last_pc = pc;
                if (self._accumulated_pc < fps_pc_threshold) {
                    const sleep_ms = @floatToInt(
                        u32,
                        @intToFloat(f64, (fps_pc_threshold - self._accumulated_pc) * 1000) / self._pc_freq,
                    );
                    sdl.delay(sleep_ms);
                } else {
                    break;
                }
            }

            if (self._accumulated_pc > max_accumulated)
                self._accumulated_pc = max_accumulated;

            // Perform as many update as we can, with fixed step
            var step_count: u32 = 0;
            const fps_delta_seconds = @floatCast(
                f32,
                @intToFloat(f64, fps_pc_threshold) / self._pc_freq,
            );
            while (self._accumulated_pc >= fps_pc_threshold) {
                step_count += 1;
                self._accumulated_pc -= fps_pc_threshold;
                self.delta_seconds = fps_delta_seconds;
                self.seconds += self.delta_seconds;

                updateFn(self) catch |e| {
                    log.err("got error in `update`: {}", .{e});
                    if (@errorReturnTrace()) |trace| {
                        std.debug.dumpStackTrace(trace.*);
                        self.kill();
                        return;
                    }
                };
            }
            assert(step_count > 0);

            // Set delta time between `draw`
            self.delta_seconds = @intToFloat(f32, step_count) * fps_delta_seconds;
        } else {
            // Perform one update
            const pc = sdl.c.SDL_GetPerformanceCounter();
            self.delta_seconds = @floatCast(
                f32,
                @intToFloat(f64, pc - self._last_pc) / self._pc_freq,
            );
            self._last_pc = pc;
            self.seconds += self.delta_seconds;

            updateFn(self) catch |e| {
                log.err("got error in `update`: {}", .{e});
                if (@errorReturnTrace()) |trace| {
                    std.debug.dumpStackTrace(trace.*);
                    self.kill();
                    return;
                }
            };
        }

        // Do rendering
        self.renderer.clear() catch unreachable;
        drawFn(self) catch |e| {
            log.err("got error in `draw`: {}", .{e});
            if (@errorReturnTrace()) |trace| {
                std.debug.dumpStackTrace(trace.*);
                self.kill();
                return;
            }
        };
        self.renderer.present();
    }

    /// Update frame stats once per second
    inline fn updateFrameStats(self: *Context) void {
        self._frame_count += 1;
        if ((self.seconds - self._last_fps_refresh_time) >= 1.0) {
            const t = self.seconds - self._last_fps_refresh_time;
            self.fps = @floatCast(
                f32,
                @intToFloat(f64, self._frame_count) / t,
            );
            self.average_cpu_time = (1.0 / self.fps) * 1000.0;
            self._last_fps_refresh_time = self.seconds;
            self._frame_count = 0;
        }
    }

    /// Get renderer's name
    pub inline fn getRendererName(self: *Context) []const u8 {
        return if (self.is_software) "software" else "hardware";
    }

    /// Kill app
    pub fn kill(self: *Context) void {
        self.quit = true;
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

    /// Toggle always-on-top
    pub fn toggleAlwaysOnTop(self: *Context, on_off: ?bool) void {
        if (on_off) |state| {
            self.always_on_top = state;
        } else {
            self.always_on_top = !self.always_on_top;
        }
        _ = sdl.c.SDL_SetWindowAlwaysOnTop(
            self.window.ptr,
            if (self.always_on_top) sdl.c.SDL_TRUE else sdl.c.SDL_FALSE,
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

    /// Get aspect ratio of drawing area
    pub fn getAspectRatio(self: Context) f32 {
        const fsize = self.renderer.getOutputSize() catch unreachable;
        return @intToFloat(f32, fsize.width_pixels) / @intToFloat(f32, fsize.width_pixels);
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
        const kb_state = sdl.getKeyboardState();
        return kb_state.isPressed(key);
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

    /// Check system information
    fn checkSys() !void {
        const target = builtin.target;
        var sdl_version: sdl.c.SDL_version = undefined;
        sdl.c.SDL_GetVersion(&sdl_version);
        const ram_size = sdl.c.SDL_GetSystemRAM();

        // Print system info
        log.info(
            \\System info:
            \\    Build Mode    : {s}
            \\    Logging Level : {s}
            \\    Zig Version   : {}
            \\    CPU           : {s}
            \\    ABI           : {s}
            \\    SDL           : {}.{}.{}
            \\    Platform      : {s}
            \\    Memory        : {d}MB
        ,
            .{
                std.meta.tagName(builtin.mode),
                std.meta.tagName(config.jok_log_level),
                builtin.zig_version,
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
            log.err("Need SDL least version >= 2.0.18", .{});
            return sdl.makeError();
        }

        if (config.jok_exit_on_recv_esc) {
            log.info("Press ESC to exit game", .{});
        }
    }

    /// Initialize SDL
    fn initSDL(self: *Context) !void {
        // Initialize SDL sub-systems
        var sdl_flags = sdl.InitFlags.everything;
        try sdl.init(sdl_flags);

        // Create window
        var window_flags = sdl.WindowFlags{
            .allow_high_dpi = true,
            .mouse_capture = true,
            .mouse_focus = true,
        };
        if (config.jok_window_borderless) {
            window_flags.borderless = true;
        }
        if (config.jok_window_minimized) {
            window_flags.dim = .minimized;
        }
        if (config.jok_window_maximized) {
            window_flags.dim = .maximized;
        }
        self.window = try sdl.createWindow(
            config.jok_window_title,
            config.jok_window_pos_x,
            config.jok_window_pos_y,
            config.jok_window_width,
            config.jok_window_height,
            window_flags,
        );
        if (config.jok_window_min_size) |size| {
            sdl.c.SDL_SetWindowMinimumSize(
                self.window.ptr,
                size.width,
                size.height,
            );
        }
        if (config.jok_window_max_size) |size| {
            sdl.c.SDL_SetWindowMaximumSize(
                self.window.ptr,
                size.width,
                size.height,
            );
        }
        self.toggleResizable(config.jok_window_resizable);
        self.toggleFullscreeen(config.jok_window_fullscreen);
        self.toggleAlwaysOnTop(config.jok_window_always_on_top);

        // Apply mouse mode
        switch (config.jok_mouse_mode) {
            .normal => {
                if (config.jok_window_fullscreen) {
                    sdl.c.SDL_SetWindowGrab(self.window.ptr, sdl.c.SDL_FALSE);
                }
                _ = sdl.c.SDL_ShowCursor(sdl.c.SDL_ENABLE);
                _ = sdl.c.SDL_SetRelativeMouseMode(sdl.c.SDL_FALSE);
            },
            .hide => {
                if (config.jok_window_fullscreen) {
                    sdl.c.SDL_SetWindowGrab(self.window.ptr, sdl.c.SDL_TRUE);
                }
                _ = sdl.c.SDL_ShowCursor(sdl.c.SDL_DISABLE);
                _ = sdl.c.SDL_SetRelativeMouseMode(sdl.c.SDL_TRUE);
            },
        }

        // Create hardware accelerated renderer
        // Fallback to software renderer if allowed
        self.renderer = sdl.createRenderer(
            self.window,
            null,
            .{
                .accelerated = true,
                .present_vsync = config.jok_fps_limit == .auto,
                .target_texture = true,
            },
        ) catch blk: {
            if (config.jok_software_renderer) {
                log.warn("hardware accelerated renderer isn't supported, fallback to software backend", .{});
                break :blk try sdl.createRenderer(
                    self.window,
                    null,
                    .{
                        .software = true,
                        .present_vsync = config.jok_fps_limit == .auto, // Doesn't matter actually, vsync won't work anyway
                        .target_texture = true,
                    },
                );
            }
        };
        const rdinfo = try self.renderer.getInfo();
        self.is_software = ((rdinfo.flags & sdl.c.SDL_RENDERER_SOFTWARE) != 0);
        try self.renderer.setDrawBlendMode(.blend);
    }

    /// Deinitialize SDL
    fn deinitSDL(self: *Context) void {
        self.renderer.destroy();
        self.window.destroy();
        sdl.quit();
    }
};
