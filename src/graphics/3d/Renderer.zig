const std = @import("std");
const assert = std.debug.assert;
const math = std.math;
const sdl = @import("sdl");
const jok = @import("../../jok.zig");
const @"3d" = jok.gfx.@"3d";
const zmath = @"3d".zmath;
const Camera = @"3d".Camera;
const Self = @This();

/// Triangle vertices
indices: std.ArrayList(u32),
sorted: bool = false,

/// Triangle vertices
vertices: std.ArrayList(sdl.Vertex),

/// Depth of vertices
depths: std.ArrayList(f32),

/// Large triangles directly in front of camera
large_front_triangles: std.ArrayList([3]u32),

/// Temporary storage for clipping
clip_vertices: std.ArrayList(zmath.Vec),
clip_colors: std.ArrayList(sdl.Color),
clip_texcoords: std.ArrayList(sdl.PointF),

/// Vertices in world space
world_positions: std.ArrayList(zmath.Vec),
world_normals: std.ArrayList(zmath.Vec),

pub fn init(allocator: std.mem.Allocator) Self {
    return .{
        .indices = std.ArrayList(u32).init(allocator),
        .vertices = std.ArrayList(sdl.Vertex).init(allocator),
        .depths = std.ArrayList(f32).init(allocator),
        .large_front_triangles = std.ArrayList([3]u32).init(allocator),
        .clip_vertices = std.ArrayList(zmath.Vec).init(allocator),
        .clip_colors = std.ArrayList(sdl.Color).init(allocator),
        .clip_texcoords = std.ArrayList(sdl.PointF).init(allocator),
        .world_positions = std.ArrayList(zmath.Vec).init(allocator),
        .world_normals = std.ArrayList(zmath.Vec).init(allocator),
    };
}

