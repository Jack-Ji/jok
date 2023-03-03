const std = @import("std");
const assert = std.debug.assert;
const math = std.math;
const jok = @import("../jok.zig");
const sdl = jok.sdl;
const DrawCmd = @import("command.zig").DrawCmd;
const Vector = @import("Vector.zig");
const Sprite = @import("Sprite.zig");
const AffineTransform = @import("AffineTransform.zig");
const Self = @This();

/// A movable object in 2d space
pub const Actor = struct {
    sprite: ?Sprite = null,
    render_opt: Sprite.RenderOption,

    fn getRenderOptions(actor: Actor, parent_opt: Sprite.RenderOption) Sprite.RenderOption {
        return .{
            .pos = .{
                .x = parent_opt.pos.x + actor.render_opt.pos.x,
                .y = parent_opt.pos.y + actor.render_opt.pos.y,
            },
            .tint_color = actor.render_opt.tint_color,
            .scale = .{
                .x = parent_opt.scale.x * actor.render_opt.scale.x,
                .y = parent_opt.scale.y * actor.render_opt.scale.y,
            },
            .rotate_degree = parent_opt.rotate_degree + actor.render_opt.rotate_degree,
            .anchor_point = actor.render_opt.anchor_point,
            .flip_h = if (parent_opt.flip_h) !actor.render_opt.flip_h else actor.render_opt.flip_h,
            .flip_v = if (parent_opt.flip_v) !actor.render_opt.flip_v else actor.render_opt.flip_v,
            .depth = parent_opt.depth,
        };
    }
};

/// Represent an abstract object in 2d space
pub const Object = struct {
    allocator: std.mem.Allocator,
    actor: Actor,
    render_opt: Sprite.RenderOption,
    depth: f32,
    parent: ?*Object = null,
    children: std.ArrayList(*Object),

    /// Create an object
    pub fn create(allocator: std.mem.Allocator, actor: Actor, depth: ?f32) !*Object {
        var o = try allocator.create(Object);
        errdefer allocator.destroy(o);
        o.* = .{
            .allocator = allocator,
            .actor = actor,
            .render_opt = actor.render_opt,
            .depth = depth orelse 0.5,
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
            for (p.children.items, 0..) |_c, idx| {
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

    /// Update all objects' render options
    pub fn updateRenderOptions(o: *Object) void {
        assert(o.parent != null);
        o.render_opt = o.actor.getRenderOptions(o.parent.?.render_opt);
        for (o.children.items) |c| {
            c.updateRenderOptions();
        }
    }

    // Change object's rendering option
    pub fn setRenderOptions(o: *Object, opt: Sprite.RenderOption) void {
        o.actor.render_opt = opt;
        o.updateRenderOptions();
    }
};

allocator: std.mem.Allocator,
root: *Object,

pub fn create(allocator: std.mem.Allocator) !*Self {
    var self = try allocator.create(Self);
    errdefer allocator.destroy(self);
    self.allocator = allocator;
    self.root = try Object.create(self.allocator, .{
        .render_opt = .{ .pos = .{ .x = 0, .y = 0 } },
    }, null);
    errdefer self.root.destroy(false);
    return self;
}

pub fn destroy(self: *Self, destroy_objects: bool) void {
    self.root.destroy(destroy_objects);
    self.allocator.destroy(self);
}

pub const RenderOption = struct {
    transform: AffineTransform = AffineTransform.init(),
    object: ?*Object = null,
};
pub fn render(
    self: Self,
    draw_commands: *std.ArrayList(DrawCmd),
    opt: RenderOption,
) !void {
    const o = opt.object orelse self.root;
    if (o.actor.sprite) |s| {
        const scale = opt.transform.getScale();
        var rdopt = o.render_opt;
        rdopt.pos = opt.transform.transformPoint(rdopt.pos);
        rdopt.scale.x *= scale.x;
        rdopt.scale.y *= scale.y;
        try s.render(draw_commands, rdopt);
    }

    for (o.children.items) |c| try self.render(
        draw_commands,
        .{ .transform = opt.transform, .object = c },
    );
}
