const std = @import("std");

pub fn inject(
    b: *std.Build,
    bin: *std.Build.Step.Compile,
    _: std.Build.ResolvedTarget,
    _: std.builtin.Mode,
    dir: std.Build.LazyPath,
) void {
    bin.addCSourceFile(.{
        .file = dir.path(b, "c/wrapper.c"),
        .flags = &.{
            "-Wno-return-type-c-linkage",
            "-fno-sanitize=undefined",
        },
    });
}
