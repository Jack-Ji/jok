const std = @import("std");

pub fn init(alloc: std.mem.Allocator) void {
    std.debug.assert(mem_allocator == null and mem_allocations == null);

    mem_allocator = alloc;
    mem_allocations = std.AutoHashMap(usize, usize).init(alloc);
    mem_allocations.?.ensureTotalCapacity(32) catch unreachable;

    zmeshMallocPtr = zmeshMalloc;
    zmeshCallocPtr = zmeshCalloc;
    zmeshReallocPtr = zmeshRealloc;
    zmeshFreePtr = zmeshFree;
    meshopt_setAllocator(zmeshMalloc, zmeshFree);
}

pub fn deinit() void {
    mem_allocations.?.deinit();
    mem_allocations = null;
    mem_allocator = null;
}

const MallocFn = *const fn (size: usize) callconv(.c) ?*anyopaque;
const FreeFn = *const fn (ptr: ?*anyopaque) callconv(.c) void;

extern fn meshopt_setAllocator(
    allocate: MallocFn,
    deallocate: FreeFn,
) void;

var mem_allocator: ?std.mem.Allocator = null;
var mem_allocations: ?std.AutoHashMap(usize, usize) = null;
var mem_mutex: std.Thread.Mutex = .{};
const mem_alignment: std.mem.Alignment = .@"16";

extern var zmeshMallocPtr: ?*const fn (size: usize) callconv(.c) ?*anyopaque;

pub fn zmeshMalloc(size: usize) callconv(.c) ?*anyopaque {
    mem_mutex.lock();
    defer mem_mutex.unlock();

    const mem = mem_allocator.?.alignedAlloc(
        u8,
        mem_alignment,
        size,
    ) catch @panic("zmesh: out of memory");

    mem_allocations.?.put(@intFromPtr(mem.ptr), size) catch @panic("zmesh: out of memory");

    return mem.ptr;
}

extern var zmeshCallocPtr: ?*const fn (num: usize, size: usize) callconv(.c) ?*anyopaque;

fn zmeshCalloc(num: usize, size: usize) callconv(.c) ?*anyopaque {
    const ptr = zmeshMalloc(num * size);
    if (ptr != null) {
        @memset(@as([*]u8, @ptrCast(ptr))[0 .. num * size], 0);
        return ptr;
    }
    return null;
}

pub fn zmeshAllocUser(user: ?*anyopaque, size: usize) callconv(.c) ?*anyopaque {
    _ = user;
    return zmeshMalloc(size);
}

extern var zmeshReallocPtr: ?*const fn (ptr: ?*anyopaque, size: usize) callconv(.c) ?*anyopaque;

fn zmeshRealloc(ptr: ?*anyopaque, size: usize) callconv(.c) ?*anyopaque {
    mem_mutex.lock();
    defer mem_mutex.unlock();

    const old_size = if (ptr != null) mem_allocations.?.get(@intFromPtr(ptr.?)).? else 0;

    const old_mem = if (old_size > 0)
        @as([*]align(mem_alignment.toByteUnits()) u8, @ptrCast(@alignCast(ptr)))[0..old_size]
    else
        @as([*]align(mem_alignment.toByteUnits()) u8, undefined)[0..0];

    const mem = mem_allocator.?.realloc(old_mem, size) catch @panic("zmesh: out of memory");

    if (ptr != null) {
        const removed = mem_allocations.?.remove(@intFromPtr(ptr.?));
        std.debug.assert(removed);
    }

    mem_allocations.?.put(@intFromPtr(mem.ptr), size) catch @panic("zmesh: out of memory");

    return mem.ptr;
}

extern var zmeshFreePtr: ?*const fn (maybe_ptr: ?*anyopaque) callconv(.c) void;

fn zmeshFree(maybe_ptr: ?*anyopaque) callconv(.c) void {
    if (maybe_ptr) |ptr| {
        mem_mutex.lock();
        defer mem_mutex.unlock();

        const size = mem_allocations.?.fetchRemove(@intFromPtr(ptr)).?.value;
        const mem = @as([*]align(mem_alignment.toByteUnits()) u8, @ptrCast(@alignCast(ptr)))[0..size];
        mem_allocator.?.free(mem);
    }
}

pub fn zmeshFreeUser(user: ?*anyopaque, ptr: ?*anyopaque) callconv(.c) void {
    _ = user;
    zmeshFree(ptr);
}
