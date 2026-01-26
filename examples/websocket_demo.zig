const std = @import("std");
const jok = @import("jok");

const Message = struct {
    text: []const u8,
    is_sent: bool,
};

const ConnectionState = enum {
    disconnected,
    connecting,
    connected,
};

const WEBSOCKET_URL = "ws://localhost:8080";
const MAX_RECONNECT_DELAY: f64 = 30.0;
const INITIAL_RECONNECT_DELAY: f64 = 1.0;

var ws: ?*jok.WebSocket = null;
var connection_state: ConnectionState = .disconnected;
var messages: std.ArrayList(Message) = undefined;
var allocator: std.mem.Allocator = undefined;
var message_counter: u32 = 0;
var last_send_time: f64 = 0;
var start_time: f64 = 0;
var reconnect_attempts: u32 = 0;
var next_reconnect_time: f64 = 0;
var reconnect_delay: f64 = INITIAL_RECONNECT_DELAY;
var had_error: bool = false;

pub fn init(ctx: jok.Context) !void {
    allocator = ctx.allocator();
    messages = try std.ArrayList(Message).initCapacity(ctx.allocator(), 32);
    message_counter = 0;
    last_send_time = 0;
    start_time = ctx.realSeconds();
    reconnect_attempts = 0;
    reconnect_delay = INITIAL_RECONNECT_DELAY;
    had_error = false;

    std.log.info("Initializing WebSocket demo...", .{});
    connectWebsocket(ctx);
}

fn connectWebsocket(ctx: jok.Context) void {
    if (ws != null) return;

    connection_state = .connecting;
    had_error = false;
    std.log.info("Connecting to {s}...", .{WEBSOCKET_URL});

    ws = jok.WebSocket.create(ctx.allocator(), WEBSOCKET_URL) catch |err| {
        std.log.err("Failed to create WebSocket: {}", .{err});
        connection_state = .disconnected;
        scheduleReconnect(ctx);
        return;
    };

    // Connect signals
    _ = ws.?.on_open.connect(onOpen, .{}) catch return;
    _ = ws.?.on_message.connect(onMessage, .{}) catch return;
    _ = ws.?.on_error.connect(onError, .{}) catch return;
    _ = ws.?.on_close.connect(onClose, .{}) catch return;
}

fn scheduleReconnect(ctx: jok.Context) void {
    reconnect_attempts += 1;
    next_reconnect_time = ctx.realSeconds() + reconnect_delay;
    std.log.info("Scheduling reconnect attempt #{d} in {d:.1}s...", .{ reconnect_attempts, reconnect_delay });

    reconnect_delay = @min(reconnect_delay * 2.0, MAX_RECONNECT_DELAY);
}

fn onOpen(websocket: *jok.WebSocket) void {
    _ = websocket;
    std.log.info("✓ WebSocket connection opened!", .{});
    connection_state = .connected;
    reconnect_attempts = 0;
    reconnect_delay = INITIAL_RECONNECT_DELAY;
    had_error = false;
}

fn onMessage(websocket: *jok.WebSocket, data: []const u8) void {
    _ = websocket;
    std.log.info("✓ Received message: {s}", .{data});

    const msg_text = allocator.dupe(u8, data) catch return;
    const msg = Message{
        .text = msg_text,
        .is_sent = false,
    };
    messages.append(allocator, msg) catch return;
}

fn onError(websocket: *jok.WebSocket) void {
    _ = websocket;
    std.log.err("✗ WebSocket error occurred", .{});
    had_error = true;
}

fn onClose(websocket: *jok.WebSocket) void {
    _ = websocket;

    if (had_error) {
        std.log.info("✗ WebSocket connection failed", .{});
    } else {
        std.log.info("✗ WebSocket connection closed", .{});
    }

    connection_state = .disconnected;

    if (ws) |w| {
        w.destroy();
    }
    ws = null;

    next_reconnect_time = -1;
}

pub fn event(ctx: jok.Context, e: jok.Event) !void {
    switch (e) {
        .key_up => |k| {
            if (k.scancode == .space and connection_state == .connected) {
                if (ws) |w| {
                    message_counter += 1;
                    const msg = try std.fmt.allocPrint(
                        allocator,
                        "Message #{d} from jok at {d:.2}s",
                        .{ message_counter, ctx.realSeconds() - start_time },
                    );
                    defer allocator.free(msg);

                    w.sendMessage(msg);
                    std.log.info("Sent message: {s}", .{msg});

                    const msg_copy = try allocator.dupe(u8, msg);
                    const sent_msg = Message{
                        .text = msg_copy,
                        .is_sent = true,
                    };
                    try messages.append(allocator, sent_msg);
                    last_send_time = ctx.realSeconds();
                }
            }
        },
        else => {},
    }
}

pub fn update(ctx: jok.Context) !void {
    if (connection_state == .disconnected and ws == null) {
        const current_time = ctx.realSeconds();
        if (next_reconnect_time == -1) {
            scheduleReconnect(ctx);
        } else if (next_reconnect_time > 0 and current_time >= next_reconnect_time) {
            connectWebsocket(ctx);
        }
    }
}

