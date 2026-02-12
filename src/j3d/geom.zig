//! 3D geometry primitives with intersection and raycast support.
//!
//! Primitives:
//! - Ray: Ray defined by origin and direction
//! - AABB: Axis-Aligned Bounding Box for fast collision detection
//! - Sphere: Sphere defined by center and radius
//! - Plane: Infinite plane defined by point and normal
//! - Triangle: Triangle defined by three vertices
//! - OBB: Oriented Bounding Box for rotated collision volumes
//!
//! All intersection tests return boolean or optional hit information.
//! Raycast operations return detailed hit information including distance and normal.

const std = @import("std");
const assert = std.debug.assert;
const math = std.math;
const jok = @import("../jok.zig");
const zmath = jok.vendor.zmath;

const epsilon = 1e-6;

/// 3D ray defined by origin and direction.
pub const Ray = struct {
    origin: [3]f32,
    direction: [3]f32,

    /// Hit information returned by raycast operations
    pub const Hit = struct {
        /// Distance from ray origin to hit point
        distance: f32,
        /// Hit point in world space
        point: [3]f32,
        /// Surface normal at hit point
        normal: [3]f32,
    };

    /// Create a ray from origin and direction.
    /// Direction will be normalized automatically.
    pub fn init(origin: [3]f32, direction: [3]f32) Ray {
        const dir_vec = zmath.f32x4(direction[0], direction[1], direction[2], 0);
        const normalized = zmath.normalize3(dir_vec);
        return .{
            .origin = origin,
            .direction = zmath.vecToArr3(normalized),
        };
    }

    /// Get point along ray at distance t
    pub fn at(self: Ray, t: f32) [3]f32 {
        return .{
            self.origin[0] + self.direction[0] * t,
            self.origin[1] + self.direction[1] * t,
            self.origin[2] + self.direction[2] * t,
        };
    }

    /// Raycast against various geometry types
    pub fn raycast(self: Ray, target: anytype) ?Hit {
        const T = @TypeOf(target);
        if (T == AABB) return self.raycastAABB(target);
        if (T == Sphere) return self.raycastSphere(target);
        if (T == Plane) return self.raycastPlane(target);
        if (T == Triangle) return self.raycastTriangle(target);
        if (T == OBB) return self.raycastOBB(target);
        @compileError("Unsupported raycast target type: " ++ @typeName(T));
    }

    /// Raycast against AABB, returns hit info if intersects
    pub fn raycastAABB(self: Ray, aabb: AABB) ?Hit {
        var tmin: f32 = -math.inf(f32);
        var tmax: f32 = math.inf(f32);
        var hit_normal: [3]f32 = .{ 0, 0, 0 };

        inline for (0..3) |i| {
            if (@abs(self.direction[i]) < epsilon) {
                if (self.origin[i] < aabb.min[i] or self.origin[i] > aabb.max[i]) return null;
            } else {
                const inv_d = 1.0 / self.direction[i];
                var t1 = (aabb.min[i] - self.origin[i]) * inv_d;
                var t2 = (aabb.max[i] - self.origin[i]) * inv_d;
                var normal: [3]f32 = .{ 0, 0, 0 };
                if (t1 > t2) {
                    const tmp = t1;
                    t1 = t2;
                    t2 = tmp;
                    normal[i] = 1;
                } else {
                    normal[i] = -1;
                }
                if (t1 > tmin) {
                    tmin = t1;
                    hit_normal = normal;
                }
                tmax = @min(tmax, t2);
                if (tmin > tmax) return null;
            }
        }

        if (tmin < 0) return null;
        return .{
            .distance = tmin,
            .point = self.at(tmin),
            .normal = hit_normal,
        };
    }

    /// Raycast against Sphere
    pub fn raycastSphere(self: Ray, sphere: Sphere) ?Hit {
        const oc_vec = zmath.f32x4(
            self.origin[0] - sphere.center[0],
            self.origin[1] - sphere.center[1],
            self.origin[2] - sphere.center[2],
            0,
        );
        const dir_vec = zmath.f32x4(self.direction[0], self.direction[1], self.direction[2], 0);

        const a = zmath.dot3(dir_vec, dir_vec)[0];
        const b = 2.0 * zmath.dot3(oc_vec, dir_vec)[0];
        const c = zmath.dot3(oc_vec, oc_vec)[0] - sphere.radius * sphere.radius;
        const discriminant = b * b - 4.0 * a * c;

        if (discriminant < 0) return null;

        const sqrt_d = @sqrt(discriminant);
        var t = (-b - sqrt_d) / (2.0 * a);
        if (t < epsilon) {
            t = (-b + sqrt_d) / (2.0 * a);
            if (t < epsilon) return null;
        }

        const point = self.at(t);
        const normal_vec = zmath.normalize3(zmath.f32x4(
            point[0] - sphere.center[0],
            point[1] - sphere.center[1],
            point[2] - sphere.center[2],
            0,
        ));
        return .{ .distance = t, .point = point, .normal = zmath.vecToArr3(normal_vec) };
    }

    /// Raycast against Plane
    pub fn raycastPlane(self: Ray, plane: Plane) ?Hit {
        const dir_vec = zmath.f32x4(self.direction[0], self.direction[1], self.direction[2], 0);
        const normal_vec = zmath.f32x4(plane.normal[0], plane.normal[1], plane.normal[2], 0);
        const denom = zmath.dot3(dir_vec, normal_vec)[0];

        if (@abs(denom) < epsilon) return null;

        const diff_vec = zmath.f32x4(
            plane.point[0] - self.origin[0],
            plane.point[1] - self.origin[1],
            plane.point[2] - self.origin[2],
            0,
        );
        const t = zmath.dot3(diff_vec, normal_vec)[0] / denom;
        if (t < epsilon) return null;

        const normal = if (denom > 0) [3]f32{
            -plane.normal[0],
            -plane.normal[1],
            -plane.normal[2],
        } else plane.normal;

        return .{ .distance = t, .point = self.at(t), .normal = normal };
    }

    /// Raycast against Triangle (Moller-Trumbore algorithm)
    pub fn raycastTriangle(self: Ray, tri: Triangle) ?Hit {
        const v0 = zmath.f32x4(tri.v0[0], tri.v0[1], tri.v0[2], 0);
        const v1 = zmath.f32x4(tri.v1[0], tri.v1[1], tri.v1[2], 0);
        const v2 = zmath.f32x4(tri.v2[0], tri.v2[1], tri.v2[2], 0);
        const dir_vec = zmath.f32x4(self.direction[0], self.direction[1], self.direction[2], 0);
        const origin_vec = zmath.f32x4(self.origin[0], self.origin[1], self.origin[2], 0);

        const e1 = v1 - v0;
        const e2 = v2 - v0;
        const h = zmath.cross3(dir_vec, e2);
        const a = zmath.dot3(e1, h)[0];

        if (@abs(a) < epsilon) return null;

        const f = 1.0 / a;
        const s = origin_vec - v0;
        const u = f * zmath.dot3(s, h)[0];
        if (u < 0.0 or u > 1.0) return null;

        const q = zmath.cross3(s, e1);
        const v = f * zmath.dot3(dir_vec, q)[0];
        if (v < 0.0 or u + v > 1.0) return null;

        const t = f * zmath.dot3(e2, q)[0];
        if (t < epsilon) return null;

        var normal_vec = zmath.normalize3(zmath.cross3(e1, e2));
        if (zmath.dot3(normal_vec, dir_vec)[0] > 0) {
            normal_vec = -normal_vec;
        }
        return .{ .distance = t, .point = self.at(t), .normal = zmath.vecToArr3(normal_vec) };
    }

    /// Raycast against OBB by transforming ray into OBB local space
    pub fn raycastOBB(self: Ray, obb: OBB) ?Hit {
        const origin_vec = zmath.f32x4(self.origin[0], self.origin[1], self.origin[2], 0);
        const center_vec = zmath.f32x4(obb.center[0], obb.center[1], obb.center[2], 0);
        const d = origin_vec - center_vec;

        const axis0 = zmath.f32x4(obb.axes[0][0], obb.axes[0][1], obb.axes[0][2], 0);
        const axis1 = zmath.f32x4(obb.axes[1][0], obb.axes[1][1], obb.axes[1][2], 0);
        const axis2 = zmath.f32x4(obb.axes[2][0], obb.axes[2][1], obb.axes[2][2], 0);
        const dir_vec = zmath.f32x4(self.direction[0], self.direction[1], self.direction[2], 0);

        const local_origin: [3]f32 = .{
            zmath.dot3(d, axis0)[0],
            zmath.dot3(d, axis1)[0],
            zmath.dot3(d, axis2)[0],
        };
        const local_dir: [3]f32 = .{
            zmath.dot3(dir_vec, axis0)[0],
            zmath.dot3(dir_vec, axis1)[0],
            zmath.dot3(dir_vec, axis2)[0],
        };

        const local_aabb = AABB{
            .min = .{ -obb.half_extents[0], -obb.half_extents[1], -obb.half_extents[2] },
            .max = obb.half_extents,
        };
        const local_ray = Ray{ .origin = local_origin, .direction = local_dir };

        if (local_ray.raycastAABB(local_aabb)) |hit| {
            const world_normal: [3]f32 = .{
                hit.normal[0] * obb.axes[0][0] + hit.normal[1] * obb.axes[1][0] + hit.normal[2] * obb.axes[2][0],
                hit.normal[0] * obb.axes[0][1] + hit.normal[1] * obb.axes[1][1] + hit.normal[2] * obb.axes[2][1],
                hit.normal[0] * obb.axes[0][2] + hit.normal[1] * obb.axes[1][2] + hit.normal[2] * obb.axes[2][2],
            };
            return .{
                .distance = hit.distance,
                .point = self.at(hit.distance),
                .normal = world_normal,
            };
        }
        return null;
    }
};

