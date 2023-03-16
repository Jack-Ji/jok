const std = @import("std");

pub fn link(exe: *std.Build.CompileStep) void {
    var flags = std.ArrayList([]const u8).init(std.heap.page_allocator);
    defer flags.deinit();
    flags.append("-Wno-return-type-c-linkage") catch unreachable;
    flags.append("-fno-sanitize=undefined") catch unreachable;

    if (exe.target.isDarwin()) {
        exe.linkFramework("AppKit");
    } else if (exe.target.isWindows()) {
        exe.linkSystemLibrary("shell32");
        exe.linkSystemLibrary("ole32");
        exe.linkSystemLibrary("uuid"); // needed by MinGW
    } else {
        exe.linkSystemLibrary("atk-1.0");
        exe.linkSystemLibrary("gdk-3");
        exe.linkSystemLibrary("gtk-3");
        exe.linkSystemLibrary("glib-2.0");
        exe.linkSystemLibrary("gobject-2.0");
    }
    exe.addIncludePath(comptime thisDir() ++ "/c/include");
    exe.addCSourceFile(comptime thisDir() ++ "/c/nfd_common.c", flags.items);
    if (exe.target.isDarwin()) {
        exe.addCSourceFile(comptime thisDir() ++ "/c/nfd_cocoa.m", flags.items);
    } else if (exe.target.isWindows()) {
        exe.addCSourceFile(comptime thisDir() ++ "/c/nfd_win.cpp", flags.items);
    } else {
        exe.addCSourceFile(comptime thisDir() ++ "/c/nfd_gtk.c", flags.items);
    }
}

fn thisDir() []const u8 {
    return std.fs.path.dirname(@src().file) orelse ".";
}
