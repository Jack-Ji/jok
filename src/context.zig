//! Application context management.
//!
//! This module provides the Context type, which serves as the central interface
//! for accessing all engine functionality. The Context uses a vtable-based design
//! to provide a stable API while allowing different implementations.
//!
//! The Context provides access to:
//! - Configuration and setup
//! - Memory allocation
//! - I/O and event handling
//! - Timing and performance metrics
//! - Window and renderer management
//! - Resource loading (textures, shaders)
//! - Audio engine
//! - Debug utilities

const std = @import("std");
const jok = @import("jok.zig");
const config = jok.config;
const Point = jok.j2d.geom.Point;
const Size = jok.j2d.geom.Size;
const Rectangle = jok.j2d.geom.Rectangle;
const font = jok.font;
const zaudio = jok.vendor.zaudio;

/// Application context providing access to all engine functionality.
///
/// This is the primary interface for interacting with the jok engine.
/// It uses a vtable pattern to provide a stable API across different
/// implementations and allows for easy mocking in tests.
///
/// The context is typically passed to all game callbacks (init, update, draw)
/// and provides access to all engine subsystems.
pub const Context = struct {
    ctx: *anyopaque,
    vtable: struct {
        cfg: *const fn (ctx: *anyopaque) config.Config,
        args: *const fn (ctx: *anyopaque) std.process.Args,
        allocator: *const fn (ctx: *anyopaque) std.mem.Allocator,
        io: *const fn (ctx: *anyopaque) std.Io,
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
        getCanvasSize: *const fn (ctx: *anyopaque) Size,
        setCanvasSize: *const fn (ctx: *anyopaque, size: ?Size) anyerror!void,
        getCanvasArea: *const fn (ctx: *anyopaque) Rectangle,
        getAspectRatio: *const fn (ctx: *anyopaque) f32,
        suppressDraw: *const fn (ctx: *anyopaque) void,
        isRunningSlow: *const fn (ctx: *anyopaque) bool,
        loadTexture: *const fn (ctx: *anyopaque, sub_path: [:0]const u8, access: jok.Texture.Access, flip: bool) anyerror!jok.Texture,
        loadShader: *const fn (ctx: *anyopaque, sub_path: [:0]const u8, entrypoint: ?[:0]const u8, format: ?jok.ShaderFormat) anyerror!jok.PixelShader,
        setPostEffect: *const fn (ctx: *anyopaque, shader: ?jok.PixelShader) void,
        displayStats: *const fn (ctx: *anyopaque, opt: DisplayStats) void,
        debugPrint: *const fn (ctx: *anyopaque, text: []const u8, opt: DebugPrint) void,
        getDebugAtlas: *const fn (ctx: *anyopaque, size: u32) *font.Atlas,
    },

    /// Get setup configuration
    pub fn cfg(self: Context) config.Config {
        return self.vtable.cfg(self.ctx);
    }

    /// Get command-line arguments passed to app
    pub fn args(self: Context) std.process.Args {
        return self.vtable.args(self.ctx);
    }

    /// Get memory allocator
    pub fn allocator(self: Context) std.mem.Allocator {
        return self.vtable.allocator(self.ctx);
    }

    /// Get io interface
    pub fn io(self: Context) std.Io {
        return self.vtable.io(self.ctx);
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
    pub fn getCanvasSize(self: Context) Size {
        return self.vtable.getCanvasSize(self.ctx);
    }

    /// Set size of canvas (null means same as current framebuffer)
    pub fn setCanvasSize(self: Context, size: ?Size) !void {
        return self.vtable.setCanvasSize(self.ctx, size);
    }

    /// Get canvas drawing area in framebuffer
    pub fn getCanvasArea(self: Context) Rectangle {
        return self.vtable.getCanvasArea(self.ctx);
    }

    /// Get aspect ratio of drawing area
    pub fn getAspectRatio(self: Context) f32 {
        return self.vtable.getAspectRatio(self.ctx);
    }

    /// Suppress drawcall of current frame
    pub fn suppressDraw(self: Context) void {
        return self.vtable.suppressDraw(self.ctx);
    }

    /// Whether game is running slow
    pub fn isRunningSlow(self: Context) bool {
        return self.vtable.isRunningSlow(self.ctx);
    }

    /// Load texture from path to file
    pub fn loadTexture(self: Context, sub_path: [:0]const u8, access: jok.Texture.Access, flip: bool) anyerror!jok.Texture {
        return self.vtable.loadTexture(self.ctx, sub_path, access, flip);
    }

    /// Load shader from path to file
    pub fn loadShader(self: Context, sub_path: [:0]const u8, entrypoint: ?[:0]const u8, format: ?jok.ShaderFormat) anyerror!jok.PixelShader {
        return self.vtable.loadShader(self.ctx, sub_path, entrypoint, format);
    }

    /// Set post effect shader
    pub fn setPostEffect(self: Context, shader: ?jok.PixelShader) void {
        return self.vtable.setPostEffect(self.ctx, shader);
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

/// Options for displaying performance statistics.
///
/// Controls the appearance and behavior of the debug statistics overlay
/// that shows FPS, frame time, and other performance metrics.
pub const DisplayStats = struct {
    /// Whether the stats window can be moved by dragging
    movable: bool = false,
    /// Whether the stats window can be collapsed
    collapsible: bool = false,
    /// Width of the stats window in pixels
    width: f32 = 250,
    /// How long to display stats (in seconds)
    duration: u32 = 15,
};

/// Options for debug text printing.
///
/// Controls the appearance of debug text rendered to the screen.
pub const DebugPrint = struct {
    /// Position to render the text
    pos: Point = .origin,
    /// Color of the text
    color: jok.Color = .white,
};
