const std = @import("std");

pub fn inject(mod: *std.Build.Module, dir: std.Build.LazyPath) void {
    if (mod.resolved_target.?.result.os.tag == .windows) {
        mod.addCMacro("STBTT_DEF", "__declspec(dllexport)");
        mod.addCMacro("STBRP_DEF", "__declspec(dllexport)");
        mod.addCMacro("STBIDEF", "__declspec(dllexport)");
        mod.addCMacro("STBIRDEF", "__declspec(dllexport)");
        mod.addCMacro("STBIWDEF", "__declspec(dllexport)");
    }

    mod.addCSourceFile(.{
        .file = dir.path(mod.owner, "c/stb_wrapper.c"),
        .flags = &.{
            "-Wno-return-type-c-linkage",
            "-fno-sanitize=undefined",
        },
    });
}
