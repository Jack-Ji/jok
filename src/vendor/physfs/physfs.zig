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
    if (PHYSFS_setAllocator(&physfs_allocator) == 0) {
        @panic(getLastErrorCode().toDesc());
    }

    if (PHYSFS_init(std.os.argv[0]) == 0) {
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
    if (PHYSFS_deinit() == 0) {
        @panic(getLastErrorCode().toDesc());
    }
}

/// Get the "base dir". This is the directory where the application was run
/// from, which is probably the installation directory, and may or may not
/// be the process's current working directory.
///
/// You should probably use the base dir in your search path.
pub fn getBaseDir() [*:0]const u8 {
    return PHYSFS_getBaseDir();
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
pub fn getPrefDir(_org: []const u8, _app: []const u8) [*:0]const u8 {
    var org_buf: [256]u8 = undefined;
    var app_buf: [256]u8 = undefined;
    const org = std.fmt.bufPrintZ(&org_buf, "{s}", .{_org}) catch unreachable;
    const app = std.fmt.bufPrintZ(&app_buf, "{s}", .{_app}) catch unreachable;
    if (PHYSFS_getPrefDir(org, app)) |p| {
        return p;
    }
    @panic("can't get data dir");
}

/// Get the current write dir. The default write dir is NULL.
pub fn getWriteDir() ?[*:0]const u8 {
    return PHYSFS_getWriteDir();
}

/// Set a new write dir. This will override the previous setting.
/// New path is specified in platform-dependent notation.
/// Setting to NULL disables the write dir, so no files can be opened
/// for writing via PhysicsFS.
///
/// This call will fail (and fail to change the write dir) if the current
/// write dir still has files open in it.
pub fn setWriteDir(path: ?[*:0]const u8) !void {
    if (PHYSFS_setWriteDir(path) == 0) {
        return getLastErrorCode().toError();
    }
}

/// Get current search paths, using given memory allocator.
pub fn getSearchPathsAlloc(allocator: std.mem.Allocator) !struct {
    allocator: std.mem.Allocator,
    cpaths: [*]?[*:0]const u8,
    paths: [][*:0]const u8,

    pub fn deinit(self: *@This()) void {
        PHYSFS_freeList(@ptrCast(self.cpaths));
        self.allocator.free(self.paths);
    }
} {
    if (PHYSFS_getSearchPath()) |cpaths| {
        var path_count: usize = 0;
        while (cpaths[path_count] != null) {
            path_count += 1;
        }

        const result = .{
            .allocator = allocator,
            .cpaths = cpaths,
            .paths = try allocator.alloc([*:0]const u8, path_count),
        };
        for (0..path_count) |i| {
            result.paths[i] = cpaths[i].?;
        }

        return result;
    }
    return getLastErrorCode().toError();
}

/// Get iterator for current search paths.
pub fn getSearchPathsIterator() !struct {
    cpaths: [*]?[*:0]const u8,
    idx: usize,

    pub fn deinit(it: *@This()) void {
        PHYSFS_freeList(@ptrCast(it.cpaths));
    }

    pub fn next(it: *@This()) ?[*:0]const u8 {
        const p = it.cpaths[it.idx];
        if (p != null) it.idx += 1;
        return p;
    }
} {
    if (PHYSFS_getSearchPath()) |cpaths| {
        return .{
            .cpaths = cpaths,
            .idx = 0,
        };
    }
    return getLastErrorCode().toError();
}

/// Add an archive or directory to the search path.
/// Append new dir to search paths if `append` is true, prepend otherwise.
///
/// If this is a duplicate, the entry is not added again, even though the
/// function succeeds. You may not add the same archive to two different
/// mountpoints: duplicate checking is done against the archive and not the
/// mountpoint.
///
/// When you mount an archive, it is added to a virtual file system...all files
/// in all of the archives are interpolated into a single hierachical file
/// tree. Two archives mounted at the same place (or an archive with files
/// overlapping another mountpoint) may have overlapping files: in such a case,
/// the file earliest in the search path is selected, and the other files are
/// inaccessible to the application. This allows archives to be used to
/// override previous revisions; you can use the mounting mechanism to place
/// archives at a specific point in the file tree and prevent overlap; this
/// is useful for downloadable mods that might trample over application data
/// or each other, for example.
pub fn mount(dir_or_archive: [*:0]const u8, mount_point: [*:0]const u8, append: bool) !void {
    if (PHYSFS_mount(dir_or_archive, mount_point, if (append) 1 else 0) == 0) {
        return getLastErrorCode().toError();
    }
}

/// Remove a directory or archive from the search path.
///
/// This must be a (case-sensitive) match to a dir or archive already in the
/// search path, specified in platform-dependent notation.
///
/// This call will fail (and fail to remove from the path) if the element still
/// has files open in it.
pub fn unmount(dir_or_archive: [*:0]const u8) !void {
    if (PHYSFS_unmount(dir_or_archive) == 0) {
        return getLastErrorCode().toError();
    }
}

/// Create a directory.
///
/// This is specified in platform-independent notation in relation to the
/// write dir. All missing parent directories are also created if they
/// don't exist.
///
/// So if you've got the write dir set to "C:\mygame\writedir" and call
/// PHYSFS_mkdir("downloads/maps") then the directories
/// "C:\mygame\writedir\downloads" and "C:\mygame\writedir\downloads\maps"
/// will be created if possible. If the creation of "maps" fails after we
/// have successfully created "downloads", then the function leaves the
/// created directory behind and reports failure.
pub fn mkdir(dirname: [*:0]const u8) !void {
    if (PHYSFS_mkdir(dirname) == 0) {
        return getLastErrorCode().toError();
    }
}

/// Delete a file or directory.
///
/// (filename) is specified in platform-independent notation in relation to the
///  write dir.
///
/// A directory must be empty before this call can delete it.
///
/// Deleting a symlink will remove the link, not what it points to, regardless
/// of whether you "permitSymLinks" or not.
///
/// So if you've got the write dir set to "C:\mygame\writedir" and call
/// PHYSFS_delete("downloads/maps/level1.map") then the file
/// "C:\mygame\writedir\downloads\maps\level1.map" is removed from the
/// physical filesystem, if it exists and the operating system permits the
/// deletion.
///
/// Note that on Unix systems, deleting a file may be successful, but the
/// actual file won't be removed until all processes that have an open
/// filehandle to it (including your program) close their handles.
///
/// Chances are, the bits that make up the file still exist, they are just
/// made available to be written over at a later point. Don't consider this
/// a security method or anything.  :)
pub fn delete(filename: [*:0]const u8) !void {
    if (PHYSFS_delete(filename) == 0) {
        return getLastErrorCode().toError();
    }
}

/// Figure out where in the search path a file resides.
///
/// The file is specified in platform-independent notation. The returned
/// filename will be the element of the search path where the file was found,
/// which may be a directory, or an archive. Even if there are multiple
/// matches in different parts of the search path, only the first one found
/// is used, just like when opening a file.
///
/// So, if you look for "maps/level1.map", and C:\\mygame is in your search
/// path and C:\\mygame\\maps\\level1.map exists, then "C:\mygame" is returned.
///
/// If a any part of a match is a symbolic link, and you've not explicitly
/// permitted symlinks, then it will be ignored, and the search for a match
/// will continue.
///
/// If you specify a fake directory that only exists as a mount point, it'll
/// be associated with the first archive mounted there, even though that
/// directory isn't necessarily contained in a real archive.
///
/// This will return NULL if there is no real directory associated with (filename).
pub fn getRealDir(filename: [*:0]const u8) ?[*:0]const u8 {
    return PHYSFS_getRealDir(filename);
}

/// Get a file listing of a search path's directory, using given memory allocator.
pub fn listAlloc(allocator: std.mem.Allocator, dir: [*:0]const u8) !struct {
    allocator: std.mem.Allocator,
    cfiles: [*]?[*:0]const u8,
    files: [][*:0]const u8,

    pub fn deinit(self: *@This()) void {
        PHYSFS_freeList(@ptrCast(self.cfiles));
        self.allocator.free(self.files);
    }
} {
    if (PHYSFS_enumerateFiles(dir)) |cfiles| {
        var file_count: usize = 0;
        while (cfiles[file_count] != null) {
            file_count += 1;
        }

        const result = .{
            .allocator = allocator,
            .cfiles = cfiles,
            .files = try allocator.alloc([*:0]const u8, file_count),
        };
        for (0..file_count) |i| {
            result.files[i] = cfiles[i].?;
        }

        return result;
    }
    return getLastErrorCode().toError();
}

/// Get iterator for current search path.
pub fn getListIterator(dir: [*:0]const u8) !struct {
    cfiles: [*]?[*:0]const u8,
    idx: usize,

    pub fn deinit(it: *@This()) void {
        PHYSFS_freeList(@ptrCast(it.cfiles));
    }

    pub fn next(it: *@This()) ?[*:0]const u8 {
        const p = it.cfiles[it.idx];
        if (p != null) it.idx += 1;
        return p;
    }
} {
    if (PHYSFS_enumerateFiles(dir)) |cfiles| {
        return .{
            .cfiles = cfiles,
            .idx = 0,
        };
    }
    return getLastErrorCode().toError();
}

/// Determine if a file exists in the search path.
pub fn exists(fname: [*:0]const u8) bool {
    return if (PHYSFS_exists(fname) == 1) true else false;
}

/// Get the current write dir. The default write dir is NULL.
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
extern fn PHYSFS_getPrefDir(org: [*:0]const u8, app: [*:0]const u8) ?[*:0]const u8;
extern fn PHYSFS_getWriteDir() ?[*:0]const u8;
extern fn PHYSFS_setWriteDir(path: ?[*:0]const u8) c_int;
extern fn PHYSFS_getSearchPath() ?[*]?[*:0]const u8;
extern fn PHYSFS_mount(dir_or_archive: [*:0]const u8, mount_point: [*:0]const u8, append: c_int) c_int;
extern fn PHYSFS_unmount(dir_or_archive: [*:0]const u8) c_int;
extern fn PHYSFS_mkdir(dirName: [*:0]const u8) c_int;
extern fn PHYSFS_delete(dirName: [*:0]const u8) c_int;
extern fn PHYSFS_getRealDir(filename: [*:0]const u8) ?[*:0]const u8;
extern fn PHYSFS_enumerateFiles(dir: [*:0]const u8) ?[*]?[*:0]const u8;
extern fn PHYSFS_exists(fname: [*:0]const u8) c_int;
