const std = @import("std");
const assert = std.debug.assert;
const math = std.math;
const unicode = std.unicode;
const jok = @import("jok.zig");
const imgui = jok.imgui;
const zmath = jok.zmath;
const zmesh = jok.zmesh;
const log = std.log.scoped(.jok);

const internal = @import("j2d/internal.zig");
pub const DrawCmd = internal.DrawCmd;
pub const AffineTransform = @import("j2d/AffineTransform.zig");
pub const Sprite = @import("j2d/Sprite.zig");
pub const SpriteSheet = @import("j2d/SpriteSheet.zig");
pub const ParticleSystem = @import("j2d/ParticleSystem.zig");
pub const AnimationSystem = @import("j2d/AnimationSystem.zig");
pub const Scene = @import("j2d/Scene.zig");
pub const Vector = @import("j2d/Vector.zig");

pub const Error = error{
    PathNotFinished,
    TooManyBatches,
    UnsupportedCodepoint,
};

pub const DepthSortMethod = enum {
    none,
    back_to_forth,
    forth_to_back,
};

pub const BatchOption = struct {
    depth_sort: DepthSortMethod = .none,
    blend_mode: jok.BlendMode = .blend,
    antialiased: bool = true,
    clip_rect: ?jok.Rectangle = null,
    offscreen_target: ?jok.Texture = null,
    offscreen_clear_color: ?jok.Color = null,
};

const invalid_batch_id = std.math.maxInt(usize);

