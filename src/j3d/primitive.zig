const std = @import("std");
const assert = std.debug.assert;
const math = std.math;
const TriangleRenderer = @import("TriangleRenderer.zig");
const Camera = @import("Camera.zig");
const sdl = @import("sdl");
const jok = @import("../jok.zig");
const j3d = jok.j3d;
const zmath = j3d.zmath;
const zmesh = j3d.zmesh;

pub const CommonDrawOption = struct {
    renderer: sdl.Renderer,
    color: sdl.Color = sdl.Color.white,
    cull_faces: bool = true,
    lighting: ?TriangleRenderer.LightingOption = null,
    weld_threshold: ?f32 = null,
};

var own_rd: bool = false;
var tri_renderer: ?TriangleRenderer = null;
var arena: std.heap.ArenaAllocator = undefined;
var all_shapes: std.ArrayList(zmesh.Shape) = undefined;

/// Initialize primitive module
pub fn init(ctx: *jok.Context, _rd: ?TriangleRenderer) !void {
    tri_renderer = _rd orelse BLK: {
        own_rd = true;
        break :BLK TriangleRenderer.init(ctx.allocator);
    };
    arena = std.heap.ArenaAllocator.init(ctx.allocator);
    all_shapes = std.ArrayList(zmesh.Shape).init(arena.allocator());
}

/// Destroy primitive module
pub fn deinit() void {
    for (all_shapes.items) |s| s.deinit();
    if (own_rd) tri_renderer.?.deinit();
    arena.deinit();
}

/// Clear primitive
pub fn clear() void {
    tri_renderer.?.clear(true);
}

/// Render data
pub const RenderOption = struct {
    texture: ?sdl.Texture = null,
    wireframe: bool = false,
    wireframe_color: sdl.Color = sdl.Color.green,
};
pub fn render(renderer: sdl.Renderer, opt: RenderOption) !void {
    if (opt.wireframe) {
        try tri_renderer.?.drawWireframe(renderer, opt.wireframe_color);
    } else {
        try tri_renderer.?.draw(renderer, opt.texture);
    }
}

/// Draw a shape
pub fn addShape(
    shape: zmesh.Shape,
    model: zmath.Mat,
    camera: Camera,
    aabb: ?[6]f32,
    opt: CommonDrawOption,
) !void {
    const S = struct {
        var colors: ?std.ArrayList(sdl.Color) = null;
    };

    if (S.colors == null) {
        S.colors = std.ArrayList(sdl.Color).initCapacity(arena.allocator(), 1000) catch unreachable;
    }

    S.colors.?.clearRetainingCapacity();
    S.colors.?.ensureTotalCapacity(shape.positions.len) catch unreachable;
    S.colors.?.appendNTimesAssumeCapacity(opt.color, shape.positions.len);

    try tri_renderer.?.appendShape(
        opt.renderer,
        model,
        camera,
        shape.indices,
        shape.positions,
        shape.normals.?,
        S.colors.?.items,
        shape.texcoords,
        .{
            .aabb = aabb,
            .cull_faces = opt.cull_faces,
            .lighting = opt.lighting,
        },
    );
}

/// Draw a cube
pub fn addCube(model: zmath.Mat, camera: Camera, opt: CommonDrawOption) !void {
    const S = struct {
        const Mesh = struct {
            shape: zmesh.Shape,
            aabb: [6]f32,
        };

        var meshes: ?std.StringHashMap(*Mesh) = null;
        var buf: [32]u8 = undefined;

        fn getKey(_opt: CommonDrawOption) []u8 {
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
        m.shape.computeAabb(&m.aabb);
        all_shapes.append(m.shape) catch unreachable;
        try S.meshes.?.put(try arena.allocator().dupe(u8, key), m);
        break :BLK m;
    };

    try addShape(mesh.shape, model, camera, mesh.aabb, opt);
}

/// Draw a plane
pub const PlaneDrawOption = struct {
    common: CommonDrawOption,
    slices: u32 = 10,
    stacks: u32 = 10,
};
pub fn addPlane(model: zmath.Mat, camera: Camera, opt: PlaneDrawOption) !void {
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
                .{ _opt.common.weld_threshold, _opt.slices, _opt.stacks },
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
        if (opt.common.weld_threshold) |w| {
            m.shape.weld(w, null);
        }
        m.shape.computeNormals();
        m.shape.computeAabb(&m.aabb);
        all_shapes.append(m.shape) catch unreachable;
        try S.meshes.?.put(try arena.allocator().dupe(u8, key), m);
        break :BLK m;
    };

    try addShape(mesh.shape, model, camera, mesh.aabb, opt.common);
}

