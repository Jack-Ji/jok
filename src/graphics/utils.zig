const std = @import("std");
const assert = std.debug.assert;
const jok = @import("../jok.zig");
const sdl = @import("sdl");
const native_endian = @import("builtin").target.cpu.arch.endian();
const stb = jok.deps.stb;

pub const Error = error{
    LoadImageError,
    EncodeTextureFailed,
};

/// Get # of channels from pixel format
pub inline fn getChannels(format: sdl.Texture.Format) u32 {
    return switch (format) {
        .rgb888, .bgr888 => @as(u32, 3),
        .rgba8888, .abgr8888 => @as(u32, 4),
        else => unreachable,
    };
}

/// Get appropriate 4-channel pixel format from endian
pub inline fn getFormatByEndian() sdl.Texture.Format {
    return switch (native_endian) {
        .Big => .rgba8888,
        .Little => .abgr8888,
    };
}

/// Create texture from pixel data
pub fn createTextureFromPixels(
    renderer: sdl.Renderer,
    pixels: ?[]const u8,
    format: sdl.PixelFormatEnum,
    access: sdl.Texture.Access,
    width: u32,
    height: u32,
) !sdl.Texture {
    var tex = try sdl.createTexture(renderer, format, access, width, height);
    try tex.setBlendMode(.blend); // Enable alpha blending by default
    errdefer tex.destroy();

    const stride = getChannels(format) * width;
    if (pixels) |px| {
        if (access == .streaming) {
            var data = try tex.lock(null);
            defer data.release();
            var i: u32 = 0;
            while (i < height) : (i += 1) {
                const line = data.scanline(@as(usize, i), u8);
                std.mem.copy(
                    u8,
                    line[0..stride],
                    px[i * stride .. (i + 1) * stride],
                );
            }
        } else {
            try tex.update(px, stride, null);
        }
    }
    return tex;
}

/// Create texture from image
pub fn createTextureFromFile(
    renderer: sdl.Renderer,
    image_file: [:0]const u8,
    access: sdl.Texture.Access,
    flip: bool,
) !sdl.Texture {
    var width: c_int = undefined;
    var height: c_int = undefined;
    var channels: c_int = undefined;

    stb.image.stbi_set_flip_vertically_on_load(@boolToInt(flip));
    var image_data = stb.image.stbi_load(
        image_file.ptr,
        &width,
        &height,
        &channels,
        4,
    );
    if (image_data == null) {
        return error.LoadImageError;
    }
    assert(channels == 3 or channels == 4);
    defer stb.image.stbi_image_free(image_data);

    return try createTextureFromPixels(
        renderer,
        image_data[0..@intCast(u32, width * height * channels)],
        getFormatByEndian(),
        access,
        @intCast(u32, width),
        @intCast(u32, height),
    );
}

/// Save texture into encoded format (png/bmp/tga/jpg) on disk
pub const EncodingOption = struct {
    format: enum { png, bmp, tga, jpg } = .png,
    png_compress_level: u8 = 8,
    tga_rle_compress: bool = true,
    jpg_quality: u8 = 75, // Between 1 and 100
    flip_on_write: bool = false,
};
pub fn savePixelsToFile(
    pixels: []const u8,
    width: u32,
    height: u32,
    format: sdl.Texture.Format,
    path: [:0]const u8,
    option: EncodingOption,
) !void {
    var channels = getChannels(format);
    assert(pixels.len == @intCast(usize, width * height * channels));

    // Encode file
    var result: c_int = undefined;
    stb.image.stbi_flip_vertically_on_write(@boolToInt(option.flip_on_write));
    switch (option.format) {
        .png => {
            stb.image.stbi_write_png_compression_level =
                @intCast(c_int, option.png_compress_level);
            result = stb.image.stbi_write_png(
                path,
                @intCast(c_int, width),
                @intCast(c_int, height),
                @intCast(c_int, channels),
                pixels.ptr,
                @intCast(c_int, width * channels),
            );
        },
        .bmp => {
            result = stb.image.stbi_write_bmp(
                path,
                @intCast(c_int, width),
                @intCast(c_int, height),
                @intCast(c_int, channels),
                pixels.ptr,
            );
        },
        .tga => {
            stb.image.stbi_write_tga_with_rle =
                if (option.tga_rle_compress) 1 else 0;
            result = stb.image.stbi_write_tga(
                path,
                @intCast(c_int, width),
                @intCast(c_int, height),
                @intCast(c_int, channels),
                pixels.ptr,
            );
        },
        .jpg => {
            result = stb.image.stbi_write_jpg(
                path,
                @intCast(c_int, width),
                @intCast(c_int, height),
                @intCast(c_int, channels),
                pixels.ptr,
                @intCast(c_int, @intCast(c_int, std.math.clamp(option.jpg_quality, 1, 100))),
            );
        },
    }
    if (result == 0) {
        return error.EncodeTextureFailed;
    }
}

/// Convert radian to degree
pub inline fn radianToDegree(r: f32) f32 {
    return r * 180.0 / std.math.pi;
}

/// Convert degree to radian
pub inline fn degreeToRadian(d: f32) f32 {
    return d * std.math.pi / 180.0;
}
