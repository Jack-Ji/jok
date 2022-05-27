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
    cull_faces: bool,
) !void {
    assert(@rem(indices.len, 3) == 0);
    assert(if (colors) |cs| cs.len == positions.len else true);
    assert(if (texcoords) |ts| ts.len == positions.len else true);
    if (indices.len == 0) return;
    const vp = renderer.getViewport();
    const mvp = zmath.mul(model, camera.getViewProjectMatrix());
    const base_index = @intCast(u32, self.vertices.items.len);
    var clipped_indices = std.StaticBitSet(std.math.maxInt(u16)).initEmpty();

    // Add vertices
    try self.vertices.ensureTotalCapacity(self.vertices.items.len + positions.len);
    try self.depths.ensureTotalCapacity(self.vertices.items.len + positions.len);
    for (positions) |pos, i| {
        // Do MVP transforming
        const pos_clip = zmath.mul(zmath.f32x4(pos[0], pos[1], pos[2], 1.0), mvp);
        const ndc = pos_clip / zmath.splat(zmath.Vec, pos_clip[3]);
        if ((ndc[0] < -1 or ndc[0] > 1) or
            (ndc[1] < -1 or ndc[1] > 1) or
            (ndc[2] < -1 or ndc[2] > 1))
        {
            clipped_indices.set(i);
        }
        self.vertices.appendAssumeCapacity(.{
            .position = .{
                .x = (1.0 + ndc[0]) * @intToFloat(f32, vp.width) / 2.0,
                .y = @intToFloat(f32, vp.height) - (1.0 + ndc[1]) * @intToFloat(f32, vp.height) / 2.0,
            },
            .color = if (colors) |cs| cs[i] else sdl.Color.white,
            .tex_coord = if (texcoords) |tex| .{ .x = tex[i][0], .y = tex[i][1] } else undefined,
        });
        self.depths.appendAssumeCapacity((1.0 + ndc[2]) / 2.0);
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

        // Ignore triangles completely outside of clip space
        if (clipped_indices.isSet(idx0) and
            clipped_indices.isSet(idx1) and
            clipped_indices.isSet(idx2))
        {
            const pos_clip0 = zmath.mul(zmath.f32x4(
                positions[idx0][0],
                positions[idx0][1],
                positions[idx0][2],
                1.0,
            ), mvp);
            const ndc0 = pos_clip0 / zmath.splat(zmath.Vec, pos_clip0[3]);
            const pos_clip1 = zmath.mul(zmath.f32x4(
                positions[idx1][0],
                positions[idx1][1],
                positions[idx1][2],
                1.0,
            ), mvp);
            const ndc1 = pos_clip1 / zmath.splat(zmath.Vec, pos_clip1[3]);
            const pos_clip2 = zmath.mul(zmath.f32x4(
                positions[idx2][0],
                positions[idx2][1],
                positions[idx2][2],
                1.0,
            ), mvp);
            const ndc2 = pos_clip2 / zmath.splat(zmath.Vec, pos_clip2[3]);
            if ((ndc0[0] < -1 and ndc1[0] < -1 and ndc2[0] < -1) or
                (ndc0[1] < -1 and ndc1[1] < -1 and ndc2[1] < -1) or
                (ndc0[2] < -1 and ndc1[2] < -1 and ndc2[2] < -1))
            {
                continue;
            }
        }

        // Ignore triangles facing away from camera (front faces' vertices are clock-wise organized)
        if (cull_faces) {
            const v0 = zmath.mul(zmath.f32x4(positions[idx0][0], positions[idx0][1], positions[idx0][2], 1), model);
            const v1 = zmath.mul(zmath.f32x4(positions[idx1][0], positions[idx1][1], positions[idx1][2], 1), model);
            const v2 = zmath.mul(zmath.f32x4(positions[idx2][0], positions[idx2][1], positions[idx2][2], 1), model);
            const center = (v0 + v1 + v2) / zmath.splat(zmath.Vec, 3.0);
            const v0v1 = v1 - v0;
            const v0v2 = v2 - v0;
            const face_dir = zmath.normalize3(zmath.cross3(v0v1, v0v2));
            const camera_dir = center - camera.position;
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

/// Sort triangles by depth values
fn compareTriangleDepths(self: *Self, lhs: [3]u32, rhs: [3]u32) bool {
    const d1 = (self.depths.items[lhs[0]] + self.depths.items[lhs[1]] + self.depths.items[lhs[2]]) / 3.0;
    const d2 = (self.depths.items[rhs[0]] + self.depths.items[rhs[1]] + self.depths.items[rhs[2]]) / 3.0;
    return d1 > d2;
}

/// Draw the meshes, fill triangles, using texture if possible
pub fn draw(self: *Self, renderer: sdl.Renderer, tex: ?sdl.Texture) !void {
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
