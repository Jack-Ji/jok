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

/// raw 3d renderer
pub const Renderer = @import("3d/renderer.zig");

/// 3d camera
pub const Camera = @import("3d/Camera.zig");

/// 3d scene
pub const Scene = @import("3d/Scene.zig");

/// 3d primitive drawing
pub const primitive = @import("3d/primitive.zig");
