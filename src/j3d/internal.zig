const std = @import("std");
const assert = std.debug.assert;
const math = std.math;
const sdl = @import("sdl");
const jok = @import("../jok.zig");
const zmath = jok.zmath;

/// Test whether an OBB (oriented AABB) is outside of clipping space.
/// Algorithm description: We simply test whether all vertices is
/// outside of clipping space, the method will report some very close
/// OBBs as inside, but it's fast.
pub inline fn isOBBOutside(obb: []const zmath.Vec) bool {
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

/// Test whether a triangle is outside of NDC.
/// Using Seperating Axis Therom (aka SAT) algorithm. There are 13 axes
/// that must be considered for projection:
/// 1. Nine axes given by the cross products of combination of edges from both
/// 2. Three face normals from the AABB
/// 3. One face normal from the triangle
pub inline fn isTriangleOutside(v0: zmath.Vec, v1: zmath.Vec, v2: zmath.Vec) bool {
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

/// Clip triangle in homogeneous space, against panel w=0.0001
/// We are conceptually clipping away stuff behind camera
pub inline fn clipTriangle(
    tri_world_positions: []const zmath.Vec,
    tri_world_normals: []const zmath.Vec,
    tri_clip_positions: []const zmath.Vec,
    tri_colors: ?[3]sdl.Color,
    tri_texcoords: ?[3]sdl.PointF,
    clip_vertices: *std.ArrayList(zmath.Vec),
    clip_colors: *std.ArrayList(sdl.Color),
    clip_texcoords: *std.ArrayList(sdl.PointF),
    world_positions: *std.ArrayList(zmath.Vec),
    world_normals: *std.ArrayList(zmath.Vec),
) void {
    const clip_plane_w = 0.0001;
    var world_v0 = tri_world_positions[0];
    var world_v1 = tri_world_positions[1];
    var world_v2 = tri_world_positions[2];
    var clip_v0 = tri_clip_positions[0];
    var clip_v1 = tri_clip_positions[1];
    var clip_v2 = tri_clip_positions[2];
    var n0 = tri_world_normals[0];
    var n1 = tri_world_normals[1];
    var n2 = tri_world_normals[2];
    var d_v0 = clip_v0[3] - clip_plane_w;
    var d_v1 = clip_v1[3] - clip_plane_w;
    var d_v2 = clip_v2[3] - clip_plane_w;
    var is_v0_inside = d_v0 >= 0;
    var is_v1_inside = d_v1 >= 0;
    var is_v2_inside = d_v2 >= 0;
    var c0: sdl.Color = undefined;
    var c1: sdl.Color = undefined;
    var c2: sdl.Color = undefined;
    if (tri_colors) |cs| {
        c0 = cs[0];
        c1 = cs[1];
        c2 = cs[2];
    }
    var t0: sdl.PointF = undefined;
    var t1: sdl.PointF = undefined;
    var t2: sdl.PointF = undefined;
    if (tri_texcoords) |ts| {
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
        if (tri_colors) |_| {
            std.mem.swap(sdl.Color, &c0, &c1);
            std.mem.swap(sdl.Color, &c1, &c2);
        }
        if (tri_texcoords) |_| {
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
        if (tri_colors) |_| {
            std.mem.swap(sdl.Color, &c1, &c2);
            std.mem.swap(sdl.Color, &c0, &c1);
        }
        if (tri_texcoords) |_| {
            std.mem.swap(sdl.PointF, &t1, &t2);
            std.mem.swap(sdl.PointF, &t0, &t1);
        }
    }

    // Append first vertex
    assert(is_v0_inside);
    clip_vertices.appendAssumeCapacity(clip_v0);
    world_positions.appendAssumeCapacity(world_v0);
    world_normals.appendAssumeCapacity(n0);
    if (tri_colors) |_| clip_colors.appendAssumeCapacity(c0);
    if (tri_texcoords) |_| clip_texcoords.appendAssumeCapacity(t0);

    // Clip next 2 vertices, depending on their positions
    if (is_v1_inside) {
        clip_vertices.appendAssumeCapacity(clip_v1);
        world_positions.appendAssumeCapacity(world_v1);
        world_normals.appendAssumeCapacity(n1);
        if (tri_colors) |_| clip_colors.appendAssumeCapacity(c1);
        if (tri_texcoords) |_| clip_texcoords.appendAssumeCapacity(t1);

        if (is_v2_inside) {
            clip_vertices.appendAssumeCapacity(clip_v2);
            world_positions.appendAssumeCapacity(world_v2);
            world_normals.appendAssumeCapacity(n2);
            if (tri_colors) |_| clip_colors.appendAssumeCapacity(c2);
            if (tri_texcoords) |_| clip_texcoords.appendAssumeCapacity(t2);
        } else {
            // First triangle
            var lerp = d_v1 / (d_v1 - d_v2);
            assert(lerp >= 0 and lerp <= 1);
            var lerp_world_position = zmath.lerp(world_v1, world_v2, lerp);
            var lerp_clip_position = zmath.lerp(clip_v1, clip_v2, lerp);
            var lerp_normal = zmath.normalize3(zmath.lerp(n1, n2, lerp));
            var lerp_color: ?sdl.Color = if (tri_colors) |_| sdl.Color.rgba(
                @floatToInt(u8, @intToFloat(f32, c1.r) + (@intToFloat(f32, c2.r) - @intToFloat(f32, c1.r)) * lerp),
                @floatToInt(u8, @intToFloat(f32, c1.g) + (@intToFloat(f32, c2.g) - @intToFloat(f32, c1.g)) * lerp),
                @floatToInt(u8, @intToFloat(f32, c1.b) + (@intToFloat(f32, c2.b) - @intToFloat(f32, c1.b)) * lerp),
                @floatToInt(u8, @intToFloat(f32, c1.a) + (@intToFloat(f32, c2.a) - @intToFloat(f32, c1.a)) * lerp),
            ) else null;
            var lerp_texcoord: ?sdl.PointF = if (tri_texcoords) |_| sdl.PointF{
                .x = t1.x + (t2.x - t1.x) * lerp,
                .y = t1.y + (t2.y - t1.y) * lerp,
            } else null;
            clip_vertices.appendAssumeCapacity(lerp_clip_position);
            world_positions.appendAssumeCapacity(lerp_world_position);
            world_normals.appendAssumeCapacity(lerp_normal);
            if (lerp_color) |c| clip_colors.appendAssumeCapacity(c);
            if (lerp_texcoord) |t| clip_texcoords.appendAssumeCapacity(t);

            // Second triangle
            clip_vertices.appendAssumeCapacity(clip_v0);
            world_positions.appendAssumeCapacity(world_v0);
            world_normals.appendAssumeCapacity(n0);
            if (tri_colors) |_| clip_colors.appendAssumeCapacity(c0);
            if (tri_texcoords) |_| clip_texcoords.appendAssumeCapacity(t0);
            clip_vertices.appendAssumeCapacity(lerp_clip_position);
            world_positions.appendAssumeCapacity(lerp_world_position);
            world_normals.appendAssumeCapacity(lerp_normal);
            if (lerp_color) |c| clip_colors.appendAssumeCapacity(c);
            if (lerp_texcoord) |t| clip_texcoords.appendAssumeCapacity(t);
            lerp = d_v0 / (d_v0 - d_v2);
            assert(lerp >= 0 and lerp <= 1);
            lerp_world_position = zmath.lerp(world_v0, world_v2, lerp);
            lerp_clip_position = zmath.lerp(clip_v0, clip_v2, lerp);
            lerp_normal = zmath.normalize3(zmath.lerp(n0, n2, lerp));
            lerp_color = if (tri_colors) |_| sdl.Color.rgba(
                @floatToInt(u8, @intToFloat(f32, c0.r) + (@intToFloat(f32, c2.r) - @intToFloat(f32, c0.r)) * lerp),
                @floatToInt(u8, @intToFloat(f32, c0.g) + (@intToFloat(f32, c2.g) - @intToFloat(f32, c0.g)) * lerp),
                @floatToInt(u8, @intToFloat(f32, c0.b) + (@intToFloat(f32, c2.b) - @intToFloat(f32, c0.b)) * lerp),
                @floatToInt(u8, @intToFloat(f32, c0.a) + (@intToFloat(f32, c2.a) - @intToFloat(f32, c0.a)) * lerp),
            ) else null;
            lerp_texcoord = if (tri_texcoords) |_| sdl.PointF{
                .x = t0.x + (t2.x - t0.x) * lerp,
                .y = t0.y + (t2.y - t0.y) * lerp,
            } else null;
            clip_vertices.appendAssumeCapacity(lerp_clip_position);
            world_positions.appendAssumeCapacity(lerp_world_position);
            world_normals.appendAssumeCapacity(lerp_normal);
            if (lerp_color) |c| clip_colors.appendAssumeCapacity(c);
            if (lerp_texcoord) |t| clip_texcoords.appendAssumeCapacity(t);
        }
    } else {
        var lerp = d_v0 / (d_v0 - d_v1);
        assert(lerp >= 0 and lerp <= 1);
        var lerp_world_position = zmath.lerp(world_v0, world_v1, lerp);
        var lerp_clip_position = zmath.lerp(clip_v0, clip_v1, lerp);
        var lerp_normal = zmath.normalize3(zmath.lerp(n0, n1, lerp));
        var lerp_color: ?sdl.Color = if (tri_colors) |_| sdl.Color.rgba(
            @floatToInt(u8, @intToFloat(f32, c0.r) + (@intToFloat(f32, c1.r) - @intToFloat(f32, c0.r)) * lerp),
            @floatToInt(u8, @intToFloat(f32, c0.g) + (@intToFloat(f32, c1.g) - @intToFloat(f32, c0.g)) * lerp),
            @floatToInt(u8, @intToFloat(f32, c0.b) + (@intToFloat(f32, c1.b) - @intToFloat(f32, c0.b)) * lerp),
            @floatToInt(u8, @intToFloat(f32, c0.a) + (@intToFloat(f32, c1.a) - @intToFloat(f32, c0.a)) * lerp),
        ) else null;
        var lerp_texcoord: ?sdl.PointF = if (tri_texcoords) |_| sdl.PointF{
            .x = t0.x + (t1.x - t0.x) * lerp,
            .y = t0.y + (t1.y - t0.y) * lerp,
        } else null;
        clip_vertices.appendAssumeCapacity(lerp_clip_position);
        world_positions.appendAssumeCapacity(lerp_world_position);
        world_normals.appendAssumeCapacity(lerp_normal);
        if (lerp_color) |c| clip_colors.appendAssumeCapacity(c);
        if (lerp_texcoord) |t| clip_texcoords.appendAssumeCapacity(t);

        if (is_v2_inside) {
            // First triangle
            lerp = d_v1 / (d_v1 - d_v2);
            assert(lerp >= 0 and lerp <= 1);
            lerp_world_position = zmath.lerp(world_v1, world_v2, lerp);
            lerp_clip_position = zmath.lerp(clip_v1, clip_v2, lerp);
            lerp_normal = zmath.normalize3(zmath.lerp(n1, n2, lerp));
            lerp_color = if (tri_colors) |_| sdl.Color.rgba(
                @floatToInt(u8, @intToFloat(f32, c1.r) + (@intToFloat(f32, c2.r) - @intToFloat(f32, c1.r)) * lerp),
                @floatToInt(u8, @intToFloat(f32, c1.g) + (@intToFloat(f32, c2.g) - @intToFloat(f32, c1.g)) * lerp),
                @floatToInt(u8, @intToFloat(f32, c1.b) + (@intToFloat(f32, c2.b) - @intToFloat(f32, c1.b)) * lerp),
                @floatToInt(u8, @intToFloat(f32, c1.a) + (@intToFloat(f32, c2.a) - @intToFloat(f32, c1.a)) * lerp),
            ) else null;
            lerp_texcoord = if (tri_texcoords) |_| sdl.PointF{
                .x = t1.x + (t2.x - t1.x) * lerp,
                .y = t1.y + (t2.y - t1.y) * lerp,
            } else null;
            clip_vertices.appendAssumeCapacity(lerp_clip_position);
            world_positions.appendAssumeCapacity(lerp_world_position);
            world_normals.appendAssumeCapacity(lerp_normal);
            if (lerp_color) |c| clip_colors.appendAssumeCapacity(c);
            if (lerp_texcoord) |t| clip_texcoords.appendAssumeCapacity(t);

            // Second triangle
            clip_vertices.appendAssumeCapacity(clip_v0);
            world_positions.appendAssumeCapacity(world_v0);
            world_normals.appendAssumeCapacity(n0);
            if (tri_colors) |_| clip_colors.appendAssumeCapacity(c0);
            if (tri_texcoords) |_| clip_texcoords.appendAssumeCapacity(t0);
            clip_vertices.appendAssumeCapacity(lerp_clip_position);
            world_positions.appendAssumeCapacity(lerp_world_position);
            world_normals.appendAssumeCapacity(lerp_normal);
            if (lerp_color) |c| clip_colors.appendAssumeCapacity(c);
            if (lerp_texcoord) |t| clip_texcoords.appendAssumeCapacity(t);
            clip_vertices.appendAssumeCapacity(clip_v2);
            world_positions.appendAssumeCapacity(world_v2);
            world_normals.appendAssumeCapacity(n2);
            if (tri_colors) |_| clip_colors.appendAssumeCapacity(c2);
            if (tri_texcoords) |_| clip_texcoords.appendAssumeCapacity(t2);
        } else {
            lerp = d_v0 / (d_v0 - d_v2);
            assert(lerp >= 0 and lerp <= 1);
            lerp_world_position = zmath.lerp(world_v0, world_v2, lerp);
            lerp_clip_position = zmath.lerp(clip_v0, clip_v2, lerp);
            lerp_normal = zmath.normalize3(zmath.lerp(n0, n2, lerp));
            lerp_color = if (tri_colors) |_| sdl.Color.rgba(
                @floatToInt(u8, @intToFloat(f32, c0.r) + (@intToFloat(f32, c2.r) - @intToFloat(f32, c0.r)) * lerp),
                @floatToInt(u8, @intToFloat(f32, c0.g) + (@intToFloat(f32, c2.g) - @intToFloat(f32, c0.g)) * lerp),
                @floatToInt(u8, @intToFloat(f32, c0.b) + (@intToFloat(f32, c2.b) - @intToFloat(f32, c0.b)) * lerp),
                @floatToInt(u8, @intToFloat(f32, c0.a) + (@intToFloat(f32, c2.a) - @intToFloat(f32, c0.a)) * lerp),
            ) else null;
            lerp_texcoord = if (tri_texcoords) |_| sdl.PointF{
                .x = t0.x + (t2.x - t0.x) * lerp,
                .y = t0.y + (t2.y - t0.y) * lerp,
            } else null;
            clip_vertices.appendAssumeCapacity(lerp_clip_position);
            world_positions.appendAssumeCapacity(lerp_world_position);
            world_normals.appendAssumeCapacity(lerp_normal);
            if (lerp_color) |c| clip_colors.appendAssumeCapacity(c);
            if (lerp_texcoord) |t| clip_texcoords.appendAssumeCapacity(t);
        }
    }
}

/// Draw batched triangles
pub inline fn drawTriangles(
    renderer: sdl.Renderer,
    indices: std.ArrayList(u32),
    vertices: std.ArrayList(sdl.Vertex),
    textures: std.ArrayList(?sdl.Texture),
    depths: std.ArrayList(f32),
    sorted: *bool,
) !void {
    const S = struct {
        var _depths: std.ArrayList(f32) = undefined;

        // Whether textures are same
        inline fn isSameTexture(tex0: ?sdl.Texture, tex1: ?sdl.Texture) bool {
            if (tex0 != null and tex1 != null) {
                return tex0.?.ptr == tex1.?.ptr;
            }
            return tex0 == null and tex1 == null;
        }

        // Sort triangles by depth values
        fn compareTriangleDepths(_: ?*anyopaque, lhs: [3]u32, rhs: [3]u32) bool {
            const d1 = (_depths.items[lhs[0]] + _depths.items[lhs[1]] + _depths.items[lhs[2]]) / 3.0;
            const d2 = (_depths.items[rhs[0]] + _depths.items[rhs[1]] + _depths.items[rhs[2]]) / 3.0;
            return d1 > d2;
        }
    };

    if (indices.items.len == 0) return;

    if (!sorted.*) {
        S._depths = depths;

        // Sort triangles by depth, from farthest to closest
        var _indices: [][3]u32 = undefined;
        _indices.ptr = @ptrCast([*][3]u32, indices.items.ptr);
        _indices.len = @divTrunc(indices.items.len, 3);
        std.sort.sort(
            [3]u32,
            _indices,
            @as(?*anyopaque, null),
            S.compareTriangleDepths,
        );
        sorted.* = true;
    }

    // Send in batches relying on same texture
    var offset: usize = 0;
    var last_texture: ?sdl.Texture = null;
    for (indices.items) |idx, i| {
        if (i > 0 and !S.isSameTexture(textures.items[idx], last_texture)) {
            try renderer.drawGeometry(
                last_texture,
                vertices.items,
                indices.items[offset..i],
            );
            offset = i;
        }
        last_texture = textures.items[idx];
    }
    try renderer.drawGeometry(
        last_texture,
        vertices.items,
        indices.items[offset..],
    );
}
