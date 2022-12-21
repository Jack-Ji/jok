const std = @import("std");
const assert = std.debug.assert;
const math = std.math;
const sdl = @import("sdl");
const jok = @import("../jok.zig");
const j3d = jok.j3d;
const zmath = j3d.zmath;
const Camera = j3d.Camera;
const utils = jok.utils;
const internal = @import("internal.zig");
const Self = @This();

allocator: std.mem.Allocator,
tex: sdl.Texture,
pixel_format: sdl.PixelFormatEnum,
width: i32,
height: i32,
color_buffer: []u32 = undefined,

// Temporary storage for clipping
clip_vertices: std.ArrayList(zmath.Vec),
clip_colors: std.ArrayList(sdl.Color),
clip_texcoords: std.ArrayList(sdl.PointF),

// Vertices in world space (after clipped)
world_positions: std.ArrayList(zmath.Vec),
world_normals: std.ArrayList(zmath.Vec),

pub fn init(allocator: std.mem.Allocator, renderer: sdl.Renderer, size: ?sdl.Size) !Self {
    const pixel_format = jok.utils.gfx.getFormatByEndian();
    const fb_size = try renderer.getOutputSize();
    const actual_size = size orelse sdl.Size{
        .width = fb_size.width_pixels,
        .height = fb_size.height_pixels,
    };
    const width = @intCast(usize, actual_size.width);
    const height = @intCast(usize, actual_size.height);
    var self = Self{
        .allocator = allocator,
        .pixel_format = pixel_format,
        .tex = try sdl.createTexture(renderer, pixel_format, .streaming, width, height),
        .width = @intCast(i32, width),
        .height = @intCast(i32, height),
        .color_buffer = try allocator.alloc(u32, width * height),
        .clip_vertices = std.ArrayList(zmath.Vec).init(allocator),
        .clip_colors = std.ArrayList(sdl.Color).init(allocator),
        .clip_texcoords = std.ArrayList(sdl.PointF).init(allocator),
        .world_positions = std.ArrayList(zmath.Vec).init(allocator),
        .world_normals = std.ArrayList(zmath.Vec).init(allocator),
    };
    return self;
}

pub fn deinit(self: *Self) void {
    self.tex.destroy();
    self.allocator.free(self.color_buffer);
    self.clip_vertices.deinit();
    self.clip_colors.deinit();
    self.clip_texcoords.deinit();
    self.world_positions.deinit();
    self.world_normals.deinit();
}

/// Clear the scene
pub const ClearOption = struct {
    clear_color: sdl.Color = sdl.Color.black,
};
pub fn clear(self: *Self, opt: ClearOption) void {
    std.mem.set(u32, self.color_buffer, self.mapRGBA(
        opt.clear_color.r,
        opt.clear_color.g,
        opt.clear_color.b,
        opt.clear_color.a,
    ));
}

/// Advanced vertice appending options
pub const AppendOption = struct {
    aabb: ?[6]f32 = null,
    cull_faces: bool = true,
    wireframe: bool = false,
};

