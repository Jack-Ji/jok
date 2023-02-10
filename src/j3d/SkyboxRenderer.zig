/// Skybox renderer
const std = @import("std");
const assert = std.debug.assert;
const math = std.math;
const sdl = @import("sdl");
const internal = @import("internal.zig");
const jok = @import("../jok.zig");
const zmath = jok.zmath;
const zmesh = jok.zmesh;
const j3d = jok.j3d;
const Camera = j3d.Camera;
const Self = @This();

// Box shape: right/left/top/bottom/front/back
box_planes: [6]zmesh.Shape,

// Temporary storage for clipping
clip_vertices: std.ArrayList(zmath.Vec),
clip_texcoords: std.ArrayList(sdl.PointF),

const InitOption = struct {
    plane_slices: i32 = 10,
    plane_stacks: i32 = 10,
};
pub fn init(allocator: std.mem.Allocator, opt: InitOption) Self {
    assert(opt.plane_slices > 0);
    assert(opt.plane_stacks > 0);
    return .{
        .box_planes = .{
            BLK: {
                // right side
                var shape = zmesh.Shape.initPlane(opt.plane_slices, opt.plane_stacks);
                shape.scale(2, 2, 0);
                shape.rotate(math.pi * 0.5, 0, 1, 0);
                shape.translate(1.0, -1.0, 1.0);
                break :BLK shape;
            },
            BLK: {
                // left side
                var shape = zmesh.Shape.initPlane(opt.plane_slices, opt.plane_stacks);
                shape.scale(2, 2, 0);
                shape.rotate(-math.pi * 0.5, 0, 1, 0);
                shape.translate(-1.0, -1.0, -1.0);
                break :BLK shape;
            },
            BLK: {
                // top side
                var shape = zmesh.Shape.initPlane(opt.plane_slices, opt.plane_stacks);
                shape.scale(2, 2, 0);
                shape.rotate(-math.pi * 0.5, 1, 0, 0);
                shape.translate(-1.0, 1.0, 1.0);
                break :BLK shape;
            },
            BLK: {
                // bottom side
                var shape = zmesh.Shape.initPlane(opt.plane_slices, opt.plane_stacks);
                shape.scale(2, 2, 0);
                shape.rotate(math.pi * 0.5, 1, 0, 0);
                shape.translate(-1.0, -1.0, -1.0);
                break :BLK shape;
            },
            BLK: {
                // front side
                var shape = zmesh.Shape.initPlane(opt.plane_slices, opt.plane_stacks);
                shape.scale(2, 2, 0);
                shape.translate(-1.0, -1.0, 1.0);
                break :BLK shape;
            },
            BLK: {
                // back side
                var shape = zmesh.Shape.initPlane(opt.plane_slices, opt.plane_stacks);
                shape.scale(2, 2, 0);
                shape.rotate(math.pi, 0, 1, 0);
                shape.translate(1.0, -1.0, -1.0);
                break :BLK shape;
            },
        },
        .clip_vertices = std.ArrayList(zmath.Vec).init(allocator),
        .clip_texcoords = std.ArrayList(sdl.PointF).init(allocator),
    };
}

pub fn deinit(self: *Self) void {
    for (self.box_planes) |s| s.deinit();
    self.clip_vertices.deinit();
    self.clip_texcoords.deinit();
    self.* = undefined;
}

