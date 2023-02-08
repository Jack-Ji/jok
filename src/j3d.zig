const std = @import("std");
const assert = std.debug.assert;
const math = std.math;
const sdl = @import("sdl");
const jok = @import("jok.zig");
const imgui = jok.imgui;
const zmath = jok.zmath;
const zmesh = jok.zmesh;

const internal = @import("j3d/internal.zig");
const TriangleRenderer = @import("j3d/TriangleRenderer.zig");
const SkyboxRenderer = @import("j3d/SkyboxRenderer.zig");
pub const lighting = @import("j3d/lighting.zig");
pub const ParticleSystem = @import("j3d/ParticleSystem.zig");
pub const Camera = @import("j3d/Camera.zig");
pub const Scene = @import("j3d/Scene.zig");
pub const Vector = @import("j3d/Vector.zig");

pub const RenderOption = struct {
    texture: ?sdl.Texture = null,
    color: sdl.Color = sdl.Color.white,
    cull_faces: bool = true,
    lighting: ?lighting.LightingOption = null,
};

pub const BeginOption = struct {
    camera: ?Camera = null,
    sort_by_depth: bool = false,
    wireframe_color: ?sdl.Color = null,
};

pub const RenderTarget = struct {
    indices: std.ArrayList(u32),
    batched_indices: std.ArrayList(u32),
    vertices: std.ArrayList(sdl.Vertex),
    depths: std.ArrayList(f32),
    textures: std.ArrayList(?sdl.Texture),
    draw_list: imgui.DrawList,

    fn init(_allocator: std.mem.Allocator) RenderTarget {
        return .{
            .indices = std.ArrayList(u32).init(_allocator),
            .batched_indices = std.ArrayList(u32).init(_allocator),
            .vertices = std.ArrayList(sdl.Vertex).init(_allocator),
            .depths = std.ArrayList(f32).init(_allocator),
            .textures = std.ArrayList(?sdl.Texture).init(_allocator),
            .draw_list = imgui.createDrawList(),
        };
    }

    fn deinit(self: *RenderTarget) void {
        self.indices.deinit();
        self.batched_indices.deinit();
        self.vertices.deinit();
        self.depths.deinit();
        self.textures.deinit();
        imgui.destroyDrawList(self.draw_list);
        self.* = undefined;
    }

    fn clear(self: *RenderTarget, recycle_memory: bool) void {
        self.draw_list.reset();
        self.draw_list.pushClipRectFullScreen();
        self.draw_list.setDrawListFlags(.{
            .anti_aliased_lines = true,
            .anti_aliased_lines_use_tex = false,
            .anti_aliased_fill = true,
            .allow_vtx_offset = true,
        });
        if (recycle_memory) {
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

    // Sort triangles by depth and texture values
    fn compareTriangles(self: *RenderTarget, lhs: [3]u32, rhs: [3]u32) bool {
        const l_idx0 = lhs[0];
        const l_idx1 = lhs[1];
        const l_idx2 = lhs[2];
        const r_idx0 = rhs[0];
        const r_idx1 = rhs[1];
        const r_idx2 = rhs[2];
        const d0 = (self.depths.items[l_idx0] + self.depths.items[l_idx1] + self.depths.items[l_idx2]) / 3.0;
        const d1 = (self.depths.items[r_idx0] + self.depths.items[r_idx1] + self.depths.items[r_idx2]) / 3.0;
        if (math.approxEqAbs(f32, d0, d1, 0.00001)) {
            const tex0 = self.textures.items[l_idx0];
            const tex1 = self.textures.items[r_idx0];
            if (tex0 != null and tex1 != null) {
                const ptr0 = @ptrToInt(tex0.?.ptr);
                const ptr1 = @ptrToInt(tex1.?.ptr);
                return if (ptr0 == ptr1) d0 > d1 else ptr0 > ptr1;
            } else if (tex0 != null or tex1 != null) {
                return tex0 == null;
            }
        }
        return d0 > d1;
    }

    fn sortTriangles(self: *RenderTarget) void {
        var _indices: [][3]u32 = undefined;
        _indices.ptr = @ptrCast([*][3]u32, self.indices.items.ptr);
        _indices.len = @divTrunc(self.indices.items.len, 3);
        std.sort.sort(
            [3]u32,
            _indices,
            self,
            RenderTarget.compareTriangles,
        );
    }

    inline fn drawTriangles(self: RenderTarget, color: sdl.Color) void {
        const col = imgui.sdl.convertColor(color);
        var i: u32 = 0;
        while (i < self.indices.items.len) : (i += 3) {
            const v0 = self.vertices.items[target.indices.items[i]];
            const v1 = self.vertices.items[target.indices.items[i + 1]];
            const v2 = self.vertices.items[target.indices.items[i + 2]];
            self.draw_list.addTriangle(.{
                .p1 = .{ v0.position.x, v0.position.y },
                .p2 = .{ v1.position.x, v1.position.y },
                .p3 = .{ v2.position.x, v2.position.y },
                .col = col,
            });
        }
    }

    pub inline fn appendTrianglesAssumeCapacity(
        self: *RenderTarget,
        indices: []const u32,
        vertices: []const sdl.Vertex,
        depths: []const f32,
        textures: []?sdl.Texture,
    ) !void {
        assert(@rem(indices.len, 3) == 0);
        assert(vertices.len == depths.len);
        assert(vertices.len == textures.len);

        if (self.batched_indices.items.len == 0) {
            try self.batched_indices.append(indices.len);
        } else {
            const last_texture = self.textures.items[self.textures.items.len - 1];
            if (internal.isSameTexture(last_texture, textures[0])) {
                self.batched_indices.items[self.batched_indices.items.len - 1] += @intCast(u32, indices.len);
            } else {
                try self.batched_indices.append(indices.len);
            }
        }

        const current_index: u32 = @intCast(u32, self.vertices.items.len);
        for (indices) |idx| {
            self.indices.appendAssumeCapacity(idx + current_index);
        }
        self.vertices.appendSliceAssumeCapacity(vertices);
        self.depths.appendSliceAssumeCapacity(depths);
        self.textures.appendSliceAssumeCapacity(textures);
    }
};

var allocator: std.mem.Allocator = undefined;
var arena: std.heap.ArenaAllocator = undefined;
var rd: sdl.Renderer = undefined;
var target: RenderTarget = undefined;
var tri_rd: TriangleRenderer = undefined;
var skybox_rd: SkyboxRenderer = undefined;
var all_shapes: std.ArrayList(zmesh.Shape) = undefined;
var camera: Camera = undefined;
var sort_by_depth: bool = undefined;
var wireframe_color: ?sdl.Color = undefined;

pub fn init(_allocator: std.mem.Allocator, _rd: sdl.Renderer) !void {
    allocator = _allocator;
    arena = std.heap.ArenaAllocator.init(allocator);
    rd = _rd;
    target = RenderTarget.init(allocator);
    tri_rd = TriangleRenderer.init(allocator);
    skybox_rd = SkyboxRenderer.init(allocator, .{});
    all_shapes = std.ArrayList(zmesh.Shape).init(arena.allocator());
}

pub fn deinit() void {
    for (all_shapes.items) |s| s.deinit();
    tri_rd.deinit();
    skybox_rd.deinit();
    target.deinit();
    arena.deinit();
}

pub fn begin(opt: BeginOption) !void {
    target.clear(false);
    camera = opt.camera orelse BLK: {
        const fsize = try rd.getOutputSize();
        const ratio = @intToFloat(f32, fsize.width_pixels) / @intToFloat(f32, fsize.width_pixels);
        break :BLK Camera.fromPositionAndTarget(
            .{
                .perspective = .{
                    .fov = math.pi / 4.0,
                    .aspect_ratio = ratio,
                    .near = 0.1,
                    .far = 100,
                },
            },
            .{ 0, 0, -1 },
            .{ 0, 0, 0 },
            null,
        );
    };
    sort_by_depth = opt.sort_by_depth;
    wireframe_color = opt.wireframe_color;
}

pub fn end() !void {
    if (target.indices.items.len == 0) return;
    assert(@rem(target.indices.items.len, 3) == 0);

    if (wireframe_color) |wc| {
        target.drawTriangles(wc);
    } else {
        if (sort_by_depth) {
            if (sort_by_depth) {
                target.sortTriangles();
            }

            // Scan vertices and send them in batches
            var offset: usize = 0;
            var last_texture: ?sdl.Texture = null;
            var i: usize = 0;
            while (i < target.indices.items.len) : (i += 3) {
                const idx = target.indices.items[i];
                if (i > 0 and !internal.isSameTexture(target.textures.items[idx], last_texture)) {
                    try rd.drawGeometry(
                        last_texture,
                        target.vertices.items,
                        target.indices.items[offset..i],
                    );
                    offset = i;
                }
                last_texture = target.textures.items[idx];
            }
            try rd.drawGeometry(
                last_texture,
                target.vertices.items,
                target.indices.items[offset..],
            );
        } else { // Send pre-batched vertices directly
            var offset: u32 = 0;
            for (target.batched_indices.items) |size| {
                assert(size % 3 == 0);
                try rd.drawGeometry(
                    target.textures.items[target.indices.items[offset]],
                    target.vertices.items,
                    target.indices.items[offset .. offset + size],
                );
                offset += size;
            }
            assert(offset == @intCast(u32, target.indices.items.len));
        }
    }
    imgui.sdl.renderDrawList(rd, target.draw_list) catch unreachable;
}

pub fn clearMemory() void {
    target.clear(true);
}

pub fn addSkybox(textures: [6]sdl.Texture, color: ?sdl.Color) !void {
    try skybox_rd.render(
        rd.getViewport(),
        &target,
        camera,
        textures,
        color,
    );
}

pub fn addScene(scene: *const Scene, opt: Scene.RenderOption) !void {
    try scene.render(
        &tri_rd,
        rd.getViewport(),
        &target,
        camera,
        opt,
    );
}

pub fn addEffects(ps: *ParticleSystem) !void {
    for (ps.effects.items) |eff| {
        try eff.render(
            &tri_rd,
            rd.getViewport(),
            &target,
            camera,
        );
    }
}

pub fn addSprite(
    model: zmath.Mat,
    pos: [3]f32,
    size: sdl.PointF,
    uv: [2]sdl.PointF,
    opt: TriangleRenderer.SpriteOption,
) !void {
    try tri_rd.renderSprite(
        rd.getViewport(),
        &target,
        model,
        camera,
        pos,
        size,
        uv,
        opt,
    );
}

pub fn addShape(
    shape: zmesh.Shape,
    model: zmath.Mat,
    aabb: ?[6]f32,
    opt: RenderOption,
) !void {
    try tri_rd.renderMesh(
        rd.getViewport(),
        &target,
        model,
        camera,
        shape.indices,
        shape.positions,
        shape.normals.?,
        null,
        shape.texcoords,
        .{
            .aabb = aabb,
            .cull_faces = opt.cull_faces,
            .color = opt.color,
            .texture = opt.texture,
            .lighting_opt = opt.lighting,
        },
    );
}

pub const AddMesh = struct {
    rdopt: RenderOption = .{},
    aabb: ?[6]f32 = null,
};
pub fn addMesh(
    model: zmath.Mat,
    indices: []const u16,
    positions: []const [3]f32,
    normals: []const [3]f32,
    colors: ?[]const sdl.Color,
    texcoords: ?[]const [2]f32,
    opt: RenderOption,
) !void {
    try tri_rd.renderMesh(
        rd.getViewport(),
        &target,
        model,
        camera,
        indices,
        positions,
        normals,
        colors,
        texcoords,
        .{
            .aabb = opt.aabb,
            .cull_faces = opt.rdopt.cull_faces,
            .color = opt.rdopt.color,
            .texture = opt.rdopt.texture,
            .lighting_opt = opt.rdopt.lighting,
        },
    );
}

pub const CubeDrawOption = struct {
    rdopt: RenderOption = .{},
    weld_threshold: ?f32 = null,
};
pub fn addCube(model: zmath.Mat, opt: CubeDrawOption) !void {
    const S = struct {
        const Mesh = struct {
            shape: zmesh.Shape,
            aabb: [6]f32,
        };

        var meshes: ?std.StringHashMap(*Mesh) = null;
        var buf: [32]u8 = undefined;

        fn getKey(_opt: CubeDrawOption) []u8 {
            return std.fmt.bufPrint(
                &buf,
                "{?:.5}",
                .{_opt.weld_threshold},
            ) catch unreachable;
        }
    };

    if (S.meshes == null) {
        S.meshes = std.StringHashMap(*S.Mesh).init(arena.allocator());
    }

    var mesh = BLK: {
        const key = S.getKey(opt);
        if (S.meshes.?.get(key)) |s| {
            break :BLK s;
        }

        var m = try arena.allocator().create(S.Mesh);
        m.shape = zmesh.Shape.initCube();
        m.shape.unweld();
        if (opt.weld_threshold) |w| {
            m.shape.weld(w, null);
        }
        m.shape.computeNormals();
        m.aabb = m.shape.computeAabb();
        all_shapes.append(m.shape) catch unreachable;
        try S.meshes.?.put(try arena.allocator().dupe(u8, key), m);
        break :BLK m;
    };

    try addShape(mesh.shape, model, camera, mesh.aabb, opt.rdopt);
}

pub const PlaneDrawOption = struct {
    rdopt: RenderOption = .{},
    weld_threshold: ?f32 = null,
    slices: u32 = 10,
    stacks: u32 = 10,
};
pub fn addPlane(model: zmath.Mat, opt: PlaneDrawOption) !void {
    const S = struct {
        const Mesh = struct {
            shape: zmesh.Shape,
            aabb: [6]f32,
        };

        var meshes: ?std.StringHashMap(*Mesh) = null;
        var buf: [32]u8 = undefined;

        fn getKey(_opt: PlaneDrawOption) []u8 {
            return std.fmt.bufPrint(
                &buf,
                "{?:.5}-{d}-{d}",
                .{ _opt.weld_threshold, _opt.slices, _opt.stacks },
            ) catch unreachable;
        }
    };

    if (S.meshes == null) {
        S.meshes = std.StringHashMap(*S.Mesh).init(arena.allocator());
    }

    var mesh = BLK: {
        assert(opt.slices > 0);
        assert(opt.stacks > 0);
        const key = S.getKey(opt);
        if (S.meshes.?.get(key)) |s| {
            break :BLK s;
        }

        var m = try arena.allocator().create(S.Mesh);
        m.shape = zmesh.Shape.initPlane(@intCast(i32, opt.slices), @intCast(i32, opt.stacks));
        m.shape.unweld();
        if (opt.weld_threshold) |w| {
            m.shape.weld(w, null);
        }
        m.shape.computeNormals();
        m.aabb = m.shape.computeAabb();
        all_shapes.append(m.shape) catch unreachable;
        try S.meshes.?.put(try arena.allocator().dupe(u8, key), m);
        break :BLK m;
    };

    try addShape(mesh.shape, model, mesh.aabb, opt.rdopt);
}

pub const ParametricSphereDrawOption = struct {
    rdopt: RenderOption = .{},
    weld_threshold: ?f32 = null,
    slices: u32 = 15,
    stacks: u32 = 15,
};
pub fn addParametricSphere(model: zmath.Mat, opt: ParametricSphereDrawOption) !void {
    const S = struct {
        const Mesh = struct {
            shape: zmesh.Shape,
            aabb: [6]f32,
        };

        var meshes: ?std.StringHashMap(*Mesh) = null;
        var buf: [32]u8 = undefined;

        fn getKey(_opt: ParametricSphereDrawOption) []u8 {
            return std.fmt.bufPrint(
                &buf,
                "{?:.5}-{d}-{d}",
                .{ _opt.weld_threshold, _opt.slices, _opt.stacks },
            ) catch unreachable;
        }
    };

    if (S.meshes == null) {
        S.meshes = std.StringHashMap(*S.Mesh).init(arena.allocator());
    }

    var mesh = BLK: {
        assert(opt.slices > 0);
        assert(opt.stacks > 0);
        const key = S.getKey(opt);
        if (S.meshes.?.get(key)) |s| {
            break :BLK s;
        }

        var m = try arena.allocator().create(S.Mesh);
        m.shape = zmesh.Shape.initParametricSphere(@intCast(i32, opt.slices), @intCast(i32, opt.stacks));
        m.shape.unweld();
        if (opt.weld_threshold) |w| {
            m.shape.weld(w, null);
        }
        m.shape.computeNormals();
        m.aabb = m.shape.computeAabb();
        all_shapes.append(m.shape) catch unreachable;
        try S.meshes.?.put(try arena.allocator().dupe(u8, key), m);
        break :BLK m;
    };

    try addShape(mesh.shape, model, mesh.aabb, opt.rdopt);
}

pub const SubdividedSphereDrawOption = struct {
    rdopt: RenderOption = .{},
    weld_threshold: ?f32 = null,
    sub_num: u32 = 2,
};
pub fn addSubdividedSphere(model: zmath.Mat, opt: SubdividedSphereDrawOption) !void {
    const S = struct {
        const Mesh = struct {
            shape: zmesh.Shape,
            aabb: [6]f32,
        };

        var meshes: ?std.StringHashMap(*Mesh) = null;
        var buf: [32]u8 = undefined;

        fn getKey(_opt: SubdividedSphereDrawOption) []u8 {
            return std.fmt.bufPrint(
                &buf,
                "{?:.5}-{d}",
                .{ _opt.weld_threshold, _opt.sub_num },
            ) catch unreachable;
        }
    };

    if (S.meshes == null) {
        S.meshes = std.StringHashMap(*S.Mesh).init(arena.allocator());
    }

    var mesh = BLK: {
        assert(opt.sub_num > 0);
        const key = S.getKey(opt);
        if (S.meshes.?.get(key)) |s| {
            break :BLK s;
        }

        var m = try arena.allocator().create(S.Mesh);
        m.shape = zmesh.Shape.initSubdividedSphere(@intCast(i32, opt.sub_num));
        m.shape.unweld();
        if (opt.weld_threshold) |w| {
            m.shape.weld(w, null);
        }
        m.shape.computeNormals();
        m.aabb = m.shape.computeAabb();
        all_shapes.append(m.shape) catch unreachable;
        try S.meshes.?.put(try arena.allocator().dupe(u8, key), m);
        break :BLK m;
    };

    try addShape(mesh.shape, model, mesh.aabb, opt.rdopt);
}

pub const HemisphereDrawOption = struct {
    rdopt: RenderOption = .{},
    weld_threshold: ?f32 = null,
    slices: u32 = 15,
    stacks: u32 = 15,
};
pub fn addHemisphere(model: zmath.Mat, opt: HemisphereDrawOption) !void {
    const S = struct {
        const Mesh = struct {
            shape: zmesh.Shape,
            aabb: [6]f32,
        };

        var meshes: ?std.StringHashMap(*Mesh) = null;
        var buf: [32]u8 = undefined;

        fn getKey(_opt: HemisphereDrawOption) []u8 {
            return std.fmt.bufPrint(
                &buf,
                "{?:.5}-{d}-{d}",
                .{ _opt.weld_threshold, _opt.slices, _opt.stacks },
            ) catch unreachable;
        }
    };

    if (S.meshes == null) {
        S.meshes = std.StringHashMap(*S.Mesh).init(arena.allocator());
    }

    var mesh = BLK: {
        assert(opt.slices > 0);
        assert(opt.stacks > 0);
        const key = S.getKey(opt);
        if (S.meshes.?.get(key)) |s| {
            break :BLK s;
        }

        var m = try arena.allocator().create(S.Mesh);
        m.shape = zmesh.Shape.initHemisphere(@intCast(i32, opt.slices), @intCast(i32, opt.stacks));
        m.shape.unweld();
        if (opt.weld_threshold) |w| {
            m.shape.weld(w, null);
        }
        m.shape.computeNormals();
        m.aabb = m.shape.computeAabb();
        all_shapes.append(m.shape) catch unreachable;
        try S.meshes.?.put(try arena.allocator().dupe(u8, key), m);
        break :BLK m;
    };

    try addShape(mesh.shape, model, mesh.aabb, opt.rdopt);
}

pub const ConeDrawOption = struct {
    rdopt: RenderOption = .{},
    weld_threshold: ?f32 = null,
    slices: u32 = 15,
    stacks: u32 = 1,
};
pub fn addCone(model: zmath.Mat, opt: ConeDrawOption) !void {
    const S = struct {
        const Mesh = struct {
            shape: zmesh.Shape,
            aabb: [6]f32,
        };

        var meshes: ?std.StringHashMap(*Mesh) = null;
        var buf: [32]u8 = undefined;

        fn getKey(_opt: ConeDrawOption) []u8 {
            return std.fmt.bufPrint(
                &buf,
                "{?:.5}-{d}-{d}",
                .{ _opt.weld_threshold, _opt.slices, _opt.stacks },
            ) catch unreachable;
        }
    };

    if (S.meshes == null) {
        S.meshes = std.StringHashMap(*S.Mesh).init(arena.allocator());
    }

    var mesh = BLK: {
        assert(opt.slices > 0);
        assert(opt.stacks > 0);
        const key = S.getKey(opt);
        if (S.meshes.?.get(key)) |s| {
            break :BLK s;
        }

        var m = try arena.allocator().create(S.Mesh);
        m.shape = zmesh.Shape.initCone(@intCast(i32, opt.slices), @intCast(i32, opt.stacks));
        m.shape.unweld();
        if (opt.weld_threshold) |w| {
            m.shape.weld(w, null);
        }
        m.shape.computeNormals();
        m.aabb = m.shape.computeAabb();
        all_shapes.append(m.shape) catch unreachable;
        try S.meshes.?.put(try arena.allocator().dupe(u8, key), m);
        break :BLK m;
    };

    try addShape(mesh.shape, model, mesh.aabb, opt.rdopt);
}

pub const CylinderDrawOption = struct {
    rdopt: RenderOption = .{},
    weld_threshold: ?f32 = null,
    slices: u32 = 20,
    stacks: u32 = 1,
};
pub fn addCylinder(model: zmath.Mat, opt: CylinderDrawOption) !void {
    const S = struct {
        const Mesh = struct {
            shape: zmesh.Shape,
            aabb: [6]f32,
        };

        var meshes: ?std.StringHashMap(*Mesh) = null;
        var buf: [32]u8 = undefined;

        fn getKey(_opt: CylinderDrawOption) []u8 {
            return std.fmt.bufPrint(
                &buf,
                "{?:.5}-{d}-{d}",
                .{ _opt.weld_threshold, _opt.slices, _opt.stacks },
            ) catch unreachable;
        }
    };

    if (S.meshes == null) {
        S.meshes = std.StringHashMap(*S.Mesh).init(arena.allocator());
    }

    var mesh = BLK: {
        assert(opt.slices > 0);
        assert(opt.stacks > 0);
        const key = S.getKey(opt);
        if (S.meshes.?.get(key)) |s| {
            break :BLK s;
        }

        var m = try arena.allocator().create(S.Mesh);
        m.shape = zmesh.Shape.initCylinder(@intCast(i32, opt.slices), @intCast(i32, opt.stacks));
        m.shape.unweld();
        if (opt.weld_threshold) |w| {
            m.shape.weld(w, null);
        }
        m.shape.computeNormals();
        m.aabb = m.shape.computeAabb();
        all_shapes.append(m.shape) catch unreachable;
        try S.meshes.?.put(try arena.allocator().dupe(u8, key), m);
        break :BLK m;
    };

    try addShape(mesh.shape, model, mesh.aabb, opt.rdopt);
}

pub const DiskDrawOption = struct {
    rdopt: RenderOption = .{},
    weld_threshold: ?f32 = null,
    radius: f32 = 1,
    slices: u32 = 20,
    center: [3]f32 = .{ 0, 0, 0 },
    normal: [3]f32 = .{ 0, 0, 1 },
};
pub fn addDisk(model: zmath.Mat, opt: DiskDrawOption) !void {
    const S = struct {
        const Mesh = struct {
            shape: zmesh.Shape,
            aabb: [6]f32,
        };

        var meshes: ?std.StringHashMap(*Mesh) = null;
        var buf: [64]u8 = undefined;

        fn getKey(_opt: DiskDrawOption) []u8 {
            return std.fmt.bufPrint(
                &buf,
                "{?:.5}-{d:.3}-{d}-({d:.3}/{d:.3}/{d:.3})-({d:.3}/{d:.3}/{d:.3})",
                .{
                    _opt.weld_threshold, _opt.radius,    _opt.slices,
                    _opt.center[0],      _opt.center[1], _opt.center[2],
                    _opt.normal[0],      _opt.normal[1], _opt.normal[2],
                },
            ) catch unreachable;
        }
    };

    if (S.meshes == null) {
        S.meshes = std.StringHashMap(*S.Mesh).init(arena.allocator());
    }

    var mesh = BLK: {
        assert(opt.radius > 0);
        assert(opt.slices > 0);
        const key = S.getKey(opt);
        if (S.meshes.?.get(key)) |s| {
            break :BLK s;
        }

        var m = try arena.allocator().create(S.Mesh);
        m.shape = zmesh.Shape.initDisk(opt.radius, @intCast(i32, opt.slices), &opt.center, &opt.normal);
        m.shape.unweld();
        if (opt.weld_threshold) |w| {
            m.shape.weld(w, null);
        }
        m.shape.computeNormals();
        m.aabb = m.shape.computeAabb();
        all_shapes.append(m.shape) catch unreachable;
        try S.meshes.?.put(try arena.allocator().dupe(u8, key), m);
        break :BLK m;
    };

    try addShape(mesh.shape, model, mesh.aabb, opt.rdopt);
}

pub const TorusDrawOption = struct {
    rdopt: RenderOption = .{},
    weld_threshold: ?f32 = null,
    radius: f32 = 0.2,
    slices: u32 = 15,
    stacks: u32 = 20,
};
pub fn addTorus(model: zmath.Mat, opt: TorusDrawOption) !void {
    const S = struct {
        const Mesh = struct {
            shape: zmesh.Shape,
            aabb: [6]f32,
        };

        var meshes: ?std.StringHashMap(*Mesh) = null;
        var buf: [64]u8 = undefined;

        fn getKey(_opt: TorusDrawOption) []u8 {
            return std.fmt.bufPrint(
                &buf,
                "{?:.5}-{d:.3}-{d}-{d}",
                .{ _opt.weld_threshold, _opt.radius, _opt.slices, _opt.stacks },
            ) catch unreachable;
        }
    };

    if (S.meshes == null) {
        S.meshes = std.StringHashMap(*S.Mesh).init(arena.allocator());
    }

    var mesh = BLK: {
        assert(opt.radius > 0);
        assert(opt.slices > 0);
        assert(opt.stacks > 0);
        const key = S.getKey(opt);
        if (S.meshes.?.get(key)) |s| {
            break :BLK s;
        }

        var m = try arena.allocator().create(S.Mesh);
        m.shape = zmesh.Shape.initTorus(@intCast(i32, opt.slices), @intCast(i32, opt.stacks), opt.radius);
        m.shape.unweld();
        if (opt.weld_threshold) |w| {
            m.shape.weld(w, null);
        }
        m.shape.computeNormals();
        m.aabb = m.shape.computeAabb();
        all_shapes.append(m.shape) catch unreachable;
        try S.meshes.?.put(try arena.allocator().dupe(u8, key), m);
        break :BLK m;
    };

    try addShape(mesh.shape, model, mesh.aabb, opt.rdopt);
}

pub const IcosahedronDrawOption = struct {
    rdopt: RenderOption = .{},
    weld_threshold: ?f32 = null,
};
pub fn addIcosahedron(model: zmath.Mat, opt: IcosahedronDrawOption) !void {
    const S = struct {
        const Mesh = struct {
            shape: zmesh.Shape,
            aabb: [6]f32,
        };

        var meshes: ?std.StringHashMap(*Mesh) = null;
        var buf: [32]u8 = undefined;

        fn getKey(_opt: IcosahedronDrawOption) []u8 {
            return std.fmt.bufPrint(
                &buf,
                "{?:.5}",
                .{_opt.weld_threshold},
            ) catch unreachable;
        }
    };

    if (S.meshes == null) {
        S.meshes = std.StringHashMap(*S.Mesh).init(arena.allocator());
    }

    var mesh = BLK: {
        const key = S.getKey(opt);
        if (S.meshes.?.get(key)) |s| {
            break :BLK s;
        }

        var m = try arena.allocator().create(S.Mesh);
        m.shape = zmesh.Shape.initIcosahedron();
        m.shape.unweld();
        if (opt.weld_threshold) |w| {
            m.shape.weld(w, null);
        }
        m.shape.computeNormals();
        m.aabb = m.shape.computeAabb();
        all_shapes.append(m.shape) catch unreachable;
        try S.meshes.?.put(try arena.allocator().dupe(u8, key), m);
        break :BLK m;
    };

    try addShape(mesh.shape, model, mesh.aabb, opt.rdopt);
}

pub const DodecahedronDrawOption = struct {
    rdopt: RenderOption = .{},
    weld_threshold: ?f32 = null,
};
pub fn addDodecahedron(model: zmath.Mat, opt: DodecahedronDrawOption) !void {
    const S = struct {
        const Mesh = struct {
            shape: zmesh.Shape,
            aabb: [6]f32,
        };

        var meshes: ?std.StringHashMap(*Mesh) = null;
        var buf: [32]u8 = undefined;

        fn getKey(_opt: DodecahedronDrawOption) []u8 {
            return std.fmt.bufPrint(
                &buf,
                "{?:.5}",
                .{_opt.weld_threshold},
            ) catch unreachable;
        }
    };

    if (S.meshes == null) {
        S.meshes = std.StringHashMap(*S.Mesh).init(arena.allocator());
    }

    var mesh = BLK: {
        const key = S.getKey(opt);
        if (S.meshes.?.get(key)) |s| {
            break :BLK s;
        }

        var m = try arena.allocator().create(S.Mesh);
        m.shape = zmesh.Shape.initDodecahedron();
        m.shape.unweld();
        if (opt.weld_threshold) |w| {
            m.shape.weld(w, null);
        }
        m.shape.computeNormals();
        m.aabb = m.shape.computeAabb();
        all_shapes.append(m.shape) catch unreachable;
        try S.meshes.?.put(try arena.allocator().dupe(u8, key), m);
        break :BLK m;
    };

    try addShape(mesh.shape, model, mesh.aabb, opt.rdopt);
}

pub const OctahedronDrawOption = struct {
    rdopt: RenderOption = .{},
    weld_threshold: ?f32 = null,
};
pub fn addOctahedron(model: zmath.Mat, opt: OctahedronDrawOption) !void {
    const S = struct {
        const Mesh = struct {
            shape: zmesh.Shape,
            aabb: [6]f32,
        };

        var meshes: ?std.StringHashMap(*Mesh) = null;
        var buf: [32]u8 = undefined;

        fn getKey(_opt: OctahedronDrawOption) []u8 {
            return std.fmt.bufPrint(
                &buf,
                "{?:.5}",
                .{_opt.weld_threshold},
            ) catch unreachable;
        }
    };

    if (S.meshes == null) {
        S.meshes = std.StringHashMap(*S.Mesh).init(arena.allocator());
    }

    var mesh = BLK: {
        const key = S.getKey(opt);
        if (S.meshes.?.get(key)) |s| {
            break :BLK s;
        }

        var m = try arena.allocator().create(S.Mesh);
        m.shape = zmesh.Shape.initOctahedron();
        m.shape.unweld();
        if (opt.weld_threshold) |w| {
            m.shape.weld(w, null);
        }
        m.shape.computeNormals();
        m.aabb = m.shape.computeAabb();
        all_shapes.append(m.shape) catch unreachable;
        try S.meshes.?.put(try arena.allocator().dupe(u8, key), m);
        break :BLK m;
    };

    try addShape(mesh.shape, model, mesh.aabb, opt.rdopt);
}

pub const TetrahedronDrawOption = struct {
    rdopt: RenderOption = .{},
    weld_threshold: ?f32 = null,
};
pub fn addTetrahedron(model: zmath.Mat, opt: TetrahedronDrawOption) !void {
    const S = struct {
        const Mesh = struct {
            shape: zmesh.Shape,
            aabb: [6]f32,
        };

        var meshes: ?std.StringHashMap(*Mesh) = null;
        var buf: [32]u8 = undefined;

        fn getKey(_opt: TetrahedronDrawOption) []u8 {
            return std.fmt.bufPrint(
                &buf,
                "{?:.5}",
                .{_opt.weld_threshold},
            ) catch unreachable;
        }
    };

    if (S.meshes == null) {
        S.meshes = std.StringHashMap(*S.Mesh).init(arena.allocator());
    }

    var mesh = BLK: {
        const key = S.getKey(opt);
        if (S.meshes.?.get(key)) |s| {
            break :BLK s;
        }

        var m = try arena.allocator().create(S.Mesh);
        m.shape = zmesh.Shape.initTetrahedron();
        m.shape.unweld();
        if (opt.weld_threshold) |w| {
            m.shape.weld(w, null);
        }
        m.shape.computeNormals();
        m.aabb = m.shape.computeAabb();
        all_shapes.append(m.shape) catch unreachable;
        try S.meshes.?.put(try arena.allocator().dupe(u8, key), m);
        break :BLK m;
    };

    try addShape(mesh.shape, model, mesh.aabb, opt.rdopt);
}

pub const RockDrawOption = struct {
    rdopt: RenderOption = .{},
    weld_threshold: ?f32 = null,
    seed: i32 = 3,
    sub_num: u32 = 1,
};
pub fn addRock(model: zmath.Mat, opt: RockDrawOption) !void {
    const S = struct {
        const Mesh = struct {
            shape: zmesh.Shape,
            aabb: [6]f32,
        };

        var meshes: ?std.StringHashMap(*Mesh) = null;
        var buf: [32]u8 = undefined;

        fn getKey(_opt: RockDrawOption) []u8 {
            return std.fmt.bufPrint(
                &buf,
                "{?:.5}-{d}-{d}",
                .{ _opt.weld_threshold, _opt.seed, _opt.sub_num },
            ) catch unreachable;
        }
    };

    if (S.meshes == null) {
        S.meshes = std.StringHashMap(*S.Mesh).init(arena.allocator());
    }

    var mesh = BLK: {
        assert(opt.sub_num > 0);
        const key = S.getKey(opt);
        if (S.meshes.?.get(key)) |s| {
            break :BLK s;
        }

        var m = try arena.allocator().create(S.Mesh);
        m.shape = zmesh.Shape.initRock(@intCast(i32, opt.seed), @intCast(i32, opt.sub_num));
        m.shape.unweld();
        if (opt.weld_threshold) |w| {
            m.shape.weld(w, null);
        }
        m.shape.computeNormals();
        m.aabb = m.shape.computeAabb();
        all_shapes.append(m.shape) catch unreachable;
        try S.meshes.?.put(try arena.allocator().dupe(u8, key), m);
        break :BLK m;
    };

    try addShape(mesh.shape, model, mesh.aabb, opt.rdopt);
}
