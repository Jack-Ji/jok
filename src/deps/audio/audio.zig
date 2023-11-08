const std = @import("std");

/// Re-export audio's api
pub usingnamespace @import("zaudio/src/zaudio.zig");
const zaudio = @import("zaudio/src/zaudio.zig");

/// Create audio context
pub fn createContext() *zaudio.Context {
    return ma_create_sdl_context().?;
}
extern fn ma_create_sdl_context() ?*zaudio.Context;

/// Destroy audio context
pub fn destroyContext(ctx: *zaudio.Context) void {
    ma_destroy_sdl_context(ctx);
}
extern fn ma_destroy_sdl_context(ctx: *zaudio.Context) void;

/// Create new engine
pub fn createEngine(ctx: *zaudio.Context) !*zaudio.Engine {
    var engine_config = zaudio.Engine.Config.init();
    engine_config.context = ctx;
    return try zaudio.Engine.create(engine_config);
}
