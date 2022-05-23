const std = @import("std");
const assert = std.debug.assert;
const math = std.math;
const sdl = @import("sdl");
const jok = @import("../../jok.zig");
const @"3d" = jok.gfx.@"3d";
const zmath = @"3d".zmath;
const zmesh = @"3d".zmesh;
const Camera = @"3d".Camera;
const Self = @This();

/// Vertex Indices
indices: std.ArrayList(u32),

/// Triangle vertices
vertices: std.ArrayList(sdl.Vertex),

pub fn init(allocator: std.mem.Allocator) Self {
    return .{
        .indices = std.ArrayList(u32).init(allocator),
        .vertices = std.ArrayList(sdl.Vertex).init(allocator),
    };
}

pub fn deinit(self: *Self) void {
    self.indices.deinit();
    self.vertices.deinit();
}

/// Clear mesh data
pub fn clearVertex(self: *Self, retain_memory: bool) void {
    if (retain_memory) {
        self.indices.clearRetainingCapacity();
        self.vertices.clearRetainingCapacity();
    } else {
        self.indices.clearAndFree();
        self.vertices.clearAndFree();
    }
}

/// Append vertex data
pub fn appendVertex(
    self: *Self,
    renderer: sdl.Renderer,
    model: zmath.Mat,
    camera: *Camera,
    indices: []u16,
    positions: [][3]f32,
    colors: ?[]sdl.Color,
    texcoords: ?[][2]f32,
) !void {
    const vp = renderer.getViewport();

    // Add indices
    if (indices.len == 0) return;
    const base_index = @intCast(u32, self.vertices.items.len);
    try self.indices.ensureTotalCapacity(self.indices.items.len + indices.len);
    for (indices) |idx| self.indices.appendAssumeCapacity(
        @intCast(u32, idx) + base_index,
    );
    errdefer self.indices.resize(self.indices.items.len - indices.len) catch unreachable;

    // Add vertices
    try self.vertices.ensureTotalCapacity(self.indices.items.len + positions.len);
    const transform = zmath.mul(model, camera.getViewProjectMatrix());
    for (positions) |pos, i| {
        // Do MVP transforming
        const pos_clip = zmath.mul(zmath.f32x4(pos[0], pos[1], pos[2], 1.0), transform);
        const ndc = pos_clip / zmath.splat(zmath.Vec, pos_clip[3]);
        self.vertices.appendAssumeCapacity(.{
            .position = .{
                .x = (1.0 + ndc[0]) * @intToFloat(f32, vp.width) / 2.0,
                .y = @intToFloat(f32, vp.height) - (1.0 + ndc[1]) * @intToFloat(f32, vp.height) / 2.0,
            },
            .color = if (colors) |cs| cs[i] else sdl.Color.white,
            .tex_coord = if (texcoords) |tex| .{ .x = tex[i][0], .y = tex[i][1] } else undefined,
        });
    }
}

/// Render the data
pub fn render(self: Self, renderer: sdl.Renderer, tex: ?sdl.Texture) !void {
    try renderer.drawGeometry(
        tex,
        self.vertices.items,
        self.indices.items,
    );
}
