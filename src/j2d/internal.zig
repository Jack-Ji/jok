const std = @import("std");
const assert = std.debug.assert;
const math = std.math;
const jok = @import("../jok.zig");
const AffineTransform = @import("AffineTransform.zig");
const zgui = jok.vendor.zgui;

pub const QuadImageCmd = struct {
    texture: jok.Texture,
    p1: jok.Point,
    p2: jok.Point,
    p3: jok.Point,
    p4: jok.Point,
    uv1: jok.Point,
    uv2: jok.Point,
    uv3: jok.Point,
    uv4: jok.Point,
    tint_color: u32,
};

pub const ImageRoundedCmd = struct {
    texture: jok.Texture,
    pmin: jok.Point,
    pmax: jok.Point,
    uv0: jok.Point,
    uv1: jok.Point,
    tint_color: u32,
    rounding: f32,
    corner_top_left: bool,
    corner_top_right: bool,
    corner_bottom_left: bool,
    corner_bottom_right: bool,
};

pub const LineCmd = struct {
    p1: jok.Point,
    p2: jok.Point,
    color: u32,
    thickness: f32,
};

pub const RectRoundedCmd = struct {
    pmin: jok.Point,
    pmax: jok.Point,
    color: u32,
    thickness: f32,
    rounding: f32,
    corner_top_left: bool,
    corner_top_right: bool,
    corner_bottom_left: bool,
    corner_bottom_right: bool,
};

pub const RectFillRoundedCmd = struct {
    pmin: jok.Point,
    pmax: jok.Point,
    color: u32,
    rounding: f32,
    corner_top_left: bool,
    corner_top_right: bool,
    corner_bottom_left: bool,
    corner_bottom_right: bool,
};

pub const QuadCmd = struct {
    p1: jok.Point,
    p2: jok.Point,
    p3: jok.Point,
    p4: jok.Point,
    color: u32,
    thickness: f32,
};

pub const QuadFillCmd = struct {
    p1: jok.Point,
    p2: jok.Point,
    p3: jok.Point,
    p4: jok.Point,
    color1: u32,
    color2: u32,
    color3: u32,
    color4: u32,
};

pub const TriangleCmd = struct {
    p1: jok.Point,
    p2: jok.Point,
    p3: jok.Point,
    color: u32,
    thickness: f32,
};

pub const TriangleFillCmd = struct {
    p1: jok.Point,
    p2: jok.Point,
    p3: jok.Point,
    color1: u32,
    color2: u32,
    color3: u32,
};

pub const CircleCmd = struct {
    p: jok.Point,
    radius: f32,
    color: u32,
    thickness: f32,
    num_segments: u32,
};

pub const CircleFillCmd = struct {
    p: jok.Point,
    radius: f32,
    color: u32,
    num_segments: u32,
};

pub const EllipseCmd = struct {
    p: jok.Point,
    radius: jok.Point,
    color: u32,
    rotation: f32,
    thickness: f32,
    num_segments: u32,
};

pub const EllipseFillCmd = struct {
    p: jok.Point,
    radius: jok.Point,
    color: u32,
    rotation: f32,
    num_segments: u32,
};

pub const NgonCmd = struct {
    p: jok.Point,
    radius: f32,
    color: u32,
    thickness: f32,
    num_segments: u32,
};

pub const NgonFillCmd = struct {
    p: jok.Point,
    radius: f32,
    color: u32,
    num_segments: u32,
};

pub const ConvexPolyFillCmd = struct {
    points: std.array_list.Managed(jok.Vertex),
    texture: ?jok.Texture,
    transform: AffineTransform = AffineTransform.init(),
};

pub const ConcavePolyFillCmd = struct {
    points: std.array_list.Managed(jok.Point),
    transformed: std.array_list.Managed(jok.Point),
    color: u32,
    transform: AffineTransform = AffineTransform.init(),
};

pub const BezierCubicCmd = struct {
    p1: jok.Point,
    p2: jok.Point,
    p3: jok.Point,
    p4: jok.Point,
    color: u32,
    thickness: f32,
    num_segments: u32,
};

