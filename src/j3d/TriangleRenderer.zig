/// 3d triangle renderer
const std = @import("std");
const assert = std.debug.assert;
const math = std.math;
const jok = @import("../jok.zig");
const sdl = jok.sdl;
const zmath = jok.zmath;
const zmesh = jok.zmesh;
const j3d = jok.j3d;
const lighting = j3d.lighting;
const Camera = j3d.Camera;
const utils = jok.utils;
const internal = @import("internal.zig");
const Mesh = @import("Mesh.zig");
const Animation = @import("Animation.zig");
const Self = @This();

pub const FrontFace = enum(i32) {
    cw,
    ccw,
};

pub const ShadingMethod = enum(i32) {
    gouraud,
    flat,
};

pub const SkeletonAnimation = struct {
    anim: *Animation,
    skin: *Mesh.Skin,
    joints: []const [4]u8,
    weights: []const [4]f32,
};

pub const RenderMeshOption = struct {
    /// AABB excluding detection
    aabb: ?[6]f32 = null,

    /// Eliminate CCW triangles
    cull_faces: bool = true,
    front_face: FrontFace = .cw,

    /// Uniform material color
    color: sdl.Color = sdl.Color.white,

    /// Shading style
    shading_method: ShadingMethod = .gouraud,

    /// Binded texture
    texture: ?sdl.Texture = null,

    /// Lighting effect (only apply to sprites with explicit direction)
    lighting: ?lighting.LightingOption = null,

    /// Skeleton animation
    animation: ?SkeletonAnimation = null,
};

pub const RenderSpriteOption = struct {
    /// Binded texture
    texture: ?sdl.Texture = null,

    /// Tint color
    tint_color: sdl.Color = sdl.Color.white,

    /// Shading style
    shading_method: ShadingMethod = .gouraud,

    /// Scale of width/height
    scale: sdl.PointF = .{ .x = 1, .y = 1 },

    /// Rotation around anchor-point
    rotate_degree: f32 = 0,

    /// Anchor-point of sprite, around which rotation and translation is calculated
    anchor_point: sdl.PointF = .{ .x = 0, .y = 0 },

    /// Horizontal/vertial flipping
    flip_h: bool = false,
    flip_v: bool = false,

    /// Facing direction (always face to camera by default)
    facing_dir: ?[3]f32 = null,

    /// Fixed size (only apply to sprites facing camera)
    fixed_size: bool = false,

    /// Lighting effect (only apply to sprites with explicit direction)
    lighting: ?lighting.LightingOption = null,

    /// Tessellation level (only apply to sprites with explicit direction)
    tessellation_level: u8 = 0,
};

// Temporary storage for clipping
clip_vertices: std.ArrayList(zmath.Vec),
clip_colors: std.ArrayList(sdl.Color),
clip_texcoords: std.ArrayList(sdl.PointF),

// Vertices in world space (after clipped)
world_positions: std.ArrayList(zmath.Vec),
world_normals: std.ArrayList(zmath.Vec),

// Different tessellation level of plane
planes: [10]zmesh.Shape,

pub fn init(allocator: std.mem.Allocator) Self {
    var self = Self{
        .clip_vertices = std.ArrayList(zmath.Vec).init(allocator),
        .clip_colors = std.ArrayList(sdl.Color).init(allocator),
        .clip_texcoords = std.ArrayList(sdl.PointF).init(allocator),
        .world_positions = std.ArrayList(zmath.Vec).init(allocator),
        .world_normals = std.ArrayList(zmath.Vec).init(allocator),
        .planes = undefined,
    };
    for (&self.planes, 0..) |*p, i| {
        p.* = zmesh.Shape.initPlane(
            @intCast(i + 1),
            @intCast(i + 1),
        );
        p.computeNormals();
    }
    return self;
}

pub fn deinit(self: *Self) void {
    self.clip_vertices.deinit();
    self.clip_colors.deinit();
    self.clip_texcoords.deinit();
    self.world_positions.deinit();
    self.world_normals.deinit();
    for (&self.planes) |*p| {
        p.deinit();
    }
    self.* = undefined;
}

