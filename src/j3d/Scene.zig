/// Scene management (Clone of three.js's scene. Learn detail from https://threejs.org/manual/#en/scenegraph)
const std = @import("std");
const assert = std.debug.assert;
const math = std.math;
const internal = @import("internal.zig");
const Mesh = @import("Mesh.zig");
const jok = @import("../jok.zig");
const sdl = jok.sdl;
const zmath = jok.zmath;
const j3d = jok.j3d;
const lighting = j3d.lighting;
const Self = @This();

/// Represent a position in 3d space
pub const Position = struct {
    transform: zmath.Mat = zmath.identity(),
};

/// Represent a mesh object in 3d space
pub const MeshObj = struct {
    transform: zmath.Mat,
    mesh: *Mesh,
    cull_faces: bool = true,
    color: sdl.Color = sdl.Color.white,
    texture: ?sdl.Texture = null,
    disable_lighting: bool = false,
};

/// Represent a sprite in 3d space
pub const SpriteObj = struct {
    transform: zmath.Mat,
    size: sdl.PointF,
    uv: [2]sdl.PointF,
    texture: ?sdl.Texture = null,
    tint_color: sdl.Color = sdl.Color.white,
    scale: sdl.PointF = .{ .x = 1.0, .y = 1.0 },
    rotate_degree: f32 = 0,
    anchor_point: sdl.PointF = .{ .x = 0, .y = 0 },
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
            .position => |p| zmath.mul(p.transform, parent_m),
            .mesh => |m| zmath.mul(m.transform, parent_m),
            .sprite => |s| zmath.mul(s.transform, parent_m),
        };
    }

    inline fn setTransform(actor: *Actor, _m: zmath.Mat) void {
        return switch (actor.*) {
            .position => |*p| p.transform = _m,
            .mesh => |*m| m.transform = _m,
            .sprite => |*s| s.transform = _m,
        };
    }

    inline fn getTransform(actor: Actor) zmath.Mat {
        return switch (actor) {
            .position => |p| p.transform,
            .mesh => |m| m.transform,
            .sprite => |s| s.transform,
        };
    }
};

/// Represent an abstract object in 3d space
pub const Object = struct {
    allocator: std.mem.Allocator,
    actor: Actor,
    transform: zmath.Mat,
    parent: ?*Object,
    children: std.ArrayList(*Object),

    /// Create an object
    pub fn create(allocator: std.mem.Allocator, actor: Actor) !*Object {
        var o = try allocator.create(Object);
        errdefer allocator.destroy(o);
        o.* = .{
            .allocator = allocator,
            .actor = actor,
            .transform = actor.getTransform(),
            .parent = null,
            .children = std.ArrayList(*Object).init(allocator),
        };
        return o;
    }

    /// Destroy an object
    pub fn destroy(o: *Object, recursive: bool) void {
        if (recursive) {
            for (o.children.items) |c| c.destroy(true);
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

    /// Update all objects' transform matrix in tree
    pub fn updateTransforms(o: *Object) void {
        o.transform = if (o.parent) |p|
            o.actor.calcTransform(p.transform)
        else
            o.actor.getTransform();
        for (o.children.items) |c| {
            c.updateTransforms();
        }
    }

    /// Change object's transform matrix, and update it's children accordingly
    pub fn setTransform(o: *Object, m: zmath.Mat) void {
        o.actor.setTransform(m);
        o.updateTransforms();
    }
};

allocator: std.mem.Allocator,
arena: std.heap.ArenaAllocator,
root: *Object,

pub fn create(allocator: std.mem.Allocator) !*Self {
    var self = try allocator.create(Self);
    errdefer allocator.destroy(self);
    self.allocator = allocator;
    self.arena = std.heap.ArenaAllocator.init(allocator);
    errdefer self.arena.deinit();
    self.root = try Object.create(self.allocator, .{ .position = .{} });
    return self;
}

pub fn destroy(self: *Self, destroy_objects: bool) void {
    self.root.destroy(destroy_objects);
    self.arena.deinit();
    self.allocator.destroy(self);
}

pub const RenderOption = struct {
    lighting: ?lighting.LightingOption = null,
};
pub fn render(self: Self, object: ?*Object, opt: RenderOption) !void {
    const o = object orelse self.root;
    switch (o.actor) {
        .position => {},
        .mesh => |m| try j3d.addMesh(
            m.mesh,
            o.transform,
            .{
                .rdopt = .{
                    .cull_faces = m.cull_faces,
                    .color = m.color,
                    .texture = m.texture,
                    .lighting = if (m.disable_lighting)
                        null
                    else
                        opt.lighting,
                },
            },
        ),
        .sprite => |s| try j3d.addSprite(
            o.transform,
            s.size,
            s.uv,
            .{
                .texture = s.texture,
                .tint_color = s.tint_color,
                .scale = s.scale,
                .rotate_degree = s.rotate_degree,
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

    for (o.children.items) |c| {
        try self.render(c, opt);
    }
}
