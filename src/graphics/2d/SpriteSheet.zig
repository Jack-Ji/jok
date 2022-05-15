const std = @import("std");
const assert = std.debug.assert;
const json = std.json;
const native_endian = @import("builtin").target.cpu.arch.endian();
const sdl = @import("sdl");
const Sprite = @import("Sprite.zig");
const jok = @import("../../jok.zig");
const gfx = jok.gfx;
const stb_rect_pack = jok.deps.stb.rect_pack;
const stb_image = jok.deps.stb.image;
const Self = @This();

pub const Error = error{
    TextureNotLargeEnough,
    SpriteNotExist,
    InvalidJson,
    NoTextureData,
};

/// image pixels
pub const ImagePixels = struct {
    data: []const u8,
    width: u32,
    height: u32,
    format: sdl.Texture.Format,
};

/// image data source
pub const ImageSource = struct {
    name: []const u8,
    image: union(enum) {
        file_path: []const u8,
        pixels: ImagePixels,
    },
};

/// sprite rectangle
pub const SpriteRect = struct {
    // texture coordinate of top-left
    s0: f32,
    t0: f32,

    // texture coordinate of bottom-right
    s1: f32,
    t1: f32,

    // size of sprite
    width: f32,
    height: f32,
};

/// used allocator
allocator: std.mem.Allocator,

/// packed pixels
packed_pixels: ?ImagePixels = null,

/// packed texture
tex: sdl.Texture,

/// sprite rectangles
rects: []SpriteRect,

/// sprite search-tree
search_tree: std.StringHashMap(u32),

