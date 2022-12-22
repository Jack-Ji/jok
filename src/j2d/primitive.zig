const std = @import("std");
const assert = std.debug.assert;
const math = std.math;
const sdl = @import("sdl");
const jok = @import("../jok.zig");
const zmath = jok.deps.zmath;

pub const CommonDrawOption = struct {
    thickness: f32 = 0, // zero means filling geometries in most cases
    rotate_degree: f32 = 0, // rotating angle around anchor_pos
    anchor_pos: ?sdl.PointF = null, // null means using geometry center
    color: sdl.Color = sdl.Color.white,
};

var rd: ?Renderer = null;

/// Create primitive renderer
pub fn init(ctx: jok.Context) !void {
    rd = Renderer.init(ctx.allocator);
}

/// Destroy primitive renderer
pub fn deinit() void {
    rd.?.deinit();
}

/// Clear primitive
pub fn clear() void {
    rd.?.clear();
}

/// Render data
pub const RenderOption = struct {
    // TODO
};
pub fn draw(renderer: sdl.Renderer, opt: RenderOption) !void {
    _ = opt;
    try rd.?.draw(renderer);
}

/// Draw equilateral triangle
pub fn addEquilateralTriangle(center: sdl.PointF, side_len: f32, opt: CommonDrawOption) !void {
    const height = math.sqrt(@as(f32, 3)) / 2.0 * side_len;
    const size = height * 2 / 3;
    const p0 = sdl.PointF{ .x = center.x, .y = center.y - size };
    const p1 = sdl.PointF{ .x = center.x + side_len / 2, .y = center.y + height - size };
    const p2 = sdl.PointF{ .x = center.x - side_len / 2, .y = center.y + height - size };
    try rd.?.addTriangle(p0, p1, p2, opt);
}

/// Draw triangle
pub fn addTriangle(p0: sdl.PointF, p1: sdl.PointF, p2: sdl.PointF, opt: CommonDrawOption) !void {
    try rd.?.addTriangle(p0, p1, p2, opt);
}

/// Draw square
pub const RectDrawOption = struct {
    common: CommonDrawOption = .{},
    round: ?f32 = null,
    segments: ?u32 = null,
};
pub fn addSquare(center: sdl.PointF, half_size: f32, opt: RectDrawOption) !void {
    try rd.?.addRectangle(.{
        .x = center.x - half_size,
        .y = center.y - half_size,
        .width = 2 * half_size,
        .height = 2 * half_size,
    }, opt);
}

/// Draw rectangle
pub fn addRectangle(rect: sdl.RectangleF, opt: RectDrawOption) !void {
    try rd.?.addRectangle(rect, opt);
}

/// Draw line
pub fn addLine(from: sdl.PointF, to: sdl.PointF, opt: CommonDrawOption) !void {
    try rd.?.addLine(from, to, opt);
}

/// Draw fan
pub const CurveDrawOption = struct {
    common: CommonDrawOption = .{},
    segments: ?u32 = null,
};
pub fn addArc(center: sdl.PointF, radius: f32, from_radian: f32, to_radian: f32, opt: CurveDrawOption) !void {
    try rd.?.addEllipse(center, radius, radius, from_radian, to_radian, opt);
}

pub fn addEllipseArc(center: sdl.PointF, half_width: f32, half_height: f32, from_radian: f32, to_radian: f32, opt: CurveDrawOption) !void {
    try rd.?.addEllipse(center, half_width, half_height, from_radian, to_radian, opt);
}

/// Draw circle
pub fn addCircle(center: sdl.PointF, radius: f32, opt: CurveDrawOption) !void {
    try rd.?.addEllipse(center, radius, radius, 0, math.tau, opt);
}

/// Draw ecllipse
pub fn addEllipse(center: sdl.PointF, half_width: f32, half_height: f32, opt: CurveDrawOption) !void {
    try rd.?.addEllipse(center, half_width, half_height, 0, math.tau, opt);
}

