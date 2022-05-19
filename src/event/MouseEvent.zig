const sdl = @import("sdl");
const c = sdl.c;
const Self = @This();

const Data = union(enum) {
    motion: struct {
        x: i32, // Current horizontal coordinate, relative to window
        y: i32, // Current vertical coordinate, relative to window
        xrel: i32, // Relative to last event
        yrel: i32, // Relative to last event
    },
    button: struct {
        x: i32, // Current horizontal coordinate, relative to window
        y: i32, // Current vertical coordinate, relative to window
        btn: sdl.MouseButton, // Pressed/released button
        clicked: bool, // False means released
        double_clicked: bool, // Double clicks
    },
    wheel: struct {
        scroll_x: i32, // Positive to the right, negative to the left
        scroll_y: i32, // Positive away from user, negative towards user
    },
};

/// Timestamp of event
timestamp: u32 = undefined,

/// Mouse event data
data: Data = undefined,

pub fn fromMotionEvent(e: sdl.MouseMotionEvent) Self {
    return .{
        .timestamp = e.timestamp,
        .data = .{
            .motion = .{
                .x = e.x,
                .y = e.y,
                .xrel = e.delta_x,
                .yrel = e.delta_y,
            },
        },
    };
}

pub fn fromButtonEvent(e: sdl.MouseButtonEvent) Self {
    return .{
        .timestamp = e.timestamp,
        .data = .{
            .button = .{
                .x = e.x,
                .y = e.y,
                .btn = e.button,
                .clicked = e.state == .pressed,
                .double_clicked = e.clicks > 1,
            },
        },
    };
}

pub fn fromWheelEvent(e: sdl.MouseWheelEvent) Self {
    return .{
        .timestamp = e.timestamp,
        .data = .{
            .wheel = .{
                .scroll_x = if (e.direction == .normal) -e.delta_x else e.delta_x,
                .scroll_y = if (e.direction == .flipped) -e.delta_y else e.delta_y,
            },
        },
    };
}
