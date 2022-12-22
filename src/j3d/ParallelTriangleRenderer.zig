const std = @import("std");
const assert = std.debug.assert;
const math = std.math;
const builtin = @import("builtin");
const sdl = @import("sdl");
const jok = @import("../jok.zig");
const zjobs = jok.deps.zjobs;
const j3d = jok.j3d;
const zmath = j3d.zmath;
const Camera = j3d.Camera;
const utils = jok.utils;
const internal = @import("internal.zig");
const Self = @This();

const max_jobs_num = @bitSizeOf(usize);

// Jobs Queue
jobs: *zjobs.JobQueue(.{}),

// Triangle vertices
indices: std.ArrayList(u32),
sorted: bool = false,

// Triangle vertices
vertices: std.ArrayList(sdl.Vertex),

// Depth of vertices
depths: std.ArrayList(f32),

// Parallel rendering jobs
rendering_jobs: [max_jobs_num]RenderJob,
rendering_job_ids: [max_jobs_num]zjobs.JobId,
rendering_job_next: u32,

pub fn init(
    allocator: std.mem.Allocator,
    jobs: *zjobs.JobQueue(.{}),
) Self {
    if (builtin.single_threaded) {
        @panic("Current system doesn't support parallel rendering!");
    }
    var self = Self{
        .jobs = jobs,
        .indices = std.ArrayList(u32).init(allocator),
        .vertices = std.ArrayList(sdl.Vertex).init(allocator),
        .depths = std.ArrayList(f32).init(allocator),
        .rendering_jobs = undefined,
        .rendering_job_ids = undefined,
        .rendering_job_next = 0,
    };
    var i: u32 = 0;
    while (i < self.rendering_jobs.len) : (i += 1) {
        self.rendering_jobs[i] = RenderJob.init(allocator) catch unreachable;
        self.rendering_job_ids[i] = .none;
    }
    return self;
}

pub fn deinit(self: *Self) void {
    self.indices.deinit();
    self.vertices.deinit();
    self.depths.deinit();
    var i: u32 = 0;
    while (i < self.rendering_jobs.len) : (i += 1) {
        self.rendering_jobs[i].deinit();
    }
}

/// Clear mesh data
pub fn clear(self: *Self, retain_memory: bool) void {
    if (retain_memory) {
        self.indices.clearRetainingCapacity();
        self.vertices.clearRetainingCapacity();
        self.depths.clearRetainingCapacity();
    } else {
        self.indices.clearAndFree();
        self.vertices.clearAndFree();
        self.depths.clearAndFree();
    }
    self.sorted = false;
    std.mem.set(zjobs.JobId, &self.rendering_job_ids, .none);
    self.rendering_job_next = 0;
}

/// Lighting options
pub const Light = union(enum) {
    directional: struct {
        ambient: zmath.Vec = zmath.f32x4s(0.1),
        diffuse: zmath.Vec = zmath.f32x4s(0.8),
        specular: zmath.Vec = zmath.f32x4s(0.5),
        direction: zmath.Vec = zmath.f32x4(0, -1, -1, 0),
    },
    point: struct {
        ambient: zmath.Vec = zmath.f32x4s(0.1),
        diffuse: zmath.Vec = zmath.f32x4s(0.8),
        specular: zmath.Vec = zmath.f32x4s(0.5),
        position: zmath.Vec = zmath.f32x4(1, 1, 1, 1),
        constant: f32 = 1.0,
        attenuation_linear: f32 = 0.5,
        attenuation_quadratic: f32 = 0.3,
    },
    spot: struct {
        ambient: zmath.Vec = zmath.f32x4s(0.1),
        diffuse: zmath.Vec = zmath.f32x4s(0.9),
        specular: zmath.Vec = zmath.f32x4s(0.8),
        position: zmath.Vec = zmath.f32x4(3, 3, 3, 1),
        direction: zmath.Vec = zmath.f32x4(-1, -1, -1, 0),
        constant: f32 = 1.0,
        attenuation_linear: f32 = 0.01,
        attenuation_quadratic: f32 = 0.001,
        inner_cutoff: f32 = 0.95,
        outer_cutoff: f32 = 0.85,
    },
};
pub const LightingOption = struct {
    const max_light_num = 32;
    lights: [max_light_num]Light = [_]Light{.{ .directional = .{} }} ** max_light_num,
    lights_num: u32 = 1,
    shininess: f32 = 4,

    // Calculate color of light source
    light_calc_fn: ?*const fn (
        material_color: sdl.Color,
        eye_pos: zmath.Vec,
        vertex_pos: zmath.Vec,
        normal: zmath.Vec,
        opt: LightingOption,
    ) sdl.Color = null,
};

