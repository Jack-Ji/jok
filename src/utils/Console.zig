//! Counter-Strike style console system for jok framework.
//!
//! Features:
//! - Scrollable message history with configurable max lines
//! - Command input with history
//! - Command triggers (callbacks) for custom commands
//! - Toggle visibility with a key (default: grave/tilde)
//! - Built with zgui for rendering
//!
//! Written by Claude Sonnet 4.5, reviewed by Jack-Ji

const std = @import("std");
const jok = @import("../jok.zig");
const geom = jok.geom;
const zgui = jok.vendor.zgui;

const Console = @This();

pub const LogLevel = enum {
    info,
    warning,
    @"error",
};

pub const EntryType = enum {
    log,
    command, // user-entered command
    command_output, // output from command execution
};

pub const LogEntry = struct {
    message: []const u8,
    level: LogLevel,
    entry_type: EntryType,
};

pub const CommandCallback = *const fn (args: []const []const u8, userdata: ?*anyopaque, console: *Console) anyerror!void;

pub const CommandTrigger = struct {
    name: []const u8,
    callback: CommandCallback,
    description: []const u8,
    userdata: ?*anyopaque,
};

pub const AdvancedOptions = struct {
    /// Optional overlay texture to display on the right side
    overlay_texture: ?jok.Texture = null,
};

ctx: jok.Context,
max_lines: u32,
visible: bool,
was_visible: bool,
was_fully_open: bool,
had_overlay: bool, // track overlay state changes
animation_progress: f32, // 0.0 = hidden, 1.0 = fully visible
logs: std.ArrayList(LogEntry),
commands: std.StringHashMap(CommandTrigger),
input_buffer: [256:0]u8,
input_history: std.ArrayList([]const u8),
history_index: ?usize,
scroll_to_bottom: bool,
auto_scroll: bool, // true = follow new logs, false = user scrolled up
refocus_input: bool,
clear_input_frames: u8, // frames to keep clearing input (to discard held backtick)
// Filters
filter_info: bool,
filter_warning: bool,
filter_error: bool,
filter_command: bool,
filter_text: [128:0]u8, // text search filter
filter_case_sensitive: bool,
// Display options
show_timestamps: bool,
// Track filter changes
prev_filter_info: bool,
prev_filter_warning: bool,
prev_filter_error: bool,
prev_filter_command: bool,
prev_filter_text_len: usize,

/// Initialize the console
pub fn create(ctx: jok.Context, max_lines: u32) !*Console {
    const console = try ctx.allocator().create(Console);
    console.* = .{
        .ctx = ctx,
        .max_lines = max_lines,
        .visible = false,
        .was_visible = false,
        .was_fully_open = false,
        .had_overlay = false,
        .animation_progress = 0.0,
        .logs = .empty,
        .commands = std.StringHashMap(CommandTrigger).init(ctx.allocator()),
        .input_buffer = std.mem.zeroes([256:0]u8),
        .input_history = .empty,
        .history_index = null,
        .scroll_to_bottom = true,
        .auto_scroll = true,
        .refocus_input = false,
        .clear_input_frames = 0,
        .filter_info = true,
        .filter_warning = true,
        .filter_error = true,
        .filter_command = true,
        .filter_text = std.mem.zeroes([128:0]u8),
        .filter_case_sensitive = false,
        .show_timestamps = true,
        .prev_filter_info = true,
        .prev_filter_warning = true,
        .prev_filter_error = true,
        .prev_filter_command = true,
        .prev_filter_text_len = 0,
    };

    // Register default commands
    try console.registerCommand("help", helpCommand, "Show available commands");
    try console.registerCommand("clear", clearCommand, "Clear console history");

    return console;
}

/// Case-insensitive substring search
fn containsIgnoreCase(haystack: []const u8, needle: []const u8) bool {
    if (needle.len == 0) return true;
    if (needle.len > haystack.len) return false;

    var i: usize = 0;
    while (i <= haystack.len - needle.len) : (i += 1) {
        var match = true;
        for (needle, 0..) |nc, j| {
            const hc = haystack[i + j];
            if (std.ascii.toLower(hc) != std.ascii.toLower(nc)) {
                match = false;
                break;
            }
        }
        if (match) return true;
    }
    return false;
}

