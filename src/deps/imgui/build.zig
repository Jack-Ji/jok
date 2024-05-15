const std = @import("std");
const zgui = @import("zgui/build.zig");
const builtin = @import("builtin");

const cflags = &.{"-fno-sanitize=undefined"};

pub fn getZguiModule(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.Mode,
) *std.Build.Module {
    const pkg = zgui.package(b, target, optimize, .{
        .options = .{ .backend = .no_backend },
    });
    return pkg.zgui;
}

pub fn link(b: *std.Build, exe: *std.Build.Step.Compile) void {
    const pkg = zgui.package(
        b,
        exe.root_module.resolved_target.?,
        exe.root_module.optimize.?,
        .{
            .options = .{ .backend = .no_backend },
        },
    );
    pkg.link(exe);

    if (exe.rootModuleTarget().os.tag == .windows) {
        exe.addIncludePath(.{ .cwd_relative = thisDir() ++ "/c/SDL2/windows" });
    } else if (exe.rootModuleTarget().os.tag == .linux) {
        exe.addIncludePath(.{ .cwd_relative = thisDir() ++ "/c/SDL2/linux" });
    } else if (exe.rootModuleTarget().isDarwin()) {
        exe.addIncludePath(.{ .cwd_relative = thisDir() ++ "/c/SDL2/macos" });
    } else unreachable;
    exe.addIncludePath(.{ .cwd_relative = thisDir() ++ "/zgui/libs" });
    exe.addIncludePath(.{ .cwd_relative = thisDir() ++ "/c" });
    exe.addCSourceFile(.{
        .file = .{ .cwd_relative = thisDir() ++ "/c/imgui_impl_sdl.cpp" },
        .flags = cflags,
    });
    exe.addCSourceFile(.{
        .file = .{ .cwd_relative = thisDir() ++ "/c/imgui_impl_sdlrenderer.cpp" },
        .flags = cflags,
    });
}

inline fn thisDir() []const u8 {
    return comptime std.fs.path.dirname(@src().file) orelse ".";
}
