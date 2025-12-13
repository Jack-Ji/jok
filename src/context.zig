const std = @import("std");
const jok = @import("jok.zig");
const config = jok.config;
const font = jok.font;
const zaudio = jok.vendor.zaudio;

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
        supressDraw: *const fn (ctx: *anyopaque) void,
        isRunningSlow: *const fn (ctx: *anyopaque) bool,
        displayStats: *const fn (ctx: *anyopaque, opt: DisplayStats) void,
        debugPrint: *const fn (ctx: *anyopaque, text: []const u8, opt: DebugPrint) void,
        getDebugAtlas: *const fn (ctx: *anyopaque, size: u32) *font.Atlas,
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
