const std = @import("std");

const LineIterator = struct {
    buffer: []u8,
    reader: *std.Io.Reader,

    pub fn next(self: *@This()) !?[]const u8 {
        if (try self.reader.takeDelimiter('\n')) |line| {
            return if (0 < line.len and line[line.len - 1] == '\r')
                line[0 .. line.len - 1]
            else
                line;
        }
        return null;
    }
};

pub fn lineIterator(rdr: *std.Io.Reader, buffer: []u8) LineIterator {
    return .{ .buffer = buffer, .reader = rdr };
}
