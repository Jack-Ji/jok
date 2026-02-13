//! Utility module for the Jok game engine.
//!
//! This module provides a collection of utility functions and data structures
//! to support common game development tasks.
//!
//! Key features:
//! - Graphics utilities (image loading, encoding, custom PNG format)
//! - Math utilities (mapping, line intersection, isometric transforms)
//! - Pathfinding algorithms (A* and Dijkstra)
//! - Easing functions for smooth animations
//! - Timer system for scheduling callbacks
//! - Dialog system for file/directory selection
//! - Signal/slot pattern for event handling
//! - Tiled map editor support
//! - Plugin system with hot-reloading
//! - Spatial data structures (QuadTree, SpatialHash)
//! - FSM (Finite State Machine) management
//! - Counter-Strike style console

const jok = @import("jok.zig");

/// Graphics utilities for image loading, saving, and custom PNG format with embedded data
pub const gfx = @import("utils/gfx.zig");

/// Math utilities for mapping, line intersection, and coordinate transformations
pub const math = @import("utils/math.zig");

/// Pathfinding algorithms (A*, Dijkstra) for graph-based navigation
pub const pathfind = @import("utils/pathfind.zig");

/// Easing functions for smooth animations and transitions (based on easings.net)
pub const easing = @import("utils/easing.zig");

/// Timer system for scheduling asynchronous callbacks with precise timing control
pub const timer = @import("utils/timer.zig");

/// Dialog system for native file/directory selection dialogs
pub const dialog = @import("utils/dialog.zig");

/// Signal/slot pattern implementation for event-driven programming
pub const signal = @import("utils/signal.zig");

/// Tiled map editor support for loading and rendering TMX format maps
pub const tiled = @import("utils/tiled.zig");

/// XML processing
pub const xml = @import("utils/xml.zig");

/// Finite state machine
/// Ported from https://github.com/cryptocode/zigfsm
pub const fsm = @import("utils/fsm.zig");

/// Plugin system with hot-reloading support for dynamic library loading
pub const plugin = @import("utils/plugin.zig");

/// Generic quad tree for efficient spatial partitioning and collision detection
const quad_tree = @import("utils/quad_tree.zig");
pub const QuadTree = quad_tree.QuadTree;

/// Generic spatial hash table for fast spatial queries and broad-phase collision detection
const spatial_hash = @import("utils/spatial_hash.zig");
pub const SpatialHash = spatial_hash.SpatialHash;

/// Generic ring data structure (stolen from old standard library)
pub const ring = @import("utils/ring.zig");

/// Console system for debugging and command input (Counter-Strike style)
pub const Console = @import("utils/Console.zig");

/// Misc utils
/// Convert various types (structs, arrays, vectors) to a 2-element f32 array
pub inline fn twoFloats(v: anytype) [2]f32 {
    if (@TypeOf(v) == jok.j2d.Vector) return v.data;
    return switch (@typeInfo(@TypeOf(v))) {
        .@"struct" => |info| blk: {
            if (info.fields.len != 2) @compileError("Expected exactly 2 fields");
            const fields = info.fields;
            break :blk .{
                @floatCast(@field(v, fields[0].name)),
                @floatCast(@field(v, fields[1].name)),
            };
        },
        .array => |info| if (info.len == 2 and info.child == f32)
            .{ v[0], v[1] }
        else
            @compileError("Expected [2]f32 array"),
        .vector => |info| if (info.len == 2 and info.child == f32)
            .{ v[0], v[1] }
        else
            @compileError("Expected @Vector(2,f32)"),
        else => @compileError("Unsupported type for twoFloats: " ++ @typeName(@TypeOf(v))),
    };
}

/// Convert various types (structs, arrays, vectors) to a 3-element f32 array
pub inline fn threeFloats(v: anytype) [3]f32 {
    if (@TypeOf(v) == jok.j3d.Vector) return v.data;
    return switch (@typeInfo(@TypeOf(v))) {
        .@"struct" => |info| blk: {
            if (info.fields.len != 3) @compileError("Expected exactly 3 fields");
            const fields = info.fields;
            break :blk .{
                @floatCast(@field(v, fields[0].name)),
                @floatCast(@field(v, fields[1].name)),
                @floatCast(@field(v, fields[2].name)),
            };
        },
        .array => |info| if (info.len == 3 and info.child == f32)
            .{ v[0], v[1], v[2] }
        else
            @compileError("Expected [3]f32 array"),
        .vector => |info| if (info.len == 3 and info.child == f32)
            .{ v[0], v[1], v[2] }
        else
            @compileError("Expected @Vector(3,f32)"),
        else => @compileError("Unsupported type for threeFloats: " ++ @typeName(@TypeOf(v))),
    };
}

test "all utils" {
    _ = pathfind;
    _ = timer;
    _ = signal;
    _ = xml;
    _ = fsm;
    _ = plugin;
    _ = quad_tree;
    _ = spatial_hash;
    _ = ring;
    _ = dialog;
}
