const std = @import("std");
const assert = std.debug.assert;
const builtin = @import("builtin");
const sdl = @import("sdl");
const bos = @import("build_options");
const config = @import("config.zig");
const jok = @import("jok.zig");
const font = jok.font;
const imgui = jok.imgui;
const zmesh = jok.zmesh;
const zaudio = jok.zaudio;
const zphysics = jok.zphysics;

const log = std.log.scoped(.jok);

/// Application context
pub const Context = struct {
    ctx: *anyopaque,
    vtable: struct {
        allocator: *const fn (ctx: *anyopaque) std.mem.Allocator,
        running: *const fn (ctx: *anyopaque) bool,
        seconds: *const fn (ctx: *anyopaque) f32,
        realSeconds: *const fn (ctx: *anyopaque) f64,
        deltaSeconds: *const fn (ctx: *anyopaque) f32,
        fps: *const fn (ctx: *anyopaque) f32,
        window: *const fn (ctx: *anyopaque) sdl.Window,
        renderer: *const fn (ctx: *anyopaque) sdl.Renderer,
        kill: *const fn (ctx: *anyopaque) void,
        toggleResizable: *const fn (ctx: *anyopaque, on_off: ?bool) void,
        toggleFullscreeen: *const fn (ctx: *anyopaque, on_off: ?bool) void,
        toggleAlwaysOnTop: *const fn (ctx: *anyopaque, on_off: ?bool) void,
        getWindowPosition: *const fn (ctx: *anyopaque) sdl.PointF,
        getWindowSize: *const fn (ctx: *anyopaque) sdl.PointF,
        getFramebufferSize: *const fn (ctx: *anyopaque) sdl.PointF,
        getAspectRatio: *const fn (ctx: *anyopaque) f32,
        getPixelRatio: *const fn (ctx: *anyopaque) f32,
        isKeyPressed: *const fn (ctx: *anyopaque, key: sdl.Scancode) bool,
        getMouseState: *const fn (ctx: *anyopaque) sdl.MouseState,
        setMousePosition: *const fn (ctx: *anyopaque, xrel: f32, yrel: f32) void,
    },

    /// Get meomry allocator
    pub fn allocator(self: Context) std.mem.Allocator {
        return self.vtable.allocator(self.ctx);
    }

    /// Get application running status
    pub fn running(self: Context) bool {
        return self.vtable.running(self.ctx);
    }

    /// Get running seconds of application
    pub fn seconds(self: Context) f32 {
        return self.vtable.seconds(self.ctx);
    }

    /// Get running seconds of application (double precision)
    pub fn realSeconds(self: Context) f64 {
        return self.vtable.realSeconds(self.ctx);
    }

    /// Get delta time between frames
    pub fn deltaSeconds(self: Context) f32 {
        return self.vtable.deltaSeconds(self.ctx);
    }

    /// Get FPS of application
    pub fn fps(self: Context) f32 {
        return self.vtable.fps(self.ctx);
    }

    /// Get SDL window
    pub fn window(self: Context) sdl.Window {
        return self.vtable.window(self.ctx);
    }

    /// Get SDL renderer
    pub fn renderer(self: Context) sdl.Renderer {
        return self.vtable.renderer(self.ctx);
    }

    /// Kill application
    pub fn kill(self: Context) void {
        return self.vtable.kill(self.ctx);
    }

    /// Toggle resizable
    pub fn toggleResizable(self: Context, on_off: ?bool) void {
        return self.vtable.toggleResizable(self.ctx, on_off);
    }

    /// Toggle fullscreen
    pub fn toggleFullscreeen(self: Context, on_off: ?bool) void {
        return self.vtable.toggleFullscreeen(self.ctx, on_off);
    }

    /// Toggle always-on-top
    pub fn toggleAlwaysOnTop(self: Context, on_off: ?bool) void {
        return self.vtable.toggleAlwaysOnTop(self.ctx, on_off);
    }

    /// Get position of window
    pub fn getWindowPosition(self: Context) sdl.PointF {
        return self.vtable.getWindowPosition(self.ctx);
    }

    /// Get size of window
    pub fn getWindowSize(self: Context) sdl.PointF {
        return self.vtable.getWindowSize(self.ctx);
    }

    /// Get size of framebuffer
    pub fn getFramebufferSize(self: Context) sdl.PointF {
        return self.vtable.getFramebufferSize(self.ctx);
    }

    /// Get aspect ratio of drawing area
    pub fn getAspectRatio(self: Context) f32 {
        return self.vtable.getAspectRatio(self.ctx);
    }

    /// Get pixel ratio
    pub fn getPixelRatio(self: Context) f32 {
        return self.vtable.getPixelRatio(self.ctx);
    }

    /// Get key status
    pub fn isKeyPressed(self: Context, key: sdl.Scancode) bool {
        return self.vtable.isKeyPressed(self.ctx, key);
    }

    /// Get mouse state
    pub fn getMouseState(self: Context) sdl.MouseState {
        return self.vtable.getMouseState(self.ctx);
    }

    /// Move mouse to given position (relative to window)
    pub fn setMousePosition(self: Context, xrel: f32, yrel: f32) void {
        return self.vtable.setMousePosition(self.ctx, xrel, yrel);
    }
};

