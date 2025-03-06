const std = @import("std");

pub fn inject(mod: *std.Build.Module, dir: std.Build.LazyPath) void {
    const cflags = &.{
        "-fno-sanitize=undefined",
        "-Wno-elaborated-enum-base",
        "-Wno-error=date-time",
    };

    if (mod.resolved_target.?.result.os.tag == .windows) {
        mod.addCMacro("IMGUI_API", "__declspec(dllexport)");
        mod.addCMacro("IMPLOT_API", "__declspec(dllexport)");
        mod.addCMacro("ZGUI_API", "__declspec(dllexport)");
    }

    const emscripten = mod.resolved_target.?.result.os.tag == .emscripten;
    if (emscripten) {
        mod.addCMacro("__EMSCRIPTEN__", "1");
        mod.addCMacro("__EMSCRIPTEN_major__", "3");
        mod.addCMacro("__EMSCRIPTEN_minor__", "1");
        mod.stack_protector = false;
    } else {
        mod.link_libc = true;
        if (mod.resolved_target.?.result.abi != .msvc) mod.link_libcpp = true;
    }

    mod.addIncludePath(dir.path(mod.owner, "c/imgui"));
    mod.addIncludePath(dir.path(mod.owner, "c/implot"));
    mod.addIncludePath(dir.path(mod.owner, "c/imguizmo"));
    mod.addIncludePath(dir.path(mod.owner, "c/node_editor"));
    mod.addIncludePath(dir.path(mod.owner, "c/impl"));
    mod.addCSourceFiles(.{
        .root = dir,
        .files = &.{
            "c/imgui/imgui.cpp",
            "c/imgui/imgui_widgets.cpp",
            "c/imgui/imgui_tables.cpp",
            "c/imgui/imgui_draw.cpp",
            "c/imgui/imgui_demo.cpp",
            "c/implot/implot_demo.cpp",
            "c/implot/implot.cpp",
            "c/implot/implot_items.cpp",
            "c/imguizmo/ImGuizmo.cpp",
            "c/node_editor/crude_json.cpp",
            "c/node_editor/imgui_canvas.cpp",
            "c/node_editor/imgui_node_editor_api.cpp",
            "c/node_editor/imgui_node_editor.cpp",
            "c/zwrapper/zgui.cpp",
            "c/zwrapper/zplot.cpp",
            "c/zwrapper/zgizmo.cpp",
            "c/zwrapper/znode_editor.cpp",
            "c/impl/imgui_impl_sdl2.cpp",
            "c/impl/imgui_impl_sdlrenderer2.cpp",
        },
        .flags = cflags,
    });
}