/// Append shape data
pub fn appendShape(
    self: *Self,
    model: zmath.Mat,
    camera: Camera,
    indices: []const u16,
    positions: []const [3]f32,
    normals: []const [3]f32,
    colors: ?[]const sdl.Color,
    texcoords: ?[]const [2]f32,
    opt: AppendOption,
) !void {
    assert(@rem(indices.len, 3) == 0);
    assert(normals.len == positions.len);
    assert(if (colors) |cs| cs.len == positions.len else true);
    assert(if (texcoords) |ts| ts.len == positions.len else true);
    if (indices.len == 0) return;
    const ndc_to_screen = zmath.loadMat43(&[_]f32{
        0.5 * @intToFloat(f32, self.width), 0.0,                                  0.0,
        0.0,                                -0.5 * @intToFloat(f32, self.height), 0.0,
        0.0,                                0.0,                                  0.5,
        0.5 * @intToFloat(f32, self.width), 0.5 * @intToFloat(f32, self.height),  0.5,
    });
    const mvp = zmath.mul(model, camera.getViewProjectMatrix());

    // Do early test with aabb if possible
    if (opt.aabb) |ab| {
        const width = ab[3] - ab[0];
        const length = ab[5] - ab[2];
        assert(width >= 0);
        assert(length >= 0);
        const v0 = zmath.f32x4(ab[0], ab[1], ab[2], 1.0);
        const v1 = zmath.f32x4(ab[0], ab[1], ab[2] + length, 1.0);
        const v2 = zmath.f32x4(ab[0] + width, ab[1], ab[2] + length, 1.0);
        const v3 = zmath.f32x4(ab[0] + width, ab[1], ab[2], 1.0);
        const v4 = zmath.f32x4(ab[3] - width, ab[4], ab[5] - length, 1.0);
        const v5 = zmath.f32x4(ab[3] - width, ab[4], ab[5], 1.0);
        const v6 = zmath.f32x4(ab[3], ab[4], ab[5], 1.0);
        const v7 = zmath.f32x4(ab[3], ab[4], ab[5] - length, 1.0);
        const obb1 = zmath.mul(zmath.Mat{
            v0, v1, v2, v3,
        }, mvp);
        const obb2 = zmath.mul(zmath.Mat{
            v4, v5, v6, v7,
        }, mvp);

        // Ignore object outside of viewing space
        if (internal.isOBBOutside(&[_]zmath.Vec{
            obb1[0], obb1[1], obb1[2], obb1[3],
            obb2[0], obb2[1], obb2[2], obb2[3],
        })) return;
    }

    // Do face-culling and W-pannel clipping
    self.clip_vertices.clearRetainingCapacity();
    self.clip_colors.clearRetainingCapacity();
    self.clip_texcoords.clearRetainingCapacity();
    self.world_positions.clearRetainingCapacity();
    self.world_normals.clearRetainingCapacity();
    const ensure_size = indices.len * 2;
    try self.clip_vertices.ensureTotalCapacityPrecise(ensure_size);
    try self.clip_colors.ensureTotalCapacityPrecise(ensure_size);
    try self.clip_texcoords.ensureTotalCapacityPrecise(ensure_size);
    try self.world_positions.ensureTotalCapacityPrecise(ensure_size);
    try self.world_normals.ensureTotalCapacityPrecise(ensure_size);
    var i: usize = 2;
    while (i < indices.len) : (i += 3) {
        const idx0 = indices[i - 2];
        const idx1 = indices[i - 1];
        const idx2 = indices[i];
        const v0 = zmath.f32x4(positions[idx0][0], positions[idx0][1], positions[idx0][2], 1.0);
        const v1 = zmath.f32x4(positions[idx1][0], positions[idx1][1], positions[idx1][2], 1.0);
        const v2 = zmath.f32x4(positions[idx2][0], positions[idx2][1], positions[idx2][2], 1.0);
        const n0 = zmath.f32x4(normals[idx0][0], normals[idx0][1], normals[idx0][2], 0);
        const n1 = zmath.f32x4(normals[idx1][0], normals[idx1][1], normals[idx1][2], 0);
        const n2 = zmath.f32x4(normals[idx2][0], normals[idx2][1], normals[idx2][2], 0);

        // Ignore triangles facing away from camera (front faces' vertices are clock-wise organized)
        if (opt.cull_faces) {
            const world_positions = zmath.mul(zmath.Mat{
                v0,
                v1,
                v2,
                zmath.f32x4(0.0, 0.0, 0.0, 1.0),
            }, model);
            const face_dir = zmath.cross3(world_positions[1] - world_positions[0], world_positions[2] - world_positions[0]);
            const camera_dir = (world_positions[0] + world_positions[1] + world_positions[2]) /
                zmath.splat(zmath.Vec, 3.0) - camera.position;
            if (zmath.dot3(face_dir, camera_dir)[0] >= 0) continue;
        }

        // Clip triangles behind camera
        const tri_world_positions = zmath.mul(zmath.Mat{
            v0,
            v1,
            v2,
            zmath.f32x4(0.0, 0.0, 0.0, 1.0),
        }, model);
        var tri_world_normals = zmath.mul(zmath.Mat{
            n0,
            n1,
            n2,
            zmath.f32x4s(0),
        }, zmath.transpose(zmath.inverse(model)));
        tri_world_normals[0] = zmath.normalize3(tri_world_normals[0]);
        tri_world_normals[1] = zmath.normalize3(tri_world_normals[1]);
        tri_world_normals[2] = zmath.normalize3(tri_world_normals[2]);
        tri_world_normals[0][3] = 0;
        tri_world_normals[1][3] = 0;
        tri_world_normals[2][3] = 0;
        const tri_clip_positions = zmath.mul(zmath.Mat{
            v0,
            v1,
            v2,
            zmath.f32x4(0.0, 0.0, 0.0, 1.0),
        }, mvp);
        const tri_colors: ?[3]sdl.Color = if (colors) |cs|
            [3]sdl.Color{ cs[idx0], cs[idx1], cs[idx2] }
        else
            null;
        const tri_texcoords: ?[3]sdl.PointF = if (texcoords) |ts|
            [3]sdl.PointF{
                .{ .x = ts[idx0][0], .y = ts[idx0][1] },
                .{ .x = ts[idx1][0], .y = ts[idx1][1] },
                .{ .x = ts[idx2][0], .y = ts[idx2][1] },
            }
        else
            null;
        internal.clipTriangle(
            tri_world_positions[0..3],
            tri_world_normals[0..3],
            tri_clip_positions[0..3],
            tri_colors,
            tri_texcoords,
            &self.clip_vertices,
            &self.clip_colors,
            &self.clip_texcoords,
            &self.world_positions,
            &self.world_normals,
        );
    }
    if (self.clip_vertices.items.len == 0) return;
    assert(@rem(self.clip_vertices.items.len, 3) == 0);

    // Continue with remaining triangles
    i = 2;
    while (i < self.clip_vertices.items.len) : (i += 3) {
        const idx0 = i - 2;
        const idx1 = i - 1;
        const idx2 = i;
        const clip_v0 = self.clip_vertices.items[idx0];
        const clip_v1 = self.clip_vertices.items[idx1];
        const clip_v2 = self.clip_vertices.items[idx2];
        const world_v0 = self.world_positions.items[idx0];
        const world_v1 = self.world_positions.items[idx1];
        const world_v2 = self.world_positions.items[idx2];
        const n0 = self.world_normals.items[idx0];
        const n1 = self.world_normals.items[idx1];
        const n2 = self.world_normals.items[idx2];
        const ndc0 = clip_v0 / zmath.splat(zmath.Vec, clip_v0[3]);
        const ndc1 = clip_v1 / zmath.splat(zmath.Vec, clip_v1[3]);
        const ndc2 = clip_v2 / zmath.splat(zmath.Vec, clip_v2[3]);

        // Ignore triangles outside of NDC
        if (internal.isTriangleOutside(ndc0, ndc1, ndc2)) {
            continue;
        }

        // Calculate screen coordinate
        const ndcs = zmath.Mat{
            ndc0,
            ndc1,
            ndc2,
            zmath.f32x4(0.0, 0.0, 0.0, 1.0),
        };
        const positions_screen = zmath.mul(ndcs, ndc_to_screen);
        const x0 = positions_screen[0][0];
        const y0 = positions_screen[0][1];
        const z0 = positions_screen[0][2];
        const x1 = positions_screen[1][0];
        const y1 = positions_screen[1][1];
        const z1 = positions_screen[1][2];
        const x2 = positions_screen[2][0];
        const y2 = positions_screen[2][1];
        const z2 = positions_screen[2][2];

        // Finally, we draw the triangles
        const c0 = if (colors) |_| self.clip_colors.items[idx0] else sdl.Color.white;
        // TODO Interpolate pixels color based on lighting model
        //const c1 = if (colors) |_| self.clip_colors.items[idx1] else sdl.Color.white;
        //const c2 = if (colors) |_| self.clip_colors.items[idx2] else sdl.Color.white;
        //const t0 = if (texcoords) |_| self.clip_texcoords.items[idx0] else undefined;
        //const t1 = if (texcoords) |_| self.clip_texcoords.items[idx1] else undefined;
        //const t2 = if (texcoords) |_| self.clip_texcoords.items[idx2] else undefined;
        _ = world_v0;
        _ = world_v1;
        _ = world_v2;
        _ = n0;
        _ = n1;
        _ = n2;
        _ = z0;
        _ = z1;
        _ = z2;
        if (opt.wireframe) {
            try self.line(@floatToInt(i32, x0), @floatToInt(i32, y0), @floatToInt(i32, x1), @floatToInt(i32, y1), c0);
            try self.line(@floatToInt(i32, x0), @floatToInt(i32, y0), @floatToInt(i32, x2), @floatToInt(i32, y2), c0);
            try self.line(@floatToInt(i32, x1), @floatToInt(i32, y1), @floatToInt(i32, x2), @floatToInt(i32, y2), c0);
        } else {
            try self.triangle(
                @floatToInt(i32, x0),
                @floatToInt(i32, y0),
                @floatToInt(i32, x1),
                @floatToInt(i32, y1),
                @floatToInt(i32, x2),
                @floatToInt(i32, y2),
                c0,
            );
        }
    }
}

