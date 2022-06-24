const std = @import("std");
const assert = std.debug.assert;
const math = std.math;
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
    rd.?.clear();
}

/// Render data
pub fn flush(renderer: sdl.Renderer) !void {
    try rd.?.draw(renderer);
}

/// Draw triangle
pub fn drawTriangle(
    p0: sdl.PointF,
    p1: sdl.PointF,
    p2: sdl.PointF,
    opt: Renderer.TriangleOption,
) !void {
    try rd.?.addTriangle(p0, p1, p2, opt);
}

/// Draw circle
pub fn drawCircle(
    center: sdl.PointF,
    radius: f32,
    opt: Renderer.CircleOption,
) !void {
    try rd.?.addCircle(center, radius, opt);
}

/// 2D primitive renderer
pub const Renderer = struct {
    vattribs: std.ArrayList(sdl.Vertex),
    vindices: std.ArrayList(u32),

    /// Create renderer
    pub fn init(allocator: std.mem.Allocator) Renderer {
        return .{
            .vattribs = std.ArrayList(sdl.Vertex).init(allocator),
            .vindices = std.ArrayList(u32).init(allocator),
        };
    }

    /// Destroy renderer
    pub fn deinit(self: *Renderer) void {
        self.vattribs.deinit();
        self.vindices.deinit();
    }

    /// Clear renderer
    pub fn clear(self: *Renderer) void {
        self.vattribs.clearRetainingCapacity();
        self.vindices.clearRetainingCapacity();
    }

    /// Add a triangle
    pub const TriangleOption = struct {
        color: sdl.Color = sdl.Color.white,
    };
    pub fn addTriangle(
        self: *Renderer,
        p0: sdl.PointF,
        p1: sdl.PointF,
        p2: sdl.PointF,
        opt: TriangleOption,
    ) !void {
        const base_index = @intCast(u32, self.vattribs.items.len);
        try self.vattribs.appendSlice(&.{
            .{ .position = p0, .color = opt.color },
            .{ .position = p1, .color = opt.color },
            .{ .position = p2, .color = opt.color },
        });
        try self.vindices.appendSlice(&.{
            base_index,
            base_index + 1,
            base_index + 2,
        });
    }

    /// Add a circle
    pub const CircleOption = struct {
        res: u32 = 20,
        color: sdl.Color = sdl.Color.white,
    };
    pub fn addCircle(
        self: *Renderer,
        center: sdl.PointF,
        radius: f32,
        opt: CircleOption,
    ) !void {
        var i: u32 = 0;
        const base_index = @intCast(u32, self.vattribs.items.len);
        const angle = math.tau / @intToFloat(f32, opt.res);
        try self.vattribs.append(.{
            .position = center,
            .color = opt.color,
        });
        while (i < opt.res) : (i += 1) {
            try self.vattribs.append(.{
                .position = .{
                    .x = center.x + radius * @cos(@intToFloat(f32, i) * angle),
                    .y = center.y + radius * @sin(@intToFloat(f32, i) * angle),
                },
                .color = opt.color,
            });
            const last_index = if (i == opt.res - 1) base_index + 1 else base_index + i + 2;
            try self.vindices.appendSlice(&.{
                base_index,
                base_index + i + 1,
                last_index,
            });
        }
    }

    /// Draw batched data
    pub fn draw(self: *Renderer, renderer: sdl.Renderer) !void {
        if (self.vindices.items.len == 0) return;

        try renderer.drawGeometry(
            null,
            self.vattribs.items,
            self.vindices.items,
        );
    }
};
