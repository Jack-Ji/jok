const std = @import("std");

pub fn inject(mod: *std.Build.Module) void {
    const dir = mod.owner.path(std.fs.path.dirname(@src().file).?);
    const cflags = &.{
        "-fno-sanitize=undefined",
        "-Wno-elaborated-enum-base",
        "-Wno-error=date-time",
    };

    mod.link_libc = true;
    if (mod.resolved_target.?.result.abi != .msvc)
        mod.link_libcpp = true;

    const sdl_dep = mod.owner.dependency("sdl", .{});
    mod.addIncludePath(sdl_dep.path("include"));
    mod.addIncludePath(dir.path(mod.owner, "c/imgui"));
    mod.addIncludePath(dir.path(mod.owner, "c/implot"));
    mod.addIncludePath(dir.path(mod.owner, "c/imgui_knobs"));
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
            "c/imgui_knobs/imgui-knobs.cpp",
            "c/imguizmo/ImGuizmo.cpp",
            "c/node_editor/crude_json.cpp",
            "c/node_editor/imgui_canvas.cpp",
            "c/node_editor/imgui_node_editor_api.cpp",
            "c/node_editor/imgui_node_editor.cpp",
            "c/zwrapper/zgui.cpp",
            "c/zwrapper/zplot.cpp",
            "c/zwrapper/zknobs.cpp",
            "c/zwrapper/zgizmo.cpp",
            "c/zwrapper/znode_editor.cpp",
            "c/impl/imgui_impl_sdl3.cpp",
            "c/impl/imgui_impl_sdlrenderer3.cpp",
        },
        .flags = cflags,
    });
}
