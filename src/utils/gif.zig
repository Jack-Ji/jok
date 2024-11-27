/// Graphics Interchange Format
/// https://www.w3.org/Graphics/GIF/spec-gif89a.txt
const std = @import("std");
const assert = std.debug.assert;
const jok = @import("../jok.zig");
const j2d = jok.j2d;
const physfs = jok.physfs;
const log = std.log.scoped(.jok);
