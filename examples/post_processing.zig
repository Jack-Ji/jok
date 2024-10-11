const std = @import("std");
const jok = @import("jok");
const sdl = jok.sdl;
const physfs = jok.physfs;
const j3d = jok.j3d;

pub const jok_window_resizable = true;
pub const jok_canvas_size = sdl.Size{ .width = 320, .height = 180 };
pub const jok_post_processing_size: sdl.Size = jok_canvas_size;

var camera: j3d.Camera = undefined;
var skybox_textures: [6]sdl.Texture = undefined;
var appctx: jok.Context = undefined;

fn ppCallback(pos: sdl.PointF, data: ?*anyopaque) ?sdl.Color {
    _ = data;
    const t = appctx.seconds();
    return sdl.Color{
        .r = @intFromFloat((1.0 + @cos(t * pos.x)) * 125),
        .g = @intFromFloat((1.0 + @sin(t * pos.y)) * 125),
        .b = @intFromFloat((1.0 + @sin(t * pos.x * pos.y)) * 125),
        .a = 1,
    };
}

pub fn init(ctx: jok.Context) !void {
    std.log.info("game init", .{});

    try physfs.mount("assets", "", true);

    appctx = ctx;
    camera = j3d.Camera.fromPositionAndTarget(
        .{
            .perspective = .{
                .fov = std.math.pi / 4.0,
                .aspect_ratio = ctx.getAspectRatio(),
                .near = 0.1,
                .far = 100,
            },
        },
        [_]f32{ 0, 0, 0 },
        [_]f32{ 0, 0, 1 },
    );
    skybox_textures[0] = try jok.utils.gfx.createTextureFromFile(
        ctx,
        "images/skybox/right.jpg",
        .static,
        true,
    );
    skybox_textures[1] = try jok.utils.gfx.createTextureFromFile(
        ctx,
        "images/skybox/left.jpg",
        .static,
        true,
    );
    skybox_textures[2] = try jok.utils.gfx.createTextureFromFile(
        ctx,
        "images/skybox/top.jpg",
        .static,
        true,
    );
    skybox_textures[3] = try jok.utils.gfx.createTextureFromFile(
        ctx,
        "images/skybox/bottom.jpg",
        .static,
        true,
    );
    skybox_textures[4] = try jok.utils.gfx.createTextureFromFile(
        ctx,
        "images/skybox/front.jpg",
        .static,
        true,
    );
    skybox_textures[5] = try jok.utils.gfx.createTextureFromFile(
        ctx,
        "images/skybox/back.jpg",
        .static,
        true,
    );

    ctx.setPostProcessing(ppCallback, null);
}

pub fn event(ctx: jok.Context, e: sdl.Event) !void {
    _ = ctx;
    _ = e;
}

pub fn update(ctx: jok.Context) !void {
    const distance = ctx.deltaSeconds() * 2;
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
}

pub fn draw(ctx: jok.Context) !void {
    ctx.clear(sdl.Color.white);

    j3d.begin(.{ .camera = camera });
    defer j3d.end();
    try j3d.skybox(skybox_textures, null);

    ctx.displayStats(.{});
}

pub fn quit(ctx: jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});
}
