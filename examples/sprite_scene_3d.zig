const std = @import("std");
const sdl = @import("sdl");
const jok = @import("jok");
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

pub fn init(ctx: *jok.Context) !void {
    std.log.info("game init", .{});

    camera = Camera.fromPositionAndTarget(
        .{
            .perspective = .{
                .fov = std.math.pi / 4.0,
                .aspect_ratio = ctx.getAspectRatio(),
                .near = 0.1,
                .far = 100,
            },
        },
        [_]f32{ 7, 0, -27 },
        [_]f32{ 0, 0, 0 },
        null,
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
    scene = try Scene.create(ctx.allocator, null);
    const angle_step = std.math.tau / @as(f32, 14.0);
    var i: u32 = 0;
    while (i < 12) : (i += 1) {
        const name = try std.fmt.bufPrint(&buf, "image{d}", .{i + 1});
        const sp = try sheet.getSpriteByName(name);
        sprites[i] = try Scene.Object.create(ctx.allocator, .{
            .sprite = .{
                .transform = zmath.mul(
                    zmath.translation(0, 10, 0),
                    zmath.rotationX(angle_step * @intToFloat(f32, i)),
                ),
                .pos = .{ 0, 0, 0 },
                .size = .{ .x = 2, .y = 2 },
                .uv = .{ sp.uv0, sp.uv1 },
                .anchor_point = .{ .x = 0.5, .y = 0.5 },
            },
        });
        try scene.root.addChild(sprites[i]);
    }
    {
        const sp = try sheet.getSpriteByName("ogre");
        sprites[12] = try Scene.Object.create(ctx.allocator, .{
            .sprite = .{
                .transform = zmath.mul(
                    zmath.translation(0, 10, 0),
                    zmath.rotationX(angle_step * 12),
                ),
                .pos = .{ 0, 0, 0 },
                .size = .{ .x = 100, .y = 100 },
                .uv = .{ sp.uv0, sp.uv1 },
                .anchor_point = .{ .x = 0.5, .y = 0.5 },
                .fixed_size = true,
            },
        });
        try scene.root.addChild(sprites[12]);
    }
    {
        const sp = try sheet.getSpriteByName("sphinx");
        sprites[13] = try Scene.Object.create(ctx.allocator, .{
            .sprite = .{
                .transform = zmath.mul(
                    zmath.translation(0, 10, 0),
                    zmath.rotationX(angle_step * 13),
                ),
                .pos = .{ 0, 0, 0 },
                .size = .{ .x = 2, .y = 2 },
                .uv = .{ sp.uv0, sp.uv1 },
                .anchor_point = .{ .x = 0.5, .y = 0.5 },
            },
        });
        try scene.root.addChild(sprites[13]);
    }

    sphere_mesh = jok.zmesh.Shape.initSubdividedSphere(1);
    sphere_obj = try Scene.Object.create(ctx.allocator, .{
        .mesh = .{
            .transform = zmath.identity(),
            .shape = sphere_mesh,
            .color = sdl.Color.white,
        },
    });
    try scene.root.addChild(sphere_obj);

    try ctx.renderer.setColorRGB(80, 80, 80);
}

pub fn event(ctx: *jok.Context, e: sdl.Event) !void {
    _ = ctx;
    _ = e;
}

pub fn update(ctx: *jok.Context) !void {
    // camera movement
    const distance = ctx.delta_tick * 2;
    if (ctx.isKeyPressed(.w)) {
        camera.move(.forward, distance);
    }
    if (ctx.isKeyPressed(.s)) {
        camera.move(.backward, distance);
    }
    if (ctx.isKeyPressed(.a)) {
        camera.move(.left, distance);
    }
    if (ctx.isKeyPressed(.d)) {
        camera.move(.right, distance);
    }
    if (ctx.isKeyPressed(.left)) {
        camera.rotate(0, -std.math.pi / 180.0);
    }
    if (ctx.isKeyPressed(.right)) {
        camera.rotate(0, std.math.pi / 180.0);
    }
    if (ctx.isKeyPressed(.up)) {
        camera.rotate(std.math.pi / 180.0, 0);
    }
    if (ctx.isKeyPressed(.down)) {
        camera.rotate(-std.math.pi / 180.0, 0);
    }

    scene.root.setTransform(zmath.rotationX(@floatCast(f32, ctx.tick)));
    sprites[12].actor.sprite.tint_color = sdl.Color.rgb(
        @floatToInt(u8, 127 * (1 + @sin(@floatCast(f32, ctx.tick)))),
        @floatToInt(u8, 127 * (1 + @cos(@floatCast(f32, ctx.tick)))),
        100,
    );
    sprites[13].actor.sprite.rotate_degree = @floatCast(f32, ctx.tick) * 180;
}

pub fn draw(ctx: *jok.Context) !void {
    try ctx.renderer.copy(
        sheet.tex,
        .{ .x = 0, .y = 0, .width = 200, .height = 200 },
        null,
    );

    scene.clear();
    try scene.draw(ctx.renderer, camera, .{ .texture = sheet.tex, .lighting = .{} });

    const ogre_pos = camera.getScreenPosition(ctx.renderer, sprites[12].transform, sprites[12].actor.sprite.pos);
    _ = try font.debugDraw(
        ctx.renderer,
        .{ .pos = .{ .x = ogre_pos.x + 50, .y = ogre_pos.y } },
        "I have fixed size!",
        .{},
    );
    _ = try font.debugDraw(
        ctx.renderer,
        .{ .pos = .{ .x = 200, .y = 10 } },
        "Press WSAD and up/down/left/right to move camera around the view",
        .{},
    );
    _ = try font.debugDraw(
        ctx.renderer,
        .{ .pos = .{ .x = 200, .y = 28 } },
        "Camera: pos({d:.3},{d:.3},{d:.3}) dir({d:.3},{d:.3},{d:.3})",
        .{
            // zig fmt: off
            camera.position[0],camera.position[1],camera.position[2],
            camera.dir[0],camera.dir[1],camera.dir[2],
        },
    );
}

pub fn quit(ctx: *jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});

    sphere_mesh.deinit();
    sheet.destroy();
    scene.destroy(true);
}

