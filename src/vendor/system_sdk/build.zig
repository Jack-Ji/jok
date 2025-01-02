const std = @import("std");

pub fn inject(
    b: *std.Build,
    bin: *std.Build.Step.Compile,
    target: std.Build.ResolvedTarget,
    _: std.builtin.Mode,
    dir: std.Build.LazyPath,
) void {
    switch (target.result.os.tag) {
        .macos => {
            bin.addFrameworkPath(dir.path(b, "macos12/System/Library/Frameworks"));
            bin.addSystemIncludePath(dir.path(b, "macos12/usr/include"));
            bin.addLibraryPath(dir.path(b, "macos12/usr/lib"));
        },
        .linux => {
            bin.addSystemIncludePath(dir.path(b, "linux/include"));
            bin.addSystemIncludePath(dir.path(b, "linux/include/wayland"));
            if (target.result.cpu.arch.isX86()) {
                bin.addLibraryPath(dir.path(b, "linux/lib/x86_64-linux-gnu"));
            } else {
                bin.addLibraryPath(dir.path(b, "linux/lib/aarch64-linux-gnu"));
            }
        },
        else => {},
    }
}
