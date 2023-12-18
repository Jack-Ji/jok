const bos = @import("build_options");

pub const sdl = @import("sdl");
pub const imgui = @import("imgui/imgui.zig");
pub const stb = @import("stb/stb.zig");
pub const svg = @import("svg/svg.zig");
pub const zaudio = @import("zaudio");
pub const zmath = @import("zmath");
pub const zmesh = @import("zmesh");
pub const znoise = @import("znoise");

pub const cp = if (bos.use_cp)
    @import("chipmunk/chipmunk.zig")
else
    null;

pub const nfd = if (bos.use_nfd)
    @import("nfd/nfd.zig")
else
    null;

pub const ztracy = if (bos.use_ztracy)
    @import("ztracy")
else
    null;
