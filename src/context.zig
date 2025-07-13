const std = @import("std");
const assert = std.debug.assert;
const builtin = @import("builtin");
const bos = @import("build_options");
const w32 = @import("w32.zig");
const config = @import("config.zig");
const pp = @import("post_processing.zig");
const PluginSystem = @import("PluginSystem.zig");
const jok = @import("jok.zig");
const sdl = jok.sdl;
const io = jok.io;
const physfs = jok.physfs;
const font = jok.font;
const imgui = jok.imgui;
const plot = imgui.plot;
const zaudio = jok.zaudio;
const zmesh = jok.zmesh;
const log = std.log.scoped(.jok);

/// Application context
pub const Context = struct {
    ctx: *anyopaque,
    vtable: struct {
        cfg: *const fn (ctx: *anyopaque) config.Config,
        allocator: *const fn (ctx: *anyopaque) std.mem.Allocator,
        seconds: *const fn (ctx: *anyopaque) f32,
        realSeconds: *const fn (ctx: *anyopaque) f64,
        deltaSeconds: *const fn (ctx: *anyopaque) f32,
        fps: *const fn (ctx: *anyopaque) f32,
        isMainThread: *const fn (ctx: *anyopaque) bool,
        window: *const fn (ctx: *anyopaque) jok.Window,
        renderer: *const fn (ctx: *anyopaque) jok.Renderer,
        canvas: *const fn (ctx: *anyopaque) jok.Texture,
        audioEngine: *const fn (ctx: *anyopaque) *zaudio.Engine,
        kill: *const fn (ctx: *anyopaque) void,
        getCanvasSize: *const fn (ctx: *anyopaque) jok.Size,
        setCanvasSize: *const fn (ctx: *anyopaque, size: ?jok.Size) anyerror!void,
        getCanvasArea: *const fn (ctx: *anyopaque) jok.Rectangle,
        getAspectRatio: *const fn (ctx: *anyopaque) f32,
        getDpiScale: *const fn (ctx: *anyopaque) f32,
        addPostProcessing: *const fn (ctx: *anyopaque, ppa: pp.Actor) anyerror!void,
        clearPostProcessing: *const fn (ctx: *anyopaque) void,
        supressDraw: *const fn (ctx: *anyopaque) void,
        isRunningSlow: *const fn (ctx: *anyopaque) bool,
        displayStats: *const fn (ctx: *anyopaque, opt: DisplayStats) void,
        debugPrint: *const fn (ctx: *anyopaque, text: []const u8, opt: DebugPrint) void,
        getDebugAtlas: *const fn (ctx: *anyopaque, size: u32) *font.Atlas,
        registerPlugin: *const fn (ctx: *anyopaque, name: []const u8, path: []const u8, hotreload: bool) anyerror!void,
        unregisterPlugin: *const fn (ctx: *anyopaque, name: []const u8) anyerror!void,
        forceReloadPlugin: *const fn (ctx: *anyopaque, name: []const u8) anyerror!void,
    },

    /// Get setup configuration
    pub fn cfg(self: Context) config.Config {
        return self.vtable.cfg(self.ctx);
    }

    /// Get meomry allocator
    pub fn allocator(self: Context) std.mem.Allocator {
        return self.vtable.allocator(self.ctx);
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

    /// Whether current thread is main thread
    pub fn isMainThread(self: Context) bool {
        return self.vtable.isMainThread(self.ctx);
    }

    /// Get SDL window
    pub fn window(self: Context) jok.Window {
        return self.vtable.window(self.ctx);
    }

    /// Get SDL renderer
    pub fn renderer(self: Context) jok.Renderer {
        return self.vtable.renderer(self.ctx);
    }

    /// Get canvas texture
    pub fn canvas(self: Context) jok.Texture {
        return self.vtable.canvas(self.ctx);
    }

    /// Get audio engine
    pub fn audioEngine(self: Context) *zaudio.Engine {
        if (bos.no_audio) @panic("Audio is disabled!");
        return self.vtable.audioEngine(self.ctx);
    }

    /// Kill application
    pub fn kill(self: Context) void {
        return self.vtable.kill(self.ctx);
    }

    /// Get size of canvas
    pub fn getCanvasSize(self: Context) jok.Size {
        return self.vtable.getCanvasSize(self.ctx);
    }

    /// Set size of canvas (null means same as current framebuffer)
    pub fn setCanvasSize(self: Context, size: ?jok.Size) !void {
        return self.vtable.setCanvasSize(self.ctx, size);
    }

    /// Get canvas drawing area in framebuffer
    pub fn getCanvasArea(self: Context) jok.Rectangle {
        return self.vtable.getCanvasArea(self.ctx);
    }

    /// Get aspect ratio of drawing area
    pub fn getAspectRatio(self: Context) f32 {
        return self.vtable.getAspectRatio(self.ctx);
    }

    /// Get dpi scale
    pub fn getDpiScale(self: Context) f32 {
        return self.vtable.getDpiScale(self.ctx);
    }

    /// Add post-processing effect
    pub fn addPostProcessing(self: Context, ppa: pp.Actor) !void {
        if (ppa.region) |r| {
            const canvas_size = self.getCanvasSize();
            assert(r.width < canvas_size.width);
            assert(r.height < canvas_size.height);
        }
        try self.vtable.addPostProcessing(self.ctx, ppa);
    }

    /// Clear post-processing effects
    pub fn clearPostProcessing(self: Context) void {
        return self.vtable.clearPostProcessing(self.ctx);
    }

    /// Supress drawcall of current frame
    pub fn supressDraw(self: Context) void {
        return self.vtable.supressDraw(self.ctx);
    }

    /// Whether game is running slow
    pub fn isRunningSlow(self: Context) bool {
        return self.vtable.isRunningSlow(self.ctx);
    }

    /// Display statistics
    pub fn displayStats(self: Context, opt: DisplayStats) void {
        return self.vtable.displayStats(self.ctx, opt);
    }

    /// Display text
    pub fn debugPrint(self: Context, text: []const u8, opt: DebugPrint) void {
        return self.vtable.debugPrint(self.ctx, text, opt);
    }

    /// Get atlas of debug font
    pub fn getDebugAtlas(self: Context, size: u32) *font.Atlas {
        return self.vtable.getDebugAtlas(self.ctx, size);
    }

    /// Register new plugin
    pub fn registerPlugin(self: Context, name: []const u8, path: []const u8, hotreload: bool) !void {
        try self.vtable.registerPlugin(self.ctx, name, path, hotreload);
    }

    /// Unregister plugin
    pub fn unregisterPlugin(self: Context, name: []const u8) !void {
        try self.vtable.unregisterPlugin(self.ctx, name);
    }

    ///  Force reload plugin
    pub fn forceReloadPlugin(self: Context, name: []const u8) !void {
        try self.vtable.forceReloadPlugin(self.ctx, name);
    }
};

pub const DisplayStats = struct {
    movable: bool = false,
    collapsible: bool = false,
    width: f32 = 250,
    duration: u32 = 15,
};

pub const DebugPrint = struct {
    pos: jok.Point = .origin,
    color: jok.Color = .white,
};

/// Context generator
pub fn JokContext(comptime cfg: config.Config) type {
    const DebugAllocatorType = std.heap.DebugAllocator(.{
        .safety = true,
        .enable_memory_limit = true,
    });

    return struct {
        var debug_allocator: DebugAllocatorType = .init;
        const max_costs_num = 300;
        const CostDataType = jok.utils.ring.Ring(f32);

        /// Setup configuration
        _cfg: config.Config = cfg,

        // Memory allocator
        _allocator: std.mem.Allocator = undefined,

        // Main thread id
        _main_thread_id: ?std.Thread.Id = undefined,

        // Application Context
        _ctx: Context = undefined,

        // Is running
        _running: bool = true,

        // Internal window
        _window: jok.Window = undefined,

        // High DPI stuff
        _default_dpi: f32 = undefined,
        _display_dpi: f32 = undefined,

        // Renderer instance
        _renderer: jok.Renderer = undefined,

        // Rendering target
        _canvas_texture: jok.Texture = undefined,
        _canvas_size: ?jok.Size = cfg.jok_canvas_size,
        _canvas_target_area: ?jok.Rectangle = null,

        // Post-processing
        _post_processing: pp.PostProcessingEffect = undefined,
        _pp_actors: std.ArrayList(pp.Actor) = undefined,

        // Drawcall supress
        _supress_draw: bool = false,

        // Audio Engine
        _audio_engine: *zaudio.Engine = undefined,

        // Debug printing
        _debug_font_size: u32 = undefined,
        _debug_print_vertices: std.ArrayList(jok.Vertex) = undefined,
        _debug_print_indices: std.ArrayList(u32) = undefined,

        // Plugin System
        _plugin_system: *PluginSystem = undefined,

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
            var _allocator = if (builtin.cpu.arch.isWasm())
                std.heap.c_allocator
            else if (cfg.jok_check_memory_leak)
                debug_allocator.allocator()
            else
                std.heap.smp_allocator;
            var self = try _allocator.create(@This());
            self.* = .{};
            self._allocator = _allocator;
            self._main_thread_id = std.Thread.getCurrentId();
            self._ctx = self.context();

            // Init PhysicsFS
            physfs.init(self._allocator);
            if (builtin.cpu.arch.isWasm()) {
                try physfs.mount("/", "", true);
            }

            // Init SDL window and renderer
            try self.initSDL();

            // Init imgui
            imgui.sdl.init(self._ctx, cfg.jok_imgui_ini_file);

            // Init zmesh
            zmesh.init(self._allocator);

            // Init audio engine
            if (!bos.no_audio) {
                zaudio.init(self._allocator);
                var audio_config = zaudio.Engine.Config.init();
                audio_config.resource_manager_vfs = &physfs.zaudio.vfs;
                self._audio_engine = try zaudio.Engine.create(audio_config);
            }

            // Init plugin system
            if (bos.link_dynamic) {
                self._plugin_system = try PluginSystem.create(self._allocator);
            }

            // Init builtin debug font
            try font.DebugFont.init(self._allocator);
            self._debug_font_size = @intFromFloat(@as(f32, @floatFromInt(cfg.jok_prebuild_atlas)) * getDpiScale(self));
            self._debug_print_vertices = std.ArrayList(jok.Vertex).init(self._allocator);
            self._debug_print_indices = std.ArrayList(u32).init(self._allocator);
            _ = try font.DebugFont.getAtlas(self._ctx, self._debug_font_size);

            // Misc.
            self._pc_freq = sdl.SDL_GetPerformanceFrequency();
            self._pc_max_accumulated = self._pc_freq / 2;
            self._pc_last = sdl.SDL_GetPerformanceCounter();
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
            self._debug_print_vertices.deinit();
            self._debug_print_indices.deinit();
            font.DebugFont.deinit();

            // Destroy plugin system
            if (bos.link_dynamic) {
                self._plugin_system.destroy(self._ctx);
            }

            // Destroy audio engine
            if (!bos.no_audio) {
                self._audio_engine.destroy();
                zaudio.deinit();
            }

            // Destroy zmesh
            zmesh.deinit();

            // Destroy imgui
            imgui.sdl.deinit();

            // Destroy window and renderer
            self.deinitSDL();

            // Deinitialize PhysicsFS
            physfs.deinit();

            // Destory self
            self._allocator.destroy(self);

            // Check memory leak if possible
            if (cfg.jok_check_memory_leak) {
                _ = debug_allocator.deinit();
            }
        }

        /// Ticking of application
        pub fn tick(
            self: *@This(),
            comptime eventFn: *const fn (Context, jok.Event) anyerror!void,
            comptime updateFn: *const fn (Context) anyerror!void,
            comptime drawFn: *const fn (Context) anyerror!void,
        ) void {
            const pc_threshold: u64 = switch (cfg.jok_fps_limit) {
                .none => 0,
                .auto => 0,
                .manual => |_fps| self._pc_freq / @as(u64, _fps),
            };

            // Update game
            if (pc_threshold > 0) {
                while (true) {
                    const pc = sdl.SDL_GetPerformanceCounter();
                    self._pc_accumulated += pc - self._pc_last;
                    self._pc_last = pc;
                    if (self._pc_accumulated >= pc_threshold) {
                        break;
                    }
                    if ((pc_threshold - self._pc_accumulated) * 1000 > self._pc_freq) {
                        sdl.SDL_Delay(1);
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
                const pc = sdl.SDL_GetPerformanceCounter();
                self._delta_seconds = @floatCast(
                    @as(f64, @floatFromInt(pc - self._pc_last)) / @as(f64, @floatFromInt(self._pc_freq)),
                );
                self._pc_last = pc;
                self._seconds += self._delta_seconds;
                self._seconds_real += self._delta_seconds;

                self._update(eventFn, updateFn);
            }

            // Do rendering
            if (self._supress_draw) {
                self._supress_draw = false;
            } else {
                const pc_begin = sdl.SDL_GetPerformanceCounter();
                defer if (cfg.jok_detailed_frame_stats) {
                    const cost = @as(f32, @floatFromInt((sdl.SDL_GetPerformanceCounter() - pc_begin) * 1000)) /
                        @as(f32, @floatFromInt(self._pc_freq));
                    self._draw_cost = if (self._draw_cost > 0) (self._draw_cost + cost) / 2 else cost;
                };

                defer self._renderer.present();

                imgui.sdl.newFrame(self.context());
                defer imgui.sdl.draw(self.context());

                self._renderer.clear(cfg.jok_framebuffer_color) catch unreachable;
                self._renderer.setTarget(self._canvas_texture) catch unreachable;
                defer {
                    self._renderer.setTarget(null) catch unreachable;
                    if (cfg.jok_enable_post_processing and self._pp_actors.items.len > 0) {
                        self._post_processing.reset();
                        for (self._pp_actors.items) |a| {
                            self._post_processing.applyActor(a);
                        }
                        self._post_processing.render();
                    } else {
                        self._renderer.drawTexture(
                            self._canvas_texture,
                            null,
                            self._canvas_target_area,
                        ) catch unreachable;
                    }
                }

                drawFn(self._ctx) catch |err| {
                    log.err("Got error in `draw`: {s}", .{@errorName(err)});
                    if (@errorReturnTrace()) |trace| {
                        std.debug.dumpStackTrace(trace.*);
                        kill(self);
                        return;
                    }
                };
                if (bos.link_dynamic) {
                    self._plugin_system.draw(self._ctx);
                }
            }

            self._updateFrameStats();
        }

        /// Update game state
        inline fn _update(
            self: *@This(),
            comptime eventFn: *const fn (Context, jok.Event) anyerror!void,
            comptime updateFn: *const fn (Context) anyerror!void,
        ) void {
            const pc_begin = sdl.SDL_GetPerformanceCounter();
            defer if (cfg.jok_detailed_frame_stats) {
                const cost = @as(f32, @floatFromInt((sdl.SDL_GetPerformanceCounter() - pc_begin) * 1000)) /
                    @as(f32, @floatFromInt(self._pc_freq));
                self._update_cost = if (self._update_cost > 0) (self._update_cost + cost) / 2 else cost;
            };

            while (io.pollNativeEvent()) |ne| {
                // ImGui event processing
                var e = ne;
                if (cfg.jok_window_highdpi) {
                    switch (e.type) {
                        sdl.SDL_MOUSEMOTION => {
                            e.motion.x = @intFromFloat(@as(f32, @floatFromInt(e.motion.x)) / getDpiScale(self));
                            e.motion.y = @intFromFloat(@as(f32, @floatFromInt(e.motion.y)) / getDpiScale(self));
                        },
                        sdl.SDL_MOUSEBUTTONDOWN, sdl.SDL_MOUSEBUTTONUP => {
                            e.button.x = @intFromFloat(@as(f32, @floatFromInt(e.button.x)) / getDpiScale(self));
                            e.button.y = @intFromFloat(@as(f32, @floatFromInt(e.button.y)) / getDpiScale(self));
                        },
                        else => {},
                    }
                }
                _ = imgui.sdl.processEvent(e);

                // Game event processing
                const we = jok.Event.from(ne, self._ctx);
                if (!builtin.cpu.arch.isWasm() and cfg.jok_exit_on_recv_esc and we == .key_up and we.key_up.scancode == .escape) {
                    kill(self);
                } else if (cfg.jok_exit_on_recv_quit and we == .quit) {
                    kill(self);
                } else {
                    if (we == .window) {
                        switch (we.window.type) {
                            .resized, .size_changed => {
                                if (self._canvas_size == null) {
                                    self._canvas_texture.destroy();
                                    self._canvas_texture = self._renderer.createTarget(.{}) catch unreachable;
                                }
                                self.updateCanvasTargetArea();
                            },
                            else => {},
                        }
                    }

                    // Passed to game code
                    eventFn(self._ctx, we) catch |err| {
                        log.err("Got error in `event`: {s}", .{@errorName(err)});
                        if (@errorReturnTrace()) |trace| {
                            std.debug.dumpStackTrace(trace.*);
                            kill(self);
                            return;
                        }
                    };
                    if (bos.link_dynamic) {
                        self._plugin_system.event(self._ctx, we);
                    }
                }
            }

            updateFn(self._ctx) catch |err| {
                log.err("Got error in `update`: {s}", .{@errorName(err)});
                if (@errorReturnTrace()) |trace| {
                    std.debug.dumpStackTrace(trace.*);
                    kill(self);
                    return;
                }
            };
            if (bos.link_dynamic) {
                self._plugin_system.update(self._ctx);
            }
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
                self._drawcall_count = self._renderer.dc.drawcall_count / self._frame_count;
                self._triangle_count = self._renderer.dc.triangle_count / self._frame_count;
                self._renderer.dc.clear();
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
        fn checkSys(self: *@This()) !void {
            const target = builtin.target;
            var sdl_version: sdl.SDL_version = undefined;
            sdl.SDL_GetVersion(&sdl_version);
            const ram_size = sdl.SDL_GetSystemRAM();
            const info = try self._renderer.getInfo();

            // Print system info
            const writer = std.debug.lockStderrWriter(&.{});
            defer std.debug.unlockStdErr();
            try writer.print(
                \\System info:
                \\    Build Mode  : {s}
                \\    Log Level   : {s}
                \\    Zig Version : {f}
                \\    CPU         : {s}
                \\    ABI         : {s}
                \\    SDL         : {d}.{d}.{d}
                \\    Platform    : {s}
                \\    Memory      : {d}MB
                \\    App Dir     : {s} 
                \\    
                \\Renderer info:
                \\    Driver           : {s}
                \\    Vertical Sync    : {}
                \\    Max Texture Size : {d}*{d}
                \\
                \\
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
                    physfs.getBaseDir(),
                    info.name,
                    info.flags & sdl.SDL_RENDERER_PRESENTVSYNC != 0,
                    info.max_texture_width,
                    info.max_texture_height,
                },
            );

            if (sdl_version.major < 2 or (sdl_version.minor == 0 and sdl_version.patch < 18)) {
                log.err("SDL version too low, need at least 2.0.18", .{});
                return sdl.Error.SdlError;
            }
        }

        /// Initialize SDL
        fn initSDL(self: *@This()) !void {
            if (cfg.jok_headless) {
                _ = sdl.SDL_SetHint(sdl.SDL_HINT_VIDEODRIVER, "offscreen");
            }

            var excluded = sdl.SDL_INIT_AUDIO;
            if (builtin.cpu.arch.isWasm()) {
                excluded |= sdl.SDL_INIT_HAPTIC;
            }
            if (sdl.SDL_Init(sdl.SDL_INIT_EVERYTHING & ~excluded) < 0) {
                log.err("Initialize SDL2 failed: {s}", .{sdl.SDL_GetError()});
                return sdl.Error.SdlError;
            }

            // Initialize dpi
            self._default_dpi = switch (builtin.target.os.tag) {
                .macos => 72.0,
                else => 96.0,
            };
            if (cfg.jok_window_highdpi) {
                if (builtin.target.os.tag == .windows) {
                    // Enable High-DPI awareness
                    // BUG: only workable on single monitor system
                    _ = w32.SetProcessDPIAware();
                }
                if (sdl.SDL_GetDisplayDPI(0, null, &self._display_dpi, null) < 0) {
                    self._display_dpi = self._default_dpi;
                }
            } else {
                self._display_dpi = self._default_dpi;
            }

            // Initialize window and renderer
            self._window = try jok.Window.init(self._ctx);
            self._renderer = try jok.Renderer.init(self._ctx);

            // Check and print system info
            try self.checkSys();

            // Init drawing target
            self._canvas_texture = try self._renderer.createTarget(.{ .size = self._canvas_size });

            if (cfg.jok_enable_post_processing) {
                // Init post-processing facility
                self._post_processing = try pp.PostProcessingEffect.init(self._ctx);
                self._pp_actors = std.ArrayList(pp.Actor).init(self._allocator);
            }
            self.updateCanvasTargetArea();

            if (!builtin.cpu.arch.isWasm() and !cfg.jok_headless and cfg.jok_exit_on_recv_esc) {
                log.info("Press ESC to exit game", .{});
            }
        }

        /// Deinitialize SDL
        fn deinitSDL(self: *@This()) void {
            if (cfg.jok_enable_post_processing) {
                self._pp_actors.deinit();
                self._post_processing.destroy();
            }
            self._canvas_texture.destroy();
            self._renderer.destroy();
            self._window.destroy();
            sdl.SDL_Quit();
        }

        /// Get type-erased context for application
        pub fn context(self: *@This()) Context {
            return .{
                .ctx = self,
                .vtable = .{
                    .cfg = getcfg,
                    .allocator = allocator,
                    .seconds = seconds,
                    .realSeconds = realSeconds,
                    .deltaSeconds = deltaSeconds,
                    .fps = fps,
                    .isMainThread = isMainThread,
                    .window = window,
                    .renderer = renderer,
                    .canvas = canvas,
                    .audioEngine = audioEngine,
                    .kill = kill,
                    .getCanvasSize = getCanvasSize,
                    .setCanvasSize = setCanvasSize,
                    .getCanvasArea = getCanvasArea,
                    .getAspectRatio = getAspectRatio,
                    .getDpiScale = getDpiScale,
                    .addPostProcessing = addPostProcessing,
                    .clearPostProcessing = clearPostProcessing,
                    .supressDraw = supressDraw,
                    .isRunningSlow = isRunningSlow,
                    .displayStats = displayStats,
                    .debugPrint = debugPrint,
                    .getDebugAtlas = getDebugAtlas,
                    .registerPlugin = registerPlugin,
                    .unregisterPlugin = unregisterPlugin,
                    .forceReloadPlugin = forceReloadPlugin,
                },
            };
        }

        /// Update canvas area according to current sizes of canvas and framebuffer
        inline fn updateCanvasTargetArea(self: *@This()) void {
            if (self._canvas_size) |sz| {
                const fbsize = self._renderer.getOutputSize() catch unreachable;
                const vpw: f32 = @floatFromInt(fbsize.width);
                const vph: f32 = @floatFromInt(fbsize.height);
                const rw: f32 = @floatFromInt(sz.width);
                const rh: f32 = @floatFromInt(sz.height);
                self._canvas_target_area = if (rw * vph < rh * vpw) jok.Rectangle{
                    .x = (vpw - rw * vph / rh) / 2.0,
                    .y = 0,
                    .width = rw * vph / rh,
                    .height = @floatFromInt(fbsize.height),
                } else .{
                    .x = 0,
                    .y = (vph - rh * vpw / rw) / 2.0,
                    .width = @floatFromInt(fbsize.width),
                    .height = rh * vpw / rw,
                };
            } else {
                self._canvas_target_area = null;
            }
            if (cfg.jok_enable_post_processing) {
                self._post_processing.onCanvasChange();
            }
        }

        ///////////////////// Wrapped API for Application Context //////////////////

        /// Get setup configuration
        fn getcfg(ptr: *anyopaque) config.Config {
            const self: *@This() = @ptrCast(@alignCast(ptr));
            return self._cfg;
        }

        /// Get meomry allocator
        fn allocator(ptr: *anyopaque) std.mem.Allocator {
            const self: *@This() = @ptrCast(@alignCast(ptr));
            return self._allocator;
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

        /// Whether current thread is main thread
        pub fn isMainThread(ptr: *anyopaque) bool {
            const self: *@This() = @ptrCast(@alignCast(ptr));
            return self._main_thread_id == std.Thread.getCurrentId();
        }

        /// Get SDL window
        fn window(ptr: *anyopaque) jok.Window {
            const self: *@This() = @ptrCast(@alignCast(ptr));
            return self._window;
        }

        /// Get SDL renderer
        fn renderer(ptr: *anyopaque) jok.Renderer {
            const self: *@This() = @ptrCast(@alignCast(ptr));
            return self._renderer;
        }

        /// Get canvas texture
        fn canvas(ptr: *anyopaque) jok.Texture {
            const self: *@This() = @ptrCast(@alignCast(ptr));
            return self._canvas_texture;
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

        /// Get size of canvas
        fn getCanvasSize(ptr: *anyopaque) jok.Size {
            const self: *@This() = @ptrCast(@alignCast(ptr));
            if (self._canvas_size) |sz| return sz;
            return self._renderer.getOutputSize() catch unreachable;
        }

        /// Set size of canvas (null means same as current framebuffer)
        fn setCanvasSize(ptr: *anyopaque, size: ?jok.Size) !void {
            assert(size == null or (size.?.width > 0 and size.?.width > 0));
            const self: *@This() = @ptrCast(@alignCast(ptr));
            self._canvas_texture.destroy();
            self._canvas_size = size;
            self._canvas_texture = try self._renderer.createTarget(.{ .size = self._canvas_size });
            self.updateCanvasTargetArea();
        }

        /// Get canvas drawing area (stretched to fill framebuffer)
        fn getCanvasArea(ptr: *anyopaque) jok.Rectangle {
            const self: *@This() = @ptrCast(@alignCast(ptr));
            if (self._canvas_target_area) |area| return area;
            const output = self._renderer.getOutputSize() catch unreachable;
            return .{
                .x = 0,
                .y = 0,
                .width = @floatFromInt(output.width),
                .height = @floatFromInt(output.height),
            };
        }

        /// Get aspect ratio of drawing area
        fn getAspectRatio(ptr: *anyopaque) f32 {
            const size = getCanvasSize(ptr);
            return @as(f32, @floatFromInt(size.width)) / @as(f32, @floatFromInt(size.height));
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

        /// Add post-processing effect
        pub fn addPostProcessing(ptr: *anyopaque, ppa: pp.Actor) !void {
            if (!cfg.jok_enable_post_processing) {
                @panic("post-processing isn't enabled!");
            }
            const self: *@This() = @ptrCast(@alignCast(ptr));
            try self._pp_actors.append(ppa);
        }

        /// Clear post-processing effect
        pub fn clearPostProcessing(ptr: *anyopaque) void {
            if (!cfg.jok_enable_post_processing) {
                @panic("post-processing isn't enabled!");
            }
            const self: *@This() = @ptrCast(@alignCast(ptr));
            self._pp_actors.clearRetainingCapacity();
        }

        /// Supress drawcall of current frame
        pub fn supressDraw(ptr: *anyopaque) void {
            const self: *@This() = @ptrCast(@alignCast(ptr));
            self._supress_draw = true;
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
            const ws = self._window.getSize();
            const cs = getCanvasSize(ptr);
            imgui.setNextWindowBgAlpha(.{ .alpha = 0.7 });
            imgui.setNextWindowPos(.{
                .x = @floatFromInt(ws.width),
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
                imgui.text("Window Size: {d:.0}x{d:.0}", .{ ws.width, ws.height });
                imgui.text("Canvas Size: {d:.0}x{d:.0}", .{ cs.width, cs.height });
                imgui.text("Display DPI: {d:.1}", .{self._display_dpi});
                imgui.text("V-Sync Enabled: {}", .{rdinfo.flags & sdl.SDL_RENDERER_PRESENTVSYNC != 0});
                imgui.text("Optimize Mode: {s}", .{@tagName(builtin.mode)});
                imgui.separator();
                imgui.text("Duration: {D}", .{@as(u64, @intFromFloat(self._seconds_real * 1e9))});
                if (self._running_slow) {
                    imgui.textColored(.{ 1, 0, 0, 1 }, "FPS: {d:.1} {s}", .{ self._fps, cfg.jok_fps_limit.str() });
                    imgui.textColored(.{ 1, 0, 0, 1 }, "CPU: {d:.1}ms", .{1000.0 / self._fps});
                } else {
                    imgui.text("FPS: {d:.1} {s}", .{ self._fps, cfg.jok_fps_limit.str() });
                    imgui.text("CPU: {d:.1}ms", .{1000.0 / self._fps});
                }
                if (builtin.mode == .Debug) {
                    imgui.text("Memory: {Bi:.3}", .{debug_allocator.total_requested_bytes});
                }
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

        /// Display text
        pub fn debugPrint(ptr: *anyopaque, text: []const u8, opt: DebugPrint) void {
            const self: *@This() = @ptrCast(@alignCast(ptr));
            const atlas = font.DebugFont.getAtlas(self._ctx, self._debug_font_size) catch unreachable;
            self._debug_print_vertices.clearRetainingCapacity();
            self._debug_print_indices.clearRetainingCapacity();
            _ = atlas.appendDrawDataFromUTF8String(
                text,
                opt.pos,
                opt.color,
                &self._debug_print_vertices,
                &self._debug_print_indices,
                .{},
            ) catch unreachable;
            self._renderer.drawTriangles(
                atlas.tex,
                self._debug_print_vertices.items,
                self._debug_print_indices.items,
            ) catch unreachable;
        }

        /// Get atlas of debug font
        pub fn getDebugAtlas(ptr: *anyopaque, size: u32) *font.Atlas {
            const self: *@This() = @ptrCast(@alignCast(ptr));
            return font.DebugFont.getAtlas(self._ctx, size) catch unreachable;
        }

        /// Register new plugin
        pub fn registerPlugin(ptr: *anyopaque, name: []const u8, path: []const u8, hotreload: bool) !void {
            if (!bos.link_dynamic) {
                @panic("plugin system isn't enabled!");
            }
            const self: *@This() = @ptrCast(@alignCast(ptr));
            try self._plugin_system.register(
                self.context(),
                name,
                path,
                hotreload,
            );
        }

        /// Unregister plugin
        pub fn unregisterPlugin(ptr: *anyopaque, name: []const u8) !void {
            if (!bos.link_dynamic) {
                @panic("plugin system isn't enabled!");
            }
            const self: *@This() = @ptrCast(@alignCast(ptr));
            try self._plugin_system.unregister(self.context(), name);
        }

        ///  Force reload plugin
        pub fn forceReloadPlugin(ptr: *anyopaque, name: []const u8) !void {
            if (!bos.link_dynamic) {
                @panic("plugin system isn't enabled!");
            }
            const self: *@This() = @ptrCast(@alignCast(ptr));
            try self._plugin_system.forceReload(name);
        }
    };
}
