const std = @import("std");
const builtin = @import("builtin");
const jok = @import("jok");
const j2d = jok.j2d;
const geom = j2d.geom;
const font = jok.font;
const physfs = jok.vendor.physfs;

var lua: jok.utils.scripting.Lua = undefined;
var batchpool: j2d.BatchPool(64, false) = undefined;
var text_draw_pos: geom.Point = undefined;
var text_speed: geom.Point = undefined;

const Engine = struct {
    pub fn drawCircle(x: f32, y: f32, r: f32) !void {
        var b = try batchpool.new(.{});
        defer b.submit();
        b.translate(.{ x, y });
        try b.circleFilled(.{ .radius = r }, .white, .{});
    }
};

pub fn init(ctx: jok.Context) !void {
    std.log.info("game init", .{});

    if (!builtin.cpu.arch.isWasm()) {
        try physfs.mount("assets", "", true);
    }

    const csz = ctx.getCanvasSize();
    lua = try jok.utils.scripting.Lua.init(ctx.allocator());
    try lua.registerTypes(&[_]jok.utils.scripting.BoundType{
        .{
            .Type = Engine,
            .name = "Engine",
        },
    });
    batchpool = try @TypeOf(batchpool).init(ctx);
    text_draw_pos = csz.toPoint().scale(0.5);
    text_speed = .{ .x = 100, .y = 100 };
}

pub fn event(ctx: jok.Context, e: jok.Event) !void {
    _ = ctx;
    _ = e;
}

pub fn update(ctx: jok.Context) !void {
    const S = struct {
        var time_to_reload: f32 = 0;
    };

    const f = try physfs.open("game.lua", .read);
    defer f.close();

    if (ctx.seconds() >= S.time_to_reload) {
        const code = try ctx.allocator().alloc(u8, try f.length() + 1);
        @memset(code, 0);
        defer ctx.allocator().free(code);

        _ = try f.read(code);
        lua.runString(code[0 .. code.len - 1 :0]) catch {};

        S.time_to_reload = ctx.seconds() + 1.0;
    }
}

pub fn draw(ctx: jok.Context) !void {
    try ctx.renderer().clear(.none);

    var b = try batchpool.new(.{});
    defer b.submit();

    const csz = ctx.getCanvasSize();
    const atlas = try font.DebugFont.getAtlas(ctx, 50);
    text_draw_pos = text_draw_pos.add(text_speed.scale(ctx.deltaSeconds()));
    const text_context = try lua.callFunction([:0]const u8, "whoami", .{});
    try b.text(
        "{s}",
        .{text_context},
        .{
            .atlas = atlas,
            .pos = .{ .x = text_draw_pos.x, .y = text_draw_pos.y },
            .tint_color = .red,
        },
    );
    const area = try atlas.getBoundingBox(
        text_context,
        .{ .x = text_draw_pos.x, .y = text_draw_pos.y },
        .{},
    );
    if (area.x < 0) {
        text_speed.x = @abs(text_speed.x);
    }
    if (area.x + area.width > @as(f32, @floatFromInt(csz.width))) {
        text_speed.x = -@abs(text_speed.x);
    }
    if (area.y < 0) {
        text_speed.y = @abs(text_speed.y);
    }
    if (area.y + area.height > @as(f32, @floatFromInt(csz.height))) {
        text_speed.y = -@abs(text_speed.y);
    }

    try lua.callFunction(void, "draw", .{ctx.seconds()});
}

pub fn quit(ctx: jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});
    lua.deinit();
    batchpool.deinit();
}
