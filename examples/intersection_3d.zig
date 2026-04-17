const std = @import("std");
const jok = @import("jok");
const j3d = jok.j3d;
const geom = j3d.geom;
const Camera = j3d.Camera;
const zmath = jok.vendor.zmath;

pub const jok_window_resizable = true;

// ==================================================================
// Constants and Configuration
// ==================================================================

const RAYCAST_PLANE_Y: f32 = 0.0;
const PICK_SPHERE_BIAS_BASE: f32 = 0.2;
const PICK_SPHERE_BIAS_SCALE: f32 = 0.02;

const PLANE_SIZE: f32 = 20.0;
const RAY_LENGTH: f32 = 50.0;
const NORMAL_VISUAL_LENGTH: f32 = 0.5;
const LINE_THICKNESS: f32 = 0.05;
const RAY_THICKNESS: f32 = 0.03;
const PLANE_LINE_THICKNESS: f32 = 0.03;

const CAMERA_FOV: f32 = std.math.degreesToRadians(70);
const CAMERA_NEAR: f32 = 0.1;
const CAMERA_FAR: f32 = 1000.0;
const CAMERA_START_POS: [3]f32 = .{ 0, 5, 15 };
const CAMERA_START_TARGET: [3]f32 = .{ 0, 0, 0 };

const MOVE_SPEED: f32 = 5.0;
const MOUSE_ROTATE_SPEED: f32 = 0.0025;
const OBB_ROTATION_SPEED: f32 = 0.5;

// ==================================================================
// Geometry Definitions
// ==================================================================

// Initial geometry objects
var aabb0 = geom.AABB.init(.{ -3, -1, -1 }, .{ -1, 1, 1 });
var aabb1 = geom.AABB.init(.{ -2, -1, 0 }, .{ 0, 1, 2 });

var sphere0 = geom.Sphere.init(.{ 3, 0, 0 }, 1.0);
var sphere1 = geom.Sphere.init(.{ 4.5, 0, 0 }, 1.0);

var plane = geom.Plane.init(.{ 0, -2, 0 }, .{ 0, 1, 0 });

var tri0 = geom.Triangle.init(.{ -1.5, 0, 1 }, .{ -0.5, 0, 1 }, .{ -1.0, 0, 2.5 });
var tri1 = geom.Triangle.init(.{ -1.5, -0.5, 2.0 }, .{ 0.5, 1.0, 4.0 }, .{ -0.5, 0.25, 5.0 });

var obb0 = geom.OBB.init(
    .{ 3, 0, 4 },
    .{ .{ 1, 0, 0 }, .{ 0, 1, 0 }, .{ 0, 0, 1 } },
    .{ 1, 1, 1 },
);
var obb1 = geom.OBB.init(
    .{ 4.5, 0, 4 },
    .{ .{ 1, 0, 0 }, .{ 0, 1, 0 }, .{ 0, 0, 1 } },
    .{ 0.8, 0.8, 0.8 },
);

// Locked Y positions for dragging (prevents vertical movement)
const LOCKED_Y: struct {
    aabb0: f32 = 0.0,
    aabb1: f32 = 0.0,
    sphere0: f32 = 0.0,
    sphere1: f32 = 0.0,
    tri0: f32 = 0.0,
    tri1: f32 = 0.25,
    obb0: f32 = 0.0,
    obb1: f32 = 0.0,
} = .{};

// ==================================================================
// Dragging System
// ==================================================================

const DragTarget = enum {
    none,
    aabb0,
    aabb1,
    sphere0,
    sphere1,
    tri0,
    tri1,
    obb0,
    obb1,
};

var batchpool: j3d.BatchPool(64, false) = undefined;
var camera: Camera = undefined;

var raycast_ray: ?geom.Ray = null;
var drag_ray: ?geom.Ray = null;

var drag_target: DragTarget = .none;
var drag_offset: [3]f32 = .{ 0, 0, 0 };
var drag_plane_y: f32 = 0.0;

// ==================================================================
// Helper Functions
// ==================================================================

