const std = @import("std");

pub fn link(exe: *std.Build.Step.Compile) void {
    var flags = std.ArrayList([]const u8).init(std.heap.page_allocator);
    defer flags.deinit();
    flags.append("-Wno-return-type-c-linkage") catch unreachable;
    flags.append("-fno-sanitize=undefined") catch unreachable;

    if (exe.rootModuleTarget().isDarwin()) {
        exe.linkFramework("AppKit");
    } else if (exe.rootModuleTarget().os.tag == .windows) {
        exe.linkSystemLibrary("shell32");
        exe.linkSystemLibrary("ole32");
        exe.linkSystemLibrary("uuid"); // needed by MinGW
    } else if (exe.rootModuleTarget().os.tag == .linux) {
        exe.linkSystemLibrary("atk-1.0");
        exe.linkSystemLibrary("gdk-3");
        exe.linkSystemLibrary("gtk-3");
        exe.linkSystemLibrary("glib-2.0");
        exe.linkSystemLibrary("gobject-2.0");
    } else unreachable;
    exe.addIncludePath(.{ .path = thisDir() ++ "/c/include" });
    exe.addCSourceFile(.{
        .file = .{ .path = thisDir() ++ "/c/nfd_common.c" },
        .flags = flags.items,
    });
    if (exe.rootModuleTarget().isDarwin()) {
        exe.addCSourceFile(.{
            .file = .{ .path = thisDir() ++ "/c/nfd_cocoa.m" },
            .flags = flags.items,
        });
    } else if (exe.rootModuleTarget().os.tag == .windows) {
        exe.addCSourceFile(.{
            .file = .{ .path = thisDir() ++ "/c/nfd_win.cpp" },
            .flags = flags.items,
        });
    } else {
        exe.addCSourceFile(.{
            .file = .{ .path = thisDir() ++ "/c/nfd_gtk.c" },
            .flags = flags.items,
        });
    }
}

inline fn thisDir() []const u8 {
    return comptime std.fs.path.dirname(@src().file) orelse ".";
}
