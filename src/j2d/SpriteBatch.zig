const std = @import("std");
const assert = std.debug.assert;
const unicode = std.unicode;
const sdl = @import("sdl");
const jok = @import("../jok.zig");
const Sprite = @import("Sprite.zig");
const Camera = @import("Camera.zig");
const Atlas = jok.font.Atlas;
const zmath = jok.zmath;
const Self = @This();

pub const Error = error{
    TooMuchSheet,
    TooMuchSprite,
};

pub const DepthSortMethod = enum {
    none,
    back_to_forth,
    forth_to_back,
};

pub const BlendMethod = enum {
    blend,
    additive,
    overwrite,
};

pub const DrawOption = struct {
    pos: sdl.PointF,
    camera: ?Camera = null,
    tint_color: sdl.Color = sdl.Color.white,
    scale_w: f32 = 1.0,
    scale_h: f32 = 1.0,
    rotate_degree: f32 = 0,
    anchor_point: sdl.PointF = .{ .x = 0, .y = 0 },
    flip_h: bool = false,
    flip_v: bool = false,
    depth: f32 = 0.5,
};

pub const TextOption = struct {
    atlas: Atlas,
    pos: sdl.PointF,
    camera: ?Camera = null,
    ypos_type: Atlas.YPosType = .top,
    tint_color: sdl.Color = sdl.Color.white,
    scale_w: f32 = 1.0,
    scale_h: f32 = 1.0,
    rotate_degree: f32 = 0,
    anchor_point: sdl.PointF = .{ .x = 0, .y = 0 },
    flip_h: bool = false,
    flip_v: bool = false,
    depth: f32 = 0.5,
};

const BatchData = struct {
    const SpriteData = struct {
        sprite: Sprite,
        draw_option: DrawOption,
    };

    tex: ?sdl.Texture = null,
    sprites_data: std.ArrayList(SpriteData),
    vattrib: std.ArrayList(sdl.Vertex),
    vindices: std.ArrayList(u32),
};

// Memory allocator
allocator: std.mem.Allocator,

// Graphics Renderer
renderer: sdl.Renderer,

// All batch data
batches: []BatchData,

// Batch data search tree
batch_search: std.AutoHashMap(*sdl.c.SDL_Texture, u32),

// Maximum limit
max_sprites_per_drawcall: u32,

//  blend method
blend_method: BlendMethod = .blend,

//  sort method
depth_sort: DepthSortMethod = .none,

/// Create sprite-batch
pub fn init(
    ctx: *jok.Context,
    max_tex_num: u32,
    max_sprites_per_drawcall: u32,
) !Self {
    var self = try ctx.allocator.create(Self);
    errdefer ctx.allocator.destroy(self);
    const batches = try ctx.allocator.alloc(BatchData, max_tex_num);
    errdefer ctx.allocator.free(batches);
    self.* = Self{
        .allocator = ctx.allocator,
        .renderer = ctx.renderer,
        .batches = batches,
        .batch_search = std.AutoHashMap(*sdl.c.SDL_Texture, u32).init(ctx.allocator),
        .max_sprites_per_drawcall = max_sprites_per_drawcall,
    };
    for (self.batches) |*b| {
        b.tex = null;
        b.sprites_data = std.ArrayList(BatchData.SpriteData).initCapacity(ctx.allocator, 1000) catch unreachable;
        b.vattrib = std.ArrayList(sdl.Vertex).initCapacity(ctx.allocator, 4000) catch unreachable;
        b.vindices = std.ArrayList(u32).initCapacity(ctx.allocator, 6000) catch unreachable;
    }
    return self;
}

pub fn deinit(self: *Self) void {
    for (self.batches) |b| {
        b.sprites_data.deinit();
        b.vattrib.deinit();
        b.vindices.deinit();
    }
    self.allocator.free(self.batches);
    self.batch_search.deinit();
    self.* = undefined;
}

/// Begin batched data
pub const BatchOption = struct {
    depth_sort: DepthSortMethod = .none,
    blend_method: BlendMethod = .blend,
};
pub fn begin(self: *Self, opt: BatchOption) void {
    self.depth_sort = opt.depth_sort;
    self.blend_method = opt.blend_method;
    const size = self.batch_search.count();
    for (self.batches[0..size]) |*b| {
        b.tex = null;
        b.sprites_data.clearRetainingCapacity();
        b.vattrib.clearRetainingCapacity();
        b.vindices.clearRetainingCapacity();
    }
    self.batch_search.clearRetainingCapacity();
}

inline fn getBatchIndex(self: *Self, tex: sdl.Texture) !usize {
    const index = self.batch_search.get(tex.ptr) orelse blk: {
        var count = self.batch_search.count();
        if (count == self.batches.len) {
            return error.TooMuchSheet;
        }
        self.batches[count].tex = tex;
        try self.batch_search.put(tex.ptr, count);
        break :blk count;
    };
    return index;
}

