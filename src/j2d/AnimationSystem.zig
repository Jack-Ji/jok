//! Generic sprite animation system.
//!
//! Manages named animations with per-frame durations, looping, reversing,
//! wait delays, play ranges, and signal-based notifications for begin/end/step events.

const std = @import("std");
const assert = std.debug.assert;
const jok = @import("../jok.zig");
const internal = @import("internal.zig");
const Sprite = @import("Sprite.zig");

/// Animation system errors.
pub const Error = error{
    NameUsed,
    NameNotExist,
};

/// Create an animation system parameterized on the frame data type.
pub fn AnimationSystem(comptime FrameDataType: type) type {
    return struct {
        const Self = @This();

        /// A single animation frame: data payload and display duration.
        pub const Frame = struct {
            data: FrameDataType,
            duration: f32,
        };

        /// Emits when animation starts
        const AnimBeginSignal = jok.utils.signal.Signal(&.{
            []const u8, // Name of animation
        });

        /// Emits when animation is over (looping animations never end)
        const AnimEndSignal = jok.utils.signal.Signal(&.{
            []const u8, // Name of animation
        });

        /// Emits every time an animation advances to a new frame.
        /// WARNING: This can fire frequently (10+ times/sec per animation).
        /// Only connect listeners that do minimal work. For expensive operations,
        /// use begin/end signals or poll getCurrentFrame() as needed.
        const FrameSteppingSignal = jok.utils.signal.Signal(&.{
            []const u8, // Name of animation
            u32, // Index of frame
        });

        // Memory allocator
        allocator: std.mem.Allocator,

        // Animations
        animations: std.StringHashMap(Animation),
        deleting: std.StringHashMap(void),

        // Notify animation's status change
        sig_begin: *AnimBeginSignal,
        sig_end: *AnimEndSignal,
        sig_stepping: *FrameSteppingSignal,

        /// Create the animation system.
        pub fn create(allocator: std.mem.Allocator) !*Self {
            const self = try allocator.create(Self);
            self.* = .{
                .allocator = allocator,
                .animations = .init(allocator),
                .deleting = .init(allocator),
                .sig_begin = try AnimBeginSignal.create(allocator),
                .sig_end = try AnimEndSignal.create(allocator),
                .sig_stepping = try FrameSteppingSignal.create(allocator),
            };
            return self;
        }

        /// Destroy animation system
        pub fn destroy(self: *Self) void {
            self.clear();
            self.update(0);
            self.animations.deinit();
            self.deleting.deinit();
            self.sig_begin.destroy();
            self.sig_end.destroy();
            self.sig_stepping.destroy();
            self.allocator.destroy(self);
        }

        /// Options for adding an animation.
        pub const AnimOption = struct {
            wait_time: f32 = 0,
            loop: bool = false,
            reverse: bool = false,
        };

        /// Add animation, each frame has its own duration
        pub fn add(
            self: *Self,
            name: []const u8,
            frames: []const Frame,
            opt: AnimOption,
        ) !void {
            assert(name.len > 0);
            assert(frames.len > 0);
            if (self.animations.getPtr(name)) |anim| {
                if (!self.deleting.contains(name)) {
                    return error.NameUsed;
                }
                _ = self.deleting.remove(name);
                anim.deinit(self.allocator);
            }
            const dname = try self.allocator.dupe(u8, name);
            errdefer self.allocator.free(dname);
            const anim = Animation{
                .name = dname,
                .frames = try self.allocator.alloc(Frame, frames.len),
                .sig_begin = self.sig_begin,
                .sig_end = self.sig_end,
                .sig_stepping = self.sig_stepping,
                .wait_time = opt.wait_time,
                .loop = opt.loop,
                .reverse = opt.reverse,
                .range_begin = 0,
                .range_end = @intCast(frames.len - 1),
                .play_index = null,
                .passed_time = 0,
                .is_over = false,
                .is_stopped = false,
            };
            errdefer anim.deinit(self.allocator);
            @memcpy(anim.frames, frames);
            try self.animations.put(anim.name, anim);
        }

        /// Add simple animation with fixed duration
        pub fn addSimple(
            self: *Self,
            name: []const u8,
            frames: []const FrameDataType,
            fps: f32,
            opt: AnimOption,
        ) !void {
            assert(name.len > 0);
            assert(frames.len > 0);
            assert(fps > 0);
            if (self.animations.getPtr(name)) |anim| {
                if (!self.deleting.contains(name)) {
                    return error.NameUsed;
                }
                _ = self.deleting.remove(name);
                anim.deinit(self.allocator);
            }
            const dname = try self.allocator.dupe(u8, name);
            errdefer self.allocator.free(dname);
            const anim = Animation{
                .name = dname,
                .frames = try self.allocator.alloc(Frame, frames.len),
                .sig_begin = self.sig_begin,
                .sig_end = self.sig_end,
                .sig_stepping = self.sig_stepping,
                .wait_time = opt.wait_time,
                .loop = opt.loop,
                .reverse = opt.reverse,
                .range_begin = 0,
                .range_end = @intCast(frames.len - 1),
                .play_index = null,
                .passed_time = 0,
                .is_over = false,
                .is_stopped = false,
            };
            errdefer anim.deinit(self.allocator);
            const duration = 1.0 / fps;
            for (anim.frames, 0..) |*f, i| {
                f.data = frames[i];
                f.duration = duration;
            }
            try self.animations.put(anim.name, anim);
        }

        /// Remove animation
        pub fn remove(self: *Self, name: []const u8) void {
            if (self.animations.getPtr(name)) |anim| {
                self.deleting.put(anim.name, {}) catch @panic("OOM");
            }
        }

        /// Clear all animations
        pub fn clear(self: *Self) void {
            var it = self.animations.keyIterator();
            while (it.next()) |key_ptr| {
                self.deleting.put(key_ptr.*, {}) catch @panic("OOM");
            }
        }

        /// Update animations
        pub fn update(self: *Self, delta_tick: f32) void {
            defer self.deleting.clearRetainingCapacity();
            var dit = self.deleting.keyIterator();
            while (dit.next()) |key_ptr| {
                if (self.animations.fetchRemove(key_ptr.*)) |entry| {
                    entry.value.deinit(self.allocator);
                }
            }

            var it = self.animations.iterator();
            while (it.next()) |entry| {
                entry.value_ptr.update(delta_tick);
            }
        }

        /// Get animation's current frame
        pub fn getCurrentFrame(self: Self, name: []const u8) !FrameDataType {
            if (self.animations.get(name)) |anim| {
                return anim.getCurrentFrame();
            }
            return error.NameNotExist;
        }

        /// Get animation's frame count
        pub fn getFrameCount(self: Self, name: []const u8) !u32 {
            if (self.animations.get(name)) |anim| {
                return anim.range_end - anim.range_begin + 1;
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

        /// Get animation's stop state
        pub fn isStopped(self: Self, name: []const u8) !bool {
            if (self.animations.get(name)) |anim| {
                return anim.is_stopped;
            }
            return error.NameNotExist;
        }

        /// Get animation's wait state
        pub fn isWaiting(self: Self, name: []const u8) !bool {
            if (self.animations.get(name)) |anim| {
                return anim.wait_time > 0;
            }
            return error.NameNotExist;
        }

        /// Reset animation's status (clear over/stop state)
        pub fn reset(self: *Self, name: []const u8) !void {
            try self.resetWait(name, 0);
        }

        /// Reset animation's status (clear over/stop state), with wait time
        pub fn resetWait(self: *Self, name: []const u8, wait_time: f32) !void {
            if (self.animations.getPtr(name)) |anim| {
                return anim.reset(wait_time);
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

        /// Set animation's reverse state
        pub fn setReverse(self: *Self, name: []const u8, b: bool) !void {
            if (self.animations.getPtr(name)) |anim| {
                anim.reverse = b;
                return;
            }
            return error.NameNotExist;
        }

        /// Set the inclusive play range for an animation.
        pub fn setRange(self: *Self, name: []const u8, _begin: ?u32, _end: ?u32) !void {
            if (self.animations.getPtr(name)) |anim| {
                const begin = _begin orelse 0;
                const end = _end orelse @as(u32, @intCast(anim.frames.len - 1));
                assert(begin <= end and end <= @as(u32, @intCast(anim.frames.len - 1)));
                anim.range_begin = begin;
                anim.range_end = end;
                if (anim.play_index) |idx| {
                    if (idx < begin or idx > end) {
                        anim.play_index = if (anim.reverse) end else begin;
                    }
                }
                return;
            }
            return error.NameNotExist;
        }

        /// Represent an animation
        pub const Animation = struct {
            name: []u8,
            frames: []Frame,
            sig_begin: *AnimBeginSignal,
            sig_end: *AnimEndSignal,
            sig_stepping: *FrameSteppingSignal,
            wait_time: f32,
            loop: bool,
            reverse: bool,
            range_begin: u32,
            range_end: u32,
            play_index: ?u32,
            passed_time: f32,
            is_over: bool,
            is_stopped: bool,

            fn deinit(anim: Animation, allocator: std.mem.Allocator) void {
                allocator.free(anim.name);
                allocator.free(anim.frames);
            }

            /// Reset the animation to its initial state with an optional wait time.
            pub fn reset(anim: *Animation, wait_time: f32) void {
                anim.wait_time = wait_time;
                anim.play_index = null;
                anim.passed_time = 0;
                anim.is_over = false;
                anim.is_stopped = false;
            }

            /// Return the frame data for the current play position.
            pub fn getCurrentFrame(anim: Animation) FrameDataType {
                return anim.frames[anim.play_index orelse if (anim.reverse) anim.range_end else anim.range_begin].data;
            }

            inline fn update(anim: *Animation, delta_tick: f32) void {
                if (anim.is_over or anim.is_stopped) return;
                anim.passed_time += delta_tick;
                if (anim.passed_time < anim.wait_time) return;
                if (anim.wait_time > 0) {
                    anim.passed_time -= anim.wait_time;
                    anim.wait_time = 0; // only take effect once
                }
                if (anim.play_index == null) {
                    anim.play_index = if (anim.reverse) anim.range_end else anim.range_begin;
                    anim.sig_begin.emit(.{anim.name});
                    anim.sig_stepping.emit(.{ anim.name, anim.play_index.? });
                }
                while (anim.passed_time >= anim.frames[anim.play_index.?].duration) {
                    anim.passed_time -= anim.frames[anim.play_index.?].duration;
                    if (!anim.reverse and anim.play_index.? < anim.range_end) {
                        anim.play_index.? += 1;
                        anim.sig_stepping.emit(.{ anim.name, anim.play_index.? });
                        continue;
                    }
                    if (anim.reverse and anim.play_index.? > anim.range_begin) {
                        anim.play_index.? -= 1;
                        anim.sig_stepping.emit(.{ anim.name, anim.play_index.? });
                        continue;
                    }
                    if (anim.loop) {
                        anim.play_index = if (anim.reverse) anim.range_end else anim.range_begin;
                        anim.sig_stepping.emit(.{ anim.name, anim.play_index.? });
                    } else {
                        anim.is_over = true;
                        anim.sig_end.emit(.{anim.name});
                        break;
                    }
                }
            }
        };
    };
}
