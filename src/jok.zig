/// Game config options
pub const config = @import("config.zig");

/// Context of application
pub const Context = @import("context.zig").Context;
pub const JokContext = @import("context.zig").JokContext;

/// Basic types
pub const Point = @import("basic.zig").Point;
pub const Size = @import("basic.zig").Size;
pub const Rectangle = @import("basic.zig").Rectangle;

/// Window of App
pub const Window = @import("window.zig").Window;

/// blend method
pub const BlendMethod = @import("blend.zig").BlendMethod;

/// 2d rendering
pub const j2d = @import("j2d.zig");

/// 3d rendering
pub const j3d = @import("j3d.zig");

/// Font module
pub const font = @import("font.zig");

/// Misc util functions
pub const utils = @import("utils.zig");

/// Expose vendor libraries
pub usingnamespace @import("vendor.zig");

// All tests
test "all" {
    _ = j2d;
    _ = j3d;
    _ = font;
    _ = utils;
}
