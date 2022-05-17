// zmesh v0.3 (wip)

pub const Shape = @import("Shape.zig");
pub const io = @import("io.zig");
pub const opt = @import("zmeshoptimizer.zig");

const std = @import("std");
const mem = @import("memory.zig");

pub fn init(alloc: std.mem.Allocator) void {
    mem.init(alloc);
}

pub fn deinit() void {
    mem.deinit();
}

comptime {
    _ = Shape;
}
