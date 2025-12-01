const std = @import("std");
const builtin = @import("builtin");
const jok = @import("jok");
const j2d = jok.j2d;
const utils = jok.utils;
const PluginType = @import("plugin.zig").PluginType;

pub const jok_window_always_on_top = true;

var batchpool: j2d.BatchPool(64, false) = undefined;
var text_draw_pos: jok.Point = undefined;
var text_speed: j2d.Vector = undefined;
var plugin: *utils.plugin.Plugin(PluginType) = undefined;

pub fn init(ctx: jok.Context) !void {
    std.log.info("game init", .{});

    const csz = ctx.getCanvasSize();

    batchpool = try @TypeOf(batchpool).init(ctx);
    text_draw_pos = csz.toPoint().scale(0.5);
    text_speed = j2d.Vector.new(100, 100);
    plugin = try utils.plugin.Plugin(PluginType).create(
        ctx.allocator(),
        if (builtin.target.os.tag == .windows)
            "./plugin.dll"
        else if (builtin.target.os.tag == .macos)
            "./libplugin.dylib"
        else
            "./libplugin.so",
    );
}

pub fn event(ctx: jok.Context, e: jok.Event) !void {
    _ = ctx;
    _ = e;
}

pub fn update(ctx: jok.Context) !void {
    _ = ctx;

    try plugin.checkAndReload();
}

pub fn draw(ctx: jok.Context) !void {
    try ctx.renderer().clear(.none);
    const csz = ctx.getCanvasSize();

    const whoami = std.mem.sliceTo(plugin.fptrs.whoAreYou(), 0);
    text_speed = text_speed.norm().scale(plugin.fptrs.howFast());
    text_draw_pos.x += text_speed.x() * ctx.deltaSeconds();
    text_draw_pos.y += text_speed.y() * ctx.deltaSeconds();

    var b = try batchpool.new(.{});
    defer b.submit();
    const atlas = try jok.font.DebugFont.getAtlas(ctx, 50);
    try b.text(
        "{s}",
        .{whoami},
        .{
            .atlas = atlas,
            .pos = .{ .x = text_draw_pos.x, .y = text_draw_pos.y },
            .tint_color = .red,
        },
    );
    const area = try atlas.getBoundingBox(
        whoami,
        .{ .x = text_draw_pos.x, .y = text_draw_pos.y },
        .{},
    );
    if (area.x < 0) {
        text_speed = .new(@abs(text_speed.x()), text_speed.y());
    }
    if (area.x + area.width > @as(f32, @floatFromInt(csz.width))) {
        text_speed = .new(-@abs(text_speed.x()), text_speed.y());
    }
    if (area.y < 0) {
        text_speed = .new(text_speed.x(), @abs(text_speed.y()));
    }
    if (area.y + area.height > @as(f32, @floatFromInt(csz.height))) {
        text_speed = .new(text_speed.x(), -@abs(text_speed.y()));
    }
}

pub fn quit(ctx: jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});
    batchpool.deinit();
    plugin.destroy();
}
