const std = @import("std");
const builtin = @import("builtin");
const jok = @import("jok");
const imgui = jok.imgui;

pub const jok_window_always_on_top = true;

pub fn init(ctx: jok.Context) !void {
    try jok.physfs.mount("assets", "/", true);
    if (builtin.target.os.tag == .windows) {
        try ctx.registerPlugin("plugin_hot", "./plugin_hot.dll", true);
        try ctx.registerPlugin("plugin", "./plugin.dll", false);
    } else if (builtin.target.os.tag == .macos) {
        try ctx.registerPlugin("plugin_hot", "./libplugin_hot.dylib", true);
        try ctx.registerPlugin("plugin", "./libplugin.dylib", false);
    } else {
        try ctx.registerPlugin("plugin_hot", "./libplugin_hot.so", true);
        try ctx.registerPlugin("plugin", "./libplugin.so", false);
    }
}

pub fn event(ctx: jok.Context, e: jok.Event) !void {
    // your event processing code
    _ = ctx;
    _ = e;
}

pub fn update(ctx: jok.Context) !void {
    // your game state updating code
    _ = ctx;
}

pub fn draw(ctx: jok.Context) !void {
    try ctx.renderer().clear(.none);

    if (imgui.begin("Main Control", .{ .flags = .{ .always_auto_resize = true } })) {
        if (imgui.button("Reload Hot Plugin", .{})) {
            try ctx.forceReloadPlugin("plugin_hot");
        }
        if (imgui.button("Reload Cold Plugin", .{})) {
            try ctx.forceReloadPlugin("plugin");
        }
    }
    imgui.end();
}

pub fn quit(ctx: jok.Context) void {
    // your deinit code
    _ = ctx;
}
