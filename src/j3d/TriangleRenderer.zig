/// 3d triangle renderer
const std = @import("std");
const assert = std.debug.assert;
const math = std.math;
const sdl = @import("sdl");
const jok = @import("../jok.zig");
const zmath = jok.zmath;
const zmesh = jok.zmesh;
const j3d = jok.j3d;
const lighting = j3d.lighting;
const Camera = j3d.Camera;
const utils = jok.utils;
const internal = @import("internal.zig");
const Self = @This();

pub const MeshOption = struct {
    aabb: ?[6]f32 = null,
    cull_faces: bool = true,
    color: sdl.Color = sdl.Color.white,
    texture: ?sdl.Texture = null,
    lighting_opt: ?lighting.LightingOption = null,
};

pub const SpriteOption = struct {
    /// Binded texture
    texture: ?sdl.Texture = null,

    /// Tint color
    tint_color: sdl.Color = sdl.Color.white,

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
    lighting_opt: ?lighting.LightingOption = null,

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
    for (self.planes) |*p, i| {
        p.* = zmesh.Shape.initPlane(
            @intCast(i32, i + 1),
            @intCast(i32, i + 1),
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
    for (self.planes) |*p| {
        p.deinit();
    }
    self.* = undefined;
}

pub fn renderMesh(
    self: *Self,
    vp: sdl.Rectangle,
    target: *internal.RenderTarget,
    model: zmath.Mat,
    camera: Camera,
    indices: []const u16,
    positions: []const [3]f32,
    normals: []const [3]f32,
    colors: ?[]const sdl.Color,
    texcoords: ?[]const [2]f32,
    opt: MeshOption,
) !void {
    assert(@rem(indices.len, 3) == 0);
    assert(normals.len == positions.len);
    assert(if (colors) |cs| cs.len == positions.len else true);
    assert(if (texcoords) |ts| ts.len == positions.len else true);
    if (indices.len == 0) return;

    // Do face-culling and W-pannel clipping
    self.clip_vertices.clearRetainingCapacity();
    self.clip_colors.clearRetainingCapacity();
    self.clip_texcoords.clearRetainingCapacity();
    self.world_positions.clearRetainingCapacity();
    self.world_normals.clearRetainingCapacity();
    const ensure_size = indices.len * 2;
    try self.clip_vertices.ensureTotalCapacityPrecise(ensure_size);
    try self.clip_colors.ensureTotalCapacityPrecise(ensure_size);
    try self.clip_texcoords.ensureTotalCapacityPrecise(ensure_size);
    try self.world_positions.ensureTotalCapacityPrecise(ensure_size);
    try self.world_normals.ensureTotalCapacityPrecise(ensure_size);
    const mvp = zmath.mul(model, camera.getViewProjectMatrix());
    const normal_transform = zmath.transpose(zmath.inverse(model));
    var i: usize = 2;
    while (i < indices.len) : (i += 3) {
        const idx0 = indices[i - 2];
        const idx1 = indices[i - 1];
        const idx2 = indices[i];
        const v0 = zmath.f32x4(positions[idx0][0], positions[idx0][1], positions[idx0][2], 1.0);
        const v1 = zmath.f32x4(positions[idx1][0], positions[idx1][1], positions[idx1][2], 1.0);
        const v2 = zmath.f32x4(positions[idx2][0], positions[idx2][1], positions[idx2][2], 1.0);
        const n0 = zmath.f32x4(normals[idx0][0], normals[idx0][1], normals[idx0][2], 0);
        const n1 = zmath.f32x4(normals[idx1][0], normals[idx1][1], normals[idx1][2], 0);
        const n2 = zmath.f32x4(normals[idx2][0], normals[idx2][1], normals[idx2][2], 0);

        // Ignore triangles facing away from camera (front faces' vertices are clock-wise organized)
        if (opt.cull_faces) {
            const world_positions = zmath.mul(zmath.Mat{
                v0,
                v1,
                v2,
                zmath.f32x4(0.0, 0.0, 0.0, 1.0),
            }, model);
            const face_dir = zmath.cross3(world_positions[1] - world_positions[0], world_positions[2] - world_positions[0]);
            const camera_dir = (world_positions[0] + world_positions[1] + world_positions[2]) /
                zmath.splat(zmath.Vec, 3.0) - camera.position;
            if (zmath.dot3(face_dir, camera_dir)[0] >= 0) continue;
        }

        // Clip triangles behind camera
        const tri_world_positions = zmath.mul(zmath.Mat{
            v0,
            v1,
            v2,
            zmath.f32x4(0.0, 0.0, 0.0, 1.0),
        }, model);
        var tri_world_normals = zmath.mul(zmath.Mat{
            n0,
            n1,
            n2,
            zmath.f32x4s(0),
        }, normal_transform);
        tri_world_normals[0] = zmath.normalize3(tri_world_normals[0]);
        tri_world_normals[1] = zmath.normalize3(tri_world_normals[1]);
        tri_world_normals[2] = zmath.normalize3(tri_world_normals[2]);
        tri_world_normals[0][3] = 0;
        tri_world_normals[1][3] = 0;
        tri_world_normals[2][3] = 0;
        const tri_clip_positions = zmath.mul(zmath.Mat{
            v0,
            v1,
            v2,
            zmath.f32x4(0.0, 0.0, 0.0, 1.0),
        }, mvp);
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
            tri_world_positions[0..3],
            tri_world_normals[0..3],
            tri_clip_positions[0..3],
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
    const ndc_to_screen = zmath.loadMat43(&[_]f32{
        0.5 * @intToFloat(f32, vp.width), 0.0,                                0.0,
        0.0,                              -0.5 * @intToFloat(f32, vp.height), 0.0,
        0.0,                              0.0,                                0.5,
        0.5 * @intToFloat(f32, vp.width), 0.5 * @intToFloat(f32, vp.height),  0.5,
    });
    try target.reserveCapacity(
        self.clip_vertices.items.len,
        self.clip_vertices.items.len,
    );
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
        const n0 = self.world_normals.items[idx0];
        const n1 = self.world_normals.items[idx1];
        const n2 = self.world_normals.items[idx2];
        const ndc0 = clip_v0 / zmath.splat(zmath.Vec, clip_v0[3]);
        const ndc1 = clip_v1 / zmath.splat(zmath.Vec, clip_v1[3]);
        const ndc2 = clip_v2 / zmath.splat(zmath.Vec, clip_v2[3]);

        // Ignore triangles outside of NDC
        if (internal.isTriangleOutside(ndc0, ndc1, ndc2)) {
            continue;
        }

        // Calculate screen coordinate
        const ndcs = zmath.Mat{
            ndc0,
            ndc1,
            ndc2,
            zmath.f32x4(0.0, 0.0, 0.0, 1.0),
        };
        const positions_screen = zmath.mul(ndcs, ndc_to_screen);

        // Get screen coordinate
        const p0 = sdl.PointF{ .x = positions_screen[0][0], .y = positions_screen[0][1] };
        const p1 = sdl.PointF{ .x = positions_screen[1][0], .y = positions_screen[1][1] };
        const p2 = sdl.PointF{ .x = positions_screen[2][0], .y = positions_screen[2][1] };

        // Get depths
        const d0 = positions_screen[0][2];
        const d1 = positions_screen[1][2];
        const d2 = positions_screen[2][2];

        // Get color of vertices
        const c0_diffuse = if (colors) |_| self.clip_colors.items[idx0] else opt.color;
        const c1_diffuse = if (colors) |_| self.clip_colors.items[idx1] else opt.color;
        const c2_diffuse = if (colors) |_| self.clip_colors.items[idx2] else opt.color;
        const c0 = if (opt.lighting_opt) |p| BLK: {
            var calc = if (p.light_calc_fn) |f| f else &lighting.calcLightColor;
            break :BLK calc(c0_diffuse, camera.position, world_v0, n0, p);
        } else c0_diffuse;
        const c1 = if (opt.lighting_opt) |p| BLK: {
            var calc = if (p.light_calc_fn) |f| f else &lighting.calcLightColor;
            break :BLK calc(c1_diffuse, camera.position, world_v1, n1, p);
        } else c1_diffuse;
        const c2 = if (opt.lighting_opt) |p| BLK: {
            var calc = if (p.light_calc_fn) |f| f else &lighting.calcLightColor;
            break :BLK calc(c2_diffuse, camera.position, world_v2, n2, p);
        } else c2_diffuse;

        // Get texture coordinates
        const t0 = if (texcoords) |_| self.clip_texcoords.items[idx0] else undefined;
        const t1 = if (texcoords) |_| self.clip_texcoords.items[idx1] else undefined;
        const t2 = if (texcoords) |_| self.clip_texcoords.items[idx2] else undefined;

        // Render to ouput
        try target.appendTrianglesAssumeCapacity(
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
    vp: sdl.Rectangle,
    target: *internal.RenderTarget,
    _model: zmath.Mat,
    camera: Camera,
    size: sdl.PointF,
    uv: [2]sdl.PointF,
    opt: SpriteOption,
) !void {
    assert(size.x > 0 and size.y > 0);
    assert(opt.scale.x >= 0 and opt.scale.y >= 0);
    assert(opt.anchor_point.x >= 0 and opt.anchor_point.x <= 1);
    assert(opt.anchor_point.y >= 0 and opt.anchor_point.y <= 1);

    // Only consider translation
    const translation = zmath.translationV(zmath.util.getTranslationVec(_model));

    // Swap texture coordinates
    var uv0 = uv[0];
    var uv1 = uv[1];
    if (opt.flip_h) std.mem.swap(f32, &uv0.x, &uv1.x);
    if (opt.flip_v) std.mem.swap(f32, &uv0.y, &uv1.y);

    // Transform coordinate and render to ouput
    if (opt.facing_dir) |dir| {
        // Create suitable model matrix
        const forward_dir = zmath.f32x4(0, 0, 1, 0);
        const facing_normal = zmath.normalize3(zmath.f32x4(dir[0], dir[1], dir[2], 0));
        const facing_xz_normal = zmath.normalize3(zmath.f32x4(dir[0], 0, dir[2], 0));
        const pitch = -math.acos(zmath.clamp(zmath.dot3(facing_normal, facing_xz_normal)[0], -1, 1));
        const yaw = if (dir[0] > 0)
            math.cos(zmath.clamp(zmath.dot3(facing_xz_normal, forward_dir)[0], -1, 1))
        else
            -math.cos(zmath.clamp(zmath.dot3(facing_xz_normal, forward_dir)[0], -1, 1));
        const m_rotate1 = zmath.mul(zmath.rotationX(math.pi), zmath.rotationY(math.pi));
        const m_translate = zmath.translation(-opt.anchor_point.x, opt.anchor_point.y, 0);
        const m_scale = zmath.scaling(size.x * opt.scale.x, size.y * opt.scale.y, 1);
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
        const tex_coord_step_x = (uv1.x - uv0.x) / @intToFloat(f32, opt.tessellation_level + 1);
        const tex_coord_step_y = (uv1.y - uv0.y) / @intToFloat(f32, opt.tessellation_level + 1);
        var x: u32 = 0;
        while (x < row_count) : (x += 1) {
            const tx = uv0.x + tex_coord_step_x * @intToFloat(f32, x);
            var y: u32 = 0;
            while (y < row_count) : (y += 1) {
                shape.texcoords.?[x * row_count + y] =
                    .{ tx, uv0.y + tex_coord_step_y * @intToFloat(f32, y) };
            }
        }
        try self.renderMesh(
            vp,
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
                .texture = opt.texture,
                .lighting_opt = opt.lighting_opt,
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
            const size_x = size.x / @intToFloat(f32, vp.width) * 2;
            const size_y = size.y / @intToFloat(f32, vp.height) * 2;
            const m_scale = zmath.scaling(size_x * opt.scale.x, size_y * opt.scale.y, 1);
            const m_rotate = zmath.rotationZ(jok.utils.math.degreeToRadian(opt.rotate_degree));
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
            const m_rotate = zmath.rotationZ(jok.utils.math.degreeToRadian(opt.rotate_degree));
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
        var min_x: f32 = math.f32_max;
        var min_y: f32 = math.f32_max;
        var max_x: f32 = math.f32_min;
        var max_y: f32 = math.f32_min;
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
            0.5 * @intToFloat(f32, vp.width), 0.0,                                0.0,
            0.0,                              -0.5 * @intToFloat(f32, vp.height), 0.0,
            0.0,                              0.0,                                0.5,
            0.5 * @intToFloat(f32, vp.width), 0.5 * @intToFloat(f32, vp.height),  0.5,
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
        try target.reserveCapacity(6, 4);
        try target.appendTrianglesAssumeCapacity(
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

/// Test whether all obb's triangles are hidden behind current front triangles
pub inline fn isOBBHiddenBehind(self: *Self, obb: []zmath.Vec) bool {
    const S = struct {
        /// Test whether a triangle is hidden behind another
        inline fn isTriangleHiddenBehind(
            front_tri: [3][2]f32,
            front_depth: f32,
            _obb: []zmath.Vec,
            indices: [3]u32,
        ) bool {
            const tri = [3][2]f32{
                .{ _obb[indices[0]][0], _obb[indices[0]][1] },
                .{ _obb[indices[1]][0], _obb[indices[1]][1] },
                .{ _obb[indices[2]][0], _obb[indices[2]][1] },
            };
            const tri_depth = (_obb[indices[0]][2] + _obb[indices[1]][2] + _obb[indices[2]][2]) / 3.0;
            return tri_depth > front_depth and
                utils.math.isPointInTriangle(front_tri, tri[0]) and
                utils.math.isPointInTriangle(front_tri, tri[1]) and
                utils.math.isPointInTriangle(front_tri, tri[2]);
        }
    };

    assert(obb.len == 8);
    var obb_visible_flags: u12 = std.math.maxInt(u12);
    for (self.large_front_triangles.items) |tri| {
        const front_tri = [3][2]f32{
            .{ self.vertices.items[tri[0]].position.x, self.vertices.items[tri[0]].position.y },
            .{ self.vertices.items[tri[1]].position.x, self.vertices.items[tri[1]].position.y },
            .{ self.vertices.items[tri[2]].position.x, self.vertices.items[tri[2]].position.y },
        };
        const front_depth = (self.depths.items[tri[0]] + self.depths.items[tri[1]] + self.depths.items[tri[2]]) / 3.0;

        if ((obb_visible_flags & 0x1) != 0) {
            if (S.isTriangleHiddenBehind(front_tri, front_depth, obb, .{ 0, 1, 2 }))
                obb_visible_flags &= ~@as(u12, 0x1);
        }
        if (obb_visible_flags & 0x2 != 0) {
            if (S.isTriangleHiddenBehind(front_tri, front_depth, obb, .{ 0, 2, 3 }))
                obb_visible_flags &= ~@as(u12, 0x2);
        }
        if (obb_visible_flags & 0x4 != 0) {
            if (S.isTriangleHiddenBehind(front_tri, front_depth, obb, .{ 0, 3, 7 }))
                obb_visible_flags &= ~@as(u12, 0x4);
        }
        if (obb_visible_flags & 0x8 != 0) {
            if (S.isTriangleHiddenBehind(front_tri, front_depth, obb, .{ 0, 7, 4 }))
                obb_visible_flags &= ~@as(u12, 0x8);
        }
        if (obb_visible_flags & 0x10 != 0) {
            if (S.isTriangleHiddenBehind(front_tri, front_depth, obb, .{ 0, 4, 5 }))
                obb_visible_flags &= ~@as(u12, 0x10);
        }
        if (obb_visible_flags & 0x20 != 0) {
            if (S.isTriangleHiddenBehind(front_tri, front_depth, obb, .{ 0, 5, 1 }))
                obb_visible_flags &= ~@as(u12, 0x20);
        }
        if (obb_visible_flags & 0x40 != 0) {
            if (S.isTriangleHiddenBehind(front_tri, front_depth, obb, .{ 6, 7, 3 }))
                obb_visible_flags &= ~@as(u12, 0x40);
        }
        if (obb_visible_flags & 0x80 != 0) {
            if (S.isTriangleHiddenBehind(front_tri, front_depth, obb, .{ 6, 3, 2 }))
                obb_visible_flags &= ~@as(u12, 0x80);
        }
        if (obb_visible_flags & 0x100 != 0) {
            if (S.isTriangleHiddenBehind(front_tri, front_depth, obb, .{ 6, 2, 1 }))
                obb_visible_flags &= ~@as(u12, 0x100);
        }
        if (obb_visible_flags & 0x200 != 0) {
            if (S.isTriangleHiddenBehind(front_tri, front_depth, obb, .{ 6, 1, 5 }))
                obb_visible_flags &= ~@as(u12, 0x200);
        }
        if (obb_visible_flags & 0x400 != 0) {
            if (S.isTriangleHiddenBehind(front_tri, front_depth, obb, .{ 6, 5, 4 }))
                obb_visible_flags &= ~@as(u12, 0x400);
        }
        if (obb_visible_flags & 0x800 != 0) {
            if (S.isTriangleHiddenBehind(front_tri, front_depth, obb, .{ 6, 4, 7 }))
                obb_visible_flags &= ~@as(u12, 0x800);
        }
        if (obb_visible_flags == 0) return true;
    }
    return false;
}
