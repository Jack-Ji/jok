/// Graphics utils
pub const gfx = @import("utils/gfx.zig");

/// Math utils
pub const math = @import("utils/math.zig");

/// Path-finding utils
pub const pathfind = @import("utils/pathfind.zig");

/// Easing utils
pub const easing = @import("utils/easing.zig");

/// Timer utils
pub const timer = @import("utils/timer.zig");

/// Signal utils
pub const signal = @import("utils/signal.zig");

/// Async tools
pub const asynctool = @import("utils/async.zig");

/// Tile map support
pub const tiled = @import("utils/tiled.zig");

/// Generic ring data structure
pub const ring = @import("utils/ring.zig");

/// XML processing
pub const xml = @import("utils/xml.zig");

/// Trait system
pub const trait = @import("utils/trait.zig");

test "utils" {
    _ = timer;
    _ = signal;
    _ = pathfind;
    _ = asynctool;
    _ = xml;
    _ = ring;
    _ = trait;
}
