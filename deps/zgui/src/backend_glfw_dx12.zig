const gui = @import("gui.zig");
const backend_glfw = @import("backend_glfw.zig");
const backend_dx12 = @import("backend_dx12.zig");

pub fn init(
    window: *const anyopaque, // zglfw.Window
    device: *const anyopaque, // ID3D12Device
    num_frames_in_flight: u32,
    rtv_format: c_uint, // DXGI_FORMAT
    cbv_srv_heap: *const anyopaque, // ID3D12DescriptorHeap
    font_srv_cpu_desc_handle: backend_dx12.D3D12_CPU_DESCRIPTOR_HANDLE,
    font_srv_gpu_desc_handle: backend_dx12.D3D12_GPU_DESCRIPTOR_HANDLE,
) void {
    backend_glfw.init(window);
    backend_dx12.init(
        device,
        num_frames_in_flight,
        rtv_format,
        cbv_srv_heap,
        font_srv_cpu_desc_handle,
        font_srv_gpu_desc_handle,
    );
}

pub fn deinit() void {
    backend_dx12.deinit();
    backend_glfw.deinit();
}

pub fn newFrame(fb_width: u32, fb_height: u32) void {
    backend_glfw.newFrame();
    backend_dx12.newFrame();

    gui.io.setDisplaySize(@as(f32, @floatFromInt(fb_width)), @as(f32, @floatFromInt(fb_height)));
    gui.io.setDisplayFramebufferScale(1.0, 1.0);

    gui.newFrame();
}

pub fn draw(
    graphics_command_list: *const anyopaque, // *ID3D12GraphicsCommandList
) void {
    gui.render();
    backend_dx12.render(gui.getDrawData(), graphics_command_list);
}
