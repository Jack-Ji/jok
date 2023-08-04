const std = @import("std");

pub fn link(exe: *std.Build.CompileStep) void {
    var flags = std.ArrayList([]const u8).init(std.heap.page_allocator);
    defer flags.deinit();
    flags.append("-Wno-return-type-c-linkage") catch unreachable;
    flags.append("-fno-sanitize=undefined") catch unreachable;

    exe.addCSourceFile(.{
        .file = .{ .path = comptime thisDir() ++ "/c/stb_wrapper.c" },
        .flags = flags.items,
    });
}

fn thisDir() []const u8 {
    return std.fs.path.dirname(@src().file) orelse ".";
}
