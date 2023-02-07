const std = @import("std");
const zgui = @import("zgui/build.zig");

const cflags = &.{"-fno-sanitize=undefined"};

pub fn link(exe: *std.build.LibExeObjStep) void {
    zgui.link(exe, .{ .backend = .no_backend });

    exe.addIncludePath(thisDir() ++ "/c");
    exe.addIncludePath(thisDir() ++ "/c/SDL2");
    exe.addCSourceFile(thisDir() ++ "/c/imgui_impl_sdl.cpp", cflags);
    exe.addCSourceFile(thisDir() ++ "/c/imgui_impl_sdlrenderer.cpp", cflags);
}

inline fn thisDir() []const u8 {
    return comptime std.fs.path.dirname(@src().file) orelse ".";
}
