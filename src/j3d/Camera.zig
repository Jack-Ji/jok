const std = @import("std");
const assert = std.debug.assert;
const math = std.math;
const sdl = @import("sdl");
const jok = @import("../jok.zig");
const zmath = jok.zmath;
const j3d = jok.j3d;
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

// Viewing frustrum
frustrum: ViewFrustrum = undefined,

// Up vector of the world
world_up: zmath.Vec = undefined,

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
pub fn fromPositionAndTarget(frustrum: ViewFrustrum, pos: [3]f32, target: [3]f32, world_up: ?[3]f32) Self {
    var camera: Self = .{};
    camera.frustrum = frustrum;
    camera.world_up = zmath.normalize3(if (world_up) |up| zmath.f32x4(up[0], up[1], up[2], 1.0) else j3d.v_up);
    camera.position = zmath.f32x4(pos[0], pos[1], pos[2], 1.0);
    camera.dir = zmath.normalize3(zmath.f32x4(target[0], target[1], target[2], 1.0) - camera.position);
    camera.right = zmath.normalize3(zmath.cross3(camera.world_up, camera.dir));
    camera.up = zmath.normalize3(zmath.cross3(camera.dir, camera.right));

    // Calculate euler angles
    var crossdir = zmath.cross3(camera.up, camera.world_up);
    var angles = zmath.dot3(crossdir, camera.right);
    const cos_pitch = zmath.dot3(camera.world_up, camera.up);
    if (angles[0] < 0) {
        camera.pitch = math.acos(math.clamp(cos_pitch[0], -1, 1));
    } else {
        camera.pitch = -math.acos(math.clamp(cos_pitch[0], -1, 1));
    }
    crossdir = zmath.cross3(camera.right, j3d.v_right);
    angles = zmath.dot3(crossdir, camera.world_up);
    const cos_yaw = zmath.dot3(camera.right, j3d.v_right);
    if (angles[0] < 0) {
        camera.yaw = math.acos(math.clamp(cos_yaw[0], -1, 1));
    } else {
        camera.yaw = -math.acos(math.clamp(cos_yaw[0], -1, 1));
    }
    camera.roll = 0;
    return camera;
}

/// Create a 3d camera using position and euler angle (in degrees)
pub fn fromPositionAndEulerAngles(frustrum: ViewFrustrum, pos: [3]f32, pitch: f32, yaw: f32, world_up: ?[3]f32) Self {
    var camera: Self = .{};
    camera.frustrum = frustrum;
    camera.position = zmath.f32x4(pos[0], pos[1], pos[2], 1.0);
    camera.world_up = zmath.normalize3(if (world_up) |up| zmath.f32x4(up[0], up[1], up[2], 1.0) else j3d.v_up);
    camera.pitch = pitch;
    camera.yaw = yaw;
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
    return zmath.lookToLh(self.position, self.dir, self.world_up);
}

/// Get projection*view matrix
pub fn getViewProjectMatrix(self: Self) zmath.Mat {
    return zmath.mul(self.getViewMatrix(), self.getProjectMatrix());
}

/// Get screen position of given coordinate
pub fn getScreenPosition(
    self: Self,
    renderer: sdl.Renderer,
    model: zmath.Mat,
    coord: [3]f32,
) sdl.PointF {
    const vp = renderer.getViewport();
    const ndc_to_screen = zmath.loadMat43(&[_]f32{
        0.5 * @intToFloat(f32, vp.width), 0.0,                                0.0,
        0.0,                              -0.5 * @intToFloat(f32, vp.height), 0.0,
        0.0,                              0.0,                                0.5,
        0.5 * @intToFloat(f32, vp.width), 0.5 * @intToFloat(f32, vp.height),  0.5,
    });
    const mvp = zmath.mul(model, self.getViewProjectMatrix());
    const clip = zmath.mul(zmath.f32x4(coord[0], coord[1], coord[2], 1), mvp);
    const ndc = clip / zmath.splat(zmath.Vec, clip[3]);
    const screen = zmath.mul(ndc, ndc_to_screen);
    return .{ .x = screen[0], .y = screen[1] };
}

/// Move camera
pub fn move(self: *Self, direction: MoveDirection, distance: f32) void {
    var movement = switch (direction) {
        .forward => self.dir * zmath.splat(zmath.Vec, distance),
        .backward => self.dir * zmath.splat(zmath.Vec, -distance),
        .left => self.right * zmath.splat(zmath.Vec, -distance),
        .right => self.right * zmath.splat(zmath.Vec, distance),
        .up => self.up * zmath.splat(zmath.Vec, distance),
        .down => self.up * zmath.splat(zmath.Vec, -distance),
    };
    self.position = self.position + movement;
}

/// Rotate camera (in radians)
pub fn rotate(self: *Self, pitch: f32, yaw: f32) void {
    self.pitch += pitch;
    self.yaw += yaw;
    self.updateVectors();
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
    self.dir = zmath.normalize3(zmath.mul(j3d.v_forward, transform));
    self.right = zmath.normalize3(zmath.cross3(self.world_up, self.dir));
    self.up = zmath.normalize3(zmath.cross3(self.dir, self.right));
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
