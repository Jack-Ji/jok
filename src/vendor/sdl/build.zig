const std = @import("std");

pub fn inject(mod: *std.Build.Module, dir: std.Build.LazyPath) void {
    switch (mod.resolved_target.?.result.os.tag) {
        .windows => {
            mod.addIncludePath(dir.path(mod.owner, "c/windows"));
        },
        .macos => {
            mod.addIncludePath(dir.path(mod.owner, "c/macos"));
        },
        .linux, .emscripten => {
            mod.addIncludePath(dir.path(mod.owner, "c/linux"));
        },
        else => unreachable,
    }
}
