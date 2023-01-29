const std = @import("std");
const assert = std.debug.assert;
const sdl = @import("sdl");
const jok = @import("../jok.zig");
const native_endian = @import("builtin").target.cpu.arch.endian();
const stb = jok.stb;

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
    opt: EncodingOption,
) !void {
    var channels = getChannels(format);
    assert(pixels.len == @intCast(usize, width * height * channels));

    // Encode file
    var result: c_int = undefined;
    stb.image.stbi_flip_vertically_on_write(@boolToInt(opt.flip_on_write));
    switch (opt.format) {
        .png => {
            stb.image.stbi_write_png_compression_level =
                @intCast(c_int, opt.png_compress_level);
            result = stb.image.stbi_write_png(
                path.ptr,
                @intCast(c_int, width),
                @intCast(c_int, height),
                @intCast(c_int, channels),
                pixels.ptr,
                @intCast(c_int, width * channels),
            );
        },
        .bmp => {
            result = stb.image.stbi_write_bmp(
                path.ptr,
                @intCast(c_int, width),
                @intCast(c_int, height),
                @intCast(c_int, channels),
                pixels.ptr,
            );
        },
        .tga => {
            stb.image.stbi_write_tga_with_rle =
                if (opt.tga_rle_compress) 1 else 0;
            result = stb.image.stbi_write_tga(
                path.ptr,
                @intCast(c_int, width),
                @intCast(c_int, height),
                @intCast(c_int, channels),
                pixels.ptr,
            );
        },
        .jpg => {
            result = stb.image.stbi_write_jpg(
                path.ptr,
                @intCast(c_int, width),
                @intCast(c_int, height),
                @intCast(c_int, channels),
                pixels.ptr,
                @intCast(c_int, @intCast(c_int, std.math.clamp(opt.jpg_quality, 1, 100))),
            );
        },
    }
    if (result == 0) {
        return error.EncodeTextureFailed;
    }
}

/// Save surface to file
pub fn saveSurfaceToFile(surface: sdl.Surface, path: [:0]const u8, opt: EncodingOption) !void {
    const format = @intToEnum(sdl.PixelFormatEnum, surface.ptr.format.*.format);
    var channels = getChannels(format);
    const pixels = @ptrCast([*]const u8, surface.ptr.pixels.?);
    const size = @intCast(usize, surface.ptr.w * surface.ptr.h * channels);
    assert(surface.ptr.h * surface.ptr.pitch == size);
    try savePixelsToFile(
        pixels[0..size],
        @intCast(u32, surface.ptr.w),
        @intCast(u32, surface.ptr.h),
        format,
        path,
        opt,
    );
}

pub const RenderToTexture = struct {
    target: ?sdl.Texture = null,
    size: ?sdl.Point = null,
    clear_color: ?sdl.Color = null,
};

/// Render to texture and return it.
/// `renderer` can be any struct with method `fn draw(sdl.Renderer) !void`
pub fn renderToTexture(rd: sdl.Renderer, renderer: anytype, opt: RenderToTexture) !sdl.Texture {
    const old_target = sdl.c.SDL_GetRenderTarget(rd.ptr);
    const target = opt.target orelse BLK: {
        const size = opt.size orelse BLK2: {
            const vp = rd.getViewport();
            break :BLK2 sdl.Point{ .x = vp.width, .y = vp.height };
        };
        const tex = try sdl.createTexture(
            rd,
            getFormatByEndian(),
            .target,
            @intCast(usize, size.x),
            @intCast(usize, size.y),
        );
        try tex.setBlendMode(.blend);
        break :BLK tex;
    };
    try rd.setTarget(target);
    defer _ = sdl.c.SDL_SetRenderTarget(rd.ptr, old_target);

    const old_blend_mode = try rd.getDrawBlendMode();
    try rd.setDrawBlendMode(.none);
    defer rd.setDrawBlendMode(old_blend_mode) catch unreachable;

    const old_color = try rd.getColor();
    const color = opt.clear_color orelse sdl.Color.rgba(0, 0, 0, 0);
    try rd.setColor(color);
    defer rd.setColor(old_color) catch unreachable;

    try rd.clear();
    try renderer.draw(rd);

    return target;
}