/// Batched rendering job, managed by BatchPool
pub const Batch = struct {
    /// All fields are private, DON'T use it directly.
    id: usize = invalid_batch_id,
    reclaimer: BatchReclaimer = undefined,
    is_submitted: bool = false,
    ctx: jok.Context,
    draw_list: imgui.DrawList,
    draw_commands: std.ArrayList(DrawCmd),
    trs_stack: std.ArrayList(AffineTransform),
    depth_sort: DepthSortMethod,
    blend_mode: jok.BlendMode,
    offscreen_target: ?jok.Texture,
    offscreen_clear_color: ?jok.Color,
    all_tex: std.AutoHashMap(*anyopaque, bool),

    fn init(_ctx: jok.Context) Batch {
        const _draw_list = imgui.createDrawList();
        const _draw_commands = std.ArrayList(DrawCmd).init(_ctx.allocator());
        const _all_tex = std.AutoHashMap(*anyopaque, bool).init(_ctx.allocator());
        return .{
            .ctx = _ctx,
            .draw_list = _draw_list,
            .draw_commands = _draw_commands,
            .trs_stack = std.ArrayList(AffineTransform).init(_ctx.allocator()),
            .depth_sort = .none,
            .blend_mode = .blend,
            .offscreen_target = null,
            .offscreen_clear_color = null,
            .all_tex = _all_tex,
        };
    }

    fn deinit(self: *Batch) void {
        self.trs_stack.deinit();
        imgui.destroyDrawList(self.draw_list);
        self.draw_commands.deinit();
        self.all_tex.deinit();
    }

    pub fn recycleMemory(self: *Batch) void {
        self.draw_list.clearMemory();
        self.draw_commands.clearAndFree();
        self.all_tex.clearAndFree();
    }

    /// Reinitialize batch, abandon all commands, no reclaiming
    pub fn reset(self: *Batch, opt: BatchOption) void {
        assert(self.id != invalid_batch_id);
        defer self.is_submitted = false;

        self.draw_list.reset();
        self.draw_list.pushClipRect(if (opt.clip_rect) |r|
            .{
                .pmin = .{ r.x, r.y },
                .pmax = .{ r.x + r.width, r.y + r.height },
            }
        else BLK: {
            const csz = self.ctx.getCanvasSize();
            break :BLK .{
                .pmin = .{ 0, 0 },
                .pmax = .{ @floatFromInt(csz.width), @floatFromInt(csz.height) },
            };
        });
        if (opt.antialiased) {
            self.draw_list.setDrawListFlags(.{
                .anti_aliased_lines = true,
                .anti_aliased_lines_use_tex = false,
                .anti_aliased_fill = true,
                .allow_vtx_offset = true,
            });
        }
        self.draw_commands.clearRetainingCapacity();
        self.all_tex.clearRetainingCapacity();
        self.trs_stack.clearRetainingCapacity();
        self.trs_stack.append(AffineTransform.init()) catch unreachable;
        self.depth_sort = opt.depth_sort;
        self.blend_mode = opt.blend_mode;
        self.offscreen_target = opt.offscreen_target;
        self.offscreen_clear_color = opt.offscreen_clear_color;
        if (self.offscreen_target) |t| {
            const info = t.query() catch unreachable;
            if (info.access != .target) {
                @panic("Given texture isn't suitable for offscreen rendering!");
            }
        }
    }

    fn ascendCompare(_: ?*anyopaque, lhs: DrawCmd, rhs: DrawCmd) bool {
        return lhs.compare(rhs, true);
    }

    fn descendCompare(_: ?*anyopaque, lhs: DrawCmd, rhs: DrawCmd) bool {
        return lhs.compare(rhs, false);
    }

    /// Submit batch, issue draw calls, don't reclaim itself
    pub fn submitWithoutReclaim(self: *Batch) void {
        assert(self.id != invalid_batch_id);
        assert(jok.utils.isMainThread());

        defer self.is_submitted = true;

        if (self.draw_commands.items.len == 0) return;

        if (!self.is_submitted) {
            switch (self.depth_sort) {
                .none => {},
                .back_to_forth => std.sort.pdq(
                    DrawCmd,
                    self.draw_commands.items,
                    @as(?*anyopaque, null),
                    descendCompare,
                ),
                .forth_to_back => std.sort.pdq(
                    DrawCmd,
                    self.draw_commands.items,
                    @as(?*anyopaque, null),
                    ascendCompare,
                ),
            }
            for (self.draw_commands.items) |dcmd| {
                switch (dcmd.cmd) {
                    .quad_image => |c| self.all_tex.put(c.texture.ptr, true) catch unreachable,
                    .image_rounded => |c| self.all_tex.put(c.texture.ptr, true) catch unreachable,
                    .convex_polygon_fill => |c| {
                        if (c.texture) |tex| self.all_tex.put(tex.ptr, true) catch unreachable;
                    },
                    else => {},
                }
                dcmd.render(self.draw_list);
            }
        }

        // Apply blend mode to renderer and textures
        const rd = self.ctx.renderer();
        const old_blend = rd.getBlendMode() catch unreachable;
        defer rd.setBlendMode(old_blend) catch unreachable;
        rd.setBlendMode(self.blend_mode) catch unreachable;
        var it = self.all_tex.keyIterator();
        while (it.next()) |k| {
            const tex = jok.Texture{ .ptr = @ptrCast(k.*) };
            tex.setBlendMode(self.blend_mode) catch unreachable;
        }

        // Apply offscreen target if given
        const old_target = rd.getTarget();
        if (self.offscreen_target) |t| {
            rd.setTarget(t) catch unreachable;
            if (self.offscreen_clear_color) |c| rd.clear(c) catch unreachable;
        }
        defer if (self.offscreen_target != null) {
            rd.setTarget(old_target) catch unreachable;
        };

        // Submit draw command
        imgui.sdl.renderDrawList(self.ctx, self.draw_list);
    }

    /// Submit batch, issue draw calls, and reclaim itself
    pub fn submit(self: *Batch) void {
        defer self.reclaimer.reclaim(self);
        self.submitWithoutReclaim();
    }

    /// Reclaim itself without drawing
    pub fn abort(self: *Batch) void {
        assert(self.id != invalid_batch_id);
        self.reclaimer.reclaim(self);
    }

    pub fn pushTransform(self: *Batch, t: AffineTransform) !void {
        assert(self.id != invalid_batch_id);
        assert(!self.is_submitted);
        try self.trs_stack.append(t);
    }

    pub fn popTransform(self: *Batch) void {
        assert(self.id != invalid_batch_id);
        assert(!self.is_submitted);
        assert(self.trs_stack.items.len > 0);
        _ = self.trs_stack.pop();
    }

    pub inline fn getCurrentTransform(self: Batch) AffineTransform {
        assert(self.id != invalid_batch_id);
        return self.trs_stack.getLast();
    }

    pub const ImageOption = struct {
        size: ?jok.Size = null,
        uv0: jok.Point = .{ .x = 0, .y = 0 },
        uv1: jok.Point = .{ .x = 1, .y = 1 },
        tint_color: jok.Color = jok.Color.white,
        scale: jok.Point = .{ .x = 1, .y = 1 },
        rotate_degree: f32 = 0,
        anchor_point: jok.Point = .{ .x = 0, .y = 0 },
        flip_h: bool = false,
        flip_v: bool = false,
        depth: f32 = 0.5,
    };
    pub fn image(self: *Batch, texture: jok.Texture, pos: jok.Point, opt: ImageOption) !void {
        assert(self.id != invalid_batch_id);
        assert(!self.is_submitted);
        const scale = self.getCurrentTransform().getScale();
        const size = opt.size orelse BLK: {
            const info = try texture.query();
            break :BLK jok.Size{
                .width = info.width,
                .height = info.height,
            };
        };
        const s = Sprite{
            .width = @floatFromInt(size.width),
            .height = @floatFromInt(size.height),
            .uv0 = opt.uv0,
            .uv1 = opt.uv1,
            .tex = texture,
        };
        try s.render(&self.draw_commands, .{
            .pos = self.getCurrentTransform().transformPoint(pos),
            .tint_color = opt.tint_color,
            .scale = .{ .x = scale.x * opt.scale.x, .y = scale.y * opt.scale.y },
            .rotate_degree = opt.rotate_degree,
            .anchor_point = opt.anchor_point,
            .flip_h = opt.flip_h,
            .flip_v = opt.flip_v,
            .depth = opt.depth,
        });
    }

    /// NOTE: Rounded image is always axis-aligned
    pub const ImageRoundedOption = struct {
        size: ?jok.Size = null,
        uv0: jok.Point = .{ .x = 0, .y = 0 },
        uv1: jok.Point = .{ .x = 1, .y = 1 },
        tint_color: jok.Color = jok.Color.white,
        scale: jok.Point = .{ .x = 1, .y = 1 },
        flip_h: bool = false,
        flip_v: bool = false,
        rounding: f32 = 4,
        depth: f32 = 0.5,
    };
    pub fn imageRounded(self: *Batch, texture: jok.Texture, pos: jok.Point, opt: ImageRoundedOption) !void {
        assert(self.id != invalid_batch_id);
        assert(!self.is_submitted);
        const scale = self.getCurrentTransform().getScale();
        const size = opt.size orelse BLK: {
            const info = try texture.query();
            break :BLK jok.Size{
                .width = info.width,
                .height = info.height,
            };
        };
        const pmin = self.getCurrentTransform().transformPoint(pos);
        const pmax = jok.Point{
            .x = pmin.x + @as(f32, @floatFromInt(size.width)) * scale.x,
            .y = pmin.y + @as(f32, @floatFromInt(size.height)) * scale.y,
        };
        var uv0 = opt.uv0;
        var uv1 = opt.uv1;
        if (opt.flip_h) std.mem.swap(f32, &uv0.x, &uv1.x);
        if (opt.flip_v) std.mem.swap(f32, &uv0.y, &uv1.y);
        try self.draw_commands.append(.{
            .cmd = .{
                .image_rounded = .{
                    .texture = texture,
                    .pmin = pmin,
                    .pmax = pmax,
                    .uv0 = uv0,
                    .uv1 = uv1,
                    .rounding = opt.rounding,
                    .tint_color = opt.tint_color.toInternalColor(),
                },
            },
            .depth = opt.depth,
        });
    }

    pub fn scene(self: *Batch, s: *const Scene) !void {
        assert(self.id != invalid_batch_id);
        assert(!self.is_submitted);
        try s.render(&self.draw_commands, .{ .transform = self.getCurrentTransform() });
    }

    pub fn effects(self: *Batch, ps: *const ParticleSystem) !void {
        assert(self.id != invalid_batch_id);
        assert(!self.is_submitted);
        for (ps.effects.items) |eff| {
            try eff.render(&self.draw_commands, .{ .transform = self.getCurrentTransform() });
        }
    }

    pub const SpriteOption = struct {
        pos: jok.Point,
        tint_color: jok.Color = jok.Color.white,
        scale: jok.Point = .{ .x = 1, .y = 1 },
        rotate_degree: f32 = 0,
        anchor_point: jok.Point = .{ .x = 0, .y = 0 },
        flip_h: bool = false,
        flip_v: bool = false,
        depth: f32 = 0.5,
    };
    pub fn sprite(self: *Batch, s: Sprite, opt: SpriteOption) !void {
        assert(self.id != invalid_batch_id);
        assert(!self.is_submitted);
        const scale = self.getCurrentTransform().getScale();
        try s.render(&self.draw_commands, .{
            .pos = self.getCurrentTransform().transformPoint(opt.pos),
            .tint_color = opt.tint_color,
            .scale = .{ .x = scale.x * opt.scale.x, .y = scale.y * opt.scale.y },
            .rotate_degree = opt.rotate_degree,
            .anchor_point = opt.anchor_point,
            .flip_h = opt.flip_h,
            .flip_v = opt.flip_v,
            .depth = opt.depth,
        });
    }

    pub const TextOption = struct {
        atlas: *jok.font.Atlas,
        pos: jok.Point,
        ignore_unexist: bool = true,
        ypos_type: jok.font.Atlas.YPosType = .top,
        tint_color: jok.Color = jok.Color.white,
        scale: jok.Point = .{ .x = 1, .y = 1 },
        rotate_degree: f32 = 0,
        anchor_point: jok.Point = .{ .x = 0, .y = 0 },
        depth: f32 = 0.5,
    };
    pub fn text(self: *Batch, comptime fmt: []const u8, args: anytype, opt: TextOption) !void {
        assert(self.id != invalid_batch_id);
        assert(!self.is_submitted);
        const txt = imgui.format(fmt, args);
        if (txt.len == 0) return;

        var pos = self.getCurrentTransform().transformPoint(opt.pos);
        var scale = self.getCurrentTransform().getScale();
        scale.x *= opt.scale.x;
        scale.y *= opt.scale.y;
        const angle = std.math.degreesToRadians(opt.rotate_degree);
        const mat = zmath.mul(
            zmath.mul(
                zmath.translation(-pos.x, -pos.y, 0),
                zmath.rotationZ(angle),
            ),
            zmath.translation(pos.x, pos.y, 0),
        );
        var i: u32 = 0;
        while (i < txt.len) {
            const size = try unicode.utf8ByteSequenceLength(txt[i]);
            const u8letter = txt[i .. i + size];
            const cp = @as(u32, @intCast(try unicode.utf8Decode(u8letter)));
            if (opt.atlas.getVerticesOfCodePoint(pos, opt.ypos_type, jok.Color.white, cp)) |cs| {
                const v = zmath.mul(
                    zmath.f32x4(
                        cs.vs[0].pos.x,
                        pos.y + (cs.vs[0].pos.y - pos.y) * scale.y,
                        0,
                        1,
                    ),
                    mat,
                );
                const draw_pos = jok.Point{ .x = v[0], .y = v[1] };
                const s = Sprite{
                    .width = cs.vs[1].pos.x - cs.vs[0].pos.x,
                    .height = cs.vs[3].pos.y - cs.vs[0].pos.y,
                    .uv0 = cs.vs[0].texcoord,
                    .uv1 = cs.vs[2].texcoord,
                    .tex = opt.atlas.tex,
                };
                try s.render(&self.draw_commands, .{
                    .pos = draw_pos,
                    .tint_color = opt.tint_color,
                    .scale = scale,
                    .rotate_degree = opt.rotate_degree,
                    .anchor_point = opt.anchor_point,
                    .depth = opt.depth,
                });
                pos.x += (cs.next_x - pos.x) * scale.x;
            } else if (!opt.ignore_unexist) {
                log.err("Doesn't support character: {s}({x})", .{ u8letter, cp });
                return error.UnsupportedCodepoint;
            }
            i += size;
        }
    }

    pub const LineOption = struct {
        thickness: f32 = 1.0,
        depth: f32 = 0.5,
    };
    pub fn line(self: *Batch, p1: jok.Point, p2: jok.Point, color: jok.Color, opt: LineOption) !void {
        assert(self.id != invalid_batch_id);
        assert(!self.is_submitted);
        try self.draw_commands.append(.{
            .cmd = .{
                .line = .{
                    .p1 = self.getCurrentTransform().transformPoint(p1),
                    .p2 = self.getCurrentTransform().transformPoint(p2),
                    .color = color.toInternalColor(),
                    .thickness = opt.thickness,
                },
            },
            .depth = opt.depth,
        });
    }

    pub const RectOption = struct {
        thickness: f32 = 1.0,
        depth: f32 = 0.5,
    };
    pub fn rect(self: *Batch, r: jok.Rectangle, color: jok.Color, opt: RectOption) !void {
        assert(self.id != invalid_batch_id);
        assert(!self.is_submitted);
        const p1 = jok.Point{ .x = r.x, .y = r.y };
        const p2 = jok.Point{ .x = p1.x + r.width, .y = p1.y };
        const p3 = jok.Point{ .x = p1.x + r.width, .y = p1.y + r.height };
        const p4 = jok.Point{ .x = p1.x, .y = p1.y + r.height };
        try self.draw_commands.append(.{
            .cmd = .{
                .quad = .{
                    .p1 = self.getCurrentTransform().transformPoint(p1),
                    .p2 = self.getCurrentTransform().transformPoint(p2),
                    .p3 = self.getCurrentTransform().transformPoint(p3),
                    .p4 = self.getCurrentTransform().transformPoint(p4),
                    .color = color.toInternalColor(),
                    .thickness = opt.thickness,
                },
            },
            .depth = opt.depth,
        });
    }

    pub const FillRect = struct {
        depth: f32 = 0.5,
    };
    pub fn rectFilled(self: *Batch, r: jok.Rectangle, color: jok.Color, opt: FillRect) !void {
        assert(self.id != invalid_batch_id);
        assert(!self.is_submitted);
        const p1 = jok.Point{ .x = r.x, .y = r.y };
        const p2 = jok.Point{ .x = p1.x + r.width, .y = p1.y };
        const p3 = jok.Point{ .x = p1.x + r.width, .y = p1.y + r.height };
        const p4 = jok.Point{ .x = p1.x, .y = p1.y + r.height };
        const c = color.toInternalColor();
        try self.draw_commands.append(.{
            .cmd = .{
                .quad_fill = .{
                    .p1 = self.getCurrentTransform().transformPoint(p1),
                    .p2 = self.getCurrentTransform().transformPoint(p2),
                    .p3 = self.getCurrentTransform().transformPoint(p3),
                    .p4 = self.getCurrentTransform().transformPoint(p4),
                    .color1 = c,
                    .color2 = c,
                    .color3 = c,
                    .color4 = c,
                },
            },
            .depth = opt.depth,
        });
    }

    pub const FillRectMultiColor = struct {
        depth: f32 = 0.5,
    };
    pub fn rectFilledMultiColor(
        self: *Batch,
        r: jok.Rectangle,
        color_top_left: jok.Color,
        color_top_right: jok.Color,
        color_bottom_right: jok.Color,
        color_bottom_left: jok.Color,
        opt: FillRectMultiColor,
    ) !void {
        assert(self.id != invalid_batch_id);
        assert(!self.is_submitted);
        const p1 = jok.Point{ .x = r.x, .y = r.y };
        const p2 = jok.Point{ .x = p1.x + r.width, .y = p1.y };
        const p3 = jok.Point{ .x = p1.x + r.width, .y = p1.y + r.height };
        const p4 = jok.Point{ .x = p1.x, .y = p1.y + r.height };
        const c1 = color_top_left.toInternalColor();
        const c2 = color_top_right.toInternalColor();
        const c3 = color_bottom_right.toInternalColor();
        const c4 = color_bottom_left.toInternalColor();
        try self.draw_commands.append(.{
            .cmd = .{
                .quad_fill = .{
                    .p1 = self.getCurrentTransform().transformPoint(p1),
                    .p2 = self.getCurrentTransform().transformPoint(p2),
                    .p3 = self.getCurrentTransform().transformPoint(p3),
                    .p4 = self.getCurrentTransform().transformPoint(p4),
                    .color1 = c1,
                    .color2 = c2,
                    .color3 = c3,
                    .color4 = c4,
                },
            },
            .depth = opt.depth,
        });
    }

    /// NOTE: Rounded rectangle is always axis-aligned
    pub const RectRoundedOption = struct {
        thickness: f32 = 1.0,
        rounding: f32 = 4,
        depth: f32 = 0.5,
    };
    pub fn rectRounded(self: *Batch, r: jok.Rectangle, color: jok.Color, opt: RectRoundedOption) !void {
        assert(self.id != invalid_batch_id);
        assert(!self.is_submitted);
        const scale = self.getCurrentTransform().getScale();
        const pmin = self.getCurrentTransform().transformPoint(.{ .x = r.x, .y = r.y });
        const pmax = jok.Point{
            .x = pmin.x + r.width * scale.x,
            .y = pmin.y + r.height * scale.y,
        };
        try self.draw_commands.append(.{
            .cmd = .{
                .rect_rounded = .{
                    .pmin = pmin,
                    .pmax = pmax,
                    .color = color.toInternalColor(),
                    .thickness = opt.thickness,
                    .rounding = opt.rounding,
                },
            },
            .depth = opt.depth,
        });
    }

    /// NOTE: Rounded rectangle is always axis-aligned
    pub const FillRectRounded = struct {
        rounding: f32 = 4,
        depth: f32 = 0.5,
    };
    pub fn rectRoundedFilled(self: *Batch, r: jok.Rectangle, color: jok.Color, opt: FillRectRounded) !void {
        assert(self.id != invalid_batch_id);
        assert(!self.is_submitted);
        const scale = self.getCurrentTransform().getScale();
        const pmin = self.getCurrentTransform().transformPoint(.{ .x = r.x, .y = r.y });
        const pmax = jok.Point{
            .x = pmin.x + r.width * scale.x,
            .y = pmin.y + r.height * scale.y,
        };
        try self.draw_commands.append(.{
            .cmd = .{
                .rect_rounded_fill = .{
                    .pmin = pmin,
                    .pmax = pmax,
                    .color = color.toInternalColor(),
                    .rounding = opt.rounding,
                },
            },
            .depth = opt.depth,
        });
    }

    pub const QuadOption = struct {
        thickness: f32 = 1.0,
        depth: f32 = 0.5,
    };
    pub fn quad(
        self: *Batch,
        p1: jok.Point,
        p2: jok.Point,
        p3: jok.Point,
        p4: jok.Point,
        color: jok.Color,
        opt: QuadOption,
    ) !void {
        assert(self.id != invalid_batch_id);
        assert(!self.is_submitted);
        try self.draw_commands.append(.{
            .cmd = .{
                .quad = .{
                    .p1 = self.getCurrentTransform().transformPoint(p1),
                    .p2 = self.getCurrentTransform().transformPoint(p2),
                    .p3 = self.getCurrentTransform().transformPoint(p3),
                    .p4 = self.getCurrentTransform().transformPoint(p4),
                    .color = color.toInternalColor(),
                    .thickness = opt.thickness,
                },
            },
            .depth = opt.depth,
        });
    }

    pub const FillQuad = struct {
        depth: f32 = 0.5,
    };
    pub fn quadFilled(
        self: *Batch,
        p1: jok.Point,
        p2: jok.Point,
        p3: jok.Point,
        p4: jok.Point,
        color: jok.Color,
        opt: FillQuad,
    ) !void {
        assert(self.id != invalid_batch_id);
        assert(!self.is_submitted);
        const c = color.toInternalColor();
        try self.draw_commands.append(.{
            .cmd = .{
                .quad_fill = .{
                    .p1 = self.getCurrentTransform().transformPoint(p1),
                    .p2 = self.getCurrentTransform().transformPoint(p2),
                    .p3 = self.getCurrentTransform().transformPoint(p3),
                    .p4 = self.getCurrentTransform().transformPoint(p4),
                    .color1 = c,
                    .color2 = c,
                    .color3 = c,
                    .color4 = c,
                },
            },
            .depth = opt.depth,
        });
    }

    pub const FillQuadMultiColor = struct {
        depth: f32 = 0.5,
    };
    pub fn quadFilledMultiColor(
        self: *Batch,
        p1: jok.Point,
        p2: jok.Point,
        p3: jok.Point,
        p4: jok.Point,
        color1: jok.Color,
        color2: jok.Color,
        color3: jok.Color,
        color4: jok.Color,
        opt: FillQuadMultiColor,
    ) !void {
        assert(self.id != invalid_batch_id);
        assert(!self.is_submitted);
        const c1 = color1.toInternalColor();
        const c2 = color2.toInternalColor();
        const c3 = color3.toInternalColor();
        const c4 = color4.toInternalColor();
        try self.draw_commands.append(.{
            .cmd = .{
                .quad_fill = .{
                    .p1 = self.getCurrentTransform().transformPoint(p1),
                    .p2 = self.getCurrentTransform().transformPoint(p2),
                    .p3 = self.getCurrentTransform().transformPoint(p3),
                    .p4 = self.getCurrentTransform().transformPoint(p4),
                    .color1 = c1,
                    .color2 = c2,
                    .color3 = c3,
                    .color4 = c4,
                },
            },
            .depth = opt.depth,
        });
    }

    pub const TriangleOption = struct {
        thickness: f32 = 1.0,
        depth: f32 = 0.5,
    };
    pub fn triangle(
        self: *Batch,
        p1: jok.Point,
        p2: jok.Point,
        p3: jok.Point,
        color: jok.Color,
        opt: TriangleOption,
    ) !void {
        assert(self.id != invalid_batch_id);
        assert(!self.is_submitted);
        try self.draw_commands.append(.{
            .cmd = .{
                .triangle = .{
                    .p1 = self.getCurrentTransform().transformPoint(p1),
                    .p2 = self.getCurrentTransform().transformPoint(p2),
                    .p3 = self.getCurrentTransform().transformPoint(p3),
                    .color = color.toInternalColor(),
                    .thickness = opt.thickness,
                },
            },
            .depth = opt.depth,
        });
    }

    pub const FillTriangle = struct {
        depth: f32 = 0.5,
    };
    pub fn triangleFilled(
        self: *Batch,
        p1: jok.Point,
        p2: jok.Point,
        p3: jok.Point,
        color: jok.Color,
        opt: FillTriangle,
    ) !void {
        assert(self.id != invalid_batch_id);
        assert(!self.is_submitted);
        const c = color.toInternalColor();
        try self.draw_commands.append(.{
            .cmd = .{
                .triangle_fill = .{
                    .p1 = self.getCurrentTransform().transformPoint(p1),
                    .p2 = self.getCurrentTransform().transformPoint(p2),
                    .p3 = self.getCurrentTransform().transformPoint(p3),
                    .color1 = c,
                    .color2 = c,
                    .color3 = c,
                },
            },
            .depth = opt.depth,
        });
    }

    pub const FillTriangleMultiColor = struct {
        depth: f32 = 0.5,
    };
    pub fn triangleFilledMultiColor(
        self: *Batch,
        p1: jok.Point,
        p2: jok.Point,
        p3: jok.Point,
        color1: jok.Color,
        color2: jok.Color,
        color3: jok.Color,
        opt: FillTriangleMultiColor,
    ) !void {
        assert(self.id != invalid_batch_id);
        assert(!self.is_submitted);
        const c1 = color1.toInternalColor();
        const c2 = color2.toInternalColor();
        const c3 = color3.toInternalColor();
        try self.draw_commands.append(.{
            .cmd = .{
                .triangle_fill = .{
                    .p1 = self.getCurrentTransform().transformPoint(p1),
                    .p2 = self.getCurrentTransform().transformPoint(p2),
                    .p3 = self.getCurrentTransform().transformPoint(p3),
                    .color1 = c1,
                    .color2 = c2,
                    .color3 = c3,
                },
            },
            .depth = opt.depth,
        });
    }

    pub const CircleOption = struct {
        thickness: f32 = 1.0,
        num_segments: u32 = 0,
        depth: f32 = 0.5,
    };
    pub fn circle(
        self: *Batch,
        center: jok.Point,
        radius: f32,
        color: jok.Color,
        opt: CircleOption,
    ) !void {
        assert(self.id != invalid_batch_id);
        assert(!self.is_submitted);
        const scale = self.getCurrentTransform().getScale();
        try self.draw_commands.append(.{
            .cmd = .{
                .circle = .{
                    .p = self.getCurrentTransform().transformPoint(center),
                    .radius = radius * scale.x,
                    .color = color.toInternalColor(),
                    .thickness = opt.thickness,
                    .num_segments = opt.num_segments,
                },
            },
            .depth = opt.depth,
        });
    }

    pub const FillCircle = struct {
        num_segments: u32 = 0,
        depth: f32 = 0.5,
    };
    pub fn circleFilled(
        self: *Batch,
        center: jok.Point,
        radius: f32,
        color: jok.Color,
        opt: FillCircle,
    ) !void {
        assert(self.id != invalid_batch_id);
        assert(!self.is_submitted);
        const scale = self.getCurrentTransform().getScale();
        try self.draw_commands.append(.{
            .cmd = .{
                .circle_fill = .{
                    .p = self.getCurrentTransform().transformPoint(center),
                    .radius = radius * scale.x,
                    .color = color.toInternalColor(),
                    .num_segments = opt.num_segments,
                },
            },
            .depth = opt.depth,
        });
    }

    pub const NgonOption = struct {
        thickness: f32 = 1.0,
        depth: f32 = 0.5,
    };
    pub fn ngon(
        self: *Batch,
        center: jok.Point,
        radius: f32,
        color: jok.Color,
        num_segments: u32,
        opt: NgonOption,
    ) !void {
        assert(self.id != invalid_batch_id);
        assert(!self.is_submitted);
        const scale = self.getCurrentTransform().getScale();
        try self.draw_commands.append(.{
            .cmd = .{
                .ngon = .{
                    .p = self.getCurrentTransform().transformPoint(center),
                    .radius = radius * scale.x,
                    .color = color.toInternalColor(),
                    .thickness = opt.thickness,
                    .num_segments = num_segments,
                },
            },
            .depth = opt.depth,
        });
    }

    pub const FillNgon = struct {
        depth: f32 = 0.5,
    };
    pub fn ngonFilled(
        self: *Batch,
        center: jok.Point,
        radius: f32,
        color: jok.Color,
        num_segments: u32,
        opt: FillNgon,
    ) !void {
        assert(self.id != invalid_batch_id);
        assert(!self.is_submitted);
        const scale = self.getCurrentTransform().getScale();
        try self.draw_commands.append(.{
            .cmd = .{
                .ngon_fill = .{
                    .p = self.getCurrentTransform().transformPoint(center),
                    .radius = radius * scale.x,
                    .color = color.toInternalColor(),
                    .num_segments = num_segments,
                },
            },
            .depth = opt.depth,
        });
    }

    pub const BezierCubicOption = struct {
        thickness: f32 = 1.0,
        num_segments: u32 = 0,
        depth: f32 = 0.5,
    };
    pub fn bezierCubic(
        self: *Batch,
        p1: jok.Point,
        p2: jok.Point,
        p3: jok.Point,
        p4: jok.Point,
        color: jok.Color,
        opt: BezierCubicOption,
    ) !void {
        assert(self.id != invalid_batch_id);
        assert(!self.is_submitted);
        try self.draw_commands.append(.{
            .cmd = .{
                .bezier_cubic = .{
                    .p1 = self.getCurrentTransform().transformPoint(p1),
                    .p2 = self.getCurrentTransform().transformPoint(p2),
                    .p3 = self.getCurrentTransform().transformPoint(p3),
                    .p4 = self.getCurrentTransform().transformPoint(p4),
                    .color = color.toInternalColor(),
                    .thickness = opt.thickness,
                    .num_segments = opt.num_segments,
                },
            },
            .depth = opt.depth,
        });
    }

    pub const BezierQuadraticOption = struct {
        thickness: f32 = 1.0,
        num_segments: u32 = 0,
        depth: f32 = 0.5,
    };
    pub fn bezierQuadratic(
        self: *Batch,
        p1: jok.Point,
        p2: jok.Point,
        p3: jok.Point,
        color: jok.Color,
        opt: BezierQuadraticOption,
    ) !void {
        assert(self.id != invalid_batch_id);
        assert(!self.is_submitted);
        try self.draw_commands.append(.{
            .cmd = .{
                .bezier_quadratic = .{
                    .p1 = self.getCurrentTransform().transformPoint(p1),
                    .p2 = self.getCurrentTransform().transformPoint(p2),
                    .p3 = self.getCurrentTransform().transformPoint(p3),
                    .color = color.toInternalColor(),
                    .thickness = opt.thickness,
                    .num_segments = opt.num_segments,
                },
            },
            .depth = opt.depth,
        });
    }

    pub const PolyOption = struct {
        thickness: f32 = 1.0,
        depth: f32 = 0.5,
    };
    pub fn convexPoly(
        self: *Batch,
        poly: ConvexPoly,
        color: jok.Color,
        opt: PolyOption,
    ) !void {
        assert(self.id != invalid_batch_id);
        assert(!self.is_submitted);
        if (!poly.finished) return error.PathNotFinished;
        try self.draw_commands.append(.{
            .cmd = .{
                .convex_polygon = .{
                    .points = poly.points,
                    .color = color.toInternalColor(),
                    .thickness = opt.thickness,
                    .transform = self.getCurrentTransform(),
                },
            },
            .depth = opt.depth,
        });
    }

    pub const FillPoly = struct {
        depth: f32 = 0.5,
    };
    pub fn convexPolyFilled(
        self: *Batch,
        poly: ConvexPoly,
        opt: FillPoly,
    ) !void {
        assert(self.id != invalid_batch_id);
        assert(!self.is_submitted);
        if (!poly.finished) return error.PathNotFinished;
        try self.draw_commands.append(.{
            .cmd = .{
                .convex_polygon_fill = .{
                    .points = poly.points,
                    .texture = poly.texture,
                    .transform = self.getCurrentTransform(),
                },
            },
            .depth = opt.depth,
        });
    }

    pub const PolylineOption = struct {
        thickness: f32 = 1.0,
        closed: bool = false,
        depth: f32 = 0.5,
    };
    pub fn polyline(
        self: *Batch,
        pl: Polyline,
        color: jok.Color,
        opt: PolylineOption,
    ) !void {
        assert(self.id != invalid_batch_id);
        assert(!self.is_submitted);
        if (!pl.finished) return error.PathNotFinished;
        try self.draw_commands.append(.{
            .cmd = .{
                .polyline = .{
                    .points = pl.points,
                    .transformed = pl.transformed,
                    .color = color.toInternalColor(),
                    .thickness = opt.thickness,
                    .closed = opt.closed,
                    .transform = self.getCurrentTransform(),
                },
            },
            .depth = opt.depth,
        });
    }

    pub const PathOption = struct {
        depth: f32 = 0.5,
    };
    pub fn path(self: *Batch, p: Path, opt: PathOption) !void {
        assert(self.id != invalid_batch_id);
        assert(!self.is_submitted);
        if (!p.finished) return error.PathNotFinished;
        var rpath = p.path;
        rpath.transform = self.getCurrentTransform();
        try self.draw_commands.append(.{
            .cmd = .{ .path = rpath },
            .depth = opt.depth,
        });
    }

    pub fn pushDrawCommand(self: *Batch, _dcmd: DrawCmd) !void {
        var dcmd = _dcmd;
        switch (dcmd.cmd) {
            .quad_image => |*cmd| {
                cmd.p1 = self.getCurrentTransform().transformPoint(cmd.p1);
                cmd.p2 = self.getCurrentTransform().transformPoint(cmd.p2);
                cmd.p3 = self.getCurrentTransform().transformPoint(cmd.p3);
                cmd.p4 = self.getCurrentTransform().transformPoint(cmd.p4);
            },
            .image_rounded => |*cmd| {
                cmd.pmin = self.getCurrentTransform().transformPoint(cmd.pmin);
                cmd.pmax = self.getCurrentTransform().transformPoint(cmd.pmax);
            },
            .line => |*cmd| {
                cmd.p1 = self.getCurrentTransform().transformPoint(cmd.p1);
                cmd.p2 = self.getCurrentTransform().transformPoint(cmd.p2);
            },
            .rect_rounded => |*cmd| {
                cmd.pmin = self.getCurrentTransform().transformPoint(cmd.pmin);
                cmd.pmax = self.getCurrentTransform().transformPoint(cmd.pmax);
            },
            .rect_rounded_fill => |*cmd| {
                cmd.pmin = self.getCurrentTransform().transformPoint(cmd.pmin);
                cmd.pmax = self.getCurrentTransform().transformPoint(cmd.pmax);
            },
            .quad => |*cmd| {
                cmd.p1 = self.getCurrentTransform().transformPoint(cmd.p1);
                cmd.p2 = self.getCurrentTransform().transformPoint(cmd.p2);
                cmd.p3 = self.getCurrentTransform().transformPoint(cmd.p3);
                cmd.p4 = self.getCurrentTransform().transformPoint(cmd.p4);
            },
            .quad_fill => |*cmd| {
                cmd.p1 = self.getCurrentTransform().transformPoint(cmd.p1);
                cmd.p2 = self.getCurrentTransform().transformPoint(cmd.p2);
                cmd.p3 = self.getCurrentTransform().transformPoint(cmd.p3);
                cmd.p4 = self.getCurrentTransform().transformPoint(cmd.p4);
            },
            .triangle => |*cmd| {
                cmd.p1 = self.getCurrentTransform().transformPoint(cmd.p1);
                cmd.p2 = self.getCurrentTransform().transformPoint(cmd.p2);
                cmd.p3 = self.getCurrentTransform().transformPoint(cmd.p3);
            },
            .triangle_fill => |*cmd| {
                cmd.p1 = self.getCurrentTransform().transformPoint(cmd.p1);
                cmd.p2 = self.getCurrentTransform().transformPoint(cmd.p2);
                cmd.p3 = self.getCurrentTransform().transformPoint(cmd.p3);
            },
            .circle => |*cmd| {
                cmd.p = self.getCurrentTransform().transformPoint(cmd.p);
                cmd.radius *= self.getCurrentTransform().getScale().x;
            },
            .circle_fill => |*cmd| {
                cmd.p = self.getCurrentTransform().transformPoint(cmd.p);
                cmd.radius *= self.getCurrentTransform().getScale().x;
            },
            .ngon => |*cmd| {
                cmd.p = self.getCurrentTransform().transformPoint(cmd.p);
                cmd.radius *= self.getCurrentTransform().getScale().x;
            },
            .ngon_fill => |*cmd| {
                cmd.p = self.getCurrentTransform().transformPoint(cmd.p);
                cmd.radius *= self.getCurrentTransform().getScale().x;
            },
            .convex_polygon => |*cmd| {
                cmd.transform = self.getCurrentTransform();
            },
            .convex_polygon_fill => |*cmd| {
                cmd.transform = self.getCurrentTransform();
            },
            .bezier_cubic => |*cmd| {
                cmd.p1 = self.getCurrentTransform().transformPoint(cmd.p1);
                cmd.p2 = self.getCurrentTransform().transformPoint(cmd.p2);
                cmd.p3 = self.getCurrentTransform().transformPoint(cmd.p3);
                cmd.p4 = self.getCurrentTransform().transformPoint(cmd.p4);
            },
            .bezier_quadratic => |*cmd| {
                cmd.p1 = self.getCurrentTransform().transformPoint(cmd.p1);
                cmd.p2 = self.getCurrentTransform().transformPoint(cmd.p2);
                cmd.p3 = self.getCurrentTransform().transformPoint(cmd.p3);
            },
            .polyline => |*cmd| {
                assert(cmd.transformed.items.len >= cmd.points.items.len);
                cmd.transform = self.getCurrentTransform();
            },
            .path => |*cmd| {
                cmd.transform = self.getCurrentTransform();
            },
        }
        try self.draw_commands.append(dcmd);
    }
};

