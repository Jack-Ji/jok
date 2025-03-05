const std = @import("std");
const jok = @import("jok");
const imgui = jok.imgui;

export fn init(ctx: *const jok.Context) void {
    _ = ctx;
}

export fn deinit(ctx: *const jok.Context) void {
    _ = ctx;
}

export fn event(ctx: *const jok.Context, e: *const jok.Event) void {
    _ = ctx;
    _ = e;
}

export fn update(ctx: *const jok.Context) void {
    _ = ctx;
}

export fn draw(ctx: *const jok.Context) void {
    imgui.setNextWindowPos(.{ .x = 100, .y = 300, .cond = .once });
    imgui.setNextWindowSize(.{ .w = 200, .h = 100 });
    if (imgui.begin("I'm Cold Plugin", .{ .flags = .{} })) {
        imgui.text("FPS: {d}", .{ctx.fps()});
        imgui.separator();
    }
    imgui.end();
}

export fn get_memory() ?*const anyopaque {
    return null;
}

export fn reload_memory(mem: ?*const anyopaque) void {
    _ = mem;
}
