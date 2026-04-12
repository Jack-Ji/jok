//! Lua 5.5 scripting support
//!
//! Features:
//! - Expose struct and it's methods to lua (ignore private names prefixed with _)
//! - Load/Execute lua code
//! - Call lua function and get result

const std = @import("std");
const builtin = @import("builtin");
const log = std.log.scoped(.jok);
const zlua = @import("zlua");

pub const BoundType = struct {
    Type: type,
    name: [:0]const u8,
    ignore_fields: []const [:0]const u8 = &[_][:0]const u8{},
    mixin: ?type = null,
};

pub const Lua = struct {
    vm: *zlua.Lua,

    pub fn init(allocator: std.mem.Allocator) !Lua {
        const vm = try zlua.Lua.init(allocator);
        vm.openLibs();
        return .{ .vm = vm };
    }

    pub fn deinit(self: Lua) void {
        self.vm.deinit();
    }

    pub fn registerTypes(self: Lua, comptime Types: []const BoundType) !void {
        const registry = Registry(Types);
        try registry.bindTypes(self.vm);
    }

    pub fn runString(self: Lua, lua_string: [:0]const u8) !void {
        self.vm.loadString(lua_string) catch |err| {
            log.err("Lua: {s}", .{try self.vm.toString(-1)});
            self.vm.pop(1);
            return err;
        };

        // Execute the new line
        self.vm.protectedCall(.{ .args = 0, .results = 0 }) catch |err| {
            log.err("Lua: {s}", .{try self.vm.toString(-1)});
            self.vm.pop(1);
            return err;
        };
    }

    pub fn callFunction(self: Lua, ReturnType: type, func_name: [:0]const u8, args: anytype) !ReturnType {
        _ = self.vm.getGlobal(func_name) catch {
            log.err("Lua: couldn't find function `{s}'", .{func_name});
            self.vm.pop(1);
            return error.NotExist;
        };

        if (!self.vm.isFunction(-1)) {
            self.vm.pop(1);
            return error.NotFunction;
        }

        // Check arguments
        const type_info = @typeInfo(@TypeOf(args));
        if (type_info != .@"struct" or !type_info.@"struct".is_tuple) @compileError("Lua: invalid args");
        if (builtin.mode == .Debug) {
            const arity = try self.getFunctionArity(func_name);
            if (arity.nparams != args.len) return error.InvalidArgs;
        }

        inline for (args) |v| try self.vm.pushAny(v);
        if (ReturnType == void) {
            self.vm.protectedCall(.{ .args = args.len, .results = 0 }) catch |err| {
                log.err("Lua: error calling func {s}: {!s} {any}", .{ func_name, self.vm.toString(-1), err });
                self.vm.pop(1);
                return err;
            };
        } else {
            self.vm.protectedCall(.{ .args = args.len, .results = 1 }) catch |err| {
                log.err("Lua: error calling func {s}: {!s} {any}", .{ func_name, self.vm.toString(-1), err });
                self.vm.pop(1);
                return err;
            };
            defer self.vm.pop(1);
            return try self.vm.toAny(ReturnType, -1);
        }
    }

    pub fn set(self: Lua, name: [:0]const u8, value: anytype) !void {
        return try self.vm.set(name, value);
    }

    pub fn get(self: Lua, ReturnType: type, name: [:0]const u8) !ReturnType {
        _ = self.vm.getGlobal(name) catch {
            log.err("Lua: couldn't find `{s}'", .{name});
            self.vm.pop(1);
            return error.NotExist;
        };

        defer self.vm.pop(1);
        return try self.vm.toAny(ReturnType, -1);
    }

    fn getFunctionArity(self: Lua, func_name: [:0]const u8) !struct { nparams: u32, isvararg: bool } {
        // 1. Get the function by name
        _ = try self.vm.getGlobal(func_name);
        defer self.vm.pop(1);

        if (!self.vm.isFunction(-1)) {
            return error.NotAFunction;
        }

        // 2. Call debug.getinfo(func, "u")
        _ = try self.vm.getGlobal("debug");
        defer self.vm.pop(1);
        _ = self.vm.getField(-1, "getinfo");
        self.vm.pushValue(-3); // push the function (argument to getinfo)
        _ = self.vm.pushString("u"); // what = "u"
        self.vm.call(.{ .args = 2, .results = 1 }); // debug.getinfo(func, "u") → 1 result (table)

        // 3. Extract nparams and isvararg from the table
        _ = self.vm.getField(-1, "nparams");
        const nparams = self.vm.toInteger(-1) catch 0;
        self.vm.pop(1);

        _ = self.vm.getField(-1, "isvararg");
        const isvararg = self.vm.toBoolean(-1);
        self.vm.pop(1);

        self.vm.pop(1); // pop the info table

        return .{ .nparams = @intCast(nparams), .isvararg = isvararg };
    }
};

