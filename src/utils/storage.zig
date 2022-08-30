const std = @import("std");
const assert = std.debug.assert;
const testing = std.testing;
const json = std.json;

pub const Error = error{
    FileNotFound,
    InvalidPath,
    InvalidKeyPath,
    InvalidValueType,
    InvalidValueLen,
    UnsupportedValue,
};

/// 代表一个存储对象，每个存储对象占据一个独立的目录，具备如下能力：
/// 1. 保存基本键值对，支持布尔值、整数、浮点数、字符串、数组、对象
/// 2. 序列化至文件
/// 3. 反序列化至内存
pub const Storage = struct {
    pub const root_json_file = "root.json";

    allocator: std.mem.Allocator,
    root_path: []const u8,
    tree: json.ValueTree,

    // 克隆整个对象
    fn cloneValueTree(allocator: std.mem.Allocator, value: json.Value) json.Value {
        switch (value) {
            .String => |bs| {
                return json.Value{
                    .String = allocator.dupe(u8, bs) catch unreachable,
                };
            },
            .Array => |vs| {
                var v = json.Value{
                    .Array = json.Array.initCapacity(allocator, vs.items.len) catch unreachable,
                };
                for (vs.items) |iv| assert(iv != .Object);
                v.Array.appendSliceAssumeCapacity(vs.items);
                return v;
            },
            .Object => |o| {
                var v = json.Value{ .Object = json.ObjectMap.init(allocator) };
                var it = o.iterator();
                while (it.next()) |kv| {
                    v.Object.put(
                        allocator.dupe(u8, kv.key_ptr.*) catch unreachable,
                        cloneValueTree(allocator, kv.value_ptr.*),
                    ) catch unreachable;
                }
                return v;
            },
            .Bool, .Integer, .Float => return value,
            else => std.debug.panic("invalid value type: {s}", .{std.meta.tagName(value)}),
        }
    }

    // 创建存储对象，若目录为空则创建，目录不为空则尝试加载
    pub fn init(allocator: std.mem.Allocator, root_path: []const u8) !*Storage {
        var dir = try std.fs.cwd().makeOpenPath(root_path, .{});
        defer dir.close();

        var s = try allocator.create(Storage);
        errdefer allocator.destroy(s);
        s.allocator = allocator;
        s.root_path = try allocator.dupe(u8, root_path);
        errdefer allocator.free(s.root_path);

        const result = dir.readFileAlloc(allocator, root_json_file, std.math.maxInt(usize));
        if (result) |content| {
            var jp = json.Parser.init(allocator, true);
            defer jp.deinit();
            var tree = try jp.parse(content);
            defer tree.deinit();
            allocator.free(content);

            // 由于Parser返回的ValueTree不能修改（https://github.com/ziglang/zig/issues/5229）
            // 这里需要重新构建整个树
            s.tree.arena = std.heap.ArenaAllocator.init(allocator);
            s.tree.root = cloneValueTree(s.tree.arena.allocator(), tree.root);
        } else |e| {
            if (e != error.FileNotFound) return e;
            s.tree.arena = std.heap.ArenaAllocator.init(allocator);
            s.tree.root = .{ .Object = json.ObjectMap.init(s.tree.arena.allocator()) };
        }

        return s;
    }

    pub fn deinit(s: *Storage) void {
        s.tree.deinit();
        s.allocator.free(s.root_path);
        s.allocator.destroy(s);
    }

    // 添加单值，示例如下：
    //      a.b.c.d => 3
    //      a.b.c.1 => 0.3
    //      a.b.c.1.3 => true
    //    实际应用中应注意控制路径深度，避免产生效率问题
    pub fn putScalar(s: *Storage, key_path: []const u8, comptime T: type, value: T) !void {
        assert(!std.mem.endsWith(u8, key_path, "."));
        var node = &s.tree.root;
        var begin_index: usize = 0;
        while (std.mem.indexOf(u8, key_path[begin_index..], ".")) |pos| {
            const key = key_path[begin_index .. begin_index + pos];
            if (node.Object.getPtr(key)) |obj| {
                node = obj;
            } else {
                try node.Object.put(
                    try s.tree.arena.allocator().dupe(u8, key),
                    .{ .Object = json.ObjectMap.init(s.tree.arena.allocator()) },
                );
                node = node.Object.getPtr(key).?;
            }
            if (node.* != .Object) {
                return error.InvalidKeyPath;
            }
            begin_index += pos + 1;
        }
        const key = key_path[begin_index..];
        assert(key.len > 0);
        switch (T) {
            bool => {
                try node.Object.put(
                    try s.tree.arena.allocator().dupe(u8, key),
                    json.Value{ .Bool = value },
                );
            },
            i8, u8, i16, u16, i32, u32, i64, u64, c_int => {
                try node.Object.put(
                    try s.tree.arena.allocator().dupe(u8, key),
                    json.Value{ .Integer = @intCast(i64, value) },
                );
            },
            f32, f64 => {
                try node.Object.put(
                    try s.tree.arena.allocator().dupe(u8, key),
                    json.Value{ .Float = @floatCast(f64, value) },
                );
            },
            else => return error.UnsupportedValue,
        }
    }

    // 添加对象，null表示添加空对象
    pub fn putObject(s: *Storage, key_path: []const u8, map: ?json.ObjectMap) !void {
        assert(!std.mem.endsWith(u8, key_path, "."));
        var node = &s.tree.root;
        var begin_index: usize = 0;
        while (std.mem.indexOf(u8, key_path[begin_index..], ".")) |pos| {
            const key = key_path[begin_index .. begin_index + pos];
            if (node.Object.getPtr(key)) |obj| {
                node = obj;
            } else {
                try node.Object.put(
                    try s.tree.arena.allocator().dupe(u8, key),
                    .{ .Object = json.ObjectMap.init(s.tree.arena.allocator()) },
                );
                node = node.Object.getPtr(key).?;
            }
            if (node.* != .Object) {
                return error.InvalidKeyPath;
            }
            begin_index += pos + 1;
        }
        const key = key_path[begin_index..];
        assert(key.len > 0);
        if (map) |o| {
            try node.Object.put(
                try s.tree.arena.allocator().dupe(u8, key),
                cloneValueTree(s.tree.arena.allocator(), .{ .Object = o }),
            );
        } else {
            try node.Object.put(
                try s.tree.arena.allocator().dupe(u8, key),
                .{ .Object = json.ObjectMap.init(s.tree.arena.allocator()) },
            );
        }
    }

    // 添加数组
    pub fn putArray(s: *Storage, key_path: []const u8, comptime T: type, values: []const T) !void {
        assert(!std.mem.endsWith(u8, key_path, "."));
        var node = &s.tree.root;
        var begin_index: usize = 0;
        while (std.mem.indexOf(u8, key_path[begin_index..], ".")) |pos| {
            const key = key_path[begin_index .. begin_index + pos];
            if (node.Object.getPtr(key)) |obj| {
                node = obj;
            } else {
                try node.Object.put(
                    try s.tree.arena.allocator().dupe(u8, key),
                    .{ .Object = json.ObjectMap.init(s.tree.arena.allocator()) },
                );
                node = node.Object.getPtr(key).?;
            }
            if (node.* != .Object) {
                return error.InvalidKeyPath;
            }
            begin_index += pos + 1;
        }
        const key = key_path[begin_index..];
        assert(key.len > 0);
        var array = json.Value{ .Array = try json.Array.initCapacity(s.tree.arena.allocator(), values.len) };
        for (values) |v| {
            switch (T) {
                bool => {
                    array.Array.appendAssumeCapacity(json.Value{ .Bool = v });
                },
                i8, u8, i16, u16, i32, u32, i64, u64 => {
                    array.Array.appendAssumeCapacity(json.Value{ .Integer = @intCast(i64, v) });
                },
                f32, f64 => {
                    array.Array.appendAssumeCapacity(json.Value{ .Float = @floatCast(f64, v) });
                },
                else => return error.UnsupportedValue,
            }
        }
        try node.Object.put(try s.tree.arena.allocator().dupe(u8, key), array);
    }

    // 添加字符串
    pub fn putString(s: *Storage, key_path: []const u8, str: []const u8) !void {
        assert(!std.mem.endsWith(u8, key_path, "."));
        var node = &s.tree.root;
        var begin_index: usize = 0;
        while (std.mem.indexOf(u8, key_path[begin_index..], ".")) |pos| {
            const key = key_path[begin_index .. begin_index + pos];
            if (node.Object.getPtr(key)) |obj| {
                node = obj;
            } else {
                try node.Object.put(
                    try s.tree.arena.allocator().dupe(u8, key),
                    .{ .Object = json.ObjectMap.init(s.tree.arena.allocator()) },
                );
                node = node.Object.getPtr(key).?;
            }
            if (node.* != .Object) {
                return error.InvalidKeyPath;
            }
            begin_index += pos + 1;
        }
        const key = key_path[begin_index..];
        assert(key.len > 0);
        try node.Object.put(
            try s.tree.arena.allocator().dupe(u8, key),
            json.Value{ .String = try s.tree.arena.allocator().dupe(u8, str) },
        );
    }

    // 获取数据，用户需自行拷贝数据，不可直接修改
    pub fn get(s: *Storage, key_path: []const u8) ?json.Value {
        assert(!std.mem.endsWith(u8, key_path, "."));
        var node = &s.tree.root;
        var begin_index: usize = 0;
        while (std.mem.indexOf(u8, key_path[begin_index..], ".")) |pos| {
            const key = key_path[begin_index .. begin_index + pos];
            if (node.Object.getPtr(key)) |obj| {
                node = obj;
            } else {
                return null;
            }
            if (node.* != .Object) {
                return null;
            }
            begin_index += pos + 1;
        }
        const key = key_path[begin_index..];
        assert(key.len > 0);
        return node.Object.get(key);
    }

    // 删除值
    pub fn remove(s: *Storage, key_path: []const u8) !void {
        assert(!std.mem.endsWith(u8, key_path, "."));
        var node = &s.tree.root;
        var begin_index: usize = 0;
        while (std.mem.indexOf(u8, key_path[begin_index..], ".")) |pos| {
            const key = key_path[begin_index .. begin_index + pos];
            if (node.Object.getPtr(key)) |obj| {
                node = obj;
            } else {
                return;
            }
            if (node.* != .Object) {
                return error.InvalidKeyPath;
            }
            begin_index += pos + 1;
        }
        const key = key_path[begin_index..];
        assert(key.len > 0);
        _ = node.Object.swapRemove(key);
    }

    // helper api
    pub fn getScalar(s: *Storage, key_path: []const u8, comptime T: type) !T {
        if (s.get(key_path)) |v| {
            switch (T) {
                bool => {
                    if (v != .Bool) return error.InvalidValueType;
                    return v.Bool;
                },
                i8, u8, i16, u16, i32, u32, i64, u64, c_int => {
                    if (v != .Integer) return error.InvalidValueType;
                    return @intCast(T, v.Integer);
                },
                f32, f64 => {
                    if (v != .Float) return error.InvalidValueType;
                    return @floatCast(T, v.Float);
                },
                else => return error.UnsupportedValue,
            }
        }
        return error.InvalidKeyPath;
    }
    pub fn getStringAlloc(s: *Storage, allocator: std.mem.Allocator, key_path: []const u8) ![]u8 {
        if (s.get(key_path)) |v| {
            if (v != .String) return error.InvalidValueType;
            return allocator.dupe(u8, v.String);
        }
        return error.InvalidKeyPath;
    }
    pub fn getArrayAlloc(s: *Storage, allocator: std.mem.Allocator, key_path: []const u8, comptime T: type) ![]T {
        if (s.get(key_path)) |v| {
            if (v != .Array) return error.InvalidValueType;
            if (v.Array.items.len == 0) return &[_]T{};
            switch (T) {
                bool => {
                    if (v.Array.items[0] != .Bool) return error.InvalidValueType;
                    return try allocator.dupe(bool, v.Array.items);
                },
                i8, u8, i16, u16, i32, u32, i64, u64 => {
                    if (v.Array.items[0] != .Integer) return error.InvalidValueType;
                    const array = try allocator.alloc(T, v.Array.items.len);
                    for (v.Array.items) |item, i| {
                        array[i] = @intCast(T, item.Integer);
                    }
                    return array;
                },
                f32, f64 => {
                    if (v.Array.items[0] != .Float) return error.InvalidValueType;
                    const array = try allocator.alloc(T, v.Array.items.len);
                    for (v.Array.items) |item, i| {
                        array[i] = @floatCast(T, item.Float);
                    }
                    return array;
                },
                else => return error.UnsupportedValue,
            }
        }
        return error.InvalidKeyPath;
    }
    pub fn getAndFillArray(s: *Storage, key_path: []const u8, comptime T: type, array: []T) !void {
        if (s.get(key_path)) |v| {
            if (v != .Array) return error.InvalidValueType;
            if (v.Array.items.len == 0) return error.InvalidValueLen;
            switch (T) {
                bool => {
                    if (v.Array.items[0] != .Bool) return error.InvalidValueType;
                    for (array) |*a, i| a.* = v.Array.items[i].Bool;
                    return;
                },
                i8, u8, i16, u16, i32, u32, i64, u64 => {
                    if (v.Array.items[0] != .Integer) return error.InvalidValueType;
                    for (array) |*a, i| a.* = @intCast(T, v.Array.items[i].Integer);
                    return;
                },
                f32, f64 => {
                    if (v.Array.items[0] != .Float) return error.InvalidValueType;
                    for (array) |*a, i| a.* = @floatCast(T, v.Array.items[i].Float);
                    return;
                },
                else => return error.UnsupportedValue,
            }
        }
        return error.InvalidKeyPath;
    }

    // 序列化至文件
    pub fn writeToDisk(s: *Storage) !void {
        var buf: [512]u8 = undefined;
        var json_path = try std.fmt.bufPrint(&buf, "{s}/{s}", .{ s.root_path, root_json_file });
        var json_file = try std.fs.cwd().createFile(json_path, .{});
        defer json_file.close();
        try s.tree.root.jsonStringify(
            .{ .whitespace = json.StringifyOptions.Whitespace{} },
            json_file.writer(),
        );
    }
};

test "storage" {
    var s = try Storage.init(std.testing.allocator, "zig-out/test");
    try s.putString("hello", "world");
    try testing.expectEqualStrings(s.get("hello").?.String, "world");
    try s.putString("hello", "world1");
    try s.putString("hello", "world2");
    try s.putString("hello", "world3");
    try s.putArray("my.other.arr", u32, &.{ 5, 4, 3 });
    try s.putScalar("another1.hello", i32, 1);
    try s.putScalar("another2.hello", i32, 2);
    try s.writeToDisk();
    s.deinit();

    s = try Storage.init(std.testing.allocator, "zig-out/test");
    try s.putScalar("another1.world.play", u32, 3);
    try s.putScalar("another2.world.play", u32, 3);
    try testing.expectEqualStrings(s.get("hello").?.String, "world3");
    try testing.expectEqual(s.get("my.other.arr").?.Array.items[2].Integer, 3);
    try testing.expectEqual(s.get("another1.hello").?.Integer, 1);
    try testing.expectEqual(s.get("another2.hello").?.Integer, 2);
    try s.writeToDisk();
    s.deinit();
}
