const std = @import("std");
const assert = std.debug.assert;
const jok = @import("../../jok.zig");
const sdl = @import("sdl");
const c = @import("c.zig");

const RendererData = struct {
    renderer: sdl.Renderer,
    font_texture: ?sdl.Texture,
};

fn getBackendData() *RendererData {
    const io = @ptrCast(*c.ImGuiIO, c.igGetIO());
    return @ptrCast(
        *RendererData,
        @alignCast(@alignOf(*RendererData), io.BackendRendererUserData.?),
    );
}

pub fn init(ctx: jok.Context) !void {
    const io = @ptrCast(*c.ImGuiIO, c.igGetIO());
    if (io.BackendRendererUserData != null) {
        std.debug.panic("already initialized!", .{});
    }

    var bd = try ctx.allocator.create(RendererData);
    io.BackendRendererUserData = bd;
    io.BackendRendererName = "imgui_impl_sdlrenderer";
    io.BackendFlags |= c.ImGuiBackendFlags_RendererHasVtxOffset;
    bd.renderer = ctx.renderer;
    bd.font_texture = null;
}

pub fn deinit(ctx: jok.Context) void {
    const io = @ptrCast(*c.ImGuiIO, c.igGetIO());
    const bd = getBackendData();
    if (bd.font_texture) |tex| {
        c.ImFontAtlas_SetTexID(io.Fonts, @intToPtr(*allowzero anyopaque, 0));
        tex.destroy();
        bd.font_texture = null;
    }
    io.BackendRendererUserData = null;
    io.BackendRendererName = null;
    ctx.allocator.destroy(bd);
}

fn setupRenderState() void {
    const bd = getBackendData();
    _ = sdl.c.SDL_RenderSetViewport(bd.renderer.ptr, null);
    _ = sdl.c.SDL_RenderSetClipRect(bd.renderer.ptr, null);
}

pub fn newFrame() void {
    const io = @ptrCast(*c.ImGuiIO, c.igGetIO());
    const bd = getBackendData();

    if (bd.font_texture == null) {
        // Build texture atlas

        // Load as RGBA 32-bit (75% of the memory is wasted, but default font is so small) because it is more likely to be compatible with user's existing shaders. If your ImTextureId represent a higher-level concept than just a GL texture id, consider calling GetTexDataAsAlpha8() instead to save on GPU memory.
        var pixels: [*c]u8 = undefined;
        var width: c_int = undefined;
        var height: c_int = undefined;
        var bytes_per_pixel: c_int = undefined;
        c.ImFontAtlas_GetTexDataAsRGBA32(
            io.Fonts,
            &pixels,
            &width,
            &height,
            &bytes_per_pixel,
        );

        // Upload texture to graphics system
        // (Bilinear sampling is required by default. Set 'io.Fonts->Flags |= ImFontAtlasFlags_NoBakedLines' or 'style.AntiAliasedLinesUseTex = false' to allow point/nearest sampling)
        bd.font_texture = sdl.createTexture(
            bd.renderer,
            .abgr8888,
            .static,
            @intCast(usize, width),
            @intCast(usize, height),
        ) catch unreachable;
        const size = 4 * @intCast(usize, width) * @intCast(usize, height);
        bd.font_texture.?.update(pixels[0..size], @intCast(usize, 4 * width), null) catch unreachable;
        bd.font_texture.?.setBlendMode(.blend) catch unreachable;
        bd.font_texture.?.setScaleMode(.linear) catch unreachable;

        // Store our identifier
        c.ImFontAtlas_SetTexID(io.Fonts, bd.font_texture.?.ptr);
    }
}