/// Axis-Aligned Bounding Box
pub const AABB = struct {
    min: [3]f32,
    max: [3]f32,

    /// Create AABB from min and max points
    pub fn init(min: [3]f32, max: [3]f32) AABB {
        return .{ .min = min, .max = max };
    }

    /// Create AABB from center and half extents
    pub fn fromCenterExtents(c: [3]f32, half_extents: [3]f32) AABB {
        return .{
            .min = .{
                c[0] - half_extents[0],
                c[1] - half_extents[1],
                c[2] - half_extents[2],
            },
            .max = .{
                c[0] + half_extents[0],
                c[1] + half_extents[1],
                c[2] + half_extents[2],
            },
        };
    }

    /// Get center point
    pub fn center(self: AABB) [3]f32 {
        return .{
            (self.min[0] + self.max[0]) * 0.5,
            (self.min[1] + self.max[1]) * 0.5,
            (self.min[2] + self.max[2]) * 0.5,
        };
    }

    /// Get half extents
    pub fn halfExtents(self: AABB) [3]f32 {
        return .{
            (self.max[0] - self.min[0]) * 0.5,
            (self.max[1] - self.min[1]) * 0.5,
            (self.max[2] - self.min[2]) * 0.5,
        };
    }

    /// Check if point is inside AABB
    pub fn containsPoint(self: AABB, point: [3]f32) bool {
        return point[0] >= self.min[0] and point[0] <= self.max[0] and
            point[1] >= self.min[1] and point[1] <= self.max[1] and
            point[2] >= self.min[2] and point[2] <= self.max[2];
    }

    /// Generic intersection dispatcher
    pub fn intersect(self: AABB, target: anytype) bool {
        const T = @TypeOf(target);
        if (T == AABB) return self.intersectAABB(target);
        if (T == Sphere) return self.intersectSphere(target);
        if (T == Plane) return self.intersectPlane(target);
        if (T == Triangle) return self.intersectTriangle(target);
        if (T == OBB) return self.intersectOBB(target);
        @compileError("Unsupported intersection target type: " ++ @typeName(T));
    }

    /// AABB-AABB intersection
    pub fn intersectAABB(self: AABB, other: AABB) bool {
        return self.min[0] <= other.max[0] and self.max[0] >= other.min[0] and
            self.min[1] <= other.max[1] and self.max[1] >= other.min[1] and
            self.min[2] <= other.max[2] and self.max[2] >= other.min[2];
    }

    /// AABB-Sphere intersection
    pub fn intersectSphere(self: AABB, sphere: Sphere) bool {
        var sqDist: f32 = 0;
        inline for (0..3) |i| {
            const v = sphere.center[i];
            if (v < self.min[i]) sqDist += (self.min[i] - v) * (self.min[i] - v);
            if (v > self.max[i]) sqDist += (v - self.max[i]) * (v - self.max[i]);
        }
        return sqDist <= sphere.radius * sphere.radius;
    }

    /// AABB-Plane intersection
    pub fn intersectPlane(self: AABB, plane: Plane) bool {
        const c = self.center();
        const e = self.halfExtents();
        const n = zmath.f32x4(plane.normal[0], plane.normal[1], plane.normal[2], 0);
        const cv = zmath.f32x4(c[0], c[1], c[2], 0);
        const pv = zmath.f32x4(plane.point[0], plane.point[1], plane.point[2], 0);
        const r = @abs(e[0] * plane.normal[0]) +
            @abs(e[1] * plane.normal[1]) +
            @abs(e[2] * plane.normal[2]);
        const s = zmath.dot3(n, cv)[0] - zmath.dot3(n, pv)[0];
        return @abs(s) <= r;
    }

    /// AABB-Triangle intersection (SAT)
    pub fn intersectTriangle(self: AABB, tri: Triangle) bool {
        const c = self.center();
        const e = self.halfExtents();
        const cv = zmath.f32x4(c[0], c[1], c[2], 0);
        const tv0 = zmath.f32x4(tri.v0[0], tri.v0[1], tri.v0[2], 0) - cv;
        const tv1 = zmath.f32x4(tri.v1[0], tri.v1[1], tri.v1[2], 0) - cv;
        const tv2 = zmath.f32x4(tri.v2[0], tri.v2[1], tri.v2[2], 0) - cv;
        const v0 = zmath.vecToArr3(tv0);
        const v1 = zmath.vecToArr3(tv1);
        const v2 = zmath.vecToArr3(tv2);

        const f0 = zmath.vecToArr3(tv1 - tv0);
        const f1 = zmath.vecToArr3(tv2 - tv1);
        const f2 = zmath.vecToArr3(tv0 - tv2);

        // Test axes a00..a22
        const axes = [_][3]f32{
            .{ 0, -f0[2], f0[1] },
            .{ 0, -f1[2], f1[1] },
            .{ 0, -f2[2], f2[1] },
            .{ f0[2], 0, -f0[0] },
            .{ f1[2], 0, -f1[0] },
            .{ f2[2], 0, -f2[0] },
            .{ -f0[1], f0[0], 0 },
            .{ -f1[1], f1[0], 0 },
            .{ -f2[1], f2[0], 0 },
        };

        for (axes) |axis| {
            const av = zmath.f32x4(axis[0], axis[1], axis[2], 0);
            const p0 = zmath.dot3(zmath.f32x4(v0[0], v0[1], v0[2], 0), av)[0];
            const p1 = zmath.dot3(zmath.f32x4(v1[0], v1[1], v1[2], 0), av)[0];
            const p2 = zmath.dot3(zmath.f32x4(v2[0], v2[1], v2[2], 0), av)[0];
            const r = e[0] * @abs(axis[0]) + e[1] * @abs(axis[1]) + e[2] * @abs(axis[2]);
            const min_p = @min(@min(p0, p1), p2);
            const max_p = @max(@max(p0, p1), p2);
            if (@max(-max_p, min_p) > r) return false;
        }

        // Test box normals
        if (@max(@max(v0[0], v1[0]), v2[0]) < -e[0] or @min(@min(v0[0], v1[0]), v2[0]) > e[0]) return false;
        if (@max(@max(v0[1], v1[1]), v2[1]) < -e[1] or @min(@min(v0[1], v1[1]), v2[1]) > e[1]) return false;
        if (@max(@max(v0[2], v1[2]), v2[2]) < -e[2] or @min(@min(v0[2], v1[2]), v2[2]) > e[2]) return false;

        // Test triangle normal
        const normal = zmath.cross3(tv1 - tv0, tv2 - tv1);
        const d = zmath.dot3(normal, tv0)[0];
        const nv = zmath.vecToArr3(normal);
        const r = e[0] * @abs(nv[0]) + e[1] * @abs(nv[1]) + e[2] * @abs(nv[2]);
        return @abs(d) <= r;
    }

    /// AABB-OBB intersection
    pub fn intersectOBB(self: AABB, obb: OBB) bool {
        return obb.intersectAABB(self);
    }
};

