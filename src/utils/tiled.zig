/// Tiled Editor
/// https://doc.mapeditor.org/en/stable/reference/tmx-map-format/
const std = @import("std");
const assert = std.debug.assert;
const xml = @import("xml.zig");
const jok = @import("../jok.zig");
const j2d = jok.j2d;
const physfs = jok.physfs;
const log = std.log.scoped(.jok);

pub const Error = error{
    UnsupportedOrientation,
    UnsupportedTileRenderSize,
    UnsupportedTilesetType,
    UnsupportedImageData,
    FailedToGetImageData,
    UnsupportedTileMargin,
    UnsupportedLayerType,
    UnsupportedLayerEncoding,
    UnsupportedLayerCompression,
    UnsupportedPropertyType,
};

pub const Orientation = enum {
    orthogonal,
    isometric, // TODO
};

pub const RenderOrder = enum {
    right_down,
    right_up,
    left_down,
    left_up,
};

pub const PropertyValue = union(enum) {
    none: void,
    string: []const u8,
    int: i32,
    float: f32,
    boolean: bool,
    color: jok.Color,
};
pub const PropertyTree = std.StringHashMap(PropertyValue);

pub const Tile = struct {
    id: u32,
    uv0: jok.Point,
    uv1: jok.Point,
    props: PropertyTree,
};

pub const Tileset = struct {
    first_gid: u32,
    tile_size: jok.Size,
    spacing: u32,
    columns: u32,
    tiles: []Tile,
    texture: jok.Texture,
    props: PropertyTree,

    fn deinit(self: Tileset) void {
        self.texture.destroy();
    }

    pub fn getTile(self: Tileset, gid: GlobalTileID) Tile {
        assert(gid.id() >= self.first_gid);
        const id = gid.id() - self.first_gid;
        assert(id < self.tiles.len);
        return self.tiles[id];
    }
};

const GlobalTileID = struct {
    const flip_horizontal = 0x80000000;
    const flip_vertial = 0x40000000;
    const flip_diagonally = 0x20000000;

    _id: u32,

    fn id(self: GlobalTileID) u32 {
        return self._id & 0x0fffffff;
    }

    fn flipH(self: GlobalTileID) bool {
        return (self._id & flip_horizontal) != 0;
    }

    fn flipV(self: GlobalTileID) bool {
        return (self._id & flip_vertial) != 0;
    }

    fn flipD(self: GlobalTileID) bool {
        return (self._id & flip_diagonally) != 0;
    }
};