/// Draw a parametric sphere
pub const ParametricSphereDrawOption = struct {
    common: CommonDrawOption,
    slices: u32 = 15,
    stacks: u32 = 15,
};
pub fn addParametricSphere(model: zmath.Mat, camera: Camera, opt: ParametricSphereDrawOption) !void {
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
                .{ _opt.common.weld_threshold, _opt.slices, _opt.stacks },
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
        if (opt.common.weld_threshold) |w| {
            m.shape.weld(w, null);
        }
        m.shape.computeNormals();
        m.shape.computeAabb(&m.aabb);
        all_shapes.append(m.shape) catch unreachable;
        try S.meshes.?.put(try arena.allocator().dupe(u8, key), m);
        break :BLK m;
    };

    try addShape(mesh.shape, model, camera, mesh.aabb, opt.common);
}

/// Draw a subdivided sphere
pub const SubdividedSphereDrawOption = struct {
    common: CommonDrawOption,
    sub_num: u32 = 2,
};
pub fn addSubdividedSphere(model: zmath.Mat, camera: Camera, opt: SubdividedSphereDrawOption) !void {
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
                .{ _opt.common.weld_threshold, _opt.sub_num },
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
        if (opt.common.weld_threshold) |w| {
            m.shape.weld(w, null);
        }
        m.shape.computeNormals();
        m.shape.computeAabb(&m.aabb);
        all_shapes.append(m.shape) catch unreachable;
        try S.meshes.?.put(try arena.allocator().dupe(u8, key), m);
        break :BLK m;
    };

    try addShape(mesh.shape, model, camera, mesh.aabb, opt.common);
}

/// Draw a parametric sphere
pub const HemisphereDrawOption = struct {
    common: CommonDrawOption,
    slices: u32 = 15,
    stacks: u32 = 15,
};
pub fn addHemisphere(model: zmath.Mat, camera: Camera, opt: HemisphereDrawOption) !void {
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
                .{ _opt.common.weld_threshold, _opt.slices, _opt.stacks },
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
        if (opt.common.weld_threshold) |w| {
            m.shape.weld(w, null);
        }
        m.shape.computeNormals();
        m.shape.computeAabb(&m.aabb);
        all_shapes.append(m.shape) catch unreachable;
        try S.meshes.?.put(try arena.allocator().dupe(u8, key), m);
        break :BLK m;
    };

    try addShape(mesh.shape, model, camera, mesh.aabb, opt.common);
}

/// Draw a cone
pub const ConeDrawOption = struct {
    common: CommonDrawOption,
    slices: u32 = 15,
    stacks: u32 = 1,
};
pub fn addCone(model: zmath.Mat, camera: Camera, opt: ConeDrawOption) !void {
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
                .{ _opt.common.weld_threshold, _opt.slices, _opt.stacks },
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
        if (opt.common.weld_threshold) |w| {
            m.shape.weld(w, null);
        }
        m.shape.computeNormals();
        m.shape.computeAabb(&m.aabb);
        all_shapes.append(m.shape) catch unreachable;
        try S.meshes.?.put(try arena.allocator().dupe(u8, key), m);
        break :BLK m;
    };

    try addShape(mesh.shape, model, camera, mesh.aabb, opt.common);
}

/// Draw a cylinder
pub const CylinderDrawOption = struct {
    common: CommonDrawOption,
    slices: u32 = 20,
    stacks: u32 = 1,
};
pub fn addCylinder(model: zmath.Mat, camera: Camera, opt: CylinderDrawOption) !void {
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
                .{ _opt.common.weld_threshold, _opt.slices, _opt.stacks },
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
        if (opt.common.weld_threshold) |w| {
            m.shape.weld(w, null);
        }
        m.shape.computeNormals();
        m.shape.computeAabb(&m.aabb);
        all_shapes.append(m.shape) catch unreachable;
        try S.meshes.?.put(try arena.allocator().dupe(u8, key), m);
        break :BLK m;
    };

    try addShape(mesh.shape, model, camera, mesh.aabb, opt.common);
}

/// Draw a disk
pub const DiskDrawOption = struct {
    common: CommonDrawOption,
    radius: f32 = 1,
    slices: u32 = 20,
    center: [3]f32 = .{ 0, 0, 0 },
    normal: [3]f32 = .{ 0, 0, 1 },
};
pub fn addDisk(model: zmath.Mat, camera: Camera, opt: DiskDrawOption) !void {
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
                    _opt.common.weld_threshold, _opt.radius,    _opt.slices,
                    _opt.center[0],             _opt.center[1], _opt.center[2],
                    _opt.normal[0],             _opt.normal[1], _opt.normal[2],
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
        if (opt.common.weld_threshold) |w| {
            m.shape.weld(w, null);
        }
        m.shape.computeNormals();
        m.shape.computeAabb(&m.aabb);
        all_shapes.append(m.shape) catch unreachable;
        try S.meshes.?.put(try arena.allocator().dupe(u8, key), m);
        break :BLK m;
    };

    try addShape(mesh.shape, model, camera, mesh.aabb, opt.common);
}

