const std = @import("std");
const assert = std.debug.assert;
pub const c = @import("c.zig");

pub const Error = error{
    InitEngineFailed,
    DecodeFileFailed,
    InternalError,
};

pub const Engine = struct {
    pub const EngineOption = struct {
        channels: u32 = 2,
        sample_rate: u32 = 48000,
        listener_num: u32 = 1,
        no_auto_start: bool = false,
    };

    const SoundList = std.TailQueue(Sound);
    const SoundGroupList = std.TailQueue(SoundGroup);

    /// memory allocator
    allocator: std.mem.Allocator,

    /// option of internal engine
    option: EngineOption,

    /// internal sound engine
    engine: c.ma_engine,

    /// allocated sound/sound group
    sound_list: SoundList,
    sound_group_list: SoundGroupList,

    pub fn init(allocator: std.mem.Allocator, opt: EngineOption) !*Engine {
        var engine = try allocator.create(Engine);
        engine.allocator = allocator;
        engine.option = opt;
        engine.sound_list = SoundList{};
        engine.sound_group_list = SoundGroupList{};
        errdefer allocator.destroy(engine);

        // create internal engine
        assert(opt.channels > 0);
        assert(opt.listener_num > 0);
        var config = c.ma_engine_config_init();
        config.channels = @intCast(c_uint, opt.channels);
        config.sampleRate = @intCast(c_uint, opt.sample_rate);
        config.listenerCount = @intCast(c_uint, opt.listener_num);
        config.noAutoStart = @as(c_uint, @boolToInt(opt.no_auto_start));
        const rc = c.ma_engine_init(&config, &engine.engine);
        if (rc != c.MA_SUCCESS) {
            return error.InitEngineFailed;
        }
        return engine;
    }

    pub fn deinit(e: *Engine) void {
        while (e.sound_list.pop()) |node| {
            _ = c.ma_sound_uninit(&node.data.sound);
            e.allocator.destroy(node);
        }
        while (e.sound_group_list.pop()) |node| {
            _ = c.ma_sound_group_uninit(&node.data.group);
            e.allocator.destroy(node);
        }
        _ = c.ma_engine_uninit(&e.engine);
        e.allocator.destroy(e);
    }

    pub fn start(e: *Engine) void {
        _ = c.ma_engine_start(&e.engine);
    }

    pub fn stop(e: *Engine) void {
        _ = c.ma_engine_stop(&e.engine);
    }

    pub fn setVolume(e: *Engine, volume: f32) void {
        _ = c.ma_engine_set_volume(&e.engine, volume);
    }

    pub fn setTimeInFrames(e: *Engine, frames: u64) u64 {
        return @intCast(u64, c.ma_engine_set_time(&e.engine, @intCast(c_ulonglong, frames)));
    }

    pub fn setTimeInMilliseconds(e: *Engine, ms: u64) u64 {
        return @intCast(u64, c.ma_engine_set_time(
            &e.engine,
            @intCast(c_ulonglong, ms / 1000 * @as(u64, e.getSampleRate())),
        ));
    }

    pub fn getTimeInFrames(e: *Engine) u64 {
        return @intCast(u64, c.ma_engine_get_time(&e.engine));
    }

    pub fn getTimeInMilliseconds(e: *Engine) u64 {
        return @intCast(u64, c.ma_engine_get_time(&e.engine)) / @as(u64, e.getSampleRate());
    }

    pub fn getSampleRate(e: *Engine) u32 {
        return @intCast(u32, c.ma_engine_get_sample_rate(&e.engine));
    }

    pub fn setListenerPosition(e: *Engine, listener_index: u32, pos_x: f32, pos_y: f32, pos_z: f32) void {
        assert(listener_index < e.option.listener_num);
        _ = c.ma_engine_listener_set_position(
            &e.engine,
            @intCast(c_uint, listener_index),
            pos_x,
            pos_y,
            pos_z,
        );
    }

    pub fn setListenerDirection(e: *Engine, listener_index: u32, dir_x: f32, dir_y: f32, dir_z: f32) void {
        assert(listener_index < e.option.listener_num);
        _ = c.ma_engine_listener_set_direction(
            &e.engine,
            @intCast(c_uint, listener_index),
            dir_x,
            dir_y,
            dir_z,
        );
    }

    pub fn setListenerWorldUp(e: *Engine, listener_index: u32, dir_x: f32, dir_y: f32, dir_z: f32) void {
        assert(listener_index < e.option.listener_num);
        _ = c.ma_engine_listener_set_world_up(
            &e.engine,
            @intCast(c_uint, listener_index),
            dir_x,
            dir_y,
            dir_z,
        );
    }

    pub fn setListenerCone(e: *Engine, listener_index: u32, inner_angle: f32, outer_angle: f32, outer_gain: f32) void {
        assert(inner_angle >= 0 and outer_gain >= 0 and outer_angle >= inner_angle);
        assert(outer_gain > 1);
        _ = c.ma_engine_listener_set_cone(
            &e.engine,
            listener_index,
            inner_angle,
            outer_angle,
            outer_gain,
        );
    }

    pub fn playSoundWithFile(e: *Engine, path: [:0]const u8, group: ?*SoundGroup) !void {
        const rc = c.ma_engine_play_sound(
            &e.engine,
            path.ptr,
            if (group) |g| &g.group else null,
        );
        if (rc != c.MA_SUCCESS) {
            return error.DecodeFileFailed;
        }
    }

    pub const SoundOption = struct {
        /// don't read file into memory at once
        stream: bool = false,

        /// asynchronously read file, return quickly but not ready to play yet
        async_read: bool = false,

        /// decode now instead on the fly
        decode: bool = false,

        /// no spatialization effect
        no_spatialization: bool = false,

        /// no doppler effect
        no_doppler: bool = false,

        fn toInt(o: SoundOption) c_uint {
            var flags: c_uint = 0;
            if (o.stream) {
                flags |= c.MA_SOUND_FLAG_STREAM;
            }
            if (o.async_read) {
                flags |= c.MA_SOUND_FLAG_ASYNC;
            }
            if (o.decode) {
                flags |= c.MA_SOUND_FLAG_DECODE;
            }
            if (o.no_spatialization) {
                flags |= c.MA_SOUND_FLAG_NO_SPATIALIZATION;
            }
            if (o.no_doppler) {
                flags |= c.MA_SOUND_FLAG_NO_PITCH;
            }
            return flags;
        }
    };
    pub fn createSoundFromFile(e: *Engine, path: [:0]const u8, group: ?*SoundGroup, opt: SoundOption) !*Sound {
        var node = try e.allocator.create(SoundList.Node);
        errdefer e.allocator.destroy(node);

        // append to list
        e.sound_list.append(node);
        errdefer e.sound_list.remove(node);

        const rc = c.ma_sound_init_from_file(
            &e.engine,
            path,
            opt.toInt(),
            if (group) |g| &g.group else null,
            null,
            &node.data.sound,
        );
        if (rc != c.MA_SUCCESS) {
            return error.DecodeFileFailed;
        }
        node.data.engine = e;
        return &node.data;
    }

    pub fn createSoundGroup(e: *Engine, parent: ?*SoundGroup) !*SoundGroup {
        var node = try e.allocator.create(SoundGroupList.Node);
        errdefer e.allocator.destroy(node);

        // append to list
        e.sound_group_list.append(node);
        errdefer e.sound_group_list.remove(node);

        const rc = c.ma_sound_group_init(
            &e.engine,
            0,
            if (parent) |g| &g.group else null,
            &node.data.group,
        );
        if (rc != c.MA_SUCCESS) {
            return error.InternalError;
        }
        node.data.engine = e;
        return node;
    }

    pub fn destroySound(e: *Engine, sound: *Sound) void {
        assert(e == sound.engine);
        c.ma_sound_uninit(&sound.sound);
        var node = @fieldParentPtr(SoundList.Node, "data", sound);
        e.sound_list.remove(node);
        e.allocator.destroy(node);
    }

    pub fn destroySoundGroup(e: *Engine, sound_group: *SoundGroup) void {
        assert(e == sound_group.engine);
        c.ma_sound_group_uninit(&sound_group.group);
        var node = @fieldParentPtr(SoundList.Node, "data", sound_group);
        e.sound_group_list.remove(sound_group);
        e.allocator.destroy(node);
    }
};

