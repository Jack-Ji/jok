/// mesh data imported from zmesh.Shape and model file
const std = @import("std");
const assert = std.debug.assert;
const sdl = @import("sdl");
const jok = @import("../jok.zig");
const Vector = @import("Vector.zig");
const zmath = jok.zmath;
const zmesh = jok.zmesh;
const Self = @This();

pub const Error = error{
    InvalidFormat,
};

pub const SubMesh = struct {
    pub const SubSubMesh = struct {
        mesh: *Self,
        indices: std.ArrayList(u32),
        positions: std.ArrayList([3]f32),
        normals: std.ArrayList([3]f32),
        colors: std.ArrayList(sdl.Color),
        texcoords: std.ArrayList([2]f32),
        aabb: ?[6]f32,
        tex_id: usize,

        pub fn init(allocator: std.mem.Allocator, mesh: *Self) SubSubMesh {
            return .{
                .mesh = mesh,
                .indices = std.ArrayList(u32).init(allocator),
                .positions = std.ArrayList([3]f32).init(allocator),
                .normals = std.ArrayList([3]f32).init(allocator),
                .colors = std.ArrayList(sdl.Color).init(allocator),
                .texcoords = std.ArrayList([2]f32).init(allocator),
                .aabb = null,
                .tex_id = 0,
            };
        }

        /// Add new geometry data
        pub fn appendTriangles(
            self: *SubSubMesh,
            indices: []u32,
            positions: [][3]f32,
            normals: ?[][3]f32,
            colors: ?[]sdl.Color,
            texcoords: ?[][2]f32,
        ) !void {
            if (indices.len == 0) return;
            assert(@rem(indices.len, 3) == 0);
            assert(if (normals) |ns| positions.len == ns.len else true);
            assert(if (texcoords) |ts| positions.len == ts.len else true);
            if ((self.normals.items.len > 0 and normals == null) or
                (self.indices.items.len > 0 and self.normals.items.len == 0 and normals != null) or
                (self.colors.items.len > 0 and colors == null) or
                (self.indices.items.len > 0 and self.colors.items.len == 0 and colors != null) or
                (self.texcoords.items.len > 0 and texcoords == null) or
                (self.indices.items.len > 0 and self.texcoords.items.len == 0 and texcoords != null))
            {
                return error.InvalidFormat;
            }
            const index_offset = @intCast(u32, self.positions.items.len);
            try self.indices.ensureTotalCapacity(self.indices.items.len + indices.len);
            for (indices) |idx| self.indices.appendAssumeCapacity(idx + index_offset);
            try self.positions.appendSlice(positions);
            if (normals) |ns| try self.normals.appendSlice(ns);
            if (colors) |cs| try self.colors.appendSlice(cs);
            if (texcoords) |ts| try self.texcoords.appendSlice(ts);
        }

        /// Compute AABB of mesh
        pub fn computeAabb(self: *SubSubMesh) void {
            var aabb_min = Vector.new(
                self.positions.items[0][0],
                self.positions.items[0][1],
                self.positions.items[0][2],
            );
            var aabb_max = aabb_min;
            for (0..self.positions.items.len) |i| {
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
        pub fn remapTexcoords(self: *SubSubMesh, uv0: sdl.PointF, uv1: sdl.PointF) void {
            for (self.texcoords.items) |*ts| {
                ts[0] = jok.utils.math.linearMap(ts[0], 0, 1, uv0.x, uv1.x);
                ts[1] = jok.utils.math.linearMap(ts[1], 0, 1, uv0.y, uv1.y);
            }
        }

        /// Get texture
        pub fn getTexture(self: *const SubSubMesh) ?sdl.Texture {
            return self.mesh.textures.get(self.tex_id);
        }
    };

    children: std.ArrayList(*SubMesh),
    local_transform: zmath.Mat,
    global_transform: zmath.Mat,
    meshes: []SubSubMesh,

    fn init(allocator: std.mem.Allocator, mesh: *Self, mesh_count: usize) !SubMesh {
        var self = SubMesh{
            .children = std.ArrayList(*SubMesh).init(allocator),
            .local_transform = zmath.identity(),
            .global_transform = zmath.identity(),
            .meshes = try allocator.alloc(SubSubMesh, mesh_count),
        };
        for (self.meshes) |*m| m.* = SubSubMesh.init(allocator, mesh);
        return self;
    }
};

allocator: std.mem.Allocator,
arena: std.heap.ArenaAllocator,
root: *SubMesh,
textures: std.AutoHashMap(usize, sdl.Texture),
own_textures: bool,

pub fn create(allocator: std.mem.Allocator, mesh_count: usize) !*Self {
    var self = try allocator.create(Self);
    errdefer allocator.destroy(self);
    self.allocator = allocator;
    self.arena = std.heap.ArenaAllocator.init(allocator);
    self.root = try self.createSubMesh(null, mesh_count);
    self.textures = std.AutoHashMap(usize, sdl.Texture).init(self.arena.allocator());
    self.own_textures = false;
    return self;
}

/// Create mesh with zmesh.Shape
pub const ShapeOption = struct {
    compute_aabb: bool = true,
    tex: ?sdl.Texture = null,
    uvs: ?[2]sdl.PointF = null,
};
pub fn fromShape(
    allocator: std.mem.Allocator,
    shape: zmesh.Shape,
    opt: ShapeOption,
) !*Self {
    var self = try create(allocator, 1);
    errdefer self.destroy();
    try self.root.primitives[0].appendTriangles(
        shape.indices,
        shape.positions,
        shape.normals,
        null,
        shape.texcoords,
    );
    if (shape.texcoords != null) {
        if (opt.tex) |t| {
            const tex_id = @ptrToInt(t.ptr);
            self.root.tex_id = tex_id;
            try self.textures.put(tex_id, t);
            if (opt.uvs != null) {
                self.root.primitives[0].remapTexcoords(opt.uvs.?[0], opt.uvs.?[1]);
            }
        }
    }
    if (opt.compute_aabb) self.root.computeAabb();
    return self;
}

/// Create mesh with GLTF model file
pub const GltfOption = struct {
    compute_aabb: bool = true,
    tex: ?sdl.Texture = null,
    uvs: ?[2]sdl.PointF = null,
};
pub fn fromGltf(
    allocator: std.mem.Allocator,
    rd: sdl.Renderer,
    file_path: [:0]const u8,
    opt: GltfOption,
) !*Self {
    const data = try zmesh.io.parseAndLoadFile(file_path);
    defer zmesh.io.freeData(data);

    var self = try create(allocator, 0);
    errdefer self.destroy();

    if (opt.tex) |t| { // Use external texture
        const tex_id = @ptrToInt(t.ptr);
        try self.textures.put(tex_id, t);
    } else {
        self.own_textures = true;
    }

    // Load the scene/nodes
    const dir = std.fs.path.dirname(file_path);
    var node_index: usize = 0;
    while (node_index < data.scene.?.nodes_count) : (node_index += 1) {
        try self.loadNodeTree(rd, dir, data.scene.?.nodes.?[node_index], self.root, opt);
    }
    return self;
}

pub fn destroy(self: *Self) void {
    if (self.own_textures) {
        var it = self.textures.iterator();
        while (it.next()) |kv| {
            kv.value_ptr.destroy();
        }
    }
    self.arena.deinit();
    self.allocator.destroy(self);
}

pub fn createSubMesh(self: *Self, parent: ?*SubMesh, mesh_count: usize) !*SubMesh {
    const allocator = self.arena.allocator();
    var m = try allocator.create(SubMesh);
    errdefer allocator.destroy(m);
    m.* = try SubMesh.init(allocator, self, mesh_count);
    if (parent) |p| try p.children.append(m);
    return m;
}

fn loadNodeTree(
    self: *Self,
    rd: sdl.Renderer,
    dir: ?[]const u8,
    node: *zmesh.io.zcgltf.Node,
    parent: *SubMesh,
    opt: GltfOption,
) !void {
    var m = try self.createSubMesh(parent, if (node.mesh) |mesh| mesh.primitives_count else 0);

    // Load transforms
    m.local_transform = zmath.loadMat(&node.transformLocal());
    m.global_transform = zmath.loadMat(&node.transformWorld());

    if (node.mesh) |mesh| {
        for (0..mesh.primitives_count, m.meshes) |prim_index, *ssm| {
            const prim = &mesh.primitives[prim_index];

            // Load material
            var transform: ?zmesh.io.zcgltf.TextureTransform = null;
            if (opt.tex) |t| {
                ssm.tex_id = @ptrToInt(t.ptr);
                if (opt.uvs != null) {
                    ssm.remapTexcoords(opt.uvs.?[0], opt.uvs.?[1]);
                }
            } else if (prim.material) |mat| {
                if (mat.has_pbr_metallic_roughness != 0 and
                    mat.pbr_metallic_roughness.base_color_texture.texture != null)
                {
                    const image = mat.pbr_metallic_roughness.base_color_texture.texture.?.image.?;
                    ssm.tex_id = @ptrToInt(image);
                    assert(ssm.tex_id != 0);

                    // Lazily load textures
                    if (self.textures.get(ssm.tex_id) == null) {
                        var tex: sdl.Texture = undefined;
                        if (image.uri) |p| { // Read external file
                            const uri_path = std.mem.sliceTo(p, '\x00');
                            tex = if (dir) |d| BLK: {
                                const path = try std.fs.path.joinZ(
                                    self.allocator,
                                    &.{ d, uri_path },
                                );
                                defer self.allocator.free(path);
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
                        } else if (image.buffer_view) |v| { // Read embedded file
                            var file_data: []u8 = undefined;
                            file_data.ptr = @ptrCast([*]u8, v.buffer.data.?) + v.offset;
                            file_data.len = v.size;
                            tex = try jok.utils.gfx.createTextureFromFileData(
                                rd,
                                file_data,
                                .static,
                                false,
                            );
                        } else unreachable;
                        try self.textures.put(ssm.tex_id, tex);
                    }

                    if (mat.pbr_metallic_roughness.base_color_texture.has_transform != 0) {
                        transform = mat.pbr_metallic_roughness.base_color_texture.transform;
                    }
                }
            }

            // Indices.
            const num_vertices: u32 = @intCast(u32, prim.attributes[0].data.count);
            const index_offset = @intCast(u32, ssm.positions.items.len);
            if (prim.indices) |accessor| {
                const num_indices: u32 = @intCast(u32, accessor.count);
                try ssm.indices.ensureTotalCapacity(ssm.indices.items.len + num_indices);

                const buffer_view = accessor.buffer_view.?;
                assert(accessor.stride == buffer_view.stride or buffer_view.stride == 0);
                assert(accessor.stride * accessor.count <= buffer_view.size);
                assert(buffer_view.buffer.data != null);

                const data_addr = @ptrToInt(buffer_view.buffer.data.?) + accessor.offset + buffer_view.offset;
                if (accessor.stride == 1) {
                    assert(accessor.component_type == .r_8u);
                    const src = @intToPtr([*]const u8, data_addr);
                    for (0..num_indices) |i| {
                        ssm.indices.appendAssumeCapacity(src[i] + index_offset);
                    }
                } else if (accessor.stride == 2) {
                    assert(accessor.component_type == .r_16u);
                    const src = @intToPtr([*]const u16, data_addr);
                    for (0..num_indices) |i| {
                        ssm.indices.appendAssumeCapacity(src[i] + index_offset);
                    }
                } else if (accessor.stride == 4) {
                    assert(accessor.component_type == .r_32u);
                    const src = @intToPtr([*]const u32, data_addr);
                    for (0..num_indices) |i| {
                        ssm.indices.appendAssumeCapacity(src[i] + index_offset);
                    }
                } else {
                    unreachable;
                }
            } else {
                assert(@rem(num_vertices, 3) == 0);
                try ssm.indices.ensureTotalCapacity(num_vertices);
                for (0..num_vertices) |i| {
                    ssm.indices.appendAssumeCapacity(@intCast(u32, i) + index_offset);
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

                    const data_addr = @ptrToInt(buffer_view.buffer.data.?) + accessor.offset + buffer_view.offset;
                    if (attrib.type == .position) {
                        assert(accessor.type == .vec3);
                        assert(accessor.component_type == .r_32f);
                        const slice = @intToPtr([*]const [3]f32, data_addr)[0..num_vertices];
                        try ssm.positions.appendSlice(slice);
                    } else if (attrib.type == .normal) {
                        assert(accessor.type == .vec3);
                        assert(accessor.component_type == .r_32f);
                        const slice = @intToPtr([*]const [3]f32, data_addr)[0..num_vertices];
                        try ssm.normals.appendSlice(slice);
                    } else if (attrib.type == .color) {
                        assert(accessor.component_type == .r_32f);
                        if (accessor.type == .vec3) {
                            const slice = @intToPtr([*]const [3]f32, data_addr)[0..num_vertices];
                            for (slice) |c| try ssm.colors.append(sdl.Color.rgb(
                                @floatToInt(u8, 255 * c[0]),
                                @floatToInt(u8, 255 * c[1]),
                                @floatToInt(u8, 255 * c[2]),
                            ));
                        } else if (accessor.type == .vec4) {
                            const slice = @intToPtr([*]const [4]f32, data_addr)[0..num_vertices];
                            for (slice) |c| try ssm.colors.append(sdl.Color.rgba(
                                @floatToInt(u8, 255 * c[0]),
                                @floatToInt(u8, 255 * c[1]),
                                @floatToInt(u8, 255 * c[2]),
                                @floatToInt(u8, 255 * c[3]),
                            ));
                        }
                    } else if (attrib.type == .texcoord) {
                        assert(accessor.type == .vec2);
                        assert(accessor.component_type == .r_32f);
                        const slice = @intToPtr([*]const [2]f32, data_addr)[0..num_vertices];
                        try ssm.texcoords.ensureTotalCapacity(ssm.texcoords.items.len + slice.len);
                        if (transform) |tr| {
                            for (slice) |ts| {
                                ssm.texcoords.appendAssumeCapacity(.{
                                    zmath.clamp(tr.offset[0] + ts[0] * tr.scale[0], 0.0, 1.0),
                                    zmath.clamp(tr.offset[1] + ts[1] * tr.scale[1], 0.0, 1.0),
                                });
                            }
                        } else {
                            for (slice) |ts| {
                                ssm.texcoords.appendAssumeCapacity(.{
                                    zmath.clamp(ts[0], 0.0, 1.0),
                                    zmath.clamp(ts[1], 0.0, 1.0),
                                });
                            }
                        }
                    }
                }
            }

            // Compute AABB
            if (opt.compute_aabb) ssm.computeAabb();
        }
    }

    // Load children
    for (0..node.children_count) |node_index| {
        try self.loadNodeTree(rd, dir, node.children.?[node_index], m, opt);
    }
}
