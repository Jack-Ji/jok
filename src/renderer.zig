//! Graphics renderer management.
//!
//! This module provides the rendering subsystem for the jok engine, supporting
//! multiple rendering backends (software, accelerated, GPU) through SDL3.
//!
//! Features:
//! - Multiple renderer types (software, accelerated, GPU)
//! - Texture creation and management
//! - Geometry rendering (triangles, sprites)
//! - Render targets and framebuffers
//! - Custom shader support (GPU backend only)
//! - Viewport and clipping
//! - Blend modes and color modulation
//! - Draw call statistics tracking
//!
//! The renderer automatically falls back to simpler backends if the requested
//! backend is not available (GPU -> accelerated -> software).

const std = @import("std");
const builtin = @import("builtin");
const assert = std.debug.assert;
const jok = @import("jok.zig");
const geom = jok.j2d.geom;
const sdl = jok.vendor.sdl;
const stb = jok.vendor.stb;
const log = std.log.scoped(.jok);

/// Renderer-specific errors.
pub const Error = error{
    /// Texture dimensions exceed hardware limits
    TextureTooLarge,
    /// Failed to load image data
    LoadImageError,
    /// Feature not supported by current renderer
    NotSupported,
    /// Invalid shader format
    InvalidFormat,
    /// Invalid struct layout for uniform data
    InvalidStruct,
    /// Invalid data type for operation
    InvalidData,
};

/// Draw call statistics tracker.
///
/// Tracks rendering performance metrics including draw call count
/// and triangle count per frame.
pub const DcStats = struct {
    allocator: std.mem.Allocator,
    drawcall_count: u32,
    triangle_count: u32,

    /// Create a new statistics tracker.
    pub fn create(allocator: std.mem.Allocator) *DcStats {
        const dc = allocator.create(DcStats) catch unreachable;
        dc.* = .{
            .allocator = allocator,
            .drawcall_count = 0,
            .triangle_count = 0,
        };
        return dc;
    }

    /// Destroy the statistics tracker.
    pub fn destroy(self: *DcStats) void {
        self.allocator.destroy(self);
    }

    /// Reset statistics counters to zero.
    pub fn clear(self: *DcStats) void {
        self.drawcall_count = 0;
        self.triangle_count = 0;
    }
};

