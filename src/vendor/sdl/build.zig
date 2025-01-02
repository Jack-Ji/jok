const std = @import("std");

pub fn inject(
    b: *std.Build,
    bin: *std.Build.Step.Compile,
    target: std.Build.ResolvedTarget,
    _: std.builtin.Mode,
    dir: std.Build.LazyPath,
) void {
    switch (target.result.os.tag) {
        .windows => {
            bin.addIncludePath(dir.path(b, "c/windows"));
        },
        .macos => {
            bin.addIncludePath(dir.path(b, "c/macos"));
        },
        .linux => {
            bin.addIncludePath(dir.path(b, "c/linux"));
        },
        else => unreachable,
    }
}