pub const ConvexPoly = struct {
    texture: ?jok.Texture,
    points: std.ArrayList(jok.Vertex),
    finished: bool = false,

    pub fn begin(allocator: std.mem.Allocator, texture: ?jok.Texture) ConvexPoly {
        return .{
            .texture = texture,
            .points = std.ArrayList(jok.Vertex).init(allocator),
        };
    }

    pub fn end(self: *ConvexPoly) void {
        self.finished = true;
    }

    pub fn deinit(self: *ConvexPoly) void {
        self.points.deinit();
        self.* = undefined;
    }

    pub fn reset(self: *ConvexPoly, texture: ?jok.Texture) void {
        self.texture = texture;
        self.points.clearRetainingCapacity();
        self.finished = false;
    }

    pub fn point(self: *ConvexPoly, p: jok.Vertex) !void {
        assert(!self.finished);
        try self.cmd.points.append(p);
    }

    pub fn npoints(self: *ConvexPoly, ps: []jok.Vertex) !void {
        assert(!self.finished);
        try self.cmd.points.appendSlice(ps);
    }
};

pub const Polyline = struct {
    points: std.ArrayList(jok.Point),
    transformed: std.ArrayList(jok.Point),
    finished: bool = false,

    pub fn begin(allocator: std.mem.Allocator) Polyline {
        return .{
            .points = std.ArrayList(jok.Point).init(allocator),
            .transformed = std.ArrayList(jok.Point).init(allocator),
        };
    }

    pub fn end(self: *Polyline) void {
        self.transformed.appendNTimes(
            .{ .x = 0, .y = 0 },
            self.points.items.len,
        ) catch unreachable;
        self.finished = true;
    }

    pub fn deinit(self: *Polyline) void {
        self.points.deinit();
        self.transformed.deinit();
        self.* = undefined;
    }

    pub fn reset(self: *Polyline, cleardata: bool) void {
        if (cleardata) {
            self.points.clearRetainingCapacity();
        }
        self.transformed.clearRetainingCapacity();
        self.finished = false;
    }

    pub fn point(self: *Polyline, p: jok.Point) !void {
        assert(!self.finished);
        try self.points.append(p);
    }

    pub fn npoints(self: *Polyline, ps: []jok.Point) !void {
        assert(!self.finished);
        try self.points.appendSlice(ps);
    }
};

