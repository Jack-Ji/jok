const std = @import("std");

pub fn inject(mod: *std.Build.Module, dir: std.Build.LazyPath) void {
    if (mod.resolved_target.?.result.os.tag == .windows) {
        //mod.addCMacro("STBIRDEF", "__declspec(dllexport)");
    }

    mod.addCSourceFile(.{
        .file = dir.path(mod.owner, "c/wrapper.c"),
        .flags = &.{
            "-Wno-return-type-c-linkage",
            "-fno-sanitize=undefined",
        },
    });
}
