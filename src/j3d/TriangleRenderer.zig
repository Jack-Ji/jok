const std = @import("std");
const assert = std.debug.assert;
const math = std.math;
const sdl = @import("sdl");
const jok = @import("../jok.zig");
const zmath = jok.zmath;
const j3d = jok.j3d;
const lighting = j3d.lighting;
const Camera = j3d.Camera;
const utils = jok.utils;
const internal = @import("internal.zig");
const Self = @This();

allocator: std.mem.Allocator,

// Triangle vertices
indices: std.ArrayList(u32),
sorted: bool = false,

// Triangle vertices
vertices: std.ArrayList(sdl.Vertex),

// Depth of vertices
depths: std.ArrayList(f32),

// Large triangles directly in front of camera
large_front_triangles: std.ArrayList([3]u32),

// Temporary storage for clipping
clip_vertices: std.ArrayList(zmath.Vec),
clip_colors: std.ArrayList(sdl.Color),
clip_texcoords: std.ArrayList(sdl.PointF),

// Vertices in world space (after clipped)
world_positions: std.ArrayList(zmath.Vec),
world_normals: std.ArrayList(zmath.Vec),

pub fn create(allocator: std.mem.Allocator) !*Self {
    var self = try allocator.create(Self);
    self.* = .{
        .allocator = allocator,
        .indices = std.ArrayList(u32).init(self.allocator),
        .vertices = std.ArrayList(sdl.Vertex).init(self.allocator),
        .depths = std.ArrayList(f32).init(self.allocator),
        .large_front_triangles = std.ArrayList([3]u32).init(self.allocator),
        .clip_vertices = std.ArrayList(zmath.Vec).init(self.allocator),
        .clip_colors = std.ArrayList(sdl.Color).init(self.allocator),
        .clip_texcoords = std.ArrayList(sdl.PointF).init(self.allocator),
        .world_positions = std.ArrayList(zmath.Vec).init(self.allocator),
        .world_normals = std.ArrayList(zmath.Vec).init(self.allocator),
    };
    return self;
}

pub fn destroy(self: *Self) void {
    self.indices.deinit();
    self.vertices.deinit();
    self.depths.deinit();
    self.large_front_triangles.deinit();
    self.clip_vertices.deinit();
    self.clip_colors.deinit();
    self.clip_texcoords.deinit();
    self.world_positions.deinit();
    self.world_normals.deinit();
    self.allocator.destroy(self);
}

/// Clear mesh data
pub fn clear(self: *Self, retain_memory: bool) void {
    if (retain_memory) {
        self.indices.clearRetainingCapacity();
        self.vertices.clearRetainingCapacity();
        self.depths.clearRetainingCapacity();
        self.large_front_triangles.clearRetainingCapacity();
    } else {
        self.indices.clearAndFree();
        self.vertices.clearAndFree();
        self.depths.clearAndFree();
        self.large_front_triangles.clearAndFree();
    }
    self.sorted = false;
}

/// Advanced vertice appending options
pub const RenderOption = struct {
    aabb: ?[6]f32 = null,
    cull_faces: bool = true,
    lighting_opt: ?lighting.LightingOption = null,
};