pub const BezierQuadraticCmd = struct {
    p1: jok.Point,
    p2: jok.Point,
    p3: jok.Point,
    color: u32,
    thickness: f32,
    num_segments: u32,
};

pub const PolylineCmd = struct {
    points: std.array_list.Managed(jok.Point),
    transformed: std.array_list.Managed(jok.Point),
    color: u32,
    thickness: f32,
    closed: bool,
    transform: AffineTransform = AffineTransform.init(),
};

pub const DrawCmd = struct {
    cmd: union(enum) {
        quad_image: QuadImageCmd,
        image_rounded: ImageRoundedCmd,
        line: LineCmd,
        rect_rounded: RectRoundedCmd,
        rect_rounded_fill: RectFillRoundedCmd,
        quad: QuadCmd,
        quad_fill: QuadFillCmd,
        triangle: TriangleCmd,
        triangle_fill: TriangleFillCmd,
        circle: CircleCmd,
        circle_fill: CircleFillCmd,
        ellipse: EllipseCmd,
        ellipse_fill: EllipseFillCmd,
        ngon: NgonCmd,
        ngon_fill: NgonFillCmd,
        convex_polygon_fill: ConvexPolyFillCmd,
        concave_polygon_fill: ConcavePolyFillCmd,
        bezier_cubic: BezierCubicCmd,
        bezier_quadratic: BezierQuadraticCmd,
        polyline: PolylineCmd,
    },
    depth: f32,

    inline fn getTexture(d: DrawCmd) ?jok.Texture {
        return switch (d.cmd) {
            .quad_image => |cmd| cmd.texture,
            .image_rounded => |cmd| cmd.texture,
            .convex_polygon_fill => |cmd| cmd.texture,
            else => null,
        };
    }

    pub fn compare(d0: DrawCmd, d1: DrawCmd, ascend: bool) bool {
        if (math.approxEqAbs(f32, d0.depth, d1.depth, 0.0001)) {
            const tex0 = d0.getTexture();
            const tex1 = d1.getTexture();
            if (tex0 == null and tex1 == null) return if (ascend) d0.depth < d1.depth else d0.depth > d1.depth;
            if (tex0 != null and tex1 != null) return @intFromPtr(tex0.?.ptr) < @intFromPtr(tex1.?.ptr);
            return tex0 == null;
        }
        return if (ascend) d0.depth < d1.depth else d0.depth > d1.depth;
    }

    pub fn render(self: DrawCmd, dl: zgui.DrawList) void {
        switch (self.cmd) {
            .quad_image => |c| {
                dl.pushTexture(c.texture.toReference());
                defer dl.popTexture();
                dl.primReserve(6, 4);
                dl.primQuadUV(
                    .{ c.p1.x, c.p1.y },
                    .{ c.p2.x, c.p2.y },
                    .{ c.p3.x, c.p3.y },
                    .{ c.p4.x, c.p4.y },
                    .{ c.uv1.x, c.uv1.y },
                    .{ c.uv2.x, c.uv2.y },
                    .{ c.uv3.x, c.uv3.y },
                    .{ c.uv4.x, c.uv4.y },
                    c.tint_color,
                );
            },
            .image_rounded => |c| dl.addImageRounded(c.texture.toReference(), .{
                .pmin = .{ c.pmin.x, c.pmin.y },
                .pmax = .{ c.pmax.x, c.pmax.y },
                .uvmin = .{ c.uv0.x, c.uv0.y },
                .uvmax = .{ c.uv1.x, c.uv1.y },
                .col = c.tint_color,
                .rounding = c.rounding,
                .flags = .{
                    .round_corners_top_left = c.corner_top_left,
                    .round_corners_top_right = c.corner_top_right,
                    .round_corners_bottom_left = c.corner_bottom_left,
                    .round_corners_bottom_right = c.corner_bottom_right,
                },
            }),
            .line => |c| dl.addLine(.{
                .p1 = .{ c.p1.x, c.p1.y },
                .p2 = .{ c.p2.x, c.p2.y },
                .col = c.color,
                .thickness = c.thickness,
            }),
            .rect_rounded => |c| dl.addRect(.{
                .pmin = .{ c.pmin.x, c.pmin.y },
                .pmax = .{ c.pmax.x, c.pmax.y },
                .col = c.color,
                .rounding = c.rounding,
                .thickness = c.thickness,
                .flags = .{
                    .round_corners_top_left = c.corner_top_left,
                    .round_corners_top_right = c.corner_top_right,
                    .round_corners_bottom_left = c.corner_bottom_left,
                    .round_corners_bottom_right = c.corner_bottom_right,
                },
            }),
            .rect_rounded_fill => |c| dl.addRectFilled(.{
                .pmin = .{ c.pmin.x, c.pmin.y },
                .pmax = .{ c.pmax.x, c.pmax.y },
                .col = c.color,
                .rounding = c.rounding,
                .flags = .{
                    .round_corners_top_left = c.corner_top_left,
                    .round_corners_top_right = c.corner_top_right,
                    .round_corners_bottom_left = c.corner_bottom_left,
                    .round_corners_bottom_right = c.corner_bottom_right,
                },
            }),
            .quad => |c| dl.addQuad(.{
                .p1 = .{ c.p1.x, c.p1.y },
                .p2 = .{ c.p2.x, c.p2.y },
                .p3 = .{ c.p3.x, c.p3.y },
                .p4 = .{ c.p4.x, c.p4.y },
                .col = c.color,
                .thickness = c.thickness,
            }),
            .quad_fill => |c| {
                const white_pixel_uv = zgui.getFontTexUvWhitePixel();
                const cur_idx = dl.getCurrentIndex();
                dl.primReserve(6, 4);
                dl.primWriteVtx(.{ c.p1.x, c.p1.y }, white_pixel_uv, c.color1);
                dl.primWriteVtx(.{ c.p2.x, c.p2.y }, white_pixel_uv, c.color2);
                dl.primWriteVtx(.{ c.p3.x, c.p3.y }, white_pixel_uv, c.color3);
                dl.primWriteVtx(.{ c.p4.x, c.p4.y }, white_pixel_uv, c.color4);
                dl.primWriteIdx(cur_idx);
                dl.primWriteIdx(cur_idx + 1);
                dl.primWriteIdx(cur_idx + 2);
                dl.primWriteIdx(cur_idx);
                dl.primWriteIdx(cur_idx + 2);
                dl.primWriteIdx(cur_idx + 3);
            },
            .triangle => |c| dl.addTriangle(.{
                .p1 = .{ c.p1.x, c.p1.y },
                .p2 = .{ c.p2.x, c.p2.y },
                .p3 = .{ c.p3.x, c.p3.y },
                .col = c.color,
                .thickness = c.thickness,
            }),
            .triangle_fill => |c| {
                const white_pixel_uv = zgui.getFontTexUvWhitePixel();
                const cur_idx = dl.getCurrentIndex();
                dl.primReserve(3, 3);
                dl.primWriteVtx(.{ c.p1.x, c.p1.y }, white_pixel_uv, c.color1);
                dl.primWriteVtx(.{ c.p2.x, c.p2.y }, white_pixel_uv, c.color2);
                dl.primWriteVtx(.{ c.p3.x, c.p3.y }, white_pixel_uv, c.color3);
                dl.primWriteIdx(cur_idx);
                dl.primWriteIdx(cur_idx + 1);
                dl.primWriteIdx(cur_idx + 2);
            },
            .circle => |c| dl.addCircle(.{
                .p = .{ c.p.x, c.p.y },
                .r = c.radius,
                .col = c.color,
                .thickness = c.thickness,
                .num_segments = @intCast(c.num_segments),
            }),
            .circle_fill => |c| dl.addCircleFilled(.{
                .p = .{ c.p.x, c.p.y },
                .r = c.radius,
                .col = c.color,
                .num_segments = @intCast(c.num_segments),
            }),
            .ellipse => |c| dl.addEllipse(.{
                .p = .{ c.p.x, c.p.y },
                .r = .{ c.radius.x, c.radius.y },
                .col = c.color,
                .rot = c.rotation,
                .thickness = c.thickness,
                .num_segments = @intCast(c.num_segments),
            }),
            .ellipse_fill => |c| dl.addEllipseFilled(.{
                .p = .{ c.p.x, c.p.y },
                .r = .{ c.radius.x, c.radius.y },
                .col = c.color,
                .rot = c.rotation,
                .num_segments = @intCast(c.num_segments),
            }),
            .ngon => |c| dl.addNgon(.{
                .p = .{ c.p.x, c.p.y },
                .r = c.radius,
                .col = c.color,
                .thickness = c.thickness,
                .num_segments = @intCast(c.num_segments),
            }),
            .ngon_fill => |c| dl.addNgonFilled(.{
                .p = .{ c.p.x, c.p.y },
                .r = c.radius,
                .col = c.color,
                .num_segments = @intCast(c.num_segments),
            }),
            .convex_polygon_fill => |c| {
                if (c.texture) |tex| dl.pushTexture(tex.toReference());
                defer if (c.texture != null) dl.popTexture();
                const idx_count = (c.points.items.len - 2) * 3;
                const vtx_count = c.points.items.len;
                const cur_idx = dl.getCurrentIndex();
                const white_pixel_uv = zgui.getFontTexUvWhitePixel();
                dl.primReserve(
                    @intCast(idx_count),
                    @intCast(vtx_count),
                );
                var i: usize = 0;
                while (i < vtx_count) : (i += 1) {
                    const p = c.points.items[i];
                    const pos = c.transform.transformPoint(p.pos);
                    dl.primWriteVtx(
                        .{ pos.x, pos.y },
                        if (c.texture != null) .{ p.texcoord.x, p.texcoord.y } else white_pixel_uv,
                        p.color.toInternalColor(),
                    );
                }
                i = 2;
                while (i < vtx_count) : (i += 1) {
                    dl.primWriteIdx(cur_idx);
                    dl.primWriteIdx(cur_idx + @as(u32, @intCast(i)) - 1);
                    dl.primWriteIdx(cur_idx + @as(u32, @intCast(i)));
                }
            },
            .concave_polygon_fill => |c| {
                assert(c.transformed.items.len >= c.points.items.len);
                for (c.points.items, 0..) |p, i| {
                    c.transformed.items[i] = c.transform.transformPoint(p);
                }
                var pts: []const [2]f32 = undefined;
                pts.len = c.transformed.items.len;
                pts.ptr = @ptrCast(c.transformed.items.ptr);
                dl.addConcavePolyFilled(pts, c.color);
            },
            .bezier_cubic => |c| dl.addBezierCubic(.{
                .p1 = .{ c.p1.x, c.p1.y },
                .p2 = .{ c.p2.x, c.p2.y },
                .p3 = .{ c.p3.x, c.p3.y },
                .p4 = .{ c.p4.x, c.p4.y },
                .col = c.color,
                .thickness = c.thickness,
                .num_segments = @intCast(c.num_segments),
            }),
            .bezier_quadratic => |c| dl.addBezierQuadratic(.{
                .p1 = .{ c.p1.x, c.p1.y },
                .p2 = .{ c.p2.x, c.p2.y },
                .p3 = .{ c.p3.x, c.p3.y },
                .col = c.color,
                .thickness = c.thickness,
                .num_segments = @intCast(c.num_segments),
            }),
            .polyline => |c| {
                assert(c.transformed.items.len >= c.points.items.len);
                for (c.points.items, 0..) |p, i| {
                    c.transformed.items[i] = c.transform.transformPoint(p);
                }
                var pts: []const [2]f32 = undefined;
                pts.len = c.transformed.items.len;
                pts.ptr = @ptrCast(c.transformed.items.ptr);
                dl.addPolyline(pts, .{
                    .col = c.color,
                    .flags = .{ .closed = c.closed },
                    .thickness = c.thickness,
                });
            },
        }
    }
};
