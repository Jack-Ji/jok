const std = @import("std");
const tokenizeAny = std.mem.tokenizeAny;
const splitAny = std.mem.splitAny;
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;
const parseFloat = std.fmt.parseFloat;
const parseInt = std.fmt.parseInt;

const lineIterator = @import("utils.zig").lineIterator;

pub const ObjData = struct {
    material_libs: []const []const u8,

    vertices: []const f32,
    tex_coords: []const f32,
    normals: []const f32,

    meshes: []const Mesh,

    pub fn deinit(self: *@This(), allocator: Allocator) void {
        for (self.material_libs) |mlib| allocator.free(mlib);
        allocator.free(self.material_libs);

        allocator.free(self.vertices);
        allocator.free(self.tex_coords);
        allocator.free(self.normals);

        for (self.meshes) |mesh| mesh.deinit(allocator);
        allocator.free(self.meshes);
    }

    const Builder = struct {
        allocator: Allocator,
        material_libs: std.ArrayList([]const u8) = .{},
        vertices: std.ArrayList(f32) = .{},
        tex_coords: std.ArrayList(f32) = .{},
        normals: std.ArrayList(f32) = .{},
        meshes: std.ArrayList(Mesh) = .{},

        // current mesh
        name: ?[]const u8 = null,
        num_verts: std.ArrayList(u32) = .{},
        indices: std.ArrayList(Mesh.Index) = .{},
        index_i: u32 = 0,

        // current mesh material
        current_material: ?MeshMaterial = null,
        mesh_materials: std.ArrayList(MeshMaterial) = .{},
        num_processed_verts: usize = 0,

        fn onError(self: *Builder) void {
            for (self.material_libs.items) |mlib| self.allocator.free(mlib);
            for (self.meshes.items) |mesh| mesh.deinit(self.allocator);
            self.material_libs.deinit(self.allocator);
            self.vertices.deinit(self.allocator);
            self.tex_coords.deinit(self.allocator);
            self.normals.deinit(self.allocator);
            self.meshes.deinit(self.allocator);
            if (self.name) |n| self.allocator.free(n);
            self.num_verts.deinit(self.allocator);
            self.indices.deinit(self.allocator);
            if (self.current_material) |mat| self.allocator.free(mat.material);
            self.mesh_materials.deinit(self.allocator);
        }

        fn finish(self: *Builder) !ObjData {
            defer self.* = undefined;
            try self.use_material(null); // add last material if any
            try self.object(null); // add last mesh (as long as it is not empty)
            return ObjData{
                .material_libs = try self.material_libs.toOwnedSlice(self.allocator),
                .vertices = try self.vertices.toOwnedSlice(self.allocator),
                .tex_coords = try self.tex_coords.toOwnedSlice(self.allocator),
                .normals = try self.normals.toOwnedSlice(self.allocator),
                .meshes = try self.meshes.toOwnedSlice(self.allocator),
            };
        }

        fn vertex(self: *Builder, x: f32, y: f32, z: f32, w: ?f32) !void {
            _ = w;
            try self.vertices.appendSlice(self.allocator, &.{ x, y, z });
        }

        fn tex_coord(self: *Builder, u: f32, v: ?f32, w: ?f32) !void {
            _ = w;
            try self.tex_coords.appendSlice(self.allocator, &.{ u, v.? });
        }

        fn normal(self: *Builder, i: f32, j: f32, k: f32) !void {
            try self.normals.appendSlice(self.allocator, &.{ i, j, k });
        }

        fn face_index(self: *Builder, vert: u32, tex: ?u32, norm: ?u32) !void {
            try self.indices.append(
                self.allocator,
                .{ .vertex = vert, .tex_coord = tex, .normal = norm },
            );
            self.index_i += 1;
        }

        fn face_end(self: *Builder) !void {
            try self.num_verts.append(self.allocator, self.index_i);
            self.num_processed_verts += self.index_i;
            self.index_i = 0;
        }

        fn object(self: *Builder, name: ?[]const u8) !void {
            if (0 < self.num_verts.items.len) {
                if (self.current_material) |*m| {
                    m.end_index = self.num_processed_verts;
                    try self.mesh_materials.append(self.allocator, m.*);
                }
                try self.meshes.append(self.allocator, .{
                    .name = self.name,
                    .num_vertices = try self.num_verts.toOwnedSlice(self.allocator),
                    .indices = try self.indices.toOwnedSlice(self.allocator),
                    .materials = try self.mesh_materials.toOwnedSlice(self.allocator),
                });
            }
            if (name) |n| {
                self.name = try self.allocator.dupe(u8, n);
                self.num_verts = .{};
                self.indices = .{};
                self.num_processed_verts = 0;
                self.current_material = null;
            }
        }

        fn use_material(self: *Builder, name: ?[]const u8) !void {
            if (self.current_material) |*m| {
                m.end_index = self.num_processed_verts;
                try self.mesh_materials.append(self.allocator, m.*);
            }
            if (name) |n| {
                self.current_material = MeshMaterial{
                    .material = try self.allocator.dupe(u8, n),
                    .start_index = self.num_processed_verts,
                    .end_index = self.num_processed_verts + 1,
                };
            } else {
                self.current_material = null;
            }
        }

        fn material_lib(self: *Builder, name: []const u8) !void {
            try self.material_libs.append(
                self.allocator,
                try self.allocator.dupe(u8, name),
            );
        }

        fn vertexCount(self: Builder) usize {
            return self.vertices.items.len;
        }

        fn texCoordCount(self: Builder) usize {
            return self.tex_coords.items.len;
        }

        fn normalCount(self: Builder) usize {
            return self.normals.items.len;
        }
    };
};

