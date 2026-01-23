const std = @import("std");

pub const Shape = @import("Shape.zig");
pub const io = @import("io.zig");
pub const opt = @import("zmeshoptimizer.zig");

pub const mem = @import("memory.zig");

/// Initialize zmesh memory allocator.
///
/// **WARNING: This function is automatically called by jok.Context during initialization.**
/// **DO NOT call this function directly from game code.**
pub fn init(alloc: std.mem.Allocator) void {
    mem.init(alloc);
}

/// Deinitialize zmesh and cleanup resources.
///
/// **WARNING: This function is automatically called by jok.Context during cleanup.**
/// **DO NOT call this function directly from game code.**
pub fn deinit() void {
    mem.deinit();
}

test {
    std.testing.refAllDecls(@This());
}
