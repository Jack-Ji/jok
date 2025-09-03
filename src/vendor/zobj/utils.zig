const std = @import("std");

pub fn LineIterator(comptime Reader: type) type {
    return struct {
        buffer: []u8,
        reader: Reader,

        pub fn next(self: *@This()) !?[]const u8 {
            var writer = std.Io.Writer.fixed(self.buffer);
            _ = self.reader.streamDelimiter(&writer, '\n') catch |err| switch (err) {
                error.EndOfStream => if (writer.end == 0) return null,
                else => |e| return e,
            };
            var line = writer.buffered();
            if (0 < line.len and line[line.len - 1] == '\r')
                line = line[0 .. line.len - 1];
            return line;
        }
    };
}

pub fn lineIterator(rdr: *std.Io.Reader, buffer: []u8) LineIterator(@TypeOf(rdr)) {
    return .{ .buffer = buffer, .reader = rdr };
}
