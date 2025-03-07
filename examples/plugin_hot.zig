const std = @import("std");
const jok = @import("jok");
const j2d = jok.j2d;
const j3d = jok.j3d;
const zmesh = jok.zmesh;
const zmath = jok.zmath;
const imgui = jok.imgui;

const GameState = struct {
    batchpool_2d: j2d.BatchPool(64, false),
    batchpool_3d: j3d.BatchPool(64, false),
    sheet: *j2d.SpriteSheet,
    shape_tetrahedron: zmesh.Shape,

    fn create(ctx: jok.Context) !*GameState {
        const s = try ctx.allocator().create(GameState);
        s.* = .{
            .batchpool_2d = try j2d.BatchPool(64, false).init(ctx),
            .batchpool_3d = try j3d.BatchPool(64, false).init(ctx),
            .sheet = try j2d.SpriteSheet.fromPicturesInDir(ctx, "images", 1024, 1024, .{}),
            .shape_tetrahedron = BLK: {
                var sh = zmesh.Shape.initTetrahedron();
                sh.scale(0.1, 0.1, 0.1);
                sh.computeNormals();
                break :BLK sh;
            },
        };
        return s;
    }

    fn destroy(self: *GameState, ctx: jok.Context) void {
        self.batchpool_2d.deinit();
        self.batchpool_3d.deinit();
        self.sheet.destroy();
        self.shape_tetrahedron.deinit();
        ctx.allocator().destroy(self);
    }
};

var state: *GameState = undefined;

export fn init(ctx: *const jok.Context) void {
    state = GameState.create(ctx.*) catch unreachable;
}

export fn deinit(ctx: *const jok.Context) void {
    state.destroy(ctx.*);
}

export fn event(ctx: *const jok.Context, e: *const jok.Event) void {
    _ = ctx;
    _ = e;
}

export fn update(ctx: *const jok.Context) void {
    _ = ctx;
}

fn scene2d(ctx: jok.Context) !void {
    _ = ctx;

    var b = try state.batchpool_2d.new(.{});
    defer b.submit();

    try b.image(
        state.sheet.tex,
        .{ .x = 0, .y = 0 },
        .{ .depth = 1 },
    );
    try b.sprite(state.sheet.getSpriteByName("ogre").?, .{
        .pos = .{ .x = 400, .y = 300 },
        .scale = .{ .x = 2, .y = 2 },
    });
}

fn scene3d(ctx: jok.Context) !void {
    var b = try state.batchpool_3d.new(.{
        .wireframe_color = .green,
    });
    defer b.submit();

    b.rotateX(0.1);
    b.rotateY(ctx.seconds());
    b.translate(0, -0.2, 0);
    try b.shape(state.shape_tetrahedron, null, .{
        .cull_faces = false,
    });
}

export fn draw(ctx: *const jok.Context) void {
    imgui.setNextWindowPos(.{ .x = 500, .y = 400, .cond = .once });
    imgui.setNextWindowSize(.{ .w = 200, .h = 100 });
    if (imgui.begin("I'm Hot Plugin", .{})) {
        imgui.text("Seconds: {d:.2}", .{ctx.seconds()});
        imgui.separator();
    }
    imgui.end();

    scene2d(ctx.*) catch unreachable;
    scene3d(ctx.*) catch unreachable;
}

export fn get_memory() ?*const anyopaque {
    return state;
}

export fn reload_memory(mem: ?*const anyopaque) void {
    state = @constCast(@alignCast(@ptrCast(mem.?)));
}
