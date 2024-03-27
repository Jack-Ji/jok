/// 3d camera
const std = @import("std");
const assert = std.debug.assert;
const math = std.math;
const jok = @import("../jok.zig");
const sdl = jok.sdl;
const zmath = jok.zmath;
const j3d = jok.j3d;
const internal = @import("internal.zig");
const Self = @This();

/// Params for viewing frustrum
pub const ViewFrustrum = union(enum) {
    orthographic: struct {
        width: f32,
        height: f32,
        near: f32,
        far: f32,
    },
    perspective: struct {
        fov: f32,
        aspect_ratio: f32,
        near: f32,
        far: f32,
    },
};

const MoveDirection = enum {
    forward,
    backward,
    left,
    right,
    up,
    down,
};

const world_up = zmath.f32x4(0, 1, 0, 0);

// Viewing frustrum
frustrum: ViewFrustrum = undefined,

// Position of camera
position: zmath.Vec = undefined,

// Direction of camera
dir: zmath.Vec = undefined,

// Up of camera
up: zmath.Vec = undefined,

// Right of camera
right: zmath.Vec = undefined,

// Euler angle of camera
pitch: f32 = undefined,
yaw: f32 = undefined,
roll: f32 = undefined,

/// Create a camera using position and target
pub fn fromPositionAndTarget(frustrum: ViewFrustrum, pos: [3]f32, target: [3]f32) Self {
    var camera: Self = .{};
    camera.frustrum = frustrum;
    camera.position = zmath.f32x4(pos[0], pos[1], pos[2], 1.0);
    camera.dir = zmath.normalize3(zmath.f32x4(target[0], target[1], target[2], 1.0) - camera.position);
    camera.right = zmath.normalize3(zmath.cross3(world_up, camera.dir));
    camera.up = zmath.normalize3(zmath.cross3(camera.dir, camera.right));

    // Calculate euler angles
    var crossdir = zmath.cross3(camera.up, world_up);
    var angles = zmath.dot3(crossdir, camera.right);
    const cos_pitch = zmath.dot3(world_up, camera.up);
    if (angles[0] < 0) {
        camera.pitch = math.acos(math.clamp(cos_pitch[0], -1, 1));
    } else {
        camera.pitch = -math.acos(math.clamp(cos_pitch[0], -1, 1));
    }
    crossdir = zmath.cross3(camera.right, zmath.f32x4(1, 0, 0, 0));
    angles = zmath.dot3(crossdir, world_up);
    const cos_yaw = zmath.dot3(camera.right, zmath.f32x4(1, 0, 0, 0));
    if (angles[0] < 0) {
        camera.yaw = math.acos(math.clamp(cos_yaw[0], -1, 1));
    } else {
        camera.yaw = -math.acos(math.clamp(cos_yaw[0], -1, 1));
    }
    camera.roll = 0;
    return camera;
}

/// Create a 3d camera using position and euler angle (in degrees)
pub fn fromPositionAndEulerAngles(frustrum: ViewFrustrum, pos: [3]f32, pitch: f32, yaw: f32) Self {
    var camera: Self = .{};
    camera.frustrum = frustrum;
    camera.position = zmath.f32x4(pos[0], pos[1], pos[2], 1.0);
    camera.pitch = pitch;
    camera.yaw = yaw;
    camera.roll = 0;
    camera.updateVectors();
    return camera;
}

/// Get camera's own transform
pub fn getTransform(self: Self) zmath.Mat {
    return zmath.mul(zmath.mul(
        zmath.rotationX(self.pitch),
        zmath.rotationY(self.yaw),
    ), zmath.translationV(self.position));
}

/// Get projection matrix
pub fn getProjectMatrix(self: Self) zmath.Mat {
    return switch (self.frustrum) {
        .orthographic => |param| zmath.orthographicLh(
            param.width,
            param.height,
            param.near,
            param.far,
        ),
        .perspective => |param| zmath.perspectiveFovLh(
            param.fov,
            param.aspect_ratio,
            param.near,
            param.far,
        ),
    };
}

/// Get view matrix
pub fn getViewMatrix(self: Self) zmath.Mat {
    return zmath.lookToLh(self.position, self.dir, world_up);
}

