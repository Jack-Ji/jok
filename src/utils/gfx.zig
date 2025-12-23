const std = @import("std");
const assert = std.debug.assert;
const jok = @import("../jok.zig");
const physfs = jok.vendor.physfs;
const stb = jok.vendor.stb;

pub const Error = error{
    EncodeTextureFailed,
    InvalidFootage,
    InvalidChecksum,
    CustomDataTooBig,
};

/// Decode image file's pixels into memory (always RGBA format)
pub const FilePixels = struct {
    allocator: std.mem.Allocator,
    pixels: []const u8, // RGBA data
    size: jok.Size,

    pub fn destroy(self: FilePixels) void {
        self.allocator.free(self.pixels);
    }
};
pub fn loadPixelsFromFile(ctx: jok.Context, path: [:0]const u8, flip: bool) !FilePixels {
    const allocator = ctx.allocator();

    var filedata: []u8 = undefined;
    if (ctx.cfg().jok_enable_physfs) {
        const handle = try physfs.open(path, .read);
        defer handle.close();

        filedata = try handle.readAllAlloc(allocator);
    } else {
        const stat = try std.Io.Dir.statPath(
            std.Io.Dir.cwd(),
            ctx.io(),
            std.mem.sliceTo(path, 0),
            .{ .follow_symlinks = false },
        );
        filedata = try allocator.alloc(u8, @intCast(stat.size));
        _ = try std.Io.Dir.readFile(
            std.Io.Dir.cwd(),
            ctx.io(),
            std.mem.sliceTo(path, 0),
            filedata,
        );
    }
    defer allocator.free(filedata);

    var width: c_int = undefined;
    var height: c_int = undefined;
    var channels: c_int = undefined;

    stb.image.stbi_set_flip_vertically_on_load(@intFromBool(flip));
    const image_data = stb.image.stbi_load_from_memory(
        filedata.ptr,
        @intCast(filedata.len),
        &width,
        &height,
        &channels,
        4,
    );
    if (image_data == null) {
        return error.LoadImageError;
    }
    assert(channels >= 3);
    defer stb.image.stbi_image_free(image_data);

    const size = @as(u32, @intCast(width * height * 4));
    const pixels = try allocator.alloc(u8, size);
    @memcpy(pixels, image_data[0..size]);
    return .{
        .allocator = allocator,
        .pixels = pixels,
        .size = .{
            .width = @intCast(width),
            .height = @intCast(height),
        },
    };
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
    ctx: jok.Context,
    pixels: []const u8,
    width: u32,
    height: u32,
    path: [:0]const u8,
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
    const Flags = packed struct(u8) {
        compressed: bool,
        encrypted: bool = false,
        dummy: u6 = 0,
    };

    // Magic string at end of file
    const magic = [_]u8{ 'p', 'n', 'g', '@', 'j', 'o', 'k' };

    // Maximum size of custom data (64MB)
    const max_custom_size = (1 << 26);

    // Buffer for compressing
    var compress_buf: [std.compress.flate.max_window_len]u8 = undefined;

    pub const SaveOption = struct {
        png_compress_level: u8 = 8,
        data_compress_options: ?std.compress.flate.Compress.Options = .level_4,
    };

    /// Save texture in jpng format
    pub fn save(
        ctx: jok.Context,
        pixels: []const u8,
        width: u32,
        height: u32,
        path: [:0]const u8,
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
            var handle = try physfs.open(path, .append);
            defer handle.close();

            try writeData(ctx, &handle.writer, data, opt);
        } else {
            const file = try std.fs.cwd().openFile(
                std.mem.sliceTo(path, 0),
                .{ .mode = .write_only },
            );
            defer file.close();

            var fwriter = file.writer(&.{});
            fwriter.pos = (try file.stat()).size;
            try writeData(ctx, &fwriter.interface, data, opt);
        }
    }

    /// Read pixels and custom data (always RGBA format)
    pub const PixelData = struct {
        allocator: std.mem.Allocator,
        pixels: []const u8, // RGBA data
        size: jok.Size,
        data: []const u8, // custom data

        pub fn destroy(self: PixelData) void {
            self.allocator.free(self.pixels);
            self.allocator.free(self.data);
        }
    };
    pub fn loadPixels(ctx: jok.Context, path: [:0]const u8, flip: bool) !PixelData {
        const allocator = ctx.allocator();

        var data: []const u8 = undefined;
        if (ctx.cfg().jok_enable_physfs) {
            const handle = try physfs.open(path, .read);
            defer handle.close();

            data = try handle.readAllAlloc(allocator);
        } else {
            const file = try std.Io.Dir.openFile(
                std.Io.Dir.cwd(),
                ctx.io(),
                std.mem.sliceTo(path, 0),
                .{ .mode = .read_only },
            );
            defer file.close(ctx.io());

            var reader = file.reader(ctx.io(), &.{});
            const size = try reader.getSize();
            data = try reader.interface.readAlloc(allocator, @intCast(size));
        }
        defer allocator.free(data);

        if (!std.mem.endsWith(u8, data, &magic)) {
            return error.InvalidFootage;
        }

        const flags: Flags = @bitCast(data[data.len - 8]);
        const custom_data_size = std.mem.readVarInt(u32, data[data.len - 12 .. data.len - 8], .big);
        assert(custom_data_size <= max_custom_size);
        const png_data = data[0 .. data.len - 16 - custom_data_size];

        // Decode image data
        var width: c_int = undefined;
        var height: c_int = undefined;
        var channels: c_int = undefined;
        stb.image.stbi_set_flip_vertically_on_load(@intFromBool(flip));
        const image_data = stb.image.stbi_load_from_memory(
            png_data.ptr,
            @intCast(png_data.len),
            &width,
            &height,
            &channels,
            4,
        );
        if (image_data == null) {
            return error.LoadImageError;
        }
        assert(channels >= 3);
        defer stb.image.stbi_image_free(image_data);
        const size = @as(u32, @intCast(width * height * 4));
        const pixels = try allocator.alloc(u8, size);
        errdefer allocator.free(pixels);
        @memcpy(pixels, image_data[0..size]);

        // Check CRC of custom data
        const checksum = std.mem.readVarInt(u32, data[data.len - 16 .. data.len - 12], .big);
        const custom_data = data[data.len - 16 - custom_data_size .. data.len - 16];
        if (std.hash.Crc32.hash(custom_data) != checksum) {
            return error.InvalidChecksum;
        }

        if (flags.compressed) {
            var bufreader = std.Io.Reader.fixed(custom_data);
            var decompress = std.compress.flate.Decompress.init(&bufreader, .gzip, &compress_buf);
            const databuf = try allocator.alloc(u8, 1 << 27);
            defer allocator.free(databuf);
            const datasize = try decompress.reader.readSliceShort(databuf);
            return .{
                .allocator = allocator,
                .pixels = pixels,
                .size = .{
                    .width = @intCast(width),
                    .height = @intCast(height),
                },
                .data = try allocator.dupe(u8, databuf[0..datasize]),
            };
        } else {
            const cloned_custom = try allocator.alloc(u8, custom_data.len);
            @memcpy(cloned_custom, custom_data);
            return .{
                .allocator = allocator,
                .pixels = pixels,
                .size = .{
                    .width = @intCast(width),
                    .height = @intCast(height),
                },
                .data = cloned_custom,
            };
        }
    }

    /// Load texture and custom data
    pub const TextureData = struct {
        tex: jok.Texture,
        data: []const u8, // custom data, **SHOULD BE FREED BY CALLER**
    };
    pub fn loadTexture(ctx: jok.Context, path: [:0]const u8, access: jok.Texture.Access, flip: bool) !TextureData {
        const pixeldata = try loadPixels(ctx, path, flip);
        errdefer pixeldata.destroy();
        const tex = try ctx.renderer().createTexture(
            pixeldata.size,
            pixeldata.pixels,
            .{ .access = access },
        );
        ctx.allocator().free(pixeldata.pixels);
        return .{
            .tex = tex,
            .data = pixeldata.data,
        };
    }

    inline fn writeData(ctx: jok.Context, writer: *std.Io.Writer, data: []const u8, opt: SaveOption) !void {
        const flags = Flags{
            .compressed = opt.data_compress_options != null,
        };
        if (opt.data_compress_options) |compress_opt| {
            const writebuf = try ctx.allocator().alloc(u8, data.len);
            defer ctx.allocator().free(writebuf);
            var bufwriter = std.Io.Writer.fixed(writebuf);
            var compress = try std.compress.flate.Compress.init(
                &bufwriter,
                &compress_buf,
                .gzip,
                compress_opt,
            );
            try compress.writer.writeAll(data);
            try compress.writer.flush();
            const deflated = bufwriter.buffered();
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
