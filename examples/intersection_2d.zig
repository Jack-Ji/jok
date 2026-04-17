const std = @import("std");
const jok = @import("jok");
const j2d = jok.j2d;
const geom = j2d.geom;

/// A simple 2D geometry intersection and raycasting demo
/// Drag shapes with left mouse button. Yellow ray from screen center shows raycasting with hit normals.
var batchpool: j2d.BatchPool(8, false) = undefined;

// ==================== Shape Definitions ====================

const Shape = union(enum) {
    rect: geom.Rectangle,
    circle: geom.Circle,
    ellipse: geom.Ellipse,
    triangle: geom.Triangle,
    line: geom.Line,
    point: geom.Point,
};

/// All interactive shapes in the scene
var shapes = [_]Shape{
    .{ .rect = geom.Rectangle{ .x = 60, .y = 60, .width = 140, .height = 90 } },
    .{ .rect = geom.Rectangle{ .x = 150, .y = 120, .width = 140, .height = 90 } },

    .{ .circle = geom.Circle{ .center = .{ .x = 380, .y = 90 }, .radius = 50 } },
    .{ .circle = geom.Circle{ .center = .{ .x = 450, .y = 130 }, .radius = 40 } },

    .{ .ellipse = geom.Ellipse{ .center = .{ .x = 650, .y = 90 }, .radius = .{ .x = 70, .y = 40 } } },
    .{ .ellipse = geom.Ellipse{ .center = .{ .x = 720, .y = 130 }, .radius = .{ .x = 50, .y = 30 } } },

    .{ .triangle = geom.Triangle{
        .p0 = .{ .x = 80, .y = 260 },
        .p1 = .{ .x = 180, .y = 220 },
        .p2 = .{ .x = 120, .y = 320 },
    } },
    .{ .triangle = geom.Triangle{
        .p0 = .{ .x = 220, .y = 240 },
        .p1 = .{ .x = 320, .y = 260 },
        .p2 = .{ .x = 260, .y = 340 },
    } },

    .{ .line = geom.Line{ .p0 = .{ .x = 380, .y = 250 }, .p1 = .{ .x = 520, .y = 310 } } },
    .{ .line = geom.Line{ .p0 = .{ .x = 400, .y = 330 }, .p1 = .{ .x = 560, .y = 260 } } },

    .{ .point = geom.Point{ .x = 680, .y = 280 } },
    .{ .point = geom.Point{ .x = 740, .y = 310 } },
};

// ==================== Drag System ====================

const DragTarget = enum {
    none,
    index0,
    index1,
    index2,
    index3,
    index4,
    index5,
    index6,
    index7,
    index8,
    index9,
    index10,
    index11,
};

var drag_target: DragTarget = .none;
var mouse_pos: geom.Point = .origin;

const HANDLE_RADIUS: f32 = 8.0;
const LINE_PICK_THRESHOLD: f32 = 8.0;

/// Returns which shape (if any) should be dragged based on mouse position
fn pickTarget(pos: geom.Point) DragTarget {
    const handle_radius2 = HANDLE_RADIUS * HANDLE_RADIUS;
    const line_threshold2 = LINE_PICK_THRESHOLD * LINE_PICK_THRESHOLD;

    for (&shapes, 0..) |*shape, i| {
        const target: DragTarget = @enumFromInt(i);

        switch (shape.*) {
            .rect => |r| if (r.containsPoint(pos)) return target,
            .circle => |c| if (c.containsPoint(pos)) return target,
            .ellipse => |e| if (e.containsPoint(pos)) return target,
            .triangle => |t| if (t.containsPoint(pos)) return target,
            .line => |l| {
                const closest = l.closestPoint(pos);
                if (closest.point.distance2(pos) <= line_threshold2) return target;
            },
            .point => |p| {
                if (p.distance2(pos) <= handle_radius2) return target;
            },
        }
    }

    return .none;
}

/// Apply drag delta to the selected shape
fn applyDrag(target: DragTarget, delta: geom.Point) void {
    if (target == .none) return;

    switch (shapes[@intFromEnum(target)]) {
        .rect => |*r| r.* = r.translate(delta),
        .circle => |*c| c.* = c.translate(delta),
        .ellipse => |*e| e.* = e.translate(delta),
        .triangle => |*t| t.* = t.translate(delta),
        .line => |*l| l.* = l.translate(delta),
        .point => |*p| p.* = p.add(delta),
    }
}

// ==================== Hit Testing ====================

