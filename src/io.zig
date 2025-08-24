const std = @import("std");
const assert = std.debug.assert;
const jok = @import("jok.zig");
const sdl = jok.sdl;

pub const KeyModifierBit = enum(u16) {
    left_shift = sdl.c.KMOD_LSHIFT,
    right_shift = sdl.c.KMOD_RSHIFT,
    left_control = sdl.c.KMOD_LCTRL,
    right_control = sdl.c.KMOD_RCTRL,
    ///left alternate
    left_alt = sdl.c.KMOD_LALT,
    ///right alternate
    right_alt = sdl.c.KMOD_RALT,
    left_gui = sdl.c.KMOD_LGUI,
    right_gui = sdl.c.KMOD_RGUI,
    ///numeric lock
    num_lock = sdl.c.KMOD_NUM,
    ///capital letters lock
    caps_lock = sdl.c.KMOD_CAPS,
    mode = sdl.c.KMOD_MODE,
    ///scroll lock (= previous value sdl.c.KMOD_RESERVED)
    scroll_lock = sdl.c.KMOD_SCROLL,
};
pub const KeyModifierSet = struct {
    storage: u16,

    pub fn fromNative(native: u16) KeyModifierSet {
        return .{ .storage = native };
    }
    pub fn get(self: KeyModifierSet, modifier: KeyModifierBit) bool {
        return (self.storage & @intFromEnum(modifier)) != 0;
    }
    pub fn set(self: *KeyModifierSet, modifier: KeyModifierBit) void {
        self.storage |= @intFromEnum(modifier);
    }
    pub fn clear(self: *KeyModifierSet, modifier: KeyModifierBit) void {
        self.storage &= ~@intFromEnum(modifier);
    }
};
pub const KeyboardEvent = struct {
    timestamp: u32,
    window_id: u32,
    is_down: bool,
    is_repeat: bool,
    scancode: Scancode,
    keycode: Keycode,
    modifiers: KeyModifierSet,

    pub fn fromNative(native: sdl.c.SDL_KeyboardEvent) KeyboardEvent {
        switch (native.type) {
            else => unreachable,
            sdl.c.SDL_KEYDOWN, sdl.c.SDL_KEYUP => {},
        }
        return .{
            .timestamp = native.timestamp,
            .window_id = native.windowID,
            .is_down = native.down,
            .is_repeat = native.repeat != 0,
            .scancode = @enumFromInt(native.keysym.scancode),
            .keycode = @enumFromInt(native.keysym.sym),
            .modifiers = KeyModifierSet.fromNative(native.keysym.mod),
        };
    }
};

pub const MouseButton = enum(u3) {
    left = sdl.c.SDL_BUTTON_LEFT,
    middle = sdl.c.SDL_BUTTON_MIDDLE,
    right = sdl.c.SDL_BUTTON_RIGHT,
    extra_1 = sdl.c.SDL_BUTTON_X1,
    extra_2 = sdl.c.SDL_BUTTON_X2,
};
pub const MouseButtonState = struct {
    pub const NativeBitField = u32;
    pub const Storage = u5;

    storage: Storage,

    pub fn fromNative(native: NativeBitField) MouseButtonState {
        return .{ .storage = @intCast(native) };
    }
    fn maskForButton(button_id: MouseButton) Storage {
        const mask: NativeBitField = @as(NativeBitField, 1) << (@intFromEnum(button_id) - 1);
        return @intCast(mask);
    }
    pub fn isPressed(self: MouseButtonState, button_id: MouseButton) bool {
        return (self.storage & maskForButton(button_id)) != 0;
    }
    pub fn setPressed(self: *MouseButtonState, button_id: MouseButton) void {
        self.storage |= maskForButton(button_id);
    }
    pub fn setUnpressed(self: *MouseButtonState, button_id: MouseButton) void {
        self.storage &= ~maskForButton(button_id);
    }
};
pub const MouseMotionEvent = struct {
    timestamp: u32,
    /// originally named `windowID`
    window_id: u32,
    /// originally named `which`;
    /// if it comes from a touch input device,
    /// the value is sdl.c.SDL_TOUCH_MOUSEID,
    /// in which case a TouchFingerEvent was also generated.
    mouse_instance_id: u32,
    /// from original field named `state`
    button_state: MouseButtonState,

    pos: jok.Point,

    /// difference of position since last reported MouseMotionEvent,
    /// ignores screen boundaries if relative mouse mode is enabled
    delta: jok.Point,

    pub fn fromNative(native: sdl.c.SDL_MouseMotionEvent, ctx: jok.Context) MouseMotionEvent {
        assert(native.type == sdl.c.SDL_MOUSEMOTION);
        const pos = mapPositionToCanvas(ctx, .{
            .x = @floatFromInt(native.x),
            .y = @floatFromInt(native.y),
        });
        const canvas_scale = getCanvasScale(ctx);
        const delta_x = @as(f32, @floatFromInt(native.xrel)) * canvas_scale;
        const delta_y = @as(f32, @floatFromInt(native.yrel)) * canvas_scale;
        return .{
            .timestamp = native.timestamp,
            .window_id = native.windowID,
            .mouse_instance_id = native.which,
            .button_state = MouseButtonState.fromNative(native.state),
            .pos = pos,
            .delta = .{ .x = delta_x, .y = delta_y },
        };
    }
};
pub const MouseButtonEvent = struct {
    timestamp: u32,
    /// originally named `windowID`
    window_id: u32,
    /// originally named `which`,
    /// if it comes from a touch input device,
    /// the value is sdl.c.SDL_TOUCH_MOUSEID,
    /// in which case a TouchFingerEvent was also generated.
    mouse_instance_id: u32,
    button: MouseButton,
    is_down: bool,
    clicks: u8,
    pos: jok.Point,

    pub fn fromNative(native: sdl.c.SDL_MouseButtonEvent, ctx: jok.Context) MouseButtonEvent {
        switch (native.type) {
            else => unreachable,
            sdl.c.SDL_MOUSEBUTTONDOWN, sdl.c.SDL_MOUSEBUTTONUP => {},
        }
        const pos = mapPositionToCanvas(ctx, .{
            .x = @floatFromInt(native.x),
            .y = @floatFromInt(native.y),
        });
        return .{
            .timestamp = native.timestamp,
            .window_id = native.windowID,
            .mouse_instance_id = native.which,
            .button = @enumFromInt(native.button),
            .is_down = native.down,
            .clicks = native.clicks,
            .pos = pos,
        };
    }
};
pub const MouseWheelEvent = struct {
    pub const Direction = enum(u8) {
        normal = sdl.c.SDL_MOUSEWHEEL_NORMAL,
        flipped = sdl.c.SDL_MOUSEWHEEL_FLIPPED,
    };

    timestamp: u32,
    /// originally named `windowID`
    window_id: u32,
    /// originally named `which`,
    /// if it comes from a touch input device,
    /// the value is sdl.c.SDL_TOUCH_MOUSEID,
    /// in which case a TouchFingerEvent was also generated.
    mouse_instance_id: u32,
    /// originally named `x`,
    /// the amount scrolled horizontally,
    /// positive to the right and negative to the left,
    /// unless field `direction` has value `.flipped`,
    /// in which case the signs are reversed.
    delta_x: i32,
    /// originally named `y`,
    /// the amount scrolled vertically,
    /// positive away from the user and negative towards the user,
    /// unless field `direction` has value `.flipped`,
    /// in which case the signs are reversed.
    delta_y: i32,
    /// On macOS, devices are often by default configured to have
    /// "natural" scrolling direction, which flips the sign of both delta values.
    /// In this case, this field will have value `.flipped` instead of `.normal`.
    direction: Direction,

    pub fn fromNative(native: sdl.c.SDL_MouseWheelEvent) MouseWheelEvent {
        assert(native.type == sdl.c.SDL_MOUSEWHEEL);
        return .{
            .timestamp = native.timestamp,
            .window_id = native.windowID,
            .mouse_instance_id = native.which,
            .delta_x = native.x,
            .delta_y = native.y,
            .direction = @enumFromInt(@as(u8, @intCast(native.direction))),
        };
    }
};

pub const JoyAxisEvent = struct {
    timestamp: u32,
    joystick_id: sdl.c.SDL_JoystickID,
    axis: u8,
    value: i16,

    pub fn fromNative(native: sdl.c.SDL_JoyAxisEvent) JoyAxisEvent {
        switch (native.type) {
            else => unreachable,
            sdl.c.SDL_JOYAXISMOTION => {},
        }
        return .{
            .timestamp = native.timestamp,
            .joystick_id = native.which,
            .axis = native.axis,
            .value = native.value,
        };
    }

    pub fn normalizedValue(self: JoyAxisEvent, comptime FloatType: type) FloatType {
        const denominator: FloatType = if (self.value > 0)
            @floatFromInt(sdl.c.SDL_JOYSTICK_AXIS_MAX)
        else
            @floatFromInt(sdl.c.SDL_JOYSTICK_AXIS_MIN);
        return @as(FloatType, @floatFromInt(self.value)) / @abs(denominator);
    }
};

