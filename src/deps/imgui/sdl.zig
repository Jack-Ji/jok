const std = @import("std");
const math = std.math;
const jok = @import("../../jok.zig");
const zgui = @import("zgui");
const sdl = @import("sdl");
const imgui = @import("imgui.zig");

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

    zgui.getStyle().scaleAllSizes(ctx.getPixelRatio());

    if (!enable_ini_file) {
        zgui.io.setIniFilename(null);
    }

    const font = zgui.io.addFontFromMemory(jok.font.DebugFont.font_data, 16);
    zgui.io.setDefaultFont(font);

    zgui.plot.init();

    // NOTE: workaround for initializing imgui's internal state
    newFrame(ctx);
    defer draw();
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

    const fb_size = ctx.getFramebufferSize();
    imgui.io.setDisplaySize(fb_size.x, fb_size.y);
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

pub fn renderDrawList(rd: sdl.Renderer, dl: zgui.DrawList) !void {
    if (dl.getCmdBufferLength() <= 0) return;

    const fb_size = try rd.getOutputSize();
    const old_clip_rect = try rd.getClipRect();
    defer rd.setClipRect(old_clip_rect) catch unreachable;

    const commands = dl.getCmdBufferData()[0..@intCast(u32, dl.getCmdBufferLength())];
    const vs_ptr = dl.getVertexBufferData();
    const vs_count = dl.getVertexBufferLength();
    const is_ptr = dl.getIndexBufferData();
    for (commands) |cmd| {
        if (cmd.user_callback) |_| continue;

        // Apply clip rect
        var clip_rect: sdl.Rectangle = undefined;
        clip_rect.x = math.min(0, @floatToInt(c_int, cmd.clip_rect[0]));
        clip_rect.y = math.min(0, @floatToInt(c_int, cmd.clip_rect[1]));
        clip_rect.width = math.min(fb_size.width_pixels, @floatToInt(c_int, cmd.clip_rect[2] - cmd.clip_rect[0]));
        clip_rect.height = math.min(fb_size.height_pixels, @floatToInt(c_int, cmd.clip_rect[3] - cmd.clip_rect[1]));
        if (clip_rect.width <= 0 or clip_rect.height <= 0) continue;
        try rd.setClipRect(clip_rect);

        // Bind texture and draw
        const xy = @ptrToInt(vs_ptr + @intCast(usize, cmd.vtx_offset)) + @offsetOf(imgui.DrawVert, "pos");
        const uv = @ptrToInt(vs_ptr + @intCast(usize, cmd.vtx_offset)) + @offsetOf(imgui.DrawVert, "uv");
        const cs = @ptrToInt(vs_ptr + @intCast(usize, cmd.vtx_offset)) + @offsetOf(imgui.DrawVert, "color");
        const is = @ptrToInt(is_ptr + cmd.idx_offset);
        const tex = cmd.texture_id;
        _ = sdl.c.SDL_RenderGeometryRaw(
            rd.ptr,
            @ptrCast(?*sdl.c.SDL_Texture, tex),
            @intToPtr([*c]const f32, xy),
            @sizeOf(imgui.DrawVert),
            @intToPtr([*c]const sdl.c.SDL_Color, cs),
            @sizeOf(imgui.DrawVert),
            @intToPtr([*c]const f32, uv),
            @sizeOf(imgui.DrawVert),
            @intCast(c_int, vs_count) - @intCast(c_int, cmd.vtx_offset),
            @intToPtr([*c]const u16, is),
            @intCast(c_int, cmd.elem_count),
            @sizeOf(imgui.DrawIdx),
        );
    }
}

/// Convert SDL color to imgui integer
pub inline fn convertColor(color: sdl.Color) u32 {
    return @intCast(u32, color.r) |
        (@intCast(u32, color.g) << 8) |
        (@intCast(u32, color.b) << 16) |
        (@intCast(u32, color.a) << 24);
}

// Those functions are defined in `imgui_impl_sdl.cpp` and 'imgui_impl_sdlrenderer.cpp`
extern fn ImGui_ImplSDL2_InitForSDLRenderer(window: *const anyopaque, renderer: *const anyopaque) bool;
extern fn ImGui_ImplSDL2_NewFrame() void;
extern fn ImGui_ImplSDL2_Shutdown() void;
extern fn ImGui_ImplSDL2_ProcessEvent(event: *const anyopaque) bool;
extern fn ImGui_ImplSDLRenderer_Init(renderer: *const anyopaque) bool;
extern fn ImGui_ImplSDLRenderer_NewFrame() void;
extern fn ImGui_ImplSDLRenderer_RenderDrawData(draw_data: *const anyopaque) void;
extern fn ImGui_ImplSDLRenderer_Shutdown() void;
