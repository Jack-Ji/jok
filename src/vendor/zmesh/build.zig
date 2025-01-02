const std = @import("std");

pub fn inject(
    b: *std.Build,
    bin: *std.Build.Step.Compile,
    _: std.Build.ResolvedTarget,
    _: std.builtin.Mode,
    dir: std.Build.LazyPath,
) void {
    bin.addIncludePath(dir.path(b, "c/par_shapes"));
    bin.addCSourceFile(.{
        .file = dir.path(b, "c/par_shapes/par_shapes.c"),
        .flags = &.{
            "-std=c99",
            "-fno-sanitize=undefined",
            "-DPAR_SHAPES_T=uint32_t",
        },
    });

    bin.addCSourceFiles(.{
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
        .flags = &.{""},
    });

    bin.addIncludePath(dir.path(b, "c/cgltf"));
    bin.addCSourceFile(.{
        .file = dir.path(b, "c/cgltf/cgltf.c"),
        .flags = &.{"-std=c99"},
    });
}
