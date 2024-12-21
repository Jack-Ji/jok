const std = @import("std");
const builtin = @import("builtin");
const assert = std.debug.assert;
const math = std.math;
const jok = @import("jok.zig");
const imgui = jok.imgui;
const zmath = jok.zmath;
const zmesh = jok.zmesh;

const TriangleRenderer = @import("j3d/TriangleRenderer.zig");
const SkyboxRenderer = @import("j3d/SkyboxRenderer.zig");
pub const ShadingMethod = TriangleRenderer.ShadingMethod;
pub const LightingOption = lighting.LightingOption;
pub const Mesh = @import("j3d/Mesh.zig");
pub const Animation = @import("j3d/Animation.zig");
pub const lighting = @import("j3d/lighting.zig");
pub const ParticleSystem = @import("j3d/ParticleSystem.zig");
pub const Camera = @import("j3d/Camera.zig");
pub const Scene = @import("j3d/Scene.zig");
pub const Vector = @import("j3d/Vector.zig");

pub const RenderOption = struct {
    cull_faces: bool = true,
    color: jok.Color = jok.Color.white,
    shading_method: ShadingMethod = .gouraud,
    texture: ?jok.Texture = null,
    lighting: ?LightingOption = null,
};

pub const BatchOption = struct {
    camera: ?Camera = null,
    wireframe_color: ?jok.Color = null,
    triangle_sort: TriangleSort = .none,
    blend_mode: jok.BlendMode = .blend,
    clip_rect: ?jok.Rectangle = null,
    offscreen_target: ?jok.Texture = null,
    offscreen_clear_color: ?jok.Color = null,
};

pub const TriangleSort = union(enum(u8)) {
    // Send to gpu directly, use it when objects are ordered manually
    none,

    // Sort by average depth, use it when you are lazy (might hog cpu)
    simple,
};

const invalid_batch_id = std.math.maxInt(usize);

