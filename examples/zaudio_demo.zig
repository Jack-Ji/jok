const std = @import("std");
const sdl = @import("sdl");
const jok = @import("jok");
const font = jok.font;
const zaudio = jok.zaudio;

var engine: *zaudio.Engine = undefined;
var music: *zaudio.Sound = undefined;
var sfx1: *zaudio.Sound = undefined;
var sfx2: *zaudio.Sound = undefined;

pub fn init(ctx: *jok.Context) !void {
    _ = ctx;
    std.log.info("game init", .{});

    engine = try zaudio.Engine.create(null);
    music = try engine.createSoundFromFile(
        "assets/audios/Edge-of-Ocean_Looping.mp3",
        .{},
    );
    music.setLooping(true);
    try music.start();

    sfx1 = try engine.createSoundFromFile(
        "assets/audios/SynthChime9.mp3",
        .{},
    );
    sfx1.setPanMode(.pan);
    sfx1.setPan(-1);

    sfx2 = try engine.createSoundFromFile(
        "assets/audios/Bells3.mp3",
        .{},
    );
    sfx2.setPanMode(.pan);
    sfx2.setPan(1);
}

pub fn event(ctx: *jok.Context, e: sdl.Event) !void {
    _ = ctx;
    switch (e) {
        .key_up => |key| {
            switch (key.scancode) {
                .z => music.setVolume(music.getVolume() - 0.1),
                .x => music.setVolume(music.getVolume() + 0.1),
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

pub fn update(ctx: *jok.Context) !void {
    _ = ctx;
}

pub fn draw(ctx: *jok.Context) !void {
    _ = try font.debugDraw(
        ctx,
        .{ .pos = .{ .x = 10, .y = 10 } },
        "Press Z/X to decrease/increase volume of music, current volume: {d:.1}",
        .{music.getVolume()},
    );
    _ = try font.debugDraw(
        ctx,
        .{
            .pos = .{ .x = 10, .y = 100 },
            .color = if (sfx1.isPlaying()) sdl.Color.red else sdl.Color.white,
        },
        "Double-click mouse's left button to trigger sound effect on your left ear",
        .{},
    );
    _ = try font.debugDraw(
        ctx,
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
    music.destroy();
    sfx1.destroy();
    sfx2.destroy();
    engine.destroy();
}
