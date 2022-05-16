const std = @import("std");
const math = std.math;
const jok = @import("../../jok.zig");
const gfx = jok.gfx;
const Self = @This();

data: @Vector(2, f32),

/// construct new vector.
pub fn new(vx: f32, vy: f32) Self {
    return .{ .data = [2]f32{ vx, vy } };
}

pub fn x(self: Self) f32 {
    return self.data[0];
}

pub fn y(self: Self) f32 {
    return self.data[1];
}

/// set all components to the same given value.
pub fn set(val: f32) Self {
    const result = @splat(f32, val);
    return .{ .data = result };
}

/// shorthand for (0..).
pub fn zero() Self {
    return set(0);
}

/// shorthand for (1..).
pub fn one() Self {
    return set(1);
}

/// shorthand for (0, -1).
pub fn up() Self {
    return Self.new(0, -1);
}

/// shorthand for (0, 1).
pub fn down() Self {
    return up().negate();
}

/// shorthand for (1, 0).
pub fn right() Self {
    return Self.new(1, 0);
}

/// shorthand for (-1, 0).
pub fn left() Self {
    return right().negate();
}

/// negate the given vector.
pub fn negate(self: Self) Self {
    return self.scale(-1);
}

/// construct new vector from slice.
pub fn fromSlice(slice: []const f32) Self {
    const result = slice[0..f32].*;
    return .{ .data = result };
}

/// transform vector to array.
pub fn toArray(self: Self) [2]f32 {
    return self.data;
}

/// return the angle (in degrees) between two vectors.
pub fn getAngle(first_vector: Self, second_vector: Self) f32 {
    const dot_product = dot(norm(first_vector), norm(second_vector));
    return gfx.utils.radianToDegree(math.acos(dot_product));
}

/// Return the length (magnitude) of given vector.
/// √[x^2 + y^2 + z^2 ...]
pub fn length(self: Self) f32 {
    return @sqrt(self.dot(self));
}

/// return the distance between two points.
/// √[(x1 - x2)^2 + (y1 - y2)^2 + (z1 - z2)^2 ...]
pub fn distance(first_vector: Self, second_vector: Self) f32 {
    return length(first_vector.sub(second_vector));
}

/// construct new normalized vector from a given one.
pub fn norm(self: Self) Self {
    const l = self.length();
    if (l == 0) {
        return self;
    }
    const result = self.data / @splat(f32, l);
    return .{ .data = result };
}

/// return true if two vectors are equals.
pub fn eql(first_vector: Self, second_vector: Self) bool {
    return @reduce(.And, first_vector.data == second_vector.data);
}

/// substraction between two given vector.
pub fn sub(first_vector: Self, second_vector: Self) Self {
    const result = first_vector.data - second_vector.data;
    return .{ .data = result };
}

/// addition betwen two given vector.
pub fn add(first_vector: Self, second_vector: Self) Self {
    const result = first_vector.data + second_vector.data;
    return .{ .data = result };
}

/// component wise multiplication betwen two given vector.
pub fn mul(first_vector: Self, second_vector: Self) Self {
    const result = first_vector.data * second_vector.data;
    return .{ .data = result };
}

/// construct vector from the max components in two vectors
pub fn max(first_vector: Self, second_vector: Self) Self {
    const result = @maximum(first_vector.data, second_vector.data);
    return .{ .data = result };
}

/// construct vector from the min components in two vectors
pub fn min(first_vector: Self, second_vector: Self) Self {
    const result = @minimum(first_vector.data, second_vector.data);
    return .{ .data = result };
}

/// construct new vector after multiplying each components by a given scalar
pub fn scale(self: Self, scalar: f32) Self {
    const result = self.data * @splat(2, scalar);
    return .{ .data = result };
}

/// return the dot product between two given vector.
/// (x1 * x2) + (y1 * y2) + (z1 * z2) ...
pub fn dot(first_vector: Self, second_vector: Self) f32 {
    return @reduce(.Add, first_vector.data * second_vector.data);
}

/// linear interpolation between two vectors
pub fn lerp(first_vector: Self, second_vector: Self, t: f32) Self {
    const from = first_vector.data;
    const to = second_vector.data;

    const result = from + (to - from) * @splat(f32, t);
    return .{ .data = result };
}