fn getLockedY(target: DragTarget) f32 {
    return switch (target) {
        .aabb0 => LOCKED_Y.aabb0,
        .aabb1 => LOCKED_Y.aabb1,
        .sphere0 => LOCKED_Y.sphere0,
        .sphere1 => LOCKED_Y.sphere1,
        .tri0 => LOCKED_Y.tri0,
        .tri1 => LOCKED_Y.tri1,
        .obb0 => LOCKED_Y.obb0,
        .obb1 => LOCKED_Y.obb1,
        .none => 0.0,
    };
}

fn getObjectCenter(target: DragTarget) [3]f32 {
    return switch (target) {
        .aabb0 => aabb0.center(),
        .aabb1 => aabb1.center(),
        .sphere0 => sphere0.center,
        .sphere1 => sphere1.center,
        .tri0 => .{
            (tri0.v0[0] + tri0.v1[0] + tri0.v2[0]) / 3.0,
            (tri0.v0[1] + tri0.v1[1] + tri0.v2[1]) / 3.0,
            (tri0.v0[2] + tri0.v1[2] + tri0.v2[2]) / 3.0,
        },
        .tri1 => .{
            (tri1.v0[0] + tri1.v1[0] + tri1.v2[0]) / 3.0,
            (tri1.v0[1] + tri1.v1[1] + tri1.v2[1]) / 3.0,
            (tri1.v0[2] + tri1.v1[2] + tri1.v2[2]) / 3.0,
        },
        .obb0 => obb0.center,
        .obb1 => obb1.center,
        .none => .{ 0, 0, 0 },
    };
}

fn buildDragRay(ctx: jok.Context, x: f32, y: f32) geom.Ray {
    const target = camera.calcRayTestTarget(ctx, x, y, 1.0);
    const origin = camera.position;
    const dir = zmath.normalize3(target - origin);
    return geom.Ray.init(
        .{ origin[0], origin[1], origin[2] },
        .{ dir[0], dir[1], dir[2] },
    );
}

fn buildRaycastRay(ctx: jok.Context, x: f32, y: f32) geom.Ray {
    const camera_ray = buildDragRay(ctx, x, y);
    const plane_xz = geom.Plane.init(.{ 0, RAYCAST_PLANE_Y, 0 }, .{ 0, 1, 0 });

    if (camera_ray.raycast(plane_xz)) |hit| {
        const origin = zmath.f32x4(0, RAYCAST_PLANE_Y, 0, 0);
        const target_xz = zmath.f32x4(hit.point[0], RAYCAST_PLANE_Y, hit.point[2], 0);
        const dir_raw = target_xz - origin;
        const dir = if (zmath.length3(dir_raw)[0] > 0)
            zmath.normalize3(dir_raw)
        else
            zmath.f32x4(0, 0, 1, 0);

        return geom.Ray.init(
            .{ 0, RAYCAST_PLANE_Y, 0 },
            .{ dir[0], 0, dir[2] },
        );
    }
    return geom.Ray.init(.{ 0, RAYCAST_PLANE_Y, 0 }, .{ 0, 0, 1 });
}

fn calculatePickSphereBias(sphere: geom.Sphere) f32 {
    const dist = zmath.length3(zmath.f32x4(
        camera.position[0] - sphere.center[0],
        camera.position[1] - sphere.center[1],
        camera.position[2] - sphere.center[2],
        0,
    ))[0];
    return @max(PICK_SPHERE_BIAS_BASE, dist * PICK_SPHERE_BIAS_SCALE);
}

// ==================================================================
// Intersection Detection
// ==================================================================

