//! # Jok - A Minimal 2D/3D Game Framework for Zig
//!
//! Jok is a lightweight, cross-platform game development framework written in Zig.
//! It provides essential building blocks for creating 2D and 3D games, including:
//!
//! - Window management and event handling
//! - 2D and 3D rendering with GPU acceleration
//! - Texture and shader support
//! - Font rendering and text layout
//! - Input handling (keyboard, mouse, gamepad)
//! - Utility functions for common game development tasks
//!
//! ## Quick Start
//!
//! ```zig
//! const jok = @import("jok");
//!
//! pub fn init(ctx: jok.Context) !void {
//!     // Initialize your game state
//! }
//!
//! pub fn event(ctx: jok.Context, e: jok.Event) !void {
//!     // Handle input events
//! }
//!
//! pub fn update(ctx: jok.Context) !void {
//!     // Update game logic
//! }
//!
//! pub fn draw(ctx: jok.Context) !void {
//!     // Render your game
//! }
//!
//! pub fn quit(ctx: jok.Context) void {
//!    // your deinit code
//! }
//! ```
//!
//! ## Module Overview
//!
//! - `config`: Game configuration options (window size, title, FPS, etc.)
//! - `Context`: Main application context providing access to all subsystems
//! - `Window`: Window management and properties
//! - `Event`: Input event handling (keyboard, mouse, touch, gamepad)
//! - `Renderer`: Low-level GPU rendering interface
//! - `Texture`: Image loading and texture management
//! - `j2d`: High-level 2D rendering API (sprites, shapes, text)
//! - `j3d`: High-level 3D rendering API (meshes, cameras, lighting)
//! - `font`: Font loading and text rendering
//! - `utils`: Utility functions and data structures

/// Game configuration options.
/// Use this to set window properties, FPS limits, and other application settings.
pub const config = @import("config.zig");

/// Application context providing access to all game subsystems.
/// This is the main interface for interacting with the framework.
/// The context is passed to all game lifecycle functions (init, event, update, draw).
pub const context = @import("context.zig");

/// Main application context type.
/// Provides access to window, renderer, input, and other subsystems.
pub const Context = context.Context;

/// Fundamental geometric and color types used throughout the framework.
const basic = @import("basic.zig");

/// 2D point with x and y coordinates.
pub const Point = basic.Point;

/// 2D size with width and height.
pub const Size = basic.Size;

/// 2D region defined by position and size.
pub const Region = basic.Region;

/// Axis-aligned rectangle.
pub const Rectangle = basic.Rectangle;

/// Circle defined by center point and radius.
pub const Circle = basic.Circle;

/// Ellipse defined by center point and radii.
pub const Ellipse = basic.Ellipse;

/// Triangle defined by three vertices.
pub const Triangle = basic.Triangle;

/// RGBA color with 8-bit integer components (0-255).
pub const Color = basic.Color;

/// RGBA color with floating-point components (0.0-1.0).
pub const ColorF = basic.ColorF;

/// Vertex structure for custom rendering (position, UV, color).
pub const Vertex = basic.Vertex;

/// Window management interface.
/// Provides control over window properties like size, title, fullscreen mode, etc.
pub const Window = @import("window.zig").Window;

/// Input/Output system for handling events.
/// Includes keyboard, mouse, touch, gamepad, and window events.
pub const io = @import("io.zig");

/// Event type for all input and window events.
/// Use pattern matching to handle different event types.
pub const Event = io.Event;

/// Low-level graphics rendering interface.
const rd = @import("renderer.zig");

/// GPU renderer for drawing primitives and textures.
/// Most users should use j2d or j3d instead of this low-level API.
pub const Renderer = rd.Renderer;

/// Shader format specification (GLSL, SPIR-V, etc.).
pub const ShaderFormat = rd.ShaderFormat;

/// Custom pixel shader for advanced rendering effects.
pub const PixelShader = rd.PixelShader;

/// Texture management for loading and using images.
/// Supports common formats like PNG, JPG, BMP, etc.
pub const Texture = @import("texture.zig").Texture;

/// Blend mode for controlling how colors are combined during rendering.
/// Includes common modes like alpha blending, additive, multiply, etc.
pub const BlendMode = @import("blend.zig").BlendMode;

/// High-level 2D rendering API.
/// Provides convenient functions for drawing sprites, shapes, text, and more.
/// This is the recommended API for 2D games.
pub const j2d = @import("j2d.zig");

/// High-level 3D rendering API.
/// Provides mesh rendering, camera management, lighting, and 3D transformations.
/// This is the recommended API for 3D games.
pub const j3d = @import("j3d.zig");

/// Font loading and text rendering.
/// Supports TrueType fonts with various rendering options.
pub const font = @import("font.zig");

/// Miscellaneous utility functions and data structures.
/// Includes math helpers, data structures, and other common utilities.
pub const utils = @import("utils.zig");

/// Third-party vendor libraries integrated into jok.
/// Includes libraries like stb_image, freetype, etc.
pub const vendor = @import("vendor.zig");

// All tests
test "all tests" {
    _ = basic;
    _ = j2d;
    _ = j3d;
    _ = font;
    _ = utils;
}
