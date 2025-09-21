const bos = @import("build_options");

pub const Error = error{
    SdlError,
};
pub const sdl = @cImport({
    @cDefine("SDL_DISABLE_OLD_NAMES", {});
    @cInclude("SDL3/SDL.h");
    @cInclude("SDL3/SDL_revision.h");
});
pub const physfs = @import("vendor/physfs/main.zig");
pub const zaudio = @import("vendor/zaudio/main.zig");
pub const zmath = @import("vendor/zmath/main.zig");
pub const zmesh = @import("vendor/zmesh/main.zig");
pub const znoise = @import("vendor/znoise/main.zig");
pub const zobj = @import("vendor/zobj/main.zig");
pub const imgui = @import("vendor/imgui/main.zig");
pub const stb = @import("vendor/stb/main.zig");
pub const svg = @import("vendor/svg/main.zig");
