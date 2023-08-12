const std = @import("std");

/// Re-export audio's api
pub usingnamespace @import("zaudio/src/zaudio.zig");
const zaudio = @import("zaudio/src/zaudio.zig");

// Get sdl context lazily
fn getContext() *zaudio.Context {
    const S = struct {
        var sdl_context: ?*zaudio.Context = null;
    };
    if (S.sdl_context) |ctx| {
        return ctx;
    } else {
        S.sdl_context = ma_create_sdl_Context();
        std.debug.assert(S.sdl_context != null);
        return S.sdl_context.?;
    }
}
extern fn ma_create_sdl_Context() ?*zaudio.Context;

/// Create new engine
pub fn createEngine() !*zaudio.Engine {
    var engine_config = zaudio.Engine.Config.init();
    engine_config.context = getContext();
    return try zaudio.Engine.create(engine_config);
}
