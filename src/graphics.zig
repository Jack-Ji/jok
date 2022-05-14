const std = @import("std");
const assert = std.debug.assert;
const jok = @import("jok.zig");
const sdl = @import("sdl");
const native_endian = @import("builtin").target.cpu.arch.endian();
const stb = jok.deps.stb;

pub const Texture = sdl.Texture;

inline fn getChannels(format: Texture.Format) u32 {
    return switch (format) {
        .rgb888, .bgr888 => @as(u32, 3),
        .rgba8888, .abgr8888 => @as(u32, 4),
        else => unreachable,
    };
}

/// create texture from pixel data
pub fn createTextureFromPixels(
    renderer: sdl.Renderer,
    pixels: ?[]const u8,
    format: sdl.PixelFormatEnum,
    access: Texture.Access,
    width: u32,
    height: u32,
) !Texture {
    var tex = try sdl.createTexture(renderer, format, access, width, height);
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

/// create texture from image
pub fn createTextureFromFile(
    renderer: sdl.Renderer,
    image_file: [:0]const u8,
    access: Texture.Access,
    flip: bool,
) !Texture {
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
        switch (native_endian) {
            .Big => .rgba8888,
            .Little => .abgr8888,
        },
        access,
        @intCast(u32, width),
        @intCast(u32, height),
    );
}
