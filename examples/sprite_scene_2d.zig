const std = @import("std");
const builtin = @import("builtin");
const jok = @import("jok");
const j2d = jok.j2d;
const geom = j2d.geom;
const font = jok.font;
const AffineTransform = j2d.AffineTransform;
const physfs = jok.vendor.physfs;

var batchpool: j2d.BatchPool(64, false) = undefined;
var sheet: *j2d.SpriteSheet = undefined;
var scene: *j2d.Scene = undefined;
var ogre1: *j2d.Scene.Object = undefined;
var ogre2: *j2d.Scene.Object = undefined;
var text: *j2d.Scene.Object = undefined;
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
        if (ctx.cfg().jok_enable_physfs) "images" else "assets/images",
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
            .radius = 200,
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
    text = try j2d.Scene.Object.create(ctx.allocator(), .{
        .text = .{
            .content = "Ogre is here!",
            .atlas = try font.DebugFont.getAtlas(ctx, 16),
            .transform = AffineTransform.identity.translate(.{ 20, 20 }),
            .ypos_type = .bottom,
            .tint_color = .white,
            .align_width = 50,
            .scale = geom.Point.unit.scale(0.5),
        },
    }, null);
    try ogre1.addChild(text);
    try prim.addChild(orbit);
    try orbit.addChild(ogre2);
    try scene.root.addChild(prim);
    try scene.root.addChild(ogre1);
}

pub fn event(ctx: jok.Context, e: jok.Event) !void {
    _ = ctx;
    _ = e;
}

pub fn update(ctx: jok.Context) !void {
    scene.root.setTransform(AffineTransform.init.translate(.{ 400, 300 }));
    ogre1.setTransform(
        AffineTransform.init.scaleAroundOrigin(
            .{ 4 + 2 * @cos(ctx.seconds()), 4 + 2 * @cos(ctx.seconds()) },
        ),
    );
    prim.setTransform(
        AffineTransform.init.rotateByOrigin(ctx.seconds()),
    );
    orbit.setTransform(
        AffineTransform.init.scaleAroundOrigin(.{ 4, 4 }).rotateByOrigin(ctx.seconds() * 5).translateX(200),
    );
}

pub fn draw(ctx: jok.Context) !void {
    try ctx.renderer().clear(.rgb(77, 77, 77));

    var b = try batchpool.new(.{});
    defer b.submit();
    try b.image(sheet.tex, .origin, .{});
    try b.scene(scene);
    try b.rect(ogre1.getTransformedBounds(.identity), .black, .{});
    try b.rect(text.getTransformedBounds(.identity), .black, .{});
}

pub fn quit(ctx: jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});
    sheet.destroy();
    scene.destroy(true);
    batchpool.deinit();
}