pub const JoyHatEvent = struct {
    pub const HatValue = enum(u8) {
        centered = sdl.c.SDL_HAT_CENTERED,
        up = sdl.c.SDL_HAT_UP,
        right = sdl.c.SDL_HAT_RIGHT,
        down = sdl.c.SDL_HAT_DOWN,
        left = sdl.c.SDL_HAT_LEFT,
        right_up = sdl.c.SDL_HAT_RIGHTUP,
        right_down = sdl.c.SDL_HAT_RIGHTDOWN,
        left_up = sdl.c.SDL_HAT_LEFTUP,
        left_down = sdl.c.SDL_HAT_LEFTDOWN,
    };

    timestamp: u32,
    joystick_id: sdl.c.SDL_JoystickID,
    hat: u8,
    value: HatValue,

    pub fn fromNative(native: sdl.c.SDL_JoyHatEvent) JoyHatEvent {
        switch (native.type) {
            else => unreachable,
            sdl.c.SDL_JOYHATMOTION => {},
        }
        return .{
            .timestamp = native.timestamp,
            .joystick_id = native.which,
            .hat = native.hat,
            .value = @enumFromInt(native.value),
        };
    }
};

pub const JoyBallEvent = struct {
    timestamp: u32,
    joystick_id: sdl.c.SDL_JoystickID,
    ball: u8,
    relative_x: i16,
    relative_y: i16,

    pub fn fromNative(native: sdl.c.SDL_JoyBallEvent) JoyBallEvent {
        switch (native.type) {
            else => unreachable,
            sdl.c.SDL_JOYBALLMOTION => {},
        }
        return .{
            .timestamp = native.timestamp,
            .joystick_id = native.which,
            .ball = native.ball,
            .relative_x = native.xrel,
            .relative_y = native.yrel,
        };
    }
};

pub const JoyButtonEvent = struct {
    timestamp: u32,
    joystick_id: sdl.c.SDL_JoystickID,
    button: u8,
    is_down: bool,

    pub fn fromNative(native: sdl.c.SDL_JoyButtonEvent) JoyButtonEvent {
        switch (native.type) {
            else => unreachable,
            sdl.c.SDL_JOYBUTTONDOWN, sdl.c.SDL_JOYBUTTONUP => {},
        }
        return .{
            .timestamp = native.timestamp,
            .joystick_id = native.which,
            .button = native.button,
            .is_down = native.down,
        };
    }
};

pub const GamepadAxisEvent = struct {
    timestamp: u32,
    joystick_id: sdl.c.SDL_JoystickID,
    axis: Gamepad.Axis,
    value: i16,

    pub fn fromNative(native: sdl.c.SDL_GamepadAxisEvent) GamepadAxisEvent {
        switch (native.type) {
            else => unreachable,
            sdl.c.SDL_EVENT_GAMEPAD_AXIS_MOTION => {},
        }
        return .{
            .timestamp = native.timestamp,
            .joystick_id = native.which,
            .axis = @enumFromInt(native.axis),
            .value = native.value,
        };
    }

    pub fn normalizedValue(self: GamepadAxisEvent, comptime FloatType: type) FloatType {
        const denominator: FloatType = if (self.value > 0)
            @floatFromInt(sdl.c.SDL_JOYSTICK_AXIS_MAX)
        else
            @floatFromInt(sdl.c.SDL_JOYSTICK_AXIS_MIN);
        return @as(FloatType, @floatFromInt(self.value)) / @abs(denominator);
    }
};

pub const GamepadButtonEvent = struct {
    timestamp: u32,
    joystick_id: sdl.c.SDL_JoystickID,
    button: Gamepad.Button,
    is_down: bool,

    pub fn fromNative(native: sdl.c.SDL_GamepadButtonEvent) GamepadButtonEvent {
        switch (native.type) {
            else => unreachable,
            sdl.c.SDL_EVENT_GAMEPAD_BUTTON_DOWN, sdl.c.SDL_EVENT_GAMEPAD_BUTTON_UP => {},
        }
        return .{
            .timestamp = native.timestamp,
            .joystick_id = native.which,
            .button = @enumFromInt(native.button),
            .is_down = native.down,
        };
    }
};

pub const UserEvent = struct {
    /// from Event.registerEvents
    type: u32,
    timestamp: u32 = 0,
    window_id: u32 = 0,
    code: i32,
    data1: ?*anyopaque = null,
    data2: ?*anyopaque = null,

    pub fn from(native: sdl.c.SDL_UserEvent) UserEvent {
        return .{
            .type = native.type,
            .timestamp = native.timestamp,
            .window_id = native.windowID,
            .code = native.code,
            .data1 = native.data1,
            .data2 = native.data2,
        };
    }
};

