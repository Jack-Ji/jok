const std = @import("std");
const assert = std.debug.assert;
const math = std.math;
const jok = @import("../jok.zig");
const Batch = jok.j2d.Batch;
const SpriteOption = Batch.SpriteOption;
const DrawCmd = @import("internal.zig").DrawCmd;
const Vector = @import("Vector.zig");
const Sprite = @import("Sprite.zig");
const AffineTransform = @import("AffineTransform.zig");
const Self = @This();

/// Represent a position in 2d space
pub const Position = struct {
    transform: AffineTransform = .init,
};

/// 2D primitive
pub const Primitive = struct {
    dcmd: DrawCmd,
    transform: AffineTransform = .init,
};

/// Sprite obj
pub const SpriteObj = struct {
    sp: Sprite,
    transform: AffineTransform = .init,
    tint_color: jok.Color = .white,
    anchor_point: jok.Point = .anchor_top_left,
    flip_h: bool = false,
    flip_v: bool = false,
};

/// An object in 2d space
pub const Actor = union(enum) {
    position: Position,
    primitive: Primitive,
    sprite: SpriteObj,

    inline fn calcTransform(actor: Actor, parent_trs: AffineTransform) AffineTransform {
        return switch (actor) {
            .position => |p| p.transform.mul(parent_trs),
            .primitive => |p| p.transform.mul(parent_trs),
            .sprite => |s| s.transform.mul(parent_trs),
        };
    }

    inline fn setTransform(actor: *Actor, trs: AffineTransform) void {
        return switch (actor.*) {
            .position => |*p| p.transform = trs,
            .primitive => |*p| p.transform = trs,
            .sprite => |*s| s.transform = trs,
        };
    }

    inline fn getTransform(actor: Actor) AffineTransform {
        return switch (actor) {
            .position => |p| p.transform,
            .primitive => |p| p.transform,
            .sprite => |s| s.transform,
        };
    }
};

/// Represent an abstract object in 2d space
pub const Object = struct {
    allocator: std.mem.Allocator,
    actor: Actor,
    transform: AffineTransform,
    parent: ?*Object,
    depth: f32,
    children: std.array_list.Managed(*Object),

    /// Create an object
    pub fn create(allocator: std.mem.Allocator, actor: Actor, depth: ?f32) !*Object {
        const o = try allocator.create(Object);
        errdefer allocator.destroy(o);
        o.* = .{
            .allocator = allocator,
            .actor = actor,
            .transform = actor.getTransform(),
            .parent = null,
            .depth = depth orelse 0.5,
            .children = .init(allocator),
        };
        return o;
    }

    /// Destroy an object
    pub fn destroy(o: *Object, recursive: bool) void {
        if (recursive) {
            while (o.children.items.len > 0) o.children.items[0].destroy(true);
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

    // Change object's transform, and update it's children accordingly
    pub fn setTransform(o: *Object, trs: AffineTransform) void {
        o.actor.setTransform(trs);
        o.updateTransforms();
    }

    /// Update all objects' transforms
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

pub fn create(allocator: std.mem.Allocator) !*Self {
    var self = try allocator.create(Self);
    errdefer allocator.destroy(self);
    self.allocator = allocator;
    self.root = try Object.create(self.allocator, .{ .position = .{} }, null);
    return self;
}

pub fn destroy(self: *Self, destroy_objects: bool) void {
    self.root.destroy(destroy_objects);
    self.allocator.destroy(self);
}

pub fn render(self: Self, batch: *Batch, object: ?*Object) !void {
    const o = object orelse self.root;
    try batch.pushTransform();
    batch.trs = o.transform.mul(batch.trs);
    switch (o.actor) {
        .position => {},
        .primitive => |p| try batch.pushDrawCommand(p.dcmd, o.depth),
        .sprite => |s| try batch.sprite(
            s.sp,
            .{
                .tint_color = s.tint_color,
                .anchor_point = s.anchor_point,
                .flip_h = s.flip_h,
                .flip_v = s.flip_v,
            },
        ),
    }
    batch.popTransform();

    for (o.children.items) |c| try self.render(batch, c);
}
