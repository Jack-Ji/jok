const std = @import("std");
const assert = std.debug.assert;
const sdl = @import("sdl");
const SpriteSheet = @import("SpriteSheet.zig");
const jok = @import("../../jok.zig");
const gfx = jok.gfx;
const math = jok.math;
const Self = @This();

/// size of sprite
width: f32,
height: f32,

/// tex-coords of sprite
uv0: sdl.PointF,
uv1: sdl.PointF,

/// reference to sprite-sheet
sheet: *SpriteSheet,

/// sprite's drawing params
pub const DrawOption = struct {
    /// position of sprite
    pos: sdl.PointF,

    /// scale of width/height
    scale_w: f32 = 1.0,
    scale_h: f32 = 1.0,

    /// rotation around anchor-point (center by default)
    rotate_degree: f32 = 0,

    /// anchor-point of sprite, around which rotation and translation is calculated
    anchor_point: sdl.PointF = .{ .x = 0, .y = 0 },

    /// mod color
    tint_color: sdl.Color = sdl.Color.white,
};

/// add vertex data
pub fn appendDrawData(
    self: Self,
    vattribs: *std.ArrayList(sdl.Vertex),
    indices: *std.ArrayList(u32),
    opt: DrawOption,
) !void {
    assert(opt.scale_w >= 0 and opt.scale_h >= 0);
    assert(opt.anchor_point.x >= 0 and opt.anchor_point.x <= 1);
    assert(opt.anchor_point.y >= 0 and opt.anchor_point.y <= 1);
    const m_scale = math.scaling(self.width * opt.scale_w, self.height * opt.scale_h, 1);
    const m_rotate = math.rotationZ(gfx.utils.degreeToRadian(opt.rotate_degree));
    const m_translate = math.translation(opt.pos.x, opt.pos.y, 0);
    const m_transform = math.mul(math.mul(m_scale, m_rotate), m_translate);
    const basic_coords = math.loadMat(&[_]f32{
        -opt.anchor_point.x, -opt.anchor_point.y, 0, 1, // left top
        -opt.anchor_point.x, 1 - opt.anchor_point.y, 0, 1, // left bottom
        1 - opt.anchor_point.x, 1 - opt.anchor_point.y, 0, 1, // right bottom
        1 - opt.anchor_point.x, -opt.anchor_point.y, 0, 1, // right top
    });
    const trasformed_coords = math.mul(basic_coords, m_transform);
    const base_index = @intCast(u32, vattribs.items.len);
    try vattribs.appendSlice(&[_]sdl.Vertex{
        .{
            .position = .{ .x = trasformed_coords[0][0], .y = trasformed_coords[0][1] },
            .color = opt.tint_color,
            .tex_coord = .{ .x = self.uv0.x, .y = self.uv0.y },
        },
        .{
            .position = .{ .x = trasformed_coords[1][0], .y = trasformed_coords[1][1] },
            .color = opt.tint_color,
            .tex_coord = .{ .x = self.uv0.x, .y = self.uv1.y },
        },
        .{
            .position = .{ .x = trasformed_coords[2][0], .y = trasformed_coords[2][1] },
            .color = opt.tint_color,
            .tex_coord = .{ .x = self.uv1.x, .y = self.uv1.y },
        },
        .{
            .position = .{ .x = trasformed_coords[3][0], .y = trasformed_coords[3][1] },
            .color = opt.tint_color,
            .tex_coord = .{ .x = self.uv1.x, .y = self.uv0.y },
        },
    });
    try indices.appendSlice(&[_]u32{
        base_index,
        base_index + 1,
        base_index + 2,
        base_index,
        base_index + 2,
        base_index + 3,
    });
}

pub fn flipH(self: *Self) void {
    std.mem.swap(u32, &self.uv0.x, &self.uv1.x);
}

pub fn flipV(self: *Self) void {
    std.mem.swap(u32, &self.uv0.y, &self.uv1.y);
}
