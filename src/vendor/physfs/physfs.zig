const std = @import("std");
const assert = std.debug.assert;

//------------------------------------------------------------------------------
// Error info
//------------------------------------------------------------------------------
pub const Error = error{
    OtherError,
    OutOfMemory,
    NotInitialized,
    IsInitialized,
    Argv0IsNull,
    Unsupported,
    PastEOF,
    FilesStillOpen,
    InvalidArgument,
    NotMounted,
    NotFound,
    SymlinkForbidden,
    NoWriteDir,
    OpenForReading,
    OpenForWriting,
    NotFile,
    ReadOnly,
    Corrupt,
    SymlinkLoop,
    IO,
    Permission,
    NoSpace,
    BadFilename,
    Busy,
    DirNotEmpty,
    OsError,
    Duplicate,
    BadPassword,
    AppCallback,
};

pub const ErrorCode = enum(c_int) {
    ok, // Success; no error.
    other_error, // Error not otherwise covered here.
    out_of_memory, // Memory allocation failed.
    not_initialized, // PhysicsFS is not initialized.
    is_initialized, // PhysicsFS is already initialized.
    argv0_is_null, // Needed argv[0], but it is NULL.
    unsupported, // Operation or feature unsupported.
    past_eof, // Attempted to access past end of file.
    files_still_open, // Files still open.
    invalid_argument, // Bad parameter passed to an function.
    not_mounted, // Requested archive/dir not mounted.
    not_found, // File (or whatever) not found.
    symlink_forbidden, // Symlink seen when not permitted.
    no_write_dir, // No write dir has been specified.
    open_for_reading, // Wrote to a file opened for reading.
    open_for_writing, // Read from a file opened for writing.
    not_a_file, // Needed a file, got a directory (etc).
    read_only, // Wrote to a read-only filesystem.
    corrupt, // Corrupted data encountered.
    symlink_loop, // Infinite symbolic link loop.
    io, // i/o error (hardware failure, etc).
    permission, // Permission denied.
    no_space, // No space (disk full, over quota, etc)
    bad_filename, // Filename is bogus/insecure.
    busy, // Tried to modify a file the OS needs.
    dir_not_empty, // Tried to delete dir with files in it.
    os_error, // Unspecified OS-level error.
    duplicate, // Duplicate entry.
    bad_password, // Bad password.
    app_callback, // Application callback reported error.

    pub fn toError(ec: ErrorCode) ?void {
        return switch (ec) {
            .ok => null,
            .other_error => error.OtherError,
            .out_of_memory => error.OutOfMemory,
            .not_initialized => error.NotInitialized,
            .is_initialized => error.IsInitialized,
            .argv0_is_null => error.Argv0IsNull,
            .unsupported => error.Unsupported,
            .past_eof => error.PastEOF,
            .files_still_open => error.FilesStillOpen,
            .invalid_argument => error.InvalidArgument,
            .not_mounted => error.NotMounted,
            .not_found => error.NotFound,
            .symlink_forbidden => error.SymlinkForbidden,
            .no_write_dir => error.NoWriteDir,
            .open_for_reading => error.OpenForReading,
            .open_for_writing => error.OpenForWriting,
            .not_a_file => error.NotFile,
            .read_only => error.ReadOnly,
            .corrupt => error.Corrupt,
            .symlink_loop => error.SymlinkLoop,
            .io => error.IO,
            .permission => error.Permission,
            .no_space => error.NoSpace,
            .bad_filename => error.BadFilename,
            .busy => error.Busy,
            .dir_not_empty => error.DirNotEmpty,
            .os_error => error.OsError,
            .duplicate => error.Duplicate,
            .bad_password => error.BadPassword,
            .app_callback => error.AppCallback,
        };
    }

    pub fn toDesc(ec: ErrorCode) []const u8 {
        return std.mem.sliceTo(PHYSFS_getErrorByCode(ec), 0);
    }
};

/// Get error information of last call.
pub fn getLastErrorCode() ErrorCode {
    return PHYSFS_getLastErrorCode();
}

