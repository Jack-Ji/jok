const std = @import("std");
const assert = std.debug.assert;
const jok = @import("../jok.zig");
const physfs = jok.physfs;
const stb = jok.stb;

pub const Error = error{
    EncodeTextureFailed,
    InvalidFootage,
    InvalidChecksum,
    CustomDataTooBig,
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

/// PNG file with customly appended data.
///
/// Overall Structure:
///   +----------------------------------------+
///   |                                        |
///   |                                        |
///   |            PNG File Data               |
///   |                                        |
///   |                                        |
///   +----------------------------------------+
///   |                                        |
///   |             Custom Data                |
///   |                                        |
///   +----------------------------------------+
///   |  CRC (4 bytes) |  Data Length (4 byte) |
///   +----------------------------------------+
///   | Flags (1 byte) | Magic String (7 byte) |
///   +----------------------------------------+
///
/// Flags:
///    7 6 5 4 3 2 1 0
///   +---------------+
///   |x|x|x|x|x|x|E|C|
///   +---------------+
///                ^ ^
///                | |
///                | +--- Compress Bit
///                +--- Encryption Bit (not implemented)
///
pub const jpng = struct {
    const CompressLevel = std.compress.flate.deflate.Level;
    const Flags = packed struct(u8) {
        compressed: bool,
        encrypted: bool = false,
        dummy: u6 = 0,
    };

    /// Magic string at end of file
    const magic = [_]u8{ 'p', 'n', 'g', '@', 'j', 'o', 'k' };

    /// Maximum size of custom data (64MB)
    const max_custom_size = (1 << 26);

    pub const SaveOption = struct {
        png_compress_level: u8 = 8,
        data_compress_level: ?CompressLevel = .level_4,
    };

    /// Save texture in jpng format
    pub fn save(
        ctx: jok.Context,
        pixels: []const u8,
        width: u32,
        height: u32,
        path: [*:0]const u8,
        data: []const u8,
        opt: SaveOption,
    ) !void {
        if (data.len > max_custom_size) {
            return error.CustomDataTooBig;
        }

        try savePixelsToFile(
            ctx,
            pixels,
            width,
            height,
            path,
            .{
                .format = .png,
                .png_compress_level = opt.png_compress_level,
            },
        );

        if (ctx.cfg().jok_enable_physfs) {
            const handle = try physfs.open(path, .append);
            defer handle.close();

            try writeData(ctx, handle.writer(), data, opt);
        } else {
            const file = try std.fs.cwd().openFileZ(path, .{ .mode = .write_only });
            defer file.close();

            _ = try file.seekFromEnd(0);
            try writeData(ctx, file.writer(), data, opt);
        }
    }

    /// Read jpng with custom data
    pub fn load(ctx: jok.Context, path: [*:0]const u8, access: jok.Texture.Access) !struct {
        tex: jok.Texture,
        data: []const u8,
    } {
        const allocator = ctx.allocator();

        var data: []const u8 = undefined;
        if (ctx.cfg().jok_enable_physfs) {
            const handle = try physfs.open(path, .read);
            defer handle.close();

            data = try handle.readAllAlloc(allocator);
        } else {
            const file = try std.fs.cwd().openFileZ(path, .{ .mode = .read_only });
            defer file.close();

            data = try file.readToEndAlloc(allocator, 1 << 30);
        }
        defer allocator.free(data);

        if (!std.mem.eql(u8, &magic, data[data.len - 7 ..])) {
            return error.InvalidFootage;
        }

        const flags: Flags = @bitCast(data[data.len - 8]);
        const custom_data_size = std.mem.readVarInt(u32, data[data.len - 12 .. data.len - 8], .big);
        assert(custom_data_size <= max_custom_size);
        const png_data = data[0 .. data.len - 16 - custom_data_size];
        const tex = try ctx.renderer().createTextureFromFileData(png_data, access, false);
        errdefer tex.destroy();

        const checksum = std.mem.readVarInt(u32, data[data.len - 16 .. data.len - 12], .big);
        const custom_data = data[data.len - 16 - custom_data_size .. data.len - 16];
        if (std.hash.Crc32.hash(custom_data) != checksum) {
            return error.InvalidChecksum;
        }

        if (flags.compressed) {
            var read_stream = std.io.fixedBufferStream(custom_data);
            var write_stream = std.ArrayList(u8).init(allocator);
            defer write_stream.deinit();
            try std.compress.gzip.decompress(read_stream.reader(), write_stream.writer());
            return .{
                .tex = tex,
                .data = try write_stream.toOwnedSlice(),
            };
        } else {
            const cloned_custom = try allocator.alloc(u8, custom_data.len);
            @memcpy(cloned_custom, custom_data);
            return .{
                .tex = tex,
                .data = cloned_custom,
            };
        }
    }

    inline fn writeData(ctx: jok.Context, writer: anytype, data: []const u8, opt: SaveOption) !void {
        const flags = Flags{
            .compressed = opt.data_compress_level != null,
        };
        if (opt.data_compress_level) |lvl| {
            var read_stream = std.io.fixedBufferStream(data);
            const writebuf = try ctx.allocator().alloc(u8, data.len);
            defer ctx.allocator().free(writebuf);
            var write_stream = std.io.fixedBufferStream(writebuf);
            try std.compress.gzip.compress(
                read_stream.reader(),
                write_stream.writer(),
                .{ .level = lvl },
            );
            const deflated = write_stream.getWritten();
            try writer.writeAll(deflated);
            const checksum = std.hash.Crc32.hash(deflated);
            try writer.writeInt(u32, checksum, .big);
            try writer.writeInt(u32, @intCast(deflated.len), .big);
        } else {
            try writer.writeAll(data);
            const checksum = std.hash.Crc32.hash(data);
            try writer.writeInt(u32, checksum, .big);
            try writer.writeInt(u32, @intCast(data.len), .big);
        }
        try writer.writeByte(@bitCast(flags));
        try writer.writeAll(&magic);
    }
};
