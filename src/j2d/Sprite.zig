//! Sprite representation for 2D rendering.
//!
//! A sprite is a rectangular region of a texture with associated UV coordinates.
//! Sprites can be rendered with transformations (position, rotation, scale),
//! flipping, tinting, and anchor point positioning.

const std = @import("std");
const assert = std.debug.assert;
const jok = @import("../jok.zig");
const internal = @import("internal.zig");
const zgui = jok.vendor.zgui;
const zmath = jok.vendor.zmath;
const Self = @This();

/// Width of the sprite in pixels
width: f32,

/// Height of the sprite in pixels
height: f32,

/// Top-left UV coordinate (0,0 to 1,1)
uv0: jok.Point,

/// Bottom-right UV coordinate (0,0 to 1,1)
uv1: jok.Point,

/// Reference to the texture containing this sprite
tex: jok.Texture,

/// Extract a sub-sprite from this sprite by specifying an offset and size.
/// Useful for extracting individual frames from a sprite sheet.
/// Parameters:
///   - offset_x: X offset in pixels from the sprite's origin
///   - offset_y: Y offset in pixels from the sprite's origin
///   - width: Width of the sub-sprite in pixels
///   - height: Height of the sub-sprite in pixels
/// Returns: A new sprite representing the sub-region
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

/// Options for rendering a sprite
pub const RenderOption = struct {
    /// Position to render at
    pos: jok.Point,

    /// Tint color applied to the sprite
    tint_color: jok.Color = .white,

    /// Scale factors for width and height
    scale: jok.Point = .unit,

    /// Rotation angle in radians around the anchor point
    rotate_angle: f32 = 0,

    /// Anchor point for rotation and positioning (0,0 = top-left, 0.5,0.5 = center, 1,1 = bottom-right)
    anchor_point: jok.Point = .origin,

    /// Flip horizontally
    flip_h: bool = false,

    /// Flip vertically
    flip_v: bool = false,

    /// Depth value for sorting (0.0 = back, 1.0 = front)
    depth: f32 = 0.5,
};

/// Render the sprite to a draw command list.
/// This is typically called internally by the batch system.
/// Parameters:
///   - draw_commands: List to append the draw command to
///   - opt: Rendering options
pub fn render(
    self: Self,
    draw_commands: *std.array_list.Managed(internal._DrawCmd),
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
    const m_rotate = zmath.rotationZ(opt.rotate_angle);
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
                .tint_color = opt.tint_color.toInternalColor(),
            },
        },
        .depth = opt.depth,
    });
}
