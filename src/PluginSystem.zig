const std = @import("std");
const DynLib = std.DynLib;
const jok = @import("jok.zig");
const log = std.log.scoped(.jok);
const Self = @This();

const Error = error{
    NameCollision,
    NameNotExist,
    LookupApiFailed,
    CallInitFailed,
};

const InitFn = *const fn (ctx: *const jok.Context) callconv(.C) void;
const DeinitFn = *const fn (ctx: *const jok.Context) callconv(.C) void;
const EventFn = *const fn (ctx: *const jok.Context, e: *const jok.Event) callconv(.C) void;
const UpdateFn = *const fn (ctx: *const jok.Context) callconv(.C) void;
const DrawFn = *const fn (ctx: *const jok.Context) callconv(.C) void;
const GetMemoryFn = *const fn () callconv(.C) ?*const anyopaque;
const ReloadMemoryFn = *const fn (mem: ?*const anyopaque) callconv(.C) void;

pub const Plugin = struct {
    lib: DynLib,
    path: []const u8,
    last_modify_time: i128,
    version: u32,
    hot_reloading: bool,
    init_fn: InitFn,
    deinit_fn: DeinitFn,
    event_fn: EventFn,
    update_fn: UpdateFn,
    draw_fn: DrawFn,
    get_mem_fn: GetMemoryFn,
    reload_fn: ReloadMemoryFn,
};

allocator: std.mem.Allocator,
plugins: std.StringArrayHashMap(Plugin),

pub fn create(allocator: std.mem.Allocator) !*Self {
    const ps = try allocator.create(Self);
    ps.* = .{
        .allocator = allocator,
        .plugins = std.StringArrayHashMap(Plugin).init(allocator),
    };
    return ps;
}

pub fn destroy(self: *Self, ctx: jok.Context) void {
    var it = self.plugins.iterator();
    while (it.next()) |kv| {
        kv.value_ptr.deinit_fn(&ctx);
        kv.value_ptr.lib.close();
        self.allocator.free(kv.key_ptr.*);
        self.allocator.free(kv.value_ptr.path);
    }
    self.plugins.deinit();
    self.allocator.destroy(self);
}

pub fn register(self: *Self, ctx: jok.Context, name: []const u8, path: []const u8, hot_reload: bool) !void {
    if (self.plugins.contains(name)) return error.NameCollision;

    const stat = try std.fs.cwd().statFile(path);
    const loaded = try loadLibrary(path, hot_reload);

    loaded.init_fn(&ctx);
    errdefer loaded.deinit_fn(&ctx);

    try self.plugins.put(try self.allocator.dupe(u8, name), .{
        .lib = loaded.lib,
        .path = try self.allocator.dupe(u8, path),
        .last_modify_time = stat.mtime,
        .version = 1,
        .hot_reloading = hot_reload,
        .init_fn = loaded.init_fn,
        .deinit_fn = loaded.deinit_fn,
        .event_fn = loaded.event_fn,
        .update_fn = loaded.update_fn,
        .draw_fn = loaded.draw_fn,
        .get_mem_fn = loaded.get_mem_fn,
        .reload_fn = loaded.reload_fn,
    });

    log.info(
        "Successfully loaded library {s}, version {d}",
        .{ path, 1 },
    );
}

pub fn unregister(self: *Self, ctx: jok.Context, name: []const u8) !void {
    if (self.plugins.contains(name)) return error.NameNotExist;
    var kv = self.plugins.fetchSwapRemove(name).?;
    kv.value.deinit_fn(&ctx);
    kv.value.lib.close();
    self.allocator.free(kv.key);
    self.allocator.free(kv.value.path);
}

pub fn event(self: Self, ctx: jok.Context, e: jok.Event) void {
    var it = self.plugins.iterator();
    while (it.next()) |kv| {
        kv.value_ptr.event_fn(&ctx, &e);
    }
}

