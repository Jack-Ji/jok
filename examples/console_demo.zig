const std = @import("std");
const jok = @import("jok");
const zgui = jok.vendor.zgui;
const sdl = jok.vendor.sdl;

pub const jok_window_size = jok.config.WindowSize{
    .custom = .{ .width = 1280, .height = 720 },
};

var console: *jok.utils.Console = undefined;
var frame_count: u32 = 0;
var overlay_texture: jok.Texture = undefined;
var batchpool: jok.j2d.BatchPool(32, false) = undefined;
var show_overlay: bool = false;

pub fn init(ctx: jok.Context) !void {
    std.log.info("console demo init", .{});

    // Initialize console with max 500 lines
    console = try jok.utils.Console.create(ctx, 500);

    // Initialize batch pool for overlay
    batchpool = try jok.j2d.BatchPool(32, false).init(ctx);

    // Create a simple overlay texture (gradient pattern)
    overlay_texture = try ctx.renderer().createTarget(.{ .size = console.getPreferedOverlaySize() });

    // Register custom commands
    try console.registerCommand("echo", echoCommand, "Echo back the arguments");
    try console.registerCommand("fps", fpsCommand, "Show current FPS");
    try console.registerCommand("spawn", spawnCommand, "Spawn an object (demo)");
    try console.registerCommand("quit", quitCommand, "Quit the application");
    try console.registerCommand("stress", stressCommand, "Stress test with 2x max_lines");
    try console.registerCommand("overlay", overlayCommand, "Toggle overlay display (on/off)");

    // Log welcome message
    try console.log(.info, "Console Demo - Press ` (grave/tilde) to toggle console", .{});
    try console.log(.info, "Type 'help' to see available commands", .{});
    try console.log(.info, "Try 'overlay on' to show the overlay panel!", .{});
}

pub fn event(ctx: jok.Context, e: jok.Event) !void {
    // Toggle console with grave/tilde key
    if (e == .key_down) {
        if (e.key_down.scancode == .grave) {
            console.toggle();
        }
    }

    _ = ctx;
}

pub fn update(ctx: jok.Context) !void {
    frame_count += 1;

    // Log a message every 300 frames (about 5 seconds at 60 FPS)
    if (frame_count % 300 == 0) {
        try console.log(.info, "Frame {d} - Time: {d:.2}s", .{ frame_count, ctx.seconds() });
    }
}

pub fn draw(ctx: jok.Context) !void {
    // Clear background
    try ctx.renderer().clear(jok.Color.rgb(30, 30, 40));

    // Draw some UI
    zgui.setNextWindowPos(.{ .x = 20, .y = 20, .cond = .first_use_ever });
    zgui.setNextWindowSize(.{ .w = 400, .h = 200, .cond = .first_use_ever });

    if (zgui.begin("Console Demo", .{})) {
        zgui.text("Press ` (grave/tilde) to toggle console", .{});
        zgui.separator();

        zgui.text("FPS: {d:.1}", .{ctx.fps()});
        zgui.text("Frame: {d}", .{frame_count});
        zgui.text("Time: {d:.2}s", .{ctx.seconds()});

        zgui.separator();

        if (zgui.button("Log Info Message", .{})) {
            try console.log(.info, "Info: Button clicked at frame {d}", .{frame_count});
        }

        if (zgui.button("Log Warning Message", .{})) {
            try console.log(.warning, "Warning: This is a warning message!", .{});
        }

        if (zgui.button("Log Error Message", .{})) {
            try console.log(.@"error", "Error: This is an error message!", .{});
        }

        zgui.separator();

        if (zgui.button("Show Console", .{})) {
            console.show();
        }

        zgui.sameLine(.{});

        if (zgui.button("Hide Console", .{})) {
            console.hide();
        }
    }
    zgui.end();

    // Draw overlay
    const b = try batchpool.new(.{
        .offscreen_target = overlay_texture,
        .offscreen_clear_color = jok.Color.rgb(40, 40, 40),
    });
    try b.text("FPS: {d:.2}", .{ctx.fps()}, .{});
    const info = try overlay_texture.query();
    b.translate(.{
        @as(f32, @floatFromInt(info.width / 2)),
        @as(f32, @floatFromInt(info.height / 2)),
    });
    b.rotateByLocalOrigin(ctx.seconds());
    try b.circle(.{ .radius = 20 }, .green, .{ .thickness = 5 });
    try b.triangle(
        .{
            .p0 = .{ .x = 0, .y = -@as(f32, @floatFromInt(info.height / 3)) },
            .p1 = .{ .x = @floatFromInt(info.width / 3), .y = @floatFromInt(info.height / 3) },
            .p2 = .{ .x = -@as(f32, @floatFromInt(info.width / 3)), .y = @floatFromInt(info.height / 3) },
        },
        .red,
        .{},
    );
    b.submit();

    // Render console (will only draw if visible)
    try console.render(.{ .overlay_texture = if (show_overlay) overlay_texture else null });
}