fn compareOpt(a: ?u32, b: ?u32) bool {
    if (a != null and b != null) {
        return a.? == b.?;
    }

    return a == null and b == null;
}

fn eqlZ(comptime T: type, a: ?[]const T, b: ?[]const T) bool {
    if (a != null and b != null) {
        return std.mem.eql(T, a.?, b.?);
    }

    return a == null and b == null;
}

pub const MeshMaterial = struct {
    material: []const u8,
    start_index: usize,
    end_index: usize,

    fn eq(self: MeshMaterial, other: MeshMaterial) bool {
        return std.mem.eql(u8, self.material, other.material) and
            self.start_index == other.start_index and
            self.end_index == other.end_index;
    }
};

pub const Mesh = struct {
    pub const Index = struct {
        vertex: ?u32,
        tex_coord: ?u32,
        normal: ?u32,

        fn eq(self: Mesh.Index, other: Mesh.Index) bool {
            return compareOpt(self.vertex, other.vertex) and
                compareOpt(self.tex_coord, other.tex_coord) and
                compareOpt(self.normal, other.normal);
        }
    };

    name: ?[]const u8,

    // Number of vertices for each face
    num_vertices: []const u32,
    indices: []const Mesh.Index,

    materials: []const MeshMaterial,

    pub fn deinit(self: Mesh, allocator: Allocator) void {
        if (self.name) |name| allocator.free(name);
        allocator.free(self.num_vertices);
        allocator.free(self.indices);
        for (self.materials) |mat| {
            allocator.free(mat.material);
        }
        allocator.free(self.materials);
    }

    // TODO Use std.meta magic?
    fn eq(self: Mesh, other: Mesh) bool {
        if (!eqlZ(u8, self.name, other.name)) return false;
        if (self.indices.len != other.indices.len) return false;
        if (!std.mem.eql(u32, self.num_vertices, other.num_vertices)) return false;
        for (self.indices, 0..) |index, i| {
            if (!index.eq(other.indices[i])) return false;
        }
        for (self.materials, 0..) |mat, i| {
            if (!mat.eq(other.materials[i])) return false;
        }
        return true;
    }
};

