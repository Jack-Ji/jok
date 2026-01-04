const std = @import("std");
const math = std.math;
const expectEqual = std.testing.expectEqual;
const jok = @import("../jok.zig");
const Vec = @Vector(2, f32);
const Self = @This();

data: Vec,

pub const zero = set(0);
pub const one = set(1);
pub const up = new(0, -1);
pub const down = new(0, 1);
pub const left = new(-1, 0);
pub const right = new(1, 0);

/// Construct new vector.
pub fn new(vx: f32, vy: f32) Self {
    return .{ .data = [2]f32{ vx, vy } };
}

pub fn toPoint(self: Self) jok.Point {
    return .{ .x = self.data[0], .y = self.data[1] };
}

pub fn x(self: Self) f32 {
    return self.data[0];
}

pub fn y(self: Self) f32 {
    return self.data[1];
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
    const result = slice[0..2].*;
    return .{ .data = result };
}

/// Transform vector to array.
pub fn toArray(self: Self) [2]f32 {
    return self.data;
}

/// Return the angle (in degrees) between two vectors.
pub fn getAngleDegreeBetween(first_vector: Self, second_vector: Self) f32 {
    return std.math.radiansToDegrees(first_vector.getAngleBetween(second_vector));
}

/// Return the angle between two vectors.
pub fn getAngleBetween(first_vector: Self, second_vector: Self) f32 {
    const dot_product = dot(norm(first_vector), norm(second_vector));
    return math.acos(dot_product);
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
