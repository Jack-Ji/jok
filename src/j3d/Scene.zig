const std = @import("std");
const assert = std.debug.assert;
const math = std.math;
const TriangleRenderer = @import("TriangleRenderer.zig");
const Camera = @import("Camera.zig");
const sdl = @import("sdl");
const jok = @import("../jok.zig");
const zmath = jok.zmath;
const zmesh = jok.zmesh;
const j3d = jok.j3d;
const lighting = j3d.lighting;
const Self = @This();

/// Represent a position in 3d space
pub const Position = struct {
    transform: zmath.Mat = zmath.identity(),
};

/// Represent a renderable object in 3d space
pub const Mesh = struct {
    transform: zmath.Mat,
    shape: zmesh.Shape,
    color: sdl.Color,
    aabb: ?[6]f32 = null,
    disable_lighting: bool = false,
};

/// A movable object in 3d space
pub const Actor = union(enum) {
    position: Position,
    mesh: Mesh,

    inline fn calcTransform(actor: Actor, parent_m: zmath.Mat) zmath.Mat {
        return switch (actor) {
            .position => |p| zmath.mul(p.transform, parent_m),
            .mesh => |m| zmath.mul(m.transform, parent_m),
        };
    }

    inline fn setTransform(actor: *Actor, _m: zmath.Mat) void {
        return switch (actor.*) {
            .position => |*p| p.transform = _m,
            .mesh => |*m| m.transform = _m,
        };
    }

    inline fn getTransform(actor: Actor) zmath.Mat {
        return switch (actor) {
            .position => |p| p.transform,
            .mesh => |m| m.transform,
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
        assert(o.parent != null);
        o.transform = o.actor.calcTransform(o.parent.?.transform);
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
tri_rd: *TriangleRenderer,
root: *Object,
colors: std.ArrayList(sdl.Color),

pub fn create(allocator: std.mem.Allocator, _rd: ?*TriangleRenderer) !*Self {
    var self = try allocator.create(Self);
    errdefer allocator.destroy(self);
    self.allocator = allocator;
    self.arena = std.heap.ArenaAllocator.init(allocator);
    errdefer self.arena.deinit();
    self.tri_rd = _rd orelse BLK: {
        break :BLK try TriangleRenderer.create(self.arena.allocator());
    };
    self.root = try Object.create(self.allocator, .{ .position = .{} });
    errdefer self.root.destroy(false);
    self.colors = try std.ArrayList(sdl.Color).initCapacity(self.arena.allocator(), 1000);
    return self;
}

pub fn destroy(self: *Self, destroy_objects: bool) void {
    self.root.destroy(destroy_objects);
    self.arena.deinit();
    self.allocator.destroy(self);
}

/// Clear scene
pub fn clear(self: *Self) void {
    self.tri_rd.clear(true);
}

// TODO Action system
// TODO Sequence Action
// TODO Parallel Action
// TODO Event system

/// Update and render the scene
pub const RenderOption = struct {
    texture: ?sdl.Texture = null,
    wireframe: bool = false,
    wireframe_color: sdl.Color = sdl.Color.green,
    cull_faces: bool = true,
    lighting: ?lighting.LightingOption = null,
};
pub fn draw(self: *Self, renderer: sdl.Renderer, camera: Camera, opt: RenderOption) !void {
    try self.addObjectToRenderer(renderer, camera, self.root, opt);
    if (opt.wireframe) {
        try self.tri_rd.drawWireframe(renderer, opt.wireframe_color);
    } else {
        try self.tri_rd.draw(renderer, opt.texture);
    }
}

fn addObjectToRenderer(self: *Self, renderer: sdl.Renderer, camera: Camera, o: *Object, opt: RenderOption) !void {
    switch (o.actor) {
        .position => {},
        .mesh => |m| {
            self.colors.clearRetainingCapacity();
            try self.colors.ensureTotalCapacity(m.shape.positions.len);
            self.colors.appendNTimesAssumeCapacity(m.color, m.shape.positions.len);

            try self.tri_rd.addShapeData(
                renderer,
                o.transform,
                camera,
                m.shape.indices,
                m.shape.positions,
                m.shape.normals.?,
                self.colors.items,
                m.shape.texcoords,
                .{
                    .aabb = m.aabb,
                    .cull_faces = opt.cull_faces,
                    .lighting_opt = if (m.disable_lighting) null else opt.lighting,
                },
            );
        },
    }

    for (o.children.items) |c| try self.addObjectToRenderer(renderer, camera, c, opt);
}