pub fn addSprite(self: *Self, sprite: Sprite, opt: DrawOption) !void {
    var index = try self.getBatchIndex(sprite.tex);
    if (self.batches[index].sprites_data.items.len >= self.max_sprites_per_drawcall) {
        return error.TooMuchSprite;
    }
    try self.batches[index].sprites_data.append(.{
        .sprite = sprite,
        .draw_option = opt,
    });
}

pub fn addText(
    self: *Self,
    opt: TextOption,
    comptime fmt: []const u8,
    args: anytype,
) !void {
    const text = jok.imgui.format(fmt, args);
    if (text.len == 0) return;

    const transform_m = zmath.mul(
        zmath.mul(
            zmath.translation(-opt.pos.x, -opt.pos.y, 0),
            zmath.rotationZ(jok.utils.math.degreeToRadian(opt.rotate_degree)),
        ),
        zmath.translation(opt.pos.x, opt.pos.y, 0),
    );
    const index = try self.getBatchIndex(opt.atlas.tex);
    var pos = opt.pos;
    var i: u32 = 0;
    while (i < text.len) {
        const size = try unicode.utf8ByteSequenceLength(text[i]);
        const cp = @intCast(u32, try unicode.utf8Decode(text[i .. i + size]));
        if (opt.atlas.getVerticesOfCodePoint(pos, opt.ypos_type, sdl.Color.white, cp)) |cs| {
            if (self.batches[index].sprites_data.items.len >= self.max_sprites_per_drawcall) {
                return error.TooMuchSprite;
            }

            const v = zmath.mul(
                zmath.f32x4(
                    cs.vs[0].position.x,
                    pos.y + (cs.vs[0].position.y - pos.y) * opt.scale_h,
                    0,
                    1,
                ),
                transform_m,
            );
            const draw_pos = sdl.PointF{ .x = v[0], .y = v[1] };
            try self.batches[index].sprites_data.append(.{
                .sprite = .{
                    .width = cs.vs[1].position.x - cs.vs[0].position.x,
                    .height = cs.vs[3].position.y - cs.vs[0].position.y,
                    .uv0 = cs.vs[0].tex_coord,
                    .uv1 = cs.vs[2].tex_coord,
                    .tex = opt.atlas.tex,
                },
                .draw_option = .{
                    .pos = draw_pos,
                    .camera = opt.camera,
                    .tint_color = opt.tint_color,
                    .scale_w = opt.scale_w,
                    .scale_h = opt.scale_h,
                    .rotate_degree = opt.rotate_degree,
                    .anchor_point = opt.anchor_point,
                    .flip_h = opt.flip_h,
                    .flip_v = opt.flip_v,
                    .depth = opt.depth,
                },
            });

            pos.x += (cs.next_x - pos.x) * opt.scale_w;
        }
        i += size;
    }
}

fn ascendCompare(self: *Self, lhs: BatchData.SpriteData, rhs: BatchData.SpriteData) bool {
    _ = self;
    return lhs.draw_option.depth < rhs.draw_option.depth;
}

fn descendCompare(self: *Self, lhs: BatchData.SpriteData, rhs: BatchData.SpriteData) bool {
    _ = self;
    return lhs.draw_option.depth > rhs.draw_option.depth;
}

/// Send batched data to gpu, issue draw command
pub fn end(self: *Self) !void {
    const size = self.batch_search.count();
    if (size == 0) return;

    // Generate draw data
    for (self.batches) |*b| {
        // Sort sprites when needed
        switch (self.depth_sort) {
            .back_to_forth => {
                // Sort depth value in descending order
                std.sort.sort(
                    BatchData.SpriteData,
                    b.sprites_data.items,
                    self,
                    descendCompare,
                );
            },
            .forth_to_back => {
                // Sort depth value in ascending order
                std.sort.sort(
                    BatchData.SpriteData,
                    b.sprites_data.items,
                    self,
                    ascendCompare,
                );
            },
            else => {},
        }

        for (b.sprites_data.items) |data| {
            try data.sprite.appendDrawData(
                &b.vattrib,
                &b.vindices,
                .{
                    .pos = data.draw_option.pos,
                    .camera = data.draw_option.camera,
                    .tint_color = data.draw_option.tint_color,
                    .scale_w = data.draw_option.scale_w,
                    .scale_h = data.draw_option.scale_h,
                    .rotate_degree = data.draw_option.rotate_degree,
                    .anchor_point = data.draw_option.anchor_point,
                    .flip_h = data.draw_option.flip_h,
                    .flip_v = data.draw_option.flip_v,
                },
            );
        }
    }

    // Send draw command
    for (self.batches[0..size]) |b| {
        switch (self.blend_method) {
            .blend => try b.tex.?.setBlendMode(.blend),
            .additive => try b.tex.?.setBlendMode(.add),
            .overwrite => try b.tex.?.setBlendMode(.none),
        }
        try self.renderer.drawGeometry(
            b.tex.?,
            b.vattrib.items,
            b.vindices.items,
        );
    }
}
