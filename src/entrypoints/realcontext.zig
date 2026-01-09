const std = @import("std");
const assert = std.debug.assert;
const builtin = @import("builtin");
const jok = @import("jok");
const config = jok.config;
const io = jok.io;
const font = jok.font;
const sdl = jok.vendor.sdl;
const physfs = jok.vendor.physfs;
const zgui = jok.vendor.zgui;
const plot = zgui.plot;
const zaudio = jok.vendor.zaudio;
const zmesh = jok.vendor.zmesh;
const log = std.log.scoped(.jok);

/// Context generator
pub fn JokContext(comptime cfg: config.Config) type {
    const DebugAllocatorType = std.heap.DebugAllocator(.{
        .stack_trace_frames = 3,
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

        // IO backend
        _io_backend: std.Io.Threaded = undefined,

        // Main thread id
        _main_thread_id: std.Thread.Id = undefined,

        // Application Context
        _ctx: jok.Context = undefined,

        // Is running
        _running: bool = true,

        // Internal window
        _window: jok.Window = undefined,

        // Renderer instance
        _renderer: jok.Renderer = undefined,

        // Rendering target
        _canvas_texture: jok.Texture = undefined,
        _canvas_size: ?jok.Size = cfg.jok_canvas_size,
        _canvas_target_area: ?jok.Rectangle = null,

        // Drawcall supress
        _supress_draw: bool = false,

        // Audio Engine
        _audio_engine: *zaudio.Engine = undefined,

        // Debug printing
        _debug_font_size: u32 = undefined,
        _debug_print_vertices: std.array_list.Managed(jok.Vertex) = undefined,
        _debug_print_indices: std.array_list.Managed(u32) = undefined,

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
            self._io_backend = .init_single_threaded;
            self._main_thread_id = std.Thread.getCurrentId();
            self._ctx = self.context();

            // Init PhysicsFS
            physfs.init(self._allocator);
            if (builtin.cpu.arch.isWasm()) {
                try physfs.mount("/", "", true);
            }

            // Init SDL window and renderer
            try self.initSDL();

            // Init zgui
            zgui.sdl.init(self._ctx, cfg.jok_imgui_ini_file);

            // Init audio engine
            self._audio_engine = try zaudio.sdl.init(self._ctx);

            // Init zmesh
            zmesh.init(self._allocator);

            // Init builtin debug font
            try font.DebugFont.init(self._allocator);
            self._debug_font_size = @intFromFloat(@as(f32, @floatFromInt(cfg.jok_prebuild_atlas)));
            self._debug_print_vertices = .init(self._allocator);
            self._debug_print_indices = .init(self._allocator);
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

            // Destroy zmesh
            zmesh.deinit();

            // Destroy audio engine
            zaudio.sdl.deinit();

            // Destroy zgui
            zgui.sdl.deinit();

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
            comptime eventFn: *const fn (jok.Context, jok.Event) anyerror!void,
            comptime updateFn: *const fn (jok.Context) anyerror!void,
            comptime drawFn: *const fn (jok.Context) anyerror!void,
        ) void {
            const pc_threshold: u64 = switch (cfg.jok_fps_limit) {
                .none => 0,
                .auto => if (cfg.jok_renderer_type == .software) @divTrunc(self._pc_freq, 30) else 0,
                .manual => |_fps| self._pc_freq / @as(u64, _fps),
            };

            // Process input
            self._event(eventFn);

            // Update game
            if (pc_threshold > 0) {
                while (true) {
                    const pc = sdl.SDL_GetPerformanceCounter();
                    self._pc_accumulated += pc - self._pc_last;
                    self._pc_last = pc;
                    if (self._pc_accumulated >= pc_threshold) {
                        break;
                    }
                    const remaining_ns: u64 = ((pc_threshold - self._pc_accumulated) * 1_000_000_000) / self._pc_freq;
                    if (remaining_ns > 1_000_000) { // Only sleep if >1 ms
                        sdl.SDL_DelayNS(remaining_ns);
                        continue;
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

                    self._update(updateFn);
                }
                assert(step_count > 0);

                // Update frame lag
                self._frame_lag += @max(0, step_count - 1);
                if (self._running_slow) {
                    if (self._frame_lag == 0) {
                        self._running_slow = false;
                    } else if (self._frame_lag > 10) {
                        // Supress rendering, give `update` chance to catch up
                        self._supress_draw = true;
                    }
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

                self._update(updateFn);
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

                defer {
                    self._renderer.present();
                    if (cfg.jok_renderer_type == .software) {
                        _ = sdl.SDL_UpdateWindowSurface(self._window.ptr);
                    }
                }

                zgui.sdl.newFrame(self.context());
                defer zgui.sdl.draw(self.context());

                self._renderer.clear(cfg.jok_framebuffer_color) catch unreachable;
                if (cfg.jok_renderer_type != .software) {
                    self._renderer.setTarget(self._canvas_texture) catch unreachable;
                }
                defer if (cfg.jok_renderer_type != .software) {
                    self._renderer.setTarget(null) catch unreachable;
                    self._renderer.drawTexture(
                        self._canvas_texture,
                        null,
                        self._canvas_target_area,
                    ) catch unreachable;
                };

                drawFn(self._ctx) catch |err| {
                    log.err("Got error in `draw`: {s}", .{@errorName(err)});
                    if (@errorReturnTrace()) |trace| {
                        std.debug.dumpStackTrace(trace);
                        kill(self);
                        return;
                    }
                };
            }

            self._updateFrameStats();
        }

        inline fn _event(
            self: *@This(),
            comptime eventFn: *const fn (jok.Context, jok.Event) anyerror!void,
        ) void {
            while (io.pollNativeEvent()) |ne| {
                // ImGui event processing
                _ = zgui.sdl.processEvent(ne);

                // Game event processing
                const we = jok.Event.from(ne, self._ctx);
                if (!builtin.cpu.arch.isWasm() and cfg.jok_exit_on_recv_esc and we == .key_up and we.key_up.scancode == .escape) {
                    kill(self);
                } else if (cfg.jok_exit_on_recv_quit and we == .quit) {
                    kill(self);
                } else {
                    if (cfg.jok_renderer_type != .software and we == .window_resized) {
                        if (self._canvas_size == null) {
                            self._canvas_texture.destroy();
                            self._canvas_texture = self._renderer.createTarget(.{
                                .scale_mode = cfg.jok_canvas_scale_mode,
                            }) catch unreachable;
                        }
                        self.updateCanvasTargetArea();
                    }
                    if (cfg.jok_window_high_pixel_density and (we == .window_pixel_size_changed or we == .window_display_scale_changed)) {
                        self.updateRenderScale();
                    }

                    // Passed to game code
                    eventFn(self._ctx, we) catch |err| {
                        log.err("Got error in `event`: {s}", .{@errorName(err)});
                        if (@errorReturnTrace()) |trace| {
                            std.debug.dumpStackTrace(trace);
                            kill(self);
                            return;
                        }
                    };
                }
            }
        }

        inline fn _update(
            self: *@This(),
            comptime updateFn: *const fn (jok.Context) anyerror!void,
        ) void {
            const pc_begin = sdl.SDL_GetPerformanceCounter();
            defer if (cfg.jok_detailed_frame_stats) {
                const cost = @as(f32, @floatFromInt((sdl.SDL_GetPerformanceCounter() - pc_begin) * 1000)) /
                    @as(f32, @floatFromInt(self._pc_freq));
                self._update_cost = if (self._update_cost > 0) (self._update_cost + cost) / 2 else cost;
            };

            updateFn(self._ctx) catch |err| {
                log.err("Got error in `update`: {s}", .{@errorName(err)});
                if (@errorReturnTrace()) |trace| {
                    std.debug.dumpStackTrace(trace);
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
            const S = struct {
                fn fmtSdlDrivers(
                    current_driver: [*:0]const u8,
                    num_drivers: c_int,
                    getDriver: *const fn (c_int) callconv(.c) ?[*:0]const u8,
                ) FormatSdlDrivers {
                    return .{
                        .current_driver = current_driver,
                        .num_drivers = num_drivers,
                        .getDriver = getDriver,
                    };
                }

                const FormatSdlDrivers = struct {
                    current_driver: [*:0]const u8,
                    num_drivers: c_int,
                    getDriver: *const fn (c_int) callconv(.c) ?[*:0]const u8,

                    pub fn format(fcontext: FormatSdlDrivers, writer: *std.Io.Writer) std.Io.Writer.Error!void {
                        var i: c_int = 0;
                        while (i < fcontext.num_drivers) : (i += 1) {
                            if (i != 0) {
                                try writer.writeAll(", ");
                            }
                            const driver = fcontext.getDriver(i).?;
                            try writer.writeAll(std.mem.span(driver));
                            if (std.mem.orderZ(u8, fcontext.current_driver, driver) == .eq) {
                                try writer.writeAll(" (current)");
                            }
                        }
                    }
                };
            };

            const target = builtin.target;
            const ram_size = sdl.SDL_GetSystemRAM();
            const info = try self._renderer.getInfo();

            // Print system info
            std.debug.print(
                \\System info:
                \\    Build Mode       : {s}
                \\    Log Level        : {s}
                \\    Zig Version      : {f}
                \\    CPU              : {s}
                \\    ABI              : {s}
                \\    SDL              : {d}.{d}.{d}
                \\    Platform         : {s}
                \\    Memory           : {d}MB
                \\    App Dir          : {s} 
                \\    Audio Drivers    : {f}
                \\    Video Drivers    : {f}
                \\    Graphics API     : {s}
                \\    Vertical Sync    : {d}
                \\    Max Texture Size : {d}
                \\
                \\
            ,
                .{
                    @tagName(builtin.mode),
                    @tagName(cfg.jok_log_level),
                    builtin.zig_version,
                    @tagName(target.cpu.arch),
                    @tagName(target.abi),
                    sdl.SDL_MAJOR_VERSION,
                    sdl.SDL_MINOR_VERSION,
                    sdl.SDL_MICRO_VERSION,
                    @tagName(target.os.tag),
                    ram_size,
                    physfs.getBaseDir(),
                    S.fmtSdlDrivers(
                        sdl.SDL_GetCurrentAudioDriver().?,
                        sdl.SDL_GetNumAudioDrivers(),
                        sdl.SDL_GetAudioDriver,
                    ),
                    S.fmtSdlDrivers(
                        sdl.SDL_GetCurrentVideoDriver().?,
                        sdl.SDL_GetNumVideoDrivers(),
                        sdl.SDL_GetVideoDriver,
                    ),
                    info.name,
                    info.vsync,
                    info.max_texture_size,
                },
            );
        }

        /// Initialize SDL
        fn initSDL(self: *@This()) !void {
            if (cfg.jok_headless) {
                _ = sdl.SDL_SetHint(sdl.SDL_HINT_VIDEO_DRIVER, "offscreen");
            }
            if (!cfg.jok_window_ime_ui) {
                _ = sdl.SDL_SetHint(sdl.SDL_HINT_IME_IMPLEMENTED_UI, "composition,candidates");
            }

            // Initialize custom memory allocator
            MemAdapter.init(self._allocator);
            if (!sdl.SDL_SetMemoryFunctions(
                MemAdapter.alloc,
                MemAdapter.calloc,
                MemAdapter.realloc,
                MemAdapter.free,
            )) {
                log.err("Initialize custom allocator for SDL3 failed: {s}", .{sdl.SDL_GetError()});
                return error.SdlError;
            }

            var init_flags = sdl.SDL_INIT_AUDIO |
                sdl.SDL_INIT_VIDEO |
                sdl.SDL_INIT_JOYSTICK |
                sdl.SDL_INIT_GAMEPAD |
                sdl.SDL_INIT_EVENTS |
                sdl.SDL_INIT_SENSOR;
            if (builtin.cpu.arch.isWasm()) {
                init_flags |= sdl.SDL_INIT_HAPTIC;
            }
            if (!sdl.SDL_Init(init_flags)) {
                log.err("Initialize SDL3 failed: {s}", .{sdl.SDL_GetError()});
                return error.SdlError;
            }

            // Initialize window and renderer
            self._window = try jok.Window.init(self._ctx);
            self._renderer = try jok.Renderer.init(self._ctx);

            // Check and print system info
            try self.checkSys();

            // Init offline drawing target
            if (cfg.jok_renderer_type != .software) {
                self._canvas_texture = try self._renderer.createTarget(.{
                    .size = self._canvas_size,
                    .scale_mode = cfg.jok_canvas_scale_mode,
                });
                self.updateCanvasTargetArea();
            }

            // Init renderer's scaling
            if (cfg.jok_window_high_pixel_density) {
                self.updateRenderScale();
            }

            if (!builtin.cpu.arch.isWasm() and !cfg.jok_headless and cfg.jok_exit_on_recv_esc) {
                log.info("Press ESC to exit game", .{});
            }
        }

        /// Deinitialize SDL
        fn deinitSDL(self: *@This()) void {
            if (cfg.jok_renderer_type != .software) {
                self._canvas_texture.destroy();
            }
            self._renderer.destroy();
            self._window.destroy();
            sdl.SDL_Quit();
            MemAdapter.deinit();
        }

        /// Get type-erased context for application
        pub fn context(self: *@This()) jok.Context {
            return .{
                .ctx = self,
                .vtable = .{
                    .cfg = getcfg,
                    .allocator = allocator,
                    .io = getIo,
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
                    .supressDraw = supressDraw,
                    .isRunningSlow = isRunningSlow,
                    .loadTexture = loadTexture,
                    .displayStats = displayStats,
                    .debugPrint = debugPrint,
                    .getDebugAtlas = getDebugAtlas,
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
                if (cfg.jok_canvas_integer_scaling) {
                    const scale = @floor(@min(vpw / rw, vph / rh));
                    const width = scale * rw;
                    const height = scale * rh;
                    self._canvas_target_area = jok.Rectangle{
                        .x = (vpw - width) / 2.0,
                        .y = (vph - height) / 2.0,
                        .width = width,
                        .height = height,
                    };
                } else {
                    self._canvas_target_area = if (rw * vph < rh * vpw)
                        jok.Rectangle{
                            .x = (vpw - rw * vph / rh) / 2.0,
                            .y = 0,
                            .width = rw * vph / rh,
                            .height = @floatFromInt(fbsize.height),
                        }
                    else
                        jok.Rectangle{
                            .x = 0,
                            .y = (vph - rh * vpw / rw) / 2.0,
                            .width = @floatFromInt(fbsize.width),
                            .height = rh * vpw / rw,
                        };
                }
            } else {
                self._canvas_target_area = null;
            }
        }

        /// Update scale of renderer according to pixel density
        inline fn updateRenderScale(self: *@This()) void {
            const scale = sdl.SDL_GetWindowDisplayScale(self._window.ptr);
            if (!sdl.SDL_SetRenderScale(self._renderer.ptr, scale, scale)) {
                log.err("Change renderer's scale failed: {s}", .{sdl.SDL_GetError()});
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

        /// Get io backend
        fn getIo(ptr: *anyopaque) std.Io {
            const self: *@This() = @ptrCast(@alignCast(ptr));
            return self._io_backend.ioBasic();
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
            if (cfg.jok_renderer_type == .software) return .{ .ptr = null };
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
            if (cfg.jok_renderer_type != .software) {
                if (self._canvas_size) |sz| return sz;
            }
            return self._renderer.getOutputSize() catch unreachable;
        }

        /// Set size of canvas (null means same as current framebuffer)
        fn setCanvasSize(ptr: *anyopaque, size: ?jok.Size) !void {
            assert(size == null or (size.?.width > 0 and size.?.width > 0));
            const self: *@This() = @ptrCast(@alignCast(ptr));
            if (cfg.jok_renderer_type == .software) @panic("Unsupported when using software renderer!");
            self._canvas_texture.destroy();
            self._canvas_size = size;
            self._canvas_texture = try self._renderer.createTarget(.{
                .size = self._canvas_size,
                .scale_mode = cfg.jok_canvas_scale_mode,
            });
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

        /// Load texture from path to file
        pub fn loadTexture(ptr: *anyopaque, sub_path: [:0]const u8, access: jok.Texture.Access, flip: bool) !jok.Texture {
            const self: *@This() = @ptrCast(@alignCast(ptr));
            if (cfg.jok_enable_physfs) {
                const handle = try physfs.open(sub_path, .read);
                defer handle.close();

                const filedata = try handle.readAllAlloc(self._allocator);
                defer self._allocator.free(filedata);

                return try self._renderer.createTextureFromFileData(
                    filedata,
                    access,
                    flip,
                );
            } else {
                const filedata = try std.Io.Dir.cwd().readFileAlloc(
                    self._io_backend.io(),
                    std.mem.sliceTo(sub_path, 0),
                    self._allocator,
                    .unlimited,
                );
                defer self._allocator.free(filedata);

                return try self._renderer.createTextureFromFileData(
                    filedata,
                    access,
                    flip,
                );
            }
        }

        /// Display frame statistics
        fn displayStats(ptr: *anyopaque, opt: jok.context.DisplayStats) void {
            const self: *@This() = @ptrCast(@alignCast(ptr));
            const rdinfo = self._renderer.getInfo() catch unreachable;
            const ws = self._window.getSize();
            const cs = getCanvasSize(ptr);
            const scale = sdl.SDL_GetWindowDisplayScale(self._window.ptr);
            const fbsize = self._renderer.getOutputSize() catch unreachable;
            zgui.setNextWindowBgAlpha(.{ .alpha = 0.7 });
            zgui.setNextWindowPos(.{
                .x = @floatFromInt(ws.width),
                .y = 0,
                .pivot_x = 1,
                .cond = if (opt.movable) .once else .always,
            });
            zgui.setNextWindowSize(.{ .w = opt.width, .h = 0, .cond = .always });
            if (zgui.begin("Frame Statistics", .{
                .flags = .{
                    .no_title_bar = !opt.collapsible,
                    .no_resize = true,
                    .always_auto_resize = true,
                },
            })) {
                zgui.text("Optimize Mode: {s}", .{@tagName(builtin.mode)});
                zgui.text("Window Size: {d:.0}x{d:.0}", .{ ws.width, ws.height });
                zgui.text("Renderer Type: {s}", .{cfg.jok_renderer_type.str()});
                zgui.text("Renderer Scale: {d:.2}", .{scale});
                zgui.text("Canvas Size: {d:.0}x{d:.0}", .{ cs.width, cs.height });
                zgui.text("Canvas Scale: {d:.2}", .{
                    if (self._canvas_target_area) |a|
                        a.width / cs.getWidthFloat()
                    else
                        fbsize.getWidthFloat() / cs.getWidthFloat(),
                });
                zgui.text("V-Sync Enabled: {}", .{rdinfo.vsync > 0});
                zgui.separator();
                zgui.text("Duration: {D}", .{@as(u64, @intFromFloat(self._seconds_real * 1e9))});
                if (self._running_slow) {
                    zgui.textColored(.{ 1, 0, 0, 1 }, "FPS: {d:.1} {s}", .{ self._fps, cfg.jok_fps_limit.str() });
                    zgui.textColored(.{ 1, 0, 0, 1 }, "CPU: {d:.1}ms", .{1000.0 / self._fps});
                } else {
                    zgui.text("FPS: {d:.1} {s}", .{ self._fps, cfg.jok_fps_limit.str() });
                    zgui.text("CPU: {d:.1}ms", .{1000.0 / self._fps});
                }
                if (builtin.mode == .Debug) {
                    zgui.text("Memory: {Bi:.3}", .{debug_allocator.total_requested_bytes});
                }
                zgui.text("Draw Calls: {d}", .{self._drawcall_count});
                zgui.text("Triangles: {d}", .{self._triangle_count});

                if (cfg.jok_detailed_frame_stats and self._seconds_real > 1) {
                    zgui.separator();
                    if (plot.beginPlot(
                        zgui.formatZ("Costs of Update/Draw ({}s)", .{opt.duration}),
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
            zgui.end();
        }

        /// Display text
        pub fn debugPrint(ptr: *anyopaque, text: []const u8, opt: jok.context.DebugPrint) void {
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
    };
}

///////////////////// Custom Memory Allocator for SDL /////////////////////
const MemAdapter = struct {
    var mem_allocator: std.mem.Allocator = undefined;
    var mem_allocations: std.AutoHashMap(usize, usize) = undefined;
    var mem_mutex: std.Thread.Mutex = .{};
    const mem_alignment: std.mem.Alignment = .@"16";

    fn init(allocator: std.mem.Allocator) void {
        mem_allocator = allocator;
        mem_allocations = std.AutoHashMap(usize, usize).init(allocator);
        mem_allocations.ensureTotalCapacity(1024) catch @panic("out of memory");
    }

    fn deinit() void {
        var it = mem_allocations.iterator();
        while (it.next()) |kv| {
            const mem = @as([*]align(mem_alignment.toByteUnits()) u8, @ptrFromInt(kv.key_ptr.*))[0..kv.value_ptr.*];
            mem_allocator.free(mem);
        }
        mem_allocations.deinit();
    }

    fn alloc(size: usize) callconv(.c) ?*anyopaque {
        mem_mutex.lock();
        defer mem_mutex.unlock();

        const mem = mem_allocator.alignedAlloc(
            u8,
            mem_alignment,
            size,
        ) catch @panic("out of memory");

        @memset(mem, 0);

        mem_allocations.put(@intFromPtr(mem.ptr), size) catch @panic("out of memory");

        return mem.ptr;
    }

    fn calloc(nmemb: usize, size: usize) callconv(.c) ?*anyopaque {
        return alloc(nmemb * size);
    }

    fn realloc(maybe_ptr: ?*anyopaque, size: usize) callconv(.c) ?*anyopaque {
        mem_mutex.lock();
        defer mem_mutex.unlock();

        const old_mem = if (maybe_ptr) |ptr| BLK: {
            const kv = mem_allocations.fetchRemove(@intFromPtr(ptr)).?;
            const old_size = kv.value;
            break :BLK @as([*]align(mem_alignment.toByteUnits()) u8, @ptrCast(@alignCast(ptr)))[0..old_size];
        } else null;

        const new_mem = if (old_mem) |m| mem_allocator.realloc(
            m,
            size,
        ) catch @panic("out of memory") else mem_allocator.alignedAlloc(
            u8,
            mem_alignment,
            size,
        ) catch @panic("out of memory");

        mem_allocations.put(@intFromPtr(new_mem.ptr), size) catch @panic("out of memory");

        return new_mem.ptr;
    }

    fn free(maybe_ptr: ?*anyopaque) callconv(.c) void {
        if (maybe_ptr) |ptr| {
            mem_mutex.lock();
            defer mem_mutex.unlock();

            if (mem_allocations.fetchRemove(@intFromPtr(ptr))) |kv| {
                const size = kv.value;
                const mem = @as([*]align(mem_alignment.toByteUnits()) u8, @ptrCast(@alignCast(ptr)))[0..size];
                mem_allocator.free(mem);
            }
        }
    }
};
