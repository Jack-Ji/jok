//! 3D particle system for visual effects.
//!
//! This module provides a particle effect system for creating dynamic
//! visual effects like fire, smoke, explosions, magic spells, etc.
//!
//! Features:
//! - Particle emission with configurable rates
//! - Lifetime management
//! - Velocity and acceleration
//! - Color and size animation over lifetime
//! - Multiple concurrent effects
//! - Signal-based event system (begin/end notifications)
//!
//! The system uses an object pool for efficient particle allocation.

const std = @import("std");
const assert = std.debug.assert;
const Vector = @import("Vector.zig");
const TriangleRenderer = @import("TriangleRenderer.zig");
const Camera = @import("Camera.zig");
const jok = @import("../jok.zig");
const j3d = jok.j3d;
const j2d = jok.j2d;
const zmesh = jok.vendor.zmesh;
const zmath = jok.vendor.zmath;
const signal = jok.utils.signal;
const Self = @This();

const EffectPool = std.heap.MemoryPool(Effect);
const SearchMap = std.StringHashMap(*Effect);
const default_effects_capacity = 10;

// Memory allocator
allocator: std.mem.Allocator,

// Default random generator
rng: std.Random.DefaultPrng,

// Effect pool, for fast allocation
pool: EffectPool,

// Particle effects
effects: std.DoublyLinkedList,

// Hashmap for searching effects
search_tree: SearchMap,

// Signal begin/end of effect
sig_begin: *signal.Signal(&.{[]const u8}),
sig_end: *signal.Signal(&.{[]const u8}),

/// Create particle effect system/manager
pub fn create(allocator: std.mem.Allocator) !*Self {
    const self = try allocator.create(Self);
    errdefer allocator.destroy(self);
    self.* = .{
        .allocator = allocator,
        .rng = .init(@intCast(jok.vendor.sdl.SDL_GetTicksNS())),
        .pool = .empty,
        .effects = .{},
        .search_tree = SearchMap.init(allocator),
        .sig_begin = try signal.Signal(&.{[]const u8}).create(allocator),
        .sig_end = try signal.Signal(&.{[]const u8}).create(allocator),
    };
    return self;
}

/// Destroy particle effect system/manager
pub fn destroy(self: *Self) void {
    self.sig_begin.destroy();
    self.sig_end.destroy();
    self.search_tree.deinit();
    var node = self.effects.first;
    while (node) |n| {
        var e: *Effect = @alignCast(@fieldParentPtr("node", n));
        node = n.next;
        e.deinit(self.allocator);
    }
    self.pool.deinit(self.allocator);
    self.allocator.destroy(self);
}

/// Update system
pub fn update(self: *Self, delta_time: f32) void {
    var node = self.effects.first;
    while (node) |n| {
        var e: *Effect = @alignCast(@fieldParentPtr("node", n));
        node = n.next;
        e.update(delta_time);
        if (e.isOver()) self.remove(e);
    }
}

/// Clear all effects
pub fn clear(self: *Self) void {
    var node = self.effects.first;
    while (node) |n| {
        const e: *Effect = @alignCast(@fieldParentPtr("node", n));
        node = n.next;
        e.deinit(self.allocator);
    }
    _ = self.pool.reset(self.allocator, .retain_capacity);
    self.effects = .{};
    self.search_tree.clearRetainingCapacity();
}

