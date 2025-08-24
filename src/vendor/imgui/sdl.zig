const std = @import("std");
const jok = @import("../../jok.zig");
const sdl = jok.sdl;
const gui = @import("main.zig");

pub fn init(ctx: jok.Context, enable_ini_file: bool) void {
    gui.init(ctx.allocator());

    const window = ctx.window();
    const renderer = ctx.renderer();
    if (!ImGui_ImplSDL3_InitForSDLRenderer(window.ptr, renderer.ptr)) {
        unreachable;
    }

    if (!ImGui_ImplSDLRenderer3_Init(renderer.ptr)) {
        unreachable;
    }

    if (!enable_ini_file) {
        gui.io.setIniFilename(null);
    }

    const font = gui.io.addFontFromMemory(jok.font.DebugFont.font_data, 16);
    gui.io.setDefaultFont(font);

    // Disable automatic mouse state updating
    gui.io.setConfigFlags(.{ .no_mouse_cursor_change = true });

    gui.plot.init();
}

pub fn deinit() void {
    gui.plot.deinit();
    ImGui_ImplSDLRenderer3_Shutdown();
    ImGui_ImplSDL3_Shutdown();
    gui.deinit();
}

pub fn newFrame(ctx: jok.Context) void {
    ImGui_ImplSDLRenderer3_NewFrame();
    ImGui_ImplSDL3_NewFrame();

    const fbsize = ctx.renderer().getOutputSize() catch unreachable;
    gui.io.setDisplaySize(
        fbsize.getWidthFloat(),
        fbsize.getHeightFloat(),
    );
    gui.io.setDisplayFramebufferScale(1.0, 1.0);

    gui.newFrame();
}

pub fn draw(ctx: jok.Context) void {
    const renderer = ctx.renderer();
    gui.render();
    ImGui_ImplSDLRenderer3_RenderDrawData(gui.getDrawData(), renderer.ptr);
}

pub fn processEvent(event: sdl.c.SDL_Event) bool {
    return ImGui_ImplSDL3_ProcessEvent(&event);
}

pub fn renderDrawList(ctx: jok.Context, dl: gui.DrawList) void {
    if (dl.getCmdBufferLength() <= 0) return;

    const rd = ctx.renderer();
    const csz = ctx.getCanvasSize();
    const old_clip = rd.getClipRegion();
    defer rd.setClipRegion(old_clip) catch unreachable;

    const commands = dl.getCmdBufferData()[0..@as(u32, @intCast(dl.getCmdBufferLength()))];
    const vs_ptr = dl.getVertexBufferData();
    const vs_count = dl.getVertexBufferLength();
    const is_ptr = dl.getIndexBufferData();

    for (commands) |cmd| {
        if (cmd.user_callback != null or cmd.elem_count == 0) continue;

        // Apply clip region
        var clip_region: jok.Region = undefined;
        clip_region.x = @intFromFloat(std.math.clamp(cmd.clip_rect[0], 0.0, csz.getWidthFloat()));
        clip_region.y = @intFromFloat(std.math.clamp(cmd.clip_rect[1], 0.0, csz.getHeightFloat()));
        clip_region.width = @intFromFloat(@min(@as(f32, @floatFromInt(csz.width - clip_region.x)), cmd.clip_rect[2] - cmd.clip_rect[0]));
        clip_region.height = @intFromFloat(@min(@as(f32, @floatFromInt(csz.height - clip_region.y)), cmd.clip_rect[3] - cmd.clip_rect[1]));
        if (clip_region.width <= 0 or clip_region.height <= 0) continue;
        rd.setClipRegion(clip_region) catch unreachable;

        // Bind texture and draw
        const tex = jok.Texture{ .ptr = @ptrCast(@alignCast(cmd.texture_id)) };
        var indices: []u32 = undefined;
        indices.ptr = @ptrCast(is_ptr + cmd.idx_offset);
        indices.len = @intCast(cmd.elem_count);
        rd.drawTrianglesRaw(
            tex,
            @ptrCast(vs_ptr + @as(usize, cmd.vtx_offset)),
            @intCast(@as(u32, @intCast(vs_count)) - cmd.vtx_offset),
            @offsetOf(gui.DrawVert, "pos"),
            @sizeOf(gui.DrawVert),
            @offsetOf(gui.DrawVert, "color"),
            @sizeOf(gui.DrawVert),
            @offsetOf(gui.DrawVert, "uv"),
            @sizeOf(gui.DrawVert),
            indices,
        ) catch unreachable;
    }
}

// These functions are defined in `imgui_impl_sdl3.cpp` and 'imgui_impl_sdlrenderer3.cpp`
extern fn ImGui_ImplSDL3_InitForSDLRenderer(window: *const anyopaque, renderer: *const anyopaque) bool;
extern fn ImGui_ImplSDL3_NewFrame() void;
extern fn ImGui_ImplSDL3_Shutdown() void;
extern fn ImGui_ImplSDL3_ProcessEvent(event: *const anyopaque) bool;
extern fn ImGui_ImplSDLRenderer3_Init(renderer: *const anyopaque) bool;
extern fn ImGui_ImplSDLRenderer3_NewFrame() void;
extern fn ImGui_ImplSDLRenderer3_RenderDrawData(draw_data: *const anyopaque, renderer: *const anyopaque) void;
extern fn ImGui_ImplSDLRenderer3_Shutdown() void;
