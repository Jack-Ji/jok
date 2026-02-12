//! 3D skeletal animation system.
//!
//! This module provides skeletal animation playback for GLTF models with:
//! - Keyframe interpolation (linear, step, cubic spline)
//! - Transform animation (translation, rotation, scale)
//! - Animation blending and transitions
//! - Skinned mesh deformation
//!
//! Animations are loaded from GLTF files and can be played back with
//! smooth transitions between different animation states.

const std = @import("std");
const math = std.math;
const assert = std.debug.assert;
const jok = @import("../jok.zig");
const Size = jok.j2d.geom.Size;
const j3d = jok.j3d;
const zmath = jok.vendor.zmath;
const Vector = @import("Vector.zig");
const TriangleRenderer = @import("TriangleRenderer.zig");
const ShadingMethod = TriangleRenderer.ShadingMethod;
const Camera = @import("Camera.zig");
const lighting = @import("lighting.zig");
const Mesh = @import("Mesh.zig");
const Self = @This();

/// Animation transition parameters for blending between animations
pub const Transition = struct {
    from: *const Self,
    progress: f32,
};

/// Rendering options for animated meshes
pub const RenderOption = struct {
    texture: ?jok.Texture = null,
    color: jok.ColorF = .white,
    shading_method: ShadingMethod = .gouraud,
    cull_faces: bool = true,
    lighting: ?lighting.LightingOption = null,
    transition: ?Transition = null,
    playtime: f32 = 0,
};

const Transform = struct {
    scale: zmath.Vec,
    rotation: zmath.Vec,
    translation: zmath.Vec,
    matrix: ?zmath.Mat = null,

    fn calcLocalTransform(self: *const Transform) zmath.Mat {
        return zmath.mul(
            zmath.mul(
                zmath.scalingV(self.scale),
                zmath.matFromQuat(@as(zmath.Quat, self.rotation)),
            ),
            zmath.translationV(self.translation),
        );
    }
};

allocator: std.mem.Allocator,
anim: *Mesh.Animation,
transforms: std.AutoHashMap(*const Mesh.Node, Transform),

pub fn create(allocator: std.mem.Allocator, ma: *Mesh.Animation) !*Self {
    var self = try allocator.create(Self);
    self.* = .{
        .allocator = allocator,
        .anim = ma,
        .transforms = std.AutoHashMap(*const Mesh.Node, Transform).init(allocator),
    };
    var it = ma.mesh.nodes_map.valueIterator();
    try self.transforms.put(ma.mesh.root, .{
        .scale = ma.mesh.root.scale,
        .rotation = ma.mesh.root.rotation,
        .translation = ma.mesh.root.translation,
    });
    while (it.next()) |node| {
        try self.transforms.put(node.*, .{
            .scale = node.*.scale,
            .rotation = node.*.rotation,
            .translation = node.*.translation,
        });
    }
    return self;
}

pub fn destroy(self: *Self) void {
    self.transforms.deinit();
    self.allocator.destroy(self);
}

pub fn render(
    self: *Self,
    csz: Size,
    batch: *j3d.Batch,
    _model: zmath.Mat,
    camera: Camera,
    tri_rd: *TriangleRenderer,
    opt: RenderOption,
) !void {
    // Convert to right-handed system (glTF use right-handed system)
    const model = zmath.mul(zmath.scaling(1, 1, -1), _model);

    // Reset world matrix
    var it = self.transforms.valueIterator();
    while (it.next()) |tr| {
        tr.*.matrix = null;
    }

    // Update TRS of nodes
    var progress: f32 = undefined;
    if (opt.transition) |tr| {
        assert(tr.from.anim.mesh == self.anim.mesh);
        progress = zmath.clamp(tr.progress, 0.0, 1.0);
    }

    for (self.anim.channels.items) |*ch| {
        const node = ch.node;
        switch (ch.path) {
            .translation => {
                const v = if (opt.playtime <= ch.timesteps[0])
                    ch.samples[0]
                else if (opt.playtime >= ch.timesteps[ch.timesteps.len - 1])
                    ch.samples[ch.timesteps.len - 1]
                else blk: {
                    var index: usize = 0;
                    for (ch.timesteps) |t| {
                        if (opt.playtime < t) {
                            index -= 1;
                            break;
                        }
                        index += 1;
                    }
                    switch (ch.interpolation) {
                        .linear => {
                            const v0 = ch.samples[index];
                            const v1 = ch.samples[index + 1];
                            const t = (opt.playtime - ch.timesteps[index]) /
                                (ch.timesteps[index + 1] - ch.timesteps[index]);
                            break :blk zmath.lerp(v0, v1, t);
                        },
                        .step => break :blk ch.samples[index],
                        else => unreachable,
                    }
                };
                if (opt.transition) |tr| {
                    const old_transform = tr.from.transforms.getPtr(node).?;
                    self.transforms.getPtr(node).?.translation =
                        zmath.lerp(old_transform.translation, v, progress);
                } else {
                    self.transforms.getPtr(node).?.translation = v;
                }
            },
            .rotation => {
                const v = @as(
                    zmath.Quat,
                    if (opt.playtime <= ch.timesteps[0])
                        ch.samples[0]
                    else if (opt.playtime >= ch.timesteps[ch.timesteps.len - 1])
                        ch.samples[ch.timesteps.len - 1]
                    else blk: {
                        var index: usize = 0;
                        for (ch.timesteps) |t| {
                            if (opt.playtime < t) {
                                index -= 1;
                                break;
                            }
                            index += 1;
                        }
                        switch (ch.interpolation) {
                            .linear => {
                                const v0 = @as(zmath.Quat, ch.samples[index]);
                                const v1 = @as(zmath.Quat, ch.samples[index + 1]);
                                const t = (opt.playtime - ch.timesteps[index]) /
                                    (ch.timesteps[index + 1] - ch.timesteps[index]);
                                break :blk zmath.slerp(v0, v1, t);
                            },
                            .step => break :blk ch.samples[index],
                            else => unreachable,
                        }
                    },
                );
                if (opt.transition) |tr| {
                    const old_transform = tr.from.transforms.getPtr(node).?;
                    self.transforms.getPtr(node).?.rotation =
                        zmath.slerp(old_transform.rotation, v, progress);
                } else {
                    self.transforms.getPtr(node).?.rotation = v;
                }
            },
            .scale => {
                const v = if (opt.playtime <= ch.timesteps[0])
                    ch.samples[0]
                else if (opt.playtime >= ch.timesteps[ch.timesteps.len - 1])
                    ch.samples[ch.timesteps.len - 1]
                else blk: {
                    var index: usize = 0;
                    for (ch.timesteps) |t| {
                        if (opt.playtime < t) {
                            index -= 1;
                            break;
                        }
                        index += 1;
                    }
                    switch (ch.interpolation) {
                        .linear => {
                            const v0 = ch.samples[index];
                            const v1 = ch.samples[index + 1];
                            const t = (opt.playtime - ch.timesteps[index]) /
                                (ch.timesteps[index + 1] - ch.timesteps[index]);
                            break :blk zmath.lerp(v0, v1, t);
                        },
                        .step => break :blk ch.samples[index],
                        else => @panic("unrechable"),
                    }
                };
                if (opt.transition) |tr| {
                    const old_transform = tr.from.transforms.getPtr(node).?;
                    self.transforms.getPtr(node).?.scale =
                        zmath.lerp(old_transform.scale, v, progress);
                } else {
                    self.transforms.getPtr(node).?.scale = v;
                }
            },
            else => continue,
        }
    }

    try self.renderNode(
        self.anim.mesh.root,
        csz,
        batch,
        model,
        camera,
        tri_rd,
        opt,
    );
}

