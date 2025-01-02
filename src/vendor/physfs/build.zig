const std = @import("std");

pub fn inject(
    _: *std.Build,
    bin: *std.Build.Step.Compile,
    target: std.Build.ResolvedTarget,
    _: std.builtin.Mode,
    dir: std.Build.LazyPath,
) void {
    const cflags = &.{
        "-Wno-return-type-c-linkage",
        "-fno-sanitize=undefined",
    };

    bin.addCSourceFiles(.{
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
    if (target.result.os.tag == .windows) {
        bin.linkSystemLibrary("advapi32");
        bin.linkSystemLibrary("shell32");
    } else if (target.result.os.tag == .macos) {
        bin.addCSourceFiles(.{
            .root = dir,
            .files = &.{
                "c/physfs_platform_apple.m",
            },
            .flags = cflags,
        });
        bin.linkSystemLibrary("objc");
        bin.linkFramework("IOKit");
        bin.linkFramework("Foundation");
    } else if (target.result.os.tag == .linux) {
        bin.linkSystemLibrary("pthread");
    } else unreachable;
}