/// Draw the scene
pub fn draw(self: Self, renderer: sdl.Renderer, pos: ?sdl.Rectangle) !void {
    try self.tex.update(std.mem.sliceAsBytes(self.color_buffer), @intCast(usize, self.width * 4), null);
    try renderer.copy(self.tex, pos, null);
}

/// Add triangle
pub fn triangle(self: *Self, _x0: i32, _y0: i32, _x1: i32, _y1: i32, _x2: i32, _y2: i32, color: sdl.Color) !void {
    const x0 = math.clamp(_x0, 0, self.width);
    const x1 = math.clamp(_x1, 0, self.width);
    const x2 = math.clamp(_x2, 0, self.width);
    const y0 = math.clamp(_y0, 0, self.width);
    const y1 = math.clamp(_y1, 0, self.width);
    const y2 = math.clamp(_y2, 0, self.width);
    const xrange = utils.math.minAndMax(x0, x1, x2);
    const yrange = utils.math.minAndMax(y0, y1, y2);
    const tri = [3][2]f32{
        [_]f32{ @intToFloat(f32, _x0), @intToFloat(f32, _y0) },
        [_]f32{ @intToFloat(f32, _x1), @intToFloat(f32, _y1) },
        [_]f32{ @intToFloat(f32, _x2), @intToFloat(f32, _y2) },
    };
    var x = xrange[0];
    while (x <= xrange[1]) : (x += 1) {
        var y = yrange[0];
        while (y <= yrange[1]) : (y += 1) {
            if (!utils.math.isPointInTriangle(tri, [_]f32{ @intToFloat(f32, x), @intToFloat(f32, y) })) {
                continue;
            }
            try self.pixel(x, y, color);
        }
    }
}