pub fn getName(self: *const Self) []const u8 {
    return self.anim.name;
}

pub fn getDuration(self: *const Self) f32 {
    return self.anim.duration;
}

fn renderNode(
    self: *Self,
    node: *Mesh.Node,
    csz: Size,
    batch: *j3d.Batch,
    model: zmath.Mat,
    camera: Camera,
    tri_rd: *TriangleRenderer,
    opt: RenderOption,
) !void {
    const matrix = if (self.anim.isSkeletonAnimation())
        if (node.is_joint)
            zmath.mul(self.getNodeTransform(node), model)
        else
            // According to glTF spec: only the joint transforms are applied to the
            // skinned mesh; the transform of the skinned mesh node MUST be ignored.
            model
    else
        zmath.mul(self.getNodeTransform(node), model);

    for (node.meshes) |sm| {
        try tri_rd.renderMesh(
            csz,
            batch,
            matrix,
            camera,
            sm.indices.items,
            sm.positions.items,
            if (sm.normals.items.len == 0)
                null
            else
                sm.normals.items,
            if (sm.colors.items.len == 0)
                null
            else
                sm.colors.items,
            if (sm.texcoords.items.len == 0)
                null
            else
                sm.texcoords.items,
            .{
                .aabb = null,
                .color = opt.color,
                .cull_faces = opt.cull_faces,
                .front_face = .ccw,
                .shading_method = opt.shading_method,
                .texture = opt.texture orelse sm.getTexture(),
                .lighting = opt.lighting,
                .animation = if (node.skin == null)
                    null
                else
                    .{
                        .anim = self,
                        .skin = node.skin.?,
                        .joints = sm.joints.items,
                        .weights = sm.weights.items,
                    },
            },
        );
    }

    for (node.children.items) |c| {
        try self.renderNode(
            c,
            csz,
            batch,
            model,
            camera,
            tri_rd,
            opt,
        );
    }
}

fn getNodeTransform(self: *Self, node: *const Mesh.Node) zmath.Mat {
    var tr = self.transforms.getPtr(node).?;
    if (tr.matrix) |m| return m;

    var mat = tr.calcLocalTransform();
    var parent = node.parent;
    while (parent) |p| {
        var tr_parent = self.transforms.getPtr(p).?;
        mat = zmath.mul(mat, tr_parent.calcLocalTransform());
        parent = p.parent;
    }
    tr.matrix = mat;
    return mat;
}

pub fn getSkinMatrix(
    self: *Self,
    skin: *const Mesh.Skin,
    joints: [4]u8,
    weights: [4]f32,
    model: zmath.Mat,
) zmath.Mat {
    const S = struct {
        const m_zero = zmath.Mat{
            zmath.f32x4s(0),
            zmath.f32x4s(0),
            zmath.f32x4s(0),
            zmath.f32x4s(0),
        };
    };
    var skin_m = S.m_zero;
    for (0..4) |i| {
        const w = weights[i];
        if (w == 0) continue;
        const j = joints[i];
        const m = zmath.mul(zmath.mul(
            skin.inverse_matrices[j],
            self.getNodeTransform(skin.nodes[j]),
        ), w);
        skin_m[0] += m[0];
        skin_m[1] += m[1];
        skin_m[2] += m[2];
        skin_m[3] += m[3];
    }
    return zmath.mul(skin_m, model);
}