/// Advanced vertice appending options
pub const ShapeOption = struct {
    aabb: ?[6]f32 = null,
    cull_faces: bool = true,
    lighting: ?LightingOption = null,
};

/// Append shape data for parallel processing
pub fn addShapeData(
    self: *Self,
    renderer: sdl.Renderer,
    model: zmath.Mat,
    camera: Camera,
    indices: []const u16,
    positions: []const [3]f32,
    normals: []const [3]f32,
    colors: ?[]const sdl.Color,
    texcoords: ?[]const [2]f32,
    opt: ShapeOption,
) !void {
    if (self.rendering_job_ids[self.rendering_job_next] != .none) {
        self.jobs.wait(self.rendering_job_ids[self.rendering_job_next]);
        try self.vertices.appendSlice(
            self.rendering_jobs[self.rendering_job_next].context.vertices.items,
        );
        try self.depths.appendSlice(
            self.rendering_jobs[self.rendering_job_next].context.depths.items,
        );
        var current_index: u32 = @intCast(u32, self.indices.items.len);
        var i: usize = 0;
        while (i < self.rendering_jobs[self.rendering_job_next].context.vertices.items.len) : (i += 1) {
            try self.indices.append(current_index);
            current_index += 1;
        }
    }

    try self.rendering_jobs[self.rendering_job_next].setup(
        renderer,
        model,
        camera,
        indices,
        positions,
        normals,
        colors,
        texcoords,
        opt,
    );

    self.rendering_job_ids[self.rendering_job_next] = try self.jobs.schedule(
        .none,
        self.rendering_jobs[self.rendering_job_next],
    );

    self.rendering_job_next = (self.rendering_job_next + 1) % max_jobs_num;
}

