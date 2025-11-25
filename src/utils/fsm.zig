//! The library offer two state machine type constructors, StateMachineFromTable and StateMachine.
//! The first type is defined using an array of events and state transitions.
//! The second type is defined by calling methods for adding events and transitions.
//! State machines can also be constructed by importing Graphviz or libfsm text.
//! SPDX-License-Identifier: MIT

const std = @import("std");
const EnumField = std.builtin.Type.EnumField;

/// State transition errors
pub const StateError = error{
    /// Invalid transition
    Invalid,
    /// A state transition was canceled
    Canceled,
    /// An event or state transition has already been defined
    AlreadyDefined,
};

/// Transition handlers must return whether the transition should complete or be canceled.
/// This can be used for state transition guards, as well as logging and debugging.
pub const HandlerResult = enum {
    /// Continue with the transition
    Continue,
    /// Cancel the transition by returning StateError.Canceled
    Cancel,
    /// Cancel the transition without error
    CancelNoError,
};

/// A transition, with optional event
pub fn Transition(comptime StateType: type, comptime EventType: ?type) type {
    return struct {
        event: if (EventType) |T| ?T else ?void = null,
        from: StateType,
        to: StateType,
    };
}
const ImportLineState = enum { ready, source, target, event, await_start_state, startstate, await_end_states, endstates };
const ImportInput = enum { identifier, startcolon, endcolon, newline };
const import_transition_table = [_]Transition(ImportLineState, ImportInput){
    .{ .event = .identifier, .from = .ready, .to = .source },
    .{ .event = .identifier, .from = .target, .to = .event },
    .{ .event = .identifier, .from = .event, .to = .event },
    .{ .event = .identifier, .from = .await_start_state, .to = .startstate },
    .{ .event = .identifier, .from = .await_end_states, .to = .endstates },
    .{ .event = .identifier, .from = .endstates, .to = .endstates },
    .{ .event = .identifier, .from = .source, .to = .target },
    .{ .event = .startcolon, .from = .ready, .to = .await_start_state },
    .{ .event = .endcolon, .from = .ready, .to = .await_end_states },
    .{ .event = .newline, .from = .ready, .to = .ready },
    .{ .event = .newline, .from = .startstate, .to = .ready },
    .{ .event = .newline, .from = .endstates, .to = .ready },
    .{ .event = .newline, .from = .target, .to = .ready },
    .{ .event = .newline, .from = .event, .to = .ready },
};

const ImportFSM = StateMachineFromTable(ImportLineState, ImportInput, import_transition_table[0..], .ready, &.{});

/// Construct a state machine type given a state enum and an optional event enum.
/// Add states and events using the member functions.
pub fn StateMachine(
    comptime StateType: type,
    comptime EventType: ?type,
    comptime initial_state: StateType,
) type {
    return StateMachineFromTable(StateType, EventType, &[0]Transition(StateType, EventType){}, initial_state, &[0]StateType{});
}

