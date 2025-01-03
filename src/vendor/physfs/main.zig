const std = @import("std");
const jok = @import("../../jok.zig");
const io = std.io;
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
    FileChanged,
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

/// This closes any files opened via physfs, blanks the search/write paths,
/// frees memory, and invalidates all of your file handles.
pub fn deinit() void {
    if (PHYSFS_deinit() == 0) {
        @panic(getLastErrorCode().toDesc());
    }
}

/// Get the "base dir". This is the directory where the application was run
/// from, which is probably the installation directory, and may or may not
/// be the process's current working directory.
pub fn getBaseDir() [*:0]const u8 {
    return PHYSFS_getBaseDir();
}

/// Get the "pref dir". This is meant to be where users can write personal
/// files (preferences and save games, etc) that are specific to your
/// application. This directory is unique per user, per application.
///
/// This function will decide the appropriate location in the native filesystem,
/// create the directory if necessary, and return a string in
/// platform-dependent notation, suitable for passing to setWriteDir().
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
pub fn getPrefDir(org: [*:0]const u8, app: [*:0]const u8) [*:0]const u8 {
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
pub fn setWriteDir(path: ?[*:0]const u8) Error!void {
    if (PHYSFS_setWriteDir(path) == 0) {
        return getLastErrorCode().toError();
    }
}

/// Get current search paths, using given memory allocator.
pub fn getSearchPathsAlloc(allocator: std.mem.Allocator) Error!struct {
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
pub fn getSearchPathsIterator() Error!struct {
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
pub fn mount(dir_or_archive: [*:0]const u8, mount_point: [*:0]const u8, append: bool) Error!void {
    if (PHYSFS_mount(dir_or_archive, mount_point, if (append) 1 else 0) == 0) {
        return getLastErrorCode().toError();
    }
}

/// Add an archive, contained in a memory buffer, to the search path.
/// `newDir` must be a unique string to identify this archive.
pub fn mountMemory(buf: []const u8, new_dir: [*:0]const u8, mount_point: [*:0]const u8, append: bool) Error!void {
    assert(buf.len > 0);
    if (PHYSFS_mountMemory(
        @ptrCast(buf.ptr),
        buf.len,
        null,
        new_dir,
        mount_point,
        if (append) 1 else 0,
    ) == 0) {
        return getLastErrorCode().toError();
    }
}

/// Remove a directory or archive from the search path.
pub fn unmount(dir_or_archive: [*:0]const u8) Error!void {
    if (PHYSFS_unmount(dir_or_archive) == 0) {
        return getLastErrorCode().toError();
    }
}

/// Create a directory.
///
/// This is specified in platform-independent notation in relation to the
/// write dir. All missing parent directories are also created if they
/// don't exist.
pub fn mkdir(dirname: [*:0]const u8) Error!void {
    if (PHYSFS_mkdir(dirname) == 0) {
        return getLastErrorCode().toError();
    }
}

/// Delete a file or directory.
/// `filename` is specified in platform-independent notation in relation to the
/// write dir. A directory must be empty before this call can delete it.
pub fn delete(filename: [*:0]const u8) Error!void {
    if (PHYSFS_delete(filename) == 0) {
        return getLastErrorCode().toError();
    }
}

/// Figure out where in the search path a file resides.
/// The file is specified in platform-independent notation. The returned
/// filename will be the element of the search path where the file was found,
/// which may be a directory, or an archive. Even if there are multiple
/// matches in different parts of the search path, only the first one found
/// is used, just like when opening a file.
pub fn getRealDir(filename: [*:0]const u8) ?[*:0]const u8 {
    return PHYSFS_getRealDir(filename);
}

/// Get a file listing of a search path's directory, using given memory allocator.
pub const ListedFiles = struct {
    allocator: std.mem.Allocator,
    cfiles: [*]?[*:0]const u8,
    files: [][*:0]const u8,

    pub fn deinit(self: *@This()) void {
        PHYSFS_freeList(@ptrCast(self.cfiles));
        self.allocator.free(self.files);
    }
};
pub fn listAlloc(allocator: std.mem.Allocator, dir: [*:0]const u8) Error!ListedFiles {
    if (PHYSFS_enumerateFiles(dir)) |cfiles| {
        var file_count: usize = 0;
        while (cfiles[file_count] != null) {
            file_count += 1;
        }

        const result = ListedFiles{
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

/// Get iterator for directory's files.
pub const ListIterator = struct {
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
};
pub fn getListIterator(dir: [*:0]const u8) Error!ListIterator {
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
    return if (PHYSFS_exists(fname) == 0) false else true;
}

/// Get various information about a directory or a file.
pub fn fstat(fname: [*:0]const u8) Error!FileStat {
    var result: FileStat = undefined;
    if (PHYSFS_stat(fname, &result) == 0) {
        return getLastErrorCode().toError();
    }
    return result;
}

/// Open file in VFS
///
/// ZIP files may be password-protected. As the PkWare specs specify, each
/// file in the .zip may have a different password, so you call
/// open("file_that_i_want.txt$PASSWORD", .read) to make it work.
pub const OpenMode = enum {
    read,
    write,
    append,
};
pub fn open(fname: [*:0]const u8, mode: OpenMode) Error!File {
    const handle = switch (mode) {
        .read => PHYSFS_openRead(fname),
        .write => PHYSFS_openWrite(fname),
        .append => PHYSFS_openAppend(fname),
    };
    if (handle) |h| {
        return .{
            .handle = h,
        };
    }
    return getLastErrorCode().toError();
}

/// An opened file
pub const File = struct {
    handle: *FileHandle,

    /// Close opened file
    pub fn close(self: File) void {
        if (PHYSFS_close(self.handle) == 0) {
            @panic(getLastErrorCode().toDesc());
        }
    }

    /// Read bytes from a filehandle
    pub fn read(self: File, data: []u8) Error!usize {
        const ret = PHYSFS_readBytes(self.handle, data.ptr, data.len);
        if (ret == -1) {
            return getLastErrorCode().toError();
        }
        return @as(usize, @intCast(ret));
    }

    /// Read all bytes from a filehandle, using given memory allocator.
    /// Note that if another process/thread is writing to this file at the same
    /// time, then the information this function supplies could be incorrect
    /// before you get it. Use with caution, or better yet, don't use at all.
    pub fn readAllAlloc(self: File, allocator: std.mem.Allocator) Error![]const u8 {
        const total = try self.length();
        const data = try allocator.alloc(u8, total);
        errdefer allocator.free(data);
        const read_len = try self.read(data);
        if (read_len != total) {
            return error.FileChanged;
        }
        return data;
    }

    /// Write bytes into a filehandle
    pub fn write(self: File, data: []const u8) Error!usize {
        try self.writeAll(data);
        return data.len;
    }

    /// Write all bytes into a filehandle
    pub fn writeAll(self: File, data: []const u8) Error!void {
        const ret = PHYSFS_writeBytes(self.handle, data.ptr, data.len);
        if (ret != @as(i64, @intCast(data.len))) {
            return getLastErrorCode().toError();
        }
    }

    /// Check for end-of-file state.
    pub fn eof(self: File) bool {
        return if (PHYSFS_eof(self.handle) == 0) false else true;
    }

    /// Determine current position within a filehandle.
    pub fn tell(self: File) Error!usize {
        const ret = PHYSFS_tell(self.handle);
        if (ret == -1) {
            return getLastErrorCode().toError();
        }
        return @as(usize, @intCast(ret));
    }

    /// Seek to a new position within a filehandle.
    /// The next read or write will occur at that place. Seeking past the
    /// beginning or end of the file is not allowed, and causes an error.
    pub fn seek(self: File, pos: usize) Error!void {
        if (PHYSFS_seek(self.handle, pos) == 0) {
            return getLastErrorCode().toError();
        }
    }

    /// Get file's total length
    /// Note that if another process/thread is writing to this file at the same
    /// time, then the information this function supplies could be incorrect
    /// before you get it. Use with caution, or better yet, don't use at all.
    pub fn length(self: File) Error!usize {
        const ret = PHYSFS_fileLength(self.handle);
        if (ret == -1) {
            return getLastErrorCode().toError();
        }
        return @as(usize, @intCast(ret));
    }

    /// Define an i/o buffer for a file handle. A memory block of (bufsize) bytes
    /// will be allocated and associated with (handle).
    ///
    /// For files opened for reading, up to (bufsize) bytes are read from (handle)
    /// and stored in the internal buffer. Calls to read() will pull from this
    /// buffer until it is empty, and then refill it for more reading.
    /// Note that compressed files, like ZIP archives, will decompress while
    /// buffering, so this can be handy for offsetting CPU-intensive operations.
    /// The buffer isn't filled until you do your next read.
    ///
    /// For files opened for writing, data will be buffered to memory until the
    /// buffer is full or the buffer is flushed. Closing a handle implicitly
    /// causes a flush...check your return values!
    ///
    /// Seeking, etc transparently accounts for buffering.
    ///
    /// You can resize an existing buffer by calling this function more than once
    /// on the same file. Setting the buffer size to zero will free an existing
    /// buffer.
    ///
    /// File handles are unbuffered by default.
    pub fn setBuffer(self: File, buf_size: usize) Error!void {
        if (PHYSFS_setBuffer(self.handle, buf_size) == 0) {
            return getLastErrorCode().toError();
        }
    }

    /// Flush a buffered PhysicsFS file handle.
    ///
    /// For buffered files opened for writing, this will put the current contents
    /// of the buffer to disk and flag the buffer as empty if possible.
    ///
    /// For buffered files opened for reading or unbuffered files, this is a safe
    /// no-op, and will report success.
    pub fn flush(self: File) Error!void {
        if (PHYSFS_flush(self.handle) == 0) {
            return getLastErrorCode().toError();
        }
    }

    /// Get std.io.Reader
    pub const Reader = io.Reader(File, Error, read);
    pub fn reader(self: File) Reader {
        return .{ .context = self };
    }

    /// Get std.io.Writer
    pub const Writer = io.Writer(File, Error, write);
    pub fn writer(self: File) Writer {
        return .{ .context = self };
    }
};

//------------------------------------------------------------------------------
// Custom memory allocator implementation (private)
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
// Custom adapters for other modules
//------------------------------------------------------------------------------

pub const stb = struct {
    pub fn writeCallback(ctx: ?*anyopaque, data: ?*anyopaque, size: c_int) callconv(.C) void {
        const handle: *File = @alignCast(@ptrCast(ctx.?));
        var wdata: []u8 = undefined;
        wdata.ptr = @ptrCast(data.?);
        wdata.len = @intCast(size);
        handle.writeAll(wdata) catch |e| @panic(@errorName(e));
    }
};

pub const zaudio = struct {
    const AudioVfs = jok.zaudio.Vfs;
    const AudioResult = jok.zaudio.Result;
    const AudioFileHandle = AudioVfs.FileHandle;
    const AudioOpenMode = AudioVfs.OpenMode;
    const SeekOrigin = AudioVfs.SeekOrigin;
    const FileInfo = AudioVfs.FileInfo;

    fn onOpen(_: *AudioVfs, file_path: [*:0]const u8, mode: AudioOpenMode, handle: *AudioFileHandle) callconv(.C) AudioResult {
        const open_mode: OpenMode = if (mode == .read) .read else .write;
        const file = open(file_path, open_mode) catch |e| @panic(@errorName(e));
        handle.* = @ptrCast(file.handle);
        return .success;
    }
    fn onOpenW(_: *AudioVfs, file_path: [*:0]const u32, mode: AudioOpenMode, handle: *AudioFileHandle) callconv(.C) AudioResult {
        _ = file_path;
        _ = mode;
        _ = handle;
        return .invalid_operation;
    }
    fn onClose(_: *AudioVfs, handle: AudioFileHandle) callconv(.C) AudioResult {
        const file = File{
            .handle = @ptrCast(handle),
        };
        file.close();
        return .success;
    }
    fn onRead(_: *AudioVfs, handle: AudioFileHandle, dst: [*]u8, size: usize, bytes_read: *usize) callconv(.C) AudioResult {
        const file = File{
            .handle = @ptrCast(handle),
        };
        var data: []u8 = undefined;
        data.ptr = dst;
        data.len = size;
        bytes_read.* = file.read(data) catch |e| @panic(@errorName(e));
        return .success;
    }
    fn onWrite(_: *AudioVfs, handle: AudioFileHandle, src: [*]const u8, size: usize, bytes_written: *usize) callconv(.C) AudioResult {
        const file = File{
            .handle = @ptrCast(handle),
        };
        var data: []u8 = undefined;
        data.ptr = @constCast(src);
        data.len = size;
        file.writeAll(data) catch |e| @panic(@errorName(e));
        bytes_written.* = size;
        return .success;
    }
    fn onSeek(_: *AudioVfs, handle: AudioFileHandle, offset: i64, origin: SeekOrigin) callconv(.C) AudioResult {
        const file = File{
            .handle = @ptrCast(handle),
        };
        const curoff: isize = @intCast(file.tell() catch |e| @panic(@errorName(e)));
        const size: isize = @intCast(file.length() catch |e| @panic(@errorName(e)));
        switch (origin) {
            .start => file.seek(@intCast(offset)) catch |e| @panic(@errorName(e)),
            .current => file.seek(@intCast(curoff + offset)) catch |e| @panic(@errorName(e)),
            .end => file.seek(@intCast(size + offset)) catch |e| @panic(@errorName(e)),
        }
        return .success;
    }
    fn onTell(_: *AudioVfs, handle: AudioFileHandle, offset: *i64) callconv(.C) AudioResult {
        const file = File{
            .handle = @ptrCast(handle),
        };
        offset.* = @intCast(file.tell() catch |e| @panic(@errorName(e)));
        return .success;
    }
    fn onInfo(_: *AudioVfs, handle: AudioFileHandle, info: *FileInfo) callconv(.C) AudioResult {
        const file = File{
            .handle = @ptrCast(handle),
        };
        const size = file.length() catch |e| @panic(@errorName(e));
        info.* = .{
            .size_in_bytes = size,
        };
        return .success;
    }

    pub var vfs: AudioVfs = .{
        .on_open = onOpen,
        .on_openw = onOpenW,
        .on_close = onClose,
        .on_read = onRead,
        .on_write = onWrite,
        .on_seek = onSeek,
        .on_tell = onTell,
        .on_info = onInfo,
    };
};

pub const zmesh = struct {
    const ZmeshFileOptions = jok.zmesh.io.zcgltf.FileOptions;
    const ZmeshMemoryOptions = jok.zmesh.io.zcgltf.MemoryOptions;
    const ZmeshResult = jok.zmesh.io.zcgltf.Result;

    fn read(
        mem_opts: *const ZmeshMemoryOptions,
        file_opts: *const ZmeshFileOptions,
        path: [*:0]const u8,
        size: *usize,
        data: *?*anyopaque,
    ) callconv(.C) ZmeshResult {
        _ = file_opts;

        const handle = open(path, .read) catch |e| {
            if (e == error.OutOfMemory) return .out_of_memory;
            if (e == error.NotFound) return .file_not_found;
            @panic(@errorName(e));
        };
        defer handle.close();

        const file_size = if (@intFromPtr(size) != 0 and size.* != 0)
            size.*
        else
            handle.length() catch |e| @panic(@errorName(e));
        size.* = file_size;
        data.* = mem_opts.alloc_func.?(
            mem_opts.user_data,
            file_size,
        );
        if (data.* == null) {
            return .out_of_memory;
        }

        var buf: []u8 = undefined;
        buf.ptr = @ptrCast(data.*.?);
        buf.len = file_size;
        const read_size = handle.read(buf) catch |e| @panic(@errorName(e));
        if (read_size != file_size) {
            mem_opts.free_func.?(mem_opts.user_data, buf.ptr);
            return .io_error;
        }
        return .success;
    }

    fn release(
        mem_opts: *const ZmeshMemoryOptions,
        file_opts: *const ZmeshFileOptions,
        data: ?*anyopaque,
    ) callconv(.C) void {
        _ = file_opts;

        mem_opts.free_func.?(mem_opts.user_data, data);
    }

    pub const file_options = ZmeshFileOptions{
        .read = read,
        .release = release,
    };
};

//------------------------------------------------------------------------------
// C api declarations
//------------------------------------------------------------------------------
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

    pub fn toError(ec: ErrorCode) Error {
        return switch (ec) {
            .ok => unreachable,
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
extern fn PHYSFS_mountMemory(buf: *const anyopaque, len: usize, dummy: ?*anyopaque, new_dir: [*:0]const u8, mount_point: [*:0]const u8, append: c_int) c_int;
extern fn PHYSFS_unmount(dir_or_archive: [*:0]const u8) c_int;
extern fn PHYSFS_mkdir(dirName: [*:0]const u8) c_int;
extern fn PHYSFS_delete(dirName: [*:0]const u8) c_int;
extern fn PHYSFS_getRealDir(filename: [*:0]const u8) ?[*:0]const u8;
extern fn PHYSFS_enumerateFiles(dir: [*:0]const u8) ?[*]?[*:0]const u8;
extern fn PHYSFS_exists(fname: [*:0]const u8) c_int;
const FileType = enum(c_int) {
    regular,
    directory,
    symlink,
    other,
};
const FileStat = extern struct {
    size: i64, // size in bytes, -1 for non-files and unknown
    mtime: i64, // last modification time
    ctime: i64, // file creation time
    atime: i64, // file access time
    type: FileType, // file type
    readonly: i32, // non-zero if read only, zero if writable
};
extern fn PHYSFS_stat(fname: [*:0]const u8, stat: *FileStat) c_int;
const FileHandle = opaque {};
extern fn PHYSFS_openWrite(filename: [*:0]const u8) ?*FileHandle;
extern fn PHYSFS_openAppend(filename: [*:0]const u8) ?*FileHandle;
extern fn PHYSFS_openRead(filename: [*:0]const u8) ?*FileHandle;
extern fn PHYSFS_close(handle: *FileHandle) c_int;
extern fn PHYSFS_readBytes(handle: *FileHandle, buf: [*]u8, len: u64) i64;
extern fn PHYSFS_writeBytes(handle: *FileHandle, buf: [*]const u8, len: u64) i64;
extern fn PHYSFS_eof(handle: *FileHandle) c_int;
extern fn PHYSFS_tell(handle: *FileHandle) i64;
extern fn PHYSFS_seek(handle: *FileHandle, pos: u64) c_int;
extern fn PHYSFS_fileLength(handle: *FileHandle) i64;
extern fn PHYSFS_setBuffer(handle: *FileHandle, bufsize: u64) c_int;
extern fn PHYSFS_flush(handle: *FileHandle) c_int;
