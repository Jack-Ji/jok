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

/// Dialog utils
pub const dialog = @import("utils/dialog.zig");

/// Signal utils
pub const signal = @import("utils/signal.zig");

/// Tile map support
pub const tiled = @import("utils/tiled.zig");

/// XML processing
pub const xml = @import("utils/xml.zig");

/// Finite state machine
/// Ported from https://github.com/cryptocode/zigfsm
pub const fsm = @import("utils/fsm.zig");

/// Plugin system
pub const plugin = @import("utils/plugin.zig");

//============================= Stolen From Old Standard Library =============================
pub const ring = @import("utils/ring.zig"); // Generic ring data structure

test "all utils" {
    _ = timer;
    _ = signal;
    _ = pathfind;
    _ = xml;
    _ = fsm;
    _ = ring;
    _ = plugin;
}