/// Sphere defined by center and radius
pub const Sphere = struct {
    center: [3]f32,
    radius: f32,

    /// Create sphere from center and radius
    pub fn init(center: [3]f32, radius: f32) Sphere {
        return .{ .center = center, .radius = radius };
    }

    /// Check if point is inside sphere
    pub fn containsPoint(self: Sphere, point: [3]f32) bool {
        const d = zmath.f32x4(point[0], point[1], point[2], 0) - zmath.f32x4(self.center[0], self.center[1], self.center[2], 0);
        return zmath.dot3(d, d)[0] <= self.radius * self.radius;
    }

    /// Generic intersection dispatcher
    pub fn intersect(self: Sphere, target: anytype) bool {
        const T = @TypeOf(target);
        if (T == Sphere) return self.intersectSphere(target);
        if (T == AABB) return self.intersectAABB(target);
        if (T == Plane) return self.intersectPlane(target);
        if (T == Triangle) return self.intersectTriangle(target);
        if (T == OBB) return self.intersectOBB(target);
        @compileError("Unsupported intersection target type: " ++ @typeName(T));
    }

    /// Sphere-Sphere intersection
    pub fn intersectSphere(self: Sphere, other: Sphere) bool {
        const d = zmath.f32x4(self.center[0], self.center[1], self.center[2], 0) -
            zmath.f32x4(other.center[0], other.center[1], other.center[2], 0);
        const dist_sq = zmath.dot3(d, d)[0];
        const radius_sum = self.radius + other.radius;
        return dist_sq <= radius_sum * radius_sum;
    }

    /// Sphere-AABB intersection
    pub fn intersectAABB(self: Sphere, aabb: AABB) bool {
        return aabb.intersectSphere(self);
    }

    /// Sphere-Plane intersection
    pub fn intersectPlane(self: Sphere, plane: Plane) bool {
        const sv = zmath.f32x4(self.center[0], self.center[1], self.center[2], 0) -
            zmath.f32x4(plane.point[0], plane.point[1], plane.point[2], 0);
        const nv = zmath.f32x4(plane.normal[0], plane.normal[1], plane.normal[2], 0);
        const d = zmath.dot3(sv, nv)[0];
        return @abs(d) <= self.radius;
    }

    /// Sphere-Triangle intersection
    pub fn intersectTriangle(self: Sphere, tri: Triangle) bool {
        const p = tri.closestPoint(self.center);
        const d = zmath.f32x4(self.center[0], self.center[1], self.center[2], 0) -
            zmath.f32x4(p[0], p[1], p[2], 0);
        return zmath.dot3(d, d)[0] <= self.radius * self.radius;
    }

    /// Sphere-OBB intersection
    pub fn intersectOBB(self: Sphere, obb: OBB) bool {
        const p = obb.closestPoint(self.center);
        const d = zmath.f32x4(self.center[0], self.center[1], self.center[2], 0) -
            zmath.f32x4(p[0], p[1], p[2], 0);
        return zmath.dot3(d, d)[0] <= self.radius * self.radius;
    }
};

