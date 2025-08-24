const std = @import("std");
const jok = @import("jok.zig");
const sdl = jok.sdl;

const log = std.log.scoped(.jok);

pub const Window = struct {
    ptr: *sdl.c.SDL_Window,

    pub fn init(ctx: jok.Context) !Window {
        const cfg = ctx.cfg();
        if (cfg.jok_window_ime_ui) {
            _ = sdl.c.SDL_SetHint(sdl.c.SDL_HINT_IME_IMPLEMENTED_UI, "1");
        }

        const props = sdl.c.SDL_CreateProperties();
        _ = sdl.c.SDL_SetStringProperty(props, sdl.c.SDL_PROP_WINDOW_CREATE_TITLE_STRING, cfg.jok_window_title);
        _ = sdl.c.SDL_SetBooleanProperty(props, sdl.c.SDL_PROP_WINDOW_CREATE_HIDDEN_BOOLEAN, cfg.jok_headless);
        _ = sdl.c.SDL_SetBooleanProperty(props, sdl.c.SDL_PROP_WINDOW_CREATE_HIGH_PIXEL_DENSITY_BOOLEAN, cfg.jok_window_highdpi);
        _ = sdl.c.SDL_SetBooleanProperty(props, sdl.c.SDL_PROP_WINDOW_CREATE_BORDERLESS_BOOLEAN, cfg.jok_window_borderless);
        var window_width: c_int = 800;
        var window_height: c_int = 600;
        switch (cfg.jok_window_size) {
            .maximized => _ = sdl.c.SDL_SetBooleanProperty(props, sdl.c.SDL_PROP_WINDOW_CREATE_MAXIMIZED_BOOLEAN, true),
            .fullscreen => _ = sdl.c.SDL_SetBooleanProperty(props, sdl.c.SDL_PROP_WINDOW_CREATE_FULLSCREEN_BOOLEAN, true),
            .custom => |size| {
                // Make sure window size looks same on different screen
                window_width = @intFromFloat(@as(f32, @floatFromInt(size.width)) * ctx.getDpiScale());
                window_height = @intFromFloat(@as(f32, @floatFromInt(size.height)) * ctx.getDpiScale());
            },
        }
        _ = sdl.c.SDL_SetNumberProperty(props, sdl.c.SDL_PROP_WINDOW_CREATE_WIDTH_NUMBER, @intCast(window_width));
        _ = sdl.c.SDL_SetNumberProperty(props, sdl.c.SDL_PROP_WINDOW_CREATE_HEIGHT_NUMBER, @intCast(window_height));
        const ptr = sdl.c.SDL_CreateWindowWithProperties(props);
        if (ptr == null) {
            log.err("create window failed: {s}", .{sdl.SDL_GetError()});
            return error.SdlError;
        }

        // Mouse mode
        switch (cfg.jok_window_mouse_mode) {
            .normal => {
                if (cfg.jok_window_size == .fullscreen) {
                    _ = sdl.c.SDL_SetWindowMouseGrab(ptr, false);
                    _ = sdl.c.SDL_SetWindowRelativeMouseMode(true);
                    _ = sdl.c.SDL_HideCursor();
                } else {
                    _ = sdl.c.SDL_SetWindowRelativeMouseMode(false);
                    _ = sdl.c.SDL_ShowCursor();
                }
            },
            .hide_in_window => {
                if (cfg.jok_window_size == .fullscreen) {
                    _ = sdl.c.SDL_SetWindowMouseGrab(ptr, true);
                }
                _ = sdl.c.SDL_HideCursor();
            },
            .hide_always => {
                if (cfg.jok_window_size == .fullscreen) {
                    _ = sdl.c.SDL_SetWindowMouseGrab(ptr, true);
                }
                _ = sdl.c.SDL_SetWindowRelativeMouseMode(true);
                _ = sdl.c.SDL_HideCursor();
            },
        }

        const window = Window{ .ptr = ptr.? };
        if (cfg.jok_window_min_size) |size| {
            window.setMinimumSize(size);
        }
        if (cfg.jok_window_max_size) |size| {
            window.setMaximumSize(size);
        }
        window.setPosition(.center);
        window.setResizable(cfg.jok_window_resizable);
        window.setAlwaysOnTop(cfg.jok_window_always_on_top);

        return window;
    }

    pub fn destroy(w: Window) void {
        sdl.c.SDL_DestroyWindow(w.ptr);
    }

    pub fn getSize(w: Window) jok.Size {
        var width: c_int = undefined;
        var height: c_int = undefined;
        _ = sdl.c.SDL_GetWindowSize(w.ptr, &width, &height);
        return .{
            .width = @intCast(width),
            .height = @intCast(height),
        };
    }

    pub fn setSize(w: Window, s: jok.Size) !void {
        if (!sdl.c.SDL_SetWindowSize(w.ptr, @intCast(s.width), @intCast(s.height))) {
            log.err("set size failed: {s}", .{sdl.c.SDL_GetError()});
            return error.SdlError;
        }
    }

    pub fn setMinimumSize(w: Window, s: jok.Size) !void {
        if (!sdl.c.SDL_SetWindowMinimumSize(w.ptr, @intCast(s.width), @intCast(s.height))) {
            log.err("set maximum size failed: {s}", .{sdl.c.SDL_GetError()});
            return error.SdlError;
        }
    }

    pub fn setMaximumSize(w: Window, s: jok.Size) !void {
        if (!sdl.c.SDL_SetWindowMinimumSize(w.ptr, @intCast(s.width), @intCast(s.height))) {
            log.err("set minimum size failed: {s}", .{sdl.c.SDL_GetError()});
            return error.SdlError;
        }
    }

    pub fn setResizable(w: Window, resizable: bool) !void {
        if (!sdl.c.SDL_SetWindowResizable(w.ptr, resizable)) {
            log.err("toggle resizable failed: {s}", .{sdl.c.SDL_GetError()});
            return error.SdlError;
        }
    }

    pub fn getPosition(w: Window) jok.Point {
        var x: c_int = undefined;
        var y: c_int = undefined;
        _ = sdl.c.SDL_GetWindowPosition(w.ptr, &x, &y);
        return .{
            .x = @floatFromInt(x),
            .y = @floatFromInt(y),
        };
    }

    pub const WindowPos = union(enum) {
        center,
        custom: jok.Point,
    };
    pub fn setPosition(w: Window, pos: WindowPos) !void {
        if (!switch (pos) {
            .center => sdl.c.SDL_SetWindowPosition(w.ptr, sdl.c.SDL_WINDOWPOS_CENTERED, sdl.c.SDL_WINDOWPOS_CENTERED),
            .custom => |p| sdl.c.SDL_SetWindowPosition(w.ptr, @intFromFloat(p.x), @intFromFloat(p.y)),
        }) {
            log.err("set position failed: {s}", .{sdl.c.SDL_GetError()});
            return error.SdlError;
        }
    }

    pub fn setTitle(w: Window, title: [:0]const u8) !void {
        if (!sdl.c.SDL_SetWindowTitle(w.ptr, title)) {
            log.err("set title failed: {s}", .{sdl.c.SDL_GetError()});
            return error.SdlError;
        }
    }

    pub fn setVisible(w: Window, visible: bool) !void {
        if (!if (visible) sdl.c.SDL_ShowWindow(w.ptr) else sdl.c.SDL_HideWindow(w.ptr)) {
            log.err("toggle visibility failed: {s}", .{sdl.c.SDL_GetError()});
            return error.SdlError;
        }
    }

    pub fn setFullscreen(w: Window, on: bool) !void {
        if (!sdl.c.SDL_SetWindowFullscreen(w.ptr, on)) {
            log.err("toggle fullscreen failed: {s}", .{sdl.c.SDL_GetError()});
            return error.SdlError;
        }
    }

    pub fn setAlwaysOnTop(w: Window, on: bool) !void {
        if (!sdl.c.SDL_SetWindowAlwaysOnTop(w.ptr, on)) {
            log.err("toggle always-on-top failed: {s}", .{sdl.c.SDL_GetError()});
            return error.SdlError;
        }
    }
};
