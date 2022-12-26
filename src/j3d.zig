const jok = @import("jok.zig");

/// Linear algebra calculation
pub const zmath = jok.deps.zmath;

/// Regularly used math constants
pub const v_zero = zmath.f32x4(0, 0, 0, 0);
pub const v_up = zmath.f32x4(0, 1, 0, 0);
pub const v_down = zmath.f32x4(0, -1, 0, 0);
pub const v_right = zmath.f32x4(1, 0, 0, 0);
pub const v_left = zmath.f32x4(-1, 0, 0, 0);
pub const v_forward = zmath.f32x4(0, 0, 1, 0);
pub const v_backward = zmath.f32x4(0, 0, -1, 0);

/// Mesh manipulation (loading/writing/optimization/generation)
pub const zmesh = jok.deps.zmesh;

/// Common types related to lighting
pub const lighting = @import("j3d/lighting.zig");

/// 3d triangle renderer (accelerated by SDL, but with limited effects)
pub const TriangleRenderer = @import("j3d/TriangleRenderer.zig");

/// Parallel 3d triangle renderer (accelerated by SDL, but with limited effects)
pub const ParallelTriangleRenderer = @import("j3d/ParallelTriangleRenderer.zig");

/// 3d pixel renderer (software rasterization, more featureful but might be slow)
pub const PixelRenderer = @import("j3d/PixelRenderer.zig");

/// Skybox renderer
pub const SkyboxRenderer = @import("j3d/SkyboxRenderer.zig");

/// 3d camera
pub const Camera = @import("j3d/Camera.zig");

/// Scene management (Clone of three.js's scene. Learn detail from https://threejs.org/manual/#en/scenegraph)
pub const Scene = @import("j3d/Scene.zig");

/// 3d primitive drawing
pub const primitive = @import("j3d/primitive.zig");
