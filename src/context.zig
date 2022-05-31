const std = @import("std");
const sdl = @import("sdl");
const config = @import("config.zig");
const jok = @import("jok.zig");
const event = jok.event;
const audio = jok.audio;

// Import game object's declarations
const game = @import("game");
usingnamespace @import("game");

pub const log = std.log.scoped(.jok);

pub var perf_counter_freq: f64 = undefined;

/// Application context
pub const Context = struct {
    /// Default allocator
    default_allocator: std.mem.Allocator = undefined,

    /// Internal window
    window: sdl.Window,

    /// Renderer
    renderer: sdl.Renderer = undefined,
    is_software: bool = false,

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

    /// Residue of fps capping
    fps_limit_residue: u64 = 0,

    /// Number of seconds since launch/last-frame
    tick: f64 = 0,
    delta_tick: f32 = 0,
    last_perf_counter: u64 = 0,

    /// Frames stats
    fps: f32 = 0,
    average_cpu_time: f32 = 0,
    frame_counter: u32 = 0,
    last_fps_refresh_time: f64 = 0,

    /// Update frame stats
    pub inline fn updateFrameStats(self: *Context) bool {
        self.frame_counter += 1;
        if ((self.tick - self.last_fps_refresh_time) >= 1.0) {
            const t = self.tick - self.last_fps_refresh_time;
            self.fps = @floatCast(
                f32,
                @intToFloat(f64, self.frame_counter) / t,
            );
            self.average_cpu_time = (1.0 / self.fps) * 1000.0;
            self.last_fps_refresh_time = self.tick;
            self.frame_counter = 0;
            return true;
        }
        return false;
    }

    /// Flush graphics contents
    pub inline fn present(self: *Context, comptime fps_limit: config.FpsLimit) void {
        var counter_threshold: u64 = switch (fps_limit) {
            .none => 0,
            .auto => if (self.is_software) @divTrunc(@floatToInt(u64, perf_counter_freq), 30) else 0,
            .manual => |fps| @floatToInt(u64, perf_counter_freq) / @intCast(u64, fps),
        };
        if (counter_threshold > 0) {
            if (self.fps_limit_residue >= counter_threshold) {
                self.fps_limit_residue -= counter_threshold;
            } else {
                counter_threshold -= self.fps_limit_residue;
                while ((sdl.c.SDL_GetPerformanceCounter() - self.last_perf_counter) < counter_threshold) {
                    sdl.delay(1);
                }
                self.fps_limit_residue = sdl.c.SDL_GetPerformanceCounter() - self.last_perf_counter - counter_threshold;
            }
        }
        const counter = sdl.c.SDL_GetPerformanceCounter();
        self.delta_tick = @floatCast(
            f32,
            @intToFloat(f64, counter - self.last_perf_counter) / perf_counter_freq,
        );
        self.last_perf_counter = counter;
        self.tick += self.delta_tick;
        self.renderer.present();
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