/// Test whether all obb's triangles are hidden behind current front triangles
inline fn isOBBHiddenBehind(self: *Self, obb: []zmath.Vec) bool {
    const S = struct {
        /// Test whether a triangle is hidden behind another
        inline fn isTriangleHiddenBehind(
            front_tri: [3][2]f32,
            front_depth: f32,
            _obb: []zmath.Vec,
            indices: [3]u32,
        ) bool {
            const tri = [3][2]f32{
                .{ _obb[indices[0]][0], _obb[indices[0]][1] },
                .{ _obb[indices[1]][0], _obb[indices[1]][1] },
                .{ _obb[indices[2]][0], _obb[indices[2]][1] },
            };
            const tri_depth = (_obb[indices[0]][2] + _obb[indices[1]][2] + _obb[indices[2]][2]) / 3.0;
            return tri_depth > front_depth and
                utils.math.isPointInTriangle(front_tri, tri[0]) and
                utils.math.isPointInTriangle(front_tri, tri[1]) and
                utils.math.isPointInTriangle(front_tri, tri[2]);
        }
    };

    assert(obb.len == 8);
    var obb_visible_flags: u12 = std.math.maxInt(u12);
    for (self.large_front_triangles.items) |tri| {
        const front_tri = [3][2]f32{
            .{ self.vertices.items[tri[0]].position.x, self.vertices.items[tri[0]].position.y },
            .{ self.vertices.items[tri[1]].position.x, self.vertices.items[tri[1]].position.y },
            .{ self.vertices.items[tri[2]].position.x, self.vertices.items[tri[2]].position.y },
        };
        const front_depth = (self.depths.items[tri[0]] + self.depths.items[tri[1]] + self.depths.items[tri[2]]) / 3.0;

        if ((obb_visible_flags & 0x1) != 0) {
            if (S.isTriangleHiddenBehind(front_tri, front_depth, obb, .{ 0, 1, 2 }))
                obb_visible_flags &= ~@as(u12, 0x1);
        }
        if (obb_visible_flags & 0x2 != 0) {
            if (S.isTriangleHiddenBehind(front_tri, front_depth, obb, .{ 0, 2, 3 }))
                obb_visible_flags &= ~@as(u12, 0x2);
        }
        if (obb_visible_flags & 0x4 != 0) {
            if (S.isTriangleHiddenBehind(front_tri, front_depth, obb, .{ 0, 3, 7 }))
                obb_visible_flags &= ~@as(u12, 0x4);
        }
        if (obb_visible_flags & 0x8 != 0) {
            if (S.isTriangleHiddenBehind(front_tri, front_depth, obb, .{ 0, 7, 4 }))
                obb_visible_flags &= ~@as(u12, 0x8);
        }
        if (obb_visible_flags & 0x10 != 0) {
            if (S.isTriangleHiddenBehind(front_tri, front_depth, obb, .{ 0, 4, 5 }))
                obb_visible_flags &= ~@as(u12, 0x10);
        }
        if (obb_visible_flags & 0x20 != 0) {
            if (S.isTriangleHiddenBehind(front_tri, front_depth, obb, .{ 0, 5, 1 }))
                obb_visible_flags &= ~@as(u12, 0x20);
        }
        if (obb_visible_flags & 0x40 != 0) {
            if (S.isTriangleHiddenBehind(front_tri, front_depth, obb, .{ 6, 7, 3 }))
                obb_visible_flags &= ~@as(u12, 0x40);
        }
        if (obb_visible_flags & 0x80 != 0) {
            if (S.isTriangleHiddenBehind(front_tri, front_depth, obb, .{ 6, 3, 2 }))
                obb_visible_flags &= ~@as(u12, 0x80);
        }
        if (obb_visible_flags & 0x100 != 0) {
            if (S.isTriangleHiddenBehind(front_tri, front_depth, obb, .{ 6, 2, 1 }))
                obb_visible_flags &= ~@as(u12, 0x100);
        }
        if (obb_visible_flags & 0x200 != 0) {
            if (S.isTriangleHiddenBehind(front_tri, front_depth, obb, .{ 6, 1, 5 }))
                obb_visible_flags &= ~@as(u12, 0x200);
        }
        if (obb_visible_flags & 0x400 != 0) {
            if (S.isTriangleHiddenBehind(front_tri, front_depth, obb, .{ 6, 5, 4 }))
                obb_visible_flags &= ~@as(u12, 0x400);
        }
        if (obb_visible_flags & 0x800 != 0) {
            if (S.isTriangleHiddenBehind(front_tri, front_depth, obb, .{ 6, 4, 7 }))
                obb_visible_flags &= ~@as(u12, 0x800);
        }
        if (obb_visible_flags == 0) return true;
    }
    return false;
}

