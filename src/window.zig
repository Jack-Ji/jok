const std = @import("std");
const jok = @import("jok.zig");
const sdl = jok.sdl;

const log = std.log.scoped(.jok);

pub const Window = struct {
    ptr: *sdl.SDL_Window,

    pub fn init(cfg: jok.config.Config, dpi_scale: f32) !Window {
        var flags: u32 = 0;
        flags |= sdl.SDL_WINDOW_MOUSE_CAPTURE;
        flags |= sdl.SDL_WINDOW_MOUSE_FOCUS;
        if (cfg.jok_window_highdpi) {
            flags |= sdl.SDL_WINDOW_ALLOW_HIGHDPI;
        }
        if (cfg.jok_window_borderless) {
            flags |= sdl.SDL_WINDOW_BORDERLESS;
        }
        if (cfg.jok_window_ime_ui) {
            _ = sdl.SDL_SetHint("SDL_IME_SHOW_UI", "1");
        }

        var window_width: c_int = 800;
        var window_height: c_int = 600;
        switch (cfg.jok_window_size) {
            .maximized => {
                flags |= sdl.SDL_WINDOW_MAXIMIZED;
            },
            .fullscreen => {
                flags |= sdl.SDL_WINDOW_FULLSCREEN_DESKTOP;
            },
            .custom => |size| {
                // Make sure window size looks same on different screen
                window_width = @intFromFloat(@as(f32, @floatFromInt(size.width)) * dpi_scale);
                window_height = @intFromFloat(@as(f32, @floatFromInt(size.height)) * dpi_scale);
            },
        }
        const ptr = sdl.SDL_CreateWindow(
            cfg.jok_window_title,
            sdl.SDL_WINDOWPOS_CENTERED,
            sdl.SDL_WINDOWPOS_CENTERED,
            window_width,
            window_height,
            flags,
        );
        if (ptr == null) {
            log.err("create window failed: {s}", .{sdl.SDL_GetError()});
            return sdl.Error.SdlError;
        }

        // Mouse mode
        switch (cfg.jok_window_mouse_mode) {
            .normal => {
                if (cfg.jok_window_size == .fullscreen) {
                    sdl.SDL_SetWindowGrab(ptr, 0);
                    _ = sdl.SDL_ShowCursor(0);
                    _ = sdl.SDL_SetRelativeMouseMode(1);
                } else {
                    _ = sdl.SDL_ShowCursor(1);
                    _ = sdl.SDL_SetRelativeMouseMode(0);
                }
            },
            .hide_in_window => {
                if (cfg.jok_window_size == .fullscreen) {
                    sdl.SDL_SetWindowGrab(ptr, 1);
                }
                _ = sdl.SDL_ShowCursor(0);
            },
            .hide_always => {
                if (cfg.jok_window_size == .fullscreen) {
                    sdl.SDL_SetWindowGrab(ptr, 1);
                }
                _ = sdl.SDL_ShowCursor(0);
                _ = sdl.SDL_SetRelativeMouseMode(1);
            },
        }

        const window = Window{ .ptr = ptr.? };
        if (cfg.jok_window_min_size) |size| {
            window.setMinimumSize(size);
        }
        if (cfg.jok_window_max_size) |size| {
            window.setMaximumSize(size);
        }
        window.setResizable(cfg.jok_window_resizable);
        window.setAlwaysOnTop(cfg.jok_window_always_on_top);

        return window;
    }

    pub fn destroy(w: Window) void {
        sdl.SDL_DestroyWindow(w.ptr);
    }

    pub fn getSize(w: Window) jok.Size {
        var width: c_int = undefined;
        var height: c_int = undefined;
        sdl.SDL_GetWindowSize(w.ptr, &width, &height);
        return .{
            .width = @intCast(width),
            .height = @intCast(height),
        };
    }

    pub fn setSize(w: Window, s: jok.Size) void {
        sdl.SDL_SetWindowSize(w.ptr, @intCast(s.width), @intCast(s.height));
    }

    pub fn setMinimumSize(w: Window, s: jok.Size) void {
        sdl.SDL_SetWindowMinimumSize(w.ptr, @intCast(s.width), @intCast(s.height));
    }

    pub fn setMaximumSize(w: Window, s: jok.Size) void {
        sdl.SDL_SetWindowMaximumSize(w.ptr, @intCast(s.width), @intCast(s.height));
    }

    pub fn setResizable(w: Window, resizable: bool) void {
        sdl.SDL_SetWindowResizable(w.ptr, @intFromBool(resizable));
    }

    pub fn getPosition(w: Window) jok.Point {
        var x: c_int = undefined;
        var y: c_int = undefined;
        sdl.SDL_GetWindowPosition(w.ptr, &x, &y);
        return .{
            .x = @floatFromInt(x),
            .y = @floatFromInt(y),
        };
    }

    pub const WindowPos = union(enum) {
        center,
        custom: jok.Point,
    };
    pub fn setPosition(w: Window, pos: WindowPos) void {
        switch (pos) {
            .center => sdl.SDL_SetWindowPosition(w.ptr, sdl.SDL_WINDOWPOS_CENTERED, sdl.SDL_WINDOWPOS_CENTERED),
            .custom => |p| sdl.SDL_SetWindowPosition(w.ptr, @intFromFloat(p.x), @intFromFloat(p.y)),
        }
    }

    pub fn setTitle(w: Window, title: [:0]const u8) void {
        sdl.SDL_SetWindowTitle(w.ptr, title);
    }

    pub fn setVisible(w: Window, visible: bool) void {
        if (visible) {
            sdl.SDL_ShowWindow(w.ptr);
        } else {
            sdl.SDL_HideWindow(w.ptr);
        }
    }

    pub const FullScreenMode = enum {
        none,
        desktop_fullscreen,
        true_fullscreen,
    };
    pub fn setFullscreen(w: Window, mode: FullScreenMode) !void {
        if (sdl.SDL_SetWindowFullscreen(w.ptr, switch (mode) {
            .none => 0,
            .desktop_fullscreen => sdl.SDL_WINDOW_FULLSCREEN_DESKTOP,
            .true_fullscreen => sdl.SDL_WINDOW_FULLSCREEN,
        }) != 0) {
            log.err("switch fullscreen failed: {s}", .{sdl.SDL_GetError()});
            return sdl.Error.SdlError;
        }
    }

    pub fn setAlwaysOnTop(w: Window, on: bool) void {
        sdl.SDL_SetWindowAlwaysOnTop(w.ptr, @intFromBool(on));
    }
};
