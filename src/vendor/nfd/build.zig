const std = @import("std");

pub fn inject(mod: *std.Build.Module, dir: std.Build.LazyPath) void {
    const cflags = &.{
        "-Wno-return-type-c-linkage",
        "-fno-sanitize=undefined",
    };

    if (mod.resolved_target.?.result.os.tag == .windows) {
        mod.linkSystemLibrary("shell32", .{});
        mod.linkSystemLibrary("ole32", .{});
        mod.linkSystemLibrary("uuid", .{}); // needed by MinGW
    } else if (mod.resolved_target.?.result.os.tag == .macos) {
        mod.linkFramework("AppKit", .{});
    } else if (mod.resolved_target.?.result.os.tag == .linux) {
        mod.linkSystemLibrary("atk-1.0", .{});
        mod.linkSystemLibrary("gdk-3", .{});
        mod.linkSystemLibrary("gtk-3", .{});
        mod.linkSystemLibrary("glib-2.0", .{});
        mod.linkSystemLibrary("gobject-2.0", .{});
    } else unreachable;

    mod.addIncludePath(dir.path(mod.owner, "c/include"));
    mod.addCSourceFile(.{
        .file = dir.path(mod.owner, "c/nfd_common.c"),
        .flags = cflags,
    });
    if (mod.resolved_target.?.result.os.tag == .windows) {
        mod.addCSourceFile(.{
            .file = dir.path(mod.owner, "c/nfd_win.cpp"),
            .flags = cflags,
        });
    } else if (mod.resolved_target.?.result.os.tag == .macos) {
        mod.addCSourceFile(.{
            .file = dir.path(mod.owner, "c/nfd_cocoa.m"),
            .flags = cflags,
        });
    } else if (mod.resolved_target.?.result.os.tag == .linux) {
        mod.addCSourceFile(.{
            .file = dir.path(mod.owner, "c/nfd_gtk.c"),
            .flags = cflags,
        });
    } else unreachable;
}
