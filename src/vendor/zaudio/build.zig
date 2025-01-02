const std = @import("std");

pub fn inject(
    b: *std.Build,
    bin: *std.Build.Step.Compile,
    target: std.Build.ResolvedTarget,
    _: std.builtin.Mode,
    dir: std.Build.LazyPath,
) void {
    bin.addIncludePath(dir.path(b, "c/miniaudio"));
    if (target.result.os.tag == .macos) {
        bin.linkFramework("CoreAudio");
        bin.linkFramework("CoreFoundation");
        bin.linkFramework("AudioUnit");
        bin.linkFramework("AudioToolbox");
    } else if (target.result.os.tag == .linux) {
        bin.linkSystemLibrary("pthread");
        bin.linkSystemLibrary("m");
        bin.linkSystemLibrary("dl");
    }

    bin.addCSourceFile(.{
        .file = dir.path(b, "c/zaudio.c"),
        .flags = &.{"-std=c99"},
    });
    bin.addCSourceFile(.{
        .file = dir.path(b, "c/miniaudio/miniaudio.c"),
        .flags = &.{
            "-DMA_NO_WEBAUDIO",
            "-DMA_NO_ENCODING",
            "-DMA_NO_NULL",
            "-DMA_NO_JACK",
            "-DMA_NO_DSOUND",
            "-DMA_NO_WINMM",
            "-std=c99",
            "-fno-sanitize=undefined",
            if (target.result.os.tag == .macos) "-DMA_NO_RUNTIME_LINKING" else "",
        },
    });
}