const Chunk = struct {
    x: i32,
    y: i32,
    width: u32,
    height: u32,
    gids: []GlobalTileID,

    const RenderSprite = struct {
        sprite: j2d.Sprite,
        pos: jok.Point,
        tint_color: jok.Color,
        flip_h: bool,
        flip_v: bool,
    };
    const Iterator = struct {
        map: *const TiledMap,
        layer: *const TileLayer,
        order: RenderOrder,
        gids: []GlobalTileID,
        rect: jok.Rectangle,
        idx: ?usize,

        fn next(it: *Iterator) ?RenderSprite {
            while (true) {
                if (it.idx) |i| {
                    defer it.idx = it.nextIdx();

                    const gid = it.gids[i];
                    if (gid._id == 0) continue;

                    const tileset = it.map.getTileset(gid);
                    const tile = tileset.getTile(gid);
                    const x_in_rect: f32 = @floatFromInt(i % @as(u32, @intFromFloat(it.rect.width)));
                    const y_in_rect: f32 = @floatFromInt(i / @as(u32, @intFromFloat(it.rect.width)));
                    const pos_in_layer = jok.Point{
                        .x = (it.rect.x + x_in_rect) * @as(f32, @floatFromInt(it.map.tile_size.width)),
                        .y = (it.rect.y + y_in_rect) * @as(f32, @floatFromInt(it.map.tile_size.height)),
                    };
                    return .{
                        .sprite = .{
                            .width = @as(f32, @floatFromInt(it.map.tile_size.width)),
                            .height = @as(f32, @floatFromInt(it.map.tile_size.height)),
                            .uv0 = tile.uv0,
                            .uv1 = tile.uv1,
                            .tex = tileset.texture,
                        },
                        .pos = pos_in_layer.add(it.layer.offset),
                        .tint_color = it.layer.tint_color,
                        .flip_h = gid.flipH(),
                        .flip_v = gid.flipV(),
                    };
                }
                return null;
            }
        }

        fn nextIdx(it: *const Iterator) ?usize {
            if (it.idx) |i| {
                const rect_w = @as(u32, @intFromFloat(it.rect.width));
                const rect_h = @as(u32, @intFromFloat(it.rect.height));
                var x_in_rect = @as(u32, @intCast(i)) % rect_w;
                var y_in_rect = @as(u32, @intCast(i)) / rect_w;
                switch (it.order) {
                    .right_down => {
                        if (x_in_rect > 0) {
                            x_in_rect -= 1;
                        } else if (y_in_rect == rect_h - 1) {
                            return null;
                        } else {
                            x_in_rect = rect_w - 1;
                            y_in_rect += 1;
                        }
                    },
                    .right_up => {
                        if (x_in_rect > 0) {
                            x_in_rect -= 1;
                        } else if (y_in_rect == 0) {
                            return null;
                        } else {
                            x_in_rect = rect_w - 1;
                            y_in_rect -= 1;
                        }
                    },
                    .left_down => {
                        if (x_in_rect < rect_w - 1) {
                            x_in_rect += 1;
                        } else if (y_in_rect == rect_h - 1) {
                            return null;
                        } else {
                            x_in_rect = 0;
                            y_in_rect += 1;
                        }
                    },
                    .left_up => {
                        if (x_in_rect < rect_w - 1) {
                            x_in_rect += 1;
                        } else if (y_in_rect == 0) {
                            return null;
                        } else {
                            x_in_rect = 0;
                            y_in_rect -= 1;
                        }
                    },
                }
                return x_in_rect + y_in_rect * @as(u32, @intFromFloat(it.rect.width));
            }
            return null;
        }
    };

    fn getSpriteIterator(c: Chunk, map: *const TiledMap, layer: *const TileLayer) Iterator {
        return .{
            .map = map,
            .layer = layer,
            .order = map.order,
            .gids = c.gids,
            .rect = .{
                .x = @floatFromInt(c.x),
                .y = @floatFromInt(c.y),
                .width = @floatFromInt(c.width),
                .height = @floatFromInt(c.height),
            },
            .idx = switch (map.order) {
                .right_down => c.width - 1,
                .right_up => c.gids.len - 1,
                .left_down => 0,
                .left_up => c.gids.len - c.width,
            },
        };
    }
};

const TileLayer = struct {
    size: jok.Size,
    offset: jok.Point,
    parallax: jok.Point,
    tint_color: jok.Color,
    chunks: []Chunk,
    props: PropertyTree,

    fn render(self: TileLayer, map: TiledMap, b: *j2d.Batch) !void {
        assert(map.orientation == .orthogonal);
        for (self.chunks) |c| {
            var it = c.getSpriteIterator(&map, &self);
            while (it.next()) |rs| {
                try b.sprite(rs.sprite, .{
                    .pos = rs.pos,
                    .tint_color = rs.tint_color,
                    .flip_h = rs.flip_h,
                    .flip_v = rs.flip_v,
                });
            }
        }
    }
};

const ObjectGroup = struct {
    offset: jok.Point,
    parallax: jok.Point,
    tint_color: jok.Color,
    props: PropertyTree,

    fn render(self: ObjectGroup, map: TiledMap, b: *j2d.Batch) !void {
        assert(map.orientation == .orthogonal);
        _ = self;
        _ = b;
        // TODO
        return error.UnsupportedLayerType;
    }
};

const ImageLayer = struct {
    offset: jok.Point,
    parallax: jok.Point,
    tint_color: jok.Color,
    props: PropertyTree,

    fn render(self: ImageLayer, map: TiledMap, b: *j2d.Batch) !void {
        assert(map.orientation == .orthogonal);
        _ = self;
        _ = b;
        // TODO
        return error.UnsupportedLayerType;
    }
};

