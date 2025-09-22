const std = @import("std");
const assert = std.debug.assert;
const jok = @import("jok.zig");
const sdl = jok.sdl;

pub const KeyModifierBit = enum(u16) {
    left_shift = sdl.SDL_KMOD_LSHIFT,
    right_shift = sdl.SDL_KMOD_RSHIFT,
    left_control = sdl.SDL_KMOD_LCTRL,
    right_control = sdl.SDL_KMOD_RCTRL,
    ///left alternate
    left_alt = sdl.SDL_KMOD_LALT,
    ///right alternate
    right_alt = sdl.SDL_KMOD_RALT,
    left_gui = sdl.SDL_KMOD_LGUI,
    right_gui = sdl.SDL_KMOD_RGUI,
    ///numeric lock
    num_lock = sdl.SDL_KMOD_NUM,
    ///capital letters lock
    caps_lock = sdl.SDL_KMOD_CAPS,
    mode = sdl.SDL_KMOD_MODE,
    ///scroll lock (= previous value sdl.KMOD_RESERVED)
    scroll_lock = sdl.SDL_KMOD_SCROLL,
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
    timestamp: u64,
    window_id: u32,
    is_down: bool,
    is_repeat: bool,
    scancode: Scancode,
    keycode: Keycode,
    modifiers: KeyModifierSet,

    pub fn fromNative(native: sdl.SDL_KeyboardEvent) KeyboardEvent {
        switch (native.type) {
            else => unreachable,
            sdl.SDL_EVENT_KEY_DOWN, sdl.SDL_EVENT_KEY_UP => {},
        }
        return .{
            .timestamp = native.timestamp,
            .window_id = native.windowID,
            .is_down = native.down,
            .is_repeat = native.repeat,
            .scancode = @enumFromInt(native.scancode),
            .keycode = @enumFromInt(native.key),
            .modifiers = KeyModifierSet.fromNative(native.mod),
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
    timestamp: u64,
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

    pub fn fromNative(native: sdl.SDL_MouseMotionEvent, ctx: jok.Context) MouseMotionEvent {
        assert(native.type == sdl.SDL_EVENT_MOUSE_MOTION);
        const pos = mapPositionToCanvas(ctx, .{
            .x = native.x,
            .y = native.y,
        });
        const canvas_scale = getCanvasScale(ctx);
        const delta_x = native.xrel * canvas_scale;
        const delta_y = native.yrel * canvas_scale;
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
    timestamp: u64,
    /// originally named `windowID`
    window_id: u32,
    /// originally named `which`,
    /// if it comes from a touch input device,
    /// the value is sdl.SDL_TOUCH_MOUSEID,
    /// in which case a TouchFingerEvent was also generated.
    mouse_instance_id: u32,
    button: MouseButton,
    is_down: bool,
    clicks: u8,
    pos: jok.Point,

    pub fn fromNative(native: sdl.SDL_MouseButtonEvent, ctx: jok.Context) MouseButtonEvent {
        switch (native.type) {
            else => unreachable,
            sdl.SDL_EVENT_MOUSE_BUTTON_DOWN, sdl.SDL_EVENT_MOUSE_BUTTON_UP => {},
        }
        const pos = mapPositionToCanvas(ctx, .{
            .x = native.x,
            .y = native.y,
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
        normal = sdl.SDL_MOUSEWHEEL_NORMAL,
        flipped = sdl.SDL_MOUSEWHEEL_FLIPPED,
    };

    timestamp: u64,
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
    delta_x: f32,
    /// originally named `y`,
    /// the amount scrolled vertically,
    /// positive away from the user and negative towards the user,
    /// unless field `direction` has value `.flipped`,
    /// in which case the signs are reversed.
    delta_y: f32,
    /// On macOS, devices are often by default configured to have
    /// "natural" scrolling direction, which flips the sign of both delta values.
    /// In this case, this field will have value `.flipped` instead of `.normal`.
    direction: Direction,

    pub fn fromNative(native: sdl.SDL_MouseWheelEvent) MouseWheelEvent {
        assert(native.type == sdl.SDL_EVENT_MOUSE_WHEEL);
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
    timestamp: u64,
    joystick_id: sdl.SDL_JoystickID,
    axis: u8,
    value: i16,

    pub fn fromNative(native: sdl.SDL_JoyAxisEvent) JoyAxisEvent {
        switch (native.type) {
            else => unreachable,
            sdl.SDL_EVENT_JOYSTICK_AXIS_MOTION => {},
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

    timestamp: u64,
    joystick_id: sdl.SDL_JoystickID,
    hat: u8,
    value: HatValue,

    pub fn fromNative(native: sdl.SDL_JoyHatEvent) JoyHatEvent {
        switch (native.type) {
            else => unreachable,
            sdl.SDL_EVENT_JOYSTICK_HAT_MOTION => {},
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
    timestamp: u64,
    joystick_id: sdl.SDL_JoystickID,
    ball: u8,
    relative_x: i16,
    relative_y: i16,

    pub fn fromNative(native: sdl.SDL_JoyBallEvent) JoyBallEvent {
        switch (native.type) {
            else => unreachable,
            sdl.SDL_EVENT_JOYSTICK_BALL_MOTION => {},
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
    timestamp: u64,
    joystick_id: sdl.SDL_JoystickID,
    button: u8,
    is_down: bool,

    pub fn fromNative(native: sdl.SDL_JoyButtonEvent) JoyButtonEvent {
        switch (native.type) {
            else => unreachable,
            sdl.SDL_EVENT_JOYSTICK_BUTTON_DOWN, sdl.SDL_EVENT_JOYSTICK_BUTTON_UP => {},
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
    timestamp: u64,
    joystick_id: sdl.SDL_JoystickID,
    axis: Gamepad.Axis,
    value: i16,

    pub fn fromNative(native: sdl.SDL_GamepadAxisEvent) GamepadAxisEvent {
        switch (native.type) {
            else => unreachable,
            sdl.SDL_EVENT_GAMEPAD_AXIS_MOTION => {},
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
            @floatFromInt(sdl.SDL_JOYSTICK_AXIS_MAX)
        else
            @floatFromInt(sdl.SDL_JOYSTICK_AXIS_MIN);
        return @as(FloatType, @floatFromInt(self.value)) / @abs(denominator);
    }
};

pub const GamepadButtonEvent = struct {
    timestamp: u64,
    joystick_id: sdl.SDL_JoystickID,
    button: Gamepad.Button,
    is_down: bool,

    pub fn fromNative(native: sdl.SDL_GamepadButtonEvent) GamepadButtonEvent {
        switch (native.type) {
            else => unreachable,
            sdl.SDL_EVENT_GAMEPAD_BUTTON_DOWN, sdl.SDL_EVENT_GAMEPAD_BUTTON_UP => {},
        }
        return .{
            .timestamp = native.timestamp,
            .joystick_id = native.which,
            .button = @enumFromInt(native.button),
            .is_down = native.down,
        };
    }
};

/// from registerEvents
pub const UserEvent = struct {
    type: u32,
    timestamp: u64 = 0,
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
    pub const WindowEvent = sdl.SDL_WindowEvent;
    pub const KeyboardDeviceEvent = sdl.SDL_KeyboardDeviceEvent;
    pub const MouseDeviceEvent = sdl.SDL_MouseDeviceEvent;
    pub const TextEditingCandidatesEvent = sdl.SDL_TextEditingCandidatesEvent;
    pub const TextEditingEvent = sdl.SDL_TextEditingEvent;
    pub const TextInputEvent = sdl.SDL_TextInputEvent;
    pub const JoyDeviceEvent = sdl.SDL_JoyDeviceEvent;
    pub const JoyBatteryEvent = sdl.SDL_JoyBatteryEvent;
    pub const GamepadDeviceEvent = sdl.SDL_GamepadDeviceEvent;
    pub const GamepadTouchpadEvent = sdl.SDL_GamepadTouchpadEvent;
    pub const GamepadSensorEvent = sdl.SDL_GamepadSensorEvent;
    pub const AudioDeviceEvent = sdl.SDL_AudioDeviceEvent;
    pub const SensorEvent = sdl.SDL_SensorEvent;
    pub const QuitEvent = sdl.SDL_QuitEvent;
    pub const TouchFingerEvent = sdl.SDL_TouchFingerEvent;
    pub const ClipboardEvent = sdl.SDL_ClipboardEvent;
    pub const DropEvent = sdl.SDL_DropEvent;
    pub const PenProximityEvent = sdl.SDL_PenProximityEvent;
    pub const PenAxisEvent = sdl.SDL_PenAxisEvent;
    pub const PenTouchEvent = sdl.SDL_PenTouchEvent;
    pub const PenButtonEvent = sdl.SDL_PenButtonEvent;
    pub const PenMotionEvent = sdl.SDL_PenMotionEvent;
    pub const CameraDeviceEvent = sdl.SDL_CameraDeviceEvent;
    pub const RenderEvent = sdl.SDL_RenderEvent;

    quit: QuitEvent,
    terminating: CommonEvent,
    low_memory: CommonEvent,
    will_enter_foreground: CommonEvent,
    did_enter_background: CommonEvent,
    will_enter_background: CommonEvent,
    did_enter_foreground: CommonEvent,
    locale_changed: CommonEvent,
    system_theme_changed: CommonEvent,
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
    key_map_changed: CommonEvent,
    keyboard_added: KeyboardDeviceEvent,
    keyboard_removed: KeyboardDeviceEvent,
    text_editing_candidates: TextEditingCandidatesEvent,
    mouse_motion: MouseMotionEvent,
    mouse_button_down: MouseButtonEvent,
    mouse_button_up: MouseButtonEvent,
    mouse_wheel: MouseWheelEvent,
    mouse_added: MouseDeviceEvent,
    mouse_removed: MouseDeviceEvent,
    joy_axis_motion: JoyAxisEvent,
    joy_ball_motion: JoyBallEvent,
    joy_hat_motion: JoyHatEvent,
    joy_button_down: JoyButtonEvent,
    joy_button_up: JoyButtonEvent,
    joy_device_added: JoyDeviceEvent,
    joy_device_removed: JoyDeviceEvent,
    joy_battery_level: JoyBatteryEvent,
    joy_update_complete: CommonEvent,
    gamepad_axis_motion: GamepadAxisEvent,
    gamepad_button_down: GamepadButtonEvent,
    gamepad_button_up: GamepadButtonEvent,
    gamepad_added: GamepadDeviceEvent,
    gamepad_removed: GamepadDeviceEvent,
    gamepad_remapped: GamepadDeviceEvent,
    gamepad_touchpad_down: GamepadTouchpadEvent,
    gamepad_touchpad_motion: GamepadTouchpadEvent,
    gamepad_touchpad_up: GamepadTouchpadEvent,
    gamepad_sensor_update: GamepadSensorEvent,
    gamepad_update_complete: CommonEvent,
    gamepad_steam_handle_updated: CommonEvent,
    finger_down: TouchFingerEvent,
    finger_up: TouchFingerEvent,
    finger_motion: TouchFingerEvent,
    finger_canceled: TouchFingerEvent,
    clip_board_update: ClipboardEvent,
    drop_file: DropEvent,
    drop_text: DropEvent,
    drop_begin: DropEvent,
    drop_complete: DropEvent,
    drop_position: DropEvent,
    audio_device_added: AudioDeviceEvent,
    audio_device_removed: AudioDeviceEvent,
    audio_device_format_changed: AudioDeviceEvent,
    sensor_update: SensorEvent,
    pen_proximity_in: PenProximityEvent,
    pen_proximity_out: PenProximityEvent,
    pen_down: PenTouchEvent,
    pen_up: PenTouchEvent,
    pen_button_down: PenButtonEvent,
    pen_button_up: PenButtonEvent,
    pen_motion: PenMotionEvent,
    pen_axis: PenAxisEvent,
    camera_device_added: CameraDeviceEvent,
    camera_device_removed: CameraDeviceEvent,
    camera_device_approved: CameraDeviceEvent,
    camera_device_denied: CameraDeviceEvent,
    render_targets_reset: RenderEvent,
    render_device_reset: RenderEvent,
    render_device_lost: RenderEvent,
    private0: CommonEvent,
    private1: CommonEvent,
    private2: CommonEvent,
    private3: CommonEvent,
    poll_sentinel: CommonEvent,
    user: UserEvent,

    pub fn from(raw: sdl.SDL_Event, ctx: jok.Context) Event {
        return switch (raw.type) {
            sdl.SDL_EVENT_QUIT => Event{ .quit = raw.quit },
            sdl.SDL_EVENT_TERMINATING => Event{ .terminating = raw.common },
            sdl.SDL_EVENT_LOW_MEMORY => Event{ .low_memory = raw.common },
            sdl.SDL_EVENT_WILL_ENTER_BACKGROUND => Event{ .will_enter_background = raw.common },
            sdl.SDL_EVENT_DID_ENTER_BACKGROUND => Event{ .did_enter_background = raw.common },
            sdl.SDL_EVENT_WILL_ENTER_FOREGROUND => Event{ .will_enter_foreground = raw.common },
            sdl.SDL_EVENT_DID_ENTER_FOREGROUND => Event{ .did_enter_foreground = raw.common },
            sdl.SDL_EVENT_LOCALE_CHANGED => Event{ .locale_changed = raw.common },
            sdl.SDL_EVENT_SYSTEM_THEME_CHANGED => Event{ .system_theme_changed = raw.common },
            sdl.SDL_EVENT_DISPLAY_ORIENTATION => Event{ .display_orientation = raw.display },
            sdl.SDL_EVENT_DISPLAY_ADDED => Event{ .display_added = raw.display },
            sdl.SDL_EVENT_DISPLAY_REMOVED => Event{ .display_removed = raw.display },
            sdl.SDL_EVENT_DISPLAY_MOVED => Event{ .display_moved = raw.display },
            sdl.SDL_EVENT_DISPLAY_DESKTOP_MODE_CHANGED => Event{ .display_desktop_mode_changed = raw.display },
            sdl.SDL_EVENT_DISPLAY_CURRENT_MODE_CHANGED => Event{ .display_current_mode_changed = raw.display },
            sdl.SDL_EVENT_DISPLAY_CONTENT_SCALE_CHANGED => Event{ .display_content_scale_changed = raw.display },
            sdl.SDL_EVENT_WINDOW_SHOWN => Event{ .window_shown = raw.window },
            sdl.SDL_EVENT_WINDOW_HIDDEN => Event{ .window_hidden = raw.window },
            sdl.SDL_EVENT_WINDOW_EXPOSED => Event{ .window_exposed = raw.window },
            sdl.SDL_EVENT_WINDOW_MOVED => Event{ .window_moved = raw.window },
            sdl.SDL_EVENT_WINDOW_RESIZED => Event{ .window_resized = raw.window },
            sdl.SDL_EVENT_WINDOW_PIXEL_SIZE_CHANGED => Event{ .window_pixel_size_changed = raw.window },
            sdl.SDL_EVENT_WINDOW_METAL_VIEW_RESIZED => Event{ .window_metal_view_resized = raw.window },
            sdl.SDL_EVENT_WINDOW_MINIMIZED => Event{ .window_minimized = raw.window },
            sdl.SDL_EVENT_WINDOW_MAXIMIZED => Event{ .window_maximized = raw.window },
            sdl.SDL_EVENT_WINDOW_RESTORED => Event{ .window_restored = raw.window },
            sdl.SDL_EVENT_WINDOW_MOUSE_ENTER => Event{ .window_mouse_enter = raw.window },
            sdl.SDL_EVENT_WINDOW_MOUSE_LEAVE => Event{ .window_mouse_leave = raw.window },
            sdl.SDL_EVENT_WINDOW_FOCUS_GAINED => Event{ .window_focus_gained = raw.window },
            sdl.SDL_EVENT_WINDOW_FOCUS_LOST => Event{ .window_focus_lost = raw.window },
            sdl.SDL_EVENT_WINDOW_CLOSE_REQUESTED => Event{ .window_close_requested = raw.window },
            sdl.SDL_EVENT_WINDOW_HIT_TEST => Event{ .window_hit_test = raw.window },
            sdl.SDL_EVENT_WINDOW_ICCPROF_CHANGED => Event{ .window_iccprof_changed = raw.window },
            sdl.SDL_EVENT_WINDOW_DISPLAY_CHANGED => Event{ .window_display_changed = raw.window },
            sdl.SDL_EVENT_WINDOW_DISPLAY_SCALE_CHANGED => Event{ .window_display_scale_changed = raw.window },
            sdl.SDL_EVENT_WINDOW_SAFE_AREA_CHANGED => Event{ .window_safe_area_changed = raw.window },
            sdl.SDL_EVENT_WINDOW_OCCLUDED => Event{ .window_occluded = raw.window },
            sdl.SDL_EVENT_WINDOW_ENTER_FULLSCREEN => Event{ .window_enter_fullscreen = raw.window },
            sdl.SDL_EVENT_WINDOW_LEAVE_FULLSCREEN => Event{ .window_leave_fullscreen = raw.window },
            sdl.SDL_EVENT_WINDOW_DESTROYED => Event{ .window_destroyed = raw.window },
            sdl.SDL_EVENT_WINDOW_HDR_STATE_CHANGED => Event{ .window_hdr_state_changed = raw.window },
            sdl.SDL_EVENT_KEY_DOWN => Event{ .key_down = KeyboardEvent.fromNative(raw.key) },
            sdl.SDL_EVENT_KEY_UP => Event{ .key_up = KeyboardEvent.fromNative(raw.key) },
            sdl.SDL_EVENT_TEXT_EDITING => Event{ .text_editing = raw.edit },
            sdl.SDL_EVENT_TEXT_INPUT => Event{ .text_input = raw.text },
            sdl.SDL_EVENT_KEYMAP_CHANGED => Event{ .key_map_changed = raw.common },
            sdl.SDL_EVENT_KEYBOARD_ADDED => Event{ .keyboard_added = raw.kdevice },
            sdl.SDL_EVENT_KEYBOARD_REMOVED => Event{ .keyboard_removed = raw.kdevice },
            sdl.SDL_EVENT_TEXT_EDITING_CANDIDATES => Event{ .text_editing_candidates = raw.edit_candidates },
            sdl.SDL_EVENT_MOUSE_MOTION => Event{ .mouse_motion = MouseMotionEvent.fromNative(raw.motion, ctx) },
            sdl.SDL_EVENT_MOUSE_BUTTON_DOWN => Event{ .mouse_button_down = MouseButtonEvent.fromNative(raw.button, ctx) },
            sdl.SDL_EVENT_MOUSE_BUTTON_UP => Event{ .mouse_button_up = MouseButtonEvent.fromNative(raw.button, ctx) },
            sdl.SDL_EVENT_MOUSE_WHEEL => Event{ .mouse_wheel = MouseWheelEvent.fromNative(raw.wheel) },
            sdl.SDL_EVENT_MOUSE_ADDED => Event{ .mouse_added = raw.mdevice },
            sdl.SDL_EVENT_MOUSE_REMOVED => Event{ .mouse_added = raw.mdevice },
            sdl.SDL_EVENT_JOYSTICK_AXIS_MOTION => Event{ .joy_axis_motion = JoyAxisEvent.fromNative(raw.jaxis) },
            sdl.SDL_EVENT_JOYSTICK_BALL_MOTION => Event{ .joy_ball_motion = JoyBallEvent.fromNative(raw.jball) },
            sdl.SDL_EVENT_JOYSTICK_HAT_MOTION => Event{ .joy_hat_motion = JoyHatEvent.fromNative(raw.jhat) },
            sdl.SDL_EVENT_JOYSTICK_BUTTON_DOWN => Event{ .joy_button_down = JoyButtonEvent.fromNative(raw.jbutton) },
            sdl.SDL_EVENT_JOYSTICK_BUTTON_UP => Event{ .joy_button_up = JoyButtonEvent.fromNative(raw.jbutton) },
            sdl.SDL_EVENT_JOYSTICK_ADDED => Event{ .joy_device_added = raw.jdevice },
            sdl.SDL_EVENT_JOYSTICK_REMOVED => Event{ .joy_device_removed = raw.jdevice },
            sdl.SDL_EVENT_JOYSTICK_BATTERY_UPDATED => Event{ .joy_battery_level = raw.jbattery },
            sdl.SDL_EVENT_JOYSTICK_UPDATE_COMPLETE => Event{ .joy_update_complete = raw.common },
            sdl.SDL_EVENT_GAMEPAD_AXIS_MOTION => Event{ .gamepad_axis_motion = GamepadAxisEvent.fromNative(raw.gaxis) },
            sdl.SDL_EVENT_GAMEPAD_BUTTON_DOWN => Event{ .gamepad_button_down = GamepadButtonEvent.fromNative(raw.gbutton) },
            sdl.SDL_EVENT_GAMEPAD_BUTTON_UP => Event{ .gamepad_button_up = GamepadButtonEvent.fromNative(raw.gbutton) },
            sdl.SDL_EVENT_GAMEPAD_ADDED => Event{ .gamepad_added = raw.gdevice },
            sdl.SDL_EVENT_GAMEPAD_REMOVED => Event{ .gamepad_removed = raw.gdevice },
            sdl.SDL_EVENT_GAMEPAD_REMAPPED => Event{ .gamepad_remapped = raw.gdevice },
            sdl.SDL_EVENT_GAMEPAD_TOUCHPAD_DOWN => Event{ .gamepad_touchpad_down = raw.gtouchpad },
            sdl.SDL_EVENT_GAMEPAD_TOUCHPAD_MOTION => Event{ .gamepad_touchpad_motion = raw.gtouchpad },
            sdl.SDL_EVENT_GAMEPAD_TOUCHPAD_UP => Event{ .gamepad_touchpad_up = raw.gtouchpad },
            sdl.SDL_EVENT_GAMEPAD_SENSOR_UPDATE => Event{ .gamepad_sensor_update = raw.gsensor },
            sdl.SDL_EVENT_GAMEPAD_UPDATE_COMPLETE => Event{ .gamepad_update_complete = raw.common },
            sdl.SDL_EVENT_GAMEPAD_STEAM_HANDLE_UPDATED => Event{ .gamepad_steam_handle_updated = raw.common },
            sdl.SDL_EVENT_FINGER_DOWN => Event{ .finger_down = raw.tfinger },
            sdl.SDL_EVENT_FINGER_UP => Event{ .finger_up = raw.tfinger },
            sdl.SDL_EVENT_FINGER_MOTION => Event{ .finger_motion = raw.tfinger },
            sdl.SDL_EVENT_FINGER_CANCELED => Event{ .finger_canceled = raw.tfinger },
            sdl.SDL_EVENT_CLIPBOARD_UPDATE => Event{ .clip_board_update = raw.clipboard },
            sdl.SDL_EVENT_DROP_FILE => Event{ .drop_file = raw.drop },
            sdl.SDL_EVENT_DROP_TEXT => Event{ .drop_text = raw.drop },
            sdl.SDL_EVENT_DROP_BEGIN => Event{ .drop_begin = raw.drop },
            sdl.SDL_EVENT_DROP_COMPLETE => Event{ .drop_complete = raw.drop },
            sdl.SDL_EVENT_DROP_POSITION => Event{ .drop_position = raw.drop },
            sdl.SDL_EVENT_AUDIO_DEVICE_ADDED => Event{ .audio_device_added = raw.adevice },
            sdl.SDL_EVENT_AUDIO_DEVICE_REMOVED => Event{ .audio_device_removed = raw.adevice },
            sdl.SDL_EVENT_AUDIO_DEVICE_FORMAT_CHANGED => Event{ .audio_device_format_changed = raw.adevice },
            sdl.SDL_EVENT_SENSOR_UPDATE => Event{ .sensor_update = raw.sensor },
            sdl.SDL_EVENT_PEN_PROXIMITY_IN => Event{ .pen_proximity_in = raw.pproximity },
            sdl.SDL_EVENT_PEN_PROXIMITY_OUT => Event{ .pen_proximity_out = raw.pproximity },
            sdl.SDL_EVENT_PEN_DOWN => Event{ .pen_down = raw.ptouch },
            sdl.SDL_EVENT_PEN_UP => Event{ .pen_up = raw.ptouch },
            sdl.SDL_EVENT_PEN_BUTTON_DOWN => Event{ .pen_button_down = raw.pbutton },
            sdl.SDL_EVENT_PEN_BUTTON_UP => Event{ .pen_button_up = raw.pbutton },
            sdl.SDL_EVENT_PEN_MOTION => Event{ .pen_motion = raw.pmotion },
            sdl.SDL_EVENT_PEN_AXIS => Event{ .pen_axis = raw.paxis },
            sdl.SDL_EVENT_CAMERA_DEVICE_ADDED => Event{ .camera_device_added = raw.cdevice },
            sdl.SDL_EVENT_CAMERA_DEVICE_REMOVED => Event{ .camera_device_removed = raw.cdevice },
            sdl.SDL_EVENT_CAMERA_DEVICE_APPROVED => Event{ .camera_device_approved = raw.cdevice },
            sdl.SDL_EVENT_CAMERA_DEVICE_DENIED => Event{ .camera_device_denied = raw.cdevice },
            sdl.SDL_EVENT_RENDER_TARGETS_RESET => Event{ .render_targets_reset = raw.render },
            sdl.SDL_EVENT_RENDER_DEVICE_RESET => Event{ .render_device_reset = raw.render },
            sdl.SDL_EVENT_RENDER_DEVICE_LOST => Event{ .render_device_lost = raw.render },
            sdl.SDL_EVENT_PRIVATE0 => Event{ .private0 = raw.common },
            sdl.SDL_EVENT_PRIVATE1 => Event{ .private1 = raw.common },
            sdl.SDL_EVENT_PRIVATE2 => Event{ .private2 = raw.common },
            sdl.SDL_EVENT_PRIVATE3 => Event{ .private3 = raw.common },
            sdl.SDL_EVENT_POLL_SENTINEL => Event{ .poll_sentinel = raw.common },
            else => |t| if (t >= sdl.SDL_EVENT_USER)
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
    if (sdl.SDL_PollEvent(&ev))
        return Event.from(ev);
    return null;
}

pub fn pollNativeEvent() ?sdl.SDL_Event {
    var ev: sdl.SDL_Event = undefined;
    if (sdl.SDL_PollEvent(&ev))
        return ev;
    return null;
}

/// Waits indefinitely to pump a new event into the queue.
/// May not conserve energy on some systems, in some versions/situations.
/// This function should only be called from
/// the thread that initialized the video subsystem.
pub fn waitEvent() !Event {
    var ev: sdl.SDL_Event = undefined;
    if (sdl.SDL_WaitEvent(&ev))
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
    if (sdl.SDL_WaitEventTimeout(&ev, @intCast(timeout)))
        return Event.from(ev);
    return null;
}

pub const MouseState = struct {
    buttons: MouseButtonState,
    pos: jok.Point,
};

pub fn getMouseState(ctx: jok.Context) MouseState {
    var ms: MouseState = undefined;
    var x: f32 = undefined;
    var y: f32 = undefined;
    const buttons = sdl.SDL_GetMouseState(&x, &y);
    ms.buttons = MouseButtonState.fromNative(buttons);
    ms.pos = mapPositionToCanvas(ctx, .{
        .x = x,
        .y = y,
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
    media_next_track = sdl.SDL_SCANCODE_MEDIA_NEXT_TRACK,
    media_previous_track = sdl.SDL_SCANCODE_MEDIA_PREVIOUS_TRACK,
    media_play = sdl.SDL_SCANCODE_MEDIA_PLAY,
    media_pause = sdl.SDL_SCANCODE_MEDIA_PAUSE,
    media_record = sdl.SDL_SCANCODE_MEDIA_RECORD,
    media_fast_forward = sdl.SDL_SCANCODE_MEDIA_FAST_FORWARD,
    media_rewind = sdl.SDL_SCANCODE_MEDIA_REWIND,
    media_stop = sdl.SDL_SCANCODE_MEDIA_STOP,
    media_eject = sdl.SDL_SCANCODE_MEDIA_EJECT,
    media_play_pause = sdl.SDL_SCANCODE_MEDIA_PLAY_PAUSE,
    media_select = sdl.SDL_SCANCODE_MEDIA_SELECT,
    application_control_search = sdl.SDL_SCANCODE_AC_SEARCH,
    application_control_home = sdl.SDL_SCANCODE_AC_HOME,
    application_control_back = sdl.SDL_SCANCODE_AC_BACK,
    application_control_forward = sdl.SDL_SCANCODE_AC_FORWARD,
    application_control_stop = sdl.SDL_SCANCODE_AC_STOP,
    application_control_refresh = sdl.SDL_SCANCODE_AC_REFRESH,
    application_control_bookmarks = sdl.SDL_SCANCODE_AC_BOOKMARKS,
    sleep = sdl.SDL_SCANCODE_SLEEP,
    _,
};

pub const KeyboardState = struct {
    states: []const bool,

    pub fn isPressed(ks: KeyboardState, scancode: Scancode) bool {
        return ks.states[@intCast(@intFromEnum(scancode))];
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
    dblapostrophe = sdl.SDLK_DBLAPOSTROPHE,
    hash = sdl.SDLK_HASH,
    percent = sdl.SDLK_PERCENT,
    dollar = sdl.SDLK_DOLLAR,
    ampersand = sdl.SDLK_AMPERSAND,
    apostrophe = sdl.SDLK_APOSTROPHE,
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
    grave = sdl.SDLK_GRAVE,
    a = sdl.SDLK_A,
    b = sdl.SDLK_B,
    c = sdl.SDLK_C,
    d = sdl.SDLK_D,
    e = sdl.SDLK_E,
    f = sdl.SDLK_F,
    g = sdl.SDLK_G,
    h = sdl.SDLK_H,
    i = sdl.SDLK_I,
    j = sdl.SDLK_J,
    k = sdl.SDLK_K,
    l = sdl.SDLK_L,
    m = sdl.SDLK_M,
    n = sdl.SDLK_N,
    o = sdl.SDLK_O,
    p = sdl.SDLK_P,
    q = sdl.SDLK_Q,
    r = sdl.SDLK_R,
    s = sdl.SDLK_S,
    t = sdl.SDLK_T,
    u = sdl.SDLK_U,
    v = sdl.SDLK_V,
    w = sdl.SDLK_W,
    x = sdl.SDLK_X,
    y = sdl.SDLK_Y,
    z = sdl.SDLK_Z,
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
    media_next = sdl.SDLK_MEDIA_NEXT_TRACK,
    media_previous = sdl.SDLK_MEDIA_PREVIOUS_TRACK,
    media_stop = sdl.SDLK_MEDIA_STOP,
    media_play = sdl.SDLK_MEDIA_PLAY,
    media_pause = sdl.SDLK_MEDIA_PAUSE,
    media_play_pause = sdl.SDLK_MEDIA_PLAY_PAUSE,
    media_eject = sdl.SDLK_MEDIA_EJECT,
    media_select = sdl.SDLK_MEDIA_SELECT,
    media_rewind = sdl.SDLK_MEDIA_REWIND,
    media_fast_forward = sdl.SDLK_MEDIA_FAST_FORWARD,
    application_control_search = sdl.SDLK_AC_SEARCH,
    application_control_home = sdl.SDLK_AC_HOME,
    application_control_back = sdl.SDLK_AC_BACK,
    application_control_forward = sdl.SDLK_AC_FORWARD,
    application_control_stop = sdl.SDLK_AC_STOP,
    application_control_refresh = sdl.SDLK_AC_REFRESH,
    application_control_bookmarks = sdl.SDLK_AC_BOOKMARKS,
    sleep = sdl.SDLK_SLEEP,
    _,
};

pub const Clipboard = struct {
    pub fn get() !?[]const u8 {
        if (!sdl.SDL_HasClipboardText())
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
        if (!sdl.SDL_SetClipboardText(@ptrCast(txt))) {
            return sdl.Error.SdlError;
        }
    }
};

pub fn getTicks() u64 {
    return sdl.SDL_GetTicks();
}

pub fn getTicksNS() u64 {
    return sdl.SDL_GetTicksNS();
}

pub fn delay(ms: u32) void {
    sdl.SDL_Delay(ms);
}

pub fn delayNS(ns: u32) void {
    sdl.SDL_DelayNS(ns);
}

pub const JoystickList = struct {
    ids: []sdl.SDL_JoystickID,

    pub fn deinit(self: @This()) void {
        sdl.SDL_free(self.ids.ptr);
    }
};

pub fn getJoysticks() ?JoystickList {
    var num: u32 = undefined;
    const joysticks = sdl.SDL_GetJoysticks(&num);
    if (joysticks == null) {
        return null;
    }
    var js = JoystickList{};
    js.ids.ptr = @ptrCast(joysticks);
    js.idx.len = @intCast(num);
    return js;
}

pub const Gamepad = struct {
    ptr: *sdl.SDL_Gamepad,

    pub fn open(joystick_index: sdl.SDL_JoystickID) !Gamepad {
        return Gamepad{
            .ptr = sdl.SDL_OpenGamepad(joystick_index) orelse return error.SdlError,
        };
    }

    pub fn is(joystick_index: sdl.SDL_JoystickID) bool {
        return sdl.SDL_IsGamepad(joystick_index);
    }

    pub fn close(self: Gamepad) void {
        sdl.SDL_CloseGamepad(self.ptr);
    }

    pub fn name(self: Gamepad) []const u8 {
        return std.mem.sliceTo(sdl.SDL_GetJoystickName(self.ptr), 0);
    }

    pub fn hasButton(self: Gamepad, button: Button) bool {
        return sdl.SDL_GamepadHasButton(self.ptr, @intFromEnum(button));
    }

    pub fn isButtonPressed(self: Gamepad, button: Button) bool {
        return sdl.SDL_GetGamepadButton(self.ptr, @intFromEnum(button));
    }

    pub fn getAxis(self: Gamepad, axis: Axis) i16 {
        return sdl.SDL_GetGamepadAxis(self.ptr, @intFromEnum(axis));
    }

    pub fn getAxisNormalized(self: Gamepad, axis: Axis) f32 {
        return @as(f32, @floatFromInt(self.getAxis(axis))) / @as(f32, @floatFromInt(sdl.SDL_JOYSTICK_AXIS_MAX));
    }

    pub fn instanceId(self: Gamepad) sdl.SDL_JoystickID {
        return sdl.SDL_GetJoystickID(sdl.SDL_GetGamepadJoystick(self.ptr));
    }

    pub const Button = enum(sdl.SDL_GamepadButton) {
        sourth = sdl.SDL_GAMEPAD_BUTTON_SOUTH,
        east = sdl.SDL_GAMEPAD_BUTTON_EAST,
        west = sdl.SDL_GAMEPAD_BUTTON_WEST,
        north = sdl.SDL_GAMEPAD_BUTTON_NORTH,
        back = sdl.SDL_GAMEPAD_BUTTON_BACK,
        guide = sdl.SDL_GAMEPAD_BUTTON_GUIDE,
        start = sdl.SDL_GAMEPAD_BUTTON_START,
        left_stick = sdl.SDL_GAMEPAD_BUTTON_LEFT_STICK,
        right_stick = sdl.SDL_GAMEPAD_BUTTON_RIGHT_STICK,
        left_shoulder = sdl.SDL_GAMEPAD_BUTTON_LEFT_SHOULDER,
        right_shoulder = sdl.SDL_GAMEPAD_BUTTON_RIGHT_SHOULDER,
        dpad_up = sdl.SDL_GAMEPAD_BUTTON_DPAD_UP,
        dpad_down = sdl.SDL_GAMEPAD_BUTTON_DPAD_DOWN,
        dpad_left = sdl.SDL_GAMEPAD_BUTTON_DPAD_LEFT,
        dpad_right = sdl.SDL_GAMEPAD_BUTTON_DPAD_RIGHT,
        /// Xbox Series X share button, PS5 microphone button, Nintendo Switch Pro capture button, Amazon Luna microphone button
        misc_1 = sdl.SDL_GAMEPAD_BUTTON_MISC1,
        right_paddle_1 = sdl.SDL_GAMEPAD_BUTTON_RIGHT_PADDLE1,
        left_paddle_1 = sdl.SDL_GAMEPAD_BUTTON_LEFT_PADDLE1,
        right_paddle_2 = sdl.SDL_GAMEPAD_BUTTON_RIGHT_PADDLE2,
        left_paddle_2 = sdl.SDL_GAMEPAD_BUTTON_LEFT_PADDLE2,
        /// PS4/PS5 touchpad button
        touchpad = sdl.SDL_GAMEPAD_BUTTON_TOUCHPAD,
    };

    pub const Axis = enum(sdl.SDL_GamepadAxis) {
        left_x = sdl.SDL_GAMEPAD_AXIS_LEFTX,
        left_y = sdl.SDL_GAMEPAD_AXIS_LEFTY,
        right_x = sdl.SDL_GAMEPAD_AXIS_RIGHTX,
        right_y = sdl.SDL_GAMEPAD_AXIS_RIGHTY,
        left_trigger = sdl.SDL_GAMEPAD_AXIS_LEFT_TRIGGER,
        right_trigger = sdl.SDL_GAMEPAD_AXIS_RIGHT_TRIGGER,
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
