const std = @import("std");
const builtin = @import("builtin");
const jok = @import("jok");
const j3d = jok.j3d;
const physfs = jok.vendor.physfs;

pub const jok_window_resizable = true;
pub const jok_canvas_size = jok.Size{ .width = 320, .height = 180 };
pub const jok_enable_post_processing = true;

var batchpool: j3d.BatchPool(64, false) = undefined;
var camera: j3d.Camera = undefined;
var skybox_textures: [6]jok.Texture = undefined;
var appctx: jok.Context = undefined;

fn ppCallback(pos: jok.Point, _: ?*anyopaque, _: ?*anyopaque) ?jok.ColorF {
    const t = appctx.seconds();
    return jok.ColorF{
        .r = 1 + @cos(t * pos.x) * 0.5,
        .g = 1 + @sin(t * pos.y) * 0.5,
        .b = 1 + @sin(t * pos.x * pos.y) * 0.5,
        .a = 1,
    };
}

pub fn init(ctx: jok.Context) !void {
    std.log.info("game init", .{});

    if (!builtin.cpu.arch.isWasm()) {
        try physfs.mount("assets", "", true);
    }

    batchpool = try @TypeOf(batchpool).init(ctx);

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
    skybox_textures[0] = try ctx.renderer().createTextureFromFile(
        ctx.allocator(),
        "images/skybox/right.jpg",
        .static,
        true,
    );
    skybox_textures[1] = try ctx.renderer().createTextureFromFile(
        ctx.allocator(),
        "images/skybox/left.jpg",
        .static,
        true,
    );
    skybox_textures[2] = try ctx.renderer().createTextureFromFile(
        ctx.allocator(),
        "images/skybox/top.jpg",
        .static,
        true,
    );
    skybox_textures[3] = try ctx.renderer().createTextureFromFile(
        ctx.allocator(),
        "images/skybox/bottom.jpg",
        .static,
        true,
    );
    skybox_textures[4] = try ctx.renderer().createTextureFromFile(
        ctx.allocator(),
        "images/skybox/front.jpg",
        .static,
        true,
    );
    skybox_textures[5] = try ctx.renderer().createTextureFromFile(
        ctx.allocator(),
        "images/skybox/back.jpg",
        .static,
        true,
    );

    try ctx.addPostProcessing(.{
        .ppfn = ppCallback,
        .region = .{
            .x = 50,
            .y = 50,
            .width = 100,
            .height = 50,
        },
    });
    try ctx.addPostProcessing(.{
        .ppfn = ppCallback,
        .region = .{
            .x = 200,
            .y = 100,
            .width = 120,
            .height = 80,
        },
    });
}

pub fn event(ctx: jok.Context, e: jok.Event) !void {
    _ = ctx;
    _ = e;
}

pub fn update(ctx: jok.Context) !void {
    const distance = ctx.deltaSeconds() * 2;
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
}

pub fn draw(ctx: jok.Context) !void {
    try ctx.renderer().clear(.white);

    var b = try batchpool.new(.{ .camera = camera });
    defer b.submit();
    try b.skybox(skybox_textures, null);

    ctx.displayStats(.{});
}

pub fn quit(ctx: jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});
    batchpool.deinit();
}
