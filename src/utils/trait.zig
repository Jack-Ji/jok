const std = @import("std");
const meta = std.meta;
const mem = std.mem;
const debug = std.debug;
const testing = std.testing;

pub const TraitFn = fn (type) bool;

pub fn multiTrait(comptime traits: anytype) TraitFn {
    const Closure = struct {
        pub fn trait(comptime T: type) bool {
            inline for (traits) |t|
                if (!t(T)) return false;
            return true;
        }
    };
    return Closure.trait;
}

test "multiTrait" {
    const Vector2 = struct {
        const MyType = @This();

        x: u8,
        y: u8,

        pub fn add(self: MyType, other: MyType) MyType {
            return MyType{
                .x = self.x + other.x,
                .y = self.y + other.y,
            };
        }
    };

    const isVector = multiTrait(.{
        hasFn("add"),
        hasField("x"),
        hasField("y"),
    });
    try testing.expect(isVector(Vector2));
    try testing.expect(!isVector(u8));
}

pub fn hasFn(comptime name: []const u8) TraitFn {
    const Closure = struct {
        pub fn trait(comptime T: type) bool {
            if (!comptime isContainer(T)) return false;
            if (!comptime @hasDecl(T, name)) return false;
            const DeclType = @TypeOf(@field(T, name));
            return @typeInfo(DeclType) == .@"fn";
        }
    };
    return Closure.trait;
}

test "hasFn" {
    const TestStruct = struct {
        pub fn useless() void {}
    };

    try testing.expect(hasFn("useless")(TestStruct));
    try testing.expect(!hasFn("append")(TestStruct));
    try testing.expect(!hasFn("useless")(u8));
}

pub fn hasField(comptime name: []const u8) TraitFn {
    const Closure = struct {
        pub fn trait(comptime T: type) bool {
            const fields = switch (@typeInfo(T)) {
                .@"struct" => |s| s.fields,
                .@"union" => |u| u.fields,
                .@"enum" => |e| e.fields,
                else => return false,
            };

            inline for (fields) |field| {
                if (mem.eql(u8, field.name, name)) return true;
            }

            return false;
        }
    };
    return Closure.trait;
}

test "hasField" {
    const TestStruct = struct {
        value: u32,
    };

    try testing.expect(hasField("value")(TestStruct));
    try testing.expect(!hasField("value")(*TestStruct));
    try testing.expect(!hasField("x")(TestStruct));
    try testing.expect(!hasField("x")(**TestStruct));
    try testing.expect(!hasField("value")(u8));
}

pub fn is(comptime id: std.builtin.TypeId) TraitFn {
    const Closure = struct {
        pub fn trait(comptime T: type) bool {
            return id == @typeInfo(T);
        }
    };
    return Closure.trait;
}

test "is" {
    try testing.expect(is(.int)(u8));
    try testing.expect(!is(.int)(f32));
    try testing.expect(is(.pointer)(*u8));
    try testing.expect(is(.void)(void));
    try testing.expect(!is(.optional)(anyerror));
}

pub fn isPtrTo(comptime id: std.builtin.TypeId) TraitFn {
    const Closure = struct {
        pub fn trait(comptime T: type) bool {
            if (!comptime isSingleItemPtr(T)) return false;
            return id == @typeInfo(meta.Child(T));
        }
    };
    return Closure.trait;
}

test "isPtrTo" {
    try testing.expect(!isPtrTo(.@"struct")(struct {}));
    try testing.expect(isPtrTo(.@"struct")(*struct {}));
    try testing.expect(!isPtrTo(.@"struct")(**struct {}));
}

pub fn isSliceOf(comptime id: std.builtin.TypeId) TraitFn {
    const Closure = struct {
        pub fn trait(comptime T: type) bool {
            if (!comptime isSlice(T)) return false;
            return id == @typeInfo(meta.Child(T));
        }
    };
    return Closure.trait;
}

test "isSliceOf" {
    try testing.expect(!isSliceOf(.@"struct")(struct {}));
    try testing.expect(isSliceOf(.@"struct")([]struct {}));
    try testing.expect(!isSliceOf(.@"struct")([][]struct {}));
}

///////////Strait trait Fns

//@TODO:
// Somewhat limited since we can't apply this logic to normal variables, fields, or
//  Fns yet. Should be isExternType?
pub fn isExtern(comptime T: type) bool {
    return switch (@typeInfo(T)) {
        .@"struct" => |s| s.layout == .@"extern",
        .@"union" => |u| u.layout == .@"extern",
        else => false,
    };
}

