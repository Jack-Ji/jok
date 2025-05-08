const std = @import("std");

pub fn LineIterator(comptime Reader: type) type {
    return struct {
        buffer: []u8,
        reader: Reader,

        pub fn next(self: *@This()) !?[]const u8 {
            var fbs = std.io.fixedBufferStream(self.buffer);
            self.reader.streamUntilDelimiter(
                fbs.writer(),
                '\n',
                fbs.buffer.len,
            ) catch |err| switch (err) {
                error.EndOfStream => if (fbs.getWritten().len == 0) return null,
                else => |e| return e,
            };
            var line = fbs.getWritten();
            if (0 < line.len and line[line.len - 1] == '\r')
                line = line[0 .. line.len - 1];
            return line;
        }
    };
}

pub fn lineIterator(rdr: anytype, buffer: []u8) LineIterator(@TypeOf(rdr)) {
    return .{ .buffer = buffer, .reader = rdr };
}
