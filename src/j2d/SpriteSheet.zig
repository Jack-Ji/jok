const std = @import("std");
const builtin = @import("builtin");
const assert = std.debug.assert;
const json = std.json;
const Sprite = @import("Sprite.zig");
const jok = @import("../jok.zig");
const physfs = jok.physfs;
const stb_rect_pack = jok.stb.rect_pack;
const stb_image = jok.stb.image;
const Self = @This();

pub const Error = error{
    TextureNotLargeEnough,
    InvalidFormat,
    NoPixelData,
    Unimplemented,
};

const max_sheet_data_size = 1 << 23;
const magic_sheet_header = [_]u8{ 's', 'h', 'e', 'e', 't', '@', 'j', 'o', 'k' };

/// Image pixels
/// Only support sdl.SDL_PIXELFORMAT_RGBA32
pub const ImagePixels = struct {
    data: []const u8,
    width: u32,
    height: u32,
};

/// Image data source
pub const ImageSource = struct {
    name: []const u8,
    image: union(enum) {
        file_path: [:0]const u8,
        file_data: []const u8,
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
size: jok.Size,

// Packed pixels
packed_pixels: ?ImagePixels = null,

// Packed texture
tex: jok.Texture,

// Sprite rectangles
rects: []SpriteRect,

// Sprite search-tree
search_tree: std.StringHashMap(u32),

/// Create sprite-sheet
pub const CreateSheetOption = struct {
    gap: u32 = 1,
    keep_packed_pixels: bool = false,
};
pub fn create(
    ctx: jok.Context,
    sources: []const ImageSource,
    width: u32,
    height: u32,
    opt: CreateSheetOption,
) !*Self {
    if (sources.len == 0) {
        @panic("ZERO image sources are given! Probably something is wrong.");
    }
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
                const filedata = BLK: {
                    if (ctx.cfg().jok_enable_physfs) {
                        const file = try physfs.open(path, .read);
                        defer file.close();
                        break :BLK try file.readAllAlloc(allocator);
                    } else {
                        break :BLK try std.fs.cwd().readFileAlloc(
                            allocator,
                            std.mem.sliceTo(path, 0),
                            1 << 30,
                        );
                    }
                };
                defer allocator.free(filedata);
                var image_data = stb_image.stbi_load_from_memory(
                    filedata.ptr,
                    @intCast(filedata.len),
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
                    },
                };
            },
            .file_data => |data| {
                var image_width: c_int = undefined;
                var image_height: c_int = undefined;
                var image_channels: c_int = undefined;
                var image_data = stb_image.stbi_load_from_memory(
                    data.ptr,
                    @intCast(data.len),
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
                    },
                };
            },
            .pixels => |ps| {
                assert(ps.data.len > 0 and ps.width > 0 and ps.height > 0);
                assert(ps.data.len == ps.width * ps.height * 4);
                images[i] = .{
                    .is_file = false,
                    .pixels = ps,
                };
            },
        }
        stb_rects[i] = std.mem.zeroes(stb_rect_pack.stbrp_rect);
        stb_rects[i].id = @intCast(i);
        stb_rects[i].w = @intCast(images[i].pixels.width + opt.gap);
        stb_rects[i].h = @intCast(images[i].pixels.height + opt.gap);
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
            .s1 = @as(f32, @floatFromInt(r.x + r.w - @as(c_int, @intCast(opt.gap)))) * inv_width,
            .t1 = @as(f32, @floatFromInt(r.y + r.h - @as(c_int, @intCast(opt.gap)))) * inv_height,
            .width = @floatFromInt(r.w - @as(c_int, @intCast(opt.gap))),
            .height = @floatFromInt(r.h - @as(c_int, @intCast(opt.gap))),
        };
        const y_begin: u32 = @intCast(r.y);
        const y_end: u32 = @intCast(r.y + r.h - @as(c_int, @intCast(opt.gap)));
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
    var tex = try ctx.renderer().createTexture(
        .{ .width = width, .height = height },
        pixels,
        .{},
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
            .width = width,
            .height = height,
        },
        .packed_pixels = if (opt.keep_packed_pixels) ImagePixels{
            .width = width,
            .height = height,
            .data = pixels,
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
pub const CreateSheetFromDirOption = struct {
    gap: u32 = 1,
    keep_packed_pixels: bool = false,
    accept_png: bool = true,
    accept_jpg: bool = true,
};
pub fn fromPicturesInDir(
    ctx: jok.Context,
    dir_path: [*:0]const u8,
    width: u32,
    height: u32,
    opt: CreateSheetFromDirOption,
) !*Self {
    const allocator = ctx.allocator();
    var images = try std.ArrayList(ImageSource).initCapacity(allocator, 10);
    defer images.deinit();

    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();

    if (ctx.cfg().jok_enable_physfs) {
        var it = try physfs.getListIterator(dir_path);
        defer it.deinit();

        // Collect pictures
        while (it.next()) |p| {
            const fname = std.mem.sliceTo(p, 0);
            if (fname.len < 5) continue;
            if ((opt.accept_png and std.mem.eql(u8, ".png", fname[fname.len - 4 ..])) or
                (opt.accept_jpg and std.mem.eql(u8, ".jpg", fname[fname.len - 4 ..])))
            {
                try images.append(.{
                    .name = try std.fmt.allocPrint(
                        arena.allocator(),
                        "{s}",
                        .{fname[0 .. fname.len - 4]},
                    ),
                    .image = .{
                        .file_path = try std.fmt.allocPrintSentinel(
                            arena.allocator(),
                            "{s}/{s}",
                            .{ dir_path, fname },
                            0,
                        ),
                    },
                });
            }
        }

        return try Self.create(ctx, images.items, width, height, .{
            .gap = opt.gap,
            .keep_packed_pixels = opt.keep_packed_pixels,
        });
    } else if (!builtin.cpu.arch.isWasm()) {
        var dir = try std.fs.cwd().openDir(std.mem.sliceTo(dir_path, 0), .{ .iterate = true });
        defer dir.close();

        // Collect pictures
        const dpath = std.mem.sliceTo(dir_path, 0);
        var it = dir.iterate();
        while (try it.next()) |p| {
            if (p.kind != .file) continue;

            const fname = std.mem.sliceTo(p.name, 0);
            if (fname.len < 5) continue;
            if ((opt.accept_png and std.mem.eql(u8, ".png", fname[fname.len - 4 ..])) or
                (opt.accept_jpg and std.mem.eql(u8, ".jpg", fname[fname.len - 4 ..])))
            {
                try images.append(.{
                    .name = try std.fmt.allocPrint(
                        arena.allocator(),
                        "{s}",
                        .{fname[0 .. fname.len - 4]},
                    ),
                    .image = .{
                        .file_path = try std.fs.path.joinZ(arena.allocator(), &[_][]const u8{
                            dpath,
                            fname,
                        }),
                    },
                });
            }
        }

        return try Self.create(ctx, images.items, width, height, .{
            .gap = opt.gap,
            .keep_packed_pixels = opt.keep_packed_pixels,
        });
    }
    return error.Unimplemented;
}

/// Create a very raw sheet with a single picture, initialize name tree if possible
pub const SpriteInfo = struct {
    name: []const u8,
    rect: jok.Rectangle,
};
pub fn fromSinglePicture(
    ctx: jok.Context,
    path: [*:0]const u8,
    sprites: []const SpriteInfo,
) !*Self {
    var tex = try ctx.renderer().createTextureFromFile(
        ctx.allocator(),
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
        rects[i] = SpriteRect{
            .width = @min(sp.rect.width, tex_width - sp.rect.x),
            .height = @min(sp.rect.height, tex_height - sp.rect.y),
            .s0 = sp.rect.x / tex_width,
            .t0 = sp.rect.y / tex_height,
            .s1 = @min(1.0, (sp.rect.x + sp.rect.width) / tex_width),
            .t1 = @min(1.0, (sp.rect.y + sp.rect.height) / tex_height),
        };
        try tree.putNoClobber(
            try std.fmt.allocPrint(allocator, "{s}", .{sp.name}),
            @intCast(i),
        );
    }

    const self = try allocator.create(Self);
    self.* = .{
        .allocator = allocator,
        .size = .{ .width = info.width, .height = info.height },
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

/// Save sprite-sheet to jpng
pub fn save(
    self: Self,
    ctx: jok.Context,
    path: [*:0]const u8,
    opt: jok.utils.gfx.jpng.SaveOption,
) !void {
    if (self.packed_pixels == null) return error.NoPixelData;
    var arena = std.heap.ArenaAllocator.init(self.allocator);
    defer arena.deinit();
    const databuf = try arena.allocator().alloc(u8, max_sheet_data_size);
    var bufstream = std.io.fixedBufferStream(databuf);

    // Magic header
    try bufstream.writer().writeAll(&magic_sheet_header);

    // Serialize sheet info
    var json_root = json.Value{
        .object = json.ObjectMap.init(arena.allocator()),
    };
    var it = self.search_tree.iterator();
    while (it.next()) |entry| {
        const name = entry.key_ptr.*;
        const rect = self.rects[entry.value_ptr.*];
        var obj = json.ObjectMap.init(arena.allocator());
        try obj.put("s0", json.Value{ .float = @as(f64, rect.s0) });
        try obj.put("t0", json.Value{ .float = @as(f64, rect.t0) });
        try obj.put("s1", json.Value{ .float = @as(f64, rect.s1) });
        try obj.put("t1", json.Value{ .float = @as(f64, rect.t1) });
        try obj.put("w", json.Value{ .float = @as(f64, rect.width) });
        try obj.put("h", json.Value{ .float = @as(f64, rect.height) });
        try json_root.object.put(name, json.Value{ .object = obj });
    }
    var adapter = bufstream.writer().adaptToNewApi();
    var stream = json.Stringify{
        .writer = &adapter.new_interface,
        .options = .{},
    };
    try json_root.jsonStringify(&stream);

    // Save to disk
    try jok.utils.gfx.jpng.save(
        ctx,
        self.packed_pixels.?.data,
        self.packed_pixels.?.width,
        self.packed_pixels.?.height,
        path,
        bufstream.getWritten(),
        opt,
    );
}

/// Load sprite-sheet from jpng
pub fn load(ctx: jok.Context, path: [*:0]const u8) !*Self {
    const S = struct {
        inline fn getFloat(v: json.Value) f32 {
            return switch (v) {
                .integer => |i| @floatFromInt(i),
                .float => |f| @floatCast(f),
                else => unreachable,
            };
        }
    };

    const loaded = try jok.utils.gfx.jpng.loadTexture(ctx, path, .static, false);
    defer ctx.allocator().free(loaded.data);
    errdefer loaded.tex.destroy();
    if (loaded.data.len < magic_sheet_header.len + 2 or
        !std.mem.eql(u8, &magic_sheet_header, loaded.data[0..magic_sheet_header.len]))
    {
        return error.InvalidFormat;
    }

    // Load sprites info
    const allocator = ctx.allocator();
    var parsed = try json.parseFromSlice(
        json.Value,
        allocator,
        loaded.data[magic_sheet_header.len..],
        .{},
    );
    defer parsed.deinit();
    if (parsed.value != .object) {
        return error.InvalidFormat;
    }
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
            .s0 = S.getFloat(info.get("s0").?),
            .t0 = S.getFloat(info.get("t0").?),
            .s1 = S.getFloat(info.get("s1").?),
            .t1 = S.getFloat(info.get("t1").?),
            .width = S.getFloat(info.get("w").?),
            .height = S.getFloat(info.get("h").?),
        };
        try search_tree.putNoClobber(
            try std.fmt.allocPrint(allocator, "{s}", .{name}),
            i,
        );
    }

    // Allocate and init SpriteSheet
    const info = try loaded.tex.query();
    const ss = try allocator.create(Self);
    ss.* = Self{
        .allocator = allocator,
        .size = .{ .width = info.width, .height = info.height },
        .tex = loaded.tex,
        .rects = rects,
        .search_tree = search_tree,
    };
    return ss;
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
pub fn getSpriteByRectangle(self: *Self, rect: jok.Rectangle) Sprite {
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
