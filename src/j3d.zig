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

var allocator: std.mem.Allocator = undefined;
var arena: std.heap.ArenaAllocator = undefined;
var rd: sdl.Renderer = undefined;
var target: internal.RenderTarget = undefined;
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
    target = internal.RenderTarget.init(allocator);
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
        try target.drawTriangles(rd, wc);
    } else {
        try target.fillTriangles(rd, sort_by_depth);
    }
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