pub fn draw(ctx: jok.Context) !void {
    const s = ctx.renderer().getOutputSize() catch unreachable;
    const height: f32 = @floatFromInt(s.height);

    try ctx.renderer().clear(jok.Color.rgb(30, 30, 40));

    ctx.debugPrint("=== WebSocket Demo ==", .{
        .pos = .{ .x = 10, .y = 10 },
        .color = jok.Color.rgb(100, 200, 255),
    });

    const instructions = if (connection_state == .connected)
        "Press SPACE to send a message"
    else
        "Waiting for connection...";
    ctx.debugPrint(instructions, .{
        .pos = .{ .x = 10, .y = 40 },
        .color = jok.Color.rgb(255, 255, 100),
    });

    var y: f32 = 70;
    switch (connection_state) {
        .connected => {
            ctx.debugPrint("Status: [CONNECTED]", .{
                .pos = .{ .x = 10, .y = y },
                .color = jok.Color.rgb(100, 255, 100),
            });

            if (last_send_time > 0) {
                const time_since = ctx.realSeconds() - last_send_time;
                const status_text = try std.fmt.allocPrint(
                    allocator,
                    "Last sent: {d:.1}s ago",
                    .{time_since},
                );
                defer allocator.free(status_text);
                ctx.debugPrint(status_text, .{
                    .pos = .{ .x = 250, .y = y },
                    .color = jok.Color.rgb(150, 150, 150),
                });
            }
        },
        .connecting => {
            const connecting_text = if (reconnect_attempts > 0)
                try std.fmt.allocPrint(
                    allocator,
                    "Status: [RECONNECTING... attempt #{d}]",
                    .{reconnect_attempts},
                )
            else
                try allocator.dupe(u8, "Status: [CONNECTING...]");
            defer allocator.free(connecting_text);

            ctx.debugPrint(connecting_text, .{
                .pos = .{ .x = 10, .y = y },
                .color = jok.Color.rgb(255, 255, 100),
            });
        },
        .disconnected => {
            const current_time = ctx.realSeconds();
            const time_until_reconnect = next_reconnect_time - current_time;

            const status_text = if (time_until_reconnect > 0)
                try std.fmt.allocPrint(
                    allocator,
                    "Status: [DISCONNECTED] - Reconnecting in {d:.1}s...",
                    .{time_until_reconnect},
                )
            else
                try allocator.dupe(u8, "Status: [DISCONNECTED]");
            defer allocator.free(status_text);

            ctx.debugPrint(status_text, .{
                .pos = .{ .x = 10, .y = y },
                .color = jok.Color.rgb(255, 100, 100),
            });
        },
    }

    y += 30;
    const counter_text = try std.fmt.allocPrint(
        allocator,
        "Total messages: {d} sent, {d} received",
        .{
            count_sent_messages(),
            count_received_messages(),
        },
    );
    defer allocator.free(counter_text);
    ctx.debugPrint(counter_text, .{
        .pos = .{ .x = 10, .y = y },
        .color = jok.Color.rgb(200, 200, 200),
    });

    y += 35;
    ctx.debugPrint("--- Message History (last 15) ---", .{
        .pos = .{ .x = 10, .y = y },
        .color = jok.Color.rgb(150, 150, 200),
    });

    y += 30;
    const max_messages = @min(messages.items.len, 15);
    if (max_messages > 0) {
        const start_idx = messages.items.len - max_messages;
        for (messages.items[start_idx..]) |msg| {
            const prefix = if (msg.is_sent) ">> SENT:  " else "<< RECV:  ";
            const prefix_color = if (msg.is_sent)
                jok.Color.rgb(100, 200, 255)
            else
                jok.Color.rgb(100, 255, 150);

            ctx.debugPrint(prefix, .{
                .pos = .{ .x = 20, .y = y },
                .color = prefix_color,
            });

            const max_len = 60;
            const display_text = if (msg.text.len > max_len)
                try std.fmt.allocPrint(allocator, "{s}...", .{msg.text[0..max_len]})
            else
                msg.text;
            defer if (msg.text.len > max_len) allocator.free(display_text);

            ctx.debugPrint(display_text, .{
                .pos = .{ .x = 140, .y = y },
                .color = jok.Color.rgb(255, 255, 255),
            });

            y += 22;

            if (y > height - 50) break;
        }
    } else {
        ctx.debugPrint("No messages yet. Press SPACE to send!", .{
            .pos = .{ .x = 20, .y = y },
            .color = jok.Color.rgb(150, 150, 150),
        });
    }

    const footer_y = height - 30;
    ctx.debugPrint("Server: " ++ WEBSOCKET_URL, .{
        .pos = .{ .x = 10, .y = footer_y },
        .color = jok.Color.rgb(100, 100, 100),
    });
}

fn count_sent_messages() u32 {
    var count: u32 = 0;
    for (messages.items) |msg| {
        if (msg.is_sent) count += 1;
    }
    return count;
}

fn count_received_messages() u32 {
    var count: u32 = 0;
    for (messages.items) |msg| {
        if (!msg.is_sent) count += 1;
    }
    return count;
}

pub fn quit(ctx: jok.Context) void {
    _ = ctx;

    if (ws) |w| {
        w.destroy();
        ws = null;
    }

    for (messages.items) |msg| {
        allocator.free(msg.text);
    }
    messages.deinit(allocator);

    std.log.info("WebSocket example quit", .{});
}
