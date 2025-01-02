const std = @import("std");

pub fn inject(
    b: *std.Build,
    bin: *std.Build.Step.Compile,
    _: std.Build.ResolvedTarget,
    _: std.builtin.Mode,
    dir: std.Build.LazyPath,
) void {
    bin.addIncludePath(dir.path(b, "c/FastNoiseLite"));
    bin.addCSourceFile(.{
        .file = dir.path(b, "c/FastNoiseLite/FastNoiseLite.c"),
        .flags = &.{ "-std=c99", "-fno-sanitize=undefined" },
    });
}