pub const Event = union(enum) {
    pub const CommonEvent = sdl.c.SDL_CommonEvent;
    pub const DisplayEvent = sdl.c.SDL_DisplayEvent;
    pub const WindowEvent = sdl.c.SDL_WindowEvent;
    pub const TextEditingEvent = sdl.c.SDL_TextEditingEvent;
    pub const TextInputEvent = sdl.c.SDL_TextInputEvent;
    pub const JoyDeviceEvent = sdl.c.SDL_JoyDeviceEvent;
    pub const JoyBatteryEvent = sdl.c.SDL_JoyBatteryEvent;
    pub const GamepadDeviceEvent = sdl.c.SDL_GamepadDeviceEvent;
    pub const AudioDeviceEvent = sdl.c.SDL_AudioDeviceEvent;
    pub const SensorEvent = sdl.c.SDL_SensorEvent;
    pub const QuitEvent = sdl.c.SDL_QuitEvent;
    pub const TouchFingerEvent = sdl.c.SDL_TouchFingerEvent;
    pub const MultiGestureEvent = sdl.c.SDL_MultiGestureEvent;
    pub const DropEvent = sdl.c.SDL_DropEvent;

    clip_board_update: CommonEvent,
    app_did_enter_background: CommonEvent,
    app_did_enter_foreground: CommonEvent,
    app_will_enter_foreground: CommonEvent,
    app_will_enter_background: CommonEvent,
    app_low_memory: CommonEvent,
    app_terminating: CommonEvent,
    render_targets_reset: CommonEvent,
    render_device_reset: CommonEvent,
    key_map_changed: CommonEvent,
    display_orientation: DisplayEvent,
    display_added: DisplayEvent,
    display_removed: DisplayEvent,
    display_moved: DisplayEvent,
    display_desktop_mode_changed: DisplayEvent,
    display_current_mode_changed: DisplayEvent,
    display_content_scale_changed: DisplayEvent,
    window_shown: WindowEvent,
    window_hidden: WindowEvent,
    window_exposed: WindowEvent,
    window_moved: WindowEvent,
    window_resized: WindowEvent,
    window_pixel_size_changed: WindowEvent,
    window_metal_view_resized: WindowEvent,
    window_minimized: WindowEvent,
    window_maximized: WindowEvent,
    window_restored: WindowEvent,
    window_mouse_enter: WindowEvent,
    window_mouse_leave: WindowEvent,
    window_focus_gained: WindowEvent,
    window_focus_lost: WindowEvent,
    window_close_requested: WindowEvent,
    window_hit_test: WindowEvent,
    window_iccprof_changed: WindowEvent,
    window_display_changed: WindowEvent,
    window_display_scale_changed: WindowEvent,
    window_safe_area_changed: WindowEvent,
    window_occluded: WindowEvent,
    window_enter_fullscreen: WindowEvent,
    window_leave_fullscreen: WindowEvent,
    window_destroyed: WindowEvent,
    window_hdr_state_changed: WindowEvent,
    key_down: KeyboardEvent,
    key_up: KeyboardEvent,
    text_editing: TextEditingEvent,
    text_input: TextInputEvent,
    mouse_motion: MouseMotionEvent,
    mouse_button_down: MouseButtonEvent,
    mouse_button_up: MouseButtonEvent,
    mouse_wheel: MouseWheelEvent,
    joy_axis_motion: JoyAxisEvent,
    joy_ball_motion: JoyBallEvent,
    joy_hat_motion: JoyHatEvent,
    joy_button_down: JoyButtonEvent,
    joy_button_up: JoyButtonEvent,
    joy_device_added: JoyDeviceEvent,
    joy_device_removed: JoyDeviceEvent,
    joy_battery_level: JoyBatteryEvent,
    gamepad_axis_motion: GamepadAxisEvent,
    gamepad_button_down: GamepadButtonEvent,
    gamepad_button_up: GamepadButtonEvent,
    gamepad_added: GamepadDeviceEvent,
    gamepad_removed: GamepadDeviceEvent,
    gamepad_remapped: GamepadDeviceEvent,
    audio_device_added: AudioDeviceEvent,
    audio_device_removed: AudioDeviceEvent,
    sensor_update: SensorEvent,
    quit: QuitEvent,
    finger_down: TouchFingerEvent,
    finger_up: TouchFingerEvent,
    finger_motion: TouchFingerEvent,
    drop_file: DropEvent,
    drop_text: DropEvent,
    drop_begin: DropEvent,
    drop_complete: DropEvent,
    user: UserEvent,

    pub fn from(raw: sdl.c.SDL_Event, ctx: jok.Context) Event {
        return switch (raw.type) {
            sdl.c.SDL_EVENT_QUIT => Event{ .quit = raw.quit },
            sdl.c.SDL_EVENT_APP_TERMINATING => Event{ .app_terminating = raw.common },
            sdl.c.SDL_EVENT_APP_LOWMEMORY => Event{ .app_low_memory = raw.common },
            sdl.c.SDL_EVENT_APP_WILLENTERBACKGROUND => Event{ .app_will_enter_background = raw.common },
            sdl.c.SDL_EVENT_APP_DIDENTERBACKGROUND => Event{ .app_did_enter_background = raw.common },
            sdl.c.SDL_EVENT_APP_WILLENTERFOREGROUND => Event{ .app_will_enter_foreground = raw.common },
            sdl.c.SDL_EVENT_APP_DIDENTERFOREGROUND => Event{ .app_did_enter_foreground = raw.common },
            sdl.c.SDL_EVENT_DISPLAY_ORIENTATION => Event{ .display_orientation = raw.display },
            sdl.c.SDL_EVENT_DISPLAY_ADDED => Event{ .display_added = raw.display },
            sdl.c.SDL_EVENT_DISPLAY_REMOVED => Event{ .display_removed = raw.display },
            sdl.c.SDL_EVENT_DISPLAY_MOVED => Event{ .display_moved = raw.display },
            sdl.c.SDL_EVENT_DISPLAY_DESKTOP_MODE_CHANGED => Event{ .display_desktop_mode_changed = raw.display },
            sdl.c.SDL_EVENT_DISPLAY_CURRENT_MODE_CHANGED => Event{ .display_current_mode_changed = raw.display },
            sdl.c.SDL_EVENT_DISPLAY_CONTENT_SCALE_CHANGED => Event{ .display_content_scale_changed = raw.display },
            sdl.c.SDL_EVENT_WINDOW_SHOWN => Event{ .window_shown = raw.window },
            sdl.c.SDL_EVENT_WINDOW_HIDDEN => Event{ .window_hidden = raw.window },
            sdl.c.SDL_EVENT_WINDOW_EXPOSED => Event{ .window_exposed = raw.window },
            sdl.c.SDL_EVENT_WINDOW_MOVED => Event{ .window_moved = raw.window },
            sdl.c.SDL_EVENT_WINDOW_RESIZED => Event{ .window_resized = raw.window },
            sdl.c.SDL_EVENT_WINDOW_PIXEL_SIZE_CHANGED => Event{ .window_pixel_size_changed = raw.window },
            sdl.c.SDL_EVENT_WINDOW_METAL_VIEW_RESIZED => Event{ .window_metal_view_resized = raw.window },
            sdl.c.SDL_EVENT_WINDOW_MINIMIZED => Event{ .window_minimized = raw.window },
            sdl.c.SDL_EVENT_WINDOW_MAXIMIZED => Event{ .window_maximized = raw.window },
            sdl.c.SDL_EVENT_WINDOW_RESTORED => Event{ .window_restored = raw.window },
            sdl.c.SDL_EVENT_WINDOW_MOUSE_ENTER => Event{ .window_mouse_enter = raw.window },
            sdl.c.SDL_EVENT_WINDOW_MOUSE_LEAVE => Event{ .window_mouse_leave = raw.window },
            sdl.c.SDL_EVENT_WINDOW_FOCUS_GAINED => Event{ .window_focus_gained = raw.window },
            sdl.c.SDL_EVENT_WINDOW_FOCUS_LOST => Event{ .window_focus_lost = raw.window },
            sdl.c.SDL_EVENT_WINDOW_CLOSE_REQUESTED => Event{ .window_close_requested = raw.window },
            sdl.c.SDL_EVENT_WINDOW_HIT_TEST => Event{ .window_hit_test = raw.window },
            sdl.c.SDL_EVENT_WINDOW_ICCPROF_CHANGED => Event{ .window_iccprof_changed = raw.window },
            sdl.c.SDL_EVENT_WINDOW_DISPLAY_CHANGED => Event{ .window_display_changed = raw.window },
            sdl.c.SDL_EVENT_WINDOW_DISPLAY_SCALE_CHANGED => Event{ .window_display_scale_changed = raw.window },
            sdl.c.SDL_EVENT_WINDOW_SAFE_AREA_CHANGED => Event{ .window_safe_area_changed = raw.window },
            sdl.c.SDL_EVENT_WINDOW_OCCLUDED => Event{ .window_occluded = raw.window },
            sdl.c.SDL_EVENT_WINDOW_ENTER_FULLSCREEN => Event{ .window_enter_fullscreen = raw.window },
            sdl.c.SDL_EVENT_WINDOW_LEAVE_FULLSCREEN => Event{ .window_leave_fullscreen = raw.window },
            sdl.c.SDL_EVENT_WINDOW_DESTROYED => Event{ .window_destroyed = raw.window },
            sdl.c.SDL_EVENT_WINDOW_HDR_STATE_CHANGED => Event{ .window_hdr_state_changed = raw.window },
            sdl.c.SDL_EVENT_KEYDOWN => Event{ .key_down = KeyboardEvent.fromNative(raw.key) },
            sdl.c.SDL_EVENT_KEYUP => Event{ .key_up = KeyboardEvent.fromNative(raw.key) },
            sdl.c.SDL_EVENT_TEXTEDITING => Event{ .text_editing = raw.edit },
            sdl.c.SDL_EVENT_TEXTINPUT => Event{ .text_input = raw.text },
            sdl.c.SDL_EVENT_KEYMAPCHANGED => Event{ .key_map_changed = raw.common },
            sdl.c.SDL_EVENT_MOUSEMOTION => Event{ .mouse_motion = MouseMotionEvent.fromNative(raw.motion, ctx) },
            sdl.c.SDL_EVENT_MOUSEBUTTONDOWN => Event{ .mouse_button_down = MouseButtonEvent.fromNative(raw.button, ctx) },
            sdl.c.SDL_EVENT_MOUSEBUTTONUP => Event{ .mouse_button_up = MouseButtonEvent.fromNative(raw.button, ctx) },
            sdl.c.SDL_EVENT_MOUSEWHEEL => Event{ .mouse_wheel = MouseWheelEvent.fromNative(raw.wheel) },
            sdl.c.SDL_EVENT_JOYAXISMOTION => Event{ .joy_axis_motion = JoyAxisEvent.fromNative(raw.jaxis) },
            sdl.c.SDL_EVENT_JOYBALLMOTION => Event{ .joy_ball_motion = JoyBallEvent.fromNative(raw.jball) },
            sdl.c.SDL_EVENT_JOYHATMOTION => Event{ .joy_hat_motion = JoyHatEvent.fromNative(raw.jhat) },
            sdl.c.SDL_EVENT_JOYBUTTONDOWN => Event{ .joy_button_down = JoyButtonEvent.fromNative(raw.jbutton) },
            sdl.c.SDL_EVENT_JOYBUTTONUP => Event{ .joy_button_up = JoyButtonEvent.fromNative(raw.jbutton) },
            sdl.c.SDL_EVENT_JOYDEVICEADDED => Event{ .joy_device_added = raw.jdevice },
            sdl.c.SDL_EVENT_JOYDEVICEREMOVED => Event{ .joy_device_removed = raw.jdevice },
            sdl.c.SDL_EVENT_JOYBATTERYUPDATED => Event{ .joy_battery_level = raw.jbattery },
            sdl.c.SDL_EVENT_GAMEPAD_AXIS_MOTION => Event{ .gamepad_axis_motion = GamepadAxisEvent.fromNative(raw.gaxis) },
            sdl.c.SDL_EVENT_GAMEPAD_BUTTON_DOWN => Event{ .gamepad_button_down = GamepadButtonEvent.fromNative(raw.gbutton) },
            sdl.c.SDL_EVENT_GAMEPAD_BUTTON_UP => Event{ .gamepad_button_up = GamepadButtonEvent.fromNative(raw.gbutton) },
            sdl.c.SDL_EVENT_GAMEPAD_ADDED => Event{ .gamepad_added = raw.gdevice },
            sdl.c.SDL_EVENT_GAMEPAD_REMOVED => Event{ .gamepad_removed = raw.gdevice },
            sdl.c.SDL_EVENT_GAMEPAD_REMAPPED => Event{ .gamepad_remapped = raw.gdevice },
            sdl.c.SDL_EVENT_FINGER_DOWN => Event{ .finger_down = raw.tfinger },
            sdl.c.SDL_EVENT_FINGER_UP => Event{ .finger_up = raw.tfinger },
            sdl.c.SDL_EVENT_FINGER_MOTION => Event{ .finger_motion = raw.tfinger },
            sdl.c.SDL_EVENT_CLIPBOARDUPDATE => Event{ .clip_board_update = raw.common },
            sdl.c.SDL_EVENT_DROPFILE => Event{ .drop_file = raw.drop },
            sdl.c.SDL_EVENT_DROPTEXT => Event{ .drop_text = raw.drop },
            sdl.c.SDL_EVENT_DROPBEGIN => Event{ .drop_begin = raw.drop },
            sdl.c.SDL_EVENT_DROPCOMPLETE => Event{ .drop_complete = raw.drop },
            sdl.c.SDL_EVENT_AUDIODEVICEADDED => Event{ .audio_device_added = raw.adevice },
            sdl.c.SDL_EVENT_AUDIODEVICEREMOVED => Event{ .audio_device_removed = raw.adevice },
            sdl.c.SDL_EVENT_SENSORUPDATE => Event{ .sensor_update = raw.sensor },
            sdl.c.SDL_EVENT_RENDER_TARGETS_RESET => Event{ .render_targets_reset = raw.common },
            sdl.c.SDL_EVENT_RENDER_DEVICE_RESET => Event{ .render_device_reset = raw.common },
            else => |t| if (t >= sdl.c.SDL_EVENT_USER)
                Event{ .user = UserEvent.from(raw.user) }
            else
                @panic("Unsupported event type detected!"),
        };
    }
};