/// Check if message matches text filter
fn matchesTextFilter(self: *Console, message: []const u8, filter_text: []const u8) bool {
    if (filter_text.len == 0) return true;
    if (self.filter_case_sensitive) {
        return std.mem.indexOf(u8, message, filter_text) != null;
    } else {
        return containsIgnoreCase(message, filter_text);
    }
}

/// Deinitialize the console
pub fn destroy(self: *Console) void {
    // Free log messages
    for (self.logs.items) |entry| {
        self.ctx.allocator().free(entry.message);
    }
    self.logs.deinit(self.ctx.allocator());

    // Free command history
    for (self.input_history.items) |cmd| {
        self.ctx.allocator().free(cmd);
    }
    self.input_history.deinit(self.ctx.allocator());

    // Free command triggers
    self.commands.deinit();

    self.ctx.allocator().destroy(self);
}

/// Toggle console visibility
pub fn toggle(self: *Console) void {
    self.visible = !self.visible;
}

/// Show console
pub fn show(self: *Console) void {
    self.visible = true;
}

/// Hide console
pub fn hide(self: *Console) void {
    self.visible = false;
}

/// Add a log message to the console
pub fn log(self: *Console, level: LogLevel, comptime fmt: []const u8, args: anytype) !void {
    // Get current timestamp using io.Clock
    const timestamp = std.Io.Clock.real.now(self.ctx.io());
    const timestamp_s: i64 = @intCast(@divFloor(timestamp.nanoseconds, std.time.ns_per_s));

    const epoch_seconds = std.time.epoch.EpochSeconds{ .secs = @intCast(timestamp_s) };
    const epoch_day = epoch_seconds.getEpochDay();
    const year_day = epoch_day.calculateYearDay();
    const month_day = year_day.calculateMonthDay();
    const day_seconds = epoch_seconds.getDaySeconds();

    // Get level prefix (I/W/E)
    const level_prefix = switch (level) {
        .info => "I",
        .warning => "W",
        .@"error" => "E",
    };

    // Format: [YYYY-MM-DD HH:MM:SS] I/W/E message
    const time_prefix = try std.fmt.allocPrint(
        self.ctx.allocator(),
        "[{d:0>4}-{d:0>2}-{d:0>2} {d:0>2}:{d:0>2}:{d:0>2}] {s} ",
        .{
            year_day.year,
            month_day.month.numeric(),
            month_day.day_index + 1,
            day_seconds.getHoursIntoDay(),
            day_seconds.getMinutesIntoHour(),
            day_seconds.getSecondsIntoMinute(),
            level_prefix,
        },
    );
    defer self.ctx.allocator().free(time_prefix);

    const message_content = try std.fmt.allocPrint(self.ctx.allocator(), fmt, args);
    defer self.ctx.allocator().free(message_content);

    const message = try std.fmt.allocPrint(self.ctx.allocator(), "{s}{s}", .{ time_prefix, message_content });
    errdefer self.ctx.allocator().free(message);

    try self.logs.append(self.ctx.allocator(), .{
        .message = message,
        .level = level,
        .entry_type = .log,
    });

    self.enforceMaxLines();

    // Only scroll to bottom if this log entry is visible based on current filters
    const level_visible = switch (level) {
        .info => self.filter_info,
        .warning => self.filter_warning,
        .@"error" => self.filter_error,
    };

    // Check text filter
    const filter_text_len = std.mem.indexOfScalar(u8, &self.filter_text, 0) orelse self.filter_text.len;
    const text_visible = self.matchesTextFilter(message, self.filter_text[0..filter_text_len]);

    if (self.auto_scroll and level_visible and text_visible) {
        self.scroll_to_bottom = true;
    }
}

/// Add a command entry to the console (no timestamp)
fn logCommand(self: *Console, command: []const u8) !void {
    const message = try self.ctx.allocator().dupe(u8, command);
    errdefer self.ctx.allocator().free(message);

    try self.logs.append(self.ctx.allocator(), .{
        .message = message,
        .level = .info,
        .entry_type = .command,
    });

    self.enforceMaxLines();
}

