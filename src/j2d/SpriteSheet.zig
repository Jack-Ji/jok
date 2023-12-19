const std = @import("std");
const assert = std.debug.assert;
const json = std.json;
const native_endian = @import("builtin").target.cpu.arch.endian();
const Sprite = @import("Sprite.zig");
const jok = @import("../jok.zig");
const sdl = jok.sdl;
const stb_rect_pack = jok.stb.rect_pack;
const stb_image = jok.stb.image;
const Self = @This();

pub const Error = error{
    TextureNotLargeEnough,
    InvalidJson,
    NoTextureData,
};

/// Image pixels
pub const ImagePixels = struct {
    data: []const u8,
    width: u32,
    height: u32,
    format: sdl.Texture.Format = jok.utils.gfx.getFormatByEndian(),
};

/// Image data source
pub const ImageSource = struct {
    name: []const u8,
    image: union(enum) {
        file_path: []const u8,
        pixels: ImagePixels,
    },
};

/// Sprite rectangle
pub const SpriteRect = struct {
    // Texture coordinate of top-left
    s0: f32,
    t0: f32,

    // Texture coordinate of bottom-right
    s1: f32,
    t1: f32,

    // Size of sprite
    width: f32,
    height: f32,
};

// Used allocator
allocator: std.mem.Allocator,

// Size of sheet
size: sdl.PointF,

// Packed pixels
packed_pixels: ?ImagePixels = null,

// Packed texture
tex: sdl.Texture,

// Sprite rectangles
rects: []SpriteRect,

// Sprite search-tree
search_tree: std.StringHashMap(u32),

