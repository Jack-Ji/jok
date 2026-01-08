/// AffineTransform represents a 2D affine transform that performs a linear mapping from 2D
/// coordinates to other 2D coordinates that preserves the "straightness" and "parallelness" of lines.
/// Affine transformations can be constructed using sequences of translations, scales, rotations.
const std = @import("std");
const assert = std.debug.assert;
const math = std.math;
const jok = @import("../jok.zig");
const twoFloats = jok.utils.twoFloats;
const zmath = jok.vendor.zmath;
const Self = @This();

mat: zmath.Mat,

pub const init = Self{ .mat = zmath.identity() };

pub fn invert(self: Self) Self {
    return .{ .mat = zmath.inverse(self.mat) };
}

pub fn setToIdentity(self: *Self) void {
    self.mat = zmath.identity();
}

pub fn setToTranslate(self: *Self, v: anytype) void {
    const x, const y = twoFloats(v);
    self.mat = zmath.translation(x, y, 0);
}

pub fn setToTranslateX(self: *Self, t: f32) void {
    self.mat = zmath.translation(t, 0, 0);
}

pub fn setToTranslateY(self: *Self, t: f32) void {
    self.mat = zmath.translation(0, t, 0);
}

pub fn setToScale(self: *Self, v: anytype) void {
    const x, const y = twoFloats(v);
    self.mat = zmath.scaling(x, y, 0);
}

pub fn setToScaleX(self: *Self, s: f32) void {
    self.mat = zmath.scaling(s, 1, 0);
}

pub fn setToScaleY(self: *Self, s: f32) void {
    self.mat = zmath.scaling(1, s, 0);
}

pub fn setToRotateByOrigin(self: *Self, radian: f32) void {
    self.mat = zmath.rotationZ(radian);
}

pub fn setToRotateByPoint(self: *Self, p: jok.Point, radian: f32) void {
    self.mat = zmath.mul(
        zmath.mul(
            zmath.translation(-p.x, -p.y, 0),
            zmath.rotationZ(radian),
        ),
        zmath.translation(p.x, p.y, 0),
    );
}

pub fn setToRotateToVec(self: *Self, v: anytype) void {
    const x, const y = twoFloats(v);
    self.mat = zmath.rotationZ(math.atan2(y, x));
}

pub fn setToRotateToVecByPoint(self: *Self, p: jok.Point, v: anytype) void {
    const x, const y = twoFloats(v);
    self.mat = zmath.mul(
        zmath.mul(
            zmath.translation(-p.x, -p.y, 0),
            zmath.rotationZ(math.atan2(y, x)),
        ),
        zmath.translation(p.x, p.y, 0),
    );
}

pub fn translate(self: Self, v: anytype) Self {
    const x, const y = twoFloats(v);
    return .{
        .mat = zmath.mul(self.mat, zmath.translation(x, y, 0)),
    };
}

pub fn translateX(self: Self, t: f32) Self {
    return .{
        .mat = zmath.mul(self.mat, zmath.translation(t, 0, 0)),
    };
}

pub fn translateY(self: Self, t: f32) Self {
    return .{
        .mat = zmath.mul(self.mat, zmath.translation(0, t, 0)),
    };
}

pub fn scaleAroundOrigin(self: Self, v: anytype) Self {
    const x, const y = twoFloats(v);
    return .{
        .mat = zmath.mul(self.mat, zmath.scaling(x, y, 0)),
    };
}

pub fn scaleAroundPoint(self: Self, p: jok.Point, v: anytype) Self {
    const x, const y = twoFloats(v);
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

pub fn rotateByOrigin(self: Self, radian: f32) Self {
    return .{
        .mat = zmath.mul(self.mat, zmath.rotationZ(radian)),
    };
}

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

pub fn rotateToVec(self: Self, v: anytype) Self {
    const x, const y = twoFloats(v);
    return .{
        .mat = zmath.mul(self.mat, zmath.rotationZ(math.atan2(y, x))),
    };
}

pub fn rotateToVecByPoint(self: Self, p: jok.Point, v: anytype) Self {
    const x, const y = twoFloats(v);
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

pub fn getTranslation(self: Self) [2]f32 {
    const v = zmath.util.getTranslationVec(self.mat);
    return .{ v[0], v[1] };
}

pub fn getTranslationX(self: Self) f32 {
    const v = zmath.util.getTranslationVec(self.mat);
    return v[0];
}

pub fn getTranslationY(self: Self) f32 {
    const v = zmath.util.getTranslationVec(self.mat);
    return v[1];
}

pub fn getRotation(self: Self) f32 {
    return math.atan2(self.mat[0][1], self.mat[0][0]);
}

pub fn getScale(self: Self) [2]f32 {
    const v = zmath.util.getScaleVec(self.mat);
    return .{ v[0], v[1] };
}

pub fn getScaleX(self: Self) f32 {
    const v = zmath.util.getScaleVec(self.mat);
    return v[0];
}

pub fn getScaleY(self: Self) f32 {
    const v = zmath.util.getScaleVec(self.mat);
    return v[1];
}

pub fn transformPoint(self: Self, p: jok.Point) jok.Point {
    const v = zmath.mul(zmath.f32x4(p.x, p.y, 0, 1), self.mat);
    return .{ .x = v[0], .y = v[1] };
}

pub fn inverseTransformPoint(self: Self, p: jok.Point) jok.Point {
    const mat = zmath.inverse(self.mat);
    const v = zmath.mul(zmath.f32x4(p.x, p.y, 0, 1), mat);
    return .{ .x = v[0], .y = v[1] };
}

pub fn transformRectangle(self: Self, r: jok.Rectangle) jok.Rectangle {
    const pos = self.transformPoint(r.getPos());
    const size = r.getSize().mul(self.getScale());
    return .{ .x = pos.x, .y = pos.y, .width = size.x, .height = size.y };
}

pub fn transformCircle(self: Self, c: jok.Circle) jok.Circle {
    const pos = self.transformPoint(c.center);
    const radius = c.radius * self.getScaleX();
    return .{ .center = pos, .radius = radius };
}

pub fn transformEllipse(self: Self, e: jok.Ellipse) jok.Ellipse {
    const pos = self.transformPoint(e.center);
    const radius = e.radius.mul(self.getScale());
    return .{ .center = pos, .radius = radius };
}

pub fn transformTriangle(self: Self, t: jok.Triangle) jok.Triangle {
    return .{
        self.transformPoint(t.p0),
        self.transformPoint(t.p1),
        self.transformPoint(t.p2),
    };
}

pub fn mul(m0: Self, m1: Self) Self {
    return .{
        .mat = zmath.mul(m0.mat, m1.mat),
    };
}