pub const Layer = union(enum) {
    tile_layer: TileLayer,
    object_layer: ObjectGroup,
    image_layer: ImageLayer,

    pub fn render(self: Layer, map: TiledMap, b: *j2d.Batch) !void {
        switch (self) {
            .tile_layer => |l| try l.render(map, b),
            .object_layer => |l| try l.render(map, b),
            .image_layer => |l| try l.render(map, b),
        }
    }

    pub fn getParallax(self: Layer) jok.Point {
        return switch (self) {
            .tile_layer => |l| l.parallax,
            .object_layer => |l| l.parallax,
            .image_layer => |l| l.parallax,
        };
    }

    pub fn getProperty(self: Layer, name: []const u8) ?PropertyValue {
        return switch (self) {
            .tile_layer => |l| try l.props.get(name),
            .object_layer => |l| try l.props.get(name),
            .image_layer => |l| try l.props.get(name),
        };
    }
};

pub const TiledMap = struct {
    arena: std.heap.ArenaAllocator,
    orientation: Orientation,
    order: RenderOrder,
    map_size: jok.Size,
    tile_size: jok.Size,
    infinite: bool,
    parallax_origin: jok.Point,
    bgcolor: jok.Color = jok.Color.none,
    tilesets: []Tileset,
    layers: []Layer,
    props: PropertyTree,

    pub fn deinit(self: TiledMap) void {
        for (self.tilesets) |t| t.deinit();
        self.arena.deinit();
    }

    pub fn getTileset(self: TiledMap, gid: GlobalTileID) Tileset {
        const id = gid.id();
        for (self.tilesets) |t| {
            if (id < t.first_gid + @as(u32, @intCast(t.tiles.len))) {
                return t;
            }
        }
        unreachable;
    }
};

/// Load TMX file
pub fn loadTMX(ctx: jok.Context, path: [*:0]const u8) !TiledMap {
    const zpath = std.mem.sliceTo(path, 0);
    assert(std.mem.endsWith(u8, zpath, ".tmx"));
    const allocator = ctx.allocator();
    var tmap: TiledMap = .{
        .arena = std.heap.ArenaAllocator.init(allocator),
        .orientation = .orthogonal,
        .order = .right_down,
        .map_size = undefined,
        .tile_size = undefined,
        .infinite = false,
        .parallax_origin = .{ .x = 0, .y = 0 },
        .bgcolor = jok.Color.none,
        .tilesets = &.{},
        .layers = &.{},
        .props = undefined,
    };
    tmap.props = PropertyTree.init(tmap.arena.allocator());
    errdefer tmap.deinit();

    var data: []const u8 = undefined;
    var dirname: []const u8 = undefined;
    if (ctx.cfg().jok_enable_physfs) {
        const handle = try physfs.open(path, .read);
        defer handle.close();

        data = try handle.readAllAlloc(allocator);
        dirname = if (std.mem.lastIndexOfScalar(u8, zpath, '/')) |idx|
            zpath[0..idx]
        else
            "";
    } else {
        const file = try std.fs.cwd().openFileZ(path, .{ .mode = .read_only });
        defer file.close();

        data = try file.readToEndAlloc(allocator, 1 << 30);
        dirname = std.fs.path.dirname(zpath) orelse ".";
    }
    defer allocator.free(data);

    const doc = try xml.parse(allocator, data);
    defer doc.deinit();
    const map = doc.root;
    assert(std.mem.eql(u8, map.tag, "map"));

    // Load map attributes
    for (map.attributes) |a| {
        if (std.mem.eql(u8, a.name, "orientation")) {
            tmap.orientation = if (std.mem.eql(u8, a.value, "orthogonal"))
                .orthogonal
            else {
                log.err("Load map failed, doesn't support `{s}` orientation.\n", .{a.value});
                return error.UnsupportedOrientation;
            };
            continue;
        }

        if (std.mem.eql(u8, a.name, "renderorder")) {
            tmap.order = if (std.mem.eql(u8, a.value, "right-down"))
                .right_down
            else if (std.mem.eql(u8, a.value, "left-down"))
                .left_down
            else if (std.mem.eql(u8, a.value, "right-up"))
                .right_up
            else if (std.mem.eql(u8, a.value, "left-up"))
                .left_up
            else
                unreachable;
            continue;
        }

        if (std.mem.eql(u8, a.name, "width")) {
            tmap.map_size.width = try std.fmt.parseInt(u32, a.value, 10);
            continue;
        }
        if (std.mem.eql(u8, a.name, "height")) {
            tmap.map_size.height = try std.fmt.parseInt(u32, a.value, 10);
            continue;
        }
        if (std.mem.eql(u8, a.name, "tilewidth")) {
            tmap.tile_size.width = try std.fmt.parseInt(u32, a.value, 10);
            continue;
        }
        if (std.mem.eql(u8, a.name, "tileheight")) {
            tmap.tile_size.height = try std.fmt.parseInt(u32, a.value, 10);
            continue;
        }
        if (std.mem.eql(u8, a.name, "infinite")) {
            tmap.infinite = if (a.value[0] == '1') true else false;
            continue;
        }
        if (std.mem.eql(u8, a.name, "parallaxoriginx")) {
            tmap.parallax_origin.x = try std.fmt.parseFloat(f32, a.value);
            continue;
        }
        if (std.mem.eql(u8, a.name, "parallaxoriginy")) {
            tmap.parallax_origin.y = try std.fmt.parseFloat(f32, a.value);
            continue;
        }
        if (std.mem.eql(u8, a.name, "backgroundcolor")) {
            tmap.bgcolor = try parseColor(a.value);
            continue;
        }
    }

    // Load tileset(s)
    tmap.tilesets = try loadTilesets(
        ctx.renderer(),
        allocator,
        tmap.arena.allocator(),
        map,
        ctx.cfg().jok_enable_physfs,
        dirname,
    );

    // Load layers
    tmap.layers = try loadLayers(
        allocator,
        tmap.arena.allocator(),
        map,
    );

    // Init map's properties
    try initPropertyTree(map, tmap.arena.allocator(), &tmap.props);

    return tmap;
}

