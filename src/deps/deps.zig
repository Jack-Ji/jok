const bos = @import("build_options");

pub const stb = @import("stb/stb.zig");
pub const imgui = @import("imgui/imgui.zig");
pub const zmath = @import("zmath");
pub const zmesh = @import("zmesh");
pub const znoise = @import("znoise");

pub const chipmunk = if (bos.use_chipmunk)
    @import("chipmunk/chipmunk.zig")
else
    null;

pub const nfd = if (bos.use_nfd)
    @import("nfd/nfd.zig")
else
    null;

pub const zaudio = if (bos.use_zaudio)
    @import("zaudio")
else
    null;

pub const zphysics = if (bos.use_zphysics)
    @import("zphysics")
else
    null;

pub const ztracy = if (bos.use_ztracy)
    @import("ztracy")
else
    null;
