const std = @import("std");
const assert = std.debug.assert;
const jok = @import("../jok.zig");
const DrawCmd = @import("internal.zig").DrawCmd;
const imgui = jok.imgui;
const zmath = jok.zmath;
const Self = @This();

// Size of sprite
width: f32,
height: f32,

// Tex-coords of sprite
uv0: jok.Point,
uv1: jok.Point,

// Reference to texture
tex: jok.Texture,

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
pub const RenderOption = struct {
    pos: jok.Point,

    /// Tint color
    tint_color: jok.Color = jok.Color.white,

    /// Scale of width/height
    scale: jok.Point = .{ .x = 1, .y = 1 },

    /// Rotation around anchor-point
    rotate_degree: f32 = 0,

    /// Anchor-point of sprite, around which rotation and translation is calculated
    anchor_point: jok.Point = .{ .x = 0, .y = 0 },

    /// Horizontal/vertial flipping
    flip_h: bool = false,
    flip_v: bool = false,

    depth: f32 = 0.5,
};

/// Render to output
pub fn render(
    self: Self,
    draw_commands: *std.ArrayList(DrawCmd),
    opt: RenderOption,
) !void {
    assert(opt.scale.x >= 0 and opt.scale.y >= 0);
    assert(opt.anchor_point.x >= 0 and opt.anchor_point.x <= 1);
    assert(opt.anchor_point.y >= 0 and opt.anchor_point.y <= 1);
    var uv0 = self.uv0;
    var uv1 = self.uv1;
    if (opt.flip_h) std.mem.swap(f32, &uv0.x, &uv1.x);
    if (opt.flip_v) std.mem.swap(f32, &uv0.y, &uv1.y);
    const m_scale = zmath.scaling(self.width * opt.scale.x, self.height * opt.scale.y, 1);
    const m_rotate = zmath.rotationZ(jok.utils.math.degreeToRadian(opt.rotate_degree));
    const m_translate = zmath.translation(opt.pos.x, opt.pos.y, 0);
    const m_transform = zmath.mul(zmath.mul(m_scale, m_rotate), m_translate);
    const basic_coords = zmath.loadMat(&[_]f32{
        -opt.anchor_point.x, -opt.anchor_point.y, 0, 1, // Left top
        1 - opt.anchor_point.x, -opt.anchor_point.y, 0, 1, // Right top
        1 - opt.anchor_point.x, 1 - opt.anchor_point.y, 0, 1, // Right bottom
        -opt.anchor_point.x, 1 - opt.anchor_point.y, 0, 1, // Left bottom
    });
    const trasformed_coords = zmath.mul(basic_coords, m_transform);
    try draw_commands.append(.{
        .cmd = .{
            .quad_image = .{
                .texture = self.tex,
                .p1 = .{
                    .x = trasformed_coords[0][0],
                    .y = trasformed_coords[0][1],
                },
                .p2 = .{
                    .x = trasformed_coords[1][0],
                    .y = trasformed_coords[1][1],
                },
                .p3 = .{
                    .x = trasformed_coords[2][0],
                    .y = trasformed_coords[2][1],
                },
                .p4 = .{
                    .x = trasformed_coords[3][0],
                    .y = trasformed_coords[3][1],
                },
                .uv1 = uv0,
                .uv2 = .{ .x = uv1.x, .y = uv0.y },
                .uv3 = uv1,
                .uv4 = .{ .x = uv0.x, .y = uv1.y },
                .tint_color = imgui.sdl.convertColor(opt.tint_color),
            },
        },
        .depth = opt.depth,
    });
}
