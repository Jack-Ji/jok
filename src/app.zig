const std = @import("std");
const builtin = @import("builtin");
const jok = @import("jok");
const sdl = jok.sdl;
const config = jok.config;
const game = @import("game");

// Validate exposed game api
comptime {
    if (!@hasDecl(game, "init") or
        !@hasDecl(game, "event") or
        !@hasDecl(game, "update") or
        !@hasDecl(game, "draw") or
        !@hasDecl(game, "quit"))
    {
        @compileError(
            \\You must provide following 5 public api in your game code:
            \\    pub fn init(ctx: jok.Context) !void
            \\    pub fn event(ctx: jok.Context, e: sdl.Event) !void
            \\    pub fn update(ctx: jok.Context) !void
            \\    pub fn draw(ctx: jok.Context) !void
            \\    pub fn quit(ctx: jok.Context) void
        );
    }
    switch (@typeInfo(@typeInfo(@TypeOf(game.init)).Fn.return_type.?)) {
        .ErrorUnion => |info| if (info.payload != void) {
            @compileError("`init` must return !void");
        },
        else => @compileError("`init` must return !void"),
    }
    switch (@typeInfo(@typeInfo(@TypeOf(game.event)).Fn.return_type.?)) {
        .ErrorUnion => |info| if (info.payload != void) {
            @compileError("`event` must return !void");
        },
        else => @compileError("`init` must return !void"),
    }
    switch (@typeInfo(@typeInfo(@TypeOf(game.update)).Fn.return_type.?)) {
        .ErrorUnion => |info| if (info.payload != void) {
            @compileError("`update` must return !void");
        },
        else => @compileError("`update` must return !void"),
    }
    switch (@typeInfo(@typeInfo(@TypeOf(game.draw)).Fn.return_type.?)) {
        .ErrorUnion => |info| if (info.payload != void) {
            @compileError("`draw` must return !void");
        },
        else => @compileError("`draw` must return !void"),
    }
    switch (@typeInfo(@typeInfo(@TypeOf(game.quit)).Fn.return_type.?)) {
        .Void => {},
        else => @compileError("`quit` must return void"),
    }
}

/// Jok configuration
const jok_config = config.init(game);

/// Options for zig executable
pub const std_options = struct {
    pub const log_level = jok_config.jok_log_level;
};

pub fn main() !void {
    // Init context
    var jok_ctx = try jok.JokContext(jok_config).create();
    defer jok_ctx.destroy();

    // Init game object
    var ctx = jok_ctx.context();
    try game.init(ctx);
    defer game.quit(ctx);

    // Start game loop
    while (jok_ctx._running) {
        jok_ctx.tick(game.event, game.update, game.draw);
    }
}
