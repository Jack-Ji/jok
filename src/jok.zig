/// Game config options
pub const config = @import("config.zig");

/// Context of application
pub const context = @import("context.zig");
pub const Context = context.Context;

/// Basic types
const basic = @import("basic.zig");
pub const Point = basic.Point;
pub const Size = basic.Size;
pub const Region = basic.Region;
pub const Rectangle = basic.Rectangle;
pub const Circle = basic.Circle;
pub const Ellipse = basic.Ellipse;
pub const Triangle = basic.Triangle;
pub const Color = basic.Color;
pub const ColorF = basic.ColorF;
pub const Vertex = basic.Vertex;

/// Window of App
pub const Window = @import("window.zig").Window;

/// I/O system
pub const io = @import("io.zig");
pub const Event = io.Event;

/// Graphics Renderer
pub const Renderer = @import("renderer.zig").Renderer;

/// Pixel Shader
pub const PixelShader = @import("shader.zig").PixelShader;

/// Graphics Texture
pub const Texture = @import("texture.zig").Texture;

/// blend mode
pub const BlendMode = @import("blend.zig").BlendMode;

/// 2d rendering
pub const j2d = @import("j2d.zig");

/// 3d rendering
pub const j3d = @import("j3d.zig");

/// Font module
pub const font = @import("font.zig");

/// Misc utils
pub const utils = @import("utils.zig");

/// Vendor libraries
pub const vendor = @import("vendor.zig");

// All tests
test "all tests" {
    _ = basic;
    _ = j2d;
    _ = j3d;
    _ = font;
    _ = utils;
}
