const std = @import("std");
const jok = @import("jok");
const j3d = jok.j3d;
const geom = j3d.geom;
const Camera = j3d.Camera;
const zmath = jok.vendor.zmath;

pub const jok_window_resizable = true;

var batchpool: j3d.BatchPool(64, false) = undefined;
var camera: Camera = undefined;

// Geometry primitives
var aabb0 = geom.AABB.init(.{ -3, -1, -1 }, .{ -1, 1, 1 });
var aabb1 = geom.AABB.init(.{ -2, -1, 0 }, .{ 0, 1, 2 });

var sphere0 = geom.Sphere.init(.{ 3, 0, 0 }, 1.0);
var sphere1 = geom.Sphere.init(.{ 4.5, 0, 0 }, 1.0);

var plane = geom.Plane.init(.{ 0, -2, 0 }, .{ 0, 1, 0 });

const raycast_plane_y: f32 = 0.0;
var drag_plane_y: f32 = 0.0;

const aabb0_center_y: f32 = 0.0;
const aabb1_center_y: f32 = 0.0;
const sphere0_center_y: f32 = 0.0;
const sphere1_center_y: f32 = 0.0;
const obb0_center_y: f32 = 0.0;
const obb1_center_y: f32 = 0.0;
const tri0_center_y: f32 = 0.0;
const tri1_center_y: f32 = 0.25;

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

// Mouse rays (separate for showcase vs dragging)
var raycast_ray: ?geom.Ray = null;
var drag_ray: ?geom.Ray = null;

// Dragging state
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

var drag_target: DragTarget = .none;
var drag_start_pos: [3]f32 = .{ 0, 0, 0 };
var drag_offset: [3]f32 = .{ 0, 0, 0 };

const pick_sphere_bias_base: f32 = 0.2;
const pick_sphere_bias_scale: f32 = 0.02;

