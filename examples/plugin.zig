const std = @import("std");

pub const PluginType = struct {
    whoAreYou: *const fn () callconv(.c) [*c]const u8 = whoAreYou,
    howFast: *const fn () callconv(.c) f32 = howFast,
};

export fn whoAreYou() [*c]const u8 {
    return "I'm a plugin!";
}

export fn howFast() f32 {
    return 150.0;
}