fn updateIntersectionFlags() struct {
    aabb0: bool,
    aabb1: bool,
    sphere0: bool,
    sphere1: bool,
    tri0: bool,
    tri1: bool,
    obb0: bool,
    obb1: bool,
} {
    return .{
        .aabb0 = aabb0.intersect(aabb1) or aabb0.intersect(sphere0) or aabb0.intersect(sphere1) or
            aabb0.intersect(plane) or aabb0.intersect(tri0) or aabb0.intersect(tri1) or
            aabb0.intersect(obb0) or aabb0.intersect(obb1),

        .aabb1 = aabb1.intersect(aabb0) or aabb1.intersect(sphere0) or aabb1.intersect(sphere1) or
            aabb1.intersect(plane) or aabb1.intersect(tri0) or aabb1.intersect(tri1) or
            aabb1.intersect(obb0) or aabb1.intersect(obb1),

        .sphere0 = sphere0.intersect(aabb0) or sphere0.intersect(aabb1) or sphere0.intersect(sphere1) or
            sphere0.intersect(plane) or sphere0.intersect(tri0) or sphere0.intersect(tri1) or
            sphere0.intersect(obb0) or sphere0.intersect(obb1),

        .sphere1 = sphere1.intersect(aabb0) or sphere1.intersect(aabb1) or sphere1.intersect(sphere0) or
            sphere1.intersect(plane) or sphere1.intersect(tri0) or sphere1.intersect(tri1) or
            sphere1.intersect(obb0) or sphere1.intersect(obb1),

        .tri0 = tri0.intersect(aabb0) or tri0.intersect(aabb1) or tri0.intersect(sphere0) or
            tri0.intersect(sphere1) or tri0.intersect(plane) or tri0.intersect(tri1) or
            tri0.intersect(obb0) or tri0.intersect(obb1),

        .tri1 = tri1.intersect(aabb0) or tri1.intersect(aabb1) or tri1.intersect(sphere0) or
            tri1.intersect(sphere1) or tri1.intersect(plane) or tri1.intersect(tri0) or
            tri1.intersect(obb0) or tri1.intersect(obb1),

        .obb0 = obb0.intersect(aabb0) or obb0.intersect(aabb1) or obb0.intersect(sphere0) or
            obb0.intersect(sphere1) or obb0.intersect(plane) or obb0.intersect(obb1) or
            obb0.intersect(tri0) or obb0.intersect(tri1),

        .obb1 = obb1.intersect(aabb0) or obb1.intersect(aabb1) or obb1.intersect(sphere0) or
            obb1.intersect(sphere1) or obb1.intersect(plane) or obb1.intersect(obb0) or
            obb1.intersect(tri0) or obb1.intersect(tri1),
    };
}

// ==================================================================
// Rendering Helpers
// ==================================================================

fn drawAABB(b: *j3d.Batch, aabb: geom.AABB, color: jok.Color) !void {
    const min = aabb.min;
    const max = aabb.max;
    const corners = [8][3]f32{
        .{ min[0], min[1], min[2] }, .{ max[0], min[1], min[2] },
        .{ max[0], max[1], min[2] }, .{ min[0], max[1], min[2] },
        .{ min[0], min[1], max[2] }, .{ max[0], min[1], max[2] },
        .{ max[0], max[1], max[2] }, .{ min[0], max[1], max[2] },
    };
    const edges = [12][2]u8{
        .{ 0, 1 }, .{ 1, 2 }, .{ 2, 3 }, .{ 3, 0 },
        .{ 4, 5 }, .{ 5, 6 }, .{ 6, 7 }, .{ 7, 4 },
        .{ 0, 4 }, .{ 1, 5 }, .{ 2, 6 }, .{ 3, 7 },
    };

    for (edges) |edge| {
        try b.line(corners[edge[0]], corners[edge[1]], .{
            .color = color.toColorF(),
            .thickness = LINE_THICKNESS,
        });
    }
}

