const jok = @import("../../jok.zig");
const zaudio = @import("zaudio");

pub const Error = error{
    InitAudioFailed,
};

pub fn init(ctx: jok.Context) !*zaudio.Context {
    zaudio.init(ctx.allocator());
    const audio_ctx = miniaudio_impl_sdl2_init_context();
    return audio_ctx orelse error.InitAudioFailed;
}

pub fn deinit(audio_ctx: *zaudio.Context) void {
    miniaudio_impl_sdl2_uninit_context(audio_ctx);
    zaudio.deinit();
}

extern fn miniaudio_impl_sdl2_init_context() ?*zaudio.Context;
extern fn miniaudio_impl_sdl2_uninit_context(_: ?*zaudio.Context) void;
