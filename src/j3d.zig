const std = @import("std");
const assert = std.debug.assert;
const math = std.math;
const jok = @import("jok.zig");
const sdl = jok.sdl;
const imgui = jok.imgui;
const zmath = jok.zmath;
const zmesh = jok.zmesh;

const internal = @import("j3d/internal.zig");
const TriangleRenderer = @import("j3d/TriangleRenderer.zig");
const SkyboxRenderer = @import("j3d/SkyboxRenderer.zig");
pub const Mesh = @import("j3d/Mesh.zig");
pub const Animation = @import("j3d/Animation.zig");
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
    wireframe_color: ?sdl.Color = null,
    triangle_sort: TriangleSort = .none,
};

pub const TriangleSort = union(enum) {
    // Send to gpu directly. Use it when:
    // 1. 3D objects are ordered manually
    // 2. Triangles' size are simillar
    none,

    // Simple solution, sort by average depth. Use it when:
    // 1. Very few textures are being used (preferably only 1)
    // 2. Triangles' size are close (e.g. voxel game)
    simple,

    // Better looking but cost more cpu, might be slower in
    // simple situations (see above):
    // 1. Split screen to subrectangles as defined by `group_merge`
    // 2. Split triangles to disjoint groups, each contained in a subrectangle
    // 3. Sort each group and merge to batches
    //
    // Use it when:
    // 1. Many textures are being used
    // 2. Triangles' size vary significantly
    group_merge: u8,
};

var allocator: std.mem.Allocator = undefined;
var arena: std.heap.ArenaAllocator = undefined;
var rd: sdl.Renderer = undefined;
var target: internal.RenderTarget = undefined;
var tri_rd: TriangleRenderer = undefined;
var skybox_rd: SkyboxRenderer = undefined;
var all_shapes: std.ArrayList(zmesh.Shape) = undefined;
var camera: Camera = undefined;

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
    target.reset(
        rd,
        opt.wireframe_color,
        opt.triangle_sort,
        false,
    );
    camera = opt.camera orelse BLK: {
        const fsize = try rd.getOutputSize();
        const ratio =
            @as(f32, @floatFromInt(fsize.width_pixels)) /
            @as(f32, @floatFromInt(fsize.height_pixels));
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
}

pub fn end() !void {
    if (target.indices.items.len == 0) return;
    try target.submit(rd);
}

pub fn clearMemory() void {
    target.clear(true);
}

/// Textures' order: right/left/top/bottom/front/back
pub fn skybox(textures: [6]sdl.Texture, color: ?sdl.Color) !void {
    try skybox_rd.render(
        rd.getViewport(),
        &target,
        camera,
        textures,
        color,
    );
}

pub fn scene(s: *const Scene, opt: Scene.RenderOption) !void {
    try s.render(null, opt);
}

pub fn effects(ps: *ParticleSystem) !void {
    for (ps.effects.items) |eff| {
        try eff.render(
            rd.getViewport(),
            &target,
            camera,
            &tri_rd,
        );
    }
}

pub fn sprite(model: zmath.Mat, size: sdl.PointF, uv: [2]sdl.PointF, opt: TriangleRenderer.RenderSpriteOption) !void {
    try tri_rd.renderSprite(
        rd.getViewport(),
        &target,
        model,
        camera,
        size,
        uv,
        opt,
    );
}

pub const LineOption = struct {
    color: sdl.Color = sdl.Color.white,
    thickness: f32 = 0.01,
};
pub fn line(model: zmath.Mat, _p0: [3]f32, _p1: [3]f32, opt: LineOption) !void {
    const v0 = zmath.mul(zmath.f32x4(_p0[0], _p0[1], _p0[2], 1), model);
    const v1 = zmath.mul(zmath.f32x4(_p1[0], _p1[1], _p1[2], 1), model);
    const perpv = zmath.normalize3(zmath.cross3(v1 - v0, camera.dir));
    const veps = zmath.f32x4s(opt.thickness);
    const p0 = v0 + veps * perpv;
    const p1 = v0 - veps * perpv;
    const p2 = v1 - veps * perpv;
    const p3 = v1 + veps * perpv;
    try tri_rd.renderMesh(
        rd.getViewport(),
        &target,
        zmath.identity(),
        camera,
        &.{ 0, 1, 2, 0, 2, 3 },
        &.{
            .{ p0[0], p0[1], p0[2] },
            .{ p1[0], p1[1], p1[2] },
            .{ p2[0], p2[1], p2[2] },
            .{ p3[0], p3[1], p3[2] },
        },
        null,
        null,
        null,
        .{
            .cull_faces = false,
            .color = opt.color,
        },
    );
}

