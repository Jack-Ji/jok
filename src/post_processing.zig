const std = @import("std");
const assert = std.debug.assert;
const config = @import("config.zig");
const jok = @import("jok.zig");

/// Post-processing function, coordinate's range is [0-1]
pub const PostProcessingFn = *const fn (pos: jok.Point, data: ?*anyopaque) ?jok.Color;

pub const Actor = struct {
    ppfn: PostProcessingFn,
    region: ?jok.Region = null,
    data: ?*anyopaque = null,
};

/// Post-processing effect
pub const PostProcessingEffect = struct {
    ctx: jok.Context,
    size: jok.Size,
    vs: []jok.Vertex,
    processed_vs: std.ArrayList(jok.Vertex),

    pub fn init(ctx: jok.Context) !@This() {
        return .{
            .ctx = ctx,
            .size = undefined,
            .vs = &.{},
            .processed_vs = std.ArrayList(jok.Vertex).init(ctx.allocator()),
        };
    }

    pub fn destroy(self: *@This()) void {
        self.ctx.allocator().free(self.vs);
        self.processed_vs.deinit();
    }

    pub fn onCanvasChange(self: *@This()) void {
        const allocator = self.ctx.allocator();
        const canvas_size = self.ctx.getCanvasSize();
        if (!self.size.isSame(canvas_size)) {
            if (self.vs.len > 0) {
                allocator.free(self.vs);
            }
            self.size = canvas_size;
            self.vs = allocator.alloc(jok.Vertex, self.size.area() * 6) catch unreachable;
            self.processed_vs.ensureTotalCapacityPrecise(self.size.area() * 6) catch unreachable;
        }

        const canvas_area = self.ctx.getCanvasArea();
        const pos_unit_w = canvas_area.width / @as(f32, @floatFromInt(self.size.width));
        const pos_unit_h = canvas_area.height / @as(f32, @floatFromInt(self.size.height));
        const texcoord_unit_w = 1.0 / @as(f32, @floatFromInt(self.size.width));
        const texcoord_unit_h = 1.0 / @as(f32, @floatFromInt(self.size.height));
        var row: u32 = 0;
        var col: u32 = 0;
        var i: usize = 0;
        while (i < self.vs.len) : (i += 6) {
            self.vs[i].pos = .{
                .x = canvas_area.x + pos_unit_w * @as(f32, @floatFromInt(col)),
                .y = canvas_area.y + pos_unit_h * @as(f32, @floatFromInt(row)),
            };
            self.vs[i].color = jok.Color.white;
            self.vs[i].texcoord = .{
                .x = texcoord_unit_w * @as(f32, @floatFromInt(col)),
                .y = texcoord_unit_h * @as(f32, @floatFromInt(row)),
            };
            self.vs[i + 1].pos = .{
                .x = canvas_area.x + pos_unit_w * @as(f32, @floatFromInt(col + 1)),
                .y = canvas_area.y + pos_unit_h * @as(f32, @floatFromInt(row)),
            };
            self.vs[i + 1].color = jok.Color.white;
            self.vs[i + 1].texcoord = .{
                .x = texcoord_unit_w * @as(f32, @floatFromInt(col + 1)),
                .y = texcoord_unit_h * @as(f32, @floatFromInt(row)),
            };
            self.vs[i + 2].pos = .{
                .x = canvas_area.x + pos_unit_w * @as(f32, @floatFromInt(col + 1)),
                .y = canvas_area.y + pos_unit_h * @as(f32, @floatFromInt(row + 1)),
            };
            self.vs[i + 2].color = jok.Color.white;
            self.vs[i + 2].texcoord = .{
                .x = texcoord_unit_w * @as(f32, @floatFromInt(col + 1)),
                .y = texcoord_unit_h * @as(f32, @floatFromInt(row + 1)),
            };
            self.vs[i + 3] = self.vs[i];
            self.vs[i + 4] = self.vs[i + 2];
            self.vs[i + 5].pos = .{
                .x = canvas_area.x + pos_unit_w * @as(f32, @floatFromInt(col)),
                .y = canvas_area.y + pos_unit_h * @as(f32, @floatFromInt(row + 1)),
            };
            self.vs[i + 5].color = jok.Color.white;
            self.vs[i + 5].texcoord = .{
                .x = texcoord_unit_w * @as(f32, @floatFromInt(col)),
                .y = texcoord_unit_h * @as(f32, @floatFromInt(row + 1)),
            };
            col += 1;
            if (col == self.size.width) {
                row += 1;
                col = 0;
            }
        }
    }

    pub fn reset(self: *@This()) void {
        self.processed_vs.clearRetainingCapacity();
    }

    pub fn applyActor(self: *@This(), ppa: Actor) void {
        if (ppa.region) |r| {
            assert(r.x < self.size.width);
            assert(r.y < self.size.height);
            var y: u32 = 0;
            while (y < r.height) : (y += 1) {
                var x: u32 = 0;
                while (x < r.width) : (x += 1) {
                    const i = ((y + r.y) * self.size.width + x + r.x) * 6;
                    if (ppa.ppfn(.{
                        .x = @as(f32, @floatFromInt(x)) / @as(f32, @floatFromInt(r.width)),
                        .y = @as(f32, @floatFromInt(y)) / @as(f32, @floatFromInt(r.height)),
                    }, ppa.data)) |c| {
                        self.vs[i].color = c;
                        self.vs[i + 1].color = c;
                        self.vs[i + 2].color = c;
                        self.vs[i + 3].color = c;
                        self.vs[i + 4].color = c;
                        self.vs[i + 5].color = c;
                        self.processed_vs.appendSliceAssumeCapacity(self.vs[i .. i + 6]);
                    }
                }
            }
        } else {
            var i: usize = 0;
            while (i < self.vs.len) : (i += 6) {
                if (ppa.ppfn(.{
                    .x = self.vs[i].texcoord.x,
                    .y = self.vs[i].texcoord.y,
                }, ppa.data)) |c| {
                    self.vs[i].color = c;
                    self.vs[i + 1].color = c;
                    self.vs[i + 2].color = c;
                    self.vs[i + 3].color = c;
                    self.vs[i + 4].color = c;
                    self.vs[i + 5].color = c;
                    self.processed_vs.appendSliceAssumeCapacity(self.vs[i .. i + 6]);
                }
            }
        }
    }

    pub fn render(self: @This()) void {
        const rd = self.ctx.renderer();
        const tex = self.ctx.canvas();
        rd.drawTexture(tex, null, self.ctx.getCanvasArea()) catch unreachable;
        rd.drawTriangles(tex, self.processed_vs.items, null) catch unreachable;
    }
};
