const std = @import("std");
const assert = std.debug.assert;
const math = std.math;
const Renderer = @import("Renderer.zig");
const sdl = @import("sdl");
const jok = @import("../../jok.zig");
const @"3d" = jok.gfx.@"3d";
const zmath = @"3d".zmath;
const zmesh = @"3d".zmesh;
const Camera = @"3d".Camera;

pub const CommonDrawOption = struct {
    color: sdl.Color = sdl.Color.white,
    cull_faces: bool = true,
    lighting_param: ?Renderer.LightingOption = null,
};

var rd: ?Renderer = null;
var arena: std.heap.ArenaAllocator = undefined;
var renderer: sdl.Renderer = undefined;

/// Create primitive renderer
pub fn init(ctx: *jok.Context) !void {
    rd = Renderer.init(ctx.allocator);
    arena = std.heap.ArenaAllocator.init(ctx.allocator);
    renderer = ctx.renderer;
}

/// Destroy primitive renderer
pub fn deinit() void {
    rd.?.deinit();
    arena.deinit();
}

/// Clear primitive
pub fn clear() void {
    rd.?.clear(true);
}

/// Render data
pub const FlushOption = struct {
    texture: ?sdl.Texture = null,
    wireframe: bool = false,
    wireframe_color: sdl.Color = sdl.Color.green,
};
pub fn flush(opt: FlushOption) !void {
    if (opt.wireframe) {
        try rd.?.drawWireframe(renderer, opt.wireframe_color);
    } else {
        try rd.?.draw(renderer, opt.texture);
    }
}

/// Draw a cube
pub fn drawCube(camera: Camera, model: zmath.Mat, opt: CommonDrawOption) !void {
    const S = struct {
        var shape: ?zmesh.Shape = null;
        var colors: std.ArrayList(sdl.Color) = undefined;
        var aabb: [6]f32 = undefined;
    };

    if (S.shape == null) {
        S.shape = zmesh.Shape.initCube();
        S.shape.?.computeNormals();
        S.shape.?.computeAabb(&S.aabb);
        S.colors = try std.ArrayList(sdl.Color).initCapacity(arena.allocator(), 8);
    }

    S.colors.clearRetainingCapacity();
    for (S.shape.?.positions) |_| {
        try S.colors.append(opt.color);
    }

    try rd.?.appendVertex(
        renderer,
        model,
        camera,
        S.shape.?.indices,
        S.shape.?.positions,
        S.shape.?.normals.?,
        S.colors.items,
        null,
        .{
            .aabb = S.aabb,
            .cull_faces = opt.cull_faces,
            .lighting = opt.lighting_param,
        },
    );
}

/// Draw a plane
pub const PlaneDrawOption = struct {
    common: CommonDrawOption,
    slices: u32 = 20,
    stacks: u32 = 20,
};
pub fn drawPlane(camera: Camera, model: zmath.Mat, opt: PlaneDrawOption) !void {
    const S = struct {
        const Mesh = struct {
            shape: zmesh.Shape,
            aabb: [6]f32,
        };

        var meshes: ?std.StringHashMap(*Mesh) = null;
        var colors: std.ArrayList(sdl.Color) = undefined;
        var buf: [32]u8 = undefined;

        fn getKey(_opt: PlaneDrawOption) []u8 {
            return std.fmt.bufPrint(&buf, "{d}-{d}", .{ _opt.slices, _opt.stacks }) catch unreachable;
        }
    };

    if (S.meshes == null) {
        S.meshes = std.StringHashMap(*S.Mesh).init(arena.allocator());
        S.colors = try std.ArrayList(sdl.Color).initCapacity(arena.allocator(), 20);
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
        m.shape.computeAabb(&m.aabb);
        m.shape.computeNormals();
        try S.meshes.?.put(try arena.allocator().dupe(u8, key), m);
        break :BLK m;
    };

    S.colors.clearRetainingCapacity();
    for (mesh.shape.positions) |_| {
        try S.colors.append(opt.common.color);
    }

    try rd.?.appendVertex(
        renderer,
        model,
        camera,
        mesh.shape.indices,
        mesh.shape.positions,
        mesh.shape.normals.?,
        S.colors.items,
        null,
        .{
            .aabb = mesh.aabb,
            .cull_faces = opt.common.cull_faces,
            .lighting = opt.common.lighting_param,
        },
    );
}

