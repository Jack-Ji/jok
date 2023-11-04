const std = @import("std");
const jok = @import("jok");
const sdl = jok.sdl;
const imgui = jok.imgui;
const j2d = jok.j2d;

var offset0: [2]f32 = .{ 0, 0 };
var offset1: [2]f32 = .{ 0, 0 };
var p0: [2]f32 = .{ 10, 10 };
var p1: [2]f32 = .{ 90, 30 };
var p2: [2]f32 = .{ 10, 90 };
var p3: [2]f32 = .{ 100, 10 };
var p4: [2]f32 = .{ 220, 50 };
var p5: [2]f32 = .{ 150, 80 };

pub fn init(ctx: jok.Context) !void {
    _ = ctx;

    std.log.info("game init", .{});
}

pub fn event(ctx: jok.Context, e: sdl.Event) !void {
    _ = ctx;
    _ = e;
}

pub fn update(ctx: jok.Context) !void {
    _ = ctx;
    if (imgui.begin("Control", .{})) {
        imgui.separator();
        imgui.text("triangle 0", .{});
        _ = imgui.dragFloat2("offset 0", .{ .v = &offset0 });
        _ = imgui.dragFloat2("p0", .{ .v = &p0 });
        _ = imgui.dragFloat2("p1", .{ .v = &p1 });
        _ = imgui.dragFloat2("p2", .{ .v = &p2 });
        imgui.text("triangle 1", .{});
        _ = imgui.dragFloat2("offset 1", .{ .v = &offset1 });
        _ = imgui.dragFloat2("p3", .{ .v = &p3 });
        _ = imgui.dragFloat2("p4", .{ .v = &p4 });
        _ = imgui.dragFloat2("p5", .{ .v = &p5 });
    }
    imgui.end();
}

pub fn draw(ctx: jok.Context) !void {
    _ = ctx;
    var tri_color = sdl.Color.white;
    var tri_thickness = @as(f32, 2);
    const tri0 = [_][2]f32{
        .{ offset0[0] + p0[0], offset0[1] + p0[1] },
        .{ offset0[0] + p1[0], offset0[1] + p1[1] },
        .{ offset0[0] + p2[0], offset0[1] + p2[1] },
    };
    const tri1 = [_][2]f32{
        .{ offset1[0] + p3[0], offset1[1] + p3[1] },
        .{ offset1[0] + p4[0], offset1[1] + p4[1] },
        .{ offset1[0] + p5[0], offset1[1] + p5[1] },
    };
    if (jok.utils.algo.areTrianglesIntersect(tri0, tri1)) {
        tri_color = sdl.Color.red;
        tri_thickness = 5;
    }
    var rect_color = sdl.Color.white;
    var rect_thickness = @as(f32, 1);
    const rect0 = jok.utils.algo.triangleRect(tri0);
    const rect1 = jok.utils.algo.triangleRect(tri1);
    if (rect0.hasIntersection(rect1)) {
        rect_color = sdl.Color.red;
        rect_thickness = 3;
    }

    try j2d.begin(.{});
    j2d.getTransform().setToTranslate(.{ .x = offset0[0], .y = offset0[1] });
    try j2d.triangle(
        .{ .x = p0[0], .y = p0[1] },
        .{ .x = p1[0], .y = p1[1] },
        .{ .x = p2[0], .y = p2[1] },
        tri_color,
        .{ .thickness = tri_thickness },
    );

    j2d.getTransform().setToTranslate(.{ .x = offset1[0], .y = offset1[1] });
    try j2d.triangle(
        .{ .x = p3[0], .y = p3[1] },
        .{ .x = p4[0], .y = p4[1] },
        .{ .x = p5[0], .y = p5[1] },
        tri_color,
        .{ .thickness = tri_thickness },
    );

    j2d.getTransform().setToIdentity();
    try j2d.rect(
        rect0,
        rect_color,
        .{ .thickness = rect_thickness },
    );
    try j2d.rect(
        rect1,
        rect_color,
        .{ .thickness = rect_thickness },
    );
    try j2d.end();
}

pub fn quit(ctx: jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});
}
