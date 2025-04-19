const std = @import("std");
const jok = @import("jok");
const imgui = jok.imgui;
const j2d = jok.j2d;

var batchpool: j2d.BatchPool(64, false) = undefined;
var offset0: [2]f32 = .{ 0, 0 };
var offset1: [2]f32 = .{ 0, 0 };
var tri0 = jok.Triangle{
    .p0 = .{ .x = 10, .y = 10 },
    .p1 = .{ .x = 90, .y = 30 },
    .p2 = .{ .x = 10, .y = 90 },
};
var tri1 = jok.Triangle{
    .p0 = .{ .x = 100, .y = 10 },
    .p1 = .{ .x = 220, .y = 50 },
    .p2 = .{ .x = 150, .y = 80 },
};

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
    try ctx.renderer().clear(.none);

    var tri_color = jok.Color.white;
    var tri_thickness = @as(f32, 2);
    if (tri0.translate(offset0).intersectTriangle(tri1.translate(offset1))) {
        tri_color = .red;
        tri_thickness = 5;
    }
    var rect_color = jok.Color.white;
    var rect_thickness = @as(f32, 1);
    const rect0 = tri0.translate(offset0).boundingRect();
    const rect1 = tri1.translate(offset1).boundingRect();
    if (rect0.hasIntersection(rect1)) {
        rect_color = .red;
        rect_thickness = 3;
    }

    var b = try batchpool.new(.{});
    defer b.submit();
    try b.pushTransform();
    b.trs = j2d.AffineTransform.init().translate(offset0);
    try b.triangle(
        tri0,
        tri_color,
        .{ .thickness = tri_thickness },
    );
    b.popTransform();

    try b.pushTransform();
    b.trs = j2d.AffineTransform.init().translate(offset1);
    try b.triangle(
        tri1,
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
        _ = imgui.dragFloat2("offset 0", .{ .v = &offset0 });
        _ = imgui.dragFloat2("p0", .{ .v = @ptrCast(&tri0.p0) });
        _ = imgui.dragFloat2("p1", .{ .v = @ptrCast(&tri0.p1) });
        _ = imgui.dragFloat2("p2", .{ .v = @ptrCast(&tri0.p2) });
        imgui.text("triangle 1", .{});
        _ = imgui.dragFloat2("offset 1", .{ .v = &offset1 });
        _ = imgui.dragFloat2("p3", .{ .v = @ptrCast(&tri1.p0) });
        _ = imgui.dragFloat2("p4", .{ .v = @ptrCast(&tri1.p1) });
        _ = imgui.dragFloat2("p5", .{ .v = @ptrCast(&tri1.p2) });
    }
    imgui.end();
}

pub fn quit(ctx: jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});
    batchpool.deinit();
}