/// Get projection*view matrix
pub fn getViewProjectMatrix(self: Self) zmath.Mat {
    return zmath.mul(self.getViewMatrix(), self.getProjectMatrix());
}

/// Get view distances
pub fn getViewRange(self: Self) [2]f32 {
    return switch (self.frustrum) {
        .orthographic => |p| [2]f32{ p.near, p.far },
        .perspective => |p| [2]f32{ p.near, p.far },
    };
}

/// Move camera
pub fn moveBy(self: *Self, direction: MoveDirection, distance: f32) void {
    const movement = switch (direction) {
        .forward => self.dir * zmath.splat(zmath.Vec, distance),
        .backward => self.dir * zmath.splat(zmath.Vec, -distance),
        .left => self.right * zmath.splat(zmath.Vec, -distance),
        .right => self.right * zmath.splat(zmath.Vec, distance),
        .up => self.up * zmath.splat(zmath.Vec, distance),
        .down => self.up * zmath.splat(zmath.Vec, -distance),
    };
    self.position = self.position + movement;
}

/// Rotate camera around axises (in radians)
pub fn rotateBy(self: *Self, delta_pitch: f32, delta_yaw: f32) void {
    self.pitch += delta_pitch;
    self.yaw += delta_yaw;
    self.updateVectors();
}

/// Change zoom relatively (by radian)
pub fn zoomBy(self: *Self, delta: f32) void {
    if (self.frustrum == .orthographic) return;
    self.frustrum.perspective.fov = math.clamp(
        self.frustrum.perspective.fov + delta,
        math.pi * 0.05,
        math.pi * 0.95,
    );
}

/// Rotate camera around given point (in radians)
pub fn rotateAroundBy(self: *Self, point: ?[3]f32, delta_angle_h: f32, delta_angle_v: f32) void {
    const center = if (point) |p|
        zmath.f32x4(p[0], p[1], p[2], 1)
    else
        zmath.f32x4(0, 0, 0, 1);
    const v = self.position - center;
    var angle_h = math.atan2(
        v[0],
        v[2],
    );
    var angle_v = math.atan2(
        v[1],
        math.sqrt(v[0] * v[0] + v[2] * v[2]),
    );
    angle_h = zmath.modAngle(angle_h + delta_angle_h);
    angle_v = zmath.clamp(angle_v + delta_angle_v, -math.pi * 0.45, math.pi * 0.45);
    const transform = zmath.mul(
        zmath.rotationX(-angle_v),
        zmath.rotationY(angle_h),
    );
    const new_pos = zmath.mul(
        zmath.f32x4(0, 0, zmath.length3(v)[0], 1),
        transform,
    ) + center;
    self.* = fromPositionAndTarget(
        self.frustrum,
        .{ new_pos[0], new_pos[1], new_pos[2] },
        point orelse .{ 0, 0, 0 },
    );
}

/// Update vectors: direction/right/up
fn updateVectors(self: *Self) void {
    self.pitch = math.clamp(
        self.pitch,
        -0.48 * math.pi,
        0.48 * math.pi,
    );
    self.yaw = zmath.modAngle(self.yaw);
    const transform = zmath.mul(
        zmath.rotationX(self.pitch),
        zmath.rotationY(self.yaw),
    );
    self.dir = zmath.normalize3(zmath.mul(zmath.f32x4(0, 0, 1, 0), transform));
    self.right = zmath.normalize3(zmath.cross3(world_up, self.dir));
    self.up = zmath.normalize3(zmath.cross3(self.dir, self.right));
}

/// Get screen position of given coordinate
pub fn calcScreenPosition(
    self: Self,
    ctx: jok.Context,
    model: zmath.Mat,
    _coord: ?[3]f32,
) sdl.PointF {
    const csz = ctx.getCanvasSize();
    const ndc_to_screen = zmath.loadMat43(&[_]f32{
        0.5 * csz.x, 0.0,          0.0,
        0.0,         -0.5 * csz.y, 0.0,
        0.0,         0.0,          0.5,
        0.5 * csz.x, 0.5 * csz.y,  0.5,
    });
    const mvp = zmath.mul(model, self.getViewProjectMatrix());
    const coord = if (_coord) |c|
        zmath.f32x4(c[0], c[1], c[2], 1)
    else
        zmath.f32x4(0, 0, 0, 1);
    const clip = zmath.mul(coord, mvp);
    const ndc = clip / zmath.splat(zmath.Vec, clip[3]);
    const screen = zmath.mul(ndc, ndc_to_screen);
    return .{ .x = screen[0], .y = screen[1] };
}