pub fn render(
    self: *Self,
    viewpoint: sdl.Rectangle,
    target: *internal.RenderTarget,
    camera: Camera,
    textures: [6]sdl.Texture, // cube textures: right/left/top/bottom/front/back
    color: ?sdl.Color, // tint color
) !void {
    const ndc_to_screen = zmath.loadMat43(&[_]f32{
        0.5 * @intToFloat(f32, viewpoint.width), 0.0,                                       0.0,
        0.0,                                     -0.5 * @intToFloat(f32, viewpoint.height), 0.0,
        0.0,                                     0.0,                                       0.5,
        0.5 * @intToFloat(f32, viewpoint.width), 0.5 * @intToFloat(f32, viewpoint.height),  0.5,
    });
    var vp = camera.getViewMatrix();
    vp[3] = zmath.f32x4s(0);
    vp = zmath.mul(vp, camera.getProjectMatrix());

    for (self.box_planes) |plane, idx| {
        self.clip_vertices.clearRetainingCapacity();
        self.clip_texcoords.clearRetainingCapacity();

        // Do W-pannel clipping
        const ensure_size = plane.indices.len * 2;
        try self.clip_vertices.ensureTotalCapacityPrecise(ensure_size);
        try self.clip_texcoords.ensureTotalCapacityPrecise(ensure_size);
        var i: usize = 2;
        while (i < plane.indices.len) : (i += 3) {
            const idx0 = plane.indices[i - 2];
            const idx1 = plane.indices[i - 1];
            const idx2 = plane.indices[i];
            const v0 = zmath.f32x4(plane.positions[idx0][0], plane.positions[idx0][1], plane.positions[idx0][2], 1.0);
            const v1 = zmath.f32x4(plane.positions[idx1][0], plane.positions[idx1][1], plane.positions[idx1][2], 1.0);
            const v2 = zmath.f32x4(plane.positions[idx2][0], plane.positions[idx2][1], plane.positions[idx2][2], 1.0);

            // Clip triangles behind camera
            var clip_positions = zmath.mul(zmath.Mat{
                v0,
                v1,
                v2,
                zmath.f32x4(0.0, 0.0, 0.0, 1.0),
            }, vp);
            const clip_texcoords = [3]sdl.PointF{
                .{ .x = plane.texcoords.?[idx0][0], .y = plane.texcoords.?[idx0][1] },
                .{ .x = plane.texcoords.?[idx1][0], .y = plane.texcoords.?[idx1][1] },
                .{ .x = plane.texcoords.?[idx2][0], .y = plane.texcoords.?[idx2][1] },
            };
            self.clipTriangle(clip_positions[0..3], &clip_texcoords);
        }
        if (self.clip_vertices.items.len == 0) continue;
        assert(@rem(self.clip_vertices.items.len, 3) == 0);

        // Continue with remaining triangles
        try target.reserveCapacity(
            self.clip_vertices.items.len,
            self.clip_vertices.items.len,
        );
        i = 2;
        while (i < self.clip_vertices.items.len) : (i += 3) {
            const idx0 = i - 2;
            const idx1 = i - 1;
            const idx2 = i;
            const clip_v0 = self.clip_vertices.items[idx0];
            const clip_v1 = self.clip_vertices.items[idx1];
            const clip_v2 = self.clip_vertices.items[idx2];
            const ndc0 = clip_v0 / zmath.splat(zmath.Vec, clip_v0[3]);
            const ndc1 = clip_v1 / zmath.splat(zmath.Vec, clip_v1[3]);
            const ndc2 = clip_v2 / zmath.splat(zmath.Vec, clip_v2[3]);

            // Calculate screen coordinate
            const ndcs = zmath.Mat{
                ndc0,
                ndc1,
                ndc2,
                zmath.f32x4(0.0, 0.0, 0.0, 1.0),
            };
            const positions_screen = zmath.mul(ndcs, ndc_to_screen);

            // Finally, we can append vertices for rendering
            const t0 = self.clip_texcoords.items[idx0];
            const t1 = self.clip_texcoords.items[idx1];
            const t2 = self.clip_texcoords.items[idx2];
            try target.appendTrianglesAssumeCapacity(
                &.{ 0, 1, 2 },
                &[_]sdl.Vertex{
                    .{
                        .position = .{ .x = positions_screen[0][0], .y = positions_screen[0][1] },
                        .color = color orelse sdl.Color.white,
                        .tex_coord = t0,
                    },
                    .{
                        .position = .{ .x = positions_screen[1][0], .y = positions_screen[1][1] },
                        .color = color orelse sdl.Color.white,
                        .tex_coord = t1,
                    },
                    .{
                        .position = .{ .x = positions_screen[2][0], .y = positions_screen[2][1] },
                        .color = color orelse sdl.Color.white,
                        .tex_coord = t2,
                    },
                },
                &[_]f32{ 10, 10, 10 },
                textures[idx],
            );
        }
    }
}

