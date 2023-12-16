const std = @import("std");
const math = std.math;
const jok = @import("jok");
const sdl = jok.sdl;
const font = jok.font;
const zmath = jok.zmath;
const zmesh = jok.zmesh;
const j2d = jok.j2d;
const j3d = jok.j3d;
const Camera = j3d.Camera;
const Scene = j3d.Scene;

var camera: Camera = undefined;
var sheet: *j2d.SpriteSheet = undefined;
var scene: *Scene = undefined;
var sprites: [14]*Scene.Object = undefined;
var sphere_mesh: jok.zmesh.Shape = undefined;
var sphere_obj: *Scene.Object = undefined;

pub fn init(ctx: jok.Context) !void {
    std.log.info("game init", .{});

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
        "assets/images",
        1024,
        1024,
        1,
        true,
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

    sphere_mesh = jok.zmesh.Shape.initSubdividedSphere(1);
    sphere_obj = try Scene.Object.create(ctx.allocator(), .{
        .mesh = .{
            .transform = zmath.identity(),
            .mesh = try j3d.Mesh.fromShape(
                ctx.allocator(),
                sphere_mesh,
                .{},
            ),
            .color = sdl.Color.white,
        },
    });
    try scene.root.addChild(sphere_obj);

    try ctx.renderer().setColorRGB(80, 80, 80);
}

pub fn event(ctx: jok.Context, e: sdl.Event) !void {
    _ = ctx;
    _ = e;
}

pub fn update(ctx: jok.Context) !void {
    // camera movement
    const distance = ctx.deltaSeconds() * 10;
    if (ctx.isKeyPressed(.w)) {
        camera.moveBy(.forward, distance);
    }
    if (ctx.isKeyPressed(.s)) {
        camera.moveBy(.backward, distance);
    }
    if (ctx.isKeyPressed(.a)) {
        camera.moveBy(.left, distance);
    }
    if (ctx.isKeyPressed(.d)) {
        camera.moveBy(.right, distance);
    }
    if (ctx.isKeyPressed(.left)) {
        camera.rotateBy(0, -std.math.pi / 180.0);
    }
    if (ctx.isKeyPressed(.right)) {
        camera.rotateBy(0, std.math.pi / 180.0);
    }
    if (ctx.isKeyPressed(.up)) {
        camera.rotateBy(std.math.pi / 180.0, 0);
    }
    if (ctx.isKeyPressed(.down)) {
        camera.rotateBy(-std.math.pi / 180.0, 0);
    }

    scene.root.setTransform(zmath.mul(
        zmath.rotationX(ctx.seconds()),
        zmath.rotationY(ctx.seconds()),
    ));
    sprites[12].actor.sprite.tint_color = sdl.Color.rgb(
        @intFromFloat(127 * (1 + @sin(ctx.seconds()))),
        @intFromFloat(127 * (1 + @cos(ctx.seconds()))),
        100,
    );
    sprites[13].actor.sprite.rotate_degree = ctx.seconds() * 180;
}

pub fn draw(ctx: jok.Context) !void {
    try ctx.renderer().clear();

    try j3d.begin(.{ .camera = camera, .triangle_sort = .simple });
    try j3d.scene(scene, .{ .lighting = .{} });
    try j3d.sprite(
        zmath.translation(10, -10, -30),
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
    try j3d.axises(.{});
    try j3d.end();

    const ogre_pos = camera.calcScreenPosition(ctx.renderer(), sprites[13].transform, null);
    try font.debugDraw(
        ctx,
        .{ .pos = .{ .x = ogre_pos.x + 50, .y = ogre_pos.y } },
        "I have fixed size!",
        .{},
    );
    try font.debugDraw(
        ctx,
        .{ .pos = .{ .x = 20, .y = 10 } },
        "Press WSAD and up/down/left/right to move camera around the view",
        .{},
    );
    try font.debugDraw(
        ctx,
        .{ .pos = .{ .x = 20, .y = 28 } },
        "Camera: pos({d:.3},{d:.3},{d:.3}) dir({d:.3},{d:.3},{d:.3})",
        .{
            // zig fmt: off
            camera.position[0],camera.position[1],camera.position[2],
            camera.dir[0],camera.dir[1],camera.dir[2],
        },
    );
}

pub fn quit(ctx: jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});

    sphere_mesh.deinit();
    sheet.destroy();
    scene.destroy(true);
}