/// register `num` user events and return the corresponding type
/// to be used when generating those.
pub fn registerEvents(num: u32) !u32 {
    const res = sdl.c.SDL_RegisterEvents(@intCast(num));
    if (res == std.math.maxInt(u32)) return error.CannotRegisterUserEvent;
    return res;
}

/// push a new user event in the event queue. Safe for concurrent use.
/// `ev_type` must be a value returned by `registerEvent`.
pub fn pushEvent(ev_type: u32, code: i32, data1: ?*anyopaque, data2: ?*anyopaque) !void {
    var sdl_ev = sdl.c.SDL_Event{
        .user = .{
            .type = ev_type,
            .timestamp = 0,
            .windowID = 0,
            .code = code,
            .data1 = data1,
            .data2 = data2,
        },
    };
    if (sdl.c.SDL_PushEvent(&sdl_ev) < 0) {
        return sdl.c.Error.SdlError;
    }
}

/// This function should only be called from
/// the thread that initialized the video subsystem.
pub fn pumpEvents() void {
    sdl.c.SDL_PumpEvents();
}

pub fn pollEvent() ?Event {
    var ev: sdl.c.SDL_Event = undefined;
    if (sdl.c.SDL_PollEvent(&ev) != 0)
        return Event.from(ev);
    return null;
}

pub fn pollNativeEvent() ?sdl.c.SDL_Event {
    var ev: sdl.c.SDL_Event = undefined;
    if (sdl.c.SDL_PollEvent(&ev) != 0)
        return ev;
    return null;
}

/// Waits indefinitely to pump a new event into the queue.
/// May not conserve energy on some systems, in some versions/situations.
/// This function should only be called from
/// the thread that initialized the video subsystem.
pub fn waitEvent() !Event {
    var ev: sdl.c.SDL_Event = undefined;
    if (sdl.c.SDL_WaitEvent(&ev) != 0)
        return Event.from(ev);
    return sdl.c.Error.SdlError;
}

/// Waits `timeout` milliseconds
/// to pump the next available event into the queue.
/// May not conserve energy on some systems, in some versions/situations.
/// This function should only be called from
/// the thread that initialized the video subsystem.
pub fn waitEventTimeout(timeout: usize) ?Event {
    var ev: sdl.c.SDL_Event = undefined;
    if (sdl.c.SDL_WaitEventTimeout(&ev, @intCast(timeout)) != 0)
        return Event.from(ev);
    return null;
}

pub const MouseState = struct {
    buttons: MouseButtonState,
    pos: jok.Point,
};

pub fn getMouseState(ctx: jok.Context) MouseState {
    var ms: MouseState = undefined;
    var x: c_int = undefined;
    var y: c_int = undefined;
    const buttons = sdl.c.SDL_GetMouseState(&x, &y);
    ms.buttons = MouseButtonState.fromNative(buttons);
    ms.pos = mapPositionToCanvas(ctx, .{
        .x = @floatFromInt(x),
        .y = @floatFromInt(y),
    });
    return ms;
}