/// Clip triangle in homogeneous space, against panel w=0.00001
/// We are conceptually clipping away stuff behind camera
inline fn clipTriangle(self: *Self, clip_positions: []const zmath.Vec, texcoords: []const sdl.PointF) void {
    const clip_plane_w = 0.0001;
    var clip_v0 = clip_positions[0];
    var clip_v1 = clip_positions[1];
    var clip_v2 = clip_positions[2];
    var d_v0 = clip_v0[3] - clip_plane_w;
    var d_v1 = clip_v1[3] - clip_plane_w;
    var d_v2 = clip_v2[3] - clip_plane_w;
    var is_v0_inside = d_v0 >= 0;
    var is_v1_inside = d_v1 >= 0;
    var is_v2_inside = d_v2 >= 0;
    var t0: sdl.PointF = texcoords[0];
    var t1: sdl.PointF = texcoords[1];
    var t2: sdl.PointF = texcoords[2];

    // The whole triangle is behind the camera, ignore directly
    if (!is_v0_inside and !is_v1_inside and !is_v2_inside) return;

    // Rearrange order of vertices, make sure first vertex is inside
    if (!is_v0_inside and is_v1_inside) {
        std.mem.swap(zmath.Vec, &clip_v0, &clip_v1);
        std.mem.swap(zmath.Vec, &clip_v1, &clip_v2);
        std.mem.swap(f32, &d_v0, &d_v1);
        std.mem.swap(f32, &d_v1, &d_v2);
        std.mem.swap(bool, &is_v0_inside, &is_v1_inside);
        std.mem.swap(bool, &is_v1_inside, &is_v2_inside);
        std.mem.swap(sdl.PointF, &t0, &t1);
        std.mem.swap(sdl.PointF, &t1, &t2);
    } else if (!is_v0_inside and !is_v1_inside) {
        std.mem.swap(zmath.Vec, &clip_v1, &clip_v2);
        std.mem.swap(zmath.Vec, &clip_v0, &clip_v1);
        std.mem.swap(f32, &d_v1, &d_v2);
        std.mem.swap(f32, &d_v0, &d_v1);
        std.mem.swap(bool, &is_v1_inside, &is_v2_inside);
        std.mem.swap(bool, &is_v0_inside, &is_v1_inside);
        std.mem.swap(sdl.PointF, &t1, &t2);
        std.mem.swap(sdl.PointF, &t0, &t1);
    }

    // Append first vertex
    assert(is_v0_inside);
    self.clip_vertices.appendAssumeCapacity(clip_v0);
    self.clip_texcoords.appendAssumeCapacity(t0);

    // Clip next 2 vertices, depending on their positions
    if (is_v1_inside) {
        self.clip_vertices.appendAssumeCapacity(clip_v1);
        self.clip_texcoords.appendAssumeCapacity(t1);

        if (is_v2_inside) {
            self.clip_vertices.appendAssumeCapacity(clip_v2);
            self.clip_texcoords.appendAssumeCapacity(t2);
        } else {
            // First triangle
            var lerp = d_v1 / (d_v1 - d_v2);
            assert(lerp >= 0 and lerp <= 1);
            var lerp_clip_position = zmath.lerp(clip_v1, clip_v2, lerp);
            var lerp_texcoord: sdl.PointF = sdl.PointF{
                .x = t1.x + (t2.x - t1.x) * lerp,
                .y = t1.y + (t2.y - t1.y) * lerp,
            };
            self.clip_vertices.appendAssumeCapacity(lerp_clip_position);
            self.clip_texcoords.appendAssumeCapacity(lerp_texcoord);

            // Second triangle
            self.clip_vertices.appendAssumeCapacity(clip_v0);
            self.clip_texcoords.appendAssumeCapacity(t0);
            self.clip_vertices.appendAssumeCapacity(lerp_clip_position);
            self.clip_texcoords.appendAssumeCapacity(lerp_texcoord);
            lerp = d_v0 / (d_v0 - d_v2);
            assert(lerp >= 0 and lerp <= 1);
            lerp_clip_position = zmath.lerp(clip_v0, clip_v2, lerp);
            lerp_texcoord = sdl.PointF{
                .x = t0.x + (t2.x - t0.x) * lerp,
                .y = t0.y + (t2.y - t0.y) * lerp,
            };
            self.clip_vertices.appendAssumeCapacity(lerp_clip_position);
            self.clip_texcoords.appendAssumeCapacity(lerp_texcoord);
        }
    } else {
        var lerp = d_v0 / (d_v0 - d_v1);
        assert(lerp >= 0 and lerp <= 1);
        var lerp_clip_position = zmath.lerp(clip_v0, clip_v1, lerp);
        var lerp_texcoord: sdl.PointF = sdl.PointF{
            .x = t0.x + (t1.x - t0.x) * lerp,
            .y = t0.y + (t1.y - t0.y) * lerp,
        };
        self.clip_vertices.appendAssumeCapacity(lerp_clip_position);
        self.clip_texcoords.appendAssumeCapacity(lerp_texcoord);

        if (is_v2_inside) {
            // First triangle
            lerp = d_v1 / (d_v1 - d_v2);
            assert(lerp >= 0 and lerp <= 1);
            lerp_clip_position = zmath.lerp(clip_v1, clip_v2, lerp);
            lerp_texcoord = sdl.PointF{
                .x = t1.x + (t2.x - t1.x) * lerp,
                .y = t1.y + (t2.y - t1.y) * lerp,
            };
            self.clip_vertices.appendAssumeCapacity(lerp_clip_position);
            self.clip_texcoords.appendAssumeCapacity(lerp_texcoord);

            // Second triangle
            self.clip_vertices.appendAssumeCapacity(clip_v0);
            self.clip_texcoords.appendAssumeCapacity(t0);
            self.clip_vertices.appendAssumeCapacity(lerp_clip_position);
            self.clip_texcoords.appendAssumeCapacity(lerp_texcoord);
            self.clip_vertices.appendAssumeCapacity(clip_v2);
            self.clip_texcoords.appendAssumeCapacity(t2);
        } else {
            lerp = d_v0 / (d_v0 - d_v2);
            assert(lerp >= 0 and lerp <= 1);
            lerp_clip_position = zmath.lerp(clip_v0, clip_v2, lerp);
            lerp_texcoord = sdl.PointF{
                .x = t0.x + (t2.x - t0.x) * lerp,
                .y = t0.y + (t2.y - t0.y) * lerp,
            };
            self.clip_vertices.appendAssumeCapacity(lerp_clip_position);
            self.clip_texcoords.appendAssumeCapacity(lerp_texcoord);
        }
    }
}
