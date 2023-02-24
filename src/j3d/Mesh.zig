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
    mesh: *Self,
    children: std.ArrayList(*SubMesh),
    model: zmath.Mat,
    indices: std.ArrayList(u16),
    positions: std.ArrayList([3]f32),
    normals: std.ArrayList([3]f32),
    colors: std.ArrayList(sdl.Color),
    texcoords: std.ArrayList([2]f32),
    aabb: ?[6]f32,
    tex_id: usize,

    fn init(allocator: std.mem.Allocator, mesh: *Self) SubMesh {
        return .{
            .mesh = mesh,
            .children = std.ArrayList(*SubMesh).init(allocator),
            .model = zmath.identity(),
            .indices = std.ArrayList(u16).init(allocator),
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
        self: *SubMesh,
        indices: []u16,
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
        const index_offset = @intCast(u16, self.positions.items.len);
        try self.indices.ensureTotalCapacity(self.indices.items.len + indices.len);
        for (indices) |idx| self.indices.appendAssumeCapacity(idx + index_offset);
        try self.positions.appendSlice(positions);
        if (normals) |ns| try self.normals.appendSlice(ns);
        if (colors) |cs| try self.colors.appendSlice(cs);
        if (texcoords) |ts| try self.texcoords.appendSlice(ts);
    }

    /// Compute AABB of mesh
    pub fn computeAabb(self: *SubMesh) void {
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
    pub fn remapTexcoords(self: *SubMesh, uv0: sdl.PointF, uv1: sdl.PointF) void {
        for (self.texcoords.items) |*ts| {
            ts[0] = jok.utils.math.linearMap(ts[0], 0, 1, uv0.x, uv1.x);
            ts[1] = jok.utils.math.linearMap(ts[1], 0, 1, uv0.y, uv1.y);
        }
    }

    /// Get texture
    pub fn getTexture(self: *const SubMesh) ?sdl.Texture {
        return self.mesh.textures.get(self.tex_id);
    }
};

allocator: std.mem.Allocator,
arena: std.heap.ArenaAllocator,
root: *SubMesh,
textures: std.AutoHashMap(usize, sdl.Texture),
own_textures: bool,

pub fn create(allocator: std.mem.Allocator) !*Self {
    var self = try allocator.create(Self);
    errdefer allocator.destroy(self);
    self.allocator = allocator;
    self.arena = std.heap.ArenaAllocator.init(allocator);
    self.root = try self.createSubMesh(null);
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
    var self = try create(allocator);
    errdefer self.destroy();
    try self.root.appendTriangles(
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
                self.root.remapTexcoords(opt.uvs.?[0], opt.uvs.?[1]);
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

    var self = try create(allocator);
    errdefer self.destroy();

    if (opt.tex) |t| { // Use external texture
        const tex_id = @ptrToInt(t.ptr);
        try self.textures.put(tex_id, t);
    } else { // Load textures
        self.own_textures = true;
        var image_index: usize = 0;
        while (image_index < data.images_count) : (image_index += 1) {
            const image = data.images.?[image_index];
            var tex: sdl.Texture = undefined;
            if (image.uri) |p| { // Read external file
                const uri_path = std.mem.sliceTo(p, '\x00');
                const dir = std.fs.path.dirname(file_path);
                tex = if (dir) |d| BLK: {
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
            const tex_id = @ptrToInt(&data.images.?[image_index]);
            try self.textures.put(tex_id, tex);
        }
    }

    // Load the scene/nodes
    var node_index: usize = 0;
    while (node_index < data.scene.?.nodes_count) : (node_index += 1) {
        try self.loadNodeTree(data.scene.?.nodes.?[node_index], self.root, opt);
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

pub fn createSubMesh(self: *Self, parent: ?*SubMesh) !*SubMesh {
    const allocator = self.arena.allocator();
    var m = try allocator.create(SubMesh);
    errdefer allocator.destroy(m);
    m.* = SubMesh.init(allocator, self);
    if (parent) |p| {
        m.model = p.model;
        try p.children.append(m);
    }
    return m;
}

fn loadNodeTree(self: *Self, node: *zmesh.io.zcgltf.Node, parent: *SubMesh, opt: GltfOption) !void {
    var m = try self.createSubMesh(parent);

    // Load transforms
    if (node.has_scale != 0) {
        m.model = zmath.mul(
            m.model,
            zmath.scaling(node.scale[0], node.scale[1], node.scale[2]),
        );
    }
    if (node.has_rotation != 0) {
        const quat = @as(zmath.Quat, zmath.f32x4(
            node.rotation[0],
            node.rotation[1],
            node.rotation[2],
            node.rotation[3],
        ));
        m.model = zmath.mul(m.model, zmath.quatToMat(quat));
    }
    if (node.has_translation != 0) {
        m.model = zmath.mul(m.model, zmath.translation(
            node.translation[0],
            node.translation[1],
            node.translation[2],
        ));
    }

    // Load vertex attributes
    if (node.mesh) |mesh| {
        var prim_index: usize = 0;
        while (prim_index < mesh.primitives_count) : (prim_index += 1) {
            const prim = &mesh.primitives[prim_index];
            const num_vertices: u32 = @intCast(u32, prim.attributes[0].data.count);

            // Indices.
            const index_offset = @intCast(u16, m.positions.items.len);
            if (prim.indices) |accessor| {
                const num_indices: u32 = @intCast(u32, accessor.count);
                try m.indices.ensureTotalCapacity(m.indices.items.len + num_indices);

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
                        m.indices.appendAssumeCapacity(src[i] + index_offset);
                    }
                } else if (accessor.stride == 2) {
                    assert(accessor.component_type == .r_16u);
                    const src = @ptrCast([*]const u16, data_addr);
                    var i: u32 = 0;
                    while (i < num_indices) : (i += 1) {
                        m.indices.appendAssumeCapacity(src[i] + index_offset);
                    }
                } else if (accessor.stride == 4) {
                    assert(accessor.component_type == .r_32u);
                    const src = @ptrCast([*]const u32, data_addr);
                    var i: u32 = 0;
                    while (i < num_indices) : (i += 1) {
                        m.indices.appendAssumeCapacity(@intCast(u16, src[i]) + index_offset);
                    }
                } else {
                    unreachable;
                }
            } else {
                assert(@rem(num_vertices, 3) == 0);
                try m.indices.ensureTotalCapacity(num_vertices);
                var i: u32 = 0;
                while (i < num_vertices) : (i += 1) {
                    m.indices.appendAssumeCapacity(@intCast(u16, i));
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
                        try m.positions.appendSlice(slice);
                    } else if (attrib.type == .normal) {
                        assert(accessor.type == .vec3);
                        assert(accessor.component_type == .r_32f);
                        const slice = @ptrCast([*]const [3]f32, @alignCast(4, data_addr))[0..num_vertices];
                        try m.normals.appendSlice(slice);
                    } else if (attrib.type == .color) {
                        assert(accessor.component_type == .r_32f);
                        if (accessor.type == .vec3) {
                            const slice = @ptrCast([*]const [3]f32, @alignCast(4, data_addr))[0..num_vertices];
                            for (slice) |c| try m.colors.append(sdl.Color.rgb(
                                @floatToInt(u8, 255 * c[0]),
                                @floatToInt(u8, 255 * c[1]),
                                @floatToInt(u8, 255 * c[2]),
                            ));
                        } else if (accessor.type == .vec4) {
                            const slice = @ptrCast([*]const [4]f32, @alignCast(4, data_addr))[0..num_vertices];
                            for (slice) |c| try m.colors.append(sdl.Color.rgba(
                                @floatToInt(u8, 255 * c[0]),
                                @floatToInt(u8, 255 * c[1]),
                                @floatToInt(u8, 255 * c[2]),
                                @floatToInt(u8, 255 * c[3]),
                            ));
                        }
                    } else if (attrib.type == .texcoord) {
                        assert(accessor.type == .vec2);
                        assert(accessor.component_type == .r_32f);
                        const slice = @ptrCast([*]const [2]f32, @alignCast(4, data_addr))[0..num_vertices];
                        try m.texcoords.appendSlice(slice);
                    }
                }
            }
        }

        if (mesh.primitives_count > 0) {
            // Load material
            if (opt.tex) |t| {
                m.tex_id = @ptrToInt(t.ptr);
                if (opt.uvs != null) {
                    m.remapTexcoords(opt.uvs.?[0], opt.uvs.?[1]);
                }
            } else if (mesh.primitives[0].material) |mat| {
                // NOTE: we assume all primtives use same texture here, might be wrong???
                if (mat.has_pbr_metallic_roughness != 0 and
                    mat.pbr_metallic_roughness.base_color_texture.texture != null)
                {
                    m.tex_id = @ptrToInt(mat.pbr_metallic_roughness.base_color_texture.texture.?.image.?);
                    assert(self.textures.get(m.tex_id) != null);
                }
            }

            // Compute AABB
            if (opt.compute_aabb) m.computeAabb();
        }
    }

    // Load children
    var node_index: usize = 0;
    while (node_index < node.children_count) : (node_index += 1) {
        try self.loadNodeTree(node.children.?[node_index], m, opt);
    }
}
