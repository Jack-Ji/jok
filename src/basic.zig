//! This module provides common definitions used throughout the engine:
//! - Color: 8-bit RGBA color
//! - ColorF: Floating-point RGBA color
//! - BlendMode: Blend mode for graphics rendering operations
//! - Vertex: Vertex with position, color, and texture coordinates

const std = @import("std");
const assert = std.debug.assert;
const jok = @import("jok.zig");
const geom = jok.geom;
const sdl = jok.vendor.sdl;
const zmath = jok.vendor.zmath;

/// 8-bit RGBA color type.
/// Values range from 0-255 for each component. Alpha defaults to 255 (fully opaque).
/// Provides conversion to/from various color formats including HSL, RGBA32, and ColorF.
pub const Color = extern struct {
    /// Transparent black (0, 0, 0, 0)
    pub const none = rgba(0x00, 0x00, 0x00, 0x00);
    /// Opaque black
    pub const black = rgb(0x00, 0x00, 0x00);
    /// Opaque white
    pub const white = rgb(0xFF, 0xFF, 0xFF);
    /// Opaque red
    pub const red = rgb(0xFF, 0x00, 0x00);
    /// Opaque green
    pub const green = rgb(0x00, 0xFF, 0x00);
    /// Opaque blue
    pub const blue = rgb(0x00, 0x00, 0xFF);
    /// Opaque magenta
    pub const magenta = rgb(0xFF, 0x00, 0xFF);
    /// Opaque cyan
    pub const cyan = rgb(0x00, 0xFF, 0xFF);
    /// Opaque yellow
    pub const yellow = rgb(0xFF, 0xFF, 0x00);
    /// Opaque purple
    pub const purple = rgb(255, 128, 255);

    r: u8,
    g: u8,
    b: u8,
    a: u8 = 255,

    /// Create opaque color from RGB components (0-255)
    pub inline fn rgb(r: u8, g: u8, b: u8) Color {
        assert(r <= 255 and g <= 255 and b <= 255);
        return Color{ .r = r, .g = g, .b = b };
    }

    /// Create color from RGBA components (0-255)
    pub inline fn rgba(r: u8, g: u8, b: u8, a: u8) Color {
        assert(r <= 255 and g <= 255 and b <= 255 and a <= 255);
        return Color{ .r = r, .g = g, .b = b, .a = a };
    }

    /// Convert from floating-point color (0.0-1.0 range)
    pub inline fn fromColorF(_c: ColorF) Color {
        var c: @Vector(4, f32) = .{ _c.r, _c.g, _c.b, _c.a };
        const multiplier: @Vector(4, f32) = @splat(255.0);
        c *= multiplier;
        return Color{
            .r = @intFromFloat(c[0]),
            .g = @intFromFloat(c[1]),
            .b = @intFromFloat(c[2]),
            .a = @intFromFloat(c[3]),
        };
    }

    /// Convert to floating-point color (0.0-1.0 range)
    pub inline fn toColorF(c: Color) ColorF {
        return .{ .r = u8tof32[c.r], .g = u8tof32[c.g], .b = u8tof32[c.b], .a = u8tof32[c.a] };
    }

    inline fn getPixelFormatDetails() [*c]const sdl.SDL_PixelFormatDetails {
        const S = struct {
            var pixel_format: ?[*c]const sdl.SDL_PixelFormatDetails = null;
        };
        if (S.pixel_format == null) {
            S.pixel_format = sdl.SDL_GetPixelFormatDetails(sdl.SDL_PIXELFORMAT_RGBA32);
        }
        return S.pixel_format.?;
    }

    /// Convert from 32-bit RGBA integer format
    pub inline fn fromRGBA32(i: u32) Color {
        var c: Color = undefined;
        sdl.SDL_GetRGBA(i, getPixelFormatDetails(), null, &c.r, &c.g, &c.b, &c.a);
        return c;
    }

    /// Convert to 32-bit RGBA integer format
    pub inline fn toRGBA32(c: Color) u32 {
        return sdl.SDL_MapRGBA(getPixelFormatDetails(), null, c.r, c.g, c.b, c.a);
    }

    /// Convert from HSL color space. Input: [hue (0-1), saturation (0-1), lightness (0-1), alpha (0-1)]
    pub inline fn fromHSL(hsl: [4]f32) Color {
        var c = zmath.hslToRgb(zmath.loadArr4(hsl));
        const multiplier: @Vector(4, f32) = @splat(255.0);
        c *= multiplier;
        return .{
            .r = @intFromFloat(c[0]),
            .g = @intFromFloat(c[1]),
            .b = @intFromFloat(c[2]),
            .a = @intFromFloat(c[3]),
        };
    }

    /// Convert to HSL color space. Output: [hue (0-1), saturation (0-1), lightness (0-1), alpha (0-1)]
    pub inline fn toHSL(c: Color) [4]f32 {
        const hsl = zmath.rgbToHsl(
            zmath.f32x4(u8tof32[c.r], u8tof32[c.g], u8tof32[c.b], u8tof32[c.a]),
        );
        return zmath.vecToArr4(hsl);
    }

    /// Convert from ImGui's internal color format (ABGR packed as u32)
    pub inline fn fromInternalColor(c: u32) Color {
        return .{
            .r = @intCast(c & 0xff),
            .g = @intCast((c >> 8) & 0xff),
            .b = @intCast((c >> 16) & 0xff),
            .a = @intCast((c >> 24) & 0xff),
        };
    }

    /// Convert to ImGui's internal color format (ABGR packed as u32)
    pub inline fn toInternalColor(c: Color) u32 {
        return @as(u32, c.r) |
            (@as(u32, c.g) << 8) |
            (@as(u32, c.b) << 16) |
            (@as(u32, c.a) << 24);
    }

    /// Linear interpolation between two colors. t should be in range [0, 1].
    pub inline fn lerp(c0: Color, c1: Color, t: f32) Color {
        assert(t >= 0 and t <= 1);
        return c0.toColorF().lerp(c1.toColorF(), t).toColor();
    }

    /// Modulate (multiply) two colors component-wise
    pub inline fn mod(c0: Color, c1: Color) Color {
        return c0.toColorF().mod(c1.toColorF()).toColor();
    }

    /// Parse a hex string color literal.
    /// Allowed formats: RGB, RGBA, #RGB, #RGBA, RRGGBB, #RRGGBB, RRGGBBAA, #RRGGBBAA
    /// Examples: "F00" (red), "#FF0000" (red), "FF0000FF" (red with full alpha)
    pub fn parse(str: []const u8) !Color {
        switch (str.len) {
            // RGB
            3 => {
                const r = try std.fmt.parseInt(u8, str[0..1], 16);
                const g = try std.fmt.parseInt(u8, str[1..2], 16);
                const b = try std.fmt.parseInt(u8, str[2..3], 16);

                return rgb(
                    r | (r << 4),
                    g | (g << 4),
                    b | (b << 4),
                );
            },

            // #RGB, RGBA
            4 => {
                if (str[0] == '#')
                    return parse(str[1..]);

                const r = try std.fmt.parseInt(u8, str[0..1], 16);
                const g = try std.fmt.parseInt(u8, str[1..2], 16);
                const b = try std.fmt.parseInt(u8, str[2..3], 16);
                const a = try std.fmt.parseInt(u8, str[3..4], 16);

                // bit-expand the patters to a uniform range
                return rgba(
                    r | (r << 4),
                    g | (g << 4),
                    b | (b << 4),
                    a | (a << 4),
                );
            },

            // #RGBA
            5 => return parse(str[1..]),

            // RRGGBB
            6 => {
                const r = try std.fmt.parseInt(u8, str[0..2], 16);
                const g = try std.fmt.parseInt(u8, str[2..4], 16);
                const b = try std.fmt.parseInt(u8, str[4..6], 16);

                return rgb(r, g, b);
            },

            // #RRGGBB
            7 => return parse(str[1..]),

            // RRGGBBAA
            8 => {
                const r = try std.fmt.parseInt(u8, str[0..2], 16);
                const g = try std.fmt.parseInt(u8, str[2..4], 16);
                const b = try std.fmt.parseInt(u8, str[4..6], 16);
                const a = try std.fmt.parseInt(u8, str[6..8], 16);

                return rgba(r, g, b, a);
            },

            // #RRGGBBAA
            9 => return parse(str[1..]),

            else => return error.UnknownFormat,
        }
    }
};

