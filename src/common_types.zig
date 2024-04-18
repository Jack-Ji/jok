const jok = @import("jok.zig");
const sdl = jok.sdl;

pub const BlendMethod = enum {
    // alpha blending
    // dstRGB = (srcRGB * srcA) + (dstRGB * (1-srcA))
    // dstA = srcA + (dstA * (1-srcA))
    blend,

    // additive blending
    // dstRGB = (srcRGB * srcA) + dstRGB
    // dstA = dstA
    additive,

    // no blending
    // dstRGBA = srcRGBA
    overwrite,

    // color modulate
    // dstRGB = srcRGB * dstRGB
    // dstA = dstA
    modulate,

    // color multiply
    // dstRGB = (srcRGB * dstRGB) + (dstRGB * (1-srcA))
    // dstA = dstA
    multiply,

    pub fn toMode(self: @This()) c_uint {
        return switch (self) {
            .blend => sdl.c.SDL_BLENDMODE_BLEND,
            .additive => sdl.c.SDL_BLENDMODE_ADD,
            .overwrite => sdl.c.SDL_BLENDMODE_NONE,
            .modulate => sdl.c.SDL_BLENDMODE_MOD,
            .multiply => sdl.c.SDL_BLENDMODE_MUL,
        };
    }
};
