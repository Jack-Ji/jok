const std = @import("std");

pub fn inject(
    b: *std.Build,
    bin: *std.Build.Step.Compile,
    target: std.Build.ResolvedTarget,
    _: std.builtin.Mode,
    dir: std.Build.LazyPath,
) void {
    bin.addIncludePath(dir.path(b, "c/tracy/tracy"));
    bin.addCSourceFile(.{
        .file = dir.path(b, "c/tracy/TracyClient.cpp"),
        .flags = &.{
            "-DTRACY_ENABLE",
            "-DTRACY_FIBERS",
            "-fno-sanitize=undefined",
        },
    });
    if (target.result.abi != .msvc) {
        bin.linkLibCpp();
    } else {
        bin.root_module.addCMacro("fileno", "_fileno");
    }
    if (target.result.os.tag == .windows) {
        bin.linkSystemLibrary("ws2_32");
        bin.linkSystemLibrary("dbghelp");
    }
}
