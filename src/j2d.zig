const std = @import("std");
const assert = std.debug.assert;
const math = std.math;
const sdl = @import("sdl");
const jok = @import("jok.zig");
const imgui = jok.imgui;
const zmath = jok.zmath;
const zmesh = jok.zmesh;

const dc = @import("j2d/draw_command.zig");
pub const Camera = @import("j2d/Camera.zig");
pub const Sprite = @import("j2d/Sprite.zig");
pub const SpriteSheet = @import("j2d/SpriteSheet.zig");
pub const ParticleSystem = @import("j2d/ParticleSystem.zig");
pub const AnimationSystem = @import("j2d/AnimationSystem.zig");
pub const Scene = @import("j2d/Scene.zig");
pub const Vector = @import("j2d/Vector.zig");

pub const TransformOption = struct {
    scale: sdl.PointF = .{ .x = 1, .y = 1 },
    anchor: sdl.PointF = .{ .x = 0, .y = 0 },
    rotate_degree: f32 = 0,
    offset: sdl.PointF = .{ .x = 0, .y = 0 },

    pub fn getMatrix(self: @This()) zmath.Mat {
        return getTransformMatrix(
            self.scale,
            self.anchor,
            self.rotate_degree,
            self.offset,
        );
    }

    pub fn getMatrixNoScale(self: @This()) zmath.Mat {
        return getTransformMatrixNoScale(
            self.anchor,
            self.rotate_degree,
            self.offset,
        );
    }
};

pub const DepthSortMethod = enum {
    none,
    back_to_forth,
    forth_to_back,
};

pub const BlendMethod = enum {
    blend,
    additive,
    overwrite,
};

pub const BeginOption = struct {
    camera: ?Camera = null,
    depth_sort: DepthSortMethod = .none,
    blend_method: BlendMethod = .blend,
    antialiased: bool = true,
};

var arena: std.heap.ArenaAllocator = undefined;
var rd: sdl.Renderer = undefined;
var draw_list: imgui.DrawList = undefined;
var draw_commands: std.ArrayList(dc.DrawCmd) = undefined;
var camera: ?Camera = undefined;
var depth_sort: DepthSortMethod = undefined;
var blend_method: BlendMethod = undefined;

pub fn init(allocator: std.mem.Allocator, _rd: sdl.Renderer) !void {
    arena = std.heap.ArenaAllocator.init(allocator);
    rd = _rd;
    draw_list = imgui.createDrawList();
    draw_commands = std.ArrayList(dc.DrawCmd).init(allocator);
}

pub fn deinit() void {
    arena.deinit();
    imgui.destroyDrawList(draw_list);
    draw_commands.deinit();
}

pub fn begin(opt: BeginOption) void {
    draw_list.reset();
    draw_list.pushClipRectFullScreen();
    draw_list.pushTextureId(imgui.io.getFontsTexId());
    draw_commands.clearRetainingCapacity();
    camera = opt.camera;
    depth_sort = opt.depth_sort;
    blend_method = opt.blend_method;
    if (opt.antialiased) {
        draw_list.setDrawListFlags(.{
            .anti_aliased_lines = true,
            .anti_aliased_lines_use_tex = false,
            .anti_aliased_fill = true,
            .allow_vtx_offset = true,
        });
    }
}

pub fn end() !void {
    try imgui.sdl.renderDrawList(rd, draw_list);
}

pub fn recycleMemory() void {
    imgui.destroyDrawList(draw_list);
    draw_list = imgui.createDrawList();
    draw_commands.clearAndFree();
}

pub fn pushClipRect(rect: sdl.RectangleF, intersect_with_current: bool) void {
    draw_list.pushClipRect(.{
        .pmin = .{ rect.x, rect.y },
        .pmax = .{ rect.x + rect.width, rect.y + rect.height },
        .intersect_with_current = intersect_with_current,
    });
}

pub fn popClipRect() void {
    draw_list.popClipRect();
}

pub const AddLine = struct {
    trs: TransformOption = .{},
    thickness: f32 = 1.0,
};
pub fn addLine(_p1: sdl.PointF, _p2: sdl.PointF, color: sdl.Color, opt: AddLine) void {
    const m = opt.trs.getMatrix();
    const p1 = transformPoint(_p1, m);
    const p2 = transformPoint(_p2, m);
    draw_list.addLine(.{
        .p1 = .{ p1.x, p1.y },
        .p2 = .{ p2.x, p2.y },
        .col = imgui.sdl.convertColor(color),
        .thickness = opt.thickness,
    });
}