pub const TimeUnit = union(enum) {
    pcm_frames: u64,
    milliseconds: u64,
};

pub const Sound = struct {
    engine: *Engine,
    sound: c.ma_sound,

    pub fn destroy(snd: *Sound) void {
        snd.engine.destroySound(snd);
    }

    pub fn start(snd: *Sound) void {
        _ = c.ma_sound_start(&snd.sound);
    }

    pub fn stop(snd: *Sound) void {
        _ = c.ma_sound_start(&snd.sound);
    }

    pub fn setVolume(snd: *Sound, volume: f32) void {
        c.ma_sound_set_volume(&snd.sound, volume);
    }

    pub fn getVolume(snd: *Sound) f32 {
        return c.ma_sound_get_volume(&snd.sound);
    }

    pub fn setLooping(snd: *Sound, looping: bool) void {
        c.ma_sound_set_looping(&snd.sound, @as(c_uint, @boolToInt(looping)));
    }

    pub fn isLooping(snd: *Sound) bool {
        return if (c.ma_sound_is_looping(&snd.sound) == 1) true else false;
    }

    pub fn isAtEnd(snd: Sound) bool {
        return if (c.ma_sound_at_end(&snd.sound) == 1) true else false;
    }

    pub fn seekTo(snd: *Sound, t: TimeUnit) void {
        switch (t) {
            .pcm_frames => |frames| {
                c.ma_sound_seek_to_pcm_frame(&snd.sound, @intCast(c_ulonglong, frames));
            },
            .milliseconds => |ms| {
                const frames = @floatToInt(c_ulonglong, @intToFloat(f32, ms) / 1000 * snd.sound.engineNode.sampleRate);
                c.ma_sound_seek_to_pcm_frame(&snd.sound, frames);
            },
        }
    }

    pub fn getCursorInFrames(snd: *Sound) u64 {
        var frames: c.ma_uint64 = undefined;
        _ = c.ma_sound_get_cursor_in_pcm_frames(&snd.sound, &frames);
        return @intCast(u64, frames);
    }

    pub fn getCursorInMilliseconds(snd: *Sound) u64 {
        var seconds: f32 = undefined;
        _ = c.ma_sound_get_cursor_in_seconds(&snd.sound, &seconds);
        return @floatToInt(u64, seconds * 1000);
    }

    pub fn getLengthInFrames(snd: *Sound) u64 {
        var frames: c.ma_uint64 = undefined;
        _ = c.ma_sound_get_length_in_pcm_frames(&snd.sound, &frames);
        return @intCast(u64, frames);
    }

    pub fn getLengthInMilliseconds(snd: *Sound) u64 {
        var seconds: f32 = undefined;
        _ = c.ma_sound_get_length_in_seconds(&snd.sound, &seconds);
        return @floatToInt(u64, seconds * 1000);
    }

    pub fn setStartTime(snd: *Sound, t: TimeUnit) void {
        switch (t) {
            .pcm_frames => |frames| {
                c.ma_sound_set_start_time_in_pcm_frames(&snd.sound, @intCast(c_ulonglong, frames));
            },
            .milliseconds => |ms| {
                c.ma_sound_set_start_time_in_milliseconds(&snd.sound, @intCast(c_ulonglong, ms));
            },
        }
    }

    pub fn setStopTime(snd: *Sound, t: TimeUnit) void {
        switch (t) {
            .pcm_frames => |frames| {
                c.ma_sound_set_stop_time_in_pcm_frames(&snd.sound, @intCast(c_ulonglong, frames));
            },
            .milliseconds => |ms| {
                c.ma_sound_set_stop_time_in_milliseconds(&snd.sound, @intCast(c_ulonglong, ms));
            },
        }
    }

    pub fn setFadeIn(snd: *Sound, volume_begin: f32, volume_end: f32, t: TimeUnit) void {
        switch (t) {
            .pcm_frames => |frames| {
                c.ma_sound_set_fade_in_pcm_frames(&snd.sound, volume_begin, volume_end, @intCast(c_ulonglong, frames));
            },
            .milliseconds => |ms| {
                c.ma_sound_set_fade_in_milliseconds(&snd.sound, volume_begin, volume_end, @intCast(c_ulonglong, ms));
            },
        }
    }

    pub fn setPosition(snd: *Sound, pos_x: f32, pos_y: f32, pos_z: f32) void {
        c.ma_sound_set_position(&snd.sound, pos_x, pos_y, pos_z);
    }

    pub fn getPosition(snd: *Sound) c.ma_vec3f {
        return c.ma_sound_get_position(&snd.sound);
    }

    pub fn setDirection(snd: *Sound, dir_x: f32, dir_y: f32, dir_z: f32) void {
        c.ma_sound_set_direction(&snd.sound, dir_x, dir_y, dir_z);
    }

    pub fn getDirection(snd: *Sound) c.ma_vec3f {
        return c.ma_sound_get_direction(&snd.sound);
    }

    pub fn setVelocity(snd: *Sound, v_x: f32, v_y: f32, v_z: f32) void {
        c.ma_sound_set_velocity(&snd.sound, v_x, v_y, v_z);
    }

    pub fn getVelocity(snd: *Sound) c.ma_vec3f {
        return c.ma_sound_get_velocity(&snd.sound);
    }

    pub fn setPan(snd: *Sound, pan: f32) void {
        assert(pan >= -1.0 and pan <= 1.0);
        c.ma_sound_set_pan(&snd.sound, pan);
    }

    pub fn getPan(snd: *Sound) f32 {
        return c.ma_sound_get_pan(&snd.sound);
    }

    pub fn setPitch(snd: *Sound, pitch: f32) void {
        assert(pitch > 0);
        c.ma_sound_set_pitch(&snd.sound, pitch);
    }

    pub fn getPitch(snd: *Sound) f32 {
        return c.ma_sound_get_pitch(&snd.sound);
    }

    pub fn setCone(snd: *Sound, inner_angle: f32, outer_angle: f32, outer_gain: f32) void {
        assert(inner_angle >= 0 and outer_gain >= 0 and outer_angle >= inner_angle);
        assert(outer_gain > 1);
        _ = c.ma_sound_set_cone(
            &snd.sound,
            inner_angle,
            outer_angle,
            outer_gain,
        );
    }

    pub fn getCone(snd: *Sound, inner_angle: *f32, outer_angle: *f32, outer_gain: *f32) void {
        _ = c.ma_sound_get_cone(
            &snd.sound,
            inner_angle,
            outer_angle,
            outer_gain,
        );
    }
};