const DefType = enum {
    comment,
    vertex,
    tex_coord,
    normal,
    face,
    object,
    group,
    material_lib,
    use_material,
    smoothing,
    line,
    param_vertex,
};

pub fn parse(allocator: Allocator, data: []const u8) !ObjData {
    var b = ObjData.Builder{ .allocator = allocator };
    errdefer b.onError();
    var fbs = std.io.fixedBufferStream(data);
    return try parseCustom(ObjData, &b, fbs.reader());
}

pub fn parseCustom(comptime T: type, b: *T.Builder, reader: anytype) !T {
    var buffer: [1024]u8 = undefined;
    var lines = lineIterator(reader, &buffer);
    while (try lines.next()) |line| {
        var iter = tokenizeAny(u8, line, " ");
        const def_type =
            if (iter.next()) |tok| try parseType(tok) else continue;
        switch (def_type) {
            .vertex => try b.vertex(
                try parseFloat(f32, iter.next().?),
                try parseFloat(f32, iter.next().?),
                try parseFloat(f32, iter.next().?),
                if (iter.next()) |w| (try parseFloat(f32, w)) else null,
            ),
            .tex_coord => try b.tex_coord(
                try parseFloat(f32, iter.next().?),
                if (iter.next()) |v| (try parseFloat(f32, v)) else null,
                if (iter.next()) |w| (try parseFloat(f32, w)) else null,
            ),
            .normal => try b.normal(
                try parseFloat(f32, iter.next().?),
                try parseFloat(f32, iter.next().?),
                try parseFloat(f32, iter.next().?),
            ),
            .face => {
                while (iter.next()) |entry| {
                    var entry_iter = splitAny(u8, entry, "/");
                    try b.face_index(
                        (try parseOptionalIndex(entry_iter.next().?, b.vertexCount())).?,
                        if (entry_iter.next()) |e| (try parseOptionalIndex(e, b.texCoordCount())) else null,
                        if (entry_iter.next()) |e| (try parseOptionalIndex(e, b.normalCount())) else null,
                    );
                }
                try b.face_end();
            },
            .object => try b.object(iter.next().?),
            .use_material => try b.use_material(iter.next().?),
            .material_lib => while (iter.next()) |lib| try b.material_lib(lib),
            else => {},
        }
    }

    return try b.finish();
}

fn parseOptionalIndex(v: []const u8, n_items: usize) !?u32 {
    if (std.mem.eql(u8, v, "")) return null;
    const i = try parseInt(i32, v, 10);

    if (i < 0) {
        // index is relative to end of indices list, -1 meaning the last element
        return @as(u32, @intCast(@as(i32, @intCast(n_items)) + i));
    } else {
        // obj is one-indexed - let's make it zero-indexed
        return @as(u32, @intCast(i)) - 1;
    }
}

fn parseType(t: []const u8) !DefType {
    if (std.mem.eql(u8, t, "#")) {
        return .comment;
    } else if (std.mem.eql(u8, t, "v")) {
        return .vertex;
    } else if (std.mem.eql(u8, t, "vt")) {
        return .tex_coord;
    } else if (std.mem.eql(u8, t, "vn")) {
        return .normal;
    } else if (std.mem.eql(u8, t, "f")) {
        return .face;
    } else if (std.mem.eql(u8, t, "o")) {
        return .object;
    } else if (std.mem.eql(u8, t, "g")) {
        return .group;
    } else if (std.mem.eql(u8, t, "mtllib")) {
        return .material_lib;
    } else if (std.mem.eql(u8, t, "usemtl")) {
        return .use_material;
    } else if (std.mem.eql(u8, t, "s")) {
        return .smoothing;
    } else if (std.mem.eql(u8, t, "l")) {
        return .line;
    } else if (std.mem.eql(u8, t, "vp")) {
        return .param_vertex;
    } else {
        return error.UnknownDefType;
    }
}