/// Append shape data
pub fn addShapeData(
    self: *Self,
    renderer: sdl.Renderer,
    model: zmath.Mat,
    camera: Camera,
    indices: []const u16,
    positions: []const [3]f32,
    normals: []const [3]f32,
    colors: ?[]const sdl.Color,
    texcoords: ?[]const [2]f32,
    opt: RenderOption,
) !void {
    assert(@rem(indices.len, 3) == 0);
    assert(normals.len == positions.len);
    assert(if (colors) |cs| cs.len == positions.len else true);
    assert(if (texcoords) |ts| ts.len == positions.len else true);
    if (indices.len == 0) return;
    const vp = renderer.getViewport();
    const ndc_to_screen = zmath.loadMat43(&[_]f32{
        0.5 * @intToFloat(f32, vp.width), 0.0,                                0.0,
        0.0,                              -0.5 * @intToFloat(f32, vp.height), 0.0,
        0.0,                              0.0,                                0.5,
        0.5 * @intToFloat(f32, vp.width), 0.5 * @intToFloat(f32, vp.height),  0.5,
    });
    const front_tri_threshold = @intToFloat(f32, vp.width * vp.height) / 64;
    const mvp = zmath.mul(model, camera.getViewProjectMatrix());

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

        // Ignore object hidden behind front triangles
        const ndc0 = obb1[0] / zmath.splat(zmath.Vec, obb1[0][3]);
        const ndc1 = obb1[1] / zmath.splat(zmath.Vec, obb1[1][3]);
        const ndc2 = obb1[2] / zmath.splat(zmath.Vec, obb1[2][3]);
        const ndc3 = obb1[3] / zmath.splat(zmath.Vec, obb1[3][3]);
        const ndc4 = obb2[0] / zmath.splat(zmath.Vec, obb2[0][3]);
        const ndc5 = obb2[1] / zmath.splat(zmath.Vec, obb2[1][3]);
        const ndc6 = obb2[2] / zmath.splat(zmath.Vec, obb2[2][3]);
        const ndc7 = obb2[3] / zmath.splat(zmath.Vec, obb2[3][3]);
        const positions_screen1 = zmath.mul(zmath.Mat{ ndc0, ndc1, ndc2, ndc3 }, ndc_to_screen);
        const positions_screen2 = zmath.mul(zmath.Mat{ ndc4, ndc5, ndc6, ndc7 }, ndc_to_screen);
        if (self.isOBBHiddenBehind(&[_]zmath.Vec{
            positions_screen1[0],
            positions_screen1[1],
            positions_screen1[2],
            positions_screen1[3],
            positions_screen2[0],
            positions_screen2[1],
            positions_screen2[2],
            positions_screen2[3],
        })) return;
    }

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
    try self.vertices.ensureTotalCapacityPrecise(self.vertices.items.len + self.clip_vertices.items.len);
    try self.depths.ensureTotalCapacityPrecise(self.vertices.items.len + self.clip_vertices.items.len);
    try self.indices.ensureTotalCapacityPrecise(self.vertices.items.len + self.clip_vertices.items.len);
    var current_index: u32 = @intCast(u32, self.vertices.items.len);
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
        const c0_diffuse = if (colors) |_| self.clip_colors.items[idx0] else sdl.Color.white;
        const c1_diffuse = if (colors) |_| self.clip_colors.items[idx1] else sdl.Color.white;
        const c2_diffuse = if (colors) |_| self.clip_colors.items[idx2] else sdl.Color.white;
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

        // Append to ouput buffers
        self.vertices.appendSliceAssumeCapacity(&[_]sdl.Vertex{
            .{ .position = p0, .color = c0, .tex_coord = t0 },
            .{ .position = p1, .color = c1, .tex_coord = t1 },
            .{ .position = p2, .color = c2, .tex_coord = t2 },
        });
        self.depths.appendSliceAssumeCapacity(&[_]f32{ d0, d1, d2 });
        self.indices.appendSliceAssumeCapacity(&[_]u32{ current_index, current_index + 1, current_index + 2 });

        // Update front triangles
        const tri_coords = [3][2]f32{
            .{ positions_screen[0][0], positions_screen[0][1] },
            .{ positions_screen[1][0], positions_screen[1][1] },
            .{ positions_screen[2][0], positions_screen[2][1] },
        };
        const tri_depth = (positions_screen[0][2] + positions_screen[1][2] + positions_screen[2][2]) / 3.0;
        const tri_area = (tri_coords[0][0] * (tri_coords[1][1] - tri_coords[2][1]) +
            tri_coords[1][0] * (tri_coords[2][1] - tri_coords[0][1]) +
            tri_coords[2][0] * (tri_coords[0][1] - tri_coords[1][1])) / 2.0;
        if (tri_area > front_tri_threshold) {
            var idx: u32 = 0;
            while (idx < self.large_front_triangles.items.len) {
                const front_tri = self.large_front_triangles.items[idx];
                const front_tri_coords = [3][2]f32{
                    .{ self.vertices.items[front_tri[0]].position.x, self.vertices.items[front_tri[0]].position.y },
                    .{ self.vertices.items[front_tri[1]].position.x, self.vertices.items[front_tri[1]].position.y },
                    .{ self.vertices.items[front_tri[2]].position.x, self.vertices.items[front_tri[2]].position.y },
                };
                const front_depth = (self.depths.items[front_tri[0]] +
                    self.depths.items[front_tri[1]] + self.depths.items[front_tri[2]]) / 3.0;

                if (tri_depth < front_depth and
                    utils.math.isPointInTriangle(tri_coords, front_tri_coords[0]) and
                    utils.math.isPointInTriangle(tri_coords, front_tri_coords[1]) and
                    utils.math.isPointInTriangle(tri_coords, front_tri_coords[2]))
                {
                    // Remove front triangle since new one is closer and larger
                    _ = self.large_front_triangles.swapRemove(idx);
                    continue;
                } else if (tri_depth > front_depth and
                    utils.math.isPointInTriangle(front_tri_coords, tri_coords[0]) and
                    utils.math.isPointInTriangle(front_tri_coords, tri_coords[1]) and
                    utils.math.isPointInTriangle(front_tri_coords, tri_coords[2]))
                {
                    // The triangle is already covered
                    break;
                }
                idx += 1;
            } else {
                self.large_front_triangles.append(.{
                    current_index,
                    current_index + 1,
                    current_index + 2,
                }) catch unreachable;
            }
        }

        // Step forward index, one triangle a time
        current_index += 3;
    }

    self.sorted = false;
}