fn loadTilesets(
    rd: jok.Renderer,
    temp_allocator: std.mem.Allocator,
    arena_allocator: std.mem.Allocator,
    map: *const xml.Element,
    use_physfs: bool,
    dirname: []const u8,
) ![]Tileset {
    var it1 = map.iterator();
    var tileset_count: usize = 0;
    while (it1.next()) |e| {
        if (e.* == .element and std.mem.eql(u8, e.element.tag, "tileset")) {
            tileset_count += 1;
        }
    }
    assert(tileset_count > 0);

    const ts = try arena_allocator.alloc(Tileset, tileset_count);
    for (ts) |*t| {
        t.* = .{
            .first_gid = 0,
            .tile_size = .{ .width = 0, .height = 0 },
            .spacing = 0,
            .columns = 0,
            .tiles = &.{},
            .texture = undefined,
            .props = PropertyTree.init(arena_allocator),
        };
    }
    var tsidx: usize = 0;
    errdefer for (0..tsidx) |i| ts[i].deinit();

    var it2 = map.findChildrenByTag("tileset");
    while (it2.next()) |e1| : (tsidx += 1) {
        var external_doc: ?xml.Document = null;
        defer if (external_doc) |doc| doc.deinit();

        // Load attributes
        var tileset = e1;
        PARSE_TILESET: while (true) {
            for (tileset.attributes) |a| {
                if (std.mem.eql(u8, a.name, "firstgid")) {
                    ts[tsidx].first_gid = try std.fmt.parseInt(u32, a.value, 10);
                    assert(if (tsidx == 0) ts[tsidx].first_gid == 1 else ts[tsidx].first_gid > ts[tsidx - 1].first_gid);
                    continue;
                }
                if (std.mem.eql(u8, a.name, "source")) {
                    const tsx_content = try getExternalFileContent(
                        temp_allocator,
                        use_physfs,
                        dirname,
                        a.value,
                    );
                    defer temp_allocator.free(tsx_content);

                    external_doc = try xml.parse(temp_allocator, tsx_content);
                    tileset = external_doc.?.root;
                    assert(std.mem.eql(u8, tileset.tag, "tileset"));
                    continue :PARSE_TILESET;
                }
            }
            break;
        }
        for (tileset.attributes) |a| {
            if (std.mem.eql(u8, a.name, "tilewidth")) {
                ts[tsidx].tile_size.width = try std.fmt.parseInt(u32, a.value, 10);
                continue;
            }
            if (std.mem.eql(u8, a.name, "tileheight")) {
                ts[tsidx].tile_size.height = try std.fmt.parseInt(u32, a.value, 10);
                continue;
            }

            if (std.mem.eql(u8, a.name, "spacing")) {
                ts[tsidx].spacing = try std.fmt.parseInt(u32, a.value, 10);
                continue;
            }
            if (std.mem.eql(u8, a.name, "margin")) {
                if (try std.fmt.parseInt(u32, a.value, 10) != 0) {
                    return error.UnsupportedTileMargin;
                }
                continue;
            }
            if (std.mem.eql(u8, a.name, "columns")) {
                ts[tsidx].columns = try std.fmt.parseInt(u32, a.value, 10);
                continue;
            }

            if (std.mem.eql(u8, a.name, "tilecount")) {
                const count = try std.fmt.parseInt(u32, a.value, 10);
                ts[tsidx].tiles = try arena_allocator.alloc(Tile, count);
                continue;
            }

            if (std.mem.eql(u8, a.name, "tilerendersize")) {
                if (!std.mem.eql(u8, a.value, "tile")) {
                    return error.UnsupportedTileRenderSize;
                }
                continue;
            }
        }

        // Init tileset's properties
        try initPropertyTree(tileset, arena_allocator, &ts[tsidx].props);

        // Get texture, only accept single sheet
        if (tileset.findChildByTag("image")) |img| {
            if (img.findChildByTag("data") != null) return error.UnsupportedImageData;
            for (img.attributes) |a| {
                if (std.mem.eql(u8, a.name, "source")) {
                    const image_content = try getExternalFileContent(
                        temp_allocator,
                        use_physfs,
                        dirname,
                        a.value,
                    );
                    defer temp_allocator.free(image_content);
                    ts[tsidx].texture = try rd.createTextureFromFileData(image_content, .static, false);
                    break;
                }
            } else {
                return error.FailedToGetImageData;
            }
        } else {
            return error.UnsupportedTilesetType;
        }

        // Init tiles
        assert(ts[tsidx].first_gid > 0);
        assert(ts[tsidx].tile_size.width > 0 and ts[tsidx].tile_size.height > 0);
        assert(ts[tsidx].columns > 0);
        assert(ts[tsidx].tiles.len > 0);
        const cell_width = ts[tsidx].tile_size.width + ts[tsidx].spacing;
        const cell_height = ts[tsidx].tile_size.height + ts[tsidx].spacing;
        const texinfo = try ts[tsidx].texture.query();
        const texwidth = @as(f32, @floatFromInt(texinfo.width));
        const texheight = @as(f32, @floatFromInt(texinfo.height));
        for (ts[tsidx].tiles, 0..) |*t, idx| {
            const x: f32 = @floatFromInt(idx % ts[tsidx].columns * cell_width);
            const y: f32 = @floatFromInt(idx / ts[tsidx].columns * cell_height);
            t.id = @intCast(idx);
            t.uv0 = .{
                .x = x / texwidth,
                .y = y / texheight,
            };
            t.uv1 = .{
                .x = (x + ts[tsidx].tile_size.getWidthFloat()) / texwidth,
                .y = (y + ts[tsidx].tile_size.getHeightFloat()) / texheight,
            };
            t.props = PropertyTree.init(arena_allocator);
        }

        // Get tiles' properties
        var it3 = tileset.findChildrenByTag("tile");
        while (it3.next()) |e2| {
            var id: u32 = undefined;
            for (e2.attributes) |a| {
                if (std.mem.eql(u8, a.name, "id")) {
                    id = try std.fmt.parseInt(u32, a.value, 10);
                    assert(id > 0);
                    break;
                }
            }
            assert(id > 0);
            try initPropertyTree(e2, arena_allocator, &ts[tsidx].tiles[id - 1].props);
        }
    }

    assert(tsidx == tileset_count);
    return ts;
}