/// Create sprite-sheet
pub fn create(
    ctx: jok.Context,
    sources: []const ImageSource,
    width: u32,
    height: u32,
    gap: u32,
    keep_packed_pixels: bool,
) !*Self {
    assert(sources.len > 0);
    const ImageData = struct {
        is_file: bool,
        pixels: ImagePixels,
    };

    const allocator = ctx.allocator();
    var pixels = try allocator.alloc(u8, width * height * 4);
    errdefer allocator.free(pixels);
    @memset(pixels, 0);

    var tree = std.StringHashMap(u32).init(allocator);
    var rects = try allocator.alloc(SpriteRect, sources.len);
    errdefer allocator.free(rects);

    var stb_rects = try allocator.alloc(stb_rect_pack.stbrp_rect, sources.len);
    defer allocator.free(stb_rects);

    const stb_nodes = try allocator.alloc(stb_rect_pack.stbrp_node, width);
    defer allocator.free(stb_nodes);

    var images = try allocator.alloc(ImageData, sources.len);
    defer allocator.free(images);

    // Load images' data
    for (sources, 0..) |s, i| {
        switch (s.image) {
            .file_path => |path| {
                var image_width: c_int = undefined;
                var image_height: c_int = undefined;
                var image_channels: c_int = undefined;
                var image_data = stb_image.stbi_load(
                    path.ptr,
                    &image_width,
                    &image_height,
                    &image_channels,
                    4, // Alpha channel is required
                );
                assert(image_data != null);
                const image_len = @as(usize, @intCast(image_width * image_height * 4));
                images[i] = .{
                    .is_file = false,
                    .pixels = .{
                        .data = image_data[0..image_len],
                        .width = @intCast(image_width),
                        .height = @intCast(image_height),
                        .format = jok.utils.gfx.getFormatByEndian(),
                    },
                };
            },
            .pixels => |ps| {
                assert(ps.data.len > 0 and ps.width > 0 and ps.height > 0);
                const channels = jok.utils.gfx.getChannels(ps.format);
                assert(channels == 4);
                assert(ps.data.len == ps.width * ps.height * channels);
                images[i] = .{
                    .is_file = false,
                    .pixels = ps,
                };
            },
        }
        stb_rects[i] = std.mem.zeroes(stb_rect_pack.stbrp_rect);
        stb_rects[i].id = @intCast(i);
        stb_rects[i].w = @intCast(images[i].pixels.width + gap);
        stb_rects[i].h = @intCast(images[i].pixels.height + gap);
    }
    defer {
        // Free file-images' data when we're done
        for (images) |img| {
            if (img.is_file) {
                stb_image.stbi_image_free(img.pixels.data.ptr);
            }
        }
    }

    // Start packing images
    var pack_ctx: stb_rect_pack.stbrp_context = undefined;
    stb_rect_pack.stbrp_init_target(
        &pack_ctx,
        @intCast(width),
        @intCast(height),
        stb_nodes.ptr,
        @intCast(stb_nodes.len),
    );
    const rc = stb_rect_pack.stbrp_pack_rects(
        &pack_ctx,
        stb_rects.ptr,
        @intCast(stb_rects.len),
    );
    if (rc == 0) {
        return error.TextureNotLargeEnough;
    }

    // Merge textures and upload to gpu
    const inv_width = 1.0 / @as(f32, @floatFromInt(width));
    const inv_height = 1.0 / @as(f32, @floatFromInt(height));
    for (stb_rects, 0..) |r, i| {
        assert(r.was_packed == 1);
        rects[i] = .{
            .s0 = @as(f32, @floatFromInt(r.x)) * inv_width,
            .t0 = @as(f32, @floatFromInt(r.y)) * inv_height,
            .s1 = @as(f32, @floatFromInt(r.x + r.w - @as(c_int, @intCast(gap)))) * inv_width,
            .t1 = @as(f32, @floatFromInt(r.y + r.h - @as(c_int, @intCast(gap)))) * inv_height,
            .width = @floatFromInt(r.w - @as(c_int, @intCast(gap))),
            .height = @floatFromInt(r.h - @as(c_int, @intCast(gap))),
        };
        const y_begin: u32 = @intCast(r.y);
        const y_end: u32 = @intCast(r.y + r.h - @as(c_int, @intCast(gap)));
        const src_pixels = images[i].pixels;
        const dst_stride: u32 = width * 4;
        const src_stride: u32 = src_pixels.width * 4;
        var y: u32 = y_begin;
        while (y < y_end) : (y += 1) {
            const dst_offset: u32 = y * dst_stride + @as(u32, @intCast(r.x)) * 4;
            const src_offset: u32 = (y - y_begin) * src_stride;
            @memcpy(
                pixels[dst_offset .. dst_offset + src_stride],
                src_pixels.data[src_offset .. src_offset + src_stride],
            );
        }
    }
    var tex = try jok.utils.gfx.createTextureFromPixels(
        ctx.renderer(),
        pixels,
        jok.utils.gfx.getFormatByEndian(),
        .static,
        width,
        height,
    );
    try tex.setScaleMode(.nearest);
    errdefer tex.destroy();

    // Fill search tree, abort if name collision happens
    for (sources, 0..) |s, i| {
        try tree.putNoClobber(
            try std.fmt.allocPrint(allocator, "{s}", .{s.name}),
            @intCast(i),
        );
    }

    const self = try allocator.create(Self);
    self.* = .{
        .allocator = allocator,
        .size = .{
            .x = @floatFromInt(width),
            .y = @floatFromInt(height),
        },
        .packed_pixels = if (keep_packed_pixels) ImagePixels{
            .width = width,
            .height = height,
            .data = pixels,
            .format = jok.utils.gfx.getFormatByEndian(),
        } else blk: {
            allocator.free(pixels);
            break :blk null;
        },
        .tex = tex,
        .rects = rects,
        .search_tree = tree,
    };
    return self;
}

/// Create sprite-sheet with all picture files in given directory
pub const DirScanOption = struct {
    accept_png: bool = true,
    accept_jpg: bool = true,
};
pub fn fromPicturesInDir(
    ctx: jok.Context,
    dir_path: []const u8,
    width: u32,
    height: u32,
    gap: u32,
    keep_packed_pixels: bool,
    opt: DirScanOption,
) !*Self {
    var curdir = std.fs.cwd();
    var dir = try curdir.openDir(dir_path, .{ .no_follow = true, .iterate = true });
    defer dir.close();

    const allocator = ctx.allocator();
    var images = try std.ArrayList(ImageSource).initCapacity(allocator, 10);
    defer images.deinit();

    // Collect pictures
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    var it = dir.iterate();
    while (try it.next()) |entry| {
        if (entry.kind != .file) continue;
        if (entry.name.len < 5) continue;
        if ((opt.accept_png and std.mem.eql(u8, ".png", entry.name[entry.name.len - 4 ..])) or
            (opt.accept_jpg and std.mem.eql(u8, ".jpg", entry.name[entry.name.len - 4 ..])))
        {
            try images.append(.{
                .name = try std.fmt.allocPrint(
                    arena.allocator(),
                    "{s}",
                    .{entry.name[0 .. entry.name.len - 4]},
                ),
                .image = .{
                    .file_path = try std.fs.path.joinZ(arena.allocator(), &[_][]const u8{
                        dir_path,
                        entry.name,
                    }),
                },
            });
        }
    }

    return try Self.create(ctx, images.items, width, height, gap, keep_packed_pixels);
}

