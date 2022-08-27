const jok = @import("../jok.zig");

/// Linear algebra calculation
pub const zmath = jok.deps.zmath;

/// Regularly used math constants
pub const v_up = zmath.f32x4(0, 1, 0, 0);
pub const v_down = zmath.f32x4(0, -1, 0, 0);
pub const v_right = zmath.f32x4(1, 0, 0, 0);
pub const v_left = zmath.f32x4(-1, 0, 0, 0);
pub const v_forward = zmath.f32x4(0, 0, 1, 0);
pub const v_backward = zmath.f32x4(0, 0, -1, 0);

/// 3d Mesh (loading/writing/optimization/generation)
pub const zmesh = jok.deps.zmesh;

/// 3d pixel renderer (using SDL2 to accelerate pixel rendering)
/// More control of fragment detail, but slower
pub const PixelRenderer = @import("3d/PixelRenderer.zig");

/// 3d triangle renderer (using SDL2 to accelerate triangle rendering)
/// Less control of fragment detail, but way faster
pub const TriangleRenderer = @import("3d/TriangleRenderer.zig");

/// 3d camera
pub const Camera = @import("3d/Camera.zig");

/// 3d scene (Clone of three.js's scene. Learn detail from https://threejs.org/manual/#en/scenegraph)
pub const Scene = @import("3d/Scene.zig");

/// 3d primitive drawing
pub const primitive = @import("3d/primitive.zig");