// Stolen from https://github.com/Interrupt/delve-framework, thanks Chad!
fn Registry(comptime entries: []const BoundType) type {
    return struct {
        const registry = entries;

        // Allow us to box up our bound types
        fn BoxType(comptime T: type, comptime in_bound_type: BoundType) type {
            return struct {
                const Self = @This();
                const bound_type: BoundType = in_bound_type;
                const ptr_metatable_name = in_bound_type.name ++ "_ptr";

                pointer: *T,

                fn checkBoxedUserdata(luaState: *zlua.Lua, lua_idx: i32) *T {
                    // First check if this is a boxed pointer, unbox and return if so
                    if (luaState.testUserdata(Self, lua_idx, ptr_metatable_name)) |boxed_ptr| {
                        return boxed_ptr.*.pointer;
                    } else |_| {}

                    // Not a boxed pointer, should be already unboxed
                    return luaState.checkUserdata(T, lua_idx, in_bound_type.name);
                }
            };
        }

        fn getMetaTableName(comptime T: type) [:0]const u8 {
            inline for (registry) |entry| {
                if (entry.Type == T) return entry.name;
            }
            log.warn("Type not found in Lua registry! " ++ @typeName(T), .{});
            return "_notFound";
        }

        fn isRegistered(comptime T: type) bool {
            inline for (registry) |entry| {
                if (entry.Type == T) return true;
            }
            return false;
        }

        fn getBoundType(comptime T: type) ?BoundType {
            inline for (registry) |entry| {
                if (entry.Type == T) return entry;
            }
            return null;
        }

        fn hasDestroyFunc(comptime T: type) bool {
            return std.meta.hasFn(T, "destroy");
        }

        fn hasIndexFunc(comptime T: type) bool {
            return std.meta.hasFn(T, "__index");
        }

        fn hasNewIndexFunc(comptime T: type) bool {
            return std.meta.hasFn(T, "__newindex");
        }

        fn bindTypes(luaState: *zlua.Lua) !void {
            const start_top = luaState.getTop();

            // Bind our functions first
            inline for (registry) |entry| {
                try bindType(luaState, entry);
            }

            // Now add in our static properties to the created libraries
            inline for (registry) |entry| {
                try bindStaticProperties(luaState, entry);
            }

            // make sure we're not leaking stack
            const end_top = luaState.getTop();
            if (start_top != end_top) {
                log.err("Lua bindTypes: leaking stack! s: {d} e: {d}", .{ start_top, end_top });
            }
        }

        // __index is called when Lua gets a value from a table
        fn indexLookupFunc(comptime T: type, luaState: *zlua.Lua, bound_type: BoundType) i32 {
            const BoxedPointerType = BoxType(T, bound_type);

            // Get our key
            const key = luaState.toString(-1) catch |err| {
                log.err("Lua: indexLookupFunc could not get key! {s}: {any}", .{ bound_type.name, err });
                return 0;
            };

            const ptr = BoxedPointerType.checkBoxedUserdata(luaState, 1);

            // Grab this field if we find it
            inline for (std.meta.fields(T)) |field| {
                if (std.mem.eql(u8, key, field.name)) {
                    const val = @field(ptr, field.name);
                    return pushAny(luaState, val);
                }
            }

            // fallback to our own metatable so that we can still call bound functions like self:ourFunc()

            // get our own metatable
            _ = luaState.getMetatableRegistry(bound_type.name);

            // push the key again
            luaState.pushValue(2);

            // return metatable[key]
            _ = luaState.getTable(-2);

            return 1;
        }

        // __newindex is called when Lua sets a value on a table
        fn indexSetValueFunc(comptime T: type, luaState: *zlua.Lua, bound_type: BoundType) i32 {
            const BoxedPointerType = BoxType(T, bound_type);

            // Get our key
            const key = luaState.toString(-2) catch |err| {
                log.err("Lua: indexLookupFunc could not get key! {s}: {any}", .{ bound_type.name, err });
                return 0;
            };

            // If this is a userdata object, check if it has this property
            if (luaState.isUserdata(1)) {
                const ptr = BoxedPointerType.checkBoxedUserdata(luaState, 1);

                // Set this field if we find it
                inline for (std.meta.fields(T)) |field| {
                    if (std.mem.eql(u8, key, field.name)) {
                        const val = toAny(luaState, field.type, -1) catch {
                            luaState.raiseErrorStr("Could not set field! Should be type %s", .{@typeName(field.type)});
                            return 0;
                        };

                        @field(ptr, field.name) = val;
                        return 1;
                    }
                }
            }

            log.warn("Lua: {s}: Could not find field '{s}' to set", .{ bound_type.name, key });
            return 0;
        }

        fn bindStaticProperties(luaState: *zlua.Lua, comptime bound_type: BoundType) !void {
            const meta_table_name = bound_type.name;

            const start_top = luaState.getTop();

            // Get our library
            _ = try luaState.getGlobal(meta_table_name);

            // Register any constant fields, like Vec2.one
            const found_fields = comptime findFields(bound_type.Type, bound_type.ignore_fields);

            inline for (found_fields) |field| {
                const val = @field(bound_type.Type, field.name);
                _ = pushAny(luaState, val);

                luaState.setField(-2, field.name);
            }

            // Reset state
            luaState.pop(1);

            const end_top = luaState.getTop();
            if (start_top != end_top) {
                log.err("Lua property binding: leaking stack! s: {d} e: {d}", .{ start_top, end_top });
            }
        }

        fn bindType(luaState: *zlua.Lua, comptime bound_type: BoundType) !void {
            const T = bound_type.Type;
            const meta_table_name = bound_type.name;
            const BoxedPointerType = BoxType(T, bound_type);

            const startTop = luaState.getTop();

            // Make our boxed pointer type
            _ = luaState.newUserdata(BoxedPointerType, @sizeOf(BoxedPointerType));
            _ = try luaState.newMetatable(BoxedPointerType.ptr_metatable_name);

            // Make our new userData and metaTable
            _ = luaState.newUserdata(T, @sizeOf(T));
            _ = try luaState.newMetatable(meta_table_name);

            // GC func is required for memory management
            // Wire GC up to our destroy function if found!
            if (comptime hasDestroyFunc(T)) {
                // Make our GC function to wire to _gc in lua
                const gcFunc = struct {
                    fn inner(L: *zlua.Lua) i32 {
                        const ptr = L.checkUserdata(T, 1, meta_table_name);
                        ptr.destroy();
                        return 0;
                    }
                }.inner;

                luaState.pushClosure(zlua.wrap(gcFunc), 0);
                luaState.setField(-2, "__gc");
            }

            if (comptime hasIndexFunc(T)) {
                // Wire to __index in lua
                const indexFunc = struct {
                    fn inner(L: *zlua.Lua) i32 {
                        const ptr = BoxedPointerType.checkBoxedUserdata(L, 1);
                        return ptr.__index(L);
                    }
                }.inner;

                const wrapped_fn = zlua.wrap(indexFunc);

                // Set on boxed metatable
                luaState.pushClosure(wrapped_fn, 0);
                luaState.setField(-4, "__index");

                // Set on struct metatable
                luaState.pushClosure(wrapped_fn, 0);
                luaState.setField(-2, "__index");
            } else {
                // If no index func was given, use our own that indexes to ourself
                const indexFunc = struct {
                    fn inner(L: *zlua.Lua) i32 {
                        return indexLookupFunc(T, L, bound_type);
                    }
                }.inner;

                const wrapped_fn = zlua.wrap(indexFunc);

                // Set on boxed metatable
                luaState.pushClosure(wrapped_fn, 0);
                luaState.setField(-4, "__index");

                // Set on struct metatable
                luaState.pushClosure(wrapped_fn, 0);
                luaState.setField(-2, "__index");
            }

            if (comptime hasNewIndexFunc(T)) {
                // Wire to __newindex in lua
                const newIndexFunc = struct {
                    fn inner(L: *zlua.Lua) i32 {
                        const ptr = BoxedPointerType.checkBoxedUserdata(L, 1);
                        return ptr.__newindex(L);
                    }
                }.inner;

                const wrapped_fn = zlua.wrap(newIndexFunc);

                // Set on boxed metatable
                luaState.pushClosure(wrapped_fn, 0);
                luaState.setField(-4, "__newindex");

                // Set on struct metatable
                luaState.pushClosure(wrapped_fn, 0);
                luaState.setField(-2, "__newindex");
            } else {
                // If no index func was given, use our own that indexes to ourself
                const indexFunc = struct {
                    fn inner(L: *zlua.Lua) i32 {
                        return indexSetValueFunc(T, L, bound_type);
                    }
                }.inner;

                const wrapped_fn = zlua.wrap(indexFunc);

                // Set on boxed metatable
                luaState.pushClosure(wrapped_fn, 0);
                luaState.setField(-4, "__newindex");

                // Set on struct metatable
                luaState.pushClosure(wrapped_fn, 0);
                luaState.setField(-2, "__newindex");
            }

            // Now wire up our functions!
            const library_fns = comptime findLibraryFunctions(T, bound_type.ignore_fields);

            // also add in our mixin
            const mixin_fns = comptime findLibraryFunctionsOpt(bound_type.mixin, bound_type.ignore_fields);
            const found_fns = library_fns ++ mixin_fns;

            inline for (found_fns) |foundFunc| {
                luaState.pushClosure(foundFunc.func.?, 0);
                luaState.setField(-2, foundFunc.name);
            }

            // Make this usable with "require" and register our funcs in the library
            luaState.requireF(meta_table_name, zlua.wrap(makeLuaOpenLibAndBindFn(found_fns)), true);
            luaState.pop(1);

            log.debug("Bound lua type: '{any}' to '{s}'", .{ T, meta_table_name });

            luaState.pop(4); // pop: boxed userdata, boxed metatable, T userdata, T metatable

            const end_top = luaState.getTop();
            if (startTop != end_top) {
                log.err("Lua binding: leaking stack! s: {d} e: {d}", .{ startTop, end_top });
            }
        }

        fn bindLibrary(luaState: *zlua.Lua, libraryName: [:0]const u8, comptime funcs: []const zlua.FnReg) void {
            luaState.requireF(libraryName, zlua.wrap(makeLuaOpenLibFn(funcs)), true);
        }

        fn makeLuaBinding(name: [:0]const u8, mod_name: [:0]const u8, comptime function: anytype) zlua.FnReg {
            return zlua.FnReg{
                .name = name,
                .func = zlua.wrap(bindFuncLua(name, mod_name, function)),
            };
        }

        fn findLibraryFunctionsOpt(comptime module: ?type, ignore_fields: []const [:0]const u8) []const zlua.FnReg {
            if (module) |m| {
                return findLibraryFunctions(m, ignore_fields);
            }
            return &[_]zlua.FnReg{};
        }

        fn findLibraryFunctions(comptime module: anytype, ignore_fields: []const [:0]const u8) []const zlua.FnReg {
            comptime {
                const fn_fields = findFunctions(module, ignore_fields);

                var found: []const zlua.FnReg = &[_]zlua.FnReg{};
                for (fn_fields) |d| {
                    // convert the name string to be :0 terminated
                    const field_name: [:0]const u8 = d.name ++ "";
                    found = found ++ .{makeLuaBinding(field_name, @typeName(module), @field(module, d.name))};
                }

                return found;
            }
        }

        fn bindFuncLua(comptime name: [:0]const u8, comptime mod_name: [:0]const u8, comptime function: anytype) fn (lua: *zlua.Lua) i32 {
            return (opaque {
                fn lua_call(luaState: *zlua.Lua) i32 {
                    const FnType = @TypeOf(function);

                    const top = luaState.getTop();

                    // Can't bind types with anytype, so early out if we see one!
                    if (comptime hasAnytypeParam(FnType)) {
                        log.warn("Cannot call bound function with anytype param", .{});
                        return 0;
                    }

                    // Get a tuple of the various types of the arguments, and then create one
                    const ArgsTuple = std.meta.ArgsTuple(FnType);
                    var args: ArgsTuple = undefined;

                    const fn_info = @typeInfo(@TypeOf(function)).@"fn";
                    const params = fn_info.params;

                    // Validate number of args
                    if (top != params.len) {
                        const ignore_default = params.len == 0 and top == 1; // could just be our self ref

                        if (!ignore_default) {
                            log.warn("Lua: function '{s}:{s}' called with {d} arguments called with {d} instead", .{ mod_name, name, params.len, top });
                            luaState.raiseErrorStr("Invalid number of arguments to function", .{});
                            return 0;
                        }
                    }

                    inline for (params, 0..) |param, i| {
                        const param_type = param.type.?;
                        const lua_idx = i + 1;

                        args[i] = toAny(luaState, param_type, lua_idx) catch {
                            log.warn("Lua: '{s}:{s}': Could not bind arg {any} to {any}", .{ mod_name, name, lua_idx, param_type });
                            luaState.raiseErrorStr("Could not bind argument! Should be type %s", .{@typeName(param_type)});
                            return 0;
                        };
                    }

                    if (fn_info.return_type == null) {
                        @compileError("Function has no return type?! This should not be possible.");
                    }

                    const ReturnType = fn_info.return_type.?;

                    // Handle both error union and non-error union function calls
                    const ret_val = switch (@typeInfo(ReturnType)) {
                        .error_union => blk: {
                            const val = @call(.auto, function, args) catch |err| {
                                log.warn("Error returned from bound Lua function: {any}", .{err});
                                return 0;
                            };

                            break :blk val;
                        },
                        else => @call(.auto, function, args),
                    };

                    return pushAny(luaState, ret_val);
                }
            }).lua_call;
        }

        // Like ziglua pushAny, but also handling our registered types
        fn pushAny(luaState: *zlua.Lua, value: anytype) i32 {
            const val_type = @TypeOf(value);

            // Push the value onto the stack

            switch (@typeInfo(val_type)) {
                .void => {
                    return 0;
                },
                .array => {
                    luaState.createTable(0, 0);
                    for (value, 0..) |index_value, i| {
                        _ = luaState.pushInteger(@intCast(i + 1));
                        _ = pushAny(luaState, index_value);
                        luaState.setTable(-3);
                    }
                    return 1;
                },
                .vector => |info| {
                    _ = pushAny(luaState, @as([info.len]info.child, value));
                    return 1;
                },
                .optional, .null => {
                    if (value == null) {
                        luaState.pushNil();
                    } else {
                        _ = pushAny(luaState, value.?);
                    }
                    return 1;
                },
                .pointer => |p| {
                    const Child = p.child;
                    if (p.size == .one) {
                        // If this is a pointer of a bound type, box it up
                        if (getBoundType(Child)) |bound_type| {
                            const BoxedPointerType = BoxType(Child, bound_type);
                            const boxed_ptr: BoxedPointerType = .{ .pointer = value };

                            // make a new ptr to return
                            const ptr: *BoxedPointerType = @alignCast(luaState.newUserdata(BoxedPointerType, @sizeOf(BoxedPointerType)));

                            // set its metatable
                            _ = luaState.getMetatableRegistry(BoxedPointerType.ptr_metatable_name);
                            _ = luaState.setMetatable(-2);

                            // copy values to our pointer
                            ptr.* = boxed_ptr;

                            return 1;
                        }
                    }
                },
                .@"struct" => {
                    // handle our registered auto-bound struct types
                    if (comptime isRegistered(val_type)) {
                        // make a new ptr
                        const ptr: *val_type = @alignCast(luaState.newUserdata(val_type, @sizeOf(val_type)));

                        // set its metatable
                        _ = luaState.getMetatableRegistry(getMetaTableName(val_type));
                        _ = luaState.setMetatable(-2);

                        // copy values to our pointer
                        ptr.* = value;
                        return 1;
                    }
                },
                else => {},
            }

            // Fall back to the ziglua pushAny
            _ = luaState.pushAny(value) catch |err| {
                log.err("Error pushing value onto Lua stack! {any}", .{err});
                return 0;
            };

            return 1;
        }

        fn toAny(luaState: *zlua.Lua, comptime T: type, lua_idx: i32) !T {
            switch (@typeInfo(T)) {
                .pointer => |p| {
                    const Child = p.child;
                    if (p.size == .one) {
                        // If this is a pointer of a bound type, try to unbox it
                        if (getBoundType(Child)) |bound_type| {
                            const BoxedPointerType = BoxType(Child, bound_type);
                            return BoxedPointerType.checkBoxedUserdata(luaState, lua_idx);
                        }
                    }

                    // Fallback to the default toAny
                    return try luaState.toAny(T, lua_idx);
                },
                .array, .vector => {
                    const child = std.meta.Child(T);
                    const arr_len = switch (@typeInfo(T)) {
                        inline else => |i| i.len,
                    };

                    var result: [arr_len]child = undefined;
                    luaState.pushValue(lua_idx);
                    defer luaState.pop(1);

                    for (0..arr_len) |i| {
                        _ = luaState.rawGetIndex(-1, @intCast(i + 1));
                        defer luaState.pop(1);
                        result[i] = try toAny(luaState, child, -1);
                    }

                    return result;
                },
                .optional => {
                    if (luaState.isNil(lua_idx)) {
                        return null;
                    } else {
                        return try toAny(luaState, @typeInfo(T).optional.child, lua_idx);
                    }
                },
                else => {
                    // Might be a registered type
                    if (getBoundType(T)) |bound_type| {
                        // May need to unbox it
                        const BoxedPointerType = BoxType(T, bound_type);
                        return BoxedPointerType.checkBoxedUserdata(luaState, lua_idx).*;
                    }

                    // Fallback to the default toAny
                    return try luaState.toAny(T, lua_idx);
                },
            }
        }

        fn makeLuaOpenLibFn(lib_funcs: []const zlua.FnReg) fn (*zlua.Lua) i32 {
            return opaque {
                fn inner(luaState: *zlua.Lua) i32 {
                    // Register our new library for this type, with all our funcs!
                    luaState.newLib(lib_funcs);
                    return 1;
                }
            }.inner;
        }

        fn makeLuaOpenLibAndBindFn(lib_funcs: []const zlua.FnReg) fn (*zlua.Lua) i32 {
            return opaque {
                fn inner(luaState: *zlua.Lua) i32 {
                    // Register our new library for this type, with all our funcs!
                    luaState.newLib(lib_funcs);

                    return 1;
                }
            }.inner;
        }
    };
}