/// Add effect
pub const AddEffect = struct {
    random: ?std.Random = null,
    origin: Vector = .zero,
    max_particle_num: u32 = 1000,
    effect_duration: ?f32 = null,
    gen_amount: u32 = 20,
    burst_freq: f32 = 0.1,
    depth: f32 = 0.5,
    overwrite: bool = false,
};
pub fn add(self: *Self, name: []const u8, emitter: ParticleEmitter, opt: AddEffect) !*Effect {
    assert(name.len > 0);
    if (std.mem.eql(u8, name, "_")) {
        return error.InvalidName;
    }
    if (self.search_tree.contains(name)) {
        if (opt.overwrite) {
            self.remove(self.search_tree.get(name).?);
        } else return error.NameUsed;
    }

    const effect = try self.pool.create(self.allocator);
    errdefer self.pool.destroy(effect);

    const dname = try self.allocator.dupe(u8, name);
    errdefer self.allocator.free(dname);

    effect.* = .{
        .system = self,
        .name = dname,
        .random = opt.random orelse self.rng.random(),
        .particles = try std.ArrayList(Particle)
            .initCapacity(self.allocator, opt.max_particle_num),
        .emitter = emitter,
        .origin = opt.origin,
        .effect_duration = opt.effect_duration,
        .gen_amount = opt.gen_amount,
        .burst_freq = opt.burst_freq,
        .burst_countdown = 0,
    };
    errdefer effect.particles.deinit(self.allocator);

    self.effects.append(&effect.node);
    self.search_tree.putNoClobber(effect.name, effect) catch |err| {
        self.effects.remove(&effect.node);
        return err;
    };

    self.sig_begin.emit(.{effect.name});
    return effect;
}

pub fn get(self: *Self, name: []const u8) ?*Effect {
    return self.search_tree.get(name);
}

pub fn remove(self: *Self, e: *Effect) void {
    assert(e.system == self);
    if (self.search_tree.remove(e.name)) {
        self.sig_end.emit(.{e.name});
        self.effects.remove(&e.node);
        e.deinit(self.allocator);
        self.pool.destroy(e);
        e.name = "_"; // Deliberately set name to special str, which will be detected as dead effect
    }
}

/// Represent a particle effect
pub const Effect = struct {
    /// Link node in system
    node: std.DoublyLinkedList.Node = .{},

    // Point back to system
    system: *Self,

    /// Name of effect (unique in system)
    name: []const u8,

    /// Random number generator
    random: std.Random,

    /// All particles
    particles: std.ArrayList(Particle),

    /// Particle emitter
    emitter: ParticleEmitter,

    /// Origin of particle
    origin: Vector,

    /// Effect duration
    effect_duration: ?f32,

    /// New particle amount per burst
    gen_amount: u32,

    /// Burst frequency
    burst_freq: f32,

    /// Burst countdown
    burst_countdown: f32,

    fn deinit(self: *Effect, allocator: std.mem.Allocator) void {
        allocator.free(self.name);
        self.particles.deinit(allocator);
    }

    /// Update effect
    fn update(self: *Effect, delta_time: f32) void {
        if (self.effect_duration == null or self.effect_duration.? > 0) {
            if (self.effect_duration != null) self.effect_duration.? -= delta_time;
            self.burst_countdown -= delta_time;
            if ((self.effect_duration == null or self.effect_duration.? >= 0) and
                self.burst_countdown <= 0 and
                self.particles.items.len < self.particles.capacity)
            {
                var i: u32 = 0;
                while (i < self.gen_amount) : (i += 1) {
                    // Generate new particle
                    self.particles.appendAssumeCapacity(
                        self.emitter.emit(self.random, self.origin),
                    );
                    if (self.particles.items.len == self.particles.capacity) break;
                }
            }
            if (self.burst_countdown <= 0) {
                self.burst_countdown = self.burst_freq;
            }
        }

        // Update each particles' status
        var i: usize = 0;
        while (i < self.particles.items.len) {
            var p = &self.particles.items[i];
            p.update(delta_time);
            if (p.isDead()) {
                _ = self.particles.swapRemove(i);
            } else {
                i += 1;
            }
        }
    }

    /// Render to output
    pub fn render(
        self: *const Effect,
        csz: jok.Size,
        batch: *j3d.Batch,
        camera: Camera,
        tri_rd: *TriangleRenderer,
    ) !void {
        if (std.mem.eql(u8, self.name, "_")) {
            // Warning: this is only best effort to avoid dead effect,
            // it's best to always use `ParticleSystem.get` to get effect!!!
            return;
        }
        for (self.particles.items) |p| {
            try p.render(csz, batch, camera, tri_rd);
        }
    }

    /// If effect is over
    pub fn isOver(self: *const Effect) bool {
        return std.mem.eql(u8, self.name, "_") or
            (self.effect_duration != null and self.effect_duration.? <= 0 and self.particles.items.len == 0);
    }
};

