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
    };

    if (S.shape == null) {
        S.shape = zmesh.Shape.initCube();
        S.shape.?.computeNormals();
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
        .{},
    );
}

/// Draw a subdivided sphere
pub fn drawSubdividedSphere(camera: Camera, model: zmath.Mat, sub_num: u32, opt: CommonDrawOption) !void {
    const S = struct {
        var shapes: ?std.AutoHashMap(u32, *zmesh.Shape) = null;
        var colors: std.ArrayList(sdl.Color) = undefined;
    };

    if (S.shapes == null) {
        S.shapes = std.AutoHashMap(u32, *zmesh.Shape).init(arena.allocator());
        S.colors = try std.ArrayList(sdl.Color).initCapacity(arena.allocator(), 20);
    }

    var shape = BLK: {
        assert(sub_num > 0);
        if (S.shapes.?.get(sub_num)) |s| {
            break :BLK s;
        }

        var s = try arena.allocator().create(zmesh.Shape);
        s.* = zmesh.Shape.initSubdividedSphere(@intCast(i32, sub_num));
        s.computeNormals();
        try S.shapes.?.put(sub_num, s);
        break :BLK s;
    };

    S.colors.clearRetainingCapacity();
    for (shape.positions) |_| {
        try S.colors.append(opt.color);
    }

    try rd.?.appendVertex(
        renderer,
        model,
        camera,
        shape.indices,
        shape.positions,
        S.colors.items,
        null,
        .{},
    );
}