/// Construct a state machine type given a state enum, an optional event enum, a transition table, initial state and end states (which can be empty)
/// If you want to add transitions and end states using the member methods, you can use `StateMachine(...)` as a shorthand.
pub fn StateMachineFromTable(
    comptime StateType: type,
    comptime EventType: ?type,
    comptime transitions: []const Transition(StateType, EventType),
    comptime initial_state_a: StateType,
    comptime final_states: []const StateType,
) type {
    const initial_state = initial_state_a;
    const StateEventSelector = enum { state, event };
    const EventTypeArg = if (EventType) |T| T else void;
    const StateEventUnion = union(StateEventSelector) {
        state: StateType,
        event: if (EventType) |T| T else void,
    };

    const state_type_count = comptime std.meta.fields(StateType).len;
    const event_type_count = comptime if (EventType) |T| std.meta.fields(T).len else 0;
    const TransitionBitSet = std.StaticBitSet(state_type_count * state_type_count);
    const FinalStatesType = std.StaticBitSet(state_type_count);

    const state_enum_bits = std.math.log2_int_ceil(usize, state_type_count);
    const event_enum_bits = if (event_type_count > 0) std.math.log2_int_ceil(usize, event_type_count) else 0;

    // Events are organized into a packed 2D array. Indexing by state and event yields the next state (where 0 means no transition)
    // Add 1 to bit_count because zero is used to indicates absence of transition (no target state defined for a source state/event combination)
    // Cell values must thus be adjusted accordingly when added or queried.
    const bits_per_cell = @as(u16, @max(state_enum_bits, event_enum_bits)) + 1;
    const total_bits = (bits_per_cell * state_type_count * @max(event_type_count, 1));
    const total_bytes = total_bits / 8 + 1;
    const CellType = std.meta.Int(.unsigned, bits_per_cell);
    const EventPackedIntArray = if (EventType != null)
        [total_bytes]u8
    else
        void;

    return struct {
        internal: struct {
            start_state: StateType,
            current_state: StateType,
            state_map: TransitionBitSet,
            final_states: FinalStatesType,
            transition_handlers: []const *Handler,
            events: EventPackedIntArray,
        } = undefined,

        const Self = @This();
        pub const StateEnum = StateType;
        pub const EventEnum = if (EventType) |T| T else void;

        /// Transition handler interface
        pub const Handler = struct {
            onTransition: *const fn (self: *Handler, event: ?EventTypeArg, from: StateType, to: StateType) HandlerResult,
        };

        /// Returns a new state machine instance
        pub fn init() Self {
            var instance: Self = .{};
            instance.internal.start_state = initial_state;
            instance.internal.current_state = initial_state;
            instance.internal.final_states = FinalStatesType.initEmpty();
            instance.internal.transition_handlers = &.{};
            instance.internal.state_map = TransitionBitSet.initEmpty();
            if (comptime EventType != null) {
                instance.internal.events = .{0} ** total_bytes;
            }

            for (transitions) |t| {
                const offset = (@intFromEnum(t.from) * state_type_count) + @intFromEnum(t.to);
                instance.internal.state_map.setValue(offset, true);

                if (comptime EventType != null) {
                    if (t.event) |event| {
                        const slot = computeEventSlot(event, t.from);
                        std.mem.writePackedIntNative(CellType, &instance.internal.events, slot * bits_per_cell, @intFromEnum(t.to) + @as(CellType, 1));
                    }
                }
            }

            for (final_states) |f| {
                instance.internal.final_states.setValue(@intFromEnum(f), true);
            }

            return instance;
        }

        /// Create a new state machine instance, with state transitions imported from the given Graphviz or libfsm text
        pub fn initFrom(input: []const u8) !Self {
            var instance = Self.init();
            try instance.importText(input);
            return instance;
        }

        /// Returns the current state
        pub fn currentState(self: *Self) StateType {
            return self.internal.current_state;
        }

        /// Sets the start state. This becomes the new `currentState()`.
        pub fn setStartState(self: *Self, start_state: StateType) void {
            self.internal.start_state = start_state;
            self.internal.current_state = start_state;
        }

        /// Unconditionally restart the state machine.
        /// This sets the current state back to the initial start state.
        pub fn restart(self: *Self) void {
            self.internal.current_state = self.internal.start_state;
        }

        /// Same as `restart` but fails if the state machine is currently neither in a final state,
        /// nor in the initial start state.
        pub fn safeRestart(self: *Self) StateError!void {
            if (!self.isInFinalState() and !self.isInStartState()) return StateError.Invalid;
            self.internal.current_state = self.internal.start_state;
        }

        /// Returns true if the current state is the start state
        pub fn isInStartState(self: *Self) bool {
            return self.internal.current_state == self.internal.start_state;
        }

        /// Final states are optional. Note that it's possible, and common, for transitions
        /// to exit final states during execution. It's up to the library user to check for
        /// any final state conditions, using `isInFinalState()` or comparing with `currentState()`
        /// Returns `StateError.Invalid` if the final state is already added.
        pub fn addFinalState(self: *Self, final_state: StateType) !void {
            if (self.isFinalState(final_state)) return StateError.Invalid;
            self.internal.final_states.setValue(@intFromEnum(final_state), true);
        }

        /// Returns true if the state machine is in a final state
        pub fn isInFinalState(self: *Self) bool {
            return self.internal.final_states.isSet(@intFromEnum(self.currentState()));
        }

        /// Returns true if the argument is a final state
        pub fn isFinalState(self: *Self, state: StateType) bool {
            return self.internal.final_states.isSet(@intFromEnum(state));
        }

        /// Invoke all `handlers` when a state transition happens
        pub fn setTransitionHandlers(self: *Self, handlers: []const *Handler) void {
            self.internal.transition_handlers = handlers;
        }

        /// Add the transition `from` -> `to` if missing, and define an event for the transition
        pub fn addEventAndTransition(self: *Self, event: EventTypeArg, from: StateType, to: StateType) !void {
            if (comptime EventType != null) {
                if (!self.canTransitionFromTo(from, to)) try self.addTransition(from, to);
                try self.addEvent(event, from, to);
            }
        }

        /// Check if the transition `from` -> `to` is valid and add the event for this transition
        pub fn addEvent(self: *Self, event: EventTypeArg, from: StateType, to: StateType) !void {
            if (comptime EventType != null) {
                if (self.canTransitionFromTo(from, to)) {
                    const slot = computeEventSlot(event, from);
                    const slot_val = std.mem.readPackedIntNative(CellType, &self.internal.events, slot * bits_per_cell);
                    if (slot_val != 0) return StateError.AlreadyDefined;
                    std.mem.writePackedIntNative(CellType, &self.internal.events, slot * bits_per_cell, @as(CellType, @intCast(@intFromEnum(to))) + 1);
                } else return StateError.Invalid;
            }
        }

        /// Trigger a transition using an event
        /// Returns `StateError.Invalid` if the event is not defined for the current state
        pub fn do(self: *Self, event: EventTypeArg) !Transition(StateType, EventType) {
            if (comptime EventType != null) {
                const from_state = self.internal.current_state;
                const slot = computeEventSlot(event, self.internal.current_state);
                const to_state = std.mem.readPackedIntNative(CellType, &self.internal.events, slot * bits_per_cell);
                if (to_state != 0) {
                    try self.transitionToInternal(event, @as(StateType, @enumFromInt(to_state - 1)));
                    return .{ .event = event, .from = from_state, .to = @as(StateType, @enumFromInt(to_state - 1)) };
                } else {
                    return StateError.Invalid;
                }
            }
        }

        /// Given an event and a from-state (usually the current state), return the slot index for the to-state
        fn computeEventSlot(event: EventTypeArg, from: StateType) usize {
            return @as(usize, @intCast(@intFromEnum(from))) * event_type_count + @intFromEnum(event);
        }

        /// Add a valid state transition
        /// Returns `StateError.AlreadyDefined` if the transition is already defined
        pub fn addTransition(self: *Self, from: StateType, to: StateType) !void {
            const offset: usize = (@as(usize, @intCast(@intFromEnum(from))) * state_type_count) + @intFromEnum(to);
            if (self.internal.state_map.isSet(offset)) return StateError.AlreadyDefined;
            self.internal.state_map.setValue(offset, true);
        }

        /// Returns true if the current state is equal to `requested_state`
        pub fn isCurrently(self: *Self, requested_state: StateType) bool {
            return self.internal.current_state == requested_state;
        }

        /// Returns true if the transition is possible
        pub fn canTransitionTo(self: *Self, new_state: StateType) bool {
            const offset: usize = (@as(usize, @intCast(@intFromEnum(self.currentState()))) * state_type_count) + @intFromEnum(new_state);
            return self.internal.state_map.isSet(offset);
        }

        /// Returns true if the transition `from` -> `to` is possible
        pub fn canTransitionFromTo(self: *Self, from: StateType, to: StateType) bool {
            const offset: usize = (@as(usize, @intCast(@intFromEnum(from))) * state_type_count) + @intFromEnum(to);
            return self.internal.state_map.isSet(offset);
        }

        /// If possible, transition from current state to `new_state`
        /// Returns `StateError.Invalid` if the transition is not allowed
        pub fn transitionTo(self: *Self, new_state: StateType) StateError!void {
            return self.transitionToInternal(null, new_state);
        }

        fn transitionToInternal(self: *Self, event: ?EventTypeArg, new_state: StateType) StateError!void {
            if (!self.canTransitionTo(new_state)) {
                return StateError.Invalid;
            }

            for (self.internal.transition_handlers) |handler| {
                switch (handler.onTransition(handler, event, self.currentState(), new_state)) {
                    .Cancel => return StateError.Canceled,
                    .CancelNoError => return,
                    else => {},
                }
            }

            self.internal.current_state = new_state;
        }

        /// Sets the new current state without firing any registered handlers
        /// Checking if the transition is valid is only done if `check_valid_transition` is true
        pub fn transitionToSilently(self: *Self, new_state: StateType, check_valid_transition: bool) StateError!void {
            if (check_valid_transition and !self.canTransitionTo(new_state)) {
                return StateError.Invalid;
            }
            self.internal.current_state = new_state;
        }

        /// Transition initiated by state or event
        /// Returns `StateError.Invalid` if the transition is not allowed
        pub fn apply(self: *Self, state_or_event: StateEventUnion) !void {
            if (state_or_event == StateEventSelector.state) {
                try self.transitionTo(state_or_event.state);
            } else if (EventType) |_| {
                _ = try self.do(state_or_event.event);
            }
        }

        /// An iterator that returns the next possible states
        pub const PossibleNextStateIterator = struct {
            fsm: *Self,
            index: usize = 0,

            /// Next valid state, or null if no more valid states are available
            pub fn next(self: *@This()) ?StateEnum {
                inline for (std.meta.fields(StateType), 0..) |field, i| {
                    if (i == self.index) {
                        self.index += 1;
                        if (self.fsm.canTransitionTo(@as(StateType, @enumFromInt(field.value)))) {
                            return @as(StateType, @enumFromInt(field.value));
                        }
                    }
                }

                return null;
            }

            /// Restarts the iterator
            pub fn reset(self: *@This()) void {
                self.index = 0;
            }
        };

        /// Returns an iterator for the next possible states from the current state
        pub fn validNextStatesIterator(self: *Self) PossibleNextStateIterator {
            return .{ .fsm = self };
        }

        /// Graphviz export options
        pub const ExportOptions = struct {
            rankdir: []const u8 = "LR",
            layout: ?[]const u8 = null,
            shape: []const u8 = "circle",
            shape_final_state: []const u8 = "doublecircle",
            fixed_shape_size: bool = false,
            show_events: bool = true,
            show_initial_state: bool = false,
        };

        /// Exports a Graphviz directed graph to the given writer
        pub fn exportGraphviz(self: *Self, title: []const u8, writer: *std.Io.Writer, options: ExportOptions) !void {
            try writer.print("digraph {s} {{\n", .{title});
            try writer.print("    rankdir=LR;\n", .{});
            if (options.layout) |layout| try writer.print("    layout={s};\n", .{layout});
            if (options.show_initial_state) try writer.print("    node [shape = point ]; \"start:\";\n", .{});

            // Style for final states
            if (self.internal.final_states.count() > 0) {
                try writer.print("    node [shape = {s} fixedsize = {}];", .{ options.shape_final_state, options.fixed_shape_size });
                var final_it = self.internal.final_states.iterator(.{ .kind = .set, .direction = .forward });
                while (final_it.next()) |index| {
                    try writer.print(" \"{s}\" ", .{@tagName(@as(StateType, @enumFromInt(index)))});
                }

                try writer.print(";\n", .{});
            }

            // Default style
            try writer.print("    node [shape = {s} fixedsize = {}];\n", .{ options.shape, options.fixed_shape_size });

            if (options.show_initial_state) {
                try writer.print("    \"start:\" -> \"{s}\";\n", .{@tagName(self.internal.start_state)});
            }

            var it = self.internal.state_map.iterator(.{ .kind = .set, .direction = .forward });
            while (it.next()) |index| {
                const from = @as(StateType, @enumFromInt(index / state_type_count));
                const to = @as(StateType, @enumFromInt(index % state_type_count));

                try writer.print("    \"{s}\" -> \"{s}\"", .{ @tagName(from), @tagName(to) });

                if (EventType) |T| {
                    if (options.show_events) {
                        const events_start_offset = @as(usize, @intCast(@intFromEnum(from))) * event_type_count;
                        var transition_name_buf: [4096]u8 = undefined;
                        var transition_name = std.Io.Writer.fixed(&transition_name_buf);
                        for (0..event_type_count) |event_index| {
                            const slot_val = std.mem.readPackedIntNative(CellType, &self.internal.events, (events_start_offset + event_index) * bits_per_cell);
                            if (slot_val > 0 and (slot_val - 1) == @intFromEnum(to)) {
                                if (transition_name.end == 0) {
                                    try writer.print(" [label = \"", .{});
                                }
                                if (transition_name.end > 0) {
                                    try transition_name.print(" || ", .{});
                                }
                                try transition_name.print("{s}", .{@tagName(@as(T, @enumFromInt(event_index)))});
                            }
                        }
                        if (transition_name.end > 0) {
                            try writer.print("{s}\"]", .{transition_name.buffered()});
                        }
                    }
                }

                try writer.print(";\n", .{});
            }
            try writer.print("}}\n", .{});
        }

        const ImportParseHandler = struct {
            handler: ImportFSM.Handler,
            fsm: *Self,
            from: ?StateType = null,
            to: ?StateType = null,
            current_identifer: []const u8 = "",

            pub fn init(fsmptr: *Self) @This() {
                return .{
                    .handler = Interface.make(ImportFSM.Handler, @This()),
                    .fsm = fsmptr,
                };
            }

            pub fn onTransition(handler: *ImportFSM.Handler, event: ?ImportInput, from: ImportLineState, to: ImportLineState) HandlerResult {
                const parse_handler = Interface.downcast(@This(), handler);
                _ = from;
                _ = event;

                if (to == .startstate) {
                    const start_enum = std.meta.stringToEnum(StateType, parse_handler.current_identifer);
                    if (start_enum) |e| parse_handler.fsm.setStartState(e);
                } else if (to == .endstates) {
                    const end_enum = std.meta.stringToEnum(StateType, parse_handler.current_identifer);
                    if (end_enum) |e| parse_handler.fsm.addFinalState(e) catch return HandlerResult.Cancel;
                } else if (to == .source) {
                    const from_enum = std.meta.stringToEnum(StateType, parse_handler.current_identifer);
                    parse_handler.from = from_enum;
                } else if (to == .target) {
                    const to_enum = std.meta.stringToEnum(StateType, parse_handler.current_identifer);
                    parse_handler.to = to_enum;
                    if (parse_handler.from != null and parse_handler.to != null) {
                        parse_handler.fsm.addTransition(parse_handler.from.?, parse_handler.to.?) catch |e| {
                            if (e != StateError.AlreadyDefined) return HandlerResult.Cancel;
                        };
                    }
                } else if (to == .event) {
                    if (EventType != null) {
                        const event_enum = std.meta.stringToEnum(EventType.?, parse_handler.current_identifer);
                        if (event_enum) |te| {
                            parse_handler.fsm.addEvent(te, parse_handler.from.?, parse_handler.to.?) catch {
                                return HandlerResult.Cancel;
                            };
                        }
                    } else {
                        return HandlerResult.Cancel;
                    }
                }

                return HandlerResult.Continue;
            }
        };

        /// Reads a state machine from a buffer containing Graphviz or libfsm text.
        /// Any currently existing transitions are preserved.
        /// Parsing is supported at both comptime and runtime.
        ///
        /// Lines of the following forms are considered during parsing:
        ///
        ///    a -> b
        ///    "a" -> "b"
        ///    a -> b [label="someevent"]
        ///    a -> b [label="event1 || event2"]
        ///    a -> b "event1"
        ///    "a" -> "b" "event1";
        ///    a -> b 'event1'
        ///    'a' -> 'b' 'event1'
        ///    'a' -> 'b' 'event1 || event2'
        ///    start: a;
        ///    start: -> "a";
        ///    end: "abc" a2 a3 a4;
        ///    end: -> "X" Y 'ZZZ';
        ///    end: -> event1, e2, 'ZZZ';
        ///
        /// The purpose of this parser is to support a simple text format for defining state machines,
        /// not to be a full .gv parser.
        pub fn importText(self: *Self, input: []const u8) !void {

            // Might as well use a state machine to implement importing textual state machines.
            // After an input event, we'll end up in one of these states:
            var fsm = ImportFSM.init();

            var parse_handler = ImportParseHandler.init(self);
            var handlers: [1]*ImportFSM.Handler = .{&parse_handler.handler};
            fsm.setTransitionHandlers(&handlers);

            var line_no: usize = 1;
            var lines = std.mem.splitAny(u8, input, "\n");

            while (lines.next()) |line| {
                if (std.mem.indexOf(u8, line, "->") == null and std.mem.indexOf(u8, line, "start:") == null and std.mem.indexOf(u8, line, "end:") == null) continue;
                var parts = std.mem.tokenizeAny(u8, line, " \t='\";,");
                while (parts.next()) |part| {
                    if (anyStringsEqual(&.{ "->", "[label", "]", "||" }, part)) {
                        continue;
                    } else if (std.mem.eql(u8, part, "start:")) {
                        _ = try fsm.do(.startcolon);
                    } else if (std.mem.eql(u8, part, "end:")) {
                        _ = try fsm.do(.endcolon);
                    } else {
                        parse_handler.current_identifer = part;
                        _ = try fsm.do(.identifier);
                    }
                }
                _ = try fsm.do(.newline);
                line_no += 1;
            }
            _ = try fsm.do(.newline);
        }
    };
}