/// Infinite plane defined by point and normal
pub const Plane = struct {
    point: [3]f32,
    normal: [3]f32,

    /// Create plane from point and normal
    pub fn init(point: [3]f32, normal: [3]f32) Plane {
        const nv = zmath.normalize3(zmath.f32x4(normal[0], normal[1], normal[2], 0));
        return .{ .point = point, .normal = zmath.vecToArr3(nv) };
    }

    /// Create plane from three points
    pub fn fromPoints(p0: [3]f32, p1: [3]f32, p2: [3]f32) Plane {
        const v0 = zmath.f32x4(p0[0], p0[1], p0[2], 0);
        const v1 = zmath.f32x4(p1[0], p1[1], p1[2], 0) - v0;
        const v2 = zmath.f32x4(p2[0], p2[1], p2[2], 0) - v0;
        const n = zmath.normalize3(zmath.cross3(v1, v2));
        return .{ .point = p0, .normal = zmath.vecToArr3(n) };
    }

    /// Get signed distance from point to plane
    pub fn distanceToPoint(self: Plane, point: [3]f32) f32 {
        const d = zmath.f32x4(point[0], point[1], point[2], 0) -
            zmath.f32x4(self.point[0], self.point[1], self.point[2], 0);
        const n = zmath.f32x4(self.normal[0], self.normal[1], self.normal[2], 0);
        return zmath.dot3(d, n)[0];
    }

    /// Project point onto plane
    pub fn projectPoint(self: Plane, point: [3]f32) [3]f32 {
        const d = self.distanceToPoint(point);
        return .{
            point[0] - self.normal[0] * d,
            point[1] - self.normal[1] * d,
            point[2] - self.normal[2] * d,
        };
    }

    /// Generic intersection dispatcher
    pub fn intersect(self: Plane, target: anytype) bool {
        const T = @TypeOf(target);
        if (T == Plane) return self.intersectPlane(target);
        if (T == AABB) return self.intersectAABB(target);
        if (T == Sphere) return self.intersectSphere(target);
        if (T == Triangle) return self.intersectTriangle(target);
        if (T == OBB) return self.intersectOBB(target);
        @compileError("Unsupported intersection target type: " ++ @typeName(T));
    }

    /// Plane-Plane intersection (returns true if not parallel)
    pub fn intersectPlane(self: Plane, other: Plane) bool {
        const n1 = zmath.f32x4(self.normal[0], self.normal[1], self.normal[2], 0);
        const n2 = zmath.f32x4(other.normal[0], other.normal[1], other.normal[2], 0);
        const d = zmath.dot3(n1, n2)[0];
        return @abs(d) < 1.0 - epsilon;
    }

    /// Plane-AABB intersection
    pub fn intersectAABB(self: Plane, aabb: AABB) bool {
        return aabb.intersectPlane(self);
    }

    /// Plane-Sphere intersection
    pub fn intersectSphere(self: Plane, sphere: Sphere) bool {
        return sphere.intersectPlane(self);
    }

    /// Plane-Triangle intersection
    pub fn intersectTriangle(self: Plane, tri: Triangle) bool {
        const d0 = self.distanceToPoint(tri.v0);
        const d1 = self.distanceToPoint(tri.v1);
        const d2 = self.distanceToPoint(tri.v2);
        return (d0 * d1 <= 0) or (d0 * d2 <= 0) or (d1 * d2 <= 0);
    }

    /// Plane-OBB intersection
    pub fn intersectOBB(self: Plane, obb: OBB) bool {
        const n = zmath.f32x4(self.normal[0], self.normal[1], self.normal[2], 0);
        const a0 = zmath.f32x4(obb.axes[0][0], obb.axes[0][1], obb.axes[0][2], 0);
        const a1 = zmath.f32x4(obb.axes[1][0], obb.axes[1][1], obb.axes[1][2], 0);
        const a2 = zmath.f32x4(obb.axes[2][0], obb.axes[2][1], obb.axes[2][2], 0);
        const r = @abs(obb.half_extents[0] * zmath.dot3(n, a0)[0]) +
            @abs(obb.half_extents[1] * zmath.dot3(n, a1)[0]) +
            @abs(obb.half_extents[2] * zmath.dot3(n, a2)[0]);
        const cv = zmath.f32x4(obb.center[0], obb.center[1], obb.center[2], 0) -
            zmath.f32x4(self.point[0], self.point[1], self.point[2], 0);
        const s = zmath.dot3(n, cv)[0];
        return @abs(s) <= r;
    }
};

