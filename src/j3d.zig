const jok = @import("jok.zig");

/// Regularly used math constants
pub const zmath = jok.zmath;
pub const v_zero = jok.zmath.f32x4(0, 0, 0, 0);
pub const v_up = jok.zmath.f32x4(0, 1, 0, 0);
pub const v_down = jok.zmath.f32x4(0, -1, 0, 0);
pub const v_right = jok.zmath.f32x4(1, 0, 0, 0);
pub const v_left = jok.zmath.f32x4(-1, 0, 0, 0);
pub const v_forward = jok.zmath.f32x4(0, 0, 1, 0);
pub const v_backward = jok.zmath.f32x4(0, 0, -1, 0);

/// Common types related to lighting
pub const lighting = @import("j3d/lighting.zig");

/// 3d triangle renderer (accelerated by SDL, but with limited effects)
pub const TriangleRenderer = @import("j3d/TriangleRenderer.zig");

/// Parallel 3d triangle renderer (accelerated by SDL, but with limited effects)
pub const ParallelTriangleRenderer = @import("j3d/ParallelTriangleRenderer.zig");

/// Skybox renderer
pub const SkyboxRenderer = @import("j3d/SkyboxRenderer.zig");

/// 3d camera
pub const Camera = @import("j3d/Camera.zig");

/// Scene management (Clone of three.js's scene. Learn detail from https://threejs.org/manual/#en/scenegraph)
pub const Scene = @import("j3d/Scene.zig");

/// 3d primitive drawing
pub const primitive = @import("j3d/primitive.zig");
