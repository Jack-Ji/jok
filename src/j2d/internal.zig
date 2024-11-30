const std = @import("std");
const assert = std.debug.assert;
const math = std.math;
const jok = @import("../jok.zig");
const AffineTransform = @import("AffineTransform.zig");
const imgui = jok.imgui;

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
};

pub const RectFillRoundedCmd = struct {
    pmin: jok.Point,
    pmax: jok.Point,
    color: u32,
    rounding: f32,
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

pub const ConvexPolyCmd = struct {
    points: std.ArrayList(jok.Vertex),
    color: u32,
    thickness: f32,
    transform: AffineTransform = AffineTransform.init(),
};

pub const ConvexPolyFillCmd = struct {
    points: std.ArrayList(jok.Vertex),
    texture: ?jok.Texture,
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
    points: std.ArrayList(jok.Point),
    transformed: std.ArrayList(jok.Point),
    color: u32,
    thickness: f32,
    closed: bool,
    transform: AffineTransform = AffineTransform.init(),
};

pub const PathCmd = struct {
    pub const LineTo = struct {
        p: jok.Point,
    };
    pub const ArcTo = struct {
        p: jok.Point,
        radius: f32,
        amin: f32,
        amax: f32,
        num_segments: u32,
    };
    pub const BezierCubicTo = struct {
        p2: jok.Point,
        p3: jok.Point,
        p4: jok.Point,
        num_segments: u32,
    };
    pub const BezierQuadraticTo = struct {
        p2: jok.Point,
        p3: jok.Point,
        num_segments: u32,
    };
    pub const RectRounded = struct {
        pmin: jok.Point,
        pmax: jok.Point,
        rounding: f32,
    };
    pub const Cmd = union(enum) {
        line_to: LineTo,
        arc_to: ArcTo,
        bezier_cubic_to: BezierCubicTo,
        bezier_quadratic_to: BezierQuadraticTo,
        rect_rounded: RectRounded,
    };
    pub const DrawMethod = enum {
        fill,
        stroke,
    };

    cmds: std.ArrayList(Cmd),
    draw_method: DrawMethod,
    color: u32,
    thickness: f32,
    closed: bool,
    transform: AffineTransform,

    pub fn init(allocator: std.mem.Allocator) @This() {
        return .{
            .cmds = std.ArrayList(Cmd).init(allocator),
            .draw_method = .fill,
            .color = 0xff_ff_ff_ff,
            .thickness = 1,
            .closed = false,
            .transform = AffineTransform.init(),
        };
    }

    pub fn deinit(self: *@This()) void {
        self.cmds.deinit();
        self.* = undefined;
    }
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
        ngon: NgonCmd,
        ngon_fill: NgonFillCmd,
        convex_polygon: ConvexPolyCmd,
        convex_polygon_fill: ConvexPolyFillCmd,
        bezier_cubic: BezierCubicCmd,
        bezier_quadratic: BezierQuadraticCmd,
        polyline: PolylineCmd,
        path: PathCmd,
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

    pub fn render(self: DrawCmd, dl: imgui.DrawList) void {
        switch (self.cmd) {
            .quad_image => |c| {
                dl.pushTextureId(c.texture.ptr);
                defer dl.popTextureId();
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
            .image_rounded => |c| dl.addImageRounded(c.texture.ptr, .{
                .pmin = .{ c.pmin.x, c.pmin.y },
                .pmax = .{ c.pmax.x, c.pmax.y },
                .uvmin = .{ c.uv0.x, c.uv0.y },
                .uvmax = .{ c.uv1.x, c.uv1.y },
                .col = c.tint_color,
                .rounding = c.rounding,
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
            }),
            .rect_rounded_fill => |c| dl.addRectFilled(.{
                .pmin = .{ c.pmin.x, c.pmin.y },
                .pmax = .{ c.pmax.x, c.pmax.y },
                .col = c.color,
                .rounding = c.rounding,
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
                const white_pixel_uv = imgui.getFontTexUvWhitePixel();
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
                const white_pixel_uv = imgui.getFontTexUvWhitePixel();
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
            .convex_polygon => |c| {
                dl.pathClear();
                for (c.points.items) |_p| {
                    const p = c.transform.transformPoint(_p.pos);
                    dl.pathLineTo(.{ p.x, p.y });
                }
                dl.pathStroke(.{
                    .col = c.color,
                    .flags = .{ .closed = true },
                    .thickness = c.thickness,
                });
            },
            .convex_polygon_fill => |c| {
                if (c.texture) |tex| dl.pushTextureId(tex.ptr);
                defer if (c.texture != null) dl.popTextureId();
                const idx_count = (c.points.items.len - 2) * 3;
                const vtx_count = c.points.items.len;
                const cur_idx = dl.getCurrentIndex();
                const white_pixel_uv = imgui.getFontTexUvWhitePixel();
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
            .path => |c| {
                dl.pathClear();
                for (c.cmds.items) |_pc| {
                    switch (_pc) {
                        .line_to => |pc| {
                            const p = c.transform.transformPoint(pc.p);
                            dl.pathLineTo(.{ p.x, p.y });
                        },
                        .arc_to => |pc| {
                            const p = c.transform.transformPoint(pc.p);
                            dl.pathArcTo(.{
                                .p = .{ p.x, p.y },
                                .r = pc.radius * c.transform.getScaleX(),
                                .amin = pc.amin,
                                .amax = pc.amax,
                                .num_segments = @intCast(pc.num_segments),
                            });
                        },
                        .bezier_cubic_to => |pc| {
                            const p2 = c.transform.transformPoint(pc.p2);
                            const p3 = c.transform.transformPoint(pc.p3);
                            const p4 = c.transform.transformPoint(pc.p4);
                            dl.pathBezierCubicCurveTo(.{
                                .p2 = .{ p2.x, p2.y },
                                .p3 = .{ p3.x, p3.y },
                                .p4 = .{ p4.x, p4.y },
                                .num_segments = @intCast(pc.num_segments),
                            });
                        },
                        .bezier_quadratic_to => |pc| {
                            const p2 = c.transform.transformPoint(pc.p2);
                            const p3 = c.transform.transformPoint(pc.p3);
                            dl.pathBezierQuadraticCurveTo(.{
                                .p2 = .{ p2.x, p2.y },
                                .p3 = .{ p3.x, p3.y },
                                .num_segments = @intCast(pc.num_segments),
                            });
                        },
                        .rect_rounded => |pc| {
                            const vmin = c.transform.transformPoint(pc.pmin);
                            const scale = c.transform.getScale();
                            const width = (pc.pmax.x - pc.pmin.x) * scale.x;
                            const height = (pc.pmax.y - pc.pmin.y) * scale.y;
                            dl.pathRect(.{
                                .bmin = .{ vmin.x, vmin.y },
                                .bmax = .{ vmin.x + width, vmin.y + height },
                                .rounding = pc.rounding,
                            });
                        },
                    }
                }
                switch (c.draw_method) {
                    .fill => dl.pathFillConvex(c.color),
                    .stroke => dl.pathStroke(.{
                        .col = c.color,
                        .flags = .{ .closed = c.closed },
                        .thickness = c.thickness,
                    }),
                }
            },
        }
    }
};
