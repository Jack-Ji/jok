const bos = @import("build_options");

pub const sdl = @import("vendor/sdl/main.zig");
pub const physfs = @import("vendor/physfs/main.zig");
pub const zaudio = if (bos.no_audio)
    .{ .Engine = struct {}, .Context = struct {} }
else
    @import("vendor/zaudio/main.zig");
pub const zmath = @import("vendor/zmath/main.zig");
pub const zmesh = @import("vendor/zmesh/main.zig");
pub const znoise = @import("vendor/znoise/main.zig");
pub const zobj = @import("vendor/zobj/main.zig");
pub const imgui = @import("vendor/imgui/main.zig");
pub const stb = @import("vendor/stb/main.zig");
pub const svg = @import("vendor/svg/main.zig");
pub const nfd = if (bos.use_nfd) @import("vendor/nfd/main.zig") else null;