pub const SoundGroup = struct {
    engine: *Engine,
    group: c.ma_sound_group,

    pub fn destroy(grp: *SoundGroup) void {
        grp.engine.destroySoundGroup(grp);
    }

    pub fn start(grp: *SoundGroup) void {
        _ = c.ma_sound_group_start(&grp.group);
    }

    pub fn stop(grp: *SoundGroup) void {
        _ = c.ma_sound_group_stop(&grp.group);
    }

    pub fn setVolume(grp: *SoundGroup, volume: f32) void {
        c.ma_sound_group_set_volume(&grp.group, volume);
    }

    pub fn getVolume(grp: *SoundGroup) f32 {
        return c.ma_sound_group_get_volume(&grp.group);
    }

    pub fn setStartTime(grp: *SoundGroup, t: TimeUnit) void {
        switch (t) {
            .pcm_frames => |frames| {
                c.ma_sound_group_set_start_time_in_pcm_frames(&grp.group, @intCast(c_ulonglong, frames));
            },
            .milliseconds => |ms| {
                c.ma_sound_group_set_start_time_in_milliseconds(&grp.group, @intCast(c_ulonglong, ms));
            },
        }
    }

    pub fn setStopTime(grp: *SoundGroup, t: TimeUnit) void {
        switch (t) {
            .pcm_frames => |frames| {
                c.ma_sound_group_set_stop_time_in_pcm_frames(&grp.group, @intCast(c_ulonglong, frames));
            },
            .milliseconds => |ms| {
                c.ma_sound_group_set_stop_time_in_milliseconds(&grp.group, @intCast(c_ulonglong, ms));
            },
        }
    }

    pub fn setFadeIn(grp: *SoundGroup, volume_begin: f32, volume_end: f32, t: TimeUnit) void {
        switch (t) {
            .pcm_frames => |frames| {
                c.ma_sound_group_set_fade_in_pcm_frames(&grp.group, volume_begin, volume_end, @intCast(c_ulonglong, frames));
            },
            .milliseconds => |ms| {
                c.ma_sound_group_set_fade_in_milliseconds(&grp.group, volume_begin, volume_end, @intCast(c_ulonglong, ms));
            },
        }
    }

    pub fn setPosition(grp: *SoundGroup, pos_x: f32, pos_y: f32, pos_z: f32) void {
        c.ma_sound_group_set_position(&grp.group, pos_x, pos_y, pos_z);
    }

    pub fn getPosition(grp: *SoundGroup) c.ma_vec3f {
        return c.ma_sound_group_get_position(&grp.group);
    }

    pub fn setDirection(grp: *SoundGroup, dir_x: f32, dir_y: f32, dir_z: f32) void {
        c.ma_sound_group_set_direction(&grp.group, dir_x, dir_y, dir_z);
    }

    pub fn getDirection(grp: *SoundGroup) c.ma_vec3f {
        return c.ma_sound_group_get_direction(&grp.group);
    }

    pub fn setVelocity(grp: *SoundGroup, v_x: f32, v_y: f32, v_z: f32) void {
        c.ma_sound_group_set_velocity(&grp.group, v_x, v_y, v_z);
    }

    pub fn getVelocity(grp: *SoundGroup) c.ma_vec3f {
        return c.ma_sound_group_get_velocity(&grp.group);
    }

    pub fn setPan(grp: *SoundGroup, pan: f32) void {
        assert(pan >= -1.0 and pan <= 1.0);
        c.ma_sound_group_set_pan(&grp.group, pan);
    }

    pub fn getPan(grp: *SoundGroup) f32 {
        return c.ma_sound_group_get_pan(&grp.group);
    }

    pub fn setPitch(grp: *SoundGroup, pitch: f32) void {
        assert(pitch > 0);
        c.ma_sound_group_set_pitch(&grp.group, pitch);
    }

    pub fn getPitch(grp: *SoundGroup) f32 {
        return c.ma_sound_group_get_pitch(&grp.group);
    }

    pub fn setCone(grp: *SoundGroup, inner_angle: f32, outer_angle: f32, outer_gain: f32) void {
        assert(inner_angle >= 0 and outer_gain >= 0 and outer_angle >= inner_angle);
        assert(outer_gain > 1);
        _ = c.ma_sound_group_set_cone(
            &grp.group,
            inner_angle,
            outer_angle,
            outer_gain,
        );
    }

    pub fn getCone(grp: *SoundGroup, inner_angle: *f32, outer_angle: *f32, outer_gain: *f32) void {
        _ = c.ma_sound_group_get_cone(
            &grp.group,
            inner_angle,
            outer_angle,
            outer_gain,
        );
    }
};