test "isExtern" {
    const TestExStruct = extern struct {};
    const TestStruct = struct {};

    try testing.expect(isExtern(TestExStruct));
    try testing.expect(!isExtern(TestStruct));
    try testing.expect(!isExtern(u8));
}

pub fn isPacked(comptime T: type) bool {
    return switch (@typeInfo(T)) {
        .@"struct" => |s| s.layout == .@"packed",
        .@"union" => |u| u.layout == .@"packed",
        else => false,
    };
}

test "isPacked" {
    const TestPStruct = packed struct {};
    const TestStruct = struct {};

    try testing.expect(isPacked(TestPStruct));
    try testing.expect(!isPacked(TestStruct));
    try testing.expect(!isPacked(u8));
}

pub fn isUnsignedInt(comptime T: type) bool {
    return switch (@typeInfo(T)) {
        .int => |i| i.signedness == .unsigned,
        else => false,
    };
}

test "isUnsignedInt" {
    try testing.expect(isUnsignedInt(u32) == true);
    try testing.expect(isUnsignedInt(comptime_int) == false);
    try testing.expect(isUnsignedInt(i64) == false);
    try testing.expect(isUnsignedInt(f64) == false);
}

pub fn isSignedInt(comptime T: type) bool {
    return switch (@typeInfo(T)) {
        .comptime_int => true,
        .int => |i| i.signedness == .signed,
        else => false,
    };
}

test "isSignedInt" {
    try testing.expect(isSignedInt(u32) == false);
    try testing.expect(isSignedInt(comptime_int) == true);
    try testing.expect(isSignedInt(i64) == true);
    try testing.expect(isSignedInt(f64) == false);
}

pub fn isSingleItemPtr(comptime T: type) bool {
    if (comptime is(.pointer)(T)) {
        return @typeInfo(T).pointer.size == .one;
    }
    return false;
}

test "isSingleItemPtr" {
    const array = [_]u8{0} ** 10;
    try comptime testing.expect(isSingleItemPtr(@TypeOf(&array[0])));
    try comptime testing.expect(!isSingleItemPtr(@TypeOf(array)));
    var runtime_zero: usize = 0;
    _ = &runtime_zero;
    try testing.expect(!isSingleItemPtr(@TypeOf(array[runtime_zero..1])));
}

pub fn isManyItemPtr(comptime T: type) bool {
    if (comptime is(.pointer)(T)) {
        return @typeInfo(T).pointer.size == .many;
    }
    return false;
}

test "isManyItemPtr" {
    const array = [_]u8{0} ** 10;
    const mip = @as([*]const u8, @ptrCast(&array[0]));
    try testing.expect(isManyItemPtr(@TypeOf(mip)));
    try testing.expect(!isManyItemPtr(@TypeOf(array)));
    try testing.expect(!isManyItemPtr(@TypeOf(array[0..1])));
}

pub fn isSlice(comptime T: type) bool {
    if (comptime is(.pointer)(T)) {
        return @typeInfo(T).pointer.size == .slice;
    }
    return false;
}

test "isSlice" {
    const array = [_]u8{0} ** 10;
    var runtime_zero: usize = 0;
    _ = &runtime_zero;
    try testing.expect(isSlice(@TypeOf(array[runtime_zero..])));
    try testing.expect(!isSlice(@TypeOf(array)));
    try testing.expect(!isSlice(@TypeOf(&array[0])));
}

pub fn isIndexable(comptime T: type) bool {
    if (comptime is(.pointer)(T)) {
        if (@typeInfo(T).pointer.size == .one) {
            return (comptime is(.array)(meta.Child(T)));
        }
        return true;
    }
    return comptime is(.array)(T) or is(.vector)(T) or isTuple(T);
}

test "isIndexable" {
    const array = [_]u8{0} ** 10;
    const slice = @as([]const u8, &array);
    const vector: @Vector(2, u32) = [_]u32{0} ** 2;
    const tuple = .{ 1, 2, 3 };

    try testing.expect(isIndexable(@TypeOf(array)));
    try testing.expect(isIndexable(@TypeOf(&array)));
    try testing.expect(isIndexable(@TypeOf(slice)));
    try testing.expect(!isIndexable(meta.Child(@TypeOf(slice))));
    try testing.expect(isIndexable(@TypeOf(vector)));
    try testing.expect(isIndexable(@TypeOf(tuple)));
}

