const std = @import("std");

pub fn inject(
    _: *std.Build,
    _: *std.Build.Step.Compile,
    _: std.Build.ResolvedTarget,
    _: std.builtin.Mode,
    _: std.Build.LazyPath,
) void {}