fn buildRaycastRay(ctx: jok.Context, x: f32, y: f32) geom.Ray {
    const camera_ray = buildDragRay(ctx, x, y);
    const plane_xz = geom.Plane.init(.{ 0, raycast_plane_y, 0 }, .{ 0, 1, 0 });
    if (camera_ray.raycast(plane_xz)) |hit| {
        const origin = zmath.f32x4(0, raycast_plane_y, 0, 0);
        const target_xz = zmath.f32x4(hit.point[0], raycast_plane_y, hit.point[2], 0);
        const dir_raw = target_xz - origin;
        const dir = if (zmath.length3(dir_raw)[0] > 0) zmath.normalize3(dir_raw) else zmath.f32x4(0, 0, 1, 0);
        return geom.Ray.init(
            .{ 0, raycast_plane_y, 0 },
            .{ dir[0], 0, dir[2] },
        );
    }
    return geom.Ray.init(.{ 0, raycast_plane_y, 0 }, .{ 0, 0, 1 });
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

pub fn init(ctx: jok.Context) !void {
    std.log.info("game init", .{});

    batchpool = try @TypeOf(batchpool).init(ctx);
    camera = Camera.fromPositionAndTarget(
        .{
            .perspective = .{
                .fov = std.math.degreesToRadians(70),
                .aspect_ratio = ctx.getAspectRatio(),
                .near = 0.1,
                .far = 1000,
            },
        },
        [_]f32{ 0, 5, 15 },
        [_]f32{ 0, 0, 0 },
    );
}

pub fn event(ctx: jok.Context, e: jok.Event) !void {
    const S = struct {
        var fullscreen = false;
        var is_viewing: bool = false;
        const mouse_speed: f32 = 0.0025;
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
                const ray = buildDragRay(ctx, me.pos.x, me.pos.y);
                drag_ray = ray;

                // Check which object was clicked
                var closest_dist: f32 = std.math.inf(f32);
                var clicked_target: DragTarget = .none;
                var hit_point: [3]f32 = undefined;

                if (ray.raycast(aabb0)) |hit| {
                    if (hit.distance < closest_dist) {
                        closest_dist = hit.distance;
                        clicked_target = .aabb0;
                        hit_point = hit.point;
                    }
                }
                if (ray.raycast(aabb1)) |hit| {
                    if (hit.distance < closest_dist) {
                        closest_dist = hit.distance;
                        clicked_target = .aabb1;
                        hit_point = hit.point;
                    }
                }
                const sphere0_dist = zmath.length3(zmath.f32x4(
                    camera.position[0] - sphere0.center[0],
                    camera.position[1] - sphere0.center[1],
                    camera.position[2] - sphere0.center[2],
                    0,
                ))[0];
                const sphere0_bias = @max(pick_sphere_bias_base, sphere0_dist * pick_sphere_bias_scale);
                const sphere0_pick = geom.Sphere.init(sphere0.center, sphere0.radius + sphere0_bias);
                if (ray.raycast(sphere0_pick)) |hit| {
                    if (hit.distance < closest_dist) {
                        closest_dist = hit.distance;
                        clicked_target = .sphere0;
                        hit_point = hit.point;
                    }
                }
                const sphere1_dist = zmath.length3(zmath.f32x4(
                    camera.position[0] - sphere1.center[0],
                    camera.position[1] - sphere1.center[1],
                    camera.position[2] - sphere1.center[2],
                    0,
                ))[0];
                const sphere1_bias = @max(pick_sphere_bias_base, sphere1_dist * pick_sphere_bias_scale);
                const sphere1_pick = geom.Sphere.init(sphere1.center, sphere1.radius + sphere1_bias);
                if (ray.raycast(sphere1_pick)) |hit| {
                    if (hit.distance < closest_dist) {
                        closest_dist = hit.distance;
                        clicked_target = .sphere1;
                        hit_point = hit.point;
                    }
                }
                if (ray.raycast(tri0)) |hit| {
                    if (hit.distance < closest_dist) {
                        closest_dist = hit.distance;
                        clicked_target = .tri0;
                        hit_point = hit.point;
                    }
                }
                if (ray.raycast(tri1)) |hit| {
                    if (hit.distance < closest_dist) {
                        closest_dist = hit.distance;
                        clicked_target = .tri1;
                        hit_point = hit.point;
                    }
                }
                if (ray.raycast(obb0)) |hit| {
                    if (hit.distance < closest_dist) {
                        closest_dist = hit.distance;
                        clicked_target = .obb0;
                        hit_point = hit.point;
                    }
                }
                if (ray.raycast(obb1)) |hit| {
                    if (hit.distance < closest_dist) {
                        closest_dist = hit.distance;
                        clicked_target = .obb1;
                        hit_point = hit.point;
                    }
                }

                if (clicked_target != .none) {
                    drag_target = clicked_target;
                    drag_start_pos = hit_point;

                    // Calculate offset from object center to hit point
                    switch (drag_target) {
                        .aabb0 => drag_offset = .{
                            aabb0.center()[0] - hit_point[0],
                            aabb0.center()[1] - hit_point[1],
                            aabb0.center()[2] - hit_point[2],
                        },
                        .aabb1 => drag_offset = .{
                            aabb1.center()[0] - hit_point[0],
                            aabb1.center()[1] - hit_point[1],
                            aabb1.center()[2] - hit_point[2],
                        },
                        .sphere0 => drag_offset = .{
                            sphere0.center[0] - hit_point[0],
                            sphere0.center[1] - hit_point[1],
                            sphere0.center[2] - hit_point[2],
                        },
                        .sphere1 => drag_offset = .{
                            sphere1.center[0] - hit_point[0],
                            sphere1.center[1] - hit_point[1],
                            sphere1.center[2] - hit_point[2],
                        },
                        .tri0 => {
                            const center = .{
                                (tri0.v0[0] + tri0.v1[0] + tri0.v2[0]) / 3.0,
                                (tri0.v0[1] + tri0.v1[1] + tri0.v2[1]) / 3.0,
                                (tri0.v0[2] + tri0.v1[2] + tri0.v2[2]) / 3.0,
                            };
                            drag_offset = .{
                                center[0] - hit_point[0],
                                center[1] - hit_point[1],
                                center[2] - hit_point[2],
                            };
                        },
                        .tri1 => {
                            const center = .{
                                (tri1.v0[0] + tri1.v1[0] + tri1.v2[0]) / 3.0,
                                (tri1.v0[1] + tri1.v1[1] + tri1.v2[1]) / 3.0,
                                (tri1.v0[2] + tri1.v1[2] + tri1.v2[2]) / 3.0,
                            };
                            drag_offset = .{
                                center[0] - hit_point[0],
                                center[1] - hit_point[1],
                                center[2] - hit_point[2],
                            };
                        },
                        .obb0 => drag_offset = .{
                            obb0.center[0] - hit_point[0],
                            obb0.center[1] - hit_point[1],
                            obb0.center[2] - hit_point[2],
                        },
                        .obb1 => drag_offset = .{
                            obb1.center[0] - hit_point[0],
                            obb1.center[1] - hit_point[1],
                            obb1.center[2] - hit_point[2],
                        },
                        .none => {},
                    }

                    // Lock dragging to the object's current Y.
                    drag_plane_y = switch (drag_target) {
                        .aabb0 => aabb0_center_y,
                        .aabb1 => aabb1_center_y,
                        .sphere0 => sphere0_center_y,
                        .sphere1 => sphere1_center_y,
                        .tri0 => tri0_center_y,
                        .tri1 => tri1_center_y,
                        .obb0 => obb0_center_y,
                        .obb1 => obb1_center_y,
                        .none => drag_plane_y,
                    };
                    drag_offset[1] = 0;
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
                    S.mouse_speed * me.delta.y,
                    S.mouse_speed * me.delta.x,
                );
            } else {
                const ray = buildDragRay(ctx, me.pos.x, me.pos.y);
                drag_ray = ray;

                // Update dragged object position
                if (drag_target != .none and drag_ray != null) {
                    // Constrain dragging to the object's locked Y plane.
                    const drag_plane = geom.Plane.init(.{ 0, drag_plane_y, 0 }, .{ 0, 1, 0 });
                    const plane_hit = ray.raycast(drag_plane) orelse return;
                    const target_pos = .{
                        plane_hit.point[0] + drag_offset[0],
                        drag_plane_y,
                        plane_hit.point[2] + drag_offset[2],
                    };

                    switch (drag_target) {
                        .aabb0 => {
                            const half_ext = aabb0.halfExtents();
                            aabb0.min = .{
                                target_pos[0] - half_ext[0],
                                target_pos[1] - half_ext[1],
                                target_pos[2] - half_ext[2],
                            };
                            aabb0.max = .{
                                target_pos[0] + half_ext[0],
                                target_pos[1] + half_ext[1],
                                target_pos[2] + half_ext[2],
                            };
                        },
                        .aabb1 => {
                            const half_ext = aabb1.halfExtents();
                            aabb1.min = .{
                                target_pos[0] - half_ext[0],
                                target_pos[1] - half_ext[1],
                                target_pos[2] - half_ext[2],
                            };
                            aabb1.max = .{
                                target_pos[0] + half_ext[0],
                                target_pos[1] + half_ext[1],
                                target_pos[2] + half_ext[2],
                            };
                        },
                        .sphere0 => sphere0.center = target_pos,
                        .sphere1 => sphere1.center = target_pos,
                        .tri0 => {
                            const old_center = .{
                                (tri0.v0[0] + tri0.v1[0] + tri0.v2[0]) / 3.0,
                                (tri0.v0[1] + tri0.v1[1] + tri0.v2[1]) / 3.0,
                                (tri0.v0[2] + tri0.v1[2] + tri0.v2[2]) / 3.0,
                            };
                            const delta = .{
                                target_pos[0] - old_center[0],
                                0,
                                target_pos[2] - old_center[2],
                            };
                            tri0.v0 = .{ tri0.v0[0] + delta[0], tri0.v0[1] + delta[1], tri0.v0[2] + delta[2] };
                            tri0.v1 = .{ tri0.v1[0] + delta[0], tri0.v1[1] + delta[1], tri0.v1[2] + delta[2] };
                            tri0.v2 = .{ tri0.v2[0] + delta[0], tri0.v2[1] + delta[1], tri0.v2[2] + delta[2] };
                        },
                        .tri1 => {
                            const old_center = .{
                                (tri1.v0[0] + tri1.v1[0] + tri1.v2[0]) / 3.0,
                                (tri1.v0[1] + tri1.v1[1] + tri1.v2[1]) / 3.0,
                                (tri1.v0[2] + tri1.v1[2] + tri1.v2[2]) / 3.0,
                            };
                            const delta = .{
                                target_pos[0] - old_center[0],
                                0,
                                target_pos[2] - old_center[2],
                            };
                            tri1.v0 = .{ tri1.v0[0] + delta[0], tri1.v0[1] + delta[1], tri1.v0[2] + delta[2] };
                            tri1.v1 = .{ tri1.v1[0] + delta[0], tri1.v1[1] + delta[1], tri1.v1[2] + delta[2] };
                            tri1.v2 = .{ tri1.v2[0] + delta[0], tri1.v2[1] + delta[1], tri1.v2[2] + delta[2] };
                        },
                        .obb0 => obb0.center = target_pos,
                        .obb1 => obb1.center = target_pos,
                        .none => {},
                    }
                }
            }
        },
        .window_resized => {
            camera.frustum = j3d.Camera.ViewFrustum{
                .perspective = .{
                    .fov = std.math.degreesToRadians(70),
                    .aspect_ratio = ctx.getAspectRatio(),
                    .near = 0.1,
                    .far = 1000,
                },
            };
        },
        else => {},
    }
}

