const std = @import("std");
const jok = @import("../../jok.zig");
const physfs = jok.vendor.physfs;
const builtin = @import("builtin");

pub const Error = error{
    ParseFailed,
};

// Rasterized SVG bitmap (RGBA format)
pub const SvgBitmap = struct {
    allocator: std.mem.Allocator,
    size: jok.Size,
    pixels: []u8,

    pub fn destroy(self: *SvgBitmap) void {
        self.allocator.free(self.pixels);
        self.* = undefined;
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

    fn str(self: Unit) [:0]const u8 {
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
    wanted_size: ?union(enum) { scale: f32, width: f32, height: f32 } = null,
};

pub fn createBitmapFromData(
    allocator: std.mem.Allocator,
    data: []const u8,
    opt: CreateBitmap,
) !SvgBitmap {
    const bs = try allocator.allocSentinel(u8, data.len, 0);
    defer allocator.free(bs);
    @memcpy(bs, data);

    const img = nsvgParse(bs, opt.unit.str(), @floatFromInt(opt.dpi));
    if (img) |m| {
        defer nsvgDelete(img);

        var scale: f32 = 1.0;
        if (opt.wanted_size) |sz| {
            scale = switch (sz) {
                .scale => |s| s,
                .width => |w| w / m.width,
                .height => |h| h / m.height,
            };
        }
        const rasterizer = nsvgCreateRasterizer();
        if (rasterizer) |rst| {
            defer nsvgDeleteRasterizer(rst);

            const w: u32 = @intFromFloat(m.width * scale);
            const h: u32 = @intFromFloat(m.height * scale);
            const pixels = try allocator.alloc(u8, w * h * 4);
            const svg = SvgBitmap{
                .allocator = allocator,
                .size = .{ .width = w, .height = h },
                .pixels = pixels,
            };

            nsvgRasterize(
                rst,
                m,
                0,
                0,
                scale,
                svg.pixels.ptr,
                @intCast(svg.size.width),
                @intCast(svg.size.height),
                @intCast(svg.size.width * 4),
            );

            return svg;
        }
    }

    return error.ParseFailed;
}

pub fn createBitmapFromFile(
    ctx: jok.Context,
    path: [:0]const u8,
    opt: CreateBitmap,
) !SvgBitmap {
    const allocator = ctx.allocator();

    var filedata: []u8 = undefined;
    if (ctx.cfg().jok_enable_physfs) {
        const handle = try physfs.open(path, .read);
        defer handle.close();

        filedata = try handle.readAllAlloc(allocator);
    } else {
        var thread = std.Io.Threaded.init_single_threaded;
        const io = thread.ioBasic();
        const stat = try std.Io.Dir.statPath(
            std.Io.Dir.cwd(),
            io,
            std.mem.sliceTo(path, 0),
            .{ .follow_symlinks = false },
        );
        filedata = try allocator.alloc(u8, @intCast(stat.size));
        _ = try std.Io.Dir.readFile(
            std.Io.Dir.cwd(),
            io,
            std.mem.sliceTo(path, 0),
            filedata,
        );
    }
    defer allocator.free(filedata);

    return try createBitmapFromData(allocator, filedata, opt);
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
