const std = @import("std");
const assert = std.debug.assert;
const config = @import("config.zig");
const jok = @import("jok.zig");

/// Post-processing function, coordinate's range is [0-1]
pub const PostProcessingFn = *const fn (pos: jok.Point, data: ?*anyopaque) ?jok.Color;

/// Post-processing effect generator
pub fn PostProcessingEffect(comptime cfg: config.Config) type {
    return struct {
        const max_cols: usize = @intCast(cfg.jok_post_processing_size.width);
        const max_rows: usize = @intCast(cfg.jok_post_processing_size.height);
        const vs_count = max_rows * max_cols * 6;

        allocator: std.mem.Allocator,
        _vs: []jok.Vertex,
        vs: []jok.Vertex,

        pub fn init(allocator: std.mem.Allocator) !@This() {
            return .{
                .allocator = allocator,
                ._vs = try allocator.alloc(jok.Vertex, vs_count),
                .vs = try allocator.alloc(jok.Vertex, vs_count),
            };
        }

        pub fn destroy(self: *@This()) void {
            self.allocator.free(self._vs);
            self.allocator.free(self.vs);
        }

        pub fn onCanvasChange(self: *@This(), rd: jok.Renderer, canvas_area: ?jok.Rectangle) void {
            const draw_area: jok.Rectangle = canvas_area orelse BLK: {
                const fbsize = rd.getOutputSize() catch unreachable;
                break :BLK .{
                    .x = 0,
                    .y = 0,
                    .width = @floatFromInt(fbsize.width),
                    .height = @floatFromInt(fbsize.height),
                };
            };
            const pos_unit_w = draw_area.width / @as(f32, @floatFromInt(max_cols));
            const pos_unit_h = draw_area.height / @as(f32, @floatFromInt(max_rows));
            const texcoord_unit_w = 1.0 / @as(f32, @floatFromInt(max_cols));
            const texcoord_unit_h = 1.0 / @as(f32, @floatFromInt(max_rows));
            var row: u32 = 0;
            var col: u32 = 0;
            var i: usize = 0;
            while (i < self._vs.len) : (i += 6) {
                self._vs[i].pos = .{
                    .x = draw_area.x + pos_unit_w * @as(f32, @floatFromInt(col)),
                    .y = draw_area.y + pos_unit_h * @as(f32, @floatFromInt(row)),
                };
                self._vs[i].color = jok.Color.white;
                self._vs[i].texcoord = .{
                    .x = texcoord_unit_w * @as(f32, @floatFromInt(col)),
                    .y = texcoord_unit_h * @as(f32, @floatFromInt(row)),
                };
                self._vs[i + 1].pos = .{
                    .x = draw_area.x + pos_unit_w * @as(f32, @floatFromInt(col + 1)),
                    .y = draw_area.y + pos_unit_h * @as(f32, @floatFromInt(row)),
                };
                self._vs[i + 1].color = jok.Color.white;
                self._vs[i + 1].texcoord = .{
                    .x = texcoord_unit_w * @as(f32, @floatFromInt(col + 1)),
                    .y = texcoord_unit_h * @as(f32, @floatFromInt(row)),
                };
                self._vs[i + 2].pos = .{
                    .x = draw_area.x + pos_unit_w * @as(f32, @floatFromInt(col + 1)),
                    .y = draw_area.y + pos_unit_h * @as(f32, @floatFromInt(row + 1)),
                };
                self._vs[i + 2].color = jok.Color.white;
                self._vs[i + 2].texcoord = .{
                    .x = texcoord_unit_w * @as(f32, @floatFromInt(col + 1)),
                    .y = texcoord_unit_h * @as(f32, @floatFromInt(row + 1)),
                };
                self._vs[i + 3] = self._vs[i];
                self._vs[i + 4] = self._vs[i + 2];
                self._vs[i + 5].pos = .{
                    .x = draw_area.x + pos_unit_w * @as(f32, @floatFromInt(col)),
                    .y = draw_area.y + pos_unit_h * @as(f32, @floatFromInt(row + 1)),
                };
                self._vs[i + 5].color = jok.Color.white;
                self._vs[i + 5].texcoord = .{
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

        pub fn applyFn(self: *@This(), ppfn: PostProcessingFn, data: ?*anyopaque) void {
            // Reset vertices
            @memcpy(self.vs, self._vs);

            // Update vertices with post-processing callback
            var i: usize = 0;
            while (i < self.vs.len) : (i += 6) {
                if (ppfn(.{
                    .x = self.vs[i].texcoord.x,
                    .y = self.vs[i].texcoord.y,
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

        pub fn render(self: @This(), rd: jok.Renderer, tex: jok.Texture) void {
            rd.drawTriangles(tex, self.vs, null) catch unreachable;
        }
    };
}
