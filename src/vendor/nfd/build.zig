const std = @import("std");

pub fn inject(
    b: *std.Build,
    bin: *std.Build.Step.Compile,
    target: std.Build.ResolvedTarget,
    _: std.builtin.Mode,
    dir: std.Build.LazyPath,
) void {
    const cflags = &.{
        "-Wno-return-type-c-linkage",
        "-fno-sanitize=undefined",
    };

    if (bin.rootModuleTarget().os.tag == .windows) {
        bin.linkSystemLibrary("shell32");
        bin.linkSystemLibrary("ole32");
        bin.linkSystemLibrary("uuid"); // needed by MinGW
    } else if (target.result.os.tag == .macos) {
        bin.linkFramework("AppKit");
    } else if (bin.rootModuleTarget().os.tag == .linux) {
        bin.linkSystemLibrary("atk-1.0");
        bin.linkSystemLibrary("gdk-3");
        bin.linkSystemLibrary("gtk-3");
        bin.linkSystemLibrary("glib-2.0");
        bin.linkSystemLibrary("gobject-2.0");
    } else unreachable;

    bin.addIncludePath(dir.path(b, "c/include"));
    bin.addCSourceFile(.{
        .file = dir.path(b, "c/nfd_common.c"),
        .flags = cflags,
    });
    if (target.result.os.tag == .windows) {
        bin.addCSourceFile(.{
            .file = dir.path(b, "c/nfd_win.cpp"),
            .flags = cflags,
        });
    } else if (target.result.os.tag == .macos) {
        bin.addCSourceFile(.{
            .file = dir.path(b, "c/nfd_cocoa.m"),
            .flags = cflags,
        });
    } else if (target.result.os.tag == .linux) {
        bin.addCSourceFile(.{
            .file = dir.path(b, "c/nfd_gtk.c"),
            .flags = cflags,
        });
    } else unreachable;
}