const u8tof32: [256]f32 = calcU8Table();

fn calcU8Table() [256]f32 {
    var cs: [256]f32 = undefined;
    inline for (0..256) |i| {
        cs[i] = @as(f32, @floatFromInt(i)) / 255.0;
    }
    return cs;
}

/// Floating-point RGBA color type.
/// Values range from 0.0-1.0 for each component. Alpha defaults to 1.0 (fully opaque).
/// Provides higher precision than Color and is used internally for color calculations.
pub const ColorF = extern struct {
    /// Transparent black (0, 0, 0, 0)
    pub const none = rgba(0, 0, 0, 0);
    /// Opaque black
    pub const black = rgb(0, 0, 0);
    /// Opaque white
    pub const white = rgb(1, 1, 1);
    /// Opaque red
    pub const red = rgb(1, 0, 0);
    /// Opaque green
    pub const green = rgb(0, 1, 0);
    /// Opaque blue
    pub const blue = rgb(0, 0, 1);
    /// Opaque magenta
    pub const magenta = rgb(1, 0, 1);
    /// Opaque cyan
    pub const cyan = rgb(0, 1, 1);
    /// Opaque yellow
    pub const yellow = rgb(1, 1, 0);
    /// Opaque purple
    pub const purple = rgb(1, 0.5, 1);

    r: f32,
    g: f32,
    b: f32,
    a: f32 = 1,

    /// Create opaque color from RGB components (0.0-1.0)
    pub inline fn rgb(r: f32, g: f32, b: f32) ColorF {
        assert(r >= 0 and r <= 1);
        assert(g >= 0 and g <= 1);
        assert(b >= 0 and b <= 1);
        return ColorF{ .r = r, .g = g, .b = b };
    }

    /// Create color from RGBA components (0.0-1.0)
    pub inline fn rgba(r: f32, g: f32, b: f32, a: f32) ColorF {
        assert(r >= 0 and r <= 1);
        assert(g >= 0 and g <= 1);
        assert(b >= 0 and b <= 1);
        assert(a >= 0 and a <= 1);
        return ColorF{ .r = r, .g = g, .b = b, .a = a };
    }

    /// Convert from 8-bit color (0-255 range)
    pub inline fn fromColor(c: Color) ColorF {
        return ColorF{ .r = u8tof32[c.r], .g = u8tof32[c.g], .b = u8tof32[c.b], .a = u8tof32[c.a] };
    }

    /// Convert to 8-bit color (0-255 range)
    pub inline fn toColor(_c: ColorF) Color {
        var c: @Vector(4, f32) = .{ _c.r, _c.g, _c.b, _c.a };
        const multiplier: @Vector(4, f32) = @splat(255.0);
        c *= multiplier;
        return .{
            .r = @intFromFloat(c[0]),
            .g = @intFromFloat(c[1]),
            .b = @intFromFloat(c[2]),
            .a = @intFromFloat(c[3]),
        };
    }

    /// Convert from 32-bit RGBA integer format
    pub inline fn fromRGBA32(i: u32) ColorF {
        return fromColor(Color.fromRGBA32(i));
    }

    /// Convert to 32-bit RGBA integer format
    pub inline fn toRGBA32(c: ColorF) u32 {
        return c.toColor().toRGBA32();
    }

    /// Convert from HSL color space. Input: [hue (0-1), saturation (0-1), lightness (0-1), alpha (0-1)]
    pub inline fn fromHSL(hsl: [4]f32) ColorF {
        const _rgba = zmath.hslToRgb(zmath.loadArr4(hsl));
        return .{ .r = _rgba[0], .g = _rgba[1], .b = _rgba[2], .a = _rgba[3] };
    }

    /// Convert to HSL color space. Output: [hue (0-1), saturation (0-1), lightness (0-1), alpha (0-1)]
    pub inline fn toHSL(c: ColorF) [4]f32 {
        const hsl = zmath.rgbToHsl(zmath.f32x4(c.r, c.g, c.b, c.a));
        return zmath.vecToArr4(hsl);
    }

    /// Convert from ImGui's internal color format (ABGR packed as u32)
    pub inline fn fromInternalColor(c: u32) ColorF {
        return fromColor(Color.fromInternalColor(c));
    }

    /// Convert to ImGui's internal color format (ABGR packed as u32)
    pub inline fn toInternalColor(c: ColorF) u32 {
        return c.toColor().toInternalColor();
    }

    /// Linear interpolation between two colors. t should be in range [0, 1].
    pub inline fn lerp(_c0: ColorF, _c1: ColorF, t: f32) ColorF {
        assert(t >= 0 and t <= 1);
        const c0 = zmath.f32x4(_c0.r, _c0.g, _c0.b, _c0.a);
        const c1 = zmath.f32x4(_c1.r, _c1.g, _c1.b, _c1.a);
        const c = zmath.lerp(c0, c1, t);
        return .{ .r = c[0], .g = c[1], .b = c[2], .a = c[3] };
    }

    /// Modulate (multiply) two colors component-wise
    pub inline fn mod(c0: ColorF, c1: ColorF) ColorF {
        return .{
            .r = c0.r * c1.r,
            .g = c0.g * c1.g,
            .b = c0.b * c1.b,
            .a = c0.a * c1.a,
        };
    }
};

