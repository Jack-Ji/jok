/// mesh data imported from zmesh.Shape and model file
const std = @import("std");
const assert = std.debug.assert;
const sdl = @import("sdl");
const jok = @import("../jok.zig");
const Vector = @import("Vector.zig");
const zmesh = jok.zmesh;
const Self = @This();

pub const Error = error{
    InvalidFormat,
};

indices: std.ArrayList(u16),
positions: std.ArrayList([3]f32),
normals: std.ArrayList([3]f32),
texcoords: std.ArrayList([2]f32),
aabb: ?[6]f32,
tex: ?sdl.Texture,
own_texture: bool,

pub fn init(allocator: std.mem.Allocator, tex: ?sdl.Texture) Self {
    return .{
        .indices = std.ArrayList(u16).init(allocator),
        .positions = std.ArrayList([3]f32).init(allocator),
        .normals = std.ArrayList([3]f32).init(allocator),
        .texcoords = std.ArrayList([2]f32).init(allocator),
        .aabb = null,
        .tex = tex,
        .own_texture = false,
    };
}

/// Init mesh with zmesh.Shape
pub const ShapeOption = struct {
    compute_aabb: bool = true,
    tex: ?sdl.Texture = null,
};
pub fn fromShape(
    allocator: std.mem.Allocator,
    shape: zmesh.Shape,
    opt: ShapeOption,
) !Self {
    var self = init(allocator, opt.tex);
    try self.indices.appendSlice(shape.indices);
    try self.positions.appendSlice(shape.positions);
    try self.normals.appendSlice(shape.normals.?);
    if (shape.texcoords) |ts| {
        try self.texcoords.appendSlice(ts);
    }
    if (opt.compute_aabb) self.computeAabb();
    return self;
}

/// Init mesh with GLTF model file
pub const GltfOption = struct {
    compute_aabb: bool = true,
};
pub fn fromGltf(
    allocator: std.mem.Allocator,
    rd: sdl.Renderer,
    file_path: [:0]const u8,
    opt: GltfOption,
) !Self {
    var self = init(allocator, null);
    const data = try zmesh.io.parseAndLoadFile(file_path);
    defer zmesh.io.freeData(data);

    var mesh_index: usize = 0;
    while (mesh_index < data.meshes_count) : (mesh_index += 1) {
        var prim_index: usize = 0;
        while (prim_index < data.meshes.?[mesh_index].primitives_count) : (prim_index += 1) {
            const mesh = &data.meshes.?[mesh_index];
            const prim = &mesh.primitives[prim_index];
            const num_vertices: u32 = @intCast(u32, prim.attributes[0].data.count);

            // Indices.
            if (prim.indices) |accessor| {
                const num_indices: u32 = @intCast(u32, accessor.count);
                try self.indices.ensureTotalCapacity(num_indices);

                const buffer_view = accessor.buffer_view.?;

                assert(accessor.stride == buffer_view.stride or buffer_view.stride == 0);
                assert(accessor.stride * accessor.count == buffer_view.size);
                assert(buffer_view.buffer.data != null);

                const data_addr = @alignCast(4, @ptrCast([*]const u8, buffer_view.buffer.data) +
                    accessor.offset + buffer_view.offset);

                if (accessor.stride == 1) {
                    assert(accessor.component_type == .r_8u);
                    const src = @ptrCast([*]const u8, data_addr);
                    var i: u32 = 0;
                    while (i < num_indices) : (i += 1) {
                        self.indices.appendAssumeCapacity(src[i]);
                    }
                } else if (accessor.stride == 2) {
                    assert(accessor.component_type == .r_16u);
                    const src = @ptrCast([*]const u16, data_addr);
                    var i: u32 = 0;
                    while (i < num_indices) : (i += 1) {
                        self.indices.appendAssumeCapacity(src[i]);
                    }
                } else if (accessor.stride == 4) {
                    assert(accessor.component_type == .r_32u);
                    const src = @ptrCast([*]const u32, data_addr);
                    var i: u32 = 0;
                    while (i < num_indices) : (i += 1) {
                        self.indices.appendAssumeCapacity(@intCast(u16, src[i]));
                    }
                } else {
                    unreachable;
                }
            } else {
                assert(@rem(num_vertices, 3) == 0);
                try self.indices.ensureTotalCapacity(num_vertices);
                var i: u32 = 0;
                while (i < num_vertices) : (i += 1) {
                    self.indices.appendAssumeCapacity(@intCast(u16, i));
                }
            }

            // Attributes.
            {
                const attributes = prim.attributes[0..prim.attributes_count];
                for (attributes) |attrib| {
                    const accessor = attrib.data;
                    const buffer_view = accessor.buffer_view.?;
                    assert(buffer_view.buffer.data != null);
                    assert(accessor.stride == buffer_view.stride or buffer_view.stride == 0);
                    assert(accessor.stride * accessor.count <= buffer_view.size);

                    const data_addr = @ptrCast([*]const u8, buffer_view.buffer.data) +
                        accessor.offset + buffer_view.offset;
                    if (attrib.type == .position) {
                        assert(accessor.type == .vec3);
                        assert(accessor.component_type == .r_32f);
                        const slice = @ptrCast([*]const [3]f32, @alignCast(4, data_addr))[0..num_vertices];
                        try self.positions.appendSlice(slice);
                    } else if (attrib.type == .normal) {
                        assert(accessor.type == .vec3);
                        assert(accessor.component_type == .r_32f);
                        const slice = @ptrCast([*]const [3]f32, @alignCast(4, data_addr))[0..num_vertices];
                        try self.normals.appendSlice(slice);
                    } else if (attrib.type == .texcoord) {
                        assert(accessor.type == .vec2);
                        assert(accessor.component_type == .r_32f);
                        const slice = @ptrCast([*]const [2]f32, @alignCast(4, data_addr))[0..num_vertices];
                        try self.texcoords.appendSlice(slice);
                    }
                }
            }
        }
    }
    if (data.images_count > 0) {
        const image = data.images.?[0];
        if (image.uri) |p| {
            // Read external file
            const uri_path = std.mem.sliceTo(p, '\x00');
            const dir = std.fs.path.dirname(file_path);
            self.tex = if (dir) |d| BLK: {
                const path = try std.fs.path.joinZ(
                    allocator,
                    &.{ d, uri_path },
                );
                defer allocator.free(path);
                break :BLK try jok.utils.gfx.createTextureFromFile(
                    rd,
                    path,
                    .static,
                    false,
                );
            } else try jok.utils.gfx.createTextureFromFile(
                rd,
                uri_path,
                .static,
                false,
            );
        } else if (image.buffer_view) |v| {
            // Read embedded file
            var file_data: []u8 = undefined;
            file_data.ptr = @ptrCast([*]u8, v.buffer.data.?) + v.offset;
            file_data.len = v.size;
            self.tex = try jok.utils.gfx.createTextureFromFileData(
                rd,
                file_data,
                .static,
                false,
            );
        }
        self.own_texture = true;
    }
    if (opt.compute_aabb) self.computeAabb();
    return self;
}

