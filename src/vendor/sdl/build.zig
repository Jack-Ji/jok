const std = @import("std");

pub fn inject(mod: *std.Build.Module, dir: std.Build.LazyPath) void {
    _ = dir;

    const sdl_dep = mod.owner.dependency("sdl", .{});
    mod.addIncludePath(sdl_dep.path("include"));
}