fn hasAnytypeParam(comptime T: type) bool {
    const fn_info = @typeInfo(T).@"fn";

    inline for (fn_info.params) |p| {
        if (p.type == null) return true;
        if (@hasField(@TypeOf(p), "is_generic") and p.is_generic) return true;
    }
    return false;
}

fn shouldIgnoreField(field_name: [:0]const u8, ignore_fields: []const [:0]const u8) bool {
    if (field_name.len == 0 or field_name[0] == '_') {
        return true;
    }

    for (ignore_fields) |toIgnore| {
        if (std.mem.eql(u8, field_name, toIgnore)) {
            return true;
        }
    }

    return false;
}

fn findFunctions(comptime module: anytype, ignore_fields: []const [:0]const u8) []const std.builtin.Type.Declaration {
    comptime {
        // Get all the public declarations in this module
        const decls = @typeInfo(module).@"struct".decls;

        // filter out only the public functions
        var gen_fields: []const std.builtin.Type.Declaration = &[_]std.builtin.Type.Declaration{};
        for (decls) |d| {
            if (shouldIgnoreField(d.name, ignore_fields))
                continue;

            const field = @field(module, d.name);
            if (@typeInfo(@TypeOf(field)) != .@"fn")
                continue;

            gen_fields = gen_fields ++ .{d};
        }

        return gen_fields;
    }
}

