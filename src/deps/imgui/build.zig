const std = @import("std");

pub fn link(exe: *std.build.LibExeObjStep) void {
    var flags = std.ArrayList([]const u8).init(std.heap.page_allocator);
    defer flags.deinit();
    flags.append("-Wno-return-type-c-linkage") catch unreachable;
    flags.append("-fno-sanitize=undefined") catch unreachable;

    var lib = exe.builder.addStaticLibrary("imgui", null);
    lib.setBuildMode(exe.build_mode);
    lib.setTarget(exe.target);
    lib.linkLibC();
    lib.linkLibCpp();
    if (exe.target.isWindows()) {
        lib.linkSystemLibrary("winmm");
        lib.linkSystemLibrary("user32");
        lib.linkSystemLibrary("imm32");
        lib.linkSystemLibrary("gdi32");
    }
    lib.addIncludeDir(comptime thisDir() ++ "/imgui/c");
    lib.addCSourceFiles(&.{
        comptime thisDir() ++ "/c/imgui.cpp",
        comptime thisDir() ++ "/c/imgui_demo.cpp",
        comptime thisDir() ++ "/c/imgui_draw.cpp",
        comptime thisDir() ++ "/c/imgui_tables.cpp",
        comptime thisDir() ++ "/c/imgui_widgets.cpp",
        comptime thisDir() ++ "/c/cimgui.cpp",
        comptime thisDir() ++ "/c/imgui_impl_sdlrenderer.cpp",
        comptime thisDir() ++ "/c/imgui_impl_sdlrenderer_wrapper.cpp",
    }, flags.items);
    lib.addCSourceFiles(&.{
        comptime thisDir() ++ "/ext/implot/c/implot.cpp",
        comptime thisDir() ++ "/ext/implot/c/implot_items.cpp",
        comptime thisDir() ++ "/ext/implot/c/implot_demo.cpp",
        comptime thisDir() ++ "/ext/implot/c/cimplot.cpp",
    }, flags.items);
    lib.addCSourceFiles(&.{
        comptime thisDir() ++ "/ext/imnodes/c/imnodes.cpp",
        comptime thisDir() ++ "/ext/imnodes/c/cimnodes.cpp",
    }, flags.items);
    exe.linkLibrary(lib);
}

fn thisDir() []const u8 {
    return std.fs.path.dirname(@src().file) orelse ".";
}