/// Add command output to the console (no timestamp)
pub fn print(self: *Console, comptime fmt: []const u8, args: anytype) !void {
    const message = try std.fmt.allocPrint(self.ctx.allocator(), fmt, args);
    errdefer self.ctx.allocator().free(message);

    try self.logs.append(self.ctx.allocator(), .{
        .message = message,
        .level = .info,
        .entry_type = .command_output,
    });

    self.enforceMaxLines();

    // Check text filter for auto-scroll
    const filter_text_len = std.mem.indexOfScalar(u8, &self.filter_text, 0) orelse self.filter_text.len;
    const text_visible = self.matchesTextFilter(message, self.filter_text[0..filter_text_len]);

    if (self.auto_scroll and self.filter_command and text_visible) {
        self.scroll_to_bottom = true;
    }
}

/// Enforce max lines limit
fn enforceMaxLines(self: *Console) void {
    while (self.logs.items.len > self.max_lines) {
        // Free the oldest entry and remove it
        self.ctx.allocator().free(self.logs.items[0].message);
        _ = self.logs.orderedRemove(0);
    }
}

/// Register a command trigger
pub fn registerCommand(self: *Console, name: []const u8, callback: CommandCallback, description: []const u8) !void {
    try self.registerCommandWithUserdata(name, callback, description, null);
}

/// Register a command trigger with custom userdata
pub fn registerCommandWithUserdata(self: *Console, name: []const u8, callback: CommandCallback, description: []const u8, userdata: ?*anyopaque) !void {
    try self.commands.put(name, .{
        .name = name,
        .callback = callback,
        .description = description,
        .userdata = userdata,
    });
}

/// Execute a command
fn executeCommand(self: *Console, command_line: []const u8) !void {
    if (command_line.len == 0) return;

    // Log the command
    try self.logCommand(command_line);

    // Parse command and arguments
    var args = std.ArrayList([]const u8).empty;
    defer args.deinit(self.ctx.allocator());

    var iter = std.mem.tokenizeScalar(u8, command_line, ' ');
    while (iter.next()) |arg| {
        try args.append(self.ctx.allocator(), arg);
    }

    if (args.items.len == 0) return;

    const cmd_name = args.items[0];
    const cmd_args = if (args.items.len > 1) args.items[1..] else &[_][]const u8{};

    // Find and execute command
    if (self.commands.get(cmd_name)) |trigger| {
        trigger.callback(cmd_args, trigger.userdata, self) catch |err| {
            try self.print("Error: {}", .{err});
        };
    } else {
        try self.print("Unknown command: {s}", .{cmd_name});
    }
}

