const bos = @import("build_options");

pub const sdl = @import("sdl");
pub const stb = @import("stb/stb.zig");
pub const imgui = @import("imgui/imgui.zig");
pub const zmath = @import("zmath");
pub const zmesh = @import("zmesh");
pub const znoise = @import("znoise");
pub const zpool = @import("zpool");
pub const ztracy = @import("ztracy");

pub const nfd = if (bos.use_nfd)
    @import("nfd/nfd.zig")
else
    null;

pub const zaudio = if (bos.use_zaudio)
    @import("zaudio")
else
    null;
