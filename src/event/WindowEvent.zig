const sdl = @import("sdl");
const c = sdl.c;
const Self = @This();

/// window position
const Point = extern struct {
    x: u32,
    y: u32,
};

/// window size
const Size = extern struct {
    width: u32,
    height: u32,
};

/// event type
const Type = enum(u8) {
    none = c.SDL_WINDOWEVENT_NONE,
    shown = c.SDL_WINDOWEVENT_SHOWN,
    hidden = c.SDL_WINDOWEVENT_HIDDEN,
    exposed = c.SDL_WINDOWEVENT_EXPOSED,
    moved = c.SDL_WINDOWEVENT_MOVED,
    resized = c.SDL_WINDOWEVENT_RESIZED,
    size_changed = c.SDL_WINDOWEVENT_SIZE_CHANGED,
    minimized = c.SDL_WINDOWEVENT_MINIMIZED,
    maximized = c.SDL_WINDOWEVENT_MAXIMIZED,
    restored = c.SDL_WINDOWEVENT_RESTORED,
    enter = c.SDL_WINDOWEVENT_ENTER,
    leave = c.SDL_WINDOWEVENT_LEAVE,
    focus_gained = c.SDL_WINDOWEVENT_FOCUS_GAINED,
    focus_lost = c.SDL_WINDOWEVENT_FOCUS_LOST,
    close = c.SDL_WINDOWEVENT_CLOSE,
    take_focus = c.SDL_WINDOWEVENT_TAKE_FOCUS,
    hit_test = c.SDL_WINDOWEVENT_HIT_TEST,

    _,
};

/// event data
const Data = union(Type) {
    shown: void,
    hidden: void,
    exposed: void,
    moved: Point,
    resized: Size,
    size_changed: Size,
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
    none: void,
};

/// window id
window_id: u32 = undefined,

/// event data
data: Data = undefined,

/// timestamp of event
timestamp: u32 = undefined,

pub fn init(e: sdl.WindowEvent) Self {
    return .{
        .window_id = e.window_id,
        .data = @bitCast(Data, e.type),
        .timestamp = e.timestamp,
    };
}
