const std = @import("std");
const jok = @import("jok.zig");
const sdl = jok.vendor.sdl;
const log = std.log.scoped(.jok);

pub const Error = error{
    NotSupported,
    InvalidFormat,
};

pub const PixelShader = struct {
    ptr: *sdl.SDL_GPUShader,
    state: *sdl.SDL_GPURenderState,
    rd: jok.Renderer,
    allocator: std.mem.Allocator,

    pub const ShaderFormat = enum(u32) {
        spirv = sdl.SDL_GPU_SHADERFORMAT_SPIRV,
        dxbc = sdl.SDL_GPU_SHADERFORMAT_DXBC,
        dxil = sdl.SDL_GPU_SHADERFORMAT_DXIL,
        msl = sdl.SDL_GPU_SHADERFORMAT_MSL,
        metallib = sdl.SDL_GPU_SHADERFORMAT_METALLIB,
    };

    pub const ShaderOption = struct {
        entrypoint: [:0]const u8 = "main",
        format: PixelShader.ShaderFormat = .spirv,
    };

    pub fn create(ctx: jok.Context, byte_code: []const u8, opt: ShaderOption) !*PixelShader {
        const allocator = ctx.allocator();
        const renderer = ctx.renderer();
        if (renderer.gpu == null) return error.NotSupported;

        const supported_formats = sdl.SDL_GetGPUShaderFormats(renderer.gpu.?);
        if ((supported_formats & @intFromEnum(opt.format)) == 0) {
            log.err("Shader format unsupported, consider other supported formats: 0b{b}", .{supported_formats});
            return error.InvalidFormat;
        }

        const shader = try allocator.create(PixelShader);
        errdefer allocator.destroy(shader);

        const gpu_shader = sdl.SDL_CreateGPUShader(renderer.gpu.?, &.{
            .code_size = byte_code.len,
            .code = @ptrCast(byte_code.ptr),
            .entrypoint = opt.entrypoint,
            .format = @intFromEnum(opt.format),
            .stage = sdl.SDL_GPU_SHADERSTAGE_FRAGMENT,
            .num_samplers = 1,
            .num_uniform_buffers = 1,
        });
        if (gpu_shader == null) {
            log.err("Create shader failed: {s}", .{sdl.SDL_GetError()});
            return error.SdlError;
        }
        errdefer sdl.SDL_ReleaseGPUShader(renderer.gpu.?, gpu_shader.?);

        var info = sdl.SDL_GPURenderStateCreateInfo{
            .fragment_shader = gpu_shader.?,
        };
        const state = sdl.SDL_CreateGPURenderState(renderer.ptr, &info);
        if (state == null) {
            log.err("Create render state failed: {s}", .{sdl.SDL_GetError()});
            return error.SdlError;
        }

        shader.* = .{
            .ptr = gpu_shader.?,
            .state = state.?,
            .rd = renderer,
            .allocator = allocator,
        };
        return shader;
    }

    pub fn destroy(self: *PixelShader) void {
        sdl.SDL_DestroyGPURenderState(self.state);
        sdl.SDL_ReleaseGPUShader(self.rd.gpu.?, self.ptr);
        self.allocator.destroy(self);
    }

    pub fn setUniform(self: *PixelShader, slot_index: u32, data: anytype) !void {
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
