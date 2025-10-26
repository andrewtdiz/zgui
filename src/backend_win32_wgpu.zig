const std = @import("std");

const gui = @import("gui.zig");

// This call will install Win32 hooks to handle GUI interactions.
// This means that custom user's message handlers need to be installed *before* calling zgpu.gui.init().
pub fn init(
    hwnd: *const anyopaque, // HWND
    wgpu_device: *const anyopaque, // wgpu.Device
    wgpu_swap_chain_format: u32, // wgpu.TextureFormat
    wgpu_depth_format: u32, // wgpu.TextureFormat
) void {
    std.debug.assert(ImGui_ImplWin32_Init(hwnd));

    var info = ImGui_ImplWGPU_InitInfo{
        .device = wgpu_device,
        .num_frames_in_flight = 1,
        .rt_format = wgpu_swap_chain_format,
        .depth_format = wgpu_depth_format,
        .pipeline_multisample_state = .{},
    };

    if (!ImGui_ImplWGPU_Init(&info)) {
        unreachable;
    }
}

pub fn deinit() void {
    ImGui_ImplWGPU_Shutdown();
    ImGui_ImplWin32_Shutdown();
}

pub fn handleMessage(hwnd: *const anyopaque, msg: u32, wparam: usize, lparam: isize) isize {
    return ImGui_ImplWin32_WndProcHandler(hwnd, msg, wparam, lparam);
}

pub fn newFrame(fb_width: u32, fb_height: u32) void {
    ImGui_ImplWGPU_NewFrame();
    ImGui_ImplWin32_NewFrame();

    gui.io.setDisplaySize(@as(f32, @floatFromInt(fb_width)), @as(f32, @floatFromInt(fb_height)));
    gui.io.setDisplayFramebufferScale(1.0, 1.0);

    gui.newFrame();
}

pub fn draw(wgpu_render_pass: *const anyopaque) void {
    gui.render();
    ImGui_ImplWGPU_RenderDrawData(gui.getDrawData(), wgpu_render_pass);
}

pub const ImGui_ImplWGPU_InitInfo = extern struct {
    device: *const anyopaque,
    num_frames_in_flight: u32 = 1,
    rt_format: u32,
    depth_format: u32,

    pipeline_multisample_state: extern struct {
        next_in_chain: ?*const anyopaque = null,
        count: u32 = 1,
        mask: u32 = @bitCast(@as(i32, -1)),
        alpha_to_coverage_enabled: bool = false,
    },
};

// Those functions are defined in 'imgui_impl_wgpu.cpp`
// (they include few custom changes).
extern fn ImGui_ImplWGPU_Init(init_info: *ImGui_ImplWGPU_InitInfo) bool;
extern fn ImGui_ImplWGPU_NewFrame() void;
extern fn ImGui_ImplWGPU_RenderDrawData(draw_data: *const anyopaque, pass_encoder: *const anyopaque) void;
extern fn ImGui_ImplWGPU_Shutdown() void;

extern fn ImGui_ImplWin32_Init(hwnd: *const anyopaque) bool;
extern fn ImGui_ImplWin32_Shutdown() void;
extern fn ImGui_ImplWin32_NewFrame() void;
extern fn ImGui_ImplWin32_WndProcHandler(hwnd: *const anyopaque, msg: u32, wparam: usize, lparam: isize) isize;
