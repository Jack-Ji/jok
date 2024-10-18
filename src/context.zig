const std = @import("std");
const assert = std.debug.assert;
const builtin = @import("builtin");
const bos = @import("build_options");
const config = @import("config.zig");
const pp = @import("post_processing.zig");
const blend = @import("blend.zig");
const jok = @import("jok.zig");
const sdl = jok.sdl;
const io = jok.io;
const physfs = jok.physfs;
const font = jok.font;
const imgui = jok.imgui;
const plot = imgui.plot;
const miniaudio = jok.miniaudio;
const zmesh = jok.zmesh;
const w32 = @import("w32.zig");

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
        window: *const fn (ctx: *anyopaque) jok.Window,
        renderer: *const fn (ctx: *anyopaque) jok.Renderer,
        canvas: *const fn (ctx: *anyopaque) jok.Texture,
        audioEngine: *const fn (ctx: *anyopaque) *miniaudio.Engine,
        kill: *const fn (ctx: *anyopaque) void,
        getCanvasSize: *const fn (ctx: *anyopaque) jok.Size,
        setCanvasSize: *const fn (ctx: *anyopaque, size: ?jok.Size) anyerror!void,
        getCanvasArea: *const fn (ctx: *anyopaque) jok.Rectangle,
        getAspectRatio: *const fn (ctx: *anyopaque) f32,
        getDpiScale: *const fn (ctx: *anyopaque) f32,
        setPostProcessing: *const fn (ctx: *anyopaque, ppfn: pp.PostProcessingFn, data: ?*anyopaque) void,
        isRunningSlow: *const fn (ctx: *anyopaque) bool,
        displayStats: *const fn (ctx: *anyopaque, opt: DisplayStats) void,
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
    pub fn audioEngine(self: Context) *miniaudio.Engine {
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

    /// Set post-processing callback
    pub fn setPostProcessing(self: Context, ppfn: pp.PostProcessingFn, data: ?*anyopaque) void {
        return self.vtable.setPostProcessing(self.ctx, ppfn, data);
    }

    /// Whether game is running slow
    pub fn isRunningSlow(self: Context) bool {
        return self.vtable.isRunningSlow(self.ctx);
    }

    /// Display statistics
    pub fn displayStats(self: Context, opt: DisplayStats) void {
        return self.vtable.displayStats(self.ctx, opt);
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
    const PostProcessingType = pp.PostProcessingEffect(cfg);

    return struct {
        var gpa: AllocatorType = .{};
        const max_costs_num = 300;
        const CostDataType = jok.utils.ring.Ring(f32);

        /// Setup configuration
        _cfg: config.Config = cfg,

        // Application Context
        _ctx: Context = undefined,

        // Memory allocator
        _allocator: std.mem.Allocator = undefined,

        // Is running
        _running: bool = true,

        // Internal window
        _window: jok.Window = undefined,

        // High DPI stuff
        _default_dpi: f32 = undefined,
        _display_dpi: f32 = undefined,

        // Renderer instance
        _renderer: jok.Renderer = undefined,
        _is_software: bool = false,

        // Rendering target
        _canvas_texture: jok.Texture = undefined,
        _canvas_size: ?jok.Size = cfg.jok_canvas_size,
        _canvas_target_area: ?jok.Rectangle = null,

        // Post-processing
        _post_processing: PostProcessingType = undefined,
        _ppfn: ?pp.PostProcessingFn = null,
        _ppdata: ?*anyopaque = null,

        // Audio stuff
        _audio_ctx: *miniaudio.Context = undefined,
        _audio_engine: *miniaudio.Engine = undefined,

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
            var _allocator = cfg.jok_mem_allocator orelse gpa.allocator();
            var self = try _allocator.create(@This());
            self.* = .{};
            self._allocator = _allocator;
            self._ctx = self.context();

            // Init PhysicsFS
            physfs.init(self._allocator);

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
            self._audio_ctx = try miniaudio.sdl.init(self._ctx);
            var audio_config = miniaudio.Engine.Config.init();
            audio_config.resource_manager_vfs = &physfs.zaudio.vfs;
            self._audio_engine = try miniaudio.Engine.create(audio_config);

            // Init builtin debug font
            try font.DebugFont.init(self._allocator);
            _ = try font.DebugFont.getAtlas(
                self._ctx,
                @intFromFloat(@as(f32, @floatFromInt(cfg.jok_prebuild_atlas)) * getDpiScale(self)),
            );

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
            font.DebugFont.deinit();

            // Destroy audio engine
            self._audio_engine.destroy();
            miniaudio.sdl.deinit(self._audio_ctx);

            // Destroy 2d and 3d modules
            jok.j3d.deinit();
            jok.j2d.deinit();

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

            // Destory memory allocator
            if (gpa.deinit() == .leak) {
                @panic("jok: memory leaks happened!");
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
                .auto => if (self._is_software) @divTrunc(self._pc_freq, 30) else 0,
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
            self._renderer.clear(jok.Color.black) catch unreachable;
            {
                const pc_begin = sdl.SDL_GetPerformanceCounter();
                defer if (cfg.jok_detailed_frame_stats) {
                    const cost = @as(f32, @floatFromInt((sdl.SDL_GetPerformanceCounter() - pc_begin) * 1000)) /
                        @as(f32, @floatFromInt(self._pc_freq));
                    self._draw_cost = if (self._draw_cost > 0) (self._draw_cost + cost) / 2 else cost;
                };

                imgui.sdl.newFrame(self.context());
                defer imgui.sdl.draw(self.context());

                self._renderer.setTarget(self._canvas_texture) catch unreachable;
                defer {
                    self._renderer.setTarget(null) catch unreachable;
                    if (self._ppfn) |f| {
                        self._post_processing.applyFn(f, self._ppdata);
                        self._post_processing.render(self._renderer, self._canvas_texture);
                    } else {
                        self._renderer.drawTexture(self._canvas_texture, self._canvas_target_area) catch unreachable;
                    }
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
                if (cfg.jok_window_high_dpi) {
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
                const we = jok.Event.from(ne);
                if (cfg.jok_exit_on_recv_esc and we == .key_up and
                    we.key_up.scancode == .escape)
                {
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
                self._drawcall_count = imgui.sdl.dcstats.drawcall_count / self._frame_count;
                self._triangle_count = imgui.sdl.dcstats.triangle_count / self._frame_count;
                imgui.sdl.dcstats.clear();
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

            // Print system info
            log.info(
                \\System info:
                \\    Build Mode  : {s}
                \\    Log Level   : {s}
                \\    Zig Version : {}
                \\    CPU         : {s}
                \\    ABI         : {s}
                \\    SDL         : {}.{}.{}
                \\    Platform    : {s}
                \\    Memory      : {d}MB
                \\    App Dir     : {s} 
                \\    Data Dir    : {s} 
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
                    physfs.getPrefDir(self._ctx),
                },
            );

            if (sdl_version.major < 2 or (sdl_version.minor == 0 and sdl_version.patch < 18)) {
                log.err("SDL version too low, need at least 2.0.18", .{});
                return sdl.Error.SdlError;
            }

            if (cfg.jok_exit_on_recv_esc) {
                log.info("Press ESC to exit game", .{});
            }
        }

        /// Initialize SDL
        fn initSDL(self: *@This()) !void {
            if (sdl.SDL_Init(sdl.SDL_INIT_EVERYTHING) < 0) {
                log.err("Initialize SDL2 failed: {s}", .{sdl.SDL_GetError()});
                return sdl.Error.SdlError;
            }

            // Initialize dpi
            self._default_dpi = switch (builtin.target.os.tag) {
                .macos => 72.0,
                else => 96.0,
            };
            if (cfg.jok_window_high_dpi) {
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

            // Initialize blending methods
            blend.init();

            // Initialize i/o context
            io.init(self._ctx);

            // Initialize window
            self._window = try jok.Window.init(cfg, getDpiScale(self));

            // Initialize renderer
            self._renderer = try jok.Renderer.init(cfg, self._window);

            // Create drawing target
            self._canvas_texture = try self._renderer.createTarget(.{ .size = self._canvas_size });
            self._post_processing = try PostProcessingType.init(self._allocator);
            self.updateCanvasTargetArea();
        }

        /// Deinitialize SDL
        fn deinitSDL(self: *@This()) void {
            self._post_processing.destroy();
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
                    .setPostProcessing = setPostProcessing,
                    .isRunningSlow = isRunningSlow,
                    .displayStats = displayStats,
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
            self._post_processing.onCanvasChange(self._renderer, self._canvas_target_area);
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
        fn audioEngine(ptr: *anyopaque) *miniaudio.Engine {
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

        /// Set post-processing callback
        pub fn setPostProcessing(ptr: *anyopaque, ppfn: pp.PostProcessingFn, data: ?*anyopaque) void {
            const self: *@This() = @ptrCast(@alignCast(ptr));
            self._ppfn = ppfn;
            self._ppdata = data;
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
                imgui.text("GPU Enabled: {}", .{!self._is_software});
                imgui.text("V-Sync Enabled: {}", .{rdinfo.flags & sdl.SDL_RENDERER_PRESENTVSYNC != 0});
                imgui.text("Optimize Mode: {s}", .{@tagName(builtin.mode)});
                imgui.separator();
                imgui.text("Duration: {}", .{std.fmt.fmtDuration(@intFromFloat(self._seconds_real * 1e9))});
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
