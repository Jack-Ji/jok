const std = @import("std");
const jok = @import("../../jok.zig");
const sdl = jok.sdl;
const gui = @import("main.zig");

var fcolors = std.array_list.Managed(jok.ColorF).init(std.heap.c_allocator);

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

pub fn processEvent(event: sdl.SDL_Event) bool {
    return ImGui_ImplSDL3_ProcessEvent(&event);
}

pub fn renderDrawList(ctx: jok.Context, dl: gui.DrawList) void {
    if (dl.getCmdBufferLength() <= 0) return;

    const rd = ctx.renderer();
    const csz = ctx.getCanvasSize();

    // Restore viewport
    const viewport_set = rd.isViewportSet();
    const viewport = rd.getViewport() catch unreachable;
    defer rd.setViewport(if (viewport_set) viewport else null) catch unreachable;

    // Restore clip rect
    const clip_enabled = rd.isClipEnabled();
    const old_clip = rd.getClipRegion() catch unreachable;
    defer rd.setClipRegion(if (clip_enabled) old_clip else null) catch unreachable;

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
        if (clip_region.width == 0 or clip_region.height == 0) continue;
        rd.setClipRegion(clip_region) catch unreachable;

        // Convert colors
        // https://github.com/libsdl-org/SDL/issues/9009
        const vptr: [*]gui.DrawVert = vs_ptr + @as(usize, cmd.vtx_offset);
        const vcount: usize = @intCast(@as(u32, @intCast(vs_count)) - cmd.vtx_offset);
        fcolors.ensureTotalCapacity(vcount) catch unreachable;
        fcolors.clearRetainingCapacity();
        var i: usize = 0;
        while (i < vcount) : (i += 1) {
            fcolors.appendAssumeCapacity(jok.ColorF.fromInternalColor(vptr[i].color));
        }

        // Bind texture and draw
        var indices: []u32 = undefined;
        indices.ptr = @ptrCast(is_ptr + cmd.idx_offset);
        indices.len = @intCast(cmd.elem_count);
        rd.drawTrianglesRaw(
            if (@intFromEnum(cmd.texture_ref.tex_id) != 0) .{
                .ptr = @ptrFromInt(@as(usize, @intCast(@intFromEnum(cmd.texture_ref.tex_id)))),
            } else null,
            @ptrFromInt(@intFromPtr(vptr) + @offsetOf(gui.DrawVert, "pos")),
            @sizeOf(gui.DrawVert),
            fcolors.items.ptr,
            @sizeOf(jok.ColorF),
            @ptrFromInt(@intFromPtr(vptr) + @offsetOf(gui.DrawVert, "uv")),
            @sizeOf(gui.DrawVert),
            vcount,
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
