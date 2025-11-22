const std = @import("std");
const builtin = @import("builtin");
const jok = @import("jok");
const j2d = jok.j2d;
const AffineTransform = j2d.AffineTransform;
const physfs = jok.vendor.physfs;

var batchpool: j2d.BatchPool(64, false) = undefined;
var sheet: *j2d.SpriteSheet = undefined;
var scene: *j2d.Scene = undefined;
var ogre1: *j2d.Scene.Object = undefined;
var ogre2: *j2d.Scene.Object = undefined;
var prim: *j2d.Scene.Object = undefined;
var orbit: *j2d.Scene.Object = undefined;

pub fn init(ctx: jok.Context) !void {
    std.log.info("game init", .{});

    if (!builtin.cpu.arch.isWasm()) {
        try physfs.mount("assets", "", true);
    }

    batchpool = try @TypeOf(batchpool).init(ctx);

    // create sprite sheet
    const size = ctx.getCanvasSize();
    sheet = try j2d.SpriteSheet.fromPicturesInDir(
        ctx,
        "images",
        @intFromFloat(size.getWidthFloat()),
        @intFromFloat(size.getHeightFloat()),
        .{},
    );
    scene = try j2d.Scene.create(ctx.allocator());
    ogre1 = try j2d.Scene.Object.create(ctx.allocator(), .{
        .sprite = .{
            .transform = .init,
            .sp = sheet.getSpriteByName("ogre").?,
            .tint_color = .red,
            .anchor_point = .anchor_center,
        },
    }, null);
    ogre2 = try j2d.Scene.Object.create(ctx.allocator(), .{
        .sprite = .{
            .transform = AffineTransform.init.scaleAroundOrigin(.{ 0.5, 0.5 }),
            .sp = sheet.getSpriteByName("ogre").?,
            .anchor_point = .anchor_center,
        },
    }, null);
    prim = try j2d.Scene.Object.create(
        ctx.allocator(),
        .{ .primitive = .{ .dcmd = .{ .circle = .{
            .p = .origin,
            .color = jok.Color.white.toInternalColor(),
            .radius = 50,
            .thickness = 2,
            .num_segments = 100,
        } } } },
        null,
    );
    orbit = try j2d.Scene.Object.create(
        ctx.allocator(),
        .{ .position = .{} },
        null,
    );
    try ogre1.addChild(prim);
    try ogre1.addChild(orbit);
    try orbit.addChild(ogre2);
    try scene.root.addChild(ogre1);
}

pub fn event(ctx: jok.Context, e: jok.Event) !void {
    _ = ctx;
    _ = e;
}

pub fn update(ctx: jok.Context) !void {
    ogre1.setTransform(
        AffineTransform.init.scaleAroundOrigin(
            .{ 4 + 2 * @cos(ctx.seconds()), 4 + 2 * @cos(ctx.seconds()) },
        ).rotateByOrigin(ctx.seconds() / 2).translate(.{ 400, 300 }),
    );
    orbit.setTransform(AffineTransform.init.rotateByOrigin(ctx.seconds() * 5).translateX(50));
}

pub fn draw(ctx: jok.Context) !void {
    try ctx.renderer().clear(.rgb(77, 77, 77));

    var b = try batchpool.new(.{});
    defer b.submit();
    try b.image(sheet.tex, .origin, .{});
    try b.scene(scene);
}

pub fn quit(ctx: jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});
    sheet.destroy();
    scene.destroy(true);
    batchpool.deinit();
}
