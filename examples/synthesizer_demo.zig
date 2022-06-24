const std = @import("std");
const assert = std.debug.assert;
const builtin = @import("builtin");
const sdl = @import("sdl");
const jok = @import("jok");

var audio_device: sdl.AudioDevice = undefined;
var audio_spec: sdl.AudioSpecResponse = undefined;
var audio_value: f32 = 1.0;

fn audioCallback(ptr: ?*anyopaque, buf: [*c]u8, size: c_int) callconv(.C) void {
    var ctx = @ptrCast(*jok.Context, @alignCast(@alignOf(*jok.Context), ptr));
    _ = ctx;
    const audio_buf = @ptrCast([*]f32, @alignCast(@alignOf([*]f32), buf));
    const buf_size = @intCast(u32, size) / @sizeOf(f32);
    assert(@intCast(u32, size) % @sizeOf(f32) == 0);
    var i: u32 = 0;
    while (i < buf_size) : (i += 2) {
        audio_buf[i] = audio_value;
        audio_buf[i + 1] = audio_value;
    }
    audio_value = -audio_value;
}

pub fn init(ctx: *jok.Context) anyerror!void {
    _ = ctx;
    std.log.info("game init", .{});

    const result = try sdl.openAudioDevice(.{
        .desired_spec = .{
            .sample_rate = 44100,
            .buffer_format = if (builtin.target.cpu.arch.endian() == .Little)
                sdl.AudioFormat.f32_lsb
            else
                sdl.AudioFormat.f32_msb,
            .channel_count = 2,
            .callback = audioCallback,
            .userdata = ctx,
        },
    });
    audio_device = result.device;
    audio_spec = result.obtained_spec;
    audio_device.pause(false);

    try ctx.renderer.setColorRGB(77, 77, 77);
}

pub fn loop(ctx: *jok.Context) anyerror!void {
    while (ctx.pollEvent()) |e| {
        switch (e) {
            .keyboard_event => |key| {
                if (key.trigger_type == .up) {
                    switch (key.scan_code) {
                        .escape => ctx.kill(),
                        else => {},
                    }
                }
            },
            .quit_event => ctx.kill(),
            else => {},
        }
    }

    try ctx.renderer.clear();
}

pub fn quit(ctx: *jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});
}
