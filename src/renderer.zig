const std = @import("std");
const assert = std.debug.assert;
const jok = @import("jok.zig");
const sdl = jok.sdl;
const physfs = jok.physfs;
const stb = jok.stb;

const log = std.log.scoped(.jok);

pub const Error = error{
    TextureTooLarge,
    LoadImageError,
    EncodeTextureFailed,
};

// Draw call statistics
pub const dcstats = struct {
    pub var drawcall_count: u32 = 0;
    pub var triangle_count: u32 = 0;

    pub fn clear() void {
        drawcall_count = 0;
        triangle_count = 0;
    }
};

pub const Renderer = struct {
    ptr: *sdl.SDL_Renderer,
    cfg: jok.config.Config,

    // Create hardware accelerated renderer
    pub fn init(cfg: jok.config.Config, window: jok.Window) !Renderer {
        var flags: u32 = sdl.SDL_RENDERER_TARGETTEXTURE | sdl.SDL_RENDERER_ACCELERATED;
        if (cfg.jok_fps_limit == .auto) {
            flags |= sdl.SDL_RENDERER_PRESENTVSYNC;
        }
        const ptr = sdl.SDL_CreateRenderer(window.ptr, -1, flags);
        if (ptr == null) {
            log.err("create renderer failed: {s}", .{sdl.SDL_GetError()});
            return sdl.Error.SdlError;
        }

        var rd = Renderer{
            .ptr = ptr.?,
            .cfg = cfg,
        };
        try rd.setBlendMode(.blend);
        const rdinfo = try rd.getInfo();
        assert((rdinfo.flags & sdl.SDL_RENDERER_ACCELERATED) != 0);
        return rd;
    }

    pub fn destroy(self: Renderer) void {
        sdl.SDL_DestroyRenderer(self.ptr);
    }

    pub const Info = struct {
        flags: u32,
        max_texture_width: u32,
        max_texture_height: u32,
    };
    pub fn getInfo(self: Renderer) !Info {
        var result: sdl.SDL_RendererInfo = undefined;
        if (sdl.SDL_GetRendererInfo(self.ptr, &result) < 0) {
            log.err("get renderer's info failed: {s}", .{sdl.SDL_GetError()});
            return sdl.Error.SdlError;
        }
        return .{
            .flags = result.flags,
            .max_texture_width = @intCast(result.max_texture_width),
            .max_texture_height = @intCast(result.max_texture_height),
        };
    }

    pub fn getOutputSize(self: Renderer) !jok.Size {
        var width_pixels: c_int = undefined;
        var height_pixels: c_int = undefined;
        if (sdl.SDL_GetRendererOutputSize(self.ptr, &width_pixels, &height_pixels) < 0) {
            log.err("get renderer's framebuffer size failed: {s}", .{sdl.SDL_GetError()});
            return sdl.Error.SdlError;
        }
        return .{
            .width = @intCast(width_pixels),
            .height = @intCast(height_pixels),
        };
    }

    pub fn clear(self: Renderer, color: jok.Color) !void {
        const old_color = try self.getColor();
        try self.setColor(color);
        defer self.setColor(old_color) catch unreachable;
        if (sdl.SDL_RenderClear(self.ptr) < 0) {
            log.err("clear renderer failed: {s}", .{sdl.SDL_GetError()});
            return sdl.Error.SdlError;
        }
    }

    pub fn present(self: Renderer) void {
        sdl.SDL_RenderPresent(self.ptr);
    }

    pub fn setVsync(self: Renderer, vsync: bool) !void {
        if (sdl.SDL_RenderSetVSync(self.ptr, @intCast(@intFromBool(vsync))) != 0) {
            log.err("set vsync failed: {s}", .{sdl.SDL_GetError()});
            return sdl.Error.SdlError;
        }
    }

    pub fn getClipRegion(self: Renderer) ?jok.Region {
        var rect: sdl.SDL_Rect = undefined;
        sdl.SDL_RenderGetClipRect(self.ptr, &rect);
        if (rect.w == 0 or rect.h == 0) return null;
        return @bitCast(rect);
    }

    pub fn setClipRegion(self: Renderer, clip_region: ?jok.Region) !void {
        if (sdl.SDL_RenderSetClipRect(
            self.ptr,
            if (clip_region) |r| @ptrCast(&r) else null,
        ) < 0) {
            log.err("set clip region failed: {s}", .{sdl.SDL_GetError()});
        }
    }

    pub fn getBlendMode(self: Renderer) !jok.BlendMode {
        var blend_mode: sdl.SDL_BlendMode = undefined;
        if (sdl.SDL_GetRenderDrawBlendMode(self.ptr, &blend_mode) < 0) {
            log.err("get renderer's blend mode failed: {s}", .{sdl.SDL_GetError()});
            return sdl.Error.SdlError;
        }
        return jok.BlendMode.fromNative(blend_mode);
    }

    pub fn setBlendMode(self: Renderer, blend_mode: jok.BlendMode) !void {
        if (sdl.SDL_SetRenderDrawBlendMode(self.ptr, blend_mode.toNative()) < 0) {
            log.err("set renderer's blend mode to {s} failed: {s}", .{ @tagName(blend_mode), sdl.SDL_GetError() });
            return sdl.Error.SdlError;
        }
    }

    pub fn getColor(self: Renderer) !jok.Color {
        var color: sdl.SDL_Color = undefined;
        if (sdl.SDL_GetRenderDrawColor(self.ptr, &color.r, &color.g, &color.b, &color.a) < 0) {
            log.err("get renderer's color failed: {s}", .{sdl.SDL_GetError()});
            return sdl.Error.SdlError;
        }
        return @bitCast(color);
    }

    pub fn setColor(self: Renderer, color: jok.Color) !void {
        if (sdl.SDL_SetRenderDrawColor(self.ptr, color.r, color.g, color.b, color.a) < 0) {
            log.err("set renderer's color failed: {s}", .{sdl.SDL_GetError()});
            return sdl.Error.SdlError;
        }
    }

    pub fn getTarget(self: Renderer) ?jok.Texture {
        if (sdl.SDL_GetRenderTarget(self.ptr)) |ptr| {
            return .{ .ptr = ptr };
        }
        return null;
    }

    pub fn setTarget(self: Renderer, tex: ?jok.Texture) !void {
        if (sdl.SDL_SetRenderTarget(self.ptr, if (tex) |t| t.ptr else null) < 0) {
            log.err("set renderer's target failed: {s}", .{sdl.SDL_GetError()});
            return sdl.Error.SdlError;
        }
    }

    pub fn drawTexture(self: Renderer, tex: jok.Texture, src_region: ?jok.Region, dst_rect: ?jok.Rectangle) !void {
        if (sdl.SDL_RenderCopyF(
            self.ptr,
            tex.ptr,
            if (src_region) |r| @ptrCast(&r) else null,
            if (dst_rect) |r| @ptrCast(&r) else null,
        ) < 0) {
            log.err("render texture failed: {s}", .{sdl.SDL_GetError()});
            return sdl.Error.SdlError;
        }
        dcstats.drawcall_count += 1;
    }

    pub fn drawTriangles(self: Renderer, tex: ?jok.Texture, vs: []const jok.Vertex, indices: ?[]const u32) !void {
        if (sdl.SDL_RenderGeometry(
            self.ptr,
            if (tex) |t| t.ptr else null,
            @ptrCast(vs.ptr),
            @intCast(vs.len),
            if (indices) |is| @ptrCast(is.ptr) else null,
            if (indices) |is| @intCast(is.len) else 0,
        ) < 0) {
            log.err("render triangles failed: {s}", .{sdl.SDL_GetError()});
            return sdl.Error.SdlError;
        }
        dcstats.drawcall_count += 1;
        dcstats.triangle_count += if (indices) |is|
            @as(u32, @intCast(is.len)) / 3
        else
            @as(u32, @intCast(vs.len)) / 3;
    }

    pub fn drawTrianglesRaw(
        self: Renderer,
        tex: ?jok.Texture,
        vs: *anyopaque,
        vs_count: usize,
        xy_offset: usize,
        xy_stride: u32,
        cs_offset: usize,
        cs_stride: u32,
        uv_offset: usize,
        uv_stride: u32,
        indices: []u32,
    ) !void {
        const base = @intFromPtr(vs);
        if (sdl.SDL_RenderGeometryRaw(
            self.ptr,
            if (tex) |t| t.ptr else null,
            @ptrFromInt(base + xy_offset),
            @intCast(xy_stride),
            @ptrFromInt(base + cs_offset),
            @intCast(cs_stride),
            @ptrFromInt(base + uv_offset),
            @intCast(uv_stride),
            @intCast(vs_count),
            @ptrCast(indices.ptr),
            @intCast(indices.len),
            4,
        ) < 0) {
            log.err("render triangles failed: {s}", .{sdl.SDL_GetError()});
            return sdl.Error.SdlError;
        }
        dcstats.drawcall_count += 1;
        dcstats.triangle_count += @as(u32, @intCast(indices.len)) / 3;
    }

    pub const TextureOption = struct {
        access: jok.Texture.Access = .static,
        blend_mode: jok.BlendMode = .blend,
        scale_mode: jok.Texture.ScaleMode = .linear,
    };
    pub fn createTexture(self: Renderer, size: jok.Size, pixels: ?[]const u8, opt: TextureOption) !jok.Texture {
        const rdinfo = try self.getInfo();
        if (size.width > rdinfo.max_texture_width or
            size.height > rdinfo.max_texture_height)
        {
            return error.TextureTooLarge;
        }
        const ptr = sdl.SDL_CreateTexture(
            self.ptr,
            sdl.SDL_PIXELFORMAT_RGBA32, // Yes, we only accept rgba format!
            @intFromEnum(opt.access),
            @intCast(size.width),
            @intCast(size.height),
        );
        if (ptr == null) {
            log.err("create texture failed: {s}", .{sdl.SDL_GetError()});
            return sdl.Error.SdlError;
        }
        const tex = jok.Texture{ .ptr = ptr.? };
        errdefer tex.destroy();
        if (pixels) |px| try tex.updateSlow(px);
        try tex.setBlendMode(opt.blend_mode);
        try tex.setScaleMode(opt.scale_mode);
        return tex;
    }

    pub fn createTextureFromFileData(
        self: Renderer,
        file_data: []const u8,
        access: jok.Texture.Access,
        flip: bool,
    ) !jok.Texture {
        var width: c_int = undefined;
        var height: c_int = undefined;
        var channels: c_int = undefined;

        stb.image.stbi_set_flip_vertically_on_load(@intFromBool(flip));
        const image_data = stb.image.stbi_load_from_memory(
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
        assert(channels >= 3);
        defer stb.image.stbi_image_free(image_data);

        return try self.createTexture(
            .{
                .width = @intCast(width),
                .height = @intCast(height),
            },
            image_data[0..@as(u32, @intCast(width * height * 4))],
            .{ .access = access },
        );
    }

    pub fn createTextureFromFile(
        self: Renderer,
        allocator: std.mem.Allocator,
        image_file: [*:0]const u8,
        access: jok.Texture.Access,
        flip: bool,
    ) !jok.Texture {
        if (self.cfg.jok_enable_physfs) {
            const handle = try physfs.open(image_file, .read);
            defer handle.close();

            const filedata = try handle.readAllAlloc(allocator);
            defer allocator.free(filedata);

            return try self.createTextureFromFileData(
                filedata,
                access,
                flip,
            );
        } else {
            const filedata = try std.fs.cwd().readFileAlloc(
                allocator,
                std.mem.sliceTo(image_file, 0),
                1 << 30,
            );
            defer allocator.free(filedata);

            return try self.createTextureFromFileData(
                filedata,
                access,
                flip,
            );
        }
    }

    pub const TargetOption = struct {
        size: ?jok.Size = null,
        blend_mode: jok.BlendMode = .none,
        scale_mode: jok.Texture.ScaleMode = .linear,
    };
    pub fn createTarget(self: Renderer, opt: TargetOption) !jok.Texture {
        const size = opt.size orelse BLK: {
            const sz = try self.getOutputSize();
            break :BLK sz;
        };
        return try self.createTexture(size, null, .{
            .access = .target,
            .blend_mode = opt.blend_mode,
            .scale_mode = opt.scale_mode,
        });
    }

    /// Readonly pixels of previous rendered result
    pub const PixelData = struct {
        allocator: std.mem.Allocator,
        pixels: []u8,
        width: u32,
        height: u32,

        pub inline fn destroy(px: @This()) void {
            px.allocator.free(px.pixels);
        }

        pub inline fn getPixel(px: @This(), x: u32, y: u32) jok.Color {
            assert(x < px.width);
            assert(y < px.height);
            const line: [*]u32 = @alignCast(@ptrCast(px.pixels.ptr + y * px.width * 4));
            return jok.Color.fromRGBA32(line[x]);
        }

        pub inline fn createTexture(px: @This(), rd: Renderer, opt: TextureOption) !jok.Texture {
            return try rd.createTexture(
                .{
                    .width = px.width,
                    .height = px.height,
                },
                px.pixels,
                opt,
            );
        }
    };
    pub fn getPixels(self: Renderer, _allocator: std.mem.Allocator, region: ?jok.Region) !PixelData {
        const rect: sdl.SDL_Rect = if (region) |r|
            @bitCast(r)
        else BLK: {
            const sz = try self.getOutputSize();
            break :BLK .{
                .x = 0,
                .y = 0,
                .w = @intCast(sz.width),
                .h = @intCast(sz.height),
            };
        };
        const pixels = try _allocator.alloc(u8, @intCast(4 * rect.w * rect.h));
        if (sdl.SDL_RenderReadPixels(
            self.ptr,
            &rect,
            sdl.SDL_PIXELFORMAT_RGBA32,
            @ptrCast(pixels.ptr),
            @intCast(4 * rect.w),
        ) < 0) {
            log.err("read pixels failed: {s}", .{sdl.SDL_GetError()});
            return sdl.Error.SdlError;
        }
        return .{
            .allocator = _allocator,
            .pixels = pixels,
            .width = @intCast(rect.w),
            .height = @intCast(rect.h),
        };
    }
};
