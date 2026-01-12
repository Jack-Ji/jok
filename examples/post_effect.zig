const std = @import("std");
const builtin = @import("builtin");
const jok = @import("jok");
const j2d = jok.j2d;
const j3d = jok.j3d;
const zgui = jok.vendor.zgui;
const physfs = jok.vendor.physfs;

pub const jok_window_size = jok.config.WindowSize{
    .custom = .{ .width = 1200, .height = 900 },
};

var batchpool_2d: j2d.BatchPool(64, false) = undefined;
var batchpool_3d: j3d.BatchPool(64, false) = undefined;
var sheet: *j2d.SpriteSheet = undefined;
var camera: j3d.Camera = undefined;
var mesh: *j3d.Mesh = undefined;
var shader: jok.PixelShader = undefined;

const CrtEffectParameter = extern struct {
    width: f32,
    height: f32,
    scan_line_amount: f32 = 0.5, // Range 0-1
    warp_amount: f32 = 0.05, // Range 0-1
    vignette_amount: f32 = 0.5, // Range 0-1
    vignette_intensity: f32 = 0.3, // Range 0-1
    grille_amount: f32 = 0.05, // Range 0-1
    brightness_boost: f32 = 1.2, // Range 1-2
};

var crt: CrtEffectParameter = undefined;
var enable_post_effect: bool = false;

pub fn init(ctx: jok.Context) !void {
    std.log.info("game init", .{});

    try physfs.mount("assets", "", true);

    batchpool_2d = try @TypeOf(batchpool_2d).init(ctx);
    batchpool_3d = try @TypeOf(batchpool_3d).init(ctx);

    // create sprite sheet1
    const size = ctx.getCanvasSize();
    sheet = try j2d.SpriteSheet.fromPicturesInDir(
        ctx,
        if (ctx.cfg().jok_enable_physfs) "images" else "assets/images",
        @intFromFloat(size.getWidthFloat()),
        @intFromFloat(size.getHeightFloat()),
        .{},
    );
    camera = j3d.Camera.fromPositionAndTarget(
        .{
            .perspective = .{
                .fov = std.math.degreesToRadians(70),
                .aspect_ratio = ctx.getAspectRatio(),
                .near = 0.1,
                .far = 1000,
            },
        },
        [_]f32{ 7, 4.1, 7 },
        [_]f32{ 0, 0, 0 },
    );
    mesh = try j3d.Mesh.fromObj(
        ctx,
        if (ctx.cfg().jok_enable_physfs) "models/akira.obj" else "assets/models/akira.obj",
        if (ctx.cfg().jok_enable_physfs) "models/akira.mtl" else "assets/models/akira.mtl",
        .{},
    );
    shader = try ctx.loadShader(
        if (ctx.cfg().jok_enable_physfs)
            switch (builtin.os.tag) {
                .windows => "shaders/crt.dxil",
                .macos => "shaders/crt.msl",
                .linux => "shaders/crt.spv",
                else => unreachable,
            }
        else switch (builtin.os.tag) {
            .windows => "assets/shaders/crt.dxil",
            .macos => "assets/shaders/crt.msl",
            .linux => "assets/shaders/crt.spv",
            else => unreachable,
        },
        null,
        null,
    );

    const csz = ctx.getCanvasSize();
    crt = .{
        .width = csz.getWidthFloat(),
        .height = csz.getHeightFloat(),
    };
}

pub fn event(ctx: jok.Context, e: jok.Event) !void {
    _ = ctx;
    _ = e;
}

pub fn update(ctx: jok.Context) !void {
    _ = ctx;
}

pub fn draw(ctx: jok.Context) !void {
    try ctx.renderer().clear(.rgb(77, 77, 77));

    if (zgui.begin("Control Panel", .{ .flags = .{
        .always_auto_resize = true,
    } })) {
        _ = zgui.checkbox("Enable Post Effect", .{ .v = &enable_post_effect });
        if (enable_post_effect) {
            _ = zgui.dragFloat("scan line amount", .{ .v = &crt.scan_line_amount, .min = 0, .max = 1, .speed = 0.001 });
            _ = zgui.dragFloat("warp amount", .{ .v = &crt.warp_amount, .min = 0, .max = 1, .speed = 0.001 });
            _ = zgui.dragFloat("vignette amount", .{ .v = &crt.vignette_amount, .min = 0, .max = 1, .speed = 0.001 });
            _ = zgui.dragFloat("vignette intensity", .{ .v = &crt.vignette_intensity, .min = 0, .max = 1, .speed = 0.001 });
            _ = zgui.dragFloat("grille amount", .{ .v = &crt.grille_amount, .min = 0, .max = 1, .speed = 0.001 });
            _ = zgui.dragFloat("brightness boost", .{ .v = &crt.brightness_boost, .min = 1, .max = 2, .speed = 0.001 });
        }
    }
    zgui.end();

    if (enable_post_effect) {
        ctx.setPostEffect(shader);
        try shader.setUniform(0, crt);
    } else {
        ctx.setPostEffect(null);
    }
    {
        var b = try batchpool_3d.new(.{
            .camera = camera,
            .triangle_sort = .simple,
        });
        defer b.submit();
        b.setIdentity();
        b.scale(.{ 0.8, 0.8, 0.8 });
        b.rotateY(ctx.seconds());
        b.translate(.{ -3, -3, 3 });
        try b.mesh(
            mesh,
            .{},
        );
    }

    {
        const sprite = sheet.getSpriteByName("image3").?;
        var b = try batchpool_2d.new(.{});
        defer b.submit();
        try b.sprite(sprite, .{
            .pos = .{ .x = 400, .y = 50 },
            .scale = .{ .x = 2, .y = 2 },
        });
    }
}

pub fn quit(ctx: jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});
    shader.destroy();
    sheet.destroy();
    mesh.destroy();
    batchpool_2d.deinit();
    batchpool_3d.deinit();
}
