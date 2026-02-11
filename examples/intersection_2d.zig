const std = @import("std");
const jok = @import("jok");
const geom = jok.geom;
const j2d = jok.j2d;

var batchpool: j2d.BatchPool(8, false) = undefined;

const DragTarget = enum {
    none,
    rect0,
    rect1,
    circle0,
    circle1,
    ellipse0,
    ellipse1,
    tri0,
    tri1,
    line0,
    line1,
    point0,
    point1,
};

var drag_target: DragTarget = .none;
var mouse_pos: geom.Point = .origin;

var rect0 = geom.Rectangle{ .x = 60, .y = 60, .width = 140, .height = 90 };
var rect1 = geom.Rectangle{ .x = 150, .y = 120, .width = 140, .height = 90 };

var circle0 = geom.Circle{ .center = .{ .x = 380, .y = 90 }, .radius = 50 };
var circle1 = geom.Circle{ .center = .{ .x = 450, .y = 130 }, .radius = 40 };

var ellipse0 = geom.Ellipse{ .center = .{ .x = 650, .y = 90 }, .radius = .{ .x = 70, .y = 40 } };
var ellipse1 = geom.Ellipse{ .center = .{ .x = 720, .y = 130 }, .radius = .{ .x = 50, .y = 30 } };

var tri0 = geom.Triangle{
    .p0 = .{ .x = 80, .y = 260 },
    .p1 = .{ .x = 180, .y = 220 },
    .p2 = .{ .x = 120, .y = 320 },
};
var tri1 = geom.Triangle{
    .p0 = .{ .x = 220, .y = 240 },
    .p1 = .{ .x = 320, .y = 260 },
    .p2 = .{ .x = 260, .y = 340 },
};

var line0 = geom.Line{ .p0 = .{ .x = 380, .y = 250 }, .p1 = .{ .x = 520, .y = 310 } };
var line1 = geom.Line{ .p0 = .{ .x = 400, .y = 330 }, .p1 = .{ .x = 560, .y = 260 } };

var point0 = geom.Point{ .x = 680, .y = 280 };
var point1 = geom.Point{ .x = 740, .y = 310 };

fn pickTarget(pos: geom.Point) DragTarget {
    const handle_radius: f32 = 8.0;
    const handle_radius2: f32 = handle_radius * handle_radius;
    const line_threshold2: f32 = 8.0 * 8.0;

    if (rect0.containsPoint(pos)) return .rect0;
    if (rect1.containsPoint(pos)) return .rect1;
    if (circle0.containsPoint(pos)) return .circle0;
    if (circle1.containsPoint(pos)) return .circle1;
    if (ellipse0.containsPoint(pos)) return .ellipse0;
    if (ellipse1.containsPoint(pos)) return .ellipse1;
    if (tri0.containsPoint(pos)) return .tri0;
    if (tri1.containsPoint(pos)) return .tri1;
    if (line0.closestPoint(pos).point.distance2(pos) <= line_threshold2) return .line0;
    if (line1.closestPoint(pos).point.distance2(pos) <= line_threshold2) return .line1;
    if (point0.distance2(pos) <= handle_radius2) return .point0;
    if (point1.distance2(pos) <= handle_radius2) return .point1;

    return .none;
}

fn applyDrag(target: DragTarget, delta: geom.Point) void {
    switch (target) {
        .rect0 => rect0 = rect0.translate(delta),
        .rect1 => rect1 = rect1.translate(delta),
        .circle0 => circle0 = circle0.translate(delta),
        .circle1 => circle1 = circle1.translate(delta),
        .ellipse0 => ellipse0 = ellipse0.translate(delta),
        .ellipse1 => ellipse1 = ellipse1.translate(delta),
        .tri0 => tri0 = tri0.translate(delta),
        .tri1 => tri1 = tri1.translate(delta),
        .line0 => line0 = line0.translate(delta),
        .line1 => line1 = line1.translate(delta),
        .point0 => point0 = point0.add(delta),
        .point1 => point1 = point1.add(delta),
        .none => {},
    }
}

