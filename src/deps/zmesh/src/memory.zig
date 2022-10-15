const builtin = @import("builtin");
const std = @import("std");
const Mutex = std.Thread.Mutex;

pub fn init(alloc: std.mem.Allocator) void {
    std.debug.assert(mem_allocator == null and mem_allocations == null);

    mem_allocator = alloc;
    mem_allocations = std.AutoHashMap(usize, usize).init(alloc);
    mem_allocations.?.ensureTotalCapacity(32) catch unreachable;

    meshopt_setAllocator(zmeshMalloc, zmeshFree);
}

pub fn deinit() void {
    mem_allocations.?.deinit();
    mem_allocations = null;
    mem_allocator = null;
}

const MallocFn = *const fn (size: usize) callconv(.C) ?*anyopaque;
const FreeFn = *const fn (ptr: ?*anyopaque) callconv(.C) void;

extern fn meshopt_setAllocator(
    allocate: MallocFn,
    deallocate: FreeFn,
) void;

var mem_allocator: ?std.mem.Allocator = null;
var mem_allocations: ?std.AutoHashMap(usize, usize) = null;
var mem_mutex: Mutex = .{};
const mem_alignment = 16;

pub export fn zmeshMalloc(size: usize) callconv(.C) ?*anyopaque {
    mem_mutex.lock();
    defer mem_mutex.unlock();

    const mem = mem_allocator.?.allocBytes(
        mem_alignment,
        size,
        0,
        @returnAddress(),
    ) catch @panic("zmesh: out of memory");

    mem_allocations.?.put(@ptrToInt(mem.ptr), size) catch @panic("zmesh: out of memory");

    return mem.ptr;
}

export fn zmeshCalloc(num: usize, size: usize) callconv(.C) ?*anyopaque {
    const ptr = zmeshMalloc(num * size);
    if (ptr != null) {
        @memset(@ptrCast([*]u8, ptr), 0, num * size);
        return ptr;
    }
    return null;
}

pub export fn zmeshAllocUser(user: ?*anyopaque, size: usize) callconv(.C) ?*anyopaque {
    _ = user;
    return zmeshMalloc(size);
}

export fn zmeshRealloc(ptr: ?*anyopaque, size: usize) callconv(.C) ?*anyopaque {
    mem_mutex.lock();
    defer mem_mutex.unlock();

    const old_size = if (ptr != null) mem_allocations.?.get(@ptrToInt(ptr.?)).? else 0;

    var old_mem = if (old_size > 0)
        @ptrCast([*]u8, ptr)[0..old_size]
    else
        @as([*]u8, undefined)[0..0];

    const mem = mem_allocator.?.reallocBytes(
        old_mem,
        mem_alignment,
        size,
        mem_alignment,
        0,
        @returnAddress(),
    ) catch @panic("zmesh: out of memory");

    if (ptr != null) {
        const removed = mem_allocations.?.remove(@ptrToInt(ptr.?));
        std.debug.assert(removed);
    }

    mem_allocations.?.put(@ptrToInt(mem.ptr), size) catch @panic("zmesh: out of memory");

    return mem.ptr;
}

export fn zmeshFree(maybe_ptr: ?*anyopaque) callconv(.C) void {
    if (maybe_ptr) |ptr| {
        mem_mutex.lock();
        defer mem_mutex.unlock();

        const size = mem_allocations.?.fetchRemove(@ptrToInt(ptr)).?.value;
        const mem = @ptrCast(
            [*]align(mem_alignment) u8,
            @alignCast(mem_alignment, ptr),
        )[0..size];
        mem_allocator.?.free(mem);
    }
}

pub export fn zmeshFreeUser(user: ?*anyopaque, ptr: ?*anyopaque) callconv(.C) void {
    _ = user;
    zmeshFree(ptr);
}
