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

// Force websocket exports to be included for wasm builds
// This ensures the callback functions are available even if the game doesn't use WebSocket
comptime {
    _ = jok.WebSocket;
}

/// Jok configuration
const jok_config = config.init(game);

/// Jok Context
const Context = JokContext(jok_config);

const LoopFn = *const fn (args: ?*anyopaque) callconv(.c) void;
extern fn emscripten_set_main_loop_arg(fp: LoopFn, args: ?*anyopaque, fps: c_int, simulate_infinite_loop: bool) void;
extern fn emscripten_cancel_main_loop() void;
extern fn emscripten_run_script(s: [*:0]const u8) void;

fn mainLoop(args: ?*anyopaque) callconv(.c) void {
    var jok_ctx: *Context = @ptrCast(@alignCast(args.?));
    if (jok_ctx._running) {
        jok_ctx.tick(game.event, game.update, game.draw);
    } else {
        game.quit(jok_ctx.context());
        jok_ctx.destroy();
        emscripten_cancel_main_loop();
    }
}

pub fn main(minimal: std.process.Init.Minimal) !void {
    const log = std.log.scoped(.jok);

    emscripten_run_script("document.title = \"" ++ jok_config.jok_window_title ++ "\"");

    var jok_ctx = try Context.create(minimal.args);
    game.init(jok_ctx.context()) catch |err| {
        log.err("Init game failed: {}", .{err});
        if (@errorReturnTrace()) |trace| {
            std.debug.dumpStackTrace(trace);
            return;
        }
        std.process.abort();
    };
    emscripten_set_main_loop_arg(mainLoop, jok_ctx, 0, true);
}
