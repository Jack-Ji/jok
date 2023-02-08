const std = @import("std");
const zgui = @import("zgui/build.zig");

const cflags = &.{"-fno-sanitize=undefined"};

pub fn getZguiModule(b: *std.Build) *std.Build.Module {
    const pkg = zgui.package(b, .{
        .options = .{ .backend = .no_backend },
    });
    return pkg.module;
}

pub fn link(exe: *std.build.LibExeObjStep) void {
    const pkg = zgui.package(exe.builder, .{
        .options = .{ .backend = .no_backend },
    });
    exe.addModule("zgui", pkg.module);
    zgui.link(exe, pkg.options);

    exe.addIncludePath(thisDir() ++ "/c");
    exe.addIncludePath(thisDir() ++ "/c/SDL2");
    exe.addCSourceFile(thisDir() ++ "/c/imgui_impl_sdl.cpp", cflags);
    exe.addCSourceFile(thisDir() ++ "/c/imgui_impl_sdlrenderer.cpp", cflags);
}

inline fn thisDir() []const u8 {
    return comptime std.fs.path.dirname(@src().file) orelse ".";
}
