const std = @import("std");
const assert = std.debug.assert;
const math = std.math;
const sdl = @import("sdl");
const jok = @import("../jok.zig");
const imgui = jok.imgui;
const zmath = jok.zmath;

pub const TransformOption = struct {
    scale: sdl.PointF = .{ .x = 1, .y = 1 },
    anchor: sdl.PointF = .{ .x = 0, .y = 0 },
    rotate: f32 = 0,
    offset: sdl.PointF = .{ .x = 0, .y = 0 },

    pub fn getMatrix(self: @This()) zmath.Mat {
        return getTransformMatrix(
            self.scale,
            self.anchor,
            self.rotate,
            self.offset,
        );
    }
};

var arena: std.heap.ArenaAllocator = undefined;
var draw_list: ?imgui.DrawList = null;
var rd: sdl.Renderer = undefined;

/// Create primitive renderer
pub fn init(allocator: std.mem.Allocator, _rd: sdl.Renderer) void {
    arena = std.heap.ArenaAllocator.init(allocator);
    draw_list = imgui.createDrawList();
    rd = _rd;
}

/// Destroy primitive renderer
pub fn deinit() void {
    arena.deinit();
    imgui.destroyDrawList(draw_list.?);
}

/// Reset draw list state
pub const RenderOption = struct {
    antialiased: bool = true,
};
pub fn clear(opt: RenderOption) void {
    draw_list.?.reset();

    const fb_size = rd.getOutputSize() catch unreachable;
    pushClipRect(.{
        .x = 0,
        .y = 0,
        .width = @intToFloat(f32, fb_size.width_pixels),
        .height = @intToFloat(f32, fb_size.height_pixels),
    }, false);

    if (opt.antialiased) {
        draw_list.?.setDrawListFlags(.{
            .anti_aliased_lines = true,
            .anti_aliased_lines_use_tex = false,
            .anti_aliased_fill = true,
            .allow_vtx_offset = true,
        });
    }
}

/// Render data
pub fn draw() !void {
    if (draw_list.?.getCmdBufferLength() <= 0) return;

    const fb_size = try rd.getOutputSize();
    const old_clip_rect = try rd.getClipRect();
    defer rd.setClipRect(old_clip_rect) catch unreachable;

    const commands = draw_list.?.getCmdBufferData()[0..@intCast(u32, draw_list.?.getCmdBufferLength())];
    const vs_ptr = draw_list.?.getVertexBufferData();
    const vs_count = draw_list.?.getVertexBufferLength();
    const is_ptr = draw_list.?.getIndexBufferData();
    for (commands) |cmd| {
        if (cmd.user_callback) |_| continue;

        // Apply clip rect
        var clip_rect: sdl.Rectangle = undefined;
        clip_rect.x = math.min(0, @floatToInt(c_int, cmd.clip_rect[0]));
        clip_rect.y = math.min(0, @floatToInt(c_int, cmd.clip_rect[1]));
        clip_rect.width = math.min(fb_size.width_pixels, @floatToInt(c_int, cmd.clip_rect[2] - cmd.clip_rect[0]));
        clip_rect.height = math.min(fb_size.height_pixels, @floatToInt(c_int, cmd.clip_rect[3] - cmd.clip_rect[1]));
        if (clip_rect.width <= 0 or clip_rect.height <= 0) continue;
        try rd.setClipRect(clip_rect);

        // Bind texture and draw
        const xy = @ptrToInt(vs_ptr + @intCast(usize, cmd.vtx_offset)) + @offsetOf(imgui.DrawVert, "pos");
        const uv = @ptrToInt(vs_ptr + @intCast(usize, cmd.vtx_offset)) + @offsetOf(imgui.DrawVert, "uv");
        const cs = @ptrToInt(vs_ptr + @intCast(usize, cmd.vtx_offset)) + @offsetOf(imgui.DrawVert, "color");
        const is = @ptrToInt(is_ptr + cmd.idx_offset);
        const tex = cmd.texture_id;
        _ = sdl.c.SDL_RenderGeometryRaw(
            rd.ptr,
            @ptrCast(?*sdl.c.SDL_Texture, tex),
            @intToPtr([*]const f32, xy),
            @sizeOf(imgui.DrawVert),
            @intToPtr([*]const sdl.c.SDL_Color, cs),
            @sizeOf(imgui.DrawVert),
            @intToPtr([*]const f32, uv),
            @sizeOf(imgui.DrawVert),
            @intCast(c_int, vs_count) - @intCast(c_int, cmd.vtx_offset),
            @intToPtr([*]const c_int, is),
            @intCast(c_int, cmd.elem_count),
            @sizeOf(imgui.DrawIdx),
        );
    }
}