pub const DrawData = union(enum) {
    mesh: struct {
        shape: zmesh.Shape,
        scale: [3]f32 = .{ 1, 1, 1 },
        aabb: ?[6]f32 = null,
        texture: ?jok.Texture = null,
    },
    sprite: struct {
        size: jok.Point,
        uv: [2]jok.Point = .{ .origin, .unit },
        texture: ?jok.Texture = null,
    },

    pub fn fromSprite(sp: j2d.Sprite, scale: ?jok.Point) DrawData {
        return .{
            .sprite = .{
                .size = .{
                    .x = if (scale) |s| sp.width * s.x else sp.width,
                    .y = if (scale) |s| sp.height * s.y else sp.height,
                },
                .uv = .{ sp.uv0, sp.uv1 },
                .texture = sp.tex,
            },
        };
    }
};

/// Represent a particle
pub const Particle = struct {
    draw_data: DrawData,

    /// Life of particle
    age: f32,

    /// Position changing
    pos: Vector,
    move_speed: Vector,
    move_acceleration: Vector,
    move_damp: f32,

    /// Rotation changing
    angle: f32 = 0,
    rotation_speed: f32 = 0,
    rotation_damp: f32 = 1,
    rotation_axis: Vector = Vector.set(1),

    /// Scale changing
    scale: f32 = 1,
    scale_speed: f32 = 0,
    scale_acceleration: f32 = 0,
    scale_max: f32 = 1,

    /// Color changing
    color: jok.ColorF = undefined,
    color_initial: jok.ColorF = .white,
    color_final: jok.ColorF = .white,
    color_fade_age: f32 = 0,

    inline fn updatePos(self: *Particle, delta_time: f32) void {
        assert(self.move_damp >= 0 and self.move_damp <= 1);
        self.move_speed = self.move_speed.scale(self.move_damp);
        self.move_speed = self.move_speed.add(self.move_acceleration.scale(delta_time));
        self.pos = self.pos.add(self.move_speed.scale(delta_time));
    }

    inline fn updateRotation(self: *Particle, delta_time: f32) void {
        assert(self.rotation_damp >= 0 and self.rotation_damp <= 1);
        self.rotation_speed *= self.rotation_damp;
        self.angle += self.rotation_speed * delta_time;
    }

    inline fn updateScale(self: *Particle, delta_time: f32) void {
        assert(self.scale_max > 0);
        self.scale_speed += self.scale_acceleration * delta_time;
        self.scale += self.scale_speed * delta_time;
        self.scale = std.math.clamp(self.scale, 0.0, self.scale_max);
    }

    inline fn updateColor(self: *Particle) void {
        if (self.age >= self.color_fade_age) {
            self.color = self.color_initial;
        } else {
            assert(self.color_fade_age > 0);
            const t = @max(self.age, 0.0) / self.color_fade_age;
            self.color = self.color_initial.lerp(self.color_final, t);
        }
    }

    /// If particle is dead
    inline fn isDead(self: Particle) bool {
        return self.age <= 0;
    }

    /// Update particle's status
    inline fn update(self: *Particle, delta_time: f32) void {
        if (self.age <= 0) return;
        self.age -= delta_time;
        self.updatePos(delta_time);
        self.updateRotation(delta_time);
        self.updateScale(delta_time);
        self.updateColor();
    }

    /// Render to output
    inline fn render(
        self: Particle,
        csz: jok.Size,
        batch: *j3d.Batch,
        camera: Camera,
        tri_rd: *TriangleRenderer,
    ) !void {
        switch (self.draw_data) {
            .mesh => |d| {
                const model = zmath.mul(
                    zmath.mul(
                        zmath.scaling(
                            d.scale[0] * self.scale,
                            d.scale[1] * self.scale,
                            d.scale[2] * self.scale,
                        ),
                        zmath.matFromAxisAngle(
                            zmath.f32x4(
                                self.rotation_axis.x(),
                                self.rotation_axis.y(),
                                self.rotation_axis.z(),
                                0,
                            ),
                            self.angle,
                        ),
                    ),
                    zmath.translation(
                        self.pos.x(),
                        self.pos.y(),
                        self.pos.z(),
                    ),
                );
                try tri_rd.renderMesh(
                    csz,
                    batch,
                    zmath.mul(model, batch.trs),
                    camera,
                    d.shape.indices,
                    d.shape.positions,
                    d.shape.normals.?,
                    null,
                    d.shape.texcoords,
                    .{
                        .aabb = d.aabb,
                        .color = self.color,
                        .texture = d.texture,
                    },
                );
            },
            .sprite => |d| {
                const model = zmath.translation(
                    self.pos.x(),
                    self.pos.y(),
                    self.pos.z(),
                );
                try tri_rd.renderSprite(
                    csz,
                    batch,
                    zmath.mul(model, batch.trs),
                    camera,
                    d.size,
                    d.uv,
                    .{
                        .texture = d.texture,
                        .tint_color = self.color,
                        .scale = .{ .x = self.scale, .y = self.scale },
                        .rotate_angle = self.angle,
                        .anchor_point = .{ .x = 0.5, .y = 0.5 },
                    },
                );
            },
        }
    }
};