/// Graphics renderer.
///
/// Manages the rendering pipeline and provides methods for drawing
/// textures, geometry, and managing render state. Supports multiple
/// backends with automatic fallback.
pub const Renderer = struct {
    ptr: *sdl.SDL_Renderer,
    gpu: ?*sdl.SDL_GPUDevice,
    cfg: jok.config.Config,
    dc: *DcStats,

    /// Initialize renderer from context configuration.
    ///
    /// **WARNING: This function is automatically called by jok.Context during initialization.**
    /// **DO NOT call this function directly from game code.**
    /// The renderer is accessible via `ctx.renderer()` after context creation.
    ///
    /// Creates a renderer with the backend specified in the configuration.
    /// Automatically falls back to simpler backends if the requested one
    /// is unavailable (GPU -> accelerated -> software).
    ///
    /// Returns: Initialized renderer or error if all backends fail
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
                        builtin.mode == .Debug,
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

    /// Destroy the renderer and free associated resources.
    ///
    /// **WARNING: This function is automatically called by jok.Context during cleanup.**
    /// **DO NOT call this function directly from game code.**
    pub fn destroy(self: Renderer) void {
        self.dc.destroy();
        sdl.SDL_DestroyRenderer(self.ptr);
        if (self.gpu) |d| sdl.SDL_DestroyGPUDevice(d);
    }

    /// Renderer information.
    pub const Info = struct {
        /// Renderer backend name
        name: []const u8,
        /// VSync mode (see SDL_SetRenderVSync)
        vsync: i32,
        /// Maximum texture size supported
        max_texture_size: u32,
    };

    /// Get renderer information and capabilities.
    ///
    /// Returns: Renderer info including backend name and limits
    pub fn getInfo(self: Renderer) !Info {
        const props = sdl.SDL_GetRendererProperties(self.ptr);
        return .{
            .name = std.mem.sliceTo(sdl.SDL_GetRendererName(self.ptr), 0),
            .vsync = @intCast(sdl.SDL_GetNumberProperty(props, sdl.SDL_PROP_RENDERER_VSYNC_NUMBER, 0)),
            .max_texture_size = @intCast(sdl.SDL_GetNumberProperty(props, sdl.SDL_PROP_RENDERER_MAX_TEXTURE_SIZE_NUMBER, 0)),
        };
    }

    /// Get the output size of the renderer's framebuffer.
    ///
    /// Returns: Framebuffer size in pixels
    pub fn getOutputSize(self: Renderer) !geom.Size {
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

    /// Clear the current render target with a color.
    ///
    /// Parameters:
    ///   color: Color to clear with
    pub fn clear(self: Renderer, color: jok.Color) !void {
        const old_color = try self.getColor();
        try self.setColor(color);
        defer self.setColor(old_color) catch {};
        if (!sdl.SDL_RenderClear(self.ptr)) {
            log.err("Clear renderer failed: {s}", .{sdl.SDL_GetError()});
            return error.SdlError;
        }
    }

    /// Present the rendered frame to the screen.
    ///
    /// Swaps buffers and displays the rendered content.
    pub fn present(self: Renderer) void {
        if (!sdl.SDL_RenderPresent(self.ptr)) {
            log.err("Renderer present failed: {s}", .{sdl.SDL_GetError()});
        }
    }

    /// Set vertical sync mode (0 = disabled, 1 = enabled, -1 = adaptive).
    pub fn setVsync(self: Renderer, vsync: i32) !void {
        if (!sdl.SDL_SetRenderVSync(self.ptr, vsync)) {
            log.err("Set vsync mode to {d} failed: {s}", .{ vsync, sdl.SDL_GetError() });
            return error.SdlError;
        }
    }

    /// Return true if a custom viewport is currently set.
    pub fn isViewportSet(self: Renderer) bool {
        return sdl.SDL_RenderViewportSet(self.ptr);
    }

    /// Get the current rendering viewport region.
    pub fn getViewport(self: Renderer) !geom.Region {
        var rect: sdl.SDL_Rect = undefined;
        if (!sdl.SDL_GetRenderViewport(self.ptr, &rect)) {
            log.err("Get viewport failed: {s}", .{sdl.SDL_GetError()});
            return error.SdlError;
        }
        return @bitCast(rect);
    }

    /// Set the rendering viewport region, or null to use the entire target.
    pub fn setViewport(self: Renderer, region: ?geom.Region) !void {
        if (!sdl.SDL_SetRenderViewport(
            self.ptr,
            if (region) |r| @ptrCast(&r) else null,
        )) {
            log.err("Set viewport failed: {s}", .{sdl.SDL_GetError()});
            return error.SdlError;
        }
    }

    /// Return true if clipping is currently enabled.
    pub fn isClipEnabled(self: Renderer) bool {
        return sdl.SDL_RenderClipEnabled(self.ptr);
    }

    /// Get the current clip rectangle.
    pub fn getClipRegion(self: Renderer) !geom.Region {
        var rect: sdl.SDL_Rect = undefined;
        if (!sdl.SDL_GetRenderClipRect(self.ptr, &rect)) {
            log.err("Get clip rect failed: {s}", .{sdl.SDL_GetError()});
            return error.SdlError;
        }
        return @bitCast(rect);
    }

    /// Set the clip rectangle, or null to disable clipping.
    pub fn setClipRegion(self: Renderer, clip_region: ?geom.Region) !void {
        if (!sdl.SDL_SetRenderClipRect(
            self.ptr,
            if (clip_region) |r| @ptrCast(&r) else null,
        )) {
            log.err("Set clip region failed: {s}", .{sdl.SDL_GetError()});
            return error.SdlError;
        }
    }

    /// Get the current blend mode.
    pub fn getBlendMode(self: Renderer) !jok.BlendMode {
        var blend_mode: sdl.SDL_BlendMode = undefined;
        if (!sdl.SDL_GetRenderDrawBlendMode(self.ptr, &blend_mode)) {
            log.err("Get renderer's blend mode failed: {s}", .{sdl.SDL_GetError()});
            return error.SdlError;
        }
        return jok.BlendMode.fromNative(blend_mode);
    }

    /// Set the blend mode used for drawing operations.
    pub fn setBlendMode(self: Renderer, blend_mode: jok.BlendMode) !void {
        if (!sdl.SDL_SetRenderDrawBlendMode(self.ptr, blend_mode.toNative())) {
            log.err("Set renderer's blend mode to {s} failed: {s}", .{ @tagName(blend_mode), sdl.SDL_GetError() });
            return error.SdlError;
        }
    }

    /// Get the current draw color.
    pub fn getColor(self: Renderer) !jok.Color {
        var color: sdl.SDL_Color = undefined;
        if (!sdl.SDL_GetRenderDrawColor(self.ptr, &color.r, &color.g, &color.b, &color.a)) {
            log.err("Get renderer's color failed: {s}", .{sdl.SDL_GetError()});
            return error.SdlError;
        }
        return @bitCast(color);
    }

    /// Set the color used for drawing operations.
    pub fn setColor(self: Renderer, color: jok.Color) !void {
        if (!sdl.SDL_SetRenderDrawColor(self.ptr, color.r, color.g, color.b, color.a)) {
            log.err("Set renderer's color failed: {s}", .{sdl.SDL_GetError()});
            return error.SdlError;
        }
    }

    /// Get the current render target, or null if rendering to the screen.
    pub fn getTarget(self: Renderer) ?jok.Texture {
        const ptr = sdl.SDL_GetRenderTarget(self.ptr);
        if (ptr != null) {
            return .{ .ptr = ptr };
        }
        return null;
    }

    /// Set the render target texture, or null to render to the screen.
    pub fn setTarget(self: Renderer, tex: ?jok.Texture) !void {
        if (!sdl.SDL_SetRenderTarget(self.ptr, if (tex) |t| t.ptr else null)) {
            log.err("Set renderer's target failed: {s}", .{sdl.SDL_GetError()});
            return error.SdlError;
        }
    }

    /// Copy a texture (or a portion of it) to the render target.
    pub fn drawTexture(self: Renderer, tex: jok.Texture, src: ?geom.Rectangle, dst: ?geom.Rectangle) !void {
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

    /// Draw textured/colored triangles from vertex and optional index data.
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

    /// Draw triangles from raw interleaved vertex attribute arrays.
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

    /// Options for texture creation.
    pub const TextureOption = struct {
        /// Texture access pattern
        access: jok.Texture.Access = .static,
        /// Blend mode for rendering
        blend_mode: jok.BlendMode = .blend,
        /// Scaling filter mode
        scale_mode: jok.Texture.ScaleMode = .linear,
    };

    /// Create a new texture.
    ///
    /// Parameters:
    ///   size: Texture dimensions
    ///   pixels: Optional initial pixel data (RGBA32 format)
    ///   opt: Texture creation options
    ///
    /// Returns: Created texture or error if creation fails
    pub fn createTexture(self: Renderer, size: geom.Size, pixels: ?[]const u8, opt: TextureOption) !jok.Texture {
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

    /// Create a texture from in-memory image file data (PNG, JPG, etc.).
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

    /// Options for creating an offscreen render target.
    pub const TargetOption = struct {
        size: ?geom.Size = null,
        blend_mode: jok.BlendMode = .none,
        scale_mode: jok.Texture.ScaleMode = .linear,
    };
    /// Create an offscreen render target texture. Not supported with software renderer.
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

    /// Read-only pixel data captured from the render target.
    pub const PixelData = struct {
        surface: [*c]sdl.SDL_Surface,
        width: u32,
        height: u32,

        /// Free the underlying surface.
        pub inline fn destroy(px: @This()) void {
            sdl.SDL_DestroySurface(px.surface);
        }

        /// Read the color of a single pixel at (x, y).
        pub inline fn getPixel(px: @This(), x: u32, y: u32) jok.Color {
            assert(x < px.width);
            assert(y < px.height);
            const c: jok.Color = undefined;
            sdl.SDL_ReadSurfacePixel(px.surface, @intCast(x), @intCast(y), &c.r, &c.g, &c.b, &c.a);
            return c;
        }

        /// Create a texture from this pixel data.
        pub inline fn createTexture(px: @This(), rd: Renderer, opt: TextureOption) !jok.Texture {
            const tex = jok.Texture{
                .ptr = sdl.SDL_CreateTextureFromSurface(rd.ptr, px.surface),
            };
            try tex.setBlendMode(opt.blend_mode);
            try tex.setScaleMode(opt.scale_mode);
            return tex;
        }
    };
    /// Read pixels from the current render target (or screen if no target is set).
    pub fn getPixels(self: Renderer, region: ?geom.Region) !PixelData {
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

    /// Check if custom shaders are supported, optionally for a specific format.
    pub fn isShaderSupported(self: Renderer, format: ?ShaderFormat) bool {
        if (self.gpu == null) return false;
        if (format == null) return true;
        const supported_formats = sdl.SDL_GetGPUShaderFormats(self.gpu.?);
        return (supported_formats & @intFromEnum(format.?)) != 0;
    }

    /// Create a pixel shader from compiled bytecode. Requires GPU renderer.
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

    /// Set the active pixel shader, or null to use the default pipeline.
    pub fn setShader(self: Renderer, shader: ?PixelShader) !void {
        if (!sdl.SDL_SetGPURenderState(self.ptr, if (shader) |s| s.state else null)) {
            log.err("Set shader failed: {s}", .{sdl.SDL_GetError()});
            return error.SdlError;
        }
    }
};

/// GPU shader bytecode format.
pub const ShaderFormat = enum(u32) {
    spirv = sdl.SDL_GPU_SHADERFORMAT_SPIRV,
    dxbc = sdl.SDL_GPU_SHADERFORMAT_DXBC,
    dxil = sdl.SDL_GPU_SHADERFORMAT_DXIL,
    msl = sdl.SDL_GPU_SHADERFORMAT_MSL,
    metallib = sdl.SDL_GPU_SHADERFORMAT_METALLIB,
};

/// Compiled pixel shader handle for custom fragment shading.
pub const PixelShader = struct {
    ptr: *sdl.SDL_GPUShader,
    gpu: *sdl.SDL_GPUDevice,
    state: *sdl.SDL_GPURenderState,

    /// Release the shader and its GPU resources.
    pub fn destroy(self: PixelShader) void {
        sdl.SDL_DestroyGPURenderState(self.state);
        sdl.SDL_ReleaseGPUShader(self.gpu, self.ptr);
    }

    /// Set uniform data for a shader slot. Struct data must have extern/packed layout and size aligned to 16 bytes.
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