/// Create from previous written sheet files (a picture and a json file)
pub fn fromSheetFiles(ctx: jok.Context, path: []const u8) !*Self {
    var path_buf: [128]u8 = undefined;

    // Load texture
    const image_path = try std.fmt.bufPrintZ(&path_buf, "{s}.png", .{path});
    var tex = try jok.utils.gfx.createTextureFromFile(
        ctx.renderer(),
        image_path,
        .static,
        false,
    );
    try tex.setScaleMode(.nearest);
    errdefer tex.destroy();

    // Load sprites info
    const allocator = ctx.allocator();
    const json_path = try std.fmt.bufPrint(&path_buf, "{s}.json", .{path});
    var file = try std.fs.cwd().openFile(json_path, .{});
    defer file.close();
    var parsed = try json.parseFromTokenSource(json.Value, allocator, file.reader(), .{});
    defer parsed.deinit();
    if (parsed.value != .object) return error.InvalidJson;
    const rect_count = parsed.value.object.count();
    assert(rect_count > 0);
    var rects = try allocator.alloc(SpriteRect, rect_count);
    errdefer allocator.free(rects);
    var search_tree = std.StringHashMap(u32).init(allocator);
    errdefer search_tree.deinit();
    var it = parsed.value.object.iterator();
    var i: u32 = 0;
    while (it.next()) |entry| : (i += 1) {
        const name = entry.key_ptr.*;
        const info = entry.value_ptr.*.object;
        rects[i] = SpriteRect{
            .s0 = @floatCast(info.get("s0").?.Float),
            .t0 = @floatCast(info.get("t0").?.Float),
            .s1 = @floatCast(info.get("s1").?.Float),
            .t1 = @floatCast(info.get("t1").?.Float),
            .width = @floatCast(info.get("width").?.Float),
            .height = @floatCast(info.get("height").?.Float),
        };
        try search_tree.putNoClobber(
            try std.fmt.allocPrint(allocator, "{s}", .{name}),
            i,
        );
    }

    // Allocate and init SpriteSheet
    const sp = try allocator.create(Self);
    sp.* = Self{
        .allocator = allocator,
        .tex = tex,
        .rects = rects,
        .search_tree = search_tree,
    };
    return sp;
}

/// Create a very raw sheet with a single picture, initialize name tree if possible
pub const SpriteInfo = struct {
    name: []const u8,
    rect: sdl.RectangleF,
};
pub fn fromSinglePicture(
    ctx: jok.Context,
    path: [:0]const u8,
    sprites: []const SpriteInfo,
) !*Self {
    var tex = try jok.utils.gfx.createTextureFromFile(
        ctx.renderer(),
        path,
        .static,
        false,
    );
    try tex.setScaleMode(.nearest);
    errdefer tex.destroy();

    const info = try tex.query();
    const tex_width = @as(f32, @floatFromInt(info.width));
    const tex_height = @as(f32, @floatFromInt(info.height));

    const allocator = ctx.allocator();
    var tree = std.StringHashMap(u32).init(allocator);
    var rects = try allocator.alloc(SpriteRect, sprites.len);
    errdefer allocator.free(rects);

    // Fill search tree, abort if name collision happens
    for (sprites, 0..) |sp, i| {
        const sr = SpriteRect{
            .width = std.math.min(sp.rect.width, tex_width - sp.rect.x),
            .height = std.math.min(sp.rect.height, tex_height - sp.rect.y),
            .s0 = .{ .x = sp.rect.x / tex_width, .y = sp.rect.y / tex_height },
            .t0 = undefined,
        };
        sp.s1 = std.math.min(1.0, (sp.rect.x + sp.rect.width) / tex_width);
        sp.t1 = std.math.min(1.0, (sp.rect.y + sp.rect.height) / tex_height);
        rects[i] = sr;
        try tree.putNoClobber(
            try std.fmt.allocPrint(allocator, "{s}", .{sp.name}),
            @intCast(i),
        );
    }

    const self = try allocator.create(Self);
    self.* = .{
        .allocator = allocator,
        .tex = tex,
        .rects = rects,
        .search_tree = tree,
    };
    return self;
}