pub fn quit(ctx: jok.Context) void {
    std.log.info("console demo quit", .{});
    overlay_texture.destroy();
    batchpool.deinit();
    console.destroy();
    _ = ctx;
}

// Custom command implementations

fn echoCommand(args: []const []const u8, userdata: ?*anyopaque, con: *jok.utils.Console) !void {
    _ = userdata;
    if (args.len == 0) {
        try con.print("Usage: echo <message>", .{});
        return;
    }

    // Just print the first argument for simplicity
    try con.print("{s}", .{args[0]});

    // If there are more arguments, print them too
    if (args.len > 1) {
        for (args[1..]) |arg| {
            try con.print("  {s}", .{arg});
        }
    }
}

fn fpsCommand(args: []const []const u8, userdata: ?*anyopaque, con: *jok.utils.Console) !void {
    _ = args;
    _ = userdata;
    // Note: We can't access ctx from here, so we'll use frame_count as a proxy
    try con.print("Current frame: {d}", .{frame_count});
    try con.print("Use the main window to see FPS", .{});
}

fn spawnCommand(args: []const []const u8, userdata: ?*anyopaque, con: *jok.utils.Console) !void {
    _ = userdata;
    if (args.len == 0) {
        try con.print("Usage: spawn <object_name>", .{});
        return;
    }

    try con.print("Spawned object: {s}", .{args[0]});
    try con.print("(This is just a demo - no actual spawning)", .{});
}

fn quitCommand(args: []const []const u8, userdata: ?*anyopaque, con: *jok.utils.Console) !void {
    _ = args;
    _ = userdata;
    try con.print("Quitting application...", .{});
    // In a real application, you would call ctx.kill() here
    // For now, just print the message
    try con.print("(Use window close button to actually quit)", .{});
}

fn stressCommand(args: []const []const u8, userdata: ?*anyopaque, con: *jok.utils.Console) !void {
    _ = args;
    _ = userdata;

    // Get the console's max_lines setting
    const max_lines = con.max_lines;
    const test_lines = max_lines * 2; // Test with 2x the max to see the circular buffer in action

    try con.print("Starting stress test: logging {d} lines (max capacity: {d})...", .{ test_lines, max_lines });

    const start_frame = frame_count;
    var i: u32 = 0;
    while (i < test_lines) : (i += 1) {
        if (i % 4 == 0) {
            try con.log(.info, "Stress test line {d} - This is an info message", .{i});
        } else if (i % 4 == 1) {
            try con.log(.warning, "Stress test line {d} - This is a warning message", .{i});
        } else if (i % 4 == 2) {
            try con.log(.@"error", "Stress test line {d} - This is an error message", .{i});
        } else {
            try con.log(.info, "Stress test line {d} - Mixed content with numbers: {d}", .{ i, i * 123 });
        }
    }

    const end_frame = frame_count;
    try con.print("Stress test complete! Logged {d} lines in {d} frames", .{ test_lines, end_frame - start_frame });
    try con.print("Console kept the most recent {d} lines (older lines were discarded)", .{max_lines});
    try con.print("Scroll up to see the oldest retained message", .{});
    try con.print("Check FPS to verify performance remained stable", .{});
}

fn overlayCommand(args: []const []const u8, userdata: ?*anyopaque, con: *jok.utils.Console) !void {
    _ = userdata;

    if (args.len == 0) {
        try con.print("Overlay is currently: {s}", .{if (show_overlay) "ON" else "OFF"});
        try con.print("Usage: overlay <on|off>", .{});
        return;
    }

    if (std.mem.eql(u8, args[0], "on")) {
        show_overlay = true;
        try con.print("Overlay enabled! Check the right side of the console.", .{});
    } else if (std.mem.eql(u8, args[0], "off")) {
        show_overlay = false;
        try con.print("Overlay disabled.", .{});
    } else {
        try con.print("Invalid argument. Use 'on' or 'off'", .{});
    }
}
