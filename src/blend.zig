const jok = @import("jok.zig");
const sdl = jok.sdl;

pub const BlendMode = enum {
    // no blending
    // dstRGBA = srcRGBA
    none,

    // alpha blending
    // dstRGB = (srcRGB * srcA) + (dstRGB * (1-srcA))
    // dstA = srcA + (dstA * (1-srcA))
    blend,

    // additive blending
    // dstRGB = (srcRGB * srcA) + dstRGB
    // dstA = dstA
    additive,

    // color modulate
    // dstRGB = srcRGB * dstRGB
    // dstA = dstA
    modulate,

    // color multiply
    // dstRGB = (srcRGB * dstRGB) + (dstRGB * (1-srcA))
    // dstA = dstA
    multiply,

    //------------------------------------------------------------------------------
    // Porter Duff compositing, might not supported on certain platform
    // https://ssp.impulsetrain.com/porterduff.html
    //------------------------------------------------------------------------------
    pd_src,
    pd_src_atop,
    pd_src_over,
    pd_src_in,
    pd_src_out,
    pd_dst,
    pd_dst_atop,
    pd_dst_over,
    pd_dst_in,
    pd_dst_out,
    pd_xor,
    pd_lighter,
    pd_clear,

    var _init: bool = false;
    var _pd_src: c_uint = undefined;
    var _pd_src_atop: c_uint = undefined;
    var _pd_src_over: c_uint = undefined;
    var _pd_src_in: c_uint = undefined;
    var _pd_src_out: c_uint = undefined;
    var _pd_dst: c_uint = undefined;
    var _pd_dst_atop: c_uint = undefined;
    var _pd_dst_over: c_uint = undefined;
    var _pd_dst_in: c_uint = undefined;
    var _pd_dst_out: c_uint = undefined;
    var _pd_xor: c_uint = undefined;
    var _pd_lighter: c_uint = undefined;
    var _pd_clear: c_uint = undefined;

    inline fn init() void {
        _pd_src = sdl.SDL_ComposeCustomBlendMode(
            sdl.SDL_BLENDFACTOR_ONE,
            sdl.SDL_BLENDFACTOR_ZERO,
            sdl.SDL_BLENDOPERATION_ADD,
            sdl.SDL_BLENDFACTOR_ONE,
            sdl.SDL_BLENDFACTOR_ZERO,
            sdl.SDL_BLENDOPERATION_ADD,
        );
        _pd_src_atop = sdl.SDL_ComposeCustomBlendMode(
            sdl.SDL_BLENDFACTOR_DST_ALPHA,
            sdl.SDL_BLENDFACTOR_ONE_MINUS_SRC_ALPHA,
            sdl.SDL_BLENDOPERATION_ADD,
            sdl.SDL_BLENDFACTOR_DST_ALPHA,
            sdl.SDL_BLENDFACTOR_ONE_MINUS_SRC_ALPHA,
            sdl.SDL_BLENDOPERATION_ADD,
        );
        _pd_src_over = sdl.SDL_ComposeCustomBlendMode(
            sdl.SDL_BLENDFACTOR_ONE,
            sdl.SDL_BLENDFACTOR_ONE_MINUS_SRC_ALPHA,
            sdl.SDL_BLENDOPERATION_ADD,
            sdl.SDL_BLENDFACTOR_ONE,
            sdl.SDL_BLENDFACTOR_ONE_MINUS_SRC_ALPHA,
            sdl.SDL_BLENDOPERATION_ADD,
        );
        _pd_src_in = sdl.SDL_ComposeCustomBlendMode(
            sdl.SDL_BLENDFACTOR_DST_ALPHA,
            sdl.SDL_BLENDFACTOR_ZERO,
            sdl.SDL_BLENDOPERATION_ADD,
            sdl.SDL_BLENDFACTOR_DST_ALPHA,
            sdl.SDL_BLENDFACTOR_ZERO,
            sdl.SDL_BLENDOPERATION_ADD,
        );
        _pd_src_out = sdl.SDL_ComposeCustomBlendMode(
            sdl.SDL_BLENDFACTOR_ONE_MINUS_DST_ALPHA,
            sdl.SDL_BLENDFACTOR_ZERO,
            sdl.SDL_BLENDOPERATION_ADD,
            sdl.SDL_BLENDFACTOR_ONE_MINUS_DST_ALPHA,
            sdl.SDL_BLENDFACTOR_ZERO,
            sdl.SDL_BLENDOPERATION_ADD,
        );
        _pd_dst = sdl.SDL_ComposeCustomBlendMode(
            sdl.SDL_BLENDFACTOR_ZERO,
            sdl.SDL_BLENDFACTOR_ONE,
            sdl.SDL_BLENDOPERATION_ADD,
            sdl.SDL_BLENDFACTOR_ZERO,
            sdl.SDL_BLENDFACTOR_ONE,
            sdl.SDL_BLENDOPERATION_ADD,
        );
        _pd_dst_atop = sdl.SDL_ComposeCustomBlendMode(
            sdl.SDL_BLENDFACTOR_ONE_MINUS_DST_ALPHA,
            sdl.SDL_BLENDFACTOR_SRC_ALPHA,
            sdl.SDL_BLENDOPERATION_ADD,
            sdl.SDL_BLENDFACTOR_ONE_MINUS_DST_ALPHA,
            sdl.SDL_BLENDFACTOR_SRC_ALPHA,
            sdl.SDL_BLENDOPERATION_ADD,
        );
        _pd_dst_over = sdl.SDL_ComposeCustomBlendMode(
            sdl.SDL_BLENDFACTOR_ONE_MINUS_DST_ALPHA,
            sdl.SDL_BLENDFACTOR_ONE,
            sdl.SDL_BLENDOPERATION_ADD,
            sdl.SDL_BLENDFACTOR_ONE_MINUS_DST_ALPHA,
            sdl.SDL_BLENDFACTOR_ONE,
            sdl.SDL_BLENDOPERATION_ADD,
        );
        _pd_dst_in = sdl.SDL_ComposeCustomBlendMode(
            sdl.SDL_BLENDFACTOR_ZERO,
            sdl.SDL_BLENDFACTOR_SRC_ALPHA,
            sdl.SDL_BLENDOPERATION_ADD,
            sdl.SDL_BLENDFACTOR_ZERO,
            sdl.SDL_BLENDFACTOR_SRC_ALPHA,
            sdl.SDL_BLENDOPERATION_ADD,
        );
        _pd_dst_out = sdl.SDL_ComposeCustomBlendMode(
            sdl.SDL_BLENDFACTOR_ZERO,
            sdl.SDL_BLENDFACTOR_ONE_MINUS_SRC_ALPHA,
            sdl.SDL_BLENDOPERATION_ADD,
            sdl.SDL_BLENDFACTOR_ZERO,
            sdl.SDL_BLENDFACTOR_ONE_MINUS_SRC_ALPHA,
            sdl.SDL_BLENDOPERATION_ADD,
        );
        _pd_xor = sdl.SDL_ComposeCustomBlendMode(
            sdl.SDL_BLENDFACTOR_ONE_MINUS_DST_ALPHA,
            sdl.SDL_BLENDFACTOR_ONE_MINUS_SRC_ALPHA,
            sdl.SDL_BLENDOPERATION_ADD,
            sdl.SDL_BLENDFACTOR_ONE_MINUS_DST_ALPHA,
            sdl.SDL_BLENDFACTOR_ONE_MINUS_SRC_ALPHA,
            sdl.SDL_BLENDOPERATION_ADD,
        );
        _pd_lighter = sdl.SDL_ComposeCustomBlendMode(
            sdl.SDL_BLENDFACTOR_ONE,
            sdl.SDL_BLENDFACTOR_ONE,
            sdl.SDL_BLENDOPERATION_ADD,
            sdl.SDL_BLENDFACTOR_ONE,
            sdl.SDL_BLENDFACTOR_ONE,
            sdl.SDL_BLENDOPERATION_ADD,
        );
        _pd_clear = sdl.SDL_ComposeCustomBlendMode(
            sdl.SDL_BLENDFACTOR_ZERO,
            sdl.SDL_BLENDFACTOR_ZERO,
            sdl.SDL_BLENDOPERATION_ADD,
            sdl.SDL_BLENDFACTOR_ZERO,
            sdl.SDL_BLENDFACTOR_ZERO,
            sdl.SDL_BLENDOPERATION_ADD,
        );
    }

    pub fn fromNative(mode: sdl.SDL_BlendMode) @This() {
        if (!_init) {
            init();
            _init = true;
        }
        switch (mode) {
            sdl.SDL_BLENDMODE_NONE => return .none,
            sdl.SDL_BLENDMODE_BLEND => return .blend,
            sdl.SDL_BLENDMODE_ADD => return .additive,
            sdl.SDL_BLENDMODE_MOD => return .modulate,
            sdl.SDL_BLENDMODE_MUL => return .multiply,
            else => {
                if (mode == _pd_src) return .pd_src;
                if (mode == _pd_src_atop) return .pd_src_atop;
                if (mode == _pd_src_over) return .pd_src_over;
                if (mode == _pd_src_in) return .pd_src_in;
                if (mode == _pd_src_out) return .pd_src_out;
                if (mode == _pd_dst) return .pd_dst;
                if (mode == _pd_dst_atop) return .pd_dst_atop;
                if (mode == _pd_dst_over) return .pd_dst_over;
                if (mode == _pd_dst_in) return .pd_dst_in;
                if (mode == _pd_dst_out) return .pd_dst_out;
                if (mode == _pd_xor) return .pd_xor;
                if (mode == _pd_lighter) return .pd_lighter;
                if (mode == _pd_clear) return .pd_clear;
                @panic("unreachable");
            },
        }
    }

    pub fn toNative(self: @This()) c_uint {
        if (!_init) {
            init();
            _init = true;
        }
        return switch (self) {
            .none => sdl.SDL_BLENDMODE_NONE,
            .blend => sdl.SDL_BLENDMODE_BLEND,
            .additive => sdl.SDL_BLENDMODE_ADD,
            .modulate => sdl.SDL_BLENDMODE_MOD,
            .multiply => sdl.SDL_BLENDMODE_MUL,
            .pd_src => _pd_src,
            .pd_src_atop => _pd_src_atop,
            .pd_src_over => _pd_src_over,
            .pd_src_in => _pd_src_in,
            .pd_src_out => _pd_src_out,
            .pd_dst => _pd_dst,
            .pd_dst_atop => _pd_dst_atop,
            .pd_dst_over => _pd_dst_over,
            .pd_dst_in => _pd_dst_in,
            .pd_dst_out => _pd_dst_out,
            .pd_xor => _pd_xor,
            .pd_lighter => _pd_lighter,
            .pd_clear => _pd_clear,
        };
    }
};