/// Generates a state machine from a file containing Graphviz or libfsm text
/// including the necessary state/event enum types. An instance is created and returned.
///
/// You can combine this with @embedFile to generate a state machine at
/// compile time from an external text file.
pub fn instanceFromText(comptime input: []const u8) !FsmFromText(input) {
    const FSM = FsmFromText(input);
    var fsm = FSM.init();
    try fsm.importText(input);
    return fsm;
}

/// Generates a state machine from a file containing Graphviz or libfsm text
/// including the necessary state/event enum types. The generated type is returned.
pub fn FsmFromText(comptime input: []const u8) type {
    comptime {
        @setEvalBranchQuota(100_000);

        // Might as well use a state machine to implement importing textual state machines.
        // After an input event, we'll end up in one of these states:
        var fsm = ImportFSM.init();

        var state_enum_field_names: []const []const u8 = &.{};
        var event_enum_field_names: []const []const u8 = &.{};

        var line_no: usize = 1;
        var lines = std.mem.splitAny(u8, input, "\n");
        var start_state_index: usize = 0;
        while (lines.next()) |line| {
            if (std.mem.indexOf(u8, line, "->") == null and std.mem.indexOf(u8, line, "start:") == null and std.mem.indexOf(u8, line, "end:") == null) continue;
            var parts = std.mem.tokenizeAny(u8, line, " \t='\";,");
            part_loop: while (parts.next()) |part| {
                if (anyStringsEqual(&.{ "->", "[label", "]", "||" }, part)) {
                    continue;
                } else if (std.mem.eql(u8, part, "start:")) {
                    _ = fsm.do(.startcolon) catch unreachable;
                } else if (std.mem.eql(u8, part, "end:")) {
                    _ = fsm.do(.endcolon) catch unreachable;
                } else {
                    const current_identifier = part;
                    _ = fsm.do(.identifier) catch unreachable;
                    const to = fsm.currentState();

                    if (to == .startstate or to == .endstates or to == .source or to == .target) {
                        for (state_enum_field_names) |name| {
                            if (std.mem.eql(u8, name, current_identifier)) {
                                continue :part_loop;
                            }
                        }

                        if (to == .startstate) {
                            start_state_index = state_enum_field_names.len;
                        }

                        state_enum_field_names = state_enum_field_names ++ &[_][]const u8{current_identifier ++ ""};
                    } else if (to == .event) {
                        for (event_enum_field_names) |name| {
                            if (std.mem.eql(u8, name, current_identifier)) {
                                continue :part_loop;
                            }
                        }

                        event_enum_field_names = event_enum_field_names ++ &[_][]const u8{current_identifier ++ ""};
                    }
                }
            }
            _ = fsm.do(.newline) catch unreachable;
            line_no += 1;
        }
        _ = fsm.do(.newline) catch unreachable;

        var state_enum_field_values: [state_enum_field_names.len]u16 = undefined;
        for (0..state_enum_field_names.len) |i| state_enum_field_values[i] = i;
        const StateEnum = @Enum(u16, .nonexhaustive, state_enum_field_names, &state_enum_field_values);

        var event_enum_field_values: [event_enum_field_names.len]u16 = undefined;
        for (0..event_enum_field_names.len) |i| event_enum_field_values[i] = i;
        const EventEnum = if (event_enum_field_names.len > 0)
            @Enum(u16, .nonexhaustive, event_enum_field_names, &event_enum_field_values)
        else
            null;

        return StateMachine(StateEnum, EventEnum, @as(StateEnum, @enumFromInt(start_state_index)));
    }
}