/// Render info panel to offscreen target
/// Render the console using zgui
pub fn render(self: *Console, options: AdvancedOptions) !void {
    // Animate console slide down/up
    const animation_speed: f32 = 8.0; // Speed of animation
    const delta = self.ctx.deltaSeconds() * animation_speed;

    if (self.visible) {
        // Slide down
        self.animation_progress = @min(1.0, self.animation_progress + delta);
    } else {
        // Slide up
        self.animation_progress = @max(0.0, self.animation_progress - delta);
    }

    // Don't render if fully hidden
    if (self.animation_progress <= 0.0) {
        self.was_visible = false;
        self.was_fully_open = false;
        return;
    }

    // Track if console was just opened (started animating)
    const just_opened = !self.was_visible and self.visible;
    self.was_visible = self.visible;

    // Track if animation just completed (fully open now, wasn't before)
    const is_fully_open = self.animation_progress >= 1.0;
    const just_fully_opened = is_fully_open and !self.was_fully_open;
    self.was_fully_open = is_fully_open;

    // Scroll to bottom when console is opened
    if (just_opened) {
        self.scroll_to_bottom = true;
    }

    // Request focus when animation completes
    if (just_fully_opened) {
        self.refocus_input = true;
        self.clear_input_frames = 3; // Clear input for a few frames to discard held backtick
    }

    // Track overlay state changes (for future use)
    const has_overlay = options.overlay_texture != null;
    self.had_overlay = has_overlay;

    const viewport = zgui.getMainViewport();
    const work_size = viewport.getWorkSize();

    // Console takes up top half of screen (fixed size, only position animates)
    const target_height = work_size[1] * 0.5;

    // Calculate console and overlay widths (fixed, not animated)
    const overlay_width = if (options.overlay_texture) |tex| blk: {
        const info = try tex.query();
        break :blk @min(work_size[0] * 0.5, @as(f32, @floatFromInt(info.width)));
    } else 0;
    const console_width = work_size[0] - overlay_width;

    // Slide down from top: position animates from -target_height to 0
    const y_offset = -target_height * (1.0 - self.animation_progress);
    zgui.setNextWindowPos(.{ .x = 0, .y = y_offset });
    zgui.setNextWindowSize(.{ .w = console_width, .h = target_height });

    const flags = zgui.WindowFlags{
        .no_title_bar = true,
        .no_resize = true,
        .no_move = true,
        .no_collapse = true,
        .no_scrollbar = true,
        .no_scroll_with_mouse = true,
    };

    if (zgui.begin("##Console", .{ .flags = flags })) {
        // Only render content if console is mostly visible (avoid issues with tiny windows)
        if (self.animation_progress >= 0.1) {
            // Get current text filter length
            const filter_text_len = std.mem.indexOfScalar(u8, &self.filter_text, 0) orelse self.filter_text.len;

            // Check if filters changed
            const filters_changed = self.filter_info != self.prev_filter_info or
                self.filter_warning != self.prev_filter_warning or
                self.filter_error != self.prev_filter_error or
                self.filter_command != self.prev_filter_command or
                filter_text_len != self.prev_filter_text_len;

            if (filters_changed) {
                self.scroll_to_bottom = true;
                self.prev_filter_info = self.filter_info;
                self.prev_filter_warning = self.filter_warning;
                self.prev_filter_error = self.filter_error;
                self.prev_filter_command = self.filter_command;
                self.prev_filter_text_len = filter_text_len;
            }

            // Get text filter as slice
            const filter_text: []const u8 = self.filter_text[0..filter_text_len];

            // Message area (scrollable)
            const footer_height = zgui.getStyle().item_spacing[1] + zgui.getFrameHeightWithSpacing();
            var filtered_count: usize = 0;
            {
                _ = zgui.beginChild("ScrollingRegion", .{
                    .w = 0,
                    .h = -footer_height,
                    .child_flags = .{ .border = true },
                });
                defer zgui.endChild();

                // Check if all filters are enabled (no filtering)
                const no_level_filter = self.filter_info and self.filter_warning and
                    self.filter_error and self.filter_command;
                const no_text_filter = filter_text.len == 0;

                if (no_level_filter and no_text_filter) {
                    // Use clipper for efficient rendering when no filtering
                    filtered_count = self.logs.items.len;
                    const text_height = zgui.getTextLineHeightWithSpacing();
                    var clipper = zgui.ListClipper.init();
                    defer clipper.end();

                    clipper.begin(@intCast(self.logs.items.len), text_height);
                    while (clipper.step()) {
                        var i: usize = @as(usize, @intCast(clipper.DisplayStart));
                        const display_end: usize = @as(usize, @intCast(clipper.DisplayEnd));
                        while (i < display_end) : (i += 1) {
                            self.renderLogEntry(self.logs.items[i]);
                        }
                    }
                } else {
                    // Render all items with filtering (can't use clipper with dynamic filtering)
                    for (self.logs.items) |entry| {
                        // Apply text filter first (most likely to filter out)
                        if (filter_text.len > 0) {
                            if (!self.matchesTextFilter(entry.message, filter_text)) continue;
                        }

                        // Check if this is a command or command output
                        const is_command_entry = entry.entry_type == .command or entry.entry_type == .command_output;

                        // Apply level filters
                        if (is_command_entry and !self.filter_command) continue;
                        if (!is_command_entry) {
                            switch (entry.level) {
                                .info => if (!self.filter_info) continue,
                                .warning => if (!self.filter_warning) continue,
                                .@"error" => if (!self.filter_error) continue,
                            }
                        }

                        filtered_count += 1;
                        self.renderLogEntry(entry);
                    }
                }

                // Track if user scrolled away from bottom (disable auto-scroll)
                const scroll_y = zgui.getScrollY();
                const scroll_max_y = zgui.getScrollMaxY();
                const at_bottom = scroll_max_y <= 0 or (scroll_max_y - scroll_y) < 10.0;

                // If user scrolled up, disable auto-scroll
                if (!at_bottom and !self.scroll_to_bottom) {
                    self.auto_scroll = false;
                }

                // Auto-scroll to bottom
                if (self.scroll_to_bottom) {
                    zgui.setScrollHereY(.{ .center_y_ratio = 1.0 });
                    // Only clear scroll flag if console is fully visible
                    if (self.animation_progress >= 1.0) {
                        self.scroll_to_bottom = false;
                        self.auto_scroll = true; // Re-enable auto-scroll when we scroll to bottom
                    }
                }
            }

            // Input area
            zgui.separator();

            // Set focus on input when refocus is requested (after animation completes or command execution)
            if (self.refocus_input) {
                zgui.setKeyboardFocusHere(0);
                self.refocus_input = false;
            }

            // Input field with copy button and filter dropdown on the right
            const copy_button_width: f32 = 60;
            const filter_button_width: f32 = 80;
            const right_buttons_width = copy_button_width + filter_button_width + zgui.getStyle().item_spacing[0];
            zgui.pushItemWidth(-right_buttons_width - zgui.getStyle().item_spacing[0]);
            defer zgui.popItemWidth();

            const input_flags = zgui.InputTextFlags{
                .enter_returns_true = true,
                .callback_history = true,
                .callback_completion = true,
            };

            if (zgui.inputTextWithHint(
                "##Input",
                .{
                    .hint = "Enter command here, press TAB for autocompletions",
                    .buf = &self.input_buffer,
                    .flags = input_flags,
                    .callback = inputCallback,
                    .user_data = self,
                },
            )) {
                const input_len = std.mem.indexOfScalar(u8, &self.input_buffer, 0) orelse self.input_buffer.len;
                if (input_len > 0) {
                    const command = self.input_buffer[0..input_len];

                    // Add to history
                    const cmd_copy = try self.ctx.allocator().dupe(u8, command);
                    try self.input_history.append(self.ctx.allocator(), cmd_copy);
                    self.history_index = null;

                    // Execute command
                    self.executeCommand(command) catch |err| {
                        try self.log(.@"error", "Failed to execute command: {}", .{err});
                    };

                    // Clear input
                    @memset(&self.input_buffer, 0);

                    // Scroll to bottom and re-enable auto-scroll after command execution
                    self.scroll_to_bottom = true;
                    self.auto_scroll = true;

                    // Request refocus for next frame
                    self.refocus_input = true;
                }
            }

            // Clear input buffer for a few frames after opening to discard held backtick
            // This must be after inputTextWithHint so we clear what imgui just added
            if (self.clear_input_frames > 0) {
                @memset(&self.input_buffer, 0);
                self.clear_input_frames -= 1;
            }

            // Copy button on the same line
            zgui.sameLine(.{});
            if (zgui.button("Copy", .{ .w = copy_button_width })) {
                try self.copyLogsToClipboard();
            }
            if (zgui.isItemHovered(.{})) {
                _ = zgui.beginTooltip();
                zgui.text("Copy all logs to clipboard", .{});
                zgui.endTooltip();
            }

            // Filter button on the same line
            zgui.sameLine(.{});
            if (zgui.button("Filter", .{ .w = filter_button_width })) {
                zgui.openPopup("##FilterPopup", .{});
            }

            // Position popup above the button
            const button_pos = zgui.getItemRectMin();
            const popup_width: f32 = 280;
            zgui.setNextWindowPos(.{
                .x = button_pos[0] - popup_width + filter_button_width,
                .y = button_pos[1] - zgui.getStyle().item_spacing[1],
                .pivot_x = 0,
                .pivot_y = 1,
            });
            zgui.setNextWindowSize(.{ .w = popup_width, .h = 0 }); // h=0 for auto-fit

            if (zgui.beginPopup("##FilterPopup", .{})) {
                zgui.text("Showing {d}/{d}", .{ filtered_count, self.logs.items.len });
                zgui.separator();
                _ = zgui.checkbox("Info", .{ .v = &self.filter_info });
                _ = zgui.checkbox("Warning", .{ .v = &self.filter_warning });
                _ = zgui.checkbox("Error", .{ .v = &self.filter_error });
                _ = zgui.checkbox("Command", .{ .v = &self.filter_command });
                zgui.separator();
                _ = zgui.checkbox("Show timestamps", .{ .v = &self.show_timestamps });
                _ = zgui.checkbox("Case sensitive", .{ .v = &self.filter_case_sensitive });
                zgui.separator();
                zgui.text("Search:", .{});
                zgui.setNextItemWidth(-1);
                _ = zgui.inputTextWithHint("##SearchFilter", .{
                    .hint = "text...",
                    .buf = &self.filter_text,
                });
                zgui.endPopup();
            }

            // Show scroll indicator when not at bottom
            if (!self.auto_scroll) {
                zgui.sameLine(.{});
                if (zgui.button("v", .{})) {
                    self.scroll_to_bottom = true;
                }
                if (zgui.isItemHovered(.{})) {
                    _ = zgui.beginTooltip();
                    zgui.text("Scroll to bottom", .{});
                    zgui.endTooltip();
                }
            }
        }
    }
    zgui.end();

    // Render overlay texture if provided using zgui
    if (options.overlay_texture) |texture| {
        // Create a separate window for the overlay
        zgui.setNextWindowPos(.{ .x = console_width, .y = y_offset });
        zgui.setNextWindowSize(.{ .w = overlay_width, .h = target_height });

        const overlay_flags = zgui.WindowFlags{
            .no_title_bar = true,
            .no_resize = true,
            .no_move = true,
            .no_collapse = true,
            .no_scrollbar = true,
            .no_scroll_with_mouse = true,
            .no_background = true,
            .no_bring_to_front_on_focus = true,
            .no_focus_on_appearing = true,
            .no_mouse_inputs = true,
            .no_nav_inputs = true,
            .no_nav_focus = true,
        };

        if (zgui.begin("##ConsoleOverlay", .{ .flags = overlay_flags })) {
            var image_width: f32 = undefined;
            var image_height: f32 = undefined;
            const info = try texture.query();
            if (target_height * @as(f32, @floatFromInt(info.width)) > overlay_width * @as(f32, @floatFromInt(info.height))) {
                image_width = overlay_width;
                image_height = image_width * @as(f32, @floatFromInt(info.height)) / @as(f32, @floatFromInt(info.width));
            } else {
                image_height = target_height;
                image_width = image_height / (@as(f32, @floatFromInt(info.height)) / @as(f32, @floatFromInt(info.width)));
            }
            const tex_ref = texture.toReference();
            zgui.imageWithBg(tex_ref, .{
                .w = image_width,
                .h = image_height,
            });
        }
        zgui.end();
    }
}

