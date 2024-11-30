const std = @import("std");
const jok = @import("jok");
const imgui = jok.imgui;
const j2d = jok.j2d;

var batchpool: j2d.BatchPool(64, false) = undefined;
var offset0: jok.Point = .{ .x = 0, .y = 0 };
var offset1: jok.Point = .{ .x = 0, .y = 0 };
var p0: jok.Point = .{ .x = 10, .y = 10 };
var p1: jok.Point = .{ .x = 90, .y = 30 };
var p2: jok.Point = .{ .x = 10, .y = 90 };
var p3: jok.Point = .{ .x = 100, .y = 10 };
var p4: jok.Point = .{ .x = 220, .y = 50 };
var p5: jok.Point = .{ .x = 150, .y = 80 };

pub fn init(ctx: jok.Context) !void {
    std.log.info("game init", .{});

    batchpool = try @TypeOf(batchpool).init(ctx);
}

pub fn event(ctx: jok.Context, e: jok.Event) !void {
    _ = ctx;
    _ = e;
}

pub fn update(ctx: jok.Context) !void {
    _ = ctx;
}

pub fn draw(ctx: jok.Context) !void {
    try ctx.renderer().clear(null);

    var tri_color = jok.Color.white;
    var tri_thickness = @as(f32, 2);
    const tri0 = [_]jok.Point{
        .{ .x = offset0.x + p0.x, .y = offset0.y + p0.y },
        .{ .x = offset0.x + p1.x, .y = offset0.y + p1.y },
        .{ .x = offset0.x + p2.x, .y = offset0.y + p2.y },
    };
    const tri1 = [_]jok.Point{
        .{ .x = offset1.x + p3.x, .y = offset1.y + p3.y },
        .{ .x = offset1.x + p4.x, .y = offset1.y + p4.y },
        .{ .x = offset1.x + p5.x, .y = offset1.y + p5.y },
    };
    if (jok.utils.algo.areTrianglesIntersect(tri0, tri1)) {
        tri_color = jok.Color.red;
        tri_thickness = 5;
    }
    var rect_color = jok.Color.white;
    var rect_thickness = @as(f32, 1);
    const rect0 = jok.utils.algo.triangleRect(tri0);
    const rect1 = jok.utils.algo.triangleRect(tri1);
    if (rect0.hasIntersection(rect1)) {
        rect_color = jok.Color.red;
        rect_thickness = 3;
    }

    var b = try batchpool.new(.{});
    defer b.submit();
    try b.pushTransform(j2d.AffineTransform.init().translate(.{ .x = offset0.x, .y = offset0.y }));
    try b.triangle(
        .{ .x = p0.x, .y = p0.y },
        .{ .x = p1.x, .y = p1.y },
        .{ .x = p2.x, .y = p2.y },
        tri_color,
        .{ .thickness = tri_thickness },
    );
    b.popTransform();

    try b.pushTransform(j2d.AffineTransform.init().translate(.{ .x = offset1.x, .y = offset1.y }));
    try b.triangle(
        .{ .x = p3.x, .y = p3.y },
        .{ .x = p4.x, .y = p4.y },
        .{ .x = p5.x, .y = p5.y },
        tri_color,
        .{ .thickness = tri_thickness },
    );
    b.popTransform();

    try b.rect(
        rect0,
        rect_color,
        .{ .thickness = rect_thickness },
    );
    try b.rect(
        rect1,
        rect_color,
        .{ .thickness = rect_thickness },
    );

    if (imgui.begin("Control", .{})) {
        imgui.separator();
        imgui.text("triangle 0", .{});
        _ = imgui.dragFloat2("offset 0", .{ .v = @ptrCast(&offset0) });
        _ = imgui.dragFloat2("p0", .{ .v = @ptrCast(&p0) });
        _ = imgui.dragFloat2("p1", .{ .v = @ptrCast(&p1) });
        _ = imgui.dragFloat2("p2", .{ .v = @ptrCast(&p2) });
        imgui.text("triangle 1", .{});
        _ = imgui.dragFloat2("offset 1", .{ .v = @ptrCast(&offset1) });
        _ = imgui.dragFloat2("p3", .{ .v = @ptrCast(&p3) });
        _ = imgui.dragFloat2("p4", .{ .v = @ptrCast(&p4) });
        _ = imgui.dragFloat2("p5", .{ .v = @ptrCast(&p5) });
    }
    imgui.end();
}

pub fn quit(ctx: jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});
    batchpool.deinit();
}
