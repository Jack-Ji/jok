const std = @import("std");
const assert = std.debug.assert;
const jok = @import("../jok.zig");
const sdl = jok.sdl;
const physfs = jok.physfs;
const native_endian = @import("builtin").target.cpu.arch.endian();
const stb = jok.stb;

pub const Error = error{
    LoadImageError,
    EncodeTextureFailed,
    TargetTooLarge,
};

/// Get # of channels from pixel format
pub inline fn getChannels(format: sdl.PixelFormatEnum) u32 {
    return switch (format) {
        .rgb888, .bgr888 => @as(u32, 3),
        .rgba8888, .abgr8888 => @as(u32, 4),
        else => unreachable,
    };
}

/// Get appropriate 4-channel pixel format from endian
pub inline fn getFormatByEndian() sdl.PixelFormatEnum {
    return switch (native_endian) {
        .big => .rgba8888,
        .little => .abgr8888,
    };
}

/// Create texture from uncompressed pixel data
pub fn createTextureFromPixels(
    ctx: jok.Context,
    pixels: ?[]const u8,
    format: ?sdl.PixelFormatEnum,
    access: sdl.Texture.Access,
    width: u32,
    height: u32,
) !sdl.Texture {
    var tex = try sdl.createTexture(
        ctx.renderer(),
        format orelse getFormatByEndian(),
        access,
        width,
        height,
    );
    try tex.setBlendMode(.blend); // Enable alpha blending by default
    errdefer tex.destroy();

    const stride = getChannels(format orelse getFormatByEndian()) * width;
    if (pixels) |px| {
        if (access == .streaming) {
            var data = try tex.lock(null);
            defer data.release();
            var i: u32 = 0;
            while (i < height) : (i += 1) {
                const line = data.scanline(@as(usize, i), u8);
                @memcpy(line[0..stride], px[i * stride .. (i + 1) * stride]);
            }
        } else {
            try tex.update(px, stride, null);
        }
    }
    return tex;
}

/// Create texture from image file
pub fn createTextureFromFile(
    ctx: jok.Context,
    image_file: [*:0]const u8,
    access: sdl.Texture.Access,
    flip: bool,
) !sdl.Texture {
    if (ctx.cfg().jok_enable_physfs) {
        const handle = try physfs.open(image_file, .read);
        defer handle.close();

        const filedata = try handle.readAllAlloc(ctx.allocator());
        defer ctx.allocator().free(filedata);

        return try createTextureFromFileData(
            ctx,
            filedata,
            access,
            flip,
        );
    } else {
        const filedata = try std.fs.cwd().readFileAlloc(ctx.allocator(), std.mem.sliceTo(image_file, 0), 1 << 30);
        defer ctx.allocator().free(filedata);

        return try createTextureFromFileData(
            ctx,
            filedata,
            access,
            flip,
        );
    }
}

