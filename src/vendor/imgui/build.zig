const std = @import("std");

pub fn inject(
    b: *std.Build,
    bin: *std.Build.Step.Compile,
    target: std.Build.ResolvedTarget,
    _: std.builtin.Mode,
    dir: std.Build.LazyPath,
) void {
    const cflags = &.{
        "-fno-sanitize=undefined",
        "-Wno-elaborated-enum-base",
        "-Wno-error=date-time",
    };

    const emscripten = target.result.os.tag == .emscripten;
    if (emscripten) {
        bin.root_module.addCMacro("__EMSCRIPTEN__", "1");
        bin.root_module.addCMacro("__EMSCRIPTEN_major__", "3");
        bin.root_module.addCMacro("__EMSCRIPTEN_minor__", "1");
        bin.root_module.stack_protector = false;
    } else {
        bin.linkLibC();
        if (target.result.abi != .msvc) bin.linkLibCpp();
    }

    bin.addIncludePath(dir.path(b, "c/imgui"));
    bin.addIncludePath(dir.path(b, "c/implot"));
    bin.addIncludePath(dir.path(b, "c/imguizmo"));
    bin.addIncludePath(dir.path(b, "c/node_editor"));
    bin.addIncludePath(dir.path(b, "c/impl"));
    bin.addCSourceFiles(.{
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
