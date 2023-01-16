const std = @import("std");
const assert = std.debug.assert;
const math = std.math;
const builtin = @import("builtin");
const sdl = @import("sdl");
const jok = @import("../jok.zig");
const zjobs = jok.zjobs;
const zmath = jok.zmath;
const j3d = jok.j3d;
const lighting = j3d.lighting;
const Camera = j3d.Camera;
const utils = jok.utils;
const internal = @import("internal.zig");
const Self = @This();

const max_jobs_num = @bitSizeOf(usize);

allocator: std.mem.Allocator,

// Jobs Queue
jobs: *zjobs.JobQueue(.{}),

// Triangle vertices
indices: std.ArrayList(u32),
sorted: bool = false,
vertices: std.ArrayList(sdl.Vertex),
depths: std.ArrayList(f32),
mutex: std.Thread.Mutex,

// Parallel rendering jobs
rendering_jobs: [max_jobs_num]RenderJob,
rendering_job_ids: [max_jobs_num]zjobs.JobId,

pub fn create(
    allocator: std.mem.Allocator,
    jobs: *zjobs.JobQueue(.{}),
) !*Self {
    if (builtin.single_threaded) {
        @panic("Current system doesn't support parallel rendering!");
    }

    var self = try allocator.create(Self);
    errdefer allocator.destroy(self);
    self.* = Self{
        .allocator = allocator,
        .jobs = jobs,
        .indices = std.ArrayList(u32).init(allocator),
        .vertices = std.ArrayList(sdl.Vertex).init(allocator),
        .depths = std.ArrayList(f32).init(allocator),
        .mutex = std.Thread.Mutex{},
        .rendering_jobs = undefined,
        .rendering_job_ids = undefined,
    };
    var i: u32 = 0;
    while (i < self.rendering_jobs.len) : (i += 1) {
        self.rendering_jobs[i] = try RenderJob.init(allocator, self, i);
        self.rendering_job_ids[i] = .none;
    }
    return self;
}

pub fn destroy(self: *Self) void {
    self.indices.deinit();
    self.vertices.deinit();
    self.depths.deinit();
    var i: u32 = 0;
    while (i < self.rendering_jobs.len) : (i += 1) {
        self.rendering_jobs[i].deinit();
    }
    self.allocator.destroy(self);
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
}

