const std = @import("std");
const assert = std.debug.assert;
const math = std.math;
const sdl = @import("sdl");
const Vector = @import("Vector.zig");
const Camera = @import("Camera.zig");
const Sprite = @import("Sprite.zig");
const SpriteBatch = @import("SpriteBatch.zig");
const Self = @This();

const RenderCallback = *const fn (
    camera: Camera,
    s: Sprite,
    sb: *SpriteBatch,
    opt: Sprite.DrawOption,
    custom: ?*anyopaque,
) anyerror!void;

/// A movable object in 2d space
pub const Actor = struct {
    sprite: ?Sprite = null,
    render_cb: ?RenderCallback = null,
    custom: ?*anyopaque = null,
    render_opt: Sprite.DrawOption,

    fn getRenderOptions(actor: Actor, parent_opt: Sprite.DrawOption) Sprite.DrawOption {
        return .{
            .pos = .{
                .x = parent_opt.pos.x + actor.render_opt.pos.x,
                .y = parent_opt.pos.y + actor.render_opt.pos.y,
            },
            .tint_color = actor.render_opt.tint_color,
            .scale_w = parent_opt.scale_w * actor.render_opt.scale_w,
            .scale_h = parent_opt.scale_h * actor.render_opt.scale_h,
            .rotate_degree = parent_opt.rotate_degree + actor.render_opt.rotate_degree,
            .anchor_point = actor.render_opt.anchor_point,
            .flip_h = if (parent_opt.flip_h) !actor.render_opt.flip_h else actor.render_opt.flip_h,
            .flip_v = if (parent_opt.flip_v) !actor.render_opt.flip_v else actor.render_opt.flip_v,
        };
    }
};

/// Represent an abstract object in 2d space
pub const Object = struct {
    allocator: std.mem.Allocator,
    actor: Actor,
    render_opt: Sprite.DrawOption,
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
        o.render_opt = o.actor.getRenderOptions(o.parent.?.render_opt);
        for (o.children.items) |c| {
            c.updateRenderOptions();
        }
    }

    // Change object's rendering option
    pub fn setRenderOptions(o: *Object, opt: Sprite.DrawOption) void {
        o.actor.render_opt = opt;
        o.updateRenderOptions();
    }
};

allocator: std.mem.Allocator,
root: *Object,
sb: *SpriteBatch,

pub fn create(allocator: std.mem.Allocator, sb: *SpriteBatch) !*Self {
    var self = try allocator.create(Self);
    errdefer allocator.destroy(self);
    self.allocator = allocator;
    self.root = try Object.create(self.allocator, .{
        .render_opt = .{ .pos = .{ .x = 0, .y = 0 } },
    }, null);
    errdefer self.root.destroy(false);
    self.sb = sb;
    return self;
}

pub fn destroy(self: *Self, destroy_objects: bool) void {
    self.root.destroy(destroy_objects);
    self.allocator.destroy(self);
}

/// Batch all sprites for rendering
pub fn draw(self: *Self, camera: Camera) !void {
    try self.submitObject(camera, self.root);
}

fn submitObject(self: *Self, camera: Camera, o: *Object) !void {
    if (o.actor.sprite) |s| {
        if (o.actor.render_cb) |cb| {
            try cb(camera, s, self.sb, o.render_opt, o.actor.custom);
        } else {
            try self.sb.addSprite(s, .{
                .pos = o.render_opt.pos,
                .camera = camera,
                .tint_color = o.render_opt.tint_color,
                .scale_w = o.render_opt.scale_w,
                .scale_h = o.render_opt.scale_h,
                .flip_h = o.render_opt.flip_h,
                .flip_v = o.render_opt.flip_v,
                .rotate_degree = o.render_opt.rotate_degree,
                .anchor_point = o.render_opt.anchor_point,
                .depth = o.depth,
            });
        }
    }

    for (o.children.items) |c| try self.submitObject(camera, c);
}
