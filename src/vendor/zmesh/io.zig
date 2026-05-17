const std = @import("std");
const assert = std.debug.assert;

/// Deprecated. Use `zmesh.io.zcgltf.parseAndLoadFile` instead.
pub const parseAndLoadFile = zcgltf.parseAndLoadFile;
/// Deprecated. Use `zmesh.io.zcgltf.freeData` instead.
pub const freeData = zcgltf.freeData;
/// Deprecated. Use `zmesh.io.zcgltf.appendMeshPrimitive` instead.
pub const appendMeshPrimitive = zcgltf.appendMeshPrimitive;

pub const zcgltf = @import("zcgltf.zig");
