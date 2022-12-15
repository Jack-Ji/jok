const bos = @import("build_options");

pub const stb = @import("stb/stb.zig");
pub const zmath = @import("zmath/src/zmath.zig");
pub const zpool = @import("zpool/src/main.zig");
pub const zjobs = @import("zjobs/src/zjobs.zig");
pub const zmesh = @import("zmesh/src/main.zig");
pub const znoise = @import("znoise/src/znoise.zig");
pub const znetwork = @import("znetwork/src/main.zig");

pub const imgui = if (bos.use_imgui)
    @import("imgui/imgui.zig")
else
    null;

pub const chipmunk = if (bos.use_chipmunk)
    @import("chipmunk/chipmunk.zig")
else
    null;

pub const nfd = if (bos.use_nfd)
    @import("nfd/nfd.zig")
else
    null;

pub const zaudio = if (bos.use_zaudio)
    @import("zaudio/src/zaudio.zig")
else
    null;

pub const zphysics = if (bos.use_zphysics)
    @import("zphysics/src/zphysics.zig")
else
    null;

pub const ztracy = if (bos.use_ztracy)
    @import("ztracy/src/ztracy.zig")
else
    null;
