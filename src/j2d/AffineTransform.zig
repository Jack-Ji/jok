//! 2D Affine transformation matrix.
//!
//! AffineTransform represents a 2D affine transform that performs a linear mapping from 2D
//! coordinates to other 2D coordinates that preserves the "straightness" and "parallelness" of lines.
//! Affine transformations can be constructed using sequences of translations, scales, and rotations.
//!
//! Transformations can be combined by multiplying matrices together. The order matters:
//! transformations are applied left-to-right
//!
//! Example:
//! ```zig
//! var transform = AffineTransform.init;
//! transform = transform.translate(.{100, 50});
//! transform = transform.rotateByOrigin(std.math.pi / 4);
//! transform = transform.scaleAroundOrigin(.{2, 2});
//! const transformed_point = transform.transformPoint(original_point);
//! ```

const std = @import("std");
const assert = std.debug.assert;
const math = std.math;
const jok = @import("../jok.zig");
const twoFloats = jok.utils.twoFloats;
const zmath = jok.vendor.zmath;
const Self = @This();

/// Internal transformation matrix
mat: zmath.Mat,

/// Identity transform (no transformation)
pub const init = Self{ .mat = zmath.identity() };

/// Identity transform (no transformation) - alias for init
pub const identity = Self{ .mat = zmath.identity() };

/// Calculate the inverse of this transformation.
/// The inverse transformation undoes the original transformation.
pub fn invert(self: Self) Self {
    return .{ .mat = zmath.inverse(self.mat) };
}

/// Reset this transformation to identity (no transformation).
pub fn setToIdentity(self: *Self) void {
    self.mat = zmath.identity();
}

/// Set this transformation to a translation.
pub fn setToTranslate(self: *Self, two_floats: anytype) void {
    const x, const y = twoFloats(two_floats);
    self.mat = zmath.translation(x, y, 0);
}

/// Set this transformation to a translation along the X axis.
pub fn setToTranslateX(self: *Self, t: f32) void {
    self.mat = zmath.translation(t, 0, 0);
}

/// Set this transformation to a translation along the Y axis.
pub fn setToTranslateY(self: *Self, t: f32) void {
    self.mat = zmath.translation(0, t, 0);
}

/// Set this transformation to a scale.
pub fn setToScale(self: *Self, two_floats: anytype) void {
    const x, const y = twoFloats(two_floats);
    self.mat = zmath.scaling(x, y, 0);
}

/// Set this transformation to a scale along the X axis.
pub fn setToScaleX(self: *Self, s: f32) void {
    self.mat = zmath.scaling(s, 1, 0);
}

/// Set this transformation to a scale along the Y axis.
pub fn setToScaleY(self: *Self, s: f32) void {
    self.mat = zmath.scaling(1, s, 0);
}

/// Set this transformation to a rotation around the origin (0, 0).
pub fn setToRotateByOrigin(self: *Self, radian: f32) void {
    self.mat = zmath.rotationZ(radian);
}

/// Set this transformation to a rotation around a specific point.
pub fn setToRotateByPoint(self: *Self, p: jok.Point, radian: f32) void {
    self.mat = zmath.mul(
        zmath.mul(
            zmath.translation(-p.x, -p.y, 0),
            zmath.rotationZ(radian),
        ),
        zmath.translation(p.x, p.y, 0),
    );
}

/// Set this transformation to a rotation to align with a direction vector.
pub fn setToRotateToVec(self: *Self, two_floats: anytype) void {
    const x, const y = twoFloats(two_floats);
    self.mat = zmath.rotationZ(math.atan2(y, x));
}

/// Set this transformation to a rotation around a point to align with a direction vector.
pub fn setToRotateToVecByPoint(self: *Self, p: jok.Point, two_floats: anytype) void {
    const x, const y = twoFloats(two_floats);
    self.mat = zmath.mul(
        zmath.mul(
            zmath.translation(-p.x, -p.y, 0),
            zmath.rotationZ(math.atan2(y, x)),
        ),
        zmath.translation(p.x, p.y, 0),
    );
}

/// Apply a translation to this transformation.
/// Returns a new transformation with the translation applied.
pub fn translate(self: Self, two_floats: anytype) Self {
    const x, const y = twoFloats(two_floats);
    return .{
        .mat = zmath.mul(self.mat, zmath.translation(x, y, 0)),
    };
}

/// Apply a translation along the X axis.
pub fn translateX(self: Self, t: f32) Self {
    return .{
        .mat = zmath.mul(self.mat, zmath.translation(t, 0, 0)),
    };
}

/// Apply a translation along the Y axis.
pub fn translateY(self: Self, t: f32) Self {
    return .{
        .mat = zmath.mul(self.mat, zmath.translation(0, t, 0)),
    };
}

/// Apply a scale around the origin (0, 0).
pub fn scaleAroundOrigin(self: Self, two_floats: anytype) Self {
    const x, const y = twoFloats(two_floats);
    return .{
        .mat = zmath.mul(self.mat, zmath.scaling(x, y, 0)),
    };
}