/// Draw a torus
pub const TorusDrawOption = struct {
    common: CommonDrawOption,
    radius: f32 = 0.2,
    slices: u32 = 15,
    stacks: u32 = 20,
};
pub fn addTorus(model: zmath.Mat, camera: Camera, opt: TorusDrawOption) !void {
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
                .{ _opt.common.weld_threshold, _opt.radius, _opt.slices, _opt.stacks },
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
        if (opt.common.weld_threshold) |w| {
            m.shape.weld(w, null);
        }
        m.shape.computeNormals();
        m.shape.computeAabb(&m.aabb);
        all_shapes.append(m.shape) catch unreachable;
        try S.meshes.?.put(try arena.allocator().dupe(u8, key), m);
        break :BLK m;
    };

    try addShape(mesh.shape, model, camera, mesh.aabb, opt.common);
}

/// Draw a icosahedron
pub fn addIcosahedron(model: zmath.Mat, camera: Camera, opt: CommonDrawOption) !void {
    const S = struct {
        const Mesh = struct {
            shape: zmesh.Shape,
            aabb: [6]f32,
        };

        var meshes: ?std.StringHashMap(*Mesh) = null;
        var buf: [32]u8 = undefined;

        fn getKey(_opt: CommonDrawOption) []u8 {
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
        m.shape.computeAabb(&m.aabb);
        all_shapes.append(m.shape) catch unreachable;
        try S.meshes.?.put(try arena.allocator().dupe(u8, key), m);
        break :BLK m;
    };

    try addShape(mesh.shape, model, camera, mesh.aabb, opt);
}

/// Draw a dodecahedron
pub fn addDodecahedron(model: zmath.Mat, camera: Camera, opt: CommonDrawOption) !void {
    const S = struct {
        const Mesh = struct {
            shape: zmesh.Shape,
            aabb: [6]f32,
        };

        var meshes: ?std.StringHashMap(*Mesh) = null;
        var buf: [32]u8 = undefined;

        fn getKey(_opt: CommonDrawOption) []u8 {
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
        m.shape.computeAabb(&m.aabb);
        all_shapes.append(m.shape) catch unreachable;
        try S.meshes.?.put(try arena.allocator().dupe(u8, key), m);
        break :BLK m;
    };

    try addShape(mesh.shape, model, camera, mesh.aabb, opt);
}

/// Draw a octahedron
pub fn addOctahedron(model: zmath.Mat, camera: Camera, opt: CommonDrawOption) !void {
    const S = struct {
        const Mesh = struct {
            shape: zmesh.Shape,
            aabb: [6]f32,
        };

        var meshes: ?std.StringHashMap(*Mesh) = null;
        var buf: [32]u8 = undefined;

        fn getKey(_opt: CommonDrawOption) []u8 {
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
        m.shape.computeAabb(&m.aabb);
        all_shapes.append(m.shape) catch unreachable;
        try S.meshes.?.put(try arena.allocator().dupe(u8, key), m);
        break :BLK m;
    };

    try addShape(mesh.shape, model, camera, mesh.aabb, opt);
}

/// Draw a tetrahedron
pub fn addTetrahedron(model: zmath.Mat, camera: Camera, opt: CommonDrawOption) !void {
    const S = struct {
        const Mesh = struct {
            shape: zmesh.Shape,
            aabb: [6]f32,
        };

        var meshes: ?std.StringHashMap(*Mesh) = null;
        var buf: [32]u8 = undefined;

        fn getKey(_opt: CommonDrawOption) []u8 {
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
        m.shape.computeAabb(&m.aabb);
        all_shapes.append(m.shape) catch unreachable;
        try S.meshes.?.put(try arena.allocator().dupe(u8, key), m);
        break :BLK m;
    };

    try addShape(mesh.shape, model, camera, mesh.aabb, opt);
}

/// Draw a rock
pub const RockDrawOption = struct {
    common: CommonDrawOption,
    seed: i32 = 3,
    sub_num: u32 = 1,
};
pub fn addRock(model: zmath.Mat, camera: Camera, opt: RockDrawOption) !void {
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
                .{ _opt.common.weld_threshold, _opt.seed, _opt.sub_num },
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
        if (opt.common.weld_threshold) |w| {
            m.shape.weld(w, null);
        }
        m.shape.computeNormals();
        m.shape.computeAabb(&m.aabb);
        all_shapes.append(m.shape) catch unreachable;
        try S.meshes.?.put(try arena.allocator().dupe(u8, key), m);
        break :BLK m;
    };

    try addShape(mesh.shape, model, camera, mesh.aabb, opt.common);
}