pub const Batch = struct {
    /// All fields are private, DON'T use it directly.
    id: usize = invalid_batch_id,
    reclaimer: BatchReclaimer = undefined,
    is_submitted: bool = false,
    ctx: jok.Context,
    camera: Camera,
    tri_rd: TriangleRenderer,
    skybox_rd: SkyboxRenderer,
    trs_stack: std.ArrayList(zmath.Mat),
    trs: zmath.Mat,
    wireframe_color: ?jok.Color,
    triangle_sort: TriangleSort,
    indices: std.ArrayList(u32),
    vertices: std.ArrayList(jok.Vertex),
    depths: std.ArrayList(f32),
    textures: std.ArrayList(?jok.Texture),
    all_tex: std.AutoHashMap(*anyopaque, bool),
    draw_list: imgui.DrawList,
    blend_mode: jok.BlendMode,
    offscreen_target: ?jok.Texture,
    offscreen_clear_color: ?jok.Color,

    fn init(_ctx: jok.Context) Batch {
        const allocator = _ctx.allocator();
        return .{
            .ctx = _ctx,
            .camera = undefined,
            .tri_rd = TriangleRenderer.init(allocator),
            .skybox_rd = SkyboxRenderer.init(allocator, .{}),
            .trs_stack = std.ArrayList(zmath.Mat).init(_ctx.allocator()),
            .trs = undefined,
            .wireframe_color = null,
            .triangle_sort = .none,
            .indices = std.ArrayList(u32).init(allocator),
            .vertices = std.ArrayList(jok.Vertex).init(allocator),
            .depths = std.ArrayList(f32).init(allocator),
            .textures = std.ArrayList(?jok.Texture).init(allocator),
            .all_tex = std.AutoHashMap(*anyopaque, bool).init(allocator),
            .draw_list = imgui.createDrawList(),
            .blend_mode = .blend,
            .offscreen_target = null,
            .offscreen_clear_color = null,
        };
    }

    fn deinit(self: *Batch) void {
        self.trs_stack.deinit();
        self.tri_rd.deinit();
        self.skybox_rd.deinit();
        self.indices.deinit();
        self.vertices.deinit();
        self.depths.deinit();
        self.textures.deinit();
        self.all_tex.deinit();
        imgui.destroyDrawList(self.draw_list);
    }

    pub fn recycleMemory(self: *Batch) void {
        self.indices.clearAndFree();
        self.vertices.clearAndFree();
        self.depths.clearAndFree();
        self.textures.clearAndFree();
        self.draw_list.clearMemory();
        self.all_tex.clearRetainingCapacity();
    }

    /// Reinitialize batch, abandon all commands, no reclaiming
    pub fn reset(self: *Batch, opt: BatchOption) void {
        assert(self.id != invalid_batch_id);
        defer self.is_submitted = false;

        self.trs_stack.clearRetainingCapacity();
        self.trs = zmath.identity();
        self.wireframe_color = opt.wireframe_color;
        self.triangle_sort = opt.triangle_sort;
        self.draw_list.reset();
        self.draw_list.pushClipRect(if (opt.clip_rect) |r|
            .{
                .pmin = .{ r.x, r.y },
                .pmax = .{ r.x + r.width, r.y + r.height },
            }
        else BLK: {
            if (opt.offscreen_target) |tex| {
                const info = tex.query() catch unreachable;
                break :BLK .{
                    .pmin = .{ 0, 0 },
                    .pmax = .{ @floatFromInt(info.width), @floatFromInt(info.height) },
                };
            }
            const csz = self.ctx.getCanvasSize();
            break :BLK .{
                .pmin = .{ 0, 0 },
                .pmax = .{ @floatFromInt(csz.width), @floatFromInt(csz.height) },
            };
        });
        self.draw_list.setDrawListFlags(.{
            .anti_aliased_lines = true,
            .anti_aliased_lines_use_tex = false,
            .anti_aliased_fill = true,
            .allow_vtx_offset = true,
        });
        self.indices.clearRetainingCapacity();
        self.vertices.clearRetainingCapacity();
        self.depths.clearRetainingCapacity();
        self.textures.clearRetainingCapacity();
        self.all_tex.clearAndFree();
        self.camera = opt.camera orelse BLK: {
            break :BLK Camera.fromPositionAndTarget(
                .{
                    .perspective = .{
                        .fov = math.pi / 4.0,
                        .aspect_ratio = self.ctx.getAspectRatio(),
                        .near = 0.1,
                        .far = 100,
                    },
                },
                .{ 0, 0, -1 },
                .{ 0, 0, 0 },
            );
        };
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

    inline fn isSameTexture(tex0: ?jok.Texture, tex1: ?jok.Texture) bool {
        if (tex0 != null and tex1 != null) {
            return tex0.?.ptr == tex1.?.ptr;
        }
        return tex0 == null and tex1 == null;
    }

    inline fn reserveCapacity(self: *Batch, idx_size: usize, vtx_size: usize) !void {
        try self.indices.ensureTotalCapacity(self.indices.items.len + idx_size);
        try self.vertices.ensureTotalCapacity(self.vertices.items.len + vtx_size);
        try self.depths.ensureTotalCapacity(self.depths.items.len + vtx_size);
        try self.textures.ensureTotalCapacity(self.textures.items.len + vtx_size);
    }

    // Compare triangles by average depth
    fn compareTrianglesByDepth(self: *Batch, lhs: [3]u32, rhs: [3]u32) bool {
        const l_idx0 = lhs[0];
        const l_idx1 = lhs[1];
        const l_idx2 = lhs[2];
        const r_idx0 = rhs[0];
        const r_idx1 = rhs[1];
        const r_idx2 = rhs[2];
        const d0 = (self.depths.items[l_idx0] + self.depths.items[l_idx1] + self.depths.items[l_idx2]) / 3.0;
        const d1 = (self.depths.items[r_idx0] + self.depths.items[r_idx1] + self.depths.items[r_idx2]) / 3.0;
        if (math.approxEqAbs(f32, d0, d1, 0.000001)) {
            const tex0 = self.textures.items[l_idx0];
            const tex1 = self.textures.items[r_idx0];
            if (tex0 == null and tex1 == null) return d0 > d1;
            if (tex0 != null and tex1 != null) return @intFromPtr(tex0.?.ptr) < @intFromPtr(tex1.?.ptr);
            return tex0 == null;
        }
        return d0 > d1;
    }

    fn sortTriangles(self: *Batch, indices: []u32) void {
        assert(@rem(indices.len, 3) == 0);
        var _indices: [][3]u32 = undefined;
        _indices.ptr = @ptrCast(indices.ptr);
        _indices.len = @divTrunc(indices.len, 3);
        std.sort.pdq(
            [3]u32,
            _indices,
            self,
            compareTrianglesByDepth,
        );
    }

    /// Submit batch, issue draw calls, don't reclaim itself
    pub fn submitWithoutReclaim(self: *Batch) void {
        const S = struct {
            inline fn addTriangles(dl: imgui.DrawList, indices: []u32, vertices: []jok.Vertex, texture: ?jok.Texture) void {
                if (texture) |tex| dl.pushTextureId(tex.ptr);
                defer if (texture != null) dl.popTextureId();

                dl.primReserve(@intCast(indices.len), @intCast(indices.len));
                const white_pixel_uv = imgui.getFontTexUvWhitePixel();
                const cur_idx = dl.getCurrentIndex();
                for (indices) |i| {
                    const p = vertices[i];
                    dl.primWriteVtx(
                        .{ p.pos.x, p.pos.y },
                        if (texture != null) .{ p.texcoord.x, p.texcoord.y } else white_pixel_uv,
                        p.color.toInternalColor(),
                    );
                }
                for (0..indices.len) |i| {
                    dl.primWriteIdx(cur_idx + @as(u32, @intCast(i)));
                }
            }
        };

        assert(self.id != invalid_batch_id);
        assert(jok.utils.isMainThread());

        defer self.is_submitted = true;

        // Apply blend mode to renderer
        const rd = self.ctx.renderer();
        const old_blend = rd.getBlendMode() catch unreachable;
        defer rd.setBlendMode(old_blend) catch unreachable;
        rd.setBlendMode(self.blend_mode) catch unreachable;

        // Apply offscreen target if given
        const old_target = rd.getTarget();
        if (self.offscreen_target) |t| {
            rd.setTarget(t) catch unreachable;
            if (self.offscreen_clear_color) |c| rd.clear(c) catch unreachable;
        }
        defer if (self.offscreen_target != null) {
            rd.setTarget(old_target) catch unreachable;
        };

        if (self.wireframe_color != null) {
            imgui.sdl.renderDrawList(self.ctx, self.draw_list);
        } else {
            // Apply blend mode to textures
            var it = self.all_tex.keyIterator();
            while (it.next()) |k| {
                const tex = jok.Texture{ .ptr = @ptrCast(k.*) };
                tex.setBlendMode(self.blend_mode) catch unreachable;
            }

            switch (self.triangle_sort) {
                .none => {
                    imgui.sdl.renderDrawList(self.ctx, self.draw_list);
                },
                .simple => {
                    if (!self.is_submitted) {
                        // Sort by average depth
                        self.sortTriangles(self.indices.items);

                        // Send triangles
                        var offset: usize = 0;
                        var last_texture: ?jok.Texture = null;
                        var i: usize = 0;
                        while (i < self.indices.items.len) : (i += 3) {
                            const idx = self.indices.items[i];
                            if (i > 0 and !isSameTexture(self.textures.items[idx], last_texture)) {
                                S.addTriangles(
                                    self.draw_list,
                                    self.indices.items[offset..i],
                                    self.vertices.items,
                                    last_texture,
                                );
                                offset = i;
                            }
                            last_texture = self.textures.items[idx];
                        }
                        S.addTriangles(
                            self.draw_list,
                            self.indices.items[offset..],
                            self.vertices.items,
                            last_texture,
                        );
                    }

                    imgui.sdl.renderDrawList(self.ctx, self.draw_list);
                },
            }
        }
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
        self.trs = self.trs_stack.pop();
    }

    pub fn setIdentity(self: *Batch) void {
        self.trs = zmath.identity();
    }

    pub fn translate(self: *Batch, x: f32, y: f32, z: f32) void {
        self.trs = zmath.mul(self.trs, zmath.translation(x, y, z));
    }

    pub fn rotateX(self: *Batch, radian: f32) void {
        self.trs = zmath.mul(self.trs, zmath.rotationX(radian));
    }

    pub fn rotateY(self: *Batch, radian: f32) void {
        self.trs = zmath.mul(self.trs, zmath.rotationY(radian));
    }

    pub fn rotateZ(self: *Batch, radian: f32) void {
        self.trs = zmath.mul(self.trs, zmath.rotationZ(radian));
    }

    pub fn scale(self: *Batch, x: f32, y: f32, z: f32) void {
        self.trs = zmath.mul(self.trs, zmath.scaling(x, y, z));
    }

    /// Get current batched data
    pub fn getBatch(self: Batch) !RenderBatch {
        assert(self.id != invalid_batch_id);
        return .{
            .indices = try self.indices.clone(),
            .vertices = try self.vertices.clone(),
            .depths = try self.depths.clone(),
            .textures = try self.textures.clone(),
        };
    }

    /// Directly push previous batched data to final dataset
    pub fn pushBatch(self: *Batch, b: RenderBatch) !void {
        assert(self.id != invalid_batch_id);
        assert(!self.is_submitted);
        assert(b.vertices.items.len == b.depths.items.len);
        assert(b.vertices.items.len == b.textures.items.len);
        try self.reserveCapacity(b.indices.items.len, b.vertices.items.len);
        const current_index: u32 = @intCast(self.vertices.items.len);
        if (current_index > 0) {
            for (b.indices.items) |idx| {
                self.indices.appendAssumeCapacity(idx + current_index);
            }
        } else {
            self.indices.appendSliceAssumeCapacity(b.indices.items);
        }
        self.vertices.appendSliceAssumeCapacity(b.vertices.items);
        self.depths.appendSliceAssumeCapacity(b.depths.items);
        self.textures.appendSliceAssumeCapacity(b.textures.items);
        for (b.textures.items) |texture| {
            if (texture) |tex| try self.all_tex.put(tex.ptr, true);
        }
    }

    /// Directly push triangles to final dataset
    pub fn pushTriangles(
        self: *Batch,
        indices: []const u32,
        vertices: []const jok.Vertex,
        depths: []const f32,
        texture: ?jok.Texture,
    ) !void {
        assert(self.id != invalid_batch_id);
        assert(!self.is_submitted);
        assert(@rem(indices.len, 3) == 0);
        assert(vertices.len == depths.len);

        if (self.wireframe_color) |color| {
            const col = color.toInternalColor();
            var i: usize = 2;
            while (i < indices.len) : (i += 3) {
                self.draw_list.addTriangle(.{
                    .p1 = .{ vertices[i - 2].pos.x, vertices[i - 2].pos.y },
                    .p2 = .{ vertices[i - 1].pos.x, vertices[i - 1].pos.y },
                    .p3 = .{ vertices[i].pos.x, vertices[i].pos.y },
                    .col = col,
                });
            }
        } else {
            switch (self.triangle_sort) {
                .none => {
                    if (texture) |tex| self.draw_list.pushTextureId(tex.ptr);
                    defer if (texture != null) self.draw_list.popTextureId();

                    self.draw_list.primReserve(@intCast(indices.len), @intCast(vertices.len));
                    const white_pixel_uv = imgui.getFontTexUvWhitePixel();
                    const cur_idx = self.draw_list.getCurrentIndex();
                    var i: usize = 0;
                    while (i < vertices.len) : (i += 1) {
                        const p = vertices[i];
                        self.draw_list.primWriteVtx(
                            .{ p.pos.x, p.pos.y },
                            if (texture != null)
                                .{ p.texcoord.x, p.texcoord.y }
                            else
                                white_pixel_uv,
                            p.color.toInternalColor(),
                        );
                    }
                    for (indices) |j| {
                        self.draw_list.primWriteIdx(cur_idx + @as(u32, @intCast(j)));
                    }
                },
                .simple => {
                    try self.reserveCapacity(indices.len, vertices.len);
                    const current_index: u32 = @intCast(self.vertices.items.len);
                    if (current_index > 0) {
                        for (indices) |idx| {
                            self.indices.appendAssumeCapacity(idx + current_index);
                        }
                    } else {
                        self.indices.appendSliceAssumeCapacity(indices);
                    }
                    self.vertices.appendSliceAssumeCapacity(vertices);
                    self.depths.appendSliceAssumeCapacity(depths);
                    self.textures.appendNTimesAssumeCapacity(
                        texture,
                        vertices.len,
                    );
                },
            }
            if (texture) |tex| try self.all_tex.put(tex.ptr, true);
        }
    }

    /// Render skybox, textures order: right/left/top/bottom/front/back
    pub fn skybox(
        self: *Batch,
        textures: [6]jok.Texture,
        color: ?jok.Color,
    ) !void {
        assert(self.id != invalid_batch_id);
        assert(!self.is_submitted);
        try self.skybox_rd.render(
            self.ctx.getCanvasSize(),
            self,
            self.camera,
            textures,
            color,
        );
    }

    /// Render given scene
    pub fn scene(
        self: *Batch,
        s: *const Scene,
        opt: Scene.RenderOption,
    ) !void {
        assert(self.id != invalid_batch_id);
        assert(!self.is_submitted);
        try s.render(self, null, opt);
    }

    /// Render particle effects
    pub fn effects(self: *Batch, ps: *ParticleSystem) !void {
        assert(self.id != invalid_batch_id);
        assert(!self.is_submitted);
        for (ps.effects.items) |eff| {
            try eff.render(
                self.ctx.getCanvasSize(),
                self,
                self.camera,
                &self.tri_rd,
            );
        }
    }

    /// Render given sprite
    pub fn sprite(
        self: *Batch,
        size: jok.Point,
        uv: [2]jok.Point,
        opt: TriangleRenderer.RenderSpriteOption,
    ) !void {
        assert(self.id != invalid_batch_id);
        assert(!self.is_submitted);
        try self.tri_rd.renderSprite(
            self.ctx.getCanvasSize(),
            self,
            self.trs,
            self.camera,
            size,
            uv,
            opt,
        );
    }

    pub const LineOption = struct {
        color: jok.Color = jok.Color.white,
        thickness: f32 = 0.1,
        stacks: u32 = 10,
    };

    /// Render given line
    pub fn line(
        self: *Batch,
        _p0: [3]f32,
        _p1: [3]f32,
        opt: LineOption,
    ) !void {
        assert(self.id != invalid_batch_id);
        assert(!self.is_submitted);
        assert(opt.thickness > 0);
        assert(opt.stacks > 0);
        const v0 = zmath.mul(zmath.f32x4(_p0[0], _p0[1], _p0[2], 1), self.trs);
        const v1 = zmath.mul(zmath.f32x4(_p1[0], _p1[1], _p1[2], 1), self.trs);
        const perpv = zmath.normalize3(zmath.cross3(v1 - v0, self.camera.dir));
        const veps = zmath.f32x4s(opt.thickness);
        const unit = (v1 - v0) / zmath.f32x4s(@floatFromInt(opt.stacks));
        for (0..opt.stacks) |i| {
            const p0 = v0 + zmath.f32x4s(@floatFromInt(i)) * unit + veps * perpv;
            const p1 = v0 + zmath.f32x4s(@floatFromInt(i)) * unit - veps * perpv;
            const p2 = v0 + zmath.f32x4s(@floatFromInt(i + 1)) * unit - veps * perpv;
            const p3 = v0 + zmath.f32x4s(@floatFromInt(i + 1)) * unit + veps * perpv;
            try self.tri_rd.renderMesh(
                self.ctx.getCanvasSize(),
                self,
                zmath.identity(),
                self.camera,
                &.{ 0, 1, 2, 0, 2, 3 },
                &.{
                    .{ p0[0], p0[1], p0[2] },
                    .{ p1[0], p1[1], p1[2] },
                    .{ p2[0], p2[1], p2[2] },
                    .{ p3[0], p3[1], p3[2] },
                },
                null,
                null,
                null,
                .{
                    .cull_faces = false,
                    .color = opt.color,
                    .shading_method = .flat,
                },
            );
        }
    }

    pub const TriangleOption = struct {
        rdopt: RenderOption = .{},
        aabb: ?[6]f32,
        fill: bool = true,
    };

    /// Render given triangle
    pub fn triangle(
        self: *Batch,
        pos: [3][3]f32,
        colors: ?[3]jok.Color,
        texcoords: ?[3][2]f32,
        opt: TriangleOption,
    ) !void {
        assert(self.id != invalid_batch_id);
        assert(!self.is_submitted);
        if (opt.fill) {
            const v0 = zmath.f32x4(
                pos[1][0] - pos[0][0],
                pos[1][1] - pos[0][1],
                pos[1][2] - pos[0][2],
                0,
            );
            const v1 = zmath.f32x4(
                pos[2][0] - pos[1][0],
                pos[2][1] - pos[1][1],
                pos[2][2] - pos[1][2],
                0,
            );
            const normal = zmath.vecToArr3(zmath.cross3(v0, v1));
            try self.tri_rd.renderMesh(
                self.ctx.getCanvasSize(),
                self,
                self.trs,
                self.camera,
                &.{ 0, 1, 2 },
                &pos,
                &.{ normal, normal, normal },
                if (colors) |cs| &cs else null,
                if (texcoords) |tex| &tex else null,
                .{
                    .aabb = opt.aabb,
                    .cull_faces = opt.rdopt.cull_faces,
                    .color = opt.rdopt.color,
                    .shading_method = opt.rdopt.shading_method,
                    .texture = opt.rdopt.texture,
                    .lighting = opt.rdopt.lighting,
                },
            );
        } else {
            try line(self.trs, pos[0], pos[1], .{ .color = opt.rdopt.color });
            try line(self.trs, pos[1], pos[2], .{ .color = opt.rdopt.color });
            try line(self.trs, pos[2], pos[0], .{ .color = opt.rdopt.color });
        }
    }

    /// Render multiple triangles
    pub fn triangles(
        self: *Batch,
        indices: []const u32,
        pos: []const [3]f32,
        normals: ?[]const [3]f32,
        colors: ?[]const [3]jok.Color,
        texcoords: ?[]const [2]f32,
        opt: TriangleOption,
    ) !void {
        assert(self.id != invalid_batch_id);
        assert(!self.is_submitted);
        assert(@rem(indices, 3) == 0);

        if (opt.fill) {
            try self.tri_rd.renderMesh(
                self.ctx.getCanvasSize(),
                self,
                self.trs,
                self.camera,
                indices,
                pos,
                normals,
                colors,
                texcoords,
                .{
                    .aabb = opt.aabb,
                    .cull_faces = opt.rdopt.cull_faces,
                    .color = opt.rdopt.color,
                    .shading_method = opt.rdopt.shading_method,
                    .texture = opt.rdopt.texture,
                    .lighting = opt.rdopt.lighting,
                },
            );
        } else {
            var i: u32 = 2;
            while (i < indices) : (i += 2) {
                const idx0 = indices[i - 2];
                const idx1 = indices[i - 1];
                const idx2 = indices[i];
                try line(self.trs, idx0, idx1, .{ .color = opt.rdopt.color });
                try line(self.trs, idx1, idx2, .{ .color = opt.rdopt.color });
                try line(self.trs, idx2, idx0, .{ .color = opt.rdopt.color });
            }
        }
    }

    /// Render a prebuilt shape
    pub fn shape(
        self: *Batch,
        s: zmesh.Shape,
        aabb: ?[6]f32,
        opt: RenderOption,
    ) !void {
        assert(self.id != invalid_batch_id);
        assert(!self.is_submitted);
        try self.tri_rd.renderMesh(
            self.ctx.getCanvasSize(),
            self,
            self.trs,
            self.camera,
            s.indices,
            s.positions,
            s.normals.?,
            null,
            s.texcoords,
            .{
                .aabb = aabb,
                .cull_faces = opt.cull_faces,
                .color = opt.color,
                .shading_method = opt.shading_method,
                .texture = opt.texture,
                .lighting = opt.lighting,
            },
        );
    }

    /// Render a loaded mesh
    pub fn mesh(
        self: *Batch,
        m: *const Mesh,
        opt: RenderOption,
    ) !void {
        assert(self.id != invalid_batch_id);
        assert(!self.is_submitted);
        try m.render(
            self.ctx.getCanvasSize(),
            self,
            self.trs,
            self.camera,
            &self.tri_rd,
            .{
                .cull_faces = opt.cull_faces,
                .color = opt.color,
                .shading_method = opt.shading_method,
                .texture = opt.texture,
                .lighting = opt.lighting,
            },
        );
    }

    /// Render given animation's current frame
    pub fn animation(
        self: *Batch,
        anim: *Animation,
        opt: Animation.RenderOption,
    ) !void {
        assert(self.id != invalid_batch_id);
        assert(!self.is_submitted);
        try anim.render(
            self.ctx.getCanvasSize(),
            self,
            self.trs,
            self.camera,
            &self.tri_rd,
            opt,
        );
    }
};

pub const RenderBatch = struct {
    indices: std.ArrayList(u32),
    vertices: std.ArrayList(jok.Vertex),
    depths: std.ArrayList(f32),
    textures: std.ArrayList(?jok.Texture),

    pub fn deinit(batch: RenderBatch) void {
        batch.indices.deinit();
        batch.vertices.deinit();
        batch.depths.deinit();
        batch.textures.deinit();
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

test "j3d" {
    _ = Vector;
}
