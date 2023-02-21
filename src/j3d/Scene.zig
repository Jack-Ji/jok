/// Scene management (Clone of three.js's scene. Learn detail from https://threejs.org/manual/#en/scenegraph)
const std = @import("std");
const assert = std.debug.assert;
const math = std.math;
const internal = @import("internal.zig");
const TriangleRenderer = @import("TriangleRenderer.zig");
const Camera = @import("Camera.zig");
const Mesh = @import("Mesh.zig");
const sdl = @import("sdl");
const jok = @import("../jok.zig");
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
    mesh: Mesh,
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
            o.actor.mesh.mesh.deinit();
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
            for (p.children.items) |_c, idx| {
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

            for (o.children.items) |_c, idx| {
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
            for (p.children.items) |c, idx| {
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
    object: ?*Object = null,
};
pub fn render(
    self: Self,
    tri_rd: *TriangleRenderer,
    vp: sdl.Rectangle,
    target: *internal.RenderTarget,
    camera: Camera,
    opt: RenderOption,
) !void {
    const o = opt.object orelse self.root;
    switch (o.actor) {
        .position => {},
        .mesh => |m| try tri_rd.renderMesh(
            vp,
            target,
            o.transform,
            camera,
            m.mesh.indices.items,
            m.mesh.positions.items,
            if (m.mesh.normals.items.len == 0)
                null
            else
                m.mesh.normals.items,
            null,
            if (m.mesh.texcoords.items.len == 0)
                null
            else
                m.mesh.texcoords.items,
            .{
                .aabb = m.mesh.aabb,
                .cull_faces = m.cull_faces,
                .color = m.color,
                .texture = m.texture orelse m.mesh.tex,
                .lighting = if (m.disable_lighting)
                    null
                else
                    opt.lighting,
            },
        ),
        .sprite => |s| try tri_rd.renderSprite(
            vp,
            target,
            o.transform,
            camera,
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

    var nopt = opt;
    for (o.children.items) |c| {
        nopt.object = c;
        try self.render(tri_rd, vp, target, camera, nopt);
    }
}
