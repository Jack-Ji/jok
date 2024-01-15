const std = @import("std");

pub fn link(exe: *std.Build.Step.Compile) void {
    exe.addCSourceFile(.{
        .file = .{ .path = comptime thisDir() ++ "/c/stb_wrapper.c" },
        .flags = &.{
            "-Wno-return-type-c-linkage",
            "-fno-sanitize=undefined",
        },
    });
}

fn thisDir() []const u8 {
    return std.fs.path.dirname(@src().file) orelse ".";
}
