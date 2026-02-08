const std = @import("std");
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;
const copyForwards = std.mem.copyForwards;

pub fn Ring(comptime T: type) type {
    return struct {
        const RingType = @This();

        data: []T,
        read_index: usize,
        write_index: usize,

        pub const Error = error{ Full, ReadLengthInvalid };

        /// Allocate a new `RingType`; `deinit()` should be called to free the buffer.
        pub fn init(allocator: Allocator, capacity: usize) Allocator.Error!RingType {
            const data = try allocator.alloc(T, capacity);
            return RingType{
                .data = data,
                .write_index = 0,
                .read_index = 0,
            };
        }

        /// Free the data backing a `RingType`; must be passed the same `Allocator` as
        /// `init()`.
        pub fn deinit(self: *RingType, allocator: Allocator) void {
            allocator.free(self.data);
            self.* = undefined;
        }

        /// Returns `index` modulo the length of the backing slice.
        pub fn mask(self: RingType, index: usize) usize {
            return index % self.data.len;
        }

        /// Returns `index` modulo twice the length of the backing slice.
        pub fn mask2(self: RingType, index: usize) usize {
            return index % (2 * self.data.len);
        }

        /// Write `data` into the ring buffer. Returns `error.Full` if the ring
        /// buffer is full.
        pub fn write(self: *RingType, data: T) Error!void {
            if (self.isFull()) return error.Full;
            self.writeAssumeCapacity(data);
        }

        /// Write `data` into the ring buffer. If the ring buffer is full, the
        /// oldest data is overwritten.
        pub fn writeAssumeCapacity(self: *RingType, data: T) void {
            if (self.isFull()) {
                self.read_index = self.mask2(self.read_index + 1);
            }
            self.data[self.mask(self.write_index)] = data;
            self.write_index = self.mask2(self.write_index + 1);
        }

        /// Write `data` into the ring buffer. Returns `error.Full` if the ring
        /// buffer does not have enough space, without writing any data.
        /// Uses memcpy and so `data` must not overlap ring buffer data.
        pub fn writeSlice(self: *RingType, data: []const T) Error!void {
            if (self.len() + data.len > self.data.len) return error.Full;
            self.writeSliceAssumeCapacity(data);
        }

        /// Write `data` into the ring buffer. If there is not enough space, older
        /// data will be overwritten.
        /// Uses memcpy and so `data` must not overlap ring buffer data.
        pub fn writeSliceAssumeCapacity(self: *RingType, data: []const T) void {
            const old_length = self.len();
            const data_start = self.mask(self.write_index);
            const part1_data_end = @min(data_start + data.len, self.data.len);
            const part1_len = part1_data_end - data_start;
            @memcpy(self.data[data_start..part1_data_end], data[0..part1_len]);

            const remaining = data.len - part1_len;
            const to_write = @min(remaining, remaining % self.data.len + self.data.len);
            const part2_data_start = data.len - to_write;
            const part2_data_end = @min(part2_data_start + self.data.len, data.len);
            const part2_len = part2_data_end - part2_data_start;
            @memcpy(self.data[0..part2_len], data[part2_data_start..part2_data_end]);
            if (part2_data_end != data.len) {
                const part3_len = data.len - part2_data_end;
                @memcpy(self.data[0..part3_len], data[part2_data_end..data.len]);
            }
            self.write_index = self.mask2(self.write_index + data.len);

            if (old_length + data.len > self.data.len) {
                self.read_index = self.mask2(self.read_index + old_length + data.len - self.data.len);
            }
        }

        /// Write `data` into the ring buffer. Returns `error.Full` if the ring
        /// buffer does not have enough space, without writing any data.
        /// Uses copyForwards and can write slices from this RingType into itself.
        pub fn writeSliceForwards(self: *RingType, data: []const T) Error!void {
            if (self.len() + data.len > self.data.len) return error.Full;
            self.writeSliceForwardsAssumeCapacity(data);
        }

        /// Write `data` into the ring buffer. If there is not enough space, older
        /// data will be overwritten.
        /// Uses copyForwards and can write slices from this RingType into itself.
        pub fn writeSliceForwardsAssumeCapacity(self: *RingType, data: []const T) void {
            const old_length = self.len();
            const data_start = self.mask(self.write_index);
            const part1_data_end = @min(data_start + data.len, self.data.len);
            const part1_len = part1_data_end - data_start;
            copyForwards(T, self.data[data_start..], data[0..part1_len]);

            const remaining = data.len - part1_len;
            const to_write = @min(remaining, remaining % self.data.len + self.data.len);
            const part2_data_start = data.len - to_write;
            const part2_data_end = @min(part2_data_start + self.data.len, data.len);
            copyForwards(T, self.data[0..], data[part2_data_start..part2_data_end]);
            if (part2_data_end != data.len)
                copyForwards(T, self.data[0..], data[part2_data_end..data.len]);
            self.write_index = self.mask2(self.write_index + data.len);

            if (old_length + data.len > self.data.len) {
                self.read_index = self.mask2(self.read_index + old_length + data.len - self.data.len);
            }
        }

        /// Consume a data from the ring buffer and return it. Returns `null` if the
        /// ring buffer is empty.
        pub fn read(self: *RingType) ?T {
            if (self.isEmpty()) return null;
            return self.readAssumeLength();
        }

        /// Consume a data from the ring buffer and return it; asserts that the buffer
        /// is not empty.
        pub fn readAssumeLength(self: *RingType) T {
            assert(!self.isEmpty());
            const data = self.data[self.mask(self.read_index)];
            self.read_index = self.mask2(self.read_index + 1);
            return data;
        }

        /// Reads first `length` data written to the ring buffer into `dest`; Returns
        /// Error.ReadLengthInvalid if length greater than ring or dest length
        /// Uses memcpy and so `dest` must not overlap ring buffer data.
        pub fn readFirst(self: *RingType, dest: []T, length: usize) Error!void {
            if (length > self.len() or length > dest.len) return error.ReadLengthInvalid;
            self.readFirstAssumeLength(dest, length);
        }

        /// Reads first `length` data written to the ring buffer into `dest`;
        /// Asserts that length not greater than ring buffer or dest length
        /// Uses memcpy and so `dest` must not overlap ring buffer data.
        pub fn readFirstAssumeLength(self: *RingType, dest: []T, length: usize) void {
            assert(length <= self.len() and length <= dest.len);
            const data_start = self.mask(self.read_index);
            const part1_data_end = @min(self.data.len, data_start + length);
            const part1_len = part1_data_end - data_start;
            const part2_len = length - part1_len;
            @memcpy(dest[0..part1_len], self.data[data_start..part1_data_end]);
            @memcpy(dest[part1_len..length], self.data[0..part2_len]);
            self.read_index = self.mask2(self.read_index + length);
        }

        /// Reads last `length` data written to the ring buffer into `dest`; Returns
        /// Error.ReadLengthInvalid if length greater than ring or dest length
        /// Uses memcpy and so `dest` must not overlap ring buffer data.
        pub fn readLast(self: *RingType, dest: []T, length: usize) Error!void {
            if (length > self.len() or length > dest.len) return error.ReadLengthInvalid;
            self.readLastAssumeLength(dest, length);
        }

        /// Reads last `length` data written to the ring buffer into `dest`;
        /// Asserts that length not greater than ring buffer or dest length
        /// Uses memcpy and so `dest` must not overlap ring buffer data.
        pub fn readLastAssumeLength(self: *RingType, dest: []T, length: usize) void {
            assert(length <= self.len() and length <= dest.len);
            const data_start = self.mask(self.write_index + self.data.len - length);
            const part1_data_end = @min(self.data.len, data_start + length);
            const part1_len = part1_data_end - data_start;
            const part2_len = length - part1_len;
            @memcpy(dest[0..part1_len], self.data[data_start..part1_data_end]);
            @memcpy(dest[part1_len..length], self.data[0..part2_len]);
            self.write_index = self.mask2(self.write_index + 2 * self.data.len - length);
        }

        /// Returns `true` if the ring buffer is empty and `false` otherwise.
        pub fn isEmpty(self: RingType) bool {
            return self.write_index == self.read_index;
        }

        /// Returns `true` if the ring buffer is full and `false` otherwise.
        pub fn isFull(self: RingType) bool {
            return self.mask2(self.write_index + self.data.len) == self.read_index;
        }

        /// Returns the length
        pub fn len(self: RingType) usize {
            const wrap_offset = 2 * self.data.len * @intFromBool(self.write_index < self.read_index);
            const adjusted_write_index = self.write_index + wrap_offset;

            return adjusted_write_index - self.read_index;
        }

        /// A `Slice` represents a region of a ring buffer. The region is split into two
        /// sections as the ring buffer data will not be contiguous if the desired
        /// region wraps to the start of the backing slice.
        pub const Slice = struct {
            first: []T,
            second: []T,
        };

        /// Returns a `Slice` for the region of the ring buffer starting at
        /// `self.mask(start_unmasked)` with the specified length.
        pub fn sliceAt(self: RingType, start_unmasked: usize, length: usize) Slice {
            assert(length <= self.data.len);
            const slice1_start = self.mask(start_unmasked);
            const slice1_end = @min(self.data.len, slice1_start + length);
            const slice1 = self.data[slice1_start..slice1_end];
            const slice2 = self.data[0 .. length - slice1.len];
            return Slice{
                .first = slice1,
                .second = slice2,
            };
        }

        /// Returns a `Slice` for the last `length` data written to the ring buffer.
        /// Does not check that any data have been written into the region.
        pub fn sliceLast(self: RingType, length: usize) Slice {
            return self.sliceAt(self.write_index + self.data.len - length, length);
        }
    };
}

