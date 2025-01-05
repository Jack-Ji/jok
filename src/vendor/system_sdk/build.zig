const std = @import("std");

pub fn inject(mod: *std.Build.Module, dir: std.Build.LazyPath) void {
    switch (mod.resolved_target.?.result.os.tag) {
        .macos => {
            mod.addFrameworkPath(dir.path(mod.owner, "macos12/System/Library/Frameworks"));
            mod.addSystemIncludePath(dir.path(mod.owner, "macos12/usr/include"));
            mod.addLibraryPath(dir.path(mod.owner, "macos12/usr/lib"));
        },
        .linux => {
            mod.addSystemIncludePath(dir.path(mod.owner, "linux/include"));
            mod.addSystemIncludePath(dir.path(mod.owner, "linux/include/wayland"));
            if (mod.resolved_target.?.result.cpu.arch.isX86()) {
                mod.addLibraryPath(dir.path(mod.owner, "linux/lib/x86_64-linux-gnu"));
            } else {
                mod.addLibraryPath(dir.path(mod.owner, "linux/lib/aarch64-linux-gnu"));
            }
        },
        else => {},
    }
}
