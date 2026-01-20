const std = @import("std");
const jok = @import("jok");
const config = jok.config;
const game = @import("game");
const compcheck = @import("compcheck.zig");
const JokContext = @import("realcontext.zig").JokContext;

// Validate game object
comptime {
    compcheck.doAppCheck(game);
}

// Jok configuration
const jok_config = config.init(game);

// Options for zig executable
pub const std_options: std.Options = .{
    .log_level = jok_config.jok_log_level,
};

pub fn main(minimal: std.process.Init.Minimal) !void {
    const log = std.log.scoped(.jok);

    // Init context
    var jok_ctx = try JokContext(jok_config).create(minimal.args);
    defer jok_ctx.destroy();

    // Init game object
    const ctx = jok_ctx.context();
    game.init(ctx) catch |err| {
        log.err("Init game failed: {}", .{err});
        if (@errorReturnTrace()) |trace| {
            std.debug.dumpStackTrace(trace);
            std.process.abort();
        }
    };
    defer game.quit(ctx);

    // Start game loop
    while (jok_ctx._running) {
        jok_ctx.tick(game.event, game.update, game.draw);
    }
}
