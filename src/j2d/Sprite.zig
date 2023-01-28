const std = @import("std");
const assert = std.debug.assert;
const sdl = @import("sdl");
const Camera = @import("Camera.zig");
const jok = @import("../jok.zig");
const zmath = jok.zmath;
const Self = @This();

// Size of sprite
width: f32,
height: f32,

// Tex-coords of sprite
uv0: sdl.PointF,
uv1: sdl.PointF,

// Reference to texture
tex: sdl.Texture,

/// Get sub-sprite by offsets/size
pub fn getSubSprite(
    self: Self,
    offset_x: f32,
    offset_y: f32,
    width: f32,
    height: f32,
) Self {
    assert(offset_x >= 0 and offset_x < self.width);
    assert(offset_y >= 0 and offset_y < self.height);
    assert(width > 0 and width <= self.width - offset_x);
    assert(height > 0 and height <= self.height - offset_y);
    return .{
        .width = width,
        .height = height,
        .uv0 = .{
            .x = self.uv0.x + (self.uv1.x - self.uv0.x) * offset_x / self.width,
            .y = self.uv0.y + (self.uv1.y - self.uv0.y) * offset_y / self.height,
        },
        .uv1 = .{
            .x = self.uv0.x + (self.uv1.x - self.uv0.x) * (offset_x + width) / self.width,
            .y = self.uv0.y + (self.uv1.y - self.uv0.y) * (offset_y + height) / self.height,
        },
        .tex = self.tex,
    };
}

/// Sprite's drawing params
pub const DrawOption = struct {
    /// Position of sprite
    pos: sdl.PointF,

    /// Optional camera
    camera: ?Camera = null,

    /// Mod color
    tint_color: sdl.Color = sdl.Color.white,

    /// Scale of width/height
    scale_w: f32 = 1.0,
    scale_h: f32 = 1.0,

    /// Rotation around anchor-point (center by default)
    rotate_degree: f32 = 0,

    /// Anchor-point of sprite, around which rotation and translation is calculated
    anchor_point: sdl.PointF = .{ .x = 0, .y = 0 },

    /// Horizontal/vertial flipping
    flip_h: bool = false,
    flip_v: bool = false,
};

/// Add vertex data
pub fn appendDrawData(
    self: Self,
    vattribs: *std.ArrayList(sdl.Vertex),
    vindices: *std.ArrayList(u32),
    opt: DrawOption,
) !void {
    assert(opt.scale_w >= 0 and opt.scale_h >= 0);
    assert(opt.anchor_point.x >= 0 and opt.anchor_point.x <= 1);
    assert(opt.anchor_point.y >= 0 and opt.anchor_point.y <= 1);
    var uv0 = self.uv0;
    var uv1 = self.uv1;
    if (opt.flip_h) std.mem.swap(f32, &uv0.x, &uv1.x);
    if (opt.flip_v) std.mem.swap(f32, &uv0.y, &uv1.y);
    const pos = if (opt.camera) |c| c.translatePointF(opt.pos) else opt.pos;
    const scale_w = if (opt.camera) |c| opt.scale_w / c.zoom else opt.scale_w;
    const scale_h = if (opt.camera) |c| opt.scale_h / c.zoom else opt.scale_h;
    const m_scale = zmath.scaling(self.width * scale_w, self.height * scale_h, 1);
    const m_rotate = zmath.rotationZ(jok.utils.math.degreeToRadian(opt.rotate_degree));
    const m_translate = zmath.translation(pos.x, pos.y, 0);
    const m_transform = zmath.mul(zmath.mul(m_scale, m_rotate), m_translate);
    const basic_coords = zmath.loadMat(&[_]f32{
        -opt.anchor_point.x, -opt.anchor_point.y, 0, 1, // Left top
        1 - opt.anchor_point.x, -opt.anchor_point.y, 0, 1, // Right top
        1 - opt.anchor_point.x, 1 - opt.anchor_point.y, 0, 1, // Right bottom
        -opt.anchor_point.x, 1 - opt.anchor_point.y, 0, 1, // Left bottom
    });
    const trasformed_coords = zmath.mul(basic_coords, m_transform);
    const base_index = @intCast(u32, vattribs.items.len);
    try vattribs.appendSlice(&[_]sdl.Vertex{
        .{
            .position = .{ .x = trasformed_coords[0][0], .y = trasformed_coords[0][1] },
            .color = opt.tint_color,
            .tex_coord = .{ .x = uv0.x, .y = uv0.y },
        },
        .{
            .position = .{ .x = trasformed_coords[1][0], .y = trasformed_coords[1][1] },
            .color = opt.tint_color,
            .tex_coord = .{ .x = uv1.x, .y = uv0.y },
        },
        .{
            .position = .{ .x = trasformed_coords[2][0], .y = trasformed_coords[2][1] },
            .color = opt.tint_color,
            .tex_coord = .{ .x = uv1.x, .y = uv1.y },
        },
        .{
            .position = .{ .x = trasformed_coords[3][0], .y = trasformed_coords[3][1] },
            .color = opt.tint_color,
            .tex_coord = .{ .x = uv0.x, .y = uv1.y },
        },
    });
    try vindices.appendSlice(&[_]u32{
        base_index,
        base_index + 1,
        base_index + 2,
        base_index,
        base_index + 2,
        base_index + 3,
    });
}
