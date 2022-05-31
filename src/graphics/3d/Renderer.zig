const std = @import("std");
const assert = std.debug.assert;
const math = std.math;
const sdl = @import("sdl");
const jok = @import("../../jok.zig");
const @"3d" = jok.gfx.@"3d";
const zmath = @"3d".zmath;
const Camera = @"3d".Camera;
const Self = @This();

/// Vertex Indices
indices: std.ArrayList(u32),
sorted: bool = false,

/// Triangle vertices
vertices: std.ArrayList(sdl.Vertex),

/// Depth of vertices
depths: std.ArrayList(f32),

pub fn init(allocator: std.mem.Allocator) Self {
    return .{
        .indices = std.ArrayList(u32).init(allocator),
        .vertices = std.ArrayList(sdl.Vertex).init(allocator),
        .depths = std.ArrayList(f32).init(allocator),
    };
}

pub fn deinit(self: *Self) void {
    self.indices.deinit();
    self.vertices.deinit();
    self.depths.deinit();
}

/// Clear mesh data
pub fn clearVertex(self: *Self, retain_memory: bool) void {
    if (retain_memory) {
        self.indices.clearRetainingCapacity();
        self.vertices.clearRetainingCapacity();
        self.depths.clearRetainingCapacity();
    } else {
        self.indices.clearAndFree();
        self.vertices.clearAndFree();
        self.depths.clearAndFree();
    }
    self.sorted = false;
}

/// Advanced vertice appending options
pub const AppendOption = struct {
    aabb: ?[6]f32 = null,
    cull_faces: bool = true,
};

