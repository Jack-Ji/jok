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
    origin_path: []const u8,
    last_modify_time: i128,
    version: u32,
    hot_reloading: bool,
    init_fn: InitFn,
    deinit_fn: DeinitFn,
    event_fn: EventFn,
    update_fn: UpdateFn,
    draw_fn: DrawFn,
    get_memory_fn: GetMemoryFn,
    reload_memory_fn: ReloadMemoryFn,
};

const plugin_path = "./loaded_plugins";

allocator: std.mem.Allocator,
plugins: std.StringArrayHashMap(Plugin),

pub fn create(allocator: std.mem.Allocator) !*Self {
    try std.fs.cwd().deleteTree(plugin_path);
    try std.fs.cwd().makeDir(plugin_path);
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
        self.allocator.free(kv.value_ptr.origin_path);
    }
    self.plugins.deinit();
    self.allocator.destroy(self);
}

pub fn register(self: *Self, ctx: jok.Context, name: []const u8, path: []const u8, hot_reload: bool) !void {
    if (self.plugins.contains(name)) return error.NameCollision;

    const loaded = try self.loadLibrary(path, 1);
    loaded.init_fn(&ctx);
    errdefer loaded.deinit_fn(&ctx);

    try self.plugins.put(try self.allocator.dupe(u8, name), .{
        .lib = loaded.lib,
        .origin_path = try self.allocator.dupe(u8, path),
        .last_modify_time = loaded.last_modify_time,
        .version = 1,
        .hot_reloading = hot_reload,
        .init_fn = loaded.init_fn,
        .deinit_fn = loaded.deinit_fn,
        .event_fn = loaded.event_fn,
        .update_fn = loaded.update_fn,
        .draw_fn = loaded.draw_fn,
        .get_memory_fn = loaded.get_memory_fn,
        .reload_memory_fn = loaded.reload_memory_fn,
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
    self.allocator.free(kv.value.origin_path);
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
        const stat = std.fs.cwd().statFile(kv.value_ptr.origin_path) catch continue;
        if (stat.mtime != kv.value_ptr.last_modify_time) {
            self.forceReload(kv.key_ptr.*) catch continue;
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
        const loaded = self.loadLibrary(v.origin_path, v.version + 1) catch |e| {
            log.err("Reload library {s} failed: {}", .{ v.origin_path, e });
            return e;
        };

        // Restore plugin's internal state
        const mem = v.get_memory_fn();
        loaded.reload_memory_fn(mem);

        // Update plugin info
        v.lib.close();
        v.lib = loaded.lib;
        v.last_modify_time = loaded.last_modify_time;
        v.init_fn = loaded.init_fn;
        v.deinit_fn = loaded.deinit_fn;
        v.event_fn = loaded.event_fn;
        v.update_fn = loaded.update_fn;
        v.draw_fn = loaded.draw_fn;
        v.get_memory_fn = loaded.get_memory_fn;
        v.reload_memory_fn = loaded.reload_memory_fn;
        v.version += 1;
        log.info("Successfully reloaded library {s}, version {d}", .{ v.origin_path, v.version });
        return;
    }
    return error.NameNotExist;
}

fn loadLibrary(self: *Self, path: []const u8, version: u32) !struct {
    lib: DynLib,
    last_modify_time: i128,
    init_fn: InitFn,
    deinit_fn: DeinitFn,
    event_fn: EventFn,
    update_fn: UpdateFn,
    draw_fn: DrawFn,
    get_memory_fn: GetMemoryFn,
    reload_memory_fn: ReloadMemoryFn,
} {
    const stat = try std.fs.cwd().statFile(path);
    const load_path = try std.fmt.allocPrint(
        self.allocator,
        "{s}/{s}.{d}",
        .{ plugin_path, std.fs.path.basename(path), version },
    );
    defer self.allocator.free(load_path);

    // Copy library to loading path
    try std.fs.cwd().copyFile(path, std.fs.cwd(), load_path, .{});

    // Load library and lookup api
    var lib = try DynLib.open(load_path);
    const init_fn = lib.lookup(InitFn, "init") orelse return error.LookupApiFailed;
    const deinit_fn = lib.lookup(DeinitFn, "deinit") orelse return error.LookupApiFailed;
    const event_fn = lib.lookup(EventFn, "event") orelse return error.LookupApiFailed;
    const update_fn = lib.lookup(UpdateFn, "update") orelse return error.LookupApiFailed;
    const draw_fn = lib.lookup(DrawFn, "draw") orelse return error.LookupApiFailed;
    const get_memory_fn = lib.lookup(GetMemoryFn, "get_memory") orelse return error.LookupApiFailed;
    const reload_memory_fn = lib.lookup(ReloadMemoryFn, "reload_memory") orelse return error.LookupApiFailed;

    return .{
        .lib = lib,
        .last_modify_time = stat.mtime,
        .init_fn = init_fn,
        .deinit_fn = deinit_fn,
        .event_fn = event_fn,
        .update_fn = update_fn,
        .draw_fn = draw_fn,
        .get_memory_fn = get_memory_fn,
        .reload_memory_fn = reload_memory_fn,
    };
}
