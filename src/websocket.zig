//! WebSocket client implementation for jok framework.
//!
//! This module provides WebSocket support for both WebAssembly and native platforms.
//! For WebAssembly, it uses the browser's native WebSocket API via JavaScript interop.
//!
//! The WebSocket operates in binary mode (binaryType = 'arraybuffer'), which is the
//! standard for game development as it provides better performance and efficiency for
//! binary data transmission.
//!
//! ## Usage
//!
//! ```zig
//! const jok = @import("jok");
//!
//! var ws: *jok.WebSocket = undefined;
//!
//! pub fn init(ctx: jok.Context) !void {
//!     ws = try jok.WebSocket.create(ctx.allocator(), "ws://localhost:8080");
//!     _ = try ws.on_message.connect(onWebSocketMessage, .{});
//!     _ = try ws.on_close.connect(onWebSocketClose, .{});
//! }
//!
//! fn onWebSocketMessage(websocket: *jok.WebSocket, data: []const u8) void {
//!     // Handle received binary message
//! }
//!
//! fn onWebSocketClose(websocket: *jok.WebSocket) void {
//!     // Handle connection close
//! }
//! ```
//!
//! Written by Claude Sonnet 4.5, reviewed by Jack-Ji

const std = @import("std");
const builtin = @import("builtin");
const signal = @import("utils/signal.zig");

/// Signal types for WebSocket events
pub const OpenSignal = signal.Signal(&.{*WebSocket});
pub const MessageSignal = signal.Signal(&.{ *WebSocket, []const u8 });
pub const ErrorSignal = signal.Signal(&.{*WebSocket});
pub const CloseSignal = signal.Signal(&.{*WebSocket});

/// WebSocket client handle
pub const WebSocket = struct {
    handle: usize,
    allocator: std.mem.Allocator,
    on_open: *OpenSignal,
    on_message: *MessageSignal,
    on_error: *ErrorSignal,
    on_close: *CloseSignal,

    /// Create a new WebSocket connection
    pub fn create(allocator: std.mem.Allocator, url: []const u8) !*WebSocket {
        if (!builtin.cpu.arch.isWasm()) {
            return error.WebSocketNotSupported;
        }

        const ws = try allocator.create(WebSocket);
        errdefer allocator.destroy(ws);

        ws.* = .{
            .handle = 0,
            .allocator = allocator,
            .on_open = try OpenSignal.create(allocator),
            .on_message = try MessageSignal.create(allocator),
            .on_error = try ErrorSignal.create(allocator),
            .on_close = try CloseSignal.create(allocator),
        };

        const ws_ptr = @intFromPtr(ws);
        ws.handle = wasm_websocket_create(url.ptr, url.len, ws_ptr);

        if (ws.handle == 0) {
            ws.on_open.destroy();
            ws.on_message.destroy();
            ws.on_error.destroy();
            ws.on_close.destroy();
            return error.WebSocketCreateFailed;
        }

        return ws;
    }

    /// Send a binary message through the WebSocket
    pub fn sendMessage(self: *WebSocket, data: []const u8) void {
        if (builtin.cpu.arch.isWasm()) {
            wasm_websocket_send(self.handle, data.ptr, data.len);
        } else {
            @panic("WebSocket is only supported on WebAssembly platform");
        }
    }

    /// Destroy the WebSocket connection
    pub fn destroy(self: *WebSocket) void {
        if (builtin.cpu.arch.isWasm()) {
            wasm_websocket_destroy(self.handle);
        }
        self.on_open.destroy();
        self.on_message.destroy();
        self.on_error.destroy();
        self.on_close.destroy();
        self.allocator.destroy(self);
    }
};

// WebAssembly JavaScript interop functions
extern fn wasm_websocket_create(url: [*]const u8, url_len: usize, ws_ptr: usize) usize;
extern fn wasm_websocket_send(handle: usize, data: [*]const u8, len: usize) void;
extern fn wasm_websocket_destroy(handle: usize) void;

/// Called by JavaScript when the connection is opened
export fn jok_websocket_on_open(ws_ptr: usize) void {
    const ws: *WebSocket = @ptrFromInt(ws_ptr);
    ws.on_open.emit(.{ws});
}

/// Called by JavaScript when a message is received
export fn jok_websocket_on_message(ws_ptr: usize, data_ptr: [*]const u8, data_len: usize) void {
    const ws: *WebSocket = @ptrFromInt(ws_ptr);
    const data = data_ptr[0..data_len];
    ws.on_message.emit(.{ ws, data });
}

/// Called by JavaScript when an error occurs
export fn jok_websocket_on_error(ws_ptr: usize) void {
    const ws: *WebSocket = @ptrFromInt(ws_ptr);
    ws.on_error.emit(.{ws});
}

/// Called by JavaScript when the connection is closed
export fn jok_websocket_on_close(ws_ptr: usize) void {
    const ws: *WebSocket = @ptrFromInt(ws_ptr);
    ws.on_close.emit(.{ws});
}