pub fn update(self: *Self, ctx: jok.Context) void {
    var it = self.plugins.iterator();
    while (it.next()) |kv| {
        kv.value_ptr.update_fn(&ctx);

        if (!kv.value_ptr.hot_reloading) continue;

        // Do hot-reload checking
        const stat = std.fs.cwd().statFile(kv.value_ptr.path) catch continue;
        if (stat.mtime != kv.value_ptr.last_modify_time) {
            const mem = kv.value_ptr.get_mem_fn();
            kv.value_ptr.lib.close();

            const loaded = loadLibrary(kv.value_ptr.path, kv.value_ptr.hot_reloading) catch |e| {
                log.err("Load library {s} failed: {}", .{ kv.value_ptr.path, e });
                continue;
            };
            loaded.reload_fn(mem);
            kv.value_ptr.lib = loaded.lib;
            kv.value_ptr.last_modify_time = stat.mtime;
            kv.value_ptr.init_fn = loaded.init_fn;
            kv.value_ptr.deinit_fn = loaded.deinit_fn;
            kv.value_ptr.event_fn = loaded.event_fn;
            kv.value_ptr.update_fn = loaded.update_fn;
            kv.value_ptr.draw_fn = loaded.draw_fn;
            kv.value_ptr.get_mem_fn = loaded.get_mem_fn;
            kv.value_ptr.reload_fn = loaded.reload_fn;
            kv.value_ptr.version += 1;
            log.info(
                "Successfully reloaded library {s}, version {d}",
                .{ kv.value_ptr.path, kv.value_ptr.version },
            );
        }
    }
}

pub fn draw(self: *Self, ctx: jok.Context) void {
    var it = self.plugins.iterator();
    while (it.next()) |kv| {
        kv.value_ptr.draw_fn(&ctx);
    }
}

pub fn forceReload(self: *Self, name: []const u8) !void {
    if (self.plugins.getPtr(name)) |v| {
        const mem = if (v.hot_reloading) v.get_mem_fn() else null;
        v.lib.close();

        const loaded = try loadLibrary(v.path, v.hot_reloading);
        if (v.hot_reloading) loaded.reload_fn(mem);
        v.lib = loaded.lib;
        v.init_fn = loaded.init_fn;
        v.deinit_fn = loaded.deinit_fn;
        v.event_fn = loaded.event_fn;
        v.update_fn = loaded.update_fn;
        v.draw_fn = loaded.draw_fn;
        v.get_mem_fn = loaded.get_mem_fn;
        v.reload_fn = loaded.reload_fn;
        v.version += 1;
        log.info("Successfully reloaded library {s}, version {d}", .{ v.path, v.version });
        return;
    }
    return error.NameNotExist;
}

fn loadLibrary(path: []const u8, hot_reload: bool) !struct {
    lib: DynLib,

    init_fn: InitFn,
    deinit_fn: DeinitFn,
    event_fn: EventFn,
    update_fn: UpdateFn,
    draw_fn: DrawFn,
    get_mem_fn: GetMemoryFn,
    reload_fn: ReloadMemoryFn,
} {
    var lib = try DynLib.open(path);
    const init_fn = lib.lookup(InitFn, "init").?;
    const deinit_fn = lib.lookup(DeinitFn, "deinit").?;
    const event_fn = lib.lookup(EventFn, "event").?;
    const update_fn = lib.lookup(UpdateFn, "update").?;
    const draw_fn = lib.lookup(DrawFn, "draw").?;
    const get_mem_fn = lib.lookup(GetMemoryFn, "get_memory").?;
    const reload_fn = lib.lookup(ReloadMemoryFn, "reload_memory").?;

    return .{
        .lib = lib,
        .init_fn = init_fn,
        .deinit_fn = deinit_fn,
        .event_fn = event_fn,
        .update_fn = update_fn,
        .draw_fn = draw_fn,
        .get_mem_fn = if (hot_reload) get_mem_fn else undefined,
        .reload_fn = if (hot_reload) reload_fn else undefined,
    };
}