/// Draw a parametric sphere
pub const ParametricSphereDrawOption = struct {
    common: CommonDrawOption,
    slices: u32 = 20,
    stacks: u32 = 20,
};
pub fn drawParametricSphere(camera: Camera, model: zmath.Mat, opt: ParametricSphereDrawOption) !void {
    const S = struct {
        const Mesh = struct {
            shape: zmesh.Shape,
            aabb: [6]f32,
        };

        var meshes: ?std.StringHashMap(*Mesh) = null;
        var colors: std.ArrayList(sdl.Color) = undefined;
        var buf: [32]u8 = undefined;

        fn getKey(_opt: ParametricSphereDrawOption) []u8 {
            return std.fmt.bufPrint(&buf, "{d}-{d}", .{ _opt.slices, _opt.stacks }) catch unreachable;
        }
    };

    if (S.meshes == null) {
        S.meshes = std.StringHashMap(*S.Mesh).init(arena.allocator());
        S.colors = try std.ArrayList(sdl.Color).initCapacity(arena.allocator(), 20);
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
        m.shape.computeAabb(&m.aabb);
        m.shape.computeNormals();
        try S.meshes.?.put(try arena.allocator().dupe(u8, key), m);
        break :BLK m;
    };

    S.colors.clearRetainingCapacity();
    for (mesh.shape.positions) |_| {
        try S.colors.append(opt.common.color);
    }

    try rd.?.appendVertex(
        renderer,
        model,
        camera,
        mesh.shape.indices,
        mesh.shape.positions,
        mesh.shape.normals.?,
        S.colors.items,
        null,
        .{
            .aabb = mesh.aabb,
            .cull_faces = opt.common.cull_faces,
            .lighting = opt.common.lighting_param,
        },
    );
}

/// Draw a subdivided sphere
pub const SubdividedSphereDrawOption = struct {
    common: CommonDrawOption,
    sub_num: u32 = 2,
};
pub fn drawSubdividedSphere(camera: Camera, model: zmath.Mat, opt: SubdividedSphereDrawOption) !void {
    const S = struct {
        const Mesh = struct {
            shape: zmesh.Shape,
            aabb: [6]f32,
        };

        var meshes: ?std.AutoHashMap(u32, *Mesh) = null;
        var colors: std.ArrayList(sdl.Color) = undefined;
    };

    if (S.meshes == null) {
        S.meshes = std.AutoHashMap(u32, *S.Mesh).init(arena.allocator());
        S.colors = try std.ArrayList(sdl.Color).initCapacity(arena.allocator(), 20);
    }

    var mesh = BLK: {
        assert(opt.sub_num > 0);
        if (S.meshes.?.get(opt.sub_num)) |s| {
            break :BLK s;
        }

        var m = try arena.allocator().create(S.Mesh);
        m.shape = zmesh.Shape.initSubdividedSphere(@intCast(i32, opt.sub_num));
        m.shape.computeAabb(&m.aabb);
        m.shape.computeNormals();
        try S.meshes.?.put(opt.sub_num, m);
        break :BLK m;
    };

    S.colors.clearRetainingCapacity();
    for (mesh.shape.positions) |_| {
        try S.colors.append(opt.common.color);
    }

    try rd.?.appendVertex(
        renderer,
        model,
        camera,
        mesh.shape.indices,
        mesh.shape.positions,
        mesh.shape.normals.?,
        S.colors.items,
        null,
        .{
            .aabb = mesh.aabb,
            .cull_faces = opt.common.cull_faces,
            .lighting = opt.common.lighting_param,
        },
    );
}

