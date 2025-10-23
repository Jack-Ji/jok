const std = @import("std");

pub fn inject(mod: *std.Build.Module) void {
    const dir = mod.owner.path(std.fs.path.dirname(@src().file).?);
    mod.addIncludePath(dir.path(mod.owner, "c/par_shapes"));
    mod.addCSourceFile(.{
        .file = dir.path(mod.owner, "c/par_shapes/par_shapes.c"),
        .flags = &.{
            "-std=c99",
            "-fno-sanitize=undefined",
            "-DPAR_SHAPES_T=uint32_t",
        },
    });

    mod.addCSourceFiles(.{
        .root = dir,
        .files = &.{
            "c/meshoptimizer/clusterizer.cpp",
            "c/meshoptimizer/indexgenerator.cpp",
            "c/meshoptimizer/vcacheoptimizer.cpp",
            "c/meshoptimizer/vcacheanalyzer.cpp",
            "c/meshoptimizer/vfetchoptimizer.cpp",
            "c/meshoptimizer/vfetchanalyzer.cpp",
            "c/meshoptimizer/overdrawoptimizer.cpp",
            "c/meshoptimizer/overdrawanalyzer.cpp",
            "c/meshoptimizer/simplifier.cpp",
            "c/meshoptimizer/allocator.cpp",
        },
        .flags = &.{},
    });

    mod.addIncludePath(dir.path(mod.owner, "c/cgltf"));
    mod.addCSourceFile(.{
        .file = dir.path(mod.owner, "c/cgltf/cgltf.c"),
        .flags = &.{
            "-std=c99",
            "-fno-sanitize=undefined",
        },
    });
}