fn drawOBB(b: *j3d.Batch, obb: geom.OBB, color: jok.Color) !void {
    const c = obb.center;
    const e = obb.half_extents;
    const ax = obb.axes;

    const corners = [8][3]f32{
        .{ c[0] - ax[0][0] * e[0] - ax[1][0] * e[1] - ax[2][0] * e[2], c[1] - ax[0][1] * e[0] - ax[1][1] * e[1] - ax[2][1] * e[2], c[2] - ax[0][2] * e[0] - ax[1][2] * e[1] - ax[2][2] * e[2] },
        .{ c[0] + ax[0][0] * e[0] - ax[1][0] * e[1] - ax[2][0] * e[2], c[1] + ax[0][1] * e[0] - ax[1][1] * e[1] - ax[2][1] * e[2], c[2] + ax[0][2] * e[0] - ax[1][2] * e[1] - ax[2][2] * e[2] },
        .{ c[0] + ax[0][0] * e[0] + ax[1][0] * e[1] - ax[2][0] * e[2], c[1] + ax[0][1] * e[0] + ax[1][1] * e[1] - ax[2][1] * e[2], c[2] + ax[0][2] * e[0] + ax[1][2] * e[1] - ax[2][2] * e[2] },
        .{ c[0] - ax[0][0] * e[0] + ax[1][0] * e[1] - ax[2][0] * e[2], c[1] - ax[0][1] * e[0] + ax[1][1] * e[1] - ax[2][1] * e[2], c[2] - ax[0][2] * e[0] + ax[1][2] * e[1] - ax[2][2] * e[2] },
        .{ c[0] - ax[0][0] * e[0] - ax[1][0] * e[1] + ax[2][0] * e[2], c[1] - ax[0][1] * e[0] - ax[1][1] * e[1] + ax[2][1] * e[2], c[2] - ax[0][2] * e[0] - ax[1][2] * e[1] + ax[2][2] * e[2] },
        .{ c[0] + ax[0][0] * e[0] - ax[1][0] * e[1] + ax[2][0] * e[2], c[1] + ax[0][1] * e[0] - ax[1][1] * e[1] + ax[2][1] * e[2], c[2] + ax[0][2] * e[0] - ax[1][2] * e[1] + ax[2][2] * e[2] },
        .{ c[0] + ax[0][0] * e[0] + ax[1][0] * e[1] + ax[2][0] * e[2], c[1] + ax[0][1] * e[0] + ax[1][1] * e[1] + ax[2][1] * e[2], c[2] + ax[0][2] * e[0] + ax[1][2] * e[1] + ax[2][2] * e[2] },
        .{ c[0] - ax[0][0] * e[0] + ax[1][0] * e[1] + ax[2][0] * e[2], c[1] - ax[0][1] * e[0] + ax[1][1] * e[1] + ax[2][1] * e[2], c[2] - ax[0][2] * e[0] + ax[1][2] * e[1] + ax[2][2] * e[2] },
    };

    const edges = [12][2]u8{
        .{ 0, 1 }, .{ 1, 2 }, .{ 2, 3 }, .{ 3, 0 },
        .{ 4, 5 }, .{ 5, 6 }, .{ 6, 7 }, .{ 7, 4 },
        .{ 0, 4 }, .{ 1, 5 }, .{ 2, 6 }, .{ 3, 7 },
    };

    for (edges) |edge| {
        try b.line(corners[edge[0]], corners[edge[1]], .{
            .color = color.toColorF(),
            .thickness = LINE_THICKNESS,
        });
    }
}

fn drawTriangle(b: *j3d.Batch, tri: geom.Triangle, color: jok.Color) !void {
    try b.line(tri.v0, tri.v1, .{ .color = color.toColorF(), .thickness = LINE_THICKNESS });
    try b.line(tri.v1, tri.v2, .{ .color = color.toColorF(), .thickness = LINE_THICKNESS });
    try b.line(tri.v2, tri.v0, .{ .color = color.toColorF(), .thickness = LINE_THICKNESS });
}

fn drawRayHit(b: *j3d.Batch, hit: geom.Ray.Hit) !void {
    const p = hit.point;
    const n = hit.normal;
    try b.line(p, .{
        p[0] + n[0] * NORMAL_VISUAL_LENGTH,
        p[1] + n[1] * NORMAL_VISUAL_LENGTH,
        p[2] + n[2] * NORMAL_VISUAL_LENGTH,
    }, .{
        .color = .yellow,
        .thickness = 0.08,
    });
}

// ==================================================================
// Main Application Lifecycle
// ==================================================================

pub fn init(ctx: jok.Context) !void {
    std.log.info("game init", .{});

    batchpool = try @TypeOf(batchpool).init(ctx);
    camera = Camera.fromPositionAndTarget(
        .{
            .perspective = .{
                .fov = CAMERA_FOV,
                .aspect_ratio = ctx.getAspectRatio(),
                .near = CAMERA_NEAR,
                .far = CAMERA_FAR,
            },
        },
        CAMERA_START_POS,
        CAMERA_START_TARGET,
    );
}