/// Append vertex data
pub fn appendVertex(
    self: *Self,
    renderer: sdl.Renderer,
    model: zmath.Mat,
    camera: *Camera,
    indices: []const u16,
    positions: []const [3]f32,
    colors: ?[]const sdl.Color,
    texcoords: ?[]const [2]f32,
    opt: AppendOption,
) !void {
    assert(@rem(indices.len, 3) == 0);
    assert(if (colors) |cs| cs.len == positions.len else true);
    assert(if (texcoords) |ts| ts.len == positions.len else true);
    if (indices.len == 0) return;
    const vp = renderer.getViewport();
    const mvp = zmath.mul(model, camera.getViewProjectMatrix());
    const base_index = @intCast(u32, self.vertices.items.len);
    var clipped_indices = std.StaticBitSet(math.maxInt(u16)).initEmpty();

    // Do early clipping with aabb if possible
    if (opt.aabb) |ab| {
        const width = ab[3] - ab[0];
        const length = ab[5] - ab[2];
        assert(width > 0);
        assert(length > 0);
        const v0 = zmath.f32x4(ab[0], ab[1], ab[2], 1.0);
        const v1 = zmath.f32x4(ab[0], ab[1], ab[2] + length, 1.0);
        const v2 = zmath.f32x4(ab[0] + width, ab[1], ab[2] + length, 1.0);
        const v3 = zmath.f32x4(ab[0] + width, ab[1], ab[2], 1.0);
        const v4 = zmath.f32x4(ab[3] - width, ab[4], ab[5] - length, 1.0);
        const v5 = zmath.f32x4(ab[3] - width, ab[4], ab[5], 1.0);
        const v6 = zmath.f32x4(ab[3], ab[4], ab[5], 1.0);
        const v7 = zmath.f32x4(ab[3], ab[4], ab[5] - length, 1.0);
        const obb = [_]zmath.Vec{
            zmath.mul(v0, mvp),
            zmath.mul(v1, mvp),
            zmath.mul(v2, mvp),
            zmath.mul(v3, mvp),
            zmath.mul(v4, mvp),
            zmath.mul(v5, mvp),
            zmath.mul(v6, mvp),
            zmath.mul(v7, mvp),
        };
        if (isOBBOutside(&obb)) return;
    }

    // Add vertices
    try self.vertices.ensureTotalCapacity(self.vertices.items.len + positions.len);
    try self.depths.ensureTotalCapacity(self.vertices.items.len + positions.len);
    for (positions) |pos, i| {
        // Do MVP transforming
        const pos_clip = zmath.mul(zmath.f32x4(pos[0], pos[1], pos[2], 1.0), mvp);
        if ((pos_clip[0] < -pos_clip[3] or pos_clip[0] > pos_clip[3]) or
            (pos_clip[1] < -pos_clip[3] or pos_clip[1] > pos_clip[3]) or
            (pos_clip[2] < -pos_clip[3] or pos_clip[2] > pos_clip[3]))
        {
            clipped_indices.set(i);
        }

        // TODO Clip coordinates to [-w, w]

        const ndc = pos_clip / zmath.splat(zmath.Vec, pos_clip[3]);
        const pos_screen = zmath.mul(ndc, zmath.loadMat43(&[_]f32{
            // zig fmt: off
            0.5 * @intToFloat(f32, vp.width), 1.0, 0.0,
            0.0, -0.5 * @intToFloat(f32, vp.height), 0.0,
            0.0, 0.0, 0.5,
            0.5 * @intToFloat(f32, vp.width), 0.5 * @intToFloat(f32, vp.height), 0.5,
        }));
        self.vertices.appendAssumeCapacity(.{
            .position = .{ .x = pos_screen[0], .y = pos_screen[1] },
            .color = if (colors) |cs| cs[i] else sdl.Color.white,
            .tex_coord = if (texcoords) |tex| .{ .x = tex[i][0], .y = tex[i][1] } else undefined,
        });
        self.depths.appendAssumeCapacity(pos_screen[2]);
    }
    errdefer {
        self.vertices.resize(self.vertices.items.len - positions.len) catch unreachable;
        self.depths.resize(self.vertices.items.len - positions.len) catch unreachable;
    }

    // Add indices
    try self.indices.ensureTotalCapacity(self.indices.items.len + indices.len);
    var i: usize = 2;
    while (i < indices.len) : (i += 3) {
        const idx0 = indices[i - 2];
        const idx1 = indices[i - 1];
        const idx2 = indices[i];

        // Ignore triangles outside of clip space
        if (clipped_indices.isSet(idx0) and
            clipped_indices.isSet(idx1) and
            clipped_indices.isSet(idx2))
        {
            const pos_clip0 = zmath.mul(zmath.f32x4(
                positions[idx0][0], positions[idx0][1],
                positions[idx0][2], 1.0,
            ), mvp);
            const pos_clip1 = zmath.mul(zmath.f32x4(
                positions[idx1][0], positions[idx1][1],
                positions[idx1][2], 1.0,
            ), mvp);
            const pos_clip2 = zmath.mul(zmath.f32x4(
                positions[idx2][0], positions[idx2][1],
                positions[idx2][2], 1.0,
            ), mvp);
            if (isTriangleOutside(pos_clip0, pos_clip1, pos_clip2)) {
                continue;
            }
        }

        // Ignore triangles facing away from camera (front faces' vertices are clock-wise organized)
        if (opt.cull_faces) {
            const v0 = zmath.mul(zmath.f32x4(positions[idx0][0], positions[idx0][1], positions[idx0][2], 1), model);
            const v1 = zmath.mul(zmath.f32x4(positions[idx1][0], positions[idx1][1], positions[idx1][2], 1), model);
            const v2 = zmath.mul(zmath.f32x4(positions[idx2][0], positions[idx2][1], positions[idx2][2], 1), model);
            const center = (v0 + v1 + v2) / zmath.splat(zmath.Vec, 3.0);
            const v0v1 = v1 - v0;
            const v0v2 = v2 - v0;
            const face_dir = zmath.normalize3(zmath.cross3(v0v1, v0v2));
            const camera_dir = zmath.normalize3(center - camera.position);
            const angles = zmath.dot3(face_dir, camera_dir);
            if (angles[0] >= 0) continue;
        }

        // Append indices
        self.indices.appendSliceAssumeCapacity(&[_]u32{
            idx0 + base_index,
            idx1 + base_index,
            idx2 + base_index,
        });
    }

    self.sorted = false;
}