inline fn clear(self: *Self) void {
    self.clip_vertices.clearRetainingCapacity();
    self.clip_colors.clearRetainingCapacity();
    self.clip_texcoords.clearRetainingCapacity();
    self.world_positions.clearRetainingCapacity();
    self.world_normals.clearRetainingCapacity();
}

pub fn renderMesh(
    self: *Self,
    csz: sdl.PointF,
    target: *internal.RenderTarget,
    model: zmath.Mat,
    camera: Camera,
    indices: []const u32,
    positions: []const [3]f32,
    normals: ?[]const [3]f32,
    colors: ?[]const sdl.Color,
    texcoords: ?[]const [2]f32,
    opt: RenderMeshOption,
) !void {
    assert(@rem(indices.len, 3) == 0);
    assert(if (normals) |ns| ns.len >= positions.len else true);
    assert(if (colors) |cs| cs.len >= positions.len else true);
    assert(if (texcoords) |ts| ts.len >= positions.len else true);
    assert(if (opt.animation) |anim| anim.joints.len == anim.weights.len else true);
    if (indices.len == 0) return;
    const ndc_to_screen = zmath.loadMat43(&[_]f32{
        0.5 * csz.x, 0.0,          0.0,
        0.0,         -0.5 * csz.y, 0.0,
        0.0,         0.0,          0.5,
        0.5 * csz.x, 0.5 * csz.y,  0.5,
    });
    const vp = camera.getViewProjectMatrix();
    const mvp = zmath.mul(model, vp);

    // Do early test with aabb if possible
    if (opt.aabb) |ab| {
        const width = ab[3] - ab[0];
        const length = ab[5] - ab[2];
        assert(width >= 0);
        assert(length >= 0);
        const v0 = zmath.f32x4(ab[0], ab[1], ab[2], 1.0);
        const v1 = zmath.f32x4(ab[0], ab[1], ab[2] + length, 1.0);
        const v2 = zmath.f32x4(ab[0] + width, ab[1], ab[2] + length, 1.0);
        const v3 = zmath.f32x4(ab[0] + width, ab[1], ab[2], 1.0);
        const v4 = zmath.f32x4(ab[3] - width, ab[4], ab[5] - length, 1.0);
        const v5 = zmath.f32x4(ab[3] - width, ab[4], ab[5], 1.0);
        const v6 = zmath.f32x4(ab[3], ab[4], ab[5], 1.0);
        const v7 = zmath.f32x4(ab[3], ab[4], ab[5] - length, 1.0);
        const obb1 = zmath.mul(zmath.Mat{
            v0, v1, v2, v3,
        }, mvp);
        const obb2 = zmath.mul(zmath.Mat{
            v4, v5, v6, v7,
        }, mvp);

        // Ignore object outside of viewing space
        if (internal.isOBBOutside(&[_]zmath.Vec{
            obb1[0], obb1[1], obb1[2], obb1[3],
            obb2[0], obb2[1], obb2[2], obb2[3],
        })) return;
    }

    // Some early testing and W-pannel clipping
    const ensure_size = indices.len * 2;
    self.clear();
    try self.clip_vertices.ensureTotalCapacityPrecise(ensure_size);
    try self.clip_colors.ensureTotalCapacityPrecise(ensure_size);
    try self.clip_texcoords.ensureTotalCapacityPrecise(ensure_size);
    try self.world_positions.ensureTotalCapacityPrecise(ensure_size);
    try self.world_normals.ensureTotalCapacityPrecise(ensure_size);
    const normal_transform = zmath.transpose(zmath.inverse(model));
    var i: usize = 2;
    while (i < indices.len) : (i += 3) {
        const idx0 = indices[i - 2];
        const idx1 = indices[i - 1];
        const idx2 = indices[i];
        const v0 = zmath.f32x4(positions[idx0][0], positions[idx0][1], positions[idx0][2], 1.0);
        const v1 = zmath.f32x4(positions[idx1][0], positions[idx1][1], positions[idx1][2], 1.0);
        const v2 = zmath.f32x4(positions[idx2][0], positions[idx2][1], positions[idx2][2], 1.0);

        // Transform vertices to world space, calculate skin matrix by the way
        var skin_mat_v0 = zmath.identity();
        var skin_mat_v1 = zmath.identity();
        var skin_mat_v2 = zmath.identity();
        var world_v0: zmath.Vec = undefined;
        var world_v1: zmath.Vec = undefined;
        var world_v2: zmath.Vec = undefined;
        if (opt.animation) |a| {
            skin_mat_v0 = a.anim.getSkinMatrix(a.skin, a.joints[idx0], a.weights[idx0], model);
            skin_mat_v1 = a.anim.getSkinMatrix(a.skin, a.joints[idx1], a.weights[idx1], model);
            skin_mat_v2 = a.anim.getSkinMatrix(a.skin, a.joints[idx2], a.weights[idx2], model);
            world_v0 = zmath.mul(v0, skin_mat_v0);
            world_v1 = zmath.mul(v1, skin_mat_v1);
            world_v2 = zmath.mul(v2, skin_mat_v2);
        } else {
            world_v0 = zmath.mul(v0, model);
            world_v1 = zmath.mul(v1, model);
            world_v2 = zmath.mul(v2, model);
        }

        // Ignore triangles facing away from camera (front faces' vertices are clock-wise organized)
        if (opt.cull_faces) {
            const face_dir = switch (opt.front_face) {
                .cw => zmath.cross3(world_v1 - world_v0, world_v2 - world_v0),
                .ccw => zmath.cross3(world_v2 - world_v0, world_v1 - world_v0),
            };
            const camera_dir = (world_v0 + world_v1 + world_v2) / zmath.splat(zmath.Vec, 3.0) - camera.position;
            if (zmath.dot3(face_dir, camera_dir)[0] >= 0) continue;
        }

        // Ignore triangles outside ndc
        var clip_v0: zmath.Vec = undefined;
        var clip_v1: zmath.Vec = undefined;
        var clip_v2: zmath.Vec = undefined;
        if (opt.animation != null) {
            const mvp_v0 = zmath.mul(skin_mat_v0, vp);
            const mvp_v1 = zmath.mul(skin_mat_v1, vp);
            const mvp_v2 = zmath.mul(skin_mat_v2, vp);
            clip_v0 = zmath.mul(v0, mvp_v0);
            clip_v1 = zmath.mul(v1, mvp_v1);
            clip_v2 = zmath.mul(v2, mvp_v2);
        } else {
            const clip_positions = zmath.mul(zmath.Mat{ v0, v1, v2, zmath.f32x4s(0.0) }, mvp);
            clip_v0 = clip_positions[0];
            clip_v1 = clip_positions[1];
            clip_v2 = clip_positions[2];
        }
        const ndc0 = clip_v0 / zmath.splat(zmath.Vec, clip_v0[3]);
        const ndc1 = clip_v1 / zmath.splat(zmath.Vec, clip_v1[3]);
        const ndc2 = clip_v2 / zmath.splat(zmath.Vec, clip_v2[3]);
        if (internal.isTriangleOutside(ndc0, ndc1, ndc2)) {
            continue;
        }

        // Clip triangles behind camera
        const tri_world_normals: ?[3]zmath.Vec = if (normals) |ns| BLK: {
            const n0 = zmath.f32x4(ns[idx0][0], ns[idx0][1], ns[idx0][2], 0);
            const n1 = zmath.f32x4(ns[idx1][0], ns[idx1][1], ns[idx1][2], 0);
            const n2 = zmath.f32x4(ns[idx2][0], ns[idx2][1], ns[idx2][2], 0);
            var world_n0: zmath.Vec = undefined;
            var world_n1: zmath.Vec = undefined;
            var world_n2: zmath.Vec = undefined;
            if (opt.animation == null) {
                const vs = zmath.mul(zmath.Mat{
                    n0, n1, n2, zmath.f32x4s(0),
                }, normal_transform);
                world_n0 = vs[0];
                world_n1 = vs[1];
                world_n2 = vs[2];
            } else {
                world_n0 = zmath.mul(n0, zmath.transpose(zmath.inverse(skin_mat_v0)));
                world_n1 = zmath.mul(n1, zmath.transpose(zmath.inverse(skin_mat_v1)));
                world_n2 = zmath.mul(n2, zmath.transpose(zmath.inverse(skin_mat_v2)));
            }
            world_n0[3] = 0;
            world_n1[3] = 0;
            world_n2[3] = 0;
            break :BLK .{
                zmath.normalize3(world_n0),
                zmath.normalize3(world_n1),
                zmath.normalize3(world_n2),
            };
        } else null;
        const tri_colors: ?[3]sdl.Color = if (colors) |cs|
            [3]sdl.Color{ cs[idx0], cs[idx1], cs[idx2] }
        else
            null;
        const tri_texcoords: ?[3]sdl.PointF = if (texcoords) |ts|
            [3]sdl.PointF{
                .{ .x = ts[idx0][0], .y = ts[idx0][1] },
                .{ .x = ts[idx1][0], .y = ts[idx1][1] },
                .{ .x = ts[idx2][0], .y = ts[idx2][1] },
            }
        else
            null;
        internal.clipTriangle(
            &.{ world_v0, world_v1, world_v2 },
            &.{ clip_v0, clip_v1, clip_v2 },
            tri_world_normals,
            tri_colors,
            tri_texcoords,
            &self.clip_vertices,
            &self.clip_colors,
            &self.clip_texcoords,
            &self.world_positions,
            &self.world_normals,
        );
    }
    if (self.clip_vertices.items.len == 0) return;
    assert(@rem(self.clip_vertices.items.len, 3) == 0);

    // Continue with remaining triangles
    i = 2;
    while (i < self.clip_vertices.items.len) : (i += 3) {
        const idx0 = i - 2;
        const idx1 = i - 1;
        const idx2 = i;
        const clip_v0 = self.clip_vertices.items[idx0];
        const clip_v1 = self.clip_vertices.items[idx1];
        const clip_v2 = self.clip_vertices.items[idx2];
        const world_v0 = self.world_positions.items[idx0];
        const world_v1 = self.world_positions.items[idx1];
        const world_v2 = self.world_positions.items[idx2];
        const ndc0 = clip_v0 / zmath.splat(zmath.Vec, clip_v0[3]);
        const ndc1 = clip_v1 / zmath.splat(zmath.Vec, clip_v1[3]);
        const ndc2 = clip_v2 / zmath.splat(zmath.Vec, clip_v2[3]);

        // Calculate screen coordinate
        const ndcs = zmath.Mat{
            ndc0,
            ndc1,
            ndc2,
            zmath.f32x4(0.0, 0.0, 0.0, 1.0),
        };
        const positions_screen = zmath.mul(ndcs, ndc_to_screen);
        const p0 = sdl.PointF{ .x = positions_screen[0][0], .y = positions_screen[0][1] };
        const p1 = sdl.PointF{ .x = positions_screen[1][0], .y = positions_screen[1][1] };
        const p2 = sdl.PointF{ .x = positions_screen[2][0], .y = positions_screen[2][1] };

        // Get depths
        const d0 = positions_screen[0][2];
        const d1 = positions_screen[1][2];
        const d2 = positions_screen[2][2];

        // Get color of vertices
        var c0: sdl.Color = undefined;
        var c1: sdl.Color = undefined;
        var c2: sdl.Color = undefined;
        switch (opt.shading_method) {
            .gouraud => {
                const c0_diffuse = if (colors) |_| self.clip_colors.items[idx0] else opt.color;
                const c1_diffuse = if (colors) |_| self.clip_colors.items[idx1] else opt.color;
                const c2_diffuse = if (colors) |_| self.clip_colors.items[idx2] else opt.color;
                c0 = if (normals != null and opt.lighting != null) BLK: {
                    const n0 = self.world_normals.items[idx0];
                    const p = opt.lighting.?;
                    const calc = if (p.light_calc_fn) |f| f else &lighting.calcLightColor;
                    break :BLK calc(c0_diffuse, camera.position, world_v0, n0, p);
                } else c0_diffuse;
                c1 = if (normals != null and opt.lighting != null) BLK: {
                    const n1 = self.world_normals.items[idx1];
                    const p = opt.lighting.?;
                    const calc = if (p.light_calc_fn) |f| f else &lighting.calcLightColor;
                    break :BLK calc(c1_diffuse, camera.position, world_v1, n1, p);
                } else c1_diffuse;
                c2 = if (normals != null and opt.lighting != null) BLK: {
                    const n2 = self.world_normals.items[idx2];
                    const p = opt.lighting.?;
                    const calc = if (p.light_calc_fn) |f| f else &lighting.calcLightColor;
                    break :BLK calc(c2_diffuse, camera.position, world_v2, n2, p);
                } else c2_diffuse;
            },
            .flat => {
                const c0_diffuse = if (colors) |_| sdl.Color{
                    .r = (self.clip_colors.items[idx0].r + self.clip_colors.items[idx1].r + self.clip_colors.items[idx2].r) / 3,
                    .g = (self.clip_colors.items[idx0].g + self.clip_colors.items[idx1].g + self.clip_colors.items[idx2].g) / 3,
                    .b = (self.clip_colors.items[idx0].b + self.clip_colors.items[idx1].b + self.clip_colors.items[idx2].b) / 3,
                    .a = (self.clip_colors.items[idx0].a + self.clip_colors.items[idx1].a + self.clip_colors.items[idx2].a) / 3,
                } else opt.color;
                c0 = if (opt.lighting) |lt| BLK: {
                    var center = (world_v0 + world_v1 + world_v2) / zmath.f32x4s(3);
                    center[3] = 1.0;
                    var normal = zmath.normalize3(switch (opt.front_face) {
                        .cw => zmath.cross3(world_v1 - world_v0, world_v2 - world_v0),
                        .ccw => zmath.cross3(world_v2 - world_v0, world_v1 - world_v0),
                    });
                    normal[3] = 0;
                    const calc = if (lt.light_calc_fn) |f| f else &lighting.calcLightColor;
                    break :BLK calc(c0_diffuse, camera.position, center, normal, lt);
                } else c0_diffuse;
                c1 = c0;
                c2 = c0;
            },
        }

        // Get texture coordinates
        const t0 = if (texcoords) |_| self.clip_texcoords.items[idx0] else undefined;
        const t1 = if (texcoords) |_| self.clip_texcoords.items[idx1] else undefined;
        const t2 = if (texcoords) |_| self.clip_texcoords.items[idx2] else undefined;

        // Render to ouput
        try target.pushTriangles(
            &.{ 0, 1, 2 },
            &[_]sdl.Vertex{
                .{ .position = p0, .color = c0, .tex_coord = t0 },
                .{ .position = p1, .color = c1, .tex_coord = t1 },
                .{ .position = p2, .color = c2, .tex_coord = t2 },
            },
            &.{ d0, d1, d2 },
            opt.texture,
        );
    }
}

