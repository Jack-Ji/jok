//! 2D vector mathematics for the j2d module.
//!
//! Provides a comprehensive 2D vector type with common operations including:
//! - Basic arithmetic (add, subtract, multiply, scale)
//! - Geometric operations (length, distance, normalize, dot product)
//! - Interpolation and comparison
//! - Angle calculations
//!
//! All operations return new vectors and do not modify the original.

const std = @import("std");
const math = std.math;
const expectEqual = std.testing.expectEqual;
const jok = @import("../jok.zig");
const geom = jok.geom;
const Vec = @Vector(2, f32);
const Self = @This();

/// Internal SIMD vector data
data: Vec,

/// Zero vector (0, 0)
pub const zero = set(0);

/// Unit vector (1, 1)
pub const one = set(1);

/// Up direction (0, -1) - negative Y is up in screen coordinates
pub const up = new(0, -1);

/// Down direction (0, 1)
pub const down = new(0, 1);

/// Left direction (-1, 0)
pub const left = new(-1, 0);

/// Right direction (1, 0)
pub const right = new(1, 0);

/// Construct a new vector from x and y components.
///
/// Parameters:
///   - vx: X component
///   - vy: Y component
pub fn new(vx: f32, vy: f32) Self {
    return .{ .data = [2]f32{ vx, vy } };
}

/// Convert vector to a geom.Point.
pub fn toPoint(self: Self) geom.Point {
    return .{ .x = self.data[0], .y = self.data[1] };
}

/// Get the X component of the vector.
pub fn x(self: Self) f32 {
    return self.data[0];
}

/// Get the Y component of the vector.
pub fn y(self: Self) f32 {
    return self.data[1];
}

/// Create a vector with all components set to the same value.
///
/// Parameters:
///   - val: Value for both X and Y components
pub fn set(val: f32) Self {
    const result = @as(Vec, @splat(val));
    return .{ .data = result };
}

/// Negate the vector (multiply by -1).
pub fn negate(self: Self) Self {
    return self.scale(-1);
}

/// Construct a vector from a slice of floats.
///
/// Parameters:
///   - slice: Slice containing at least 2 floats
pub fn fromSlice(slice: []const f32) Self {
    const result = slice[0..2].*;
    return .{ .data = result };
}

/// Convert vector to a 2-element array.
pub fn toArray(self: Self) [2]f32 {
    return self.data;
}

/// Calculate the angle in degrees between two vectors.
///
/// Parameters:
///   - first_vector: First vector
///   - second_vector: Second vector
/// Returns: Angle in degrees (0-180)
pub fn getAngleDegreeBetween(first_vector: Self, second_vector: Self) f32 {
    return std.math.radiansToDegrees(first_vector.getAngleBetween(second_vector));
}

/// Calculate the angle in radians between two vectors.
///
/// Parameters:
///   - first_vector: First vector
///   - second_vector: Second vector
/// Returns: Angle in radians (0-π)
pub fn getAngleBetween(first_vector: Self, second_vector: Self) f32 {
    const dot_product = dot(norm(first_vector), norm(second_vector));
    return math.acos(dot_product);
}

/// Calculate the length (magnitude) of the vector.
/// Formula: √(x² + y²)
pub fn length(self: Self) f32 {
    return @sqrt(self.dot(self));
}

/// Calculate the distance between two points.
/// Formula: √((x1-x2)² + (y1-y2)²)
///
/// Parameters:
///   - first_vector: First point
///   - second_vector: Second point
pub fn distance(first_vector: Self, second_vector: Self) f32 {
    return length(first_vector.sub(second_vector));
}

/// Normalize the vector to unit length.
/// Returns a vector with the same direction but length of 1.
/// If the vector has zero length, returns the original vector.
pub fn norm(self: Self) Self {
    const l = self.length();
    if (l == 0) {
        return self;
    }
    const result = self.data / @as(Vec, @splat(l));
    return .{ .data = result };
}

/// Check if two vectors are equal.
///
/// Parameters:
///   - first_vector: First vector
///   - second_vector: Second vector
pub fn eql(first_vector: Self, second_vector: Self) bool {
    return @reduce(.And, first_vector.data == second_vector.data);
}

/// Subtract one vector from another.
///
/// Parameters:
///   - first_vector: Vector to subtract from
///   - second_vector: Vector to subtract
pub fn sub(first_vector: Self, second_vector: Self) Self {
    const result = first_vector.data - second_vector.data;
    return .{ .data = result };
}

/// Add two vectors together.
///
/// Parameters:
///   - first_vector: First vector
///   - second_vector: Second vector
pub fn add(first_vector: Self, second_vector: Self) Self {
    const result = first_vector.data + second_vector.data;
    return .{ .data = result };
}

