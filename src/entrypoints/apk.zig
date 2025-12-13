const std = @import("std");
const jok = @import("jok");
const config = jok.config;
const game = @import("game");
const compcheck = @import("compcheck.zig");
const JokContext = @import("realcontext.zig").JokContext;

// Validate game object
comptime {
    compcheck.doCheck(game);
}

/// Jok configuration
const jok_config = config.init(game);

// TODO Android callbacks
