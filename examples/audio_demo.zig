const std = @import("std");
const sdl = @import("sdl");
const jok = @import("jok");
const zaudio = jok.zaudio;

var engine: zaudio.Engine = undefined;
var music: zaudio.Sound = undefined;
var sfx1: zaudio.Sound = undefined;
var sfx2: zaudio.Sound = undefined;

pub fn init(ctx: *jok.Context) anyerror!void {
    _ = ctx;
    std.log.info("game init", .{});

    engine = try zaudio.createEngine(ctx.default_allocator, null);
    music = try engine.createSoundFromFile(
        ctx.default_allocator,
        "assets/audios/Edge-of-Ocean_Looping.mp3",
        .{},
    );
    music.setLooping(true);
    try music.start();

    sfx1 = try engine.createSoundFromFile(
        ctx.default_allocator,
        "assets/audios/SynthChime9.mp3",
        .{},
    );
    sfx1.setPanMode(.pan);
    sfx1.setPan(-1);

    sfx2 = try engine.createSoundFromFile(
        ctx.default_allocator,
        "assets/audios/Bells3.mp3",
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
                        try sfx1.stop();
                        try sfx1.seekToPcmFrame(0);
                        try sfx1.start();
                    }
                    if (me.data.button.btn == .right) {
                        try sfx2.stop();
                        try sfx2.seekToPcmFrame(0);
                        try sfx2.start();
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
    std.log.info("game quit", .{});
    music.destroy(ctx.default_allocator);
    sfx1.destroy(ctx.default_allocator);
    sfx2.destroy(ctx.default_allocator);
    engine.destroy(ctx.default_allocator);
}
