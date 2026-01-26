const std = @import("std");
const jok = @import("jok");
const j2d = jok.j2d;

var batchpool: j2d.BatchPool(16, false) = undefined;
var map: jok.Rectangle = undefined;
var camera: j2d.Camera = undefined;
var rects = std.ArrayList(jok.Rectangle).empty;

pub fn init(ctx: jok.Context) !void {
    const csz = ctx.getCanvasSize();
    batchpool = try j2d.BatchPool(16, false).init(ctx);
    map = .{ .x = 0, .y = 0, .width = 3000, .height = 3000 };
    camera = j2d.Camera.init(ctx, csz.toPoint().scale(0.5), csz.width, csz.height);

    var rng = std.Random.DefaultPrng.init(@intCast((try std.Io.Clock.now(.awake, ctx.io())).toMilliseconds()));
    for (0..100) |_| {
        try rects.append(ctx.allocator(), .{
            .x = @floatFromInt(rng.random().uintLessThan(u32, 2900)),
            .y = @floatFromInt(rng.random().uintLessThan(u32, 2900)),
            .width = @floatFromInt(rng.random().uintLessThan(u32, 100)),
            .height = @floatFromInt(rng.random().uintLessThan(u32, 100)),
        });
    }
}

pub fn event(ctx: jok.Context, e: jok.Event) !void {
    _ = ctx;

    switch (e) {
        .key_up => |ke| {
            switch (ke.scancode) {
                .space => camera.rotateTo(0),
                .c => camera.scaleTo(1),
                .@"return" => camera.translateTo(camera.orig.getCenter()),
                else => {},
            }
        },
        else => {},
    }
}

pub fn update(ctx: jok.Context) !void {
    _ = ctx;

    const speed = 10;
    var v = j2d.Vector.zero;
    const keyboard = jok.io.getKeyboardState();
    if (keyboard.isPressed(.left)) {
        v.data[0] = -1;
    } else if (keyboard.isPressed(.right)) {
        v.data[0] = 1;
    }
    if (keyboard.isPressed(.up)) {
        v.data[1] = -1;
    } else if (keyboard.isPressed(.down)) {
        v.data[1] = 1;
    }
    v = v.norm().scale(speed);
    camera.translateBy(v);

    if (keyboard.isPressed(.page_down)) {
        camera.rotateBy(0.1);
    } else if (keyboard.isPressed(.page_up)) {
        camera.rotateBy(-0.1);
    }

    if (keyboard.isPressed(.z)) {
        camera.scaleBy(1.1);
    } else if (keyboard.isPressed(.x)) {
        camera.scaleBy(0.9);
    }
}

pub fn draw(ctx: jok.Context) !void {
    try ctx.renderer().clear(.black);

    {
        // Draw map
        var b = try batchpool.new(.{});
        b.trs = camera.getTransform();
        try b.rectFilled(map, .rgb(80, 80, 80), .{});
        for (rects.items) |r| try b.rectFilled(r, .purple, .{});

        b.setIdentity();
        const screen_center = ctx.getCanvasSize().toRect(.origin).getCenter();
        try b.line(
            screen_center.sub(.{ 25, 0 }),
            screen_center.add(.{ 25, 0 }),
            .red,
            .{ .thickness = 4 },
        );
        try b.line(
            screen_center.sub(.{ 0, 25 }),
            screen_center.add(.{ 0, 25 }),
            .red,
            .{ .thickness = 4 },
        );
        b.submit();
    }
    {
        // Draw mini-map on bottom-right corner
        const csz = ctx.getCanvasSize();
        const mini_map = jok.Rectangle{
            .x = csz.getWidthFloat() - 200,
            .y = csz.getHeightFloat() - 200,
            .width = 200,
            .height = 200,
        };
        var b = try batchpool.new(.{ .clip_rect = mini_map });
        b.scaleAroundWorldOrigin(.{ mini_map.width / map.width, mini_map.height / map.height });
        b.translate(mini_map.getTopLeft());
        try b.rectFilled(map, .cyan, .{});
        for (rects.items) |r| try b.rectFilled(r, .rgb(80, 80, 80), .{});

        // Draw camera rectangle
        const transformed = b.trs.transformRectangle(camera.rect);
        b.rotateByPoint(transformed.getCenter(), camera.rotation);
        try b.rect(camera.rect, .black, .{});
        try b.line(
            camera.rect.getCenter().sub(.{ 100, 0 }),
            camera.rect.getCenter().add(.{ 100, 0 }),
            .black,
            .{ .thickness = 2 },
        );
        try b.line(
            camera.rect.getCenter().sub(.{ 0, 100 }),
            camera.rect.getCenter().add(.{ 0, 100 }),
            .black,
            .{ .thickness = 2 },
        );
        b.submit();
    }

    var buf: [1024]u8 = undefined;
    ctx.debugPrint(
        try std.fmt.bufPrint(&buf, "Camera Position: {d:.0},{d:.0}", .{ camera.rect.getCenter().x, camera.rect.getCenter().y }),
        .{ .pos = .origin, .color = .white },
    );
    ctx.debugPrint(
        try std.fmt.bufPrint(&buf, "Camera Rotation: {d:.2}", .{std.math.radiansToDegrees(camera.rotation)}),
        .{ .pos = .{ .x = 0, .y = 20 }, .color = .white },
    );
    ctx.debugPrint(
        try std.fmt.bufPrint(&buf, "Camera Scaling: {d:.2}", .{camera.getScaling()}),
        .{ .pos = .{ .x = 0, .y = 40 }, .color = .white },
    );
    ctx.debugPrint(
        try std.fmt.bufPrint(&buf, "Camera control Keys:", .{}),
        .{ .pos = .{ .x = 0, .y = 60 }, .color = .white },
    );
    ctx.debugPrint(
        try std.fmt.bufPrint(&buf, "    UP/DOWN/LEFT/RIGHT to move, ENTER to reset position to original", .{}),
        .{ .pos = .{ .x = 0, .y = 80 }, .color = .white },
    );
    ctx.debugPrint(
        try std.fmt.bufPrint(&buf, "    PAGE-DOWN/PAGE-UP to rotate, SPACE to reset rotation to 0", .{}),
        .{ .pos = .{ .x = 0, .y = 100 }, .color = .white },
    );
    ctx.debugPrint(
        try std.fmt.bufPrint(&buf, "    Z/X to scale up and down, C to reset scaling to 1", .{}),
        .{ .pos = .{ .x = 0, .y = 120 }, .color = .white },
    );
}

pub fn quit(ctx: jok.Context) void {
    rects.deinit(ctx.allocator());
    batchpool.deinit();
}