/// Returns whether a shape intersects with any other shape
fn isShapeHit(idx: usize) bool {
    const self = shapes[idx];

    for (shapes, 0..) |other, j| {
        if (idx == j) continue;

        switch (self) {
            .rect => |r| switch (other) {
                inline else => |o| if (r.intersect(o)) return true,
            },
            .circle => |c| switch (other) {
                inline else => |o| if (c.intersect(o)) return true,
            },
            .ellipse => |e| switch (other) {
                inline else => |o| if (e.intersect(o)) return true,
            },
            .triangle => |t| switch (other) {
                inline else => |o| if (t.intersect(o)) return true,
            },
            .line => |l| switch (other) {
                .point => |o| {
                    const closest = l.closestPoint(o);
                    if (closest.point.distance(o) < 2.0) return true;
                },
                inline else => |o| if (o.intersect(l)) return true,
            },
            .point => |p| switch (other) {
                .line => |o| {
                    const closest = o.closestPoint(p);
                    if (closest.point.distance(p) < 2.0) return true;
                },
                .point => |o| if (p.distance(o) < 2.0) return true,
                inline else => |o| if (o.containsPoint(p)) return true,
            },
        }
    }
    return false;
}

// ==================== Rendering Helpers ====================

fn drawHit(b: *j2d.Batch, hit: geom.Ray.Hit) !void {
    const normal_len: f32 = 18.0;

    try b.circleFilled(.{ .center = hit.point, .radius = 3 }, .yellow, .{});
    try b.line(
        .{ .p0 = hit.point, .p1 = hit.point.add(hit.normal.scale(normal_len)) },
        .yellow,
        .{ .thickness = 2 },
    );
}

fn getShapeColor(idx: usize, is_dragging: bool) jok.Color {
    return if (isShapeHit(idx))
        .red
    else if (is_dragging)
        .white // could use a highlight color if desired
    else
        .white;
}

// ==================== Main Callbacks ====================

pub fn init(ctx: jok.Context) !void {
    std.log.info("game init", .{});
    batchpool = try @TypeOf(batchpool).init(ctx);
}

pub fn event(ctx: jok.Context, e: jok.Event) !void {
    _ = ctx;

    switch (e) {
        .mouse_motion => |me| {
            mouse_pos = me.pos;
            if (drag_target != .none and me.button_state.isPressed(.left)) {
                applyDrag(drag_target, me.delta);
            }
        },
        .mouse_button_down => |me| {
            mouse_pos = me.pos;
            if (me.button == .left) {
                drag_target = pickTarget(me.pos);
            }
        },
        .mouse_button_up => |me| {
            mouse_pos = me.pos;
            if (me.button == .left) {
                drag_target = .none;
            }
        },
        else => {},
    }
}

pub fn update(ctx: jok.Context) !void {
    _ = ctx;
}

pub fn draw(ctx: jok.Context) !void {
    try ctx.renderer().clear(.none);

    var b = try batchpool.new(.{});
    defer b.submit();

    // Draw all shapes
    for (shapes, 0..) |shape, i| {
        const is_dragging = drag_target == @as(DragTarget, @enumFromInt(i));
        const color = getShapeColor(i, is_dragging);
        const thickness = if (is_dragging) @as(f32, 6) else @as(f32, 2);

        switch (shape) {
            .rect => |r| try b.rect(r, color, .{ .thickness = thickness }),
            .circle => |c| try b.circle(c, color, .{ .thickness = thickness }),
            .ellipse => |e| try b.ellipse(e, color, .{ .thickness = thickness }),
            .triangle => |t| try b.triangle(t, color, .{ .thickness = thickness }),
            .line => |l| try b.line(l, color, .{ .thickness = thickness }),
            .point => |p| try b.circleFilled(.{ .center = p, .radius = 5 }, color, .{}),
        }
    }

    // Draw ray from center to mouse and perform raycasting
    const csz = ctx.getCanvasSize();
    const center = csz.toRect(.origin).getCenter();
    const to_mouse = mouse_pos.sub(center);
    const to_mouse_len2 = to_mouse.dot(to_mouse);

    if (to_mouse_len2 > 0.0001) {
        const ray = geom.Ray.init(center, mouse_pos);
        const max_dim = @as(f32, @floatFromInt(@max(csz.width, csz.height)));
        const ray_end = center.add(ray.dir.scale(max_dim * 1.5));

        try b.line(.{ .p0 = center, .p1 = ray_end }, .yellow, .{ .thickness = 1 });

        // Raycast against all shapes
        for (shapes) |s| {
            const hit = switch (s) {
                .rect => |r| ray.raycast(r),
                .circle => |c| ray.raycast(c),
                .ellipse => |e| ray.raycast(e),
                .triangle => |t| ray.raycast(t),
                .line => |l| ray.raycast(l),
                else => null,
            };
            if (hit) |h| try drawHit(b, h);
        }
    }

    ctx.debugPrint("Press mouse's Left button to drag shapes.", .{});
}

pub fn quit(ctx: jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});
    batchpool.deinit();
}