/// Calculate tint color of vertex according to lighting paramters
fn calcLightColor(
    material_color: sdl.Color,
    eye_pos: zmath.Vec,
    vertex_pos: zmath.Vec,
    normal: zmath.Vec,
    opt: LightingOption,
) sdl.Color {
    const S = struct {
        inline fn calcColor(
            raw_color: zmath.Vec,
            shininess: f32,
            light_dir: zmath.Vec,
            eye_dir: zmath.Vec,
            _normal: zmath.Vec,
            _ambient: zmath.Vec,
            _diffuse: zmath.Vec,
            _specular: zmath.Vec,
        ) zmath.Vec {
            const dns = zmath.dot3(_normal, light_dir);
            var diffuse = zmath.max(dns, zmath.f32x4s(0)) * _diffuse;
            var specular = zmath.f32x4s(0);
            if (dns[0] > 0) {
                // Calculate reflect ratio (Blinn-Phong model)
                const halfway_dir = zmath.normalize3(eye_dir + light_dir);
                const s = math.pow(f32, zmath.max(
                    zmath.dot3(_normal, halfway_dir),
                    zmath.f32x4s(0),
                )[0], shininess);
                specular = zmath.f32x4s(s) * _specular;
            }
            return raw_color * (_ambient + diffuse + specular);
        }
    };

    if (opt.lights_num == 0) return material_color;
    assert(math.approxEqAbs(f32, eye_pos[3], 1.0, math.f32_epsilon));
    assert(math.approxEqAbs(f32, vertex_pos[3], 1.0, math.f32_epsilon));
    assert(math.approxEqAbs(f32, normal[3], 0, math.f32_epsilon));
    const ts = zmath.f32x4s(1.0 / 255.0);
    const raw_color = zmath.f32x4(
        @intToFloat(f32, material_color.r),
        @intToFloat(f32, material_color.g),
        @intToFloat(f32, material_color.b),
        0,
    ) * ts;

    var final_color = zmath.f32x4s(0);
    for (opt.lights[0..opt.lights_num]) |ul| {
        switch (ul) {
            .directional => |light| {
                const light_dir = zmath.normalize3(-light.direction);
                const eye_dir = zmath.normalize3(eye_pos - vertex_pos);
                final_color += S.calcColor(
                    raw_color,
                    opt.shininess,
                    light_dir,
                    eye_dir,
                    normal,
                    light.ambient,
                    light.diffuse,
                    light.specular,
                );
            },
            .point => |light| {
                const light_dir = zmath.normalize3(light.position - vertex_pos);
                const eye_dir = zmath.normalize3(eye_pos - vertex_pos);
                const distance = zmath.length3(light.position - vertex_pos);
                const attenuation = zmath.f32x4s(1.0) / (zmath.f32x4s(light.constant) +
                    zmath.f32x4s(light.attenuation_linear) * distance +
                    zmath.f32x4s(light.attenuation_quadratic) * distance * distance);
                final_color += S.calcColor(
                    raw_color,
                    opt.shininess,
                    light_dir,
                    eye_dir,
                    normal,
                    light.ambient,
                    light.diffuse,
                    light.specular,
                ) * attenuation;
            },
            .spot => |light| {
                const eye_dir = zmath.normalize3(eye_pos - vertex_pos);
                const distance = zmath.length3(light.position - vertex_pos);
                const attenuation = zmath.f32x4s(1.0) / (zmath.f32x4s(light.constant) +
                    zmath.f32x4s(light.attenuation_linear) * distance +
                    zmath.f32x4s(light.attenuation_quadratic) * distance * distance);
                const light_dir = zmath.normalize3(light.position - vertex_pos);
                const theta = zmath.dot3(light_dir, zmath.normalize3(-light.direction))[0];
                assert(light.inner_cutoff > light.outer_cutoff);
                const epsilon = light.inner_cutoff - light.outer_cutoff;
                assert(epsilon > 0);
                const intensity = zmath.f32x4s(math.clamp((theta - light.outer_cutoff) / epsilon, 0.0, 1.0));
                final_color += S.calcColor(
                    raw_color,
                    opt.shininess,
                    light_dir,
                    eye_dir,
                    normal,
                    light.ambient,
                    light.diffuse * intensity,
                    light.specular * intensity,
                ) * attenuation;
            },
        }
    }

    final_color = zmath.clamp(
        final_color,
        zmath.f32x4s(0),
        zmath.f32x4s(1),
    );
    return .{
        .r = @floatToInt(u8, final_color[0] * 255),
        .g = @floatToInt(u8, final_color[1] * 255),
        .b = @floatToInt(u8, final_color[2] * 255),
        .a = material_color.a,
    };
}

/// Sort triangles by depth values
fn compareTriangleDepths(self: *Self, lhs: [3]u32, rhs: [3]u32) bool {
    const d1 = (self.depths.items[lhs[0]] + self.depths.items[lhs[1]] + self.depths.items[lhs[2]]) / 3.0;
    const d2 = (self.depths.items[rhs[0]] + self.depths.items[rhs[1]] + self.depths.items[rhs[2]]) / 3.0;
    return d1 > d2;
}

/// Draw the meshes, fill triangles, using texture if possible
pub fn draw(self: *Self, renderer: sdl.Renderer, tex: ?sdl.Texture) !void {
    for (self.rendering_job_ids) |id, i| {
        if (id == .none) continue;

        self.jobs.wait(id);
        try self.vertices.appendSlice(
            self.rendering_jobs[i].context.vertices.items,
        );
        try self.depths.appendSlice(
            self.rendering_jobs[i].context.depths.items,
        );
        var current_index: u32 = @intCast(u32, self.indices.items.len);
        var j: usize = 0;
        while (j < self.rendering_jobs[i].context.vertices.items.len) : (j += 1) {
            try self.indices.append(current_index);
            current_index += 1;
        }

        self.rendering_job_ids[i] = .none;
    }

    if (self.indices.items.len == 0) return;

    if (!self.sorted) {
        // Sort triangles by depth, from farthest to closest
        var indices: [][3]u32 = undefined;
        indices.ptr = @ptrCast([*][3]u32, self.indices.items.ptr);
        indices.len = @divTrunc(self.indices.items.len, 3);
        std.sort.sort(
            [3]u32,
            indices,
            self,
            compareTriangleDepths,
        );
        self.sorted = true;
    }

    try renderer.drawGeometry(
        tex,
        self.vertices.items,
        self.indices.items,
    );
}

