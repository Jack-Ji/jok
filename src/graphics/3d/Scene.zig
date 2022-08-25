const std = @import("std");
const assert = std.debug.assert;
const math = std.math;
const Renderer = @import("Renderer.zig");
const Camera = @import("Camera.zig");
const sdl = @import("sdl");
const jok = @import("../../jok.zig");
const @"3d" = jok.gfx.@"3d";
const zmath = @"3d".zmath;
const zmesh = @"3d".zmesh;
const Self = @This();

allocator: std.mem.Allocator,
arena: std.heap.ArenaAllocator,

pub fn init(allocator: std.mem.Allocator) !*Self {
    var self = try allocator.create(Self);
    self.allocator = allocator;
    self.arena = std.heap.ArenaAllocator.init(allocator);
    return self;
}

pub fn deinit(self: *Self) void {
    self.arena.deinit();
    self.allocator.destroy(self);
}
