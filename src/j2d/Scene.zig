const std = @import("std");
const builtin = @import("builtin");
const assert = std.debug.assert;
const math = std.math;
const jok = @import("../jok.zig");
const geom = jok.geom;
const Batch = jok.j2d.Batch;
const SpriteOption = Batch.SpriteOption;
const DrawCmd = @import("internal.zig").DrawCmd;
const Vector = @import("Vector.zig");
const Sprite = @import("Sprite.zig");
const AffineTransform = @import("AffineTransform.zig");
const Atlas = jok.font.Atlas;
const log = std.log.scoped(.jok);
const Self = @This();

/// Represent a position in 2d space
pub const Position = struct {
    transform: AffineTransform = .init,
};

/// A 2D draw primitive in the scene graph.
pub const Primitive = struct {
    dcmd: DrawCmd,
    transform: AffineTransform = .init,
};

/// A 2D sprite object in the scene graph.
pub const SpriteObj = struct {
    sp: Sprite,
    transform: AffineTransform = .init,
    tint_color: jok.Color = .white,
    anchor_point: geom.Point = .anchor_top_left,
    flip_h: bool = false,
    flip_v: bool = false,
};

/// A 2D text object in the scene graph.
pub const Text = struct {
    content: []const u8,
    atlas: *Atlas,
    transform: AffineTransform = .init,
    ypos_type: Atlas.YPosType = .top,
    align_type: Atlas.AlignType = .left,
    align_width: ?u32 = null,
    auto_hyphen: bool = false,
    kerning: bool = false,
    tint_color: jok.Color = .white,
    scale: geom.Point = .unit,
};

/// An object in 2d space
pub const Actor = union(enum) {
    position: Position,
    primitive: Primitive,
    sprite: SpriteObj,
    text: Text,

    inline fn calcTransform(actor: Actor, parent_trs: AffineTransform) AffineTransform {
        return switch (actor) {
            inline else => |a| a.transform.mul(parent_trs),
        };
    }

    inline fn setTransform(actor: *Actor, trs: AffineTransform) void {
        return switch (actor.*) {
            inline else => |*a| a.transform = trs,
        };
    }

    inline fn getTransform(actor: Actor) AffineTransform {
        return switch (actor) {
            inline else => |a| a.transform,
        };
    }

    inline fn getTransformedBounds(actor: Actor, trs: AffineTransform) geom.Rectangle {
        switch (actor) {
            .position => {
                const translation = trs.getTranslation();
                return .{
                    .x = translation[0],
                    .y = translation[1],
                    .width = 1,
                    .height = 1,
                };
            },
            .primitive => |a| {
                return trs.transformRectangle(a.dcmd.getRect());
            },
            .sprite => |a| {
                const rect = geom.Rectangle{
                    .x = -a.anchor_point.x * a.sp.width,
                    .y = -a.anchor_point.y * a.sp.height,
                    .width = a.sp.width,
                    .height = a.sp.height,
                };
                return trs.transformRectangle(rect);
            },
            .text => |a| {
                return a.atlas.getBoundingBox(
                    a.content,
                    trs.transformPoint(.origin),
                    .{
                        .ypos_type = a.ypos_type,
                        .align_type = a.align_type,
                        .align_width = a.align_width,
                        .auto_hyphen = a.auto_hyphen,
                        .kerning = a.kerning,
                        .scale = a.scale.mul(trs.getScale()),
                    },
                ) catch unreachable;
            },
        }
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
        if (actor == .text) {
            // Clone the text
            o.actor.text.content = try allocator.dupe(u8, actor.text.content);
        }
        return o;
    }

    /// Destroy an object
    pub fn destroy(o: *Object, recursive: bool) void {
        if (recursive) {
            while (o.children.items.len > 0) o.children.items[0].destroy(true);
        }
        o.removeSelf();
        o.children.deinit();
        if (o.actor == .text) {
            o.allocator.free(o.actor.text.content);
        }
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

    /// Change object's transform, and update its children accordingly.
    pub fn setTransform(o: *Object, trs: AffineTransform) void {
        o.actor.setTransform(trs);
        o.updateTransforms();
    }

    /// Get the axis-aligned bounding box of this object after applying transforms.
    /// NOTE: Rotation is not considered; only returns an axis-aligned rectangle.
    pub fn getTransformedBounds(o: Object, _trs: AffineTransform) geom.Rectangle {
        const trs = o.transform.mul(_trs);
        if (builtin.mode == .Debug) {
            if (!std.math.approxEqAbs(
                f32,
                trs.getRotation(),
                0,
                std.math.floatEps(f32),
            )) {
                log.warn("j2d.Scene.Object.getTransformedBounds is called on rotated object!", .{});
            }
        }
        return o.actor.getTransformedBounds(trs);
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

/// Create a new 2D scene with an empty root object.
pub fn create(allocator: std.mem.Allocator) !*Self {
    var self = try allocator.create(Self);
    errdefer allocator.destroy(self);
    self.allocator = allocator;
    self.root = try Object.create(self.allocator, .{ .position = .{} }, null);
    return self;
}

/// Destroy the scene. If `destroy_objects` is true, recursively destroy all objects.
pub fn destroy(self: *Self, destroy_objects: bool) void {
    self.root.destroy(destroy_objects);
    self.allocator.destroy(self);
}

/// Render the scene (or a subtree starting at `object`) into the given batch.
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
        .text => |t| try batch.text("{s}", .{t.content}, .{
            .atlas = t.atlas,
            .ypos_type = t.ypos_type,
            .align_type = t.align_type,
            .align_width = t.align_width,
            .auto_hyphen = t.auto_hyphen,
            .kerning = t.kerning,
            .tint_color = t.tint_color,
            .scale = t.scale,
        }),
    }
    batch.popTransform();

    for (o.children.items) |c| try self.render(batch, c);
}