/// Context generator
pub fn JokContext(comptime cfg: config.Config) type {
    const AllocatorType = std.heap.GeneralPurposeAllocator(.{
        .safety = cfg.jok_mem_leak_checks,
        .verbose_log = cfg.jok_mem_detail_logs,
        .enable_memory_limit = true,
    });

    return struct {
        var gpa: AllocatorType = .{};

        // Application Context
        _ctx: Context = undefined,

        // Memory allocator
        _allocator: std.mem.Allocator = undefined,

        // Is running
        _running: bool = true,

        // Internal window
        _window: sdl.Window = undefined,

        // Renderer
        _renderer: sdl.Renderer = undefined,
        _is_software: bool = false,

        // Resizable mode
        _resizable: bool = undefined,

        // Fullscreen mode
        _fullscreen: bool = undefined,

        // Whether always on top
        _always_on_top: bool = undefined,

        // Elapsed time of game
        _seconds: f32 = 0,
        _seconds_real: f64 = 0,

        // Delta time between update/draw
        _delta_seconds: f32 = 0,

        // Frames stats
        _fps: f32 = 0,
        _average_cpu_time: f32 = 0,
        _last_pc: u64 = 0,
        _accumulated_pc: u64 = 0,
        _pc_freq: f64 = 0,
        _frame_count: u32 = 0,
        _last_fps_refresh_time: f64 = 0,

        pub fn create() !*@This() {
            var _allocator = cfg.jok_allocator orelse gpa.allocator();
            var self = try _allocator.create(@This());
            self.* = .{};
            self._allocator = _allocator;
            self._ctx = self.context();

            // Check and print system info
            try self.checkSys();

            // Init SDL window and renderer
            try self.initSDL();

            // Init zmodules
            imgui.sdl.init(self._ctx);
            zmesh.init(self._allocator);
            if (bos.use_zaudio) {
                zaudio.init(self._allocator);
            }
            if (bos.use_zphysics) {
                zphysics.init(self._allocator, .{});
            }

            // Init 2d and 3d modules
            try jok.j2d.init(self._allocator, self._renderer);
            try jok.j3d.init(self._allocator, self._renderer);

            // Init builtin debug font
            try font.DebugFont.init(self._allocator);
            self._pc_freq = @intToFloat(f64, sdl.c.SDL_GetPerformanceFrequency());
            self._last_pc = sdl.c.SDL_GetPerformanceCounter();
            return self;
        }

        pub fn destroy(self: *@This()) void {
            // Destroy builtin font data
            font.DebugFont.deinit();

            // Destroy 2d and 3d modules
            jok.j3d.deinit();
            jok.j2d.deinit();

            // Destroy zmodules
            if (bos.use_zphysics) {
                zphysics.deinit();
            }
            if (bos.use_zaudio) {
                zaudio.deinit();
            }
            zmesh.deinit();
            imgui.sdl.deinit();

            // Destroy window and renderer
            self.deinitSDL();

            // Destory itself
            self._allocator.destroy(self);

            // Destory memory allocator
            if (gpa.deinit()) {
                @panic("jok: memory leaks happened!");
            }
        }

        /// Ticking of application
        pub fn tick(
            self: *@This(),
            comptime eventFn: *const fn (Context, sdl.Event) anyerror!void,
            comptime updateFn: *const fn (Context) anyerror!void,
            comptime drawFn: *const fn (Context) anyerror!void,
        ) void {
            while (sdl.pollNativeEvent()) |e| {
                _ = imgui.sdl.processEvent(e);
                const we = sdl.Event.from(e);
                if (cfg.jok_exit_on_recv_esc and we == .key_up and
                    we.key_up.scancode == .escape)
                {
                    kill(self);
                } else if (cfg.jok_exit_on_recv_quit and we == .quit) {
                    kill(self);
                } else {
                    eventFn(self._ctx, we) catch |err| {
                        log.err("got error in `event`: {}", .{err});
                        if (@errorReturnTrace()) |trace| {
                            std.debug.dumpStackTrace(trace.*);
                            break;
                        }
                    };
                }
            }

            self.internalLoop(updateFn, drawFn);

            if (self.updateFrameStats() and cfg.jok_framestat_display) {
                var buf: [128]u8 = undefined;
                const txt = std.fmt.bufPrintZ(
                    &buf,
                    "{s} | {d}x{d} | FPS: {d:.1}, {s} | CPU: {d:.1}ms | RENDERER: {s} | OPTIMIZE: {s}",
                    .{
                        cfg.jok_window_title,
                        getWindowSize(self).x,
                        getWindowSize(self).y,
                        self._fps,
                        cfg.jok_fps_limit.str(),
                        self._average_cpu_time,
                        if (self._is_software) "software" else "hardware",
                        @tagName(builtin.mode),
                    },
                ) catch unreachable;
                sdl.c.SDL_SetWindowTitle(self._window.ptr, txt.ptr);
            }
        }

        /// Internal game loop
        inline fn internalLoop(
            self: *@This(),
            comptime updateFn: *const fn (Context) anyerror!void,
            comptime drawFn: *const fn (Context) anyerror!void,
        ) void {
            const fps_pc_threshold: u64 = switch (cfg.jok_fps_limit) {
                .none => 0,
                .auto => if (self._is_software) @divTrunc(@floatToInt(u64, self._pc_freq), 30) else 0,
                .manual => |_fps| @floatToInt(u64, self._pc_freq) / @intCast(u64, _fps),
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
                    self._delta_seconds = fps_delta_seconds;
                    self._seconds += self._delta_seconds;
                    self._seconds_real += self._delta_seconds;

                    updateFn(self._ctx) catch |e| {
                        log.err("got error in `update`: {}", .{e});
                        if (@errorReturnTrace()) |trace| {
                            std.debug.dumpStackTrace(trace.*);
                            kill(self);
                            return;
                        }
                    };
                }
                assert(step_count > 0);

                // Set delta time between `draw`
                self._delta_seconds = @intToFloat(f32, step_count) * fps_delta_seconds;
            } else {
                // Perform one update
                const pc = sdl.c.SDL_GetPerformanceCounter();
                self._delta_seconds = @floatCast(
                    f32,
                    @intToFloat(f64, pc - self._last_pc) / self._pc_freq,
                );
                self._last_pc = pc;
                self._seconds += self._delta_seconds;
                self._seconds_real += self._delta_seconds;

                updateFn(self._ctx) catch |e| {
                    log.err("got error in `update`: {}", .{e});
                    if (@errorReturnTrace()) |trace| {
                        std.debug.dumpStackTrace(trace.*);
                        kill(self);
                        return;
                    }
                };
            }

            // Do rendering
            self._renderer.clear() catch unreachable;
            drawFn(self._ctx) catch |e| {
                log.err("got error in `draw`: {}", .{e});
                if (@errorReturnTrace()) |trace| {
                    std.debug.dumpStackTrace(trace.*);
                    kill(self);
                    return;
                }
            };
            self._renderer.present();
        }

        /// Update frame stats once per second
        inline fn updateFrameStats(self: *@This()) bool {
            self._frame_count += 1;
            if ((self._seconds_real - self._last_fps_refresh_time) >= 1.0) {
                const t = self._seconds_real - self._last_fps_refresh_time;
                self._fps = @floatCast(
                    f32,
                    @intToFloat(f64, self._frame_count) / t,
                );
                self._average_cpu_time = (1.0 / self._fps) * 1000.0;
                self._last_fps_refresh_time = self._seconds_real;
                self._frame_count = 0;
                return true;
            }
            return false;
        }

        /// Check system information
        fn checkSys(_: *const @This()) !void {
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
                    std.meta.tagName(cfg.jok_log_level),
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

            if (cfg.jok_exit_on_recv_esc) {
                log.info("Press ESC to exit game", .{});
            }
        }

        /// Initialize SDL
        fn initSDL(self: *@This()) !void {
            var sdl_flags = sdl.InitFlags.everything;
            try sdl.init(sdl_flags);

            // Create window
            var window_flags = sdl.WindowFlags{
                .allow_high_dpi = true,
                .mouse_capture = true,
                .mouse_focus = true,
            };
            if (cfg.jok_window_borderless) {
                window_flags.borderless = true;
            }
            if (cfg.jok_window_minimized) {
                window_flags.dim = .minimized;
            }
            if (cfg.jok_window_maximized) {
                window_flags.dim = .maximized;
            }
            self._window = try sdl.createWindow(
                cfg.jok_window_title,
                cfg.jok_window_pos_x,
                cfg.jok_window_pos_y,
                cfg.jok_window_width,
                cfg.jok_window_height,
                window_flags,
            );
            if (cfg.jok_window_min_size) |size| {
                sdl.c.SDL_SetWindowMinimumSize(
                    self._window.ptr,
                    size.width,
                    size.height,
                );
            }
            if (cfg.jok_window_max_size) |size| {
                sdl.c.SDL_SetWindowMaximumSize(
                    self._window.ptr,
                    size.width,
                    size.height,
                );
            }
            toggleResizable(self, cfg.jok_window_resizable);
            toggleFullscreeen(self, cfg.jok_window_fullscreen);
            toggleAlwaysOnTop(self, cfg.jok_window_always_on_top);

            // Apply mouse mode
            switch (cfg.jok_mouse_mode) {
                .normal => {
                    if (cfg.jok_window_fullscreen) {
                        sdl.c.SDL_SetWindowGrab(self._window.ptr, sdl.c.SDL_FALSE);
                    }
                    _ = sdl.c.SDL_ShowCursor(sdl.c.SDL_ENABLE);
                    _ = sdl.c.SDL_SetRelativeMouseMode(sdl.c.SDL_FALSE);
                },
                .hide => {
                    if (cfg.jok_window_fullscreen) {
                        sdl.c.SDL_SetWindowGrab(self._window.ptr, sdl.c.SDL_TRUE);
                    }
                    _ = sdl.c.SDL_ShowCursor(sdl.c.SDL_DISABLE);
                    _ = sdl.c.SDL_SetRelativeMouseMode(sdl.c.SDL_TRUE);
                },
            }

            // Create hardware accelerated renderer
            // Fallback to software renderer if allowed
            self._renderer = sdl.createRenderer(
                self._window,
                null,
                .{
                    .accelerated = true,
                    .present_vsync = cfg.jok_fps_limit == .auto,
                    .target_texture = true,
                },
            ) catch blk: {
                if (cfg.jok_software_renderer) {
                    log.warn("hardware accelerated renderer isn't supported, fallback to software backend", .{});
                    break :blk try sdl.createRenderer(
                        self._window,
                        null,
                        .{
                            .software = true,
                            .present_vsync = cfg.jok_fps_limit == .auto, // Doesn't matter actually, vsync won't work anyway
                            .target_texture = true,
                        },
                    );
                }
            };
            const rdinfo = try self._renderer.getInfo();
            self._is_software = ((rdinfo.flags & sdl.c.SDL_RENDERER_SOFTWARE) != 0);
            try self._renderer.setDrawBlendMode(.blend);
        }

        /// Deinitialize SDL
        fn deinitSDL(self: *@This()) void {
            self._renderer.destroy();
            self._window.destroy();
            sdl.quit();
        }

        /// Get type-erased context for application
        pub fn context(self: *@This()) Context {
            return .{
                .ctx = self,
                .vtable = .{
                    .allocator = allocator,
                    .running = running,
                    .seconds = seconds,
                    .realSeconds = realSeconds,
                    .deltaSeconds = deltaSeconds,
                    .fps = fps,
                    .window = window,
                    .renderer = renderer,
                    .kill = kill,
                    .toggleResizable = toggleResizable,
                    .toggleFullscreeen = toggleFullscreeen,
                    .toggleAlwaysOnTop = toggleAlwaysOnTop,
                    .getWindowPosition = getWindowPosition,
                    .getWindowSize = getWindowSize,
                    .getFramebufferSize = getFramebufferSize,
                    .getAspectRatio = getAspectRatio,
                    .getPixelRatio = getPixelRatio,
                    .isKeyPressed = isKeyPressed,
                    .getMouseState = getMouseState,
                    .setMousePosition = setMousePosition,
                },
            };
        }

        /////////////////////////////////////////////////////////////////////////////
        ///
        ///  Wrapped API for application context
        ///
        /////////////////////////////////////////////////////////////////////////////

        /// Get meomry allocator
        fn allocator(ptr: *anyopaque) std.mem.Allocator {
            var self = @ptrCast(*@This(), @alignCast(@alignOf(*@This()), ptr));
            return self._allocator;
        }

        /// Get application running status
        fn running(ptr: *anyopaque) bool {
            var self = @ptrCast(*@This(), @alignCast(@alignOf(*@This()), ptr));
            return self._running;
        }

        /// Get running seconds of application
        fn seconds(ptr: *anyopaque) f32 {
            var self = @ptrCast(*@This(), @alignCast(@alignOf(*@This()), ptr));
            return self._seconds;
        }

        /// Get running seconds of application (double precision)
        fn realSeconds(ptr: *anyopaque) f64 {
            var self = @ptrCast(*@This(), @alignCast(@alignOf(*@This()), ptr));
            return self._seconds_real;
        }

        /// Get delta time between frames
        fn deltaSeconds(ptr: *anyopaque) f32 {
            var self = @ptrCast(*@This(), @alignCast(@alignOf(*@This()), ptr));
            return self._delta_seconds;
        }

        /// Get FPS of application
        fn fps(ptr: *anyopaque) f32 {
            var self = @ptrCast(*@This(), @alignCast(@alignOf(*@This()), ptr));
            return self._fps;
        }

        /// Get SDL window
        fn window(ptr: *anyopaque) sdl.Window {
            var self = @ptrCast(*@This(), @alignCast(@alignOf(*@This()), ptr));
            return self._window;
        }

        /// Get SDL renderer
        fn renderer(ptr: *anyopaque) sdl.Renderer {
            var self = @ptrCast(*@This(), @alignCast(@alignOf(*@This()), ptr));
            return self._renderer;
        }

        /// Kill app
        fn kill(ptr: *anyopaque) void {
            var self = @ptrCast(*@This(), @alignCast(@alignOf(*@This()), ptr));
            self._running = false;
        }

        /// Toggle resizable
        fn toggleResizable(ptr: *anyopaque, on_off: ?bool) void {
            var self = @ptrCast(*@This(), @alignCast(@alignOf(*@This()), ptr));
            if (on_off) |state| {
                self._resizable = state;
            } else {
                self._resizable = !self._resizable;
            }
            _ = sdl.c.SDL_SetWindowResizable(
                self._window.ptr,
                if (self._resizable) sdl.c.SDL_TRUE else sdl.c.SDL_FALSE,
            );
        }

        /// Toggle fullscreen
        fn toggleFullscreeen(ptr: *anyopaque, on_off: ?bool) void {
            var self = @ptrCast(*@This(), @alignCast(@alignOf(*@This()), ptr));
            if (on_off) |state| {
                self._fullscreen = state;
            } else {
                self._fullscreen = !self._fullscreen;
            }
            _ = sdl.c.SDL_SetWindowFullscreen(
                self._window.ptr,
                if (self._fullscreen) sdl.c.SDL_WINDOW_FULLSCREEN_DESKTOP else 0,
            );
        }

        /// Toggle always-on-top
        fn toggleAlwaysOnTop(ptr: *anyopaque, on_off: ?bool) void {
            var self = @ptrCast(*@This(), @alignCast(@alignOf(*@This()), ptr));
            if (on_off) |state| {
                self._always_on_top = state;
            } else {
                self._always_on_top = !self._always_on_top;
            }
            _ = sdl.c.SDL_SetWindowAlwaysOnTop(
                self._window.ptr,
                if (self._always_on_top) sdl.c.SDL_TRUE else sdl.c.SDL_FALSE,
            );
        }

        /// Get position of window
        fn getWindowPosition(ptr: *anyopaque) sdl.PointF {
            var self = @ptrCast(*@This(), @alignCast(@alignOf(*@This()), ptr));
            var x: c_int = undefined;
            var y: c_int = undefined;
            sdl.c.SDL_GetWindowPosition(self._window.ptr, &x, &y);
            return .{ .x = @intToFloat(f32, x), .y = @intToFloat(f32, y) };
        }

        /// Get size of window
        fn getWindowSize(ptr: *anyopaque) sdl.PointF {
            var self = @ptrCast(*@This(), @alignCast(@alignOf(*@This()), ptr));
            var w: c_int = undefined;
            var h: c_int = undefined;
            sdl.c.SDL_GetWindowSize(self._window.ptr, &w, &h);
            return .{ .x = @intToFloat(f32, w), .y = @intToFloat(f32, h) };
        }

        /// Get size of framebuffer
        fn getFramebufferSize(ptr: *anyopaque) sdl.PointF {
            var self = @ptrCast(*@This(), @alignCast(@alignOf(*@This()), ptr));
            const fsize = self._renderer.getOutputSize() catch unreachable;
            return .{
                .x = @intToFloat(f32, fsize.width_pixels),
                .y = @intToFloat(f32, fsize.height_pixels),
            };
        }

        /// Get aspect ratio of drawing area
        fn getAspectRatio(ptr: *anyopaque) f32 {
            var self = @ptrCast(*@This(), @alignCast(@alignOf(*@This()), ptr));
            const fsize = self._renderer.getOutputSize() catch unreachable;
            return @intToFloat(f32, fsize.width_pixels) / @intToFloat(f32, fsize.width_pixels);
        }

        /// Get pixel ratio
        fn getPixelRatio(ptr: *anyopaque) f32 {
            const fsize = getFramebufferSize(ptr);
            const wsize = getWindowSize(ptr);
            return fsize.x / wsize.x;
        }

        /// Get key status
        fn isKeyPressed(_: *anyopaque, key: sdl.Scancode) bool {
            const kb_state = sdl.getKeyboardState();
            return kb_state.isPressed(key);
        }

        /// Get mouse state
        fn getMouseState(_: *anyopaque) sdl.MouseState {
            return sdl.getMouseState();
        }

        /// Move mouse to given position (relative to window)
        fn setMousePosition(ptr: *anyopaque, xrel: f32, yrel: f32) void {
            var self = @ptrCast(*@This(), @alignCast(@alignOf(*@This()), ptr));
            var w: i32 = undefined;
            var h: i32 = undefined;
            sdl.c.SDL_GetWindowSize(self._window.ptr, &w, &h);
            sdl.c.SDL_WarpMouseInWindow(
                self._window.ptr,
                @floatToInt(i32, @intToFloat(f32, w) * xrel),
                @floatToInt(i32, @intToFloat(f32, h) * yrel),
            );
        }
    };
}