pub fn event(ctx: jok.Context, e: jok.Event) !void {
    const S = struct {
        var fullscreen = false;
        var is_viewing = false;
    };

    switch (e) {
        .key_down => |k| {
            if (k.scancode == .f1) {
                S.fullscreen = !S.fullscreen;
                try ctx.window().setFullscreen(S.fullscreen);
            }
        },
        .mouse_button_down => |me| {
            if (me.button == .right) {
                try ctx.window().setRelativeMouseMode(true);
                S.is_viewing = true;
            } else if (me.button == .left) {
                drag_ray = buildDragRay(ctx, me.pos.x, me.pos.y);

                // Raycast against all objects to find the closest hit
                var closest_dist: f32 = std.math.inf(f32);
                var clicked_target: DragTarget = .none;
                var hit_point: [3]f32 = undefined;

                // AABBs
                if (drag_ray.?.raycast(aabb0)) |hit| {
                    if (hit.distance < closest_dist) {
                        closest_dist = hit.distance;
                        clicked_target = .aabb0;
                        hit_point = hit.point;
                    }
                }
                if (drag_ray.?.raycast(aabb1)) |hit| {
                    if (hit.distance < closest_dist) {
                        closest_dist = hit.distance;
                        clicked_target = .aabb1;
                        hit_point = hit.point;
                    }
                }

                // Spheres (with dynamic pick bias for better UX at distance)
                {
                    const bias = calculatePickSphereBias(sphere0);
                    const pick_sphere = geom.Sphere.init(sphere0.center, sphere0.radius + bias);
                    if (drag_ray.?.raycast(pick_sphere)) |hit| {
                        if (hit.distance < closest_dist) {
                            closest_dist = hit.distance;
                            clicked_target = .sphere0;
                            hit_point = hit.point;
                        }
                    }
                }
                {
                    const bias = calculatePickSphereBias(sphere1);
                    const pick_sphere = geom.Sphere.init(sphere1.center, sphere1.radius + bias);
                    if (drag_ray.?.raycast(pick_sphere)) |hit| {
                        if (hit.distance < closest_dist) {
                            closest_dist = hit.distance;
                            clicked_target = .sphere1;
                            hit_point = hit.point;
                        }
                    }
                }

                // Triangles and OBBs
                if (drag_ray.?.raycast(tri0)) |hit| {
                    if (hit.distance < closest_dist) {
                        closest_dist = hit.distance;
                        clicked_target = .tri0;
                        hit_point = hit.point;
                    }
                }
                if (drag_ray.?.raycast(tri1)) |hit| {
                    if (hit.distance < closest_dist) {
                        closest_dist = hit.distance;
                        clicked_target = .tri1;
                        hit_point = hit.point;
                    }
                }
                if (drag_ray.?.raycast(obb0)) |hit| {
                    if (hit.distance < closest_dist) {
                        closest_dist = hit.distance;
                        clicked_target = .obb0;
                        hit_point = hit.point;
                    }
                }
                if (drag_ray.?.raycast(obb1)) |hit| {
                    if (hit.distance < closest_dist) {
                        closest_dist = hit.distance;
                        clicked_target = .obb1;
                        hit_point = hit.point;
                    }
                }

                if (clicked_target != .none) {
                    drag_target = clicked_target;
                    drag_plane_y = getLockedY(clicked_target);

                    const center = getObjectCenter(clicked_target);
                    drag_offset = .{
                        center[0] - hit_point[0],
                        0, // Y is locked
                        center[2] - hit_point[2],
                    };
                }
            }
        },
        .mouse_button_up => |me| {
            if (me.button == .right) {
                try ctx.window().setRelativeMouseMode(false);
                S.is_viewing = false;
            } else if (me.button == .left) {
                drag_target = .none;
            }
        },
        .mouse_motion => |me| {
            if (S.is_viewing) {
                camera.rotateBy(
                    MOUSE_ROTATE_SPEED * me.delta.y,
                    MOUSE_ROTATE_SPEED * me.delta.x,
                );
            } else if (drag_target != .none) {
                const ray = buildDragRay(ctx, me.pos.x, me.pos.y);
                drag_ray = ray;

                const drag_plane = geom.Plane.init(.{ 0, drag_plane_y, 0 }, .{ 0, 1, 0 });
                const plane_hit = ray.raycast(drag_plane) orelse return;

                const target_pos = .{
                    plane_hit.point[0] + drag_offset[0],
                    drag_plane_y,
                    plane_hit.point[2] + drag_offset[2],
                };

                switch (drag_target) {
                    .aabb0 => {
                        const half = aabb0.halfExtents();
                        aabb0.min = .{ target_pos[0] - half[0], target_pos[1] - half[1], target_pos[2] - half[2] };
                        aabb0.max = .{ target_pos[0] + half[0], target_pos[1] + half[1], target_pos[2] + half[2] };
                    },
                    .aabb1 => {
                        const half = aabb1.halfExtents();
                        aabb1.min = .{ target_pos[0] - half[0], target_pos[1] - half[1], target_pos[2] - half[2] };
                        aabb1.max = .{ target_pos[0] + half[0], target_pos[1] + half[1], target_pos[2] + half[2] };
                    },
                    .sphere0 => sphere0.center = target_pos,
                    .sphere1 => sphere1.center = target_pos,
                    .tri0, .tri1 => |t| {
                        const tri = if (t == .tri0) &tri0 else &tri1;
                        const old_center = .{
                            (tri.v0[0] + tri.v1[0] + tri.v2[0]) / 3.0,
                            (tri.v0[1] + tri.v1[1] + tri.v2[1]) / 3.0,
                            (tri.v0[2] + tri.v1[2] + tri.v2[2]) / 3.0,
                        };
                        const delta = .{
                            target_pos[0] - old_center[0],
                            0,
                            target_pos[2] - old_center[2],
                        };
                        tri.v0 = .{ tri.v0[0] + delta[0], tri.v0[1] + delta[1], tri.v0[2] + delta[2] };
                        tri.v1 = .{ tri.v1[0] + delta[0], tri.v1[1] + delta[1], tri.v1[2] + delta[2] };
                        tri.v2 = .{ tri.v2[0] + delta[0], tri.v2[1] + delta[1], tri.v2[2] + delta[2] };
                    },
                    .obb0 => obb0.center = target_pos,
                    .obb1 => obb1.center = target_pos,
                    .none => {},
                }
            }
        },
        .window_resized => {
            camera.frustum = j3d.Camera.ViewFrustum{
                .perspective = .{
                    .fov = CAMERA_FOV,
                    .aspect_ratio = ctx.getAspectRatio(),
                    .near = CAMERA_NEAR,
                    .far = CAMERA_FAR,
                },
            };
        },
        else => {},
    }
}

