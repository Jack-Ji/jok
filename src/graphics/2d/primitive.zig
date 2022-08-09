const std = @import("std");
const assert = std.debug.assert;
const math = std.math;
const sdl = @import("sdl");
const jok = @import("../../jok.zig");
const zmath = jok.zmath;

pub const CommonDrawOption = struct {
    thickness: f32 = 0, // zero means filling geometries
    rotate_degree: f32 = 0, // rotating angle around anchor_pos
    anchor_pos: ?sdl.PointF = null, // null means using geometry center
    color: sdl.Color = sdl.Color.white,
};

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

/// Draw equilateral triangle
pub fn drawEquilateralTriangle(center: sdl.PointF, side_len: f32, opt: CommonDrawOption) !void {
    const height = math.sqrt(@as(f32, 3)) / 2.0 * side_len;
    const size = height * 2 / 3;
    const p0 = sdl.PointF{ .x = center.x, .y = center.y - size };
    const p1 = sdl.PointF{ .x = center.x + side_len / 2, .y = center.y + height - size };
    const p2 = sdl.PointF{ .x = center.x - side_len / 2, .y = center.y + height - size };
    try rd.?.addTriangle(p0, p1, p2, opt);
}

/// Draw triangle
pub fn drawTriangle(p0: sdl.PointF, p1: sdl.PointF, p2: sdl.PointF, opt: CommonDrawOption) !void {
    try rd.?.addTriangle(p0, p1, p2, opt);
}

/// Draw square
pub fn drawSquare(center: sdl.PointF, half_size: f32, opt: CommonDrawOption) !void {
    try rd.?.addRectangle(.{
        .x = center.x - half_size,
        .y = center.y - half_size,
        .width = 2 * half_size,
        .height = 2 * half_size,
    }, opt);
}

/// Draw rectangle
pub fn drawRectangle(rect: sdl.RectangleF, opt: CommonDrawOption) !void {
    try rd.?.addRectangle(rect, opt);
}

/// Draw line
pub fn drawLine(from: sdl.PointF, to: sdl.PointF, opt: CommonDrawOption) !void {
    try rd.?.addLine(from, to, opt);
}

/// Draw circle
pub fn drawCircle(center: sdl.PointF, radius: f32, opt: EllipseOption) !void {
    try rd.?.addEllipse(center, radius, radius, opt);
}

/// Draw ecllipse
pub const EllipseOption = struct {
    common_opt: CommonDrawOption = .{},
    segments: u32 = 25,
};
pub fn drawEllipse(center: sdl.PointF, half_width: f32, half_height: f32, opt: EllipseOption) !void {
    try rd.?.addEllipse(center, half_width, half_height, opt);
}

