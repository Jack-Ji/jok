const std = @import("std");
const zgui = @import("zgui/build.zig");
const builtin = @import("builtin");

const cflags = &.{"-fno-sanitize=undefined"};

pub fn getZguiModule(
    b: *std.Build,
    target: std.zig.CrossTarget,
    optimize: std.builtin.Mode,
) *std.Build.Module {
    const pkg = zgui.package(b, target, optimize, .{
        .options = .{ .backend = .no_backend },
    });
    return pkg.zgui;
}

pub fn link(b: *std.Build, exe: *std.Build.CompileStep) void {
    const pkg = zgui.package(
        b,
        exe.target,
        exe.optimize,
        .{
            .options = .{ .backend = .no_backend },
        },
    );
    pkg.link(exe);

    if (exe.target.isWindows()) {
        exe.addIncludePath(.{ .path = thisDir() ++ "/c/SDL2/windows" });
    } else if (exe.target.isLinux()) {
        exe.addIncludePath(.{ .path = thisDir() ++ "/c/SDL2/linux" });
    } else if (exe.target.isDarwin()) {
        exe.addIncludePath(.{ .path = thisDir() ++ "/c/SDL2/macos" });
    } else unreachable;
    exe.addIncludePath(.{ .path = thisDir() ++ "/zgui/libs" });
    exe.addIncludePath(.{ .path = thisDir() ++ "/c" });
    exe.addCSourceFile(.{
        .file = .{ .path = thisDir() ++ "/c/imgui_impl_sdl.cpp" },
        .flags = cflags,
    });
    exe.addCSourceFile(.{
        .file = .{ .path = thisDir() ++ "/c/imgui_impl_sdlrenderer.cpp" },
        .flags = cflags,
    });
}

inline fn thisDir() []const u8 {
    return comptime std.fs.path.dirname(@src().file) orelse ".";
}