/// Draw polyline
pub fn addPolyline(points: []sdl.PointF, opt: CommonDrawOption) !void {
    if (points.len < 2) return;
    try rd.?.addPolyline(points, opt);
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
        is_loop: bool,
    ) !void {
        assert(inner_base_index < outer_base_index);
        const npoints = @intCast(u32, self.vattribs.items.len - outer_base_index);
        assert(npoints == outer_base_index - inner_base_index);
        var i: u32 = 0;
        while (i < npoints) : (i += 1) {
            const idx = @intCast(u32, i);
            if (is_loop) {
                const next_idx = if (i + 1 == npoints) 0 else idx + 1;
                try self.vindices.appendSlice(&.{
                    inner_base_index + idx,
                    outer_base_index + idx,
                    outer_base_index + next_idx,
                    inner_base_index + idx,
                    outer_base_index + next_idx,
                    inner_base_index + next_idx,
                });
            } else if (i < npoints - 1) {
                const next_idx = idx + 1;
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
            try self.addStripe(inner_base_index, outer_base_index, true);
        }
    }

    /// Add a rectangle
    fn addRectangle(self: *Renderer, rect: sdl.RectangleF, opt: RectDrawOption) !void {
        const S = struct {
            inline fn addRound(
                attribs: *std.ArrayList(sdl.Vertex),
                center: sdl.PointF,
                radius: f32,
                segments: u32,
                from_angle: f32,
                transform: zmath.Mat,
                color: sdl.Color,
            ) !void {
                const segment_angle = math.pi / 2.0 / @intToFloat(f32, segments);
                var i: u32 = 0;
                while (i <= segments) : (i += 1) {
                    try attribs.append(.{
                        .position = transformPoint(.{
                            .x = center.x + radius * @cos(@intToFloat(f32, i) * segment_angle + from_angle),
                            .y = center.y + radius * @sin(@intToFloat(f32, i) * segment_angle + from_angle),
                        }, transform),
                        .color = color,
                    });
                }
            }
        };

        const center = sdl.PointF{ .x = rect.x + rect.width / 2.0, .y = rect.y + rect.height / 3.0 };
        const common = opt.common;
        const transform_m = getTransformMatrix(
            common.anchor_pos orelse center,
            common.rotate_degree,
        );
        if (common.thickness == 0) {
            const base_index = @intCast(u32, self.vattribs.items.len);
            var r = opt.round orelse 0;
            if (r > 0) {
                const segments = opt.segments orelse math.max(@floatToInt(u32, (0.25 * math.tau * r) / 20), 18);
                try self.vattribs.append(.{
                    .position = transformPoint(center, transform_m),
                    .color = common.color,
                });

                try self.vattribs.append(.{
                    .position = transformPoint(.{ .x = rect.x + r, .y = rect.y }, transform_m),
                    .color = common.color,
                });
                try self.vattribs.append(.{
                    .position = transformPoint(.{ .x = rect.x + rect.width - r, .y = rect.y }, transform_m),
                    .color = common.color,
                });
                try S.addRound(
                    &self.vattribs,
                    .{ .x = rect.x + rect.width - r, .y = rect.y + r },
                    r,
                    segments,
                    math.pi * 1.5,
                    transform_m,
                    common.color,
                );

                try self.vattribs.append(.{
                    .position = transformPoint(.{ .x = rect.x + rect.width, .y = rect.y + r }, transform_m),
                    .color = common.color,
                });
                try self.vattribs.append(.{
                    .position = transformPoint(.{ .x = rect.x + rect.width, .y = rect.y + rect.height - r }, transform_m),
                    .color = common.color,
                });
                try S.addRound(
                    &self.vattribs,
                    .{ .x = rect.x + rect.width - r, .y = rect.y + rect.height - r },
                    r,
                    segments,
                    0,
                    transform_m,
                    common.color,
                );

                try self.vattribs.append(.{
                    .position = transformPoint(.{ .x = rect.x + rect.width - r, .y = rect.y + rect.height }, transform_m),
                    .color = common.color,
                });
                try self.vattribs.append(.{
                    .position = transformPoint(.{ .x = rect.x + r, .y = rect.y + rect.height }, transform_m),
                    .color = common.color,
                });
                try S.addRound(
                    &self.vattribs,
                    .{ .x = rect.x + r, .y = rect.y + rect.height - r },
                    r,
                    segments,
                    math.pi * 0.5,
                    transform_m,
                    common.color,
                );

                try self.vattribs.append(.{
                    .position = transformPoint(.{ .x = rect.x, .y = rect.y + rect.height - r }, transform_m),
                    .color = common.color,
                });
                try self.vattribs.append(.{
                    .position = transformPoint(.{ .x = rect.x, .y = rect.y + r }, transform_m),
                    .color = common.color,
                });
                try S.addRound(
                    &self.vattribs,
                    .{ .x = rect.x + r, .y = rect.y + r },
                    r,
                    segments,
                    math.pi,
                    transform_m,
                    common.color,
                );

                var i = base_index + 1;
                while (i < @intCast(u32, self.vattribs.items.len)) : (i += 1) {
                    if (i < @intCast(u32, self.vattribs.items.len - 1)) {
                        try self.vindices.appendSlice(&.{ base_index, i, i + 1 });
                    } else {
                        try self.vindices.appendSlice(&.{ base_index, i, base_index + 1 });
                    }
                }
            } else {
                try self.vattribs.append(.{
                    .position = transformPoint(.{ .x = rect.x, .y = rect.y }, transform_m),
                    .color = common.color,
                });
                try self.vattribs.append(.{
                    .position = transformPoint(.{ .x = rect.x + rect.width, .y = rect.y }, transform_m),
                    .color = common.color,
                });
                try self.vattribs.append(.{
                    .position = transformPoint(.{ .x = rect.x + rect.width, .y = rect.y + rect.height }, transform_m),
                    .color = common.color,
                });
                try self.vattribs.append(.{
                    .position = transformPoint(.{ .x = rect.x, .y = rect.y + rect.height }, transform_m),
                    .color = common.color,
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
        } else {
            var r = opt.round orelse 0;
            if (r > 0) {
                const segments = opt.segments orelse math.max(@floatToInt(u32, (0.25 * math.tau * r) / 20), 18);

                // inner points
                const inner_base_index = @intCast(u32, self.vattribs.items.len);
                {
                    try self.vattribs.append(.{
                        .position = transformPoint(.{ .x = rect.x + r + common.thickness, .y = rect.y + common.thickness }, transform_m),
                        .color = common.color,
                    });
                    try self.vattribs.append(.{
                        .position = transformPoint(.{ .x = rect.x + rect.width - r - common.thickness, .y = rect.y + common.thickness }, transform_m),
                        .color = common.color,
                    });
                    try S.addRound(
                        &self.vattribs,
                        .{ .x = rect.x + rect.width - r - common.thickness, .y = rect.y + common.thickness + r },
                        r,
                        segments,
                        math.pi * 1.5,
                        transform_m,
                        common.color,
                    );

                    try self.vattribs.append(.{
                        .position = transformPoint(.{ .x = rect.x + rect.width - common.thickness, .y = rect.y + r + common.thickness }, transform_m),
                        .color = common.color,
                    });
                    try self.vattribs.append(.{
                        .position = transformPoint(.{ .x = rect.x + rect.width - common.thickness, .y = rect.y + rect.height - r - common.thickness }, transform_m),
                        .color = common.color,
                    });
                    try S.addRound(
                        &self.vattribs,
                        .{ .x = rect.x + rect.width - common.thickness - r, .y = rect.y + rect.height - r - common.thickness },
                        r,
                        segments,
                        0,
                        transform_m,
                        common.color,
                    );

                    try self.vattribs.append(.{
                        .position = transformPoint(.{ .x = rect.x + rect.width - r - common.thickness, .y = rect.y + rect.height - common.thickness }, transform_m),
                        .color = common.color,
                    });
                    try self.vattribs.append(.{
                        .position = transformPoint(.{ .x = rect.x + r + common.thickness, .y = rect.y + rect.height - common.thickness }, transform_m),
                        .color = common.color,
                    });
                    try S.addRound(
                        &self.vattribs,
                        .{ .x = rect.x + r + common.thickness, .y = rect.y + rect.height - common.thickness - r },
                        r,
                        segments,
                        math.pi * 0.5,
                        transform_m,
                        common.color,
                    );

                    try self.vattribs.append(.{
                        .position = transformPoint(.{ .x = rect.x + common.thickness, .y = rect.y + rect.height - r - common.thickness }, transform_m),
                        .color = common.color,
                    });
                    try self.vattribs.append(.{
                        .position = transformPoint(.{ .x = rect.x + common.thickness, .y = rect.y + r + common.thickness }, transform_m),
                        .color = common.color,
                    });
                    try S.addRound(
                        &self.vattribs,
                        .{ .x = rect.x + common.thickness + r, .y = rect.y + r + common.thickness },
                        r,
                        segments,
                        math.pi,
                        transform_m,
                        common.color,
                    );
                }

                // outer points
                const outer_base_index = @intCast(u32, self.vattribs.items.len);
                {
                    try self.vattribs.append(.{
                        .position = transformPoint(.{ .x = rect.x + r, .y = rect.y }, transform_m),
                        .color = common.color,
                    });
                    try self.vattribs.append(.{
                        .position = transformPoint(.{ .x = rect.x + rect.width - r, .y = rect.y }, transform_m),
                        .color = common.color,
                    });
                    try S.addRound(
                        &self.vattribs,
                        .{ .x = rect.x + rect.width - r, .y = rect.y + r },
                        r,
                        segments,
                        math.pi * 1.5,
                        transform_m,
                        common.color,
                    );

                    try self.vattribs.append(.{
                        .position = transformPoint(.{ .x = rect.x + rect.width, .y = rect.y + r }, transform_m),
                        .color = common.color,
                    });
                    try self.vattribs.append(.{
                        .position = transformPoint(.{ .x = rect.x + rect.width, .y = rect.y + rect.height - r }, transform_m),
                        .color = common.color,
                    });
                    try S.addRound(
                        &self.vattribs,
                        .{ .x = rect.x + rect.width - r, .y = rect.y + rect.height - r },
                        r,
                        segments,
                        0,
                        transform_m,
                        common.color,
                    );

                    try self.vattribs.append(.{
                        .position = transformPoint(.{ .x = rect.x + rect.width - r, .y = rect.y + rect.height }, transform_m),
                        .color = common.color,
                    });
                    try self.vattribs.append(.{
                        .position = transformPoint(.{ .x = rect.x + r, .y = rect.y + rect.height }, transform_m),
                        .color = common.color,
                    });
                    try S.addRound(
                        &self.vattribs,
                        .{ .x = rect.x + r, .y = rect.y + rect.height - r },
                        r,
                        segments,
                        math.pi * 0.5,
                        transform_m,
                        common.color,
                    );

                    try self.vattribs.append(.{
                        .position = transformPoint(.{ .x = rect.x, .y = rect.y + rect.height - r }, transform_m),
                        .color = common.color,
                    });
                    try self.vattribs.append(.{
                        .position = transformPoint(.{ .x = rect.x, .y = rect.y + r }, transform_m),
                        .color = common.color,
                    });
                    try S.addRound(
                        &self.vattribs,
                        .{ .x = rect.x + r, .y = rect.y + r },
                        r,
                        segments,
                        math.pi,
                        transform_m,
                        common.color,
                    );
                }

                try self.addStripe(inner_base_index, outer_base_index, true);
            } else {
                const outer_p0 = sdl.PointF{ .x = rect.x, .y = rect.y };
                const outer_p1 = sdl.PointF{ .x = rect.x + rect.width, .y = rect.y };
                const outer_p2 = sdl.PointF{ .x = rect.x + rect.width, .y = rect.y + rect.height };
                const outer_p3 = sdl.PointF{ .x = rect.x, .y = rect.y + rect.height };
                const inner_p0 = sdl.PointF{ .x = rect.x + common.thickness, .y = rect.y + common.thickness };
                const inner_p1 = sdl.PointF{ .x = rect.x + rect.width - common.thickness, .y = rect.y + common.thickness };
                const inner_p2 = sdl.PointF{ .x = rect.x + rect.width - common.thickness, .y = rect.y + rect.height - common.thickness };
                const inner_p3 = sdl.PointF{ .x = rect.x + common.thickness, .y = rect.y + rect.height - common.thickness };
                const inner_base_index = @intCast(u32, self.vattribs.items.len);
                try self.vattribs.append(.{ .position = transformPoint(inner_p0, transform_m), .color = common.color });
                try self.vattribs.append(.{ .position = transformPoint(inner_p1, transform_m), .color = common.color });
                try self.vattribs.append(.{ .position = transformPoint(inner_p2, transform_m), .color = common.color });
                try self.vattribs.append(.{ .position = transformPoint(inner_p3, transform_m), .color = common.color });
                const outer_base_index = @intCast(u32, self.vattribs.items.len);
                try self.vattribs.append(.{ .position = transformPoint(outer_p0, transform_m), .color = common.color });
                try self.vattribs.append(.{ .position = transformPoint(outer_p1, transform_m), .color = common.color });
                try self.vattribs.append(.{ .position = transformPoint(outer_p2, transform_m), .color = common.color });
                try self.vattribs.append(.{ .position = transformPoint(outer_p3, transform_m), .color = common.color });
                try self.addStripe(inner_base_index, outer_base_index, true);
            }
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
        from_radian: f32,
        to_radian: f32,
        opt: CurveDrawOption,
    ) !void {
        assert(to_radian >= from_radian);
        const transform_m = getTransformMatrix(
            opt.common.anchor_pos orelse center,
            opt.common.rotate_degree,
        );
        const half_big = math.max(half_width, half_height);
        const half_small = math.min(half_width, half_height);
        const total_angle = math.min(to_radian - from_radian, math.tau);
        const is_loop = math.approxEqRel(f32, total_angle, math.tau, math.f32_epsilon);
        const segments = opt.segments orelse
            math.max(@floatToInt(u32, total_angle / math.tau * (math.tau * half_small + 4 * (half_big - half_small)) / 20), 25);
        const segment_angle = total_angle / @intToFloat(f32, segments);
        if (opt.common.thickness == 0) {
            const base_index = @intCast(u32, self.vattribs.items.len);
            try self.vattribs.append(.{
                .position = transformPoint(center, transform_m),
                .color = opt.common.color,
            });
            var i: u32 = 0;
            while (i <= segments) : (i += 1) {
                try self.vattribs.append(.{
                    .position = transformPoint(.{
                        .x = center.x + half_width * @cos(@intToFloat(f32, i) * segment_angle + from_radian),
                        .y = center.y + half_height * @sin(@intToFloat(f32, i) * segment_angle + from_radian),
                    }, transform_m),
                    .color = opt.common.color,
                });
                if (is_loop) {
                    const last_index = if (i == segments) base_index + 1 else base_index + i + 2;
                    try self.vindices.appendSlice(&.{
                        base_index,
                        base_index + i + 1,
                        last_index,
                    });
                } else if (i < segments) {
                    const last_index = base_index + i + 2;
                    try self.vindices.appendSlice(&.{
                        base_index,
                        base_index + i + 1,
                        last_index,
                    });
                }
            }
        } else {
            const inner_base_index = @intCast(u32, self.vattribs.items.len);
            var i: u32 = 0;
            while (i <= segments) : (i += 1) {
                try self.vattribs.append(.{
                    .position = transformPoint(.{
                        .x = center.x + (half_width - opt.common.thickness) * @cos(@intToFloat(f32, i) * segment_angle + from_radian),
                        .y = center.y + (half_height - opt.common.thickness) * @sin(@intToFloat(f32, i) * segment_angle + from_radian),
                    }, transform_m),
                    .color = opt.common.color,
                });
            }
            const outer_base_index = @intCast(u32, self.vattribs.items.len);
            i = 0;
            while (i <= segments) : (i += 1) {
                try self.vattribs.append(.{
                    .position = transformPoint(.{
                        .x = center.x + half_width * @cos(@intToFloat(f32, i) * segment_angle + from_radian),
                        .y = center.y + half_height * @sin(@intToFloat(f32, i) * segment_angle + from_radian),
                    }, transform_m),
                    .color = opt.common.color,
                });
            }
            try self.addStripe(inner_base_index, outer_base_index, is_loop);
        }
    }

    /// Add a polyline
    fn addPolyline(self: *Renderer, points: []sdl.PointF, opt: CommonDrawOption) !void {
        assert(points.len > 1);
        const transform_m = getTransformMatrix(
            opt.anchor_pos orelse points[0],
            opt.rotate_degree,
        );
        var half_thickness = zmath.splat(zmath.Vec, math.max(opt.thickness / 2, 1));
        const inner_base_index = @intCast(u32, self.vattribs.items.len);
        for (points) |p, i| {
            const vt = if (i == 0)
                zmath.normalize2(zmath.f32x4(p.y - points[1].y, points[1].x - p.x, 0, 0)) * half_thickness
            else if (i < points.len - 1) BLK: {
                const v1 = zmath.normalize2(zmath.f32x4(p.x - points[i - 1].x, p.y - points[i - 1].y, 0, 0));
                const v2 = zmath.normalize2(zmath.f32x4(p.x - points[i + 1].x, p.y - points[i + 1].y, 0, 0));
                const perp1 = zmath.normalize2(zmath.f32x4(p.y - points[i + 1].y, points[i + 1].x - p.x, 0, 0));
                const perp2 = zmath.normalize2(zmath.f32x4(points[i - 1].y - p.y, p.x - points[i - 1].x, 0, 0));
                const v1_scale = zmath.splat(zmath.Vec, 1) / zmath.dot2(v1, perp1) * half_thickness;
                const v2_scale = zmath.splat(zmath.Vec, 1) / zmath.dot2(v2, perp2) * half_thickness;
                break :BLK v1 * v1_scale + v2 * v2_scale;
            } else zmath.normalize2(zmath.f32x4(points[i - 1].y - p.y, p.x - points[i - 1].x, 0, 0)) * half_thickness;
            const v = zmath.f32x4(p.x, p.y, 0, 0) + vt;
            try self.vattribs.append(.{
                .position = transformPoint(.{ .x = v[0], .y = v[1] }, transform_m),
                .color = opt.color,
            });
        }
        half_thickness = half_thickness * zmath.splat(zmath.Vec, -1);
        const outer_base_index = @intCast(u32, self.vattribs.items.len);
        for (points) |p, i| {
            const vt = if (i == 0)
                zmath.normalize2(zmath.f32x4(p.y - points[1].y, points[1].x - p.x, 0, 0)) * half_thickness
            else if (i < points.len - 1) BLK: {
                const v1 = zmath.normalize2(zmath.f32x4(p.x - points[i - 1].x, p.y - points[i - 1].y, 0, 0));
                const v2 = zmath.normalize2(zmath.f32x4(p.x - points[i + 1].x, p.y - points[i + 1].y, 0, 0));
                const perp1 = zmath.normalize2(zmath.f32x4(p.y - points[i + 1].y, points[i + 1].x - p.x, 0, 0));
                const perp2 = zmath.normalize2(zmath.f32x4(points[i - 1].y - p.y, p.x - points[i - 1].x, 0, 0));
                const v1_scale = zmath.splat(zmath.Vec, 1) / zmath.dot2(v1, perp1) * half_thickness;
                const v2_scale = zmath.splat(zmath.Vec, 1) / zmath.dot2(v2, perp2) * half_thickness;
                break :BLK v1 * v1_scale + v2 * v2_scale;
            } else zmath.normalize2(zmath.f32x4(points[i - 1].y - p.y, p.x - points[i - 1].x, 0, 0)) * half_thickness;
            const v = zmath.f32x4(p.x, p.y, 0, 0) + vt;
            try self.vattribs.append(.{
                .position = transformPoint(.{ .x = v[0], .y = v[1] }, transform_m),
                .color = opt.color,
            });
        }
        try self.addStripe(inner_base_index, outer_base_index, false);
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