pub const TriangleOption = struct {
    rdopt: RenderOption = .{},
    aabb: ?[6]f32,
    fill: bool = true,
};
pub fn triangle(model: zmath.Mat, pos: [3][3]f32, colors: ?[3]sdl.Color, texcoords: ?[3][2]f32, opt: TriangleOption) !void {
    if (opt.fill) {
        const v0 = zmath.f32x4(
            pos[1][0] - pos[0][0],
            pos[1][1] - pos[0][1],
            pos[1][2] - pos[0][2],
            0,
        );
        const v1 = zmath.f32x4(
            pos[2][0] - pos[1][0],
            pos[2][1] - pos[1][1],
            pos[2][2] - pos[1][2],
            0,
        );
        const normal = zmath.vecToArr3(zmath.cross3(v0, v1));
        try tri_rd.renderMesh(
            rd.getViewport(),
            &target,
            model,
            camera,
            &.{ 0, 1, 2 },
            &pos,
            &.{ normal, normal, normal },
            if (colors) |cs| &cs else null,
            if (texcoords) |tex| &tex else null,
            .{
                .aabb = opt.aabb,
                .cull_faces = opt.rdopt.cull_faces,
                .color = opt.rdopt.color,
                .texture = opt.rdopt.texture,
                .lighting = opt.rdopt.lighting,
            },
        );
    } else {
        try line(model, pos[0], pos[1], .{ .color = opt.rdopt.color });
        try line(model, pos[1], pos[2], .{ .color = opt.rdopt.color });
        try line(model, pos[2], pos[0], .{ .color = opt.rdopt.color });
    }
}

pub fn triangles(
    model: zmath.Mat,
    indices: []const u32,
    pos: []const [3]f32,
    normals: ?[]const [3]f32,
    colors: ?[]const [3]sdl.Color,
    texcoords: ?[]const [2]f32,
    opt: TriangleOption,
) !void {
    assert(@rem(indices, 3) == 0);

    if (opt.fill) {
        try tri_rd.renderMesh(
            rd.getViewport(),
            &target,
            model,
            camera,
            indices,
            pos,
            normals,
            colors,
            texcoords,
            .{
                .aabb = opt.aabb,
                .cull_faces = opt.rdopt.cull_faces,
                .color = opt.rdopt.color,
                .texture = opt.rdopt.texture,
                .lighting = opt.rdopt.lighting,
            },
        );
    } else {
        var i: u32 = 2;
        while (i < indices) : (i += 2) {
            const idx0 = indices[i - 2];
            const idx1 = indices[i - 1];
            const idx2 = indices[i];
            try line(model, idx0, idx1, .{ .color = opt.rdopt.color });
            try line(model, idx1, idx2, .{ .color = opt.rdopt.color });
            try line(model, idx2, idx0, .{ .color = opt.rdopt.color });
        }
    }
}

pub fn shape(s: zmesh.Shape, model: zmath.Mat, aabb: ?[6]f32, opt: RenderOption) !void {
    try tri_rd.renderMesh(
        rd.getViewport(),
        &target,
        model,
        camera,
        s.indices,
        s.positions,
        s.normals.?,
        null,
        s.texcoords,
        .{
            .aabb = aabb,
            .cull_faces = opt.cull_faces,
            .color = opt.color,
            .texture = opt.texture,
            .lighting = opt.lighting,
        },
    );
}

pub fn mesh(m: *const Mesh, model: zmath.Mat, opt: RenderOption) !void {
    try m.render(
        rd.getViewport(),
        &target,
        model,
        camera,
        &tri_rd,
        .{
            .texture = opt.texture,
            .color = opt.color,
            .cull_faces = opt.cull_faces,
            .lighting = opt.lighting,
        },
    );
}

