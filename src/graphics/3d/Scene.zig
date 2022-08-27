const std = @import("std");
const assert = std.debug.assert;
const math = std.math;
const TriangleRenderer = @import("TriangleRenderer.zig");
const Camera = @import("Camera.zig");
const sdl = @import("sdl");
const jok = @import("../../jok.zig");
const @"3d" = jok.gfx.@"3d";
const zmath = @"3d".zmath;
const zmesh = @"3d".zmesh;
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

/// Universal object
pub const UO = union(enum) {
    position: Position,
    mesh: Mesh,

    inline fn calcTransform(uo: UO, parent_m: zmath.Mat) zmath.Mat {
        return switch (uo) {
            .position => |p| zmath.mul(p.transform, parent_m),
            .mesh => |m| zmath.mul(m.transform, parent_m),
        };
    }

    inline fn setTransform(uo: *UO, _m: zmath.Mat) void {
        return switch (uo.*) {
            .position => |*p| p.transform = _m,
            .mesh => |*m| m.transform = _m,
        };
    }

    inline fn getTransform(uo: UO) zmath.Mat {
        return switch (uo) {
            .position => |p| p.transform,
            .mesh => |m| m.transform,
        };
    }
};

/// Represent an object in 3d space
pub const Object = struct {
    allocator: std.mem.Allocator,
    uo: UO,
    transform: zmath.Mat,
    parent: ?*Object,
    children: std.ArrayList(*Object),

    /// Create an object
    pub fn init(allocator: std.mem.Allocator, uo: UO) !*Object {
        var o = try allocator.create(Object);
        errdefer allocator.destroy(o);
        o.* = .{
            .allocator = allocator,
            .uo = uo,
            .transform = uo.getTransform(),
            .parent = null,
            .children = std.ArrayList(*Object).init(allocator),
        };
        return o;
    }

    /// Destroy an object
    pub fn deinit(o: *Object, recursive: bool) void {
        if (recursive) {
            for (o.children.items) |c| c.deinit(true);
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
        o.transform = o.uo.calcTransform(o.parent.?.transform);
        for (o.children.items) |c| {
            c.updateTransforms();
        }
    }

    /// Change object's transform matrix, and update it's children accordingly
    pub fn setTransform(o: *Object, m: zmath.Mat) void {
        o.uo.setTransform(m);
        o.updateTransforms();
    }
};

allocator: std.mem.Allocator,
arena: std.heap.ArenaAllocator,
rd: TriangleRenderer,
root: *Object,
colors: std.ArrayList(sdl.Color),

pub fn init(ctx: *jok.Context) !*Self {
    var self = try ctx.allocator.create(Self);
    errdefer ctx.allocator.destroy(self);
    self.allocator = ctx.allocator;
    self.arena = std.heap.ArenaAllocator.init(ctx.allocator);
    errdefer self.arena.deinit();
    self.rd = TriangleRenderer.init(ctx);
    self.root = try Object.init(self.arena.allocator(), .{ .position = .{} });
    errdefer self.root.deinit(false);
    self.colors = try std.ArrayList(sdl.Color).initCapacity(self.arena.allocator(), 1000);
    return self;
}

pub fn deinit(self: *Self, destroy_objects: bool) void {
    self.root.deinit(destroy_objects);
    self.rd.deinit();
    self.arena.deinit();
    self.allocator.destroy(self);
}

/// Update and render the scene
pub const RenderOption = struct {
    texture: ?sdl.Texture = null,
    wireframe: bool = false,
    wireframe_color: sdl.Color = sdl.Color.green,
    cull_faces: bool = true,
    lighting: ?TriangleRenderer.LightingOption = null,
};
pub fn render(self: *Self, camera: Camera, opt: RenderOption) !void {
    self.rd.clear(true);
    try self.addObjectToRenderer(camera, self.root, opt);
    if (opt.wireframe) {
        try self.rd.drawWireframe(opt.wireframe_color);
    } else {
        try self.rd.draw(opt.texture);
    }
}

fn addObjectToRenderer(self: *Self, camera: Camera, o: *Object, opt: RenderOption) !void {
    switch (o.uo) {
        .position => {},
        .mesh => |m| {
            self.colors.clearRetainingCapacity();
            try self.colors.ensureTotalCapacity(m.shape.positions.len);
            self.colors.appendNTimesAssumeCapacity(m.color, m.shape.positions.len);

            try self.rd.appendShape(
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
                    .lighting = if (m.disable_lighting) null else opt.lighting,
                },
            );
        },
    }

    for (o.children.items) |c| try self.addObjectToRenderer(camera, c, opt);
}
