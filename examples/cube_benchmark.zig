const std = @import("std");
const builtin = @import("builtin");
const jok = @import("jok");
const font = jok.font;
const j3d = jok.j3d;
const physfs = jok.vendor.physfs;
const zmath = jok.vendor.zmath;
const zmesh = jok.vendor.zmesh;

pub const jok_window_size = jok.config.WindowSize{
    .custom = .{ .width = 1280, .height = 720 },
};

pub const jok_fps_limit: jok.config.FpsLimit = .none;
pub const jok_window_resizable = true;

var batchpool: j3d.BatchPool(64, false) = undefined;
var camera: j3d.Camera = undefined;
var cube: zmesh.Shape = undefined;
var aabb: [6]f32 = undefined;
var tex: jok.Texture = undefined;
var translations: std.array_list.Managed(zmath.Mat) = undefined;
var rotation_axises: std.array_list.Managed(zmath.Vec) = undefined;
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
        [_]f32{ 8, 9, -9 },
        [_]f32{ 0, 0, 0 },
    );
    cube = zmesh.Shape.initCube();
    cube.computeNormals();
    cube.texcoords = texcoords[0..];
    aabb = cube.computeAabb();

    tex = try ctx.renderer().createTextureFromFile(
        ctx.allocator(),
        "images/image5.jpg",
        .static,
        false,
    );

    var rng = std.Random.DefaultPrng.init(@intCast(std.time.timestamp()));
    translations = .init(ctx.allocator());
    rotation_axises = .init(ctx.allocator());
    var i: u32 = 0;
    while (i < 5000) : (i += 1) {
        try translations.append(zmath.translation(
            -5 + rng.random().float(f32) * 10,
            -5 + rng.random().float(f32) * 10,
            -5 + rng.random().float(f32) * 10,
        ));
        try rotation_axises.append(zmath.f32x4(
            -1 + rng.random().float(f32) * 2,
            -1 + rng.random().float(f32) * 2,
            -1 + rng.random().float(f32) * 2,
            0,
        ));
    }
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
    ctx.displayStats(.{});

    {
        var b = try batchpool.new(.{
            .camera = camera,
            .triangle_sort = .simple,
        });
        defer b.submit();
        for (translations.items, 0..) |tr, i| {
            b.trs = zmath.mul(
                zmath.translation(-0.5, -0.5, -0.5),
                zmath.mul(
                    zmath.mul(
                        zmath.scaling(0.1, 0.1, 0.1),
                        zmath.matFromAxisAngle(
                            rotation_axises.items[i],
                            std.math.pi / 3.0 * ctx.seconds(),
                        ),
                    ),
                    tr,
                ),
            );
            try b.shape(
                cube,
                aabb,
                .{ .texture = tex },
            );
        }
    }

    ctx.debugPrint(
        "Press WSAD to move around, drag mouse while pressing right-button to rotate the view",
        .{ .pos = .{ .x = 20, .y = 10 } },
    );
}

pub fn quit(ctx: jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});

    cube.deinit();
    translations.deinit();
    rotation_axises.deinit();
    batchpool.deinit();
}