/// Get prefered overlay size
pub fn getPreferedOverlaySize(self: Console) geom.Size {
    const size = self.ctx.renderer().getOutputSize() catch unreachable;
    return .{
        .width = @intFromFloat(size.getWidthFloat() * 0.3),
        .height = @intFromFloat(size.getHeightFloat() * 0.5),
    };
}

/// Copy all logs to clipboard
fn copyLogsToClipboard(self: *Console) !void {
    if (self.logs.items.len == 0) {
        return;
    }

    // Get text filter
    const filter_text_len = std.mem.indexOfScalar(u8, &self.filter_text, 0) orelse self.filter_text.len;
    const filter_text: []const u8 = self.filter_text[0..filter_text_len];

    // First pass: calculate size and count filtered items
    var total_size: usize = 0;
    var filtered_count: usize = 0;
    for (self.logs.items) |entry| {
        // Apply text filter first
        if (!self.matchesTextFilter(entry.message, filter_text)) continue;

        // Check if this is a command or command output
        const is_command_entry = entry.entry_type == .command or entry.entry_type == .command_output;

        // Apply level filters
        if (is_command_entry and !self.filter_command) continue;
        if (!is_command_entry) {
            switch (entry.level) {
                .info => if (!self.filter_info) continue,
                .warning => if (!self.filter_warning) continue,
                .@"error" => if (!self.filter_error) continue,
            }
        }

        // Calculate size for this entry
        if (entry.entry_type == .command) {
            total_size += 2 + entry.message.len + 1; // "> " + message + newline
        } else {
            total_size += entry.message.len + 1; // message + newline
        }
        filtered_count += 1;
    }

    if (filtered_count == 0) {
        try self.print("No logs to copy (all filtered out)", .{});
        return;
    }

    // Allocate buffer with null terminator
    const buffer = try self.ctx.allocator().allocSentinel(u8, total_size, 0);
    defer self.ctx.allocator().free(buffer);

    // Second pass: copy filtered messages into buffer
    var offset: usize = 0;
    for (self.logs.items) |entry| {
        // Apply text filter first
        if (!self.matchesTextFilter(entry.message, filter_text)) continue;

        // Check if this is a command or command output
        const is_command_entry = entry.entry_type == .command or entry.entry_type == .command_output;

        // Apply level filters
        if (is_command_entry and !self.filter_command) continue;
        if (!is_command_entry) {
            switch (entry.level) {
                .info => if (!self.filter_info) continue,
                .warning => if (!self.filter_warning) continue,
                .@"error" => if (!self.filter_error) continue,
            }
        }

        // Copy message
        if (entry.entry_type == .command) {
            buffer[offset] = '>';
            offset += 1;
            buffer[offset] = ' ';
            offset += 1;
        }
        @memcpy(buffer[offset .. offset + entry.message.len], entry.message);
        offset += entry.message.len;
        buffer[offset] = '\n';
        offset += 1;
    }

    // Ensure null termination
    buffer[offset] = 0;

    // Set clipboard text
    zgui.setClipboardText(buffer[0..offset :0]);

    // Log confirmation
    try self.print("Copied {d} lines to clipboard", .{filtered_count});
}

