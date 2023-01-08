const std = @import("std");
const assert = std.debug.assert;
const sdl = @import("sdl");
const jok = @import("../jok.zig");
const Sprite = @import("Sprite.zig");
const SpriteSheet = @import("SpriteSheet.zig");
const Camera = @import("Camera.zig");
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

const BatchData = struct {
    const SpriteData = struct {
        sprite: Sprite,
        draw_option: DrawOption,
    };

    sheet: ?*SpriteSheet = null,
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

// Sprite-sheet search tree
search_tree: std.AutoHashMap(*SpriteSheet, u32),

// Maximum limit
max_sprites_per_drawcall: u32,

//  blend method
blend_method: BlendMethod = .blend,

//  sort method
depth_sort: DepthSortMethod = .none,

/// Create sprite-batch
pub fn create(
    ctx: *jok.Context,
    max_sheet_num: u32,
    max_sprites_per_drawcall: u32,
) !*Self {
    var self = try ctx.allocator.create(Self);
    errdefer ctx.allocator.destroy(self);
    const batches = try ctx.allocator.alloc(BatchData, max_sheet_num);
    errdefer ctx.allocator.free(batches);
    self.* = Self{
        .allocator = ctx.allocator,
        .renderer = ctx.renderer,
        .batches = batches,
        .search_tree = std.AutoHashMap(*SpriteSheet, u32).init(ctx.allocator),
        .max_sprites_per_drawcall = max_sprites_per_drawcall,
    };
    for (self.batches) |*b| {
        b.sheet = null;
        b.sprites_data = std.ArrayList(BatchData.SpriteData).initCapacity(ctx.allocator, 1000) catch unreachable;
        b.vattrib = std.ArrayList(sdl.Vertex).initCapacity(ctx.allocator, 4000) catch unreachable;
        b.vindices = std.ArrayList(u32).initCapacity(ctx.allocator, 6000) catch unreachable;
    }
    return self;
}

pub fn destroy(self: *Self) void {
    for (self.batches) |b| {
        b.sprites_data.deinit();
        b.vattrib.deinit();
        b.vindices.deinit();
    }
    self.allocator.free(self.batches);
    self.search_tree.deinit();
    self.allocator.destroy(self);
}

/// Begin batched data
pub const BatchOption = struct {
    depth_sort: DepthSortMethod = .none,
    blend_method: BlendMethod = .blend,
};
pub fn begin(self: *Self, opt: BatchOption) void {
    self.depth_sort = opt.depth_sort;
    self.blend_method = opt.blend_method;
    const size = self.search_tree.count();
    for (self.batches[0..size]) |*b| {
        b.sheet = null;
        b.sprites_data.clearRetainingCapacity();
        b.vattrib.clearRetainingCapacity();
        b.vindices.clearRetainingCapacity();
    }
    self.search_tree.clearRetainingCapacity();
}

/// Add sprite to next batch
pub fn addSprite(self: *Self, sprite: Sprite, opt: DrawOption) !void {
    var index = self.search_tree.get(sprite.sheet) orelse blk: {
        var count = self.search_tree.count();
        if (count == self.batches.len) {
            return error.TooMuchSheet;
        }
        self.batches[count].sheet = sprite.sheet;
        try self.search_tree.put(sprite.sheet, count);
        break :blk count;
    };
    if (self.batches[index].sprites_data.items.len >= self.max_sprites_per_drawcall) {
        return error.TooMuchSprite;
    }
    try self.batches[index].sprites_data.append(.{
        .sprite = sprite,
        .draw_option = opt,
    });
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
    const size = self.search_tree.count();
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
                    .pos = if (data.draw_option.camera) |c| c.translatePointF(data.draw_option.pos) else data.draw_option.pos,
                    .tint_color = data.draw_option.tint_color,
                    .scale_w = if (data.draw_option.camera) |c| data.draw_option.scale_w / c.zoom else data.draw_option.scale_w,
                    .scale_h = if (data.draw_option.camera) |c| data.draw_option.scale_h / c.zoom else data.draw_option.scale_h,
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
            .blend => try b.sheet.?.tex.setBlendMode(.blend),
            .additive => try b.sheet.?.tex.setBlendMode(.add),
            .overwrite => try b.sheet.?.tex.setBlendMode(.none),
        }
        try self.renderer.drawGeometry(
            b.sheet.?.tex,
            b.vattrib.items,
            b.vindices.items,
        );
    }
}