/// Triangle defined by three vertices
pub const Triangle = struct {
    v0: [3]f32,
    v1: [3]f32,
    v2: [3]f32,

    /// Create triangle from three vertices
    pub fn init(v0: [3]f32, v1: [3]f32, v2: [3]f32) Triangle {
        return .{ .v0 = v0, .v1 = v1, .v2 = v2 };
    }

    /// Get triangle normal
    pub fn normal(self: Triangle) [3]f32 {
        const v0 = zmath.f32x4(self.v0[0], self.v0[1], self.v0[2], 0);
        const v1 = zmath.f32x4(self.v1[0], self.v1[1], self.v1[2], 0);
        const v2 = zmath.f32x4(self.v2[0], self.v2[1], self.v2[2], 0);
        const e1 = v1 - v0;
        const e2 = v2 - v0;
        return zmath.vecToArr3(zmath.normalize3(zmath.cross3(e1, e2)));
    }

    /// Get triangle area
    pub fn area(self: Triangle) f32 {
        const v0 = zmath.f32x4(self.v0[0], self.v0[1], self.v0[2], 0);
        const v1 = zmath.f32x4(self.v1[0], self.v1[1], self.v1[2], 0);
        const v2 = zmath.f32x4(self.v2[0], self.v2[1], self.v2[2], 0);
        const e1 = v1 - v0;
        const e2 = v2 - v0;
        const cross = zmath.cross3(e1, e2);
        return @sqrt(zmath.dot3(cross, cross)[0]) * 0.5;
    }

    /// Find closest point on triangle to given point
    pub fn closestPoint(self: Triangle, point: [3]f32) [3]f32 {
        const p = zmath.f32x4(point[0], point[1], point[2], 0);
        const a = zmath.f32x4(self.v0[0], self.v0[1], self.v0[2], 0);
        const b = zmath.f32x4(self.v1[0], self.v1[1], self.v1[2], 0);
        const c = zmath.f32x4(self.v2[0], self.v2[1], self.v2[2], 0);

        const ab = b - a;
        const ac = c - a;
        const ap = p - a;

        const d1 = zmath.dot3(ab, ap)[0];
        const d2 = zmath.dot3(ac, ap)[0];
        if (d1 <= 0 and d2 <= 0) return zmath.vecToArr3(a);

        const bp = p - b;
        const d3 = zmath.dot3(ab, bp)[0];
        const d4 = zmath.dot3(ac, bp)[0];
        if (d3 >= 0 and d4 <= d3) return zmath.vecToArr3(b);

        const cp = p - c;
        const d5 = zmath.dot3(ab, cp)[0];
        const d6 = zmath.dot3(ac, cp)[0];
        if (d6 >= 0 and d5 <= d6) return zmath.vecToArr3(c);

        const vc = d1 * d4 - d3 * d2;
        if (vc <= 0 and d1 >= 0 and d3 <= 0) {
            const v = d1 / (d1 - d3);
            return zmath.vecToArr3(a + @as(zmath.Vec, @splat(v)) * ab);
        }

        const vb = d5 * d2 - d1 * d6;
        if (vb <= 0 and d2 >= 0 and d6 <= 0) {
            const w = d2 / (d2 - d6);
            return zmath.vecToArr3(a + @as(zmath.Vec, @splat(w)) * ac);
        }

        const va = d3 * d6 - d5 * d4;
        if (va <= 0 and (d4 - d3) >= 0 and (d5 - d6) >= 0) {
            const w = (d4 - d3) / ((d4 - d3) + (d5 - d6));
            return zmath.vecToArr3(b + @as(zmath.Vec, @splat(w)) * (c - b));
        }

        const denom = 1.0 / (va + vb + vc);
        const v = vb * denom;
        const w = vc * denom;
        return zmath.vecToArr3(a + @as(zmath.Vec, @splat(v)) * ab + @as(zmath.Vec, @splat(w)) * ac);
    }

    /// Generic intersection dispatcher
    pub fn intersect(self: Triangle, target: anytype) bool {
        const T = @TypeOf(target);
        if (T == AABB) return self.intersectAABB(target);
        if (T == Sphere) return self.intersectSphere(target);
        if (T == Plane) return self.intersectPlane(target);
        if (T == Triangle) return self.intersectTriangle(target);
        if (T == OBB) return self.intersectOBB(target);
        @compileError("Unsupported intersection target type: " ++ @typeName(T));
    }

    /// Triangle-AABB intersection
    pub fn intersectAABB(self: Triangle, aabb: AABB) bool {
        return aabb.intersectTriangle(self);
    }

    /// Triangle-Sphere intersection
    pub fn intersectSphere(self: Triangle, sphere: Sphere) bool {
        return sphere.intersectTriangle(self);
    }

    /// Triangle-Plane intersection
    pub fn intersectPlane(self: Triangle, plane: Plane) bool {
        return plane.intersectTriangle(self);
    }

    /// Triangle-OBB intersection
    pub fn intersectOBB(self: Triangle, obb: OBB) bool {
        return obb.intersectTriangle(self);
    }

    /// Triangle-Triangle intersection (SAT-based)
    pub fn intersectTriangle(self: Triangle, other: Triangle) bool {
        const v0 = zmath.f32x4(self.v0[0], self.v0[1], self.v0[2], 0);
        const v1 = zmath.f32x4(self.v1[0], self.v1[1], self.v1[2], 0);
        const v2 = zmath.f32x4(self.v2[0], self.v2[1], self.v2[2], 0);
        const w0 = zmath.f32x4(other.v0[0], other.v0[1], other.v0[2], 0);
        const w1 = zmath.f32x4(other.v1[0], other.v1[1], other.v1[2], 0);
        const w2 = zmath.f32x4(other.v2[0], other.v2[1], other.v2[2], 0);

        const n1 = zmath.normalize3(zmath.cross3(v1 - v0, v2 - v0));
        const n2 = zmath.normalize3(zmath.cross3(w1 - w0, w2 - w0));

        const d1_u0 = zmath.dot3(n1, w0 - v0)[0];
        const d1_u1 = zmath.dot3(n1, w1 - v0)[0];
        const d1_u2 = zmath.dot3(n1, w2 - v0)[0];
        if ((d1_u0 > epsilon and d1_u1 > epsilon and d1_u2 > epsilon) or
            (d1_u0 < -epsilon and d1_u1 < -epsilon and d1_u2 < -epsilon))
        {
            return false;
        }

        const d2_v0 = zmath.dot3(n2, v0 - w0)[0];
        const d2_v1 = zmath.dot3(n2, v1 - w0)[0];
        const d2_v2 = zmath.dot3(n2, v2 - w0)[0];
        if ((d2_v0 > epsilon and d2_v1 > epsilon and d2_v2 > epsilon) or
            (d2_v0 < -epsilon and d2_v1 < -epsilon and d2_v2 < -epsilon))
        {
            return false;
        }

        return true;
    }
};