pub fn renderSprite(
    self: *Self,
    csz: sdl.PointF,
    target: *internal.RenderTarget,
    model: zmath.Mat,
    camera: Camera,
    size: sdl.PointF,
    uv: [2]sdl.PointF,
    opt: RenderSpriteOption,
) !void {
    assert(size.x > 0 and size.y > 0);
    assert(opt.scale.x >= 0 and opt.scale.y >= 0);
    assert(opt.anchor_point.x >= 0 and opt.anchor_point.x <= 1);
    assert(opt.anchor_point.y >= 0 and opt.anchor_point.y <= 1);

    // Only consider translation
    const translation = zmath.translationV(zmath.util.getTranslationVec(model));

    // Swap texture coordinates
    var uv0 = uv[0];
    var uv1 = uv[1];
    if (opt.flip_h) std.mem.swap(f32, &uv0.x, &uv1.x);
    if (opt.flip_v) std.mem.swap(f32, &uv0.y, &uv1.y);

    // Transform coordinate and render to ouput
    if (opt.facing_dir) |dir| {
        // Create suitable model matrix
        const forward_dir = zmath.f32x4(0.0, 0.0, 1.0, 0.0);
        const facing_normal = zmath.normalize3(zmath.f32x4(dir[0], dir[1], dir[2], 0.0));
        const facing_xz_normal = zmath.normalize3(zmath.f32x4(dir[0], 0, dir[2], 0.0));
        const pitch = -math.acos(zmath.clamp(zmath.dot3(facing_normal, facing_xz_normal)[0], -1.0, 1.0));
        const yaw = if (dir[0] > 0.0)
            math.acos(zmath.clamp(zmath.dot3(facing_xz_normal, forward_dir)[0], -1.0, 1.0))
        else
            -math.acos(zmath.clamp(zmath.dot3(facing_xz_normal, forward_dir)[0], -1.0, 1.0));
        const m_rotate1 = zmath.mul(zmath.rotationX(math.pi), zmath.rotationY(math.pi));
        const m_translate = zmath.translation(opt.anchor_point.x, opt.anchor_point.y, 0.0);
        const m_scale = zmath.scaling(size.x * opt.scale.x, size.y * opt.scale.y, 1.0);
        const m_rotate2 = zmath.mul(
            zmath.rotationZ(jok.utils.math.degreeToRadian(opt.rotate_degree)),
            zmath.mul(zmath.rotationX(pitch), zmath.rotationY(yaw)),
        );
        const transform = zmath.mul(zmath.mul(
            zmath.mul(m_rotate1, m_translate),
            zmath.mul(m_scale, m_rotate2),
        ), translation);

        // Compute texture coordinates and render the plane
        assert(opt.tessellation_level < 10);
        const shape = self.planes[opt.tessellation_level];
        const row_count = opt.tessellation_level + 2;
        assert(shape.texcoords.?.len == row_count * row_count);
        const tex_coord_step_x = (uv1.x - uv0.x) / @as(f32, @floatFromInt(opt.tessellation_level + 1));
        const tex_coord_step_y = (uv1.y - uv0.y) / @as(f32, @floatFromInt(opt.tessellation_level + 1));
        for (0..row_count) |x| {
            const tx = uv0.x + tex_coord_step_x * @as(f32, @floatFromInt(x));
            for (0..row_count) |y| {
                shape.texcoords.?[x * row_count + y] =
                    .{ tx, uv0.y + tex_coord_step_y * @as(f32, @floatFromInt(y)) };
            }
        }
        try self.renderMesh(
            csz,
            target,
            transform,
            camera,
            shape.indices,
            shape.positions,
            shape.normals.?,
            null,
            shape.texcoords,
            .{
                .cull_faces = false,
                .color = opt.tint_color,
                .shading_method = opt.shading_method,
                .texture = opt.texture,
                .lighting = opt.lighting,
            },
        );
    } else {
        const basic_coords = zmath.loadMat(&[_]f32{
            -opt.anchor_point.x, opt.anchor_point.y, 0, 1, // Left top
            -opt.anchor_point.x, opt.anchor_point.y - 1, 0, 1, // Left bottom
            1 - opt.anchor_point.x, opt.anchor_point.y - 1, 0, 1, // Right bottom
            1 - opt.anchor_point.x, opt.anchor_point.y, 0, 1, // Right top
        });
        const t0 = uv0;
        const t1 = sdl.PointF{ .x = uv0.x, .y = uv1.y };
        const t2 = uv1;
        const t3 = sdl.PointF{ .x = uv1.x, .y = uv0.y };
        var ndc0: zmath.Vec = undefined;
        var ndc1: zmath.Vec = undefined;
        var ndc2: zmath.Vec = undefined;
        var ndc3: zmath.Vec = undefined;
        if (opt.fixed_size) {
            const mvp = zmath.mul(translation, camera.getViewProjectMatrix());
            const pos_in_clip_space = zmath.mul(zmath.f32x4(0, 0, 0, 1), mvp);
            const ndc_center = pos_in_clip_space / zmath.splat(zmath.Vec, pos_in_clip_space[3]);
            if (ndc_center[2] <= -1 or ndc_center[2] >= 1) {
                return;
            }
            const size_x = size.x / csz.x * 2;
            const size_y = size.y / csz.y * 2;
            const m_scale = zmath.scaling(size_x * opt.scale.x, size_y * opt.scale.y, 1);
            const m_rotate = zmath.rotationZ(jok.utils.math.degreeToRadian(-opt.rotate_degree));
            const m_translate = zmath.translation(ndc_center[0], ndc_center[1], 0);
            const m_transform = zmath.mul(zmath.mul(m_scale, m_rotate), m_translate);
            const ndc_coords = zmath.mul(basic_coords, m_transform);
            ndc0 = ndc_coords[0];
            ndc1 = ndc_coords[1];
            ndc2 = ndc_coords[2];
            ndc3 = ndc_coords[3];
            ndc0[2] = ndc_center[2];
            ndc1[2] = ndc_center[2];
            ndc2[2] = ndc_center[2];
            ndc3[2] = ndc_center[2];
        } else {
            // Convert position to camera space and test visibility
            const mv = zmath.mul(translation, camera.getViewMatrix());
            const view_range = camera.getViewRange();
            const pos_in_camera_space = zmath.mul(zmath.f32x4(0, 0, 0, 1), mv);
            if (pos_in_camera_space[2] <= view_range[0] or
                pos_in_camera_space[2] >= view_range[1])
            {
                return;
            }

            const m_scale = zmath.scaling(size.x * opt.scale.x, size.y * opt.scale.y, 1);
            const m_rotate = zmath.rotationZ(jok.utils.math.degreeToRadian(-opt.rotate_degree));
            const m_translate = zmath.translation(
                pos_in_camera_space[0],
                pos_in_camera_space[1],
                pos_in_camera_space[2],
            );
            const m_transform = zmath.mul(
                zmath.mul(zmath.mul(m_scale, m_rotate), m_translate),
                camera.getProjectMatrix(),
            );
            const clip_coords = zmath.mul(basic_coords, m_transform);
            ndc0 = clip_coords[0] / zmath.splat(zmath.Vec, clip_coords[0][3]);
            ndc1 = clip_coords[1] / zmath.splat(zmath.Vec, clip_coords[1][3]);
            ndc2 = clip_coords[2] / zmath.splat(zmath.Vec, clip_coords[2][3]);
            ndc3 = clip_coords[3] / zmath.splat(zmath.Vec, clip_coords[3][3]);
        }

        // Test visibility
        var min_x: f32 = math.floatMax(f32);
        var min_y: f32 = math.floatMax(f32);
        var max_x: f32 = math.floatMin(f32);
        var max_y: f32 = math.floatMin(f32);
        for ([_]zmath.Vec{ ndc0, ndc1, ndc2, ndc3 }) |p| {
            if (min_x > p[0]) min_x = p[0];
            if (min_y > p[1]) min_y = p[1];
            if (max_x < p[0]) max_x = p[0];
            if (max_y < p[1]) max_y = p[1];
        }
        if (min_x > 1 or max_x < -1 or min_y > 1 or max_y < -1) {
            return;
        }

        // Calculate screen coordinate
        const ndc_to_screen = zmath.loadMat43(&[_]f32{
            0.5 * csz.x, 0.0,          0.0,
            0.0,         -0.5 * csz.y, 0.0,
            0.0,         0.0,          0.5,
            0.5 * csz.x, 0.5 * csz.y,  0.5,
        });
        const ndcs = zmath.Mat{
            ndc0,
            ndc1,
            ndc2,
            ndc3,
        };
        const positions_screen = zmath.mul(ndcs, ndc_to_screen);

        // Get screen coordinate
        const p0 = sdl.PointF{ .x = positions_screen[0][0], .y = positions_screen[0][1] };
        const p1 = sdl.PointF{ .x = positions_screen[1][0], .y = positions_screen[1][1] };
        const p2 = sdl.PointF{ .x = positions_screen[2][0], .y = positions_screen[2][1] };
        const p3 = sdl.PointF{ .x = positions_screen[3][0], .y = positions_screen[3][1] };

        // Get depths
        const d0 = positions_screen[0][2];
        const d1 = positions_screen[1][2];
        const d2 = positions_screen[2][2];
        const d3 = positions_screen[3][2];

        // Render to ouput
        try target.pushTriangles(
            &.{ 0, 1, 2, 0, 2, 3 },
            &[_]sdl.Vertex{
                .{ .position = p0, .color = opt.tint_color, .tex_coord = t0 },
                .{ .position = p1, .color = opt.tint_color, .tex_coord = t1 },
                .{ .position = p2, .color = opt.tint_color, .tex_coord = t2 },
                .{ .position = p3, .color = opt.tint_color, .tex_coord = t3 },
            },
            &.{ d0, d1, d2, d3 },
            opt.texture,
        );
    }
}