/// Draw the wireframe
pub fn drawWireframe(self: *Self, renderer: sdl.Renderer, color: sdl.Color) !void {
    if (self.indices.items.len == 0) return;

    const old_color = try renderer.getColor();
    defer renderer.setColor(old_color) catch unreachable;
    try renderer.setColor(color);

    const vs = self.vertices.items;
    var i: usize = 2;
    while (i < self.indices.items.len) : (i += 3) {
        const idx1 = self.indices.items[i - 2];
        const idx2 = self.indices.items[i - 1];
        const idx3 = self.indices.items[i];
        assert(idx1 < vs.len);
        assert(idx2 < vs.len);
        assert(idx3 < vs.len);
        try renderer.drawLineF(vs[idx1].position.x, vs[idx1].position.y, vs[idx2].position.x, vs[idx2].position.y);
        try renderer.drawLineF(vs[idx2].position.x, vs[idx2].position.y, vs[idx3].position.x, vs[idx3].position.y);
        try renderer.drawLineF(vs[idx3].position.x, vs[idx3].position.y, vs[idx1].position.x, vs[idx1].position.y);
    }
}

// Parallel rendering job
const RenderJob = struct {
    const Context = struct {
        // Temporary storage for clipping
        clip_vertices: std.ArrayList(zmath.Vec),
        clip_colors: std.ArrayList(sdl.Color),
        clip_texcoords: std.ArrayList(sdl.PointF),

        // vertices in world space (after clipped)
        world_positions: std.ArrayList(zmath.Vec),
        world_normals: std.ArrayList(zmath.Vec),

        // Output: vertices in screen space
        vertices: std.ArrayList(sdl.Vertex),
        depths: std.ArrayList(f32),

        // Input
        viewport: sdl.Rectangle,
        model: zmath.Mat,
        camera: Camera,
        indices: std.ArrayList(u16),
        positions: std.ArrayList([3]f32),
        normals: std.ArrayList([3]f32),
        colors: std.ArrayList(sdl.Color),
        texcoords: std.ArrayList([2]f32),
        opt: ShapeOption,

        fn init(allocator: std.mem.Allocator) Context {
            return .{
                .clip_vertices = std.ArrayList(zmath.Vec).init(allocator),
                .clip_colors = std.ArrayList(sdl.Color).init(allocator),
                .clip_texcoords = std.ArrayList(sdl.PointF).init(allocator),
                .world_positions = std.ArrayList(zmath.Vec).init(allocator),
                .world_normals = std.ArrayList(zmath.Vec).init(allocator),
                .vertices = std.ArrayList(sdl.Vertex).init(allocator),
                .depths = std.ArrayList(f32).init(allocator),
                .viewport = undefined,
                .model = undefined,
                .camera = undefined,
                .indices = std.ArrayList(u16).init(allocator),
                .positions = std.ArrayList([3]f32).init(allocator),
                .normals = std.ArrayList([3]f32).init(allocator),
                .colors = std.ArrayList(sdl.Color).init(allocator),
                .texcoords = std.ArrayList([2]f32).init(allocator),
                .opt = undefined,
            };
        }

        fn deinit(ctx: *Context) void {
            ctx.clip_vertices.deinit();
            ctx.clip_colors.deinit();
            ctx.clip_texcoords.deinit();
            ctx.world_positions.deinit();
            ctx.world_normals.deinit();
            ctx.vertices.deinit();
            ctx.depths.deinit();
            ctx.indices.deinit();
            ctx.positions.deinit();
            ctx.normals.deinit();
            ctx.colors.deinit();
            ctx.texcoords.deinit();
        }
    };

    allocator: std.mem.Allocator,
    context: *Context,

    fn init(allocator: std.mem.Allocator) !RenderJob {
        var ctx = try allocator.create(Context);
        ctx.* = Context.init(allocator);
        var job = RenderJob{
            .allocator = allocator,
            .context = ctx,
        };
        return job;
    }

    fn deinit(job: RenderJob) void {
        job.context.deinit();
        job.allocator.destroy(job.context);
    }

    fn setup(
        job: *RenderJob,
        renderer: sdl.Renderer,
        model: zmath.Mat,
        camera: Camera,
        indices: []const u16,
        positions: []const [3]f32,
        normals: []const [3]f32,
        colors: ?[]const sdl.Color,
        texcoords: ?[]const [2]f32,
        opt: ShapeOption,
    ) !void {
        // Empty outputs
        job.context.clip_vertices.clearRetainingCapacity();
        job.context.clip_colors.clearRetainingCapacity();
        job.context.clip_texcoords.clearRetainingCapacity();
        job.context.world_positions.clearRetainingCapacity();
        job.context.world_normals.clearRetainingCapacity();
        job.context.vertices.clearRetainingCapacity();
        job.context.depths.clearRetainingCapacity();
        const ensure_size = indices.len * 2;
        try job.context.clip_vertices.ensureTotalCapacityPrecise(ensure_size);
        try job.context.clip_colors.ensureTotalCapacityPrecise(ensure_size);
        try job.context.clip_texcoords.ensureTotalCapacityPrecise(ensure_size);
        try job.context.world_positions.ensureTotalCapacityPrecise(ensure_size);
        try job.context.world_normals.ensureTotalCapacityPrecise(ensure_size);

        // Setup inputs
        job.context.viewport = renderer.getViewport();
        job.context.model = model;
        job.context.camera = camera;
        try job.context.indices.replaceRange(
            0,
            job.context.indices.items.len,
            indices,
        );
        try job.context.positions.replaceRange(
            0,
            job.context.positions.items.len,
            positions,
        );
        try job.context.normals.replaceRange(
            0,
            job.context.normals.items.len,
            normals,
        );
        if (colors) |cs| {
            try job.context.colors.replaceRange(
                0,
                job.context.colors.items.len,
                cs,
            );
        } else {
            job.context.colors.clearRetainingCapacity();
        }
        if (texcoords) |ts| {
            try job.context.texcoords.replaceRange(
                0,
                job.context.texcoords.items.len,
                ts,
            );
        } else {
            job.context.texcoords.clearRetainingCapacity();
        }
        job.context.opt = opt;
    }

    pub fn exec(job: *RenderJob) void {
        var ctx = job.context;
        assert(@rem(ctx.indices.items.len, 3) == 0);
        assert(ctx.normals.items.len == ctx.positions.items.len);
        assert(if (ctx.colors.items.len > 0) ctx.colors.items.len == ctx.positions.items.len else true);
        assert(if (ctx.texcoords.items.len > 0) ctx.texcoords.items.len == ctx.positions.items.len else true);
        if (ctx.indices.items.len == 0) return;
        const ndc_to_screen = zmath.loadMat43(&[_]f32{
            0.5 * @intToFloat(f32, ctx.viewport.width), 0.0,                                          0.0,
            0.0,                                        -0.5 * @intToFloat(f32, ctx.viewport.height), 0.0,
            0.0,                                        0.0,                                          0.5,
            0.5 * @intToFloat(f32, ctx.viewport.width), 0.5 * @intToFloat(f32, ctx.viewport.height),  0.5,
        });
        const mvp = zmath.mul(ctx.model, ctx.camera.getViewProjectMatrix());

        // Do early test with aabb if possible
        if (ctx.opt.aabb) |ab| {
            const width = ab[3] - ab[0];
            const length = ab[5] - ab[2];
            assert(width >= 0);
            assert(length >= 0);
            const v0 = zmath.f32x4(ab[0], ab[1], ab[2], 1.0);
            const v1 = zmath.f32x4(ab[0], ab[1], ab[2] + length, 1.0);
            const v2 = zmath.f32x4(ab[0] + width, ab[1], ab[2] + length, 1.0);
            const v3 = zmath.f32x4(ab[0] + width, ab[1], ab[2], 1.0);
            const v4 = zmath.f32x4(ab[3] - width, ab[4], ab[5] - length, 1.0);
            const v5 = zmath.f32x4(ab[3] - width, ab[4], ab[5], 1.0);
            const v6 = zmath.f32x4(ab[3], ab[4], ab[5], 1.0);
            const v7 = zmath.f32x4(ab[3], ab[4], ab[5] - length, 1.0);
            const obb1 = zmath.mul(zmath.Mat{
                v0, v1, v2, v3,
            }, mvp);
            const obb2 = zmath.mul(zmath.Mat{
                v4, v5, v6, v7,
            }, mvp);

            // Ignore object outside of viewing space
            if (internal.isOBBOutside(&[_]zmath.Vec{
                obb1[0], obb1[1], obb1[2], obb1[3],
                obb2[0], obb2[1], obb2[2], obb2[3],
            })) return;
        }

        // Do face-culling and W-pannel clipping
        var i: usize = 2;
        while (i < ctx.indices.items.len) : (i += 3) {
            const idx0 = ctx.indices.items[i - 2];
            const idx1 = ctx.indices.items[i - 1];
            const idx2 = ctx.indices.items[i];
            const v0 = zmath.f32x4(ctx.positions.items[idx0][0], ctx.positions.items[idx0][1], ctx.positions.items[idx0][2], 1.0);
            const v1 = zmath.f32x4(ctx.positions.items[idx1][0], ctx.positions.items[idx1][1], ctx.positions.items[idx1][2], 1.0);
            const v2 = zmath.f32x4(ctx.positions.items[idx2][0], ctx.positions.items[idx2][1], ctx.positions.items[idx2][2], 1.0);
            const n0 = zmath.f32x4(ctx.normals.items[idx0][0], ctx.normals.items[idx0][1], ctx.normals.items[idx0][2], 0);
            const n1 = zmath.f32x4(ctx.normals.items[idx1][0], ctx.normals.items[idx1][1], ctx.normals.items[idx1][2], 0);
            const n2 = zmath.f32x4(ctx.normals.items[idx2][0], ctx.normals.items[idx2][1], ctx.normals.items[idx2][2], 0);

            // Ignore triangles facing away from camera (front faces' vertices are clock-wise organized)
            if (ctx.opt.cull_faces) {
                const world_positions = zmath.mul(zmath.Mat{
                    v0,
                    v1,
                    v2,
                    zmath.f32x4(0.0, 0.0, 0.0, 1.0),
                }, ctx.model);
                const face_dir = zmath.cross3(world_positions[1] - world_positions[0], world_positions[2] - world_positions[0]);
                const camera_dir = (world_positions[0] + world_positions[1] + world_positions[2]) /
                    zmath.splat(zmath.Vec, 3.0) - ctx.camera.position;
                if (zmath.dot3(face_dir, camera_dir)[0] >= 0) continue;
            }

            // Clip triangles behind camera
            const tri_world_positions = zmath.mul(zmath.Mat{
                v0,
                v1,
                v2,
                zmath.f32x4(0.0, 0.0, 0.0, 1.0),
            }, ctx.model);
            var tri_world_normals = zmath.mul(zmath.Mat{
                n0,
                n1,
                n2,
                zmath.f32x4s(0),
            }, zmath.transpose(zmath.inverse(ctx.model)));
            tri_world_normals[0] = zmath.normalize3(tri_world_normals[0]);
            tri_world_normals[1] = zmath.normalize3(tri_world_normals[1]);
            tri_world_normals[2] = zmath.normalize3(tri_world_normals[2]);
            tri_world_normals[0][3] = 0;
            tri_world_normals[1][3] = 0;
            tri_world_normals[2][3] = 0;
            const tri_clip_positions = zmath.mul(zmath.Mat{
                v0,
                v1,
                v2,
                zmath.f32x4(0.0, 0.0, 0.0, 1.0),
            }, mvp);
            const tri_colors: ?[3]sdl.Color = if (ctx.colors.items.len > 0)
                [3]sdl.Color{ ctx.colors.items[idx0], ctx.colors.items[idx1], ctx.colors.items[idx2] }
            else
                null;
            const tri_texcoords: ?[3]sdl.PointF = if (ctx.texcoords.items.len > 0)
                [3]sdl.PointF{
                    .{ .x = ctx.texcoords.items[idx0][0], .y = ctx.texcoords.items[idx0][1] },
                    .{ .x = ctx.texcoords.items[idx1][0], .y = ctx.texcoords.items[idx1][1] },
                    .{ .x = ctx.texcoords.items[idx2][0], .y = ctx.texcoords.items[idx2][1] },
                }
            else
                null;
            internal.clipTriangle(
                tri_world_positions[0..3],
                tri_world_normals[0..3],
                tri_clip_positions[0..3],
                tri_colors,
                tri_texcoords,
                &ctx.clip_vertices,
                &ctx.clip_colors,
                &ctx.clip_texcoords,
                &ctx.world_positions,
                &ctx.world_normals,
            );
        }
        if (ctx.clip_vertices.items.len == 0) return;
        assert(@rem(ctx.clip_vertices.items.len, 3) == 0);

        // Continue with remaining triangles
        ctx.vertices.ensureTotalCapacityPrecise(ctx.clip_vertices.items.len) catch unreachable;
        ctx.depths.ensureTotalCapacityPrecise(ctx.clip_vertices.items.len) catch unreachable;
        ctx.indices.ensureTotalCapacityPrecise(ctx.clip_vertices.items.len) catch unreachable;
        i = 2;
        while (i < ctx.clip_vertices.items.len) : (i += 3) {
            const idx0 = i - 2;
            const idx1 = i - 1;
            const idx2 = i;
            const clip_v0 = ctx.clip_vertices.items[idx0];
            const clip_v1 = ctx.clip_vertices.items[idx1];
            const clip_v2 = ctx.clip_vertices.items[idx2];
            const world_v0 = ctx.world_positions.items[idx0];
            const world_v1 = ctx.world_positions.items[idx1];
            const world_v2 = ctx.world_positions.items[idx2];
            const n0 = ctx.world_normals.items[idx0];
            const n1 = ctx.world_normals.items[idx1];
            const n2 = ctx.world_normals.items[idx2];
            const ndc0 = clip_v0 / zmath.splat(zmath.Vec, clip_v0[3]);
            const ndc1 = clip_v1 / zmath.splat(zmath.Vec, clip_v1[3]);
            const ndc2 = clip_v2 / zmath.splat(zmath.Vec, clip_v2[3]);

            // Ignore triangles outside of NDC
            if (internal.isTriangleOutside(ndc0, ndc1, ndc2)) {
                continue;
            }

            // Calculate screen coordinate
            const ndcs = zmath.Mat{
                ndc0,
                ndc1,
                ndc2,
                zmath.f32x4(0.0, 0.0, 0.0, 1.0),
            };
            const positions_screen = zmath.mul(ndcs, ndc_to_screen);

            // Finally, we can append vertices for rendering
            const c0 = if (ctx.colors.items.len > 0) ctx.clip_colors.items[idx0] else sdl.Color.white;
            const c1 = if (ctx.colors.items.len > 0) ctx.clip_colors.items[idx1] else sdl.Color.white;
            const c2 = if (ctx.colors.items.len > 0) ctx.clip_colors.items[idx2] else sdl.Color.white;
            const t0 = if (ctx.texcoords.items.len > 0) ctx.clip_texcoords.items[idx0] else undefined;
            const t1 = if (ctx.texcoords.items.len > 0) ctx.clip_texcoords.items[idx1] else undefined;
            const t2 = if (ctx.texcoords.items.len > 0) ctx.clip_texcoords.items[idx2] else undefined;
            ctx.vertices.appendSliceAssumeCapacity(&[_]sdl.Vertex{
                .{
                    .position = .{ .x = positions_screen[0][0], .y = positions_screen[0][1] },
                    .color = if (ctx.opt.lighting) |p| BLK: {
                        var calc = if (p.light_calc_fn) |f| f else &calcLightColor;
                        break :BLK calc(c0, ctx.camera.position, world_v0, n0, p);
                    } else c0,
                    .tex_coord = t0,
                },
                .{
                    .position = .{ .x = positions_screen[1][0], .y = positions_screen[1][1] },
                    .color = if (ctx.opt.lighting) |p| BLK: {
                        var calc = if (p.light_calc_fn) |f| f else &calcLightColor;
                        break :BLK calc(c1, ctx.camera.position, world_v1, n1, p);
                    } else c1,
                    .tex_coord = t1,
                },
                .{
                    .position = .{ .x = positions_screen[2][0], .y = positions_screen[2][1] },
                    .color = if (ctx.opt.lighting) |p| BLK: {
                        var calc = if (p.light_calc_fn) |f| f else &calcLightColor;
                        break :BLK calc(c2, ctx.camera.position, world_v2, n2, p);
                    } else c2,
                    .tex_coord = t2,
                },
            });
            ctx.depths.appendSliceAssumeCapacity(&[_]f32{
                positions_screen[0][2],
                positions_screen[1][2],
                positions_screen[2][2],
            });
        }
    }
};
