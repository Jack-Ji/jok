const std = @import("std");
const builtin = @import("builtin");
const assert = std.debug.assert;
const jok = @import("../jok.zig");
const sdl = jok.sdl;
const log = std.log.scoped(.jok);

/// Dialog types
pub const DialogType = enum(c_int) {
    open_file = sdl.SDL_FILEDIALOG_OPENFILE,
    open_dir = sdl.SDL_FILEDIALOG_OPENFOLDER,
    save_file = sdl.SDL_FILEDIALOG_SAVEFILE,
};

/// An entry for filters for file dialogs.
/// e.g.
///    { .name = "PNG images",  .pattern = "png" }
///    { .name = "JPEG images", .pattern = "jpg;jpeg" }
///    { .name = "All images",  .pattern = "png;jpg;jpeg" }
///    { .name = "All files",   .pattern = "*" }
pub const DialogFilter = extern struct {
    name: [*c]const u8,
    pattern: [*c]const u8,
};

/// Dialog options
pub const DialogOption = struct {
    title: ?[*:0]const u8 = null,
    accept_label: ?[*:0]const u8 = null,
    cancel_label: ?[*:0]const u8 = null,
    filters: []const DialogFilter = &.{},
    default_location: ?[*:0]const u8 = null,
    allow_many: bool = false,
};

pub const DialogCallback = *const fn (userdata: ?*anyopaque, paths: [][:0]const u8) anyerror!void;

/// Show dialog for opening/saving files/directory
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

    fn deinit(self: *RealUserData) void {
        self.allocator.free(self.filters);
        self.allocator.destroy(self);
    }
};

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

    const files = real_userdata.allocator.alloc([:0]const u8, files_num) catch unreachable;
    defer real_userdata.allocator.free(files);
    path_ptr = filelist;
    for (0..files_num) |i| {
        files[i] = std.mem.sliceTo(filelist.*, 0);
        path_ptr += 1;
    }

    real_userdata.callback(real_userdata.userdata, files) catch |e| {
        log.err("Dialog callback failed: {s}", .{@errorName(e)});
    };
}
