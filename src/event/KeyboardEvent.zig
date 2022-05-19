const sdl = @import("sdl");
const Self = @This();

/// Press or release
pub const TriggerType = enum {
    down,
    up,
};

/// Trigger type
trigger_type: TriggerType = undefined,

/// Key being pressed/released
scan_code: sdl.Scancode = undefined,

/// Key modifier
modifiers: sdl.KeyModifierSet = undefined,

/// Repeat key
is_repeat: bool = undefined,

/// Timestamp of event
timestamp: u32 = undefined,

pub fn init(e: sdl.KeyboardEvent) Self {
    return .{
        .trigger_type = switch (e.key_state) {
            .released => .up,
            .pressed => .down,
        },
        .scan_code = e.scancode,
        .modifiers = e.modifiers,
        .is_repeat = e.is_repeat,
        .timestamp = e.timestamp,
    };
}