/// Blend mode for graphics rendering operations.
/// Defines how source and destination colors are combined.
pub const BlendMode = enum {
    /// No blending - source replaces destination
    /// Formula: dstRGBA = srcRGBA
    none,

    /// Alpha blending - standard transparency blending
    /// Formula:
    /// - dstRGB = (srcRGB * srcA) + (dstRGB * (1-srcA))
    /// - dstA = srcA + (dstA * (1-srcA))
    blend,

    /// Additive blending - adds source to destination (brightens)
    /// Formula:
    /// - dstRGB = (srcRGB * srcA) + dstRGB
    /// - dstA = dstA
    additive,

    /// Color modulate - multiplies source and destination
    /// Formula:
    /// - dstRGB = srcRGB * dstRGB
    /// - dstA = dstA
    modulate,

    /// Color multiply - modulate with alpha consideration
    /// Formula:
    /// - dstRGB = (srcRGB * dstRGB) + (dstRGB * (1-srcA))
    /// - dstA = dstA
    multiply,

    //------------------------------------------------------------------------------
    // Porter-Duff compositing operations
    // May not be supported on all platforms
    // See: https://ssp.impulsetrain.com/porterduff.html
    //------------------------------------------------------------------------------

    /// Porter-Duff: Source
    pd_src,
    /// Porter-Duff: Source Atop
    pd_src_atop,
    /// Porter-Duff: Source Over
    pd_src_over,
    /// Porter-Duff: Source In
    pd_src_in,
    /// Porter-Duff: Source Out
    pd_src_out,
    /// Porter-Duff: Destination
    pd_dst,
    /// Porter-Duff: Destination Atop
    pd_dst_atop,
    /// Porter-Duff: Destination Over
    pd_dst_over,
    /// Porter-Duff: Destination In
    pd_dst_in,
    /// Porter-Duff: Destination Out
    pd_dst_out,
    /// Porter-Duff: XOR
    pd_xor,
    /// Porter-Duff: Lighter
    pd_lighter,
    /// Porter-Duff: Clear
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

    /// Initialize Porter-Duff blend modes (called automatically)
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

    /// Convert from SDL's native blend mode to jok BlendMode
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

    /// Convert from jok BlendMode to SDL's native blend mode
    pub fn toNative(self: @This()) sdl.SDL_BlendMode {
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

/// Vertex structure for rendering.
/// Contains position, color, and optional texture coordinates.
/// Used by the rendering system for drawing textured and colored geometry.
pub const Vertex = extern struct {
    /// Vertex position in 2D space
    pos: geom.Point,
    /// Vertex color (floating-point RGBA)
    color: ColorF,
    /// Texture coordinates (UV mapping). Undefined if not using textures.
    texcoord: geom.Point = undefined,
};

test "basic" {
    const testing = std.testing;
    const expect = testing.expect;
    const expectEqual = testing.expectEqual;
    const expectApproxEqAbs = testing.expectApproxEqAbs;

    // Color tests
    {
        // rgb / rgba constructors
        const c = Color.rgb(255, 128, 0);
        try expectEqual(c.r, 255);
        try expectEqual(c.g, 128);
        try expectEqual(c.b, 0);
        try expectEqual(c.a, 255);
        const ca = Color.rgba(10, 20, 30, 40);
        try expectEqual(ca.r, 10);
        try expectEqual(ca.g, 20);
        try expectEqual(ca.b, 30);
        try expectEqual(ca.a, 40);

        // Color <-> ColorF round-trip
        const cf = c.toColorF();
        try expectApproxEqAbs(cf.r, 1.0, 0.004);
        try expectApproxEqAbs(cf.g, 128.0 / 255.0, 0.004);
        try expectApproxEqAbs(cf.b, 0.0, 0.004);
        try expectApproxEqAbs(cf.a, 1.0, 0.004);
        const back = Color.fromColorF(cf);
        try expectEqual(back.r, 255);
        try expectEqual(back.g, 128);
        try expectEqual(back.b, 0);
        try expectEqual(back.a, 255);

        // fromInternalColor / toInternalColor round-trip (ABGR)
        const internal: u32 = 0xAA_BB_CC_DD; // a=0xAA, b=0xBB, g=0xCC, r=0xDD
        const from_int = Color.fromInternalColor(internal);
        try expectEqual(from_int.r, 0xDD);
        try expectEqual(from_int.g, 0xCC);
        try expectEqual(from_int.b, 0xBB);
        try expectEqual(from_int.a, 0xAA);
        try expectEqual(from_int.toInternalColor(), internal);

        // lerp
        const c0 = Color.rgb(0, 0, 0);
        const c1 = Color.rgb(255, 255, 255);
        const mid = c0.lerp(c1, 0.5);
        // Should be approximately 128 for each channel
        try expect(mid.r >= 126 and mid.r <= 129);
        try expect(mid.g >= 126 and mid.g <= 129);
        try expect(mid.b >= 126 and mid.b <= 129);
        // lerp at boundaries
        const at0 = c0.lerp(c1, 0.0);
        try expectEqual(at0.r, 0);
        try expectEqual(at0.g, 0);
        try expectEqual(at0.b, 0);
        const at1 = c0.lerp(c1, 1.0);
        try expectEqual(at1.r, 255);
        try expectEqual(at1.g, 255);
        try expectEqual(at1.b, 255);

        // mod
        const white = Color.rgb(255, 255, 255);
        const half = Color.rgba(128, 128, 128, 255);
        const modded = white.mod(half);
        // 255/255 * 128/255 * 255 ≈ 128
        try expect(modded.r >= 126 and modded.r <= 129);

        // parse: RGB (3 chars)
        const p3 = try Color.parse("F00");
        try expectEqual(p3.r, 0xFF);
        try expectEqual(p3.g, 0x00);
        try expectEqual(p3.b, 0x00);
        try expectEqual(p3.a, 255);

        // parse: #RGB (4 chars with #)
        const p4h = try Color.parse("#0F0");
        try expectEqual(p4h.g, 0xFF);

        // parse: RGBA (4 chars)
        const p4 = try Color.parse("F00F");
        try expectEqual(p4.r, 0xFF);
        try expectEqual(p4.a, 0xFF);

        // parse: #RGBA (5 chars)
        const p5 = try Color.parse("#F00F");
        try expectEqual(p5.r, 0xFF);
        try expectEqual(p5.a, 0xFF);

        // parse: RRGGBB (6 chars)
        const p6 = try Color.parse("FF8000");
        try expectEqual(p6.r, 0xFF);
        try expectEqual(p6.g, 0x80);
        try expectEqual(p6.b, 0x00);
        try expectEqual(p6.a, 255);

        // parse: #RRGGBB (7 chars)
        const p7 = try Color.parse("#FF8000");
        try expectEqual(p7.r, 0xFF);
        try expectEqual(p7.g, 0x80);

        // parse: RRGGBBAA (8 chars)
        const p8 = try Color.parse("FF800080");
        try expectEqual(p8.r, 0xFF);
        try expectEqual(p8.g, 0x80);
        try expectEqual(p8.b, 0x00);
        try expectEqual(p8.a, 0x80);

        // parse: #RRGGBBAA (9 chars)
        const p9 = try Color.parse("#FF800080");
        try expectEqual(p9.a, 0x80);

        // parse: invalid format
        try expect(Color.parse("XY") == error.UnknownFormat);
        try expect(Color.parse("ZZZZZZ") == error.InvalidCharacter);
    }

    // ColorF tests
    {
        // rgb / rgba constructors
        const cf = ColorF.rgb(0.5, 0.25, 0.75);
        try expectApproxEqAbs(cf.r, 0.5, 0.000001);
        try expectApproxEqAbs(cf.g, 0.25, 0.000001);
        try expectApproxEqAbs(cf.b, 0.75, 0.000001);
        try expectApproxEqAbs(cf.a, 1.0, 0.000001);
        const cfa = ColorF.rgba(0.1, 0.2, 0.3, 0.4);
        try expectApproxEqAbs(cfa.a, 0.4, 0.000001);

        // fromColor / toColor round-trip
        const c = Color.rgba(100, 150, 200, 250);
        const cf2 = ColorF.fromColor(c);
        try expectApproxEqAbs(cf2.r, 100.0 / 255.0, 0.004);
        try expectApproxEqAbs(cf2.g, 150.0 / 255.0, 0.004);
        const back = cf2.toColor();
        try expectEqual(back.r, 100);
        try expectEqual(back.g, 150);
        try expectEqual(back.b, 200);
        try expectEqual(back.a, 250);

        // fromInternalColor / toInternalColor round-trip
        const internal: u32 = 0xFF_00_80_40; // a=0xFF, b=0x00, g=0x80, r=0x40
        const from_int = ColorF.fromInternalColor(internal);
        try expectApproxEqAbs(from_int.r, @as(f32, 0x40) / 255.0, 0.004);
        try expectApproxEqAbs(from_int.g, @as(f32, 0x80) / 255.0, 0.004);
        try expectEqual(from_int.toInternalColor(), internal);

        // lerp
        const black = ColorF.rgb(0, 0, 0);
        const white = ColorF.rgb(1, 1, 1);
        const mid = black.lerp(white, 0.5);
        try expectApproxEqAbs(mid.r, 0.5, 0.000001);
        try expectApproxEqAbs(mid.g, 0.5, 0.000001);
        try expectApproxEqAbs(mid.b, 0.5, 0.000001);
        try expectApproxEqAbs(mid.a, 1.0, 0.000001);
        // lerp at t=0 and t=1
        const at0 = black.lerp(white, 0.0);
        try expectApproxEqAbs(at0.r, 0.0, 0.000001);
        const at1 = black.lerp(white, 1.0);
        try expectApproxEqAbs(at1.r, 1.0, 0.000001);

        // mod
        const half = ColorF.rgb(0.5, 0.5, 0.5);
        const modded = white.mod(half);
        try expectApproxEqAbs(modded.r, 0.5, 0.000001);
        try expectApproxEqAbs(modded.g, 0.5, 0.000001);
        try expectApproxEqAbs(modded.b, 0.5, 0.000001);
        try expectApproxEqAbs(modded.a, 1.0, 0.000001);

        // HSL round-trip
        const red_hsl = ColorF.red.toHSL();
        try expectApproxEqAbs(red_hsl[0], 0.0, 0.01); // hue ~0
        try expectApproxEqAbs(red_hsl[1], 1.0, 0.01); // full saturation
        try expectApproxEqAbs(red_hsl[2], 0.5, 0.01); // lightness 0.5
        const back_from_hsl = ColorF.fromHSL(red_hsl);
        try expectApproxEqAbs(back_from_hsl.r, 1.0, 0.01);
        try expectApproxEqAbs(back_from_hsl.g, 0.0, 0.01);
        try expectApproxEqAbs(back_from_hsl.b, 0.0, 0.01);

        // Color HSL round-trip
        const red_c = Color.rgb(255, 0, 0);
        const red_c_hsl = red_c.toHSL();
        try expectApproxEqAbs(red_c_hsl[0], 0.0, 0.01);
        try expectApproxEqAbs(red_c_hsl[1], 1.0, 0.01);
        const red_back = Color.fromHSL(red_c_hsl);
        try expectEqual(red_back.r, 255);
        try expectEqual(red_back.g, 0);
        try expectEqual(red_back.b, 0);
    }
}