/// Helper that returns true if any of the slices are equal to the item
fn anyStringsEqual(slices: []const []const u8, item: []const u8) bool {
    for (slices) |slice| {
        if (std.mem.eql(u8, slice, item)) return true;
    }
    return false;
}

/// Helper type to make it easier to deal with polymorphic types
pub const Interface = struct {
    /// We establish the convention that the implementation type has the interface as the
    /// first field, allowing a slightly less verbose interface idiom. This will not compile
    /// if there's a mismatch. When this convention doesn't work, use @fieldParentPtr directly.
    pub fn downcast(comptime Implementer: type, interface_ref: anytype) *Implementer {
        const field_name = comptime std.meta.fieldNames(Implementer).*[0];
        return @alignCast(@fieldParentPtr(field_name, interface_ref));
    }

    /// Instantiates an interface type and populates its function pointers to point to
    /// proper functions in the given implementer type.
    pub fn make(comptime InterfaceType: type, comptime Implementer: type) InterfaceType {
        var instance: InterfaceType = undefined;
        inline for (std.meta.fields(InterfaceType)) |f| {
            if (comptime std.meta.hasFn(Implementer, f.name)) {
                @field(instance, f.name) = @field(Implementer, f.name);
            }
        }
        return instance;
    }
};

/// An enum generator useful for testing, as well as state machines with sequenced states or events.
/// If `prefix` is an empty string, use @"0", @"1", etc to refer to the enum field.
pub fn GenerateConsecutiveEnum(comptime prefix: []const u8, comptime element_count: usize) type {
    @setEvalBranchQuota(100_000);
    const TagType = std.math.IntFittingRange(0, element_count);
    var field_names: []const []const u8 = &.{};
    var field_values: [element_count]TagType = undefined;

    for (0..element_count) |i| {
        var tmp_buf: [128]u8 = undefined;
        const name = try std.fmt.bufPrint(&tmp_buf, "{s}{d}", .{ prefix, i });
        field_names = field_names ++ &[_][]const u8{name};
        field_values[i] = i;
    }

    return @Enum(TagType, .nonexhaustive, field_names, &field_values);
}

const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
const expectEqualSlices = std.testing.expectEqualSlices;
const expectError = std.testing.expectError;

// Demonstrates that triggering a single "click" event can perpetually cycle through intensity states.
test "moore machine: three-level intensity light" {
    // A state machine type is defined using state enums and, optionally, event enums.
    // An event takes the state machine from one state to another, but you can also switch to
    // other states without using events.
    //
    // State and event enums can be explicit enum types, comptime generated enums, or
    // anonymous enums like in this example.
    //
    // If you don't want to use events, simply pass null to the second argument.
    // We also define what state is the initial one, in this case .off
    var fsm = StateMachine(enum { off, dim, medium, bright }, enum { click }, .off).init();

    try fsm.addEventAndTransition(.click, .off, .dim);
    try fsm.addEventAndTransition(.click, .dim, .medium);
    try fsm.addEventAndTransition(.click, .medium, .bright);
    try fsm.addEventAndTransition(.click, .bright, .off);

    // Do a full cycle of off -> dim -> medium -> bright -> off

    try expect(fsm.isCurrently(.off));

    _ = try fsm.do(.click);
    try expect(fsm.isCurrently(.dim));

    _ = try fsm.do(.click);
    try expect(fsm.isCurrently(.medium));

    _ = try fsm.do(.click);
    try expect(fsm.isCurrently(.bright));

    _ = try fsm.do(.click);
    try expect(fsm.isCurrently(.off));

    // Make sure we're in a good state
    try expect(fsm.canTransitionTo(.dim));
    try expect(!fsm.canTransitionTo(.medium));
    try expect(!fsm.canTransitionTo(.bright));
    try expect(!fsm.canTransitionTo(.off));
}

test "minimal without event" {
    const State = enum { on, off };
    var fsm = StateMachine(State, null, .off).init();
    try fsm.addTransition(.on, .off);
    try fsm.addTransition(.off, .on);

    try fsm.transitionTo(.on);
    try expectEqual(fsm.currentState(), .on);
}

