//! 3D camera system for view and projection transformations.
//!
//! This module provides a camera implementation supporting:
//! - Perspective and orthographic projections
//! - Position and orientation control
//! - Camera movement and rotation
//! - View frustum management
//! - Screen-space coordinate calculations
//! - Visibility testing
//!
//! The camera uses Euler angles (pitch, yaw, roll) for orientation.

const std = @import("std");
const assert = std.debug.assert;
const math = std.math;
const jok = @import("../jok.zig");
const Point = jok.j2d.geom.Point;
const j3d = jok.j3d;
const zmath = jok.vendor.zmath;
const internal = @import("internal.zig");
const Self = @This();

/// View frustum parameters for projection
pub const ViewFrustum = union(enum) {
    /// Orthographic projection (parallel lines stay parallel)
    orthographic: struct {
        width: f32,
        height: f32,
        near: f32,
        far: f32,
    },
    /// Perspective projection (simulates human eye perspective)
    perspective: struct {
        fov: f32,
        aspect_ratio: f32,
        near: f32,
        far: f32,
    },
};

/// Camera movement directions
const MoveDirection = enum {
    forward,
    backward,
    left,
    right,
    up,
    down,
};

/// World up vector (Y-axis)
const world_up = zmath.f32x4(0, 1, 0, 0);

/// Viewing frustum configuration
frustum: ViewFrustum = undefined,

/// Camera position in world space
position: zmath.Vec = undefined,

/// Camera forward direction vector
dir: zmath.Vec = undefined,

/// Camera up direction vector
up: zmath.Vec = undefined,

/// Camera right direction vector
right: zmath.Vec = undefined,

/// Euler angle: rotation around X-axis (radians)
pitch: f32 = undefined,
/// Euler angle: rotation around Y-axis (radians)
yaw: f32 = undefined,
/// Euler angle: rotation around Z-axis (radians)
roll: f32 = undefined,

