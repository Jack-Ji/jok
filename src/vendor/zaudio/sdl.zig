const std = @import("std");
const jok = @import("../../jok.zig");
const sdl = jok.vendor.sdl;
const physfs = jok.vendor.physfs;
const audio = @import("main.zig");

var engine: *audio.Engine = undefined;
var frames: std.array_list.Managed(u8) = undefined;
var stream: *sdl.SDL_AudioStream = undefined;

/// Initialize zaudio with SDL backend.
///
/// **WARNING: This function is automatically called by jok.Context during initialization.**
/// **DO NOT call this function directly from game code.**
/// The audio engine is accessible via `ctx.audioEngine()` after context creation.
pub fn init(ctx: jok.Context) !*audio.Engine {
    audio.init(ctx.allocator(), ctx.io());

    // Create engine
    var engine_cfg = audio.Engine.Config.init();
    engine_cfg.no_device = .true32;
    engine_cfg.channels = 2;
    engine_cfg.sample_rate = 48000;
    if (ctx.cfg().jok_enable_physfs) {
        engine_cfg.resource_manager_vfs = &physfs.zaudio.vfs;
    }
    engine = try audio.Engine.create(engine_cfg);
    frames = std.array_list.Managed(u8).init(ctx.allocator());

    // Setup audio callback
    const spec = sdl.SDL_AudioSpec{
        .format = sdl.SDL_AUDIO_F32,
        .channels = 2,
        .freq = 48000,
    };
    stream = sdl.SDL_OpenAudioDeviceStream(
        sdl.SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK,
        &spec,
        audioCallback,
        null,
    ).?;
    _ = sdl.SDL_ResumeAudioDevice(sdl.SDL_GetAudioStreamDevice(stream));

    return engine;
}

/// Deinitialize zaudio and cleanup resources.
///
/// **WARNING: This function is automatically called by jok.Context during cleanup.**
/// **DO NOT call this function directly from game code.**
pub fn deinit() void {
    sdl.SDL_DestroyAudioStream(stream);
    engine.destroy();
    frames.deinit();
    audio.deinit();
}

fn audioCallback(_: ?*anyopaque, s: ?*sdl.SDL_AudioStream, additional_amount: c_int, _: c_int) callconv(.c) void {
    if (additional_amount <= 0) return;

    frames.ensureTotalCapacity(@intCast(additional_amount)) catch unreachable;
    defer frames.clearRetainingCapacity();

    const buffer_size_in_frames = @as(u32, @intCast(additional_amount)) / (ma_get_bytes_per_sample(.float32) * 2);
    _ = ma_engine_read_pcm_frames(engine, @ptrCast(frames.items.ptr), buffer_size_in_frames, null);
    _ = sdl.SDL_PutAudioStreamData(s, @ptrCast(frames.items.ptr), additional_amount);
}
extern fn ma_get_bytes_per_sample(format: audio.Format) u32;
extern fn ma_engine_read_pcm_frames(engine: *audio.Engine, pFramesOut: ?*anyopaque, frameCount: u64, pFramesRead: ?[*]u64) audio.Result;