/// Add line
pub fn line(self: *Self, _x0: i32, _y0: i32, _x1: i32, _y1: i32, color: sdl.Color) !void {
    var x0 = _x0;
    var y0 = _y0;
    var x1 = _x1;
    var y1 = _y1;
    var steep = false;
    if (try math.absInt(x0 - x1) < try math.absInt(y0 - y1)) {
        std.mem.swap(i32, &x0, &y0);
        std.mem.swap(i32, &x1, &y1);
        steep = true;
    }
    if (x0 > x1) {
        std.mem.swap(i32, &x0, &x1);
        std.mem.swap(i32, &y0, &y1);
    }

    var dx = x1 - x0;
    var dy = y1 - y0;
    var derror2 = try math.absInt(dy) * 2;
    var error2 = @as(i32, 0);
    var x = x0;
    var y = y0;
    while (x <= x1) : (x += 1) {
        if (steep) {
            try self.pixel(y, x, color);
        } else {
            try self.pixel(x, y, color);
        }
        error2 += derror2;
        if (error2 > dx) {
            y += if (y1 > y0) 1 else -1;
            error2 -= dx * 2;
        }
    }
}

/// Add pixel
pub fn pixel(self: *Self, x: i32, y: i32, color: sdl.Color) !void {
    if (self.posToIndex(x, y)) |idx| {
        self.color_buffer[idx] = self.mapRGBA(color.r, color.g, color.b, color.a);
    }
}

//-------------------------------------------------------------------------------
//
// Internal functions
//
//-------------------------------------------------------------------------------
inline fn posToIndex(self: Self, x: i32, y: i32) ?u32 {
    if (x < 0 or x >= self.width or y < 0 or y >= self.height) return null;
    return @intCast(u32, x + y * self.width);
}

inline fn mapRGBA(self: Self, _r: u8, _g: u8, _b: u8, _a: u8) u32 {
    const r = @intCast(u32, _r);
    const g = @intCast(u32, _g);
    const b = @intCast(u32, _b);
    const a = @intCast(u32, _a);
    return switch (self.pixel_format) {
        .rgba8888 => (r << 24) | (g << 16) | (b << 8) | a,
        .abgr8888 => (a << 24) | (b << 16) | (g << 8) | r,
        else => unreachable,
    };
}