pub const Scancode = enum(sdl.c.SDL_Scancode) {
    unknown = sdl.c.SDL_SCANCODE_UNKNOWN,
    a = sdl.c.SDL_SCANCODE_A,
    b = sdl.c.SDL_SCANCODE_B,
    c = sdl.c.SDL_SCANCODE_C,
    d = sdl.c.SDL_SCANCODE_D,
    e = sdl.c.SDL_SCANCODE_E,
    f = sdl.c.SDL_SCANCODE_F,
    g = sdl.c.SDL_SCANCODE_G,
    h = sdl.c.SDL_SCANCODE_H,
    i = sdl.c.SDL_SCANCODE_I,
    j = sdl.c.SDL_SCANCODE_J,
    k = sdl.c.SDL_SCANCODE_K,
    l = sdl.c.SDL_SCANCODE_L,
    m = sdl.c.SDL_SCANCODE_M,
    n = sdl.c.SDL_SCANCODE_N,
    o = sdl.c.SDL_SCANCODE_O,
    p = sdl.c.SDL_SCANCODE_P,
    q = sdl.c.SDL_SCANCODE_Q,
    r = sdl.c.SDL_SCANCODE_R,
    s = sdl.c.SDL_SCANCODE_S,
    t = sdl.c.SDL_SCANCODE_T,
    u = sdl.c.SDL_SCANCODE_U,
    v = sdl.c.SDL_SCANCODE_V,
    w = sdl.c.SDL_SCANCODE_W,
    x = sdl.c.SDL_SCANCODE_X,
    y = sdl.c.SDL_SCANCODE_Y,
    z = sdl.c.SDL_SCANCODE_Z,
    @"1" = sdl.c.SDL_SCANCODE_1,
    @"2" = sdl.c.SDL_SCANCODE_2,
    @"3" = sdl.c.SDL_SCANCODE_3,
    @"4" = sdl.c.SDL_SCANCODE_4,
    @"5" = sdl.c.SDL_SCANCODE_5,
    @"6" = sdl.c.SDL_SCANCODE_6,
    @"7" = sdl.c.SDL_SCANCODE_7,
    @"8" = sdl.c.SDL_SCANCODE_8,
    @"9" = sdl.c.SDL_SCANCODE_9,
    @"0" = sdl.c.SDL_SCANCODE_0,
    @"return" = sdl.c.SDL_SCANCODE_RETURN,
    escape = sdl.c.SDL_SCANCODE_ESCAPE,
    backspace = sdl.c.SDL_SCANCODE_BACKSPACE,
    tab = sdl.c.SDL_SCANCODE_TAB,
    space = sdl.c.SDL_SCANCODE_SPACE,
    minus = sdl.c.SDL_SCANCODE_MINUS,
    equals = sdl.c.SDL_SCANCODE_EQUALS,
    left_bracket = sdl.c.SDL_SCANCODE_LEFTBRACKET,
    right_bracket = sdl.c.SDL_SCANCODE_RIGHTBRACKET,
    backslash = sdl.c.SDL_SCANCODE_BACKSLASH,
    non_us_hash = sdl.c.SDL_SCANCODE_NONUSHASH,
    semicolon = sdl.c.SDL_SCANCODE_SEMICOLON,
    apostrophe = sdl.c.SDL_SCANCODE_APOSTROPHE,
    grave = sdl.c.SDL_SCANCODE_GRAVE,
    comma = sdl.c.SDL_SCANCODE_COMMA,
    period = sdl.c.SDL_SCANCODE_PERIOD,
    slash = sdl.c.SDL_SCANCODE_SLASH,
    ///capital letters lock
    caps_lock = sdl.c.SDL_SCANCODE_CAPSLOCK,
    f1 = sdl.c.SDL_SCANCODE_F1,
    f2 = sdl.c.SDL_SCANCODE_F2,
    f3 = sdl.c.SDL_SCANCODE_F3,
    f4 = sdl.c.SDL_SCANCODE_F4,
    f5 = sdl.c.SDL_SCANCODE_F5,
    f6 = sdl.c.SDL_SCANCODE_F6,
    f7 = sdl.c.SDL_SCANCODE_F7,
    f8 = sdl.c.SDL_SCANCODE_F8,
    f9 = sdl.c.SDL_SCANCODE_F9,
    f10 = sdl.c.SDL_SCANCODE_F10,
    f11 = sdl.c.SDL_SCANCODE_F11,
    f12 = sdl.c.SDL_SCANCODE_F12,
    print_screen = sdl.c.SDL_SCANCODE_PRINTSCREEN,
    scroll_lock = sdl.c.SDL_SCANCODE_SCROLLLOCK,
    pause = sdl.c.SDL_SCANCODE_PAUSE,
    insert = sdl.c.SDL_SCANCODE_INSERT,
    home = sdl.c.SDL_SCANCODE_HOME,
    page_up = sdl.c.SDL_SCANCODE_PAGEUP,
    delete = sdl.c.SDL_SCANCODE_DELETE,
    end = sdl.c.SDL_SCANCODE_END,
    page_down = sdl.c.SDL_SCANCODE_PAGEDOWN,
    right = sdl.c.SDL_SCANCODE_RIGHT,
    left = sdl.c.SDL_SCANCODE_LEFT,
    down = sdl.c.SDL_SCANCODE_DOWN,
    up = sdl.c.SDL_SCANCODE_UP,
    ///numeric lock, "Clear" key on Apple keyboards
    num_lock_clear = sdl.c.SDL_SCANCODE_NUMLOCKCLEAR,
    keypad_divide = sdl.c.SDL_SCANCODE_KP_DIVIDE,
    keypad_multiply = sdl.c.SDL_SCANCODE_KP_MULTIPLY,
    keypad_minus = sdl.c.SDL_SCANCODE_KP_MINUS,
    keypad_plus = sdl.c.SDL_SCANCODE_KP_PLUS,
    keypad_enter = sdl.c.SDL_SCANCODE_KP_ENTER,
    keypad_1 = sdl.c.SDL_SCANCODE_KP_1,
    keypad_2 = sdl.c.SDL_SCANCODE_KP_2,
    keypad_3 = sdl.c.SDL_SCANCODE_KP_3,
    keypad_4 = sdl.c.SDL_SCANCODE_KP_4,
    keypad_5 = sdl.c.SDL_SCANCODE_KP_5,
    keypad_6 = sdl.c.SDL_SCANCODE_KP_6,
    keypad_7 = sdl.c.SDL_SCANCODE_KP_7,
    keypad_8 = sdl.c.SDL_SCANCODE_KP_8,
    keypad_9 = sdl.c.SDL_SCANCODE_KP_9,
    keypad_0 = sdl.c.SDL_SCANCODE_KP_0,
    keypad_period = sdl.c.SDL_SCANCODE_KP_PERIOD,
    non_us_backslash = sdl.c.SDL_SCANCODE_NONUSBACKSLASH,
    application = sdl.c.SDL_SCANCODE_APPLICATION,
    power = sdl.c.SDL_SCANCODE_POWER,
    keypad_equals = sdl.c.SDL_SCANCODE_KP_EQUALS,
    f13 = sdl.c.SDL_SCANCODE_F13,
    f14 = sdl.c.SDL_SCANCODE_F14,
    f15 = sdl.c.SDL_SCANCODE_F15,
    f16 = sdl.c.SDL_SCANCODE_F16,
    f17 = sdl.c.SDL_SCANCODE_F17,
    f18 = sdl.c.SDL_SCANCODE_F18,
    f19 = sdl.c.SDL_SCANCODE_F19,
    f20 = sdl.c.SDL_SCANCODE_F20,
    f21 = sdl.c.SDL_SCANCODE_F21,
    f22 = sdl.c.SDL_SCANCODE_F22,
    f23 = sdl.c.SDL_SCANCODE_F23,
    f24 = sdl.c.SDL_SCANCODE_F24,
    execute = sdl.c.SDL_SCANCODE_EXECUTE,
    help = sdl.c.SDL_SCANCODE_HELP,
    menu = sdl.c.SDL_SCANCODE_MENU,
    select = sdl.c.SDL_SCANCODE_SELECT,
    stop = sdl.c.SDL_SCANCODE_STOP,
    again = sdl.c.SDL_SCANCODE_AGAIN,
    undo = sdl.c.SDL_SCANCODE_UNDO,
    cut = sdl.c.SDL_SCANCODE_CUT,
    copy = sdl.c.SDL_SCANCODE_COPY,
    paste = sdl.c.SDL_SCANCODE_PASTE,
    find = sdl.c.SDL_SCANCODE_FIND,
    mute = sdl.c.SDL_SCANCODE_MUTE,
    volume_up = sdl.c.SDL_SCANCODE_VOLUMEUP,
    volume_down = sdl.c.SDL_SCANCODE_VOLUMEDOWN,
    keypad_comma = sdl.c.SDL_SCANCODE_KP_COMMA,
    keypad_equals_as_400 = sdl.c.SDL_SCANCODE_KP_EQUALSAS400,
    international_1 = sdl.c.SDL_SCANCODE_INTERNATIONAL1,
    international_2 = sdl.c.SDL_SCANCODE_INTERNATIONAL2,
    international_3 = sdl.c.SDL_SCANCODE_INTERNATIONAL3,
    international_4 = sdl.c.SDL_SCANCODE_INTERNATIONAL4,
    international_5 = sdl.c.SDL_SCANCODE_INTERNATIONAL5,
    international_6 = sdl.c.SDL_SCANCODE_INTERNATIONAL6,
    international_7 = sdl.c.SDL_SCANCODE_INTERNATIONAL7,
    international_8 = sdl.c.SDL_SCANCODE_INTERNATIONAL8,
    international_9 = sdl.c.SDL_SCANCODE_INTERNATIONAL9,
    language_1 = sdl.c.SDL_SCANCODE_LANG1,
    language_2 = sdl.c.SDL_SCANCODE_LANG2,
    language_3 = sdl.c.SDL_SCANCODE_LANG3,
    language_4 = sdl.c.SDL_SCANCODE_LANG4,
    language_5 = sdl.c.SDL_SCANCODE_LANG5,
    language_6 = sdl.c.SDL_SCANCODE_LANG6,
    language_7 = sdl.c.SDL_SCANCODE_LANG7,
    language_8 = sdl.c.SDL_SCANCODE_LANG8,
    language_9 = sdl.c.SDL_SCANCODE_LANG9,
    alternate_erase = sdl.c.SDL_SCANCODE_ALTERASE,
    ///aka "Attention"
    system_request = sdl.c.SDL_SCANCODE_SYSREQ,
    cancel = sdl.c.SDL_SCANCODE_CANCEL,
    clear = sdl.c.SDL_SCANCODE_CLEAR,
    prior = sdl.c.SDL_SCANCODE_PRIOR,
    return_2 = sdl.c.SDL_SCANCODE_RETURN2,
    separator = sdl.c.SDL_SCANCODE_SEPARATOR,
    out = sdl.c.SDL_SCANCODE_OUT,
    ///Don't know what this stands for, operator? operation? operating system? Couldn't find it anywhere.
    oper = sdl.c.SDL_SCANCODE_OPER,
    ///technically named "Clear/Again"
    clear_again = sdl.c.SDL_SCANCODE_CLEARAGAIN,
    ///aka "CrSel/Props" (properties)
    cursor_selection = sdl.c.SDL_SCANCODE_CRSEL,
    extend_selection = sdl.c.SDL_SCANCODE_EXSEL,
    keypad_00 = sdl.c.SDL_SCANCODE_KP_00,
    keypad_000 = sdl.c.SDL_SCANCODE_KP_000,
    thousands_separator = sdl.c.SDL_SCANCODE_THOUSANDSSEPARATOR,
    decimal_separator = sdl.c.SDL_SCANCODE_DECIMALSEPARATOR,
    currency_unit = sdl.c.SDL_SCANCODE_CURRENCYUNIT,
    currency_subunit = sdl.c.SDL_SCANCODE_CURRENCYSUBUNIT,
    keypad_left_parenthesis = sdl.c.SDL_SCANCODE_KP_LEFTPAREN,
    keypad_right_parenthesis = sdl.c.SDL_SCANCODE_KP_RIGHTPAREN,
    keypad_left_brace = sdl.c.SDL_SCANCODE_KP_LEFTBRACE,
    keypad_right_brace = sdl.c.SDL_SCANCODE_KP_RIGHTBRACE,
    keypad_tab = sdl.c.SDL_SCANCODE_KP_TAB,
    keypad_backspace = sdl.c.SDL_SCANCODE_KP_BACKSPACE,
    keypad_a = sdl.c.SDL_SCANCODE_KP_A,
    keypad_b = sdl.c.SDL_SCANCODE_KP_B,
    keypad_c = sdl.c.SDL_SCANCODE_KP_C,
    keypad_d = sdl.c.SDL_SCANCODE_KP_D,
    keypad_e = sdl.c.SDL_SCANCODE_KP_E,
    keypad_f = sdl.c.SDL_SCANCODE_KP_F,
    ///keypad exclusive or
    keypad_xor = sdl.c.SDL_SCANCODE_KP_XOR,
    keypad_power = sdl.c.SDL_SCANCODE_KP_POWER,
    keypad_percent = sdl.c.SDL_SCANCODE_KP_PERCENT,
    keypad_less = sdl.c.SDL_SCANCODE_KP_LESS,
    keypad_greater = sdl.c.SDL_SCANCODE_KP_GREATER,
    keypad_ampersand = sdl.c.SDL_SCANCODE_KP_AMPERSAND,
    keypad_double_ampersand = sdl.c.SDL_SCANCODE_KP_DBLAMPERSAND,
    keypad_vertical_bar = sdl.c.SDL_SCANCODE_KP_VERTICALBAR,
    keypad_double_vertical_bar = sdl.c.SDL_SCANCODE_KP_DBLVERTICALBAR,
    keypad_colon = sdl.c.SDL_SCANCODE_KP_COLON,
    keypad_hash = sdl.c.SDL_SCANCODE_KP_HASH,
    keypad_space = sdl.c.SDL_SCANCODE_KP_SPACE,
    keypad_at_sign = sdl.c.SDL_SCANCODE_KP_AT,
    keypad_exclamation_mark = sdl.c.SDL_SCANCODE_KP_EXCLAM,
    keypad_memory_store = sdl.c.SDL_SCANCODE_KP_MEMSTORE,
    keypad_memory_recall = sdl.c.SDL_SCANCODE_KP_MEMRECALL,
    keypad_memory_clear = sdl.c.SDL_SCANCODE_KP_MEMCLEAR,
    keypad_memory_add = sdl.c.SDL_SCANCODE_KP_MEMADD,
    keypad_memory_subtract = sdl.c.SDL_SCANCODE_KP_MEMSUBTRACT,
    keypad_memory_multiply = sdl.c.SDL_SCANCODE_KP_MEMMULTIPLY,
    keypad_memory_divide = sdl.c.SDL_SCANCODE_KP_MEMDIVIDE,
    keypad_plus_minus = sdl.c.SDL_SCANCODE_KP_PLUSMINUS,
    keypad_clear = sdl.c.SDL_SCANCODE_KP_CLEAR,
    keypad_clear_entry = sdl.c.SDL_SCANCODE_KP_CLEARENTRY,
    keypad_binary = sdl.c.SDL_SCANCODE_KP_BINARY,
    keypad_octal = sdl.c.SDL_SCANCODE_KP_OCTAL,
    keypad_decimal = sdl.c.SDL_SCANCODE_KP_DECIMAL,
    keypad_hexadecimal = sdl.c.SDL_SCANCODE_KP_HEXADECIMAL,
    left_control = sdl.c.SDL_SCANCODE_LCTRL,
    left_shift = sdl.c.SDL_SCANCODE_LSHIFT,
    ///left alternate
    left_alt = sdl.c.SDL_SCANCODE_LALT,
    left_gui = sdl.c.SDL_SCANCODE_LGUI,
    right_control = sdl.c.SDL_SCANCODE_RCTRL,
    right_shift = sdl.c.SDL_SCANCODE_RSHIFT,
    ///right alternate
    right_alt = sdl.c.SDL_SCANCODE_RALT,
    right_gui = sdl.c.SDL_SCANCODE_RGUI,
    mode = sdl.c.SDL_SCANCODE_MODE,
    media_next_track = sdl.c.SDL_SCANCODE_MEDIA_NEXT_TRACK,
    media_previous_track = sdl.c.SDL_SCANCODE_MEDIA_PREVIOUS_TRACK,
    media_play = sdl.c.SDL_SCANCODE_MEDIA_PLAY,
    media_pause = sdl.c.SDL_SCANCODE_MEDIA_PAUSE,
    media_record = sdl.c.SDL_SCANCODE_MEDIA_RECORD,
    media_fast_forward = sdl.c.SDL_SCANCODE_MEDIA_FAST_FORWARD,
    media_rewind = sdl.c.SDL_SCANCODE_MEDIA_REWIND,
    media_stop = sdl.c.SDL_SCANCODE_MEDIA_STOP,
    media_eject = sdl.c.SDL_SCANCODE_MEDIA_EJECT,
    media_play_pause = sdl.c.SDL_SCANCODE_MEDIA_PLAY_PAUSE,
    media_select = sdl.c.SDL_SCANCODE_MEDIA_SELECT,
    application_control_search = sdl.c.SDL_SCANCODE_AC_SEARCH,
    application_control_home = sdl.c.SDL_SCANCODE_AC_HOME,
    application_control_back = sdl.c.SDL_SCANCODE_AC_BACK,
    application_control_forward = sdl.c.SDL_SCANCODE_AC_FORWARD,
    application_control_stop = sdl.c.SDL_SCANCODE_AC_STOP,
    application_control_refresh = sdl.c.SDL_SCANCODE_AC_REFRESH,
    application_control_bookmarks = sdl.c.SDL_SCANCODE_AC_BOOKMARKS,
    sleep = sdl.c.SDL_SCANCODE_SLEEP,
    _,
};