/// Input callback for handling history navigation and tab completion
fn inputCallback(data: *zgui.InputTextCallbackData) callconv(.c) i32 {
    const self: *Console = @ptrCast(@alignCast(data.user_data));

    if (data.event_flag.callback_completion) {
        // Tab completion
        const input_len: usize = @intCast(data.buf_text_len);
        if (input_len == 0) return 0;

        const input = data.buf[0..input_len];

        // Find the command being typed (first word)
        const space_pos = std.mem.indexOfScalar(u8, input, ' ');
        if (space_pos != null) return 0; // Don't complete if already typing arguments

        // Find matching commands
        var matches: [32][]const u8 = undefined;
        var match_count: usize = 0;
        var iter = self.commands.iterator();
        while (iter.next()) |entry| {
            if (std.mem.startsWith(u8, entry.key_ptr.*, input)) {
                if (match_count < matches.len) {
                    matches[match_count] = entry.key_ptr.*;
                    match_count += 1;
                }
            }
        }

        if (match_count == 1) {
            // Single match - complete it
            data.deleteChars(0, @intCast(data.buf_text_len));
            data.insertChars(0, matches[0]);
            data.insertChars(@intCast(matches[0].len), " ");
        } else if (match_count > 1) {
            // Multiple matches - find common prefix and show options
            var common_len = matches[0].len;
            for (matches[1..match_count]) |m| {
                var i: usize = 0;
                while (i < common_len and i < m.len and matches[0][i] == m[i]) : (i += 1) {}
                common_len = i;
            }

            if (common_len > input_len) {
                // Complete to common prefix
                data.deleteChars(0, @intCast(data.buf_text_len));
                data.insertChars(0, matches[0][0..common_len]);
            } else {
                // Show available completions
                self.print("Available commands:", .{}) catch {};
                for (matches[0..match_count]) |m| {
                    self.print("  {s}", .{m}) catch {};
                }
            }
        }
    } else if (data.event_flag.callback_history) {
        if (data.event_key == .up_arrow) {
            // Navigate up in history
            if (self.input_history.items.len > 0) {
                if (self.history_index) |*idx| {
                    if (idx.* > 0) {
                        idx.* -= 1;
                    }
                } else {
                    self.history_index = self.input_history.items.len - 1;
                }

                if (self.history_index) |idx| {
                    const cmd = self.input_history.items[idx];
                    data.deleteChars(0, @intCast(data.buf_text_len));
                    data.insertChars(0, cmd);
                }
            }
        } else if (data.event_key == .down_arrow) {
            // Navigate down in history
            if (self.history_index) |*idx| {
                if (idx.* < self.input_history.items.len - 1) {
                    idx.* += 1;
                    const cmd = self.input_history.items[idx.*];
                    data.deleteChars(0, @intCast(data.buf_text_len));
                    data.insertChars(0, cmd);
                } else {
                    self.history_index = null;
                    data.deleteChars(0, @intCast(data.buf_text_len));
                }
            }
        }
    }

    return 0;
}