pub fn animation(anim: *Animation, model: zmath.Mat, opt: Animation.RenderOption) !void {
    try anim.render(rd.getViewport(), &target, model, camera, &tri_rd, opt);
}

pub const AxisOption = struct {
    radius: f32 = 0.1,
    length: f32 = 4,
    pos: [3]f32 = .{ 0, 0, 0 },
    rotation: zmath.Quat = zmath.matToQuat(zmath.identity()),
    color_x: sdl.Color = sdl.Color.red,
    color_y: sdl.Color = sdl.Color.green,
    color_z: sdl.Color = sdl.Color.blue,
};
pub fn axises(opt: AxisOption) !void {
    const scale_cylinder = zmath.scaling(opt.radius, opt.radius, opt.length);
    const scale_cone = zmath.scaling(opt.radius * 2.5, opt.radius * 2.5, opt.length / 9);
    const move_cylinder = zmath.translation(opt.pos[0], opt.pos[1], opt.pos[2]);
    const rotation = zmath.matFromQuat(opt.rotation);
    const right_angle = math.pi / 2.0;

    // X axis
    try cone(
        zmath.mul(
            zmath.mul(
                zmath.mul(scale_cone, zmath.rotationY(right_angle)),
                rotation,
            ),
            zmath.mul(zmath.translation(opt.length, 0, 0), move_cylinder),
        ),
        .{ .rdopt = .{ .color = opt.color_x, .cull_faces = false } },
    );
    try cylinder(
        zmath.mul(
            zmath.mul(
                zmath.mul(scale_cylinder, zmath.rotationY(right_angle)),
                rotation,
            ),
            move_cylinder,
        ),
        .{ .rdopt = .{ .color = opt.color_x }, .stacks = 10 },
    );

    // Y axis
    try cone(
        zmath.mul(
            zmath.mul(
                zmath.mul(scale_cone, zmath.rotationX(-right_angle)),
                rotation,
            ),
            zmath.mul(zmath.translation(0, opt.length, 0), move_cylinder),
        ),
        .{ .rdopt = .{ .color = opt.color_y, .cull_faces = false } },
    );
    try cylinder(
        zmath.mul(
            zmath.mul(
                zmath.mul(scale_cylinder, zmath.rotationX(-right_angle)),
                rotation,
            ),
            move_cylinder,
        ),
        .{ .rdopt = .{ .color = opt.color_y }, .stacks = 10 },
    );

    // Z axis
    try cone(
        zmath.mul(
            zmath.mul(scale_cone, rotation),
            zmath.mul(zmath.translation(0, 0, opt.length), move_cylinder),
        ),
        .{ .rdopt = .{ .color = opt.color_z, .cull_faces = false } },
    );
    try cylinder(
        zmath.mul(
            zmath.mul(scale_cylinder, rotation),
            move_cylinder,
        ),
        .{ .rdopt = .{ .color = opt.color_z }, .stacks = 10 },
    );
}