/// Create a camera from position and target point
/// The camera will look at the target from the given position
pub fn fromPositionAndTarget(frustum: ViewFrustum, pos: [3]f32, target: [3]f32) Self {
    var camera: Self = .{};
    camera.frustum = frustum;
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

/// Create a camera from position and Euler angles
/// Angles are specified in radians
pub fn fromPositionAndEulerAngles(frustum: ViewFrustum, pos: [3]f32, pitch: f32, yaw: f32) Self {
    var camera: Self = .{};
    camera.frustum = frustum;
    camera.position = zmath.f32x4(pos[0], pos[1], pos[2], 1.0);
    camera.pitch = pitch;
    camera.yaw = yaw;
    camera.roll = 0;
    camera.updateVectors();
    return camera;
}

/// Get the camera's transformation matrix
pub fn getTransform(self: Self) zmath.Mat {
    return zmath.mul(zmath.mul(
        zmath.rotationX(self.pitch),
        zmath.rotationY(self.yaw),
    ), zmath.translationV(self.position));
}

/// Get the projection matrix based on frustum settings
pub fn getProjectMatrix(self: Self) zmath.Mat {
    return switch (self.frustum) {
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

/// Get the view matrix for transforming world space to camera space
pub fn getViewMatrix(self: Self) zmath.Mat {
    return zmath.lookToLh(self.position, self.dir, world_up);
}

/// Get the combined view-projection matrix
pub fn getViewProjectMatrix(self: Self) zmath.Mat {
    return zmath.mul(self.getViewMatrix(), self.getProjectMatrix());
}

/// Get the near and far clipping plane distances
pub fn getViewRange(self: Self) [2]f32 {
    return switch (self.frustum) {
        .orthographic => |p| [2]f32{ p.near, p.far },
        .perspective => |p| [2]f32{ p.near, p.far },
    };
}

/// Move the camera in a specified direction by a given distance
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

/// Rotate the camera by delta angles (in radians)
pub fn rotateBy(self: *Self, delta_pitch: f32, delta_yaw: f32) void {
    self.pitch += delta_pitch;
    self.yaw += delta_yaw;
    self.updateVectors();
}

/// Change the field of view by a delta value (in radians)
/// Only applies to perspective cameras
pub fn zoomBy(self: *Self, delta: f32) void {
    if (self.frustum == .orthographic) return;
    self.frustum.perspective.fov = math.clamp(
        self.frustum.perspective.fov + delta,
        math.pi * 0.05,
        math.pi * 0.95,
    );
}

/// Rotate the camera around a point (orbit camera)
/// Angles are specified in radians
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
        self.frustum,
        .{ new_pos[0], new_pos[1], new_pos[2] },
        point orelse .{ 0, 0, 0 },
    );
}

/// Update camera direction vectors based on Euler angles
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

/// Calculate the screen position of a 3D coordinate
/// Returns 2D screen coordinates
pub fn calcScreenPosition(
    self: Self,
    ctx: jok.Context,
    model: zmath.Mat,
    _coord: ?[3]f32,
) Point {
    const csz = ctx.getCanvasSize();
    const csz_w = csz.getWidthFloat();
    const csz_h = csz.getHeightFloat();
    const ndc_to_screen = zmath.loadMat43(&[_]f32{
        0.5 * csz_w, 0.0,          0.0,
        0.0,         -0.5 * csz_h, 0.0,
        0.0,         0.0,          0.5,
        0.5 * csz_w, 0.5 * csz_h,  0.5,
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

/// Test if an axis-aligned bounding box is visible to the camera
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

/// Calculate the 3D position for ray casting from screen coordinates
/// Used for mouse picking and interaction
/// Screen position should be relative to the top-left corner of the viewport
pub fn calcRayTestTarget(
    self: Self,
    ctx: jok.Context,
    screen_x: f32,
    screen_y: f32,
    _test_distance: ?f32,
) zmath.Vec {
    const far_plane = _test_distance orelse 10000.0;
    const ray_forward = self.dir * zmath.splat(zmath.Vec, far_plane);
    const csz = ctx.getCanvasSize();
    switch (self.frustum) {
        .orthographic => |p| {
            const hor = self.right * zmath.splat(zmath.Vec, p.width);
            const vertical = self.up * zmath.splat(zmath.Vec, p.height);

            const ray_to_center = self.position + ray_forward;
            const csz_w = csz.getWidthFloat();
            const csz_h = csz.getHeightFloat();
            const dhor = hor * zmath.splat(zmath.Vec, 1.0 / csz_w);
            const dvert = vertical * zmath.splat(zmath.Vec, 1.0 / csz_h);

            var ray_to = ray_to_center - hor * zmath.splat(zmath.Vec, 0.5) - vertical * zmath.splat(zmath.Vec, 0.5);
            ray_to = ray_to + dhor * zmath.splat(zmath.Vec, screen_x);
            ray_to = ray_to + dvert * zmath.splat(zmath.Vec, csz_h - screen_y);
            return ray_to;
        },
        .perspective => |p| {
            const tanfov = @tan(0.5 * p.fov);
            const aspect = ctx.getAspectRatio();

            const hor = self.right * zmath.splat(zmath.Vec, 2.0 * far_plane * tanfov * aspect);
            const vertical = self.up * zmath.splat(zmath.Vec, 2.0 * far_plane * tanfov);

            const ray_to_center = self.position + ray_forward;
            const csz_w = csz.getWidthFloat();
            const csz_h = csz.getHeightFloat();
            const dhor = hor * zmath.splat(zmath.Vec, 1.0 / csz_w);
            const dvert = vertical * zmath.splat(zmath.Vec, 1.0 / csz_h);

            var ray_to = ray_to_center - hor * zmath.splat(zmath.Vec, 0.5) - vertical * zmath.splat(zmath.Vec, 0.5);
            ray_to = ray_to + dhor * zmath.splat(zmath.Vec, screen_x);
            ray_to = ray_to + dvert * zmath.splat(zmath.Vec, csz_h - screen_y);
            return ray_to;
        },
    }
}