pub fn isNumber(comptime T: type) bool {
    return switch (@typeInfo(T)) {
        .int, .float, .comptime_int, .comptime_float => true,
        else => false,
    };
}

test "isNumber" {
    const NotANumber = struct {
        number: u8,
    };

    try testing.expect(isNumber(u32));
    try testing.expect(isNumber(f32));
    try testing.expect(isNumber(u64));
    try testing.expect(isNumber(@TypeOf(102)));
    try testing.expect(isNumber(@TypeOf(102.123)));
    try testing.expect(!isNumber([]u8));
    try testing.expect(!isNumber(NotANumber));
}

pub fn isIntegral(comptime T: type) bool {
    return switch (@typeInfo(T)) {
        .int, .comptime_int => true,
        else => false,
    };
}

test "isIntegral" {
    try testing.expect(isIntegral(u32));
    try testing.expect(!isIntegral(f32));
    try testing.expect(isIntegral(@TypeOf(102)));
    try testing.expect(!isIntegral(@TypeOf(102.123)));
    try testing.expect(!isIntegral(*u8));
    try testing.expect(!isIntegral([]u8));
}

pub fn isFloat(comptime T: type) bool {
    return switch (@typeInfo(T)) {
        .float, .comptime_float => true,
        else => false,
    };
}

test "isFloat" {
    try testing.expect(!isFloat(u32));
    try testing.expect(isFloat(f32));
    try testing.expect(!isFloat(@TypeOf(102)));
    try testing.expect(isFloat(@TypeOf(102.123)));
    try testing.expect(!isFloat(*f64));
    try testing.expect(!isFloat([]f32));
}

pub fn isConstPtr(comptime T: type) bool {
    if (!comptime is(.pointer)(T)) return false;
    return @typeInfo(T).pointer.is_const;
}

test "isConstPtr" {
    var t: u8 = 0;
    t = t;
    const c: u8 = 0;
    try testing.expect(isConstPtr(*const @TypeOf(t)));
    try testing.expect(isConstPtr(@TypeOf(&c)));
    try testing.expect(!isConstPtr(*@TypeOf(t)));
    try testing.expect(!isConstPtr(@TypeOf(6)));
}

pub fn isContainer(comptime T: type) bool {
    return switch (@typeInfo(T)) {
        .@"struct", .@"union", .@"enum", .@"opaque" => true,
        else => false,
    };
}

test "isContainer" {
    const TestStruct = struct {};
    const TestUnion = union {
        a: void,
    };
    const TestEnum = enum {
        A,
        B,
    };
    const TestOpaque = opaque {};

    try testing.expect(isContainer(TestStruct));
    try testing.expect(isContainer(TestUnion));
    try testing.expect(isContainer(TestEnum));
    try testing.expect(isContainer(TestOpaque));
    try testing.expect(!isContainer(u8));
}

pub fn isTuple(comptime T: type) bool {
    return is(.@"struct")(T) and @typeInfo(T).@"struct".is_tuple;
}

test "isTuple" {
    const t1 = struct {};
    const t2 = .{ .a = 0 };
    const t3 = .{ 1, 2, 3 };
    try testing.expect(!isTuple(t1));
    try testing.expect(!isTuple(@TypeOf(t2)));
    try testing.expect(isTuple(@TypeOf(t3)));
}

/// Returns true if the passed type will coerce to []const u8.
/// Any of the following are considered strings:
/// ```
/// []const u8, [:S]const u8, *const [N]u8, *const [N:S]u8,
/// []u8, [:S]u8, *[:S]u8, *[N:S]u8.
/// ```
/// These types are not considered strings:
/// ```
/// u8, [N]u8, [*]const u8, [*:0]const u8,
/// [*]const [N]u8, []const u16, []const i8,
/// *const u8, ?[]const u8, ?*const [N]u8.
/// ```
pub fn isZigString(comptime T: type) bool {
    return comptime blk: {
        // Only pointer types can be strings, no optionals
        const info = @typeInfo(T);
        if (info != .pointer) break :blk false;

        const ptr = &info.pointer;
        // Check for CV qualifiers that would prevent coerction to []const u8
        if (ptr.is_volatile or ptr.is_allowzero) break :blk false;

        // If it's already a slice, simple check.
        if (ptr.size == .slice) {
            break :blk ptr.child == u8;
        }

        // Otherwise check if it's an array type that coerces to slice.
        if (ptr.size == .one) {
            const child = @typeInfo(ptr.child);
            if (child == .array) {
                const arr = &child.array;
                break :blk arr.child == u8;
            }
        }

        break :blk false;
    };
}