pub fn update(ctx: jok.Context) !void {
    const distance = ctx.deltaSeconds() * 5;
    const kbd = jok.io.getKeyboardState();
    if (kbd.isPressed(.w)) {
        camera.moveBy(.forward, distance);
    }
    if (kbd.isPressed(.s)) {
        camera.moveBy(.backward, distance);
    }
    if (kbd.isPressed(.a)) {
        camera.moveBy(.left, distance);
    }
    if (kbd.isPressed(.d)) {
        camera.moveBy(.right, distance);
    }

    const rot_speed = ctx.deltaSeconds() * 0.5;
    obb1.axes[0] = .{
        @cos(ctx.seconds() * rot_speed),
        0,
        @sin(ctx.seconds() * rot_speed),
    };
    obb1.axes[2] = .{
        -@sin(ctx.seconds() * rot_speed),
        0,
        @cos(ctx.seconds() * rot_speed),
    };

    const mouse = jok.io.getMouseState(ctx);
    raycast_ray = buildRaycastRay(ctx, mouse.pos.x, mouse.pos.y);
    drag_ray = buildDragRay(ctx, mouse.pos.x, mouse.pos.y);
}

fn drawAABB(b: *j3d.Batch, aabb: geom.AABB, color: jok.Color) !void {
    const min = aabb.min;
    const max = aabb.max;
    const corners = [8][3]f32{
        .{ min[0], min[1], min[2] },
        .{ max[0], min[1], min[2] },
        .{ max[0], max[1], min[2] },
        .{ min[0], max[1], min[2] },
        .{ min[0], min[1], max[2] },
        .{ max[0], min[1], max[2] },
        .{ max[0], max[1], max[2] },
        .{ min[0], max[1], max[2] },
    };
    const edges = [12][2]u8{
        .{ 0, 1 }, .{ 1, 2 }, .{ 2, 3 }, .{ 3, 0 },
        .{ 4, 5 }, .{ 5, 6 }, .{ 6, 7 }, .{ 7, 4 },
        .{ 0, 4 }, .{ 1, 5 }, .{ 2, 6 }, .{ 3, 7 },
    };
    for (edges) |edge| {
        try b.line(corners[edge[0]], corners[edge[1]], .{
            .color = color.toColorF(),
            .thickness = 0.05,
        });
    }
}