/// Test visibility of aabb
pub fn isVisible(self: Self, model: zmath.Mat, aabb: [6]f32) bool {
    const mvp = zmath.mul(model, self.getViewProjectMatrix());
    const width = aabb[3] - aabb[0];
    const length = aabb[5] - aabb[2];
    assert(width >= 0);
    assert(length >= 0);
    const v0 = zmath.f32x4(aabb[0], aabb[1], aabb[2], 1.0);
    const v1 = zmath.f32x4(aabb[0], aabb[1], aabb[2] + length, 1.0);
    const v2 = zmath.f32x4(aabb[0] + width, aabb[1], aabb[2] + length, 1.0);
    const v3 = zmath.f32x4(aabb[0] + width, aabb[1], aabb[2], 1.0);
    const v4 = zmath.f32x4(aabb[3] - width, aabb[4], aabb[5] - length, 1.0);
    const v5 = zmath.f32x4(aabb[3] - width, aabb[4], aabb[5], 1.0);
    const v6 = zmath.f32x4(aabb[3], aabb[4], aabb[5], 1.0);
    const v7 = zmath.f32x4(aabb[3], aabb[4], aabb[5] - length, 1.0);
    const obb1 = zmath.mul(zmath.Mat{ v0, v1, v2, v3 }, mvp);
    const obb2 = zmath.mul(zmath.Mat{ v4, v5, v6, v7 }, mvp);

    return !internal.isOBBOutside(&[_]zmath.Vec{
        obb1[0], obb1[1], obb1[2], obb1[3],
        obb2[0], obb2[1], obb2[2], obb2[3],
    });
}

/// Get position of ray test target
/// NOTE: assuming screen position is relative to top-left corner of viewport
pub fn clacRayTestTarget(
    self: Self,
    ctx: jok.Context,
    screen_x: f32,
    screen_y: f32,
    _test_distance: ?f32,
) zmath.Vec {
    assert(self.frustrum == .perspective);
    const far_plane = _test_distance orelse 10000.0;
    const ray_forward = self.dir * far_plane;
    const csz = ctx.getCanvasSize();
    switch (self.frustrum) {
        .orthographic => |p| {
            const hor = self.right * zmath.splat(zmath.Vec, csz.x);
            const vertical = self.up * zmath.splat(zmath.Vec, p.height);

            const ray_to_center = self.position + ray_forward;
            const dhor = hor * zmath.splat(zmath.Vec, 1.0 / csz.x);
            const dvert = vertical * zmath.splat(zmath.Vec, 1.0 / csz.y);

            var ray_to = ray_to_center - hor * zmath.splat(zmath.Vec, 0.5) - vertical * zmath.splat(zmath.Vec, 0.5);
            ray_to = ray_to + dhor * zmath.splat(zmath.Vec, screen_x);
            ray_to = ray_to + dvert * zmath.splat(zmath.Vec, csz.y - screen_y);
            return ray_to;
        },
        .perspective => |p| {
            const tanfov = @tan(0.5 * p.fov);
            const aspect = ctx.getAspectRatio();

            const hor = self.right * zmath.splat(zmath.Vec, 2.0 * far_plane * tanfov * aspect);
            const vertical = self.up * zmath.splat(zmath.Vec, 2.0 * far_plane * tanfov);

            const ray_to_center = self.position + ray_forward;
            const dhor = hor * zmath.splat(zmath.Vec, 1.0 / csz.x);
            const dvert = vertical * zmath.splat(zmath.Vec, 1.0 / csz.y);

            var ray_to = ray_to_center - hor * zmath.splat(zmath.Vec, 0.5) - vertical * zmath.splat(zmath.Vec, 0.5);
            ray_to = ray_to + dhor * zmath.splat(zmath.Vec, screen_x);
            ray_to = ray_to + dvert * zmath.splat(zmath.Vec, csz.y - screen_y);
            return ray_to;
        },
    }
}
