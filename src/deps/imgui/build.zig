const std = @import("std");
const zgui = @import("zgui/build.zig");

const cflags = &.{"-fno-sanitize=undefined"};

pub fn getZguiModule(
    b: *std.Build,
    target: std.zig.CrossTarget,
    optimize: std.builtin.Mode,
) *std.Build.Module {
    const pkg = zgui.Package.build(b, target, optimize, .{
        .options = .{ .backend = .no_backend },
    });
    return pkg.zgui;
}

pub fn link(exe: *std.Build.CompileStep) void {
    const pkg = zgui.Package.build(
        exe.builder,
        exe.target,
        exe.optimize,
        .{
            .options = .{ .backend = .no_backend },
        },
    );
    exe.addModule("zgui", pkg.zgui);
    pkg.link(exe);

    exe.addIncludePath(thisDir() ++ "/zgui/libs");
    exe.addIncludePath(thisDir() ++ "/c");
    exe.addIncludePath(thisDir() ++ "/c/SDL2");
    exe.addCSourceFile(thisDir() ++ "/c/imgui_impl_sdl.cpp", cflags);
    exe.addCSourceFile(thisDir() ++ "/c/imgui_impl_sdlrenderer.cpp", cflags);
}

inline fn thisDir() []const u8 {
    return comptime std.fs.path.dirname(@src().file) orelse ".";
}