fn drawOBB(b: *j3d.Batch, obb: geom.OBB, color: jok.Color) !void {
    const c = obb.center;
    const e = obb.half_extents;
    const ax = obb.axes;

    const corners = [8][3]f32{
        .{
            c[0] - ax[0][0] * e[0] - ax[1][0] * e[1] - ax[2][0] * e[2],
            c[1] - ax[0][1] * e[0] - ax[1][1] * e[1] - ax[2][1] * e[2],
            c[2] - ax[0][2] * e[0] - ax[1][2] * e[1] - ax[2][2] * e[2],
        },
        .{
            c[0] + ax[0][0] * e[0] - ax[1][0] * e[1] - ax[2][0] * e[2],
            c[1] + ax[0][1] * e[0] - ax[1][1] * e[1] - ax[2][1] * e[2],
            c[2] + ax[0][2] * e[0] - ax[1][2] * e[1] - ax[2][2] * e[2],
        },
        .{
            c[0] + ax[0][0] * e[0] + ax[1][0] * e[1] - ax[2][0] * e[2],
            c[1] + ax[0][1] * e[0] + ax[1][1] * e[1] - ax[2][1] * e[2],
            c[2] + ax[0][2] * e[0] + ax[1][2] * e[1] - ax[2][2] * e[2],
        },
        .{
            c[0] - ax[0][0] * e[0] + ax[1][0] * e[1] - ax[2][0] * e[2],
            c[1] - ax[0][1] * e[0] + ax[1][1] * e[1] - ax[2][1] * e[2],
            c[2] - ax[0][2] * e[0] + ax[1][2] * e[1] - ax[2][2] * e[2],
        },
        .{
            c[0] - ax[0][0] * e[0] - ax[1][0] * e[1] + ax[2][0] * e[2],
            c[1] - ax[0][1] * e[0] - ax[1][1] * e[1] + ax[2][1] * e[2],
            c[2] - ax[0][2] * e[0] - ax[1][2] * e[1] + ax[2][2] * e[2],
        },
        .{
            c[0] + ax[0][0] * e[0] - ax[1][0] * e[1] + ax[2][0] * e[2],
            c[1] + ax[0][1] * e[0] - ax[1][1] * e[1] + ax[2][1] * e[2],
            c[2] + ax[0][2] * e[0] - ax[1][2] * e[1] + ax[2][2] * e[2],
        },
        .{
            c[0] + ax[0][0] * e[0] + ax[1][0] * e[1] + ax[2][0] * e[2],
            c[1] + ax[0][1] * e[0] + ax[1][1] * e[1] + ax[2][1] * e[2],
            c[2] + ax[0][2] * e[0] + ax[1][2] * e[1] + ax[2][2] * e[2],
        },
        .{
            c[0] - ax[0][0] * e[0] + ax[1][0] * e[1] + ax[2][0] * e[2],
            c[1] - ax[0][1] * e[0] + ax[1][1] * e[1] + ax[2][1] * e[2],
            c[2] - ax[0][2] * e[0] + ax[1][2] * e[1] + ax[2][2] * e[2],
        },
    };
    const edges = [12][2]u8{
        .{ 0, 1 }, .{ 1, 2 }, .{ 2, 3 }, .{ 3, 0 },
        .{ 4, 5 }, .{ 5, 6 }, .{ 6, 7 }, .{ 7, 4 },
        .{ 0, 4 }, .{ 1, 5 }, .{ 2, 6 }, .{ 3, 7 },
    };
    for (edges) |edge| {
        try b.line(corners[edge[0]], corners[edge[1]], .{
            .color = color.toColorF(),
            .thickness = 0.05,
        });
    }
}

