const std = @import("std");
const assert = std.debug.assert;
const jok = @import("jok.zig");
const sdl = jok.sdl;

const log = std.log.scoped(.jok);

pub const Texture = struct {
    pub const Access = enum(sdl.SDL_TextureAccess) {
        static = sdl.SDL_TEXTUREACCESS_STATIC,
        streaming = sdl.SDL_TEXTUREACCESS_STREAMING,
        target = sdl.SDL_TEXTUREACCESS_TARGET,
    };
    pub const ScaleMode = enum(sdl.SDL_ScaleMode) {
        nearest = sdl.SDL_ScaleModeNearest,
        linear = sdl.SDL_ScaleModeLinear,
        best = sdl.SDL_ScaleModeBest,
    };

    ptr: *sdl.SDL_Texture,

    pub fn destroy(self: Texture) void {
        sdl.SDL_DestroyTexture(self.ptr);
    }

    pub const Info = struct {
        width: u32,
        height: u32,
        format: u32,
        access: Access,
    };
    pub fn query(self: Texture) !Info {
        var format: u32 = undefined;
        var w: c_int = undefined;
        var h: c_int = undefined;
        var access: c_int = undefined;
        if (sdl.SDL_QueryTexture(self.ptr, &format, &access, &w, &h) < 0) {
            log.err("query texture info failed: {s}", .{sdl.SDL_GetError()});
            return sdl.Error.SdlError;
        }
        return Info{
            .width = @intCast(w),
            .height = @intCast(h),
            .format = format,
            .access = @enumFromInt(access),
        };
    }

    // This is a fairly slow function, intended for use with static textures that do not change often.
    pub fn updateSlow(self: Texture, pixels: []const u8) !void {
        const info = try self.query();
        assert(pixels.len == info.width * info.height * 4);
        if (sdl.SDL_UpdateTexture(
            self.ptr,
            null,
            pixels.ptr,
            @intCast(info.width * 4),
        ) != 0) {
            log.err("update texture failed: {s}", .{sdl.SDL_GetError()});
            return sdl.Error.SdlError;
        }
    }

    pub fn getBlendMode(self: Texture) !jok.BlendMode {
        var blend_mode: sdl.SDL_BlendMode = undefined;
        if (sdl.SDL_GetTextureBlendMode(self.ptr, &blend_mode) < 0) {
            log.err("get blend mode failed: {s}", .{sdl.SDL_GetError()});
            return sdl.Error.SdlError;
        }
        return jok.BlendMode.fromNative(blend_mode);
    }

    pub fn setBlendMode(self: Texture, blend_mode: jok.BlendMode) !void {
        if (sdl.SDL_SetTextureBlendMode(self.ptr, blend_mode.toNative()) < 0) {
            log.err("set blend mode failed: {s}", .{sdl.SDL_GetError()});
            return sdl.Error.SdlError;
        }
    }

    pub fn getScaleMode(self: Texture) !ScaleMode {
        const scale_mode: sdl.SDL_ScaleMode = undefined;
        if (sdl.SDL_GetTextureScaleMode(self.ptr, @intFromEnum(scale_mode)) < 0) {
            log.err("get scale mode failed: {s}", .{sdl.SDL_GetError()});
            return sdl.Error.SdlError;
        }
        return @enumFromInt(scale_mode);
    }

    pub fn setScaleMode(self: Texture, scale_mode: ScaleMode) !void {
        if (sdl.SDL_SetTextureScaleMode(self.ptr, @intFromEnum(scale_mode)) < 0) {
            log.err("set scale mode failed: {s}", .{sdl.SDL_GetError()});
            return sdl.Error.SdlError;
        }
    }

    /// Pixels meant to be written to textures
    pub const PixelData = struct {
        allocator: std.mem.Allocator,
        region: ?jok.Region,
        pixels: []u8,
        stride: u32,
        width: u32,
        height: u32,

        pub inline fn destroy(self: PixelData) void {
            self.allocator.free(self.pixels);
        }

        pub inline fn clear(self: PixelData) void {
            @memset(self.pixels, 0);
        }

        pub inline fn getPixel(self: PixelData, x: u32, y: u32) jok.Color {
            assert(x < self.width);
            assert(y < self.height);
            const line: [*]u32 = @alignCast(@ptrCast(self.pixels.ptr + y * self.stride));
            return jok.Color.fromRGBA32(line[x]);
        }

        pub inline fn setPixel(self: PixelData, x: u32, y: u32, c: jok.Color) void {
            assert(x < self.width);
            assert(y < self.height);
            const line: [*]u32 = @alignCast(@ptrCast(self.pixels.ptr + y * self.stride));
            line[x] = c.toRGBA32();
        }

        pub inline fn setPixelByIndex(self: PixelData, index: u32, c: jok.Color) void {
            const x = index % self.width;
            const y = index / self.width;
            self.setPixel(x, y, c);
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
        if (sdl.SDL_LockTexture(
            self.ptr,
            if (region) |r| @ptrCast(&r) else null,
            &pixels,
            &pitch,
        ) != 0) {
            log.err("lock texture failed: {s}", .{sdl.SDL_GetError()});
            return sdl.Error.SdlError;
        }
        sdl.SDL_UnlockTexture(self.ptr);

        const width = if (region) |r| r.width else info.width;
        const height = if (region) |r| r.height else info.height;
        const bufsize = @as(u32, @intCast(pitch)) * height;
        const buf = try allocator.alloc(u8, bufsize);
        return .{
            .allocator = allocator,
            .region = region,
            .pixels = buf,
            .stride = @intCast(pitch),
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
        if (sdl.SDL_LockTexture(
            self.ptr,
            if (data.region) |r| @ptrCast(&r) else null,
            &pixels,
            &pitch,
        ) != 0) {
            log.err("lock texture failed: {s}", .{sdl.SDL_GetError()});
            return sdl.Error.SdlError;
        }
        assert(@as(u32, @intCast(pitch)) == data.stride);
        var pixelbuf: []u8 = undefined;
        pixelbuf.ptr = @ptrCast(pixels.?);
        pixelbuf.len = data.pixels.len;
        @memcpy(pixelbuf, data.pixels);
        sdl.SDL_UnlockTexture(self.ptr);
    }
};
