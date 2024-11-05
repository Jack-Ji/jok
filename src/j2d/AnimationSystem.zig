const std = @import("std");
const assert = std.debug.assert;
const jok = @import("../jok.zig");
const Sprite = @import("Sprite.zig");
const Self = @This();

pub const Error = error{
    NameUsed,
    NameNotExist,
};

// Memory allocator
allocator: std.mem.Allocator,

// Animations
animations: std.StringHashMap(Animation),

pub fn create(allocator: std.mem.Allocator) !*Self {
    const self = try allocator.create(Self);
    self.* = .{
        .allocator = allocator,
        .animations = std.StringHashMap(Animation).init(allocator),
    };
    return self;
}

/// Destroy animation system
pub fn destroy(self: *Self) void {
    self.clear();
    self.animations.deinit();
    self.allocator.destroy(self);
}

/// Add animation, each frame has its own duration
pub fn add(
    self: *Self,
    name: []const u8,
    sprites: []const Sprite,
    durations: []const f32,
    loop: bool,
) !void {
    assert(name.len > 0);
    assert(sprites.len > 0);
    assert(sprites.len == durations.len);
    if (self.animations.get(name) != null) {
        return error.NameUsed;
    }
    const dname = try self.allocator.dupe(u8, name);
    errdefer self.allocator.free(dname);
    const anim = Animation{
        .name = dname,
        .frames = try self.allocator.alloc(Frame, sprites.len),
        .loop = loop,
        .play_index = 0,
        .passed_time = 0,
        .is_over = false,
    };
    errdefer self.allocator.free(anim.frames);
    for (anim.frames, 0..) |*f, i| {
        f.sp = sprites[i];
        f.duration = durations[i];
    }
    try self.animations.put(dname, anim);
}

/// Add simple animation with fixed duration
pub fn addSimple(
    self: *Self,
    name: []const u8,
    sprites: []const Sprite,
    fps: f32,
    loop: bool,
) !void {
    assert(name.len > 0);
    assert(sprites.len > 0);
    assert(fps > 0);
    if (self.animations.get(name) != null) {
        return error.NameUsed;
    }
    const dname = try self.allocator.dupe(u8, name);
    errdefer self.allocator.free(dname);
    const anim = Animation{
        .name = dname,
        .frames = try self.allocator.alloc(Frame, sprites.len),
        .loop = loop,
        .play_index = 0,
        .passed_time = 0,
        .is_over = false,
    };
    errdefer self.allocator.free(anim.frames);
    const duration = 1.0 / fps;
    for (anim.frames, 0..) |*f, i| {
        f.sp = sprites[i];
        f.duration = duration;
    }
    try self.animations.put(dname, anim);
}

/// Remove animation
pub fn remove(self: *Self, name: []const u8) !void {
    if (self.animations.getEntry(name)) |entry| {
        self.allocator.free(entry.value_ptr.name);
        self.allocator.free(entry.value_ptr.frames);
        self.animations.removeByPtr(entry.key_ptr);
    } else {
        return error.NameNotExist;
    }
}

/// Clear all animations
pub fn clear(self: *Self) void {
    var it = self.animations.iterator();
    while (it.next()) |entry| {
        self.allocator.free(entry.value_ptr.name);
        self.allocator.free(entry.value_ptr.frames);
    }
    self.animations.clearRetainingCapacity();
}

/// Update animations
pub fn update(self: *Self, delta_tick: f32) void {
    var it = self.animations.iterator();
    while (it.next()) |entry| {
        if (entry.value_ptr.is_over) {
            continue;
        }
        entry.value_ptr.update(delta_tick);
    }
}

/// Get animation's current frame
pub fn getCurrentFrame(self: Self, name: []const u8) !Sprite {
    if (self.animations.get(name)) |anim| {
        return anim.getCurrentFrame();
    }
    return error.NameNotExist;
}

/// Get animation's status
pub fn isOver(self: Self, name: []const u8) !bool {
    if (self.animations.get(name)) |anim| {
        return anim.is_over;
    }
    return error.NameNotExist;
}

/// Reset animation's status
pub fn reset(self: *Self, name: []const u8) !void {
    if (self.animations.getPtr(name)) |anim| {
        return anim.reset();
    }
    return error.NameNotExist;
}

pub const Frame = struct {
    sp: Sprite,
    duration: f32,
};

/// Represent an animation
pub const Animation = struct {
    name: []u8,
    frames: []Frame,
    loop: bool,
    play_index: u32,
    passed_time: f32,
    is_over: bool,

    pub fn reset(anim: *Animation) void {
        anim.play_index = 0;
        anim.passed_time = 0;
        anim.is_over = false;
    }

    pub fn getCurrentFrame(self: Animation) Sprite {
        return self.frames[self.play_index].sp;
    }

    pub fn update(anim: *Animation, delta_tick: f32) void {
        if (anim.is_over) return;
        anim.passed_time += delta_tick;
        while (anim.passed_time >= anim.frames[anim.play_index].duration) {
            anim.passed_time -= anim.frames[anim.play_index].duration;
            anim.play_index += 1;
            if (anim.play_index >= @as(u32, @intCast(anim.frames.len))) {
                if (anim.loop) {
                    anim.play_index = 0;
                } else {
                    anim.play_index = @as(u32, @intCast(anim.frames.len)) - 1;
                    anim.is_over = true;
                    break;
                }
            }
        }
    }
};
