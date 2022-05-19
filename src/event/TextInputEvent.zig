const sdl = @import("sdl");
const c = sdl.c;
const Self = @This();

/// Input text
text: [32]u8,

/// Timestamp of event
timestamp: u32 = undefined,

pub fn init(e: c.SDL_TextInputEvent) Self {
    return .{
        .text = e.text,
        .timestamp = e.timestamp,
    };
}