fn drawTriangle(b: *j3d.Batch, tri: geom.Triangle, color: jok.Color) !void {
    try b.line(tri.v0, tri.v1, .{ .color = color.toColorF(), .thickness = 0.05 });
    try b.line(tri.v1, tri.v2, .{ .color = color.toColorF(), .thickness = 0.05 });
    try b.line(tri.v2, tri.v0, .{ .color = color.toColorF(), .thickness = 0.05 });
}

fn drawRayHit(b: *j3d.Batch, hit: geom.Ray.Hit) !void {
    const normal_len: f32 = 0.5;
    const p = hit.point;
    const n = hit.normal;
    try b.line(p, .{ p[0] + n[0] * normal_len, p[1] + n[1] * normal_len, p[2] + n[2] * normal_len }, .{
        .color = .yellow,
        .thickness = 0.08,
    });
}

pub fn draw(ctx: jok.Context) !void {
    try ctx.renderer().clear(.rgb(40, 40, 50));

    const aabb0_hit = aabb0.intersect(aabb1) or aabb0.intersect(sphere0) or aabb0.intersect(sphere1) or aabb0.intersect(plane) or aabb0.intersect(tri0) or aabb0.intersect(tri1) or aabb0.intersect(obb0) or aabb0.intersect(obb1);
    const aabb1_hit = aabb1.intersect(aabb0) or aabb1.intersect(sphere0) or aabb1.intersect(sphere1) or aabb1.intersect(plane) or aabb1.intersect(tri0) or aabb1.intersect(tri1) or aabb1.intersect(obb0) or aabb1.intersect(obb1);

    const sphere0_hit = sphere0.intersect(aabb0) or sphere0.intersect(aabb1) or sphere0.intersect(sphere1) or sphere0.intersect(plane) or sphere0.intersect(tri0) or sphere0.intersect(tri1) or sphere0.intersect(obb0) or sphere0.intersect(obb1);
    const sphere1_hit = sphere1.intersect(aabb0) or sphere1.intersect(aabb1) or sphere1.intersect(sphere0) or sphere1.intersect(plane) or sphere1.intersect(tri0) or sphere1.intersect(tri1) or sphere1.intersect(obb0) or sphere1.intersect(obb1);

    const tri0_hit = tri0.intersect(aabb0) or tri0.intersect(aabb1) or tri0.intersect(sphere0) or tri0.intersect(sphere1) or tri0.intersect(plane) or tri0.intersect(tri1) or tri0.intersect(obb0) or tri0.intersect(obb1);
    const tri1_hit = tri1.intersect(aabb0) or tri1.intersect(aabb1) or tri1.intersect(sphere0) or tri1.intersect(sphere1) or tri1.intersect(plane) or tri1.intersect(tri0) or tri1.intersect(obb0) or tri1.intersect(obb1);

    const obb0_hit = obb0.intersect(aabb0) or obb0.intersect(aabb1) or obb0.intersect(sphere0) or obb0.intersect(sphere1) or obb0.intersect(plane) or obb0.intersect(obb1) or obb0.intersect(tri0) or obb0.intersect(tri1);
    const obb1_hit = obb1.intersect(aabb0) or obb1.intersect(aabb1) or obb1.intersect(sphere0) or obb1.intersect(sphere1) or obb1.intersect(plane) or obb1.intersect(obb0) or obb1.intersect(tri0) or obb1.intersect(tri1);

    var b = try batchpool.new(.{ .camera = camera });
    defer b.submit();

    try drawAABB(b, aabb0, if (aabb0_hit) .red else .white);
    try drawAABB(b, aabb1, if (aabb1_hit) .red else .white);

    b.translate(sphere0.center);
    b.scale(.{ sphere0.radius, sphere0.radius, sphere0.radius });
    const sphere_shape = jok.vendor.zmesh.Shape.initParametricSphere(12, 12);
    defer sphere_shape.deinit();
    try b.shape(sphere_shape, null, .{
        .color = if (sphere0_hit) .red else .white,
        .cull_faces = false,
    });

    b.setIdentity();
    b.translate(sphere1.center);
    b.scale(.{ sphere1.radius, sphere1.radius, sphere1.radius });
    try b.shape(sphere_shape, null, .{
        .color = if (sphere1_hit) .red else .white,
        .cull_faces = false,
    });

    b.setIdentity();
    const plane_size: f32 = 20;
    try b.line(.{ -plane_size, plane.point[1], -plane_size }, .{ plane_size, plane.point[1], -plane_size }, .{ .color = .cyan, .thickness = 0.03 });
    try b.line(.{ plane_size, plane.point[1], -plane_size }, .{ plane_size, plane.point[1], plane_size }, .{ .color = .cyan, .thickness = 0.03 });
    try b.line(.{ plane_size, plane.point[1], plane_size }, .{ -plane_size, plane.point[1], plane_size }, .{ .color = .cyan, .thickness = 0.03 });
    try b.line(.{ -plane_size, plane.point[1], plane_size }, .{ -plane_size, plane.point[1], -plane_size }, .{ .color = .cyan, .thickness = 0.03 });

    try drawTriangle(b, tri0, if (tri0_hit) .red else .white);
    try drawTriangle(b, tri1, if (tri1_hit) .red else .white);

    try drawOBB(b, obb0, if (obb0_hit) .red else .white);
    try drawOBB(b, obb1, if (obb1_hit) .red else .white);

    if (raycast_ray) |ray| {
        const ray_len: f32 = 50;
        const ray_end: [3]f32 = .{
            ray.origin[0] + ray.direction[0] * ray_len,
            ray.origin[1] + ray.direction[1] * ray_len,
            ray.origin[2] + ray.direction[2] * ray_len,
        };
        try b.line(ray.origin, ray_end, .{ .color = .yellow, .thickness = 0.03 });

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

    ctx.debugPrint("Press WSAD to move, drag mouse with right-button to rotate view", .{ .pos = .{ .x = 20, .y = 10 } });
    ctx.debugPrint("Left-click and drag to move objects around", .{ .pos = .{ .x = 20, .y = 28 } });
    ctx.debugPrint("Geometries turn RED when intersecting with each other", .{ .pos = .{ .x = 20, .y = 46 } });
}

pub fn quit(ctx: jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});
    batchpool.deinit();
}