/// Oriented Bounding Box defined by center, local axes, and half extents
pub const OBB = struct {
    center: [3]f32,
    axes: [3][3]f32,
    half_extents: [3]f32,

    /// Create OBB from center, axes, and half extents
    pub fn init(center: [3]f32, axes: [3][3]f32, half_extents: [3]f32) OBB {
        return .{ .center = center, .axes = axes, .half_extents = half_extents };
    }

    /// Create axis-aligned OBB (equivalent to AABB)
    pub fn fromAABB(aabb: AABB) OBB {
        return .{
            .center = aabb.center(),
            .axes = .{
                .{ 1, 0, 0 },
                .{ 0, 1, 0 },
                .{ 0, 0, 1 },
            },
            .half_extents = aabb.halfExtents(),
        };
    }

    /// Find closest point on OBB to given point
    pub fn closestPoint(self: OBB, point: [3]f32) [3]f32 {
        const pv = zmath.f32x4(point[0], point[1], point[2], 0);
        const cv = zmath.f32x4(self.center[0], self.center[1], self.center[2], 0);
        const d = pv - cv;
        var result = cv;

        inline for (0..3) |i| {
            const axis = zmath.f32x4(self.axes[i][0], self.axes[i][1], self.axes[i][2], 0);
            var dist = zmath.dot3(d, axis)[0];
            dist = @max(-self.half_extents[i], @min(dist, self.half_extents[i]));
            result += @as(zmath.Vec, @splat(dist)) * axis;
        }
        return zmath.vecToArr3(result);
    }

    /// Check if point is inside OBB
    pub fn containsPoint(self: OBB, point: [3]f32) bool {
        const pv = zmath.f32x4(point[0], point[1], point[2], 0);
        const cv = zmath.f32x4(self.center[0], self.center[1], self.center[2], 0);
        const d = pv - cv;

        inline for (0..3) |i| {
            const axis = zmath.f32x4(self.axes[i][0], self.axes[i][1], self.axes[i][2], 0);
            const dist = @abs(zmath.dot3(d, axis)[0]);
            if (dist > self.half_extents[i]) return false;
        }
        return true;
    }

    /// Generic intersection dispatcher
    pub fn intersect(self: OBB, target: anytype) bool {
        const T = @TypeOf(target);
        if (T == OBB) return self.intersectOBB(target);
        if (T == AABB) return self.intersectAABB(target);
        if (T == Sphere) return self.intersectSphere(target);
        if (T == Plane) return self.intersectPlane(target);
        if (T == Triangle) return self.intersectTriangle(target);
        @compileError("Unsupported intersection target type: " ++ @typeName(T));
    }

    /// OBB-AABB intersection (convert AABB to OBB, then use SAT)
    pub fn intersectAABB(self: OBB, aabb: AABB) bool {
        return self.intersectOBB(fromAABB(aabb));
    }

    /// OBB-Sphere intersection
    pub fn intersectSphere(self: OBB, sphere: Sphere) bool {
        const p = self.closestPoint(sphere.center);
        const d = zmath.f32x4(sphere.center[0], sphere.center[1], sphere.center[2], 0) -
            zmath.f32x4(p[0], p[1], p[2], 0);
        return zmath.dot3(d, d)[0] <= sphere.radius * sphere.radius;
    }

    /// OBB-Plane intersection
    pub fn intersectPlane(self: OBB, plane: Plane) bool {
        return plane.intersectOBB(self);
    }

    /// OBB-Triangle intersection (transform triangle into OBB local space)
    pub fn intersectTriangle(self: OBB, tri: Triangle) bool {
        const cv = zmath.f32x4(self.center[0], self.center[1], self.center[2], 0);
        const a0 = zmath.f32x4(self.axes[0][0], self.axes[0][1], self.axes[0][2], 0);
        const a1 = zmath.f32x4(self.axes[1][0], self.axes[1][1], self.axes[1][2], 0);
        const a2 = zmath.f32x4(self.axes[2][0], self.axes[2][1], self.axes[2][2], 0);

        const v0w = zmath.f32x4(tri.v0[0], tri.v0[1], tri.v0[2], 0) - cv;
        const v1w = zmath.f32x4(tri.v1[0], tri.v1[1], tri.v1[2], 0) - cv;
        const v2w = zmath.f32x4(tri.v2[0], tri.v2[1], tri.v2[2], 0) - cv;

        const v0: [3]f32 = .{ zmath.dot3(v0w, a0)[0], zmath.dot3(v0w, a1)[0], zmath.dot3(v0w, a2)[0] };
        const v1: [3]f32 = .{ zmath.dot3(v1w, a0)[0], zmath.dot3(v1w, a1)[0], zmath.dot3(v1w, a2)[0] };
        const v2: [3]f32 = .{ zmath.dot3(v2w, a0)[0], zmath.dot3(v2w, a1)[0], zmath.dot3(v2w, a2)[0] };

        const local_tri = Triangle.init(v0, v1, v2);
        const local_aabb = AABB{
            .min = .{ -self.half_extents[0], -self.half_extents[1], -self.half_extents[2] },
            .max = self.half_extents,
        };
        return local_aabb.intersectTriangle(local_tri);
    }

    /// OBB-OBB intersection using 15-axis SAT test
    pub fn intersectOBB(self: OBB, other: OBB) bool {
        const ca = zmath.f32x4(self.center[0], self.center[1], self.center[2], 0);
        const cb = zmath.f32x4(other.center[0], other.center[1], other.center[2], 0);
        const t = cb - ca;

        var a_axes: [3]zmath.Vec = undefined;
        var b_axes: [3]zmath.Vec = undefined;
        inline for (0..3) |i| {
            a_axes[i] = zmath.f32x4(self.axes[i][0], self.axes[i][1], self.axes[i][2], 0);
            b_axes[i] = zmath.f32x4(other.axes[i][0], other.axes[i][1], other.axes[i][2], 0);
        }

        // Rotation matrix and absolute rotation matrix
        var r_mat: [3][3]f32 = undefined;
        var abs_r: [3][3]f32 = undefined;
        inline for (0..3) |i| {
            inline for (0..3) |j| {
                r_mat[i][j] = zmath.dot3(a_axes[i], b_axes[j])[0];
                abs_r[i][j] = @abs(r_mat[i][j]) + epsilon;
            }
        }

        // Test axes L = A0, A1, A2
        inline for (0..3) |i| {
            const ra = self.half_extents[i];
            const rb = other.half_extents[0] * abs_r[i][0] +
                other.half_extents[1] * abs_r[i][1] +
                other.half_extents[2] * abs_r[i][2];
            if (@abs(zmath.dot3(t, a_axes[i])[0]) > ra + rb) return false;
        }

        // Test axes L = B0, B1, B2
        inline for (0..3) |i| {
            const ra = self.half_extents[0] * abs_r[0][i] +
                self.half_extents[1] * abs_r[1][i] +
                self.half_extents[2] * abs_r[2][i];
            const rb = other.half_extents[i];
            if (@abs(zmath.dot3(t, b_axes[i])[0]) > ra + rb) return false;
        }

        // Test 9 cross product axes
        // L = A0 x B0
        {
            const ra = self.half_extents[1] * abs_r[2][0] + self.half_extents[2] * abs_r[1][0];
            const rb = other.half_extents[1] * abs_r[0][2] + other.half_extents[2] * abs_r[0][1];
            if (@abs(zmath.dot3(t, a_axes[2])[0] * r_mat[1][0] - zmath.dot3(t, a_axes[1])[0] * r_mat[2][0]) > ra + rb) return false;
        }
        // L = A0 x B1
        {
            const ra = self.half_extents[1] * abs_r[2][1] + self.half_extents[2] * abs_r[1][1];
            const rb = other.half_extents[0] * abs_r[0][2] + other.half_extents[2] * abs_r[0][0];
            if (@abs(zmath.dot3(t, a_axes[2])[0] * r_mat[1][1] - zmath.dot3(t, a_axes[1])[0] * r_mat[2][1]) > ra + rb) return false;
        }
        // L = A0 x B2
        {
            const ra = self.half_extents[1] * abs_r[2][2] + self.half_extents[2] * abs_r[1][2];
            const rb = other.half_extents[0] * abs_r[0][1] + other.half_extents[1] * abs_r[0][0];
            if (@abs(zmath.dot3(t, a_axes[2])[0] * r_mat[1][2] - zmath.dot3(t, a_axes[1])[0] * r_mat[2][2]) > ra + rb) return false;
        }
        // L = A1 x B0
        {
            const ra = self.half_extents[0] * abs_r[2][0] + self.half_extents[2] * abs_r[0][0];
            const rb = other.half_extents[1] * abs_r[1][2] + other.half_extents[2] * abs_r[1][1];
            if (@abs(zmath.dot3(t, a_axes[0])[0] * r_mat[2][0] - zmath.dot3(t, a_axes[2])[0] * r_mat[0][0]) > ra + rb) return false;
        }
        // L = A1 x B1
        {
            const ra = self.half_extents[0] * abs_r[2][1] + self.half_extents[2] * abs_r[0][1];
            const rb = other.half_extents[0] * abs_r[1][2] + other.half_extents[2] * abs_r[1][0];
            if (@abs(zmath.dot3(t, a_axes[0])[0] * r_mat[2][1] - zmath.dot3(t, a_axes[2])[0] * r_mat[0][1]) > ra + rb) return false;
        }
        // L = A1 x B2
        {
            const ra = self.half_extents[0] * abs_r[2][2] + self.half_extents[2] * abs_r[0][2];
            const rb = other.half_extents[0] * abs_r[1][1] + other.half_extents[1] * abs_r[1][0];
            if (@abs(zmath.dot3(t, a_axes[0])[0] * r_mat[2][2] - zmath.dot3(t, a_axes[2])[0] * r_mat[0][2]) > ra + rb) return false;
        }
        // L = A2 x B0
        {
            const ra = self.half_extents[0] * abs_r[1][0] + self.half_extents[1] * abs_r[0][0];
            const rb = other.half_extents[1] * abs_r[2][2] + other.half_extents[2] * abs_r[2][1];
            if (@abs(zmath.dot3(t, a_axes[1])[0] * r_mat[0][0] - zmath.dot3(t, a_axes[0])[0] * r_mat[1][0]) > ra + rb) return false;
        }
        // L = A2 x B1
        {
            const ra = self.half_extents[0] * abs_r[1][1] + self.half_extents[1] * abs_r[0][1];
            const rb = other.half_extents[0] * abs_r[2][2] + other.half_extents[2] * abs_r[2][0];
            if (@abs(zmath.dot3(t, a_axes[1])[0] * r_mat[0][1] - zmath.dot3(t, a_axes[0])[0] * r_mat[1][1]) > ra + rb) return false;
        }
        // L = A2 x B2
        {
            const ra = self.half_extents[0] * abs_r[1][2] + self.half_extents[1] * abs_r[0][2];
            const rb = other.half_extents[0] * abs_r[2][1] + other.half_extents[1] * abs_r[2][0];
            if (@abs(zmath.dot3(t, a_axes[1])[0] * r_mat[0][2] - zmath.dot3(t, a_axes[0])[0] * r_mat[1][2]) > ra + rb) return false;
        }

        return true;
    }
};

