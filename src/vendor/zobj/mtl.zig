const std = @import("std");
const tokenizeAny = std.mem.tokenizeAny;
const Allocator = std.mem.Allocator;

const lineIterator = @import("utils.zig").lineIterator;

pub const MaterialData = struct {
    materials: std.StringHashMapUnmanaged(Material),

    pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
        var iter = self.materials.iterator();
        while (iter.next()) |m| {
            m.value_ptr.deinit(allocator);
            allocator.free(m.key_ptr.*);
        }
        self.materials.deinit(allocator);
    }

    const Builder = struct {
        allocator: Allocator,
        current_material: Material = .{},
        current_name: ?[]const u8 = null,
        materials: std.StringHashMapUnmanaged(Material) = .{},

        fn onError(self: *Builder) void {
            var iter = self.materials.iterator();
            while (iter.next()) |m| {
                m.value_ptr.deinit(self.allocator);
                self.allocator.free(m.key_ptr.*);
            }
            self.materials.deinit(self.allocator);
            if (self.current_name) |n|
                self.allocator.free(n);
        }

        fn finish(self: *Builder) !MaterialData {
            if (self.current_name) |nm|
                try self.materials.put(self.allocator, nm, self.current_material);
            return MaterialData{ .materials = self.materials };
        }

        fn new_material(self: *Builder, name: []const u8) !void {
            if (self.current_name) |n| {
                try self.materials.put(
                    self.allocator,
                    n,
                    self.current_material,
                );
                self.current_material = Material{};
            }
            self.current_name = try self.allocator.dupe(u8, name);
        }

        fn dupeTextureMap(self: *Builder, map: TextureMap) !TextureMap {
            return .{
                .path = try self.allocator.dupe(u8, map.path),
                .opts = try self.allocator.dupe(u8, map.opts),
            };
        }

        fn ambient_color(self: *Builder, rgb: [3]f32) !void {
            self.current_material.ambient_color = rgb;
        }
        fn diffuse_color(self: *Builder, rgb: [3]f32) !void {
            self.current_material.diffuse_color = rgb;
        }
        fn specular_color(self: *Builder, rgb: [3]f32) !void {
            self.current_material.specular_color = rgb;
        }
        fn specular_highlight(self: *Builder, v: f32) !void {
            self.current_material.specular_highlight = v;
        }
        fn emissive_coefficient(self: *Builder, rgb: [3]f32) !void {
            self.current_material.emissive_coefficient = rgb;
        }
        fn optical_density(self: *Builder, v: f32) !void {
            self.current_material.optical_density = v;
        }
        fn dissolve(self: *Builder, v: f32) !void {
            self.current_material.dissolve = v;
        }
        fn illumination(self: *Builder, v: u8) !void {
            self.current_material.illumination = v;
        }
        fn roughness(self: *Builder, v: f32) !void {
            self.current_material.roughness = v;
        }
        fn metallic(self: *Builder, v: f32) !void {
            self.current_material.metallic = v;
        }
        fn sheen(self: *Builder, v: f32) !void {
            self.current_material.sheen = v;
        }
        fn clearcoat_thickness(self: *Builder, v: f32) !void {
            self.current_material.clearcoat_thickness = v;
        }
        fn clearcoat_roughness(self: *Builder, v: f32) !void {
            self.current_material.clearcoat_roughness = v;
        }
        fn anisotropy(self: *Builder, v: f32) !void {
            self.current_material.anisotropy = v;
        }
        fn anisotropy_rotation(self: *Builder, v: f32) !void {
            self.current_material.anisotropy_rotation = v;
        }
        fn ambient_map(self: *Builder, map: TextureMap) !void {
            self.current_material.ambient_map = try self.dupeTextureMap(map);
        }
        fn diffuse_map(self: *Builder, map: TextureMap) !void {
            self.current_material.diffuse_map = try self.dupeTextureMap(map);
        }
        fn specular_color_map(self: *Builder, map: TextureMap) !void {
            self.current_material.specular_color_map = try self.dupeTextureMap(map);
        }
        fn specular_highlight_map(self: *Builder, map: TextureMap) !void {
            self.current_material.specular_highlight_map = try self.dupeTextureMap(map);
        }
        fn bump_map(self: *Builder, map: TextureMap) !void {
            self.current_material.bump_map = try self.dupeTextureMap(map);
        }
        fn roughness_map(self: *Builder, map: TextureMap) !void {
            self.current_material.roughness_map = try self.dupeTextureMap(map);
        }
        fn metallic_map(self: *Builder, map: TextureMap) !void {
            self.current_material.metallic_map = try self.dupeTextureMap(map);
        }
        fn sheen_map(self: *Builder, map: TextureMap) !void {
            self.current_material.sheen_map = try self.dupeTextureMap(map);
        }
        fn emissive_map(self: *Builder, map: TextureMap) !void {
            self.current_material.emissive_map = try self.dupeTextureMap(map);
        }
        fn normal_map(self: *Builder, map: TextureMap) !void {
            self.current_material.normal_map = try self.dupeTextureMap(map);
        }
    };
};

