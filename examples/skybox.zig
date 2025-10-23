const std = @import("std");
const builtin = @import("builtin");
const jok = @import("jok");
const font = jok.font;
const j3d = jok.j3d;
const physfs = jok.vendor.physfs;
const zgui = jok.vendor.zgui;
const zmath = jok.vendor.zmath;
const zmesh = jok.vendor.zmesh;

var batchpool: j3d.BatchPool(64, false) = undefined;
var camera: j3d.Camera = undefined;
var cube: zmesh.Shape = undefined;
var tex: jok.Texture = undefined;
var texcoords = [_][2]f32{
    .{ 0, 1 },
    .{ 0, 0 },
    .{ 1, 0 },
    .{ 1, 1 },
    .{ 1, 1 },
    .{ 0, 1 },
    .{ 0, 0 },
    .{ 1, 0 },
};
var skybox_textures: [6]jok.Texture = undefined;
var skybox_tint_color: jok.ColorF = .white;

pub fn init(ctx: jok.Context) !void {
    std.log.info("game init", .{});

    if (!builtin.cpu.arch.isWasm()) {
        try physfs.mount("assets", "", true);
    }

    batchpool = try @TypeOf(batchpool).init(ctx);

    camera = j3d.Camera.fromPositionAndTarget(
        .{
            //.orthographic = .{
            //    .width = 2 * ctx.getAspectRatio(),
            //    .height = 2,
            //    .near = 0.1,
            //    .far = 100,
            //},
            .perspective = .{
                .fov = std.math.pi / 4.0,
                .aspect_ratio = ctx.getAspectRatio(),
                .near = 0.1,
                .far = 100,
            },
        },
        [_]f32{ 0, 1, -2 },
        [_]f32{ 0, 0, 0 },
    );
    cube = zmesh.Shape.initCube();
    cube.computeNormals();
    cube.texcoords = texcoords[0..];
    tex = try ctx.renderer().createTextureFromFile(
        ctx.allocator(),
        "images/image5.jpg",
        .static,
        false,
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
}

pub fn event(ctx: jok.Context, e: jok.Event) !void {
    const S = struct {
        var is_viewing: bool = false;
        const mouse_speed: f32 = 0.0025;
    };

    switch (e) {
        .mouse_button_down => |me| {
            if (me.button == .right) {
                try ctx.window().setRelativeMouseMode(true);
                S.is_viewing = true;
            }
        },
        .mouse_button_up => |me| {
            if (me.button == .right) {
                try ctx.window().setRelativeMouseMode(false);
                S.is_viewing = false;
            }
        },
        .mouse_motion => |me| {
            if (S.is_viewing) {
                camera.rotateBy(
                    S.mouse_speed * me.delta.y,
                    S.mouse_speed * me.delta.x,
                );
            }
        },
        else => {},
    }
}

pub fn update(ctx: jok.Context) !void {
    // camera movement
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
}

pub fn draw(ctx: jok.Context) !void {
    try ctx.renderer().clear(.rgb(77, 77, 77));

    if (zgui.begin("Tint Color", .{})) {
        var cs: [3]f32 = .{ skybox_tint_color.r, skybox_tint_color.g, skybox_tint_color.b };
        if (zgui.colorEdit3("Tint Color", .{ .col = &cs })) {
            skybox_tint_color.r = cs[0];
            skybox_tint_color.g = cs[1];
            skybox_tint_color.b = cs[2];
        }
    }
    zgui.end();

    var b = try batchpool.new(.{ .camera = camera, .triangle_sort = .simple });
    b.trs = zmath.mul(
        zmath.translation(-0.5, -0.5, -0.5),
        zmath.mul(
            zmath.scaling(0.5, 0.5, 0.5),
            zmath.rotationY(ctx.seconds() * std.math.pi),
        ),
    );
    try b.shape(
        cube,
        null,
        .{ .texture = tex },
    );
    try b.skybox(skybox_textures, skybox_tint_color);
    b.submit();

    ctx.debugPrint(
        "Press WSAD to move around, drag mouse while pressing right-button to rotate the view",
        .{ .pos = .{ .x = 20, .y = 10 } },
    );
    ctx.debugPrint(
        zgui.format(
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

    cube.deinit();
    batchpool.deinit();
}
