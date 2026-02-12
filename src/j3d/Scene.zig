//! Scene graph management for hierarchical 3D rendering.
//!
//! This module provides a scene graph system inspired by three.js, allowing
//! hierarchical organization of 3D objects with parent-child relationships.
//!
//! Features:
//! - Hierarchical transformations (parent transforms affect children)
//! - Multiple object types (positions, meshes, sprites)
//! - Transform inheritance through the scene graph
//! - Efficient batch rendering
//!
//! Learn more at: https://threejs.org/manual/#en/scenegraph

const std = @import("std");
const assert = std.debug.assert;
const math = std.math;
const internal = @import("internal.zig");
const jok = @import("../jok.zig");
const Point = jok.j2d.geom.Point;
const Batch = jok.j3d.Batch;
const lighting = jok.j3d.lighting;
const zmath = jok.vendor.zmath;
const Mesh = @import("Mesh.zig");
const Self = @This();

/// Represent a position in 3d space
pub const Position = struct {
    transform: zmath.Mat = zmath.identity(),
};

/// Represent a mesh object in 3d space
pub const MeshObj = struct {
    mesh: *Mesh,
    transform: zmath.Mat = zmath.identity(),
    cull_faces: bool = true,
    color: jok.ColorF = .white,
    texture: ?jok.Texture = null,
    disable_lighting: bool = false,
};

/// Represent a sprite in 3d space
pub const SpriteObj = struct {
    size: Point,
    uv: [2]Point,
    transform: zmath.Mat = zmath.identity(),
    texture: ?jok.Texture = null,
    tint_color: jok.ColorF = .white,
    scale: Point = .unit,
    rotate_angle: f32 = 0,
    anchor_point: Point = .origin,
    flip_h: bool = false,
    flip_v: bool = false,
    facing_dir: ?[3]f32 = null,
    fixed_size: bool = false,
    disable_lighting: bool = true,
    tessellation_level: u8 = 0,
};

/// A movable object in 3d space
pub const Actor = union(enum) {
    position: Position,
    mesh: MeshObj,
    sprite: SpriteObj,

    inline fn calcTransform(actor: Actor, parent_m: zmath.Mat) zmath.Mat {
        return switch (actor) {
            inline else => |a| zmath.mul(a.transform, parent_m),
        };
    }

    inline fn setTransform(actor: *Actor, _m: zmath.Mat) void {
        return switch (actor.*) {
            inline else => |*a| a.transform = _m,
        };
    }

    inline fn getTransform(actor: Actor) zmath.Mat {
        return switch (actor) {
            inline else => |a| a.transform,
        };
    }
};

/// Represent an abstract object in 3d space
pub const Object = struct {
    allocator: std.mem.Allocator,
    actor: Actor,
    transform: zmath.Mat,
    parent: ?*Object,
    children: std.array_list.Managed(*Object),

    /// Create an object
    pub fn create(allocator: std.mem.Allocator, actor: Actor) !*Object {
        const o = try allocator.create(Object);
        errdefer allocator.destroy(o);
        o.* = .{
            .allocator = allocator,
            .actor = actor,
            .transform = actor.getTransform(),
            .parent = null,
            .children = .init(allocator),
        };
        return o;
    }

    /// Destroy an object
    pub fn destroy(o: *Object, recursive: bool) void {
        if (recursive) {
            while (o.children.items.len > 0) o.children.items[0].destroy(true);
        }
        if (o.actor == .mesh) {
            o.actor.mesh.mesh.destroy();
        }
        o.removeSelf();
        o.children.deinit();
        o.allocator.destroy(o);
    }

    /// Add child
    pub fn addChild(o: *Object, c: *Object) !void {
        assert(o != c);
        if (c.parent) |p| {
            if (p == o) return;

            // Leave old parent
            for (p.children.items, 0..) |_c, idx| {
                if (_c == c) {
                    _ = p.children.swapRemove(idx);
                    break;
                }
            } else unreachable;
        }

        c.parent = o;
        try o.children.append(c);
        c.updateTransforms();
    }

    /// Remove child
    pub fn removeChild(o: *Object, c: *Object) void {
        if (c.parent) |p| {
            if (p != o) return;

            for (o.children.items, 0..) |_c, idx| {
                if (_c == c) {
                    _ = o.children.swapRemove(idx);
                    break;
                }
            } else unreachable;

            c.parent = null;
        }
    }

    /// Remove itself from scene
    pub fn removeSelf(o: *Object) void {
        if (o.parent) |p| {
            // Leave old parent
            for (p.children.items, 0..) |c, idx| {
                if (o == c) {
                    _ = p.children.swapRemove(idx);
                    break;
                }
            } else unreachable;

            o.parent = null;
        }
    }

    /// Change object's transform matrix, and update its children accordingly
    pub fn setTransform(o: *Object, m: zmath.Mat) void {
        o.actor.setTransform(m);
        o.updateTransforms();
    }

    /// Update all objects' transform matrix in tree
    fn updateTransforms(o: *Object) void {
        o.transform = if (o.parent) |p|
            o.actor.calcTransform(p.transform)
        else
            o.actor.getTransform();
        for (o.children.items) |c| {
            c.updateTransforms();
        }
    }
};

allocator: std.mem.Allocator,
root: *Object,

/// Create a new scene with an empty root object.
pub fn create(allocator: std.mem.Allocator) !*Self {
    var self = try allocator.create(Self);
    errdefer allocator.destroy(self);
    self.allocator = allocator;
    self.root = try Object.create(self.allocator, .{ .position = .{} });
    return self;
}

/// Destroy the scene. If `destroy_objects` is true, recursively destroy all objects.
pub fn destroy(self: *Self, destroy_objects: bool) void {
    self.root.destroy(destroy_objects);
    self.allocator.destroy(self);
}

/// Options for rendering the scene.
pub const RenderOption = struct {
    /// Optional lighting applied to all objects (unless individually disabled)
    lighting: ?lighting.LightingOption = null,
};

/// Render the scene (or a subtree starting at `object`) into the given batch.
pub fn render(self: Self, batch: *Batch, object: ?*Object, opt: RenderOption) !void {
    const o = object orelse self.root;
    try batch.pushTransform();
    batch.trs = zmath.mul(o.transform, batch.trs);
    switch (o.actor) {
        .position => {},
        .mesh => |m| {
            try batch.mesh(
                m.mesh,
                .{
                    .cull_faces = m.cull_faces,
                    .color = m.color,
                    .texture = m.texture,
                    .lighting = if (m.disable_lighting)
                        null
                    else
                        opt.lighting,
                },
            );
        },
        .sprite => |s| try batch.sprite(
            s.size,
            s.uv,
            .{
                .texture = s.texture,
                .tint_color = s.tint_color,
                .scale = s.scale,
                .rotate_angle = s.rotate_angle,
                .anchor_point = s.anchor_point,
                .flip_h = s.flip_h,
                .flip_v = s.flip_v,
                .facing_dir = s.facing_dir,
                .fixed_size = s.fixed_size,
                .lighting = if (s.disable_lighting)
                    null
                else
                    opt.lighting,
                .tessellation_level = s.tessellation_level,
            },
        ),
    }
    batch.popTransform();

    for (o.children.items) |c| {
        try self.render(batch, c, opt);
    }
}