/// Apply a scale around a specific point.
pub fn scaleAroundPoint(self: Self, p: jok.Point, two_floats: anytype) Self {
    const x, const y = twoFloats(two_floats);
    return .{
        .mat = zmath.mul(
            self.mat,
            zmath.mul(
                zmath.mul(
                    zmath.translation(-p.x, -p.y, 0),
                    zmath.scaling(x, y, 0),
                ),
                zmath.translation(p.x, p.y, 0),
            ),
        ),
    };
}

/// Apply a rotation around the origin (0, 0).
pub fn rotateByOrigin(self: Self, radian: f32) Self {
    return .{
        .mat = zmath.mul(self.mat, zmath.rotationZ(radian)),
    };
}

/// Apply a rotation around a specific point.
pub fn rotateByPoint(self: Self, p: jok.Point, radian: f32) Self {
    return .{
        .mat = zmath.mul(
            self.mat,
            zmath.mul(
                zmath.mul(
                    zmath.translation(-p.x, -p.y, 0),
                    zmath.rotationZ(radian),
                ),
                zmath.translation(p.x, p.y, 0),
            ),
        ),
    };
}

/// Apply a rotation to align with a direction vector.
pub fn rotateToVec(self: Self, two_floats: anytype) Self {
    const x, const y = twoFloats(two_floats);
    return .{
        .mat = zmath.mul(self.mat, zmath.rotationZ(math.atan2(y, x))),
    };
}

/// Apply a rotation around a point to align with a direction vector.
pub fn rotateToVecByPoint(self: Self, p: jok.Point, two_floats: anytype) Self {
    const x, const y = twoFloats(two_floats);
    return .{
        .mat = zmath.mul(
            self.mat,
            zmath.mul(
                zmath.mul(
                    zmath.translation(-p.x, -p.y, 0),
                    zmath.rotationZ(math.atan2(y, x)),
                ),
                zmath.translation(p.x, p.y, 0),
            ),
        ),
    };
}

/// Get the translation component of this transformation.
pub fn getTranslation(self: Self) [2]f32 {
    const v = zmath.util.getTranslationVec(self.mat);
    return .{ v[0], v[1] };
}

/// Get the X translation component.
pub fn getTranslationX(self: Self) f32 {
    const v = zmath.util.getTranslationVec(self.mat);
    return v[0];
}

/// Get the Y translation component.
pub fn getTranslationY(self: Self) f32 {
    const v = zmath.util.getTranslationVec(self.mat);
    return v[1];
}

/// Get the rotation component in radians.
pub fn getRotation(self: Self) f32 {
    return math.atan2(self.mat[0][1], self.mat[0][0]);
}

/// Get the scale component.
pub fn getScale(self: Self) [2]f32 {
    const v = zmath.util.getScaleVec(self.mat);
    return .{ v[0], v[1] };
}

/// Get the X scale component.
pub fn getScaleX(self: Self) f32 {
    const v = zmath.util.getScaleVec(self.mat);
    return v[0];
}

/// Get the Y scale component.
pub fn getScaleY(self: Self) f32 {
    const v = zmath.util.getScaleVec(self.mat);
    return v[1];
}

/// Transform a point using this transformation.
pub fn transformPoint(self: Self, p: jok.Point) jok.Point {
    const v = zmath.mul(zmath.f32x4(p.x, p.y, 0, 1), self.mat);
    return .{ .x = v[0], .y = v[1] };
}

/// Transform a point using the inverse of this transformation.
pub fn inverseTransformPoint(self: Self, p: jok.Point) jok.Point {
    const mat = zmath.inverse(self.mat);
    const v = zmath.mul(zmath.f32x4(p.x, p.y, 0, 1), mat);
    return .{ .x = v[0], .y = v[1] };
}

/// Transform a rectangle using this transformation.
pub fn transformRectangle(self: Self, r: jok.Rectangle) jok.Rectangle {
    const pos = self.transformPoint(r.getPos());
    const size = r.getSizeF().mul(self.getScale());
    return .{ .x = pos.x, .y = pos.y, .width = size.x, .height = size.y };
}

/// Transform a circle using this transformation.
pub fn transformCircle(self: Self, c: jok.Circle) jok.Circle {
    const pos = self.transformPoint(c.center);
    const radius = c.radius * self.getScaleX();
    return .{ .center = pos, .radius = radius };
}

/// Transform an ellipse using this transformation.
pub fn transformEllipse(self: Self, e: jok.Ellipse) jok.Ellipse {
    const pos = self.transformPoint(e.center);
    const radius = e.radius.mul(self.getScale());
    return .{ .center = pos, .radius = radius };
}

/// Transform a triangle using this transformation.
pub fn transformTriangle(self: Self, t: jok.Triangle) jok.Triangle {
    return .{
        self.transformPoint(t.p0),
        self.transformPoint(t.p1),
        self.transformPoint(t.p2),
    };
}

/// Multiply two transformations together.
/// The result applies m0 first, then m1.
pub fn mul(m0: Self, m1: Self) Self {
    return .{
        .mat = zmath.mul(m0.mat, m1.mat),
    };
}
