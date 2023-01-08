const std = @import("std");
const assert = std.debug.assert;
const sdl = @import("sdl");
const Sprite = @import("Sprite.zig");
const SpriteBatch = @import("SpriteBatch.zig");
const Self = @This();

pub const Error = error{
    NameUsed,
    NameNotExist,
};

// Memory allocator
allocator: std.mem.Allocator,

// Animations
animations: std.StringHashMap(Animation),

pub fn init(allocator: std.mem.Allocator) !*Self {
    var self = try allocator.create(Self);
    self.* = .{
        .allocator = allocator,
        .animations = std.StringHashMap(Animation).init(allocator),
    };
    return self;
}

/// Destroy animation system/manager
pub fn deinit(self: *Self) void {
    self.clear();
    self.animations.deinit();
    self.allocator.destroy(self);
}

/// Add animation
pub fn add(self: *Self, name: []const u8, anim: Animation) !void {
    if (self.animations.get(name) != null) {
        return error.NameUsed;
    }
    const dname = try self.allocator.dupe(u8, name);
    try self.animations.put(dname, anim);
}

/// Remove animation
pub fn remove(self: *Self, name: []const u8) void {
    if (self.animations.getEntry(name)) |entry| {
        self.allocator.free(entry.key_ptr.*);
        entry.value_ptr.deinit();
        _ = self.animations.remove(name);
    }
}

/// Clear all animations
pub fn clear(self: *Self) void {
    var it = self.animations.iterator();
    while (it.next()) |entry| {
        self.allocator.free(entry.key_ptr.*);
        entry.value_ptr.deinit();
    }
}

/// Update animations
pub fn update(self: *Self, delta_tick: f32) void {
    var it = self.animations.iterator();
    while (it.next()) |entry| {
        var anim = entry.value_ptr;
        if (anim.is_over) {
            continue;
        }
        anim.update(delta_tick);
    }
}

/// Get animation's current frame
pub fn getCurrentFrame(self: Self, name: []const u8) !Sprite {
    if (self.animations.get(name)) |anim| {
        return anim.frames.items[anim.play_index];
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

/// Represent an animation
pub const Animation = struct {
    frames: std.ArrayList(Sprite),
    frame_interval: f32,
    loop: bool,
    play_index: u32,
    passed_time: f32,
    is_over: bool,

    pub fn init(allocator: std.mem.Allocator, sprites: []const Sprite, fps: f32, loop: bool) !Animation {
        assert(sprites.len > 0);
        assert(fps > 0);
        var frames = try std.ArrayList(Sprite).initCapacity(allocator, sprites.len);
        frames.appendSliceAssumeCapacity(sprites);
        return Animation{
            .frames = frames,
            .frame_interval = 1.0 / fps,
            .loop = loop,
            .play_index = 0,
            .passed_time = 0,
            .is_over = false,
        };
    }

    pub fn deinit(anim: Animation) void {
        anim.frames.deinit();
    }

    pub fn reset(anim: *Animation) void {
        anim.is_over = false;
        anim.play_index = 0;
    }

    pub fn update(anim: *Animation, delta_tick: f32) void {
        if (anim.is_over) return;
        anim.passed_time += delta_tick;
        while (anim.passed_time > anim.frame_interval) : (anim.passed_time -= anim.frame_interval) {
            anim.play_index += 1;
            if (anim.play_index >= @intCast(u32, anim.frames.items.len)) {
                if (anim.loop) {
                    anim.play_index = 0;
                } else {
                    anim.play_index = @intCast(u32, anim.frames.items.len) - 1;
                    anim.is_over = true;
                }
            }
        }
    }
};
