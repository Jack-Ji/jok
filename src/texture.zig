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
            .access = @enumFromInt(access),
        };
    }

    // This is a fairly slow function, intended for use with static textures that do not change often.
    pub fn update(self: Texture, pixels: []const u8) !void {
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
};