/// Draw a cone
pub const ConeDrawOption = struct {
    common: CommonDrawOption,
    slices: u32 = 20,
    stacks: u32 = 1,
};
pub fn drawCone(camera: Camera, model: zmath.Mat, opt: ConeDrawOption) !void {
    const S = struct {
        const Mesh = struct {
            shape: zmesh.Shape,
            aabb: [6]f32,
        };

        var meshes: ?std.StringHashMap(*Mesh) = null;
        var colors: std.ArrayList(sdl.Color) = undefined;
        var buf: [32]u8 = undefined;

        fn getKey(_opt: ConeDrawOption) []u8 {
            return std.fmt.bufPrint(&buf, "{d}-{d}", .{ _opt.slices, _opt.stacks }) catch unreachable;
        }
    };

    if (S.meshes == null) {
        S.meshes = std.StringHashMap(*S.Mesh).init(arena.allocator());
        S.colors = try std.ArrayList(sdl.Color).initCapacity(arena.allocator(), 20);
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
        m.shape.computeAabb(&m.aabb);
        m.shape.computeNormals();
        try S.meshes.?.put(try arena.allocator().dupe(u8, key), m);
        break :BLK m;
    };

    S.colors.clearRetainingCapacity();
    for (mesh.shape.positions) |_| {
        try S.colors.append(opt.common.color);
    }

    try rd.?.appendVertex(
        renderer,
        model,
        camera,
        mesh.shape.indices,
        mesh.shape.positions,
        mesh.shape.normals.?,
        S.colors.items,
        null,
        .{
            .aabb = mesh.aabb,
            .cull_faces = opt.common.cull_faces,
            .lighting = opt.common.lighting_param,
        },
    );
}

/// Draw a cylinder
pub const CylinderDrawOption = struct {
    common: CommonDrawOption,
    slices: u32 = 20,
    stacks: u32 = 1,
};
pub fn drawCylinder(camera: Camera, model: zmath.Mat, opt: CylinderDrawOption) !void {
    const S = struct {
        const Mesh = struct {
            shape: zmesh.Shape,
            aabb: [6]f32,
        };

        var meshes: ?std.StringHashMap(*Mesh) = null;
        var colors: std.ArrayList(sdl.Color) = undefined;
        var buf: [32]u8 = undefined;

        fn getKey(_opt: CylinderDrawOption) []u8 {
            return std.fmt.bufPrint(&buf, "{d}-{d}", .{ _opt.slices, _opt.stacks }) catch unreachable;
        }
    };

    if (S.meshes == null) {
        S.meshes = std.StringHashMap(*S.Mesh).init(arena.allocator());
        S.colors = try std.ArrayList(sdl.Color).initCapacity(arena.allocator(), 20);
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
        m.shape.computeAabb(&m.aabb);
        m.shape.computeNormals();
        try S.meshes.?.put(try arena.allocator().dupe(u8, key), m);
        break :BLK m;
    };

    S.colors.clearRetainingCapacity();
    for (mesh.shape.positions) |_| {
        try S.colors.append(opt.common.color);
    }

    try rd.?.appendVertex(
        renderer,
        model,
        camera,
        mesh.shape.indices,
        mesh.shape.positions,
        mesh.shape.normals.?,
        S.colors.items,
        null,
        .{
            .aabb = mesh.aabb,
            .cull_faces = opt.common.cull_faces,
            .lighting = opt.common.lighting_param,
        },
    );
}

