//! 2D camera management.
//!
//! Camera represent a rectangular area on a large map.
//! Camera can be translated/scaled/rotated, which directly affects
//! how stuff are rendered on screen.

const std = @import("std");
const assert = std.debug.assert;
const jok = @import("../jok.zig");
const utils = jok.utils;
const zmath = jok.vendor.zmath;
const AffineTransform = @import("AffineTransform.zig");
const Camera = @This();

/// Represent the screen
screen: jok.Rectangle,

/// Rectangle area of camera
orig: jok.Rectangle,
rect: jok.Rectangle,

/// Rotation of camera (in radians)
rotation: f32,

/// Create a new camera.
///
/// Parameters:
///   - ctx: Application context
///   - pos: Center position of camera
///   - width: Width of camera
///   - height: Height of camera
///
/// Returns: A newly initialized camera
pub fn init(ctx: jok.Context, pos: jok.Point, width: u32, height: u32) Camera {
    const half_w = @as(f32, @floatFromInt(width)) * 0.5;
    const half_h = @as(f32, @floatFromInt(height)) * 0.5;
    return .{
        .screen = ctx.getCanvasSize().toRect(.origin),
        .orig = .{
            .x = pos.x - half_w,
            .y = pos.y - half_h,
            .width = half_w * 2,
            .height = half_h * 2,
        },
        .rect = .{
            .x = pos.x - half_w,
            .y = pos.y - half_h,
            .width = half_w * 2,
            .height = half_h * 2,
        },
        .rotation = 0,
    };
}

/// Get current scaling of camera
pub fn getScaling(self: Camera) f32 {
    return self.rect.width / self.orig.width;
}

/// Reset screen state, used when size of canvas is changed,
/// which is usually caused by resizing the window.
pub fn resetScreen(self: *Camera, ctx: jok.Context) void {
    self.screen = ctx.getCanvasSize().toRect(.origin);
}

/// Translate the camera by given offset
///
/// Parameters:
///   - two_floats: Translation offset as .{x, y}
///
/// Note: Translation is applied in camera's local space (respects rotation)
pub fn translateBy(self: *Camera, two_floats: anytype) void {
    // If camera is rotated, transform the offset to world space
    if (self.rotation != 0) {
        const offset = utils.twoFloats(two_floats);
        const cos = @cos(-self.rotation);
        const sin = @sin(-self.rotation);
        const rotated_x = offset[0] * cos - offset[1] * sin;
        const rotated_y = offset[0] * sin + offset[1] * cos;
        self.rect = self.rect.translate(.{ rotated_x, rotated_y });
    } else {
        self.rect = self.rect.translate(two_floats);
    }
}

/// Translate the camera to given position
///
/// Parameters:
///   - two_floats: Absolute world position {x, y} for camera center
///
/// Note: Preserves current scaling and rotation
pub fn translateTo(self: *Camera, two_floats: anytype) void {
    const target_center = jok.Point{
        .x = utils.twoFloats(two_floats)[0],
        .y = utils.twoFloats(two_floats)[1],
    };
    const current_center = self.rect.getCenter();

    // Calculate offset needed to move center to target position
    const offset = target_center.sub(current_center);

    // Apply the offset (this preserves scale and doesn't affect rotation)
    self.rect = self.rect.translate(offset);
}

/// Rotate the camera by give angle, around it's center point
///
/// Parameters:
///   - radian: Rotation angle in radians
///
pub fn rotateBy(self: *Camera, radian: f32) void {
    self.rotation = zmath.modAngle(self.rotation - radian);
}

/// Rotate the camera to give angle, around it's center point
///
/// Parameters:
///   - radian: Rotation angle in radians
pub fn rotateTo(self: *Camera, radian: f32) void {
    self.rotation = zmath.modAngle(-radian);
}

/// Scale the camera by given factor, around it's center point
pub fn scaleBy(self: *Camera, s: f32) void {
    const center = self.rect.getCenter();
    const new_rect = self.rect.scale(.{ s, s });
    const new_center = new_rect.getCenter();
    self.rect = new_rect.translate(center.sub(new_center));
}

/// Scale the camera to given factor, around it's center point
pub fn scaleTo(self: *Camera, s: f32) void {
    const center = self.rect.getCenter();
    const new_rect = self.orig.scale(.{ s, s });
    const new_center = new_rect.getCenter();
    self.rect = new_rect.translate(center.sub(new_center));
}

/// Get transform matrix
pub fn getTransform(self: Camera) AffineTransform {
    const screen_center = self.screen.getCenter();
    const rect_center = self.rect.getCenter();
    var trs = AffineTransform.init;
    if (!std.math.approxEqAbs(f32, self.rect.width, self.screen.width, 0.0001) or
        !std.math.approxEqAbs(f32, self.rect.height, self.screen.height, 0.0001))
    {
        trs = trs.scaleAroundPoint(rect_center, .{
            self.screen.width / self.rect.width,
            self.screen.height / self.rect.height,
        });
    }
    if (self.rotation != 0) {
        trs = trs.rotateByPoint(rect_center, self.rotation);
    }
    trs = trs.translate(screen_center.sub(rect_center));
    return trs;
}