test "isZigString" {
    try testing.expect(isZigString([]const u8));
    try testing.expect(isZigString([]u8));
    try testing.expect(isZigString([:0]const u8));
    try testing.expect(isZigString([:0]u8));
    try testing.expect(isZigString([:5]const u8));
    try testing.expect(isZigString([:5]u8));
    try testing.expect(isZigString(*const [0]u8));
    try testing.expect(isZigString(*[0]u8));
    try testing.expect(isZigString(*const [0:0]u8));
    try testing.expect(isZigString(*[0:0]u8));
    try testing.expect(isZigString(*const [0:5]u8));
    try testing.expect(isZigString(*[0:5]u8));
    try testing.expect(isZigString(*const [10]u8));
    try testing.expect(isZigString(*[10]u8));
    try testing.expect(isZigString(*const [10:0]u8));
    try testing.expect(isZigString(*[10:0]u8));
    try testing.expect(isZigString(*const [10:5]u8));
    try testing.expect(isZigString(*[10:5]u8));

    try testing.expect(!isZigString(u8));
    try testing.expect(!isZigString([4]u8));
    try testing.expect(!isZigString([4:0]u8));
    try testing.expect(!isZigString([*]const u8));
    try testing.expect(!isZigString([*]const [4]u8));
    try testing.expect(!isZigString([*c]const u8));
    try testing.expect(!isZigString([*c]const [4]u8));
    try testing.expect(!isZigString([*:0]const u8));
    try testing.expect(!isZigString([*:0]const u8));
    try testing.expect(!isZigString(*[]const u8));
    try testing.expect(!isZigString(?[]const u8));
    try testing.expect(!isZigString(?*const [4]u8));
    try testing.expect(!isZigString([]allowzero u8));
    try testing.expect(!isZigString([]volatile u8));
    try testing.expect(!isZigString(*allowzero [4]u8));
    try testing.expect(!isZigString(*volatile [4]u8));
}

pub fn hasDecls(comptime T: type, comptime names: anytype) bool {
    inline for (names) |name| {
        if (!@hasDecl(T, name))
            return false;
    }
    return true;
}

test "hasDecls" {
    const TestStruct1 = struct {};
    const TestStruct2 = struct {
        pub var a: u32 = undefined;
        pub var b: u32 = undefined;
        c: bool,
        pub fn useless() void {}
    };

    const tuple = .{ "a", "b", "c" };

    try testing.expect(!hasDecls(TestStruct1, .{"a"}));
    try testing.expect(hasDecls(TestStruct2, .{ "a", "b" }));
    try testing.expect(hasDecls(TestStruct2, .{ "a", "b", "useless" }));
    try testing.expect(!hasDecls(TestStruct2, .{ "a", "b", "c" }));
    try testing.expect(!hasDecls(TestStruct2, tuple));
}

pub fn hasFields(comptime T: type, comptime names: anytype) bool {
    inline for (names) |name| {
        if (!@hasField(T, name))
            return false;
    }
    return true;
}

test "hasFields" {
    const TestStruct1 = struct {};
    const TestStruct2 = struct {
        a: u32,
        b: u32,
        c: bool,
        pub fn useless() void {}
    };

    const tuple = .{ "a", "b", "c" };

    try testing.expect(!hasFields(TestStruct1, .{"a"}));
    try testing.expect(hasFields(TestStruct2, .{ "a", "b" }));
    try testing.expect(hasFields(TestStruct2, .{ "a", "b", "c" }));
    try testing.expect(hasFields(TestStruct2, tuple));
    try testing.expect(!hasFields(TestStruct2, .{ "a", "b", "useless" }));
}

pub fn hasFunctions(comptime T: type, comptime names: anytype) bool {
    inline for (names) |name| {
        if (!hasFn(name)(T))
            return false;
    }
    return true;
}

test "hasFunctions" {
    const TestStruct1 = struct {};
    const TestStruct2 = struct {
        pub fn a() void {}
        fn b() void {}
    };

    const tuple = .{ "a", "b", "c" };

    try testing.expect(!hasFunctions(TestStruct1, .{"a"}));
    try testing.expect(hasFunctions(TestStruct2, .{ "a", "b" }));
    try testing.expect(!hasFunctions(TestStruct2, .{ "a", "b", "c" }));
    try testing.expect(!hasFunctions(TestStruct2, tuple));
}
