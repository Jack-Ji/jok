const std = @import("std");
const assert = std.debug.assert;
const jok = @import("../jok.zig");
const physfs = jok.physfs;
const stb = jok.stb;

pub const Error = error{
    EncodeTextureFailed,
};

/// Save texture into encoded format (png/bmp/tga/jpg) on disk
pub const EncodingOption = struct {
    format: enum { png, bmp, tga, jpg } = .png,
    png_compress_level: u8 = 8,
    tga_rle_compress: bool = true,
    jpg_quality: u8 = 75, // Between 1 and 100
    flip_on_write: bool = false,
};
pub fn savePixelsToFile(
    ctx: jok.Context,
    pixels: []const u8,
    width: u32,
    height: u32,
    path: [*:0]const u8,
    opt: EncodingOption,
) !void {
    const channels = 4;
    assert(pixels.len == @as(usize, width * height * channels));

    // Encode file
    var result: c_int = undefined;
    stb.image.stbi_flip_vertically_on_write(@intFromBool(opt.flip_on_write));

    if (ctx.cfg().jok_enable_physfs) {
        const handle = try physfs.open(path, .write);
        defer handle.close();

        switch (opt.format) {
            .png => {
                stb.image.stbi_write_png_compression_level =
                    @as(c_int, opt.png_compress_level);
                result = stb.image.stbi_write_png_to_func(
                    physfs.stb.writeCallback,
                    @ptrCast(@constCast(&handle)),
                    @intCast(width),
                    @intCast(height),
                    channels,
                    pixels.ptr,
                    @intCast(width * channels),
                );
            },
            .bmp => {
                result = stb.image.stbi_write_bmp_to_func(
                    physfs.stb.writeCallback,
                    @ptrCast(@constCast(&handle)),
                    @intCast(width),
                    @intCast(height),
                    channels,
                    pixels.ptr,
                );
            },
            .tga => {
                stb.image.stbi_write_tga_with_rle =
                    if (opt.tga_rle_compress) 1 else 0;
                result = stb.image.stbi_write_tga_to_func(
                    physfs.stb.writeCallback,
                    @ptrCast(@constCast(&handle)),
                    @intCast(width),
                    @intCast(height),
                    channels,
                    pixels.ptr,
                );
            },
            .jpg => {
                result = stb.image.stbi_write_jpg_to_func(
                    physfs.stb.writeCallback,
                    @ptrCast(@constCast(&handle)),
                    @intCast(width),
                    @intCast(height),
                    channels,
                    pixels.ptr,
                    @intCast(@as(c_int, std.math.clamp(opt.jpg_quality, 1, 100))),
                );
            },
        }
    } else {
        switch (opt.format) {
            .png => {
                stb.image.stbi_write_png_compression_level =
                    @as(c_int, opt.png_compress_level);
                result = stb.image.stbi_write_png(
                    path,
                    @intCast(width),
                    @intCast(height),
                    channels,
                    pixels.ptr,
                    @intCast(width * channels),
                );
            },
            .bmp => {
                result = stb.image.stbi_write_bmp(
                    path,
                    @intCast(width),
                    @intCast(height),
                    channels,
                    pixels.ptr,
                );
            },
            .tga => {
                stb.image.stbi_write_tga_with_rle =
                    if (opt.tga_rle_compress) 1 else 0;
                result = stb.image.stbi_write_tga(
                    path,
                    @intCast(width),
                    @intCast(height),
                    channels,
                    pixels.ptr,
                );
            },
            .jpg => {
                result = stb.image.stbi_write_jpg(
                    path,
                    @intCast(width),
                    @intCast(height),
                    channels,
                    pixels.ptr,
                    @intCast(@as(c_int, std.math.clamp(opt.jpg_quality, 1, 100))),
                );
            },
        }
    }

    if (result == 0) {
        return error.EncodeTextureFailed;
    }
}