pub fn render(data: *c.ImDrawData) void {
    const bd = getBackendData();

    // If there's a scale factor set by the user, use that instead
    // If the user has specified a scale factor to SDL_Renderer already via SDL_RenderSetScale(), SDL will scale whatever we pass
    // to SDL_RenderGeometryRaw() by that scale factor. In that case we don't want to be also scaling it ourselves here.
    var rsx: f32 = 1.0;
    var rsy: f32 = 1.0;
    sdl.c.SDL_RenderGetScale(bd.renderer.ptr, &rsx, &rsy);
    var render_scale = c.ImVec2{
        .x = if (rsx == 1.0) data.FramebufferScale.x else 1.0,
        .y = if (rsy == 1.0) data.FramebufferScale.y else 1.0,
    };

    // Avoid rendering when minimized, scale coordinates for retina displays (screen coordinates != framebuffer coordinates)
    const fb_width = @floatToInt(c_int, data.DisplaySize.x * render_scale.x);
    const fb_height = @floatToInt(c_int, data.DisplaySize.y * render_scale.y);
    if (fb_width == 0 or fb_height == 0) return;

    // Backup SDL_Renderer state that will be modified to restore it afterwards
    const RendererState = struct {
        viewport: sdl.c.SDL_Rect,
        clip_enabled: bool,
        clip_rect: sdl.c.SDL_Rect,
    };
    var old: RendererState = undefined;
    old.clip_enabled = sdl.c.SDL_RenderIsClipEnabled(bd.renderer.ptr) == sdl.c.SDL_TRUE;
    sdl.c.SDL_RenderGetViewport(bd.renderer.ptr, &old.viewport);
    sdl.c.SDL_RenderGetClipRect(bd.renderer.ptr, &old.clip_rect);

    // Will project scissor/clipping rectangles into framebuffer space
    var clip_off = data.DisplayPos; // (0,0) unless using multi-viewports
    var clip_scale = render_scale;

    // Render command lists
    setupRenderState();
    var n: u32 = 0;
    while (n < @intCast(u32, data.CmdListsCount)) : (n += 1) {
        const cmd_list = @ptrCast(*c.ImDrawList, data.CmdLists[n]);
        const vtx_buffer = cmd_list.VtxBuffer.Data;
        const idx_buffer = cmd_list.IdxBuffer.Data;

        var cmd_i: u32 = 0;
        while (cmd_i < @intCast(u32, cmd_list.CmdBuffer.Size)) : (cmd_i += 1) {
            const pcmd = @ptrCast(*c.ImDrawCmd, &cmd_list.CmdBuffer.Data[cmd_i]);
            assert(pcmd.UserCallback == null);

            // Project scissor/clipping rectangles into framebuffer space
            var clip_min = c.ImVec2{
                .x = (pcmd.ClipRect.x - clip_off.x) * clip_scale.x,
                .y = (pcmd.ClipRect.y - clip_off.y) * clip_scale.y,
            };
            var clip_max = c.ImVec2{
                .x = (pcmd.ClipRect.z - clip_off.x) * clip_scale.x,
                .y = (pcmd.ClipRect.w - clip_off.y) * clip_scale.y,
            };
            if (clip_min.x < 0.0) clip_min.x = 0.0;
            if (clip_min.y < 0.0) clip_min.y = 0.0;
            if (clip_max.x > @intToFloat(f32, fb_width))
                clip_max.x = @intToFloat(f32, fb_width);
            if (clip_max.y > @intToFloat(f32, fb_height))
                clip_max.y = @intToFloat(f32, fb_height);
            if (clip_max.x <= clip_min.x or clip_max.y <= clip_min.y)
                continue;

            bd.renderer.setClipRect(sdl.Rectangle{
                .x = @floatToInt(c_int, clip_min.x),
                .y = @floatToInt(c_int, clip_min.y),
                .width = @floatToInt(c_int, clip_max.x - clip_min.x),
                .height = @floatToInt(c_int, clip_max.y - clip_min.y),
            }) catch unreachable;

            const xy = @ptrCast(
                [*]f32,
                @ptrCast([*c]u8, vtx_buffer + pcmd.VtxOffset) + @offsetOf(c.ImDrawVert, "pos"),
            );
            const uv = @ptrCast(
                [*]f32,
                @ptrCast([*c]u8, vtx_buffer + pcmd.VtxOffset) + @offsetOf(c.ImDrawVert, "uv"),
            );
            const color = @ptrCast(
                [*]sdl.c.SDL_Color,
                @ptrCast([*c]u8, vtx_buffer + pcmd.VtxOffset) + @offsetOf(c.ImDrawVert, "col"),
            );

            // Bind texture, Draw
            const tex = @ptrCast(*sdl.c.SDL_Texture, pcmd.TextureId);
            _ = sdl.c.SDL_RenderGeometryRaw(
                bd.renderer.ptr,
                tex,
                xy,
                @sizeOf(c.ImDrawVert),
                color,
                @sizeOf(c.ImDrawVert),
                uv,
                @sizeOf(c.ImDrawVert),
                cmd_list.VtxBuffer.Size - @intCast(c_int, pcmd.VtxOffset),
                @ptrCast([*]c_int, idx_buffer + pcmd.IdxOffset),
                @intCast(c_int, pcmd.ElemCount),
                @sizeOf(c.ImDrawIdx),
            );
        }
    }

    // Restore modified SDL_Renderer state
    _ = sdl.c.SDL_RenderSetViewport(bd.renderer.ptr, &old.viewport);
    _ = sdl.c.SDL_RenderSetClipRect(bd.renderer.ptr, if (old.clip_enabled) &old.clip_rect else null);
}
