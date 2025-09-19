const std = @import("std");
const jok = @import("../../jok.zig");
const sdl = jok.sdl;
const physfs = jok.physfs;
const audio = @import("main.zig");

var engine: *audio.Engine = undefined;
var frames: std.array_list.Managed(u8) = undefined;
var stream: *sdl.SDL_AudioStream = undefined;

pub fn init(ctx: jok.Context) !*audio.Engine {
    audio.init(ctx.allocator());

    // Create engine
    var engine_cfg = audio.Engine.Config.init();
    engine_cfg.no_device = .true32;
    engine_cfg.channels = 2;
    engine_cfg.sample_rate = 48000;
    engine_cfg.resource_manager_vfs = &physfs.zaudio.vfs;
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

pub fn deinit() void {
    engine.destroy();
    frames.deinit();
    sdl.SDL_DestroyAudioStream(stream);
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