/// 2D primitive renderer
const Renderer = struct {
    vattribs: std.ArrayList(sdl.Vertex),
    vindices: std.ArrayList(u32),

    /// Create renderer
    fn init(allocator: std.mem.Allocator) Renderer {
        return .{
            .vattribs = std.ArrayList(sdl.Vertex).init(allocator),
            .vindices = std.ArrayList(u32).init(allocator),
        };
    }

    /// Destroy renderer
    fn deinit(self: *Renderer) void {
        self.vattribs.deinit();
        self.vindices.deinit();
    }

    /// Clear renderer
    fn clear(self: *Renderer) void {
        self.vattribs.clearRetainingCapacity();
        self.vindices.clearRetainingCapacity();
    }

    // Calculate transform matrix
    inline fn getTransformMatrix(anchor_pos: sdl.PointF, rotate_degree: f32) zmath.Mat {
        const translate1_m = zmath.translation(-anchor_pos.x, -anchor_pos.y, 0);
        const rotate_m = zmath.rotationZ(rotate_degree * math.pi / 180);
        const translate2_m = zmath.translation(anchor_pos.x, anchor_pos.y, 0);
        return zmath.mul(zmath.mul(translate1_m, rotate_m), translate2_m);
    }

    // Transform coordinate
    inline fn transformPoint(pos: sdl.PointF, trs: zmath.Mat) sdl.PointF {
        const v = zmath.f32x4(pos.x, pos.y, 0, 1);
        const tv = zmath.mul(v, trs);
        return .{ .x = tv[0], .y = tv[1] };
    }

    inline fn addStripe(
        self: *Renderer,
        inner_base_index: u32,
        outer_base_index: u32,
    ) !void {
        assert(inner_base_index < outer_base_index);
        const npoints = @intCast(u32, self.vattribs.items.len - outer_base_index);
        assert(npoints == outer_base_index - inner_base_index);
        var i: u32 = 0;
        while (i < npoints) : (i += 1) {
            const idx = @intCast(u32, i);
            const next_idx = if (i + 1 == npoints) 0 else idx + 1;
            try self.vindices.appendSlice(&.{
                inner_base_index + idx,
                outer_base_index + idx,
                outer_base_index + next_idx,
                inner_base_index + idx,
                outer_base_index + next_idx,
                inner_base_index + next_idx,
            });
        }
    }

    /// Add a triangle
    fn addTriangle(
        self: *Renderer,
        p0: sdl.PointF,
        p1: sdl.PointF,
        p2: sdl.PointF,
        opt: CommonDrawOption,
    ) !void {
        const center = sdl.PointF{ .x = (p0.x + p1.x + p2.x) / 3.0, .y = (p0.y + p1.y + p2.y) / 3.0 };
        const transform_m = getTransformMatrix(
            opt.anchor_pos orelse center,
            opt.rotate_degree,
        );
        if (opt.thickness == 0) {
            const base_index = @intCast(u32, self.vattribs.items.len);
            try self.vattribs.append(.{ .position = transformPoint(p0, transform_m), .color = opt.color });
            try self.vattribs.append(.{ .position = transformPoint(p1, transform_m), .color = opt.color });
            try self.vattribs.append(.{ .position = transformPoint(p2, transform_m), .color = opt.color });
            try self.vindices.appendSlice(&.{
                base_index,
                base_index + 1,
                base_index + 2,
            });
        } else {
            const v_center = zmath.f32x4(center.x, center.y, 0, 0);
            const v_p0 = zmath.f32x4(p0.x, p0.y, 0, 0);
            const v_p1 = zmath.f32x4(p1.x, p1.y, 0, 0);
            const v_p2 = zmath.f32x4(p2.x, p2.y, 0, 0);
            const inner_v0 = zmath.normalize2(v_center - v_p0) * zmath.splat(zmath.Vec, opt.thickness) + v_p0;
            const inner_v1 = zmath.normalize2(v_center - v_p1) * zmath.splat(zmath.Vec, opt.thickness) + v_p1;
            const inner_v2 = zmath.normalize2(v_center - v_p2) * zmath.splat(zmath.Vec, opt.thickness) + v_p2;
            const inner_p0 = sdl.PointF{ .x = inner_v0[0], .y = inner_v0[1] };
            const inner_p1 = sdl.PointF{ .x = inner_v1[0], .y = inner_v1[1] };
            const inner_p2 = sdl.PointF{ .x = inner_v2[0], .y = inner_v2[1] };
            const inner_base_index = @intCast(u32, self.vattribs.items.len);
            try self.vattribs.append(.{ .position = transformPoint(inner_p0, transform_m), .color = opt.color });
            try self.vattribs.append(.{ .position = transformPoint(inner_p1, transform_m), .color = opt.color });
            try self.vattribs.append(.{ .position = transformPoint(inner_p2, transform_m), .color = opt.color });
            const outer_base_index = @intCast(u32, self.vattribs.items.len);
            try self.vattribs.append(.{ .position = transformPoint(p0, transform_m), .color = opt.color });
            try self.vattribs.append(.{ .position = transformPoint(p1, transform_m), .color = opt.color });
            try self.vattribs.append(.{ .position = transformPoint(p2, transform_m), .color = opt.color });
            try self.addStripe(inner_base_index, outer_base_index);
        }
    }

    /// Add a rectangle
    fn addRectangle(self: *Renderer, rect: sdl.RectangleF, opt: CommonDrawOption) !void {
        const center = sdl.PointF{ .x = (rect.x + rect.width) / 2.0, .y = (rect.y + rect.height) / 3.0 };
        const transform_m = getTransformMatrix(
            opt.anchor_pos orelse center,
            opt.rotate_degree,
        );
        if (opt.thickness == 0) {
            const base_index = @intCast(u32, self.vattribs.items.len);
            try self.vattribs.append(.{
                .position = transformPoint(.{ .x = rect.x, .y = rect.y }, transform_m),
                .color = opt.color,
            });
            try self.vattribs.append(.{
                .position = transformPoint(.{ .x = rect.x + rect.width, .y = rect.y }, transform_m),
                .color = opt.color,
            });
            try self.vattribs.append(.{
                .position = transformPoint(.{ .x = rect.x + rect.width, .y = rect.y + rect.height }, transform_m),
                .color = opt.color,
            });
            try self.vattribs.append(.{
                .position = transformPoint(.{ .x = rect.x, .y = rect.y + rect.height }, transform_m),
                .color = opt.color,
            });
            try self.vindices.appendSlice(&.{
                base_index,
                base_index + 1,
                base_index + 2,
                base_index,
                base_index + 2,
                base_index + 3,
            });
        } else {
            const outer_p0 = sdl.PointF{ .x = rect.x, .y = rect.y };
            const outer_p1 = sdl.PointF{ .x = rect.x + rect.width, .y = rect.y };
            const outer_p2 = sdl.PointF{ .x = rect.x + rect.width, .y = rect.y + rect.height };
            const outer_p3 = sdl.PointF{ .x = rect.x, .y = rect.y + rect.height };
            const inner_p0 = sdl.PointF{ .x = rect.x + opt.thickness, .y = rect.y + opt.thickness };
            const inner_p1 = sdl.PointF{ .x = rect.x + rect.width - opt.thickness, .y = rect.y + opt.thickness };
            const inner_p2 = sdl.PointF{ .x = rect.x + rect.width - opt.thickness, .y = rect.y + rect.height - opt.thickness };
            const inner_p3 = sdl.PointF{ .x = rect.x + opt.thickness, .y = rect.y + rect.height - opt.thickness };
            const inner_base_index = @intCast(u32, self.vattribs.items.len);
            try self.vattribs.append(.{ .position = transformPoint(inner_p0, transform_m), .color = opt.color });
            try self.vattribs.append(.{ .position = transformPoint(inner_p1, transform_m), .color = opt.color });
            try self.vattribs.append(.{ .position = transformPoint(inner_p2, transform_m), .color = opt.color });
            try self.vattribs.append(.{ .position = transformPoint(inner_p3, transform_m), .color = opt.color });
            const outer_base_index = @intCast(u32, self.vattribs.items.len);
            try self.vattribs.append(.{ .position = transformPoint(outer_p0, transform_m), .color = opt.color });
            try self.vattribs.append(.{ .position = transformPoint(outer_p1, transform_m), .color = opt.color });
            try self.vattribs.append(.{ .position = transformPoint(outer_p2, transform_m), .color = opt.color });
            try self.vattribs.append(.{ .position = transformPoint(outer_p3, transform_m), .color = opt.color });
            try self.addStripe(inner_base_index, outer_base_index);
        }
    }

    /// Add a line
    fn addLine(
        self: *Renderer,
        from: sdl.PointF,
        to: sdl.PointF,
        opt: CommonDrawOption,
    ) !void {
        const base_index = @intCast(u32, self.vattribs.items.len);
        const transform_m = getTransformMatrix(
            opt.anchor_pos orelse sdl.PointF{ .x = (from.x + to.x) / 2.0, .y = (from.y + to.y) / 3.0 },
            opt.rotate_degree,
        );

        // Calculate normal vector
        const thickness = if (opt.thickness == 0) 2 else opt.thickness;
        var dx = to.x - from.x;
        var dy = to.y - from.y;
        if (dx == 0 or dy == 0) return;
        const a = 1 / math.sqrt(dx * dx + dy * dy);
        dx = dx * a * thickness * 0.5;
        dy = dy * a * thickness * 0.5;

        try self.vattribs.append(.{
            .position = transformPoint(.{ .x = from.x - dy, .y = from.y + dx }, transform_m),
            .color = opt.color,
        });
        try self.vattribs.append(.{
            .position = transformPoint(.{ .x = to.x - dy, .y = to.y + dx }, transform_m),
            .color = opt.color,
        });
        try self.vattribs.append(.{
            .position = transformPoint(.{ .x = to.x + dy, .y = to.y - dx }, transform_m),
            .color = opt.color,
        });
        try self.vattribs.append(.{
            .position = transformPoint(.{ .x = from.x + dy, .y = from.y - dx }, transform_m),
            .color = opt.color,
        });
        try self.vindices.appendSlice(&.{
            base_index,
            base_index + 1,
            base_index + 2,
            base_index,
            base_index + 2,
            base_index + 3,
        });
    }

    /// Add a ellipse
    fn addEllipse(
        self: *Renderer,
        center: sdl.PointF,
        half_width: f32,
        half_height: f32,
        opt: EllipseOption,
    ) !void {
        const transform_m = getTransformMatrix(
            opt.common_opt.anchor_pos orelse center,
            opt.common_opt.rotate_degree,
        );
        if (opt.common_opt.thickness == 0) {
            const base_index = @intCast(u32, self.vattribs.items.len);
            const angle = math.tau / @intToFloat(f32, opt.segments);
            try self.vattribs.append(.{
                .position = transformPoint(center, transform_m),
                .color = opt.common_opt.color,
            });
            var i: u32 = 0;
            while (i < opt.segments) : (i += 1) {
                try self.vattribs.append(.{
                    .position = transformPoint(.{
                        .x = center.x + half_width * @cos(@intToFloat(f32, i) * angle),
                        .y = center.y + half_height * @sin(@intToFloat(f32, i) * angle),
                    }, transform_m),
                    .color = opt.common_opt.color,
                });
                const last_index = if (i == opt.segments - 1) base_index + 1 else base_index + i + 2;
                try self.vindices.appendSlice(&.{
                    base_index,
                    base_index + i + 1,
                    last_index,
                });
            }
        } else {
            const angle = math.tau / @intToFloat(f32, opt.segments);
            const inner_base_index = @intCast(u32, self.vattribs.items.len);
            var i: u32 = 0;
            while (i < opt.segments) : (i += 1) {
                try self.vattribs.append(.{
                    .position = transformPoint(.{
                        .x = center.x + (half_width - opt.common_opt.thickness) * @cos(@intToFloat(f32, i) * angle),
                        .y = center.y + (half_height - opt.common_opt.thickness) * @sin(@intToFloat(f32, i) * angle),
                    }, transform_m),
                    .color = opt.common_opt.color,
                });
            }
            const outer_base_index = @intCast(u32, self.vattribs.items.len);
            i = 0;
            while (i < opt.segments) : (i += 1) {
                try self.vattribs.append(.{
                    .position = transformPoint(.{
                        .x = center.x + half_width * @cos(@intToFloat(f32, i) * angle),
                        .y = center.y + half_height * @sin(@intToFloat(f32, i) * angle),
                    }, transform_m),
                    .color = opt.common_opt.color,
                });
            }
            try self.addStripe(inner_base_index, outer_base_index);
        }
    }

    /// Draw batched data
    fn draw(self: *Renderer, renderer: sdl.Renderer) !void {
        if (self.vindices.items.len == 0) return;

        try renderer.drawGeometry(
            null,
            self.vattribs.items,
            self.vindices.items,
        );
    }
};
