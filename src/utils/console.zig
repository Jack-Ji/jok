const std = @import("std");
const jok = @import("../jok.zig");
const imgui = jok.imgui;

pub const Error = error{
    DuplicateCommand,
};

pub const CommandExecuter = struct {
    callback: *const fn (console: *Console, cmd: []const u8, user_data: ?*anyopaque) anyerror!void,
    user_data: ?*anyopaque = null,
};

pub const Console = struct {
    allocator: std.mem.Allocator,
    input_buf: [256]u8,
    items: std.ArrayList([]const u8),
    history: std.ArrayList([]const u8),
    history_pos: i32, // -1: new line, 0..history.len-1 browsing history.
    filter: *Filter,
    auto_scroll: bool,
    scroll_to_bottom: bool,
    commands: std.StringHashMap(CommandExecuter),

    pub fn create(allocator: std.mem.Allocator) !*Console {
        const c = try allocator.create(Console);
        c.* = .{
            .allocator = allocator,
            .input_buf = undefined,
            .items = std.ArrayList([]const u8).init(allocator),
            .history = std.ArrayList([]const u8).init(allocator),
            .history_pos = -1,
            .filter = try Filter.create(allocator),
            .auto_scroll = true,
            .scroll_to_bottom = false,
            .commands = std.StringHashMap(CommandExecuter).init(allocator),
        };
        @memset(&c.input_buf, 0);
        try c.addCommand("help", .{ .callback = internalCommands });
        try c.addCommand("history", .{ .callback = internalCommands });
        try c.addCommand("clear", .{ .callback = internalCommands });
        return c;
    }

    pub fn destroy(self: *Console) void {
        var it = self.commands.keyIterator();
        while (it.next()) |c| self.allocator.free(c.*);
        self.commands.deinit();
        self.filter.destroy();
        self.clearLog();
        self.items.deinit();
        for (self.history.items) |s| self.allocator.free(s);
        self.history.deinit();
        self.allocator.destroy(self);
    }

    pub fn addCommand(self: *Console, command_name: []const u8, executer: CommandExecuter) !void {
        if (self.commands.get(command_name) != null) return error.DuplicateCommand;
        try self.commands.put(try self.allocator.dupe(u8, command_name), executer);
    }

    pub fn deleteCommand(self: *Console, command_name: []const u8) void {
        if (self.commands.fetchRemove(command_name)) |kv| {
            self.allocator.free(kv.key);
        }
    }

    fn internalCommands(console: *Console, cmd: []const u8, user_data: ?*anyopaque) !void {
        _ = user_data;

        // Process command
        if (std.mem.eql(u8, cmd, "clear")) {
            console.clearLog();
            return;
        } else if (std.mem.eql(u8, cmd, "help")) {
            try console.addLog("Commands:", .{});
            var it = console.commands.keyIterator();
            while (it.next()) |k| {
                try console.addLog("- {s}", .{k.*});
            }
            return;
        } else if (std.mem.eql(u8, cmd, "history")) {
            var i = if (console.history.items.len > 10)
                console.history.items.len - 10
            else
                0;
            while (i < console.history.items.len) : (i += 1) {
                try console.addLog("{d:3}: {s}", .{ i, console.history.items[i] });
            }
            return;
        }

        unreachable;
    }

    pub fn clearLog(self: *Console) void {
        for (self.items.items) |s| self.allocator.free(s);
        self.items.clearRetainingCapacity();
    }

    pub fn addLog(self: *Console, comptime fmt: []const u8, args: anytype) !void {
        const buf = imgui.format(fmt, args);
        try self.items.append(try self.allocator.dupe(u8, buf));
    }

    pub fn draw(self: *Console, title: [:0]const u8) !void {
        imgui.setNextWindowSize(.{ .w = 520, .h = 600, .cond = .first_use_ever });
        imgui.setNextWindowSize(.{
            .cond = .first_use_ever,
            .w = 520,
            .h = 600,
        });
        if (!imgui.begin(title, .{})) {
            imgui.end();
            return;
        }

        _ = imgui.checkbox("Auto-scroll", .{ .v = &self.auto_scroll });
        imgui.sameLine(.{});
        const copy_to_clipboard = imgui.smallButton("Copy To Clipboard");

        imgui.separator();

        try self.filter.draw("Filter (\"incl,-excl\") (\"error\")", 180);

        imgui.separator();

        // Reserve enough left-over height for 1 separator + 1 input text
        const footer_height_to_reserve = imgui.getStyle().item_spacing[1] + imgui.getFrameHeightWithSpacing();
        if (imgui.beginChild("ScrollingRegion", .{
            .h = -footer_height_to_reserve,
            .child_flags = .{ .nav_flattened = true },
            .window_flags = .{ .horizontal_scrollbar = true },
        })) {
            imgui.pushStyleVar2f(.{ .idx = .item_spacing, .v = .{ 4, 1 } });
            if (copy_to_clipboard) imgui.logToClipboard(.{});
            for (self.items.items) |t| {
                if (!self.filter.passFilter(t)) continue;

                // Normally you would store more information in your item than just a string.
                // (e.g. make Items[] an array of structure, store color/type etc.)
                var color: ?jok.Color = null;
                if (std.mem.indexOf(u8, t, "[error]") != null) {
                    color = .rgb(255, 102, 102);
                } else if (std.mem.startsWith(u8, t, "# ")) {
                    color = .rgb(255, 204, 153);
                }
                if (color) |c| imgui.pushStyleColor1u(.{
                    .idx = .text,
                    .c = c.toInternalColor(),
                });
                imgui.textUnformatted(t);
                if (color != null) imgui.popStyleColor(.{});
            }
            if (copy_to_clipboard) imgui.logFinish();

            // Keep up at the bottom of the scroll region if we were already at the bottom at the beginning of the frame.
            // Using a scrollbar or mouse-wheel will take away from the bottom edge.
            if (self.scroll_to_bottom or (self.auto_scroll and imgui.getScrollY() >= imgui.getScrollMaxX())) {
                imgui.setScrollHereY(.{ .center_y_ratio = 1.0 });
            }
            self.scroll_to_bottom = false;

            imgui.popStyleVar(.{});
        }
        imgui.endChild();

        imgui.separator();

        // Command-line
        var reclaim_focus = false;
        if (imgui.inputText("Input", .{
            .buf = self.input_buf[0..],
            .flags = .{
                .enter_returns_true = true,
                .escape_clears_all = true,
                .callback_completion = true,
                .callback_history = true,
            },
            .callback = inputTextCallback,
            .user_data = self,
        })) {
            const buf = std.mem.sliceTo(&self.input_buf, 0);
            const s = std.mem.trimRight(u8, buf, " ");
            if (s.len > 0) try self.execCommand(s);
            self.input_buf[0] = 0;
            reclaim_focus = true;
        }

        // Auto-focus on window apparition
        imgui.setItemDefaultFocus();
        if (reclaim_focus) {
            imgui.setKeyboardFocusHere(-1); // Auto focus previous widget
        }

        imgui.end();
    }

    fn execCommand(self: *Console, command_line: []const u8) !void {
        try self.addLog("# {s}", .{command_line});

        // Insert into history. First find match and delete it so it can be pushed to the back.
        // This isn't trying to be smart or optimal.
        self.history_pos = -1;
        if (self.history.items.len > 0) {
            var i = self.history.items.len;
            while (i > 0) {
                i -= 1;
                if (std.mem.eql(u8, self.history.items[i], command_line)) {
                    self.allocator.free(self.history.items[i]);
                    _ = self.history.orderedRemove(i);
                    break;
                }
            }
        }
        try self.history.append(try self.allocator.dupe(u8, command_line));

        if (self.commands.get(command_line)) |executer| {
            try executer.callback(self, command_line, executer.user_data);
        } else {
            try self.addLog("Unknown command: '{s}'", .{command_line});
        }

        // On command input, we scroll to bottom even if !auto_scroll
        self.scroll_to_bottom = true;
    }

    fn inputTextCallback(data: *imgui.InputTextCallbackData) callconv(.C) i32 {
        var self: *Console = @alignCast(@ptrCast(data.user_data.?));
        return self.textEditCallback(data);
    }

    fn textEditCallback(self: *Console, data: *imgui.InputTextCallbackData) i32 {
        if (data.event_flag.callback_completion) {
            // Locate beginning of current word
            const word_end_idx = @as(usize, @intCast(data.cursor_pos));
            const word_begin_idx = std.mem.lastIndexOfAny(u8, data.buf[0..word_end_idx], " \t,;") orelse 0;
            const word = data.buf[word_begin_idx..word_end_idx];

            // Build a list of candidates
            var candidates = std.ArrayList([]const u8).initCapacity(self.allocator, 10) catch unreachable;
            defer candidates.deinit();
            var it = self.commands.keyIterator();
            while (it.next()) |k| {
                if (std.mem.startsWith(u8, k.*, word)) {
                    candidates.append(k.*) catch unreachable;
                }
            }

            if (candidates.items.len == 0) {
                // No match
                self.addLog("No match for \"{s}\"!", .{word}) catch unreachable;
            } else if (candidates.items.len == 1) {
                // Single match. Delete the beginning of the word and replace it entirely so we've got nice casing.
                data.deleteChars(@intCast(word_begin_idx), @intCast(word.len));
                data.insertChars(data.cursor_pos, candidates.items[0]);
                data.insertChars(data.cursor_pos, " ");
            } else {
                // Multiple matches. Complete as much as we can..
                // So inputing "C"+Tab will complete to "CL" then display "CLEAR" and "CLASSIFY" as matches.
                var match_len = word.len;
                while (true) {
                    var c: u8 = 0;
                    var all_candidates_matches = true;
                    var i: usize = 0;
                    while (i < candidates.items.len and all_candidates_matches) : (i += 1) {
                        if (i == 0) {
                            c = std.ascii.toUpper(candidates.items[i][match_len]);
                        } else if (c == 0 or c != std.ascii.toUpper(candidates.items[i][match_len])) {
                            all_candidates_matches = false;
                        }
                    }
                    if (!all_candidates_matches) break;
                    match_len += 1;
                }

                if (match_len > 0) {
                    data.deleteChars(@intCast(word_begin_idx), @intCast(word.len));
                    data.insertChars(data.cursor_pos, candidates.items[0][0..match_len]);
                }

                // List matches
                self.addLog("Possible matches:", .{}) catch unreachable;
                for (candidates.items) |c| self.addLog("- {s}", .{c}) catch unreachable;
            }
        } else if (data.event_flag.callback_history) {
            // Reuse history
            const prev_history_pos = self.history_pos;
            if (data.event_key == .up_arrow) {
                if (self.history_pos == -1) {
                    self.history_pos = @as(i32, @intCast(self.history.items.len)) - 1;
                } else if (self.history_pos > 0) {
                    self.history_pos -= 1;
                }
            } else if (data.event_key == .down_arrow) {
                if (self.history_pos != -1) {
                    self.history_pos += 1;
                    if (self.history_pos >= @as(i32, @intCast(self.history.items.len)))
                        self.history_pos = -1;
                }
            }

            // A better implementation would preserve the data on the current input line along with cursor position.
            if (prev_history_pos != self.history_pos) {
                const history_str = if (self.history_pos >= 0) self.history.items[@intCast(self.history_pos)] else "";
                data.deleteChars(0, data.buf_text_len);
                data.insertChars(0, history_str);
            }
        }
        return 0;
    }
};

