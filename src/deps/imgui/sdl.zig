const std = @import("std");
const jok = @import("../../jok.zig");
const sdl = jok.sdl;
const zgui = @import("zgui");
const imgui = @import("imgui.zig");

// Record number of draw calls
var drawcall_count: u32 = 0;
var triangle_count: u32 = 0;

pub fn init(ctx: jok.Context, enable_ini_file: bool) void {
    zgui.init(ctx.allocator());

    const window = ctx.window();
    const renderer = ctx.renderer();
    if (!ImGui_ImplSDL2_InitForSDLRenderer(window.ptr, renderer.ptr)) {
        unreachable;
    }

    if (!ImGui_ImplSDLRenderer_Init(renderer.ptr)) {
        unreachable;
    }

    const fsize = renderer.getOutputSize() catch unreachable;
    const wsize = ctx.getWindowSize();
    const scale = @as(f32, @floatFromInt(fsize.width_pixels)) / wsize.x;
    zgui.getStyle().scaleAllSizes(scale);

    if (!enable_ini_file) {
        zgui.io.setIniFilename(null);
    }

    const font = zgui.io.addFontFromMemory(jok.font.DebugFont.font_data, 16);
    zgui.io.setDefaultFont(font);

    zgui.plot.init();

    // Initialize imgui's internal state
    newFrame(ctx);
    draw();
}

pub fn deinit() void {
    zgui.plot.deinit();
    ImGui_ImplSDLRenderer_Shutdown();
    ImGui_ImplSDL2_Shutdown();
    zgui.deinit();
}

pub fn newFrame(ctx: jok.Context) void {
    ImGui_ImplSDLRenderer_NewFrame();
    ImGui_ImplSDL2_NewFrame();

    const fb_size = ctx.renderer().getOutputSize() catch unreachable;
    imgui.io.setDisplaySize(
        @floatFromInt(fb_size.width_pixels),
        @floatFromInt(fb_size.height_pixels),
    );
    imgui.io.setDisplayFramebufferScale(1.0, 1.0);

    imgui.newFrame();
}

pub fn draw() void {
    imgui.render();
    ImGui_ImplSDLRenderer_RenderDrawData(imgui.getDrawData());
}

pub fn processEvent(event: sdl.c.SDL_Event) bool {
    return ImGui_ImplSDL2_ProcessEvent(&event);
}

pub fn renderDrawList(rd: sdl.Renderer, dl: zgui.DrawList) void {
    if (dl.getCmdBufferLength() <= 0) return;

    const fb_size = rd.getOutputSize() catch unreachable;
    const old_clip_rect = rd.getClipRect() catch unreachable;
    defer rd.setClipRect(old_clip_rect) catch unreachable;

    const commands = dl.getCmdBufferData()[0..@as(u32, @intCast(dl.getCmdBufferLength()))];
    const vs_ptr = dl.getVertexBufferData();
    const vs_count = dl.getVertexBufferLength();
    const is_ptr = dl.getIndexBufferData();

    for (commands) |cmd| {
        if (cmd.user_callback != null or cmd.elem_count == 0) continue;

        // Apply clip rect
        var clip_rect: sdl.Rectangle = undefined;
        clip_rect.x = @min(0, @as(c_int, @intFromFloat(cmd.clip_rect[0])));
        clip_rect.y = @min(0, @as(c_int, @intFromFloat(cmd.clip_rect[1])));
        clip_rect.width = @min(fb_size.width_pixels, @as(c_int, @intFromFloat(cmd.clip_rect[2] - cmd.clip_rect[0])));
        clip_rect.height = @min(fb_size.height_pixels, @as(c_int, @intFromFloat(cmd.clip_rect[3] - cmd.clip_rect[1])));
        if (clip_rect.width <= 0 or clip_rect.height <= 0) continue;
        rd.setClipRect(clip_rect) catch unreachable;

        // Bind texture and draw
        const xy = @intFromPtr(vs_ptr + @as(usize, cmd.vtx_offset)) + @offsetOf(imgui.DrawVert, "pos");
        const uv = @intFromPtr(vs_ptr + @as(usize, cmd.vtx_offset)) + @offsetOf(imgui.DrawVert, "uv");
        const cs = @intFromPtr(vs_ptr + @as(usize, cmd.vtx_offset)) + @offsetOf(imgui.DrawVert, "color");
        const is = @intFromPtr(is_ptr + cmd.idx_offset);
        const tex = cmd.texture_id;
        _ = sdl.c.SDL_RenderGeometryRaw(
            rd.ptr,
            @as(?*sdl.c.SDL_Texture, @ptrCast(tex)),
            @as([*c]const f32, @ptrFromInt(xy)),
            @sizeOf(imgui.DrawVert),
            @as([*c]const sdl.c.SDL_Color, @ptrFromInt(cs)),
            @sizeOf(imgui.DrawVert),
            @as([*c]const f32, @ptrFromInt(uv)),
            @sizeOf(imgui.DrawVert),
            @as(c_int, vs_count) - @as(c_int, @intCast(cmd.vtx_offset)),
            @as([*c]const u16, @ptrFromInt(is)),
            @intCast(cmd.elem_count),
            @sizeOf(imgui.DrawIdx),
        );
        drawcall_count += 1;
        triangle_count += cmd.elem_count / 3;
    }
}

pub fn getDrawCallStats() std.meta.Tuple(&.{ u32, u32 }) {
    return .{ drawcall_count, triangle_count };
}

pub fn clearDrawCallStats() void {
    drawcall_count = 0;
    triangle_count = 0;
}

/// Convert SDL color to imgui integer
pub inline fn convertColor(color: sdl.Color) u32 {
    return @as(u32, color.r) |
        (@as(u32, color.g) << 8) |
        (@as(u32, color.b) << 16) |
        (@as(u32, color.a) << 24);
}

// These functions are defined in `imgui_impl_sdl.cpp` and 'imgui_impl_sdlrenderer.cpp`
extern fn ImGui_ImplSDL2_InitForSDLRenderer(window: *const anyopaque, renderer: *const anyopaque) bool;
extern fn ImGui_ImplSDL2_NewFrame() void;
extern fn ImGui_ImplSDL2_Shutdown() void;
extern fn ImGui_ImplSDL2_ProcessEvent(event: *const anyopaque) bool;
extern fn ImGui_ImplSDLRenderer_Init(renderer: *const anyopaque) bool;
extern fn ImGui_ImplSDLRenderer_NewFrame() void;
extern fn ImGui_ImplSDLRenderer_RenderDrawData(draw_data: *const anyopaque) void;
extern fn ImGui_ImplSDLRenderer_Shutdown() void;
