const std = @import("std");

pub fn link(exe: *std.Build.CompileStep) void {
    exe.addIncludePath(.{ .path = thisDir() ++ "/zaudio/libs/miniaudio" });
    if (exe.target.isLinux()) {
        exe.linkSystemLibraryName("pthread");
        exe.linkSystemLibraryName("m");
        exe.linkSystemLibraryName("dl");
    }

    exe.addCSourceFile(.{
        .file = .{ .path = thisDir() ++ "/zaudio/src/zaudio.c" },
        .flags = &.{"-std=c99"},
    });
    exe.addCSourceFile(.{
        .file = .{ .path = thisDir() ++ "/c/sdl_impl.c" },
        .flags = &.{
            "-std=c99",
            "-fno-sanitize=undefined",
        },
    });
}

inline fn thisDir() []const u8 {
    return comptime std.fs.path.dirname(@src().file) orelse ".";
}