pub const AddRect = struct {
    trs: TransformOption = .{},
    thickness: f32 = 1.0,
    rounding: f32 = 0,
};
pub fn addRect(rect: sdl.RectangleF, color: sdl.Color, opt: AddRect) void {
    const m = opt.trs.getMatrixNoScale();
    const _p1 = sdl.PointF{
        .x = rect.x,
        .y = rect.y,
    };
    const p1 = transformPoint(_p1, m);
    const p2 = sdl.PointF{
        .x = p1.x + rect.width * opt.trs.scale.x,
        .y = p1.y + rect.height * opt.trs.scale.y,
    };
    draw_list.addRect(.{
        .pmin = .{ p1.x, p1.y },
        .pmax = .{ p2.x, p2.y },
        .col = imgui.sdl.convertColor(color),
        .rounding = opt.rounding,
        .thickness = opt.thickness,
    });
}

pub const FillRect = struct {
    trs: TransformOption = .{},
    rounding: f32 = 0,
};
pub fn addRectFilled(rect: sdl.RectangleF, color: sdl.Color, opt: FillRect) void {
    const m = opt.trs.getMatrixNoScale();
    const _p1 = sdl.PointF{
        .x = rect.x,
        .y = rect.y,
    };
    const p1 = transformPoint(_p1, m);
    const p2 = sdl.PointF{
        .x = p1.x + rect.width * opt.trs.scale.x,
        .y = p1.y + rect.height * opt.trs.scale.y,
    };
    draw_list.addRectFilled(.{
        .pmin = .{ p1.x, p1.y },
        .pmax = .{ p2.x, p2.y },
        .col = imgui.sdl.convertColor(color),
        .rounding = opt.rounding,
    });
}

pub const FillRectMultiColor = struct {
    trs: TransformOption = .{},
};
pub fn addRectFilledMultiColor(
    rect: sdl.RectangleF,
    color_top_left: sdl.Color,
    color_top_right: sdl.Color,
    color_bottom_right: sdl.Color,
    color_bottom_left: sdl.Color,
    opt: FillRectMultiColor,
) void {
    const m = opt.trs.getMatrixNoScale();
    const _p1 = sdl.PointF{
        .x = rect.x,
        .y = rect.y,
    };
    const p1 = transformPoint(_p1, m);
    const p2 = sdl.PointF{
        .x = p1.x + rect.width * opt.trs.scale.x,
        .y = p1.y + rect.height * opt.trs.scale.y,
    };
    draw_list.addRectFilledMultiColor(.{
        .pmin = .{ p1.x, p1.y },
        .pmax = .{ p2.x, p2.y },
        .col_upr_left = imgui.sdl.convertColor(color_top_left),
        .col_upr_right = imgui.sdl.convertColor(color_top_right),
        .col_bot_right = imgui.sdl.convertColor(color_bottom_right),
        .col_bot_left = imgui.sdl.convertColor(color_bottom_left),
    });
}

pub const AddQuad = struct {
    trs: TransformOption = .{},
    thickness: f32 = 1.0,
};
pub fn addQuad(
    _p1: sdl.PointF,
    _p2: sdl.PointF,
    _p3: sdl.PointF,
    _p4: sdl.PointF,
    color: sdl.Color,
    opt: AddQuad,
) void {
    const m = opt.trs.getMatrix();
    const p1 = transformPoint(_p1, m);
    const p2 = transformPoint(_p2, m);
    const p3 = transformPoint(_p3, m);
    const p4 = transformPoint(_p4, m);
    draw_list.addQuad(.{
        .p1 = [_]f32{ p1.x, p1.y },
        .p2 = [_]f32{ p2.x, p2.y },
        .p3 = [_]f32{ p3.x, p3.y },
        .p4 = [_]f32{ p4.x, p4.y },
        .col = imgui.sdl.convertColor(color),
        .thickness = opt.thickness,
    });
}

pub const FillQuad = struct {
    trs: TransformOption = .{},
};
pub fn addQuadFilled(
    _p1: sdl.PointF,
    _p2: sdl.PointF,
    _p3: sdl.PointF,
    _p4: sdl.PointF,
    color: sdl.Color,
    opt: FillQuad,
) void {
    const m = opt.trs.getMatrix();
    const p1 = transformPoint(_p1, m);
    const p2 = transformPoint(_p2, m);
    const p3 = transformPoint(_p3, m);
    const p4 = transformPoint(_p4, m);
    draw_list.addQuadFilled(.{
        .p1 = [_]f32{ p1.x, p1.y },
        .p2 = [_]f32{ p2.x, p2.y },
        .p3 = [_]f32{ p3.x, p3.y },
        .p4 = [_]f32{ p4.x, p4.y },
        .col = imgui.sdl.convertColor(color),
    });
}

