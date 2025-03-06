const std = @import("std");
const math = std.math;
const jok = @import("jok");
const physfs = jok.physfs;
const font = jok.font;
const zmath = jok.zmath;
const zmesh = jok.zmesh;
const imgui = jok.imgui;
const j2d = jok.j2d;
const j3d = jok.j3d;
const Camera = j3d.Camera;
const Scene = j3d.Scene;

var batchpool: j3d.BatchPool(64, false) = undefined;
var camera: Camera = undefined;
var sheet: *j2d.SpriteSheet = undefined;
var scene: *Scene = undefined;
var sprites: [14]*Scene.Object = undefined;
var sphere_mesh: zmesh.Shape = undefined;
var sphere_obj: *Scene.Object = undefined;

pub fn init(ctx: jok.Context) !void {
    std.log.info("game init", .{});

    try physfs.mount("assets", "", true);

    batchpool = try @TypeOf(batchpool).init(ctx);

    camera = Camera.fromPositionAndTarget(
        .{
            .perspective = .{
                .fov = std.math.pi / 4.0,
                .aspect_ratio = ctx.getAspectRatio(),
                .near = 0.1,
                .far = 1000,
            },
        },
        [_]f32{ 37, 9, 2 },
        [_]f32{ 0, 0, 0 },
    );

    sheet = try j2d.SpriteSheet.fromPicturesInDir(
        ctx,
        "images",
        1024,
        1024,
        .{},
    );

    // Init scene
    var buf: [10]u8 = undefined;
    scene = try Scene.create(ctx.allocator());
    const angle_step = std.math.tau / @as(f32, 14.0);
    var i: u32 = 0;
    while (i < 12) : (i += 1) {
        const name = try std.fmt.bufPrint(&buf, "image{d}", .{i + 1});
        const sp = sheet.getSpriteByName(name).?;
        sprites[i] = try Scene.Object.create(ctx.allocator(), .{
            .sprite = .{
                .transform = zmath.mul(
                    zmath.translation(0, 10, 0),
                    zmath.rotationX(angle_step * @as(f32, @floatFromInt(i))),
                ),
                .size = .{ .x = 2, .y = 2 },
                .uv = .{ sp.uv0, sp.uv1 },
                .texture = sheet.tex,
                .anchor_point = .{ .x = 0.5, .y = 0.5 },
            },
        });
        try scene.root.addChild(sprites[i]);
    }
    {
        const sp = sheet.getSpriteByName("ogre").?;
        sprites[12] = try Scene.Object.create(ctx.allocator(), .{
            .sprite = .{
                .transform = zmath.mul(
                    zmath.translation(0, 10, 0),
                    zmath.rotationX(angle_step * 12),
                ),
                .size = .{ .x = 5, .y = 5 },
                .uv = .{ sp.uv0, sp.uv1 },
                .texture = sheet.tex,
                .anchor_point = .{ .x = 0.5, .y = 0.5 },
                .facing_dir = .{ 0, 0, 1 },
            },
        });
        try scene.root.addChild(sprites[12]);
    }
    {
        const sp = sheet.getSpriteByName("sphinx").?;
        sprites[13] = try Scene.Object.create(ctx.allocator(), .{
            .sprite = .{
                .transform = zmath.mul(
                    zmath.translation(0, 10, 0),
                    zmath.rotationX(angle_step * 13),
                ),
                .size = .{ .x = 60, .y = 60 },
                .uv = .{ sp.uv0, sp.uv1 },
                .texture = sheet.tex,
                .anchor_point = .{ .x = 0.5, .y = 0.5 },
                .fixed_size = true,
            },
        });
        try scene.root.addChild(sprites[13]);
    }

    sphere_mesh = zmesh.Shape.initSubdividedSphere(1);
    sphere_obj = try Scene.Object.create(ctx.allocator(), .{
        .mesh = .{
            .transform = zmath.identity(),
            .mesh = try j3d.Mesh.fromShape(
                ctx.allocator(),
                sphere_mesh,
                .{},
            ),
            .color = .white,
        },
    });
    try scene.root.addChild(sphere_obj);
}

pub fn event(ctx: jok.Context, e: jok.Event) !void {
    _ = ctx;
    _ = e;
}

pub fn update(ctx: jok.Context) !void {
    // camera movement
    const distance = ctx.deltaSeconds() * 10;
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
    if (kbd.isPressed(.left)) {
        camera.rotateBy(0, -std.math.pi / 180.0);
    }
    if (kbd.isPressed(.right)) {
        camera.rotateBy(0, std.math.pi / 180.0);
    }
    if (kbd.isPressed(.up)) {
        camera.rotateBy(std.math.pi / 180.0, 0);
    }
    if (kbd.isPressed(.down)) {
        camera.rotateBy(-std.math.pi / 180.0, 0);
    }

    scene.root.setTransform(zmath.mul(
        zmath.rotationX(ctx.seconds()),
        zmath.rotationY(ctx.seconds()),
    ));
    sprites[12].actor.sprite.tint_color = .rgb(
        @intFromFloat(127 * (1 + @sin(ctx.seconds()))),
        @intFromFloat(127 * (1 + @cos(ctx.seconds()))),
        100,
    );
    sprites[13].actor.sprite.rotate_degree = ctx.seconds() * 180;
}

pub fn draw(ctx: jok.Context) !void {
    try ctx.renderer().clear(.rgb(80, 80, 80));

    var b = try batchpool.new(.{ .camera = camera, .triangle_sort = .simple });
    defer b.submit();
    try b.scene(scene, .{ .lighting = .{} });

    b.trs = zmath.translation(10, -10, -30);
    try b.sprite(
        .{ .x = 50, .y = 20 },
        .{
            .{ .x = 0, .y = 0 },
            .{ .x = 1, .y = 0.3 },
        },
        .{
            .texture = sheet.tex,
            .facing_dir = .{ 1, 1, 1 },
            .tessellation_level = 9,
        },
    );

    const ogre_pos = camera.calcScreenPosition(ctx, sprites[13].transform, null);
    ctx.debugPrint(
        "I have fixed size!",
        .{ .pos = .{ .x = ogre_pos.x + 50, .y = ogre_pos.y } },
    );
    ctx.debugPrint(
        "Press WSAD and up/down/left/right to move camera around the view",
        .{ .pos = .{ .x = 20, .y = 10 } },
    );
    ctx.debugPrint(
        imgui.format(
            "Camera: pos({d:.3},{d:.3},{d:.3}) dir({d:.3},{d:.3},{d:.3})",
            .{
                // zig fmt: off
            camera.position[0],camera.position[1],camera.position[2],
            camera.dir[0],camera.dir[1],camera.dir[2],
        },
        ),
        .{.pos=.{ .x = 20, .y = 28 }},
    );
}

pub fn quit(ctx: jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});

    sphere_mesh.deinit();
    sheet.destroy();
    scene.destroy(true);
    batchpool.deinit();
}
