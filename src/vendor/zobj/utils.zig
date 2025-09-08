const std = @import("std");

pub fn LineIterator(comptime Reader: type) type {
    return struct {
        buffer: []u8,
        reader: Reader,

        pub fn next(self: *@This()) !?[]const u8 {
            var writer = std.Io.Writer.fixed(self.buffer);
            const size = self.reader.streamDelimiterEnding(&writer, '\n') catch |err| {
                if (err == error.EndOfStream) return null;
                return err;
            };
            if (size == 0) return null;
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
