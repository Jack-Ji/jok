/// Game config options
pub const config = @import("config.zig");

/// Context of application
pub const Context = @import("context.zig").Context;

/// Toolkit for 2d game
pub const j2d = @import("j2d.zig");

/// Toolkit for 3d game
pub const j3d = @import("j3d.zig");

/// Font module
pub const font = @import("font.zig");

/// Misc util functions
pub const utils = @import("utils.zig");

/// Expose vendor libraries
pub usingnamespace @import("deps/deps.zig");

// All tests
test "all" {
    _ = @import("j2d/Vector.zig");
}
