const std = @import("std");
const assert = std.debug.assert;
const math = std.math;
const jok = @import("../jok.zig");
const sdl = jok.sdl;
const imgui = jok.imgui;
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
            const r = @abs(axis[0]) + @abs(axis[1]) + @abs(axis[2]);

            const mm = jok.utils.math.minAndMax(p0, p1, p2);
            return @max(-mm[1], mm[0]) > r;
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
    if (@max(v0[0], @max(v1[0], v2[0])) < -1 or @min(v0[0], @min(v1[0], v2[0])) > 1) return true;
    if (@max(v0[1], @max(v1[1], v2[1])) < -1 or @min(v0[1], @min(v1[1], v2[1])) > 1) return true;
    if (@max(v0[2], @max(v1[2], v2[2])) < -1 or @min(v0[2], @min(v1[2], v2[2])) > 1) return true;

    // Finally, test if AABB intersects triangle plane
    const plane_n = zmath.normalize3(zmath.cross3(f0, f1));
    const r = @abs(plane_n[0]) + @abs(plane_n[1]) + @abs(plane_n[2]);
    return @abs(zmath.dot3(plane_n, v0)[0]) > r;
}

/// Clip triangle in homogeneous space, against panel w=0.0001
/// We are conceptually clipping away stuff behind camera
pub inline fn clipTriangle(
    tri_world_positions: []const zmath.Vec,
    tri_clip_positions: []const zmath.Vec,
    tri_world_normals: ?[3]zmath.Vec,
    tri_colors: ?[3]sdl.Color,
    tri_texcoords: ?[3]sdl.PointF,
    clip_vertices: *std.ArrayList(zmath.Vec),
    clip_colors: *std.ArrayList(sdl.Color),
    clip_texcoords: *std.ArrayList(sdl.PointF),
    world_positions: *std.ArrayList(zmath.Vec),
    world_normals: *std.ArrayList(zmath.Vec),
) void {
    const clip_plane_w = 0.001;
    var world_v0 = tri_world_positions[0];
    var world_v1 = tri_world_positions[1];
    var world_v2 = tri_world_positions[2];
    var clip_v0 = tri_clip_positions[0];
    var clip_v1 = tri_clip_positions[1];
    var clip_v2 = tri_clip_positions[2];
    var d_v0 = clip_v0[3] - clip_plane_w;
    var d_v1 = clip_v1[3] - clip_plane_w;
    var d_v2 = clip_v2[3] - clip_plane_w;
    var is_v0_inside = d_v0 >= 0;
    var is_v1_inside = d_v1 >= 0;
    var is_v2_inside = d_v2 >= 0;
    var n0: zmath.Vec = undefined;
    var n1: zmath.Vec = undefined;
    var n2: zmath.Vec = undefined;
    if (tri_world_normals) |ns| {
        n0 = ns[0];
        n1 = ns[1];
        n2 = ns[2];
    }
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
        std.mem.swap(f32, &d_v0, &d_v1);
        std.mem.swap(f32, &d_v1, &d_v2);
        std.mem.swap(bool, &is_v0_inside, &is_v1_inside);
        std.mem.swap(bool, &is_v1_inside, &is_v2_inside);
        if (tri_world_normals != null) {
            std.mem.swap(zmath.Vec, &n0, &n1);
            std.mem.swap(zmath.Vec, &n1, &n2);
        }
        if (tri_colors != null) {
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
        std.mem.swap(f32, &d_v1, &d_v2);
        std.mem.swap(f32, &d_v0, &d_v1);
        std.mem.swap(bool, &is_v1_inside, &is_v2_inside);
        std.mem.swap(bool, &is_v0_inside, &is_v1_inside);
        if (tri_world_normals != null) {
            std.mem.swap(zmath.Vec, &n1, &n2);
            std.mem.swap(zmath.Vec, &n0, &n1);
        }
        if (tri_colors != null) {
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
    if (tri_world_normals != null) world_normals.appendAssumeCapacity(n0);
    if (tri_colors != null) clip_colors.appendAssumeCapacity(c0);
    if (tri_texcoords != null) clip_texcoords.appendAssumeCapacity(t0);

    // Clip next 2 vertices, depending on their positions
    if (is_v1_inside) {
        clip_vertices.appendAssumeCapacity(clip_v1);
        world_positions.appendAssumeCapacity(world_v1);
        if (tri_world_normals != null) world_normals.appendAssumeCapacity(n1);
        if (tri_colors != null) clip_colors.appendAssumeCapacity(c1);
        if (tri_texcoords != null) clip_texcoords.appendAssumeCapacity(t1);

        if (is_v2_inside) {
            clip_vertices.appendAssumeCapacity(clip_v2);
            world_positions.appendAssumeCapacity(world_v2);
            if (tri_world_normals != null) world_normals.appendAssumeCapacity(n2);
            if (tri_colors != null) clip_colors.appendAssumeCapacity(c2);
            if (tri_texcoords != null) clip_texcoords.appendAssumeCapacity(t2);
        } else {
            // First triangle
            var lerp = d_v1 / (d_v1 - d_v2);
            assert(lerp >= 0 and lerp <= 1);
            var lerp_world_position = zmath.lerp(world_v1, world_v2, lerp);
            var lerp_clip_position = zmath.lerp(clip_v1, clip_v2, lerp);
            var lerp_normal: ?zmath.Vec = if (tri_world_normals != null)
                zmath.normalize3(zmath.lerp(n1, n2, lerp))
            else
                null;
            var lerp_color: ?sdl.Color = if (tri_colors) |_| sdl.Color.rgba(
                @intFromFloat(@as(f32, @floatFromInt(c1.r)) + (@as(f32, @floatFromInt(c2.r)) - @as(f32, @floatFromInt(c1.r))) * lerp),
                @intFromFloat(@as(f32, @floatFromInt(c1.g)) + (@as(f32, @floatFromInt(c2.g)) - @as(f32, @floatFromInt(c1.g))) * lerp),
                @intFromFloat(@as(f32, @floatFromInt(c1.b)) + (@as(f32, @floatFromInt(c2.b)) - @as(f32, @floatFromInt(c1.b))) * lerp),
                @intFromFloat(@as(f32, @floatFromInt(c1.a)) + (@as(f32, @floatFromInt(c2.a)) - @as(f32, @floatFromInt(c1.a))) * lerp),
            ) else null;
            var lerp_texcoord: ?sdl.PointF = if (tri_texcoords) |_| sdl.PointF{
                .x = t1.x + (t2.x - t1.x) * lerp,
                .y = t1.y + (t2.y - t1.y) * lerp,
            } else null;
            clip_vertices.appendAssumeCapacity(lerp_clip_position);
            world_positions.appendAssumeCapacity(lerp_world_position);
            if (lerp_normal) |n| world_normals.appendAssumeCapacity(n);
            if (lerp_color) |c| clip_colors.appendAssumeCapacity(c);
            if (lerp_texcoord) |t| clip_texcoords.appendAssumeCapacity(t);

            // Second triangle
            clip_vertices.appendAssumeCapacity(clip_v0);
            world_positions.appendAssumeCapacity(world_v0);
            if (tri_world_normals != null) world_normals.appendAssumeCapacity(n0);
            if (tri_colors != null) clip_colors.appendAssumeCapacity(c0);
            if (tri_texcoords != null) clip_texcoords.appendAssumeCapacity(t0);
            clip_vertices.appendAssumeCapacity(lerp_clip_position);
            world_positions.appendAssumeCapacity(lerp_world_position);
            if (lerp_normal) |n| world_normals.appendAssumeCapacity(n);
            if (lerp_color) |c| clip_colors.appendAssumeCapacity(c);
            if (lerp_texcoord) |t| clip_texcoords.appendAssumeCapacity(t);
            lerp = d_v0 / (d_v0 - d_v2);
            assert(lerp >= 0 and lerp <= 1);
            lerp_world_position = zmath.lerp(world_v0, world_v2, lerp);
            lerp_clip_position = zmath.lerp(clip_v0, clip_v2, lerp);
            lerp_normal = if (tri_world_normals != null)
                zmath.normalize3(zmath.lerp(n0, n2, lerp))
            else
                null;
            lerp_color = if (tri_colors != null) sdl.Color.rgba(
                @intFromFloat(@as(f32, @floatFromInt(c0.r)) + (@as(f32, @floatFromInt(c2.r)) - @as(f32, @floatFromInt(c0.r))) * lerp),
                @intFromFloat(@as(f32, @floatFromInt(c0.g)) + (@as(f32, @floatFromInt(c2.g)) - @as(f32, @floatFromInt(c0.g))) * lerp),
                @intFromFloat(@as(f32, @floatFromInt(c0.b)) + (@as(f32, @floatFromInt(c2.b)) - @as(f32, @floatFromInt(c0.b))) * lerp),
                @intFromFloat(@as(f32, @floatFromInt(c0.a)) + (@as(f32, @floatFromInt(c2.a)) - @as(f32, @floatFromInt(c0.a))) * lerp),
            ) else null;
            lerp_texcoord = if (tri_texcoords != null) sdl.PointF{
                .x = t0.x + (t2.x - t0.x) * lerp,
                .y = t0.y + (t2.y - t0.y) * lerp,
            } else null;
            clip_vertices.appendAssumeCapacity(lerp_clip_position);
            world_positions.appendAssumeCapacity(lerp_world_position);
            if (lerp_normal) |n| world_normals.appendAssumeCapacity(n);
            if (lerp_color) |c| clip_colors.appendAssumeCapacity(c);
            if (lerp_texcoord) |t| clip_texcoords.appendAssumeCapacity(t);
        }
    } else {
        var lerp = d_v0 / (d_v0 - d_v1);
        assert(lerp >= 0 and lerp <= 1);
        var lerp_world_position = zmath.lerp(world_v0, world_v1, lerp);
        var lerp_clip_position = zmath.lerp(clip_v0, clip_v1, lerp);
        var lerp_normal: ?zmath.Vec = if (tri_world_normals != null)
            zmath.normalize3(zmath.lerp(n0, n1, lerp))
        else
            null;
        var lerp_color: ?sdl.Color = if (tri_colors != null) sdl.Color.rgba(
            @intFromFloat(@as(f32, @floatFromInt(c0.r)) + (@as(f32, @floatFromInt(c1.r)) - @as(f32, @floatFromInt(c0.r))) * lerp),
            @intFromFloat(@as(f32, @floatFromInt(c0.g)) + (@as(f32, @floatFromInt(c1.g)) - @as(f32, @floatFromInt(c0.g))) * lerp),
            @intFromFloat(@as(f32, @floatFromInt(c0.b)) + (@as(f32, @floatFromInt(c1.b)) - @as(f32, @floatFromInt(c0.b))) * lerp),
            @intFromFloat(@as(f32, @floatFromInt(c0.a)) + (@as(f32, @floatFromInt(c1.a)) - @as(f32, @floatFromInt(c0.a))) * lerp),
        ) else null;
        var lerp_texcoord: ?sdl.PointF = if (tri_texcoords != null) sdl.PointF{
            .x = t0.x + (t1.x - t0.x) * lerp,
            .y = t0.y + (t1.y - t0.y) * lerp,
        } else null;
        clip_vertices.appendAssumeCapacity(lerp_clip_position);
        world_positions.appendAssumeCapacity(lerp_world_position);
        if (lerp_normal) |n| world_normals.appendAssumeCapacity(n);
        if (lerp_color) |c| clip_colors.appendAssumeCapacity(c);
        if (lerp_texcoord) |t| clip_texcoords.appendAssumeCapacity(t);

        if (is_v2_inside) {
            // First triangle
            lerp = d_v1 / (d_v1 - d_v2);
            assert(lerp >= 0 and lerp <= 1);
            lerp_world_position = zmath.lerp(world_v1, world_v2, lerp);
            lerp_clip_position = zmath.lerp(clip_v1, clip_v2, lerp);
            lerp_normal = if (tri_world_normals != null)
                zmath.normalize3(zmath.lerp(n1, n2, lerp))
            else
                null;
            lerp_color = if (tri_colors != null) sdl.Color.rgba(
                @intFromFloat(@as(f32, @floatFromInt(c1.r)) + (@as(f32, @floatFromInt(c2.r)) - @as(f32, @floatFromInt(c1.r))) * lerp),
                @intFromFloat(@as(f32, @floatFromInt(c1.g)) + (@as(f32, @floatFromInt(c2.g)) - @as(f32, @floatFromInt(c1.g))) * lerp),
                @intFromFloat(@as(f32, @floatFromInt(c1.b)) + (@as(f32, @floatFromInt(c2.b)) - @as(f32, @floatFromInt(c1.b))) * lerp),
                @intFromFloat(@as(f32, @floatFromInt(c1.a)) + (@as(f32, @floatFromInt(c2.a)) - @as(f32, @floatFromInt(c1.a))) * lerp),
            ) else null;
            lerp_texcoord = if (tri_texcoords != null) sdl.PointF{
                .x = t1.x + (t2.x - t1.x) * lerp,
                .y = t1.y + (t2.y - t1.y) * lerp,
            } else null;
            clip_vertices.appendAssumeCapacity(lerp_clip_position);
            world_positions.appendAssumeCapacity(lerp_world_position);
            if (lerp_normal) |n| world_normals.appendAssumeCapacity(n);
            if (lerp_color) |c| clip_colors.appendAssumeCapacity(c);
            if (lerp_texcoord) |t| clip_texcoords.appendAssumeCapacity(t);

            // Second triangle
            clip_vertices.appendAssumeCapacity(clip_v0);
            world_positions.appendAssumeCapacity(world_v0);
            if (tri_world_normals != null) world_normals.appendAssumeCapacity(n0);
            if (tri_colors != null) clip_colors.appendAssumeCapacity(c0);
            if (tri_texcoords != null) clip_texcoords.appendAssumeCapacity(t0);
            clip_vertices.appendAssumeCapacity(lerp_clip_position);
            world_positions.appendAssumeCapacity(lerp_world_position);
            if (lerp_normal) |n| world_normals.appendAssumeCapacity(n);
            if (lerp_color) |c| clip_colors.appendAssumeCapacity(c);
            if (lerp_texcoord) |t| clip_texcoords.appendAssumeCapacity(t);
            clip_vertices.appendAssumeCapacity(clip_v2);
            world_positions.appendAssumeCapacity(world_v2);
            if (tri_world_normals != null) world_normals.appendAssumeCapacity(n2);
            if (tri_colors != null) clip_colors.appendAssumeCapacity(c2);
            if (tri_texcoords != null) clip_texcoords.appendAssumeCapacity(t2);
        } else {
            lerp = d_v0 / (d_v0 - d_v2);
            assert(lerp >= 0 and lerp <= 1);
            lerp_world_position = zmath.lerp(world_v0, world_v2, lerp);
            lerp_clip_position = zmath.lerp(clip_v0, clip_v2, lerp);
            lerp_normal = if (tri_world_normals != null)
                zmath.normalize3(zmath.lerp(n0, n2, lerp))
            else
                null;
            lerp_color = if (tri_colors != null) sdl.Color.rgba(
                @intFromFloat(@as(f32, @floatFromInt(c0.r)) + (@as(f32, @floatFromInt(c2.r)) - @as(f32, @floatFromInt(c0.r))) * lerp),
                @intFromFloat(@as(f32, @floatFromInt(c0.g)) + (@as(f32, @floatFromInt(c2.g)) - @as(f32, @floatFromInt(c0.g))) * lerp),
                @intFromFloat(@as(f32, @floatFromInt(c0.b)) + (@as(f32, @floatFromInt(c2.b)) - @as(f32, @floatFromInt(c0.b))) * lerp),
                @intFromFloat(@as(f32, @floatFromInt(c0.a)) + (@as(f32, @floatFromInt(c2.a)) - @as(f32, @floatFromInt(c0.a))) * lerp),
            ) else null;
            lerp_texcoord = if (tri_texcoords != null) sdl.PointF{
                .x = t0.x + (t2.x - t0.x) * lerp,
                .y = t0.y + (t2.y - t0.y) * lerp,
            } else null;
            clip_vertices.appendAssumeCapacity(lerp_clip_position);
            world_positions.appendAssumeCapacity(lerp_world_position);
            if (lerp_normal) |n| world_normals.appendAssumeCapacity(n);
            if (lerp_color) |c| clip_colors.appendAssumeCapacity(c);
            if (lerp_texcoord) |t| clip_texcoords.appendAssumeCapacity(t);
        }
    }
}

/// Whether textures are same
pub inline fn isSameTexture(tex0: ?sdl.Texture, tex1: ?sdl.Texture) bool {
    if (tex0 != null and tex1 != null) {
        return tex0.?.ptr == tex1.?.ptr;
    }
    return tex0 == null and tex1 == null;
}

/// Triangle sorting method
pub const TriangleSort = union(enum) {
    // Send to gpu directly
    none,

    // Simple solution: sort by average depth
    simple,

    // Complex but better looking: group into subrectangles, then sort and merge
    group_merge: u8,
};

/// Target for storing rendering result
pub const RenderTarget = struct {
    const max_group_merge = 5;
    const max_group_size = math.pow(usize, 2, max_group_merge) *
        math.pow(usize, 2, max_group_merge);

    triangle_sort: TriangleSort,
    wireframe_color: ?sdl.Color,
    triangle_groups: [max_group_size]std.ArrayList(u32),
    indices: std.ArrayList(u32),
    batched_indices: std.ArrayList(u32),
    vertices: std.ArrayList(sdl.Vertex),
    depths: std.ArrayList(f32),
    textures: std.ArrayList(?sdl.Texture),
    draw_list: imgui.DrawList,

    pub fn init(_allocator: std.mem.Allocator) RenderTarget {
        var target = RenderTarget{
            .triangle_sort = .none,
            .wireframe_color = null,
            .triangle_groups = undefined,
            .indices = std.ArrayList(u32).init(_allocator),
            .batched_indices = std.ArrayList(u32).init(_allocator),
            .vertices = std.ArrayList(sdl.Vertex).init(_allocator),
            .depths = std.ArrayList(f32).init(_allocator),
            .textures = std.ArrayList(?sdl.Texture).init(_allocator),
            .draw_list = imgui.createDrawList(),
        };
        for (&target.triangle_groups) |*g| g.* = std.ArrayList(u32).init(_allocator);
        return target;
    }

    pub fn deinit(self: *RenderTarget) void {
        for (self.triangle_groups) |g| g.deinit();
        self.indices.deinit();
        self.batched_indices.deinit();
        self.vertices.deinit();
        self.depths.deinit();
        self.textures.deinit();
        imgui.destroyDrawList(self.draw_list);
        self.* = undefined;
    }

    pub fn reset(
        self: *RenderTarget,
        rd: sdl.Renderer,
        wireframe_color: ?sdl.Color,
        triangle_sort: TriangleSort,
        recycle_memory: bool,
    ) void {
        const output_size = rd.getOutputSize() catch unreachable;
        self.wireframe_color = wireframe_color;
        if (self.wireframe_color != null) {
            self.triangle_sort = .none;
        } else {
            self.triangle_sort = triangle_sort;
            if (triangle_sort == .group_merge) {
                if (triangle_sort.group_merge > max_group_merge) {
                    @panic("Invalid group-merge value!");
                }
                if (triangle_sort.group_merge == 0) {
                    self.triangle_sort = .simple;
                } else {
                    for (0..triangle_sort.group_merge) |i| {
                        self.triangle_groups[i].clearRetainingCapacity();
                    }
                }
            }
        }
        self.draw_list.reset();
        self.draw_list.pushClipRect(.{
            .pmin = .{ 0, 0 },
            .pmax = .{
                @as(f32, @floatFromInt(output_size.width_pixels)),
                @as(f32, @floatFromInt(output_size.height_pixels)),
            },
        });
        self.draw_list.setDrawListFlags(.{
            .anti_aliased_lines = true,
            .anti_aliased_lines_use_tex = false,
            .anti_aliased_fill = true,
            .allow_vtx_offset = true,
        });
        if (recycle_memory) {
            for (&self.triangle_groups) |*g| g.clearAndFree();
            self.indices.clearAndFree();
            self.batched_indices.clearAndFree();
            self.vertices.clearAndFree();
            self.depths.clearAndFree();
            self.textures.clearAndFree();
            self.draw_list.clearMemory();
        } else {
            self.indices.clearRetainingCapacity();
            self.batched_indices.clearRetainingCapacity();
            self.vertices.clearRetainingCapacity();
            self.depths.clearRetainingCapacity();
            self.textures.clearRetainingCapacity();
        }
    }

    // Compare triangles by average depth
    fn compareTrianglesByDepth(self: *RenderTarget, lhs: [3]u32, rhs: [3]u32) bool {
        const l_idx0 = lhs[0];
        const l_idx1 = lhs[1];
        const l_idx2 = lhs[2];
        const r_idx0 = rhs[0];
        const r_idx1 = rhs[1];
        const r_idx2 = rhs[2];
        const d0 = (self.depths.items[l_idx0] + self.depths.items[l_idx1] + self.depths.items[l_idx2]) / 3.0;
        const d1 = (self.depths.items[r_idx0] + self.depths.items[r_idx1] + self.depths.items[r_idx2]) / 3.0;
        return d0 > d1;
    }

    fn sortTriangles(self: *RenderTarget, indices: []u32) void {
        assert(@rem(indices.len, 3) == 0);
        var _indices: [][3]u32 = undefined;
        _indices.ptr = @ptrCast(indices.ptr);
        _indices.len = @divTrunc(indices.len, 3);
        std.sort.pdq(
            [3]u32,
            _indices,
            self,
            RenderTarget.compareTrianglesByDepth,
        );
    }

    inline fn drawTriangles(self: RenderTarget, rd: sdl.Renderer, color: sdl.Color) !void {
        const col = imgui.sdl.convertColor(color);
        var i: u32 = 0;
        while (i < self.indices.items.len) : (i += 3) {
            const v0 = self.vertices.items[self.indices.items[i]];
            const v1 = self.vertices.items[self.indices.items[i + 1]];
            const v2 = self.vertices.items[self.indices.items[i + 2]];
            self.draw_list.addTriangle(.{
                .p1 = .{ v0.position.x, v0.position.y },
                .p2 = .{ v1.position.x, v1.position.y },
                .p3 = .{ v2.position.x, v2.position.y },
                .col = col,
            });
        }
        try imgui.sdl.renderDrawList(rd, self.draw_list);
    }

    inline fn fillTriangles(self: *RenderTarget, rd: sdl.Renderer) !void {
        switch (self.triangle_sort) {
            .none => {
                // Send pre-batched vertices
                var offset: u32 = 0;
                for (self.batched_indices.items) |size| {
                    assert(size % 3 == 0);
                    try rd.drawGeometry(
                        self.textures.items[self.indices.items[offset]],
                        self.vertices.items,
                        self.indices.items[offset .. offset + size],
                    );
                    offset += size;
                }
                assert(offset == @as(u32, @intCast(self.indices.items.len)));
            },
            .simple => {
                // Sort triangles by average depth
                self.sortTriangles(self.indices.items);

                // Scan vertices and send them in batches
                var offset: usize = 0;
                var last_texture: ?sdl.Texture = null;
                var i: usize = 0;
                while (i < self.indices.items.len) : (i += 3) {
                    const idx = self.indices.items[i];
                    if (i > 0 and !isSameTexture(self.textures.items[idx], last_texture)) {
                        try rd.drawGeometry(
                            last_texture,
                            self.vertices.items,
                            self.indices.items[offset..i],
                        );
                        offset = i;
                    }
                    last_texture = self.textures.items[idx];
                }
                try rd.drawGeometry(
                    last_texture,
                    self.vertices.items,
                    self.indices.items[offset..],
                );
            },
            .group_merge => |m| {
                _ = m;
            },
        }
    }

    pub fn submit(self: *RenderTarget, rd: sdl.Renderer) !void {
        if (self.wireframe_color) |c| {
            try self.drawTriangles(rd, c);
        } else {
            try self.fillTriangles(rd);
        }
    }

    pub fn reserveCapacity(self: *RenderTarget, idx_size: usize, vtx_size: usize) !void {
        try self.indices.ensureTotalCapacity(self.indices.items.len + idx_size);
        try self.vertices.ensureTotalCapacity(self.vertices.items.len + vtx_size);
        try self.depths.ensureTotalCapacity(self.depths.items.len + vtx_size);
        try self.textures.ensureTotalCapacity(self.textures.items.len + vtx_size);
    }

    pub fn appendTrianglesAssumeCapacity(
        self: *RenderTarget,
        indices: []const u32,
        vertices: []const sdl.Vertex,
        depths: []const f32,
        texture: ?sdl.Texture,
    ) !void {
        assert(@rem(indices.len, 3) == 0);
        assert(vertices.len == depths.len);

        switch (self.triangle_sort) {
            .none => {
                if (self.batched_indices.items.len == 0) {
                    try self.batched_indices.append(@intCast(indices.len));
                } else {
                    const last_texture = self.textures.items[self.textures.items.len - 1];
                    if (isSameTexture(last_texture, texture)) {
                        self.batched_indices.items[self.batched_indices.items.len - 1] += @intCast(indices.len);
                    } else {
                        try self.batched_indices.append(@intCast(indices.len));
                    }
                }

                const current_index: u32 = @intCast(self.vertices.items.len);
                for (indices) |idx| {
                    self.indices.appendAssumeCapacity(idx + current_index);
                }
                self.vertices.appendSliceAssumeCapacity(vertices);
                self.depths.appendSliceAssumeCapacity(depths);
                self.textures.appendNTimesAssumeCapacity(texture, vertices.len);
            },
            .simple => {
                const current_index: u32 = @intCast(self.vertices.items.len);
                for (indices) |idx| {
                    self.indices.appendAssumeCapacity(idx + current_index);
                }
                self.vertices.appendSliceAssumeCapacity(vertices);
                self.depths.appendSliceAssumeCapacity(depths);
                self.textures.appendNTimesAssumeCapacity(texture, vertices.len);
            },
            .group_merge => |m| {
                _ = m;
            },
        }
    }
};
