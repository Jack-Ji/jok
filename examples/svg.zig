const std = @import("std");
const builtin = @import("builtin");
const jok = @import("jok");
const physfs = jok.physfs;
const font = jok.font;
const j2d = jok.j2d;

var batchpool: j2d.BatchPool(64, false) = undefined;
var svg: jok.svg.SvgBitmap = undefined;
var tex: jok.Texture = undefined;

pub fn init(ctx: jok.Context) !void {
    std.log.info("game init", .{});

    if (!builtin.cpu.arch.isWasm()) {
        try physfs.mount("assets", "/", true);
    }

    batchpool = try @TypeOf(batchpool).init(ctx);

    svg = try jok.svg.createBitmapFromFile(
        ctx.allocator(),
        "tiger.svg",
        .{},
    );

    tex = try ctx.renderer().createTexture(svg.size, svg.pixels, .{});
}

pub fn event(ctx: jok.Context, e: jok.Event) !void {
    _ = ctx;
    _ = e;
}

pub fn update(ctx: jok.Context) !void {
    _ = ctx;
}

pub fn draw(ctx: jok.Context) !void {
    try ctx.renderer().clear(.rgb(100, 100, 100));

    var b = try batchpool.new(.{});
    defer b.submit();
    try b.image(
        tex,
        .{
            .x = ctx.getCanvasSize().getWidthFloat() / 2,
            .y = ctx.getCanvasSize().getHeightFloat() / 2,
        },
        .{
            .rotate_angle = ctx.seconds(),
            .scale = .{
                .x = 0.8 + @cos(ctx.seconds()) * 0.5,
                .y = 0.8 + @cos(ctx.seconds()) * 0.5,
            },
            .anchor_point = .anchor_center,
        },
    );
}

pub fn quit(ctx: jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});

    svg.destroy();
    tex.destroy();
    batchpool.deinit();
}
