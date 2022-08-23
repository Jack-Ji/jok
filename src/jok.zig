/// Game config options
pub const config = @import("config.zig");

/// Context of application
pub const Context = @import("context.zig").Context;

/// Graphics module
pub const gfx = @import("graphics.zig");

/// Audio module
pub const zaudio = deps.zaudio;

/// Linear algebra math module
pub const zmath = deps.zmath;

/// Noise generator
pub const znoise = deps.znoise;

/// Vendor libraries
pub const deps = @import("deps/deps.zig");

/// Misc util functions
pub const utils = @import("utils.zig");