/// Create texture from image data
pub fn createTextureFromFileData(
    ctx: jok.Context,
    file_data: []const u8,
    access: sdl.Texture.Access,
    flip: bool,
) !sdl.Texture {
    var width: c_int = undefined;
    var height: c_int = undefined;
    var channels: c_int = undefined;

    stb.image.stbi_set_flip_vertically_on_load(@intFromBool(flip));
    var image_data = stb.image.stbi_load_from_memory(
        file_data.ptr,
        @intCast(file_data.len),
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
        ctx,
        image_data[0..@as(u32, @intCast(width * height * channels))],
        getFormatByEndian(),
        access,
        @intCast(width),
        @intCast(height),
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
    ctx: jok.Context,
    pixels: []const u8,
    width: u32,
    height: u32,
    format: ?sdl.PixelFormatEnum,
    path: [*:0]const u8,
    opt: EncodingOption,
) !void {
    const channels = getChannels(format orelse getFormatByEndian());
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
                    @intCast(channels),
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
                    @intCast(channels),
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
                    @intCast(channels),
                    pixels.ptr,
                );
            },
            .jpg => {
                result = stb.image.stbi_write_jpg_to_func(
                    physfs.stb.writeCallback,
                    @ptrCast(@constCast(&handle)),
                    @intCast(width),
                    @intCast(height),
                    @intCast(channels),
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
                    @intCast(channels),
                    pixels.ptr,
                    @intCast(width * channels),
                );
            },
            .bmp => {
                result = stb.image.stbi_write_bmp(
                    path,
                    @intCast(width),
                    @intCast(height),
                    @intCast(channels),
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
                    @intCast(channels),
                    pixels.ptr,
                );
            },
            .jpg => {
                result = stb.image.stbi_write_jpg(
                    path,
                    @intCast(width),
                    @intCast(height),
                    @intCast(channels),
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

/// Save surface to file
pub fn saveSurfaceToFile(ctx: jok.Context, surface: sdl.Surface, path: [*:0]const u8, opt: EncodingOption) !void {
    const format = @as(sdl.PixelFormatEnum, @enumFromInt(surface.ptr.format.*.format));
    const channels = getChannels(format);
    const pixels = @as([*]const u8, @ptrCast(surface.ptr.pixels.?));
    const size = @as(usize, surface.ptr.w * surface.ptr.h * channels);
    assert(surface.ptr.h * surface.ptr.pitch == size);
    try savePixelsToFile(
        ctx,
        pixels[0..size],
        @intCast(surface.ptr.w),
        @intCast(surface.ptr.h),
        format,
        path,
        opt,
    );
}

/// Read pixels from screen
pub fn getScreenPixels(ctx: jok.Context, rect: ?sdl.Rectangle) !struct {
    _ctx: jok.Context,
    format: sdl.PixelFormatEnum,
    pixels: []u8,
    width: u32,
    height: u32,

    pub fn destroy(self: @This()) void {
        self._ctx.allocator().free(self.pixels);
    }

    pub fn createTexture(self: @This()) !sdl.Texture {
        return try createTextureFromPixels(
            self._ctx,
            self.pixels,
            self.format,
            .static,
            self.width,
            self.height,
        );
    }

    pub fn saveToFile(self: @This(), path: [:0]const u8, opt: EncodingOption) !void {
        try savePixelsToFile(self._ctx, self.pixels, self.width, self.height, self.format, path, opt);
    }
} {
    const format = getFormatByEndian();
    const channels = @as(c_int, @intCast(getChannels(format)));
    const csz = ctx.getCanvasSize();
    const width = if (rect) |r| r.width else @as(c_int, @intFromFloat(csz.x));
    const height = if (rect) |r| r.height else @as(c_int, @intFromFloat(csz.y));
    const pixel_size = @as(usize, @intCast(channels * width * height));
    const pixels = try ctx.allocator().alloc(u8, pixel_size);
    try ctx.renderer().readPixels(rect, format, pixels.ptr, @intCast(channels * width));
    return .{
        ._ctx = ctx,
        .format = format,
        .pixels = pixels,
        .width = @intCast(width),
        .height = @intCast(height),
    };
}

/// Take screenshot and save to file, **slow**
pub fn saveScreenToFile(
    allocator: std.mem.Allocator,
    rd: sdl.Renderer,
    rect: ?sdl.Rectangle,
    path: [:0]const u8,
    opt: EncodingOption,
) !void {
    const data = try getScreenPixels(allocator, rd, rect);
    defer data.destroy();
    try data.saveToFile(path, opt);
}

/// Create texture for offscreen rendering
pub const CreateTarget = struct {
    size: ?sdl.Size = null,
    blend_mode: sdl.BlendMode = .none,
    scale_mode: sdl.ScaleMode = .linear,
};
pub fn createTextureAsTarget(ctx: jok.Context, opt: CreateTarget) !sdl.Texture {
    const size = opt.size orelse BLK: {
        const csz = ctx.getCanvasSize();
        break :BLK sdl.Size{
            .width = @intFromFloat(csz.x),
            .height = @intFromFloat(csz.y),
        };
    };
    const rdinfo = ctx.renderer().getInfo() catch unreachable;
    if (size.width > rdinfo.max_texture_width or size.height > rdinfo.max_texture_height) {
        return error.TargetTooLarge;
    }
    const tex = try sdl.createTexture(
        ctx.renderer(),
        getFormatByEndian(),
        .target,
        @intCast(size.width),
        @intCast(size.height),
    );
    try tex.setBlendMode(opt.blend_mode);
    try tex.setScaleMode(opt.scale_mode);
    return tex;
}

/// Render to texture and return it. `renderer` can be any struct instance with method:
///   fn draw(self: @This(), ctx: jok.Context, size: sdl.PointF) !void
///
/// NOTE: This is not elegant at all, you probably would want to pass offscreen target to
///       j2d.begin/j3d.begin directly.
pub const RenderToTexture = struct {
    target: ?sdl.Texture = null,
    size: ?sdl.Size = null,
    clear_color: ?sdl.Color = null,
};
pub fn renderToTexture(ctx: jok.Context, renderer: anytype, opt: RenderToTexture) !sdl.Texture {
    const rd = ctx.renderer();
    const old_target = rd.getTarget();
    const target = opt.target orelse try createTextureAsTarget(
        ctx,
        .{ .size = opt.size },
    );
    const tex_info = try target.query();
    assert(tex_info.access == .target);
    try rd.setTarget(target);
    defer rd.setTarget(old_target) catch unreachable;

    const old_blend_mode = try rd.getDrawBlendMode();
    try rd.setDrawBlendMode(.none);
    defer rd.setDrawBlendMode(old_blend_mode) catch unreachable;

    if (opt.clear_color) |c| {
        const old_color = try rd.getColor();
        try rd.setColor(c);
        try rd.clear();
        try rd.setColor(old_color);
    }
    try renderer.draw(ctx, .{
        .x = @floatFromInt(tex_info.width),
        .y = @floatFromInt(tex_info.height),
    });
    return target;
}
