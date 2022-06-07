const std = @import("std");
const sdl = @import("sdl");
const jok = @import("jok");

var music: *jok.audio.Sound = undefined;
var sfx1: *jok.audio.Sound = undefined;
var sfx2: *jok.audio.Sound = undefined;

pub fn init(ctx: *jok.Context) anyerror!void {
    _ = ctx;
    std.log.info("game init", .{});

    music = try ctx.audio.createSoundFromFile(
        "assets/audios/Edge-of-Ocean_Looping.mp3",
        null,
        .{},
    );
    music.setLooping(true);
    music.start();

    sfx1 = try ctx.audio.createSoundFromFile(
        "assets/audios/SynthChime9.mp3",
        null,
        .{},
    );
    sfx1.setPanMode(.pan);
    sfx1.setPan(-1);

    sfx2 = try ctx.audio.createSoundFromFile(
        "assets/audios/Bells3.mp3",
        null,
        .{},
    );
    sfx2.setPanMode(.pan);
    sfx2.setPan(1);
}

pub fn loop(ctx: *jok.Context) anyerror!void {
    while (ctx.pollEvent()) |e| {
        switch (e) {
            .keyboard_event => |key| {
                if (key.trigger_type == .up) {
                    switch (key.scan_code) {
                        .escape => ctx.kill(),
                        .z => music.setVolume(music.getVolume() - 0.1),
                        .x => music.setVolume(music.getVolume() + 0.1),
                        else => {},
                    }
                }
            },
            .mouse_event => |me| {
                if (me.data == .button and me.data.button.double_clicked) {
                    if (me.data.button.btn == .left) {
                        sfx1.stop();
                        sfx1.seekTo(.{ .pcm_frames = 0 });
                        sfx1.start();
                    }
                    if (me.data.button.btn == .right) {
                        sfx2.stop();
                        sfx2.seekTo(.{ .pcm_frames = 0 });
                        sfx2.start();
                    }
                }
            },
            .quit_event => ctx.kill(),
            else => {},
        }
    }

    try ctx.renderer.clear();

    const font = jok.gfx.@"2d".font;
    _ = try font.debugDraw(
        ctx.renderer,
        .{ .pos = .{ .x = 10, .y = 10 } },
        "Press Z/X to decrease/increase volume of music, current volume: {d:.1}",
        .{music.getVolume()},
    );
    _ = try font.debugDraw(
        ctx.renderer,
        .{
            .pos = .{ .x = 10, .y = 100 },
            .color = if (sfx1.isPlaying()) sdl.Color.red else sdl.Color.white,
        },
        "Double-click mouse's left button to trigger sound effect on your left ear",
        .{},
    );
    _ = try font.debugDraw(
        ctx.renderer,
        .{
            .pos = .{ .x = 200, .y = 150 },
            .color = if (sfx2.isPlaying()) sdl.Color.magenta else sdl.Color.white,
        },
        "Double-click mouse's right button to trigger sound effect on your right ear",
        .{},
    );
}

pub fn quit(ctx: *jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});
}
