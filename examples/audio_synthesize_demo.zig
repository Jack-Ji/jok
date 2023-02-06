const std = @import("std");
const assert = std.debug.assert;
const builtin = @import("builtin");
const sdl = @import("sdl");
const jok = @import("jok");
const j2d = jok.j2d;
const font = jok.font;

var audio_device: sdl.AudioDevice = undefined;
var audio_spec: sdl.AudioSpecResponse = undefined;

var frequency: f32 = 440;
var phase: f32 = 0;
var phase_step: f32 = undefined;
var amplitude: f32 = 0.1;

fn audioCallback(ptr: ?*anyopaque, buf: [*c]u8, size: c_int) callconv(.C) void {
    var ctx = @ptrCast(*jok.Context, @alignCast(@alignOf(*jok.Context), ptr));
    _ = ctx;
    const audio_buf = @ptrCast([*]f32, @alignCast(@alignOf([*]f32), buf));
    const buf_size = @intCast(u32, size) / @sizeOf(f32);
    assert(@intCast(u32, size) % @sizeOf(f32) == 0);

    var i: u32 = 0;
    while (i < buf_size) : (i += 2) {
        phase += phase_step;
        const sample = amplitude * @sin(phase);
        audio_buf[i] = sample;
        audio_buf[i + 1] = sample;
    }
}

pub fn init(ctx: *jok.Context) !void {
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
    phase_step = frequency * std.math.tau / @intToFloat(f32, audio_spec.sample_rate);
    audio_device.pause(false);

    try ctx.renderer.setColorRGB(77, 77, 77);
}

pub fn event(ctx: *jok.Context, e: sdl.Event) !void {
    switch (e) {
        .mouse_motion => |me| {
            const fb = ctx.getFramebufferSize();
            frequency = jok.utils.math.mapf(
                @intToFloat(f32, me.x),
                0,
                @intToFloat(f32, fb.w),
                40,
                2000,
            );
            phase_step = frequency * std.math.tau / @intToFloat(f32, audio_spec.sample_rate);
            amplitude = jok.utils.math.mapf(
                @intToFloat(f32, me.y),
                0,
                @intToFloat(f32, fb.h),
                1.0,
                0,
            );
        },
        else => {},
    }
}

pub fn update(ctx: *jok.Context) !void {
    _ = ctx;
}

pub fn draw(ctx: *jok.Context) !void {
    var ms = ctx.getMouseState();
    try j2d.begin(.{});
    try j2d.addCircleFilled(
        .{ .x = @intToFloat(f32, ms.x), .y = @intToFloat(f32, ms.y) },
        10,
        sdl.Color.white,
        .{},
    );
    try j2d.end();

    _ = try font.debugDraw(
        ctx.renderer,
        .{ .pos = .{ .x = 0, .y = 0 } },
        "frequency:{d:.1} amplitude:{d:.3}",
        .{ frequency, amplitude },
    );
    _ = try font.debugDraw(
        ctx.renderer,
        .{ .pos = .{ .x = 0, .y = 16 } },
        "Move mouse to left to decrease frequency",
        .{},
    );
    _ = try font.debugDraw(
        ctx.renderer,
        .{ .pos = .{ .x = 0, .y = 32 } },
        "Move mouse to right to increase frequency",
        .{},
    );
    _ = try font.debugDraw(
        ctx.renderer,
        .{ .pos = .{ .x = 0, .y = 48 } },
        "Move mouse to bottom to decrease amplitude",
        .{},
    );
    _ = try font.debugDraw(
        ctx.renderer,
        .{ .pos = .{ .x = 0, .y = 64 } },
        "Move mouse to top to increase amplitude",
        .{},
    );
}

pub fn quit(ctx: *jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});
}
