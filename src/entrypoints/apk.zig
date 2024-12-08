const std = @import("std");
const jok = @import("jok");
const config = jok.config;
const game = @import("game");
const compcheck = @import("compcheck.zig");

// Validate game object
comptime {
    compcheck.doCheck(game);
}

/// Jok configuration
const jok_config = config.init(game);

// TODO Android callbacks