fn findFields(comptime module: anytype, ignore_fields: []const [:0]const u8) []const std.builtin.Type.Declaration {
    comptime {
        // Get all the public declarations in this module
        const decls = @typeInfo(module).@"struct".decls;

        // filter out only the public constants
        var gen_fields: []const std.builtin.Type.Declaration = &[_]std.builtin.Type.Declaration{};
        for (decls) |d| {
            if (shouldIgnoreField(d.name, ignore_fields))
                continue;

            const field = @field(module, d.name);
            if (@typeInfo(@TypeOf(field)) == .@"fn")
                continue;

            // Now filter out just the contants
            if (@typeInfo(@TypeOf(&field)).pointer.is_const) {
                gen_fields = gen_fields ++ .{d};
            }
        }

        return gen_fields;
    }
}

test "lua scripting" {
    const testing = std.testing;

    const Cat = struct {
        pub fn meow() void {
            log.info(" > The cat meows", .{});
        }
    };

    const TestBindingStruct = struct {
        message: []const u8,

        pub fn new(in_message: []const u8) @This() {
            return .{ .message = in_message };
        }

        pub fn getSelf(self: *@This()) *@This() {
            return self;
        }

        pub fn sayHello(self: @This()) void {
            log.info(" > Test Lua Binding says: {s}", .{self.message});
        }

        pub fn getMessage(self: *@This()) []const u8 {
            return self.message;
        }

        pub fn testOptional(self: ?*@This()) ?@This() {
            return self.?.*;
        }

        pub fn ignoreMe() void {
            @compileError("This field should be ignored during binding!");
        }

        // Lua garbage collection will automatically call destroy if found
        pub fn destroy(self: *@This()) void {
            _ = self;
            log.info("@This() cleanup called from Lua gc", .{});
        }

        // Test returning another bound type
        pub fn getCat() Cat {
            return .{};
        }

        pub const constant_message: [:0]const u8 = "This is a constant!";

        pub const cat: Cat = .{};
    };

    const Mixin = struct {
        pub fn testMixin(self: TestBindingStruct) void {
            log.info(" > This function was mixed in! Message: {s}", .{self.message});
        }
    };

    const lua = try Lua.init(std.testing.allocator);
    defer lua.deinit();

    const testScript =
        \\ -- sample data
        \\ sample_data = {
        \\      a = 1,
        \\      b = 2,
        \\      c = 'hello',
        \\ }
        \\
        \\ -- module from zig
        \\ local TestStruct = require("TestStruct")
        \\ local test_binding = TestStruct.new("Hello from Lua!")
        \\ test_binding:sayHello()
        \\ test_binding:testOptional()
        \\ test_binding:getCat():meow()
        \\ TestStruct.cat:meow()
        \\ local title = test_binding:getMessage()
        \\
        \\ -- Set and get fields
        \\ test_binding.message = "Updated value"
        \\ local title = test_binding:getMessage()
        \\
        \\ -- Pointer types
        \\ local test_pointer = test_binding:getSelf()
        \\ test_pointer:sayHello()
        \\ test_pointer.message = "Set from a pointer"
        \\ test_pointer:sayHello()
        \\ test_pointer:testMixin()
        \\
        \\ -- Random functions
        \\ function nops()
        \\      ;;
        \\ end
        \\ function concat(msg1, msg2)
        \\      local t1 = TestStruct.new(msg1)
        \\      t1:sayHello()
        \\      assert(t1:getMessage() == 'hello')
        \\      local t2 = TestStruct.new(msg2)
        \\      t2:sayHello()
        \\      assert(t2:getMessage() == 'lua')
        \\      return t1:getMessage() .. ' ' .. t2:getMessage()
        \\ end
    ;

    try lua.registerTypes(&[_]BoundType{
        .{
            .Type = TestBindingStruct,
            .name = "TestStruct",
            .ignore_fields = &[_][:0]const u8{"ignoreMe"},
            .mixin = Mixin,
        },
        .{
            .Type = Cat,
            .name = "Cat",
        },
    });
    try lua.runString(testScript);

    const Sample = struct {
        a: u32,
        b: u32,
        c: [:0]const u8,
    };
    var sample = try lua.get(Sample, "sample_data");
    try testing.expectEqual(sample.a, 1);
    try testing.expectEqual(sample.b, 2);
    try testing.expectEqualStrings(sample.c, "hello");

    sample.c = "world";
    try lua.set("sample_data", sample);
    sample = try lua.get(Sample, "sample_data");
    try testing.expectEqualStrings(sample.c, "world");

    try lua.callFunction(void, "nops", .{});
    const ret = try lua.callFunction([:0]const u8, "concat", .{ "hello", "lua" });
    try testing.expectEqualStrings("hello lua", ret);
}