pub fn pushClipRect(rect: sdl.RectangleF, intersect_with_current: bool) void {
    draw_list.?.pushClipRect(.{
        .pmin = .{ rect.x, rect.y },
        .pmax = .{ rect.x + rect.width, rect.y + rect.height },
        .intersect_with_current = intersect_with_current,
    });
}

pub fn popClipRect() void {
    draw_list.?.popClipRect();
}

pub fn pushTexture(tex: sdl.Texture) void {
    draw_list.?.pushTextureId(tex.ptr);
}

pub fn popTexture() void {
    draw_list.?.popTextureId();
}

pub const AddLine = struct {
    trs: TransformOption = .{},
    thickness: f32 = 1.0,
};
pub fn addLine(_p1: sdl.PointF, _p2: sdl.PointF, color: sdl.Color, opt: AddLine) void {
    const m = opt.trs.getMatrix();
    const p1 = transformPoint(_p1, m);
    const p2 = transformPoint(_p2, m);
    draw_list.?.addLine(.{
        .p1 = .{ p1.x, p1.y },
        .p2 = .{ p2.x, p2.y },
        .col = convertColor(color),
        .thickness = opt.thickness,
    });
}

pub const AddRect = struct {
    trs: TransformOption = .{},
    thickness: f32 = 1.0,
    rounding: f32 = 0,
};
pub fn addRect(rect: sdl.RectangleF, color: sdl.Color, opt: AddRect) void {
    const m = opt.trs.getMatrix();
    const _p1 = sdl.PointF{
        .x = rect.x,
        .y = rect.y,
    };
    const p1 = transformPoint(_p1, m);
    const p2 = sdl.PointF{
        .x = p1.x + rect.width,
        .y = p1.y + rect.height,
    };
    draw_list.?.addRect(.{
        .pmin = .{ p1.x, p1.y },
        .pmax = .{ p2.x, p2.y },
        .col = convertColor(color),
        .rounding = opt.rounding,
        .thickness = opt.thickness,
    });
}

