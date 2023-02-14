const std = @import("std");
const sdl = @import("sdl");
const jok = @import("../jok.zig");
const AffineTransform = @import("AffineTransform.zig");
const imgui = jok.imgui;

pub const ImageCmd = struct {
    texture: sdl.Texture,
    pmin: sdl.PointF,
    pmax: sdl.PointF,
    uv0: sdl.PointF,
    uv1: sdl.PointF,
    tint_color: u32,
};

pub const ImageRoundedCmd = struct {
    texture: sdl.Texture,
    pmin: sdl.PointF,
    pmax: sdl.PointF,
    uv0: sdl.PointF,
    uv1: sdl.PointF,
    tint_color: u32,
    rounding: f32,
};

pub const QuadImageCmd = struct {
    texture: sdl.Texture,
    p1: sdl.PointF,
    p2: sdl.PointF,
    p3: sdl.PointF,
    p4: sdl.PointF,
    uv1: sdl.PointF,
    uv2: sdl.PointF,
    uv3: sdl.PointF,
    uv4: sdl.PointF,
    tint_color: u32,
};

pub const LineCmd = struct {
    p1: sdl.PointF,
    p2: sdl.PointF,
    color: u32,
    thickness: f32,
};

pub const RectCmd = struct {
    pmin: sdl.PointF,
    pmax: sdl.PointF,
    color: u32,
    thickness: f32,
    rounding: f32,
};

pub const RectFillCmd = struct {
    pmin: sdl.PointF,
    pmax: sdl.PointF,
    color: u32,
    rounding: f32,
};

pub const RectFillMultiColorCmd = struct {
    pmin: sdl.PointF,
    pmax: sdl.PointF,
    color_ul: u32,
    color_ur: u32,
    color_br: u32,
    color_bl: u32,
};

pub const QuadCmd = struct {
    p1: sdl.PointF,
    p2: sdl.PointF,
    p3: sdl.PointF,
    p4: sdl.PointF,
    color: u32,
    thickness: f32,
};

pub const QuadFillCmd = struct {
    p1: sdl.PointF,
    p2: sdl.PointF,
    p3: sdl.PointF,
    p4: sdl.PointF,
    color: u32,
};

pub const TriangleCmd = struct {
    p1: sdl.PointF,
    p2: sdl.PointF,
    p3: sdl.PointF,
    color: u32,
    thickness: f32,
};

pub const TriangleFillCmd = struct {
    p1: sdl.PointF,
    p2: sdl.PointF,
    p3: sdl.PointF,
    color: u32,
};

pub const CircleCmd = struct {
    p: sdl.PointF,
    radius: f32,
    color: u32,
    thickness: f32,
    num_segments: u32,
};

pub const CircleFillCmd = struct {
    p: sdl.PointF,
    radius: f32,
    color: u32,
    num_segments: u32,
};

pub const NgonCmd = struct {
    p: sdl.PointF,
    radius: f32,
    color: u32,
    thickness: f32,
    num_segments: u32,
};

pub const NgonFillCmd = struct {
    p: sdl.PointF,
    radius: f32,
    color: u32,
    num_segments: u32,
};

pub const ConvexPolyCmd = struct {
    points: std.ArrayList(sdl.Vertex),
    color: u32,
    thickness: f32,
    transform: AffineTransform,
};

pub const ConvexPolyFillCmd = struct {
    points: std.ArrayList(sdl.Vertex),
    texture: ?sdl.Texture,
    transform: AffineTransform,
};

pub const BezierCubicCmd = struct {
    p1: sdl.PointF,
    p2: sdl.PointF,
    p3: sdl.PointF,
    p4: sdl.PointF,
    color: u32,
    thickness: f32,
    num_segments: u32,
};

pub const BezierQuadraticCmd = struct {
    p1: sdl.PointF,
    p2: sdl.PointF,
    p3: sdl.PointF,
    color: u32,
    thickness: f32,
    num_segments: u32,
};