/// Draw a disk
pub const DiskDrawOption = struct {
    common: CommonDrawOption,
    radius: f32 = 1,
    slices: u32 = 20,
    center: [3]f32 = .{ 0, 0, 0 },
    normal: [3]f32 = .{ 0, 0, 1 },
};
pub fn drawDisk(camera: Camera, model: zmath.Mat, opt: DiskDrawOption) !void {
    const S = struct {
        const Mesh = struct {
            shape: zmesh.Shape,
            aabb: [6]f32,
        };

        var meshes: ?std.StringHashMap(*Mesh) = null;
        var colors: std.ArrayList(sdl.Color) = undefined;
        var buf: [64]u8 = undefined;

        fn getKey(_opt: DiskDrawOption) []u8 {
            return std.fmt.bufPrint(
                &buf,
                "{d:.3}-{d}-({d:.3}/{d:.3}/{d:.3})-({d:.3}/{d:.3}/{d:.3})",
                .{
                    _opt.radius,    _opt.slices,
                    _opt.center[0], _opt.center[1],
                    _opt.center[2], _opt.normal[0],
                    _opt.normal[1], _opt.normal[2],
                },
            ) catch unreachable;
        }
    };

    if (S.meshes == null) {
        S.meshes = std.StringHashMap(*S.Mesh).init(arena.allocator());
        S.colors = try std.ArrayList(sdl.Color).initCapacity(arena.allocator(), 20);
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
        m.shape.computeAabb(&m.aabb);
        m.shape.computeNormals();
        try S.meshes.?.put(try arena.allocator().dupe(u8, key), m);
        break :BLK m;
    };

    S.colors.clearRetainingCapacity();
    for (mesh.shape.positions) |_| {
        try S.colors.append(opt.common.color);
    }

    try rd.?.appendVertex(
        renderer,
        model,
        camera,
        mesh.shape.indices,
        mesh.shape.positions,
        mesh.shape.normals.?,
        S.colors.items,
        null,
        .{
            .aabb = mesh.aabb,
            .cull_faces = opt.common.cull_faces,
            .lighting = opt.common.lighting_param,
        },
    );
}

/// Draw a torus
pub const TorusDrawOption = struct {
    common: CommonDrawOption,
    radius: f32 = 0.2,
    slices: u32 = 10,
    stacks: u32 = 20,
};
pub fn drawTorus(camera: Camera, model: zmath.Mat, opt: TorusDrawOption) !void {
    const S = struct {
        const Mesh = struct {
            shape: zmesh.Shape,
            aabb: [6]f32,
        };

        var meshes: ?std.StringHashMap(*Mesh) = null;
        var colors: std.ArrayList(sdl.Color) = undefined;
        var buf: [64]u8 = undefined;

        fn getKey(_opt: TorusDrawOption) []u8 {
            return std.fmt.bufPrint(
                &buf,
                "{d:.3}-{d}-{d}",
                .{ _opt.radius, _opt.slices, _opt.stacks },
            ) catch unreachable;
        }
    };

    if (S.meshes == null) {
        S.meshes = std.StringHashMap(*S.Mesh).init(arena.allocator());
        S.colors = try std.ArrayList(sdl.Color).initCapacity(arena.allocator(), 20);
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
        m.shape.computeAabb(&m.aabb);
        m.shape.computeNormals();
        try S.meshes.?.put(try arena.allocator().dupe(u8, key), m);
        break :BLK m;
    };

    S.colors.clearRetainingCapacity();
    for (mesh.shape.positions) |_| {
        try S.colors.append(opt.common.color);
    }

    try rd.?.appendVertex(
        renderer,
        model,
        camera,
        mesh.shape.indices,
        mesh.shape.positions,
        mesh.shape.normals.?,
        S.colors.items,
        null,
        .{
            .aabb = mesh.aabb,
            .cull_faces = opt.common.cull_faces,
            .lighting = opt.common.lighting_param,
        },
    );
}

