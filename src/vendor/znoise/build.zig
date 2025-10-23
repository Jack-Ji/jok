const std = @import("std");

pub fn inject(mod: *std.Build.Module) void {
    const dir = mod.owner.path(std.fs.path.dirname(@src().file).?);
    mod.addIncludePath(dir.path(mod.owner, "c/FastNoiseLite"));
    mod.addCSourceFile(.{
        .file = dir.path(mod.owner, "c/FastNoiseLite/FastNoiseLite.c"),
        .flags = &.{ "-std=c99", "-fno-sanitize=undefined" },
    });
}
