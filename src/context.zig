const std = @import("std");
const assert = std.debug.assert;
const builtin = @import("builtin");
const bos = @import("build_options");
const config = @import("config.zig");
const jok = @import("jok.zig");
const sdl = jok.sdl;
const font = jok.font;
const imgui = jok.imgui;
const plot = imgui.plot;
const zaudio = jok.zaudio;
const zmesh = jok.zmesh;
const w32 = @import("w32.zig");

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
        audioEngine: *const fn (ctx: *anyopaque) *zaudio.Engine,
        kill: *const fn (ctx: *anyopaque) void,
        toggleResizable: *const fn (ctx: *anyopaque, on_off: ?bool) void,
        toggleFullscreeen: *const fn (ctx: *anyopaque, on_off: ?bool) void,
        toggleAlwaysOnTop: *const fn (ctx: *anyopaque, on_off: ?bool) void,
        getWindowPosition: *const fn (ctx: *anyopaque) sdl.PointF,
        getWindowSize: *const fn (ctx: *anyopaque) sdl.PointF,
        setWindowSize: *const fn (ctx: *anyopaque, size: sdl.PointF) void,
        getCanvasSize: *const fn (ctx: *anyopaque) sdl.PointF,
        getAspectRatio: *const fn (ctx: *anyopaque) f32,
        getDpiScale: *const fn (ctx: *anyopaque) f32,
        isKeyPressed: *const fn (ctx: *anyopaque, key: sdl.Scancode) bool,
        getMouseState: *const fn (ctx: *anyopaque) sdl.MouseState,
        isRunningSlow: *const fn (ctx: *anyopaque) bool,
        displayStats: *const fn (ctx: *anyopaque, opt: DisplayStats) void,
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

    /// Get audio engine
    pub fn audioEngine(self: Context) *zaudio.Engine {
        return self.vtable.audioEngine(self.ctx);
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

    /// Set size of window
    pub fn setWindowSize(self: Context, size: sdl.PointF) void {
        return self.vtable.setWindowSize(self.ctx, size);
    }

    /// Get size of canvas
    pub fn getCanvasSize(self: Context) sdl.PointF {
        return self.vtable.getCanvasSize(self.ctx);
    }

    /// Get aspect ratio of drawing area
    pub fn getAspectRatio(self: Context) f32 {
        return self.vtable.getAspectRatio(self.ctx);
    }

    /// Get dpi scale
    pub fn getDpiScale(self: Context) f32 {
        return self.vtable.getDpiScale(self.ctx);
    }

    /// Get key status
    pub fn isKeyPressed(self: Context, key: sdl.Scancode) bool {
        return self.vtable.isKeyPressed(self.ctx, key);
    }

    /// Get mouse state
    pub fn getMouseState(self: Context) sdl.MouseState {
        return self.vtable.getMouseState(self.ctx);
    }

    /// Whether game is running slow
    pub fn isRunningSlow(self: Context) bool {
        return self.vtable.isRunningSlow(self.ctx);
    }

    /// Display statistics
    pub fn displayStats(self: Context, opt: DisplayStats) void {
        return self.vtable.displayStats(self.ctx, opt);
    }

    /// Clear canvas
    pub fn clear(ctx: Context, color: ?sdl.Color) void {
        const rd = ctx.renderer();
        const old_color = rd.getColor() catch unreachable;
        defer rd.setColor(old_color) catch unreachable;
        rd.setColor(color orelse sdl.Color.black) catch unreachable;
        rd.clear() catch unreachable;
    }
};