//------------------------------------------------------------------------------
// Wrapped api
//------------------------------------------------------------------------------

/// This must be called before any other PhysicsFS function.
/// This should be called prior to any attempts to change your process's
/// current working directory.
pub fn init(allocator: std.mem.Allocator) void {
    assert(mem_allocator == null);
    mem_allocator = allocator;
    physfs_allocator = .{
        .init_fn = memInit,
        .deinit_fn = memDeinit,
        .malloc_fn = memAlloc,
        .realloc_fn = memRealloc,
        .free_fn = memFree,
    };
    var ret = PHYSFS_setAllocator(&physfs_allocator);
    if (ret == 0) {
        @panic(getLastErrorCode().toDesc());
    }

    ret = PHYSFS_init(std.os.argv[0]);
    if (ret == 0) {
        @panic(getLastErrorCode().toDesc());
    }
}

/// This closes any files opened via PhysicsFS, blanks the search/write paths,
/// frees memory, and invalidates all of your file handles.
///
/// Note that this call can FAIL if there's a file open for writing that
/// refuses to close (for example, the underlying operating system was
/// buffering writes to network filesystem, and the fileserver has crashed,
/// or a hard drive has failed, etc). It is usually best to close all write
/// handles yourself before calling this function, so that you can gracefully
/// handle a specific failure.
pub fn deinit() void {
    const ret = PHYSFS_deinit();
    if (ret == 0) {
        @panic(getLastErrorCode().toDesc());
    }
}

/// Get the "base dir". This is the directory where the application was run
/// from, which is probably the installation directory, and may or may not
/// be the process's current working directory.
///
/// You should probably use the base dir in your search path.
pub fn getBaseDir() []const u8 {
    return std.mem.sliceTo(PHYSFS_getBaseDir(), 0);
}

/// Get the "pref dir". This is meant to be where users can write personal
///  files (preferences and save games, etc) that are specific to your
///  application. This directory is unique per user, per application.
///
/// This function will decide the appropriate location in the native filesystem,
///  create the directory if necessary, and return a string in
///  platform-dependent notation, suitable for passing to PHYSFS_setWriteDir().
///
/// On Windows, this might look like:
///  "C:\\Users\\bob\\AppData\\Roaming\\My Company\\My Program Name"
///
/// On Linux, this might look like:
///  "/home/bob/.local/share/My Program Name"
///
/// On Mac OS X, this might look like:
///  "/Users/bob/Library/Application Support/My Program Name"
///
/// (etc.)
///
/// You should probably use the pref dir for your write dir, and also put it
///  near the beginning of your search path. Older versions of PhysicsFS
///  offered only PHYSFS_getUserDir() and left you to figure out where the
///  files should go under that tree. This finds the correct location
///  for whatever platform, which not only changes between operating systems,
///  but also versions of the same operating system.
///
/// You specify the name of your organization (if it's not a real organization,
///  your name or an Internet domain you own might do) and the name of your
///  application. These should be proper names.
///
/// Both the (org) and (app) strings may become part of a directory name, so
///  please follow these rules:
///
///    - Try to use the same org string (including case-sensitivity) for
///      all your applications that use this function.
///    - Always use a unique app string for each one, and make sure it never
///      changes for an app once you've decided on it.
///    - Unicode characters are legal, as long as it's UTF-8 encoded, but...
///    - ...only use letters, numbers, and spaces. Avoid punctuation like
///      "Game Name 2: Bad Guy's Revenge!" ... "Game Name 2" is sufficient.
///
/// The pointer returned by this function remains valid until you call this
///  function again, or call PHYSFS_deinit(). This is not necessarily a fast
///  call, though, so you should call this once at startup and copy the string
///  if you need it.
///
/// You should assume the path returned by this function is the only safe
/// place to write files.
pub fn getRefDir(_org: []const u8, _app: []const u8) []const u8 {
    var org_buf: [256]u8 = undefined;
    var app_buf: [256]u8 = undefined;
    const org = std.fmt.bufPrintZ(&org_buf, "{s}", .{_org}) catch unreachable;
    const app = std.fmt.bufPrintZ(&app_buf, "{s}", .{_app}) catch unreachable;
    return std.mem.sliceTo(PHYSFS_getPrefDir(org, app), 0);
}

