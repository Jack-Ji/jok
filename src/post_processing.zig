const std = @import("std");
const assert = std.debug.assert;
const config = @import("config.zig");
const jok = @import("jok.zig");
const sdl = jok.sdl;

/// Post-processing function
pub const PostProcessingFn = *const fn (pos: sdl.PointF, data: ?*anyopaque) ?sdl.Color;

/// Post-processing effect generator
pub fn PostProcessingEffect(comptime cfg: config.Config) type {
    return struct {
        const max_cols: usize = @intCast(cfg.jok_post_processing_size.width);
        const max_rows: usize = @intCast(cfg.jok_post_processing_size.height);

        fbsize: sdl.Renderer.OutputSize,
        _vs: [max_rows * max_cols * 6]sdl.Vertex,
        vs: [max_rows * max_cols * 6]sdl.Vertex,

        pub fn init(rd: sdl.Renderer) @This() {
            var pp: @This() = undefined;
            pp.reinit(rd.getOutputSize() catch unreachable);
            return pp;
        }

        fn reinit(self: *@This(), newsize: sdl.Renderer.OutputSize) void {
            self.fbsize = newsize;
            const pos_unit_w = @as(f32, @floatFromInt(self.fbsize.width_pixels)) / @as(f32, @floatFromInt(max_cols));
            const pos_unit_h = @as(f32, @floatFromInt(self.fbsize.height_pixels)) / @as(f32, @floatFromInt(max_rows));
            const texcoord_unit_w = 1.0 / @as(f32, @floatFromInt(max_cols));
            const texcoord_unit_h = 1.0 / @as(f32, @floatFromInt(max_rows));
            var row: u32 = 0;
            var col: u32 = 0;
            var i: usize = 0;
            while (i < self._vs.len) : (i += 6) {
                self._vs[i].position = .{
                    .x = pos_unit_w * @as(f32, @floatFromInt(col)),
                    .y = pos_unit_h * @as(f32, @floatFromInt(row)),
                };
                self._vs[i].color = sdl.Color.white;
                self._vs[i].tex_coord = .{
                    .x = texcoord_unit_w * @as(f32, @floatFromInt(col)),
                    .y = texcoord_unit_h * @as(f32, @floatFromInt(row)),
                };
                self._vs[i + 1].position = .{
                    .x = pos_unit_w * @as(f32, @floatFromInt(col + 1)),
                    .y = pos_unit_h * @as(f32, @floatFromInt(row)),
                };
                self._vs[i + 1].color = sdl.Color.white;
                self._vs[i + 1].tex_coord = .{
                    .x = texcoord_unit_w * @as(f32, @floatFromInt(col + 1)),
                    .y = texcoord_unit_h * @as(f32, @floatFromInt(row)),
                };
                self._vs[i + 2].position = .{
                    .x = pos_unit_w * @as(f32, @floatFromInt(col + 1)),
                    .y = pos_unit_h * @as(f32, @floatFromInt(row + 1)),
                };
                self._vs[i + 2].color = sdl.Color.white;
                self._vs[i + 2].tex_coord = .{
                    .x = texcoord_unit_w * @as(f32, @floatFromInt(col + 1)),
                    .y = texcoord_unit_h * @as(f32, @floatFromInt(row + 1)),
                };
                self._vs[i + 3] = self._vs[i];
                self._vs[i + 4] = self._vs[i + 2];
                self._vs[i + 5].position = .{
                    .x = pos_unit_w * @as(f32, @floatFromInt(col)),
                    .y = pos_unit_h * @as(f32, @floatFromInt(row + 1)),
                };
                self._vs[i + 5].color = sdl.Color.white;
                self._vs[i + 5].tex_coord = .{
                    .x = texcoord_unit_w * @as(f32, @floatFromInt(col)),
                    .y = texcoord_unit_h * @as(f32, @floatFromInt(row + 1)),
                };
                col += 1;
                if (col == max_cols) {
                    row += 1;
                    col = 0;
                }
            }
        }

        pub fn reset(self: *@This(), rd: sdl.Renderer) void {
            const fbsize = rd.getOutputSize() catch unreachable;
            if (self.fbsize.width_pixels != fbsize.width_pixels or
                self.fbsize.height_pixels != fbsize.height_pixels)
            {
                self.reinit(fbsize);
            }
            @memcpy(&self.vs, &self._vs);
        }

        pub fn applyFn(self: *@This(), ctx: jok.Context, ppfn: PostProcessingFn, data: ?*anyopaque) void {
            const csz = ctx.getCanvasSize();
            var i: usize = 0;
            while (i < self.vs.len) : (i += 6) {
                if (ppfn(.{
                    .x = self.vs[i].tex_coord.x * csz.x,
                    .y = self.vs[i].tex_coord.y * csz.y,
                }, data)) |c| {
                    self.vs[i].color = c;
                    self.vs[i + 1].color = c;
                    self.vs[i + 2].color = c;
                    self.vs[i + 3].color = c;
                    self.vs[i + 4].color = c;
                    self.vs[i + 5].color = c;
                }
            }
        }

        pub fn render(self: @This(), rd: sdl.Renderer, tex: sdl.Texture) void {
            rd.drawGeometry(tex, &self.vs, null) catch unreachable;
        }
    };
}
