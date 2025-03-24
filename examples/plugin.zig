const std = @import("std");
const jok = @import("jok");
const imgui = jok.imgui;

pub fn init(ctx: jok.Context) !void {
    _ = ctx;
}

pub fn event(ctx: jok.Context, e: jok.Event) !void {
    _ = ctx;
    _ = e;
}

pub fn update(ctx: jok.Context) !void {
    _ = ctx;
}

pub fn draw(ctx: jok.Context) !void {
    imgui.setNextWindowPos(.{ .x = 100, .y = 300, .cond = .once });
    imgui.setNextWindowSize(.{ .w = 200, .h = 100 });
    if (imgui.begin("I'm Cold Plugin", .{ .flags = .{} })) {
        imgui.text("FPS: {d}", .{ctx.fps()});
        imgui.separator();
    }
    imgui.end();
}

pub fn quit(ctx: jok.Context) void {
    _ = ctx;
}

pub fn getMemory() ?*const anyopaque {
    return null;
}

pub fn reloadMemory(mem: ?*const anyopaque) void {
    _ = mem;
}
