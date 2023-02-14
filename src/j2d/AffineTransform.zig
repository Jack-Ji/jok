/// AffineTransform represents a 2D affine transform that performs a linear mapping from 2D
/// coordinates to other 2D coordinates that preserves the "straightness" and "parallelness" of lines.
/// Affine transformations can be constructed using sequences of translations, scales, rotations.
const std = @import("std");
const assert = std.debug.assert;
const math = std.math;
const sdl = @import("sdl");
const jok = @import("../jok.zig");
const zmath = jok.zmath;
const Self = @This();

mat: zmath.Mat,

pub fn init() Self {
    return .{
        .mat = zmath.identity(),
    };
}

pub fn clone(self: Self) Self {
    const cloned = self;
    return cloned;
}

pub fn transformPoint(self: Self, p: sdl.PointF) sdl.PointF {
    const v = zmath.mul(zmath.f32x4(p.x, p.y, 0, 1), self.mat);
    return .{ .x = v[0], .y = v[1] };
}

pub fn inverseTransformPoint(self: Self, p: sdl.PointF) sdl.PointF {
    const mat = zmath.inverse(self.mat);
    const v = zmath.mul(zmath.f32x4(p.x, p.y, 0, 1), mat);
    return .{ .x = v[0], .y = v[1] };
}

pub fn invert(self: Self) void {
    self.mat = zmath.inverse(self.mat);
}

pub fn setToIdentity(self: *Self) void {
    self.mat = zmath.identity();
}

pub fn setToTranslate(self: *Self, t: sdl.PointF) void {
    self.mat = zmath.translation(t.x, t.y, 0);
}

pub fn setToTranslateX(self: *Self, t: f32) void {
    self.mat = zmath.translation(t, 0, 0);
}

pub fn setToTranslateY(self: *Self, t: f32) void {
    self.mat = zmath.translation(0, t, 0);
}

pub fn setToScale(self: *Self, s: sdl.PointF) void {
    self.mat = zmath.scaling(s.x, s.y, 0);
}

pub fn setToScaleX(self: *Self, s: f32) void {
    self.mat = zmath.scaling(s, 1, 0);
}

pub fn setToScaleY(self: *Self, s: f32) void {
    self.mat = zmath.scaling(1, s, 0);
}

pub fn setToRotateByOrgin(self: *Self, radian: f32) void {
    self.mat = zmath.rotationZ(radian);
}

pub fn setToRotateByPoint(self: *Self, p: sdl.PointF, radian: f32) void {
    self.mat = zmath.mul(
        zmath.mul(
            zmath.translation(-p.x, -p.y, 0),
            zmath.rotationZ(radian),
        ),
        zmath.translation(p.x, p.y, 0),
    );
}

pub fn setToRotateToVec(self: *Self, v: sdl.PointF) void {
    self.mat = zmath.rotationZ(math.atan2(f32, v.y, v.x));
}

pub fn setToRotateToVecByPoint(self: *Self, p: sdl.PointF, v: sdl.PointF) void {
    self.mat = zmath.mul(
        zmath.mul(
            zmath.translation(-p.x, -p.y, 0),
            zmath.rotationZ(math.atan2(f32, v.y, v.x)),
        ),
        zmath.translation(p.x, p.y, 0),
    );
}

pub fn translate(self: *Self, t: sdl.PointF) void {
    self.mat = zmath.mul(self.mat, zmath.translation(t.x, t.y, 0));
}

pub fn translateX(self: *Self, t: f32) void {
    self.mat = zmath.mul(self.mat, zmath.translation(t, 0, 0));
}

pub fn translateY(self: *Self, t: f32) void {
    self.mat = zmath.mul(self.mat, zmath.translation(0, t, 0));
}

pub fn scale(self: *Self, s: sdl.PointF) void {
    self.mat = zmath.mul(self.mat, zmath.scaling(s.x, s.y, 0));
}

pub fn scaleX(self: *Self, s: f32) void {
    self.mat = zmath.mul(self.mat, zmath.scaling(s, 1, 0));
}

pub fn scaleY(self: *Self, s: f32) void {
    self.mat = zmath.mul(self.mat, zmath.scaling(1, s, 0));
}

pub fn rotateByOrgin(self: *Self, radian: f32) void {
    self.mat = zmath.mul(self.mat, zmath.rotationZ(radian));
}

pub fn rotateByPoint(self: *Self, p: sdl.PointF, radian: f32) void {
    self.mat = zmath.mul(
        self.mat,
        zmath.mul(
            zmath.mul(
                zmath.translation(-p.x, -p.y, 0),
                zmath.rotationZ(radian),
            ),
            zmath.translation(p.x, p.y, 0),
        ),
    );
}

pub fn rotateToVec(self: *Self, v: sdl.PointF) void {
    self.mat = zmath.mul(self.mat, zmath.rotationZ(math.atan2(f32, v.y, v.x)));
}

pub fn rotateToVecByPoint(self: *Self, v: sdl.PointF, p: sdl.PointF) void {
    self.mat = zmath.mul(
        self.mat,
        zmath.mul(
            zmath.mul(
                zmath.translation(-p.x, -p.y, 0),
                zmath.rotationZ(math.atan2(f32, v.y, v.x)),
            ),
            zmath.translation(p.x, p.y, 0),
        ),
    );
}

pub fn getTranslation(self: Self) sdl.PointF {
    const v = zmath.util.getTranslationVec(self.mat);
    return .{ .x = v[0], .y = v[1] };
}

pub fn getTranslationX(self: Self) f32 {
    const v = zmath.util.getTranslationVec(self.mat);
    return v[0];
}

pub fn getTranslationY(self: Self) f32 {
    const v = zmath.util.getTranslationVec(self.mat);
    return v[1];
}

pub fn getScale(self: Self) sdl.PointF {
    const v = zmath.util.getScaleVec(self.mat);
    return .{ .x = v[0], .y = v[1] };
}

pub fn getScaleX(self: Self) f32 {
    const v = zmath.util.getScaleVec(self.mat);
    return v[0];
}

pub fn getScaleY(self: Self) f32 {
    const v = zmath.util.getScaleVec(self.mat);
    return v[1];
}