/// Render a single log entry
fn renderLogEntry(self: *Console, entry: LogEntry) void {
    const is_command = entry.entry_type == .command;
    const is_command_output = entry.entry_type == .command_output;

    // Draw background for command entries
    if (is_command or is_command_output) {
        const cursor_pos = zgui.getCursorScreenPos();
        const avail_width = zgui.getContentRegionAvail()[0];
        const text_height = zgui.getTextLineHeight();
        const draw_list = zgui.getWindowDrawList();

        const bg_color: u32 = if (is_command)
            0xFF3D2817 // dark brown/orange background for command line
        else
            0xFF2D2D2D; // dark gray for output

        draw_list.addRectFilled(.{
            .pmin = .{ cursor_pos[0], cursor_pos[1] },
            .pmax = .{ cursor_pos[0] + avail_width, cursor_pos[1] + text_height },
            .col = bg_color,
        });
    }

    // Set text color
    const color = if (is_command)
        [4]f32{ 0.5, 1.0, 0.5, 1.0 } // Green for command input
    else if (is_command_output)
        [4]f32{ 0.8, 0.8, 0.8, 1.0 } // Light gray for command output
    else switch (entry.level) {
        .info => [4]f32{ 1.0, 1.0, 1.0, 1.0 },
        .warning => [4]f32{ 1.0, 1.0, 0.0, 1.0 },
        .@"error" => [4]f32{ 1.0, 0.2, 0.2, 1.0 },
    };

    zgui.pushStyleColor4f(.{ .idx = .text, .c = color });
    defer zgui.popStyleColor(.{});

    // Display message
    if (is_command) {
        // Command: show with > prefix
        zgui.text("> {s}", .{entry.message});
    } else if (is_command_output) {
        // Command output: show as-is (no timestamp)
        zgui.textUnformatted(entry.message);
    } else {
        // Regular log entry
        if (self.show_timestamps) {
            zgui.textUnformatted(entry.message);
        } else {
            // Skip timestamp but keep level prefix: "[YYYY-MM-DD HH:MM:SS] I " -> "I "
            const timestamp_end = std.mem.indexOf(u8, entry.message, "] ");
            if (timestamp_end) |end| {
                const level_start = end + 2; // Skip "] "
                if (level_start < entry.message.len) {
                    zgui.textUnformatted(entry.message[level_start..]);
                } else {
                    zgui.textUnformatted(entry.message);
                }
            } else {
                zgui.textUnformatted(entry.message);
            }
        }
    }
}

// Default command implementations

fn helpCommand(args: []const []const u8, userdata: ?*anyopaque, console: *Console) !void {
    _ = args;
    _ = userdata;
    try console.print("Available commands:", .{});
    var iter = console.commands.iterator();
    while (iter.next()) |entry| {
        try console.print("  {s} - {s}", .{ entry.key_ptr.*, entry.value_ptr.description });
    }
}

fn clearCommand(args: []const []const u8, userdata: ?*anyopaque, console: *Console) !void {
    _ = args;
    _ = userdata;
    for (console.logs.items) |entry| {
        console.ctx.allocator().free(entry.message);
    }
    console.logs.clearRetainingCapacity();
    try console.print("Console cleared", .{});
}
