/// Game config options
pub const config = @import("config.zig");

/// Context of application
pub const Context = @import("context.zig").Context;

/// System events
pub const event = @import("event.zig");

/// Graphics module
pub const gfx = @import("graphics.zig");

/// Audio module
pub const audio = deps.miniaudio;

/// Linear algebra math module
pub const zmath = deps.zmath;

/// Vendor libraries
pub const deps = @import("deps/deps.zig");
