const std = @import("std");

pub fn inject(mod: *std.Build.Module) void {
    const dir = mod.owner.path(std.fs.path.dirname(@src().file).?);
    const cflags = &.{
        "-Wno-return-type-c-linkage",
        "-fno-sanitize=undefined",
    };

    mod.addCSourceFiles(.{
        .root = dir,
        .files = &.{
            "c/physfs.c",
            "c/physfs_byteorder.c",
            "c/physfs_unicode.c",
            "c/physfs_platform_posix.c",
            "c/physfs_platform_unix.c",
            "c/physfs_platform_windows.c",
            "c/physfs_platform_ogc.c",
            "c/physfs_platform_os2.c",
            "c/physfs_platform_qnx.c",
            "c/physfs_platform_android.c",
            "c/physfs_platform_playdate.c",
            "c/physfs_archiver_dir.c",
            "c/physfs_archiver_unpacked.c",
            "c/physfs_archiver_grp.c",
            "c/physfs_archiver_hog.c",
            "c/physfs_archiver_7z.c",
            "c/physfs_archiver_mvl.c",
            "c/physfs_archiver_qpak.c",
            "c/physfs_archiver_wad.c",
            "c/physfs_archiver_csm.c",
            "c/physfs_archiver_zip.c",
            "c/physfs_archiver_slb.c",
            "c/physfs_archiver_iso9660.c",
            "c/physfs_archiver_vdf.c",
            "c/physfs_archiver_lec3d.c",
        },
        .flags = cflags,
    });
    if (mod.resolved_target.?.result.os.tag == .windows) {
        mod.linkSystemLibrary("advapi32", .{});
        mod.linkSystemLibrary("shell32", .{});
    } else if (mod.resolved_target.?.result.os.tag == .macos) {
        mod.addCSourceFiles(.{
            .root = dir,
            .files = &.{
                "c/physfs_platform_apple.m",
            },
            .flags = cflags,
        });
        mod.linkSystemLibrary("objc", .{});
        mod.linkFramework("IOKit", .{});
        mod.linkFramework("Foundation", .{});
    } else if (mod.resolved_target.?.result.os.tag == .linux) {
        mod.linkSystemLibrary("pthread", .{});
    }
}
