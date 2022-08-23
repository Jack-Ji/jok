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
    wireframe: bool,
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
        S.colors.items,
        null,
        .{ .aabb = S.aabb, .cull_faces = opt.cull_faces },
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
        S.colors.items,
        null,
        .{ .aabb = mesh.aabb, .cull_faces = opt.common.cull_faces },
    );
}
