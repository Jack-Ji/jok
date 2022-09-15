const std = @import("std");
const assert = std.debug.assert;
const c = @import("c.zig");
const log = std.log.scoped(.nfd);

pub const Error = error{
    NfdError,
};

fn makeError() Error {
    if (c.NFD_GetError()) |ptr| {
        log.debug("{s}\n", .{std.mem.span(ptr)});
    }
    return error.NfdError;
}

/// path to single file
pub const FilePath = struct {
    path: [:0]const u8,

    const Self = @This();

    pub fn deinit(self: Self) void {
        std.c.free(@intToPtr(*anyopaque, @ptrToInt(self.path.ptr)));
    }
};

/// open single file dialog
pub fn openFileDialog(
    filter: ?[:0]const u8,
    default_path: ?[:0]const u8,
) Error!?FilePath {
    var out_path: [*c]u8 = null;

    const result = c.NFD_OpenDialog(
        if (filter) |f| f.ptr else null,
        if (default_path) |p| p.ptr else null,
        &out_path,
    );

    return switch (result) {
        c.NFD_OKAY => if (out_path == null)
            null
        else
            FilePath{ .path = std.mem.sliceTo(out_path, 0) },
        c.NFD_ERROR => makeError(),
        else => null,
    };
}

/// open save dialog
pub fn saveFileDialog(
    filter: ?[:0]const u8,
    default_path: ?[:0]const u8,
) Error!?FilePath {
    var out_path: [*c]u8 = null;

    const result = c.NFD_SaveDialog(
        if (filter) |f| f.ptr else null,
        if (default_path) |p| p.ptr else null,
        &out_path,
    );

    return switch (result) {
        c.NFD_OKAY => if (out_path == null)
            null
        else
            FilePath{ .path = std.mem.sliceTo(out_path, 0) },
        c.NFD_ERROR => makeError(),
        else => null,
    };
}

/// path to multiple files
pub const MultipleFilePath = struct {
    pathset: c.nfdpathset_t,

    const Self = @This();

    pub fn deinit(self: Self) void {
        c.NFD_PathSet_Free(&self.pathset);
    }

    pub fn getCount(self: Self) u32 {
        return @intCast(u32, self.pathset.count);
    }

    pub fn getPath(self: Self, index: u32) [:0]const u8 {
        assert(index < self.getCount());
        return std.mem.sliceTo(c.NFD_PathSet_GetPath(&self.pathset, index), 0);
    }
};

/// open multiple file dialog
pub fn openMultipleFileDialog(
    filter: ?[:0]const u8,
    default_path: ?[:0]const u8,
) Error!?MultipleFilePath {
    var out_pathset: c.nfdpathset_t = undefined;

    const result = c.NFD_OpenDialogMultiple(
        if (filter) |f| f.ptr else null,
        if (default_path) |p| p.ptr else null,
        &out_pathset,
    );

    return switch (result) {
        c.NFD_OKAY => MultipleFilePath{ .pathset = out_pathset },
        c.NFD_ERROR => makeError(),
        else => null,
    };
}

/// select directory
pub fn openDirectoryDialog(default_path: ?[:0]const u8) Error!?FilePath {
    var out_path: [*c]u8 = null;

    const result = c.NFD_PickFolder(
        if (default_path) |p| p.ptr else null,
        &out_path,
    );

    return switch (result) {
        c.NFD_OKAY => if (out_path == null)
            null
        else
            FilePath{ .path = std.mem.sliceTo(out_path, 0) },
        c.NFD_ERROR => makeError(),
        else => null,
    };
}
