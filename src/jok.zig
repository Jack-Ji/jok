/// export core definitions
pub usingnamespace @import("core.zig");

/// system events
pub const event = @import("event.zig");

/// graphics module
pub const gfx = @import("graphics.zig");

/// audio module
pub const audio = deps.miniaudio;

/// math module
pub const math = deps.zmath;

/// vendor libraries
pub const deps = @import("deps/deps.zig");