fn loadLayers(temp_allocator: std.mem.Allocator, arena_allocator: std.mem.Allocator, map: *const xml.Element) ![]Layer {
    const Grouping = struct {
        const Self = @This();
        const Group = struct {
            it: xml.Element.ChildElementIterator,
            offset: jok.Point = .{ .x = 0, .y = 0 },
            parallax: jok.Point = .{ .x = 1, .y = 1 },
            tint_color: jok.Color = jok.Color.white,
        };
        groups: std.ArrayList(Group),
        offset: jok.Point,
        parallax: jok.Point,
        tint_color: jok.Color,

        fn init(allocator: std.mem.Allocator) Self {
            return .{
                .groups = std.ArrayList(Group).init(allocator),
                .offset = .{ .x = 0, .y = 0 },
                .parallax = .{ .x = 1, .y = 1 },
                .tint_color = jok.Color.white,
            };
        }

        fn deinit(self: Self) void {
            self.groups.deinit();
        }

        inline fn onResize(self: *Self) void {
            self.offset = .{ .x = 0, .y = 0 };
            self.parallax = .{ .x = 1, .y = 1 };
            self.tint_color = jok.Color.white;
            for (self.groups.items) |g| {
                self.offset = self.offset.add(g.offset);
                self.parallax = self.parallax.mul(g.parallax);
                self.tint_color = self.tint_color.mod(g.tint_color);
            }
        }

        inline fn size(self: Self) usize {
            return self.groups.items.len;
        }

        fn push(self: *Self, g: Group) !void {
            try self.groups.append(g);
            self.onResize();
        }

        fn pop(self: *Self) void {
            assert(self.size() > 0);
            _ = self.groups.pop();
            self.onResize();
        }

        fn getNextLayer(self: *Self) !?*xml.Element {
            if (self.size() == 0) return null;
            var it = &self.groups.items[self.size() - 1].it;
            while (it.next()) |e| {
                if (std.mem.eql(u8, e.tag, "group")) {
                    var g: Group = .{
                        .it = e.elements(),
                        .offset = .{ .x = 0, .y = 0 },
                        .parallax = .{ .x = 1, .y = 1 },
                        .tint_color = jok.Color.white,
                    };
                    for (e.attributes) |a| {
                        if (std.mem.eql(u8, a.name, "offsetx")) {
                            g.offset.x = try std.fmt.parseFloat(f32, a.value);
                            continue;
                        }
                        if (std.mem.eql(u8, a.name, "offsety")) {
                            g.offset.y = try std.fmt.parseFloat(f32, a.value);
                            continue;
                        }
                        if (std.mem.eql(u8, a.name, "parallaxx")) {
                            g.parallax.x = try std.fmt.parseFloat(f32, a.value);
                            continue;
                        }
                        if (std.mem.eql(u8, a.name, "parallaxy")) {
                            g.parallax.y = try std.fmt.parseFloat(f32, a.value);
                            continue;
                        }
                        if (std.mem.eql(u8, a.name, "opacity")) {
                            g.tint_color.a = @intFromFloat(
                                @as(f32, @floatFromInt(g.tint_color.a)) * try std.fmt.parseFloat(f32, a.value),
                            );
                            continue;
                        }
                        if (std.mem.eql(u8, a.name, "tintcolor")) {
                            g.tint_color = try parseColor(a.value);
                            continue;
                        }
                    }
                    try self.push(g);
                    return try self.getNextLayer();
                }
                if (std.mem.eql(u8, e.tag, "layer") or
                    std.mem.eql(u8, e.tag, "objectgroup") or
                    std.mem.eql(u8, e.tag, "imagelayer"))
                {
                    return e;
                }
            }
            self.pop();
            return try self.getNextLayer();
        }
    };

    var grouping = Grouping.init(temp_allocator);
    defer grouping.deinit();
    try grouping.push(.{
        .it = map.elements(),
        .offset = .{ .x = 0, .y = 0 },
        .parallax = .{ .x = 1, .y = 1 },
        .tint_color = jok.Color.white,
    });

    var ls = std.ArrayList(Layer).init(arena_allocator);

    // Recursively get next layer, until there's no layer left.
    // Visibility isn't considered, all layers are considered necessary to rendering.
    while (try grouping.getNextLayer()) |e| {
        var layer: Layer = undefined;
        var offset: jok.Point = grouping.offset;
        var parallax: jok.Point = grouping.parallax;
        var tint_color: jok.Color = grouping.tint_color;
        var props: PropertyTree = PropertyTree.init(arena_allocator);

        // Load common stuff
        for (e.attributes) |a| {
            if (std.mem.eql(u8, a.name, "offsetx")) {
                offset.x = try std.fmt.parseFloat(f32, a.value);
                continue;
            }
            if (std.mem.eql(u8, a.name, "offsety")) {
                offset.y = try std.fmt.parseFloat(f32, a.value);
                continue;
            }
            if (std.mem.eql(u8, a.name, "parallaxx")) {
                parallax.x = try std.fmt.parseFloat(f32, a.value);
                continue;
            }
            if (std.mem.eql(u8, a.name, "parallaxy")) {
                parallax.y = try std.fmt.parseFloat(f32, a.value);
                continue;
            }
            if (std.mem.eql(u8, a.name, "opacity")) {
                tint_color.a = @intFromFloat(
                    @as(f32, @floatFromInt(tint_color.a)) * try std.fmt.parseFloat(f32, a.value),
                );
                continue;
            }
            if (std.mem.eql(u8, a.name, "tintcolor")) {
                tint_color = tint_color.mod(try parseColor(a.value));
                continue;
            }
        }
        try initPropertyTree(e, arena_allocator, &props);

        // Load layer-specific stuff
        if (std.mem.eql(u8, e.tag, "layer")) {
            var size: jok.Size = undefined;
            for (e.attributes) |a| {
                if (std.mem.eql(u8, a.name, "width")) {
                    size.width = try std.fmt.parseInt(u32, a.value, 10);
                    continue;
                }
                if (std.mem.eql(u8, a.name, "height")) {
                    size.height = try std.fmt.parseInt(u32, a.value, 10);
                    continue;
                }
            }
            var encoding: []const u8 = "";
            const data = e.findChildByTag("data").?;
            for (data.attributes) |a| {
                if (std.mem.eql(u8, a.name, "encoding")) {
                    encoding = a.value;
                    continue;
                }
                if (std.mem.eql(u8, a.name, "compression")) {
                    return error.UnsupportedLayerCompression;
                }
            }
            if (!std.mem.eql(u8, encoding, "csv")) {
                return error.UnsupportedLayerEncoding;
            }
            var chunks = try std.ArrayList(Chunk).initCapacity(arena_allocator, 20);
            if (data.children.len > 0) {
                if (data.findChildByTag("chunk") == null) {
                    try chunks.append(.{
                        .x = 0,
                        .y = 0,
                        .width = size.width,
                        .height = size.height,
                        .gids = &.{},
                    });
                    var gids = try std.ArrayList(GlobalTileID).initCapacity(arena_allocator, 20);
                    var gid_it = std.mem.splitAny(u8, data.children[0].char_data, ",\n");
                    while (gid_it.next()) |s| {
                        if (s.len == 0) continue;
                        try gids.append(.{ ._id = try std.fmt.parseInt(u32, s, 10) });
                    }
                    assert(gids.items.len == size.width * size.height);
                    chunks.items[chunks.items.len - 1].gids = try gids.toOwnedSlice();
                } else {
                    var it = data.findChildrenByTag("chunk");
                    while (it.next()) |ce| {
                        var c: Chunk = undefined;
                        for (ce.attributes) |a| {
                            if (std.mem.eql(u8, a.name, "x")) {
                                c.x = try std.fmt.parseInt(i32, a.value, 10);
                                continue;
                            }
                            if (std.mem.eql(u8, a.name, "y")) {
                                c.y = try std.fmt.parseInt(i32, a.value, 10);
                                continue;
                            }
                            if (std.mem.eql(u8, a.name, "width")) {
                                c.width = try std.fmt.parseInt(u32, a.value, 10);
                                continue;
                            }
                            if (std.mem.eql(u8, a.name, "height")) {
                                c.height = try std.fmt.parseInt(u32, a.value, 10);
                                continue;
                            }
                        }
                        var gids = try std.ArrayList(GlobalTileID).initCapacity(arena_allocator, 20);
                        var gid_it = std.mem.splitAny(u8, ce.children[0].char_data, ",\n");
                        while (gid_it.next()) |s| {
                            if (s.len == 0) continue;
                            try gids.append(.{ ._id = try std.fmt.parseInt(u32, s, 10) });
                        }
                        c.gids = try gids.toOwnedSlice();
                        try chunks.append(c);
                    }
                }
            }
            layer = Layer{
                .tile_layer = .{
                    .size = size,
                    .offset = offset,
                    .parallax = parallax,
                    .tint_color = tint_color,
                    .chunks = try chunks.toOwnedSlice(),
                    .props = props,
                },
            };
        } else if (std.mem.eql(u8, e.tag, "objectgroup")) {
            // TODO
            return error.UnsupportedLayerType;
        } else if (std.mem.eql(u8, e.tag, "imagelayer")) {
            // TODO
            return error.UnsupportedLayerType;
        } else unreachable;
        try ls.append(layer);
    }
    assert(grouping.size() == 0);

    return try ls.toOwnedSlice();
}

