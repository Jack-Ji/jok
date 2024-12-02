const std = @import("std");
const assert = std.debug.assert;
const jok = @import("../jok.zig");
const internal = @import("internal.zig");
const Sprite = @import("Sprite.zig");
const Self = @This();

pub const Error = error{
    NameUsed,
    NameNotExist,
};

const AnimationSignal = jok.utils.signal.Signal(&.{[]const u8});

// Memory allocator
allocator: std.mem.Allocator,

// Animations
animations: std.StringHashMap(Animation),

// Notify animation is over
sig: *AnimationSignal,

pub fn create(allocator: std.mem.Allocator) !*Self {
    const self = try allocator.create(Self);
    self.* = .{
        .allocator = allocator,
        .animations = std.StringHashMap(Animation).init(allocator),
        .sig = try AnimationSignal.create(allocator),
    };
    return self;
}

/// Destroy animation system
pub fn destroy(self: *Self) void {
    self.clear();
    self.animations.deinit();
    self.sig.destroy();
    self.allocator.destroy(self);
}

/// Add animation, each frame has its own duration
pub fn add(
    self: *Self,
    name: []const u8,
    frames: []const Frame,
    loop: bool,
) !void {
    assert(name.len > 0);
    assert(frames.len > 0);
    if (self.animations.get(name) != null) {
        return error.NameUsed;
    }
    const dname = try self.allocator.dupe(u8, name);
    errdefer self.allocator.free(dname);
    const anim = Animation{
        .name = dname,
        .frames = try self.allocator.alloc(Frame, frames.len),
        .loop = loop,
        .play_index = 0,
        .passed_time = 0,
        .is_over = false,
        .is_stopped = false,
    };
    errdefer self.allocator.free(anim.frames);
    @memcpy(anim.frames, frames);
    try self.animations.put(dname, anim);
}

/// Add simple animation with fixed duration
pub fn addSimple(
    self: *Self,
    name: []const u8,
    frames: []const Frame.Data,
    fps: f32,
    loop: bool,
) !void {
    assert(name.len > 0);
    assert(frames.len > 0);
    assert(fps > 0);
    if (self.animations.get(name) != null) {
        return error.NameUsed;
    }
    const dname = try self.allocator.dupe(u8, name);
    errdefer self.allocator.free(dname);
    const anim = Animation{
        .name = dname,
        .frames = try self.allocator.alloc(Frame, frames.len),
        .loop = loop,
        .play_index = 0,
        .passed_time = 0,
        .is_over = false,
        .is_stopped = false,
    };
    errdefer self.allocator.free(anim.frames);
    const duration = 1.0 / fps;
    for (anim.frames, 0..) |*f, i| {
        f.data = frames[i];
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
        if (entry.value_ptr.is_over) {
            self.sig.emit(.{entry.key_ptr.*});
        }
    }
}

/// Get animation's current frame
pub fn getCurrentFrame(self: Self, name: []const u8) !Frame.Data {
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

/// Reset animation's status (clear over/stop state)
pub fn reset(self: *Self, name: []const u8) !void {
    if (self.animations.getPtr(name)) |anim| {
        return anim.reset();
    }
    return error.NameNotExist;
}

/// Set animation's stop state
pub fn setStop(self: *Self, name: []const u8, b: bool) !void {
    if (self.animations.getPtr(name)) |anim| {
        anim.is_stopped = b;
        return;
    }
    return error.NameNotExist;
}

/// Set animation's loop state
pub fn setLoop(self: *Self, name: []const u8, b: bool) !void {
    if (self.animations.getPtr(name)) |anim| {
        anim.loop = b;
        return;
    }
    return error.NameNotExist;
}

pub const Frame = struct {
    pub const Data = union(enum) {
        sp: Sprite,
        dcmd: internal.DrawCmd,
    };
    data: Data,
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
    is_stopped: bool,

    pub fn reset(anim: *Animation) void {
        anim.play_index = 0;
        anim.passed_time = 0;
        anim.is_over = false;
        anim.is_stopped = false;
    }

    pub fn getCurrentFrame(self: Animation) Frame.Data {
        return self.frames[self.play_index].data;
    }

    fn update(anim: *Animation, delta_tick: f32) void {
        if (anim.is_over or anim.is_stopped) return;
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
