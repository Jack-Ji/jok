//! Texture management.
//!
//! This module provides texture creation, manipulation, and rendering functionality.
//! Textures are the primary way to display images and graphics in the jok engine.
//!
//! Features:
//! - Multiple access modes (static, streaming, target)
//! - Pixel-level manipulation for streaming textures
//! - Blend mode and scale mode control
//! - Integration with zgui for UI rendering
//! - Efficient texture updates

const std = @import("std");
const assert = std.debug.assert;
const jok = @import("jok.zig");
const sdl = jok.vendor.sdl;
const zgui = jok.vendor.zgui;

const log = std.log.scoped(.jok);

/// Texture wrapper providing access to SDL texture functionality.
///
/// Textures can be used for rendering images, as render targets, or for
/// dynamic pixel manipulation depending on their access mode.
pub const Texture = struct {
    /// Texture access pattern.
    pub const Access = enum(sdl.SDL_TextureAccess) {
        /// Changes rarely, not lockable
        static = sdl.SDL_TEXTUREACCESS_STATIC,
        /// Changes frequently, lockable for pixel access
        streaming = sdl.SDL_TEXTUREACCESS_STREAMING,
        /// Can be used as a render target
        target = sdl.SDL_TEXTUREACCESS_TARGET,
    };

    /// Texture scaling filter mode.
    pub const ScaleMode = enum(sdl.SDL_ScaleMode) {
        /// Nearest-neighbor filtering (pixelated)
        nearest = sdl.SDL_SCALEMODE_NEAREST,
        /// Linear filtering (smooth)
        linear = sdl.SDL_SCALEMODE_LINEAR,
    };

    ptr: [*c]sdl.SDL_Texture,

    /// Destroy the texture and free associated resources.
    pub fn destroy(self: Texture) void {
        sdl.SDL_DestroyTexture(self.ptr);
    }

    /// Convert texture to zgui texture reference for UI rendering.
    ///
    /// Returns: Texture reference usable with zgui
    pub fn toReference(self: Texture) zgui.TextureRef {
        return .{
            .tex_data = null,
            .tex_id = @enumFromInt(@intFromPtr(self.ptr)),
        };
    }

    /// Texture information.
    pub const Info = struct {
        /// Texture width in pixels
        width: u32,
        /// Texture height in pixels
        height: u32,
        /// Pixel format
        format: u32,
        /// Access pattern
        access: Access,
    };

    /// Query texture properties.
    ///
    /// Returns: Texture information including size and format
    pub fn query(self: Texture) !Info {
        const props = sdl.SDL_GetTextureProperties(self.ptr);
        return Info{
            .width = @intCast(sdl.SDL_GetNumberProperty(props, sdl.SDL_PROP_TEXTURE_WIDTH_NUMBER, 0)),
            .height = @intCast(sdl.SDL_GetNumberProperty(props, sdl.SDL_PROP_TEXTURE_HEIGHT_NUMBER, 0)),
            .format = @intCast(sdl.SDL_GetNumberProperty(props, sdl.SDL_PROP_TEXTURE_FORMAT_NUMBER, 0)),
            .access = @enumFromInt(@as(sdl.SDL_TextureAccess, @intCast(sdl.SDL_GetNumberProperty(props, sdl.SDL_PROP_TEXTURE_ACCESS_NUMBER, 0)))),
        };
    }

    /// Update texture pixels (slow method for static textures).
    ///
    /// This is a fairly slow function, intended for use with static textures
    /// that do not change often. For frequent updates, use streaming textures
    /// with createPixelData/update instead.
    ///
    /// Parameters:
    ///   pixels: Pixel data in RGBA32 format (must match texture size)
    pub fn updateSlow(self: Texture, pixels: []const u8) !void {
        const info = try self.query();
        assert(pixels.len == info.width * info.height * 4);
        if (!sdl.SDL_UpdateTexture(
            self.ptr,
            null,
            pixels.ptr,
            @intCast(info.width * 4),
        )) {
            log.err("Update texture failed: {s}", .{sdl.SDL_GetError()});
            return error.SdlError;
        }
    }

    pub fn getBlendMode(self: Texture) !jok.BlendMode {
        var blend_mode: sdl.SDL_BlendMode = undefined;
        if (!sdl.SDL_GetTextureBlendMode(self.ptr, &blend_mode)) {
            log.err("Get blend mode failed: {s}", .{sdl.SDL_GetError()});
            return error.SdlError;
        }
        return jok.BlendMode.fromNative(blend_mode);
    }

    pub fn setBlendMode(self: Texture, blend_mode: jok.BlendMode) !void {
        if (!sdl.SDL_SetTextureBlendMode(self.ptr, blend_mode.toNative())) {
            log.err("Set blend mode failed: {s}", .{sdl.SDL_GetError()});
            return error.SdlError;
        }
    }

    pub fn getScaleMode(self: Texture) !ScaleMode {
        const scale_mode: sdl.SDL_ScaleMode = undefined;
        if (!sdl.SDL_GetTextureScaleMode(self.ptr, &scale_mode)) {
            log.err("Get scale mode failed: {s}", .{sdl.SDL_GetError()});
            return error.SdlError;
        }
        return @enumFromInt(scale_mode);
    }

    pub fn setScaleMode(self: Texture, scale_mode: ScaleMode) !void {
        if (!sdl.SDL_SetTextureScaleMode(self.ptr, @intFromEnum(scale_mode))) {
            log.err("Set scale mode failed: {s}", .{sdl.SDL_GetError()});
            return error.SdlError;
        }
    }

    /// Pixel data buffer for writing to streaming textures.
    ///
    /// Provides efficient pixel-level access for dynamic texture updates.
    /// Must be used with streaming textures only.
    pub const PixelData = struct {
        allocator: std.mem.Allocator,
        region: ?jok.Region,
        buf: []u8,
        pixels: []u32,
        width: u32,
        height: u32,

        pub inline fn destroy(self: PixelData) void {
            self.allocator.free(self.buf);
        }

        pub inline fn clear(self: PixelData, c: jok.Color, region: ?jok.Region) void {
            const rgba = c.toRGBA32();
            if (region) |r| {
                assert(r.x + r.width <= self.width);
                assert(r.y + r.height <= self.height);
                for (0..r.height) |h| {
                    const off_begin = (r.y + h) * self.width + r.x;
                    const off_end = (r.y + h) * self.width + r.x + r.width;
                    @memset(self.pixels[off_begin..off_end], rgba);
                }
            } else {
                @memset(self.pixels, rgba);
            }
        }

        pub inline fn getPixel(self: PixelData, x: u32, y: u32) jok.Color {
            assert(x < self.width);
            assert(y < self.height);
            return jok.Color.fromRGBA32(self.pixels[y * self.width + x]);
        }

        pub inline fn setPixel(self: PixelData, x: u32, y: u32, c: jok.Color) void {
            assert(x < self.width);
            assert(y < self.height);
            self.pixels[y * self.width + x] = c.toRGBA32();
        }

        pub inline fn setPixelByIndex(self: PixelData, index: u32, c: jok.Color) void {
            assert(index < self.pixels.len);
            self.pixels[index] = c.toRGBA32();
        }
    };
    pub fn createPixelData(self: Texture, allocator: std.mem.Allocator, region: ?jok.Region) !PixelData {
        const info = try self.query();
        assert(info.access == .streaming);
        assert(info.format == @as(u32, @intCast(sdl.SDL_PIXELFORMAT_RGBA32)));
        assert(region == null or region.?.width <= info.width);
        assert(region == null or region.?.height <= info.height);

        var pixels: ?*anyopaque = undefined;
        var pitch: c_int = undefined;
        if (!sdl.SDL_LockTexture(
            self.ptr,
            if (region) |r| @ptrCast(&r) else null,
            &pixels,
            &pitch,
        )) {
            log.err("Lock texture failed: {s}", .{sdl.SDL_GetError()});
            return error.SdlError;
        }
        assert(@rem(pitch, 4) == 0);
        sdl.SDL_UnlockTexture(self.ptr);

        const width = if (region) |r| r.width else info.width;
        assert(width * 4 == pitch);
        const height = if (region) |r| r.height else info.height;
        const bufsize = width * height * 4;
        const buf = try allocator.alloc(u8, bufsize);
        var pixelbuf: []u32 = undefined;
        pixelbuf.ptr = @ptrCast(@alignCast(buf.ptr));
        pixelbuf.len = width * height;
        return .{
            .allocator = allocator,
            .region = region,
            .buf = buf,
            .pixels = pixelbuf,
            .width = width,
            .height = height,
        };
    }

    pub fn update(self: Texture, data: PixelData) !void {
        const info = try self.query();
        assert(info.access == .streaming);
        assert(info.format == @as(u32, @intCast(sdl.SDL_PIXELFORMAT_RGBA32)));

        const width = if (data.region) |r| r.width else info.width;
        const height = if (data.region) |r| r.height else info.height;
        assert(width <= info.width);
        assert(height <= info.height);

        var pixels: ?*anyopaque = undefined;
        var pitch: c_int = undefined;
        if (!sdl.SDL_LockTexture(
            self.ptr,
            if (data.region) |r| @ptrCast(&r) else null,
            &pixels,
            &pitch,
        )) {
            log.err("Lock texture failed: {s}", .{sdl.SDL_GetError()});
            return error.SdlError;
        }
        assert(@as(u32, @intCast(pitch)) == data.width * 4);
        var pixelbuf: []u8 = undefined;
        pixelbuf.ptr = @ptrCast(pixels.?);
        pixelbuf.len = data.buf.len;
        @memcpy(pixelbuf, data.buf);
        sdl.SDL_UnlockTexture(self.ptr);
    }
};