inline fn initPropertyTree(element: *const xml.Element, allocator: std.mem.Allocator, tree: *PropertyTree) !void {
    if (element.findChildByTag("properties")) |p| {
        var it = p.findChildrenByTag("property");
        while (it.next()) |v| {
            var name: []const u8 = "";
            var value: []const u8 = "";
            var vtype: []const u8 = "string";
            for (v.attributes) |a| {
                if (std.mem.eql(u8, a.name, "name")) {
                    name = try allocator.dupe(u8, a.value);
                    continue;
                }
                if (std.mem.eql(u8, a.name, "type")) {
                    vtype = a.value;
                    continue;
                }
                if (std.mem.eql(u8, a.name, "value")) {
                    value = a.value;
                    continue;
                }
            }
            assert(name.len > 0);
            assert(value.len > 0);
            var pv: PropertyValue = undefined;
            if (std.mem.eql(u8, vtype, "string")) {
                pv = PropertyValue{ .string = try allocator.dupe(u8, value) };
            } else if (std.mem.eql(u8, vtype, "int")) {
                pv = PropertyValue{ .int = try std.fmt.parseInt(i32, value, 0) };
            } else if (std.mem.eql(u8, vtype, "float")) {
                pv = PropertyValue{ .float = try std.fmt.parseFloat(f32, value) };
            } else if (std.mem.eql(u8, vtype, "bool")) {
                pv = PropertyValue{ .boolean = if (std.mem.eql(u8, value, "true")) true else false };
            } else if (std.mem.eql(u8, vtype, "color")) {
                pv = PropertyValue{ .color = try parseColor(value) };
            } else {
                return error.UnsupportedPropertyType;
            }
            try tree.put(name, pv);
        }
    }
}