pub const CubeOption = struct {
    rdopt: RenderOption = .{},
    weld_threshold: ?f32 = null,
};
pub fn cube(model: zmath.Mat, opt: CubeOption) !void {
    const S = struct {
        const Shape = struct {
            shape: zmesh.Shape,
            aabb: [6]f32,
        };

        var meshes: ?std.StringHashMap(*Shape) = null;
        var buf: [32]u8 = undefined;

        fn getKey(_opt: CubeOption) []u8 {
            return std.fmt.bufPrint(
                &buf,
                "{?:.5}",
                .{_opt.weld_threshold},
            ) catch unreachable;
        }
    };

    if (S.meshes == null) {
        S.meshes = std.StringHashMap(*S.Shape).init(arena.allocator());
    }

    var m = BLK: {
        const key = S.getKey(opt);
        if (S.meshes.?.get(key)) |s| {
            break :BLK s;
        }

        var m = try arena.allocator().create(S.Shape);
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

    try shape(m.shape, model, m.aabb, opt.rdopt);
}

pub const PlaneOption = struct {
    rdopt: RenderOption = .{},
    weld_threshold: ?f32 = null,
    slices: u32 = 10,
    stacks: u32 = 10,
};
pub fn plane(model: zmath.Mat, opt: PlaneOption) !void {
    const S = struct {
        const Shape = struct {
            shape: zmesh.Shape,
            aabb: [6]f32,
        };

        var meshes: ?std.StringHashMap(*Shape) = null;
        var buf: [32]u8 = undefined;

        fn getKey(_opt: PlaneOption) []u8 {
            return std.fmt.bufPrint(
                &buf,
                "{?:.5}-{d}-{d}",
                .{ _opt.weld_threshold, _opt.slices, _opt.stacks },
            ) catch unreachable;
        }
    };

    if (S.meshes == null) {
        S.meshes = std.StringHashMap(*S.Shape).init(arena.allocator());
    }

    var m = BLK: {
        assert(opt.slices > 0);
        assert(opt.stacks > 0);
        const key = S.getKey(opt);
        if (S.meshes.?.get(key)) |s| {
            break :BLK s;
        }

        var m = try arena.allocator().create(S.Shape);
        m.shape = zmesh.Shape.initPlane(@intCast(opt.slices), @intCast(opt.stacks));
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

    try shape(m.shape, model, m.aabb, opt.rdopt);
}

pub const ParametricSphereOption = struct {
    rdopt: RenderOption = .{},
    weld_threshold: ?f32 = null,
    slices: u32 = 15,
    stacks: u32 = 15,
};
pub fn parametricSphere(model: zmath.Mat, opt: ParametricSphereOption) !void {
    const S = struct {
        const Shape = struct {
            shape: zmesh.Shape,
            aabb: [6]f32,
        };

        var meshes: ?std.StringHashMap(*Shape) = null;
        var buf: [32]u8 = undefined;

        fn getKey(_opt: ParametricSphereOption) []u8 {
            return std.fmt.bufPrint(
                &buf,
                "{?:.5}-{d}-{d}",
                .{ _opt.weld_threshold, _opt.slices, _opt.stacks },
            ) catch unreachable;
        }
    };

    if (S.meshes == null) {
        S.meshes = std.StringHashMap(*S.Shape).init(arena.allocator());
    }

    var m = BLK: {
        assert(opt.slices > 0);
        assert(opt.stacks > 0);
        const key = S.getKey(opt);
        if (S.meshes.?.get(key)) |s| {
            break :BLK s;
        }

        var m = try arena.allocator().create(S.Shape);
        m.shape = zmesh.Shape.initParametricSphere(@intCast(opt.slices), @intCast(opt.stacks));
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

    try shape(m.shape, model, m.aabb, opt.rdopt);
}

pub const SubdividedSphereOption = struct {
    rdopt: RenderOption = .{},
    weld_threshold: ?f32 = null,
    sub_num: u32 = 2,
};
pub fn subdividedSphere(model: zmath.Mat, opt: SubdividedSphereOption) !void {
    const S = struct {
        const Shape = struct {
            shape: zmesh.Shape,
            aabb: [6]f32,
        };

        var meshes: ?std.StringHashMap(*Shape) = null;
        var buf: [32]u8 = undefined;

        fn getKey(_opt: SubdividedSphereOption) []u8 {
            return std.fmt.bufPrint(
                &buf,
                "{?:.5}-{d}",
                .{ _opt.weld_threshold, _opt.sub_num },
            ) catch unreachable;
        }
    };

    if (S.meshes == null) {
        S.meshes = std.StringHashMap(*S.Shape).init(arena.allocator());
    }

    var m = BLK: {
        assert(opt.sub_num > 0);
        const key = S.getKey(opt);
        if (S.meshes.?.get(key)) |s| {
            break :BLK s;
        }

        var m = try arena.allocator().create(S.Shape);
        m.shape = zmesh.Shape.initSubdividedSphere(@intCast(opt.sub_num));
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

    try shape(m.shape, model, m.aabb, opt.rdopt);
}

pub const HemisphereOption = struct {
    rdopt: RenderOption = .{},
    weld_threshold: ?f32 = null,
    slices: u32 = 15,
    stacks: u32 = 15,
};
pub fn hemisphere(model: zmath.Mat, opt: HemisphereOption) !void {
    const S = struct {
        const Shape = struct {
            shape: zmesh.Shape,
            aabb: [6]f32,
        };

        var meshes: ?std.StringHashMap(*Shape) = null;
        var buf: [32]u8 = undefined;

        fn getKey(_opt: HemisphereOption) []u8 {
            return std.fmt.bufPrint(
                &buf,
                "{?:.5}-{d}-{d}",
                .{ _opt.weld_threshold, _opt.slices, _opt.stacks },
            ) catch unreachable;
        }
    };

    if (S.meshes == null) {
        S.meshes = std.StringHashMap(*S.Shape).init(arena.allocator());
    }

    var m = BLK: {
        assert(opt.slices > 0);
        assert(opt.stacks > 0);
        const key = S.getKey(opt);
        if (S.meshes.?.get(key)) |s| {
            break :BLK s;
        }

        var m = try arena.allocator().create(S.Shape);
        m.shape = zmesh.Shape.initHemisphere(@intCast(opt.slices), @intCast(opt.stacks));
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

    try shape(m.shape, model, m.aabb, opt.rdopt);
}

pub const ConeOption = struct {
    rdopt: RenderOption = .{},
    weld_threshold: ?f32 = null,
    slices: u32 = 15,
    stacks: u32 = 1,
};
pub fn cone(model: zmath.Mat, opt: ConeOption) !void {
    const S = struct {
        const Shape = struct {
            shape: zmesh.Shape,
            aabb: [6]f32,
        };

        var meshes: ?std.StringHashMap(*Shape) = null;
        var buf: [32]u8 = undefined;

        fn getKey(_opt: ConeOption) []u8 {
            return std.fmt.bufPrint(
                &buf,
                "{?:.5}-{d}-{d}",
                .{ _opt.weld_threshold, _opt.slices, _opt.stacks },
            ) catch unreachable;
        }
    };

    if (S.meshes == null) {
        S.meshes = std.StringHashMap(*S.Shape).init(arena.allocator());
    }

    var m = BLK: {
        assert(opt.slices > 0);
        assert(opt.stacks > 0);
        const key = S.getKey(opt);
        if (S.meshes.?.get(key)) |s| {
            break :BLK s;
        }

        var m = try arena.allocator().create(S.Shape);
        m.shape = zmesh.Shape.initCone(@intCast(opt.slices), @intCast(opt.stacks));
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

    try shape(m.shape, model, m.aabb, opt.rdopt);
}

pub const CylinderOption = struct {
    rdopt: RenderOption = .{},
    weld_threshold: ?f32 = null,
    slices: u32 = 20,
    stacks: u32 = 1,
};
pub fn cylinder(model: zmath.Mat, opt: CylinderOption) !void {
    const S = struct {
        const Shape = struct {
            shape: zmesh.Shape,
            aabb: [6]f32,
        };

        var meshes: ?std.StringHashMap(*Shape) = null;
        var buf: [32]u8 = undefined;

        fn getKey(_opt: CylinderOption) []u8 {
            return std.fmt.bufPrint(
                &buf,
                "{?:.5}-{d}-{d}",
                .{ _opt.weld_threshold, _opt.slices, _opt.stacks },
            ) catch unreachable;
        }
    };

    if (S.meshes == null) {
        S.meshes = std.StringHashMap(*S.Shape).init(arena.allocator());
    }

    var m = BLK: {
        assert(opt.slices > 0);
        assert(opt.stacks > 0);
        const key = S.getKey(opt);
        if (S.meshes.?.get(key)) |s| {
            break :BLK s;
        }

        var m = try arena.allocator().create(S.Shape);
        m.shape = zmesh.Shape.initCylinder(@intCast(opt.slices), @intCast(opt.stacks));
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

    try shape(m.shape, model, m.aabb, opt.rdopt);
}

pub const DiskOption = struct {
    rdopt: RenderOption = .{},
    weld_threshold: ?f32 = null,
    radius: f32 = 1,
    slices: u32 = 20,
    center: [3]f32 = .{ 0, 0, 0 },
    normal: [3]f32 = .{ 0, 0, 1 },
};
pub fn disk(model: zmath.Mat, opt: DiskOption) !void {
    const S = struct {
        const Shape = struct {
            shape: zmesh.Shape,
            aabb: [6]f32,
        };

        var meshes: ?std.StringHashMap(*Shape) = null;
        var buf: [64]u8 = undefined;

        fn getKey(_opt: DiskOption) []u8 {
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
        S.meshes = std.StringHashMap(*S.Shape).init(arena.allocator());
    }

    var m = BLK: {
        assert(opt.radius > 0);
        assert(opt.slices > 0);
        const key = S.getKey(opt);
        if (S.meshes.?.get(key)) |s| {
            break :BLK s;
        }

        var m = try arena.allocator().create(S.Shape);
        m.shape = zmesh.Shape.initDisk(opt.radius, @intCast(opt.slices), &opt.center, &opt.normal);
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

    try shape(m.shape, model, m.aabb, opt.rdopt);
}

pub const TorusOption = struct {
    rdopt: RenderOption = .{},
    weld_threshold: ?f32 = null,
    radius: f32 = 0.2,
    slices: u32 = 15,
    stacks: u32 = 20,
};
pub fn torus(model: zmath.Mat, opt: TorusOption) !void {
    const S = struct {
        const Shape = struct {
            shape: zmesh.Shape,
            aabb: [6]f32,
        };

        var meshes: ?std.StringHashMap(*Shape) = null;
        var buf: [64]u8 = undefined;

        fn getKey(_opt: TorusOption) []u8 {
            return std.fmt.bufPrint(
                &buf,
                "{?:.5}-{d:.3}-{d}-{d}",
                .{ _opt.weld_threshold, _opt.radius, _opt.slices, _opt.stacks },
            ) catch unreachable;
        }
    };

    if (S.meshes == null) {
        S.meshes = std.StringHashMap(*S.Shape).init(arena.allocator());
    }

    var m = BLK: {
        assert(opt.radius > 0);
        assert(opt.slices > 0);
        assert(opt.stacks > 0);
        const key = S.getKey(opt);
        if (S.meshes.?.get(key)) |s| {
            break :BLK s;
        }

        var m = try arena.allocator().create(S.Shape);
        m.shape = zmesh.Shape.initTorus(@intCast(opt.slices), @intCast(opt.stacks), opt.radius);
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

    try shape(m.shape, model, m.aabb, opt.rdopt);
}

pub const IcosahedronOption = struct {
    rdopt: RenderOption = .{},
    weld_threshold: ?f32 = null,
};
pub fn icosahedron(model: zmath.Mat, opt: IcosahedronOption) !void {
    const S = struct {
        const Shape = struct {
            shape: zmesh.Shape,
            aabb: [6]f32,
        };

        var meshes: ?std.StringHashMap(*Shape) = null;
        var buf: [32]u8 = undefined;

        fn getKey(_opt: IcosahedronOption) []u8 {
            return std.fmt.bufPrint(
                &buf,
                "{?:.5}",
                .{_opt.weld_threshold},
            ) catch unreachable;
        }
    };

    if (S.meshes == null) {
        S.meshes = std.StringHashMap(*S.Shape).init(arena.allocator());
    }

    var m = BLK: {
        const key = S.getKey(opt);
        if (S.meshes.?.get(key)) |s| {
            break :BLK s;
        }

        var m = try arena.allocator().create(S.Shape);
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

    try shape(m.shape, model, m.aabb, opt.rdopt);
}

pub const DodecahedronOption = struct {
    rdopt: RenderOption = .{},
    weld_threshold: ?f32 = null,
};
pub fn dodecahedron(model: zmath.Mat, opt: DodecahedronOption) !void {
    const S = struct {
        const Shape = struct {
            shape: zmesh.Shape,
            aabb: [6]f32,
        };

        var meshes: ?std.StringHashMap(*Shape) = null;
        var buf: [32]u8 = undefined;

        fn getKey(_opt: DodecahedronOption) []u8 {
            return std.fmt.bufPrint(
                &buf,
                "{?:.5}",
                .{_opt.weld_threshold},
            ) catch unreachable;
        }
    };

    if (S.meshes == null) {
        S.meshes = std.StringHashMap(*S.Shape).init(arena.allocator());
    }

    var m = BLK: {
        const key = S.getKey(opt);
        if (S.meshes.?.get(key)) |s| {
            break :BLK s;
        }

        var m = try arena.allocator().create(S.Shape);
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

    try shape(m.shape, model, m.aabb, opt.rdopt);
}

pub const OctahedronOption = struct {
    rdopt: RenderOption = .{},
    weld_threshold: ?f32 = null,
};
pub fn octahedron(model: zmath.Mat, opt: OctahedronOption) !void {
    const S = struct {
        const Shape = struct {
            shape: zmesh.Shape,
            aabb: [6]f32,
        };

        var meshes: ?std.StringHashMap(*Shape) = null;
        var buf: [32]u8 = undefined;

        fn getKey(_opt: OctahedronOption) []u8 {
            return std.fmt.bufPrint(
                &buf,
                "{?:.5}",
                .{_opt.weld_threshold},
            ) catch unreachable;
        }
    };

    if (S.meshes == null) {
        S.meshes = std.StringHashMap(*S.Shape).init(arena.allocator());
    }

    var m = BLK: {
        const key = S.getKey(opt);
        if (S.meshes.?.get(key)) |s| {
            break :BLK s;
        }

        var m = try arena.allocator().create(S.Shape);
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

    try shape(m.shape, model, m.aabb, opt.rdopt);
}

pub const TetrahedronOption = struct {
    rdopt: RenderOption = .{},
    weld_threshold: ?f32 = null,
};
pub fn tetrahedron(model: zmath.Mat, opt: TetrahedronOption) !void {
    const S = struct {
        const Shape = struct {
            shape: zmesh.Shape,
            aabb: [6]f32,
        };

        var meshes: ?std.StringHashMap(*Shape) = null;
        var buf: [32]u8 = undefined;

        fn getKey(_opt: TetrahedronOption) []u8 {
            return std.fmt.bufPrint(
                &buf,
                "{?:.5}",
                .{_opt.weld_threshold},
            ) catch unreachable;
        }
    };

    if (S.meshes == null) {
        S.meshes = std.StringHashMap(*S.Shape).init(arena.allocator());
    }

    var m = BLK: {
        const key = S.getKey(opt);
        if (S.meshes.?.get(key)) |s| {
            break :BLK s;
        }

        var m = try arena.allocator().create(S.Shape);
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

    try shape(m.shape, model, m.aabb, opt.rdopt);
}

pub const RockOption = struct {
    rdopt: RenderOption = .{},
    weld_threshold: ?f32 = null,
    seed: i32 = 3,
    sub_num: u32 = 1,
};
pub fn rock(model: zmath.Mat, opt: RockOption) !void {
    const S = struct {
        const Shape = struct {
            shape: zmesh.Shape,
            aabb: [6]f32,
        };

        var meshes: ?std.StringHashMap(*Shape) = null;
        var buf: [32]u8 = undefined;

        fn getKey(_opt: RockOption) []u8 {
            return std.fmt.bufPrint(
                &buf,
                "{?:.5}-{d}-{d}",
                .{ _opt.weld_threshold, _opt.seed, _opt.sub_num },
            ) catch unreachable;
        }
    };

    if (S.meshes == null) {
        S.meshes = std.StringHashMap(*S.Shape).init(arena.allocator());
    }

    var m = BLK: {
        assert(opt.sub_num > 0);
        const key = S.getKey(opt);
        if (S.meshes.?.get(key)) |s| {
            break :BLK s;
        }

        var m = try arena.allocator().create(S.Shape);
        m.shape = zmesh.Shape.initRock(@intCast(opt.seed), @intCast(opt.sub_num));
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

    try shape(m.shape, model, m.aabb, opt.rdopt);
}
