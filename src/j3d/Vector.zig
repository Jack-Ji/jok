/// 3d vector
const std = @import("std");
const math = std.math;
const expectEqual = std.testing.expectEqual;
const jok = @import("../jok.zig");
const Vec = @Vector(3, f32);
const Self = @This();

data: Vec,

pub fn new(vx: f32, vy: f32, vz: f32) Self {
    return .{ .data = [3]f32{ vx, vy, vz } };
}

pub fn x(self: Self) f32 {
    return self.data[0];
}

pub fn y(self: Self) f32 {
    return self.data[1];
}

pub fn z(self: Self) f32 {
    return self.data[2];
}

/// Set all components to the same given value.
pub fn set(val: f32) Self {
    const result = @as(Vec, @splat(val));
    return .{ .data = result };
}

/// Shorthand for (0..).
pub fn zero() Self {
    return set(0);
}

/// Shorthand for (1..).
pub fn one() Self {
    return set(1);
}

/// Shorthand for (0, 0, 1).
pub fn forward() Self {
    return new(0, 0, 1);
}

/// Shorthand for (0, 0, -1).
pub fn back() Self {
    return forward().negate();
}

/// Shorthand for (0, 1, 0).
pub fn up() Self {
    return Self.new(0, 1, 0);
}

/// Shorthand for (0, -1, 0).
pub fn down() Self {
    return Self.new(0, -1, 0);
}

/// Shorthand for (1, 0, 0).
pub fn right() Self {
    return Self.new(1, 0, 0);
}

/// Shorthand for (-1, 0, 0).
pub fn left() Self {
    return Self.new(-1, 0, 0);
}

/// Negate the given vector.
pub fn negate(self: Self) Self {
    return self.scale(-1);
}

/// Construct new vector from slice.
pub fn fromSlice(slice: []const f32) Self {
    const result = slice[0..3].*;
    return .{ .data = result };
}

/// Transform vector to array.
pub fn toArray(self: Self) [3]f32 {
    return self.data;
}

/// Return the angle (in degrees) between two vectors.
pub fn getAngle(first_vector: Self, second_vector: Self) f32 {
    const dot_product = dot(norm(first_vector), norm(second_vector));
    return std.math.radiansToDegrees(math.acos(dot_product));
}

/// Return the length (magnitude) of given vector.
/// √[x^2 + y^2 + z^2 ...]
pub fn length(self: Self) f32 {
    return @sqrt(self.dot(self));
}

/// Return the distance between two points.
/// √[(x1 - x2)^2 + (y1 - y2)^2 + (z1 - z2)^2 ...]
pub fn distance(first_vector: Self, second_vector: Self) f32 {
    return length(first_vector.sub(second_vector));
}

/// Construct new normalized vector from a given one.
pub fn norm(self: Self) Self {
    const l = self.length();
    if (l == 0) {
        return self;
    }
    const result = self.data / @as(Vec, @splat(l));
    return .{ .data = result };
}

/// Return true if two vectors are equals.
pub fn eql(first_vector: Self, second_vector: Self) bool {
    return @reduce(.And, first_vector.data == second_vector.data);
}

/// Substraction between two given vector.
pub fn sub(first_vector: Self, second_vector: Self) Self {
    const result = first_vector.data - second_vector.data;
    return .{ .data = result };
}

/// Addition betwen two given vector.
pub fn add(first_vector: Self, second_vector: Self) Self {
    const result = first_vector.data + second_vector.data;
    return .{ .data = result };
}

/// Component wise multiplication betwen two given vector.
pub fn mul(first_vector: Self, second_vector: Self) Self {
    const result = first_vector.data * second_vector.data;
    return .{ .data = result };
}

/// Construct vector from the max components in two vectors
pub fn max(first_vector: Self, second_vector: Self) Self {
    const result = @max(first_vector.data, second_vector.data);
    return .{ .data = result };
}

/// Construct vector from the min components in two vectors
pub fn min(first_vector: Self, second_vector: Self) Self {
    const result = @min(first_vector.data, second_vector.data);
    return .{ .data = result };
}

/// Construct new vector after multiplying each components by a given scalar
pub fn scale(self: Self, scalar: f32) Self {
    const result = self.data * @as(Vec, @splat(scalar));
    return .{ .data = result };
}

/// Return the dot product between two given vector.
/// (x1 * x2) + (y1 * y2) + (z1 * z2) ...
pub fn dot(first_vector: Self, second_vector: Self) f32 {
    return @reduce(.Add, first_vector.data * second_vector.data);
}

