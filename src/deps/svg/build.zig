const std = @import("std");

pub fn link(exe: *std.Build.Step.Compile) void {
    exe.addCSourceFile(.{
        .file = .{ .path = thisDir() ++ "/c/wrapper.c" },
        .flags = &.{
            "-Wno-return-type-c-linkage",
            "-fno-sanitize=undefined",
        },
    });
}

inline fn thisDir() []const u8 {
    return comptime std.fs.path.dirname(@src().file) orelse ".";
}