/// Advanced vertice appending options
pub const RenderOption = struct {
    aabb: ?[6]f32 = null,
    cull_faces: bool = true,
    lighting_opt: ?lighting.LightingOption = null,
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
    opt: RenderOption,
) !void {
    // Do early test with aabb if possible
    if (opt.aabb) |ab| {
        const mvp = zmath.mul(model, camera.getViewProjectMatrix());
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

    var i: usize = 0;
    while (true) : (i = (i + 1) % self.rendering_job_ids.len) {
        if (self.rendering_job_ids[i] != .none) {
            continue;
        }

        try self.rendering_jobs[i].setup(
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

        assert(self.jobs.isRunning());
        self.rendering_job_ids[i] = try self.jobs.schedule(
            .none,
            self.rendering_jobs[i],
        );
        break;
    }
}

/// Sort triangles by depth values
fn compareTriangleDepths(self: *Self, lhs: [3]u32, rhs: [3]u32) bool {
    const d1 = (self.depths.items[lhs[0]] + self.depths.items[lhs[1]] + self.depths.items[lhs[2]]) / 3.0;
    const d2 = (self.depths.items[rhs[0]] + self.depths.items[rhs[1]] + self.depths.items[rhs[2]]) / 3.0;
    return d1 > d2;
}

inline fn waitJobs(self: *Self) void {
    for (self.rendering_job_ids) |id| {
        if (id != .none) {
            self.jobs.wait(id);
        }
    }
}

/// Draw the meshes, fill triangles, using texture if possible
pub fn draw(self: *Self, renderer: sdl.Renderer, tex: ?sdl.Texture) !void {
    self.waitJobs();

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
    self.waitJobs();

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
        opt: RenderOption,

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
    prd: *Self,
    idx: usize,
    context: *Context,

    fn init(allocator: std.mem.Allocator, prd: *Self, idx: usize) !RenderJob {
        var ctx = try allocator.create(Context);
        ctx.* = Context.init(allocator);
        var job = RenderJob{
            .allocator = allocator,
            .prd = prd,
            .idx = idx,
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
        opt: RenderOption,
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

        // Do face-culling and W-pannel clipping
        const normal_transform = zmath.transpose(zmath.inverse(ctx.model));
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
            }, normal_transform);
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

            // Transform to screen coordinates
            const ndcs = zmath.Mat{
                ndc0,
                ndc1,
                ndc2,
                zmath.f32x4(0.0, 0.0, 0.0, 1.0),
            };
            const positions_screen = zmath.mul(ndcs, ndc_to_screen);

            // Get screen coordinate
            const p0 = sdl.PointF{ .x = positions_screen[0][0], .y = positions_screen[0][1] };
            const p1 = sdl.PointF{ .x = positions_screen[1][0], .y = positions_screen[1][1] };
            const p2 = sdl.PointF{ .x = positions_screen[2][0], .y = positions_screen[2][1] };

            // Get depths
            const d0 = positions_screen[0][2];
            const d1 = positions_screen[1][2];
            const d2 = positions_screen[2][2];

            // Get color of vertices
            const c0_diffuse = if (ctx.colors.items.len > 0) ctx.clip_colors.items[idx0] else sdl.Color.white;
            const c1_diffuse = if (ctx.colors.items.len > 0) ctx.clip_colors.items[idx1] else sdl.Color.white;
            const c2_diffuse = if (ctx.colors.items.len > 0) ctx.clip_colors.items[idx2] else sdl.Color.white;
            const c0 = if (ctx.opt.lighting_opt) |p| BLK: {
                var calc = if (p.light_calc_fn) |f| f else &lighting.calcLightColor;
                break :BLK calc(c0_diffuse, ctx.camera.position, world_v0, n0, p);
            } else c0_diffuse;
            const c1 = if (ctx.opt.lighting_opt) |p| BLK: {
                var calc = if (p.light_calc_fn) |f| f else &lighting.calcLightColor;
                break :BLK calc(c1_diffuse, ctx.camera.position, world_v1, n1, p);
            } else c1_diffuse;
            const c2 = if (ctx.opt.lighting_opt) |p| BLK: {
                var calc = if (p.light_calc_fn) |f| f else &lighting.calcLightColor;
                break :BLK calc(c2_diffuse, ctx.camera.position, world_v2, n2, p);
            } else c2_diffuse;

            // Get texture coordinates
            const t0 = if (ctx.texcoords.items.len > 0) ctx.clip_texcoords.items[idx0] else undefined;
            const t1 = if (ctx.texcoords.items.len > 0) ctx.clip_texcoords.items[idx1] else undefined;
            const t2 = if (ctx.texcoords.items.len > 0) ctx.clip_texcoords.items[idx2] else undefined;

            // Append to ouput buffers
            ctx.vertices.appendSliceAssumeCapacity(&[_]sdl.Vertex{
                .{ .position = p0, .color = c0, .tex_coord = t0 },
                .{ .position = p1, .color = c1, .tex_coord = t1 },
                .{ .position = p2, .color = c2, .tex_coord = t2 },
            });
            ctx.depths.appendSliceAssumeCapacity(&[_]f32{ d0, d1, d2 });
        }

        // Finally, we can append vertices for rendering
        job.prd.mutex.lock();
        defer job.prd.mutex.unlock();
        job.prd.vertices.ensureTotalCapacityPrecise(job.prd.vertices.items.len + ctx.vertices.items.len) catch unreachable;
        job.prd.depths.ensureTotalCapacityPrecise(job.prd.vertices.items.len + ctx.vertices.items.len) catch unreachable;
        job.prd.indices.ensureTotalCapacityPrecise(job.prd.vertices.items.len + ctx.vertices.items.len) catch unreachable;
        job.prd.vertices.appendSliceAssumeCapacity(ctx.vertices.items);
        job.prd.depths.appendSliceAssumeCapacity(ctx.depths.items);
        const offset = job.prd.indices.items.len;
        i = 0;
        while (i < ctx.vertices.items.len) : (i += 1) {
            job.prd.indices.appendAssumeCapacity(@intCast(u32, offset + i));
        }
        job.prd.rendering_job_ids[job.idx] = .none;
    }
};
