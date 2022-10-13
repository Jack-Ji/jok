const std = @import("std");
const assert = std.debug.assert;
const sdl = @import("sdl");
const config = @import("config.zig");
const jok = @import("jok.zig");

pub const log = std.log.scoped(.jok);

/// Application context
pub const Context = struct {
    // Default allocator
    allocator: std.mem.Allocator = undefined,

    // Internal window
    window: sdl.Window,

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

    // Elapsed time of game (seconds)
    tick: f64 = 0,

    // Delta time between update/draw (seconds)
    delta_tick: f32 = 0,

    // Frames stats
    fps: f32 = 0,
    average_cpu_time: f32 = 0,

    _last_pc: u64 = 0,
    _accumulated_pc: u64 = 0,
    _pc_freq: f64 = 0,

    _frame_count: u32 = 0,
    _last_fps_refresh_time: f64 = 0,

    /// Internal game loop
    pub inline fn internalLoop(
        self: *Context,
        comptime fps_limit: config.FpsLimit,
        comptime updateFn: *const fn (ctx: *jok.Context) anyerror!void,
        comptime drawFn: *const fn (ctx: *jok.Context) anyerror!void,
    ) void {
        const fps_pc_threshold: u64 = switch (fps_limit) {
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
            const fps_delta_tick = @floatCast(
                f32,
                @intToFloat(f64, fps_pc_threshold) / self._pc_freq,
            );
            while (self._accumulated_pc >= fps_pc_threshold) {
                step_count += 1;
                self._accumulated_pc -= fps_pc_threshold;
                self.delta_tick = fps_delta_tick;
                self.tick += self.delta_tick;

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
            self.delta_tick = @intToFloat(f32, step_count) * fps_delta_tick;
        } else {
            // Perform one update
            const pc = sdl.c.SDL_GetPerformanceCounter();
            self.delta_tick = @floatCast(
                f32,
                @intToFloat(f64, pc - self._last_pc) / self._pc_freq,
            );
            self._last_pc = pc;
            self.tick += self.delta_tick;

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

    /// Update frame stats
    pub inline fn updateFrameStats(self: *Context) bool {
        self._frame_count += 1;
        if ((self.tick - self._last_fps_refresh_time) >= 1.0) {
            const t = self.tick - self._last_fps_refresh_time;
            self.fps = @floatCast(
                f32,
                @intToFloat(f64, self._frame_count) / t,
            );
            self.average_cpu_time = (1.0 / self.fps) * 1000.0;
            self._last_fps_refresh_time = self.tick;
            self._frame_count = 0;
            return true;
        }
        return false;
    }

    /// Get renderer's name
    pub inline fn getRendererName(self: *Context) []const u8 {
        return if (self.is_software) "soft" else "hard";
    }

    /// Kill app
    pub fn kill(self: *Context) void {
        self.quit = true;
    }

    /// Poll event
    pub fn pollEvent(self: *Context) ?sdl.Event {
        _ = self;
        return sdl.pollEvent();
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
};
