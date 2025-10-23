const std = @import("std");

pub fn inject(mod: *std.Build.Module) void {
    const dir = mod.owner.path(std.fs.path.dirname(@src().file).?);
    mod.addCSourceFile(.{
        .file = dir.path(mod.owner, "c/stb_wrapper.c"),
        .flags = &.{
            "-Wno-return-type-c-linkage",
            "-fno-sanitize=undefined",
        },
    });
}
