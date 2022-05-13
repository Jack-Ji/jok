const std = @import("std");
const sdl = @import("sdl");

/// event definitions
pub const WindowEvent = @import("event/WindowEvent.zig");
pub const KeyboardEvent = @import("event/KeyboardEvent.zig");
pub const TextInputEvent = @import("event/TextInputEvent.zig");
pub const MouseEvent = @import("event/MouseEvent.zig");
pub const GamepadEvent = @import("event/GamepadEvent.zig");
pub const QuitEvent = struct {};

/// generic event
pub const Event = union(enum) {
    window_event: WindowEvent,
    keyboard_event: KeyboardEvent,
    text_input_event: TextInputEvent,
    mouse_event: MouseEvent,
    gamepad_event: GamepadEvent,
    quit_event: QuitEvent,

    pub fn init(e: sdl.Event) ?Event {
        return switch (e) {
            .window => |ee| Event{
                .window_event = WindowEvent.init(ee),
            },
            .key_up => |ee| Event{
                .keyboard_event = KeyboardEvent.init(ee),
            },
            .key_down => |ee| Event{
                .keyboard_event = KeyboardEvent.init(ee),
            },
            .text_input => |ee| Event{
                .text_input_event = TextInputEvent.init(ee),
            },
            .mouse_motion => |ee| Event{
                .mouse_event = MouseEvent.fromMotionEvent(ee),
            },
            .mouse_button_up => |ee| Event{
                .mouse_event = MouseEvent.fromButtonEvent(ee),
            },
            .mouse_button_down => |ee| Event{
                .mouse_event = MouseEvent.fromButtonEvent(ee),
            },
            .mouse_wheel => |ee| Event{
                .mouse_event = MouseEvent.fromWheelEvent(ee),
            },
            .controller_axis_motion => |ee| Event{
                .gamepad_event = GamepadEvent.fromAxisEvent(ee),
            },
            .controller_button_up => |ee| Event{
                .gamepad_event = GamepadEvent.fromButtonEvent(ee),
            },
            .controller_button_down => |ee| Event{
                .gamepad_event = GamepadEvent.fromButtonEvent(ee),
            },
            .controller_device_added => |ee| Event{
                .gamepad_event = GamepadEvent.fromDeviceEvent(ee),
            },
            .controller_device_removed => |ee| Event{
                .gamepad_event = GamepadEvent.fromDeviceEvent(ee),
            },
            .controller_device_remapped => |ee| Event{
                .gamepad_event = GamepadEvent.fromDeviceEvent(ee),
            },
            .quit => Event{
                .quit_event = QuitEvent{},
            },

            // ignored other events
            else => null,
        };
    }
};