/// Sprite's drawing params
pub const SpriteOption = struct {
    /// Mod color
    tint_color: sdl.Color = sdl.Color.white,

    /// Scale of width/height
    scale_w: f32 = 1.0,
    scale_h: f32 = 1.0,

    /// Rotation around anchor-point (center by default)
    rotate_degree: f32 = 0,

    /// Anchor-point of sprite, around which rotation and translation is calculated
    anchor_point: sdl.PointF = .{ .x = 0, .y = 0 },

    /// Horizontal/vertial flipping
    flip_h: bool = false,
    flip_v: bool = false,
};

/// Append sprite data
pub fn addSpriteData(
    self: *Self,
    renderer: sdl.Renderer,
    model: zmath.Mat,
    camera: Camera,
    pos: [3]f32,
    size: sdl.PointF,
    uv: [2]sdl.PointF,
    opt: SpriteOption,
) !void {
    assert(size.x > 0 and size.y > 0);
    assert(opt.scale_w >= 0 and opt.scale_h >= 0);
    assert(opt.anchor_point.x >= 0 and opt.anchor_point.x <= 1);
    assert(opt.anchor_point.y >= 0 and opt.anchor_point.y <= 1);
    const vp = renderer.getViewport();
    const mv = zmath.mul(model, camera.getViewMatrix());
    const view_range = camera.getViewRange();

    var uv0 = uv[0];
    var uv1 = uv[1];
    if (opt.flip_h) std.mem.swap(f32, &uv0.x, &uv1.x);
    if (opt.flip_v) std.mem.swap(f32, &uv0.y, &uv1.y);

    // Convert to camera space
    const pos_in_camera_space = zmath.mul(zmath.f32x4(pos[0], pos[1], pos[2], 1), mv);
    if (pos_in_camera_space[2] <= view_range[0] or pos_in_camera_space[2] >= view_range[1]) {
        return;
    }

    // Get rectangle coordinates and convert it to clip space
    const basic_coords = zmath.loadMat(&[_]f32{
        -opt.anchor_point.x, opt.anchor_point.y, pos_in_camera_space[2], 1, // Left top
        -opt.anchor_point.x, opt.anchor_point.y - 1, pos_in_camera_space[2], 1, // Left bottom
        1 - opt.anchor_point.x, opt.anchor_point.y - 1, pos_in_camera_space[2], 1, // Right bottom
        1 - opt.anchor_point.x, opt.anchor_point.y, pos_in_camera_space[2], 1, // Right top
    });
    const m_scale = zmath.scaling(size.x * opt.scale_w, size.y * opt.scale_h, 1);
    const m_rotate = zmath.rotationZ(jok.utils.math.degreeToRadian(opt.rotate_degree));
    const m_translate = zmath.translation(pos_in_camera_space[0], pos_in_camera_space[1], pos_in_camera_space[2]);
    const m_transform = zmath.mul(
        zmath.mul(zmath.mul(m_scale, m_rotate), m_translate),
        camera.getProjectMatrix(),
    );
    const clip_coords = zmath.mul(basic_coords, m_transform);
    const ndc0 = clip_coords[0] / zmath.splat(zmath.Vec, clip_coords[0][3]);
    const ndc1 = clip_coords[1] / zmath.splat(zmath.Vec, clip_coords[1][3]);
    const ndc2 = clip_coords[2] / zmath.splat(zmath.Vec, clip_coords[2][3]);
    const ndc3 = clip_coords[3] / zmath.splat(zmath.Vec, clip_coords[3][3]);
    if (internal.isTriangleOutside(ndc0, ndc1, ndc2) or internal.isTriangleOutside(ndc0, ndc2, ndc3)) {
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

    // Get texture coordinates
    const t0 = uv0;
    const t1 = sdl.PointF{ .x = uv0.x, .y = uv1.y };
    const t2 = uv1;
    const t3 = sdl.PointF{ .x = uv1.x, .y = uv0.y };

    // Append to ouput buffers
    try self.vertices.ensureTotalCapacityPrecise(self.vertices.items.len + 4);
    try self.depths.ensureTotalCapacityPrecise(self.depths.items.len + 4);
    try self.indices.ensureTotalCapacityPrecise(self.indices.items.len + 6);
    var current_index: u32 = @intCast(u32, self.vertices.items.len);
    self.vertices.appendSliceAssumeCapacity(&[_]sdl.Vertex{
        .{ .position = p0, .color = opt.tint_color, .tex_coord = t0 },
        .{ .position = p1, .color = opt.tint_color, .tex_coord = t1 },
        .{ .position = p2, .color = opt.tint_color, .tex_coord = t2 },
        .{ .position = p3, .color = opt.tint_color, .tex_coord = t3 },
    });
    self.depths.appendSliceAssumeCapacity(&[_]f32{ d0, d1, d2, d3 });
    self.indices.appendSliceAssumeCapacity(&[_]u32{
        current_index, current_index + 1, current_index + 2,
        current_index, current_index + 2, current_index + 3,
    });

    self.sorted = false;
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

/// Sort triangles by depth values
fn compareTriangleDepths(self: *Self, lhs: [3]u32, rhs: [3]u32) bool {
    const d1 = (self.depths.items[lhs[0]] + self.depths.items[lhs[1]] + self.depths.items[lhs[2]]) / 3.0;
    const d2 = (self.depths.items[rhs[0]] + self.depths.items[rhs[1]] + self.depths.items[rhs[2]]) / 3.0;
    return d1 > d2;
}

/// Draw the meshes, fill triangles, using texture if possible
pub fn draw(self: *Self, renderer: sdl.Renderer, tex: ?sdl.Texture) !void {
    if (self.indices.items.len == 0) return;

    if (!self.sorted) {
        // Sort triangles by depth, from farthest to closest
        var indices: [][3]u32 = undefined;
        indices.ptr = @ptrCast([*][3]u32, self.indices.items.ptr);
        indices.len = @divTrunc(self.indices.items.len, 3);
        std.sort.sort(
            [3]u32,
            indices,
            self,
            compareTriangleDepths,
        );
        self.sorted = true;
    }

    try renderer.drawGeometry(
        tex,
        self.vertices.items,
        self.indices.items,
    );

    // Debug: draw front triangles
    //for (self.large_front_triangles.items) |tri| {
    //    try renderer.drawGeometry(
    //        null,
    //        &[3]sdl.Vertex{
    //            self.vertices.items[tri[0]],
    //            self.vertices.items[tri[1]],
    //            self.vertices.items[tri[2]],
    //        },
    //        null,
    //    );
    //}
}

/// Draw the wireframe
pub fn drawWireframe(self: *Self, renderer: sdl.Renderer, color: sdl.Color) !void {
    if (self.indices.items.len == 0) return;

    const old_color = try renderer.getColor();
    defer renderer.setColor(old_color) catch unreachable;
    try renderer.setColor(color);

    const vs = self.vertices.items;
    var i: usize = 2;
    while (i < self.indices.items.len) : (i += 3) {
        const idx1 = self.indices.items[i - 2];
        const idx2 = self.indices.items[i - 1];
        const idx3 = self.indices.items[i];
        assert(idx1 < vs.len);
        assert(idx2 < vs.len);
        assert(idx3 < vs.len);
        try renderer.drawLineF(vs[idx1].position.x, vs[idx1].position.y, vs[idx2].position.x, vs[idx2].position.y);
        try renderer.drawLineF(vs[idx2].position.x, vs[idx2].position.y, vs[idx3].position.x, vs[idx3].position.y);
        try renderer.drawLineF(vs[idx3].position.x, vs[idx3].position.y, vs[idx1].position.x, vs[idx1].position.y);
    }
}