pub const FillRect = struct {
    trs: TransformOption = .{},
    rounding: f32 = 0,
};
pub fn addRectFilled(rect: sdl.RectangleF, color: sdl.Color, opt: FillRect) void {
    const m = opt.trs.getMatrix();
    const _p1 = sdl.PointF{
        .x = rect.x,
        .y = rect.y,
    };
    const p1 = transformPoint(_p1, m);
    const p2 = sdl.PointF{
        .x = p1.x + rect.width,
        .y = p1.y + rect.height,
    };
    draw_list.?.addRectFilled(.{
        .pmin = .{ p1.x, p1.y },
        .pmax = .{ p2.x, p2.y },
        .col = convertColor(color),
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
    _opt: FillRectMultiColor,
) void {
    var opt = _opt;
    opt.trs.rotate = 0; // NOTE: doesn't support rotating
    //
    const m = opt.trs.getMatrix();
    const _p1 = sdl.PointF{
        .x = rect.x,
        .y = rect.y,
    };
    const _p2 = sdl.PointF{
        .x = rect.x + rect.width,
        .y = rect.y + rect.height,
    };
    const p1 = transformPoint(_p1, m);
    const p2 = transformPoint(_p2, m);
    draw_list.?.addRectFilledMultiColor(.{
        .pmin = .{ p1.x, p1.y },
        .pmax = .{ p2.x, p2.y },
        .col_upr_left = convertColor(color_top_left),
        .col_upr_right = convertColor(color_top_right),
        .col_bot_right = convertColor(color_bottom_right),
        .col_bot_left = convertColor(color_bottom_left),
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
    draw_list.?.addQuad(.{
        .p1 = [_]f32{ p1.x, p1.y },
        .p2 = [_]f32{ p2.x, p2.y },
        .p3 = [_]f32{ p3.x, p3.y },
        .p4 = [_]f32{ p4.x, p4.y },
        .col = convertColor(color),
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
    draw_list.?.addQuadFilled(.{
        .p1 = [_]f32{ p1.x, p1.y },
        .p2 = [_]f32{ p2.x, p2.y },
        .p3 = [_]f32{ p3.x, p3.y },
        .p4 = [_]f32{ p4.x, p4.y },
        .col = convertColor(color),
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
    draw_list.?.addTriangle(.{
        .p1 = [_]f32{ p1.x, p1.y },
        .p2 = [_]f32{ p2.x, p2.y },
        .p3 = [_]f32{ p3.x, p3.y },
        .col = convertColor(color),
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
    draw_list.?.addTriangleFilled(.{
        .p1 = [_]f32{ p1.x, p1.y },
        .p2 = [_]f32{ p2.x, p2.y },
        .p3 = [_]f32{ p3.x, p3.y },
        .col = convertColor(color),
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
    const m = opt.trs.getMatrix();
    const center = transformPoint(_center, m);
    draw_list.?.addCircle(.{
        .p = [_]f32{ center.x, center.y },
        .r = radius,
        .col = convertColor(color),
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
    const m = opt.trs.getMatrix();
    const center = transformPoint(_center, m);
    draw_list.?.addCircleFilled(.{
        .p = [_]f32{ center.x, center.y },
        .r = radius,
        .col = convertColor(color),
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
    const m = opt.trs.getMatrix();
    const center = transformPoint(_center, m);
    draw_list.?.addNgon(.{
        .p = [_]f32{ center.x, center.y },
        .r = radius,
        .col = convertColor(color),
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
    const m = opt.trs.getMatrix();
    const center = transformPoint(_center, m);
    draw_list.?.addNgonFilled(.{
        .p = [_]f32{ center.x, center.y },
        .r = radius,
        .col = convertColor(color),
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

    draw_list.?.addPolyline(
        S.points.?.items,
        .{
            .col = convertColor(color),
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

    draw_list.?.addConvexPolyFilled(
        S.points.?.items,
        convertColor(color),
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
    draw_list.?.addBezierCubic(.{
        .p1 = .{ p1.x, p1.y },
        .p2 = .{ p2.x, p2.y },
        .p3 = .{ p3.x, p3.y },
        .p4 = .{ p4.x, p4.y },
        .col = convertColor(color),
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
    draw_list.?.addBezierQuadratic(.{
        .p1 = .{ p1.x, p1.y },
        .p2 = .{ p2.x, p2.y },
        .p3 = .{ p3.x, p3.y },
        .col = convertColor(color),
        .thickness = opt.thickness,
    });
}

// Calculate transform matrix
inline fn getTransformMatrix(scale: sdl.PointF, anchor: sdl.PointF, rotate: f32, offset: sdl.PointF) zmath.Mat {
    const m1 = zmath.scaling(scale.x, scale.y, 0);
    const m2 = zmath.translation(-anchor.x, -anchor.y, 0);
    const m3 = zmath.rotationZ(rotate * math.pi / 180);
    const m4 = zmath.translation(anchor.x, anchor.y, 0);
    const m5 = zmath.translation(offset.x, offset.y, 0);
    return zmath.mul(zmath.mul(zmath.mul(zmath.mul(m1, m2), m3), m4), m5);
}

// Transform coordinate
inline fn transformPoint(pos: sdl.PointF, trs: zmath.Mat) sdl.PointF {
    const v = zmath.f32x4(pos.x, pos.y, 0, 1);
    const tv = zmath.mul(v, trs);
    return .{ .x = tv[0], .y = tv[1] };
}

// Convert RGBA color
inline fn convertColor(color: sdl.Color) u32 {
    return @intCast(u32, color.r) |
        (@intCast(u32, color.g) << 8) |
        (@intCast(u32, color.b) << 16) |
        (@intCast(u32, color.a) << 24);
}
