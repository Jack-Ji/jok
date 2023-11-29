const std = @import("std");
const jok = @import("jok");
const sdl = jok.sdl;
const font = jok.font;
const zaudio = jok.zaudio;

var music: *zaudio.Sound = undefined;
var music_played_length: u32 = undefined;
var music_total_length: u32 = undefined;
var sfx1: *zaudio.Sound = undefined;
var sfx2: *zaudio.Sound = undefined;

pub fn init(ctx: jok.Context) !void {
    std.log.info("game init", .{});

    music = try ctx.audioEngine().createSoundFromFile(
        "assets/audios/Edge-of-Ocean_Looping.mp3",
        .{},
    );
    music_total_length = @intFromFloat(try music.getLengthInSeconds());
    music.setLooping(true);
    try music.start();

    sfx1 = try ctx.audioEngine().createSoundFromFile(
        "assets/audios/SynthChime9.mp3",
        .{},
    );
    sfx1.setPanMode(.pan);
    sfx1.setPan(-1);

    sfx2 = try ctx.audioEngine().createSoundFromFile(
        "assets/audios/Bells3.mp3",
        .{},
    );
    sfx2.setPanMode(.pan);
    sfx2.setPan(1);
}

pub fn event(ctx: jok.Context, e: sdl.Event) !void {
    const S = struct {
        var pcm_frame_index: u64 = undefined;
    };

    _ = ctx;
    switch (e) {
        .key_up => |key| {
            switch (key.scancode) {
                .z => music.setVolume(music.getVolume() - 0.1),
                .x => music.setVolume(music.getVolume() + 0.1),
                .@"return" => {
                    if (music.isPlaying()) {
                        S.pcm_frame_index = try music.getCursorInPcmFrames();
                        try music.stop();
                    } else {
                        try music.start();
                        try music.seekToPcmFrame(S.pcm_frame_index);
                    }
                },
                else => {},
            }
        },
        .mouse_button_up => |me| {
            if (me.clicks < 2) return;
            if (me.button == .left) {
                try sfx1.seekToPcmFrame(0);
                try sfx1.start();
            }
            if (me.button == .right) {
                try sfx2.seekToPcmFrame(0);
                try sfx2.start();
            }
        },
        else => {},
    }
}

pub fn update(ctx: jok.Context) !void {
    const S = struct {
        var last_update_time: f32 = 0;
    };

    if (ctx.seconds() - S.last_update_time > 1.0) {
        S.last_update_time = ctx.seconds();
        music_played_length = @intFromFloat(try music.getCursorInSeconds());
    }
}

pub fn draw(ctx: jok.Context) !void {
    try font.debugDraw(
        ctx,
        .{ .pos = .{ .x = 10, .y = 10 } },
        "Press *RETURN* to start/pause playing, current status: {s}, progress: {d}/{d}(s)",
        .{
            if (music.isPlaying()) "playing" else "paused",
            music_played_length,
            music_total_length,
        },
    );
    try font.debugDraw(
        ctx,
        .{ .pos = .{ .x = 10, .y = 26 } },
        "Press *Z/X* to decrease/increase volume of music, current volume: {d:.1}",
        .{music.getVolume()},
    );
    try font.debugDraw(
        ctx,
        .{
            .pos = .{ .x = 10, .y = 100 },
            .color = if (sfx1.isPlaying()) sdl.Color.red else sdl.Color.white,
        },
        "Double-click mouse's left button to trigger sound effect on your left ear",
        .{},
    );
    try font.debugDraw(
        ctx,
        .{
            .pos = .{ .x = 200, .y = 150 },
            .color = if (sfx2.isPlaying()) sdl.Color.magenta else sdl.Color.white,
        },
        "Double-click mouse's right button to trigger sound effect on your right ear",
        .{},
    );
}

pub fn quit(ctx: jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});
    music.destroy();
    sfx1.destroy();
    sfx2.destroy();
}