test "comptime minimal without event" {
    comptime {
        const State = enum { on, off };
        var fsm = StateMachine(State, null, .off).init();
        try fsm.addTransition(.on, .off);
        try fsm.addTransition(.off, .on);

        try fsm.transitionTo(.on);
        try expectEqual(fsm.currentState(), .on);
    }
}

test "minimal with event" {
    const State = enum { on, off };
    const Event = enum { click };
    var fsm = StateMachine(State, Event, .off).init();
    try fsm.addTransition(.on, .off);
    try fsm.addTransition(.off, .on);
    try fsm.addEvent(.click, .on, .off);
    try fsm.addEvent(.click, .off, .on);

    // Transition manually
    try fsm.transitionTo(.on);
    try expectEqual(fsm.currentState(), .on);

    // Transition through an event
    _ = try fsm.do(.click);
    try expectEqual(fsm.currentState(), .off);
}

test "minimal with event defined using a table" {
    const State = enum { on, off };
    const Event = enum { click };
    const definition = [_]Transition(State, Event){
        .{ .event = .click, .from = .on, .to = .off },
        .{ .event = .click, .from = .off, .to = .on },
    };
    var fsm = StateMachineFromTable(State, Event, &definition, .off, &.{}).init();

    // Transition manually
    try fsm.transitionTo(.on);
    try expectEqual(fsm.currentState(), .on);

    // Transition through an event
    _ = try fsm.do(.click);
    try expectEqual(fsm.currentState(), .off);
}

test "generate state enum" {
    // When you have a simple sequence of states, such as S0, S1, ... then you
    // can have generate these for you, rather than manually creating
    // the enum. The same applies to events; see next test.
    // You can use any prefix; here we use S
    const State = GenerateConsecutiveEnum("S", 100);
    var fsm = StateMachine(State, null, .S0).init();
    try fsm.addTransition(.S0, .S1);
    try fsm.transitionTo(.S1);
    try expectEqual(fsm.currentState(), .S1);
}

test "generate state enum and event enum" {
    // Generate state enums, S0, S1, ...
    const State = GenerateConsecutiveEnum("S", 100);

    // We also generate event enums, E0, E1, ...
    const Event = GenerateConsecutiveEnum("E", 100);

    // Initialize the state machine in state S0
    var fsm = StateMachine(State, Event, .S0).init();

    // When event E0 happens when in state S0, go to state S1
    try fsm.addEventAndTransition(.E0, .S0, .S1);
    _ = try fsm.do(.E0);

    // Make sure we're in the correct state after the event fired
    try expectEqual(fsm.currentState(), .S1);
}

test "check state" {
    const State = enum { start, stop };
    const FSM = StateMachine(State, null, .start);

    var fsm = FSM.init();
    try fsm.addTransition(.start, .stop);
    try fsm.addFinalState(.stop);

    try expect(fsm.isFinalState(.stop));
    try expect(fsm.isInStartState());
    try expect(fsm.isCurrently(.start));
    try expect(!fsm.isInFinalState());

    try fsm.transitionTo(.stop);
    try expect(fsm.isCurrently(.stop));
    try expectEqual(fsm.currentState(), .stop);
    try expect(fsm.isInFinalState());
}

// Implements https://en.wikipedia.org/wiki/Deterministic_finite_automaton#Example
// Comptime state machines finally works in stage2, see https://github.com/ziglang/zig/issues/10694
test "comptime dfa: binary alphabet, require even number of zeros in input" {
    comptime {
        @setEvalBranchQuota(10_000);

        // Note that both "start: S1;" and "start: -> S1;" syntaxes work, same with end:
        const input =
            \\ S1 -> S2 [label = "0"];
            \\ S2 -> S1 [label = "0"];
            \\ S1 -> S1 [label = "1"];
            \\ S2 -> S2 [label = "1"];
            \\ start: S1;
            \\ end: S1;
        ;

        const State = enum { S1, S2 };
        const Bit = enum { @"0", @"1" };
        var fsm = StateMachine(State, Bit, .S1).init();
        try fsm.importText(input);

        // With valid input, we wil end up in the final state
        const valid_input: []const Bit = &.{ .@"0", .@"0", .@"1", .@"1" };
        for (valid_input) |bit| _ = try fsm.do(bit);
        try expect(fsm.isInFinalState());

        // With invalid input, we will not end up in the final state
        const invalid_input: []const Bit = &.{ .@"0", .@"0", .@"0", .@"1" };
        for (invalid_input) |bit| _ = try fsm.do(bit);
        try expect(!fsm.isInFinalState());
    }
}

// Simple CSV parser based on the state model in https://ppolv.wordpress.com/2008/02/25/parsing-csv-in-erlang
// The main idea is that we classify incoming characters as InputEvent's. When a character arrives, we
// simply trigger the event. If the input is well-formed, we automatically move to the appropriate state.
// To actually extract CSV fields, we use a transition handler to keep track of where field slices starts and ends.
// If the input is incorrect we have detailed information about where it happens, and why based on states and events.
test "csv parser" {
    const State = enum { field_start, unquoted, quoted, post_quoted, done };
    const InputEvent = enum { char, quote, whitespace, comma, newline, anything_not_quote, eof };

    // Intentionally badly formatted csv to exercise corner cases
    const csv_input =
        \\"first",second,"third",4
        \\  "more", right, here, 5
        \\  1,,b,c
    ;

    const FSM = StateMachine(State, InputEvent, .field_start);

    const Parser = struct {
        handler: FSM.Handler,
        fsm: *FSM,
        csv: []const u8,
        cur_field_start: usize,
        cur_index: usize,
        line: usize = 0,
        col: usize = 0,

        const expected_parse_result: [3][4][]const u8 = .{
            .{ "\"first\"", "second", "\"third\"", "4" },
            .{ "\"more\"", "right", "here", "5" },
            .{ "1", "", "b", "c" },
        };

        pub fn parse(fsm: *FSM, csv: []const u8) !void {
            var instance: @This() = .{
                .handler = Interface.make(FSM.Handler, @This()),
                .fsm = fsm,
                .csv = csv,
                .cur_field_start = 0,
                .cur_index = 0,
                .line = 0,
                .col = 0,
            };
            instance.fsm.setTransitionHandlers(&.{&instance.handler});
            try instance.read();
        }

        /// Feeds the input stream through the state machine
        fn read(self: *@This()) !void {
            var reader = std.Io.Reader.fixed(self.csv);
            while (true) : (self.cur_index += 1) {
                const input = reader.takeByte() catch {
                    // An example of how to handle parsing errors
                    _ = self.fsm.do(.eof) catch {
                        std.debug.print("Unexpected end of stream\n", .{});
                    };
                    return;
                };

                // The order of checks is important to classify input correctly
                if (self.fsm.isCurrently(.quoted) and input != '"') {
                    _ = try self.fsm.do(.anything_not_quote);
                } else if (input == '\n') {
                    _ = try self.fsm.do(.newline);
                } else if (std.ascii.isWhitespace(input)) {
                    _ = try self.fsm.do(.whitespace);
                } else if (input == ',') {
                    _ = try self.fsm.do(.comma);
                } else if (input == '"') {
                    _ = try self.fsm.do(.quote);
                } else if (std.ascii.isPrint(input)) {
                    _ = try self.fsm.do(.char);
                }
            }
        }

        /// We use state transitions to extract CSV field slices, and we're not using any extra memory.
        /// Note that the transition handler must be public.
        pub fn onTransition(handler: *FSM.Handler, event: ?InputEvent, from: State, to: State) HandlerResult {
            const self = Interface.downcast(@This(), handler);

            const fields_per_row = 4;

            // Start of a field
            if (from == .field_start) {
                self.cur_field_start = self.cur_index;
            }

            // End of a field
            if (to != from and (from == .unquoted or from == .post_quoted)) {
                const found_field = std.mem.trim(u8, self.csv[self.cur_field_start..self.cur_index], " ");

                std.testing.expectEqualSlices(u8, found_field, expected_parse_result[self.line][self.col]) catch unreachable;
                self.col = (self.col + 1) % fields_per_row;
            }

            // Empty field
            if (event.? == .comma and self.cur_field_start == self.cur_index) {
                self.col = (self.col + 1) % fields_per_row;
            }

            if (event.? == .newline) {
                self.line += 1;
            }

            return HandlerResult.Continue;
        }
    };

    var fsm = FSM.init();
    try fsm.addEventAndTransition(.whitespace, .field_start, .field_start);
    try fsm.addEventAndTransition(.whitespace, .unquoted, .unquoted);
    try fsm.addEventAndTransition(.whitespace, .post_quoted, .post_quoted);
    try fsm.addEventAndTransition(.char, .field_start, .unquoted);
    try fsm.addEventAndTransition(.char, .unquoted, .unquoted);
    try fsm.addEventAndTransition(.quote, .field_start, .quoted);
    try fsm.addEventAndTransition(.quote, .quoted, .post_quoted);
    try fsm.addEventAndTransition(.anything_not_quote, .quoted, .quoted);
    try fsm.addEventAndTransition(.comma, .post_quoted, .field_start);
    try fsm.addEventAndTransition(.comma, .unquoted, .field_start);
    try fsm.addEventAndTransition(.comma, .field_start, .field_start);
    try fsm.addEventAndTransition(.newline, .post_quoted, .field_start);
    try fsm.addEventAndTransition(.newline, .unquoted, .field_start);
    try fsm.addEventAndTransition(.eof, .unquoted, .done);
    try fsm.addEventAndTransition(.eof, .quoted, .done);
    try fsm.addFinalState(.done);

    try Parser.parse(&fsm, csv_input);
    try expect(fsm.isInFinalState());
}