/// create sprite-sheet
pub fn init(
    allocator: std.mem.Allocator,
    renderer: sdl.Renderer,
    sources: []const ImageSource,
    width: u32,
    height: u32,
    keep_packed_pixels: bool,
) !*Self {
    assert(sources.len > 0);
    const ImageData = struct {
        is_file: bool,
        pixels: ImagePixels,
    };

    var pixels = try allocator.alloc(u8, width * height * 4);
    errdefer allocator.free(pixels);

    var tree = std.StringHashMap(u32).init(allocator);
    var rects = try allocator.alloc(SpriteRect, sources.len);
    errdefer allocator.free(rects);

    var stb_rects = try allocator.alloc(stb_rect_pack.stbrp_rect, sources.len);
    defer allocator.free(stb_rects);

    var stb_nodes = try allocator.alloc(stb_rect_pack.stbrp_node, width);
    defer allocator.free(stb_nodes);

    var images = try allocator.alloc(ImageData, sources.len);
    defer allocator.free(images);

    // load images' data
    for (sources) |s, i| {
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
                    4, // alpha channel is required
                );
                assert(image_data != null);
                var image_len = image_width * image_height * 4;
                images[i] = .{
                    .is_file = false,
                    .pixels = .{
                        .data = image_data[0..@intCast(usize, image_len)],
                        .width = @intCast(u32, image_width),
                        .height = @intCast(u32, image_height),
                        .format = gfx.utils.getFormatByEndian(),
                    },
                };
            },
            .pixels => |ps| {
                assert(ps.data.len > 0 and ps.width > 0 and ps.height > 0);
                const channels = gfx.utils.getChannels(ps.format);
                assert(channels == 4);
                assert(ps.data.len == ps.width * ps.height * channels);
                images[i] = .{
                    .is_file = false,
                    .pixels = ps,
                };
            },
        }
        stb_rects[i] = std.mem.zeroes(stb_rect_pack.stbrp_rect);
        stb_rects[i].id = @intCast(c_int, i);
        stb_rects[i].w = @intCast(c_ushort, images[i].pixels.width);
        stb_rects[i].h = @intCast(c_ushort, images[i].pixels.height);
    }
    defer {
        // free file-images' data when we're done
        for (images) |img| {
            if (img.is_file) {
                stb_image.stbi_image_free(img.pixels.data.ptr);
            }
        }
    }

    // start packing images
    var pack_ctx: stb_rect_pack.stbrp_context = undefined;
    stb_rect_pack.stbrp_init_target(
        &pack_ctx,
        @intCast(c_int, width),
        @intCast(c_int, height),
        stb_nodes.ptr,
        @intCast(c_int, stb_nodes.len),
    );
    const rc = stb_rect_pack.stbrp_pack_rects(
        &pack_ctx,
        stb_rects.ptr,
        @intCast(c_int, stb_rects.len),
    );
    if (rc == 0) {
        return error.TextureNotLargeEnough;
    }

    // merge textures and upload to gpu
    const inv_width = 1.0 / @intToFloat(f32, width);
    const inv_height = 1.0 / @intToFloat(f32, height);
    for (stb_rects) |r, i| {
        rects[i] = .{
            .s0 = @intToFloat(f32, r.x) * inv_width,
            .t0 = @intToFloat(f32, r.y) * inv_height,
            .s1 = @intToFloat(f32, r.x + r.w) * inv_width,
            .t1 = @intToFloat(f32, r.y + r.h) * inv_height,
            .width = @intToFloat(f32, r.w),
            .height = @intToFloat(f32, r.h),
        };
        const y_begin: u32 = @intCast(u32, r.y);
        const y_end: u32 = @intCast(u32, r.y + r.h);
        const src_pixels = images[i].pixels;
        const dst_stride: u32 = width * 4;
        const src_stride: u32 = src_pixels.width * 4;
        var y: u32 = y_begin;
        while (y < y_end) : (y += 1) {
            const dst_offset: u32 = y * dst_stride + @intCast(u32, r.x) * 4;
            const src_offset: u32 = (y - y_begin) * src_stride;
            std.mem.copy(
                u8,
                pixels[dst_offset .. dst_offset + src_stride],
                src_pixels.data[src_offset .. src_offset + src_stride],
            );
        }
    }
    var tex = try gfx.utils.createTextureFromPixels(
        renderer,
        pixels,
        gfx.utils.getFormatByEndian(),
        .static,
        width,
        height,
    );
    try tex.setScaleMode(.nearest);
    errdefer tex.destroy();

    // fill search tree, abort if name collision happens
    for (sources) |s, i| {
        try tree.putNoClobber(
            try std.fmt.allocPrint(allocator, "{s}", .{s.name}),
            @intCast(u32, i),
        );
    }

    var self = try allocator.create(Self);
    self.* = .{
        .allocator = allocator,
        .packed_pixels = if (keep_packed_pixels) ImagePixels{
            .width = width,
            .height = height,
            .data = pixels,
            .format = gfx.utils.getFormatByEndian(),
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

/// create sprite-sheet with all picture files in given directory
pub const DirScanOption = struct {
    accept_png: bool = true,
    accept_jpg: bool = true,
};
pub fn fromPicturesInDir(
    allocator: std.mem.Allocator,
    renderer: sdl.Renderer,
    dir_path: []const u8,
    width: u32,
    height: u32,
    keep_packed_pixels: bool,
    opt: DirScanOption,
) !*Self {
    var curdir = std.fs.cwd();
    var dir = try curdir.openDir(dir_path, .{ .iterate = true, .no_follow = true });
    defer dir.close();

    var images = try std.ArrayList(ImageSource).initCapacity(allocator, 10);
    defer images.deinit();

    // collect pictures
    var it = dir.iterate();
    while (try it.next()) |entry| {
        if (entry.kind != .File) continue;
        if (entry.name.len < 5) continue;
        if ((opt.accept_png and std.mem.eql(u8, ".png", entry.name[entry.name.len - 4 ..])) or
            (opt.accept_jpg and std.mem.eql(u8, ".jpg", entry.name[entry.name.len - 4 ..])))
        {
            try images.append(.{
                .name = try std.fmt.allocPrint(
                    allocator,
                    "{s}",
                    .{entry.name[0 .. entry.name.len - 4]},
                ),
                .image = .{
                    .file_path = try std.fs.path.joinZ(allocator, &[_][]const u8{
                        dir_path,
                        entry.name,
                    }),
                },
            });
        }
    }
    defer {
        for (images.items) |img| {
            allocator.free(img.name);
            allocator.free(img.image.file_path);
        }
    }

    return try Self.init(allocator, renderer, images.items, width, height, keep_packed_pixels);
}

pub fn fromSheetFiles(allocator: std.mem.Allocator, renderer: sdl.Renderer, path: []const u8) !*Self {
    var path_buf: [128]u8 = undefined;

    // load texture
    const image_path = try std.fmt.bufPrintZ(&path_buf, "{s}.png", .{path});
    var tex = try gfx.utils.createTextureFromFile(
        renderer,
        image_path,
        .static,
        false,
    );
    try tex.setScaleMode(.nearest);
    errdefer tex.deinit();

    // load sprites info
    const json_path = try std.fmt.bufPrint(&path_buf, "{s}.json", .{path});
    var json_content = try std.fs.cwd().readFileAlloc(allocator, json_path, 1 << 30);
    defer allocator.free(json_content);
    var parser = json.Parser.init(allocator, false);
    defer parser.deinit();
    var json_tree = try parser.parse(json_content);
    defer json_tree.deinit();
    if (json_tree.root != .Object) return error.InvalidJson;
    const rect_count = json_tree.root.Object.count();
    assert(rect_count > 0);
    var rects = try allocator.alloc(SpriteRect, rect_count);
    errdefer allocator.free(rects);
    var search_tree = std.StringHashMap(u32).init(allocator);
    errdefer search_tree.deinit();
    var it = json_tree.root.Object.iterator();
    var i: u32 = 0;
    while (it.next()) |entry| : (i += 1) {
        const name = entry.key_ptr.*;
        const info = entry.value_ptr.*.Object;
        rects[i] = SpriteRect{
            .s0 = @floatCast(f32, info.get("s0").?.Float),
            .t0 = @floatCast(f32, info.get("t0").?.Float),
            .s1 = @floatCast(f32, info.get("s1").?.Float),
            .t1 = @floatCast(f32, info.get("t1").?.Float),
            .width = @floatCast(f32, info.get("width").?.Float),
            .height = @floatCast(f32, info.get("height").?.Float),
        };
        try search_tree.putNoClobber(
            try std.fmt.allocPrint(allocator, "{s}", .{name}),
            i,
        );
    }

    // allocate and init SpriteSheet
    var sp = try allocator.create(Self);
    sp.* = Self{
        .allocator = allocator,
        .tex = tex,
        .rects = rects,
        .search_tree = search_tree,
    };
    return sp;
}

/// destroy sprite-sheet
pub fn deinit(self: *Self) void {
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

/// save sprite-sheet to 2 files (image and json)
pub fn saveToFiles(self: Self, path: []const u8) !void {
    if (self.packed_pixels == null) return error.NoTextureData;
    var path_buf: [128]u8 = undefined;

    // save image file
    const image_path = try std.fmt.bufPrintZ(&path_buf, "{s}.png", .{path});
    try gfx.utils.savePixelsToFile(
        self.packed_pixels.?.data,
        self.packed_pixels.?.width,
        self.packed_pixels.?.height,
        self.packed_pixels.?.format,
        image_path,
        .{ .format = .png },
    );

    // save json file
    const json_path = try std.fmt.bufPrint(&path_buf, "{s}.json", .{path});
    var json_file = try std.fs.cwd().createFile(json_path, .{});
    defer json_file.close();
    var arena_allocator = std.heap.ArenaAllocator.init(self.allocator);
    var json_tree = json.ValueTree{
        .arena = arena_allocator,
        .root = json.Value{
            .Object = json.ObjectMap.init(arena_allocator.allocator()),
        },
    };
    defer json_tree.deinit();
    var it = self.search_tree.iterator();
    while (it.next()) |entry| {
        const name = entry.key_ptr.*;
        const rect = self.rects[entry.value_ptr.*];
        var obj = json.ObjectMap.init(arena_allocator.allocator());
        try obj.put("s0", json.Value{ .Float = @as(f64, rect.s0) });
        try obj.put("t0", json.Value{ .Float = @as(f64, rect.t0) });
        try obj.put("s1", json.Value{ .Float = @as(f64, rect.s1) });
        try obj.put("t1", json.Value{ .Float = @as(f64, rect.t1) });
        try obj.put("width", json.Value{ .Float = @as(f64, rect.width) });
        try obj.put("height", json.Value{ .Float = @as(f64, rect.height) });
        try json_tree.root.Object.put(name, json.Value{ .Object = obj });
    }
    try json_tree.root.jsonStringify(
        .{ .whitespace = json.StringifyOptions.Whitespace{} },
        json_file.writer(),
    );
}

/// create sprite
pub fn createSprite(
    self: *Self,
    name: []const u8,
) !Sprite {
    if (self.getSpriteRect(name)) |rect| {
        return Sprite{
            .width = rect.width,
            .height = rect.height,
            .uv0 = .{ .x = rect.s0, .y = rect.t0 },
            .uv1 = .{ .x = rect.s1, .y = rect.t1 },
            .sheet = self,
        };
    }
    return error.SpriteNotExist;
}

/// get sprite rectangle by name
pub fn getSpriteRect(self: Self, name: []const u8) ?SpriteRect {
    if (self.search_tree.get(name)) |idx| {
        return self.rects[idx];
    }
    return null;
}