/// Linear interpolation between two vectors
pub fn lerp(first_vector: Self, second_vector: Self, t: f32) Self {
    const from = first_vector.data;
    const to = second_vector.data;

    const result = from + (to - from) * @as(Vec, @splat(t));
    return .{ .data = result };
}

/// Construct the cross product (as vector) from two vectors.
pub fn cross(first_vector: Self, second_vector: Self) Self {
    const x1 = first_vector.x();
    const y1 = first_vector.y();
    const z1 = first_vector.z();

    const x2 = second_vector.x();
    const y2 = second_vector.y();
    const z2 = second_vector.z();

    const result_x = (y1 * z2) - (z1 * y2);
    const result_y = (z1 * x2) - (x1 * z2);
    const result_z = (x1 * y2) - (y1 * x2);
    return new(result_x, result_y, result_z);
}

test "Vectors.eql" {
    const a = Self.new(1, 2, 3);
    const b = Self.new(1, 2, 3);
    const c = Self.new(1.5, 2, 3);

    try expectEqual(Self.eql(a, b), true);
    try expectEqual(Self.eql(a, c), false);
}

test "Vectors.set" {
    const a = Self.new(2.5, 2.5, 2.5);
    const b = Self.set(2.5);
    try expectEqual(a, b);
}

test "Vectors.add" {
    const a = Self.one();
    const b = Self.one();
    try expectEqual(a.add(b), Self.set(2));
}

test "Vectors.negate" {
    const a = Self.set(5);
    const a_negated = Self.set(-5);
    try expectEqual(a.negate(), a_negated);
}

test "Vectors.getAngle" {
    const a = Self.right();
    const b = Self.up();
    const c = Self.left();
    const d = Self.new(1, 1, 0);

    try expectEqual(math.approxEqAbs(f32, a.getAngle(a), 0, 0.0001), true);
    try expectEqual(math.approxEqAbs(f32, a.getAngle(b), 90, 0.0001), true);
    try expectEqual(math.approxEqAbs(f32, a.getAngle(c), 180, 0.0001), true);
    try expectEqual(math.approxEqAbs(f32, a.getAngle(d), 45, 0.0001), true);
}

test "Vectors.toArray" {
    const a = Self.up().toArray();
    const b = [_]f32{ 0, 1, 0 };

    try std.testing.expectEqualSlices(f32, &a, &b);
}

test "Vectors.length" {
    const a = Self.new(1.5, 2.6, 3.7);
    try expectEqual(a.length(), 4.7644519);
}

test "Vectors.distance" {
    const a = Self.zero();
    const b = Self.left();
    const c = Self.new(0, 5, 0);

    try expectEqual(a.distance(b), 1);
    try expectEqual(a.distance(c), 5);
}

test "Vectors.normalize" {
    const a = Self.new(1.5, 2.6, 3.7);
    const a_normalized = Self.new(0.314831584, 0.545708060, 0.776584625);
    try expectEqual(a.norm(), a_normalized);
}

test "Vectors.scale" {
    const a = Self.new(1, 2, 3);
    const a_scaled = Self.new(5, 10, 15);
    try expectEqual(a.scale(5), a_scaled);
}

test "Vectors.dot" {
    const a = Self.new(1.5, 2.6, 3.7);
    const b = Self.new(2.5, 3.45, 1.0);
    try expectEqual(a.dot(b), 16.42);
}

test "Vectors.lerp" {
    const a = Self.new(-10, 0, -10);
    const b = Self.set(10);
    try expectEqual(Self.lerp(a, b, 0.5), Self.new(0, 5, 0));
}

test "Vectors.min" {
    const a = Self.new(10, -2, 0);
    const b = Self.new(-10, 5, 0);
    const minimum = Self.new(-10, -2, 0);
    try expectEqual(Self.min(a, b), minimum);
}

test "Vectors.max" {
    const a = Self.new(10, -2, 0);
    const b = Self.new(-10, 5, 0);
    const maximum = Self.new(10, 5, 0);
    try expectEqual(Self.max(a, b), maximum);
}

test "Vectors.fromSlice" {
    const slice = [_]f32{ 2, 4, 3 };
    try expectEqual(Self.fromSlice(&slice), Self.new(2, 4, 3));
}

test "Vectors.cross" {
    const a = Self.new(1.5, 2.6, 3.7);
    const b = Self.new(2.5, 3.45, 1.0);
    const c = Self.new(1.5, 2.6, 3.7);

    const result_1 = Self.cross(a, c);
    const result_2 = Self.cross(a, b);

    try expectEqual(result_1, Self.zero());
    try expectEqual(result_2, Self.new(-10.1650009, 7.75, -1.32499980));
}