pub const Path = struct {
    path: internal.PathCmd,
    finished: bool = false,

    /// Begin definition of path
    pub fn begin(allocator: std.mem.Allocator) Path {
        return .{
            .path = internal.PathCmd.init(allocator),
        };
    }

    /// End definition of path
    pub const PathEnd = struct {
        color: jok.Color = jok.Color.white,
        thickness: f32 = 1.0,
        closed: bool = false,
    };
    pub fn end(
        self: *Path,
        method: internal.PathCmd.DrawMethod,
        opt: PathEnd,
    ) void {
        self.path.draw_method = method;
        self.path.color = opt.color.toInternalColor();
        self.path.thickness = opt.thickness;
        self.path.closed = opt.closed;
        self.finished = true;
    }

    pub fn deinit(self: *Path) void {
        self.path.deinit();
        self.* = undefined;
    }

    pub fn reset(self: *Path, cleardata: bool) void {
        if (cleardata) {
            self.path.cmds.clearRetainingCapacity();
        }
        self.finished = false;
    }

    pub fn lineTo(self: *Path, pos: jok.Point) !void {
        assert(!self.finished);
        try self.path.cmds.append(.{ .line_to = .{ .p = pos } });
    }

    pub const ArcTo = struct {
        num_segments: u32 = 0,
    };
    pub fn arcTo(
        self: *Path,
        pos: jok.Point,
        radius: f32,
        degree_begin: f32,
        degree_end: f32,
        opt: ArcTo,
    ) !void {
        assert(!self.finished);
        try self.path.cmds.append(.{
            .arc_to = .{
                .p = pos,
                .radius = radius,
                .amin = std.math.degreesToRadians(degree_begin),
                .amax = std.math.degreesToRadians(degree_end),
                .num_segments = opt.num_segments,
            },
        });
    }

    pub const BezierCurveTo = struct {
        num_segments: u32 = 0,
    };
    pub fn bezierCubicCurveTo(
        self: *Path,
        p2: jok.Point,
        p3: jok.Point,
        p4: jok.Point,
        opt: BezierCurveTo,
    ) !void {
        assert(!self.finished);
        try self.path.cmds.append(.{
            .bezier_cubic_to = .{
                .p2 = p2,
                .p3 = p3,
                .p4 = p4,
                .num_segments = opt.num_segments,
            },
        });
    }
    pub fn bezierQuadraticCurveTo(
        self: *Path,
        p2: jok.Point,
        p3: jok.Point,
        opt: BezierCurveTo,
    ) !void {
        assert(!self.finished);
        try self.path.cmds.append(.{
            .bezier_quadratic_to = .{
                .p2 = p2,
                .p3 = p3,
                .num_segments = opt.num_segments,
            },
        });
    }

    /// NOTE: Rounded rectangle is always axis-aligned
    pub const Rect = struct {
        rounding: f32 = 4,
    };
    pub fn rect(
        self: *Path,
        r: jok.Rectangle,
        opt: Rect,
    ) !void {
        assert(!self.finished);
        const pmin = jok.Point{ .x = r.x, .y = r.y };
        const pmax = jok.Point{
            .x = pmin.x + r.width,
            .y = pmin.y + r.height,
        };
        try self.path.cmds.append(.{
            .rect_rounded = .{
                .pmin = pmin,
                .pmax = pmax,
                .rounding = opt.rounding,
            },
        });
    }
};