pub const AddTriangle = struct {
    trs: TransformOption = .{},
    thickness: f32 = 1.0,
};
pub fn addTriangle(
    _p1: sdl.PointF,
    _p2: sdl.PointF,
    _p3: sdl.PointF,
    color: sdl.Color,
    opt: AddTriangle,
) void {
    const m = opt.trs.getMatrix();
    const p1 = transformPoint(_p1, m);
    const p2 = transformPoint(_p2, m);
    const p3 = transformPoint(_p3, m);
    draw_list.addTriangle(.{
        .p1 = [_]f32{ p1.x, p1.y },
        .p2 = [_]f32{ p2.x, p2.y },
        .p3 = [_]f32{ p3.x, p3.y },
        .col = imgui.sdl.convertColor(color),
        .thickness = opt.thickness,
    });
}

pub const FillTriangle = struct {
    trs: TransformOption = .{},
};
pub fn addTriangleFilled(
    _p1: sdl.PointF,
    _p2: sdl.PointF,
    _p3: sdl.PointF,
    color: sdl.Color,
    opt: FillTriangle,
) void {
    const m = opt.trs.getMatrix();
    const p1 = transformPoint(_p1, m);
    const p2 = transformPoint(_p2, m);
    const p3 = transformPoint(_p3, m);
    draw_list.addTriangleFilled(.{
        .p1 = [_]f32{ p1.x, p1.y },
        .p2 = [_]f32{ p2.x, p2.y },
        .p3 = [_]f32{ p3.x, p3.y },
        .col = imgui.sdl.convertColor(color),
    });
}

pub const AddCircle = struct {
    trs: TransformOption = .{},
    thickness: f32 = 1.0,
    num_segments: u32 = 0,
};
pub fn addCircle(
    _center: sdl.PointF,
    radius: f32,
    color: sdl.Color,
    opt: AddCircle,
) void {
    const m = opt.trs.getMatrixNoScale();
    const center = transformPoint(_center, m);
    draw_list.addCircle(.{
        .p = [_]f32{ center.x, center.y },
        .r = radius * opt.trs.scale.x,
        .col = imgui.sdl.convertColor(color),
        .thickness = opt.thickness,
        .num_segments = opt.num_segments,
    });
}

pub const FillCircle = struct {
    trs: TransformOption = .{},
    num_segments: u32 = 0,
};
pub fn addCircleFilled(
    _center: sdl.PointF,
    radius: f32,
    color: sdl.Color,
    opt: FillCircle,
) void {
    const m = opt.trs.getMatrixNoScale();
    const center = transformPoint(_center, m);
    draw_list.addCircleFilled(.{
        .p = [_]f32{ center.x, center.y },
        .r = radius * opt.trs.scale.x,
        .col = imgui.sdl.convertColor(color),
        .num_segments = opt.num_segments,
    });
}

pub const AddNgon = struct {
    trs: TransformOption = .{},
    thickness: f32 = 1.0,
    num_segments: u32 = 0,
};
pub fn addNgon(
    _center: sdl.PointF,
    radius: f32,
    color: sdl.Color,
    num_segments: u32,
    opt: AddNgon,
) void {
    const m = opt.trs.getMatrixNoScale();
    const center = transformPoint(_center, m);
    draw_list.addNgon(.{
        .p = [_]f32{ center.x, center.y },
        .r = radius * opt.trs.scale.x,
        .col = imgui.sdl.convertColor(color),
        .num_segments = num_segments,
        .thickness = opt.thickness,
    });
}

pub const FillNgon = struct {
    trs: TransformOption = .{},
};
pub fn addNgonFilled(
    _center: sdl.PointF,
    radius: f32,
    color: sdl.Color,
    num_segments: u32,
    opt: FillNgon,
) void {
    const m = opt.trs.getMatrixNoScale();
    const center = transformPoint(_center, m);
    draw_list.addNgonFilled(.{
        .p = [_]f32{ center.x, center.y },
        .r = radius * opt.trs.scale.x,
        .col = imgui.sdl.convertColor(color),
        .num_segments = num_segments,
    });
}