inline fn getExternalFileContent(
    allocator: std.mem.Allocator,
    use_physfs: bool,
    dirname: []const u8,
    filename: []const u8,
) ![]const u8 {
    const sep = if (use_physfs) "/" else std.fs.path.sep_str;
    const path = try std.fmt.allocPrintZ(allocator, "{s}{s}{s}", .{ dirname, sep, filename });
    defer allocator.free(path);
    if (use_physfs) {
        const handle = try physfs.open(path, .read);
        defer handle.close();
        return try handle.readAllAlloc(allocator);
    } else {
        const file = try std.fs.cwd().openFileZ(path, .{ .mode = .read_only });
        defer file.close();
        return file.readToEndAlloc(allocator, 1 << 30);
    }
}

inline fn parseColor(s: []const u8) !jok.Color {
    return switch (s.len) {
        // #RRGGBB
        7 => jok.Color.rgb(
            try std.fmt.parseInt(u8, s[1..3], 16),
            try std.fmt.parseInt(u8, s[3..5], 16),
            try std.fmt.parseInt(u8, s[5..7], 16),
        ),

        // #AARRGGBB
        9 => jok.Color.rgba(
            try std.fmt.parseInt(u8, s[3..5], 16),
            try std.fmt.parseInt(u8, s[5..7], 16),
            try std.fmt.parseInt(u8, s[7..9], 16),
            try std.fmt.parseInt(u8, s[1..3], 16),
        ),

        else => unreachable,
    };
}
