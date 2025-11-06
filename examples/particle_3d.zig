const std = @import("std");
const builtin = @import("builtin");
const math = std.math;
const jok = @import("jok");
const j2d = jok.j2d;
const j3d = jok.j3d;
const font = jok.font;
const physfs = jok.vendor.physfs;
const zmath = jok.vendor.zmath;
const zmesh = jok.vendor.zmesh;
const zgui = jok.vendor.zgui;

pub const jok_window_size = jok.config.WindowSize{
    .custom = .{ .width = 1280, .height = 720 },
};

var batchpool: j3d.BatchPool(64, false) = undefined;
var rand: std.Random.DefaultPrng = undefined;
var plane: zmesh.Shape = undefined;
var sheet: *j2d.SpriteSheet = undefined;
var ps: *j3d.ParticleSystem = undefined;
var camera: j3d.Camera = undefined;
var sort_by_depth: bool = false;

// fire effect
const emitter1 = j3d.ParticleSystem.Effect.FireEmitter(
    20,
    50,
    3,
    .red,
    .yellow,
    1.75,
);
const emitter2 = j3d.ParticleSystem.Effect.FireEmitter(
    20,
    50,
    3,
    .black,
    .white,
    2.75,
);

pub fn init(ctx: jok.Context) !void {
    std.log.info("game init", .{});

    if (!builtin.cpu.arch.isWasm()) {
        try physfs.mount("assets", "", true);
    }

    batchpool = try @TypeOf(batchpool).init(ctx);
    var thread = std.Io.Threaded.init_single_threaded;
    const io = thread.ioBasic();
    rand = std.Random.DefaultPrng.init(@intCast((try std.Io.Clock.awake.now(io)).toSeconds()));
    plane = zmesh.Shape.initPlane(20, 20);
    sheet = try j2d.SpriteSheet.create(
        ctx,
        &.{
            .{
                .name = "white-circle",
                .image = .{
                    .file_path = "images/white-circle.png",
                },
            },
            .{
                .name = "ogre",
                .image = .{
                    .file_path = "images/ogre.png",
                },
            },
        },
        500,
        500,
        .{},
    );
    ps = try j3d.ParticleSystem.create(ctx.allocator());
    camera = j3d.Camera.fromPositionAndTarget(
        .{
            .perspective = .{
                .fov = std.math.degreesToRadians(45),
                .aspect_ratio = ctx.getAspectRatio(),
                .near = 0.1,
                .far = 1000,
            },
        },
        .{ 150, 150, 150 },
        .{ 0, 0, 0 },
    );
    emitter1.draw_data = j3d.ParticleSystem.DrawData.fromSprite(
        sheet.getSpriteByName("white-circle").?,
        .{ .x = 0.2, .y = 0.2 },
    );
    emitter2.draw_data = j3d.ParticleSystem.DrawData.fromSprite(
        sheet.getSpriteByName("ogre").?,
        .{ .x = 0.2, .y = 0.2 },
    );
    try ps.addEffect(
        rand.random(),
        5000,
        emitter1.emit,
        j3d.Vector.new(0, 0, 0),
        60,
        40,
        0.016,
    );
    try ps.addEffect(
        rand.random(),
        5000,
        emitter2.emit,
        j3d.Vector.new(60, 0, 0),
        60,
        10,
        0.016,
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
    const distance = ctx.deltaSeconds() * 100;
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

    ps.update(ctx.deltaSeconds());
}

pub fn draw(ctx: jok.Context) !void {
    try ctx.renderer().clear(.none);
    ctx.displayStats(.{});

    if (zgui.begin("Control", .{})) {
        _ = zgui.checkbox("sort by depth", .{ .v = &sort_by_depth });
    }
    zgui.end();

    var b = try batchpool.new(.{
        .camera = camera,
        .triangle_sort = if (sort_by_depth) .simple else .none,
    });
    defer b.submit();
    b.trs = zmath.mul(
        zmath.mul(
            zmath.rotationX(-math.pi * 0.5),
            zmath.translation(-0.5, -1.1, 0.5),
        ),
        zmath.scaling(200, 1, 200),
    );
    try b.shape(
        plane,
        null,
        .{
            .color = .rgba(0.4, 0.4, 0.4, 0.8),
            .lighting = .{},
        },
    );
    try b.effects(ps);

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
    ps.destroy();
    sheet.destroy();
    plane.deinit();
    batchpool.deinit();
}