/// Test whether an OBB (oriented AABB) is outside of clipping space.
/// Algorithm description: We simply test whether all vertices is 
/// outside of clipping space, the method will report some very close
/// OBBs as inside, but it's fast.
inline fn isOBBOutside(obb: []const zmath.Vec) bool {
    assert(obb.len == 8);

    // Get extents of AABB (our clipping space)
    const es = zmath.f32x8(
        obb[0][3], obb[1][3], obb[2][3], obb[3][3],
        obb[4][3], obb[5][3], obb[6][3], obb[7][3],
    );
    const e = @reduce(.Max, es);

    // test x coordinate
    const xs = zmath.f32x8(
        obb[0][0], obb[1][0], obb[2][0], obb[3][0],
        obb[4][0], obb[5][0], obb[6][0], obb[7][0],
    );
    if (@reduce(.Min, xs) > e or @reduce(.Max, xs) < -e) {
        return true;
    }
   
    // test y coordinate
    const ys = zmath.f32x8(
        obb[0][1], obb[1][1], obb[2][1], obb[3][1],
        obb[4][1], obb[5][1], obb[6][1], obb[7][1],
    );
    if (@reduce(.Min, ys) > e or @reduce(.Max, ys) < -e) {
        return true;
    }
   
    // test z coordinate
    const zs = zmath.f32x8(
        obb[0][2], obb[1][2], obb[2][2], obb[3][2],
        obb[4][2], obb[5][2], obb[6][2], obb[7][2],
    );
    if (@reduce(.Min, zs) > e or @reduce(.Max, zs) < -e) {
        return true;
    }

    return false;
}

