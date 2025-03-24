const std = @import("std");
const jok = @import("jok");
const plugin = @import("plugin");
const compcheck = @import("compcheck.zig");
const log = std.log.scoped(.jok);

// Validate plugin object
comptime {
    compcheck.doPluginCheck(plugin);
}

export fn init(ctx: *const jok.Context, name: [*:0]const u8) bool {
    plugin.init(ctx.*) catch |err| {
        log.err("Plugin({s}) init failed: {}", .{ name, err });
        if (@errorReturnTrace()) |trace| std.debug.dumpStackTrace(trace.*);
        return false;
    };
    log.info("Plugin({s}) initialized", .{name});
    return true;
}

export fn deinit(ctx: *const jok.Context, name: [*:0]const u8) void {
    plugin.quit(ctx.*);
    log.info("Plugin({s}) destroyed", .{name});
}

export fn event(ctx: *const jok.Context, e: *const jok.Event, name: [*:0]const u8) void {
    plugin.event(ctx.*, e.*) catch |err| {
        log.err("Plugin({s}) process event failed: {}", .{ err, name });
        if (@errorReturnTrace()) |trace| std.debug.dumpStackTrace(trace.*);
    };
}

export fn update(ctx: *const jok.Context, name: [*:0]const u8) void {
    plugin.update(ctx.*) catch |err| {
        log.err("Plugin({s}) update failed: {}", .{ name, err });
        if (@errorReturnTrace()) |trace| std.debug.dumpStackTrace(trace.*);
    };
}

export fn draw(ctx: *const jok.Context, name: [*:0]const u8) void {
    plugin.draw(ctx.*) catch |err| {
        log.err("Plugin({s}) draw failed: {}", .{ name, err });
        if (@errorReturnTrace()) |trace| std.debug.dumpStackTrace(trace.*);
    };
}

export fn get_memory() ?*const anyopaque {
    return plugin.getMemory();
}

export fn reload_memory(mem: ?*const anyopaque, name: [*:0]const u8) void {
    plugin.reloadMemory(mem);
    log.info("Plugin({s}) memory reset: {?p}", .{ name, mem });
}
