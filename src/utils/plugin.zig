//! Plugin system with hot-reloading support for dynamic library loading.
//!
//! This module provides a plugin system that allows loading and hot-reloading
//! of dynamic libraries at runtime. Useful for rapid development and modding support.
//!
//! Features:
//! - Load plugins from dynamic libraries (.so, .dll, .dylib)
//! - Hot-reload plugins when source files change
//! - Static plugin support for WASM and other platforms
//! - Type-safe function pointer management
//! - Automatic version tracking
//!
//! Requirements:
//! - Plugin struct must contain only function pointers
//! - All functions must use C calling convention
//!
//! Example usage:
//! ```zig
//! const MyPlugin = struct {
//!     init: *const fn() callconv(.c) void,
//!     update: *const fn(f32) callconv(.c) void,
//!     deinit: *const fn() callconv(.c) void,
//! };
//!
//! var plugin = try Plugin(MyPlugin).create(ctx, .{ .dynamic = "libmyplugin.so" });
//! defer plugin.destroy();
//!
//! // In your update loop:
//! try plugin.checkAndReload(); // Hot-reload if file changed
//! plugin.fptrs.update(delta_time);
//! ```

const std = @import("std");
const builtin = @import("builtin");
const DynLib = std.DynLib;
const log = std.log.scoped(.jok);
const jok = @import("../jok.zig");

const loaded_plugins_path = "./loaded_plugins/";

/// Errors that can occur during plugin operations
const Error = error{
    /// Failed to lookup API function in plugin
    LookupApiFailed,
};

/// Generic plugin loader with hot-reload support
/// StructType: A struct containing only function pointers with C calling convention
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

        ctx: jok.Context,
        type: Type,
        fptrs: StructType, // Directly used by app
        lib: DynLib,
        origin_path: []const u8,
        last_modify_time: std.Io.Timestamp,
        version: u32,

        pub const Type = enum { dynamic, static };
        pub const Source = union(Type) {
            dynamic: []const u8,
            static: void,
        };

        /// Create a plugin with given source
        pub fn create(ctx: jok.Context, source: Source) !*Self {
            if (!builtin.cpu.arch.isWasm() and source == .dynamic) {
                // Load dynamic library
                const allocator = ctx.allocator();
                const path = source.dynamic;
                const plugin_path = getPluginPath(allocator, path);
                defer allocator.free(plugin_path);
                try std.Io.Dir.cwd().deleteTree(ctx.io(), plugin_path);
                try std.Io.Dir.cwd().createDirPath(ctx.io(), plugin_path);

                // Clone original path
                const origin_path = try allocator.dupe(u8, path);
                errdefer allocator.free(origin_path);

                const self = try allocator.create(Self);
                errdefer allocator.destroy(self);
                const loaded = try loadLibrary(ctx, origin_path, 1);
                self.* = .{
                    .ctx = ctx,
                    .type = .dynamic,
                    .fptrs = loaded.fptrs,
                    .lib = loaded.lib,
                    .origin_path = origin_path,
                    .last_modify_time = loaded.last_modify_time,
                    .version = 1,
                };
                return self;
            } else {
                // Statically initialize plugin struct
                const allocator = ctx.allocator();
                const self = try allocator.create(Self);
                self.* = .{
                    .ctx = ctx,
                    .type = .static,
                    .fptrs = .{},
                    .lib = undefined,
                    .origin_path = undefined,
                    .last_modify_time = undefined,
                    .version = 1,
                };
                return self;
            }
        }

        /// Destroy plugin
        pub fn destroy(self: *Self) void {
            if (!builtin.cpu.arch.isWasm() and self.type == .dynamic) {
                self.lib.close();
                self.ctx.allocator().free(self.origin_path);
            }
            self.ctx.allocator().destroy(self);
        }

        /// Check mtime of plugin, reload if it's more update
        pub fn checkAndReload(self: *Self) !void {
            if (self.type == .static) return;
            const stat = std.Io.Dir.cwd().statFile(self.ctx.io(), self.origin_path, .{}) catch |e| {
                log.err("Check library {s} failed: {}", .{ self.origin_path, e });
                return e;
            };
            if (stat.mtime.nanoseconds != self.last_modify_time.nanoseconds) {
                try self.forceReload();
            }
        }

        /// Manually reload plugin
        pub fn forceReload(self: *Self) !void {
            if (builtin.cpu.arch.isWasm() or self.type == .static) return;

            const loaded = loadLibrary(self.ctx, self.origin_path, self.version + 1) catch |e| {
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

        fn loadLibrary(ctx: jok.Context, path: []const u8, version: u32) !struct {
            fptrs: StructType,
            lib: DynLib,
            last_modify_time: std.Io.Timestamp,
        } {
            const allocator = ctx.allocator();
            const stat = try std.Io.Dir.cwd().statFile(ctx.io(), path, .{});
            const plugin_path = getPluginPath(allocator, path);
            defer allocator.free(plugin_path);
            const load_path = try std.fmt.allocPrint(
                allocator,
                "{s}/{s}.{d}",
                .{ plugin_path, std.fs.path.basename(path), version },
            );
            defer allocator.free(load_path);

            // Copy library to loading path
            try std.Io.Dir.cwd().copyFile(
                path,
                std.Io.Dir.cwd(),
                load_path,
                ctx.io(),
                .{},
            );

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
