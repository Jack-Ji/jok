const std = @import("std");
const assert = std.debug.assert;
const jok = @import("jok.zig");
const sdl = jok.sdl;

const log = std.log.scoped(.jok);

pub const Texture = struct {
    pub const Access = enum(sdl.c.SDL_TextureAccess) {
        static = sdl.c.SDL_TEXTUREACCESS_STATIC,
        streaming = sdl.c.SDL_TEXTUREACCESS_STREAMING,
        target = sdl.c.SDL_TEXTUREACCESS_TARGET,
    };
    pub const ScaleMode = enum(sdl.c.SDL_ScaleMode) {
        nearest = sdl.c.SDL_SCALEMODE_NEAREST,
        linear = sdl.c.SDL_SCALEMODE_LINEAR,
        pixelart = sdl.c.SDL_SCALEMODE_PIXELART,
    };

    ptr: *sdl.c.SDL_Texture,

    pub fn destroy(self: Texture) void {
        sdl.c.SDL_DestroyTexture(self.ptr);
    }

    pub const Info = struct {
        width: u32,
        height: u32,
        format: u32,
        access: Access,
    };
    pub fn query(self: Texture) !Info {
        const props = sdl.c.SDL_GetTextureProperties(self.ptr);
        return Info{
            .width = @intCast(sdl.c.SDL_GetNumberProperty(props, sdl.c.SDL_PROP_TEXTURE_WIDTH_NUMBER, 0)),
            .height = @intCast(sdl.c.SDL_GetNumberProperty(props, sdl.c.SDL_PROP_TEXTURE_HEIGHT_NUMBER, 0)),
            .format = @intCast(sdl.c.SDL_GetNumberProperty(props, sdl.c.SDL_PROP_TEXTURE_FORMAT_NUMBER, 0)),
            .access = @enumFromInt(@as(sdl.c.SDL_TextureAccess, @intCast(sdl.c.SDL_GetNumberProperty(props, sdl.c.SDL_PROP_TEXTURE_ACCESS_NUMBER, 0)))),
        };
    }

    // This is a fairly slow function, intended for use with static textures that do not change often.
    pub fn updateSlow(self: Texture, pixels: []const u8) !void {
        const info = try self.query();
        assert(pixels.len == info.width * info.height * 4);
        if (!sdl.c.SDL_UpdateTexture(
            self.ptr,
            null,
            pixels.ptr,
            @intCast(info.width * 4),
        )) {
            log.err("update texture failed: {s}", .{sdl.c.SDL_GetError()});
            return error.SdlError;
        }
    }

    pub fn getBlendMode(self: Texture) !jok.BlendMode {
        var blend_mode: sdl.c.SDL_BlendMode = undefined;
        if (!sdl.c.SDL_GetTextureBlendMode(self.ptr, &blend_mode)) {
            log.err("get blend mode failed: {s}", .{sdl.c.SDL_GetError()});
            return error.SdlError;
        }
        return jok.BlendMode.fromNative(blend_mode);
    }

    pub fn setBlendMode(self: Texture, blend_mode: jok.BlendMode) !void {
        if (!sdl.c.SDL_SetTextureBlendMode(self.ptr, blend_mode.toNative())) {
            log.err("set blend mode failed: {s}", .{sdl.c.SDL_GetError()});
            return error.SdlError;
        }
    }

    pub fn getScaleMode(self: Texture) !ScaleMode {
        const scale_mode: sdl.c.SDL_ScaleMode = undefined;
        if (!sdl.c.SDL_GetTextureScaleMode(self.ptr, &scale_mode)) {
            log.err("get scale mode failed: {s}", .{sdl.c.SDL_GetError()});
            return error.SdlError;
        }
        return @enumFromInt(scale_mode);
    }

    pub fn setScaleMode(self: Texture, scale_mode: ScaleMode) !void {
        if (!sdl.c.SDL_SetTextureScaleMode(self.ptr, @intFromEnum(scale_mode))) {
            log.err("set scale mode failed: {s}", .{sdl.c.SDL_GetError()});
            return error.SdlError;
        }
    }

    /// Pixels meant to be written to textures
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
        assert(info.format == @as(u32, @intCast(sdl.c.SDL_PIXELFORMAT_RGBA32)));
        assert(region == null or region.?.width <= info.width);
        assert(region == null or region.?.height <= info.height);

        var pixels: ?*anyopaque = undefined;
        var pitch: c_int = undefined;
        if (!sdl.c.SDL_LockTexture(
            self.ptr,
            if (region) |r| @ptrCast(&r) else null,
            &pixels,
            &pitch,
        )) {
            log.err("lock texture failed: {s}", .{sdl.c.SDL_GetError()});
            return error.SdlError;
        }
        assert(@rem(pitch, 4) == 0);
        sdl.c.SDL_UnlockTexture(self.ptr);

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
        assert(info.format == @as(u32, @intCast(sdl.c.SDL_PIXELFORMAT_RGBA32)));

        const width = if (data.region) |r| r.width else info.width;
        const height = if (data.region) |r| r.height else info.height;
        assert(width <= info.width);
        assert(height <= info.height);

        var pixels: ?*anyopaque = undefined;
        var pitch: c_int = undefined;
        if (!sdl.c.SDL_LockTexture(
            self.ptr,
            if (data.region) |r| @ptrCast(&r) else null,
            &pixels,
            &pitch,
        )) {
            log.err("lock texture failed: {s}", .{sdl.c.SDL_GetError()});
            return error.SdlError;
        }
        assert(@as(u32, @intCast(pitch)) == data.width * 4);
        var pixelbuf: []u8 = undefined;
        pixelbuf.ptr = @ptrCast(pixels.?);
        pixelbuf.len = data.buf.len;
        @memcpy(pixelbuf, data.buf);
        sdl.c.SDL_UnlockTexture(self.ptr);
    }
};
