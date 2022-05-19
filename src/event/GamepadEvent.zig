const sdl = @import("sdl");
const c = sdl.c;
const Self = @This();

/// Timestamp of event
timestamp: u32,

pub fn fromAxisEvent(e: sdl.ControllerAxisEvent) Self {
    return .{
        .timestamp = e.timestamp,
    };
}

pub fn fromButtonEvent(e: sdl.ControllerButtonEvent) Self {
    return .{
        .timestamp = e.timestamp,
    };
}

pub fn fromDeviceEvent(e: c.SDL_ControllerDeviceEvent) Self {
    return .{
        .timestamp = e.timestamp,
    };
}

pub fn fromSensorEvent(e: c.SDL_ControllerSensorEvent) Self {
    return .{
        .timestamp = e.timestamp,
    };
}
