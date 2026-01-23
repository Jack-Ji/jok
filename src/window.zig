//! Window management.
//!
//! This module provides window creation and management functionality through SDL3.
//! It handles window properties like size, position, fullscreen mode, and various
//! window states.
//!
//! Features:
//! - Window creation with customizable properties
//! - Fullscreen and windowed modes
//! - Window resizing and positioning
//! - Mouse mode control (normal, hidden, relative)
//! - Text input management
//! - High DPI support

const std = @import("std");
const builtin = @import("builtin");
const jok = @import("jok.zig");
const sdl = jok.vendor.sdl;
const log = std.log.scoped(.jok);

/// Window wrapper providing access to SDL window functionality.
///
/// Manages a single application window with support for various display modes,
/// input handling, and window state management.
pub const Window = struct {
    ptr: *sdl.SDL_Window,
    cfg: jok.config.Config,

    /// Initialize a new window from context configuration.
    ///
    /// **WARNING: This function is automatically called by jok.Context during initialization.**
    /// **DO NOT call this function directly from game code.**
    /// The window is accessible via `ctx.window()` after context creation.
    ///
    /// Creates and configures a window based on the settings in the provided context.
    /// Handles platform-specific initialization including WebAssembly support.
    ///
    /// Returns: Initialized window or error if creation fails
    pub fn init(ctx: jok.Context) !Window {
        const cfg = ctx.cfg();
        const props = sdl.SDL_CreateProperties();
        _ = sdl.SDL_SetStringProperty(props, sdl.SDL_PROP_WINDOW_CREATE_TITLE_STRING, cfg.jok_window_title);
        _ = sdl.SDL_SetBooleanProperty(props, sdl.SDL_PROP_WINDOW_CREATE_HIDDEN_BOOLEAN, cfg.jok_headless);
        _ = sdl.SDL_SetBooleanProperty(props, sdl.SDL_PROP_WINDOW_CREATE_BORDERLESS_BOOLEAN, cfg.jok_window_borderless);
        _ = sdl.SDL_SetBooleanProperty(props, sdl.SDL_PROP_WINDOW_CREATE_HIGH_PIXEL_DENSITY_BOOLEAN, cfg.jok_window_high_pixel_density);
        if (cfg.jok_renderer_type != .software) {
            _ = sdl.SDL_SetBooleanProperty(props, sdl.SDL_PROP_WINDOW_CREATE_RESIZABLE_BOOLEAN, true);
        }
        var size = jok.Size{ .width = 800, .height = 600 };
        switch (cfg.jok_window_size) {
            .maximized => {
                _ = sdl.SDL_SetBooleanProperty(props, sdl.SDL_PROP_WINDOW_CREATE_MAXIMIZED_BOOLEAN, true);
            },
            .fullscreen => {
                if (builtin.cpu.arch.isWasm()) {
                    // TODO no property is provided yet
                } else {
                    _ = sdl.SDL_SetBooleanProperty(props, sdl.SDL_PROP_WINDOW_CREATE_FULLSCREEN_BOOLEAN, true);
                }
            },
            .custom => |sz| size = sz,
        }
        _ = sdl.SDL_SetNumberProperty(props, sdl.SDL_PROP_WINDOW_CREATE_WIDTH_NUMBER, @intCast(size.width));
        _ = sdl.SDL_SetNumberProperty(props, sdl.SDL_PROP_WINDOW_CREATE_HEIGHT_NUMBER, @intCast(size.height));
        const ptr = sdl.SDL_CreateWindowWithProperties(props);
        if (ptr == null) {
            log.err("Create window failed: {s}", .{sdl.SDL_GetError()});
            return error.SdlError;
        }

        // Mouse mode
        switch (cfg.jok_window_mouse_mode) {
            .normal => {
                if (cfg.jok_window_size == .fullscreen) {
                    _ = sdl.SDL_SetWindowMouseGrab(ptr, false);
                    _ = sdl.SDL_SetWindowRelativeMouseMode(ptr, true);
                    _ = sdl.SDL_HideCursor();
                } else {
                    _ = sdl.SDL_SetWindowRelativeMouseMode(ptr, false);
                    _ = sdl.SDL_ShowCursor();
                }
            },
            .hide_in_window => {
                if (cfg.jok_window_size == .fullscreen) {
                    _ = sdl.SDL_SetWindowMouseGrab(ptr, true);
                }
                _ = sdl.SDL_HideCursor();
            },
            .hide_always => {
                if (cfg.jok_window_size == .fullscreen) {
                    _ = sdl.SDL_SetWindowMouseGrab(ptr, true);
                }
                _ = sdl.SDL_SetWindowRelativeMouseMode(ptr, true);
                _ = sdl.SDL_HideCursor();
            },
        }

        const window = Window{ .ptr = ptr.?, .cfg = ctx.cfg() };
        if (cfg.jok_window_min_size) |sz| {
            try window.setMinimumSize(sz);
        }
        if (cfg.jok_window_max_size) |sz| {
            try window.setMaximumSize(sz);
        }
        if (!builtin.cpu.arch.isWasm()) {
            window.setPosition(.center) catch {};
        }
        try window.setResizable(cfg.jok_window_size != .custom or cfg.jok_window_resizable);
        try window.setAlwaysOnTop(cfg.jok_window_always_on_top);

        return window;
    }

    /// Destroy the window and free associated resources.
    ///
    /// **WARNING: This function is automatically called by jok.Context during cleanup.**
    /// **DO NOT call this function directly from game code.**
    pub fn destroy(self: Window) void {
        sdl.SDL_DestroyWindow(self.ptr);
    }

    /// Maximize the window.
    pub fn maximize(self: Window) !void {
        if (!sdl.SDL_MaximizeWindow(self.ptr)) {
            log.err("Minimum window failed: {s}", .{sdl.SDL_GetError()});
            return error.SdlError;
        }
    }

    /// Minimize the window.
    pub fn minimize(self: Window) !void {
        if (!sdl.SDL_MinimizeWindow(self.ptr)) {
            log.err("Minimize window failed: {s}", .{sdl.SDL_GetError()});
            return error.SdlError;
        }
    }

    /// Get the current size of the window.
    ///
    /// Returns: Window size in pixels
    pub fn getSize(self: Window) jok.Size {
        var width: c_int = undefined;
        var height: c_int = undefined;
        _ = sdl.SDL_GetWindowSize(self.ptr, &width, &height);
        return .{
            .width = @intCast(width),
            .height = @intCast(height),
        };
    }

    /// Set the size of the window.
    ///
    /// Parameters:
    ///   s: New window size in pixels
    pub fn setSize(self: Window, s: jok.Size) !void {
        if (!sdl.SDL_SetWindowSize(self.ptr, @intCast(s.width), @intCast(s.height))) {
            log.err("Set size failed: {s}", .{sdl.SDL_GetError()});
            return error.SdlError;
        }
    }

    /// Set the minimum size of the window.
    ///
    /// Parameters:
    ///   s: Minimum window size in pixels
    pub fn setMinimumSize(self: Window, s: jok.Size) !void {
        if (!sdl.SDL_SetWindowMinimumSize(self.ptr, @intCast(s.width), @intCast(s.height))) {
            log.err("Set maximum size failed: {s}", .{sdl.SDL_GetError()});
            return error.SdlError;
        }
    }

    /// Set the maximum size of the window.
    ///
    /// Parameters:
    ///   s: Maximum window size in pixels
    pub fn setMaximumSize(self: Window, s: jok.Size) !void {
        if (!sdl.SDL_SetWindowMinimumSize(self.ptr, @intCast(s.width), @intCast(s.height))) {
            log.err("Set minimum size failed: {s}", .{sdl.SDL_GetError()});
            return error.SdlError;
        }
    }

    /// Set whether the window is resizable.
    ///
    /// Note: Not supported for software renderer.
    ///
    /// Parameters:
    ///   resizable: True to allow resizing, false to disable
    pub fn setResizable(self: Window, resizable: bool) !void {
        if (self.cfg.jok_renderer_type == .software) return;
        if (!sdl.SDL_SetWindowResizable(self.ptr, resizable)) {
            log.err("Toggle resizable failed: {s}", .{sdl.SDL_GetError()});
            return error.SdlError;
        }
    }

    /// Get the current position of the window.
    ///
    /// Returns: Window position in screen coordinates
    pub fn getPosition(self: Window) jok.Point {
        var x: c_int = undefined;
        var y: c_int = undefined;
        _ = sdl.SDL_GetWindowPosition(self.ptr, &x, &y);
        return .{
            .x = @floatFromInt(x),
            .y = @floatFromInt(y),
        };
    }

    /// Window position specification.
    pub const WindowPos = union(enum) {
        /// Center the window on screen
        center,
        /// Custom position in screen coordinates
        custom: jok.Point,
    };

    /// Set the position of the window.
    ///
    /// Parameters:
    ///   pos: Window position (centered or custom coordinates)
    pub fn setPosition(self: Window, pos: WindowPos) !void {
        if (!switch (pos) {
            .center => sdl.SDL_SetWindowPosition(self.ptr, sdl.SDL_WINDOWPOS_CENTERED, sdl.SDL_WINDOWPOS_CENTERED),
            .custom => |p| sdl.SDL_SetWindowPosition(self.ptr, @intFromFloat(p.x), @intFromFloat(p.y)),
        }) {
            log.err("Set position failed: {s}", .{sdl.SDL_GetError()});
            return error.SdlError;
        }
    }

    /// Set the window title.
    ///
    /// Parameters:
    ///   title: New window title (null-terminated string)
    pub fn setTitle(self: Window, title: [:0]const u8) !void {
        if (!sdl.SDL_SetWindowTitle(self.ptr, title)) {
            log.err("Set title failed: {s}", .{sdl.SDL_GetError()});
            return error.SdlError;
        }
    }

    /// Set window visibility.
    ///
    /// Parameters:
    ///   visible: True to show window, false to hide
    pub fn setVisible(self: Window, visible: bool) !void {
        if (!if (visible) sdl.SDL_ShowWindow(self.ptr) else sdl.SDL_HideWindow(self.ptr)) {
            log.err("Toggle visibility failed: {s}", .{sdl.SDL_GetError()});
            return error.SdlError;
        }
    }

    /// Set fullscreen mode.
    ///
    /// Note: Not supported for software renderer.
    /// On WebAssembly (SDL 3.4+), uses document fill mode.
    ///
    /// Parameters:
    ///   on: True to enable fullscreen, false to disable
    pub fn setFullscreen(self: Window, on: bool) !void {
        if (self.cfg.jok_renderer_type == .software) return;
        const minor_version = sdl.SDL_VERSIONNUM_MINOR(sdl.SDL_GetVersion());
        if (builtin.cpu.arch.isWasm() and minor_version >= 4) {
            if (!sdl.SDL_SetWindowFillDocument(self.ptr, on)) {
                log.err("Toggle fullscreen failed: {s}", .{sdl.SDL_GetError()});
                return error.SdlError;
            }
        } else {
            if (!sdl.SDL_SetWindowFullscreen(self.ptr, on)) {
                log.err("Toggle fullscreen failed: {s}", .{sdl.SDL_GetError()});
                return error.SdlError;
            }
        }
    }

    /// Set whether window stays on top of other windows.
    ///
    /// Parameters:
    ///   on: True to keep window on top, false for normal behavior
    pub fn setAlwaysOnTop(self: Window, on: bool) !void {
        if (!sdl.SDL_SetWindowAlwaysOnTop(self.ptr, on)) {
            log.err("Toggle always-on-top failed: {s}", .{sdl.SDL_GetError()});
            return error.SdlError;
        }
    }

    /// Set relative mouse mode for the window.
    ///
    /// In relative mode, the cursor is hidden and mouse motion generates
    /// relative movement events without cursor position constraints.
    ///
    /// Parameters:
    ///   on: True to enable relative mode, false to disable
    pub fn setRelativeMouseMode(self: Window, on: bool) !void {
        if (!sdl.SDL_SetWindowRelativeMouseMode(self.ptr, on)) {
            log.err("Toggle relative mouse mode failed: {s}", .{sdl.SDL_GetError()});
            return error.SdlError;
        }
    }

    /// Start text input for the window.
    ///
    /// Enables text input events and shows the on-screen keyboard on mobile platforms.
    pub fn startTextInput(self: Window) !void {
        if (!sdl.SDL_StartTextInput(self.ptr)) {
            log.err("Start text input failed: {s}", .{sdl.SDL_GetError()});
            return error.SdlError;
        }
    }

    /// Stop text input for the window.
    ///
    /// Disables text input events and hides the on-screen keyboard on mobile platforms.
    pub fn stopTextInput(self: Window) !void {
        if (!sdl.SDL_StopTextInput(self.ptr)) {
            log.err("Stop text input failed: {s}", .{sdl.SDL_GetError()});
            return error.SdlError;
        }
    }

    /// Check if text input is currently active.
    ///
    /// Returns: True if text input is active, false otherwise
    pub fn isTextInputActive(self: Window) bool {
        return sdl.SDL_TextInputActive(self.ptr);
    }

    /// Set the text input area for IME composition.
    ///
    /// Parameters:
    ///   rect: Input area rectangle (null for default)
    ///   offset_x: Horizontal offset for the composition window
    pub fn setTextInputArea(self: Window, rect: ?jok.Region, offset_x: u32) !void {
        if (!sdl.SDL_TextInputActive(self.ptr, &rect orelse null, @intCast(offset_x))) {
            log.err("Set text input area failed: {s}", .{sdl.SDL_GetError()});
            return error.SdlError;
        }
    }
};