pub const KeyboardState = struct {
    states: []const u8,

    pub fn isPressed(ks: KeyboardState, scancode: Scancode) bool {
        return ks.states[@intCast(@intFromEnum(scancode))] != 0;
    }
};

pub fn getKeyboardState() KeyboardState {
    var len: c_int = undefined;
    const slice = sdl.c.SDL_GetKeyboardState(&len);
    return KeyboardState{
        .states = slice[0..@intCast(len)],
    };
}
pub const getModState = getKeyboardModifierState;
pub fn getKeyboardModifierState() KeyModifierSet {
    return KeyModifierSet.fromNative(@intCast(sdl.c.SDL_GetModState()));
}

pub const Keycode = enum(sdl.c.SDL_Keycode) {
    unknown = sdl.c.SDLK_UNKNOWN,
    @"return" = sdl.c.SDLK_RETURN,
    escape = sdl.c.SDLK_ESCAPE,
    backspace = sdl.c.SDLK_BACKSPACE,
    tab = sdl.c.SDLK_TAB,
    space = sdl.c.SDLK_SPACE,
    exclamation_mark = sdl.c.SDLK_EXCLAIM,
    dblapostrophe = sdl.c.SDLK_DBLAPOSTROPHE,
    hash = sdl.c.SDLK_HASH,
    percent = sdl.c.SDLK_PERCENT,
    dollar = sdl.c.SDLK_DOLLAR,
    ampersand = sdl.c.SDLK_AMPERSAND,
    apostrophe = sdl.c.SDLK_APOSTROPHE,
    left_parenthesis = sdl.c.SDLK_LEFTPAREN,
    right_parenthesis = sdl.c.SDLK_RIGHTPAREN,
    asterisk = sdl.c.SDLK_ASTERISK,
    plus = sdl.c.SDLK_PLUS,
    comma = sdl.c.SDLK_COMMA,
    minus = sdl.c.SDLK_MINUS,
    period = sdl.c.SDLK_PERIOD,
    slash = sdl.c.SDLK_SLASH,
    @"0" = sdl.c.SDLK_0,
    @"1" = sdl.c.SDLK_1,
    @"2" = sdl.c.SDLK_2,
    @"3" = sdl.c.SDLK_3,
    @"4" = sdl.c.SDLK_4,
    @"5" = sdl.c.SDLK_5,
    @"6" = sdl.c.SDLK_6,
    @"7" = sdl.c.SDLK_7,
    @"8" = sdl.c.SDLK_8,
    @"9" = sdl.c.SDLK_9,
    colon = sdl.c.SDLK_COLON,
    semicolon = sdl.c.SDLK_SEMICOLON,
    less = sdl.c.SDLK_LESS,
    equals = sdl.c.SDLK_EQUALS,
    greater = sdl.c.SDLK_GREATER,
    question_mark = sdl.c.SDLK_QUESTION,
    at_sign = sdl.c.SDLK_AT,
    left_bracket = sdl.c.SDLK_LEFTBRACKET,
    backslash = sdl.c.SDLK_BACKSLASH,
    right_bracket = sdl.c.SDLK_RIGHTBRACKET,
    caret = sdl.c.SDLK_CARET,
    underscore = sdl.c.SDLK_UNDERSCORE,
    grave = sdl.c.SDLK_GRAVE,
    a = sdl.c.SDLK_A,
    b = sdl.c.SDLK_B,
    c = sdl.c.SDLK_C,
    d = sdl.c.SDLK_D,
    e = sdl.c.SDLK_E,
    f = sdl.c.SDLK_F,
    g = sdl.c.SDLK_G,
    h = sdl.c.SDLK_H,
    i = sdl.c.SDLK_I,
    j = sdl.c.SDLK_J,
    k = sdl.c.SDLK_K,
    l = sdl.c.SDLK_L,
    m = sdl.c.SDLK_M,
    n = sdl.c.SDLK_N,
    o = sdl.c.SDLK_O,
    p = sdl.c.SDLK_P,
    q = sdl.c.SDLK_Q,
    r = sdl.c.SDLK_R,
    s = sdl.c.SDLK_S,
    t = sdl.c.SDLK_T,
    u = sdl.c.SDLK_U,
    v = sdl.c.SDLK_V,
    w = sdl.c.SDLK_W,
    x = sdl.c.SDLK_X,
    y = sdl.c.SDLK_Y,
    z = sdl.c.SDLK_Z,
    ///capital letters lock
    caps_lock = sdl.c.SDLK_CAPSLOCK,
    f1 = sdl.c.SDLK_F1,
    f2 = sdl.c.SDLK_F2,
    f3 = sdl.c.SDLK_F3,
    f4 = sdl.c.SDLK_F4,
    f5 = sdl.c.SDLK_F5,
    f6 = sdl.c.SDLK_F6,
    f7 = sdl.c.SDLK_F7,
    f8 = sdl.c.SDLK_F8,
    f9 = sdl.c.SDLK_F9,
    f10 = sdl.c.SDLK_F10,
    f11 = sdl.c.SDLK_F11,
    f12 = sdl.c.SDLK_F12,
    print_screen = sdl.c.SDLK_PRINTSCREEN,
    scroll_lock = sdl.c.SDLK_SCROLLLOCK,
    pause = sdl.c.SDLK_PAUSE,
    insert = sdl.c.SDLK_INSERT,
    home = sdl.c.SDLK_HOME,
    page_up = sdl.c.SDLK_PAGEUP,
    delete = sdl.c.SDLK_DELETE,
    end = sdl.c.SDLK_END,
    page_down = sdl.c.SDLK_PAGEDOWN,
    right = sdl.c.SDLK_RIGHT,
    left = sdl.c.SDLK_LEFT,
    down = sdl.c.SDLK_DOWN,
    up = sdl.c.SDLK_UP,
    ///numeric lock, "Clear" key on Apple keyboards
    num_lock_clear = sdl.c.SDLK_NUMLOCKCLEAR,
    keypad_divide = sdl.c.SDLK_KP_DIVIDE,
    keypad_multiply = sdl.c.SDLK_KP_MULTIPLY,
    keypad_minus = sdl.c.SDLK_KP_MINUS,
    keypad_plus = sdl.c.SDLK_KP_PLUS,
    keypad_enter = sdl.c.SDLK_KP_ENTER,
    keypad_1 = sdl.c.SDLK_KP_1,
    keypad_2 = sdl.c.SDLK_KP_2,
    keypad_3 = sdl.c.SDLK_KP_3,
    keypad_4 = sdl.c.SDLK_KP_4,
    keypad_5 = sdl.c.SDLK_KP_5,
    keypad_6 = sdl.c.SDLK_KP_6,
    keypad_7 = sdl.c.SDLK_KP_7,
    keypad_8 = sdl.c.SDLK_KP_8,
    keypad_9 = sdl.c.SDLK_KP_9,
    keypad_0 = sdl.c.SDLK_KP_0,
    keypad_period = sdl.c.SDLK_KP_PERIOD,
    application = sdl.c.SDLK_APPLICATION,
    power = sdl.c.SDLK_POWER,
    keypad_equals = sdl.c.SDLK_KP_EQUALS,
    f13 = sdl.c.SDLK_F13,
    f14 = sdl.c.SDLK_F14,
    f15 = sdl.c.SDLK_F15,
    f16 = sdl.c.SDLK_F16,
    f17 = sdl.c.SDLK_F17,
    f18 = sdl.c.SDLK_F18,
    f19 = sdl.c.SDLK_F19,
    f20 = sdl.c.SDLK_F20,
    f21 = sdl.c.SDLK_F21,
    f22 = sdl.c.SDLK_F22,
    f23 = sdl.c.SDLK_F23,
    f24 = sdl.c.SDLK_F24,
    execute = sdl.c.SDLK_EXECUTE,
    help = sdl.c.SDLK_HELP,
    menu = sdl.c.SDLK_MENU,
    select = sdl.c.SDLK_SELECT,
    stop = sdl.c.SDLK_STOP,
    again = sdl.c.SDLK_AGAIN,
    undo = sdl.c.SDLK_UNDO,
    cut = sdl.c.SDLK_CUT,
    copy = sdl.c.SDLK_COPY,
    paste = sdl.c.SDLK_PASTE,
    find = sdl.c.SDLK_FIND,
    mute = sdl.c.SDLK_MUTE,
    volume_up = sdl.c.SDLK_VOLUMEUP,
    volume_down = sdl.c.SDLK_VOLUMEDOWN,
    keypad_comma = sdl.c.SDLK_KP_COMMA,
    keypad_equals_as_400 = sdl.c.SDLK_KP_EQUALSAS400,
    alternate_erase = sdl.c.SDLK_ALTERASE,
    ///aka "Attention"
    system_request = sdl.c.SDLK_SYSREQ,
    cancel = sdl.c.SDLK_CANCEL,
    clear = sdl.c.SDLK_CLEAR,
    prior = sdl.c.SDLK_PRIOR,
    return_2 = sdl.c.SDLK_RETURN2,
    separator = sdl.c.SDLK_SEPARATOR,
    out = sdl.c.SDLK_OUT,
    ///Don't know what this stands for, operator? operation? operating system? Couldn't find it anywhere.
    oper = sdl.c.SDLK_OPER,
    ///technically named "Clear/Again"
    clear_again = sdl.c.SDLK_CLEARAGAIN,
    ///aka "CrSel/Props" (properties)
    cursor_selection = sdl.c.SDLK_CRSEL,
    extend_selection = sdl.c.SDLK_EXSEL,
    keypad_00 = sdl.c.SDLK_KP_00,
    keypad_000 = sdl.c.SDLK_KP_000,
    thousands_separator = sdl.c.SDLK_THOUSANDSSEPARATOR,
    decimal_separator = sdl.c.SDLK_DECIMALSEPARATOR,
    currency_unit = sdl.c.SDLK_CURRENCYUNIT,
    currency_subunit = sdl.c.SDLK_CURRENCYSUBUNIT,
    keypad_left_parenthesis = sdl.c.SDLK_KP_LEFTPAREN,
    keypad_right_parenthesis = sdl.c.SDLK_KP_RIGHTPAREN,
    keypad_left_brace = sdl.c.SDLK_KP_LEFTBRACE,
    keypad_right_brace = sdl.c.SDLK_KP_RIGHTBRACE,
    keypad_tab = sdl.c.SDLK_KP_TAB,
    keypad_backspace = sdl.c.SDLK_KP_BACKSPACE,
    keypad_a = sdl.c.SDLK_KP_A,
    keypad_b = sdl.c.SDLK_KP_B,
    keypad_c = sdl.c.SDLK_KP_C,
    keypad_d = sdl.c.SDLK_KP_D,
    keypad_e = sdl.c.SDLK_KP_E,
    keypad_f = sdl.c.SDLK_KP_F,
    ///keypad exclusive or
    keypad_xor = sdl.c.SDLK_KP_XOR,
    keypad_power = sdl.c.SDLK_KP_POWER,
    keypad_percent = sdl.c.SDLK_KP_PERCENT,
    keypad_less = sdl.c.SDLK_KP_LESS,
    keypad_greater = sdl.c.SDLK_KP_GREATER,
    keypad_ampersand = sdl.c.SDLK_KP_AMPERSAND,
    keypad_double_ampersand = sdl.c.SDLK_KP_DBLAMPERSAND,
    keypad_vertical_bar = sdl.c.SDLK_KP_VERTICALBAR,
    keypad_double_vertical_bar = sdl.c.SDLK_KP_DBLVERTICALBAR,
    keypad_colon = sdl.c.SDLK_KP_COLON,
    keypad_hash = sdl.c.SDLK_KP_HASH,
    keypad_space = sdl.c.SDLK_KP_SPACE,
    keypad_at_sign = sdl.c.SDLK_KP_AT,
    keypad_exclamation_mark = sdl.c.SDLK_KP_EXCLAM,
    keypad_memory_store = sdl.c.SDLK_KP_MEMSTORE,
    keypad_memory_recall = sdl.c.SDLK_KP_MEMRECALL,
    keypad_memory_clear = sdl.c.SDLK_KP_MEMCLEAR,
    keypad_memory_add = sdl.c.SDLK_KP_MEMADD,
    keypad_memory_subtract = sdl.c.SDLK_KP_MEMSUBTRACT,
    keypad_memory_multiply = sdl.c.SDLK_KP_MEMMULTIPLY,
    keypad_memory_divide = sdl.c.SDLK_KP_MEMDIVIDE,
    keypad_plus_minus = sdl.c.SDLK_KP_PLUSMINUS,
    keypad_clear = sdl.c.SDLK_KP_CLEAR,
    keypad_clear_entry = sdl.c.SDLK_KP_CLEARENTRY,
    keypad_binary = sdl.c.SDLK_KP_BINARY,
    keypad_octal = sdl.c.SDLK_KP_OCTAL,
    keypad_decimal = sdl.c.SDLK_KP_DECIMAL,
    keypad_hexadecimal = sdl.c.SDLK_KP_HEXADECIMAL,
    left_control = sdl.c.SDLK_LCTRL,
    left_shift = sdl.c.SDLK_LSHIFT,
    ///left alternate
    left_alt = sdl.c.SDLK_LALT,
    left_gui = sdl.c.SDLK_LGUI,
    right_control = sdl.c.SDLK_RCTRL,
    right_shift = sdl.c.SDLK_RSHIFT,
    ///right alternate
    right_alt = sdl.c.SDLK_RALT,
    right_gui = sdl.c.SDLK_RGUI,
    mode = sdl.c.SDLK_MODE,
    media_next = sdl.c.SDLK_MEDIA_NEXT_TRACK,
    media_previous = sdl.c.SDLK_MEDIA_PREVIOUS_TRACK,
    media_stop = sdl.c.SDLK_MEDIA_STOP,
    media_play = sdl.c.SDLK_MEDIA_PLAY,
    media_pause = sdl.c.SDLK_MEDIA_PAUSE,
    media_play_pause = sdl.c.SDLK_MEDIA_PLAY_PAUSE,
    media_eject = sdl.c.SDLK_MEDIA_EJECT,
    media_select = sdl.c.SDLK_MEDIA_SELECT,
    media_rewind = sdl.c.SDLK_MEDIA_REWIND,
    media_fast_forward = sdl.c.SDLK_MEDIA_FAST_FORWARD,
    application_control_search = sdl.c.SDLK_AC_SEARCH,
    application_control_home = sdl.c.SDLK_AC_HOME,
    application_control_back = sdl.c.SDLK_AC_BACK,
    application_control_forward = sdl.c.SDLK_AC_FORWARD,
    application_control_stop = sdl.c.SDLK_AC_STOP,
    application_control_refresh = sdl.c.SDLK_AC_REFRESH,
    application_control_bookmarks = sdl.c.SDLK_AC_BOOKMARKS,
    sleep = sdl.c.SDLK_SLEEP,
    _,
};

