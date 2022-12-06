const std = @import("std");
const sdl = @import("sdl");
const jok = @import("jok");
const imgui = jok.deps.imgui;

pub const jok_window_width: u32 = 800;
pub const jok_window_height: u32 = 600;

pub fn init(ctx: *jok.Context) anyerror!void {
    _ = ctx;
    std.log.info("game init", .{});
}

pub fn event(ctx: *jok.Context, e: sdl.Event) anyerror!void {
    _ = ctx;
    _ = e;
}

pub fn update(ctx: *jok.Context) anyerror!void {
    _ = ctx;
}

pub fn draw(ctx: *jok.Context) anyerror!void {
    imgui.sdl.newFrame(ctx.*);
    defer imgui.sdl.draw();

    const S = struct {
        var f: f32 = 0.0;
        var counter: i32 = 0;
        var show_demo_window = true;
        var show_another_window = true;
        var clear_color = [3]f32{ 0.45, 0.55, 0.6 };
    };

    var mouse_state = ctx.getMouseState();
    imgui.setNextWindowPos(.{
        .x = @intToFloat(f32, mouse_state.x + 10),
        .y = @intToFloat(f32, mouse_state.y + 10),
    });
    if (imgui.begin(
        "mouse context",
        .{ .flags = .{ .no_title_bar = true } },
    )) {
        imgui.text("You're here!", .{});
    }
    imgui.end();

    if (imgui.begin("Hello, world!", .{})) {
        imgui.text("This is some useful text", .{});
        imgui.textUnformatted("some useful text");
        _ = imgui.checkbox("Demo Window", .{ .v = &S.show_demo_window });
        _ = imgui.checkbox("Another Window", .{ .v = &S.show_another_window });
        _ = imgui.sliderFloat("float", .{ .v = &S.f, .min = 0, .max = 1 });
        if (imgui.colorEdit3("clear color", .{ .col = &S.clear_color })) {
            try ctx.renderer.setColorRGB(
                @floatToInt(u8, @floor(S.clear_color[0] * 255.0)),
                @floatToInt(u8, @floor(S.clear_color[1] * 255.0)),
                @floatToInt(u8, @floor(S.clear_color[2] * 255.0)),
            );
        }
        if (imgui.button("Button", .{}))
            S.counter += 1;
        imgui.sameLine(.{});
        imgui.text("count = {d}", .{S.counter});
    }
    imgui.end();

    if (S.show_demo_window) {
        imgui.showDemoWindow(&S.show_demo_window);
    }

    if (S.show_another_window) {
        if (imgui.begin("Another Window", .{ .popen = &S.show_another_window })) {
            imgui.text("Hello from another window!", .{});
            if (imgui.button("Close Me", .{}))
                S.show_another_window = false;
        }
        imgui.end();
    }
}

pub fn quit(ctx: *jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});
}