pub const AddPolyline = struct {
    trs: TransformOption = .{},
    thickness: f32 = 1.0,
    closed: bool = false,
};
pub fn addPolyline(
    _points: []const sdl.PointF,
    color: sdl.Color,
    opt: AddPolyline,
) void {
    const S = struct {
        var points: ?std.ArrayList([2]f32) = null;
    };

    if (_points.len < 2) return;

    if (S.points == null) {
        S.points = std.ArrayList([2]f32).init(arena.allocator());
    }

    S.points.?.clearRetainingCapacity();

    const m = opt.trs.getMatrix();
    for (_points) |_p| {
        const p = transformPoint(_p, m);
        S.points.?.append(.{ p.x, p.y }) catch unreachable;
    }

    draw_list.addPolyline(
        S.points.?.items,
        .{
            .col = imgui.sdl.convertColor(color),
            .flags = .{ .closed = opt.closed },
            .thickness = opt.thickness,
        },
    );
}

pub const AddConvexPolyFilled = struct {
    trs: TransformOption = .{},
};
pub fn addConvexPolyFilled(
    _points: []const sdl.PointF,
    color: sdl.Color,
    opt: AddConvexPolyFilled,
) void {
    const S = struct {
        var points: ?std.ArrayList([2]f32) = null;
    };

    if (_points.len < 2) return;

    if (S.points == null) {
        S.points = std.ArrayList([2]f32).init(arena.allocator());
    }

    S.points.?.clearRetainingCapacity();

    const m = opt.trs.getMatrix();
    for (_points) |_p| {
        const p = transformPoint(_p, m);
        S.points.?.append(.{ p.x, p.y }) catch unreachable;
    }

    draw_list.addConvexPolyFilled(
        S.points.?.items,
        imgui.sdl.convertColor(color),
    );
}

pub const AddBezierCubic = struct {
    trs: TransformOption = .{},
    thickness: f32 = 1.0,
    num_segments: u32 = 0,
};
pub fn addBezierCubic(
    _p1: sdl.PointF,
    _p2: sdl.PointF,
    _p3: sdl.PointF,
    _p4: sdl.PointF,
    color: sdl.Color,
    opt: AddBezierCubic,
) void {
    const m = opt.trs.getMatrix();
    const p1 = transformPoint(_p1, m);
    const p2 = transformPoint(_p2, m);
    const p3 = transformPoint(_p3, m);
    const p4 = transformPoint(_p4, m);
    draw_list.addBezierCubic(.{
        .p1 = .{ p1.x, p1.y },
        .p2 = .{ p2.x, p2.y },
        .p3 = .{ p3.x, p3.y },
        .p4 = .{ p4.x, p4.y },
        .col = imgui.sdl.convertColor(color),
        .thickness = opt.thickness,
    });
}

pub const AddBezierQuadratic = struct {
    trs: TransformOption = .{},
    thickness: f32 = 1.0,
    num_segments: u32 = 0,
};
pub fn addBezierQuadratic(
    _p1: sdl.PointF,
    _p2: sdl.PointF,
    _p3: sdl.PointF,
    color: sdl.Color,
    opt: AddBezierQuadratic,
) void {
    const m = opt.trs.getMatrix();
    const p1 = transformPoint(_p1, m);
    const p2 = transformPoint(_p2, m);
    const p3 = transformPoint(_p3, m);
    draw_list.addBezierQuadratic(.{
        .p1 = .{ p1.x, p1.y },
        .p2 = .{ p2.x, p2.y },
        .p3 = .{ p3.x, p3.y },
        .col = imgui.sdl.convertColor(color),
        .thickness = opt.thickness,
    });
}

pub fn addText(pos: sdl.PointF, color: sdl.Color, fmt: []const u8, args: anytype) void {
    draw_list.addText(
        .{ pos.x, pos.y },
        imgui.sdl.convertColor(color),
        fmt,
        args,
    );
}