// NOTE: I'm not sure which material statements are optional. For now, I'm
// assuming all of them are.
pub const Material = struct {
    ambient_color: ?[3]f32 = null,
    diffuse_color: ?[3]f32 = null,
    specular_color: ?[3]f32 = null,
    specular_highlight: ?f32 = null,
    emissive_coefficient: ?[3]f32 = null,
    optical_density: ?f32 = null,
    dissolve: ?f32 = null,
    illumination: ?u8 = null,
    roughness: ?f32 = null,
    metallic: ?f32 = null,
    sheen: ?f32 = null,
    clearcoat_thickness: ?f32 = null,
    clearcoat_roughness: ?f32 = null,
    anisotropy: ?f32 = null,
    anisotropy_rotation: ?f32 = null,

    ambient_map: ?TextureMap = null,
    diffuse_map: ?TextureMap = null,
    specular_color_map: ?TextureMap = null,
    specular_highlight_map: ?TextureMap = null,
    bump_map: ?TextureMap = null,
    roughness_map: ?TextureMap = null,
    metallic_map: ?TextureMap = null,
    sheen_map: ?TextureMap = null,
    emissive_map: ?TextureMap = null,
    normal_map: ?TextureMap = null,

    pub fn deinit(self: *Material, allocator: Allocator) void {
        if (self.bump_map) |m| freeTextureMap(allocator, m);
        if (self.diffuse_map) |m| freeTextureMap(allocator, m);
        if (self.specular_color_map) |m| freeTextureMap(allocator, m);
        if (self.specular_highlight_map) |m| freeTextureMap(allocator, m);
        if (self.ambient_map) |m| freeTextureMap(allocator, m);
        if (self.roughness_map) |m| freeTextureMap(allocator, m);
        if (self.metallic_map) |m| freeTextureMap(allocator, m);
        if (self.sheen_map) |m| freeTextureMap(allocator, m);
        if (self.emissive_map) |m| freeTextureMap(allocator, m);
        if (self.normal_map) |m| freeTextureMap(allocator, m);
    }

    fn freeTextureMap(allocator: Allocator, map: TextureMap) void {
        allocator.free(map.path);
        allocator.free(map.opts);
    }
};

const Keyword = enum {
    comment,
    new_material,
    ambient_color,
    diffuse_color,
    specular_color,
    specular_highlight,
    emissive_coefficient,
    optical_density,
    dissolve,
    transparent,
    illumination,
    roughness,
    metallic,
    sheen,
    clearcoat_thickness,
    clearcoat_roughness,
    anisotropy,
    anisotropy_rotation,
    ambient_map,
    diffuse_map,
    specular_color_map,
    specular_highlight_map,
    bump_map,
    roughness_map,
    metallic_map,
    sheen_map,
    emissive_map,
    normal_map,
};

pub const TextureMap = struct { path: []const u8, opts: []const u8 };

pub fn parse(allocator: Allocator, data: []const u8) !MaterialData {
    var b = MaterialData.Builder{ .allocator = allocator };
    errdefer b.onError();
    var reader = std.Io.Reader.fixed(data);
    return try parseCustom(MaterialData, &b, &reader);
}

pub fn parseCustom(comptime T: type, b: *T.Builder, reader: anytype) !T {
    var buffer: [128]u8 = undefined;
    var lines = lineIterator(reader, &buffer);
    while (try lines.next()) |line| {
        var iter = tokenizeAny(u8, line, " ");
        const def_type =
            if (iter.next()) |tok| try parseKeyword(tok) else continue;
        switch (def_type) {
            .comment => {},
            .new_material => try b.new_material(iter.next().?),
            .ambient_color => try b.ambient_color(try parseVec3(&iter)),
            .diffuse_color => try b.diffuse_color(try parseVec3(&iter)),
            .specular_color => try b.specular_color(try parseVec3(&iter)),
            .specular_highlight => try b.specular_highlight(try parseF32(&iter)),
            .emissive_coefficient => try b.emissive_coefficient(try parseVec3(&iter)),
            .optical_density => try b.optical_density(try parseF32(&iter)),
            .dissolve => try b.dissolve(try parseF32(&iter)),
            .transparent => try b.dissolve(1.0 - try parseF32(&iter)),
            .illumination => try b.illumination(try parseU8(&iter)),
            .roughness => try b.roughness(try parseF32(&iter)),
            .metallic => try b.metallic(try parseF32(&iter)),
            .sheen => try b.sheen(try parseF32(&iter)),
            .clearcoat_thickness => try b.clearcoat_thickness(try parseF32(&iter)),
            .clearcoat_roughness => try b.clearcoat_roughness(try parseF32(&iter)),
            .anisotropy => try b.anisotropy(try parseF32(&iter)),
            .anisotropy_rotation => try b.anisotropy_rotation(try parseF32(&iter)),
            .ambient_map => try b.ambient_map(try parseTextureMap(&iter)),
            .diffuse_map => try b.diffuse_map(try parseTextureMap(&iter)),
            .specular_color_map => try b.specular_color_map(try parseTextureMap(&iter)),
            .specular_highlight_map => try b.specular_highlight_map(try parseTextureMap(&iter)),
            .bump_map => try b.bump_map(try parseTextureMap(&iter)),
            .roughness_map => try b.roughness_map(try parseTextureMap(&iter)),
            .metallic_map => try b.metallic_map(try parseTextureMap(&iter)),
            .sheen_map => try b.sheen_map(try parseTextureMap(&iter)),
            .emissive_map => try b.emissive_map(try parseTextureMap(&iter)),
            .normal_map => try b.normal_map(try parseTextureMap(&iter)),
        }
    }
    return try b.finish();
}

