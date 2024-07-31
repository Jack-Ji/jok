const bos = @import("build_options");

pub const sdl = @import("sdl");
pub const zaudio = @import("zaudio");
pub const zmath = @import("zmath");
pub const zmesh = @import("zmesh");
pub const znoise = @import("znoise");
pub const ztracy = if (bos.use_ztracy)
    @import("ztracy")
else
    null;

pub const imgui = @import("vendor/imgui/imgui.zig");
pub const stb = @import("vendor/stb/stb.zig");
pub const svg = @import("vendor/svg/svg.zig");
pub const cp = if (bos.use_cp)
    @import("vendor/chipmunk//chipmunk.zig")
else
    null;
pub const nfd = if (bos.use_nfd)
    @import("vendor/nfd/nfd.zig")
else
    null;