/// Component-wise multiplication of two vectors.
///
/// Parameters:
///   - first_vector: First vector
///   - second_vector: Second vector
pub fn mul(first_vector: Self, second_vector: Self) Self {
    const result = first_vector.data * second_vector.data;
    return .{ .data = result };
}

/// Create a vector from the maximum components of two vectors.
///
/// Parameters:
///   - first_vector: First vector
///   - second_vector: Second vector
pub fn max(first_vector: Self, second_vector: Self) Self {
    const result = @max(first_vector.data, second_vector.data);
    return .{ .data = result };
}

/// Create a vector from the minimum components of two vectors.
///
/// Parameters:
///   - first_vector: First vector
///   - second_vector: Second vector
pub fn min(first_vector: Self, second_vector: Self) Self {
    const result = @min(first_vector.data, second_vector.data);
    return .{ .data = result };
}

/// Scale the vector by a scalar value.
/// Multiplies each component by the scalar.
///
/// Parameters:
///   - scalar: Value to multiply by
pub fn scale(self: Self, scalar: f32) Self {
    const result = self.data * @as(Vec, @splat(scalar));
    return .{ .data = result };
}

/// Calculate the dot product of two vectors.
/// Formula: (x1 * x2) + (y1 * y2)
///
/// Parameters:
///   - first_vector: First vector
///   - second_vector: Second vector
pub fn dot(first_vector: Self, second_vector: Self) f32 {
    return @reduce(.Add, first_vector.data * second_vector.data);
}

/// Linear interpolation between two vectors.
///
/// Parameters:
///   - first_vector: Start vector (t=0)
///   - second_vector: End vector (t=1)
///   - t: Interpolation factor (0.0 to 1.0)
pub fn lerp(first_vector: Self, second_vector: Self, t: f32) Self {
    const from = first_vector.data;
    const to = second_vector.data;

    const result = from + (to - from) * @as(Vec, @splat(t));
    return .{ .data = result };
}

test "Vectors.eql" {
    const a = Self.new(1, 2);
    const b = Self.new(1, 2);
    const c = Self.new(1.5, 2);

    try expectEqual(Self.eql(a, b), true);
    try expectEqual(Self.eql(a, c), false);
}

test "Vectors.set" {
    const a = Self.new(2.5, 2.5);
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
    try expectEqual(math.approxEqAbs(f32, right.getAngleDegreeBetween(right), 0, 0.0001), true);
    try expectEqual(math.approxEqAbs(f32, right.getAngleDegreeBetween(up), 90, 0.0001), true);
    try expectEqual(math.approxEqAbs(f32, right.getAngleDegreeBetween(left), 180, 0.0001), true);
    try expectEqual(math.approxEqAbs(f32, right.getAngleDegreeBetween(one), 45, 0.0001), true);
}

test "Vectors.toArray" {
    const a = up.toArray();
    const b = [_]f32{ 0, -1 };

    try std.testing.expectEqualSlices(f32, &a, &b);
}

test "Vectors.length" {
    const a = Self.new(1.5, 2.6);
    try expectEqual(a.length(), 3.00166606);
}

test "Vectors.distance" {
    const c = Self.new(0, 5);

    try expectEqual(zero.distance(left), 1);
    try expectEqual(zero.distance(c), 5);
}

test "Vectors.normalize" {
    const a = Self.new(1.5, 2.6);
    const a_normalized = Self.new(0.499722480, 0.866185605);
    try expectEqual(a.norm(), a_normalized);
}

test "Vectors.scale" {
    const a = Self.new(1, 2);
    const a_scaled = Self.new(5, 10);
    try expectEqual(a.scale(5), a_scaled);
}

test "Vectors.dot" {
    const a = Self.new(1.5, 2.6);
    const b = Self.new(2.5, 3.45);
    try expectEqual(a.dot(b), 12.7200002);
}

test "Vectors.lerp" {
    const a = Self.new(-10, 0);
    const b = Self.set(10);
    try expectEqual(Self.lerp(a, b, 0.5), Self.new(0, 5));
}

test "Vectors.min" {
    const a = Self.new(10, -2);
    const b = Self.new(-10, 5);
    const minimum = Self.new(-10, -2);
    try expectEqual(Self.min(a, b), minimum);
}

test "Vectors.max" {
    const a = Self.new(10, -2);
    const b = Self.new(-10, 5);
    const maximum = Self.new(10, 5);
    try expectEqual(Self.max(a, b), maximum);
}

test "Vectors.fromSlice" {
    const slice = [_]f32{ 2, 4 };
    try expectEqual(Self.fromSlice(&slice), Self.new(2, 4));
}
