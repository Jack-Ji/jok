/// mesh data imported from zmesh.Shape and model file
const std = @import("std");
const math = std.math;
const assert = std.debug.assert;
const jok = @import("../jok.zig");
const j3d = jok.j3d;
const physfs = jok.physfs;
const zmath = jok.zmath;
const zmesh = jok.zmesh;
const zobj = jok.zobj;
const Vector = @import("Vector.zig");
const TriangleRenderer = @import("TriangleRenderer.zig");
const ShadingMethod = TriangleRenderer.ShadingMethod;
const Camera = @import("Camera.zig");
const lighting = @import("lighting.zig");
const Self = @This();

pub const Error = error{
    InvalidFormat,
    InvalidAnimation,
    TooManyMaterial, // Only support single material (diffuse map)
};

const Format = enum {
    shape,
    gltf,
    obj,
};

pub const RenderOption = struct {
    texture: ?jok.Texture = null,
    color: jok.ColorF = .white,
    shading_method: ShadingMethod = .gouraud,
    cull_faces: bool = true,
    lighting: ?lighting.LightingOption = null,
};

pub const GltfNode = zmesh.io.zcgltf.bindings.Node;
pub const Node = struct {
    pub const SubMesh = struct {
        mesh: *Self,
        indices: std.array_list.Managed(u32),
        positions: std.array_list.Managed([3]f32),
        normals: std.array_list.Managed([3]f32),
        colors: std.array_list.Managed(jok.ColorF),
        texcoords: std.array_list.Managed([2]f32),
        joints: std.array_list.Managed([4]u8),
        weights: std.array_list.Managed([4]f32),
        aabb: ?[6]f32,
        tex_id: usize,

        pub fn init(allocator: std.mem.Allocator, mesh: *Self) SubMesh {
            return .{
                .mesh = mesh,
                .indices = .init(allocator),
                .positions = .init(allocator),
                .normals = .init(allocator),
                .colors = .init(allocator),
                .texcoords = .init(allocator),
                .joints = .init(allocator),
                .weights = .init(allocator),
                .aabb = null,
                .tex_id = 0,
            };
        }

        /// Push attributes data
        pub fn appendAttributes(
            self: *SubMesh,
            indices: []const u32,
            positions: []const [3]f32,
            normals: ?[]const [3]f32,
            colors: ?[]const jok.ColorF,
            texcoords: ?[]const [2]f32,
            joints: ?[]const [4]u8,
            weights: ?[]const [4]f32,
        ) !void {
            if (indices.len == 0) return;
            assert(@rem(indices.len, 3) == 0);
            assert(if (normals) |ns| positions.len == ns.len else true);
            assert(if (texcoords) |ts| positions.len == ts.len else true);
            assert(if (joints) |js| positions.len == js.len else true);
            assert(if (weights) |ws| positions.len == ws.len else true);
            if ((self.normals.items.len > 0 and normals == null) or
                (self.indices.items.len > 0 and self.normals.items.len == 0 and normals != null) or
                (self.colors.items.len > 0 and colors == null) or
                (self.indices.items.len > 0 and self.colors.items.len == 0 and colors != null) or
                (self.texcoords.items.len > 0 and texcoords == null) or
                (self.indices.items.len > 0 and self.texcoords.items.len == 0 and texcoords != null) or
                (self.joints.items.len > 0 and joints == null) or
                (self.indices.items.len > 0 and self.joints.items.len == 0 and joints != null) or
                (self.weights.items.len > 0 and weights == null) or
                (self.indices.items.len > 0 and self.weights.items.len == 0 and weights != null))
            {
                return error.InvalidFormat;
            }
            const index_offset = @as(u32, @intCast(self.positions.items.len));
            try self.indices.ensureTotalCapacity(self.indices.items.len + indices.len);
            for (indices) |idx| self.indices.appendAssumeCapacity(idx + index_offset);
            try self.positions.appendSlice(positions);
            if (normals) |ns| try self.normals.appendSlice(ns);
            if (colors) |cs| try self.colors.appendSlice(cs);
            if (texcoords) |ts| try self.texcoords.appendSlice(ts);
            if (joints) |js| try self.joints.appendSlice(js);
            if (weights) |ws| try self.weights.appendSlice(ws);
        }

        /// Compute AABB of mesh
        pub fn computeAabb(self: *SubMesh) void {
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
        pub fn remapTexcoords(self: *SubMesh, uv0: jok.Point, uv1: jok.Point) void {
            for (self.texcoords.items) |*ts| {
                ts[0] = jok.utils.math.linearMap(ts[0], 0, 1, uv0.x, uv1.x);
                ts[1] = jok.utils.math.linearMap(ts[1], 0, 1, uv0.y, uv1.y);
            }
        }

        /// Get texture
        pub fn getTexture(self: *const SubMesh) ?jok.Texture {
            return self.mesh.textures.get(self.tex_id);
        }
    };

    mesh: *Self,
    parent: ?*Node,
    children: std.array_list.Managed(*Node),
    scale: zmath.Vec,
    rotation: zmath.Vec,
    translation: zmath.Vec,
    matrix: zmath.Mat,
    meshes: []SubMesh,
    skin: ?*Skin = null,
    is_joint: bool = false,

    fn init(
        allocator: std.mem.Allocator,
        mesh: *Self,
        parent: ?*Node,
        mesh_count: usize,
    ) !Node {
        const self = Node{
            .mesh = mesh,
            .parent = parent,
            .children = std.array_list.Managed(*Node).init(allocator),
            .scale = zmath.f32x4(1.0, 1.0, 1.0, 0.0),
            .rotation = zmath.f32x4(0.0, 0.0, 0.0, 1.0),
            .translation = zmath.f32x4s(0),
            .matrix = zmath.identity(),
            .meshes = try allocator.alloc(SubMesh, mesh_count),
        };
        for (self.meshes) |*m| m.* = SubMesh.init(allocator, mesh);
        return self;
    }

    fn fromGltfNode(
        allocator: std.mem.Allocator,
        mesh: *Self,
        parent: *Node,
        gltf_node: *const GltfNode,
    ) !Node {
        var self = try Node.init(
            allocator,
            mesh,
            parent,
            if (gltf_node.mesh) |m| m.primitives_count else 0,
        );
        if (gltf_node.has_matrix == 1) {
            const m = zmath.loadMat(&gltf_node.transformLocal());
            self.matrix = zmath.loadMat(&gltf_node.transformWorld());
            self.translation = zmath.util.getTranslationVec(m);
            self.rotation = zmath.util.getRotationQuat(m);
            self.scale = zmath.util.getScaleVec(m);
        } else {
            if (gltf_node.has_scale == 1) {
                self.scale = zmath.f32x4(
                    gltf_node.scale[0],
                    gltf_node.scale[1],
                    gltf_node.scale[2],
                    0.0,
                );
            }
            if (gltf_node.has_rotation == 1) {
                self.rotation = zmath.f32x4(
                    gltf_node.rotation[0],
                    gltf_node.rotation[1],
                    gltf_node.rotation[2],
                    gltf_node.rotation[3],
                );
            }
            if (gltf_node.has_translation == 1) {
                self.translation = zmath.f32x4(
                    gltf_node.translation[0],
                    gltf_node.translation[1],
                    gltf_node.translation[2],
                    0.0,
                );
            }
            self.matrix = zmath.mul(parent.matrix, self.calcLocalTransform());
        }
        for (self.meshes) |*m| m.* = SubMesh.init(allocator, mesh);
        return self;
    }

    fn calcLocalTransform(node: *const Node) zmath.Mat {
        return zmath.mul(
            zmath.mul(
                zmath.scalingV(node.scale),
                zmath.matFromQuat(@as(zmath.Quat, node.rotation)),
            ),
            zmath.translationV(node.translation),
        );
    }

    fn render(
        node: *Node,
        csz: jok.Size,
        batch: *j3d.Batch,
        model: zmath.Mat,
        camera: Camera,
        tri_rd: *TriangleRenderer,
        opt: RenderOption,
    ) !void {
        for (node.meshes) |sm| {
            try tri_rd.renderMesh(
                csz,
                batch,
                zmath.mul(node.matrix, model),
                camera,
                sm.indices.items,
                sm.positions.items,
                if (sm.normals.items.len == 0)
                    null
                else
                    sm.normals.items,
                if (sm.colors.items.len == 0)
                    null
                else
                    sm.colors.items,
                if (sm.texcoords.items.len == 0)
                    null
                else
                    sm.texcoords.items,
                .{
                    .aabb = sm.aabb,
                    .cull_faces = opt.cull_faces,
                    .front_face = if (node.mesh.format != .shape) .ccw else .cw, // Use CCW when it is GLTF/OBJ model
                    .color = opt.color,
                    .shading_method = opt.shading_method,
                    .texture = opt.texture orelse sm.getTexture(),
                    .lighting = opt.lighting,
                    .animation = null,
                },
            );
        }
        for (node.children.items) |c| {
            try c.render(
                csz,
                batch,
                model,
                camera,
                tri_rd,
                opt,
            );
        }
    }
};

pub const GltfAnimation = zmesh.io.zcgltf.bindings.Animation;
pub const GltfAnimationPathType = zmesh.io.zcgltf.bindings.AnimationPathType;
pub const GltfInterpolationType = zmesh.io.zcgltf.bindings.InterpolationType;
pub const Animation = struct {
    const Channel = struct {
        node: *Node,
        path: GltfAnimationPathType,
        interpolation: GltfInterpolationType,
        timesteps: []f32,
        samples: []zmath.Vec,
    };
    mesh: *Self,
    name: []const u8,
    channels: std.array_list.Managed(Channel),
    duration: f32,

    fn fromGltfAnimation(allocator: std.mem.Allocator, mesh: *Self, gltf_anim: GltfAnimation, name: []const u8) !?Animation {
        var anim = Animation{
            .mesh = mesh,
            .name = name,
            .channels = std.array_list.Managed(Channel).init(allocator),
            .duration = 0,
        };
        for (gltf_anim.channels[0..gltf_anim.channels_count]) |ch| {
            if (ch.target_path == .weights) continue; // TODO weights path not supported
            if (ch.sampler.interpolation == .cubic_spline) continue; // TODO cubis-spline not supported

            assert(ch.sampler.output.component_type == .r_32f);
            var samples = try allocator.alloc(zmath.Vec, ch.sampler.output.count);
            switch (ch.target_path) {
                .scale => {
                    var xs: [3]f32 = undefined;
                    for (0..ch.sampler.output.count) |i| {
                        const ret = ch.sampler.output.readFloat(i, &xs);
                        assert(ret == true);
                        samples[i] = zmath.f32x4(
                            xs[0],
                            xs[1],
                            xs[2],
                            0,
                        );
                    }
                },
                .rotation => {
                    var xs: [4]f32 = undefined;
                    for (0..ch.sampler.output.count) |i| {
                        const ret = ch.sampler.output.readFloat(i, &xs);
                        assert(ret == true);
                        samples[i] = zmath.f32x4(
                            xs[0],
                            xs[1],
                            xs[2],
                            xs[3],
                        );
                    }
                },
                .translation => {
                    var xs: [3]f32 = undefined;
                    for (0..ch.sampler.output.count) |i| {
                        const ret = ch.sampler.output.readFloat(i, &xs);
                        assert(ret == true);
                        samples[i] = zmath.f32x4(
                            xs[0],
                            xs[1],
                            xs[2],
                            0,
                        );
                    }
                },
                else => unreachable,
            }

            const timesteps = try allocator.alloc(f32, ch.sampler.input.unpackFloatsCount());
            _ = ch.sampler.input.unpackFloats(timesteps);
            assert(timesteps.len == samples.len);
            assert(std.sort.isSorted(f32, timesteps, {}, std.sort.asc(f32)));
            anim.duration = @max(anim.duration, timesteps[timesteps.len - 1]);

            try anim.channels.append(Channel{
                .node = mesh.nodes_map.get(ch.target_node.?).?,
                .path = ch.target_path,
                .interpolation = ch.sampler.interpolation,
                .timesteps = timesteps,
                .samples = samples,
            });
        }
        return if (anim.channels.items.len == 0) null else anim;
    }

    pub fn isSkeletonAnimation(anim: Animation) bool {
        return anim.channels.items[0].node.is_joint;
    }
};

pub const GltfSkin = zmesh.io.zcgltf.bindings.Skin;
pub const Skin = struct {
    inverse_matrices: []zmath.Mat,
    nodes: []*Node,

    fn fromGltfSkin(allocator: std.mem.Allocator, mesh: *Self, gltf_skin: *const GltfSkin) !Skin {
        assert(gltf_skin.joints_count > 0);
        var matrices = try allocator.alloc(zmath.Mat, gltf_skin.joints_count);
        var xs: [16]f32 = undefined;
        for (0..gltf_skin.joints_count) |i| {
            const ret = gltf_skin.inverse_bind_matrices.?.readFloat(i, &xs);
            assert(ret == true);
            matrices[i] = zmath.loadMat(&xs);
        }
        var nodes = try allocator.alloc(*Node, gltf_skin.joints_count);
        for (0..gltf_skin.joints_count) |i| {
            nodes[i] = mesh.nodes_map.get(gltf_skin.joints[i]).?;
            nodes[i].is_joint = true;
        }
        return .{ .inverse_matrices = matrices, .nodes = nodes };
    }
};

allocator: std.mem.Allocator,
arena: std.heap.ArenaAllocator,
root: *Node,
textures: std.AutoHashMap(usize, jok.Texture),
nodes_map: std.AutoHashMap(*const GltfNode, *Node),
animations: std.StringHashMap(Animation),
skins_map: std.AutoHashMap(*const GltfSkin, *Skin),
own_textures: bool,
format: Format,

pub fn create(allocator: std.mem.Allocator, mesh_count: usize, format: Format) !*Self {
    var self = try allocator.create(Self);
    errdefer allocator.destroy(self);
    self.allocator = allocator;
    self.arena = std.heap.ArenaAllocator.init(allocator);
    self.root = try self.createRootNode(mesh_count);
    self.textures = std.AutoHashMap(usize, jok.Texture).init(self.arena.allocator());
    self.nodes_map = std.AutoHashMap(*const GltfNode, *Node).init(self.arena.allocator());
    self.animations = std.StringHashMap(Animation).init(self.arena.allocator());
    self.skins_map = std.AutoHashMap(*const GltfSkin, *Skin).init(self.arena.allocator());
    self.own_textures = false;
    self.format = format;
    return self;
}

/// Create mesh with zmesh.Shape
pub const ShapeOption = struct {
    compute_aabb: bool = true,
    tex: ?jok.Texture = null,
    uvs: ?[2]jok.Point = null,
};
pub fn fromShape(
    allocator: std.mem.Allocator,
    shape: zmesh.Shape,
    opt: ShapeOption,
) !*Self {
    var self = try create(allocator, 1, .shape);
    errdefer self.destroy();
    try self.root.meshes[0].appendAttributes(
        shape.indices,
        shape.positions,
        shape.normals,
        null,
        shape.texcoords,
        null,
        null,
    );
    if (shape.texcoords != null) {
        if (opt.tex) |t| {
            const tex_id = @intFromPtr(t.ptr);
            self.root.meshes[0].tex_id = tex_id;
            try self.textures.put(tex_id, t);
            if (opt.uvs != null) {
                self.root.meshes[0].remapTexcoords(opt.uvs.?[0], opt.uvs.?[1]);
            }
        }
    }
    if (opt.compute_aabb) self.root.meshes[0].computeAabb();
    return self;
}

/// Create mesh with OBJ model file
pub const ObjOption = struct {
    compute_aabb: bool = true,
    tex: ?jok.Texture = null,
    uvs: ?[2]jok.Point = null,
};
pub fn fromObj(
    ctx: jok.Context,
    obj_file_path: [*:0]const u8,
    mtl_file_path: ?[*:0]const u8,
    opt: ObjOption,
) !*Self {
    const obj_file_data = BLK: {
        if (ctx.cfg().jok_enable_physfs) {
            const handle = try physfs.open(obj_file_path, .read);
            defer handle.close();
            break :BLK try handle.readAllAlloc(ctx.allocator());
        } else {
            const idx = std.mem.indexOfSentinel(u8, 0, obj_file_path);
            break :BLK try std.fs.cwd().readFileAlloc(ctx.allocator(), obj_file_path[0..idx :0], 1 << 30);
        }
    };
    defer ctx.allocator().free(obj_file_data);

    const mtl_file_data = BLK: {
        if (mtl_file_path) |p| {
            if (ctx.cfg().jok_enable_physfs) {
                const handle = try physfs.open(p, .read);
                defer handle.close();
                break :BLK try handle.readAllAlloc(ctx.allocator());
            } else {
                const idx = std.mem.indexOfSentinel(u8, 0, p);
                break :BLK try std.fs.cwd().readFileAlloc(ctx.allocator(), p[0..idx :0], 1 << 30);
            }
        } else {
            break :BLK null;
        }
    };
    defer if (mtl_file_data) |d| ctx.allocator().free(d);

    // Parse obj data
    var objdata = try zobj.parseObj(ctx.allocator(), obj_file_data);
    defer objdata.deinit(ctx.allocator());
    if (objdata.material_libs.len != 0 and objdata.material_libs.len > 1) {
        return error.TooManyMaterial;
    }

    // Init mesh instance
    var self = try create(ctx.allocator(), objdata.meshes.len, .obj);
    errdefer self.destroy();

    // Parse material data
    var mtldata: ?zobj.MaterialData = null;
    if (mtl_file_data) |d| {
        mtldata = try zobj.parseMtl(ctx.allocator(), d);
        var it = mtldata.?.materials.iterator();
        while (it.next()) |e| {
            if (e.value_ptr.diffuse_map) |map| {
                const dir = std.fs.path.dirname(std.mem.sliceTo(mtl_file_path.?, 0)) orelse "";
                const uri_path = std.mem.sliceTo(map.path, 0);
                const path = try std.mem.joinZ(
                    self.allocator,
                    "/",
                    &.{ dir, uri_path },
                );
                defer self.allocator.free(path);
                const tex = try ctx.renderer().createTextureFromFile(
                    ctx.allocator(),
                    path,
                    .static,
                    true, // MTL texture's bottom-left is origin
                );
                try self.textures.put(@intFromPtr(map.path.ptr), tex);
            }
        }
    }
    defer if (mtldata) |*d| d.deinit(ctx.allocator());

    // Add faces
    for (0..objdata.meshes.len) |i| {
        const mesh = objdata.meshes[i];

        var idx: u32 = 0;
        for (mesh.num_vertices) |n| {
            assert(n >= 3);
            assert(mesh.indices[idx..].len >= 3);

            // Triangulate the polygon
            for (2..n) |j| {
                const idx1 = idx;
                const idx2: u32 = @intCast(idx + j - 1);
                const idx3: u32 = @intCast(idx + j);

                // Get referenced material
                var mtl1: ?zobj.Material = null;
                var mtl2: ?zobj.Material = null;
                var mtl3: ?zobj.Material = null;
                if (mtldata != null) {
                    for (mesh.materials) |m| {
                        if (mtl1 == null and idx1 < m.end_index) {
                            mtl1 = mtldata.?.materials.get(m.material).?;
                        }
                        if (mtl2 == null and idx2 < m.end_index) {
                            mtl2 = mtldata.?.materials.get(m.material).?;
                        }
                        if (mtl3 == null and idx3 < m.end_index) {
                            mtl3 = mtldata.?.materials.get(m.material).?;
                        }
                    }
                    if (mtl1 != null and mtl1.?.diffuse_map != null) {
                        // WARNING: we're assuming at most one material
                        self.root.meshes[i].tex_id = @intFromPtr(mtl1.?.diffuse_map.?.path.ptr);
                    }
                }

                // Calculate normal vector
                const index1 = mesh.indices[idx1];
                const index2 = mesh.indices[idx2];
                const index3 = mesh.indices[idx3];
                const v1 = zmath.f32x4(
                    objdata.vertices[index2.vertex.? * 3] - objdata.vertices[index1.vertex.? * 3],
                    objdata.vertices[index2.vertex.? * 3 + 1] - objdata.vertices[index1.vertex.? * 3 + 1],
                    objdata.vertices[index2.vertex.? * 3 + 2] - objdata.vertices[index1.vertex.? * 3 + 2],
                    0,
                );
                const v2 = zmath.f32x4(
                    objdata.vertices[index3.vertex.? * 3] - objdata.vertices[index1.vertex.? * 3],
                    objdata.vertices[index3.vertex.? * 3 + 1] - objdata.vertices[index1.vertex.? * 3 + 1],
                    objdata.vertices[index3.vertex.? * 3 + 2] - objdata.vertices[index1.vertex.? * 3 + 2],
                    0,
                );
                const normal = zmath.vecToArr3(zmath.normalize3(zmath.cross3(v1, v2)));

                // Fill attributes of vertices
                try self.root.meshes[i].appendAttributes(
                    &.{ 0, 1, 2 },
                    &.{
                        .{ objdata.vertices[index1.vertex.? * 3], objdata.vertices[index1.vertex.? * 3 + 1], objdata.vertices[index1.vertex.? * 3 + 2] },
                        .{ objdata.vertices[index2.vertex.? * 3], objdata.vertices[index2.vertex.? * 3 + 1], objdata.vertices[index2.vertex.? * 3 + 2] },
                        .{ objdata.vertices[index3.vertex.? * 3], objdata.vertices[index3.vertex.? * 3 + 1], objdata.vertices[index3.vertex.? * 3 + 2] },
                    },
                    &.{ normal, normal, normal },
                    null,
                    if (mtl1 != null and mtl1.?.diffuse_map != null)
                        &.{
                            .{
                                std.math.clamp(objdata.tex_coords[index1.tex_coord.? * 2], 0, 1),
                                std.math.clamp(objdata.tex_coords[index1.tex_coord.? * 2 + 1], 0, 1),
                            },
                            .{
                                std.math.clamp(objdata.tex_coords[index2.tex_coord.? * 2], 0, 1),
                                std.math.clamp(objdata.tex_coords[index2.tex_coord.? * 2 + 1], 0, 1),
                            },
                            .{
                                std.math.clamp(objdata.tex_coords[index3.tex_coord.? * 2], 0, 1),
                                std.math.clamp(objdata.tex_coords[index3.tex_coord.? * 2 + 1], 0, 1),
                            },
                        }
                    else
                        null,
                    null,
                    null,
                );
            }

            idx += n;
        }

        if (opt.compute_aabb) self.root.meshes[i].computeAabb();
    }

    if (opt.tex) |t| {
        const tex_id = @intFromPtr(t.ptr);
        for (self.root.meshes) |*m| {
            m.tex_id = tex_id;
            try self.textures.put(tex_id, t);
            if (opt.uvs != null) {
                m.remapTexcoords(opt.uvs.?[0], opt.uvs.?[1]);
            }
        }
    }
    return self;
}

/// Create mesh with GLTF model file
pub const GltfOption = struct {
    compute_aabb: bool = true,
    tex: ?jok.Texture = null,
    uvs: ?[2]jok.Point = null,
};
pub fn fromGltf(ctx: jok.Context, file_path: [*:0]const u8, opt: GltfOption) !*Self {
    var filedata: ?[]const u8 = null;
    defer if (filedata) |d| ctx.allocator().free(d);

    const data = BLK: {
        if (ctx.cfg().jok_enable_physfs) {
            const handle = try physfs.open(file_path, .read);
            defer handle.close();

            const options = zmesh.io.zcgltf.bindings.Options{
                .memory = .{
                    .alloc_func = zmesh.mem.zmeshAllocUser,
                    .free_func = zmesh.mem.zmeshFreeUser,
                },
                .file = physfs.zmesh.file_options,
            };
            filedata = try handle.readAllAlloc(ctx.allocator());
            const data = try zmesh.io.zcgltf.bindings.parse(options, filedata.?);
            try zmesh.io.zcgltf.bindings.loadBuffers(options, data, file_path);
            break :BLK data;
        } else {
            const idx = std.mem.indexOfSentinel(u8, 0, file_path);
            const data = try zmesh.io.parseAndLoadFile(file_path[0..idx :0]);
            break :BLK data;
        }
    };
    defer zmesh.io.freeData(data);

    var self = try create(ctx.allocator(), 0, .gltf);
    errdefer self.destroy();

    if (opt.tex) |t| { // Use external texture
        const tex_id = @intFromPtr(t.ptr);
        try self.textures.put(tex_id, t);
    } else {
        self.own_textures = true;
    }

    // Load the scene/nodes
    const dir: []const u8 = std.fs.path.dirname(std.mem.sliceTo(file_path, 0)) orelse "";
    var node_index: usize = 0;
    while (node_index < data.scene.?.nodes_count) : (node_index += 1) {
        try self.loadNodeTree(ctx, dir, data.scene.?.nodes.?[node_index], self.root, opt);
    }

    // Load animations
    var index: usize = 0;
    while (index < data.animations_count) : (index += 1) {
        try self.loadAnimation(data.animations.?[index]);
    }
    index = 0;
    while (index < data.skins_count) : (index += 1) {
        try self.loadSkin(&data.skins.?[index]);
    }

    // Connect nodes and skins
    var it = self.nodes_map.iterator();
    while (it.next()) |kv| {
        const gltf_node = kv.key_ptr.*;
        const node = kv.value_ptr.*;
        if (gltf_node.skin) |s| {
            node.skin = self.skins_map.get(s).?;
        }
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

pub fn render(
    self: *const Self,
    csz: jok.Size,
    batch: *j3d.Batch,
    model: zmath.Mat,
    camera: Camera,
    tri_rd: *TriangleRenderer,
    opt: RenderOption,
) !void {
    try self.root.render(
        csz,
        batch,
        if (self.format != .shape) // Convert to right-handed system (glTF/OBJ use right-handed system)
            zmath.mul(zmath.scaling(1, 1, -1), model)
        else
            model,
        camera,
        tri_rd,
        opt,
    );
}

pub inline fn getAnimation(self: Self, name: []const u8) ?*Animation {
    var anim = self.animations.getPtr(name);
    if (anim == null) {
        if (self.animations.count() == 1 and
            std.mem.eql(u8, name, "default"))
        {
            var it = self.animations.valueIterator();
            anim = it.next();
            assert(anim != null);
        }
    }
    return anim;
}

fn createRootNode(self: *Self, mesh_count: usize) !*Node {
    const allocator = self.arena.allocator();
    const node = try allocator.create(Node);
    errdefer allocator.destroy(node);
    node.* = try Node.init(allocator, self, null, mesh_count);
    return node;
}

fn loadNodeTree(
    self: *Self,
    ctx: jok.Context,
    dir: []const u8,
    gltf_node: *const GltfNode,
    parent: *Node,
    opt: GltfOption,
) !void {
    const node = try self.arena.allocator().create(Node);
    node.* = try Node.fromGltfNode(self.arena.allocator(), self, parent, gltf_node);
    try parent.children.append(node);
    try self.nodes_map.putNoClobber(gltf_node, node);

    if (gltf_node.mesh) |mesh| {
        for (0..mesh.primitives_count, node.meshes) |prim_index, *sm| {
            const prim = &mesh.primitives[prim_index];

            // Load material
            var transform: ?zmesh.io.zcgltf.bindings.TextureTransform = null;
            if (opt.tex) |t| {
                sm.tex_id = @intFromPtr(t.ptr);
                if (opt.uvs != null) {
                    sm.remapTexcoords(opt.uvs.?[0], opt.uvs.?[1]);
                }
            } else if (prim.material) |mat| {
                if (mat.has_pbr_metallic_roughness != 0 and
                    mat.pbr_metallic_roughness.base_color_texture.texture != null)
                {
                    const image = mat.pbr_metallic_roughness.base_color_texture.texture.?.image.?;
                    sm.tex_id = @intFromPtr(image);
                    assert(sm.tex_id != 0);

                    // Lazily load textures
                    if (self.textures.get(sm.tex_id) == null) {
                        var tex: jok.Texture = undefined;
                        if (image.uri) |p| { // Read external file
                            const uri_path = std.mem.sliceTo(p, 0);
                            const path = try std.mem.joinZ(
                                self.allocator,
                                "/",
                                &.{ dir, uri_path },
                            );
                            defer self.allocator.free(path);
                            tex = try ctx.renderer().createTextureFromFile(
                                ctx.allocator(),
                                path,
                                .static,
                                false,
                            );
                        } else if (image.buffer_view) |v| { // Read embedded file
                            var file_data: []u8 = undefined;
                            file_data.ptr = @as([*]u8, @ptrCast(v.buffer.data.?)) + v.offset;
                            file_data.len = v.size;
                            tex = try ctx.renderer().createTextureFromFileData(
                                file_data,
                                .static,
                                false,
                            );
                        } else unreachable;
                        try self.textures.putNoClobber(sm.tex_id, tex);
                    }

                    if (mat.pbr_metallic_roughness.base_color_texture.has_transform != 0) {
                        transform = mat.pbr_metallic_roughness.base_color_texture.transform;
                    }
                }
            }

            // Indices.
            const num_vertices: u32 = @intCast(prim.attributes[0].data.count);
            const index_offset = @as(u32, @intCast(sm.positions.items.len));
            if (prim.indices) |accessor| {
                const num_indices: u32 = @intCast(accessor.count);
                try sm.indices.ensureTotalCapacity(sm.indices.items.len + num_indices);

                const buffer_view = accessor.buffer_view.?;
                assert(accessor.stride == buffer_view.stride or buffer_view.stride == 0);
                assert(accessor.stride * accessor.count <= buffer_view.size);
                assert(buffer_view.buffer.data != null);

                const data_addr = @intFromPtr(buffer_view.buffer.data.?) + accessor.offset + buffer_view.offset;
                if (accessor.stride == 1) {
                    assert(accessor.component_type == .r_8u);
                    const src = @as([*]const u8, @ptrFromInt(data_addr));
                    for (0..num_indices) |i| {
                        sm.indices.appendAssumeCapacity(src[i] + index_offset);
                    }
                } else if (accessor.stride == 2) {
                    assert(accessor.component_type == .r_16u);
                    const src = @as([*]const u16, @ptrFromInt(data_addr));
                    for (0..num_indices) |i| {
                        sm.indices.appendAssumeCapacity(src[i] + index_offset);
                    }
                } else if (accessor.stride == 4) {
                    assert(accessor.component_type == .r_32u);
                    const src = @as([*]const u32, @ptrFromInt(data_addr));
                    for (0..num_indices) |i| {
                        sm.indices.appendAssumeCapacity(src[i] + index_offset);
                    }
                } else {
                    unreachable;
                }
            } else {
                assert(@rem(num_vertices, 3) == 0);
                try sm.indices.ensureTotalCapacity(num_vertices);
                for (0..num_vertices) |i| {
                    sm.indices.appendAssumeCapacity(@as(u32, @intCast(i)) + index_offset);
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

                    const data_addr = @intFromPtr(buffer_view.buffer.data.?) + accessor.offset + buffer_view.offset;
                    if (attrib.type == .position) {
                        assert(accessor.type == .vec3);
                        assert(accessor.component_type == .r_32f);
                        const slice = @as([*]const [3]f32, @ptrFromInt(data_addr))[0..num_vertices];
                        try sm.positions.appendSlice(slice);
                    } else if (attrib.type == .normal) {
                        assert(accessor.type == .vec3);
                        assert(accessor.component_type == .r_32f);
                        const slice = @as([*]const [3]f32, @ptrFromInt(data_addr))[0..num_vertices];
                        try sm.normals.appendSlice(slice);
                    } else if (attrib.type == .color) {
                        assert(accessor.component_type == .r_32f);
                        if (accessor.type == .vec3) {
                            const slice = @as([*]const [3]f32, @ptrFromInt(data_addr))[0..num_vertices];
                            for (slice) |c| try sm.colors.append(.rgb(c[0], c[1], c[2]));
                        } else if (accessor.type == .vec4) {
                            const slice = @as([*]const [4]f32, @ptrFromInt(data_addr))[0..num_vertices];
                            for (slice) |c| try sm.colors.append(.rgba(c[0], c[1], c[2], c[3]));
                        }
                    } else if (attrib.type == .texcoord) {
                        assert(accessor.type == .vec2);
                        assert(accessor.component_type == .r_32f);
                        const slice = @as([*]const [2]f32, @ptrFromInt(data_addr))[0..num_vertices];
                        try sm.texcoords.ensureTotalCapacity(sm.texcoords.items.len + slice.len);
                        if (transform) |tr| {
                            for (slice) |ts| {
                                sm.texcoords.appendAssumeCapacity(.{
                                    zmath.clamp(tr.offset[0] + ts[0] * tr.scale[0], 0.0, 1.0),
                                    zmath.clamp(tr.offset[1] + ts[1] * tr.scale[1], 0.0, 1.0),
                                });
                            }
                        } else {
                            for (slice) |ts| {
                                sm.texcoords.appendAssumeCapacity(.{
                                    zmath.clamp(ts[0], 0.0, 1.0),
                                    zmath.clamp(ts[1], 0.0, 1.0),
                                });
                            }
                        }
                    } else if (attrib.type == .joints) {
                        assert(accessor.type == .vec4);
                        try sm.joints.ensureTotalCapacity(sm.joints.items.len + num_vertices);
                        if (accessor.component_type == .r_8u) {
                            const slice = @as([*]const [4]u8, @ptrFromInt(data_addr))[0..num_vertices];
                            try sm.joints.appendSlice(slice);
                        } else if (accessor.component_type == .r_16u) {
                            const slice = @as([*]const [4]u16, @ptrFromInt(data_addr))[0..num_vertices];
                            for (slice) |xs| {
                                sm.joints.appendAssumeCapacity([4]u8{
                                    @intCast(xs[0]),
                                    @intCast(xs[1]),
                                    @intCast(xs[2]),
                                    @intCast(xs[3]),
                                });
                            }
                        } else unreachable;
                    } else if (attrib.type == .weights) {
                        assert(accessor.type == .vec4);
                        try sm.weights.ensureTotalCapacity(sm.weights.items.len + num_vertices);
                        if (accessor.component_type == .r_32f) {
                            const slice = @as([*]const [4]f32, @ptrFromInt(data_addr))[0..num_vertices];
                            try sm.weights.appendSlice(slice);
                        } else if (accessor.component_type == .r_8u) {
                            const slice = @as([*]const [4]u8, @ptrFromInt(data_addr))[0..num_vertices];
                            for (slice) |xs| {
                                sm.weights.appendAssumeCapacity([4]f32{
                                    @as(f32, @floatFromInt(xs[0])) / 255.0,
                                    @as(f32, @floatFromInt(xs[1])) / 255.0,
                                    @as(f32, @floatFromInt(xs[2])) / 255.0,
                                    @as(f32, @floatFromInt(xs[3])) / 255.0,
                                });
                            }
                        } else if (accessor.component_type == .r_16u) {
                            const slice = @as([*]const [4]u16, @ptrFromInt(data_addr))[0..num_vertices];
                            for (slice) |xs| {
                                sm.weights.appendAssumeCapacity([4]f32{
                                    @as(f32, @floatFromInt(xs[0])) / 65535.0,
                                    @as(f32, @floatFromInt(xs[1])) / 65535.0,
                                    @as(f32, @floatFromInt(xs[2])) / 65535.0,
                                    @as(f32, @floatFromInt(xs[3])) / 65535.0,
                                });
                            }
                        } else unreachable;
                    }
                }
            }

            // Compute AABB
            if (opt.compute_aabb) sm.computeAabb();
        }
    }

    // Load children
    for (0..gltf_node.children_count) |node_index| {
        try self.loadNodeTree(ctx, dir, gltf_node.children.?[node_index], node, opt);
    }
}

fn loadAnimation(self: *Self, gltf_anim: GltfAnimation) !void {
    const name = try self.arena.allocator().dupe(
        u8,
        std.mem.sliceTo(gltf_anim.name orelse "default", 0),
    );
    errdefer self.arena.allocator().free(name);

    if (try Animation.fromGltfAnimation(self.arena.allocator(), self, gltf_anim, name)) |anim| {
        try self.animations.putNoClobber(name, anim);
    }
}

fn loadSkin(self: *Self, gltf_skin: *const GltfSkin) !void {
    const allocator = self.arena.allocator();
    const skin = try allocator.create(Skin);
    errdefer allocator.destroy(skin);
    skin.* = try Skin.fromGltfSkin(allocator, self, gltf_skin);
    try self.skins_map.putNoClobber(gltf_skin, skin);
}