// --- Tests ---

fn expectVecApprox(a: [3]f32, b: [3]f32, tol: f32) !void {
    try std.testing.expectApproxEqAbs(a[0], b[0], tol);
    try std.testing.expectApproxEqAbs(a[1], b[1], tol);
    try std.testing.expectApproxEqAbs(a[2], b[2], tol);
}

test "ray_aabb_hit" {
    const ray = Ray.init(.{ 0, 0, -5 }, .{ 0, 0, 1 });
    const aabb = AABB.init(.{ -1, -1, -1 }, .{ 1, 1, 1 });
    const hit = ray.raycast(aabb).?;
    try std.testing.expectApproxEqAbs(@as(f32, 4.0), hit.distance, epsilon);
    try std.testing.expectApproxEqAbs(@as(f32, 0.0), hit.normal[0], epsilon);
    try std.testing.expectApproxEqAbs(@as(f32, 0.0), hit.normal[1], epsilon);
    try std.testing.expectApproxEqAbs(@as(f32, -1.0), hit.normal[2], epsilon);
}

test "ray_aabb_miss" {
    const ray = Ray.init(.{ 0, 0, -5 }, .{ 0, 1, 0 });
    const aabb = AABB.init(.{ -1, -1, -1 }, .{ 1, 1, 1 });
    try std.testing.expect(ray.raycast(aabb) == null);
}

test "ray_aabb_inside_returns_null" {
    const ray = Ray.init(.{ 0, 0, 0 }, .{ 1, 0, 0 });
    const aabb = AABB.init(.{ -1, -1, -1 }, .{ 1, 1, 1 });
    try std.testing.expect(ray.raycast(aabb) == null);
}

test "ray_sphere_hit" {
    const ray = Ray.init(.{ 0, 0, -5 }, .{ 0, 0, 1 });
    const sphere = Sphere.init(.{ 0, 0, 0 }, 1.0);
    const hit = ray.raycast(sphere).?;
    try std.testing.expectApproxEqAbs(@as(f32, 4.0), hit.distance, epsilon);
}

test "ray_sphere_miss" {
    const ray = Ray.init(.{ 0, 3, -5 }, .{ 0, 0, 1 });
    const sphere = Sphere.init(.{ 0, 0, 0 }, 1.0);
    try std.testing.expect(ray.raycast(sphere) == null);
}

test "ray_plane_hit" {
    const ray = Ray.init(.{ 0, 5, 0 }, .{ 0, -1, 0 });
    const plane = Plane.init(.{ 0, 0, 0 }, .{ 0, 1, 0 });
    const hit = ray.raycast(plane).?;
    try std.testing.expectApproxEqAbs(@as(f32, 5.0), hit.distance, epsilon);
}

test "ray_plane_parallel_miss" {
    const ray = Ray.init(.{ 0, 1, 0 }, .{ 1, 0, 0 });
    const plane = Plane.init(.{ 0, 0, 0 }, .{ 0, 1, 0 });
    try std.testing.expect(ray.raycast(plane) == null);
}

test "ray_triangle_hit" {
    const ray = Ray.init(.{ 0.25, 0.25, -5 }, .{ 0, 0, 1 });
    const tri = Triangle.init(.{ 0, 0, 0 }, .{ 1, 0, 0 }, .{ 0, 1, 0 });
    const hit = ray.raycast(tri).?;
    try std.testing.expectApproxEqAbs(@as(f32, 5.0), hit.distance, epsilon);
}

test "ray_triangle_miss" {
    const ray = Ray.init(.{ 2, 2, -5 }, .{ 0, 0, 1 });
    const tri = Triangle.init(.{ 0, 0, 0 }, .{ 1, 0, 0 }, .{ 0, 1, 0 });
    try std.testing.expect(ray.raycast(tri) == null);
}

test "ray_triangle_backface_normal_flips" {
    const ray = Ray.init(.{ 0.25, 0.25, 5 }, .{ 0, 0, -1 });
    const tri = Triangle.init(.{ 0, 0, 0 }, .{ 1, 0, 0 }, .{ 0, 1, 0 });
    const hit = ray.raycast(tri).?;
    try std.testing.expectApproxEqAbs(@as(f32, 5.0), hit.distance, epsilon);
    try std.testing.expect(hit.normal[2] > 0);
}

test "ray_obb_hit" {
    const ray = Ray.init(.{ 0, 0, -5 }, .{ 0, 0, 1 });
    const obb = OBB.init(.{ 0, 0, 0 }, .{ .{ 1, 0, 0 }, .{ 0, 1, 0 }, .{ 0, 0, 1 } }, .{ 1, 1, 1 });
    const hit = ray.raycast(obb).?;
    try std.testing.expectApproxEqAbs(@as(f32, 4.0), hit.distance, epsilon);
}

test "ray_obb_rotated_hit" {
    const ray = Ray.init(.{ -5, 0, 0 }, .{ 1, 0, 0 });
    const s = @as(f32, 0.70710677);
    const axes = .{ .{ s, 0, -s }, .{ 0, 1, 0 }, .{ s, 0, s } };
    const obb = OBB.init(.{ 0, 0, 0 }, axes, .{ 1, 1, 1 });
    const hit = ray.raycast(obb).?;
    try std.testing.expect(hit.distance > 3.0);
    try std.testing.expect(hit.distance < 5.0);
}

