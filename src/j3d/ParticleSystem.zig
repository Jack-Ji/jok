/// Particle system
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
const Self = @This();

const EffectPool = std.heap.MemoryPool(Effect);
const SearchMap = std.StringHashMap(*Effect);
const default_effects_capacity = 10;

// Memory allocator
allocator: std.mem.Allocator,

// Effect pool, for fast allocation
pool: EffectPool,

// Particle effects
effects: std.DoublyLinkedList,

// Hashmap for searching effects
search_tree: SearchMap,

/// Create particle effect system/manager
pub fn create(allocator: std.mem.Allocator) !*Self {
    const self = try allocator.create(Self);
    errdefer allocator.destroy(self);
    self.* = .{
        .allocator = allocator,
        .pool = .empty,
        .effects = .{},
        .search_tree = SearchMap.init(allocator),
    };
    return self;
}

/// Destroy particle effect system/manager
pub fn destroy(self: *Self) void {
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
pub fn add(
    self: *Self,
    name: []const u8,
    random: std.Random,
    max_particle_num: u32,
    emit_fn: Effect.ParticleEmitFn,
    origin: Vector,
    effect_duration: f32,
    gen_amount: u32,
    burst_freq: f32,
) !*Effect {
    assert(name.len > 0);
    if (self.search_tree.contains(name)) {
        return error.NameUsed;
    }
    const effect = try self.pool.create(self.allocator);
    const dname = try self.allocator.dupe(u8, name);
    errdefer self.allocator.free(dname);
    effect.* = .{
        .system = self,
        .name = dname,
        .random = random,
        .particles = try std.ArrayList(Particle)
            .initCapacity(self.allocator, max_particle_num),
        .emit_fn = emit_fn,
        .origin = origin,
        .effect_duration = effect_duration,
        .gen_amount = gen_amount,
        .burst_freq = burst_freq,
        .burst_countdown = burst_freq,
    };
    errdefer effect.deinit(self.allocator);
    self.effects.append(&effect.node);
    try self.search_tree.put(effect.name, effect);
    return effect;
}

pub fn get(self: *Self, name: []const u8) ?*Effect {
    return self.search_tree.get(name);
}

pub fn remove(self: *Self, e: *Effect) void {
    assert(e.system == self);
    if (self.search_tree.remove(e.name)) {
        self.effects.remove(&e.node);
        e.deinit(self.allocator);
        self.pool.destroy(e);
        e.name = ""; // Deliberately set name to null str, which will be detected as dead effect
    }
}

/// Represent a particle effect
pub const Effect = struct {
    pub const ParticleEmitFn = *const fn (
        random: std.Random,
        origin: Vector,
    ) Particle;

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
    emit_fn: ParticleEmitFn,

    /// Origin of particle
    origin: Vector,

    /// Effect duration
    effect_duration: f32,

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
        if (self.effect_duration > 0) {
            self.effect_duration -= delta_time;
            self.burst_countdown -= delta_time;
            if (self.effect_duration >= 0 and
                self.burst_countdown <= 0 and
                self.particles.items.len < self.particles.capacity)
            {
                var i: u32 = 0;
                while (i < self.gen_amount) : (i += 1) {
                    // Generate new particle
                    self.particles.appendAssumeCapacity(
                        self.emit_fn(self.random, self.origin),
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
        if (self.name.len == 0) {
            return; // Warning: Although we handled dead effect here, it's best to always use `ParticleSystem.get` to get effect!!!
        }
        for (self.particles.items) |p| {
            try p.render(csz, batch, camera, tri_rd);
        }
    }

    /// If effect is over
    pub fn isOver(self: *const Effect) bool {
        return self.effect_duration <= 0 and self.particles.items.len == 0;
    }

    /// Bulitin particle emitter: fire
    pub fn FireEmitter(
        comptime _radius: f32,
        comptime _acceleration: f32,
        comptime _age: f32,
        comptime _color_initial: jok.ColorF,
        comptime _color_final: jok.ColorF,
        comptime _color_fade_age: f32,
    ) type {
        return struct {
            pub var draw_data: ?DrawData = null;
            pub var radius = _radius;
            pub var acceleration = _acceleration;
            pub var age = _age;
            pub var color_initial = _color_initial;
            pub var color_final = _color_final;
            pub var color_fade_age = _color_fade_age;

            pub fn emit(random: std.Random, origin: Vector) Particle {
                const offset = Vector.new(
                    random.float(f32) * radius * @cos(random.float(f32) * std.math.tau) * @cos(random.float(f32) * std.math.tau),
                    random.float(f32) * radius * @sin(random.float(f32) * std.math.tau),
                    random.float(f32) * radius * @cos(random.float(f32) * std.math.tau) * @sin(random.float(f32) * std.math.tau),
                );

                assert(color_fade_age < age);
                return Particle{
                    .draw_data = draw_data.?,
                    .age = age,
                    .pos = origin.add(offset),
                    .move_speed = Vector.new(-offset.x() * 0.5, 0, -offset.z() * 0.5),
                    .move_acceleration = Vector.new(0, random.float(f32) * acceleration, 0),
                    .move_damp = 0.96,
                    .scale = 0.5,
                    .scale_speed = -0.1,
                    .scale_acceleration = 0.0,
                    .scale_max = 1.0,
                    .color_initial = color_initial,
                    .color_final = color_final,
                    .color_fade_age = color_fade_age,
                };
            }
        };
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
                    model,
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
                try tri_rd.renderSprite(
                    csz,
                    batch,
                    zmath.translation(
                        self.pos.x(),
                        self.pos.y(),
                        self.pos.z(),
                    ),
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
