const std = @import("std");
const bulitin = @import("builtin");
const assert = std.debug.assert;
const jok = @import("jok.zig");
const sdl = jok.vendor.sdl;
const stb = jok.vendor.stb;
const log = std.log.scoped(.jok);

pub const Error = error{
    TextureTooLarge,
    LoadImageError,
    NotSupported,
    InvalidFormat,
    InvalidStruct,
    InvalidData,
};

// Draw call statistics
pub const DcStats = struct {
    allocator: std.mem.Allocator,
    drawcall_count: u32,
    triangle_count: u32,

    pub fn create(allocator: std.mem.Allocator) *DcStats {
        const dc = allocator.create(DcStats) catch unreachable;
        dc.* = .{
            .allocator = allocator,
            .drawcall_count = 0,
            .triangle_count = 0,
        };
        return dc;
    }

    pub fn destroy(self: *DcStats) void {
        self.allocator.destroy(self);
    }

    pub fn clear(self: *DcStats) void {
        self.drawcall_count = 0;
        self.triangle_count = 0;
    }
};

pub const Renderer = struct {
    ptr: *sdl.SDL_Renderer,
    gpu: ?*sdl.SDL_GPUDevice,
    cfg: jok.config.Config,
    dc: *DcStats,

    pub fn init(ctx: jok.Context) !Renderer {
        const cfg = ctx.cfg();
        const renderer: ?*sdl.SDL_Renderer, const gpu: ?*sdl.SDL_GPUDevice =
            blk: switch (cfg.jok_renderer_type) {
                .software => {
                    const surface = sdl.SDL_GetWindowSurface(ctx.window().ptr);
                    break :blk .{ sdl.SDL_CreateSoftwareRenderer(surface).?, null };
                },
                .accelerated => {
                    const rd = sdl.SDL_CreateRenderer(ctx.window().ptr, null);
                    if (rd == null) continue :blk .software; // Fallback to software
                    break :blk .{ rd.?, null };
                },
                .gpu => {
                    const gpu = sdl.SDL_CreateGPUDevice(
                        sdl.SDL_GPU_SHADERFORMAT_SPIRV |
                            sdl.SDL_GPU_SHADERFORMAT_DXBC |
                            sdl.SDL_GPU_SHADERFORMAT_DXIL |
                            sdl.SDL_GPU_SHADERFORMAT_MSL |
                            sdl.SDL_GPU_SHADERFORMAT_METALLIB,
                        bulitin.mode == .Debug,
                        null,
                    );
                    if (gpu == null) continue :blk .accelerated; // Fallback to accelerated
                    const rd = sdl.SDL_CreateGPURenderer(gpu, ctx.window().ptr);
                    if (rd == null) continue :blk .accelerated; // Fallback to accelerated
                    break :blk .{ rd.?, gpu.? };
                },
            };
        if (renderer == null) {
            log.err("Create renderer failed: {s}", .{sdl.SDL_GetError()});
            return error.SdlError;
        }

        var rd = Renderer{
            .ptr = renderer.?,
            .gpu = gpu,
            .cfg = cfg,
            .dc = DcStats.create(ctx.allocator()),
        };
        try rd.setBlendMode(.blend);
        if (cfg.jok_fps_limit == .auto) try rd.setVsync(1);
        return rd;
    }

    pub fn destroy(self: Renderer) void {
        self.dc.destroy();
        sdl.SDL_DestroyRenderer(self.ptr);
        if (self.gpu) |d| sdl.SDL_DestroyGPUDevice(d);
    }

    pub const Info = struct {
        name: []const u8,
        vsync: i32, // https://wiki.libsdl.org/SDL3/SDL_SetRenderVSync
        max_texture_size: u32,
    };
    pub fn getInfo(self: Renderer) !Info {
        const props = sdl.SDL_GetRendererProperties(self.ptr);
        return .{
            .name = std.mem.sliceTo(sdl.SDL_GetRendererName(self.ptr), 0),
            .vsync = @intCast(sdl.SDL_GetNumberProperty(props, sdl.SDL_PROP_RENDERER_VSYNC_NUMBER, 0)),
            .max_texture_size = @intCast(sdl.SDL_GetNumberProperty(props, sdl.SDL_PROP_RENDERER_MAX_TEXTURE_SIZE_NUMBER, 0)),
        };
    }

    pub fn getOutputSize(self: Renderer) !jok.Size {
        var width_pixels: c_int = undefined;
        var height_pixels: c_int = undefined;
        if (!sdl.SDL_GetCurrentRenderOutputSize(self.ptr, &width_pixels, &height_pixels)) {
            log.err("Get renderer's framebuffer size failed: {s}", .{sdl.SDL_GetError()});
            return error.SdlError;
        }
        return .{
            .width = @intCast(width_pixels),
            .height = @intCast(height_pixels),
        };
    }

    pub fn clear(self: Renderer, color: jok.Color) !void {
        const old_color = try self.getColor();
        try self.setColor(color);
        defer self.setColor(old_color) catch {};
        if (!sdl.SDL_RenderClear(self.ptr)) {
            log.err("Clear renderer failed: {s}", .{sdl.SDL_GetError()});
            return error.SdlError;
        }
    }

    pub fn present(self: Renderer) void {
        if (!sdl.SDL_RenderPresent(self.ptr)) {
            log.err("Renderer present failed: {s}", .{sdl.SDL_GetError()});
        }
    }

    // https://wiki.libsdl.org/SDL3/SDL_SetRenderVSync
    pub fn setVsync(self: Renderer, vsync: i32) !void {
        if (!sdl.SDL_SetRenderVSync(self.ptr, vsync)) {
            log.err("Set vsync mode to {d} failed: {s}", .{ vsync, sdl.SDL_GetError() });
            return error.SdlError;
        }
    }

    pub fn isViewportSet(self: Renderer) bool {
        return sdl.SDL_RenderViewportSet(self.ptr);
    }

    pub fn getViewport(self: Renderer) !jok.Region {
        var rect: sdl.SDL_Rect = undefined;
        if (!sdl.SDL_GetRenderViewport(self.ptr, &rect)) {
            log.err("Get viewport failed: {s}", .{sdl.SDL_GetError()});
            return error.SdlError;
        }
        return @bitCast(rect);
    }

    pub fn setViewport(self: Renderer, region: ?jok.Region) !void {
        if (!sdl.SDL_SetRenderViewport(
            self.ptr,
            if (region) |r| @ptrCast(&r) else null,
        )) {
            log.err("Set viewport failed: {s}", .{sdl.SDL_GetError()});
            return error.SdlError;
        }
    }

    pub fn isClipEnabled(self: Renderer) bool {
        return sdl.SDL_RenderClipEnabled(self.ptr);
    }

    pub fn getClipRegion(self: Renderer) !jok.Region {
        var rect: sdl.SDL_Rect = undefined;
        if (!sdl.SDL_GetRenderClipRect(self.ptr, &rect)) {
            log.err("Get clip rect failed: {s}", .{sdl.SDL_GetError()});
            return error.SdlError;
        }
        return @bitCast(rect);
    }

    pub fn setClipRegion(self: Renderer, clip_region: ?jok.Region) !void {
        if (!sdl.SDL_SetRenderClipRect(
            self.ptr,
            if (clip_region) |r| @ptrCast(&r) else null,
        )) {
            log.err("Set clip region failed: {s}", .{sdl.SDL_GetError()});
            return error.SdlError;
        }
    }

    pub fn getBlendMode(self: Renderer) !jok.BlendMode {
        var blend_mode: sdl.SDL_BlendMode = undefined;
        if (!sdl.SDL_GetRenderDrawBlendMode(self.ptr, &blend_mode)) {
            log.err("Get renderer's blend mode failed: {s}", .{sdl.SDL_GetError()});
            return error.SdlError;
        }
        return jok.BlendMode.fromNative(blend_mode);
    }

    pub fn setBlendMode(self: Renderer, blend_mode: jok.BlendMode) !void {
        if (!sdl.SDL_SetRenderDrawBlendMode(self.ptr, blend_mode.toNative())) {
            log.err("Set renderer's blend mode to {s} failed: {s}", .{ @tagName(blend_mode), sdl.SDL_GetError() });
            return error.SdlError;
        }
    }

    pub fn getColor(self: Renderer) !jok.Color {
        var color: sdl.SDL_Color = undefined;
        if (!sdl.SDL_GetRenderDrawColor(self.ptr, &color.r, &color.g, &color.b, &color.a)) {
            log.err("Get renderer's color failed: {s}", .{sdl.SDL_GetError()});
            return error.SdlError;
        }
        return @bitCast(color);
    }

    pub fn setColor(self: Renderer, color: jok.Color) !void {
        if (!sdl.SDL_SetRenderDrawColor(self.ptr, color.r, color.g, color.b, color.a)) {
            log.err("Set renderer's color failed: {s}", .{sdl.SDL_GetError()});
            return error.SdlError;
        }
    }

    pub fn getTarget(self: Renderer) ?jok.Texture {
        const ptr = sdl.SDL_GetRenderTarget(self.ptr);
        if (ptr != null) {
            return .{ .ptr = ptr };
        }
        return null;
    }

    pub fn setTarget(self: Renderer, tex: ?jok.Texture) !void {
        if (!sdl.SDL_SetRenderTarget(self.ptr, if (tex) |t| t.ptr else null)) {
            log.err("Set renderer's target failed: {s}", .{sdl.SDL_GetError()});
            return error.SdlError;
        }
    }

    pub fn drawTexture(self: Renderer, tex: jok.Texture, src: ?jok.Rectangle, dst: ?jok.Rectangle) !void {
        if (!sdl.SDL_RenderTexture(
            self.ptr,
            tex.ptr,
            if (src) |r| @ptrCast(&r) else null,
            if (dst) |r| @ptrCast(&r) else null,
        )) {
            log.err("Render texture failed: {s}", .{sdl.SDL_GetError()});
            return error.SdlError;
        }
        self.dc.drawcall_count += 1;
    }

    pub fn drawTriangles(self: Renderer, tex: ?jok.Texture, vs: []const jok.Vertex, indices: ?[]const u32) !void {
        if (!sdl.SDL_RenderGeometry(
            self.ptr,
            if (tex) |t| t.ptr else null,
            @ptrCast(vs.ptr),
            @intCast(vs.len),
            if (indices) |is| @ptrCast(is.ptr) else null,
            if (indices) |is| @intCast(is.len) else 0,
        )) {
            log.err("Render triangles failed: {s}", .{sdl.SDL_GetError()});
            return error.SdlError;
        }
        self.dc.drawcall_count += 1;
        self.dc.triangle_count += if (indices) |is|
            @as(u32, @intCast(is.len)) / 3
        else
            @as(u32, @intCast(vs.len)) / 3;
    }

    pub fn drawTrianglesRaw(
        self: Renderer,
        tex: ?jok.Texture,
        xy_ptr: [*]const f32,
        xy_stride: u32,
        cs_ptr: [*]const jok.ColorF,
        cs_stride: u32,
        uv_ptr: [*]const f32,
        uv_stride: u32,
        vs_count: usize,
        indices: []const u32,
    ) !void {
        if (!sdl.SDL_RenderGeometryRaw(
            self.ptr,
            if (tex) |t| t.ptr else null,
            xy_ptr,
            @intCast(xy_stride),
            @ptrCast(cs_ptr),
            @intCast(cs_stride),
            uv_ptr,
            @intCast(uv_stride),
            @intCast(vs_count),
            @ptrCast(indices.ptr),
            @intCast(indices.len),
            4,
        )) {
            log.err("Render triangles(raw) failed: {s}", .{sdl.SDL_GetError()});
            return error.SdlError;
        }
        self.dc.drawcall_count += 1;
        self.dc.triangle_count += @as(u32, @intCast(indices.len)) / 3;
    }

    pub const TextureOption = struct {
        access: jok.Texture.Access = .static,
        blend_mode: jok.BlendMode = .blend,
        scale_mode: jok.Texture.ScaleMode = .linear,
    };
    pub fn createTexture(self: Renderer, size: jok.Size, pixels: ?[]const u8, opt: TextureOption) !jok.Texture {
        if (self.cfg.jok_renderer_type != .software) {
            const rdinfo = try self.getInfo();
            if (rdinfo.max_texture_size > 0 and (size.width > rdinfo.max_texture_size or size.height > rdinfo.max_texture_size)) {
                return error.TextureTooLarge;
            }
        }
        const ptr = sdl.SDL_CreateTexture(
            self.ptr,
            sdl.SDL_PIXELFORMAT_RGBA32, // Yes, we only accept rgba format!
            @intFromEnum(opt.access),
            @intCast(size.width),
            @intCast(size.height),
        );
        if (ptr == null) {
            log.err("Create texture failed: {s}", .{sdl.SDL_GetError()});
            return error.SdlError;
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

    pub const TargetOption = struct {
        size: ?jok.Size = null,
        blend_mode: jok.BlendMode = .none,
        scale_mode: jok.Texture.ScaleMode = .linear,
    };
    pub fn createTarget(self: Renderer, opt: TargetOption) !jok.Texture {
        if (self.cfg.jok_renderer_type == .software) @panic("Unsupported when using software renderer!");
        const size = opt.size orelse blk: {
            const sz = try self.getOutputSize();
            break :blk sz;
        };
        return try self.createTexture(size, null, .{
            .access = .target,
            .blend_mode = opt.blend_mode,
            .scale_mode = opt.scale_mode,
        });
    }

    /// Readonly pixels of previous rendered result
    pub const PixelData = struct {
        surface: [*c]sdl.SDL_Surface,
        width: u32,
        height: u32,

        pub inline fn destroy(px: @This()) void {
            sdl.SDL_DestroySurface(px.surface);
        }

        pub inline fn getPixel(px: @This(), x: u32, y: u32) jok.Color {
            assert(x < px.width);
            assert(y < px.height);
            const c: jok.Color = undefined;
            sdl.SDL_ReadSurfacePixel(px.surface, @intCast(x), @intCast(y), &c.r, &c.g, &c.b, &c.a);
            return c;
        }

        pub inline fn createTexture(px: @This(), rd: Renderer, opt: TextureOption) !jok.Texture {
            const tex = jok.Texture{
                .ptr = sdl.SDL_CreateTextureFromSurface(rd.ptr, px.surface),
            };
            try tex.setBlendMode(opt.blend_mode);
            try tex.setScaleMode(opt.scale_mode);
            return tex;
        }
    };
    pub fn getPixels(self: Renderer, region: ?jok.Region) !PixelData {
        const rect: sdl.SDL_Rect = if (region) |r|
            @bitCast(r)
        else blk: {
            const sz = try self.getOutputSize();
            break :blk .{
                .x = 0,
                .y = 0,
                .w = @intCast(sz.width),
                .h = @intCast(sz.height),
            };
        };
        const surface = sdl.SDL_RenderReadPixels(self.ptr, &rect);
        if (surface == null) {
            log.err("Read pixels failed: {s}", .{sdl.SDL_GetError()});
            return error.SdlError;
        }
        return .{
            .surface = surface,
            .width = @intCast(rect.w),
            .height = @intCast(rect.h),
        };
    }

    pub fn isShaderSupported(self: Renderer, format: ?ShaderFormat) bool {
        if (self.gpu == null) return false;
        if (format == null) return true;
        const supported_formats = sdl.SDL_GetGPUShaderFormats(self.gpu.?);
        return (supported_formats & @intFromEnum(format.?)) != 0;
    }

    pub fn createShader(self: Renderer, byte_code: []const u8, entrypoint: ?[:0]const u8, format: ShaderFormat) !PixelShader {
        if (self.gpu == null) {
            log.err("Current renderer doesn't support custom shader", .{});
            return error.NotSupported;
        }

        if (!self.isShaderSupported(format)) {
            var supported: [5]ShaderFormat = undefined;
            var size: usize = 0;
            for ([_]ShaderFormat{ .spirv, .dxbc, .dxil, .msl, .metallib }) |f| {
                if (self.isShaderSupported(f)) {
                    supported[size] = f;
                    size += 1;
                }
            }
            log.err("Shader format unsupported, consider other supported formats: {any}", .{supported[0..size]});
            return error.InvalidFormat;
        }

        const gpu_shader = sdl.SDL_CreateGPUShader(self.gpu.?, &.{
            .code_size = byte_code.len,
            .code = @ptrCast(byte_code.ptr),
            .entrypoint = entrypoint orelse "main",
            .format = @intFromEnum(format),
            .stage = sdl.SDL_GPU_SHADERSTAGE_FRAGMENT,
            .num_samplers = 1,
            .num_uniform_buffers = 1,
        });
        if (gpu_shader == null) {
            log.err("Create shader failed: {s}", .{sdl.SDL_GetError()});
            return error.SdlError;
        }
        errdefer sdl.SDL_ReleaseGPUShader(self.gpu.?, gpu_shader.?);

        var info = sdl.SDL_GPURenderStateCreateInfo{
            .fragment_shader = gpu_shader.?,
        };
        const state = sdl.SDL_CreateGPURenderState(self.ptr, &info);
        if (state == null) {
            log.err("Create render state failed: {s}", .{sdl.SDL_GetError()});
            return error.SdlError;
        }

        return .{
            .ptr = gpu_shader.?,
            .gpu = self.gpu.?,
            .state = state.?,
        };
    }

    pub fn setShader(self: Renderer, shader: ?PixelShader) !void {
        if (!sdl.SDL_SetGPURenderState(self.ptr, if (shader) |s| s.state else null)) {
            log.err("Set shader failed: {s}", .{sdl.SDL_GetError()});
            return error.SdlError;
        }
    }
};

pub const ShaderFormat = enum(u32) {
    spirv = sdl.SDL_GPU_SHADERFORMAT_SPIRV,
    dxbc = sdl.SDL_GPU_SHADERFORMAT_DXBC,
    dxil = sdl.SDL_GPU_SHADERFORMAT_DXIL,
    msl = sdl.SDL_GPU_SHADERFORMAT_MSL,
    metallib = sdl.SDL_GPU_SHADERFORMAT_METALLIB,
};

pub const PixelShader = struct {
    ptr: *sdl.SDL_GPUShader,
    gpu: *sdl.SDL_GPUDevice,
    state: *sdl.SDL_GPURenderState,

    pub fn destroy(self: PixelShader) void {
        sdl.SDL_DestroyGPURenderState(self.state);
        sdl.SDL_ReleaseGPUShader(self.gpu, self.ptr);
    }

    pub fn setUniform(self: PixelShader, slot_index: u32, data: anytype) !void {
        const T = @TypeOf(data);
        const type_info = @typeInfo(T);
        switch (type_info) {
            .@"struct" => |s| {
                if (s.layout == .auto) {
                    log.err("Struct for uniform data must have defined layout (extern or packed)", .{});
                    return error.InvalidStruct;
                }
                if (@sizeOf((T)) % 16 != 0) {
                    log.err("Struct for uniform data must be multiple of 16 bytes (demanded by std140), given size is {d}", .{@sizeOf(T)});
                    return error.InvalidStruct;
                }
            },
            .pointer => {
                log.err("Pointer type isn't acceptable as uniform data", .{});
                return error.InvalidData;
            },
            else => {
                // You'are on your own here
            },
        }
        if (!sdl.SDL_SetGPURenderStateFragmentUniforms(
            self.state,
            slot_index,
            @ptrCast(&data),
            @sizeOf(@TypeOf(data)),
        )) {
            log.err("Set uniform data failed: {s}", .{sdl.SDL_GetError()});
            return error.SdlError;
        }
    }
};