/// A PhysicsFS file handle.
///
/// You get a pointer to one of these when you open a file for reading,
/// writing, or appending via PhysicsFS.
pub const File = *opaque {};

//------------------------------------------------------------------------------
// Custom memory allocator implementation
//------------------------------------------------------------------------------
var physfs_allocator: MemAllocator = undefined;
var mem_allocator: ?std.mem.Allocator = null;
var mem_allocations: std.AutoHashMap(usize, usize) = undefined;
var mem_mutex: std.Thread.Mutex = .{};
const mem_alignment = 16;

fn memInit() callconv(.C) c_int {
    assert(mem_allocator != null);
    mem_allocations = std.AutoHashMap(usize, usize).init(mem_allocator.?);
    mem_allocations.ensureTotalCapacity(32) catch @panic("OOM");
    return 1;
}

fn memDeinit() callconv(.C) void {
    assert(mem_allocator != null);
    mem_allocations.deinit();
}

fn memAlloc(size: usize) callconv(.C) ?*anyopaque {
    assert(mem_allocator != null);
    mem_mutex.lock();
    defer mem_mutex.unlock();

    const mem = mem_allocator.?.alignedAlloc(
        u8,
        mem_alignment,
        size,
    ) catch @panic("OOM");

    mem_allocations.put(@intFromPtr(mem.ptr), size) catch @panic("OOM");

    return mem.ptr;
}

fn memRealloc(ptr: ?*anyopaque, size: usize) callconv(.C) ?*anyopaque {
    assert(mem_allocator != null);
    mem_mutex.lock();
    defer mem_mutex.unlock();

    var mem: []u8 = undefined;
    if (mem_allocations.fetchRemove(@intFromPtr(ptr))) |kv| {
        const old_size = kv.value;
        const old_mem = @as([*]align(mem_alignment) u8, @ptrCast(@alignCast(ptr)))[0..old_size];
        mem = mem_allocator.?.realloc(old_mem, size) catch @panic("OOM");
    } else {
        mem = mem_allocator.?.alignedAlloc(
            u8,
            mem_alignment,
            size,
        ) catch @panic("OOM");
    }
    mem_allocations.put(@intFromPtr(mem.ptr), size) catch @panic("OOM");
    return mem.ptr;
}

fn memFree(ptr: ?*anyopaque) callconv(.C) void {
    if (ptr == null) return;

    assert(mem_allocator != null);
    mem_mutex.lock();
    defer mem_mutex.unlock();

    const size = mem_allocations.fetchRemove(@intFromPtr(ptr)).?.value;
    const mem = @as([*]align(mem_alignment) u8, @ptrCast(@alignCast(ptr)))[0..size];
    mem_allocator.?.free(mem);
}

//------------------------------------------------------------------------------
// C api declarations
//------------------------------------------------------------------------------
const MemAllocator = extern struct {
    init_fn: ?*const fn () callconv(.C) c_int,
    deinit_fn: ?*const fn () callconv(.C) void,
    malloc_fn: ?*const fn (usize) callconv(.C) ?*anyopaque,
    realloc_fn: ?*const fn (?*anyopaque, usize) callconv(.C) ?*anyopaque,
    free_fn: ?*const fn (?*anyopaque) callconv(.C) void,
};
extern fn PHYSFS_init(argv0: ?[*:0]const u8) c_int;
extern fn PHYSFS_deinit() c_int;
extern fn PHYSFS_setAllocator(allocator: *const MemAllocator) c_int;
extern fn PHYSFS_getErrorByCode(ec: ErrorCode) [*:0]const u8;
extern fn PHYSFS_getLastErrorCode() ErrorCode;
extern fn PHYSFS_freeList(list_var: ?*anyopaque) void;
extern fn PHYSFS_getBaseDir() [*:0]const u8;
extern fn PHYSFS_getPrefDir(org: [*:0]const u8, app: [*:0]const u8) [*:0]const u8;
