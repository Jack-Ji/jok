const std = @import("std");
const assert = std.debug.assert;
const sdl = @import("sdl");
const Self = @This();

// Position of camera's center
pos: sdl.PointF,

// Half-size of camera
orig_half_size: sdl.PointF,
half_size: sdl.PointF,

// Zoom value
zoom: f32,

pub fn init(pos: sdl.PointF, half_size: sdl.PointF) Self {
    assert(half_size.x > 0 and half_size.y > 0);
    return .{
        .pos = pos,
        .orig_half_size = half_size,
        .half_size = half_size,
        .zoom = 1,
    };
}

pub fn fromViewport(vp: sdl.Rectangle) Self {
    assert(vp.width > 0 and vp.height > 0);
    return init(
        .{ .x = @intToFloat(f32, vp.width) / 2, .y = @intToFloat(f32, vp.height) / 2 },
        .{ .x = @intToFloat(f32, vp.width) / 2, .y = @intToFloat(f32, vp.height) / 2 },
    );
}

/// Calculate coordinate in camera space
pub fn translatePoint(self: Self, pos: sdl.Point) sdl.Point {
    const left_top = sdl.Point{
        .x = @floatToInt(c_int, self.pos.x - self.half_size.x),
        .y = @floatToInt(c_int, self.pos.y - self.half_size.y),
    };
    return sdl.Point{
        .x = @floatToInt(c_int, @intToFloat(f32, pos.x - left_top.x) / self.zoom),
        .y = @floatToInt(c_int, @intToFloat(f32, pos.y - left_top.y) / self.zoom),
    };
}

/// Calculate coordinate in camera space
pub fn translatePointF(self: Self, pos: sdl.PointF) sdl.PointF {
    const left_top = sdl.PointF{
        .x = self.pos.x - self.half_size.x,
        .y = self.pos.y - self.half_size.y,
    };
    return sdl.PointF{
        .x = (pos.x - left_top.x) / self.zoom,
        .y = (pos.y - left_top.y) / self.zoom,
    };
}

/// Calculate coordinate in camera space
pub fn translateRectangle(self: Self, rect: sdl.Rectangle) sdl.Rectangle {
    const left_top = sdl.Point{
        .x = @floatToInt(c_int, self.pos.x - self.half_size.x),
        .y = @floatToInt(c_int, self.pos.y - self.half_size.y),
    };
    return sdl.Rectangle{
        .x = @floatToInt(c_int, @intToFloat(f32, rect.x - left_top.x) / self.zoom),
        .y = @floatToInt(c_int, @intToFloat(f32, rect.y - left_top.y) / self.zoom),
        .width = rect.width,
        .height = rect.height,
    };
}

/// Calculate coordinate in camera space
pub fn translateRectangleF(self: Self, rect: sdl.RectangleF) sdl.RectangleF {
    const left_top = sdl.PointF{
        .x = self.pos.x - self.half_size.x,
        .y = self.pos.y - self.half_size.y,
    };
    return sdl.RectangleF{
        .x = (rect.x - left_top.x) / self.zoom,
        .y = (rect.y - left_top.y) / self.zoom,
        .width = rect.width,
        .height = rect.height,
    };
}

/// Coordinate limiting
pub const CoordLimit = struct {
    min_x: f32 = 0,
    min_y: f32 = 0,
    max_x: f32 = std.math.floatMax(f32),
    max_y: f32 = std.math.floatMax(f32),
};

/// Move camera around
pub fn move(self: *Self, tr_x: f32, tr_y: f32, limit: CoordLimit) void {
    var move_x = if (tr_x > 0)
        std.math.min(tr_x, limit.max_x - (self.pos.x + self.half_size.x))
    else
        std.math.max(tr_x, limit.min_x - (self.pos.x - self.half_size.x));

    var move_y = if (tr_y > 0)
        std.math.min(tr_y, limit.max_y - (self.pos.y + self.half_size.y))
    else
        std.math.max(tr_y, limit.min_y - (self.pos.y - self.half_size.y));

    self.pos.x += move_x;
    self.pos.y += move_y;
}

/// Zooming
pub fn setZoom(self: *Self, zoom: f32, limit: CoordLimit) void {
    assert(zoom > 0);
    const half_size_x = self.orig_half_size.x * zoom;
    const half_size_y = self.orig_half_size.y * zoom;
    var left_top = sdl.PointF{
        .x = self.pos.x - half_size_x,
        .y = self.pos.y - half_size_y,
    };
    var right_bottom = sdl.PointF{
        .x = self.pos.x + half_size_x,
        .y = self.pos.y + half_size_y,
    };
    const reached_max_width = left_top.x <= limit.min_x and right_bottom.x >= limit.max_x;
    const reached_max_height = left_top.y <= limit.min_y and right_bottom.y >= limit.max_y;
    if (reached_max_width) {
        left_top.x = limit.min_x;
        right_bottom.x = limit.max_x;
        if (left_top.y < limit.min_y) {
            right_bottom.y += limit.min_y - left_top.y;
            left_top.y = limit.min_y;
        }
        if (right_bottom.y > limit.max_y) {
            left_top.y -= right_bottom.y - limit.max_y;
            right_bottom.y = limit.max_y;
        }
        self.half_size.x = (right_bottom.x - left_top.x) / 2;
        self.half_size.y = self.half_size.x * self.orig_half_size.y / self.orig_half_size.x;
    } else if (reached_max_height) {
        left_top.y = limit.min_y;
        right_bottom.y = limit.max_y;
        if (left_top.x < limit.min_x) {
            right_bottom.x += limit.min_x - left_top.x;
            left_top.x = limit.min_x;
        }
        if (right_bottom.x > limit.max_x) {
            left_top.x -= right_bottom.x - limit.max_x;
            right_bottom.x = limit.max_x;
        }
        self.half_size.y = (right_bottom.y - left_top.y) / 2;
        self.half_size.x = self.half_size.y * self.orig_half_size.x / self.orig_half_size.y;
    } else {
        if (left_top.x < limit.min_x) {
            right_bottom.x += limit.min_x - left_top.x;
            left_top.x = limit.min_x;
        }
        if (right_bottom.x > limit.max_x) {
            left_top.x -= right_bottom.x - limit.max_x;
            right_bottom.x = limit.max_x;
        }
        if (left_top.y < limit.min_y) {
            right_bottom.y += limit.min_y - left_top.y;
            left_top.y = limit.min_y;
        }
        if (right_bottom.y > limit.max_y) {
            left_top.y -= right_bottom.y - limit.max_y;
            right_bottom.y = limit.max_y;
        }
        self.half_size.x = (right_bottom.x - left_top.x) / 2;
        self.half_size.y = (right_bottom.y - left_top.y) / 2;
    }
    self.pos.x = (left_top.x + right_bottom.x) / 2;
    self.pos.y = (left_top.y + right_bottom.y) / 2;
    self.zoom = self.half_size.x / self.orig_half_size.x;
}