test "ring: readLastAssumeLength maintains length with wraparound write_index" {
    const testing = std.testing;
    const allocator = testing.allocator;

    var ring = try Ring(u8).init(allocator, 8);
    defer ring.deinit(allocator);

    // Fill buffer to capacity.
    var i: u8 = 0;
    while (i < 8) : (i += 1) {
        ring.writeAssumeCapacity(i);
    }

    // Advance read index a bit.
    _ = ring.readAssumeLength();
    _ = ring.readAssumeLength();
    _ = ring.readAssumeLength();

    // Write more data to move write_index into the second half.
    ring.writeAssumeCapacity(8);
    ring.writeAssumeCapacity(9);
    ring.writeAssumeCapacity(10);

    // Consume data to push read_index into the second half.
    _ = ring.readAssumeLength();
    _ = ring.readAssumeLength();
    _ = ring.readAssumeLength();
    _ = ring.readAssumeLength();
    _ = ring.readAssumeLength();
    _ = ring.readAssumeLength();

    // Write enough to wrap write_index into the first half.
    ring.writeAssumeCapacity(11);
    ring.writeAssumeCapacity(12);
    ring.writeAssumeCapacity(13);
    ring.writeAssumeCapacity(14);
    ring.writeAssumeCapacity(15);
    ring.writeAssumeCapacity(16);

    // Sanity: buffer is full before removing from the end.
    try testing.expectEqual(@as(usize, 8), ring.len());

    // Remove last 2 items and ensure length decreases correctly.
    var tmp: [2]u8 = undefined;
    ring.readLastAssumeLength(&tmp, 2);
    try testing.expectEqual(@as(usize, 6), ring.len());
}
