const std = @import("std");

pub fn inject(mod: *std.Build.Module, dir: std.Build.LazyPath) void {
    if (mod.resolved_target.?.result.os.tag == .windows) {
        mod.addCMacro("MA_API", "__declspec(dllexport)");
        mod.addCMacro("ZAUDIO_API", "__declspec(dllexport)");
    }

    mod.addIncludePath(dir.path(mod.owner, "c/miniaudio"));
    if (mod.resolved_target.?.result.os.tag == .linux) {
        mod.linkSystemLibrary("pthread", .{});
        mod.linkSystemLibrary("m", .{});
        mod.linkSystemLibrary("dl", .{});
    }

    mod.addCSourceFile(.{
        .file = dir.path(mod.owner, "c/zaudio.c"),
        .flags = &.{
            "-std=c99",
            "-fno-sanitize=undefined",
        },
    });
    mod.addCSourceFile(.{
        .file = dir.path(mod.owner, "c/miniaudio/miniaudio.c"),
        .flags = &.{
            "-DMA_NO_ENCODING",
            "-DMA_NO_NULL",
            "-DMA_NO_JACK",
            "-DMA_NO_DSOUND",
            "-DMA_NO_WINMM",
            "-std=gnu99",
            "-fno-sanitize=undefined",
            if (mod.resolved_target.?.result.os.tag == .macos) "-DMA_NO_RUNTIME_LINKING" else "",
        },
    });
}