pub fn deinit(self: *Self) void {
    self.indices.deinit();
    self.positions.deinit();
    self.normals.deinit();
    self.texcoords.deinit();
    if (self.own_texture) self.tex.?.destroy();
    self.* = undefined;
}

/// Add new geometry data
pub fn appendTriangles(
    self: *Self,
    indices: []u16,
    positions: [][3]f32,
    normals: ?[][3]f32,
    texcoords: ?[][3]f32,
) !void {
    if (indices.len == 0) return;
    assert(@rem(indices.len, 3) == 0);
    assert(if (normals) |ns| positions.len == ns.len else true);
    assert(if (texcoords) |ts| positions.len == ts.len else true);
    if ((self.normals.items.len > 0 and normals == null) or
        (self.indices.items.len > 0 and self.normals.items.len == 0 and normals != null))
    {
        return error.InvalidFormat;
    }
    try self.indices.appendSlice(indices);
    try self.positions.appendSlice(positions);
    if (normals) |ns| try self.normals.appendSlice(ns);
    if (texcoords) |ts| try self.texcoords.appendSlice(ts);
}

/// Compute AABB of mesh
pub fn computeAabb(self: *Self) void {
    var aabb_min = Vector.new(
        self.positions.items[0][0],
        self.positions.items[0][1],
        self.positions.items[0][2],
    );
    var aabb_max = aabb_min;
    var i: usize = 1;
    while (i < self.positions.items.len) : (i += 1) {
        const v = Vector.new(
            self.positions.items[i][0],
            self.positions.items[i][1],
            self.positions.items[i][2],
        );
        aabb_min = aabb_min.min(v);
        aabb_max = aabb_max.max(v);
    }
    self.aabb = [6]f32{
        aabb_min.x(), aabb_min.y(), aabb_min.z(),
        aabb_max.x(), aabb_max.y(), aabb_max.z(),
    };
}

/// Remap texture coordinates to new range
pub fn remapTexcoords(self: *Self, uv0: sdl.PointF, uv1: sdl.PointF) void {
    for (self.texcoords.items) |*ts| {
        ts[0] = jok.utils.math.linearMap(ts[0], 0, 1, uv0.x, uv1.x);
        ts[1] = jok.utils.math.linearMap(ts[1], 0, 1, uv0.y, uv1.y);
    }
}