/// Draw a icosahedron
pub fn drawIcosahedron(camera: Camera, model: zmath.Mat, opt: CommonDrawOption) !void {
    const S = struct {
        var shape: ?zmesh.Shape = null;
        var colors: std.ArrayList(sdl.Color) = undefined;
        var aabb: [6]f32 = undefined;
    };

    if (S.shape == null) {
        S.shape = zmesh.Shape.initIcosahedron();
        S.shape.?.computeNormals();
        S.shape.?.computeAabb(&S.aabb);
        S.colors = try std.ArrayList(sdl.Color).initCapacity(arena.allocator(), 8);
    }

    S.colors.clearRetainingCapacity();
    for (S.shape.?.positions) |_| {
        try S.colors.append(opt.color);
    }

    try rd.?.appendVertex(
        renderer,
        model,
        camera,
        S.shape.?.indices,
        S.shape.?.positions,
        S.shape.?.normals.?,
        S.colors.items,
        null,
        .{
            .aabb = S.aabb,
            .cull_faces = opt.cull_faces,
            .lighting = opt.lighting_param,
        },
    );
}

/// Draw a dodecahedron
pub fn drawDodecahedron(camera: Camera, model: zmath.Mat, opt: CommonDrawOption) !void {
    const S = struct {
        var shape: ?zmesh.Shape = null;
        var colors: std.ArrayList(sdl.Color) = undefined;
        var aabb: [6]f32 = undefined;
    };

    if (S.shape == null) {
        S.shape = zmesh.Shape.initDodecahedron();
        S.shape.?.computeNormals();
        S.shape.?.computeAabb(&S.aabb);
        S.colors = try std.ArrayList(sdl.Color).initCapacity(arena.allocator(), 8);
    }

    S.colors.clearRetainingCapacity();
    for (S.shape.?.positions) |_| {
        try S.colors.append(opt.color);
    }

    try rd.?.appendVertex(
        renderer,
        model,
        camera,
        S.shape.?.indices,
        S.shape.?.positions,
        S.shape.?.normals.?,
        S.colors.items,
        null,
        .{
            .aabb = S.aabb,
            .cull_faces = opt.cull_faces,
            .lighting = opt.lighting_param,
        },
    );
}

/// Draw a octahedron
pub fn drawOctahedron(camera: Camera, model: zmath.Mat, opt: CommonDrawOption) !void {
    const S = struct {
        var shape: ?zmesh.Shape = null;
        var colors: std.ArrayList(sdl.Color) = undefined;
        var aabb: [6]f32 = undefined;
    };

    if (S.shape == null) {
        S.shape = zmesh.Shape.initOctahedron();
        S.shape.?.computeNormals();
        S.shape.?.computeAabb(&S.aabb);
        S.colors = try std.ArrayList(sdl.Color).initCapacity(arena.allocator(), 8);
    }

    S.colors.clearRetainingCapacity();
    for (S.shape.?.positions) |_| {
        try S.colors.append(opt.color);
    }

    try rd.?.appendVertex(
        renderer,
        model,
        camera,
        S.shape.?.indices,
        S.shape.?.positions,
        S.shape.?.normals.?,
        S.colors.items,
        null,
        .{
            .aabb = S.aabb,
            .cull_faces = opt.cull_faces,
            .lighting = opt.lighting_param,
        },
    );
}

/// Draw a tetrahedron
pub fn drawTetrahedron(camera: Camera, model: zmath.Mat, opt: CommonDrawOption) !void {
    const S = struct {
        var shape: ?zmesh.Shape = null;
        var colors: std.ArrayList(sdl.Color) = undefined;
        var aabb: [6]f32 = undefined;
    };

    if (S.shape == null) {
        S.shape = zmesh.Shape.initTetrahedron();
        S.shape.?.computeNormals();
        S.shape.?.computeAabb(&S.aabb);
        S.colors = try std.ArrayList(sdl.Color).initCapacity(arena.allocator(), 8);
    }

    S.colors.clearRetainingCapacity();
    for (S.shape.?.positions) |_| {
        try S.colors.append(opt.color);
    }

    try rd.?.appendVertex(
        renderer,
        model,
        camera,
        S.shape.?.indices,
        S.shape.?.positions,
        S.shape.?.normals.?,
        S.colors.items,
        null,
        .{
            .aabb = S.aabb,
            .cull_faces = opt.cull_faces,
            .lighting = opt.lighting_param,
        },
    );
}
