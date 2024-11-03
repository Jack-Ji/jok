const std = @import("std");
const jok = @import("jok");
const j2d = jok.j2d;
const physfs = jok.physfs;
const font = jok.font;
const miniaudio = jok.miniaudio;

var batchpool: j2d.BatchPool(64, false) = undefined;
var atlas: *font.Atlas = undefined;
var music: *miniaudio.Sound = undefined;
var music_played_length: u32 = undefined;
var music_total_length: u32 = undefined;
var sfx1: *miniaudio.Sound = undefined;
var sfx2: *miniaudio.Sound = undefined;

pub fn init(ctx: jok.Context) !void {
    std.log.info("game init", .{});

    try physfs.mount("assets", "", true);

    batchpool = try @TypeOf(batchpool).init(ctx);

    atlas = try font.DebugFont.getAtlas(ctx, 16);
    music = try ctx.audioEngine().createSoundFromFile(
        "audios/Edge-of-Ocean_Looping.mp3",
        .{},
    );
    music_total_length = @intFromFloat(try music.getLengthInSeconds());
    music.setLooping(true);
    try music.start();

    sfx1 = try ctx.audioEngine().createSoundFromFile(
        "audios/SynthChime9.mp3",
        .{},
    );
    sfx1.setPanMode(.pan);
    sfx1.setPan(-1);

    sfx2 = try ctx.audioEngine().createSoundFromFile(
        "audios/Bells3.mp3",
        .{},
    );
    sfx2.setPanMode(.pan);
    sfx2.setPan(1);
}

pub fn event(ctx: jok.Context, e: jok.Event) !void {
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
    try ctx.renderer().clear(null);

    var b = try batchpool.new(.{});
    defer b.submit();

    try b.text(
        "Press *RETURN* to start/pause playing, current status: {s}, progress: {d}/{d}(s)",
        .{
            if (music.isPlaying()) "playing" else "paused",
            music_played_length,
            music_total_length,
        },
        .{ .atlas = atlas, .pos = .{ .x = 10, .y = 10 } },
    );
    try b.text(
        "Press *Z/X* to decrease/increase volume of music, current volume: {d:.1}",
        .{music.getVolume()},
        .{ .atlas = atlas, .pos = .{ .x = 10, .y = 26 } },
    );
    try b.text(
        "Double-click mouse's left button to trigger sound effect on your left ear",
        .{},
        .{
            .atlas = atlas,
            .pos = .{ .x = 10, .y = 100 },
            .tint_color = if (sfx1.isPlaying()) jok.Color.red else jok.Color.white,
        },
    );
    try b.text(
        "Double-click mouse's right button to trigger sound effect on your right ear",
        .{},
        .{
            .atlas = atlas,
            .pos = .{ .x = 200, .y = 150 },
            .tint_color = if (sfx2.isPlaying()) jok.Color.magenta else jok.Color.white,
        },
    );
}

pub fn quit(ctx: jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});
    music.destroy();
    sfx1.destroy();
    sfx2.destroy();
    batchpool.deinit();
}