pub const Clipboard = struct {
    pub fn get() !?[]const u8 {
        if (sdl.c.SDL_HasClipboardText() == sdl.c.SDL_FALSE)
            return null;
        const c_string = sdl.c.SDL_GetClipboardText();
        const txt = std.mem.sliceTo(c_string, 0);
        if (txt.len == 0) {
            sdl.c.SDL_free(c_string);
            return sdl.c.Error.SdlError;
        }
        return txt;
    }
    /// free is to be called with a previously fetched clipboard content
    pub fn free(txt: []const u8) void {
        sdl.c.SDL_free(@ptrCast(txt));
    }
    pub fn set(txt: []const u8) !void {
        if (sdl.c.SDL_SetClipboardText(@ptrCast(txt)) != 0) {
            return sdl.c.Error.SdlError;
        }
    }
};

pub fn getTicks() u32 {
    return sdl.c.SDL_GetTicks();
}

pub fn getTicks64() u64 {
    return sdl.c.SDL_GetTicks64();
}

pub fn delay(ms: u32) void {
    sdl.c.SDL_Delay(ms);
}

pub fn numJoysticks() !u31 {
    const num = sdl.c.SDL_NumJoysticks();
    if (num < 0) return error.SdlError;
    return @intCast(num);
}

pub const Gamepad = struct {
    ptr: *sdl.c.SDL_Gamepad,

    pub fn open(joystick_index: u32) !Gamepad {
        return Gamepad{
            .ptr = sdl.c.SDL_OpenGamepad(joystick_index) orelse return error.SdlError,
        };
    }

    pub fn is(joystick_index: u31) bool {
        return sdl.c.SDL_IsGamepad(joystick_index) > 0;
    }

    pub fn close(self: Gamepad) void {
        sdl.c.SDL_GamepadClose(self.ptr);
    }

    pub fn nameForIndex(joystick_index: u31) []const u8 {
        return std.mem.sliceTo(sdl.c.SDL_GamepadNameForIndex(joystick_index), 0);
    }

    pub fn getButton(self: Gamepad, button: Button) u8 {
        return sdl.c.SDL_GamepadGetButton(self.ptr, @intFromEnum(button));
    }

    pub fn getAxis(self: Gamepad, axis: Axis) i16 {
        return sdl.c.SDL_GamepadGetAxis(self.ptr, @intFromEnum(axis));
    }

    pub fn getAxisNormalized(self: Gamepad, axis: Axis) f32 {
        return @as(f32, @floatFromInt(self.getAxis(axis))) / @as(f32, @floatFromInt(sdl.c.SDL_JOYSTICK_AXIS_MAX));
    }

    pub fn instanceId(self: Gamepad) sdl.c.SDL_JoystickID {
        return sdl.c.SDL_JoystickInstanceID(sdl.c.SDL_GamepadGetJoystick(self.ptr));
    }

    pub const Button = enum(i32) {
        sourth = sdl.c.SDL_GAMEPAD_BUTTON_SOUTH,
        east = sdl.c.SDL_GAMEPAD_BUTTON_EAST,
        west = sdl.c.SDL_GAMEPAD_BUTTON_WEST,
        north = sdl.c.SDL_GAMEPAD_BUTTON_NORTH,
        back = sdl.c.SDL_GAMEPAD_BUTTON_BACK,
        guide = sdl.c.SDL_GAMEPAD_BUTTON_GUIDE,
        start = sdl.c.SDL_GAMEPAD_BUTTON_START,
        left_stick = sdl.c.SDL_GAMEPAD_BUTTON_LEFT_STICK,
        right_stick = sdl.c.SDL_GAMEPAD_BUTTON_RIGHT_STICK,
        left_shoulder = sdl.c.SDL_GAMEPAD_BUTTON_LEFT_SHOULDER,
        right_shoulder = sdl.c.SDL_GAMEPAD_BUTTON_RIGHT_SHOULDER,
        dpad_up = sdl.c.SDL_GAMEPAD_BUTTON_DPAD_UP,
        dpad_down = sdl.c.SDL_GAMEPAD_BUTTON_DPAD_DOWN,
        dpad_left = sdl.c.SDL_GAMEPAD_BUTTON_DPAD_LEFT,
        dpad_right = sdl.c.SDL_GAMEPAD_BUTTON_DPAD_RIGHT,
        /// Xbox Series X share button, PS5 microphone button, Nintendo Switch Pro capture button, Amazon Luna microphone button
        misc_1 = sdl.c.SDL_GAMEPAD_BUTTON_MISC1,
        right_paddle_1 = sdl.c.SDL_GAMEPAD_BUTTON_RIGHT_PADDLE1,
        left_paddle_1 = sdl.c.SDL_GAMEPAD_BUTTON_LEFT_PADDLE1,
        right_paddle_2 = sdl.c.SDL_GAMEPAD_BUTTON_RIGHT_PADDLE2,
        left_paddle_2 = sdl.c.SDL_GAMEPAD_BUTTON_LEFT_PADDLE2,
        /// PS4/PS5 touchpad button
        touchpad = sdl.c.SDL_GAMEPAD_BUTTON_TOUCHPAD,
    };

    pub const Axis = enum(i32) {
        left_x = sdl.c.SDL_GAMEPAD_AXIS_LEFTX,
        left_y = sdl.c.SDL_GAMEPAD_AXIS_LEFTY,
        right_x = sdl.c.SDL_GAMEPAD_AXIS_RIGHTX,
        right_y = sdl.c.SDL_GAMEPAD_AXIS_RIGHTY,
        left_trigger = sdl.c.SDL_GAMEPAD_AXIS_LEFT_TRIGGER,
        right_trigger = sdl.c.SDL_GAMEPAD_AXIS_RIGHT_TRIGGER,
    };
};

inline fn getCanvasScale(ctx: jok.Context) f32 {
    const canvas_size = ctx.getCanvasSize();
    const canvas_area = ctx.getCanvasArea();
    return @as(f32, @floatFromInt(canvas_size.width)) / canvas_area.width;
}

inline fn mapPositionToCanvas(ctx: jok.Context, pos: jok.Point) jok.Point {
    const canvas_size = ctx.getCanvasSize();
    const canvas_area = ctx.getCanvasArea();
    const canvas_scale = @as(f32, @floatFromInt(canvas_size.width)) / canvas_area.width;
    return .{
        .x = @round((pos.x - canvas_area.x) * canvas_scale),
        .y = @round((pos.y - canvas_area.y) * canvas_scale),
    };
}
