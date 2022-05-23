const std = @import("std");
const sdl = @import("sdl");
const jok = @import("jok");
const gfx = jok.gfx.@"3d";

var camera: gfx.Camera = undefined;
var renderer: gfx.Renderer = undefined;

fn init(ctx: *jok.Context) anyerror!void {
    std.log.info("game init", .{});

    gfx.zmesh.init(ctx.default_allocator);
    const size = ctx.getFramebufferSize();

    camera = gfx.Camera.fromPositionAndTarget(
        .{
            .perspective = .{
                .fov = std.math.pi / 4.0,
                .aspect_ratio = @intToFloat(f32, size.w) / @intToFloat(f32, size.h),
                .near = 0.1,
                .far = 100,
            },
        },
        gfx.zmath.f32x4(0, -2, -2, 1),
        gfx.zmath.f32x4(0, 0, 0, 1),
        null,
    );
    renderer = gfx.Renderer.init(ctx.default_allocator);
    var cube = gfx.zmesh.Shape.initCube();
    defer cube.deinit();
    try renderer.appendVertex(
        ctx.renderer,
        gfx.zmath.identity(),
        &camera,
        cube.indices,
        cube.positions,
        null,
        null,
    );
}

fn loop(ctx: *jok.Context) anyerror!void {
    while (ctx.pollEvent()) |e| {
        switch (e) {
            .keyboard_event => |key| {
                if (key.trigger_type == .up) {
                    switch (key.scan_code) {
                        .escape => ctx.kill(),
                        else => {},
                    }
                }
            },
            .quit_event => ctx.kill(),
            else => {},
        }
    }

    try ctx.renderer.setColorRGB(77, 77, 77);
    try ctx.renderer.clear();
    try renderer.render(ctx.renderer, null);
}

fn quit(ctx: *jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});

    gfx.zmesh.deinit();
    renderer.deinit();
}

pub fn main() anyerror!void {
    try jok.run(.{
        .initFn = init,
        .loopFn = loop,
        .quitFn = quit,
    });
}
