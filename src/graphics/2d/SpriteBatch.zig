const std = @import("std");
const assert = std.debug.assert;
const sdl = @import("sdl");
const Sprite = @import("Sprite.zig");
const SpriteSheet = @import("SpriteSheet.zig");
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
    alpha_blend,
    additive,
    overwrite,
};

pub const DrawOption = struct {
    pos: sdl.PointF,
    color: sdl.Color = sdl.Color.white,
    scale_w: f32 = 1.0,
    scale_h: f32 = 1.0,
    rotate_degree: f32 = 0,
    anchor_point: sdl.PointF = .{ .x = 0, .y = 0 },
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

/// memory allocator
allocator: std.mem.Allocator,

/// all batch data
batches: []BatchData,

/// sprite-sheet search tree
search_tree: std.AutoHashMap(*SpriteSheet, u32),

/// maximum limit
max_sprites_per_drawcall: u32,

///  sort method
depth_sort: DepthSortMethod,

/// create sprite-batch
pub fn init(
    allocator: std.mem.Allocator,
    max_sheet_num: u32,
    max_sprites_per_drawcall: u32,
) !*Self {
    var self = try allocator.create(Self);
    errdefer allocator.destroy(self);
    const batches = try allocator.alloc(BatchData, max_sheet_num);
    errdefer allocator.free(batches);
    self.* = Self{
        .allocator = allocator,
        .batches = batches,
        .search_tree = std.AutoHashMap(*SpriteSheet, u32).init(allocator),
        .max_sprites_per_drawcall = max_sprites_per_drawcall,
        .depth_sort = .none,
    };
    for (self.batches) |*b| {
        b.sheet = null;
        b.sprites_data = std.ArrayList(BatchData.SpriteData).initCapacity(allocator, 1000) catch unreachable;
        b.vattrib = std.ArrayList(sdl.Vertex).initCapacity(allocator, 4000) catch unreachable;
        b.vindices = std.ArrayList(u32).initCapacity(allocator, 6000) catch unreachable;
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
    self.search_tree.deinit();
    self.allocator.destroy(self);
}

/// begin batched data
pub const BatchOption = struct {
    depth_sort: DepthSortMethod = .none,
};
pub fn begin(self: *Self, opt: BatchOption) void {
    self.depth_sort = opt.depth_sort;
    const size = self.search_tree.count();
    for (self.batches[0..size]) |*b| {
        b.sheet = null;
        b.sprites_data.clearRetainingCapacity();
        b.vattrib.clearRetainingCapacity();
        b.vindices.clearRetainingCapacity();
    }
    self.search_tree.clearRetainingCapacity();
}

/// add sprite to next batch
pub fn drawSprite(self: *Self, sprite: Sprite, opt: DrawOption) !void {
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

/// send batched data to gpu, issue draw command
pub fn end(self: *Self, renderer: sdl.Renderer) !void {
    const size = self.search_tree.count();
    if (size == 0) return;

    // generate draw data
    for (self.batches) |*b| {
        // sort sprites when needed
        switch (self.depth_sort) {
            .back_to_forth => {
                // sort depth value in descending order
                std.sort.sort(
                    BatchData.SpriteData,
                    b.sprites_data.items,
                    self,
                    descendCompare,
                );
            },
            .forth_to_back => {
                // sort depth value in ascending order
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
                    .scale_w = data.draw_option.scale_w,
                    .scale_h = data.draw_option.scale_h,
                    .rotate_degree = data.draw_option.rotate_degree,
                    .anchor_point = data.draw_option.anchor_point,
                    .tint_color = data.draw_option.color,
                },
            );
        }
    }

    // send draw command
    for (self.batches[0..size]) |b| {
        try renderer.drawGeometry(
            b.sheet.?.tex,
            b.vattrib.items,
            b.vindices.items,
        );
    }
}
