const std = @import("std");
const assert = std.debug.assert;
const jok = @import("jok.zig");
const sdl = jok.sdl;

pub const WindowEvent = struct {
    const Type = enum(u8) {
        none = sdl.SDL_WINDOWEVENT_NONE,
        shown = sdl.SDL_WINDOWEVENT_SHOWN,
        hidden = sdl.SDL_WINDOWEVENT_HIDDEN,
        exposed = sdl.SDL_WINDOWEVENT_EXPOSED,
        moved = sdl.SDL_WINDOWEVENT_MOVED,
        resized = sdl.SDL_WINDOWEVENT_RESIZED,
        size_changed = sdl.SDL_WINDOWEVENT_SIZE_CHANGED,
        minimized = sdl.SDL_WINDOWEVENT_MINIMIZED,
        maximized = sdl.SDL_WINDOWEVENT_MAXIMIZED,
        restored = sdl.SDL_WINDOWEVENT_RESTORED,
        enter = sdl.SDL_WINDOWEVENT_ENTER,
        leave = sdl.SDL_WINDOWEVENT_LEAVE,
        focus_gained = sdl.SDL_WINDOWEVENT_FOCUS_GAINED,
        focus_lost = sdl.SDL_WINDOWEVENT_FOCUS_LOST,
        close = sdl.SDL_WINDOWEVENT_CLOSE,
        take_focus = sdl.SDL_WINDOWEVENT_TAKE_FOCUS,
        hit_test = sdl.SDL_WINDOWEVENT_HIT_TEST,

        _,
    };

    const Data = union(Type) {
        none: void,
        shown: void,
        hidden: void,
        exposed: void,
        moved: jok.Point,
        resized: jok.Size,
        size_changed: jok.Size,
        minimized: void,
        maximized: void,
        restored: void,
        enter: void,
        leave: void,
        focus_gained: void,
        focus_lost: void,
        close: void,
        take_focus: void,
        hit_test: void,
    };

    timestamp: u32,
    window_id: u32,
    type: Data,

    fn fromNative(ev: sdl.SDL_WindowEvent) WindowEvent {
        return WindowEvent{
            .timestamp = ev.timestamp,
            .window_id = ev.windowID,
            .type = switch (@as(Type, @enumFromInt(ev.event))) {
                .shown => Data{ .shown = {} },
                .hidden => Data{ .hidden = {} },
                .exposed => Data{ .exposed = {} },
                .moved => Data{ .moved = jok.Point{ .x = @floatFromInt(ev.data1), .y = @floatFromInt(ev.data2) } },
                .resized => Data{ .resized = jok.Size{ .width = @intCast(ev.data1), .height = @intCast(ev.data2) } },
                .size_changed => Data{ .size_changed = jok.Size{ .width = @intCast(ev.data1), .height = @intCast(ev.data2) } },
                .minimized => Data{ .minimized = {} },
                .maximized => Data{ .maximized = {} },
                .restored => Data{ .restored = {} },
                .enter => Data{ .enter = {} },
                .leave => Data{ .leave = {} },
                .focus_gained => Data{ .focus_gained = {} },
                .focus_lost => Data{ .focus_lost = {} },
                .close => Data{ .close = {} },
                .take_focus => Data{ .take_focus = {} },
                .hit_test => Data{ .hit_test = {} },
                else => Data{ .none = {} },
            },
        };
    }
};

pub const KeyModifierBit = enum(u16) {
    left_shift = sdl.KMOD_LSHIFT,
    right_shift = sdl.KMOD_RSHIFT,
    left_control = sdl.KMOD_LCTRL,
    right_control = sdl.KMOD_RCTRL,
    ///left alternate
    left_alt = sdl.KMOD_LALT,
    ///right alternate
    right_alt = sdl.KMOD_RALT,
    left_gui = sdl.KMOD_LGUI,
    right_gui = sdl.KMOD_RGUI,
    ///numeric lock
    num_lock = sdl.KMOD_NUM,
    ///capital letters lock
    caps_lock = sdl.KMOD_CAPS,
    mode = sdl.KMOD_MODE,
    ///scroll lock (= previous value sdl.KMOD_RESERVED)
    scroll_lock = sdl.KMOD_SCROLL,
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
    pub const KeyState = enum(u8) {
        released = sdl.SDL_RELEASED,
        pressed = sdl.SDL_PRESSED,
    };

    timestamp: u32,
    window_id: u32,
    key_state: KeyState,
    is_repeat: bool,
    scancode: Scancode,
    keycode: Keycode,
    modifiers: KeyModifierSet,

    pub fn fromNative(native: sdl.SDL_KeyboardEvent) KeyboardEvent {
        switch (native.type) {
            else => unreachable,
            sdl.SDL_KEYDOWN, sdl.SDL_KEYUP => {},
        }
        return .{
            .timestamp = native.timestamp,
            .window_id = native.windowID,
            .key_state = @enumFromInt(native.state),
            .is_repeat = native.repeat != 0,
            .scancode = @enumFromInt(native.keysym.scancode),
            .keycode = @enumFromInt(native.keysym.sym),
            .modifiers = KeyModifierSet.fromNative(native.keysym.mod),
        };
    }
};