/// Destroy sprite-sheet
pub fn destroy(self: *Self) void {
    if (self.packed_pixels) |px| {
        self.allocator.free(px.data);
    }
    self.tex.destroy();
    self.allocator.free(self.rects);
    var it = self.search_tree.iterator();
    while (it.next()) |entry| {
        self.allocator.free(entry.key_ptr.*);
    }
    self.search_tree.deinit();
    self.allocator.destroy(self);
}

/// Save sprite-sheet to 2 files (image and json)
pub fn saveToFiles(self: Self, path: []const u8) !void {
    if (self.packed_pixels == null) return error.NoTextureData;
    var path_buf: [128]u8 = undefined;

    // Save image file
    const image_path = try std.fmt.bufPrintZ(&path_buf, "{s}.png", .{path});
    try jok.utils.gfx.savePixelsToFile(
        self.packed_pixels.?.data,
        self.packed_pixels.?.width,
        self.packed_pixels.?.height,
        self.packed_pixels.?.format,
        image_path,
        .{ .format = .png },
    );

    // Save json file
    const json_path = try std.fmt.bufPrint(&path_buf, "{s}.json", .{path});
    var json_file = try std.fs.cwd().createFile(json_path, .{});
    defer json_file.close();
    var arena_allocator = std.heap.ArenaAllocator.init(self.allocator);
    defer arena_allocator.deinit();
    var json_root = json.Value{
        .object = json.ObjectMap.init(arena_allocator.allocator()),
    };
    var it = self.search_tree.iterator();
    while (it.next()) |entry| {
        const name = entry.key_ptr.*;
        const rect = self.rects[entry.value_ptr.*];
        var obj = json.ObjectMap.init(arena_allocator.allocator());
        try obj.put("s0", json.Value{ .float = @as(f64, rect.s0) });
        try obj.put("t0", json.Value{ .float = @as(f64, rect.t0) });
        try obj.put("s1", json.Value{ .float = @as(f64, rect.s1) });
        try obj.put("t1", json.Value{ .float = @as(f64, rect.t1) });
        try obj.put("width", json.Value{ .float = @as(f64, rect.width) });
        try obj.put("height", json.Value{ .float = @as(f64, rect.height) });
        try json_root.object.put(name, json.Value{ .object = obj });
    }
    try json_root.jsonStringify(
        .{ .whitespace = json.StringifyOptions.Whitespace{} },
        json_file.writer(),
    );
}

/// Get sprite by name
pub fn getSpriteByName(self: *Self, name: []const u8) ?Sprite {
    if (self.getSpriteRect(name)) |rect| {
        return Sprite{
            .width = rect.width,
            .height = rect.height,
            .uv0 = .{ .x = rect.s0, .y = rect.t0 },
            .uv1 = .{ .x = rect.s1, .y = rect.t1 },
            .tex = self.tex,
        };
    }
    return null;
}

/// Get sprite by rectangle
pub fn getSpriteByRectangle(self: *Self, rect: sdl.RectangleF) Sprite {
    const info = try self.tex.query();
    const tex_width = @as(f32, @floatFromInt(info.width));
    const tex_height = @as(f32, @floatFromInt(info.height));
    var sp = Sprite{
        .width = std.math.min(rect.width, tex_width - rect.x),
        .height = std.math.min(rect.height, tex_height - rect.y),
        .tex = self.tex,
        .uv0 = .{ .x = rect.x / tex_width, .y = rect.y / tex_height },
    };
    sp.uv1.x = std.math.min(1.0, (rect.x + sp.width) / tex_width);
    sp.uv1.y = std.math.min(1.0, (rect.y + sp.height) / tex_height);
    return sp;
}

/// Get sprite rectangle by name
inline fn getSpriteRect(self: Self, name: []const u8) ?SpriteRect {
    if (self.search_tree.get(name)) |idx| {
        return self.rects[idx];
    }
    return null;
}
