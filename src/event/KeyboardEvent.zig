const sdl = @import("sdl");
const Self = @This();

///  press or release
pub const TriggerType = enum {
    down,
    up,
};

/// trigger type
trigger_type: TriggerType = undefined,

/// key being pressed/released
scan_code: sdl.Scancode = undefined,

/// key modifier
modifiers: sdl.KeyModifierSet = undefined,

/// repeat key
is_repeat: bool = undefined,

/// timestamp of event
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