pub fn deinit(self: *Self) void {
    self.indices.deinit();
    self.vertices.deinit();
    self.depths.deinit();
    self.large_front_triangles.deinit();
    self.clip_vertices.deinit();
    self.clip_colors.deinit();
    self.clip_texcoords.deinit();
    self.world_positions.deinit();
    self.world_normals.deinit();
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

/// Lighting options
pub const LightingOption = struct {
    ambient_color: sdl.Color = sdl.Color.rgb(50, 50, 50),
    sun_pos: [3]f32 = .{ 1, 1, 1 },
    sun_color: sdl.Color = sdl.Color.white,

    // Calculate tint color
    tint_color_calc_fn: ?*const fn (
        material_color: sdl.Color,
        eye_pos: zmath.Vec,
        vertex_pos: zmath.Vec,
        normal: zmath.Vec,
        opt: LightingOption,
    ) sdl.Color = null,
};

/// Advanced vertice appending options
pub const AppendOption = struct {
    aabb: ?[6]f32 = null,
    cull_faces: bool = true,
    lighting: ?LightingOption = null,
};

/// Append mesh data
pub fn appendMesh(
    self: *Self,
    renderer: sdl.Renderer,
    model: zmath.Mat,
    camera: Camera,
    indices: []const u16,
    positions: []const [3]f32,
    normals: []const [3]f32,
    colors: ?[]const sdl.Color,
    texcoords: ?[]const [2]f32,
    opt: AppendOption,
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
        if (isOBBOutside(&[_]zmath.Vec{
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
        const world_positions = zmath.mul(zmath.Mat{
            v0,
            v1,
            v2,
            zmath.f32x4(0.0, 0.0, 0.0, 1.0),
        }, model);
        const world_normals = [3]zmath.Vec{ n0, n1, n2 };
        const clip_positions = zmath.mul(zmath.Mat{
            v0,
            v1,
            v2,
            zmath.f32x4(0.0, 0.0, 0.0, 1.0),
        }, mvp);
        const clip_colors: ?[3]sdl.Color = if (colors) |cs|
            [3]sdl.Color{ cs[idx0], cs[idx1], cs[idx2] }
        else
            null;
        const clip_texcoords: ?[3]sdl.PointF = if (texcoords) |ts|
            [3]sdl.PointF{
                .{ .x = ts[idx0][0], .y = ts[idx0][1] },
                .{ .x = ts[idx1][0], .y = ts[idx1][1] },
                .{ .x = ts[idx2][0], .y = ts[idx2][1] },
            }
        else
            null;
        self.clipTriangle(
            world_positions[0..3],
            &world_normals,
            clip_positions[0..3],
            clip_colors,
            clip_texcoords,
        );
    }
    if (self.clip_vertices.items.len == 0) return;
    assert(@rem(self.clip_vertices.items.len, 3) == 0);

    // Continue with remaining triangles
    try self.vertices.ensureTotalCapacityPrecise(self.vertices.items.len + self.clip_vertices.items.len);
    try self.depths.ensureTotalCapacityPrecise(self.vertices.items.len + self.clip_vertices.items.len);
    try self.indices.ensureTotalCapacityPrecise(self.vertices.items.len + self.clip_vertices.items.len);
    var current_index: u32 = @intCast(u32, self.indices.items.len);
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
        if (isTriangleOutside(ndc0, ndc1, ndc2)) {
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

        // Finally, we can append vertices for rendering
        const c0 = if (colors) |_| self.clip_colors.items[idx0] else sdl.Color.white;
        const c1 = if (colors) |_| self.clip_colors.items[idx1] else sdl.Color.white;
        const c2 = if (colors) |_| self.clip_colors.items[idx2] else sdl.Color.white;
        const t0 = if (texcoords) |_| self.clip_texcoords.items[idx0] else undefined;
        const t1 = if (texcoords) |_| self.clip_texcoords.items[idx1] else undefined;
        const t2 = if (texcoords) |_| self.clip_texcoords.items[idx2] else undefined;
        self.vertices.appendSliceAssumeCapacity(&[_]sdl.Vertex{
            .{
                .position = .{ .x = positions_screen[0][0], .y = positions_screen[0][1] },
                .color = if (opt.lighting) |p| BLK: {
                    var calc = if (p.tint_color_calc_fn) |f| f else &calcTintColor;
                    break :BLK calc(c0, camera.position, world_v0, n0, p);
                } else c0,
                .tex_coord = t0,
            },
            .{
                .position = .{ .x = positions_screen[1][0], .y = positions_screen[1][1] },
                .color = if (opt.lighting) |p| BLK: {
                    var calc = if (p.tint_color_calc_fn) |f| f else &calcTintColor;
                    break :BLK calc(c1, camera.position, world_v1, n1, p);
                } else c1,
                .tex_coord = t1,
            },
            .{
                .position = .{ .x = positions_screen[2][0], .y = positions_screen[2][1] },
                .color = if (opt.lighting) |p| BLK: {
                    var calc = if (p.tint_color_calc_fn) |f| f else &calcTintColor;
                    break :BLK calc(c2, camera.position, world_v2, n2, p);
                } else c2,
                .tex_coord = t2,
            },
        });
        self.indices.appendSliceAssumeCapacity(&[_]u32{
            current_index,
            current_index + 1,
            current_index + 2,
        });
        self.depths.appendSliceAssumeCapacity(&[_]f32{
            positions_screen[0][2],
            positions_screen[1][2],
            positions_screen[2][2],
        });

        // Update front triangles
        const tri_coords = [3][2]f32{
            .{ positions_screen[0][0], positions_screen[0][1] },
            .{ positions_screen[1][0], positions_screen[1][1] },
            .{ positions_screen[2][0], positions_screen[2][1] },
        };
        const tri_depth = (positions_screen[0][2] + positions_screen[1][2] + positions_screen[2][2]) / 3.0;
        var is_suitable_front = false;
        const tri_area = (tri_coords[0][0] * (tri_coords[1][1] - tri_coords[2][1]) +
            tri_coords[1][0] * (tri_coords[2][1] - tri_coords[0][1]) +
            tri_coords[2][0] * (tri_coords[0][1] - tri_coords[1][1])) / 2.0;
        if (tri_area > front_tri_threshold) {
            is_suitable_front = true;
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
                    isPointInTriangle(tri_coords, front_tri_coords[0]) and
                    isPointInTriangle(tri_coords, front_tri_coords[1]) and
                    isPointInTriangle(tri_coords, front_tri_coords[2]))
                {
                    // Remove front triangle since new one is closer and larger
                    _ = self.large_front_triangles.swapRemove(idx);
                    continue;
                } else if (tri_depth > front_depth and
                    isPointInTriangle(front_tri_coords, tri_coords[0]) and
                    isPointInTriangle(front_tri_coords, tri_coords[1]) and
                    isPointInTriangle(front_tri_coords, tri_coords[2]))
                {
                    // The triangle is already covered
                    is_suitable_front = false;
                }
                idx += 1;
            }
        }
        if (is_suitable_front) {
            self.large_front_triangles.append(.{
                current_index,
                current_index + 1,
                current_index + 2,
            }) catch unreachable;
        }

        // Step forward index, one triangle a time
        current_index += 3;
    }

    self.sorted = false;
}

/// Clip triangle in homogeneous space, against panel w=0.00001
/// We are conceptually clipping away stuff behind camera
inline fn clipTriangle(
    self: *Self,
    world_positions: []const zmath.Vec,
    world_normals: []const zmath.Vec,
    clip_positions: []const zmath.Vec,
    colors: ?[3]sdl.Color,
    texcoords: ?[3]sdl.PointF,
) void {
    const clip_plane_w = 0.00001;
    var world_v0 = world_positions[0];
    var world_v1 = world_positions[1];
    var world_v2 = world_positions[2];
    var clip_v0 = clip_positions[0];
    var clip_v1 = clip_positions[1];
    var clip_v2 = clip_positions[2];
    var n0 = world_normals[0];
    var n1 = world_normals[1];
    var n2 = world_normals[2];
    var d_v0 = clip_v0[3] - clip_plane_w;
    var d_v1 = clip_v1[3] - clip_plane_w;
    var d_v2 = clip_v2[3] - clip_plane_w;
    var is_v0_inside = d_v0 >= 0;
    var is_v1_inside = d_v1 >= 0;
    var is_v2_inside = d_v2 >= 0;
    var c0: sdl.Color = undefined;
    var c1: sdl.Color = undefined;
    var c2: sdl.Color = undefined;
    if (colors) |cs| {
        c0 = cs[0];
        c1 = cs[1];
        c2 = cs[2];
    }
    var t0: sdl.PointF = undefined;
    var t1: sdl.PointF = undefined;
    var t2: sdl.PointF = undefined;
    if (texcoords) |ts| {
        t0 = ts[0];
        t1 = ts[1];
        t2 = ts[2];
    }

    // The whole triangle is behind the camera, ignore directly
    if (!is_v0_inside and !is_v1_inside and !is_v2_inside) return;

    // Rearrange order of vertices, make sure first vertex is inside
    if (!is_v0_inside and is_v1_inside) {
        std.mem.swap(zmath.Vec, &clip_v0, &clip_v1);
        std.mem.swap(zmath.Vec, &clip_v1, &clip_v2);
        std.mem.swap(zmath.Vec, &world_v0, &world_v1);
        std.mem.swap(zmath.Vec, &world_v1, &world_v2);
        std.mem.swap(zmath.Vec, &n0, &n1);
        std.mem.swap(zmath.Vec, &n1, &n2);
        std.mem.swap(f32, &d_v0, &d_v1);
        std.mem.swap(f32, &d_v1, &d_v2);
        std.mem.swap(bool, &is_v0_inside, &is_v1_inside);
        std.mem.swap(bool, &is_v1_inside, &is_v2_inside);
        if (colors) |_| {
            std.mem.swap(sdl.Color, &c0, &c1);
            std.mem.swap(sdl.Color, &c1, &c2);
        }
        if (texcoords) |_| {
            std.mem.swap(sdl.PointF, &t0, &t1);
            std.mem.swap(sdl.PointF, &t1, &t2);
        }
    } else if (!is_v0_inside and !is_v1_inside) {
        std.mem.swap(zmath.Vec, &clip_v1, &clip_v2);
        std.mem.swap(zmath.Vec, &clip_v0, &clip_v1);
        std.mem.swap(zmath.Vec, &world_v1, &world_v2);
        std.mem.swap(zmath.Vec, &world_v0, &world_v1);
        std.mem.swap(zmath.Vec, &n1, &n2);
        std.mem.swap(zmath.Vec, &n0, &n1);
        std.mem.swap(f32, &d_v1, &d_v2);
        std.mem.swap(f32, &d_v0, &d_v1);
        std.mem.swap(bool, &is_v1_inside, &is_v2_inside);
        std.mem.swap(bool, &is_v0_inside, &is_v1_inside);
        if (colors) |_| {
            std.mem.swap(sdl.Color, &c1, &c2);
            std.mem.swap(sdl.Color, &c0, &c1);
        }
        if (texcoords) |_| {
            std.mem.swap(sdl.PointF, &t1, &t2);
            std.mem.swap(sdl.PointF, &t0, &t1);
        }
    }

    // Append first vertex
    assert(is_v0_inside);
    self.clip_vertices.appendAssumeCapacity(clip_v0);
    self.world_positions.appendAssumeCapacity(world_v0);
    self.world_normals.appendAssumeCapacity(n0);
    if (colors) |_| self.clip_colors.appendAssumeCapacity(c0);
    if (texcoords) |_| self.clip_texcoords.appendAssumeCapacity(t0);

    // Clip next 2 vertices, depending on their positions
    if (is_v1_inside) {
        self.clip_vertices.appendAssumeCapacity(clip_v1);
        self.world_positions.appendAssumeCapacity(world_v1);
        self.world_normals.appendAssumeCapacity(n1);
        if (colors) |_| self.clip_colors.appendAssumeCapacity(c1);
        if (texcoords) |_| self.clip_texcoords.appendAssumeCapacity(t1);

        if (is_v2_inside) {
            self.clip_vertices.appendAssumeCapacity(clip_v2);
            self.world_positions.appendAssumeCapacity(world_v2);
            self.world_normals.appendAssumeCapacity(n2);
            if (colors) |_| self.clip_colors.appendAssumeCapacity(c2);
            if (texcoords) |_| self.clip_texcoords.appendAssumeCapacity(t2);
        } else {
            // First triangle
            var lerp = d_v1 / (d_v1 - d_v2);
            assert(lerp >= 0 and lerp <= 1);
            var lerp_world_position = zmath.lerp(world_v1, world_v2, lerp);
            var lerp_clip_position = zmath.lerp(clip_v1, clip_v2, lerp);
            var lerp_normal = zmath.normalize3(zmath.lerp(n1, n2, lerp));
            var lerp_color: ?sdl.Color = if (colors) |_| sdl.Color.rgba(
                @floatToInt(u8, @intToFloat(f32, c1.r) + (@intToFloat(f32, c2.r) - @intToFloat(f32, c1.r)) * lerp),
                @floatToInt(u8, @intToFloat(f32, c1.g) + (@intToFloat(f32, c2.g) - @intToFloat(f32, c1.g)) * lerp),
                @floatToInt(u8, @intToFloat(f32, c1.b) + (@intToFloat(f32, c2.b) - @intToFloat(f32, c1.b)) * lerp),
                @floatToInt(u8, @intToFloat(f32, c1.a) + (@intToFloat(f32, c2.a) - @intToFloat(f32, c1.a)) * lerp),
            ) else null;
            var lerp_texcoord: ?sdl.PointF = if (texcoords) |_| sdl.PointF{
                .x = t1.x + (t2.x - t1.x) * lerp,
                .y = t1.y + (t2.y - t1.y) * lerp,
            } else null;
            self.clip_vertices.appendAssumeCapacity(lerp_clip_position);
            self.world_positions.appendAssumeCapacity(lerp_world_position);
            self.world_normals.appendAssumeCapacity(lerp_normal);
            if (lerp_color) |c| self.clip_colors.appendAssumeCapacity(c);
            if (lerp_texcoord) |t| self.clip_texcoords.appendAssumeCapacity(t);

            // Second triangle
            self.clip_vertices.appendAssumeCapacity(clip_v0);
            self.world_positions.appendAssumeCapacity(world_v0);
            self.world_normals.appendAssumeCapacity(n0);
            if (colors) |_| self.clip_colors.appendAssumeCapacity(c0);
            if (texcoords) |_| self.clip_texcoords.appendAssumeCapacity(t0);
            self.clip_vertices.appendAssumeCapacity(lerp_clip_position);
            self.world_positions.appendAssumeCapacity(lerp_world_position);
            self.world_normals.appendAssumeCapacity(lerp_normal);
            if (lerp_color) |c| self.clip_colors.appendAssumeCapacity(c);
            if (lerp_texcoord) |t| self.clip_texcoords.appendAssumeCapacity(t);
            lerp = d_v0 / (d_v0 - d_v2);
            assert(lerp >= 0 and lerp <= 1);
            lerp_world_position = zmath.lerp(world_v0, world_v2, lerp);
            lerp_clip_position = zmath.lerp(clip_v0, clip_v2, lerp);
            lerp_normal = zmath.normalize3(zmath.lerp(n0, n2, lerp));
            lerp_color = if (colors) |_| sdl.Color.rgba(
                @floatToInt(u8, @intToFloat(f32, c0.r) + (@intToFloat(f32, c2.r) - @intToFloat(f32, c0.r)) * lerp),
                @floatToInt(u8, @intToFloat(f32, c0.g) + (@intToFloat(f32, c2.g) - @intToFloat(f32, c0.g)) * lerp),
                @floatToInt(u8, @intToFloat(f32, c0.b) + (@intToFloat(f32, c2.b) - @intToFloat(f32, c0.b)) * lerp),
                @floatToInt(u8, @intToFloat(f32, c0.a) + (@intToFloat(f32, c2.a) - @intToFloat(f32, c0.a)) * lerp),
            ) else null;
            lerp_texcoord = if (texcoords) |_| sdl.PointF{
                .x = t0.x + (t2.x - t0.x) * lerp,
                .y = t0.y + (t2.y - t0.y) * lerp,
            } else null;
            self.clip_vertices.appendAssumeCapacity(lerp_clip_position);
            self.world_positions.appendAssumeCapacity(lerp_world_position);
            self.world_normals.appendAssumeCapacity(lerp_normal);
            if (lerp_color) |c| self.clip_colors.appendAssumeCapacity(c);
            if (lerp_texcoord) |t| self.clip_texcoords.appendAssumeCapacity(t);
        }
    } else {
        var lerp = d_v0 / (d_v0 - d_v1);
        assert(lerp >= 0 and lerp <= 1);
        var lerp_world_position = zmath.lerp(world_v0, world_v1, lerp);
        var lerp_clip_position = zmath.lerp(clip_v0, clip_v1, lerp);
        var lerp_normal = zmath.normalize3(zmath.lerp(n0, n1, lerp));
        var lerp_color: ?sdl.Color = if (colors) |_| sdl.Color.rgba(
            @floatToInt(u8, @intToFloat(f32, c0.r) + (@intToFloat(f32, c1.r) - @intToFloat(f32, c0.r)) * lerp),
            @floatToInt(u8, @intToFloat(f32, c0.g) + (@intToFloat(f32, c1.g) - @intToFloat(f32, c0.g)) * lerp),
            @floatToInt(u8, @intToFloat(f32, c0.b) + (@intToFloat(f32, c1.b) - @intToFloat(f32, c0.b)) * lerp),
            @floatToInt(u8, @intToFloat(f32, c0.a) + (@intToFloat(f32, c1.a) - @intToFloat(f32, c0.a)) * lerp),
        ) else null;
        var lerp_texcoord: ?sdl.PointF = if (texcoords) |_| sdl.PointF{
            .x = t0.x + (t1.x - t0.x) * lerp,
            .y = t0.y + (t1.y - t0.y) * lerp,
        } else null;
        self.clip_vertices.appendAssumeCapacity(lerp_clip_position);
        self.world_positions.appendAssumeCapacity(lerp_world_position);
        self.world_normals.appendAssumeCapacity(lerp_normal);
        if (lerp_color) |c| self.clip_colors.appendAssumeCapacity(c);
        if (lerp_texcoord) |t| self.clip_texcoords.appendAssumeCapacity(t);

        if (is_v2_inside) {
            // First triangle
            lerp = d_v1 / (d_v1 - d_v2);
            assert(lerp >= 0 and lerp <= 1);
            lerp_world_position = zmath.lerp(world_v1, world_v2, lerp);
            lerp_clip_position = zmath.lerp(clip_v1, clip_v2, lerp);
            lerp_normal = zmath.normalize3(zmath.lerp(n1, n2, lerp));
            lerp_color = if (colors) |_| sdl.Color.rgba(
                @floatToInt(u8, @intToFloat(f32, c1.r) + (@intToFloat(f32, c2.r) - @intToFloat(f32, c1.r)) * lerp),
                @floatToInt(u8, @intToFloat(f32, c1.g) + (@intToFloat(f32, c2.g) - @intToFloat(f32, c1.g)) * lerp),
                @floatToInt(u8, @intToFloat(f32, c1.b) + (@intToFloat(f32, c2.b) - @intToFloat(f32, c1.b)) * lerp),
                @floatToInt(u8, @intToFloat(f32, c1.a) + (@intToFloat(f32, c2.a) - @intToFloat(f32, c1.a)) * lerp),
            ) else null;
            lerp_texcoord = if (texcoords) |_| sdl.PointF{
                .x = t1.x + (t2.x - t1.x) * lerp,
                .y = t1.y + (t2.y - t1.y) * lerp,
            } else null;
            self.clip_vertices.appendAssumeCapacity(lerp_clip_position);
            self.world_positions.appendAssumeCapacity(lerp_world_position);
            self.world_normals.appendAssumeCapacity(lerp_normal);
            if (lerp_color) |c| self.clip_colors.appendAssumeCapacity(c);
            if (lerp_texcoord) |t| self.clip_texcoords.appendAssumeCapacity(t);

            // Second triangle
            self.clip_vertices.appendAssumeCapacity(clip_v0);
            self.world_positions.appendAssumeCapacity(world_v0);
            self.world_normals.appendAssumeCapacity(n0);
            if (colors) |_| self.clip_colors.appendAssumeCapacity(c0);
            if (texcoords) |_| self.clip_texcoords.appendAssumeCapacity(t0);
            self.clip_vertices.appendAssumeCapacity(lerp_clip_position);
            self.world_positions.appendAssumeCapacity(lerp_world_position);
            self.world_normals.appendAssumeCapacity(lerp_normal);
            if (lerp_color) |c| self.clip_colors.appendAssumeCapacity(c);
            if (lerp_texcoord) |t| self.clip_texcoords.appendAssumeCapacity(t);
            self.clip_vertices.appendAssumeCapacity(clip_v2);
            self.world_positions.appendAssumeCapacity(world_v2);
            self.world_normals.appendAssumeCapacity(n2);
            if (colors) |_| self.clip_colors.appendAssumeCapacity(c2);
            if (texcoords) |_| self.clip_texcoords.appendAssumeCapacity(t2);
        } else {
            lerp = d_v0 / (d_v0 - d_v2);
            assert(lerp >= 0 and lerp <= 1);
            lerp_world_position = zmath.lerp(world_v0, world_v2, lerp);
            lerp_clip_position = zmath.lerp(clip_v0, clip_v2, lerp);
            lerp_normal = zmath.normalize3(zmath.lerp(n0, n2, lerp));
            lerp_color = if (colors) |_| sdl.Color.rgba(
                @floatToInt(u8, @intToFloat(f32, c0.r) + (@intToFloat(f32, c2.r) - @intToFloat(f32, c0.r)) * lerp),
                @floatToInt(u8, @intToFloat(f32, c0.g) + (@intToFloat(f32, c2.g) - @intToFloat(f32, c0.g)) * lerp),
                @floatToInt(u8, @intToFloat(f32, c0.b) + (@intToFloat(f32, c2.b) - @intToFloat(f32, c0.b)) * lerp),
                @floatToInt(u8, @intToFloat(f32, c0.a) + (@intToFloat(f32, c2.a) - @intToFloat(f32, c0.a)) * lerp),
            ) else null;
            lerp_texcoord = if (texcoords) |_| sdl.PointF{
                .x = t0.x + (t2.x - t0.x) * lerp,
                .y = t0.y + (t2.y - t0.y) * lerp,
            } else null;
            self.clip_vertices.appendAssumeCapacity(lerp_clip_position);
            self.world_positions.appendAssumeCapacity(lerp_world_position);
            self.world_normals.appendAssumeCapacity(lerp_normal);
            if (lerp_color) |c| self.clip_colors.appendAssumeCapacity(c);
            if (lerp_texcoord) |t| self.clip_texcoords.appendAssumeCapacity(t);
        }
    }
}

/// Test whether an OBB (oriented AABB) is outside of clipping space.
/// Algorithm description: We simply test whether all vertices is
/// outside of clipping space, the method will report some very close
/// OBBs as inside, but it's fast.
inline fn isOBBOutside(obb: []const zmath.Vec) bool {
    assert(obb.len == 8);

    // Get extents of AABB (our clipping space)
    const es = zmath.f32x8(
        obb[0][3],
        obb[1][3],
        obb[2][3],
        obb[3][3],
        obb[4][3],
        obb[5][3],
        obb[6][3],
        obb[7][3],
    );
    const e = @reduce(.Max, es);

    // test x coordinate
    const xs = zmath.f32x8(
        obb[0][0],
        obb[1][0],
        obb[2][0],
        obb[3][0],
        obb[4][0],
        obb[5][0],
        obb[6][0],
        obb[7][0],
    );
    if (@reduce(.Min, xs) > e or @reduce(.Max, xs) < -e) {
        return true;
    }

    // test y coordinate
    const ys = zmath.f32x8(
        obb[0][1],
        obb[1][1],
        obb[2][1],
        obb[3][1],
        obb[4][1],
        obb[5][1],
        obb[6][1],
        obb[7][1],
    );
    if (@reduce(.Min, ys) > e or @reduce(.Max, ys) < -e) {
        return true;
    }

    // test z coordinate
    const zs = zmath.f32x8(
        obb[0][2],
        obb[1][2],
        obb[2][2],
        obb[3][2],
        obb[4][2],
        obb[5][2],
        obb[6][2],
        obb[7][2],
    );
    if (@reduce(.Min, zs) > e or @reduce(.Max, zs) < -e) {
        return true;
    }

    return false;
}

/// Test whether all obb's triangles are hidden behind current front triangles
inline fn isOBBHiddenBehind(self: *Self, obb: []zmath.Vec) bool {
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
                isPointInTriangle(front_tri, tri[0]) and
                isPointInTriangle(front_tri, tri[1]) and
                isPointInTriangle(front_tri, tri[2]);
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

/// Test whether a triangle is outside of NDC.
/// Using Seperating Axis Therom (aka SAT) algorithm. There are 13 axes
/// that must be considered for projection:
/// 1. Nine axes given by the cross products of combination of edges from both
/// 2. Three face normals from the AABB
/// 3. One face normal from the triangle
inline fn isTriangleOutside(v0: zmath.Vec, v1: zmath.Vec, v2: zmath.Vec) bool {
    const S = struct {
        // Testing axis
        inline fn checkAxis(
            axis: zmath.Vec,
            _v0: zmath.Vec,
            _v1: zmath.Vec,
            _v2: zmath.Vec,
        ) bool {
            // Project all 3 vertices of the triangle onto the Seperating axis
            const p0 = zmath.dot3(_v0, axis)[0];
            const p1 = zmath.dot3(_v1, axis)[0];
            const p2 = zmath.dot3(_v2, axis)[0];

            // Project the AABB onto the seperating axis
            const r = @fabs(axis[0]) + @fabs(axis[1]) + @fabs(axis[2]);

            return math.max(-math.max3(p0, p1, p2), math.min3(p0, p1, p2)) > r;
        }
    };

    // Compute the edge vectors of the triangle  (ABC)
    // That is, get the lines between the points as vectors
    const f0 = v1 - v0;
    const f1 = v2 - v1;
    const f2 = v0 - v2;

    // We first test against 9 axis, these axis are given by
    // cross product combinations of the edges of the triangle
    // and the edges of the AABB.
    const axis_n0_f0 = zmath.f32x4(0, -f0[2], f0[1], 0); // zmath.cross3(n0, f0)
    const axis_n0_f1 = zmath.f32x4(0, -f1[2], f1[1], 0); // zmath.cross3(n0, f1)
    const axis_n0_f2 = zmath.f32x4(0, -f2[2], f2[1], 0); // zmath.cross3(n0, f2)
    const axis_n1_f0 = zmath.f32x4(f0[2], 0, -f0[0], 0); // zmath.cross3(n1, f0)
    const axis_n1_f1 = zmath.f32x4(f1[2], 0, -f1[0], 0); // zmath.cross3(n1, f1)
    const axis_n1_f2 = zmath.f32x4(f2[2], 0, -f2[0], 0); // zmath.cross3(n1, f2)
    const axis_n2_f0 = zmath.f32x4(-f0[1], f0[0], 0, 0); // zmath.cross3(n2, f0)
    const axis_n2_f1 = zmath.f32x4(-f1[1], f1[0], 0, 0); // zmath.cross3(n2, f1)
    const axis_n2_f2 = zmath.f32x4(-f2[1], f2[0], 0, 0); // zmath.cross3(n2, f2)
    if (S.checkAxis(axis_n0_f0, v0, v1, v2)) return true;
    if (S.checkAxis(axis_n0_f1, v0, v1, v2)) return true;
    if (S.checkAxis(axis_n0_f2, v0, v1, v2)) return true;
    if (S.checkAxis(axis_n1_f0, v0, v1, v2)) return true;
    if (S.checkAxis(axis_n1_f1, v0, v1, v2)) return true;
    if (S.checkAxis(axis_n1_f2, v0, v1, v2)) return true;
    if (S.checkAxis(axis_n2_f0, v0, v1, v2)) return true;
    if (S.checkAxis(axis_n2_f1, v0, v1, v2)) return true;
    if (S.checkAxis(axis_n2_f2, v0, v1, v2)) return true;

    // Next, we have 3 face normals from the AABB
    // for these tests we are conceptually checking if the bounding box
    // of the triangle intersects the bounding box of the AABB
    if (math.max3(v0[0], v1[0], v2[0]) < -1 or math.min3(v0[0], v1[0], v2[0]) > 1) return true;
    if (math.max3(v0[1], v1[1], v2[1]) < -1 or math.min3(v0[1], v1[1], v2[1]) > 1) return true;
    if (math.max3(v0[2], v1[2], v2[2]) < -1 or math.min3(v0[2], v1[2], v2[2]) > 1) return true;

    // Finally, test if AABB intersects triangle plane
    const plane_n = zmath.normalize3(zmath.cross3(f0, f1));
    const r = @fabs(plane_n[0]) + @fabs(plane_n[1]) + @fabs(plane_n[2]);
    return @fabs(zmath.dot3(plane_n, v0)[0]) > r;
}

/// Test whether a point is in triangle
/// Using Barycentric Technique, checkout link https://blackpawn.com/texts/pointinpoly
inline fn isPointInTriangle(tri: [3][2]f32, point: [2]f32) bool {
    @setEvalBranchQuota(10000);

    const v0 = zmath.f32x4(
        tri[2][0] - tri[0][0],
        tri[2][1] - tri[0][1],
        0,
        0,
    );
    const v1 = zmath.f32x4(
        tri[1][0] - tri[0][0],
        tri[1][1] - tri[0][1],
        0,
        0,
    );
    const v2 = zmath.f32x4(
        point[0] - tri[0][0],
        point[1] - tri[0][1],
        0,
        0,
    );
    const dot00 = zmath.dot2(v0, v0)[0];
    const dot01 = zmath.dot2(v0, v1)[0];
    const dot02 = zmath.dot2(v0, v2)[0];
    const dot11 = zmath.dot2(v1, v1)[0];
    const dot12 = zmath.dot2(v1, v2)[0];
    const inv_denom = 1.0 / (dot00 * dot11 - dot01 * dot01);
    const u = (dot11 * dot02 - dot01 * dot12) * inv_denom;
    const v = (dot00 * dot12 - dot01 * dot02) * inv_denom;
    return u >= 0 and v >= 0 and (u + v < 1);
}

/// Calculate tint color of vertex according to lighting paramters
fn calcTintColor(
    material_color: sdl.Color,
    eye_pos: zmath.Vec,
    vertex_pos: zmath.Vec,
    normal: zmath.Vec,
    opt: LightingOption,
) sdl.Color {
    assert(math.approxEqAbs(f32, eye_pos[3], 1.0, math.f32_epsilon));
    assert(math.approxEqAbs(f32, vertex_pos[3], 1.0, math.f32_epsilon));
    assert(math.approxEqAbs(f32, normal[3], 0, math.f32_epsilon));
    const tc = 1.0 / 255.0;
    const raw_color = zmath.f32x4(
        @intToFloat(f32, material_color.r) * tc,
        @intToFloat(f32, material_color.g) * tc,
        @intToFloat(f32, material_color.b) * tc,
        0,
    );
    const ambient_color = raw_color * zmath.f32x4(
        @intToFloat(f32, opt.ambient_color.r) * tc,
        @intToFloat(f32, opt.ambient_color.g) * tc,
        @intToFloat(f32, opt.ambient_color.b) * tc,
        0,
    );
    const sun_color = zmath.f32x4(
        @intToFloat(f32, opt.sun_color.r) * tc,
        @intToFloat(f32, opt.sun_color.g) * tc,
        @intToFloat(f32, opt.sun_color.b) * tc,
        0,
    );
    const sun_dir = zmath.normalize3(zmath.f32x4(
        opt.sun_pos[0],
        opt.sun_pos[1],
        opt.sun_pos[2],
        1,
    ) - vertex_pos);
    const eye_dir = zmath.normalize3(eye_pos - vertex_pos);
    const halfway_dir = zmath.normalize3(eye_dir + sun_dir);
    const ratios = zmath.max(
        zmath.dot3(normal, halfway_dir),
        zmath.f32x4(0, 0, 0, 0),
    );
    const final_color = zmath.clamp(
        ambient_color + raw_color * ratios * sun_color,
        zmath.splat(zmath.Vec, 0),
        zmath.splat(zmath.Vec, 1),
    );
    return .{
        .r = @floatToInt(u8, final_color[0] * 255),
        .g = @floatToInt(u8, final_color[1] * 255),
        .b = @floatToInt(u8, final_color[2] * 255),
        .a = material_color.a,
    };
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