pub const PathCmd = struct {
    pub const LineTo = struct {
        p: sdl.PointF,
    };
    pub const ArcTo = struct {
        p: sdl.PointF,
        radius: f32,
        amin: f32,
        amax: f32,
        num_segments: u32,
    };
    pub const BezierCubicTo = struct {
        p2: sdl.PointF,
        p3: sdl.PointF,
        p4: sdl.PointF,
        num_segments: u32,
    };
    pub const BezierQuadraticTo = struct {
        p2: sdl.PointF,
        p3: sdl.PointF,
        num_segments: u32,
    };
    pub const Rect = struct {
        pmin: sdl.PointF,
        pmax: sdl.PointF,
        rounding: f32,
    };
    pub const Cmd = union(enum) {
        line_to: LineTo,
        arc_to: ArcTo,
        bezier_cubic_to: BezierCubicTo,
        bezier_quadratic_to: BezierQuadraticTo,
        rect: Rect,
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
            .transform = undefined,
        };
    }

    pub fn deinit(self: *@This()) void {
        self.cmds.deinit();
        self.* = undefined;
    }
};

pub const DrawCmd = struct {
    cmd: union(enum) {
        image: ImageCmd,
        image_rounded: ImageRoundedCmd,
        quad_image: QuadImageCmd,
        line: LineCmd,
        rect: RectCmd,
        rect_fill: RectFillCmd,
        rect_fill_multicolor: RectFillMultiColorCmd,
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
        path: PathCmd,
    },
    depth: f32,

    pub fn render(self: DrawCmd, dl: imgui.DrawList) !void {
        switch (self.cmd) {
            .image => |c| dl.addImage(c.texture.ptr, .{
                .pmin = .{ c.pmin.x, c.pmin.y },
                .pmax = .{ c.pmax.x, c.pmax.y },
                .uvmin = .{ c.uv0.x, c.uv0.y },
                .uvmax = .{ c.uv1.x, c.uv1.y },
                .col = c.tint_color,
            }),
            .image_rounded => |c| dl.addImageRounded(c.texture.ptr, .{
                .pmin = .{ c.pmin.x, c.pmin.y },
                .pmax = .{ c.pmax.x, c.pmax.y },
                .uvmin = .{ c.uv0.x, c.uv0.y },
                .uvmax = .{ c.uv1.x, c.uv1.y },
                .col = c.tint_color,
                .rounding = c.rounding,
            }),
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
            .line => |c| dl.addLine(.{
                .p1 = .{ c.p1.x, c.p1.y },
                .p2 = .{ c.p2.x, c.p2.y },
                .col = c.color,
                .thickness = c.thickness,
            }),
            .rect => |c| dl.addRect(.{
                .pmin = .{ c.pmin.x, c.pmin.y },
                .pmax = .{ c.pmax.x, c.pmax.y },
                .col = c.color,
                .rounding = c.rounding,
                .thickness = c.thickness,
            }),
            .rect_fill => |c| dl.addRectFilled(.{
                .pmin = .{ c.pmin.x, c.pmin.y },
                .pmax = .{ c.pmax.x, c.pmax.y },
                .col = c.color,
                .rounding = c.rounding,
            }),
            .rect_fill_multicolor => |c| dl.addRectFilledMultiColor(.{
                .pmin = .{ c.pmin.x, c.pmin.y },
                .pmax = .{ c.pmax.x, c.pmax.y },
                .col_upr_left = c.color_ul,
                .col_upr_right = c.color_ur,
                .col_bot_right = c.color_br,
                .col_bot_left = c.color_bl,
            }),
            .quad => |c| dl.addQuad(.{
                .p1 = .{ c.p1.x, c.p1.y },
                .p2 = .{ c.p2.x, c.p2.y },
                .p3 = .{ c.p3.x, c.p3.y },
                .p4 = .{ c.p4.x, c.p4.y },
                .col = c.color,
                .thickness = c.thickness,
            }),
            .quad_fill => |c| dl.addQuadFilled(.{
                .p1 = .{ c.p1.x, c.p1.y },
                .p2 = .{ c.p2.x, c.p2.y },
                .p3 = .{ c.p3.x, c.p3.y },
                .p4 = .{ c.p4.x, c.p4.y },
                .col = c.color,
            }),
            .triangle => |c| dl.addTriangle(.{
                .p1 = .{ c.p1.x, c.p1.y },
                .p2 = .{ c.p2.x, c.p2.y },
                .p3 = .{ c.p3.x, c.p3.y },
                .col = c.color,
                .thickness = c.thickness,
            }),
            .triangle_fill => |c| dl.addTriangleFilled(.{
                .p1 = .{ c.p1.x, c.p1.y },
                .p2 = .{ c.p2.x, c.p2.y },
                .p3 = .{ c.p3.x, c.p3.y },
                .col = c.color,
            }),
            .circle => |c| dl.addCircle(.{
                .p = .{ c.p.x, c.p.y },
                .r = c.radius,
                .col = c.color,
                .thickness = c.thickness,
                .num_segments = c.num_segments,
            }),
            .circle_fill => |c| dl.addCircleFilled(.{
                .p = .{ c.p.x, c.p.y },
                .r = c.radius,
                .col = c.color,
                .num_segments = c.num_segments,
            }),
            .ngon => |c| dl.addNgon(.{
                .p = .{ c.p.x, c.p.y },
                .r = c.radius,
                .col = c.color,
                .thickness = c.thickness,
                .num_segments = c.num_segments,
            }),
            .ngon_fill => |c| dl.addNgonFilled(.{
                .p = .{ c.p.x, c.p.y },
                .r = c.radius,
                .col = c.color,
                .num_segments = c.num_segments,
            }),
            .convex_polygon => |c| {
                dl.pathClear();
                for (c.points.items) |_p| {
                    const p = c.transform.transformPoint(_p.position);
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
                const cur_idx = @intCast(u16, dl.getCurrentIndex());
                const white_pixel_uv = imgui.getFontTexUvWhitePixel();
                dl.primReserve(
                    @intCast(i32, idx_count),
                    @intCast(i32, vtx_count),
                );
                var i: usize = 0;
                while (i < vtx_count) : (i += 1) {
                    const p = c.points.items[i];
                    const pos = c.transform.transformPoint(p.position);
                    dl.primWriteVtx(
                        .{ pos.x, pos.y },
                        if (c.texture != null) .{ p.tex_coord.x, p.tex_coord.y } else white_pixel_uv,
                        imgui.sdl.convertColor(p.color),
                    );
                }
                i = 2;
                while (i < vtx_count) : (i += 1) {
                    dl.primWriteIdx(cur_idx);
                    dl.primWriteIdx(cur_idx + @intCast(u16, i) - 1);
                    dl.primWriteIdx(cur_idx + @intCast(u16, i));
                }
            },
            .bezier_cubic => |c| dl.addBezierCubic(.{
                .p1 = .{ c.p1.x, c.p1.y },
                .p2 = .{ c.p2.x, c.p2.y },
                .p3 = .{ c.p3.x, c.p3.y },
                .p4 = .{ c.p4.x, c.p4.y },
                .col = c.color,
                .thickness = c.thickness,
                .num_segments = c.num_segments,
            }),
            .bezier_quadratic => |c| dl.addBezierQuadratic(.{
                .p1 = .{ c.p1.x, c.p1.y },
                .p2 = .{ c.p2.x, c.p2.y },
                .p3 = .{ c.p3.x, c.p3.y },
                .col = c.color,
                .thickness = c.thickness,
                .num_segments = c.num_segments,
            }),
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
                                .num_segments = pc.num_segments,
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
                                .num_segments = pc.num_segments,
                            });
                        },
                        .bezier_quadratic_to => |pc| {
                            const p2 = c.transform.transformPoint(pc.p2);
                            const p3 = c.transform.transformPoint(pc.p3);
                            dl.pathBezierQuadraticCurveTo(.{
                                .p2 = .{ p2.x, p2.y },
                                .p3 = .{ p3.x, p3.y },
                                .num_segments = pc.num_segments,
                            });
                        },
                        .rect => |pc| {
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
