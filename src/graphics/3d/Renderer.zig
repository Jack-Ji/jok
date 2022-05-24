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

/// Triangle vertices
vertices: std.ArrayList(sdl.Vertex),

pub fn init(allocator: std.mem.Allocator) Self {
    return .{
        .indices = std.ArrayList(u32).init(allocator),
        .vertices = std.ArrayList(sdl.Vertex).init(allocator),
    };
}

pub fn deinit(self: *Self) void {
    self.indices.deinit();
    self.vertices.deinit();
}

/// Clear mesh data
pub fn clearVertex(self: *Self, retain_memory: bool) void {
    if (retain_memory) {
        self.indices.clearRetainingCapacity();
        self.vertices.clearRetainingCapacity();
    } else {
        self.indices.clearAndFree();
        self.vertices.clearAndFree();
    }
}

/// Append vertex data
pub fn appendVertex(
    self: *Self,
    renderer: sdl.Renderer,
    model: zmath.Mat,
    camera: *Camera,
    indices: []u16,
    positions: [][3]f32,
    colors: ?[]sdl.Color,
    texcoords: ?[][2]f32,
    cull_faces: bool,
) !void {
    if (indices.len == 0) return;
    const vp = renderer.getViewport();
    const mv = zmath.mul(model, camera.getViewMatrix());
    const mvp = zmath.mul(model, camera.getViewProjectMatrix());
    const base_index = @intCast(u32, self.vertices.items.len);
    var clipped_indices = std.StaticBitSet(std.math.maxInt(u16)).initEmpty();

    // Add vertices
    try self.vertices.ensureTotalCapacity(self.vertices.items.len + positions.len);
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
    }
    errdefer self.vertices.resize(self.vertices.items.len - positions.len) catch unreachable;

    // Add indices
    try self.indices.ensureTotalCapacity(self.indices.items.len + indices.len);
    var i: usize = 2;
    while (i < indices.len) : (i += 3) {
        const idx0 = indices[i - 2];
        const idx1 = indices[i - 1];
        const idx2 = indices[i];

        // Ignore clipped triangles
        if (clipped_indices.isSet(idx0) and
            clipped_indices.isSet(idx1) and
            clipped_indices.isSet(idx2))
        {
            continue;
        }

        // Ignore triangles facing away from camera
        if (cull_faces) {
            const v0 = zmath.mul(zmath.f32x4(positions[idx0][0], positions[idx0][1], positions[idx0][2], 1), mv);
            const v1 = zmath.mul(zmath.f32x4(positions[idx1][0], positions[idx1][1], positions[idx1][2], 1), mv);
            const v2 = zmath.mul(zmath.f32x4(positions[idx2][0], positions[idx2][1], positions[idx2][2], 1), mv);
            const v1v0 = v1 - v0;
            const v2v0 = v2 - v0;
            const face_dir = zmath.cross3(v1v0, v2v0);
            const angles = zmath.dot3(face_dir, camera.dir);
            if (angles[0] > 0) continue;
        }

        // Append indices
        self.indices.appendSliceAssumeCapacity(&[_]u32{
            idx0 + base_index,
            idx1 + base_index,
            idx2 + base_index,
        });
    }
}

/// Draw the meshes, fill triangles, using texture if possible
pub fn draw(self: Self, renderer: sdl.Renderer, tex: ?sdl.Texture) !void {
    try renderer.drawGeometry(
        tex,
        self.vertices.items,
        self.indices.items,
    );
}

/// Draw the wireframe
pub fn drawWireframe(self: Self, renderer: sdl.Renderer, color: sdl.Color) !void {
    const old_color = try renderer.getColor();
    defer renderer.setColor(old_color) catch unreachable;

    try renderer.setColor(color);
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
