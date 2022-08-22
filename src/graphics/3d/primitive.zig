const std = @import("std");
const assert = std.debug.assert;
const math = std.math;
const Renderer = @import("Renderer.zig");
const sdl = @import("sdl");
const jok = @import("../../jok.zig");
const @"3d" = jok.gfx.@"3d";
const zmath = @"3d".zmath;
const Camera = @"3d".Camera;

pub const CommonDrawOption = struct {
    model: zmath.Mat = zmath.identity(),
    camera: ?*Camera = null,
    color: sdl.Color = sdl.Color.white,
};

var rd: ?Renderer = null;
var camera: Camera = undefined;
var renderer: sdl.Renderer = undefined;

/// Create default primitive renderer
pub fn init(ctx: *jok.Context) !void {
    rd = Renderer.init(ctx.default_allocator);
    camera = Camera.fromPositionAndTarget(
        .{
            .perspective = .{
                .fov = jok.gfx.utils.degreeToRadian(70),
                .aspect_ratio = ctx.getAspectRatio(),
                .near = 0.1,
                .far = 100,
            },
        },
        [_]f32{ 10, 10, 10 },
        [_]f32{ 0, 0, 0 },
        null,
    );
    renderer = ctx.renderer;
}

/// Destroy default primitive renderer
pub fn deinit() void {
    rd.?.deinit();
}

/// Clear primitive
pub fn clear() void {
    rd.?.clear(true);
}

/// Render data
pub fn flush() !void {
    try rd.?.draw(renderer, null);
}

// Draw a cube
pub fn drawCube(size: f32, opt: CommonDrawOption) !void {
    const w = size / 2;
    const positions = [_][3]f32{
        .{ -w, -w, -w },
        .{ w, -w, -w },
        .{ w, w, -w },
        .{ -w, w, -w },
        .{ -w, -w, w },
        .{ w, -w, w },
        .{ w, w, w },
        .{ -w, w, w },
    };
    const colors = [_]sdl.Color{
        opt.color, opt.color, opt.color, opt.color,
        opt.color, opt.color, opt.color, opt.color,
    };
    const indices = [_]u16{
        0, 3, 2, 0, 2, 1,
        4, 5, 6, 4, 6, 7,
        0, 1, 5, 0, 5, 4,
        1, 2, 6, 1, 6, 5,
        2, 3, 7, 2, 7, 6,
        3, 0, 4, 3, 4, 7,
    };

    try rd.?.appendVertex(
        renderer,
        opt.model,
        opt.camera orelse &camera,
        &indices,
        &positions,
        &colors,
        null,
        .{},
    );
}