// An alternative to the "csv parser" test using do(...) return values rather than transition callbacks
test "csv parser, without handler callback" {
    const State = enum { field_start, unquoted, quoted, post_quoted, done };
    const InputEvent = enum { char, quote, whitespace, comma, newline, anything_not_quote, eof };

    // Intentionally badly formatted csv to exercise corner cases
    const csv_input =
        \\"first",second,"third",4
        \\  "more", right, here, 5
        \\  1,,b,c
    ;

    const FSM = StateMachine(State, InputEvent, .field_start);

    const Parser = struct {
        fsm: *FSM,
        csv: []const u8,
        cur_field_start: usize,
        cur_index: usize,
        line: usize = 0,
        col: usize = 0,

        const expected_parse_result: [3][4][]const u8 = .{
            .{ "\"first\"", "second", "\"third\"", "4" },
            .{ "\"more\"", "right", "here", "5" },
            .{ "1", "", "b", "c" },
        };

        pub fn parse(fsm: *FSM, csv: []const u8) !void {
            var instance: @This() = .{
                .fsm = fsm,
                .csv = csv,
                .cur_field_start = 0,
                .cur_index = 0,
                .line = 0,
                .col = 0,
            };
            try instance.read();
        }

        /// Feeds the input stream through the state machine
        fn read(self: *@This()) !void {
            var reader = std.Io.Reader.fixed(self.csv);
            while (true) : (self.cur_index += 1) {
                const input = reader.takeByte() catch {
                    // An example of how to handle parsing errors
                    _ = self.fsm.do(.eof) catch {
                        std.debug.print("Unexpected end of stream\n", .{});
                    };
                    return;
                };

                // Holds from/to/event if a transition is triggered
                var maybe_transition: ?Transition(State, InputEvent) = null;

                // The order of checks is important to classify input correctly
                if (self.fsm.isCurrently(.quoted) and input != '"') {
                    maybe_transition = try self.fsm.do(.anything_not_quote);
                } else if (input == '\n') {
                    maybe_transition = try self.fsm.do(.newline);
                } else if (std.ascii.isWhitespace(input)) {
                    maybe_transition = try self.fsm.do(.whitespace);
                } else if (input == ',') {
                    maybe_transition = try self.fsm.do(.comma);
                } else if (input == '"') {
                    maybe_transition = try self.fsm.do(.quote);
                } else if (std.ascii.isPrint(input)) {
                    maybe_transition = try self.fsm.do(.char);
                }

                if (maybe_transition) |transition| {
                    const fields_per_row = 4;

                    // Start of a field
                    if (transition.from == .field_start) {
                        self.cur_field_start = self.cur_index;
                    }

                    // End of a field
                    if (transition.to != transition.from and (transition.from == .unquoted or transition.from == .post_quoted)) {
                        const found_field = std.mem.trim(u8, self.csv[self.cur_field_start..self.cur_index], " ");

                        std.testing.expectEqualSlices(u8, found_field, expected_parse_result[self.line][self.col]) catch unreachable;
                        self.col = (self.col + 1) % fields_per_row;
                    }

                    // Empty field
                    if (transition.event.? == .comma and self.cur_field_start == self.cur_index) {
                        self.col = (self.col + 1) % fields_per_row;
                    }

                    if (transition.event.? == .newline) {
                        self.line += 1;
                    }
                }
            }
        }
    };

    var fsm = FSM.init();
    try fsm.addEventAndTransition(.whitespace, .field_start, .field_start);
    try fsm.addEventAndTransition(.whitespace, .unquoted, .unquoted);
    try fsm.addEventAndTransition(.whitespace, .post_quoted, .post_quoted);
    try fsm.addEventAndTransition(.char, .field_start, .unquoted);
    try fsm.addEventAndTransition(.char, .unquoted, .unquoted);
    try fsm.addEventAndTransition(.quote, .field_start, .quoted);
    try fsm.addEventAndTransition(.quote, .quoted, .post_quoted);
    try fsm.addEventAndTransition(.anything_not_quote, .quoted, .quoted);
    try fsm.addEventAndTransition(.comma, .post_quoted, .field_start);
    try fsm.addEventAndTransition(.comma, .unquoted, .field_start);
    try fsm.addEventAndTransition(.comma, .field_start, .field_start);
    try fsm.addEventAndTransition(.newline, .post_quoted, .field_start);
    try fsm.addEventAndTransition(.newline, .unquoted, .field_start);
    try fsm.addEventAndTransition(.eof, .unquoted, .done);
    try fsm.addEventAndTransition(.eof, .quoted, .done);
    try fsm.addFinalState(.done);

    try Parser.parse(&fsm, csv_input);
    try expect(fsm.isInFinalState());
}