// Helper: Parse and apply text filters. In format "aaaaa[,bbbb][,ccccc]"
const Filter = struct {
    allocator: std.mem.Allocator,
    input_buf: [256:0]u8,
    fields: std.ArrayList([]const u8),
    count_grep: u32,

    fn create(allocator: std.mem.Allocator) !*Filter {
        const filter = try allocator.create(Filter);
        filter.* = .{
            .allocator = allocator,
            .input_buf = undefined,
            .fields = std.ArrayList([]const u8).init(allocator),
            .count_grep = 0,
        };
        @memset(&filter.input_buf, 0);
        return filter;
    }

    fn destroy(self: *Filter) void {
        self.fields.deinit();
        self.allocator.destroy(self);
    }

    fn clear(self: *Filter) void {
        self.input_buf[0] = 0;
        self.build() catch unreachable;
    }

    fn build(self: *Filter) !void {
        self.fields.clearRetainingCapacity();
        self.count_grep = 0;
        var it = std.mem.splitScalar(
            u8,
            std.mem.sliceTo(&self.input_buf, 0),
            ',',
        );
        while (it.next()) |f| {
            if (f.len == 0) continue;
            var b: u32 = 0;
            var e: u32 = @intCast(f.len - 1);
            while (b < e and f[b] == ' ' or f[b] == '\t') b += 1;
            while (b < e and f[e] == ' ' or f[e] == '\t') e -= 1;
            const s = f[b..e];
            if (s.len == 0) continue;
            try self.fields.append(s);
            if (s[0] != '-') self.count_grep += 1;
        }
    }

    fn draw(self: *Filter, label: [:0]const u8, width: f32) !void {
        if (width != 0) imgui.setNextItemWidth(width);
        if (imgui.inputText(label, .{ .buf = &self.input_buf })) {
            try self.build();
        }
    }

    fn passFilter(self: *Filter, text: []const u8) bool {
        if (self.fields.items.len == 0) return true;

        for (self.fields.items) |f| {
            if (f[0] == '-') { // Subtract
                if (std.mem.indexOf(u8, text, f[1..]) != null) {
                    return false;
                }
            } else { // Grep
                if (std.mem.indexOf(u8, text, f) != null) {
                    return true;
                }
            }
        }

        // Implicit * grep
        if (self.count_grep == 0) return true;
        return false;
    }
};
