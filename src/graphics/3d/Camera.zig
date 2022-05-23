const std = @import("std");
const assert = std.debug.assert;
const math = std.math;
const jok = @import("../../jok.zig");
const @"3d" = jok.gfx.@"3d";
const zmath = @"3d".zmath;
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

/// Viewing frustrum
frustrum: ViewFrustrum = undefined,

/// Up vector of the world
world_up: zmath.Vec = undefined,

/// Position of camera
position: zmath.Vec = undefined,

/// Direction of camera
dir: zmath.Vec = undefined,

/// Up of camera
up: zmath.Vec = undefined,

/// Right of camera
right: zmath.Vec = undefined,

/// Euler angle of camera
pitch: f32 = undefined,
yaw: f32 = undefined,
roll: f32 = undefined,

/// Create a camera using position and target
pub fn fromPositionAndTarget(frustrum: ViewFrustrum, pos: zmath.Vec, target: zmath.Vec, world_up: ?zmath.Vec) Self {
    var camera: Self = .{};
    camera.frustrum = frustrum;
    camera.world_up = zmath.normalize3(world_up orelse @"3d".v_up);
    camera.position = pos;
    camera.dir = zmath.normalize3(target - pos);
    camera.right = zmath.normalize3(zmath.cross3(camera.dir, camera.world_up));
    camera.up = zmath.normalize3(zmath.cross3(camera.right, camera.dir));

    // Calculate euler angles
    var crossdir = zmath.cross3(camera.world_up, camera.up);
    var angles = zmath.dot3(crossdir, camera.right);
    const cos_pitch = zmath.dot3(camera.world_up, camera.up);
    if (angles[0] < 0) {
        camera.pitch = -math.acos(cos_pitch[0]);
    } else {
        camera.pitch = math.acos(cos_pitch[0]);
    }
    crossdir = zmath.cross3(camera.right, @"3d".v_right);
    angles = zmath.dot3(crossdir, camera.world_up);
    const cos_yaw = zmath.dot3(camera.right, @"3d".v_right);
    if (zmath.Vec.dot(crossdir, camera.world_up) < 0) {
        camera.yaw = -math.acos(cos_yaw[0]) - math.pi / 2;
    } else {
        camera.yaw = math.acos(cos_yaw[0]) - math.pi / 2;
    }
    camera.roll = 0;
    return camera;
}

/// Create a 3d camera using position and euler angle (in degrees)
pub fn fromPositionAndEulerAngles(frustrum: ViewFrustrum, pos: zmath.Vec, pitch: f32, yaw: f32, world_up: ?zmath.Vec) Self {
    var camera: Self = .{};
    camera.frustrum = frustrum;
    camera.world_up = zmath.normalize3(world_up orelse @"3d".v_up);
    camera.position = pos;
    camera.pitch = pitch;
    camera.yaw = yaw - math.pi / 2;
    camera.roll = 0;
    camera.updateVectors();
    return camera;
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
    return zmath.lookAtLh(self.position, self.position + self.dir, self.world_up);
}

/// Get projection*view matrix
pub fn getViewProjectMatrix(self: Self) zmath.Mat {
    return zmath.mul(self.getViewMatrix(), getProjectMatrix());
}

/// Move camera
pub fn move(self: *Self, direction: MoveDirection, distance: f32) void {
    var movement = switch (direction) {
        .forward => self.dir * distance,
        .backward => self.dir * -distance,
        .left => self.right * -distance,
        .right => self.right * distance,
        .up => self.up * distance,
        .down => self.up * -distance,
    };
    self.position = self.position + movement;
}

/// Rotate camera (in degrees)
pub fn rotate(self: *Self, pitch: f32, yaw: f32) void {
    self.pitch += pitch;
    self.yaw += yaw;
    self.updateVectors();
}

/// Update vectors: direction/right/up
fn updateVectors(self: *Self) void {
    const min_pitch = -89.0 * math.pi / 180.0;
    const max_pitch = 89.0 * math.pi / 180.0;
    self.pitch = math.clamp(self.pitch, min_pitch, max_pitch);
    const sin_pitch = @sin(self.pitch);
    const cos_pitch = @cos(self.pitch);
    const sin_yaw = @sin(self.yaw);
    const cos_yaw = @cos(self.yaw);
    self.dir = zmath.normalize3(zmath.f32x4(cos_yaw * cos_pitch, sin_pitch, sin_yaw * cos_pitch, 0));
    self.right = zmath.normalize3(zmath.cross3(self.dir, self.world_up));
    self.up = zmath.normalize3(zmath.cross3(self.right, self.dir));
}

/// Get position of ray test target
/// NOTE: assuming mouse's coordinate is relative to top-left corner of viewport
pub fn getRayTestTarget(
    self: Self,
    viewport_w: u32,
    viewport_h: u32,
    mouse_x: u32,
    mouse_y: u32,
) zmath.Vec {
    assert(self.frustrum == .perspective);
    const far_plane: f32 = 10000.0;
    const tanfov = @tan(0.5 * self.frustrum.perspective.fov);
    const width = @intToFloat(f32, viewport_w);
    const height = @intToFloat(f32, viewport_h);
    const aspect = width / height;

    const ray_forward = self.dir * far_plane;
    const hor = self.right * zmath.splat(zmath.Vec, 2.0 * far_plane * tanfov * aspect);
    const vertical = self.up * zmath.splat(zmath.Vec, 2.0 * far_plane * tanfov);

    const ray_to_center = self.position + ray_forward;
    const dhor = hor * zmath.splat(zmath.Vec, 1.0 / width);
    const dvert = vertical * zmath.splat(zmath.Vec, 1.0 / height);

    var ray_to = ray_to_center - hor * zmath.splat(zmath.Vec, 0.5) - vertical * zmath.splat(zmath.Vec, 0.5);
    ray_to = ray_to + dhor * zmath.splat(zmath.Vec, @intToFloat(f32, mouse_x));
    ray_to = ray_to + dvert * zmath.splat(zmath.Vec, @intToFloat(f32, viewport_h - mouse_y));
    return ray_to;
}
