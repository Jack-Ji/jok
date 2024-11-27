/// Graphics utils
pub const gfx = @import("utils/gfx.zig");

/// Math utils
pub const math = @import("utils/math.zig");

/// Algorithms (trigonomy etc)
pub const algo = @import("utils/algo.zig");

/// Path-finding utils
pub const pathfind = @import("utils/pathfind.zig");

/// Easing utils
pub const easing = @import("utils/easing.zig");

/// Async tools
pub const asynctool = @import("utils/async.zig");

/// Tile map support
pub const tiled = @import("utils/tiled.zig");

/// GIF support
pub const gif = @import("utils/gif.zig");

/// Generic ring data structure
pub const ring = @import("utils/ring.zig");

/// XML processing
pub const xml = @import("utils/xml.zig");

/// Trait system
pub const trait = @import("utils/trait.zig");

/// Whether current thread is main thread
pub fn isMainThread() bool {
    const std = @import("std");
    const S = struct {
        var main_thread_id: ?std.Thread.Id = null;
    };
    if (S.main_thread_id) |id| {
        return id == std.Thread.getCurrentId();
    }
    S.main_thread_id = std.Thread.getCurrentId();
    return true;
}

test "utils" {
    _ = pathfind;
    _ = asynctool;
    _ = xml;
    _ = ring;
    _ = trait;
}