/// Test whether a triangle is outside of clipping space.
/// Using Seperating Axis Therom (aka SAT) algorithm. There are 13 axes 
/// that must be considered for projection:
/// 1. Nine axes given by the cross products of combination of edges from both
/// 2. Three face normals from the AABB
/// 3. One face normal from the triangle
inline fn isTriangleOutside(v0: zmath.Vec, v1: zmath.Vec, v2: zmath.Vec) bool {
    const S = struct {
        // Face normals of the AABB, which is our clipping space [-1, 1]
        const n0 = @"3d".v_right;
        const n1 = @"3d".v_up;
        const n2 = @"3d".v_forward;

        // Testing axis
        inline fn checkAxis(
            axis: zmath.Vec,
            e0: f32,
            e1: f32,
            e2: f32,
            _v0: zmath.Vec,
            _v1: zmath.Vec,
            _v2: zmath.Vec,
        ) bool {
            // Project all 3 vertices of the triangle onto the Seperating axis
            const p0 = zmath.dot3(_v0, axis)[0];
            const p1 = zmath.dot3(_v1, axis)[0];
            const p2 = zmath.dot3(_v2, axis)[0];

            // Project the AABB onto the seperating axis
            const r = e0 * @fabs(zmath.dot3(n0, axis)[0]) +
                      e1 * @fabs(zmath.dot3(n1, axis)[0]) +
                      e2 * @fabs(zmath.dot3(n2, axis)[0]);

            return math.max(-math.max3(p0, p1, p2), math.min3(p0, p1, p2)) > r;
        }
    };

    // Get extents of AABB (our clipping space)
    const e0 = math.max3(v0[3], v1[3], v2[3]);
    const e1 = e0;
    const e2 = e0;

    // Compute the edge vectors of the triangle  (ABC)
    // That is, get the lines between the points as vectors
    const f0 = v1 - v0;
    const f1 = v2 - v1;
    const f2 = v0 - v2;

    // We first test against 9 axis, these axis are given by
    // cross product combinations of the edges of the triangle
    // and the edges of the AABB.
    const axis_n0_f0 = zmath.cross3(S.n0, f0);
    const axis_n0_f1 = zmath.cross3(S.n0, f1);
    const axis_n0_f2 = zmath.cross3(S.n0, f2);
    const axis_n1_f0 = zmath.cross3(S.n1, f0);
    const axis_n1_f1 = zmath.cross3(S.n1, f1);
    const axis_n1_f2 = zmath.cross3(S.n1, f2);
    const axis_n2_f0 = zmath.cross3(S.n2, f0);
    const axis_n2_f1 = zmath.cross3(S.n2, f1);
    const axis_n2_f2 = zmath.cross3(S.n2, f2);
    if (S.checkAxis(axis_n0_f0, e0, e1, e2, v0, v1, v2)) return true;
    if (S.checkAxis(axis_n0_f1, e0, e1, e2, v0, v1, v2)) return true;
    if (S.checkAxis(axis_n0_f2, e0, e1, e2, v0, v1, v2)) return true;
    if (S.checkAxis(axis_n1_f0, e0, e1, e2, v0, v1, v2)) return true;
    if (S.checkAxis(axis_n1_f1, e0, e1, e2, v0, v1, v2)) return true;
    if (S.checkAxis(axis_n1_f2, e0, e1, e2, v0, v1, v2)) return true;
    if (S.checkAxis(axis_n2_f0, e0, e1, e2, v0, v1, v2)) return true;
    if (S.checkAxis(axis_n2_f1, e0, e1, e2, v0, v1, v2)) return true;
    if (S.checkAxis(axis_n2_f2, e0, e1, e2, v0, v1, v2)) return true;

    // Next, we have 3 face normals from the AABB
    // for these tests we are conceptually checking if the bounding box
    // of the triangle intersects the bounding box of the AABB
    if (math.max3(v0[0], v1[0], v2[0]) < -e0 or math.min3(v0[0], v1[0], v2[0]) > e0) return true;
    if (math.max3(v0[1], v1[1], v2[1]) < -e1 or math.min3(v0[1], v1[1], v2[1]) > e1) return true;
    if (math.max3(v0[2], v1[2], v2[2]) < -e2 or math.min3(v0[2], v1[2], v2[2]) > e2) return true;

    // Finally, test if AABB intersects triangle plane
    const plane_n = zmath.normalize3(zmath.cross3(f0, f1));
    const r = e0 * @fabs(plane_n[0]) + e1 * @fabs(plane_n[1]) + e2 * @fabs(plane_n[2]);
    return @fabs(zmath.dot3(plane_n, v0)[0]) > r;
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
        const indices = @bitCast([][3]u32, self.indices.items)[0..@divTrunc(self.indices.items.len, 3)];
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
}

/// Draw the wireframe
pub fn drawWireframe(self: Self, renderer: sdl.Renderer) !void {
    var i: usize = 2;
    while (i < self.indices.items.len) : (i += 3) {
        try renderer.drawLineF(
            self.vertices.items[self.indices.items[i - 2]].position.x,
            self.vertices.items[self.indices.items[i - 2]].position.y,
            self.vertices.items[self.indices.items[i - 1]].position.x,
            self.vertices.items[self.indices.items[i - 1]].position.y,
        );
        try renderer.drawLineF(
            self.vertices.items[self.indices.items[i - 1]].position.x,
            self.vertices.items[self.indices.items[i - 1]].position.y,
            self.vertices.items[self.indices.items[i]].position.x,
            self.vertices.items[self.indices.items[i]].position.y,
        );
        try renderer.drawLineF(
            self.vertices.items[self.indices.items[i]].position.x,
            self.vertices.items[self.indices.items[i]].position.y,
            self.vertices.items[self.indices.items[i - 2]].position.x,
            self.vertices.items[self.indices.items[i - 2]].position.y,
        );
    }
}
