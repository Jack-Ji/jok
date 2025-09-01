const std = @import("std");

pub fn inject(mod: *std.Build.Module, dir: std.Build.LazyPath) void {
    switch (mod.resolved_target.?.result.os.tag) {
        .macos => {
            mod.addFrameworkPath(dir.path(mod.owner, "macos12/System/Library/Frameworks"));
            mod.addSystemIncludePath(dir.path(mod.owner, "macos12/usr/include"));
            mod.addLibraryPath(dir.path(mod.owner, "macos12/usr/lib"));
        },
        else => {},
    }
}
