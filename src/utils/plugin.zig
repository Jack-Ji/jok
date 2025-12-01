const std = @import("std");
const DynLib = std.DynLib;
const log = std.log.scoped(.jok);

const loaded_plugins_path = "./loaded_plugins/";

const Error = error{
    LookupApiFailed,
};

pub fn Plugin(comptime StructType: type) type {
    const info = @typeInfo(StructType);
    if (info != .@"struct") @panic("Only accept struct type!");

    // Validate fields of struct
    const fields = info.@"struct".fields;
    for (fields) |f| {
        const field_info = @typeInfo(f.type);
        if (field_info != .pointer) @panic("All fields must be pointer to function!");
        const child_info = @typeInfo(field_info.pointer.child);
        if (child_info != .@"fn") @panic("All fields must be pointer to function!");
        if (!child_info.@"fn".calling_convention.eql(.c)) @panic("All functions must use C calling convention!");
    }

    return struct {
        const Self = @This();

        allocator: std.mem.Allocator,
        fptrs: StructType, // Directly used by app
        lib: DynLib,
        origin_path: []const u8,
        last_modify_time: std.Io.Timestamp,
        version: u32,

        pub fn create(allocator: std.mem.Allocator, path: []const u8) !*Self {
            // Initialize plugin path
            std.fs.cwd().makeDir(loaded_plugins_path) catch {};
            const plugin_path = getPluginPath(allocator, path);
            defer allocator.free(plugin_path);
            try std.fs.cwd().deleteTree(plugin_path);
            try std.fs.cwd().makeDir(plugin_path);

            // Clone original path
            const origin_path = try allocator.dupe(u8, path);
            errdefer allocator.free(origin_path);

            const self = try allocator.create(Self);
            errdefer allocator.destroy(self);
            const loaded = try loadLibrary(allocator, origin_path, 1);
            self.* = .{
                .allocator = allocator,
                .fptrs = loaded.fptrs,
                .lib = loaded.lib,
                .origin_path = origin_path,
                .last_modify_time = loaded.last_modify_time,
                .version = 1,
            };
            return self;
        }

        pub fn destroy(self: *Self) void {
            self.lib.close();
            self.allocator.free(self.origin_path);
            self.allocator.destroy(self);
        }

        /// Check mtime of plugin, reload if it's more update
        pub fn checkAndReload(self: *Self) !void {
            const stat = std.fs.cwd().statFile(self.origin_path) catch |e| {
                log.err("Check library {s} failed: {}", .{ self.origin_path, e });
                return e;
            };
            if (stat.mtime.nanoseconds != self.last_modify_time.nanoseconds) {
                try self.forceReload();
            }
        }

        /// Manually reload plugin
        pub fn forceReload(self: *Self) !void {
            const loaded = loadLibrary(self.allocator, self.origin_path, self.version + 1) catch |e| {
                log.err("Reload library {s} failed: {}", .{ self.origin_path, e });
                return e;
            };

            self.lib.close();
            self.fptrs = loaded.fptrs;
            self.lib = loaded.lib;
            self.last_modify_time = loaded.last_modify_time;
            self.version = self.version + 1;
            log.info("Successfully reloaded library {s}, version {d}", .{ self.origin_path, self.version });
        }

        fn loadLibrary(allocator: std.mem.Allocator, path: []const u8, version: u32) !struct {
            fptrs: StructType,
            lib: DynLib,
            last_modify_time: std.Io.Timestamp,
        } {
            const stat = try std.fs.cwd().statFile(path);
            const plugin_path = getPluginPath(allocator, path);
            defer allocator.free(plugin_path);
            const load_path = try std.fmt.allocPrint(
                allocator,
                "{s}/{s}.{d}",
                .{ plugin_path, std.fs.path.basename(path), version },
            );
            defer allocator.free(load_path);

            // Copy library to loading path
            try std.fs.cwd().copyFile(path, std.fs.cwd(), load_path, .{});

            // Load library and lookup api
            var lib = try DynLib.open(load_path);
            errdefer lib.close();
            var fptrs: StructType = undefined;
            inline for (fields) |f| {
                @field(fptrs, f.name) = lib.lookup(f.type, f.name) orelse return error.LookupApiFailed;
            }

            return .{
                .fptrs = fptrs,
                .lib = lib,
                .last_modify_time = stat.mtime,
            };
        }

        fn getPluginPath(allocator: std.mem.Allocator, path: []const u8) []const u8 {
            const pname = std.mem.sliceTo(std.fs.path.basename(path), '.');
            return std.fmt.allocPrint(
                allocator,
                "{s}{s}",
                .{ loaded_plugins_path, pname },
            ) catch unreachable;
        }
    };
}
