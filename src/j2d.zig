const std = @import("std");
const builtin = @import("builtin");
const assert = std.debug.assert;
const math = std.math;
const ascii = std.ascii;
const unicode = std.unicode;
const jok = @import("jok.zig");
const font = jok.font;
const zgui = jok.vendor.zgui;
const zmath = jok.vendor.zmath;
const zmesh = jok.vendor.zmesh;
const log = std.log.scoped(.jok);

const internal = @import("j2d/internal.zig");
pub const DrawCmd = internal.DrawCmd;
pub const AffineTransform = @import("j2d/AffineTransform.zig");
pub const Sprite = @import("j2d/Sprite.zig");
pub const SpriteSheet = @import("j2d/SpriteSheet.zig");
pub const ParticleSystem = @import("j2d/ParticleSystem.zig");
pub const AnimationSystem = @import("j2d/AnimationSystem.zig").AnimationSystem;
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
    do_early_clipping: bool = false,
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
    draw_list: zgui.DrawList,
    draw_commands: std.array_list.Managed(DrawCmd),
    trs_stack: std.array_list.Managed(AffineTransform),
    trs: AffineTransform,
    depth_sort: DepthSortMethod,
    blend_mode: jok.BlendMode,
    clip_rect: jok.Rectangle = undefined,
    do_early_clipping: bool,
    offscreen_target: ?jok.Texture,
    offscreen_clear_color: ?jok.Color,
    all_tex: std.AutoHashMap(*anyopaque, bool),

    fn init(_ctx: jok.Context) Batch {
        return .{
            .ctx = _ctx,
            .draw_list = zgui.createDrawList(),
            .draw_commands = .init(_ctx.allocator()),
            .trs_stack = .init(_ctx.allocator()),
            .trs = undefined,
            .depth_sort = .none,
            .blend_mode = .blend,
            .do_early_clipping = false,
            .offscreen_target = null,
            .offscreen_clear_color = null,
            .all_tex = .init(_ctx.allocator()),
        };
    }

    fn deinit(self: *Batch) void {
        self.trs_stack.deinit();
        zgui.destroyDrawList(self.draw_list);
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

        self.draw_commands.clearRetainingCapacity();
        self.all_tex.clearRetainingCapacity();
        self.trs_stack.clearRetainingCapacity();
        self.trs = AffineTransform.init();
        self.depth_sort = opt.depth_sort;
        self.blend_mode = opt.blend_mode;
        self.do_early_clipping = opt.do_early_clipping;
        self.offscreen_target = opt.offscreen_target;
        self.offscreen_clear_color = opt.offscreen_clear_color;
        if (self.offscreen_target) |t| {
            const info = t.query() catch unreachable;
            if (info.access != .target) {
                @panic("Given texture isn't suitable for offscreen rendering!");
            }
        }

        self.clip_rect = opt.clip_rect orelse BLK: {
            if (opt.offscreen_target) |tex| {
                const info = tex.query() catch unreachable;
                break :BLK .{
                    .x = 0,
                    .y = 0,
                    .width = @floatFromInt(info.width),
                    .height = @floatFromInt(info.height),
                };
            }
            const csz = self.ctx.getCanvasSize();
            break :BLK .{
                .x = 0,
                .y = 0,
                .width = csz.getWidthFloat(),
                .height = csz.getHeightFloat(),
            };
        };
        self.draw_list.reset();
        self.draw_list.pushClipRect(.{
            .pmin = .{ self.clip_rect.x, self.clip_rect.y },
            .pmax = .{
                self.clip_rect.x + self.clip_rect.width,
                self.clip_rect.y + self.clip_rect.height,
            },
        });
        if (opt.antialiased) {
            self.draw_list.setDrawListFlags(.{
                .anti_aliased_lines = true,
                .anti_aliased_lines_use_tex = false,
                .anti_aliased_fill = true,
                .allow_vtx_offset = true,
            });
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
        assert(self.ctx.isMainThread());

        defer self.is_submitted = true;

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
                if (self.do_early_clipping) {
                    if (self.clip_rect.intersectRect(dcmd.getRect()) != null) {
                        dcmd.render(self.draw_list);
                    }
                } else {
                    dcmd.render(self.draw_list);
                }
            }
        }

        // Apply blend mode to renderer and textures
        const rd = self.ctx.renderer();
        const old_blend = rd.getBlendMode() catch unreachable;
        defer rd.setBlendMode(old_blend) catch unreachable;
        rd.setBlendMode(self.blend_mode) catch unreachable;
        var it = self.all_tex.keyIterator();
        while (it.next()) |k| {
            const tex = jok.Texture{ .ptr = @ptrCast(@alignCast(k.*)) };
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
        zgui.sdl.renderDrawList(self.ctx, self.draw_list);
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

    pub fn pushTransform(self: *Batch) !void {
        assert(self.id != invalid_batch_id);
        assert(!self.is_submitted);
        try self.trs_stack.append(self.trs);
    }

    pub fn popTransform(self: *Batch) void {
        assert(self.id != invalid_batch_id);
        assert(!self.is_submitted);
        assert(self.trs_stack.items.len > 0);
        self.trs = self.trs_stack.pop().?;
    }

    pub fn setIdentity(self: *Batch) void {
        self.trs = AffineTransform.init();
    }

    pub fn translate(self: *Batch, v: [2]f32) void {
        self.trs = self.trs.translate(v);
    }

    pub fn rotateByWorldOrigin(self: *Batch, radian: f32) void {
        self.trs = self.trs.rotateByOrigin(radian);
    }

    pub fn rotateByLocalOrigin(self: *Batch, radian: f32) void {
        const t = self.trs.getTranslation();
        self.trs = self.trs.rotateByPoint(.{ .x = t[0], .y = t[1] }, radian);
    }

    pub fn rotateByPoint(self: *Batch, p: jok.Point, radian: f32) void {
        self.trs = self.trs.rotateByPoint(p, radian);
    }

    pub fn scaleAroundWorldOrigin(self: *Batch, v: [2]f32) void {
        self.trs = self.trs.scaleAroundOrigin(v);
    }

    pub fn scaleAroundLocalOrigin(self: *Batch, v: [2]f32) void {
        const t = self.trs.getTranslation();
        self.trs = self.trs.scaleAroundPoint(.{ .x = t[0], .y = t[1] }, v);
    }

    pub fn scaleAroundPoint(self: *Batch, p: jok.Point, v: [2]f32) void {
        self.trs = self.trs.scaleAroundPoint(p, v);
    }

    pub const ImageOption = struct {
        size: ?jok.Size = null,
        uv0: jok.Point = .origin,
        uv1: jok.Point = .unit,
        tint_color: jok.Color = .white,
        scale: jok.Point = .unit,
        rotate_angle: f32 = 0,
        anchor_point: jok.Point = .anchor_top_left,
        flip_h: bool = false,
        flip_v: bool = false,
        depth: f32 = 0.5,
    };
    pub fn image(self: *Batch, texture: jok.Texture, pos: jok.Point, opt: ImageOption) !void {
        assert(self.id != invalid_batch_id);
        assert(!self.is_submitted);
        const scaling = self.trs.getScale();
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
            .pos = self.trs.transformPoint(pos),
            .tint_color = opt.tint_color,
            .scale = .{ .x = scaling[0] * opt.scale.x, .y = scaling[1] * opt.scale.y },
            .rotate_angle = opt.rotate_angle + self.trs.getRotation(),
            .anchor_point = opt.anchor_point,
            .flip_h = opt.flip_h,
            .flip_v = opt.flip_v,
            .depth = opt.depth,
        });
    }

    /// NOTE: Rounded image is always aligned with axis of world
    pub const ImageRoundedOption = struct {
        size: ?jok.Size = null,
        uv0: jok.Point = .origin,
        uv1: jok.Point = .unit,
        anchor_point: jok.Point = .anchor_top_left,
        tint_color: jok.Color = .white,
        flip_h: bool = false,
        flip_v: bool = false,
        rounding: f32 = 4,
        corner_top_left: bool = true,
        corner_top_right: bool = true,
        corner_bottom_left: bool = true,
        corner_bottom_right: bool = true,
        depth: f32 = 0.5,
    };
    pub fn imageRounded(self: *Batch, texture: jok.Texture, pos: jok.Point, opt: ImageRoundedOption) !void {
        assert(self.id != invalid_batch_id);
        assert(!self.is_submitted);
        assert(opt.anchor_point.x >= 0 and opt.anchor_point.x <= 1);
        assert(opt.anchor_point.y >= 0 and opt.anchor_point.y <= 1);
        var uv0 = opt.uv0;
        var uv1 = opt.uv1;
        if (opt.flip_h) std.mem.swap(f32, &uv0.x, &uv1.x);
        if (opt.flip_v) std.mem.swap(f32, &uv0.y, &uv1.y);
        const _size: jok.Point = if (opt.size) |sz|
            sz.toPoint()
        else BLK: {
            const info = try texture.query();
            break :BLK .{
                .x = @floatFromInt(info.width),
                .y = @floatFromInt(info.height),
            };
        };
        const size: @Vector(2, f32) = _size.mul(self.trs.getScale()).toArray();
        const pmin = pos.add(self.trs.getTranslation()).sub(size * opt.anchor_point.toArray());
        const pmax = pmin.add(size);
        try self.pushDrawCommand(.{
            .cmd = .{
                .image_rounded = .{
                    .texture = texture,
                    .pmin = pmin,
                    .pmax = pmax,
                    .uv0 = uv0,
                    .uv1 = uv1,
                    .tint_color = opt.tint_color.toInternalColor(),
                    .rounding = opt.rounding,
                    .corner_top_left = opt.corner_top_left,
                    .corner_top_right = opt.corner_top_right,
                    .corner_bottom_left = opt.corner_bottom_left,
                    .corner_bottom_right = opt.corner_bottom_right,
                },
            },
            .depth = opt.depth,
        });
    }

    pub fn scene(self: *Batch, s: *const Scene) !void {
        assert(self.id != invalid_batch_id);
        assert(!self.is_submitted);
        try s.render(&self.draw_commands, .{ .transform = self.trs });
    }

    pub fn effect(self: *Batch, e: *const ParticleSystem.Effect) !void {
        assert(self.id != invalid_batch_id);
        assert(!self.is_submitted);
        try e.render(&self.draw_commands, .{ .transform = self.trs });
    }

    pub const SpriteOption = struct {
        pos: jok.Point = .origin,
        tint_color: jok.Color = .white,
        scale: jok.Point = .unit,
        rotate_angle: f32 = 0,
        anchor_point: jok.Point = .anchor_top_left,
        flip_h: bool = false,
        flip_v: bool = false,
        depth: f32 = 0.5,
    };
    pub fn sprite(self: *Batch, s: Sprite, opt: SpriteOption) !void {
        assert(self.id != invalid_batch_id);
        assert(!self.is_submitted);
        const scaling = self.trs.getScale();
        try s.render(&self.draw_commands, .{
            .pos = self.trs.transformPoint(opt.pos),
            .tint_color = opt.tint_color,
            .scale = .{ .x = scaling[0] * opt.scale.x, .y = scaling[1] * opt.scale.y },
            .rotate_angle = opt.rotate_angle + self.trs.getRotation(),
            .anchor_point = opt.anchor_point,
            .flip_h = opt.flip_h,
            .flip_v = opt.flip_v,
            .depth = opt.depth,
        });
    }

    pub const TextOption = struct {
        pos: jok.Point = .origin,
        atlas: ?*font.Atlas = null,
        ignore_unexist: bool = true,
        ypos_type: font.Atlas.YPosType = .top,
        align_type: font.Atlas.AlignType = .left,
        align_width: ?u32 = null,
        auto_hyphen: bool = false,
        kerning: bool = false,
        tint_color: jok.Color = .white,
        scale: jok.Point = .unit,
        rotate_angle: f32 = 0,
        depth: f32 = 0.5,
    };
    pub fn text(self: *Batch, comptime fmt: []const u8, args: anytype, opt: TextOption) !void {
        assert(self.id != invalid_batch_id);
        assert(!self.is_submitted);
        const txt = zgui.format(fmt, args);
        if (txt.len == 0) return;
        const atlas = opt.atlas orelse self.ctx.getDebugAtlas(
            @intCast(self.ctx.cfg().jok_prebuild_atlas),
        );
        const rotation = opt.rotate_angle + self.trs.getRotation();
        var pos = self.trs.transformPoint(opt.pos);
        const begin_x = pos.x;
        const scaling = opt.scale.mul(self.trs.getScale());
        const mat = zmath.mul(
            zmath.mul(
                zmath.translation(-pos.x, -pos.y, 0),
                zmath.rotationZ(rotation),
            ),
            zmath.translation(pos.x, pos.y, 0),
        );

        if (opt.align_type != .left) {
            const bbox = try atlas.getBoundingBox(
                std.mem.sliceTo(txt, '\n'),
                pos,
                .{
                    .ypos_type = opt.ypos_type,
                    .align_type = opt.align_type,
                    .align_width = opt.align_width,
                    .kerning = opt.kerning,
                    .scale = scaling,
                },
            );
            if (opt.align_type == .middle) {
                pos.x -= bbox.width / 2;
            } else if (opt.align_type == .right) {
                pos.x -= bbox.width;
            }
        }

        var align_width: f32 = math.inf(f32);
        if (opt.align_width) |w| {
            align_width = @as(f32, @floatFromInt(w)) * scaling.x;
        }

        var wrapped = false;
        var line_x = pos.x;
        var last_size: u32 = 0;
        var last_codepoint: u32 = 0;
        var i: u32 = 0;
        while (i < txt.len) {
            const size = try unicode.utf8ByteSequenceLength(txt[i]);
            const u8letter = txt[i .. i + size];
            var codepoint = @as(u32, @intCast(try unicode.utf8Decode(u8letter)));

            // Kerning adjustment
            pos.x += if (opt.kerning and last_codepoint > 0)
                scaling.x * atlas.getKerningInPixels(last_codepoint, codepoint)
            else
                0;

            if (wrapped or pos.x - line_x >= align_width) {
                // Wrapping text
                wrapped = false;
                pos = .{
                    .x = begin_x,
                    .y = pos.y + (atlas.getVPosOfNextLine(pos.y) - pos.y) * scaling.y,
                };
                if (opt.align_type != .left) {
                    const bbox = try atlas.getBoundingBox(
                        std.mem.sliceTo(txt[i..], '\n'),
                        pos,
                        .{
                            .ypos_type = opt.ypos_type,
                            .align_type = opt.align_type,
                            .align_width = opt.align_width,
                            .kerning = opt.kerning,
                            .scale = scaling,
                        },
                    );
                    if (opt.align_type == .middle) {
                        pos.x -= bbox.width * 0.5;
                    } else if (opt.align_type == .right) {
                        pos.x -= bbox.width;
                    }
                }
                line_x = pos.x;
            } else if (opt.align_width != null and i < txt.len - 1) {
                // Add hyphen at the end of line when possible
                if (opt.auto_hyphen and last_size == 1 and size == 1 and
                    ascii.isAlphabetic(@intCast(codepoint)) and
                    (ascii.isAlphabetic(@intCast(last_codepoint)) or ascii.isWhitespace(@intCast(last_codepoint))))
                {
                    // Check if this is last character of the line
                    const new_x = pos.x + (atlas.getVerticesOfCodePoint(
                        pos,
                        opt.ypos_type,
                        .white,
                        codepoint,
                    ).?.next_x - pos.x) * scaling.x;
                    if (new_x - line_x >= align_width) {
                        wrapped = true;
                        codepoint = if (ascii.isWhitespace(@intCast(last_codepoint))) ' ' else '-';
                    }
                }
            }

            // Save state and step to next codepoint
            if (!wrapped) {
                i += size;
                last_codepoint = codepoint;
                last_size = size;
                if (size == 1 and codepoint == '\n') {
                    wrapped = true;
                    continue;
                }
            }

            // Render current codepoint
            if (atlas.getVerticesOfCodePoint(
                pos,
                opt.ypos_type,
                .white,
                codepoint,
            )) |cs| {
                const v = zmath.mul(
                    zmath.f32x4(
                        cs.vs[0].pos.x,
                        pos.y + (cs.vs[0].pos.y - pos.y) * scaling.y,
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
                    .tex = atlas.tex,
                };
                try s.render(&self.draw_commands, .{
                    .pos = draw_pos,
                    .tint_color = opt.tint_color,
                    .scale = scaling,
                    .rotate_angle = rotation,
                    .depth = opt.depth,
                });
                pos.x += (cs.next_x - pos.x) * scaling.x;
            } else if (!opt.ignore_unexist) {
                log.err("Doesn't support character: {s}({x})", .{ u8letter, codepoint });
                return error.UnsupportedCodepoint;
            }
        }
    }

    pub const LineOption = struct {
        thickness: f32 = 1.0,
        depth: f32 = 0.5,
    };
    pub fn line(self: *Batch, p1: jok.Point, p2: jok.Point, color: jok.Color, opt: LineOption) !void {
        assert(self.id != invalid_batch_id);
        assert(!self.is_submitted);
        try self.pushDrawCommand(.{
            .cmd = .{
                .line = .{
                    .p1 = p1,
                    .p2 = p2,
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
        try self.pushDrawCommand(.{
            .cmd = .{
                .quad = .{
                    .p1 = p1,
                    .p2 = p2,
                    .p3 = p3,
                    .p4 = p4,
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
        try self.pushDrawCommand(.{
            .cmd = .{
                .quad_fill = .{
                    .p1 = p1,
                    .p2 = p2,
                    .p3 = p3,
                    .p4 = p4,
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
        try self.pushDrawCommand(.{
            .cmd = .{
                .quad_fill = .{
                    .p1 = p1,
                    .p2 = p2,
                    .p3 = p3,
                    .p4 = p4,
                    .color1 = c1,
                    .color2 = c2,
                    .color3 = c3,
                    .color4 = c4,
                },
            },
            .depth = opt.depth,
        });
    }

    /// NOTE: Rounded rectangle is always aligned with world axis
    pub const RectRoundedOption = struct {
        anchor_point: jok.Point = .anchor_top_left,
        thickness: f32 = 1.0,
        rounding: f32 = 4,
        corner_top_left: bool = true,
        corner_top_right: bool = true,
        corner_bottom_left: bool = true,
        corner_bottom_right: bool = true,
        depth: f32 = 0.5,
    };
    pub fn rectRounded(self: *Batch, r: jok.Rectangle, color: jok.Color, opt: RectRoundedOption) !void {
        assert(self.id != invalid_batch_id);
        assert(!self.is_submitted);
        const size: @Vector(2, f32) = r.getSize().mul(self.trs.getScale()).toArray();
        const pmin = r.getPos().add(self.trs.getTranslation()).sub(size * opt.anchor_point.toArray());
        const pmax = pmin.add(size);
        try self.pushDrawCommand(.{
            .cmd = .{
                .rect_rounded = .{
                    .pmin = pmin,
                    .pmax = pmax,
                    .color = color.toInternalColor(),
                    .thickness = opt.thickness,
                    .rounding = opt.rounding,
                    .corner_top_left = opt.corner_top_left,
                    .corner_top_right = opt.corner_top_right,
                    .corner_bottom_left = opt.corner_bottom_left,
                    .corner_bottom_right = opt.corner_bottom_right,
                },
            },
            .depth = opt.depth,
        });
    }

    /// NOTE: Rounded rectangle is always aligned with world axis
    pub const FillRectRounded = struct {
        anchor_point: jok.Point = .anchor_top_left,
        rounding: f32 = 4,
        corner_top_left: bool = true,
        corner_top_right: bool = true,
        corner_bottom_left: bool = true,
        corner_bottom_right: bool = true,
        depth: f32 = 0.5,
    };
    pub fn rectRoundedFilled(self: *Batch, r: jok.Rectangle, color: jok.Color, opt: FillRectRounded) !void {
        assert(self.id != invalid_batch_id);
        assert(!self.is_submitted);
        const size: @Vector(2, f32) = r.getSize().mul(self.trs.getScale()).toArray();
        const pmin = r.getPos().add(self.trs.getTranslation()).sub(size * opt.anchor_point.toArray());
        const pmax = pmin.add(size);
        try self.pushDrawCommand(.{
            .cmd = .{
                .rect_rounded_fill = .{
                    .pmin = pmin,
                    .pmax = pmax,
                    .color = color.toInternalColor(),
                    .rounding = opt.rounding,
                    .corner_top_left = opt.corner_top_left,
                    .corner_top_right = opt.corner_top_right,
                    .corner_bottom_left = opt.corner_bottom_left,
                    .corner_bottom_right = opt.corner_bottom_right,
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
        try self.pushDrawCommand(.{
            .cmd = .{
                .quad = .{
                    .p1 = p1,
                    .p2 = p2,
                    .p3 = p3,
                    .p4 = p4,
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
        try self.pushDrawCommand(.{
            .cmd = .{
                .quad_fill = .{
                    .p1 = p1,
                    .p2 = p2,
                    .p3 = p3,
                    .p4 = p4,
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
        try self.pushDrawCommand(.{
            .cmd = .{
                .quad_fill = .{
                    .p1 = p1,
                    .p2 = p2,
                    .p3 = p3,
                    .p4 = p4,
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
        tri: jok.Triangle,
        color: jok.Color,
        opt: TriangleOption,
    ) !void {
        assert(self.id != invalid_batch_id);
        assert(!self.is_submitted);
        try self.pushDrawCommand(.{
            .cmd = .{
                .triangle = .{
                    .p1 = tri.p0,
                    .p2 = tri.p1,
                    .p3 = tri.p2,
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
        tri: jok.Triangle,
        color: jok.Color,
        opt: FillTriangle,
    ) !void {
        assert(self.id != invalid_batch_id);
        assert(!self.is_submitted);
        const c = color.toInternalColor();
        try self.pushDrawCommand(.{
            .cmd = .{
                .triangle_fill = .{
                    .p1 = tri.p0,
                    .p2 = tri.p1,
                    .p3 = tri.p2,
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
        tri: jok.Triangle,
        cs: [3]jok.Color,
        opt: FillTriangleMultiColor,
    ) !void {
        assert(self.id != invalid_batch_id);
        assert(!self.is_submitted);
        const c1 = cs[0].toInternalColor();
        const c2 = cs[1].toInternalColor();
        const c3 = cs[2].toInternalColor();
        try self.pushDrawCommand(.{
            .cmd = .{
                .triangle_fill = .{
                    .p1 = tri.p0,
                    .p2 = tri.p1,
                    .p3 = tri.p2,
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
        c: jok.Circle,
        color: jok.Color,
        opt: CircleOption,
    ) !void {
        assert(self.id != invalid_batch_id);
        assert(!self.is_submitted);
        try self.pushDrawCommand(.{
            .cmd = .{
                .circle = .{
                    .p = c.center,
                    .radius = c.radius,
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
        c: jok.Circle,
        color: jok.Color,
        opt: FillCircle,
    ) !void {
        assert(self.id != invalid_batch_id);
        assert(!self.is_submitted);
        try self.pushDrawCommand(.{
            .cmd = .{
                .circle_fill = .{
                    .p = c.center,
                    .radius = c.radius,
                    .color = color.toInternalColor(),
                    .num_segments = opt.num_segments,
                },
            },
            .depth = opt.depth,
        });
    }

    pub const EllipseOption = struct {
        rotate_angle: f32 = 0,
        thickness: f32 = 1.0,
        num_segments: u32 = 0,
        depth: f32 = 0.5,
    };
    pub fn ellipse(
        self: *Batch,
        c: jok.Ellipse,
        color: jok.Color,
        opt: EllipseOption,
    ) !void {
        assert(self.id != invalid_batch_id);
        assert(!self.is_submitted);
        try self.pushDrawCommand(.{
            .cmd = .{
                .ellipse = .{
                    .p = c.center,
                    .radius = c.radius,
                    .color = color.toInternalColor(),
                    .rotation = opt.rotate_angle + self.trs.getRotation(),
                    .thickness = opt.thickness,
                    .num_segments = opt.num_segments,
                },
            },
            .depth = opt.depth,
        });
    }

    pub const FillEllipse = struct {
        rotate_angle: f32 = 0,
        num_segments: u32 = 0,
        depth: f32 = 0.5,
    };
    pub fn ellipseFilled(
        self: *Batch,
        e: jok.Ellipse,
        color: jok.Color,
        opt: FillEllipse,
    ) !void {
        assert(self.id != invalid_batch_id);
        assert(!self.is_submitted);
        try self.pushDrawCommand(.{
            .cmd = .{
                .ellipse_fill = .{
                    .p = e.center,
                    .radius = e.radius,
                    .color = color.toInternalColor(),
                    .rotation = opt.rotate_angle + self.trs.getRotation(),
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
        try self.pushDrawCommand(.{
            .cmd = .{
                .ngon = .{
                    .p = center,
                    .radius = radius,
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
        try self.pushDrawCommand(.{
            .cmd = .{
                .ngon_fill = .{
                    .p = center,
                    .radius = radius,
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
        try self.pushDrawCommand(.{
            .cmd = .{
                .bezier_cubic = .{
                    .p1 = p1,
                    .p2 = p2,
                    .p3 = p3,
                    .p4 = p4,
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
        try self.pushDrawCommand(.{
            .cmd = .{
                .bezier_quadratic = .{
                    .p1 = p1,
                    .p2 = p2,
                    .p3 = p3,
                    .color = color.toInternalColor(),
                    .thickness = opt.thickness,
                    .num_segments = opt.num_segments,
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
        try self.pushDrawCommand(.{
            .cmd = .{
                .convex_polygon_fill = .{
                    .points = poly.points,
                    .texture = poly.texture,
                },
            },
            .depth = opt.depth,
        });
    }

    /// Probably not fast enough O(n^2), use it at your discretion
    pub fn concavePolyFilled(
        self: *Batch,
        poly: ConcavePoly,
        color: jok.Color,
        opt: FillPoly,
    ) !void {
        assert(self.id != invalid_batch_id);
        assert(!self.is_submitted);
        if (!poly.finished) return error.PathNotFinished;
        try self.pushDrawCommand(.{
            .cmd = .{
                .concave_polygon_fill = .{
                    .points = poly.points,
                    .transformed = poly.transformed,
                    .color = color.toInternalColor(),
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
        try self.pushDrawCommand(.{
            .cmd = .{
                .polyline = .{
                    .points = pl.points,
                    .transformed = pl.transformed,
                    .color = color.toInternalColor(),
                    .thickness = opt.thickness,
                    .closed = opt.closed,
                },
            },
            .depth = opt.depth,
        });
    }

    pub inline fn pushDrawCommand(self: *Batch, _dcmd: DrawCmd) !void {
        var dcmd = _dcmd;
        switch (dcmd.cmd) {
            .quad_image => |*cmd| {
                cmd.p1 = self.trs.transformPoint(cmd.p1);
                cmd.p2 = self.trs.transformPoint(cmd.p2);
                cmd.p3 = self.trs.transformPoint(cmd.p3);
                cmd.p4 = self.trs.transformPoint(cmd.p4);
            },
            .image_rounded => {
                // Nothing to do
            },
            .line => |*cmd| {
                cmd.p1 = self.trs.transformPoint(cmd.p1);
                cmd.p2 = self.trs.transformPoint(cmd.p2);
            },
            .rect_rounded => {
                // Nothing to do
            },
            .rect_rounded_fill => {
                // Nothing to do
            },
            .quad => |*cmd| {
                cmd.p1 = self.trs.transformPoint(cmd.p1);
                cmd.p2 = self.trs.transformPoint(cmd.p2);
                cmd.p3 = self.trs.transformPoint(cmd.p3);
                cmd.p4 = self.trs.transformPoint(cmd.p4);
            },
            .quad_fill => |*cmd| {
                cmd.p1 = self.trs.transformPoint(cmd.p1);
                cmd.p2 = self.trs.transformPoint(cmd.p2);
                cmd.p3 = self.trs.transformPoint(cmd.p3);
                cmd.p4 = self.trs.transformPoint(cmd.p4);
            },
            .triangle => |*cmd| {
                cmd.p1 = self.trs.transformPoint(cmd.p1);
                cmd.p2 = self.trs.transformPoint(cmd.p2);
                cmd.p3 = self.trs.transformPoint(cmd.p3);
            },
            .triangle_fill => |*cmd| {
                cmd.p1 = self.trs.transformPoint(cmd.p1);
                cmd.p2 = self.trs.transformPoint(cmd.p2);
                cmd.p3 = self.trs.transformPoint(cmd.p3);
            },
            .circle => |*cmd| {
                cmd.p = self.trs.transformPoint(cmd.p);
                cmd.radius *= self.trs.getScaleX();
            },
            .circle_fill => |*cmd| {
                cmd.p = self.trs.transformPoint(cmd.p);
                cmd.radius *= self.trs.getScaleX();
            },
            .ellipse => |*cmd| {
                cmd.p = self.trs.transformPoint(cmd.p);
                cmd.radius = cmd.radius.mul(self.trs.getScale());
            },
            .ellipse_fill => |*cmd| {
                cmd.p = self.trs.transformPoint(cmd.p);
                cmd.radius = cmd.radius.mul(self.trs.getScale());
            },
            .ngon => |*cmd| {
                cmd.p = self.trs.transformPoint(cmd.p);
                cmd.radius *= self.trs.getScaleX();
            },
            .ngon_fill => |*cmd| {
                cmd.p = self.trs.transformPoint(cmd.p);
                cmd.radius *= self.trs.getScaleX();
            },
            .convex_polygon_fill => |*cmd| {
                cmd.transform = self.trs;
            },
            .concave_polygon_fill => |*cmd| {
                assert(cmd.transformed.items.len >= cmd.points.items.len);
                cmd.transform = self.trs;
            },
            .bezier_cubic => |*cmd| {
                cmd.p1 = self.trs.transformPoint(cmd.p1);
                cmd.p2 = self.trs.transformPoint(cmd.p2);
                cmd.p3 = self.trs.transformPoint(cmd.p3);
                cmd.p4 = self.trs.transformPoint(cmd.p4);
            },
            .bezier_quadratic => |*cmd| {
                cmd.p1 = self.trs.transformPoint(cmd.p1);
                cmd.p2 = self.trs.transformPoint(cmd.p2);
                cmd.p3 = self.trs.transformPoint(cmd.p3);
            },
            .polyline => |*cmd| {
                assert(cmd.transformed.items.len >= cmd.points.items.len);
                cmd.transform = self.trs;
            },
        }
        try self.draw_commands.append(dcmd);
    }
};

pub const ConvexPoly = struct {
    texture: ?jok.Texture,
    points: std.array_list.Managed(jok.Vertex),
    finished: bool = false,

    pub fn begin(allocator: std.mem.Allocator, texture: ?jok.Texture) ConvexPoly {
        return .{
            .texture = texture,
            .points = .init(allocator),
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
        try self.points.append(p);
    }

    pub fn npoints(self: *ConvexPoly, ps: []jok.Vertex) !void {
        assert(!self.finished);
        try self.points.appendSlice(ps);
    }
};

pub const ConcavePoly = Polyline;

pub const Polyline = struct {
    points: std.array_list.Managed(jok.Point),
    transformed: std.array_list.Managed(jok.Point),
    finished: bool = false,

    pub fn begin(allocator: std.mem.Allocator) Polyline {
        return .{
            .points = .init(allocator),
            .transformed = .init(allocator),
        };
    }

    pub fn end(self: *Polyline) void {
        self.transformed.appendNTimes(.origin, self.points.items.len) catch unreachable;
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

pub fn BatchPool(comptime pool_size: usize, comptime thread_safe: bool) type {
    const AllocSet = std.StaticBitSet(pool_size);
    const mutex_init = if (thread_safe and !builtin.single_threaded)
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