/// Interface for particle emitters
pub const ParticleEmitter = struct {
    ptr: *anyopaque,
    vtable: *const VTable,

    const VTable = struct {
        emit: *const fn (ctx: *anyopaque, random: std.Random, origin: Vector) Particle,
    };

    fn emit(pe: ParticleEmitter, random: std.Random, origin: Vector) Particle {
        return pe.vtable.emit(pe.ptr, random, origin);
    }
};

/////////////////////////// Builtin Particle Emitters ///////////////////////////

/// Fire Emitter
pub const FireEmitter = struct {
    draw_data: DrawData,
    radius: f32 = 20,
    acceleration: f32 = 50,
    age: f32 = 3,
    color_initial: jok.ColorF = .red,
    color_final: jok.ColorF = .yellow,
    color_fade_age: f32 = 2,

    pub fn emitter(self: *FireEmitter) ParticleEmitter {
        return .{
            .ptr = @ptrCast(self),
            .vtable = &.{ .emit = emit },
        };
    }

    fn emit(ptr: *anyopaque, random: std.Random, origin: Vector) Particle {
        const self: *FireEmitter = @ptrCast(@alignCast(ptr));
        const offset = Vector.new(
            random.float(f32) * self.radius * @cos(random.float(f32) * std.math.tau) * @cos(random.float(f32) * std.math.tau),
            random.float(f32) * self.radius * @sin(random.float(f32) * std.math.tau),
            random.float(f32) * self.radius * @cos(random.float(f32) * std.math.tau) * @sin(random.float(f32) * std.math.tau),
        );

        assert(self.color_fade_age <= self.age);
        return Particle{
            .draw_data = self.draw_data,
            .age = self.age,
            .pos = origin.add(offset),
            .move_speed = Vector.new(-offset.x() * 0.5, 0, -offset.z() * 0.5),
            .move_acceleration = Vector.new(0, random.float(f32) * self.acceleration, 0),
            .move_damp = 0.96,
            .scale = 0.5,
            .scale_speed = -0.1,
            .scale_acceleration = 0.0,
            .scale_max = 1.0,
            .color_initial = self.color_initial,
            .color_final = self.color_final,
            .color_fade_age = self.color_fade_age,
        };
    }
};
