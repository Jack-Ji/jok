const std = @import("std");

pub const Error = error{
    ParseFailed,
};

// Rasterized SVG bitmap (RGBA format)
pub const SvgBitmap = struct {
    allocator: std.mem.Allocator,
    width: u32,
    height: u32,
    pixels: []u8,

    pub fn destroy(self: *SvgBitmap) void {
        self.allocator.free(self.pixels);
        self.allocator.destroy(self);
    }
};

/// Size unit
pub const Unit = enum {
    px,
    pt,
    pc,
    mm,
    cm,
    in,

    fn str(self: Unit) [*:0]const u8 {
        return switch (self) {
            .px => "px",
            .pt => "pt",
            .pc => "pc",
            .mm => "mm",
            .cm => "cm",
            .in => "in",
        };
    }
};

pub const CreateBitmap = struct {
    unit: Unit = .px,
    dpi: u32 = 96,
};

pub fn createBitmapFromData(
    allocator: std.mem.Allocator,
    data: []const u8,
    opt: CreateBitmap,
) !*SvgBitmap {
    const bs = try allocator.allocSentinel(u8, data.len, 0);
    defer allocator.free(bs);
    @memcpy(bs, data);

    const img = nsvgParse(bs, opt.unit.str(), @floatFromInt(opt.dpi));
    if (img) |m| {
        defer nsvgDelete(img);

        const rasterizer = nsvgCreateRasterizer();
        if (rasterizer) |rst| {
            defer nsvgDeleteRasterizer(rst);

            const svg = try allocator.create(SvgBitmap);
            svg.* = .{
                .allocator = allocator,
                .width = @intFromFloat(@trunc(m.width)),
                .height = @intFromFloat(@trunc(m.height)),
                .pixels = try allocator.alloc(u8, @intFromFloat(
                    m.width * m.height * 4.0,
                )),
            };

            nsvgRasterize(
                rst,
                m,
                0,
                0,
                1.0,
                svg.pixels.ptr,
                @intCast(svg.width),
                @intCast(svg.height),
                @intCast(svg.width * 4),
            );

            return svg;
        }
    }

    return error.ParseFailed;
}

pub fn createBitmapFromFile(
    allocator: std.mem.Allocator,
    path: []const u8,
    opt: CreateBitmap,
) !*SvgBitmap {
    const data = try std.fs.cwd().readFileAlloc(
        allocator,
        path,
        std.math.maxInt(u64),
    );
    defer allocator.free(data);
    return try createBitmapFromData(allocator, data, opt);
}

const NSVGimage = extern struct {
    width: f32,
    height: f32,
    shapes: *anyopaque,
};
extern fn nsvgParse(input: [*:0]const u8, units: [*:0]const u8, dpi: f32) ?*NSVGimage;
extern fn nsvgDelete(img: ?*NSVGimage) void;
extern fn nsvgCreateRasterizer() ?*anyopaque;
extern fn nsvgDeleteRasterizer(rasterizer: ?*anyopaque) void;
extern fn nsvgRasterize(
    rasterizer: ?*anyopaque,
    image: ?*NSVGimage,
    tx: f32,
    ty: f32,
    scale: f32,
    pixels: [*c]const u8,
    w: i32,
    h: i32,
    stride: i32,
) void;
