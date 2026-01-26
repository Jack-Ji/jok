//! Native file/directory dialog system.
//!
//! This module provides cross-platform file and directory selection dialogs
//! using SDL3's native dialog support.
//!
//! Supported platforms: Windows, Linux, macOS
//!
//! Features:
//! - Open file/directory dialogs
//! - Save file dialogs
//! - File type filters
//! - Multiple file selection
//! - Asynchronous callbacks
//! - Main thread or background execution
//!
//! Example usage:
//! ```zig
//! fn onFileSelected(userdata: ?*anyopaque, paths: [][]const u8) !void {
//!     for (paths) |path| {
//!         std.debug.print("Selected: {s}\n", .{path});
//!     }
//! }
//!
//! try showDialog(
//!     ctx,
//!     .open_file,
//!     onFileSelected,
//!     null,
//!     .{
//!         .title = "Select an image",
//!         .filters = &.{
//!             .{ .name = "PNG images", .pattern = "png" },
//!             .{ .name = "All files", .pattern = "*" },
//!         },
//!         .allow_many = true,
//!     },
//! );
//! ```

const std = @import("std");
const builtin = @import("builtin");
const assert = std.debug.assert;
const jok = @import("../jok.zig");
const sdl = jok.vendor.sdl;
const log = std.log.scoped(.jok);

/// Types of file dialogs
pub const DialogType = enum(c_int) {
    /// Open an existing file
    open_file = sdl.SDL_FILEDIALOG_OPENFILE,
    /// Open a directory
    open_dir = sdl.SDL_FILEDIALOG_OPENFOLDER,
    /// Save to a file (may not exist yet)
    save_file = sdl.SDL_FILEDIALOG_SAVEFILE,
};

/// File filter entry for dialog file type filtering
/// Examples:
///   .{ .name = "PNG images",  .pattern = "png" }
///   .{ .name = "JPEG images", .pattern = "jpg;jpeg" }
///   .{ .name = "All images",  .pattern = "png;jpg;jpeg" }
///   .{ .name = "All files",   .pattern = "*" }
pub const DialogFilter = extern struct {
    name: [*c]const u8,
    pattern: [*c]const u8,
};

/// Options for configuring file dialogs
pub const DialogOption = struct {
    title: ?[:0]const u8 = null,
    accept_label: ?[:0]const u8 = null,
    cancel_label: ?[:0]const u8 = null,
    filters: []const DialogFilter = &.{},
    default_location: ?[:0]const u8 = null,
    allow_many: bool = false,
    run_on_main_thread: bool = true,
};

/// Callback function type for dialog results
/// Called with user data and array of selected file paths
pub const DialogCallback = *const fn (userdata: ?*anyopaque, paths: [][]const u8) anyerror!void;

/// Show a file/directory dialog
/// The callback will be invoked asynchronously when the user makes a selection
pub fn showDialog(ctx: jok.Context, dt: DialogType, callback: DialogCallback, userdata: ?*anyopaque, opt: DialogOption) !void {
    if (builtin.os.tag != .windows and builtin.os.tag != .linux and builtin.os.tag != .macos) {
        @panic("Unsupported platform");
    }

    const real_userdata = try ctx.allocator().create(RealUserData);
    real_userdata.* = .{
        .allocator = ctx.allocator(),
        .callback = callback,
        .userdata = userdata,
        .filters = try ctx.allocator().dupe(DialogFilter, opt.filters),
        .run_on_main_thread = opt.run_on_main_thread,
    };

    const props = sdl.SDL_CreateProperties();
    if (opt.title) |s| {
        _ = sdl.SDL_SetStringProperty(props, sdl.SDL_PROP_FILE_DIALOG_TITLE_STRING, s);
    }
    if (opt.accept_label) |s| {
        _ = sdl.SDL_SetStringProperty(props, sdl.SDL_PROP_FILE_DIALOG_ACCEPT_STRING, s);
    }
    if (opt.cancel_label) |s| {
        _ = sdl.SDL_SetStringProperty(props, sdl.SDL_PROP_FILE_DIALOG_CANCEL_STRING, s);
    }
    if (opt.filters.len > 0) {
        _ = sdl.SDL_SetPointerProperty(props, sdl.SDL_PROP_FILE_DIALOG_FILTERS_POINTER, @ptrCast(@constCast(real_userdata.filters.ptr)));
        _ = sdl.SDL_SetNumberProperty(props, sdl.SDL_PROP_FILE_DIALOG_NFILTERS_NUMBER, @intCast(real_userdata.filters.len));
    }
    if (opt.default_location) |loc| {
        _ = sdl.SDL_SetStringProperty(props, sdl.SDL_PROP_FILE_DIALOG_LOCATION_STRING, loc);
    }
    if (opt.allow_many) {
        _ = sdl.SDL_SetBooleanProperty(props, sdl.SDL_PROP_FILE_DIALOG_MANY_BOOLEAN, true);
    }
    _ = sdl.SDL_SetPointerProperty(props, sdl.SDL_PROP_FILE_DIALOG_WINDOW_POINTER, @ptrCast(ctx.window().ptr));

    sdl.SDL_ShowFileDialogWithProperties(@intCast(@intFromEnum(dt)), realCallback, real_userdata, props);
}

const RealUserData = struct {
    allocator: std.mem.Allocator,
    callback: DialogCallback,
    userdata: ?*anyopaque,
    filters: []const DialogFilter,
    run_on_main_thread: bool,

    fn deinit(self: *RealUserData) void {
        self.allocator.free(self.filters);
        self.allocator.destroy(self);
    }
};

// Called from arbitrary thread
fn realCallback(_userdata: ?*anyopaque, filelist: [*c]const [*c]const u8, _: c_int) callconv(.c) void {
    const real_userdata: *RealUserData = @ptrCast(@alignCast(_userdata.?));
    defer real_userdata.deinit();

    if (filelist == null) {
        log.err("Show dialog failed: {s}", .{sdl.SDL_GetError()});
        return;
    }
    if (filelist.* == null) {
        return;
    }

    var files_num: usize = 0;
    var path_ptr = filelist;
    while (path_ptr.* != null) : (path_ptr += 1) {
        files_num += 1;
    }

    const files = real_userdata.allocator.alloc([]const u8, files_num) catch unreachable;
    defer real_userdata.allocator.free(files);
    path_ptr = filelist;
    for (0..files_num) |i| {
        files[i] = std.mem.sliceTo(filelist.*, 0);
        path_ptr += 1;
    }

    if (real_userdata.run_on_main_thread) {
        const real_userdata2 = real_userdata.allocator.create(RealUserData2) catch unreachable;
        defer real_userdata.allocator.destroy(real_userdata2);

        real_userdata2.* = .{
            .real_userdata = real_userdata,
            .files = files,
        };
        _ = sdl.SDL_RunOnMainThread(realCallback2, real_userdata2, true);
    } else {
        real_userdata.callback(real_userdata.userdata, files) catch |e| {
            log.err("Dialog callback failed: {s}", .{@errorName(e)});
        };
    }
}

const RealUserData2 = struct {
    real_userdata: *RealUserData,
    files: [][]const u8,
};

// Called from main thread
fn realCallback2(_userdata: ?*anyopaque) callconv(.c) void {
    const real_userdata2: *RealUserData2 = @ptrCast(@alignCast(_userdata.?));
    real_userdata2.real_userdata.callback(real_userdata2.real_userdata.userdata, real_userdata2.files) catch |e| {
        log.err("Dialog callback failed: {s}", .{@errorName(e)});
    };
}