fn parseU8(iter: *std.mem.TokenIterator(u8, .any)) !u8 {
    return try std.fmt.parseInt(u8, iter.next().?, 10);
}

fn parseF32(iter: *std.mem.TokenIterator(u8, .any)) !f32 {
    return try std.fmt.parseFloat(f32, iter.next().?);
}

fn parseVec3(iter: *std.mem.TokenIterator(u8, .any)) ![3]f32 {
    const x = try std.fmt.parseFloat(f32, iter.next().?);
    const y = try std.fmt.parseFloat(f32, iter.next().?);
    const z = try std.fmt.parseFloat(f32, iter.next().?);
    return [_]f32{ x, y, z };
}

fn parseTextureMap(iter: *std.mem.TokenIterator(u8, .any)) !TextureMap {
    const start = iter.index;
    var end = iter.index;
    var path: []const u8 = "";
    while (iter.next()) |s| {
        if (iter.peek() != null) {
            end = iter.index;
        }
        path = s;
    }
    return .{
        .path = path,
        .opts = std.mem.trim(u8, iter.buffer[start..end], " "),
    };
}

fn parseKeyword(s: []const u8) !Keyword {
    if (std.ascii.eqlIgnoreCase(s, "#")) {
        return .comment;
    } else if (std.ascii.eqlIgnoreCase(s, "newmtl")) {
        return .new_material;
    } else if (std.ascii.eqlIgnoreCase(s, "Ka")) {
        return .ambient_color;
    } else if (std.ascii.eqlIgnoreCase(s, "Kd")) {
        return .diffuse_color;
    } else if (std.ascii.eqlIgnoreCase(s, "Ks")) {
        return .specular_color;
    } else if (std.ascii.eqlIgnoreCase(s, "Ns")) {
        return .specular_highlight;
    } else if (std.ascii.eqlIgnoreCase(s, "Ke")) {
        return .emissive_coefficient;
    } else if (std.ascii.eqlIgnoreCase(s, "Ni")) {
        return .optical_density;
    } else if (std.ascii.eqlIgnoreCase(s, "d")) {
        return .dissolve;
    } else if (std.ascii.eqlIgnoreCase(s, "tr")) {
        return .transparent;
    } else if (std.ascii.eqlIgnoreCase(s, "illum")) {
        return .illumination;
    } else if (std.ascii.eqlIgnoreCase(s, "Pr")) {
        return .roughness;
    } else if (std.ascii.eqlIgnoreCase(s, "Pm")) {
        return .metallic;
    } else if (std.ascii.eqlIgnoreCase(s, "Ps")) {
        return .sheen;
    } else if (std.ascii.eqlIgnoreCase(s, "Pc")) {
        return .clearcoat_thickness;
    } else if (std.ascii.eqlIgnoreCase(s, "Pcr")) {
        return .clearcoat_roughness;
    } else if (std.ascii.eqlIgnoreCase(s, "aniso")) {
        return .anisotropy;
    } else if (std.ascii.eqlIgnoreCase(s, "anisor")) {
        return .anisotropy_rotation;
    } else if (std.ascii.eqlIgnoreCase(s, "map_Ka")) {
        return .ambient_map;
    } else if (std.ascii.eqlIgnoreCase(s, "map_Kd")) {
        return .diffuse_map;
    } else if (std.ascii.eqlIgnoreCase(s, "map_Ks")) {
        return .specular_color_map;
    } else if (std.ascii.eqlIgnoreCase(s, "map_Ns")) {
        return .specular_highlight_map;
    } else if (std.ascii.eqlIgnoreCase(s, "map_Bump")) {
        return .bump_map;
    } else if (std.ascii.eqlIgnoreCase(s, "map_Pr")) {
        return .roughness_map;
    } else if (std.ascii.eqlIgnoreCase(s, "map_Pm")) {
        return .metallic_map;
    } else if (std.ascii.eqlIgnoreCase(s, "map_Ps")) {
        return .sheen_map;
    } else if (std.ascii.eqlIgnoreCase(s, "map_Ke")) {
        return .emissive_map;
    } else if (std.ascii.eqlIgnoreCase(s, "map_Norm")) {
        return .normal_map;
    } else {
        std.log.warn("Unknown keyword: {s}", .{s});
        return error.UnknownKeyword;
    }
}
