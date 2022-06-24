const std = @import("std");
const assert = std.debug.assert;
const math = std.math;
const Renderer = @import("Renderer.zig");
const sdl = @import("sdl");

var rd: ?Renderer = null;

/// Create default primitive renderer
pub fn init(allocator: std.mem.Allocator) void {
    rd = Renderer.init(allocator);
}

/// Destroy default primitive renderer
pub fn deinit() void {
    rd.?.deinit();
}

/// Clear primitive
pub fn clear() void {
    rd.?.clearVertex(true);
}

/// Render data
pub fn flush(renderer: sdl.Renderer) !void {
    try rd.?.draw(renderer, null);
}