pub const MouseButton = enum(u3) {
    left = sdl.SDL_BUTTON_LEFT,
    middle = sdl.SDL_BUTTON_MIDDLE,
    right = sdl.SDL_BUTTON_RIGHT,
    extra_1 = sdl.SDL_BUTTON_X1,
    extra_2 = sdl.SDL_BUTTON_X2,
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
    /// the value is sdl.SDL_TOUCH_MOUSEID,
    /// in which case a TouchFingerEvent was also generated.
    mouse_instance_id: u32,
    /// from original field named `state`
    button_state: MouseButtonState,

    pos: jok.Point,

    /// difference of position since last reported MouseMotionEvent,
    /// ignores screen boundaries if relative mouse mode is enabled
    delta: jok.Point,

    pub fn fromNative(native: sdl.SDL_MouseMotionEvent) MouseMotionEvent {
        assert(native.type == sdl.SDL_MOUSEMOTION);
        const pos = mapPositionToCanvas(.{
            .x = @floatFromInt(native.x),
            .y = @floatFromInt(native.y),
        });
        const canvas_scale = getCanvasScale();
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
    pub const ButtonState = enum(u8) {
        released = sdl.SDL_RELEASED,
        pressed = sdl.SDL_PRESSED,
    };

    timestamp: u32,
    /// originally named `windowID`
    window_id: u32,
    /// originally named `which`,
    /// if it comes from a touch input device,
    /// the value is sdl.SDL_TOUCH_MOUSEID,
    /// in which case a TouchFingerEvent was also generated.
    mouse_instance_id: u32,
    button: MouseButton,
    state: ButtonState,
    clicks: u8,
    pos: jok.Point,

    pub fn fromNative(native: sdl.SDL_MouseButtonEvent) MouseButtonEvent {
        switch (native.type) {
            else => unreachable,
            sdl.SDL_MOUSEBUTTONDOWN, sdl.SDL_MOUSEBUTTONUP => {},
        }
        const pos = mapPositionToCanvas(.{
            .x = @floatFromInt(native.x),
            .y = @floatFromInt(native.y),
        });
        return .{
            .timestamp = native.timestamp,
            .window_id = native.windowID,
            .mouse_instance_id = native.which,
            .button = @enumFromInt(native.button),
            .state = @enumFromInt(native.state),
            .clicks = native.clicks,
            .pos = pos,
        };
    }
};
pub const MouseWheelEvent = struct {
    pub const Direction = enum(u8) {
        normal = sdl.SDL_MOUSEWHEEL_NORMAL,
        flipped = sdl.SDL_MOUSEWHEEL_FLIPPED,
    };

    timestamp: u32,
    /// originally named `windowID`
    window_id: u32,
    /// originally named `which`,
    /// if it comes from a touch input device,
    /// the value is sdl.SDL_TOUCH_MOUSEID,
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

    pub fn fromNative(native: sdl.SDL_MouseWheelEvent) MouseWheelEvent {
        assert(native.type == sdl.SDL_MOUSEWHEEL);
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
    joystick_id: sdl.SDL_JoystickID,
    axis: u8,
    value: i16,

    pub fn fromNative(native: sdl.SDL_JoyAxisEvent) JoyAxisEvent {
        switch (native.type) {
            else => unreachable,
            sdl.SDL_JOYAXISMOTION => {},
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
            @floatFromInt(sdl.SDL_JOYSTICK_AXIS_MAX)
        else
            @floatFromInt(sdl.SDL_JOYSTICK_AXIS_MIN);
        return @as(FloatType, @floatFromInt(self.value)) / @abs(denominator);
    }
};

pub const JoyHatEvent = struct {
    pub const HatValue = enum(u8) {
        centered = sdl.SDL_HAT_CENTERED,
        up = sdl.SDL_HAT_UP,
        right = sdl.SDL_HAT_RIGHT,
        down = sdl.SDL_HAT_DOWN,
        left = sdl.SDL_HAT_LEFT,
        right_up = sdl.SDL_HAT_RIGHTUP,
        right_down = sdl.SDL_HAT_RIGHTDOWN,
        left_up = sdl.SDL_HAT_LEFTUP,
        left_down = sdl.SDL_HAT_LEFTDOWN,
    };

    timestamp: u32,
    joystick_id: sdl.SDL_JoystickID,
    hat: u8,
    value: HatValue,

    pub fn fromNative(native: sdl.SDL_JoyHatEvent) JoyHatEvent {
        switch (native.type) {
            else => unreachable,
            sdl.SDL_JOYHATMOTION => {},
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
    joystick_id: sdl.SDL_JoystickID,
    ball: u8,
    relative_x: i16,
    relative_y: i16,

    pub fn fromNative(native: sdl.SDL_JoyBallEvent) JoyBallEvent {
        switch (native.type) {
            else => unreachable,
            sdl.SDL_JOYBALLMOTION => {},
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
    pub const ButtonState = enum(u8) {
        released = sdl.SDL_RELEASED,
        pressed = sdl.SDL_PRESSED,
    };

    timestamp: u32,
    joystick_id: sdl.SDL_JoystickID,
    button: u8,
    button_state: ButtonState,

    pub fn fromNative(native: sdl.SDL_JoyButtonEvent) JoyButtonEvent {
        switch (native.type) {
            else => unreachable,
            sdl.SDL_JOYBUTTONDOWN, sdl.SDL_JOYBUTTONUP => {},
        }
        return .{
            .timestamp = native.timestamp,
            .joystick_id = native.which,
            .button = native.button,
            .button_state = @enumFromInt(native.state),
        };
    }
};

pub const ControllerAxisEvent = struct {
    timestamp: u32,
    joystick_id: sdl.SDL_JoystickID,
    axis: GameController.Axis,
    value: i16,

    pub fn fromNative(native: sdl.SDL_ControllerAxisEvent) ControllerAxisEvent {
        switch (native.type) {
            else => unreachable,
            sdl.SDL_CONTROLLERAXISMOTION => {},
        }
        return .{
            .timestamp = native.timestamp,
            .joystick_id = native.which,
            .axis = @enumFromInt(native.axis),
            .value = native.value,
        };
    }

    pub fn normalizedValue(self: ControllerAxisEvent, comptime FloatType: type) FloatType {
        const denominator: FloatType = if (self.value > 0)
            @floatFromInt(sdl.SDL_JOYSTICK_AXIS_MAX)
        else
            @floatFromInt(sdl.SDL_JOYSTICK_AXIS_MIN);
        return @as(FloatType, @floatFromInt(self.value)) / @abs(denominator);
    }
};

pub const ControllerButtonEvent = struct {
    pub const ButtonState = enum(u8) {
        released = sdl.SDL_RELEASED,
        pressed = sdl.SDL_PRESSED,
    };

    timestamp: u32,
    joystick_id: sdl.SDL_JoystickID,
    button: GameController.Button,
    button_state: ButtonState,

    pub fn fromNative(native: sdl.SDL_ControllerButtonEvent) ControllerButtonEvent {
        switch (native.type) {
            else => unreachable,
            sdl.SDL_CONTROLLERBUTTONDOWN, sdl.SDL_CONTROLLERBUTTONUP => {},
        }
        return .{
            .timestamp = native.timestamp,
            .joystick_id = native.which,
            .button = @enumFromInt(native.button),
            .button_state = @enumFromInt(native.state),
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

    pub fn from(native: sdl.SDL_UserEvent) UserEvent {
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
    pub const CommonEvent = sdl.SDL_CommonEvent;
    pub const DisplayEvent = sdl.SDL_DisplayEvent;
    pub const TextEditingEvent = sdl.SDL_TextEditingEvent;
    pub const TextInputEvent = sdl.SDL_TextInputEvent;
    pub const JoyDeviceEvent = sdl.SDL_JoyDeviceEvent;
    pub const JoyBatteryEvent = sdl.SDL_JoyBatteryEvent;
    pub const ControllerDeviceEvent = sdl.SDL_ControllerDeviceEvent;
    pub const AudioDeviceEvent = sdl.SDL_AudioDeviceEvent;
    pub const SensorEvent = sdl.SDL_SensorEvent;
    pub const QuitEvent = sdl.SDL_QuitEvent;
    pub const SysWMEvent = sdl.SDL_SysWMEvent;
    pub const TouchFingerEvent = sdl.SDL_TouchFingerEvent;
    pub const MultiGestureEvent = sdl.SDL_MultiGestureEvent;
    pub const DollarGestureEvent = sdl.SDL_DollarGestureEvent;
    pub const DropEvent = sdl.SDL_DropEvent;

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
    display: DisplayEvent,
    window: WindowEvent,
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
    controller_axis_motion: ControllerAxisEvent,
    controller_button_down: ControllerButtonEvent,
    controller_button_up: ControllerButtonEvent,
    controller_device_added: ControllerDeviceEvent,
    controller_device_removed: ControllerDeviceEvent,
    controller_device_remapped: ControllerDeviceEvent,
    audio_device_added: AudioDeviceEvent,
    audio_device_removed: AudioDeviceEvent,
    sensor_update: SensorEvent,
    quit: QuitEvent,
    sys_wm: SysWMEvent,
    finger_down: TouchFingerEvent,
    finger_up: TouchFingerEvent,
    finger_motion: TouchFingerEvent,
    multi_gesture: MultiGestureEvent,
    dollar_gesture: DollarGestureEvent,
    dollar_record: DollarGestureEvent,
    drop_file: DropEvent,
    drop_text: DropEvent,
    drop_begin: DropEvent,
    drop_complete: DropEvent,
    user: UserEvent,

    pub fn from(raw: sdl.SDL_Event) Event {
        return switch (raw.type) {
            sdl.SDL_QUIT => Event{ .quit = raw.quit },
            sdl.SDL_APP_TERMINATING => Event{ .app_terminating = raw.common },
            sdl.SDL_APP_LOWMEMORY => Event{ .app_low_memory = raw.common },
            sdl.SDL_APP_WILLENTERBACKGROUND => Event{ .app_will_enter_background = raw.common },
            sdl.SDL_APP_DIDENTERBACKGROUND => Event{ .app_did_enter_background = raw.common },
            sdl.SDL_APP_WILLENTERFOREGROUND => Event{ .app_will_enter_foreground = raw.common },
            sdl.SDL_APP_DIDENTERFOREGROUND => Event{ .app_did_enter_foreground = raw.common },
            sdl.SDL_DISPLAYEVENT => Event{ .display = raw.display },
            sdl.SDL_WINDOWEVENT => Event{ .window = WindowEvent.fromNative(raw.window) },
            sdl.SDL_SYSWMEVENT => Event{ .sys_wm = raw.syswm },
            sdl.SDL_KEYDOWN => Event{ .key_down = KeyboardEvent.fromNative(raw.key) },
            sdl.SDL_KEYUP => Event{ .key_up = KeyboardEvent.fromNative(raw.key) },
            sdl.SDL_TEXTEDITING => Event{ .text_editing = raw.edit },
            sdl.SDL_TEXTINPUT => Event{ .text_input = raw.text },
            sdl.SDL_KEYMAPCHANGED => Event{ .key_map_changed = raw.common },
            sdl.SDL_MOUSEMOTION => Event{ .mouse_motion = MouseMotionEvent.fromNative(raw.motion) },
            sdl.SDL_MOUSEBUTTONDOWN => Event{ .mouse_button_down = MouseButtonEvent.fromNative(raw.button) },
            sdl.SDL_MOUSEBUTTONUP => Event{ .mouse_button_up = MouseButtonEvent.fromNative(raw.button) },
            sdl.SDL_MOUSEWHEEL => Event{ .mouse_wheel = MouseWheelEvent.fromNative(raw.wheel) },
            sdl.SDL_JOYAXISMOTION => Event{ .joy_axis_motion = JoyAxisEvent.fromNative(raw.jaxis) },
            sdl.SDL_JOYBALLMOTION => Event{ .joy_ball_motion = JoyBallEvent.fromNative(raw.jball) },
            sdl.SDL_JOYHATMOTION => Event{ .joy_hat_motion = JoyHatEvent.fromNative(raw.jhat) },
            sdl.SDL_JOYBUTTONDOWN => Event{ .joy_button_down = JoyButtonEvent.fromNative(raw.jbutton) },
            sdl.SDL_JOYBUTTONUP => Event{ .joy_button_up = JoyButtonEvent.fromNative(raw.jbutton) },
            sdl.SDL_JOYDEVICEADDED => Event{ .joy_device_added = raw.jdevice },
            sdl.SDL_JOYDEVICEREMOVED => Event{ .joy_device_removed = raw.jdevice },
            sdl.SDL_JOYBATTERYUPDATED => Event{ .joy_battery_level = raw.jbattery },
            sdl.SDL_CONTROLLERAXISMOTION => Event{ .controller_axis_motion = ControllerAxisEvent.fromNative(raw.caxis) },
            sdl.SDL_CONTROLLERBUTTONDOWN => Event{ .controller_button_down = ControllerButtonEvent.fromNative(raw.cbutton) },
            sdl.SDL_CONTROLLERBUTTONUP => Event{ .controller_button_up = ControllerButtonEvent.fromNative(raw.cbutton) },
            sdl.SDL_CONTROLLERDEVICEADDED => Event{ .controller_device_added = raw.cdevice },
            sdl.SDL_CONTROLLERDEVICEREMOVED => Event{ .controller_device_removed = raw.cdevice },
            sdl.SDL_CONTROLLERDEVICEREMAPPED => Event{ .controller_device_remapped = raw.cdevice },
            sdl.SDL_FINGERDOWN => Event{ .finger_down = raw.tfinger },
            sdl.SDL_FINGERUP => Event{ .finger_up = raw.tfinger },
            sdl.SDL_FINGERMOTION => Event{ .finger_motion = raw.tfinger },
            sdl.SDL_DOLLARGESTURE => Event{ .dollar_gesture = raw.dgesture },
            sdl.SDL_DOLLARRECORD => Event{ .dollar_record = raw.dgesture },
            sdl.SDL_MULTIGESTURE => Event{ .multi_gesture = raw.mgesture },
            sdl.SDL_CLIPBOARDUPDATE => Event{ .clip_board_update = raw.common },
            sdl.SDL_DROPFILE => Event{ .drop_file = raw.drop },
            sdl.SDL_DROPTEXT => Event{ .drop_text = raw.drop },
            sdl.SDL_DROPBEGIN => Event{ .drop_begin = raw.drop },
            sdl.SDL_DROPCOMPLETE => Event{ .drop_complete = raw.drop },
            sdl.SDL_AUDIODEVICEADDED => Event{ .audio_device_added = raw.adevice },
            sdl.SDL_AUDIODEVICEREMOVED => Event{ .audio_device_removed = raw.adevice },
            sdl.SDL_SENSORUPDATE => Event{ .sensor_update = raw.sensor },
            sdl.SDL_RENDER_TARGETS_RESET => Event{ .render_targets_reset = raw.common },
            sdl.SDL_RENDER_DEVICE_RESET => Event{ .render_device_reset = raw.common },
            else => |t| if (t >= sdl.SDL_USEREVENT)
                Event{ .user = UserEvent.from(raw.user) }
            else
                @panic("Unsupported event type detected!"),
        };
    }
};

/// register `num` user events and return the corresponding type
/// to be used when generating those.
pub fn registerEvents(num: u32) !u32 {
    const res = sdl.SDL_RegisterEvents(@intCast(num));
    if (res == std.math.maxInt(u32)) return error.CannotRegisterUserEvent;
    return res;
}

/// push a new user event in the event queue. Safe for concurrent use.
/// `ev_type` must be a value returned by `registerEvent`.
pub fn pushEvent(ev_type: u32, code: i32, data1: ?*anyopaque, data2: ?*anyopaque) !void {
    var sdl_ev = sdl.SDL_Event{
        .user = .{
            .type = ev_type,
            .timestamp = 0,
            .windowID = 0,
            .code = code,
            .data1 = data1,
            .data2 = data2,
        },
    };
    if (sdl.SDL_PushEvent(&sdl_ev) < 0) {
        return sdl.Error.SdlError;
    }
}

/// This function should only be called from
/// the thread that initialized the video subsystem.
pub fn pumpEvents() void {
    sdl.SDL_PumpEvents();
}

pub fn pollEvent() ?Event {
    var ev: sdl.SDL_Event = undefined;
    if (sdl.SDL_PollEvent(&ev) != 0)
        return Event.from(ev);
    return null;
}

pub fn pollNativeEvent() ?sdl.SDL_Event {
    var ev: sdl.SDL_Event = undefined;
    if (sdl.SDL_PollEvent(&ev) != 0)
        return ev;
    return null;
}

/// Waits indefinitely to pump a new event into the queue.
/// May not conserve energy on some systems, in some versions/situations.
/// This function should only be called from
/// the thread that initialized the video subsystem.
pub fn waitEvent() !Event {
    var ev: sdl.SDL_Event = undefined;
    if (sdl.SDL_WaitEvent(&ev) != 0)
        return Event.from(ev);
    return sdl.Error.SdlError;
}

/// Waits `timeout` milliseconds
/// to pump the next available event into the queue.
/// May not conserve energy on some systems, in some versions/situations.
/// This function should only be called from
/// the thread that initialized the video subsystem.
pub fn waitEventTimeout(timeout: usize) ?Event {
    var ev: sdl.SDL_Event = undefined;
    if (sdl.SDL_WaitEventTimeout(&ev, @intCast(timeout)) != 0)
        return Event.from(ev);
    return null;
}

pub const MouseState = struct {
    buttons: MouseButtonState,
    pos: jok.Point,
};

pub fn getMouseState() MouseState {
    var ms: MouseState = undefined;
    var x: c_int = undefined;
    var y: c_int = undefined;
    const buttons = sdl.SDL_GetMouseState(&x, &y);
    ms.buttons = MouseButtonState.fromNative(buttons);
    ms.pos = mapPositionToCanvas(.{
        .x = @floatFromInt(x),
        .y = @floatFromInt(y),
    });
    return ms;
}

pub const Scancode = enum(sdl.SDL_Scancode) {
    unknown = sdl.SDL_SCANCODE_UNKNOWN,
    a = sdl.SDL_SCANCODE_A,
    b = sdl.SDL_SCANCODE_B,
    c = sdl.SDL_SCANCODE_C,
    d = sdl.SDL_SCANCODE_D,
    e = sdl.SDL_SCANCODE_E,
    f = sdl.SDL_SCANCODE_F,
    g = sdl.SDL_SCANCODE_G,
    h = sdl.SDL_SCANCODE_H,
    i = sdl.SDL_SCANCODE_I,
    j = sdl.SDL_SCANCODE_J,
    k = sdl.SDL_SCANCODE_K,
    l = sdl.SDL_SCANCODE_L,
    m = sdl.SDL_SCANCODE_M,
    n = sdl.SDL_SCANCODE_N,
    o = sdl.SDL_SCANCODE_O,
    p = sdl.SDL_SCANCODE_P,
    q = sdl.SDL_SCANCODE_Q,
    r = sdl.SDL_SCANCODE_R,
    s = sdl.SDL_SCANCODE_S,
    t = sdl.SDL_SCANCODE_T,
    u = sdl.SDL_SCANCODE_U,
    v = sdl.SDL_SCANCODE_V,
    w = sdl.SDL_SCANCODE_W,
    x = sdl.SDL_SCANCODE_X,
    y = sdl.SDL_SCANCODE_Y,
    z = sdl.SDL_SCANCODE_Z,
    @"1" = sdl.SDL_SCANCODE_1,
    @"2" = sdl.SDL_SCANCODE_2,
    @"3" = sdl.SDL_SCANCODE_3,
    @"4" = sdl.SDL_SCANCODE_4,
    @"5" = sdl.SDL_SCANCODE_5,
    @"6" = sdl.SDL_SCANCODE_6,
    @"7" = sdl.SDL_SCANCODE_7,
    @"8" = sdl.SDL_SCANCODE_8,
    @"9" = sdl.SDL_SCANCODE_9,
    @"0" = sdl.SDL_SCANCODE_0,
    @"return" = sdl.SDL_SCANCODE_RETURN,
    escape = sdl.SDL_SCANCODE_ESCAPE,
    backspace = sdl.SDL_SCANCODE_BACKSPACE,
    tab = sdl.SDL_SCANCODE_TAB,
    space = sdl.SDL_SCANCODE_SPACE,
    minus = sdl.SDL_SCANCODE_MINUS,
    equals = sdl.SDL_SCANCODE_EQUALS,
    left_bracket = sdl.SDL_SCANCODE_LEFTBRACKET,
    right_bracket = sdl.SDL_SCANCODE_RIGHTBRACKET,
    backslash = sdl.SDL_SCANCODE_BACKSLASH,
    non_us_hash = sdl.SDL_SCANCODE_NONUSHASH,
    semicolon = sdl.SDL_SCANCODE_SEMICOLON,
    apostrophe = sdl.SDL_SCANCODE_APOSTROPHE,
    grave = sdl.SDL_SCANCODE_GRAVE,
    comma = sdl.SDL_SCANCODE_COMMA,
    period = sdl.SDL_SCANCODE_PERIOD,
    slash = sdl.SDL_SCANCODE_SLASH,
    ///capital letters lock
    caps_lock = sdl.SDL_SCANCODE_CAPSLOCK,
    f1 = sdl.SDL_SCANCODE_F1,
    f2 = sdl.SDL_SCANCODE_F2,
    f3 = sdl.SDL_SCANCODE_F3,
    f4 = sdl.SDL_SCANCODE_F4,
    f5 = sdl.SDL_SCANCODE_F5,
    f6 = sdl.SDL_SCANCODE_F6,
    f7 = sdl.SDL_SCANCODE_F7,
    f8 = sdl.SDL_SCANCODE_F8,
    f9 = sdl.SDL_SCANCODE_F9,
    f10 = sdl.SDL_SCANCODE_F10,
    f11 = sdl.SDL_SCANCODE_F11,
    f12 = sdl.SDL_SCANCODE_F12,
    print_screen = sdl.SDL_SCANCODE_PRINTSCREEN,
    scroll_lock = sdl.SDL_SCANCODE_SCROLLLOCK,
    pause = sdl.SDL_SCANCODE_PAUSE,
    insert = sdl.SDL_SCANCODE_INSERT,
    home = sdl.SDL_SCANCODE_HOME,
    page_up = sdl.SDL_SCANCODE_PAGEUP,
    delete = sdl.SDL_SCANCODE_DELETE,
    end = sdl.SDL_SCANCODE_END,
    page_down = sdl.SDL_SCANCODE_PAGEDOWN,
    right = sdl.SDL_SCANCODE_RIGHT,
    left = sdl.SDL_SCANCODE_LEFT,
    down = sdl.SDL_SCANCODE_DOWN,
    up = sdl.SDL_SCANCODE_UP,
    ///numeric lock, "Clear" key on Apple keyboards
    num_lock_clear = sdl.SDL_SCANCODE_NUMLOCKCLEAR,
    keypad_divide = sdl.SDL_SCANCODE_KP_DIVIDE,
    keypad_multiply = sdl.SDL_SCANCODE_KP_MULTIPLY,
    keypad_minus = sdl.SDL_SCANCODE_KP_MINUS,
    keypad_plus = sdl.SDL_SCANCODE_KP_PLUS,
    keypad_enter = sdl.SDL_SCANCODE_KP_ENTER,
    keypad_1 = sdl.SDL_SCANCODE_KP_1,
    keypad_2 = sdl.SDL_SCANCODE_KP_2,
    keypad_3 = sdl.SDL_SCANCODE_KP_3,
    keypad_4 = sdl.SDL_SCANCODE_KP_4,
    keypad_5 = sdl.SDL_SCANCODE_KP_5,
    keypad_6 = sdl.SDL_SCANCODE_KP_6,
    keypad_7 = sdl.SDL_SCANCODE_KP_7,
    keypad_8 = sdl.SDL_SCANCODE_KP_8,
    keypad_9 = sdl.SDL_SCANCODE_KP_9,
    keypad_0 = sdl.SDL_SCANCODE_KP_0,
    keypad_period = sdl.SDL_SCANCODE_KP_PERIOD,
    non_us_backslash = sdl.SDL_SCANCODE_NONUSBACKSLASH,
    application = sdl.SDL_SCANCODE_APPLICATION,
    power = sdl.SDL_SCANCODE_POWER,
    keypad_equals = sdl.SDL_SCANCODE_KP_EQUALS,
    f13 = sdl.SDL_SCANCODE_F13,
    f14 = sdl.SDL_SCANCODE_F14,
    f15 = sdl.SDL_SCANCODE_F15,
    f16 = sdl.SDL_SCANCODE_F16,
    f17 = sdl.SDL_SCANCODE_F17,
    f18 = sdl.SDL_SCANCODE_F18,
    f19 = sdl.SDL_SCANCODE_F19,
    f20 = sdl.SDL_SCANCODE_F20,
    f21 = sdl.SDL_SCANCODE_F21,
    f22 = sdl.SDL_SCANCODE_F22,
    f23 = sdl.SDL_SCANCODE_F23,
    f24 = sdl.SDL_SCANCODE_F24,
    execute = sdl.SDL_SCANCODE_EXECUTE,
    help = sdl.SDL_SCANCODE_HELP,
    menu = sdl.SDL_SCANCODE_MENU,
    select = sdl.SDL_SCANCODE_SELECT,
    stop = sdl.SDL_SCANCODE_STOP,
    again = sdl.SDL_SCANCODE_AGAIN,
    undo = sdl.SDL_SCANCODE_UNDO,
    cut = sdl.SDL_SCANCODE_CUT,
    copy = sdl.SDL_SCANCODE_COPY,
    paste = sdl.SDL_SCANCODE_PASTE,
    find = sdl.SDL_SCANCODE_FIND,
    mute = sdl.SDL_SCANCODE_MUTE,
    volume_up = sdl.SDL_SCANCODE_VOLUMEUP,
    volume_down = sdl.SDL_SCANCODE_VOLUMEDOWN,
    keypad_comma = sdl.SDL_SCANCODE_KP_COMMA,
    keypad_equals_as_400 = sdl.SDL_SCANCODE_KP_EQUALSAS400,
    international_1 = sdl.SDL_SCANCODE_INTERNATIONAL1,
    international_2 = sdl.SDL_SCANCODE_INTERNATIONAL2,
    international_3 = sdl.SDL_SCANCODE_INTERNATIONAL3,
    international_4 = sdl.SDL_SCANCODE_INTERNATIONAL4,
    international_5 = sdl.SDL_SCANCODE_INTERNATIONAL5,
    international_6 = sdl.SDL_SCANCODE_INTERNATIONAL6,
    international_7 = sdl.SDL_SCANCODE_INTERNATIONAL7,
    international_8 = sdl.SDL_SCANCODE_INTERNATIONAL8,
    international_9 = sdl.SDL_SCANCODE_INTERNATIONAL9,
    language_1 = sdl.SDL_SCANCODE_LANG1,
    language_2 = sdl.SDL_SCANCODE_LANG2,
    language_3 = sdl.SDL_SCANCODE_LANG3,
    language_4 = sdl.SDL_SCANCODE_LANG4,
    language_5 = sdl.SDL_SCANCODE_LANG5,
    language_6 = sdl.SDL_SCANCODE_LANG6,
    language_7 = sdl.SDL_SCANCODE_LANG7,
    language_8 = sdl.SDL_SCANCODE_LANG8,
    language_9 = sdl.SDL_SCANCODE_LANG9,
    alternate_erase = sdl.SDL_SCANCODE_ALTERASE,
    ///aka "Attention"
    system_request = sdl.SDL_SCANCODE_SYSREQ,
    cancel = sdl.SDL_SCANCODE_CANCEL,
    clear = sdl.SDL_SCANCODE_CLEAR,
    prior = sdl.SDL_SCANCODE_PRIOR,
    return_2 = sdl.SDL_SCANCODE_RETURN2,
    separator = sdl.SDL_SCANCODE_SEPARATOR,
    out = sdl.SDL_SCANCODE_OUT,
    ///Don't know what this stands for, operator? operation? operating system? Couldn't find it anywhere.
    oper = sdl.SDL_SCANCODE_OPER,
    ///technically named "Clear/Again"
    clear_again = sdl.SDL_SCANCODE_CLEARAGAIN,
    ///aka "CrSel/Props" (properties)
    cursor_selection = sdl.SDL_SCANCODE_CRSEL,
    extend_selection = sdl.SDL_SCANCODE_EXSEL,
    keypad_00 = sdl.SDL_SCANCODE_KP_00,
    keypad_000 = sdl.SDL_SCANCODE_KP_000,
    thousands_separator = sdl.SDL_SCANCODE_THOUSANDSSEPARATOR,
    decimal_separator = sdl.SDL_SCANCODE_DECIMALSEPARATOR,
    currency_unit = sdl.SDL_SCANCODE_CURRENCYUNIT,
    currency_subunit = sdl.SDL_SCANCODE_CURRENCYSUBUNIT,
    keypad_left_parenthesis = sdl.SDL_SCANCODE_KP_LEFTPAREN,
    keypad_right_parenthesis = sdl.SDL_SCANCODE_KP_RIGHTPAREN,
    keypad_left_brace = sdl.SDL_SCANCODE_KP_LEFTBRACE,
    keypad_right_brace = sdl.SDL_SCANCODE_KP_RIGHTBRACE,
    keypad_tab = sdl.SDL_SCANCODE_KP_TAB,
    keypad_backspace = sdl.SDL_SCANCODE_KP_BACKSPACE,
    keypad_a = sdl.SDL_SCANCODE_KP_A,
    keypad_b = sdl.SDL_SCANCODE_KP_B,
    keypad_c = sdl.SDL_SCANCODE_KP_C,
    keypad_d = sdl.SDL_SCANCODE_KP_D,
    keypad_e = sdl.SDL_SCANCODE_KP_E,
    keypad_f = sdl.SDL_SCANCODE_KP_F,
    ///keypad exclusive or
    keypad_xor = sdl.SDL_SCANCODE_KP_XOR,
    keypad_power = sdl.SDL_SCANCODE_KP_POWER,
    keypad_percent = sdl.SDL_SCANCODE_KP_PERCENT,
    keypad_less = sdl.SDL_SCANCODE_KP_LESS,
    keypad_greater = sdl.SDL_SCANCODE_KP_GREATER,
    keypad_ampersand = sdl.SDL_SCANCODE_KP_AMPERSAND,
    keypad_double_ampersand = sdl.SDL_SCANCODE_KP_DBLAMPERSAND,
    keypad_vertical_bar = sdl.SDL_SCANCODE_KP_VERTICALBAR,
    keypad_double_vertical_bar = sdl.SDL_SCANCODE_KP_DBLVERTICALBAR,
    keypad_colon = sdl.SDL_SCANCODE_KP_COLON,
    keypad_hash = sdl.SDL_SCANCODE_KP_HASH,
    keypad_space = sdl.SDL_SCANCODE_KP_SPACE,
    keypad_at_sign = sdl.SDL_SCANCODE_KP_AT,
    keypad_exclamation_mark = sdl.SDL_SCANCODE_KP_EXCLAM,
    keypad_memory_store = sdl.SDL_SCANCODE_KP_MEMSTORE,
    keypad_memory_recall = sdl.SDL_SCANCODE_KP_MEMRECALL,
    keypad_memory_clear = sdl.SDL_SCANCODE_KP_MEMCLEAR,
    keypad_memory_add = sdl.SDL_SCANCODE_KP_MEMADD,
    keypad_memory_subtract = sdl.SDL_SCANCODE_KP_MEMSUBTRACT,
    keypad_memory_multiply = sdl.SDL_SCANCODE_KP_MEMMULTIPLY,
    keypad_memory_divide = sdl.SDL_SCANCODE_KP_MEMDIVIDE,
    keypad_plus_minus = sdl.SDL_SCANCODE_KP_PLUSMINUS,
    keypad_clear = sdl.SDL_SCANCODE_KP_CLEAR,
    keypad_clear_entry = sdl.SDL_SCANCODE_KP_CLEARENTRY,
    keypad_binary = sdl.SDL_SCANCODE_KP_BINARY,
    keypad_octal = sdl.SDL_SCANCODE_KP_OCTAL,
    keypad_decimal = sdl.SDL_SCANCODE_KP_DECIMAL,
    keypad_hexadecimal = sdl.SDL_SCANCODE_KP_HEXADECIMAL,
    left_control = sdl.SDL_SCANCODE_LCTRL,
    left_shift = sdl.SDL_SCANCODE_LSHIFT,
    ///left alternate
    left_alt = sdl.SDL_SCANCODE_LALT,
    left_gui = sdl.SDL_SCANCODE_LGUI,
    right_control = sdl.SDL_SCANCODE_RCTRL,
    right_shift = sdl.SDL_SCANCODE_RSHIFT,
    ///right alternate
    right_alt = sdl.SDL_SCANCODE_RALT,
    right_gui = sdl.SDL_SCANCODE_RGUI,
    mode = sdl.SDL_SCANCODE_MODE,
    audio_next = sdl.SDL_SCANCODE_AUDIONEXT,
    audio_previous = sdl.SDL_SCANCODE_AUDIOPREV,
    audio_stop = sdl.SDL_SCANCODE_AUDIOSTOP,
    audio_play = sdl.SDL_SCANCODE_AUDIOPLAY,
    audio_mute = sdl.SDL_SCANCODE_AUDIOMUTE,
    media_select = sdl.SDL_SCANCODE_MEDIASELECT,
    www = sdl.SDL_SCANCODE_WWW,
    mail = sdl.SDL_SCANCODE_MAIL,
    calculator = sdl.SDL_SCANCODE_CALCULATOR,
    computer = sdl.SDL_SCANCODE_COMPUTER,
    application_control_search = sdl.SDL_SCANCODE_AC_SEARCH,
    application_control_home = sdl.SDL_SCANCODE_AC_HOME,
    application_control_back = sdl.SDL_SCANCODE_AC_BACK,
    application_control_forward = sdl.SDL_SCANCODE_AC_FORWARD,
    application_control_stop = sdl.SDL_SCANCODE_AC_STOP,
    application_control_refresh = sdl.SDL_SCANCODE_AC_REFRESH,
    application_control_bookmarks = sdl.SDL_SCANCODE_AC_BOOKMARKS,
    brightness_down = sdl.SDL_SCANCODE_BRIGHTNESSDOWN,
    brightness_up = sdl.SDL_SCANCODE_BRIGHTNESSUP,
    display_switch = sdl.SDL_SCANCODE_DISPLAYSWITCH,
    keyboard_illumination_toggle = sdl.SDL_SCANCODE_KBDILLUMTOGGLE,
    keyboard_illumination_down = sdl.SDL_SCANCODE_KBDILLUMDOWN,
    keyboard_illumination_up = sdl.SDL_SCANCODE_KBDILLUMUP,
    eject = sdl.SDL_SCANCODE_EJECT,
    sleep = sdl.SDL_SCANCODE_SLEEP,
    application_1 = sdl.SDL_SCANCODE_APP1,
    application_2 = sdl.SDL_SCANCODE_APP2,
    audio_rewind = sdl.SDL_SCANCODE_AUDIOREWIND,
    audio_fast_forward = sdl.SDL_SCANCODE_AUDIOFASTFORWARD,
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
    const slice = sdl.SDL_GetKeyboardState(&len);
    return KeyboardState{
        .states = slice[0..@intCast(len)],
    };
}
pub const getModState = getKeyboardModifierState;
pub fn getKeyboardModifierState() KeyModifierSet {
    return KeyModifierSet.fromNative(@intCast(sdl.SDL_GetModState()));
}

pub const Keycode = enum(sdl.SDL_Keycode) {
    unknown = sdl.SDLK_UNKNOWN,
    @"return" = sdl.SDLK_RETURN,
    escape = sdl.SDLK_ESCAPE,
    backspace = sdl.SDLK_BACKSPACE,
    tab = sdl.SDLK_TAB,
    space = sdl.SDLK_SPACE,
    exclamation_mark = sdl.SDLK_EXCLAIM,
    quote = sdl.SDLK_QUOTEDBL,
    hash = sdl.SDLK_HASH,
    percent = sdl.SDLK_PERCENT,
    dollar = sdl.SDLK_DOLLAR,
    ampersand = sdl.SDLK_AMPERSAND,
    apostrophe = sdl.SDLK_QUOTE,
    left_parenthesis = sdl.SDLK_LEFTPAREN,
    right_parenthesis = sdl.SDLK_RIGHTPAREN,
    asterisk = sdl.SDLK_ASTERISK,
    plus = sdl.SDLK_PLUS,
    comma = sdl.SDLK_COMMA,
    minus = sdl.SDLK_MINUS,
    period = sdl.SDLK_PERIOD,
    slash = sdl.SDLK_SLASH,
    @"0" = sdl.SDLK_0,
    @"1" = sdl.SDLK_1,
    @"2" = sdl.SDLK_2,
    @"3" = sdl.SDLK_3,
    @"4" = sdl.SDLK_4,
    @"5" = sdl.SDLK_5,
    @"6" = sdl.SDLK_6,
    @"7" = sdl.SDLK_7,
    @"8" = sdl.SDLK_8,
    @"9" = sdl.SDLK_9,
    colon = sdl.SDLK_COLON,
    semicolon = sdl.SDLK_SEMICOLON,
    less = sdl.SDLK_LESS,
    equals = sdl.SDLK_EQUALS,
    greater = sdl.SDLK_GREATER,
    question_mark = sdl.SDLK_QUESTION,
    at_sign = sdl.SDLK_AT,
    left_bracket = sdl.SDLK_LEFTBRACKET,
    backslash = sdl.SDLK_BACKSLASH,
    right_bracket = sdl.SDLK_RIGHTBRACKET,
    caret = sdl.SDLK_CARET,
    underscore = sdl.SDLK_UNDERSCORE,
    grave = sdl.SDLK_BACKQUOTE,
    a = sdl.SDLK_a,
    b = sdl.SDLK_b,
    c = sdl.SDLK_c,
    d = sdl.SDLK_d,
    e = sdl.SDLK_e,
    f = sdl.SDLK_f,
    g = sdl.SDLK_g,
    h = sdl.SDLK_h,
    i = sdl.SDLK_i,
    j = sdl.SDLK_j,
    k = sdl.SDLK_k,
    l = sdl.SDLK_l,
    m = sdl.SDLK_m,
    n = sdl.SDLK_n,
    o = sdl.SDLK_o,
    p = sdl.SDLK_p,
    q = sdl.SDLK_q,
    r = sdl.SDLK_r,
    s = sdl.SDLK_s,
    t = sdl.SDLK_t,
    u = sdl.SDLK_u,
    v = sdl.SDLK_v,
    w = sdl.SDLK_w,
    x = sdl.SDLK_x,
    y = sdl.SDLK_y,
    z = sdl.SDLK_z,
    ///capital letters lock
    caps_lock = sdl.SDLK_CAPSLOCK,
    f1 = sdl.SDLK_F1,
    f2 = sdl.SDLK_F2,
    f3 = sdl.SDLK_F3,
    f4 = sdl.SDLK_F4,
    f5 = sdl.SDLK_F5,
    f6 = sdl.SDLK_F6,
    f7 = sdl.SDLK_F7,
    f8 = sdl.SDLK_F8,
    f9 = sdl.SDLK_F9,
    f10 = sdl.SDLK_F10,
    f11 = sdl.SDLK_F11,
    f12 = sdl.SDLK_F12,
    print_screen = sdl.SDLK_PRINTSCREEN,
    scroll_lock = sdl.SDLK_SCROLLLOCK,
    pause = sdl.SDLK_PAUSE,
    insert = sdl.SDLK_INSERT,
    home = sdl.SDLK_HOME,
    page_up = sdl.SDLK_PAGEUP,
    delete = sdl.SDLK_DELETE,
    end = sdl.SDLK_END,
    page_down = sdl.SDLK_PAGEDOWN,
    right = sdl.SDLK_RIGHT,
    left = sdl.SDLK_LEFT,
    down = sdl.SDLK_DOWN,
    up = sdl.SDLK_UP,
    ///numeric lock, "Clear" key on Apple keyboards
    num_lock_clear = sdl.SDLK_NUMLOCKCLEAR,
    keypad_divide = sdl.SDLK_KP_DIVIDE,
    keypad_multiply = sdl.SDLK_KP_MULTIPLY,
    keypad_minus = sdl.SDLK_KP_MINUS,
    keypad_plus = sdl.SDLK_KP_PLUS,
    keypad_enter = sdl.SDLK_KP_ENTER,
    keypad_1 = sdl.SDLK_KP_1,
    keypad_2 = sdl.SDLK_KP_2,
    keypad_3 = sdl.SDLK_KP_3,
    keypad_4 = sdl.SDLK_KP_4,
    keypad_5 = sdl.SDLK_KP_5,
    keypad_6 = sdl.SDLK_KP_6,
    keypad_7 = sdl.SDLK_KP_7,
    keypad_8 = sdl.SDLK_KP_8,
    keypad_9 = sdl.SDLK_KP_9,
    keypad_0 = sdl.SDLK_KP_0,
    keypad_period = sdl.SDLK_KP_PERIOD,
    application = sdl.SDLK_APPLICATION,
    power = sdl.SDLK_POWER,
    keypad_equals = sdl.SDLK_KP_EQUALS,
    f13 = sdl.SDLK_F13,
    f14 = sdl.SDLK_F14,
    f15 = sdl.SDLK_F15,
    f16 = sdl.SDLK_F16,
    f17 = sdl.SDLK_F17,
    f18 = sdl.SDLK_F18,
    f19 = sdl.SDLK_F19,
    f20 = sdl.SDLK_F20,
    f21 = sdl.SDLK_F21,
    f22 = sdl.SDLK_F22,
    f23 = sdl.SDLK_F23,
    f24 = sdl.SDLK_F24,
    execute = sdl.SDLK_EXECUTE,
    help = sdl.SDLK_HELP,
    menu = sdl.SDLK_MENU,
    select = sdl.SDLK_SELECT,
    stop = sdl.SDLK_STOP,
    again = sdl.SDLK_AGAIN,
    undo = sdl.SDLK_UNDO,
    cut = sdl.SDLK_CUT,
    copy = sdl.SDLK_COPY,
    paste = sdl.SDLK_PASTE,
    find = sdl.SDLK_FIND,
    mute = sdl.SDLK_MUTE,
    volume_up = sdl.SDLK_VOLUMEUP,
    volume_down = sdl.SDLK_VOLUMEDOWN,
    keypad_comma = sdl.SDLK_KP_COMMA,
    keypad_equals_as_400 = sdl.SDLK_KP_EQUALSAS400,
    alternate_erase = sdl.SDLK_ALTERASE,
    ///aka "Attention"
    system_request = sdl.SDLK_SYSREQ,
    cancel = sdl.SDLK_CANCEL,
    clear = sdl.SDLK_CLEAR,
    prior = sdl.SDLK_PRIOR,
    return_2 = sdl.SDLK_RETURN2,
    separator = sdl.SDLK_SEPARATOR,
    out = sdl.SDLK_OUT,
    ///Don't know what this stands for, operator? operation? operating system? Couldn't find it anywhere.
    oper = sdl.SDLK_OPER,
    ///technically named "Clear/Again"
    clear_again = sdl.SDLK_CLEARAGAIN,
    ///aka "CrSel/Props" (properties)
    cursor_selection = sdl.SDLK_CRSEL,
    extend_selection = sdl.SDLK_EXSEL,
    keypad_00 = sdl.SDLK_KP_00,
    keypad_000 = sdl.SDLK_KP_000,
    thousands_separator = sdl.SDLK_THOUSANDSSEPARATOR,
    decimal_separator = sdl.SDLK_DECIMALSEPARATOR,
    currency_unit = sdl.SDLK_CURRENCYUNIT,
    currency_subunit = sdl.SDLK_CURRENCYSUBUNIT,
    keypad_left_parenthesis = sdl.SDLK_KP_LEFTPAREN,
    keypad_right_parenthesis = sdl.SDLK_KP_RIGHTPAREN,
    keypad_left_brace = sdl.SDLK_KP_LEFTBRACE,
    keypad_right_brace = sdl.SDLK_KP_RIGHTBRACE,
    keypad_tab = sdl.SDLK_KP_TAB,
    keypad_backspace = sdl.SDLK_KP_BACKSPACE,
    keypad_a = sdl.SDLK_KP_A,
    keypad_b = sdl.SDLK_KP_B,
    keypad_c = sdl.SDLK_KP_C,
    keypad_d = sdl.SDLK_KP_D,
    keypad_e = sdl.SDLK_KP_E,
    keypad_f = sdl.SDLK_KP_F,
    ///keypad exclusive or
    keypad_xor = sdl.SDLK_KP_XOR,
    keypad_power = sdl.SDLK_KP_POWER,
    keypad_percent = sdl.SDLK_KP_PERCENT,
    keypad_less = sdl.SDLK_KP_LESS,
    keypad_greater = sdl.SDLK_KP_GREATER,
    keypad_ampersand = sdl.SDLK_KP_AMPERSAND,
    keypad_double_ampersand = sdl.SDLK_KP_DBLAMPERSAND,
    keypad_vertical_bar = sdl.SDLK_KP_VERTICALBAR,
    keypad_double_vertical_bar = sdl.SDLK_KP_DBLVERTICALBAR,
    keypad_colon = sdl.SDLK_KP_COLON,
    keypad_hash = sdl.SDLK_KP_HASH,
    keypad_space = sdl.SDLK_KP_SPACE,
    keypad_at_sign = sdl.SDLK_KP_AT,
    keypad_exclamation_mark = sdl.SDLK_KP_EXCLAM,
    keypad_memory_store = sdl.SDLK_KP_MEMSTORE,
    keypad_memory_recall = sdl.SDLK_KP_MEMRECALL,
    keypad_memory_clear = sdl.SDLK_KP_MEMCLEAR,
    keypad_memory_add = sdl.SDLK_KP_MEMADD,
    keypad_memory_subtract = sdl.SDLK_KP_MEMSUBTRACT,
    keypad_memory_multiply = sdl.SDLK_KP_MEMMULTIPLY,
    keypad_memory_divide = sdl.SDLK_KP_MEMDIVIDE,
    keypad_plus_minus = sdl.SDLK_KP_PLUSMINUS,
    keypad_clear = sdl.SDLK_KP_CLEAR,
    keypad_clear_entry = sdl.SDLK_KP_CLEARENTRY,
    keypad_binary = sdl.SDLK_KP_BINARY,
    keypad_octal = sdl.SDLK_KP_OCTAL,
    keypad_decimal = sdl.SDLK_KP_DECIMAL,
    keypad_hexadecimal = sdl.SDLK_KP_HEXADECIMAL,
    left_control = sdl.SDLK_LCTRL,
    left_shift = sdl.SDLK_LSHIFT,
    ///left alternate
    left_alt = sdl.SDLK_LALT,
    left_gui = sdl.SDLK_LGUI,
    right_control = sdl.SDLK_RCTRL,
    right_shift = sdl.SDLK_RSHIFT,
    ///right alternate
    right_alt = sdl.SDLK_RALT,
    right_gui = sdl.SDLK_RGUI,
    mode = sdl.SDLK_MODE,
    audio_next = sdl.SDLK_AUDIONEXT,
    audio_previous = sdl.SDLK_AUDIOPREV,
    audio_stop = sdl.SDLK_AUDIOSTOP,
    audio_play = sdl.SDLK_AUDIOPLAY,
    audio_mute = sdl.SDLK_AUDIOMUTE,
    media_select = sdl.SDLK_MEDIASELECT,
    www = sdl.SDLK_WWW,
    mail = sdl.SDLK_MAIL,
    calculator = sdl.SDLK_CALCULATOR,
    computer = sdl.SDLK_COMPUTER,
    application_control_search = sdl.SDLK_AC_SEARCH,
    application_control_home = sdl.SDLK_AC_HOME,
    application_control_back = sdl.SDLK_AC_BACK,
    application_control_forward = sdl.SDLK_AC_FORWARD,
    application_control_stop = sdl.SDLK_AC_STOP,
    application_control_refresh = sdl.SDLK_AC_REFRESH,
    application_control_bookmarks = sdl.SDLK_AC_BOOKMARKS,
    brightness_down = sdl.SDLK_BRIGHTNESSDOWN,
    brightness_up = sdl.SDLK_BRIGHTNESSUP,
    display_switch = sdl.SDLK_DISPLAYSWITCH,
    keyboard_illumination_toggle = sdl.SDLK_KBDILLUMTOGGLE,
    keyboard_illumination_down = sdl.SDLK_KBDILLUMDOWN,
    keyboard_illumination_up = sdl.SDLK_KBDILLUMUP,
    eject = sdl.SDLK_EJECT,
    sleep = sdl.SDLK_SLEEP,
    application_1 = sdl.SDLK_APP1,
    application_2 = sdl.SDLK_APP2,
    audio_rewind = sdl.SDLK_AUDIOREWIND,
    audio_fast_forward = sdl.SDLK_AUDIOFASTFORWARD,
    _,
};

pub const Clipboard = struct {
    pub fn get() !?[]const u8 {
        if (sdl.SDL_HasClipboardText() == sdl.SDL_FALSE)
            return null;
        const c_string = sdl.SDL_GetClipboardText();
        const txt = std.mem.sliceTo(c_string, 0);
        if (txt.len == 0) {
            sdl.SDL_free(c_string);
            return sdl.Error.SdlError;
        }
        return txt;
    }
    /// free is to be called with a previously fetched clipboard content
    pub fn free(txt: []const u8) void {
        sdl.SDL_free(@ptrCast(txt));
    }
    pub fn set(txt: []const u8) !void {
        if (sdl.SDL_SetClipboardText(@ptrCast(txt)) != 0) {
            return sdl.Error.SdlError;
        }
    }
};

pub fn getTicks() u32 {
    return sdl.SDL_GetTicks();
}

pub fn getTicks64() u64 {
    return sdl.SDL_GetTicks64();
}

pub fn delay(ms: u32) void {
    sdl.SDL_Delay(ms);
}

test "platform independent declarations" {
    std.testing.refAllDecls(@This());
}

pub fn numJoysticks() !u31 {
    const num = sdl.SDL_NumJoysticks();
    if (num < 0) return error.SdlError;
    return @intCast(num);
}

pub const GameController = struct {
    ptr: *sdl.SDL_GameController,

    pub fn open(joystick_index: u31) !GameController {
        return GameController{
            .ptr = sdl.SDL_GameControllerOpen(joystick_index) orelse return error.SdlError,
        };
    }

    pub fn is(joystick_index: u31) bool {
        return sdl.SDL_IsGameController(joystick_index) > 0;
    }

    pub fn close(self: GameController) void {
        sdl.SDL_GameControllerClose(self.ptr);
    }

    pub fn nameForIndex(joystick_index: u31) []const u8 {
        return std.mem.sliceTo(sdl.SDL_GameControllerNameForIndex(joystick_index), 0);
    }

    pub fn getButton(self: GameController, button: Button) u8 {
        return sdl.SDL_GameControllerGetButton(self.ptr, @intFromEnum(button));
    }

    pub fn getAxis(self: GameController, axis: Axis) i16 {
        return sdl.SDL_GameControllerGetAxis(self.ptr, @intFromEnum(axis));
    }

    pub fn getAxisNormalized(self: GameController, axis: Axis) f32 {
        return @as(f32, @floatFromInt(self.getAxis(axis))) / @as(f32, @floatFromInt(sdl.SDL_JOYSTICK_AXIS_MAX));
    }

    pub fn instanceId(self: GameController) sdl.SDL_JoystickID {
        return sdl.SDL_JoystickInstanceID(sdl.SDL_GameControllerGetJoystick(self.ptr));
    }

    pub const Button = enum(i32) {
        a = sdl.SDL_CONTROLLER_BUTTON_A,
        b = sdl.SDL_CONTROLLER_BUTTON_B,
        x = sdl.SDL_CONTROLLER_BUTTON_X,
        y = sdl.SDL_CONTROLLER_BUTTON_Y,
        back = sdl.SDL_CONTROLLER_BUTTON_BACK,
        guide = sdl.SDL_CONTROLLER_BUTTON_GUIDE,
        start = sdl.SDL_CONTROLLER_BUTTON_START,
        left_stick = sdl.SDL_CONTROLLER_BUTTON_LEFTSTICK,
        right_stick = sdl.SDL_CONTROLLER_BUTTON_RIGHTSTICK,
        left_shoulder = sdl.SDL_CONTROLLER_BUTTON_LEFTSHOULDER,
        right_shoulder = sdl.SDL_CONTROLLER_BUTTON_RIGHTSHOULDER,
        dpad_up = sdl.SDL_CONTROLLER_BUTTON_DPAD_UP,
        dpad_down = sdl.SDL_CONTROLLER_BUTTON_DPAD_DOWN,
        dpad_left = sdl.SDL_CONTROLLER_BUTTON_DPAD_LEFT,
        dpad_right = sdl.SDL_CONTROLLER_BUTTON_DPAD_RIGHT,
        /// Xbox Series X share button, PS5 microphone button, Nintendo Switch Pro capture button, Amazon Luna microphone button
        misc_1 = sdl.SDL_CONTROLLER_BUTTON_MISC1,
        /// Xbox Elite paddle P1
        paddle_1 = sdl.SDL_CONTROLLER_BUTTON_PADDLE1,
        /// Xbox Elite paddle P2
        paddle_2 = sdl.SDL_CONTROLLER_BUTTON_PADDLE2,
        /// Xbox Elite paddle P3
        paddle_3 = sdl.SDL_CONTROLLER_BUTTON_PADDLE3,
        /// Xbox Elite paddle P4
        paddle_4 = sdl.SDL_CONTROLLER_BUTTON_PADDLE4,
        /// PS4/PS5 touchpad button
        touchpad = sdl.SDL_CONTROLLER_BUTTON_TOUCHPAD,
    };

    pub const Axis = enum(i32) {
        left_x = sdl.SDL_CONTROLLER_AXIS_LEFTX,
        left_y = sdl.SDL_CONTROLLER_AXIS_LEFTY,
        right_x = sdl.SDL_CONTROLLER_AXIS_RIGHTX,
        right_y = sdl.SDL_CONTROLLER_AXIS_RIGHTY,
        trigger_left = sdl.SDL_CONTROLLER_AXIS_TRIGGERLEFT,
        trigger_right = sdl.SDL_CONTROLLER_AXIS_TRIGGERRIGHT,
    };
};

var ctx: jok.Context = undefined;

pub fn init(_ctx: jok.Context) void {
    ctx = _ctx;
}

inline fn getCanvasScale() f32 {
    const canvas_size = ctx.getCanvasSize();
    const canvas_area = ctx.getCanvasArea();
    return @as(f32, @floatFromInt(canvas_size.width)) / canvas_area.width;
}

inline fn mapPositionToCanvas(pos: jok.Point) jok.Point {
    const canvas_size = ctx.getCanvasSize();
    const canvas_area = ctx.getCanvasArea();
    const canvas_scale = @as(f32, @floatFromInt(canvas_size.width)) / canvas_area.width;
    return .{
        .x = @round((pos.x - canvas_area.x) * canvas_scale),
        .y = @round((pos.y - canvas_area.y) * canvas_scale),
    };
}