pub const DisplayStats = struct {
    movable: bool = false,
    collapsible: bool = false,
    width: f32 = 250,
    duration: u32 = 15,
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
        const max_costs_num = 300;
        const CostDataType = jok.utils.ring.Ring(f32);

        // Application Context
        _ctx: Context = undefined,

        // Memory allocator
        _allocator: std.mem.Allocator = undefined,

        // Is running
        _running: bool = true,

        // Internal window
        _window: sdl.Window = undefined,

        // High DPI stuff
        _default_dpi: f32 = undefined,
        _display_dpi: f32 = undefined,

        // Renderer instance
        _renderer: sdl.Renderer = undefined,
        _is_software: bool = false,

        // Rendering target
        _canvas_texture: sdl.Texture = undefined,
        _canvas_area: ?sdl.Rectangle = null,
        _canvas_scale: f32 = 1.0,

        // Audio stuff
        _audio_engine: *zaudio.Engine = undefined,

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

        // Whether game is running slow
        _running_slow: bool = false,
        _frame_lag: u64 = 0,

        // Frames stats
        _fps: f32 = 0,
        _pc_last: u64 = 0,
        _pc_accumulated: u64 = 0,
        _pc_freq: u64 = 0,
        _pc_max_accumulated: u64 = 0,
        _drawcall_count: u32 = 0,
        _triangle_count: u32 = 0,
        _frame_count: u32 = 0,
        _last_fps_refresh_time: f64 = 0,
        _last_costs_refresh_time: f64 = 0,
        _update_cost: f32 = 0,
        _draw_cost: f32 = 0,
        _recent_update_costs: CostDataType = undefined,
        _recent_draw_costs: CostDataType = undefined,
        _recent_total_costs: CostDataType = undefined,

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

            // Init imgui
            imgui.sdl.init(self._ctx, cfg.jok_imgui_ini_file);

            // Init zmesh
            zmesh.init(self._allocator);

            // Init 2d and 3d modules
            try jok.j2d.init(self.context());
            try jok.j3d.init(self.context());

            // Init audio engine
            zaudio.init(self._allocator);
            self._audio_engine = try zaudio.Engine.create(null);

            // Init builtin debug font
            try font.DebugFont.init(self._allocator);
            _ = try font.DebugFont.getAtlas(
                self._ctx,
                @intFromFloat(@as(f32, @floatFromInt(cfg.jok_prebuild_atlas)) * getDpiScale(self)),
            );

            // Misc.
            self._pc_freq = sdl.c.SDL_GetPerformanceFrequency();
            self._pc_max_accumulated = self._pc_freq / 2;
            self._pc_last = sdl.c.SDL_GetPerformanceCounter();
            self._recent_update_costs = try CostDataType.init(self._allocator, max_costs_num);
            self._recent_draw_costs = try CostDataType.init(self._allocator, max_costs_num);
            self._recent_total_costs = try CostDataType.init(self._allocator, max_costs_num);
            return self;
        }

        pub fn destroy(self: *@This()) void {
            // Destroy cost data
            self._recent_update_costs.deinit(self._allocator);
            self._recent_draw_costs.deinit(self._allocator);
            self._recent_total_costs.deinit(self._allocator);

            // Destroy builtin font data
            font.DebugFont.deinit();

            // Destroy audio engine
            self._audio_engine.destroy();
            zaudio.deinit();

            // Destroy 2d and 3d modules
            jok.j3d.deinit();
            jok.j2d.deinit();

            // Destroy zmesh
            zmesh.deinit();

            // Destroy imgui
            imgui.sdl.deinit();

            // Destroy window and renderer
            self.deinitSDL();

            // Destory self
            self._allocator.destroy(self);

            // Destory memory allocator
            if (gpa.deinit() == .leak) {
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
            const pc_threshold: u64 = switch (cfg.jok_fps_limit) {
                .none => 0,
                .auto => if (self._is_software) @divTrunc(self._pc_freq, 30) else 0,
                .manual => |_fps| self._pc_freq / @as(u64, _fps),
            };

            // Update game
            if (pc_threshold > 0) {
                while (true) {
                    const pc = sdl.c.SDL_GetPerformanceCounter();
                    self._pc_accumulated += pc - self._pc_last;
                    self._pc_last = pc;
                    if (self._pc_accumulated >= pc_threshold) {
                        break;
                    }
                    if ((pc_threshold - self._pc_accumulated) * 1000 > self._pc_freq) {
                        sdl.delay(1);
                    }
                }

                if (self._pc_accumulated > self._pc_max_accumulated)
                    self._pc_accumulated = self._pc_max_accumulated;

                // Perform as many update as we can, with fixed step
                var step_count: u32 = 0;
                const fps_delta_seconds: f32 = @floatCast(
                    @as(f64, @floatFromInt(pc_threshold)) / @as(f64, @floatFromInt(self._pc_freq)),
                );
                while (self._pc_accumulated >= pc_threshold) {
                    step_count += 1;
                    self._pc_accumulated -= pc_threshold;
                    self._delta_seconds = fps_delta_seconds;
                    self._seconds += self._delta_seconds;
                    self._seconds_real += self._delta_seconds;

                    self._update(eventFn, updateFn);
                }
                assert(step_count > 0);

                // Update frame lag
                self._frame_lag += @max(0, step_count - 1);
                if (self._running_slow) {
                    if (self._frame_lag == 0) self._running_slow = false;
                } else if (self._frame_lag >= 5) {
                    // Consider game running slow when lagging more than 5 frames
                    self._running_slow = true;
                }
                if (self._frame_lag > 0 and step_count == 1) self._frame_lag -= 1;

                // Set delta time between `draw`
                self._delta_seconds = @as(f32, @floatFromInt(step_count)) * fps_delta_seconds;
            } else {
                // Perform one update
                const pc = sdl.c.SDL_GetPerformanceCounter();
                self._delta_seconds = @floatCast(
                    @as(f64, @floatFromInt(pc - self._pc_last)) / @as(f64, @floatFromInt(self._pc_freq)),
                );
                self._pc_last = pc;
                self._seconds += self._delta_seconds;
                self._seconds_real += self._delta_seconds;

                self._update(eventFn, updateFn);
            }

            // Do rendering
            const old_color = self._renderer.getColor() catch unreachable;
            self._renderer.setColor(sdl.Color.black) catch unreachable;
            self._renderer.clear() catch unreachable;
            self._renderer.setColor(old_color) catch unreachable;
            {
                const pc_begin = sdl.c.SDL_GetPerformanceCounter();
                defer if (cfg.jok_detailed_frame_stats) {
                    const cost = @as(f32, @floatFromInt((sdl.c.SDL_GetPerformanceCounter() - pc_begin) * 1000)) /
                        @as(f32, @floatFromInt(self._pc_freq));
                    self._draw_cost = if (self._draw_cost > 0) (self._draw_cost + cost) / 2 else cost;
                };

                imgui.sdl.newFrame(self.context());
                defer imgui.sdl.draw();

                self._renderer.setTarget(self._canvas_texture) catch unreachable;
                defer {
                    self._renderer.setTarget(null) catch unreachable;
                    self._renderer.copy(self._canvas_texture, self._canvas_area, null) catch unreachable;
                }

                drawFn(self._ctx) catch |e| {
                    log.err("Got error in `draw`: {}", .{e});
                    if (@errorReturnTrace()) |trace| {
                        std.debug.dumpStackTrace(trace.*);
                        kill(self);
                        return;
                    }
                };
            }
            self._renderer.present();
            self._updateFrameStats();
        }

        /// Update game state
        inline fn _update(
            self: *@This(),
            comptime eventFn: *const fn (Context, sdl.Event) anyerror!void,
            comptime updateFn: *const fn (Context) anyerror!void,
        ) void {
            const pc_begin = sdl.c.SDL_GetPerformanceCounter();
            defer if (cfg.jok_detailed_frame_stats) {
                const cost = @as(f32, @floatFromInt((sdl.c.SDL_GetPerformanceCounter() - pc_begin) * 1000)) /
                    @as(f32, @floatFromInt(self._pc_freq));
                self._update_cost = if (self._update_cost > 0) (self._update_cost + cost) / 2 else cost;
            };

            while (sdl.pollNativeEvent()) |ne| {
                // ImGui event processing
                var e = ne;
                if (cfg.jok_high_dpi_support) {
                    switch (e.type) {
                        sdl.c.SDL_MOUSEMOTION => {
                            e.motion.x = @intFromFloat(@as(f32, @floatFromInt(e.motion.x)) / getDpiScale(self));
                            e.motion.y = @intFromFloat(@as(f32, @floatFromInt(e.motion.y)) / getDpiScale(self));
                        },
                        sdl.c.SDL_MOUSEBUTTONDOWN, sdl.c.SDL_MOUSEBUTTONUP => {
                            e.button.x = @intFromFloat(@as(f32, @floatFromInt(e.button.x)) / getDpiScale(self));
                            e.button.y = @intFromFloat(@as(f32, @floatFromInt(e.button.y)) / getDpiScale(self));
                        },
                        else => {},
                    }
                }
                _ = imgui.sdl.processEvent(e);

                // Game event processing
                var we = sdl.Event.from(ne);
                if (cfg.jok_exit_on_recv_esc and we == .key_up and
                    we.key_up.scancode == .escape)
                {
                    kill(self);
                } else if (cfg.jok_exit_on_recv_quit and we == .quit) {
                    kill(self);
                } else {
                    if (we == .window and (we.window.type == .resized or we.window.type == .size_changed)) {
                        if (cfg.jok_canvas_size == null) {
                            self._canvas_texture.destroy();
                            self._canvas_texture = jok.utils.gfx.createTextureAsTarget(self.context(), .{}) catch unreachable;
                        }
                        self.updateCanvasArea();
                    } else if (cfg.jok_canvas_size != null) {
                        // Remapping mouse position to canvas
                        switch (we) {
                            .mouse_button_down => |*me| {
                                const pos = self.mapPositionFromFramebufferToCanvas(.{
                                    .x = @intCast(me.x),
                                    .y = @intCast(me.y),
                                });
                                me.x = @intCast(pos.x);
                                me.y = @intCast(pos.y);
                            },
                            .mouse_button_up => |*me| {
                                const pos = self.mapPositionFromFramebufferToCanvas(.{
                                    .x = @intCast(me.x),
                                    .y = @intCast(me.y),
                                });
                                me.x = @intCast(pos.x);
                                me.y = @intCast(pos.y);
                            },
                            .mouse_motion => |*me| {
                                const pos = self.mapPositionFromFramebufferToCanvas(.{
                                    .x = @intCast(me.x),
                                    .y = @intCast(me.y),
                                });
                                me.x = @intCast(pos.x);
                                me.y = @intCast(pos.y);
                            },
                            else => {},
                        }
                    }
                    eventFn(self._ctx, we) catch |err| {
                        log.err("Got error in `event`: {}", .{err});
                        if (@errorReturnTrace()) |trace| {
                            std.debug.dumpStackTrace(trace.*);
                            break;
                        }
                    };
                }
            }

            updateFn(self._ctx) catch |e| {
                log.err("Got error in `update`: {}", .{e});
                if (@errorReturnTrace()) |trace| {
                    std.debug.dumpStackTrace(trace.*);
                    kill(self);
                    return;
                }
            };
        }

        /// Update frame stats once per second
        inline fn _updateFrameStats(self: *@This()) void {
            self._frame_count += 1;
            if ((self._seconds_real - self._last_fps_refresh_time) >= 1) {
                const duration = self._seconds_real - self._last_fps_refresh_time;
                self._fps = @as(f32, @floatCast(
                    @as(f64, @floatFromInt(self._frame_count)) / duration,
                ));
                self._last_fps_refresh_time = self._seconds_real;
                const dc_stats = imgui.sdl.getDrawCallStats();
                self._drawcall_count = dc_stats[0] / self._frame_count;
                self._triangle_count = dc_stats[1] / self._frame_count;
                imgui.sdl.clearDrawCallStats();
                self._frame_count = 0;
            }
            if (cfg.jok_detailed_frame_stats and (self._seconds_real - self._last_costs_refresh_time) >= 0.1) {
                self._last_costs_refresh_time = self._seconds_real;
                self._recent_update_costs.writeAssumeCapacity(self._update_cost);
                self._recent_draw_costs.writeAssumeCapacity(self._draw_cost);
                self._recent_total_costs.writeAssumeCapacity(self._update_cost + self._draw_cost);
                self._update_cost = 0;
                self._draw_cost = 0;
            }
        }

        /// Check system information
        fn checkSys(_: *@This()) !void {
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
                    @tagName(builtin.mode),
                    @tagName(cfg.jok_log_level),
                    builtin.zig_version,
                    @tagName(target.cpu.arch),
                    @tagName(target.abi),
                    sdl_version.major,
                    sdl_version.minor,
                    sdl_version.patch,
                    @tagName(target.os.tag),
                    ram_size,
                },
            );

            if (sdl_version.major < 2 or (sdl_version.minor == 0 and sdl_version.patch < 18)) {
                log.err("SDL version too low, need at least 2.0.18", .{});
                return sdl.makeError();
            }

            if (cfg.jok_exit_on_recv_esc) {
                log.info("Press ESC to exit game", .{});
            }
        }

        /// Initialize SDL
        fn initSDL(self: *@This()) !void {
            const sdl_flags = sdl.InitFlags.everything;
            try sdl.init(sdl_flags);

            // Create window
            var window_flags = sdl.WindowFlags{
                .mouse_capture = true,
                .mouse_focus = true,
            };
            self._default_dpi = switch (builtin.target.os.tag) {
                .macos => 72.0,
                else => 96.0,
            };
            if (cfg.jok_high_dpi_support) {
                if (builtin.target.os.tag == .windows) {
                    // Enable High-DPI awareness
                    // BUG: only workable on single monitor system
                    _ = w32.SetProcessDPIAware();
                }
                if (sdl.c.SDL_GetDisplayDPI(0, null, &self._display_dpi, null) < 0) {
                    self._display_dpi = self._default_dpi;
                }
                window_flags.allow_high_dpi = true;
            } else {
                self._display_dpi = self._default_dpi;
            }
            if (cfg.jok_window_borderless) {
                window_flags.borderless = true;
            }
            if (cfg.jok_window_ime_ui) {
                _ = sdl.setHint("SDL_IME_SHOW_UI", "1");
            }
            var window_width: usize = 800;
            var window_height: usize = 600;
            switch (cfg.jok_window_size) {
                .maximized => {
                    window_flags.dim = .maximized;
                },
                .fullscreen => {
                    self._fullscreen = true;
                    window_flags.dim = .fullscreen_desktop;
                },
                .custom => |size| {
                    window_width = @intFromFloat(@as(f32, @floatFromInt(size.width)) * getDpiScale(self));
                    window_height = @intFromFloat(@as(f32, @floatFromInt(size.height)) * getDpiScale(self));
                },
            }
            self._window = try sdl.createWindow(
                cfg.jok_window_title,
                cfg.jok_window_pos_x,
                cfg.jok_window_pos_y,
                window_width,
                window_height,
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
            toggleAlwaysOnTop(self, cfg.jok_window_always_on_top);

            // Apply mouse mode
            switch (cfg.jok_mouse_mode) {
                .normal => {
                    if (cfg.jok_window_size == .fullscreen) {
                        sdl.c.SDL_SetWindowGrab(self._window.ptr, sdl.c.SDL_FALSE);
                        _ = sdl.c.SDL_ShowCursor(sdl.c.SDL_DISABLE);
                        _ = sdl.c.SDL_SetRelativeMouseMode(sdl.c.SDL_TRUE);
                    } else {
                        _ = sdl.c.SDL_ShowCursor(sdl.c.SDL_ENABLE);
                        _ = sdl.c.SDL_SetRelativeMouseMode(sdl.c.SDL_FALSE);
                    }
                },
                .hide => {
                    if (cfg.jok_window_size == .fullscreen) {
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
                    .software = cfg.jok_software_renderer,
                    .present_vsync = cfg.jok_fps_limit == .auto,
                    .target_texture = true,
                },
            ) catch blk: {
                if (cfg.jok_software_renderer_fallback) {
                    log.warn("Hardware accelerated renderer isn't supported, fallback to software backend", .{});
                    break :blk try sdl.createRenderer(
                        self._window,
                        null,
                        .{
                            .software = true,
                            .present_vsync = cfg.jok_fps_limit == .auto, // Doesn't matter actually, vsync won't work anyway
                            .target_texture = true,
                        },
                    );
                } else {
                    @panic("Failed to create renderer!");
                }
            };
            try self._renderer.setDrawBlendMode(.blend);
            const rdinfo = try self._renderer.getInfo();
            self._is_software = ((rdinfo.flags & sdl.c.SDL_RENDERER_SOFTWARE) != 0);

            // Create drawing target
            self._canvas_texture = try jok.utils.gfx.createTextureAsTarget(
                self.context(),
                .{ .size = cfg.jok_canvas_size },
            );
            self.updateCanvasArea();
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
                    .audioEngine = audioEngine,
                    .kill = kill,
                    .toggleResizable = toggleResizable,
                    .toggleFullscreeen = toggleFullscreeen,
                    .toggleAlwaysOnTop = toggleAlwaysOnTop,
                    .getWindowPosition = getWindowPosition,
                    .getWindowSize = getWindowSize,
                    .setWindowSize = setWindowSize,
                    .getCanvasSize = getCanvasSize,
                    .getAspectRatio = getAspectRatio,
                    .getDpiScale = getDpiScale,
                    .isKeyPressed = isKeyPressed,
                    .getMouseState = getMouseState,
                    .isRunningSlow = isRunningSlow,
                    .displayStats = displayStats,
                },
            };
        }

        /// Calculate canvas area according to current sizes of canvas and framebuffer
        inline fn updateCanvasArea(self: *@This()) void {
            if (cfg.jok_canvas_size) |sz| {
                const fbsize = self._renderer.getOutputSize() catch unreachable;
                const vpw: f32 = @floatFromInt(fbsize.width_pixels);
                const vph: f32 = @floatFromInt(fbsize.height_pixels);
                const rw: f32 = @floatFromInt(sz.width);
                const rh: f32 = @floatFromInt(sz.height);
                self._canvas_area = if (rw * vph < rh * vpw) sdl.Rectangle{
                    .x = @intFromFloat(@trunc((vpw - rw * vph / rh) / 2.0)),
                    .y = 0,
                    .width = @intFromFloat(@trunc(rw * vph / rh)),
                    .height = fbsize.height_pixels,
                } else .{
                    .x = 0,
                    .y = @intFromFloat(@trunc((vph - rh * vpw / rw) / 2.0)),
                    .width = fbsize.width_pixels,
                    .height = @intFromFloat(@trunc(rh * vpw / rw)),
                };
                self._canvas_scale = @as(f32, @floatFromInt(sz.width)) /
                    @as(f32, @floatFromInt(self._canvas_area.?.width));
            }
        }

        /// Map position from framebuffer to canvas
        inline fn mapPositionFromFramebufferToCanvas(self: *@This(), pos: sdl.Point) sdl.Point {
            if (cfg.jok_canvas_size != null) {
                const area = self._canvas_area.?;
                return .{
                    .x = @intFromFloat(@as(f32, @floatFromInt(pos.x - area.x)) * self._canvas_scale),
                    .y = @intFromFloat(@as(f32, @floatFromInt(pos.y - area.y)) * self._canvas_scale),
                };
            }
            return pos;
        }

        ///////////////////// Wrapped API for Application Context //////////////////

        /// Get meomry allocator
        fn allocator(ptr: *anyopaque) std.mem.Allocator {
            const self: *@This() = @ptrCast(@alignCast(ptr));
            return self._allocator;
        }

        /// Get application running status
        fn running(ptr: *anyopaque) bool {
            const self: *@This() = @ptrCast(@alignCast(ptr));
            return self._running;
        }

        /// Get running seconds of application
        fn seconds(ptr: *anyopaque) f32 {
            const self: *@This() = @ptrCast(@alignCast(ptr));
            return self._seconds;
        }

        /// Get running seconds of application (double precision)
        fn realSeconds(ptr: *anyopaque) f64 {
            const self: *@This() = @ptrCast(@alignCast(ptr));
            return self._seconds_real;
        }

        /// Get delta time between frames
        fn deltaSeconds(ptr: *anyopaque) f32 {
            const self: *@This() = @ptrCast(@alignCast(ptr));
            return self._delta_seconds;
        }

        /// Get FPS of application
        fn fps(ptr: *anyopaque) f32 {
            const self: *@This() = @ptrCast(@alignCast(ptr));
            return self._fps;
        }

        /// Get SDL window
        fn window(ptr: *anyopaque) sdl.Window {
            const self: *@This() = @ptrCast(@alignCast(ptr));
            return self._window;
        }

        /// Get SDL renderer
        fn renderer(ptr: *anyopaque) sdl.Renderer {
            const self: *@This() = @ptrCast(@alignCast(ptr));
            return self._renderer;
        }

        /// Get audio engine
        fn audioEngine(ptr: *anyopaque) *zaudio.Engine {
            const self: *@This() = @ptrCast(@alignCast(ptr));
            return self._audio_engine;
        }

        /// Kill app
        fn kill(ptr: *anyopaque) void {
            const self: *@This() = @ptrCast(@alignCast(ptr));
            self._running = false;
        }

        /// Toggle resizable
        fn toggleResizable(ptr: *anyopaque, on_off: ?bool) void {
            var self: *@This() = @ptrCast(@alignCast(ptr));
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
            var self: *@This() = @ptrCast(@alignCast(ptr));
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
            var self: *@This() = @ptrCast(@alignCast(ptr));
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
            const self: *@This() = @ptrCast(@alignCast(ptr));
            var x: c_int = undefined;
            var y: c_int = undefined;
            sdl.c.SDL_GetWindowPosition(self._window.ptr, &x, &y);
            return .{ .x = @floatFromInt(x), .y = @floatFromInt(y) };
        }

        /// Get size of window
        fn getWindowSize(ptr: *anyopaque) sdl.PointF {
            const self: *@This() = @ptrCast(@alignCast(ptr));
            var w: c_int = undefined;
            var h: c_int = undefined;
            sdl.c.SDL_GetWindowSize(self._window.ptr, &w, &h);
            return .{ .x = @floatFromInt(w), .y = @floatFromInt(h) };
        }

        /// Set size of window
        fn setWindowSize(ptr: *anyopaque, size: sdl.PointF) void {
            const self: *@This() = @ptrCast(@alignCast(ptr));
            const w: c_int = @intFromFloat(size.x * getDpiScale(ptr));
            const h: c_int = @intFromFloat(size.y * getDpiScale(ptr));
            sdl.c.SDL_SetWindowSize(self._window.ptr, w, h);
        }

        /// Get size of canvas
        fn getCanvasSize(ptr: *anyopaque) sdl.PointF {
            const self: *@This() = @ptrCast(@alignCast(ptr));
            if (cfg.jok_canvas_size) |sz| return .{
                .x = @floatFromInt(sz.width),
                .y = @floatFromInt(sz.height),
            };
            const fbsize = self._renderer.getOutputSize() catch unreachable;
            return .{
                .x = @floatFromInt(fbsize.width_pixels),
                .y = @floatFromInt(fbsize.height_pixels),
            };
        }

        /// Get aspect ratio of drawing area
        fn getAspectRatio(ptr: *anyopaque) f32 {
            const size = getCanvasSize(ptr);
            return size.x / size.y;
        }

        /// Get dpi scale
        fn getDpiScale(ptr: *anyopaque) f32 {
            const S = struct {
                var scale: ?f32 = null;
            };
            if (S.scale) |s| {
                return s;
            } else {
                const self: *@This() = @ptrCast(@alignCast(ptr));
                S.scale = self._display_dpi / self._default_dpi;
                return S.scale.?;
            }
        }

        /// Get key status
        fn isKeyPressed(_: *anyopaque, key: sdl.Scancode) bool {
            const kb_state = sdl.getKeyboardState();
            return kb_state.isPressed(key);
        }

        /// Get mouse state
        fn getMouseState(ptr: *anyopaque) sdl.MouseState {
            const self: *@This() = @ptrCast(@alignCast(ptr));
            var state = sdl.getMouseState();
            if (cfg.jok_canvas_size != null) {
                const pos = self.mapPositionFromFramebufferToCanvas(.{
                    .x = state.x,
                    .y = state.y,
                });
                state.x = pos.x;
                state.y = pos.y;
            }
            return state;
        }

        /// Indicating game loop is running too slow
        pub fn isRunningSlow(ptr: *anyopaque) bool {
            const self: *@This() = @ptrCast(@alignCast(ptr));
            return self._running_slow;
        }

        /// Display frame statistics
        fn displayStats(ptr: *anyopaque, opt: DisplayStats) void {
            const self: *@This() = @ptrCast(@alignCast(ptr));
            const rdinfo = self._renderer.getInfo() catch unreachable;
            const ws = getWindowSize(ptr);
            const cs = getCanvasSize(ptr);
            imgui.setNextWindowBgAlpha(.{ .alpha = 0.7 });
            imgui.setNextWindowPos(.{
                .x = ws.x,
                .y = 0,
                .pivot_x = 1,
                .cond = if (opt.movable) .once else .always,
            });
            imgui.setNextWindowSize(.{ .w = opt.width * getDpiScale(ptr), .h = 0, .cond = .always });
            if (imgui.begin("Frame Statistics", .{
                .flags = .{
                    .no_title_bar = !opt.collapsible,
                    .no_resize = true,
                    .always_auto_resize = true,
                },
            })) {
                imgui.text("Window Size: {d}x{d}", .{ ws.x, ws.y });
                imgui.text("Canvas Size: {d}x{d}", .{ cs.x, cs.y });
                imgui.text("Display DPI: {d:.1}", .{self._display_dpi});
                imgui.text("GPU Enabled: {}", .{!self._is_software});
                imgui.text("V-Sync Enabled: {}", .{rdinfo.flags & sdl.c.SDL_RENDERER_PRESENTVSYNC != 0});
                imgui.text("Optimize Mode: {s}", .{@tagName(builtin.mode)});
                imgui.separator();
                if (self._running_slow) {
                    imgui.textColored(.{ 1, 0, 0, 1 }, "FPS: {d:.1} {s}", .{ self._fps, cfg.jok_fps_limit.str() });
                    imgui.textColored(.{ 1, 0, 0, 1 }, "CPU: {d:.1}ms", .{1000.0 / self._fps});
                } else {
                    imgui.text("FPS: {d:.1} {s}", .{ self._fps, cfg.jok_fps_limit.str() });
                    imgui.text("CPU: {d:.1}ms", .{1000.0 / self._fps});
                }
                imgui.text("Memory: {:.3}", .{std.fmt.fmtIntSizeBin(gpa.total_requested_bytes)});
                imgui.text("Draw Calls: {d}", .{self._drawcall_count});
                imgui.text("Triangles: {d}", .{self._triangle_count});

                if (cfg.jok_detailed_frame_stats and self._seconds_real > 1) {
                    imgui.separator();
                    if (plot.beginPlot(
                        imgui.formatZ("Costs of Update/Draw ({}s)", .{opt.duration}),
                        .{
                            .h = opt.width * 3 / 4,
                            .flags = .{ .no_menus = true },
                        },
                    )) {
                        plot.setupLegend(
                            .{ .south = true },
                            .{ .horizontal = true, .outside = true },
                        );
                        plot.setupAxisLimits(.x1, .{
                            .min = 0,
                            .max = @floatFromInt(@min(max_costs_num, opt.duration * 10)),
                        });
                        plot.setupAxisLimits(.y1, .{
                            .min = 0,
                            .max = @max(20, self._update_cost + self._draw_cost + 5),
                        });
                        plot.setupAxis(.x1, .{
                            .flags = .{
                                .no_label = true,
                                .no_tick_labels = true,
                                .no_highlight = true,
                                .lock_min = true,
                                .lock_max = true,
                            },
                        });
                        plot.setupAxis(.y1, .{
                            .flags = .{
                                .no_label = true,
                                .no_highlight = true,
                                .lock_min = true,
                            },
                        });
                        plot.pushStyleColor4f(.{
                            .idx = .frame_bg,
                            .c = .{ 0.1, 0.1, 0.1, 0.1 },
                        });
                        plot.pushStyleColor4f(.{
                            .idx = .plot_bg,
                            .c = .{ 0.2, 0.2, 0.2, 0.2 },
                        });
                        defer plot.popStyleColor(.{ .count = 2 });
                        var update_costs: [max_costs_num]f32 = undefined;
                        var draw_costs: [max_costs_num]f32 = undefined;
                        var total_costs: [max_costs_num]f32 = undefined;
                        const size = @min(self._recent_update_costs.len(), opt.duration * 10);
                        var costs = self._recent_update_costs.sliceLast(size);
                        @memcpy(update_costs[0..costs.first.len], costs.first);
                        @memcpy(update_costs[costs.first.len .. costs.first.len + costs.second.len], costs.second);
                        costs = self._recent_draw_costs.sliceLast(size);
                        @memcpy(draw_costs[0..costs.first.len], costs.first);
                        @memcpy(draw_costs[costs.first.len .. costs.first.len + costs.second.len], costs.second);
                        costs = self._recent_total_costs.sliceLast(size);
                        @memcpy(total_costs[0..costs.first.len], costs.first);
                        @memcpy(total_costs[costs.first.len .. costs.first.len + costs.second.len], costs.second);
                        plot.plotLineValues("update", f32, .{
                            .v = update_costs[0..size],
                        });
                        plot.plotLineValues("draw", f32, .{
                            .v = draw_costs[0..size],
                        });
                        plot.plotLineValues("update+draw", f32, .{
                            .v = total_costs[0..size],
                        });
                        plot.endPlot();
                    }
                }
            }
            imgui.end();
        }
    };
}
