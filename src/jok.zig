/// Export core definitions
pub usingnamespace @import("core.zig");

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