test "aabb_aabb_intersect" {
    const a = AABB.init(.{ -1, -1, -1 }, .{ 1, 1, 1 });
    const b = AABB.init(.{ 0, 0, 0 }, .{ 2, 2, 2 });
    const c = AABB.init(.{ 5, 5, 5 }, .{ 6, 6, 6 });
    try std.testing.expect(a.intersect(b));
    try std.testing.expect(!a.intersect(c));
}

test "aabb_center_half_extents" {
    const aabb = AABB.init(.{ -2, 0, 2 }, .{ 2, 4, 6 });
    try expectVecApprox(aabb.center(), .{ 0, 2, 4 }, epsilon);
    try expectVecApprox(aabb.halfExtents(), .{ 2, 2, 2 }, epsilon);
}

test "aabb_contains_point_edges" {
    const aabb = AABB.init(.{ -1, -1, -1 }, .{ 1, 1, 1 });
    try std.testing.expect(aabb.containsPoint(.{ -1, 0, 1 }));
    try std.testing.expect(!aabb.containsPoint(.{ 1.1, 0, 0 }));
}

test "aabb_sphere_intersect" {
    const aabb = AABB.init(.{ -1, -1, -1 }, .{ 1, 1, 1 });
    const s1 = Sphere.init(.{ 1.5, 0, 0 }, 1.0);
    const s2 = Sphere.init(.{ 5, 0, 0 }, 1.0);
    try std.testing.expect(aabb.intersect(s1));
    try std.testing.expect(!aabb.intersect(s2));
}

test "sphere_sphere_intersect" {
    const a = Sphere.init(.{ 0, 0, 0 }, 1.0);
    const b = Sphere.init(.{ 1.5, 0, 0 }, 1.0);
    const c = Sphere.init(.{ 5, 0, 0 }, 1.0);
    try std.testing.expect(a.intersect(b));
    try std.testing.expect(!a.intersect(c));
}

test "plane_sphere_intersect" {
    const plane = Plane.init(.{ 0, 0, 0 }, .{ 0, 1, 0 });
    const s1 = Sphere.init(.{ 0, 0.5, 0 }, 1.0);
    const s2 = Sphere.init(.{ 0, 5, 0 }, 1.0);
    try std.testing.expect(plane.intersect(s1));
    try std.testing.expect(!plane.intersect(s2));
}

test "plane_distance_and_project" {
    const plane = Plane.init(.{ 0, 0, 0 }, .{ 0, 1, 0 });
    try std.testing.expectApproxEqAbs(@as(f32, 3.0), plane.distanceToPoint(.{ 0, 3, 0 }), epsilon);
    try expectVecApprox(plane.projectPoint(.{ 1, 3, -2 }), .{ 1, 0, -2 }, epsilon);
}

test "triangle_normal_and_area" {
    const tri = Triangle.init(.{ 0, 0, 0 }, .{ 1, 0, 0 }, .{ 0, 1, 0 });
    const n = tri.normal();
    try std.testing.expectApproxEqAbs(@as(f32, 0.0), n[0], epsilon);
    try std.testing.expectApproxEqAbs(@as(f32, 0.0), n[1], epsilon);
    try std.testing.expectApproxEqAbs(@as(f32, 1.0), n[2], epsilon);
    try std.testing.expectApproxEqAbs(@as(f32, 0.5), tri.area(), epsilon);
}

test "triangle_closest_point_regions" {
    const tri = Triangle.init(.{ 0, 0, 0 }, .{ 2, 0, 0 }, .{ 0, 2, 0 });
    try expectVecApprox(tri.closestPoint(.{ -1, -1, 0 }), .{ 0, 0, 0 }, epsilon);
    try expectVecApprox(tri.closestPoint(.{ 3, 0, 0 }), .{ 2, 0, 0 }, epsilon);
    try expectVecApprox(tri.closestPoint(.{ 0, 3, 0 }), .{ 0, 2, 0 }, epsilon);
    try expectVecApprox(tri.closestPoint(.{ 1, 1, 1 }), .{ 1, 1, 0 }, epsilon);
}

test "obb_contains_point" {
    const obb = OBB.init(.{ 0, 0, 0 }, .{ .{ 1, 0, 0 }, .{ 0, 1, 0 }, .{ 0, 0, 1 } }, .{ 1, 1, 1 });
    try std.testing.expect(obb.containsPoint(.{ 0.5, 0.5, 0.5 }));
    try std.testing.expect(!obb.containsPoint(.{ 2, 0, 0 }));
}

test "obb_closest_point" {
    const obb = OBB.init(.{ 0, 0, 0 }, .{ .{ 1, 0, 0 }, .{ 0, 1, 0 }, .{ 0, 0, 1 } }, .{ 1, 2, 3 });
    try expectVecApprox(obb.closestPoint(.{ 5, 1, -10 }), .{ 1, 1, -3 }, epsilon);
}

test "obb_obb_intersect" {
    const a = OBB.init(.{ 0, 0, 0 }, .{ .{ 1, 0, 0 }, .{ 0, 1, 0 }, .{ 0, 0, 1 } }, .{ 1, 1, 1 });
    const b = OBB.init(.{ 1.5, 0, 0 }, .{ .{ 1, 0, 0 }, .{ 0, 1, 0 }, .{ 0, 0, 1 } }, .{ 1, 1, 1 });
    const c = OBB.init(.{ 5, 0, 0 }, .{ .{ 1, 0, 0 }, .{ 0, 1, 0 }, .{ 0, 0, 1 } }, .{ 1, 1, 1 });
    try std.testing.expect(a.intersect(b));
    try std.testing.expect(!a.intersect(c));
}

test "obb_plane_intersect" {
    const obb = OBB.init(.{ 0, 0.25, 0 }, .{ .{ 1, 0, 0 }, .{ 0, 1, 0 }, .{ 0, 0, 1 } }, .{ 1, 0.5, 1 });
    const plane = Plane.init(.{ 0, 0, 0 }, .{ 0, 1, 0 });
    try std.testing.expect(obb.intersect(plane));
}

test "aabb_triangle_intersect" {
    const aabb = AABB.init(.{ -1, -1, -1 }, .{ 1, 1, 1 });
    const t1 = Triangle.init(.{ 0, 0, 0 }, .{ 2, 0, 0 }, .{ 0, 2, 0 });
    const t2 = Triangle.init(.{ 5, 5, 5 }, .{ 6, 5, 5 }, .{ 5, 6, 5 });
    try std.testing.expect(aabb.intersect(t1));
    try std.testing.expect(!aabb.intersect(t2));
}

test "triangle_triangle_separated" {
    const a = Triangle.init(.{ 0, 0, 0 }, .{ 1, 0, 0 }, .{ 0, 1, 0 });
    const b = Triangle.init(.{ 0, 0, 5 }, .{ 1, 0, 5 }, .{ 0, 1, 5 });
    try std.testing.expect(!a.intersect(b));
}
