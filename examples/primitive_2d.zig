const std = @import("std");
const jok = @import("jok");
const imgui = jok.imgui;
const j2d = jok.j2d;

pub const jok_window_size = jok.config.WindowSize{
    .custom = .{ .width = 1280, .height = 720 },
};

var batchpool: j2d.BatchPool(64, false) = undefined;
var scale: f32 = 1.0;
var rotate: f32 = 0.0;
var translate: jok.Point = .{ .x = 0, .y = 0 };
var convex_poly: j2d.ConvexPoly = undefined;
var concave_poly: j2d.ConcavePoly = undefined;
var polyline: j2d.Polyline = undefined;

pub fn init(ctx: jok.Context) !void {
    batchpool = try @TypeOf(batchpool).init(ctx);

    convex_poly = j2d.ConvexPoly.begin(ctx.allocator(), null);
    try convex_poly.point(.{ .color = .red, .pos = .{ .x = -40, .y = -40 } });
    try convex_poly.point(.{ .color = .green, .pos = .{ .x = 0, .y = -50 } });
    try convex_poly.point(.{ .color = .blue, .pos = .{ .x = 40, .y = -40 } });
    try convex_poly.point(.{ .color = .yellow, .pos = .{ .x = 50, .y = 0 } });
    try convex_poly.point(.{ .color = .cyan, .pos = .{ .x = 0, .y = 40 } });
    try convex_poly.point(.{ .color = .purple, .pos = .{ .x = -40, .y = 30 } });
    convex_poly.end();

    concave_poly = j2d.ConcavePoly.begin(ctx.allocator());
    try concave_poly.point(.{ .x = -50, .y = -50 });
    try concave_poly.point(.{ .x = -30, .y = -50 });
    try concave_poly.point(.{ .x = 0, .y = 0 });
    try concave_poly.point(.{ .x = 30, .y = -50 });
    try concave_poly.point(.{ .x = 50, .y = -50 });
    try concave_poly.point(.{ .x = 0, .y = 30 });
    concave_poly.end();

    polyline = j2d.Polyline.begin(ctx.allocator());
    try polyline.point(.{ .x = -50, .y = -50 });
    try polyline.point(.{ .x = -30, .y = -50 });
    try polyline.point(.{ .x = 0, .y = 0 });
    try polyline.point(.{ .x = 30, .y = -50 });
    try polyline.point(.{ .x = 50, .y = -50 });
    try polyline.point(.{ .x = 0, .y = 30 });
    polyline.end();
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

    imgui.setNextWindowPos(.{
        .cond = .always,
        .x = 0,
        .y = 0,
    });
    if (imgui.begin("Control", .{ .flags = .{
        .always_auto_resize = true,
        .no_title_bar = true,
        .no_resize = true,
    } })) {
        _ = imgui.sliderFloat("scale", .{ .v = &scale, .min = 0.1, .max = 1.4 });
        imgui.sameLine(.{ .spacing = 50 });
        _ = imgui.sliderFloat("rotate", .{ .v = &rotate, .min = 0, .max = std.math.pi * 2 });
        imgui.sameLine(.{ .spacing = 50 });
        _ = imgui.sliderFloat2("translate", .{ .v = @ptrCast(&translate), .min = 0, .max = 400 });
    }
    imgui.end();

    var b = try batchpool.new(.{});
    defer b.submit();

    b.scale(scale, scale);
    b.rotateByOrigin(rotate);
    b.translate(translate.x, translate.y);

    {
        try b.pushTransform();
        defer b.popTransform();
        b.translate(100, 200);
        try b.line(
            .{ .x = -50, .y = 0 },
            .{ .x = 50, .y = 0 },
            .white,
            .{},
        );
    }
    {
        try b.pushTransform();
        defer b.popTransform();
        b.translate(250, 200);
        try b.rect(.{
            .x = -50,
            .y = -50,
            .width = 100,
            .height = 100,
        }, .white, .{});
    }
    {
        try b.pushTransform();
        defer b.popTransform();
        b.translate(400, 200);
        try b.rectFilled(.{
            .x = -50,
            .y = -50,
            .width = 100,
            .height = 100,
        }, .white, .{});
    }
    {
        try b.pushTransform();
        defer b.popTransform();
        b.translate(550, 200);
        try b.rectFilledMultiColor(
            .{
                .x = -50,
                .y = -50,
                .width = 100,
                .height = 100,
            },
            .red,
            .green,
            .blue,
            .yellow,
            .{},
        );
    }
    {
        try b.pushTransform();
        defer b.popTransform();
        b.translate(700, 200);
        try b.rectRounded(
            .{
                .x = 0,
                .y = 0,
                .width = 100,
                .height = 100,
            },
            .white,
            .{
                .rounding = 10,
                .anchor_point = .{ .x = 0.5, .y = 0.5 },
            },
        );
    }
    {
        try b.pushTransform();
        defer b.popTransform();
        b.translate(850, 200);
        try b.rectRoundedFilled(
            .{
                .x = 0,
                .y = 0,
                .width = 100,
                .height = 100,
            },
            .white,
            .{
                .rounding = 10,
                .anchor_point = .{ .x = 0.5, .y = 0.5 },
            },
        );
    }
    {
        try b.pushTransform();
        defer b.popTransform();
        b.translate(1000, 200);
        try b.quad(
            .{ .x = -30, .y = -30 },
            .{ .x = 30, .y = -30 },
            .{ .x = 50, .y = 30 },
            .{ .x = -50, .y = 30 },
            .white,
            .{},
        );
    }
    {
        try b.pushTransform();
        defer b.popTransform();
        b.translate(1150, 200);
        try b.quadFilled(
            .{ .x = -30, .y = -30 },
            .{ .x = 30, .y = -30 },
            .{ .x = 50, .y = 30 },
            .{ .x = -50, .y = 30 },
            .white,
            .{},
        );
    }
    {
        try b.pushTransform();
        defer b.popTransform();
        b.translate(100, 400);
        try b.quadFilledMultiColor(
            .{ .x = -30, .y = -30 },
            .{ .x = 30, .y = -30 },
            .{ .x = 50, .y = 30 },
            .{ .x = -50, .y = 30 },
            .red,
            .green,
            .blue,
            .yellow,
            .{},
        );
    }
    {
        try b.pushTransform();
        defer b.popTransform();
        b.translate(250, 400);
        try b.triangle(
            .{
                .p0 = .{ .x = 0, .y = -50 },
                .p1 = .{ .x = -50, .y = 40 },
                .p2 = .{ .x = 50, .y = 40 },
            },
            .white,
            .{},
        );
    }
    {
        try b.pushTransform();
        defer b.popTransform();
        b.translate(400, 400);
        try b.triangleFilled(
            .{
                .p0 = .{ .x = 0, .y = -50 },
                .p1 = .{ .x = -50, .y = 40 },
                .p2 = .{ .x = 50, .y = 40 },
            },
            .white,
            .{},
        );
    }
    {
        try b.pushTransform();
        defer b.popTransform();
        b.translate(400, 400);
        try b.triangleFilledMultiColor(
            .{
                .p0 = .{ .x = 0, .y = -50 },
                .p1 = .{ .x = -50, .y = 40 },
                .p2 = .{ .x = 50, .y = 40 },
            },
            .{
                .red,
                .green,
                .blue,
            },
            .{},
        );
    }
    {
        try b.pushTransform();
        defer b.popTransform();
        b.translate(550, 400);
        try b.circle(
            .{
                .center = .{ .x = 0, .y = 0 },
                .radius = 50,
            },
            .white,
            .{},
        );
    }
    {
        try b.pushTransform();
        defer b.popTransform();
        b.translate(700, 400);
        try b.circleFilled(
            .{
                .center = .{ .x = 0, .y = 0 },
                .radius = 50,
            },
            .white,
            .{},
        );
    }
    {
        try b.pushTransform();
        defer b.popTransform();
        b.translate(850, 400);
        try b.ellipse(
            .{
                .center = .{ .x = 0, .y = 0 },
                .radius = .{ .x = 50, .y = 30 },
            },
            .white,
            .{ .rotate_angle = rotate },
        );
    }
    {
        try b.pushTransform();
        defer b.popTransform();
        b.translate(1000, 400);
        try b.ellipseFilled(
            .{
                .center = .{ .x = 0, .y = 0 },
                .radius = .{ .x = 50, .y = 30 },
            },
            .white,
            .{ .rotate_angle = rotate },
        );
    }
    {
        try b.pushTransform();
        defer b.popTransform();
        b.translate(1150, 400);
        try b.ngon(
            .{ .x = 0, .y = 0 },
            50,
            .white,
            6,
            .{},
        );
    }
    {
        try b.pushTransform();
        defer b.popTransform();
        b.translate(100, 600);
        try b.ngonFilled(
            .{ .x = 0, .y = 0 },
            50,
            .white,
            6,
            .{},
        );
    }
    {
        try b.pushTransform();
        defer b.popTransform();
        b.translate(250, 600);
        try b.bezierCubic(
            .{ .x = -50, .y = -50 },
            .{ .x = -10, .y = -50 },
            .{ .x = 10, .y = 50 },
            .{ .x = 50, .y = 50 },
            .white,
            .{},
        );
    }
    {
        try b.pushTransform();
        defer b.popTransform();
        b.translate(400, 600);
        try b.bezierQuadratic(
            .{ .x = -50, .y = -50 },
            .{ .x = 0, .y = 50 },
            .{ .x = 50, .y = -50 },
            .white,
            .{},
        );
    }
    {
        try b.pushTransform();
        defer b.popTransform();
        b.translate(550, 600);
        try b.convexPolyFilled(convex_poly, .{});
    }
    {
        try b.pushTransform();
        defer b.popTransform();
        b.translate(700, 600);
        try b.concavePolyFilled(concave_poly, .white, .{});
    }
    {
        try b.pushTransform();
        defer b.popTransform();
        b.translate(850, 600);
        try b.polyline(polyline, .white, .{});
    }
}

pub fn quit(ctx: jok.Context) void {
    _ = ctx;

    convex_poly.deinit();
    concave_poly.deinit();
    polyline.deinit();
    batchpool.deinit();
}
