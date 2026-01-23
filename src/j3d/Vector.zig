//! 3D vector mathematics module.
//!
//! This module provides a 3D vector type with common vector operations including:
//! - Basic arithmetic (add, subtract, multiply, scale)
//! - Vector operations (dot product, cross product, normalization)
//! - Geometric calculations (length, distance, angle)
//! - Interpolation and component-wise operations
//!
//! The vector uses SIMD operations internally for performance.

const std = @import("std");
const math = std.math;
const expectEqual = std.testing.expectEqual;
const jok = @import("../jok.zig");
const Vec = @Vector(3, f32);
const Self = @This();

/// Internal SIMD vector data
data: Vec,

/// Zero vector (0, 0, 0)
pub const zero = set(0);
/// Unit vector (1, 1, 1)
pub const one = set(1);
/// Forward direction (0, 0, 1)
pub const forward = new(0, 0, 1);
/// Backward direction (0, 0, -1)
pub const back = new(0, 0, -1);
/// Up direction (0, 1, 0)
pub const up = new(0, 1, 0);
/// Down direction (0, -1, 0)
pub const down = new(0, -1, 0);
/// Left direction (-1, 0, 0)
pub const left = new(-1, 0, 0);
/// Right direction (1, 0, 0)
pub const right = new(1, 0, 0);

/// Create a new vector from three components
pub fn new(vx: f32, vy: f32, vz: f32) Self {
    return .{ .data = [3]f32{ vx, vy, vz } };
}

/// Get the X component
pub fn x(self: Self) f32 {
    return self.data[0];
}

/// Get the Y component
pub fn y(self: Self) f32 {
    return self.data[1];
}

/// Get the Z component
pub fn z(self: Self) f32 {
    return self.data[2];
}

/// Set all components to the same given value.
pub fn set(val: f32) Self {
    const result = @as(Vec, @splat(val));
    return .{ .data = result };
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

/// Calculate the angle (in degrees) between two vectors
pub fn getAngleDegreeBetween(first_vector: Self, second_vector: Self) f32 {
    return std.math.radiansToDegrees(first_vector.getAngleBetween(second_vector));
}

/// Calculate the angle (in radians) between two vectors
pub fn getAngleBetween(first_vector: Self, second_vector: Self) f32 {
    const dot_product = dot(norm(first_vector), norm(second_vector));
    return math.acos(dot_product);
}

/// Calculate the length (magnitude) of the vector
/// Formula: √(x² + y² + z²)
pub fn length(self: Self) f32 {
    return @sqrt(self.dot(self));
}

/// Calculate the distance between two points
/// Formula: √((x1 - x2)² + (y1 - y2)² + (z1 - z2)²)
pub fn distance(first_vector: Self, second_vector: Self) f32 {
    return length(first_vector.sub(second_vector));
}

/// Create a normalized (unit length) vector from this vector
/// Returns the original vector if its length is zero
pub fn norm(self: Self) Self {
    const l = self.length();
    if (l == 0) {
        return self;
    }
    const result = self.data / @as(Vec, @splat(l));
    return .{ .data = result };
}

/// Check if two vectors are equal
pub fn eql(first_vector: Self, second_vector: Self) bool {
    return @reduce(.And, first_vector.data == second_vector.data);
}

/// Subtract one vector from another
pub fn sub(first_vector: Self, second_vector: Self) Self {
    const result = first_vector.data - second_vector.data;
    return .{ .data = result };
}

/// Add two vectors together
pub fn add(first_vector: Self, second_vector: Self) Self {
    const result = first_vector.data + second_vector.data;
    return .{ .data = result };
}

/// Component-wise multiplication of two vectors
pub fn mul(first_vector: Self, second_vector: Self) Self {
    const result = first_vector.data * second_vector.data;
    return .{ .data = result };
}

/// Create a vector from the maximum components of two vectors
pub fn max(first_vector: Self, second_vector: Self) Self {
    const result = @max(first_vector.data, second_vector.data);
    return .{ .data = result };
}

/// Create a vector from the minimum components of two vectors
pub fn min(first_vector: Self, second_vector: Self) Self {
    const result = @min(first_vector.data, second_vector.data);
    return .{ .data = result };
}

/// Multiply each component by a scalar value
pub fn scale(self: Self, scalar: f32) Self {
    const result = self.data * @as(Vec, @splat(scalar));
    return .{ .data = result };
}

/// Calculate the dot product of two vectors
/// Formula: (x1 * x2) + (y1 * y2) + (z1 * z2)
pub fn dot(first_vector: Self, second_vector: Self) f32 {
    return @reduce(.Add, first_vector.data * second_vector.data);
}

/// Perform linear interpolation between two vectors
/// t=0 returns first_vector, t=1 returns second_vector
pub fn lerp(first_vector: Self, second_vector: Self, t: f32) Self {
    const from = first_vector.data;
    const to = second_vector.data;

    const result = from + (to - from) * @as(Vec, @splat(t));
    return .{ .data = result };
}

/// Calculate the cross product of two vectors
/// Returns a vector perpendicular to both input vectors
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
    try expectEqual(one.add(one), Self.set(2));
}

test "Vectors.negate" {
    const a = Self.set(5);
    const a_negated = Self.set(-5);
    try expectEqual(a.negate(), a_negated);
}

test "Vectors.getAngleDegreeBetween" {
    const d = Self.new(1, 1, 0);

    try expectEqual(math.approxEqAbs(f32, right.getAngleDegreeBetween(right), 0, 0.0001), true);
    try expectEqual(math.approxEqAbs(f32, right.getAngleDegreeBetween(up), 90, 0.0001), true);
    try expectEqual(math.approxEqAbs(f32, right.getAngleDegreeBetween(left), 180, 0.0001), true);
    try expectEqual(math.approxEqAbs(f32, right.getAngleDegreeBetween(d), 45, 0.0001), true);
}

test "Vectors.toArray" {
    const a = up.toArray();
    const b = [_]f32{ 0, 1, 0 };

    try std.testing.expectEqualSlices(f32, &a, &b);
}

test "Vectors.length" {
    const a = Self.new(1.5, 2.6, 3.7);
    try expectEqual(a.length(), 4.7644519);
}

test "Vectors.distance" {
    const c = Self.new(0, 5, 0);

    try expectEqual(zero.distance(left), 1);
    try expectEqual(zero.distance(c), 5);
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

    try expectEqual(result_1, zero);
    try expectEqual(result_2, Self.new(-10.1650009, 7.75, -1.32499980));
}