fn drawHit(b: *j2d.Batch, hit: geom.Ray.Hit) !void {
    const normal_len: f32 = 18.0;
    try b.circleFilled(.{ .center = hit.point, .radius = 3 }, .yellow, .{});
    try b.line(
        .{ .p0 = hit.point, .p1 = hit.point.add(hit.normal.scale(normal_len)) },
        .yellow,
        .{ .thickness = 2 },
    );
}

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

    const rect0_hit = rect0.intersect(rect1) or rect0.intersect(circle0) or rect0.intersect(circle1) or rect0.intersect(ellipse0) or rect0.intersect(ellipse1) or rect0.intersect(tri0) or rect0.intersect(tri1) or rect0.intersect(line0) or rect0.intersect(line1) or rect0.intersect(point0) or rect0.intersect(point1);
    const rect1_hit = rect1.intersect(rect0) or rect1.intersect(circle0) or rect1.intersect(circle1) or rect1.intersect(ellipse0) or rect1.intersect(ellipse1) or rect1.intersect(tri0) or rect1.intersect(tri1) or rect1.intersect(line0) or rect1.intersect(line1) or rect1.intersect(point0) or rect1.intersect(point1);

    const circle0_hit = circle0.intersect(rect0) or circle0.intersect(rect1) or circle0.intersect(circle1) or circle0.intersect(ellipse0) or circle0.intersect(ellipse1) or circle0.intersect(tri0) or circle0.intersect(tri1) or circle0.intersect(line0) or circle0.intersect(line1) or circle0.intersect(point0) or circle0.intersect(point1);
    const circle1_hit = circle1.intersect(rect0) or circle1.intersect(rect1) or circle1.intersect(circle0) or circle1.intersect(ellipse0) or circle1.intersect(ellipse1) or circle1.intersect(tri0) or circle1.intersect(tri1) or circle1.intersect(line0) or circle1.intersect(line1) or circle1.intersect(point0) or circle1.intersect(point1);

    const ellipse0_hit = ellipse0.intersect(rect0) or ellipse0.intersect(rect1) or ellipse0.intersect(circle0) or ellipse0.intersect(circle1) or ellipse0.intersect(ellipse1) or ellipse0.intersect(tri0) or ellipse0.intersect(tri1) or ellipse0.intersect(line0) or ellipse0.intersect(line1) or ellipse0.intersect(point0) or ellipse0.intersect(point1);
    const ellipse1_hit = ellipse1.intersect(rect0) or ellipse1.intersect(rect1) or ellipse1.intersect(circle0) or ellipse1.intersect(circle1) or ellipse1.intersect(ellipse0) or ellipse1.intersect(tri0) or ellipse1.intersect(tri1) or ellipse1.intersect(line0) or ellipse1.intersect(line1) or ellipse1.intersect(point0) or ellipse1.intersect(point1);

    const tri0_hit = tri0.intersect(rect0) or tri0.intersect(rect1) or tri0.intersect(circle0) or tri0.intersect(circle1) or tri0.intersect(ellipse0) or tri0.intersect(ellipse1) or tri0.intersect(tri1) or tri0.intersect(line0) or tri0.intersect(line1) or tri0.intersect(point0) or tri0.intersect(point1);
    const tri1_hit = tri1.intersect(rect0) or tri1.intersect(rect1) or tri1.intersect(circle0) or tri1.intersect(circle1) or tri1.intersect(ellipse0) or tri1.intersect(ellipse1) or tri1.intersect(tri0) or tri1.intersect(line0) or tri1.intersect(line1) or tri1.intersect(point0) or tri1.intersect(point1);

    const line0_hit = line0.intersect(rect0) or line0.intersect(rect1) or line0.intersect(circle0) or line0.intersect(circle1) or line0.intersect(ellipse0) or line0.intersect(ellipse1) or line0.intersect(tri0) or line0.intersect(tri1) or line0.intersect(line1) or line0.intersect(point0) or line0.intersect(point1);
    const line1_hit = line1.intersect(rect0) or line1.intersect(rect1) or line1.intersect(circle0) or line1.intersect(circle1) or line1.intersect(ellipse0) or line1.intersect(ellipse1) or line1.intersect(tri0) or line1.intersect(tri1) or line1.intersect(line0) or line1.intersect(point0) or line1.intersect(point1);

    const point0_hit = rect0.containsPoint(point0) or rect1.containsPoint(point0) or circle0.containsPoint(point0) or circle1.containsPoint(point0) or ellipse0.containsPoint(point0) or ellipse1.containsPoint(point0) or tri0.containsPoint(point0) or tri1.containsPoint(point0) or line0.closestPoint(point0).point.distance(point0) < 2 or line1.closestPoint(point0).point.distance(point0) < 2 or point0.distance(point1) < 2;
    const point1_hit = rect0.containsPoint(point1) or rect1.containsPoint(point1) or circle0.containsPoint(point1) or circle1.containsPoint(point1) or ellipse0.containsPoint(point1) or ellipse1.containsPoint(point1) or tri0.containsPoint(point1) or tri1.containsPoint(point1) or line0.closestPoint(point1).point.distance(point1) < 2 or line1.closestPoint(point1).point.distance(point1) < 2 or point0.distance(point1) < 2;

    var b = try batchpool.new(.{});
    defer b.submit();

    const rect0_color: jok.Color = if (rect0_hit) .red else .white;
    const rect1_color: jok.Color = if (rect1_hit) .red else .white;
    const circle0_color: jok.Color = if (circle0_hit) .red else .white;
    const circle1_color: jok.Color = if (circle1_hit) .red else .white;
    const ellipse0_color: jok.Color = if (ellipse0_hit) .red else .white;
    const ellipse1_color: jok.Color = if (ellipse1_hit) .red else .white;
    const tri0_color: jok.Color = if (tri0_hit) .red else .white;
    const tri1_color: jok.Color = if (tri1_hit) .red else .white;
    const line0_color: jok.Color = if (line0_hit) .red else .white;
    const line1_color: jok.Color = if (line1_hit) .red else .white;
    const point0_color: jok.Color = if (point0_hit) .red else .white;
    const point1_color: jok.Color = if (point1_hit) .red else .white;

    try b.rect(rect0, rect0_color, .{ .thickness = if (drag_target == .rect0) 6 else 2 });
    try b.rect(rect1, rect1_color, .{ .thickness = if (drag_target == .rect1) 6 else 2 });
    try b.circle(circle0, circle0_color, .{ .thickness = if (drag_target == .circle0) 6 else 2 });
    try b.circle(circle1, circle1_color, .{ .thickness = if (drag_target == .circle1) 6 else 2 });
    try b.ellipse(ellipse0, ellipse0_color, .{ .thickness = if (drag_target == .ellipse0) 6 else 2 });
    try b.ellipse(ellipse1, ellipse1_color, .{ .thickness = if (drag_target == .ellipse1) 6 else 2 });
    try b.triangle(tri0, tri0_color, .{ .thickness = if (drag_target == .tri0) 6 else 2 });
    try b.triangle(tri1, tri1_color, .{ .thickness = if (drag_target == .tri1) 6 else 2 });
    try b.line(line0, line0_color, .{ .thickness = if (drag_target == .line0) 6 else 2 });
    try b.line(line1, line1_color, .{ .thickness = if (drag_target == .line1) 6 else 2 });
    try b.circleFilled(.{ .center = point0, .radius = 5 }, point0_color, .{});
    try b.circleFilled(.{ .center = point1, .radius = 5 }, point1_color, .{});

    const csz = ctx.getCanvasSize();
    const center = csz.toRect(.origin).getCenter();
    const to_mouse = mouse_pos.sub(center);
    const to_mouse_len2 = to_mouse.dot(to_mouse);
    if (to_mouse_len2 > 0.0001) {
        const ray = geom.Ray.fromPoints(center, mouse_pos);
        const max_dim = @as(f32, @floatFromInt(@max(csz.width, csz.height)));
        const ray_end = center.add(ray.dir.scale(max_dim * 1.5));
        try b.line(.{ .p0 = center, .p1 = ray_end }, .yellow, .{ .thickness = 1 });

        if (ray.raycast(rect0)) |hit| try drawHit(b, hit);
        if (ray.raycast(rect1)) |hit| try drawHit(b, hit);
        if (ray.raycast(circle0)) |hit| try drawHit(b, hit);
        if (ray.raycast(circle1)) |hit| try drawHit(b, hit);
        if (ray.raycast(ellipse0)) |hit| try drawHit(b, hit);
        if (ray.raycast(ellipse1)) |hit| try drawHit(b, hit);
        if (ray.raycast(tri0)) |hit| try drawHit(b, hit);
        if (ray.raycast(tri1)) |hit| try drawHit(b, hit);
        if (ray.raycast(line0)) |hit| try drawHit(b, hit);
        if (ray.raycast(line1)) |hit| try drawHit(b, hit);
    }

    ctx.debugPrint("Press mouse's Left button to drag shapes.", .{});
}

pub fn quit(ctx: jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});
    batchpool.deinit();
}
