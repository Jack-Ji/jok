const std = @import("std");
const assert = std.debug.assert;
const math = std.math;
const sdl = @import("sdl");
const Vector = @import("Vector.zig");
const Camera = @import("Camera.zig");
const Sprite = @import("Sprite.zig");
const SpriteBatch = @import("SpriteBatch.zig");
const Self = @This();

pub const Actor = struct {
    sprite: ?Sprite = null,
    opt: Sprite.DrawOption,
    render: *const fn (sb: *SpriteBatch, opt: Sprite.DrawOption) void,
};

/// Represent an object in 2d space
pub const Object = struct {
    allocator: std.mem.Allocator,
    pos: sdl.PointF,
    actor: Actor,
    opt: Sprite.DrawOption,
    parent: ?*Object = null,
    children: std.ArrayList(*Object),

    /// Create an object
    pub fn init(allocator: std.mem.Allocator, actor: Actor) !*Object {
        var o = try allocator.create(Object);
        errdefer allocator.destroy(o);
        o.* = .{
            .allocator = allocator,
            .actor = actor,
            .opt = actor.opt,
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
        c.updateRenderOptions();
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

    /// Update all objects' render options
    pub fn updateRenderOptions(o: *Object) void {
        assert(o.parent != null);
        o.transform = o.uo.calcTransform(o.parent.?.transform);
        for (o.children.items) |c| {
            c.updateRenderOptions();
        }
    }

    // Change object's transform matrix, and update it's children accordingly
    //pub fn setTransform(o: *Object, m: zmath.Mat) void {
    //    o.uo.setTransform(m);
    //    o.updateTransforms();
    //}
};

allocator: std.mem.Allocator,
arena: std.heap.ArenaAllocator,
root: *Object,
sb: *SpriteBatch,

pub fn init(allocator: std.mem.Allocator, sb: *SpriteBatch) !*Self {
    var self = try allocator.create(Self);
    errdefer allocator.destroy(self);
    self.allocator = allocator;
    self.arena = std.heap.ArenaAllocator.init(allocator);
    errdefer self.arena.deinit();
    self.root = try Object.init(self.arena.allocator(), .{ .position = .{} });
    errdefer self.root.deinit(false);
    self.sb = sb;
    return self;
}

pub fn deinit(self: *Self, destroy_objects: bool) void {
    self.root.deinit(destroy_objects);
    self.tri_rd.deinit();
    self.arena.deinit();
    self.allocator.destroy(self);
}

/// Update and render the scene
pub const RenderOption = struct {
    texture: ?sdl.Texture = null,
    wireframe: bool = false,
    wireframe_color: sdl.Color = sdl.Color.green,
    cull_faces: bool = true,
};
pub fn render(self: *Self, renderer: sdl.Renderer, camera: Camera, opt: RenderOption) !void {
    try self.addObjectToRenderer(renderer, camera, self.root, opt);
    if (opt.wireframe) {
        try self.tri_rd.drawWireframe(renderer, opt.wireframe_color);
    } else {
        try self.tri_rd.draw(renderer, opt.texture);
    }
}
