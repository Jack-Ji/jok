const std = @import("std");
const builtin = @import("builtin");
const jok = @import("jok.zig");
const sdl = jok.vendor.sdl;
const log = std.log.scoped(.jok);

pub const Window = struct {
    ptr: *sdl.SDL_Window,
    cfg: jok.config.Config,

    pub fn init(ctx: jok.Context) !Window {
        const cfg = ctx.cfg();
        if (cfg.jok_window_ime_ui) {
            _ = sdl.SDL_SetHint(sdl.SDL_HINT_IME_IMPLEMENTED_UI, "1");
        }

        const props = sdl.SDL_CreateProperties();
        _ = sdl.SDL_SetStringProperty(props, sdl.SDL_PROP_WINDOW_CREATE_TITLE_STRING, cfg.jok_window_title);
        _ = sdl.SDL_SetBooleanProperty(props, sdl.SDL_PROP_WINDOW_CREATE_HIDDEN_BOOLEAN, cfg.jok_headless);
        _ = sdl.SDL_SetBooleanProperty(props, sdl.SDL_PROP_WINDOW_CREATE_BORDERLESS_BOOLEAN, cfg.jok_window_borderless);
        if (cfg.jok_renderer_type != .software) {
            _ = sdl.SDL_SetBooleanProperty(props, sdl.SDL_PROP_WINDOW_CREATE_RESIZABLE_BOOLEAN, true);
        }
        var window_width: c_int = 800;
        var window_height: c_int = 600;
        switch (cfg.jok_window_size) {
            .maximized => _ = sdl.SDL_SetBooleanProperty(props, sdl.SDL_PROP_WINDOW_CREATE_MAXIMIZED_BOOLEAN, true),
            .fullscreen => _ = sdl.SDL_SetBooleanProperty(props, sdl.SDL_PROP_WINDOW_CREATE_FULLSCREEN_BOOLEAN, true),
            .custom => |size| {
                window_width = @intCast(size.width);
                window_height = @intCast(size.height);
            },
        }
        _ = sdl.SDL_SetNumberProperty(props, sdl.SDL_PROP_WINDOW_CREATE_WIDTH_NUMBER, @intCast(window_width));
        _ = sdl.SDL_SetNumberProperty(props, sdl.SDL_PROP_WINDOW_CREATE_HEIGHT_NUMBER, @intCast(window_height));
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
        if (cfg.jok_window_min_size) |size| {
            try window.setMinimumSize(size);
        }
        if (cfg.jok_window_max_size) |size| {
            try window.setMaximumSize(size);
        }
        if (!builtin.cpu.arch.isWasm()) {
            window.setPosition(.center) catch {};
        }
        try window.setResizable(cfg.jok_window_resizable);
        try window.setAlwaysOnTop(cfg.jok_window_always_on_top);

        return window;
    }

    pub fn destroy(self: Window) void {
        sdl.SDL_DestroyWindow(self.ptr);
    }

    pub fn maximize(self: Window) !void {
        if (!sdl.SDL_MaximizeWindow(self.ptr)) {
            log.err("Minimum window failed: {s}", .{sdl.SDL_GetError()});
            return error.SdlError;
        }
    }

    pub fn minimize(self: Window) !void {
        if (!sdl.SDL_MinimizeWindow(self.ptr)) {
            log.err("Minimize window failed: {s}", .{sdl.SDL_GetError()});
            return error.SdlError;
        }
    }

    pub fn getSize(self: Window) jok.Size {
        var width: c_int = undefined;
        var height: c_int = undefined;
        _ = sdl.SDL_GetWindowSize(self.ptr, &width, &height);
        return .{
            .width = @intCast(width),
            .height = @intCast(height),
        };
    }

    pub fn setSize(self: Window, s: jok.Size) !void {
        if (!sdl.SDL_SetWindowSize(self.ptr, @intCast(s.width), @intCast(s.height))) {
            log.err("Set size failed: {s}", .{sdl.SDL_GetError()});
            return error.SdlError;
        }
    }

    pub fn setMinimumSize(self: Window, s: jok.Size) !void {
        if (!sdl.SDL_SetWindowMinimumSize(self.ptr, @intCast(s.width), @intCast(s.height))) {
            log.err("Set maximum size failed: {s}", .{sdl.SDL_GetError()});
            return error.SdlError;
        }
    }

    pub fn setMaximumSize(self: Window, s: jok.Size) !void {
        if (!sdl.SDL_SetWindowMinimumSize(self.ptr, @intCast(s.width), @intCast(s.height))) {
            log.err("Set minimum size failed: {s}", .{sdl.SDL_GetError()});
            return error.SdlError;
        }
    }

    pub fn setResizable(self: Window, resizable: bool) !void {
        if (self.cfg.jok_renderer_type == .software) return;
        if (!sdl.SDL_SetWindowResizable(self.ptr, resizable)) {
            log.err("Toggle resizable failed: {s}", .{sdl.SDL_GetError()});
            return error.SdlError;
        }
    }

    pub fn getPosition(self: Window) jok.Point {
        var x: c_int = undefined;
        var y: c_int = undefined;
        _ = sdl.SDL_GetWindowPosition(self.ptr, &x, &y);
        return .{
            .x = @floatFromInt(x),
            .y = @floatFromInt(y),
        };
    }

    pub const WindowPos = union(enum) {
        center,
        custom: jok.Point,
    };
    pub fn setPosition(self: Window, pos: WindowPos) !void {
        if (!switch (pos) {
            .center => sdl.SDL_SetWindowPosition(self.ptr, sdl.SDL_WINDOWPOS_CENTERED, sdl.SDL_WINDOWPOS_CENTERED),
            .custom => |p| sdl.SDL_SetWindowPosition(self.ptr, @intFromFloat(p.x), @intFromFloat(p.y)),
        }) {
            log.err("Set position failed: {s}", .{sdl.SDL_GetError()});
            return error.SdlError;
        }
    }

    pub fn setTitle(self: Window, title: [:0]const u8) !void {
        if (!sdl.SDL_SetWindowTitle(self.ptr, title)) {
            log.err("Set title failed: {s}", .{sdl.SDL_GetError()});
            return error.SdlError;
        }
    }

    pub fn setVisible(self: Window, visible: bool) !void {
        if (!if (visible) sdl.SDL_ShowWindow(self.ptr) else sdl.SDL_HideWindow(self.ptr)) {
            log.err("Toggle visibility failed: {s}", .{sdl.SDL_GetError()});
            return error.SdlError;
        }
    }

    pub fn setFullscreen(self: Window, on: bool) !void {
        if (!sdl.SDL_SetWindowFullscreen(self.ptr, on)) {
            log.err("Toggle fullscreen failed: {s}", .{sdl.SDL_GetError()});
            return error.SdlError;
        }
    }

    pub fn setAlwaysOnTop(self: Window, on: bool) !void {
        if (!sdl.SDL_SetWindowAlwaysOnTop(self.ptr, on)) {
            log.err("Toggle always-on-top failed: {s}", .{sdl.SDL_GetError()});
            return error.SdlError;
        }
    }

    pub fn setRelativeMouseMode(self: Window, on: bool) !void {
        if (!sdl.SDL_SetWindowRelativeMouseMode(self.ptr, on)) {
            log.err("Toggle relative mouse mode failed: {s}", .{sdl.SDL_GetError()});
            return error.SdlError;
        }
    }
};