test "handler that cancels" {
    const State = enum { on, off };
    const Event = enum { click };
    const FSM = StateMachine(State, Event, .off);
    var fsm = FSM.init();

    // Demonstrates how to manage extra state (in this case a simple counter) while reacting
    // to transitions. Once the counter reaches 3, it cancels any further transitions. Real-world
    // handlers typically check from/to states and perhaps even which event (if any) caused the
    // transition.
    const CountingHandler = struct {
        // The handler must be the first field
        handler: FSM.Handler,
        counter: usize,

        pub fn init() @This() {
            return .{
                .handler = Interface.make(FSM.Handler, @This()),
                .counter = 0,
            };
        }

        pub fn onTransition(handler: *FSM.Handler, event: ?Event, from: State, to: State) HandlerResult {
            _ = &.{ from, to, event };
            const self = Interface.downcast(@This(), handler);
            self.counter += 1;
            return if (self.counter < 3) HandlerResult.Continue else HandlerResult.Cancel;
        }
    };

    var countingHandler = CountingHandler.init();
    fsm.setTransitionHandlers(&.{&countingHandler.handler});
    try fsm.addEventAndTransition(.click, .on, .off);
    try fsm.addEventAndTransition(.click, .off, .on);

    _ = try fsm.do(.click);
    _ = try fsm.do(.click);

    // Third time will fail
    try expectError(StateError.Canceled, fsm.do(.click));
}

test "import: graphviz" {
    const input =
        \\digraph parser_example {
        \\    rankdir=LR;
        \\    node [shape = doublecircle fixedsize = false]; 3  4  8 ;
        \\    node [shape = circle fixedsize = false];
        \\    start: -> 0;
        \\    0 -> 2 [label = "SS(B)"];
        \\    0 -> 1 [label = "SS(S)"];
        \\    1 -> 3 [label = "S($end)"];
        \\    2 -> 6 [label = "SS(b)"];
        \\    2 -> 5 [label = "SS(a)"];
        \\    2 -> 4 [label = "S(A)"];
        \\    5 -> 7 [label = "S(b)"];
        \\    5 -> 5 [label = "S(a)"];
        \\    6 -> 6 [label = "S(b)"];
        \\    6 -> 5 [label = "S(a)"];
        \\    7 -> 8 [label = "S(b)"];
        \\    7 -> 5 [label = "S(a)"];
        \\    8 -> 6 [label = "S(b)"];
        \\    8 -> 5 [label = "S(a) || extra"];
        \\}
    ;

    const State = enum { @"0", @"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8" };
    const Event = enum { @"SS(B)", @"SS(S)", @"S($end)", @"SS(b)", @"SS(a)", @"S(A)", @"S(b)", @"S(a)", extra };

    var fsm = StateMachine(State, Event, .@"0").init();
    try fsm.importText(input);

    try fsm.apply(.{ .event = .@"SS(B)" });
    try expectEqual(fsm.currentState(), .@"2");
    try fsm.transitionTo(.@"6");
    try expectEqual(fsm.currentState(), .@"6");
    // Self-transition
    _ = try fsm.do(.@"S(b)");
    try expectEqual(fsm.currentState(), .@"6");
}

test "import: libfsm text" {
    const input =
        \\ 1 -> 2 "a";
        \\ 2 -> 3 "a";
        \\ 3 -> 4 "b";
        \\ 4 -> 5 "b";
        \\ 5 -> 1 'c';
        \\ "1" -> "3" 'c';
        \\ 3 -> 5 'c';
        \\ start: 1;
        \\ end: 3, 4, 5;
    ;

    const State = enum { @"0", @"1", @"2", @"3", @"4", @"5" };
    const Event = enum { a, b, c };

    var fsm = StateMachine(State, Event, .@"0").init();
    try fsm.importText(input);

    try expectEqual(fsm.currentState(), .@"1");
    try fsm.transitionTo(.@"2");
    try expectEqual(fsm.currentState(), .@"2");
    _ = try fsm.do(.a);
    try expectEqual(fsm.currentState(), .@"3");
    try expect(fsm.isInFinalState());
}

// Implements the state diagram example from the Graphviz docs
test "export: graphviz export of finite automaton sample" {
    const State = enum { @"0", @"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8" };
    const Event = enum { @"SS(B)", @"SS(S)", @"S($end)", @"SS(b)", @"SS(a)", @"S(A)", @"S(b)", @"S(a)", extra };

    var fsm = StateMachine(State, Event, .@"0").init();
    try fsm.addTransition(State.@"0", State.@"2");
    try fsm.addTransition(State.@"0", State.@"1");
    try fsm.addTransition(State.@"1", State.@"3");
    try fsm.addTransition(State.@"2", State.@"6");
    try fsm.addTransition(State.@"2", State.@"5");
    try fsm.addTransition(State.@"2", State.@"4");
    try fsm.addTransition(State.@"5", State.@"7");
    try fsm.addTransition(State.@"5", State.@"5");
    try fsm.addTransition(State.@"6", State.@"6");
    try fsm.addTransition(State.@"6", State.@"5");
    try fsm.addTransition(State.@"7", State.@"8");
    try fsm.addTransition(State.@"7", State.@"5");
    try fsm.addTransition(State.@"8", State.@"6");
    try fsm.addTransition(State.@"8", State.@"5");

    try fsm.addFinalState(State.@"3");
    try fsm.addFinalState(State.@"4");
    try fsm.addFinalState(State.@"8");

    try fsm.addEvent(.@"SS(B)", .@"0", .@"2");
    try fsm.addEvent(.@"SS(S)", .@"0", .@"1");
    try fsm.addEvent(.@"S($end)", .@"1", .@"3");
    try fsm.addEvent(.@"SS(b)", .@"2", .@"6");
    try fsm.addEvent(.@"SS(a)", .@"2", .@"5");
    try fsm.addEvent(.@"S(A)", .@"2", .@"4");
    try fsm.addEvent(.@"S(b)", .@"5", .@"7");
    try fsm.addEvent(.@"S(a)", .@"5", .@"5");
    try fsm.addEvent(.@"S(b)", .@"6", .@"6");
    try fsm.addEvent(.@"S(a)", .@"6", .@"5");
    try fsm.addEvent(.@"S(b)", .@"7", .@"8");
    try fsm.addEvent(.@"S(a)", .@"7", .@"5");
    try fsm.addEvent(.@"S(b)", .@"8", .@"6");
    try fsm.addEvent(.@"S(a)", .@"8", .@"5");
    // This demonstrates that multiple events on the same transition are concatenated with ||
    try fsm.addEvent(.extra, .@"8", .@"5");

    const outbuf = try std.testing.allocator.alloc(u8, 1024);
    defer std.testing.allocator.free(outbuf);
    var writer = std.Io.Writer.fixed(outbuf);

    try fsm.exportGraphviz("parser_example", &writer, .{});

    const target =
        \\digraph parser_example {
        \\    rankdir=LR;
        \\    node [shape = doublecircle fixedsize = false]; "3"  "4"  "8" ;
        \\    node [shape = circle fixedsize = false];
        \\    "0" -> "1" [label = "SS(S)"];
        \\    "0" -> "2" [label = "SS(B)"];
        \\    "1" -> "3" [label = "S($end)"];
        \\    "2" -> "4" [label = "S(A)"];
        \\    "2" -> "5" [label = "SS(a)"];
        \\    "2" -> "6" [label = "SS(b)"];
        \\    "5" -> "5" [label = "S(a)"];
        \\    "5" -> "7" [label = "S(b)"];
        \\    "6" -> "5" [label = "S(a)"];
        \\    "6" -> "6" [label = "S(b)"];
        \\    "7" -> "5" [label = "S(a)"];
        \\    "7" -> "8" [label = "S(b)"];
        \\    "8" -> "5" [label = "S(a) || extra"];
        \\    "8" -> "6" [label = "S(b)"];
        \\}
        \\
    ;

    try expectEqualSlices(u8, target[0..], writer.buffered());
}