pub fn update(ctx: jok.Context) !void {
    const distance = ctx.deltaSeconds() * MOVE_SPEED;
    const kbd = jok.io.getKeyboardState();

    if (kbd.isPressed(.w)) camera.moveBy(.forward, distance);
    if (kbd.isPressed(.s)) camera.moveBy(.backward, distance);
    if (kbd.isPressed(.a)) camera.moveBy(.left, distance);
    if (kbd.isPressed(.d)) camera.moveBy(.right, distance);

    // Rotate OBB1 for visual interest
    const rot = ctx.seconds() * OBB_ROTATION_SPEED;
    obb1.axes[0] = .{ @cos(rot), 0, @sin(rot) };
    obb1.axes[2] = .{ -@sin(rot), 0, @cos(rot) };

    // Update rays every frame
    const mouse = jok.io.getMouseState(ctx);
    raycast_ray = buildRaycastRay(ctx, mouse.pos.x, mouse.pos.y);
    drag_ray = buildDragRay(ctx, mouse.pos.x, mouse.pos.y);
}

pub fn draw(ctx: jok.Context) !void {
    try ctx.renderer().clear(.rgb(40, 40, 50));

    const hits = updateIntersectionFlags();

    var b = try batchpool.new(.{ .camera = camera });
    defer b.submit();

    // Draw AABBs
    try drawAABB(b, aabb0, if (hits.aabb0) .red else .white);
    try drawAABB(b, aabb1, if (hits.aabb1) .red else .white);

    // Draw Spheres
    {
        b.translate(sphere0.center);
        b.scale(.{ sphere0.radius, sphere0.radius, sphere0.radius });
        const sphere_shape = jok.vendor.zmesh.Shape.initParametricSphere(12, 12);
        defer sphere_shape.deinit();
        try b.shape(sphere_shape, null, .{
            .color = if (hits.sphere0) .red else .white,
            .cull_faces = false,
        });
    }

    {
        b.setIdentity();
        b.translate(sphere1.center);
        b.scale(.{ sphere1.radius, sphere1.radius, sphere1.radius });
        const sphere_shape = jok.vendor.zmesh.Shape.initParametricSphere(12, 12);
        defer sphere_shape.deinit();
        try b.shape(sphere_shape, null, .{
            .color = if (hits.sphere1) .red else .white,
            .cull_faces = false,
        });
    }

    // Draw Plane
    b.setIdentity();
    try b.line(.{ -PLANE_SIZE, plane.point[1], -PLANE_SIZE }, .{ PLANE_SIZE, plane.point[1], -PLANE_SIZE }, .{ .color = .cyan, .thickness = PLANE_LINE_THICKNESS });
    try b.line(.{ PLANE_SIZE, plane.point[1], -PLANE_SIZE }, .{ PLANE_SIZE, plane.point[1], PLANE_SIZE }, .{ .color = .cyan, .thickness = PLANE_LINE_THICKNESS });
    try b.line(.{ PLANE_SIZE, plane.point[1], PLANE_SIZE }, .{ -PLANE_SIZE, plane.point[1], PLANE_SIZE }, .{ .color = .cyan, .thickness = PLANE_LINE_THICKNESS });
    try b.line(.{ -PLANE_SIZE, plane.point[1], PLANE_SIZE }, .{ -PLANE_SIZE, plane.point[1], -PLANE_SIZE }, .{ .color = .cyan, .thickness = PLANE_LINE_THICKNESS });

    // Draw Triangles and OBBs
    try drawTriangle(b, tri0, if (hits.tri0) .red else .white);
    try drawTriangle(b, tri1, if (hits.tri1) .red else .white);
    try drawOBB(b, obb0, if (hits.obb0) .red else .white);
    try drawOBB(b, obb1, if (hits.obb1) .red else .white);

    // Draw raycast ray and hit normals
    if (raycast_ray) |ray| {
        const ray_end = .{
            ray.origin[0] + ray.direction[0] * RAY_LENGTH,
            ray.origin[1] + ray.direction[1] * RAY_LENGTH,
            ray.origin[2] + ray.direction[2] * RAY_LENGTH,
        };
        try b.line(ray.origin, ray_end, .{ .color = .yellow, .thickness = RAY_THICKNESS });

        if (ray.raycast(aabb0)) |hit| try drawRayHit(b, hit);
        if (ray.raycast(aabb1)) |hit| try drawRayHit(b, hit);
        if (ray.raycast(sphere0)) |hit| try drawRayHit(b, hit);
        if (ray.raycast(sphere1)) |hit| try drawRayHit(b, hit);
        if (ray.raycast(plane)) |hit| try drawRayHit(b, hit);
        if (ray.raycast(tri0)) |hit| try drawRayHit(b, hit);
        if (ray.raycast(tri1)) |hit| try drawRayHit(b, hit);
        if (ray.raycast(obb0)) |hit| try drawRayHit(b, hit);
        if (ray.raycast(obb1)) |hit| try drawRayHit(b, hit);
    }

    // UI Help Text
    ctx.debugPrint("Press WSAD to move, drag mouse with right-button to rotate view", .{ .pos = .{ .x = 20, .y = 10 } });
    ctx.debugPrint("Left-click and drag to move objects around", .{ .pos = .{ .x = 20, .y = 28 } });
    ctx.debugPrint("Geometries turn RED when intersecting with each other", .{ .pos = .{ .x = 20, .y = 46 } });
}

pub fn quit(ctx: jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});
    batchpool.deinit();
}