pub const Path = struct {
    transform_m: zmath.Mat,
    scale: sdl.PointF,
    path: dc.PathCmd,
    finished: bool = false,

    /// Begin definition of path
    pub const PathBegin = struct {
        trs: TransformOption = .{},
    };
    pub fn begin(allocator: std.mem.Allocator, opt: PathBegin) Path {
        return .{
            .transform_m = opt.trs.getMatrix(),
            .scale = opt.trs.scale,
            .path = dc.PathCmd.init(allocator),
        };
    }

    /// End definition of path
    pub const PathEnd = struct {
        color: sdl.Color = sdl.Color.white,
        thickness: f32 = 1.0,
        closed: bool = false,
    };
    pub fn end(
        self: *Path,
        method: dc.PathCmd.DrawMethod,
        opt: PathEnd,
    ) void {
        self.path.draw_method = method;
        self.path.color = imgui.sdl.convertColor(opt.color);
        self.path.thickness = opt.thickness;
        self.path.closed = opt.closed;
        self.finished = true;
    }

    pub fn deinit(self: *Path) void {
        self.cmd.deinit();
        self.* = undefined;
    }

    fn convertPoint(self: Path, point: sdl.PointF) sdl.PointF {
        return if (camera) |c|
            c.translatePointF(transformPoint(point, self.transform_m))
        else
            transformPoint(point, self.transform_m);
    }

    pub fn lineTo(self: *Path, pos: sdl.PointF) !void {
        try self.path.cmds.append(.{
            .line_to = .{ .p = self.convertPoint(pos) },
        });
    }

    pub const ArcTo = struct {
        num_segments: u32 = 0,
    };
    pub fn arcTo(
        self: *Path,
        pos: sdl.PointF,
        radius: f32,
        degree_begin: f32,
        degree_end: f32,
        opt: ArcTo,
    ) !void {
        try self.path.cmds.append(.{
            .arc_to = .{
                .p = self.convertPoint(pos),
                .radius = radius * self.scale.x,
                .amin = jok.utils.math.degreeToRadian(degree_begin),
                .amax = jok.utils.math.degreeToRadian(degree_end),
                .num_segments = opt.num_segments,
            },
        });
    }

    pub const BezierCurveTo = struct {
        num_segments: u32 = 0,
    };
    pub fn bezierCubicCurveTo(
        self: *Path,
        p2: sdl.PointF,
        p3: sdl.PointF,
        p4: sdl.PointF,
        opt: BezierCurveTo,
    ) void {
        try self.path.cmds.append(.{
            .bezier_cubic_to = .{
                .p2 = self.convertPoint(p2),
                .p3 = self.convertPoint(p3),
                .p4 = self.convertPoint(p4),
                .num_segments = opt.num_segments,
            },
        });
    }
    pub fn bezierQuadraticCurveTo(
        self: *Path,
        p2: sdl.PointF,
        p3: sdl.PointF,
        opt: BezierCurveTo,
    ) void {
        try self.path.cmds.append(.{
            .bezier_quadratic_to = .{
                .p2 = self.convertPoint(p2),
                .p3 = self.convertPoint(p3),
                .num_segments = opt.num_segments,
            },
        });
    }

    pub const Rect = struct {
        rounding: f32 = 0,
    };
    pub fn rect(
        self: *Path,
        r: sdl.RectangleF,
        opt: Rect,
    ) void {
        const pmin = self.convertPoint(.{
            .x = r.x,
            .y = r.y,
        });
        const pmax = self.convertPoint(.{
            .x = pmin.x + r.width * self.scale.x,
            .y = pmin.y + r.height * self.scale.y,
        });
        try self.path.cmds.append(.{
            .rect = .{
                .pmin = pmin,
                .pmax = pmax,
                .rounding = opt.rounding,
            },
        });
    }
};

// Calculate transform matrix
inline fn getTransformMatrix(scale: sdl.PointF, anchor: sdl.PointF, rotate_degree: f32, offset: sdl.PointF) zmath.Mat {
    const m1 = zmath.scaling(scale.x, scale.y, 0);
    const m2 = zmath.translation(-anchor.x, -anchor.y, 0);
    const m3 = zmath.rotationZ(jok.utils.math.degreeToRadian(rotate_degree));
    const m4 = zmath.translation(anchor.x, anchor.y, 0);
    const m5 = zmath.translation(offset.x, offset.y, 0);
    return zmath.mul(zmath.mul(zmath.mul(zmath.mul(m1, m2), m3), m4), m5);
}
inline fn getTransformMatrixNoScale(anchor: sdl.PointF, rotate_degree: f32, offset: sdl.PointF) zmath.Mat {
    const m1 = zmath.translation(-anchor.x, -anchor.y, 0);
    const m2 = zmath.rotationZ(jok.utils.math.degreeToRadian(rotate_degree));
    const m3 = zmath.translation(anchor.x, anchor.y, 0);
    const m4 = zmath.translation(offset.x, offset.y, 0);
    return zmath.mul(zmath.mul(zmath.mul(m1, m2), m3), m4);
}

// Transform coordinate
inline fn transformPoint(pos: sdl.PointF, trs: zmath.Mat) sdl.PointF {
    const v = zmath.f32x4(pos.x, pos.y, 0, 1);
    const tv = zmath.mul(v, trs);
    return .{ .x = tv[0], .y = tv[1] };
}