test "finite state automaton for accepting a 25p car park charge (from Computers Without Memory - Computerphile)" {
    const state_machine =
        \\ sum0  ->  sum5   p5
        \\ sum0  ->  sum10  p10
        \\ sum0  ->  sum20  p20
        \\ sum5  ->  sum10  p5
        \\ sum5  ->  sum15  p10
        \\ sum5  ->  sum25  p20
        \\ sum10 ->  sum15  p5
        \\ sum10 ->  sum20  p10
        \\ sum15 ->  sum20  p5
        \\ sum15 ->  sum25  p10
        \\ sum20 ->  sum25  p5
        \\ start: sum0
        \\ end: sum25
    ;

    const Sum = enum { sum0, sum5, sum10, sum15, sum20, sum25 };
    const Coin = enum { p5, p10, p20 };
    var fsm = StateMachine(Sum, Coin, .sum0).init();
    try fsm.importText(state_machine);

    // Add 5p, 10p and 10p coins
    _ = try fsm.do(.p5);
    _ = try fsm.do(.p10);
    _ = try fsm.do(.p10);

    // Car park charge reached
    try expect(fsm.isInFinalState());

    // Verify that we're unable to accept more coins
    try expectError(StateError.Invalid, fsm.do(.p10));

    // Restart the state machine and try a different combination to reach 25p
    fsm.restart();
    _ = try fsm.do(.p20);
    _ = try fsm.do(.p5);
    try expect(fsm.isInFinalState());

    // Same as restart(), but makes sure we're currently in the start state or a final state
    try fsm.safeRestart();
    _ = try fsm.do(.p10);
    try expectError(StateError.Invalid, fsm.safeRestart());
    _ = try fsm.do(.p5);
    _ = try fsm.do(.p5);
    _ = try fsm.do(.p5);
    try expect(fsm.isInFinalState());
}

test "iterate next valid states" {
    const state_machine =
        \\ sum0  ->  sum5   p5
        \\ sum0  ->  sum10  p10
        \\ sum0  ->  sum20  p20
        \\ sum5  ->  sum10  p5
        \\ sum5  ->  sum15  p10
        \\ sum5  ->  sum25  p20
        \\ sum10 ->  sum15  p5
        \\ sum10 ->  sum20  p10
        \\ sum15 ->  sum20  p5
        \\ sum15 ->  sum25  p10
        \\ sum20 ->  sum25  p5
        \\ start: sum0
        \\ end: sum25
    ;

    const Sum = enum { sum0, sum5, sum10, sum15, sum20, sum25 };
    const Coin = enum { p5, p10, p20 };
    var fsm = StateMachine(Sum, Coin, .sum0).init();
    try fsm.importText(state_machine);

    var next_valid_iterator = fsm.validNextStatesIterator();
    try expectEqual(Sum.sum5, next_valid_iterator.next().?);
    try expectEqual(Sum.sum10, next_valid_iterator.next().?);
    try expectEqual(Sum.sum20, next_valid_iterator.next().?);
    try expectEqual(next_valid_iterator.next(), null);
}

// You don't actually need to define the state and event enums manually, but
// rather generate them at compile-time from a string or embedded text file.
//
// A downside is that editors are unlikely to autocomplete generated types
test "iterate next valid states, using state machine with generated enums" {
    const state_machine =
        \\ sum0  ->  sum5   p5
        \\ sum0  ->  sum10  p10
        \\ sum0  ->  sum20  p20
        \\ sum5  ->  sum10  p5
        \\ sum5  ->  sum15  p10
        \\ sum5  ->  sum25  p20
        \\ sum10 ->  sum15  p5
        \\ sum10 ->  sum20  p10
        \\ sum15 ->  sum20  p5
        \\ sum15 ->  sum25  p10
        \\ sum20 ->  sum25  p5
        \\ start: sum0
        \\ end: sum25
    ;

    var fsm = try instanceFromText(state_machine);
    const State = @TypeOf(fsm).StateEnum;
    _ = @TypeOf(fsm).EventEnum;

    var next_valid_iterator = fsm.validNextStatesIterator();
    try expectEqual(State.sum5, next_valid_iterator.next().?);
    try expectEqual(State.sum10, next_valid_iterator.next().?);
    try expectEqual(State.sum20, next_valid_iterator.next().?);
    try expectEqual(next_valid_iterator.next(), null);
}

// A simple push-down automaton to reliably return from jumping
// to the original standing or crouching state. Double-jumps
// leads to flying.
///
// In this example, we have a simple do/undo API. In a real-world app,
// a pushdown-automaton can obviously have any API suitable for
// the situation.
const GameState = struct {
    fsm: FSM,
    stack: std.ArrayList(FSM.StateEnum),

    const FSM = StateMachine(
        enum { standing, crouching, jumping, flying },
        enum { walk, jump },
        .standing,
    );

    pub fn init() !GameState {
        var state = GameState{
            .fsm = FSM.init(),
            .stack = std.ArrayList(FSM.StateEnum).empty,
        };

        // Event-triggered transitions
        try state.fsm.addEventAndTransition(.jump, .standing, .jumping);
        try state.fsm.addEventAndTransition(.jump, .crouching, .jumping);
        try state.fsm.addEventAndTransition(.jump, .jumping, .flying);

        // The valid undo-transitions for the push-down automaton
        try state.fsm.addTransition(.flying, .jumping);
        try state.fsm.addTransition(.jumping, .standing);
        try state.fsm.addTransition(.jumping, .crouching);
        return state;
    }

    pub fn deinit(self: *GameState) void {
        self.stack.deinit(std.testing.allocator);
    }

    // Trigger an undoable event
    pub fn do(self: *GameState, event: FSM.EventEnum) !Transition(FSM.StateEnum, FSM.EventEnum) {
        try self.stack.append(std.testing.allocator, self.fsm.currentState());
        return try self.fsm.do(event);
    }

    // Pops from the state stack and transitions to it. Returns true if stack had at least one state.
    pub fn undo(self: *GameState) !bool {
        if (self.stack.pop()) |state| {
            try self.fsm.transitionTo(state);
            return true;
        } else return false;
    }
};

test "push-down automaton game: standing -> jumping -> standing" {
    var state = try GameState.init();
    defer state.deinit();

    // We can jump whether we're standing or crouching
    _ = try state.do(.jump);
    std.debug.assert(state.fsm.isCurrently(.jumping));

    // Go back to previous state from jumping
    _ = try state.undo();
    std.debug.assert(state.fsm.isCurrently(.standing));
}

test "push-down automaton game: crouching -> jumping -> flying -> jumping -> croaching" {
    var state = try GameState.init();
    defer state.deinit();

    // Next sequence is: crouching -> jumping -> flying -> jumping -> croaching
    state.fsm.setStartState(.crouching);

    // Double jump to start flying
    _ = try state.do(.jump);
    _ = try state.do(.jump);
    std.debug.assert(state.fsm.isCurrently(.flying));

    // Go back to previous state from jumping
    _ = try state.undo();
    std.debug.assert(state.fsm.isCurrently(.jumping));
    _ = try state.undo();
    std.debug.assert(state.fsm.isCurrently(.crouching));
}

test {
    std.testing.refAllDecls(@This());
}