pub fn BatchPool(comptime pool_size: usize, comptime thread_safe: bool) type {
    const AllocSet = std.StaticBitSet(pool_size);
    const mutex_init = if (thread_safe)
        std.Thread.Mutex{}
    else
        DummyMutex{};

    return struct {
        ctx: jok.Context,
        alloc_set: AllocSet,
        batches: []Batch,
        mutex: @TypeOf(mutex_init),

        pub fn init(_ctx: jok.Context) !@This() {
            const bs = try _ctx.allocator().alloc(Batch, pool_size);
            for (bs) |*b| {
                b.* = Batch.init(_ctx);
            }
            return .{
                .ctx = _ctx,
                .alloc_set = AllocSet.initFull(),
                .batches = bs,
                .mutex = mutex_init,
            };
        }

        pub fn deinit(self: *@This()) void {
            for (self.batches) |*b| b.deinit();
            self.ctx.allocator().free(self.batches);
        }

        fn allocBatch(self: *@This()) !*Batch {
            self.mutex.lock();
            defer self.mutex.unlock();
            if (self.alloc_set.count() == 0) {
                return error.TooManyBatches;
            }
            const idx = self.alloc_set.toggleFirstSet().?;
            var b = &self.batches[idx];
            b.id = idx;
            b.reclaimer = .{
                .ptr = @ptrCast(self),
                .vtable = .{
                    .reclaim = reclaim,
                },
            };
            return b;
        }

        fn reclaim(ptr: *anyopaque, b: *Batch) void {
            const self: *@This() = @ptrCast(@alignCast(ptr));
            assert(&self.batches[b.id] == b);
            self.mutex.lock();
            defer self.mutex.unlock();
            self.alloc_set.set(b.id);
            b.id = invalid_batch_id;
            b.reclaimer = undefined;
        }

        /// Recycle all internally reserved memories.
        ///
        /// NOTE: should only be used when no batch is being used.
        pub fn recycleMemory(self: @This()) void {
            self.mutex.lock();
            defer self.mutex.unlock();
            assert(self.alloc_set.count() == pool_size);
            for (self.batches) |*b| b.recycleMemory();
        }

        /// Allocate and initialize new batch
        pub fn new(self: *@This(), opt: BatchOption) !*Batch {
            var b = try self.allocBatch();
            b.reset(opt);
            return b;
        }
    };
}

const DummyMutex = struct {
    fn lock(_: *DummyMutex) void {}
    fn unlock(_: *DummyMutex) void {}
};

const BatchReclaimer = struct {
    ptr: *anyopaque,
    vtable: VTable,

    const VTable = struct {
        reclaim: *const fn (ctx: *anyopaque, b: *Batch) void,
    };

    fn reclaim(self: BatchReclaimer, b: *Batch) void {
        self.vtable.reclaim(self.ptr, b);
    }
};

test "j2d" {
    _ = Vector;
}
