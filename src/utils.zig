const jok = @import("jok.zig");

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

/// Generic quad tree
const quad_tree = @import("utils/quad_tree.zig");
pub const QuadTree = quad_tree.QuadTree;

/// Generic Spatial hash-table
const spatial_hash = @import("utils/spatial_hash.zig");
pub const SpatialHash = spatial_hash.SpatialHash;

/// Generic ring data structure (stolen from old standard library)
pub const ring = @import("utils/ring.zig");

/// Misc utils
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
        else => @compileError("Unsupported type for threeFloats: " ++ @typeName(@TypeOf(v))),
    };
}

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
}
