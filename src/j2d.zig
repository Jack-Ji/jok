const std = @import("std");
const assert = std.debug.assert;
const math = std.math;
const unicode = std.unicode;
const sdl = @import("sdl");
const jok = @import("jok.zig");
const imgui = jok.imgui;
const zmath = jok.zmath;
const zmesh = jok.zmesh;

const dc = @import("j2d/command.zig");
const Atlas = @import("font/Atlas.zig");
pub const AffineTransform = @import("j2d/AffineTransform.zig");
pub const Sprite = @import("j2d/Sprite.zig");
pub const SpriteSheet = @import("j2d/SpriteSheet.zig");
pub const ParticleSystem = @import("j2d/ParticleSystem.zig");
pub const AnimationSystem = @import("j2d/AnimationSystem.zig");
pub const Scene = @import("j2d/Scene.zig");
pub const Vector = @import("j2d/Vector.zig");

pub const Error = error{
    PathNotFinished,
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
    transform: AffineTransform = AffineTransform.init(),
    depth_sort: DepthSortMethod = .none,
    blend_method: BlendMethod = .blend,
    antialiased: bool = true,
};

var arena: std.heap.ArenaAllocator = undefined;
var rd: sdl.Renderer = undefined;
var draw_list: imgui.DrawList = undefined;
var draw_commands: std.ArrayList(dc.DrawCmd) = undefined;
var transform: AffineTransform = undefined;
var depth_sort: DepthSortMethod = undefined;
var blend_method: BlendMethod = undefined;
var all_tex: std.AutoHashMap(*sdl.c.SDL_Texture, bool) = undefined;

pub fn init(allocator: std.mem.Allocator, _rd: sdl.Renderer) !void {
    arena = std.heap.ArenaAllocator.init(allocator);
    rd = _rd;
    draw_list = imgui.createDrawList();
    draw_commands = std.ArrayList(dc.DrawCmd).init(allocator);
    all_tex = std.AutoHashMap(*sdl.c.SDL_Texture, bool).init(allocator);
}

pub fn deinit() void {
    arena.deinit();
    imgui.destroyDrawList(draw_list);
    draw_commands.deinit();
    all_tex.deinit();
}

pub fn begin(opt: BeginOption) !void {
    draw_list.reset();
    draw_list.pushClipRectFullScreen();
    draw_list.pushTextureId(imgui.io.getFontsTexId());
    draw_commands.clearRetainingCapacity();
    all_tex.clearRetainingCapacity();
    transform = opt.transform;
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
    const S = struct {
        fn ascendCompare(_: ?*anyopaque, lhs: dc.DrawCmd, rhs: dc.DrawCmd) bool {
            return lhs.depth < rhs.depth;
        }
        fn descendCompare(_: ?*anyopaque, lhs: dc.DrawCmd, rhs: dc.DrawCmd) bool {
            return lhs.depth > rhs.depth;
        }
    };

    if (draw_commands.items.len == 0) return;

    switch (depth_sort) {
        .none => {},
        .back_to_forth => std.sort.sort(
            dc.DrawCmd,
            draw_commands.items,
            @as(?*anyopaque, null),
            S.descendCompare,
        ),
        .forth_to_back => std.sort.sort(
            dc.DrawCmd,
            draw_commands.items,
            @as(?*anyopaque, null),
            S.ascendCompare,
        ),
    }
    for (draw_commands.items) |dcmd| {
        switch (dcmd.cmd) {
            .image => |c| try all_tex.put(c.texture.ptr, true),
            .image_rounded => |c| try all_tex.put(c.texture.ptr, true),
            .quad_image => |c| try all_tex.put(c.texture.ptr, true),
            else => {},
        }
        try dcmd.render(draw_list);
    }
    const mode = switch (blend_method) {
        .blend => sdl.c.SDL_BLENDMODE_BLEND,
        .additive => sdl.c.SDL_BLENDMODE_ADD,
        .overwrite => sdl.c.SDL_BLENDMODE_NONE,
    };
    var it = all_tex.keyIterator();
    while (it.next()) |k| {
        _ = sdl.c.SDL_SetTextureBlendMode(k.*, @intCast(c_uint, mode));
    }
    try imgui.sdl.renderDrawList(rd, draw_list);
}

pub fn clearMemory() void {
    draw_list.clearMemory();
    draw_commands.clearAndFree();
    all_tex.clearAndFree();
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

pub fn setTransform(t: AffineTransform) void {
    transform = t;
}

pub fn getTransform() *AffineTransform {
    return &transform;
}

pub const AddImage = struct {
    uv0: sdl.PointF = .{ .x = 0, .y = 0 },
    uv1: sdl.PointF = .{ .x = 1, .y = 1 },
    tint_color: sdl.Color = sdl.Color.white,
    scale: sdl.PointF = .{ .x = 1, .y = 1 },
    rotate_degree: f32 = 0,
    anchor_point: sdl.PointF = .{ .x = 0, .y = 0 },
    flip_h: bool = false,
    flip_v: bool = false,
    depth: f32 = 0.5,
};
pub fn addImage(texture: sdl.Texture, rect: sdl.RectangleF, opt: AddImage) !void {
    const scale = transform.getScale();
    const pos = transform.transformPoint(.{ .x = rect.x, .y = rect.y });
    const sprite = Sprite{
        .width = rect.width,
        .height = rect.height,
        .uv0 = opt.uv0,
        .uv1 = opt.uv1,
        .tex = texture,
    };
    try sprite.render(&draw_commands, .{
        .pos = pos,
        .tint_color = opt.tint_color,
        .scale = .{ .x = scale.x * opt.scale.x, .y = scale.y * opt.scale.y },
        .rotate_degree = opt.rotate_degree,
        .anchor_point = opt.anchor_point,
        .flip_h = opt.flip_h,
        .flip_v = opt.flip_v,
        .depth = opt.depth,
    });
}

/// NOTE: Rounded image is always axis-aligned
pub const AddImageRounded = struct {
    uv0: sdl.PointF = .{ .x = 0, .y = 0 },
    uv1: sdl.PointF = .{ .x = 1, .y = 1 },
    tint_color: sdl.Color = sdl.Color.white,
    scale: sdl.PointF = .{ .x = 1, .y = 1 },
    flip_h: bool = false,
    flip_v: bool = false,
    rounding: f32 = 4,
    depth: f32 = 0.5,
};
pub fn addImageRounded(texture: sdl.Texture, rect: sdl.RectangleF, opt: AddImageRounded) !void {
    const scale = transform.getScale();
    const pmin = transform.transformPoint(.{ .x = rect.x, .y = rect.y });
    const pmax = sdl.PointF{
        .x = pmin.x + rect.width * scale.x,
        .y = pmin.y + rect.height * scale.y,
    };
    var uv0 = opt.uv0;
    var uv1 = opt.uv1;
    if (opt.flip_h) std.mem.swap(f32, &uv0.x, &uv1.x);
    if (opt.flip_v) std.mem.swap(f32, &uv0.y, &uv1.y);
    try draw_commands.append(.{
        .cmd = .{
            .image_rounded = .{
                .texture = texture,
                .pmin = pmin,
                .pmax = pmax,
                .uv0 = uv0,
                .uv1 = uv1,
                .rounding = opt.rounding,
                .tint_color = imgui.sdl.convertColor(opt.tint_color),
            },
        },
        .depth = opt.depth,
    });
}

pub fn addScene(scene: *const Scene) !void {
    try scene.render(&draw_commands, .{ .transform = transform });
}

pub fn addEffects(ps: *const ParticleSystem) !void {
    for (ps.effects.items) |eff| {
        try eff.render(&draw_commands, .{ .transform = transform });
    }
}

pub const AddSprite = struct {
    pos: sdl.PointF,
    tint_color: sdl.Color = sdl.Color.white,
    scale: sdl.PointF = .{ .x = 1, .y = 1 },
    rotate_degree: f32 = 0,
    anchor_point: sdl.PointF = .{ .x = 0, .y = 0 },
    flip_h: bool = false,
    flip_v: bool = false,
    depth: f32 = 0.5,
};
pub fn addSprite(sprite: Sprite, opt: AddSprite) !void {
    const scale = transform.getScale();
    try sprite.render(&draw_commands, .{
        .pos = transform.transformPoint(opt.pos),
        .tint_color = opt.tint_color,
        .scale = .{ .x = scale.x * opt.scale.x, .y = scale.y * opt.scale.y },
        .rotate_degree = opt.rotate_degree,
        .anchor_point = opt.anchor_point,
        .flip_h = opt.flip_h,
        .flip_v = opt.flip_v,
        .depth = opt.depth,
    });
}

pub const AddText = struct {
    atlas: Atlas,
    pos: sdl.PointF,
    ypos_type: Atlas.YPosType = .top,
    tint_color: sdl.Color = sdl.Color.white,
    scale: sdl.PointF = .{ .x = 1, .y = 1 },
    rotate_degree: f32 = 0,
    anchor_point: sdl.PointF = .{ .x = 0, .y = 0 },
    depth: f32 = 0.5,
};
pub fn addText(opt: AddText, comptime fmt: []const u8, args: anytype) !void {
    const text = jok.imgui.format(fmt, args);
    if (text.len == 0) return;

    var pos = transform.transformPoint(opt.pos);
    var scale = transform.getScale();
    scale.x *= opt.scale.x;
    scale.y *= opt.scale.y;
    const angle = jok.utils.math.degreeToRadian(opt.rotate_degree);
    const mat = zmath.mul(
        zmath.mul(
            zmath.translation(-pos.x, -pos.y, 0),
            zmath.rotationZ(angle),
        ),
        zmath.translation(pos.x, pos.y, 0),
    );
    var i: u32 = 0;
    while (i < text.len) {
        const size = try unicode.utf8ByteSequenceLength(text[i]);
        const cp = @intCast(u32, try unicode.utf8Decode(text[i .. i + size]));
        if (opt.atlas.getVerticesOfCodePoint(pos, opt.ypos_type, sdl.Color.white, cp)) |cs| {
            const v = zmath.mul(
                zmath.f32x4(
                    cs.vs[0].position.x,
                    pos.y + (cs.vs[0].position.y - pos.y) * scale.y,
                    0,
                    1,
                ),
                mat,
            );
            const draw_pos = sdl.PointF{ .x = v[0], .y = v[1] };
            const sprite = Sprite{
                .width = cs.vs[1].position.x - cs.vs[0].position.x,
                .height = cs.vs[3].position.y - cs.vs[0].position.y,
                .uv0 = cs.vs[0].tex_coord,
                .uv1 = cs.vs[2].tex_coord,
                .tex = opt.atlas.tex,
            };
            try sprite.render(&draw_commands, .{
                .pos = draw_pos,
                .tint_color = opt.tint_color,
                .scale = scale,
                .rotate_degree = opt.rotate_degree,
                .anchor_point = opt.anchor_point,
                .depth = opt.depth,
            });
            pos.x += (cs.next_x - pos.x) * scale.x;
        }
        i += size;
    }
}

pub const AddLine = struct {
    thickness: f32 = 1.0,
    depth: f32 = 0.5,
};
pub fn addLine(p1: sdl.PointF, p2: sdl.PointF, color: sdl.Color, opt: AddLine) !void {
    try draw_commands.append(.{
        .cmd = .{
            .line = .{
                .p1 = transform.transformPoint(p1),
                .p2 = transform.transformPoint(p2),
                .color = imgui.sdl.convertColor(color),
                .thickness = opt.thickness,
            },
        },
        .depth = opt.depth,
    });
}

/// NOTE: Rectangle is always axis-aligned
pub const AddRect = struct {
    thickness: f32 = 1.0,
    rounding: f32 = 0,
    depth: f32 = 0.5,
};
pub fn addRect(rect: sdl.RectangleF, color: sdl.Color, opt: AddRect) !void {
    const scale = transform.getScale();
    const pmin = transform.transformPoint(.{ .x = rect.x, .y = rect.y });
    const pmax = sdl.PointF{
        .x = pmin.x + rect.width * scale.x,
        .y = pmin.y + rect.height * scale.y,
    };
    try draw_commands.append(.{
        .cmd = .{
            .rect = .{
                .pmin = pmin,
                .pmax = pmax,
                .color = imgui.sdl.convertColor(color),
                .thickness = opt.thickness,
                .rounding = opt.rounding,
            },
        },
        .depth = opt.depth,
    });
}

/// NOTE: Rectangle is always axis-aligned
pub const FillRect = struct {
    rounding: f32 = 0,
    depth: f32 = 0.5,
};
pub fn addRectFilled(rect: sdl.RectangleF, color: sdl.Color, opt: FillRect) !void {
    const scale = transform.getScale();
    const pmin = transform.transformPoint(.{ .x = rect.x, .y = rect.y });
    const pmax = sdl.PointF{
        .x = pmin.x + rect.width * scale.x,
        .y = pmin.y + rect.height * scale.y,
    };
    try draw_commands.append(.{
        .cmd = .{
            .rect_fill = .{
                .pmin = pmin,
                .pmax = pmax,
                .color = imgui.sdl.convertColor(color),
                .rounding = opt.rounding,
            },
        },
        .depth = opt.depth,
    });
}

/// NOTE: Rectangle is always axis-aligned
pub const FillRectMultiColor = struct {
    depth: f32 = 0.5,
};
pub fn addRectFilledMultiColor(
    rect: sdl.RectangleF,
    color_top_left: sdl.Color,
    color_top_right: sdl.Color,
    color_bottom_right: sdl.Color,
    color_bottom_left: sdl.Color,
    opt: FillRectMultiColor,
) !void {
    const scale = transform.getScale();
    const pmin = transform.transformPoint(.{ .x = rect.x, .y = rect.y });
    const pmax = sdl.PointF{
        .x = pmin.x + rect.width * scale.x,
        .y = pmin.y + rect.height * scale.y,
    };
    try draw_commands.append(.{
        .cmd = .{
            .rect_fill_multicolor = .{
                .pmin = pmin,
                .pmax = pmax,
                .color_ul = imgui.sdl.convertColor(color_top_left),
                .color_ur = imgui.sdl.convertColor(color_top_right),
                .color_br = imgui.sdl.convertColor(color_bottom_right),
                .color_bl = imgui.sdl.convertColor(color_bottom_left),
            },
        },
        .depth = opt.depth,
    });
}

pub const AddQuad = struct {
    thickness: f32 = 1.0,
    depth: f32 = 0.5,
};
pub fn addQuad(
    p1: sdl.PointF,
    p2: sdl.PointF,
    p3: sdl.PointF,
    p4: sdl.PointF,
    color: sdl.Color,
    opt: AddQuad,
) !void {
    try draw_commands.append(.{
        .cmd = .{
            .quad = .{
                .p1 = transform.transformPoint(p1),
                .p2 = transform.transformPoint(p2),
                .p3 = transform.transformPoint(p3),
                .p4 = transform.transformPoint(p4),
                .color = imgui.sdl.convertColor(color),
                .thickness = opt.thickness,
            },
        },
        .depth = opt.depth,
    });
}

pub const FillQuad = struct {
    depth: f32 = 0.5,
};
pub fn addQuadFilled(
    p1: sdl.PointF,
    p2: sdl.PointF,
    p3: sdl.PointF,
    p4: sdl.PointF,
    color: sdl.Color,
    opt: FillQuad,
) !void {
    try draw_commands.append(.{
        .cmd = .{
            .quad_fill = .{
                .p1 = transform.transformPoint(p1),
                .p2 = transform.transformPoint(p2),
                .p3 = transform.transformPoint(p3),
                .p4 = transform.transformPoint(p4),
                .color = imgui.sdl.convertColor(color),
            },
        },
        .depth = opt.depth,
    });
}

pub const AddTriangle = struct {
    thickness: f32 = 1.0,
    depth: f32 = 0.5,
};
pub fn addTriangle(
    p1: sdl.PointF,
    p2: sdl.PointF,
    p3: sdl.PointF,
    color: sdl.Color,
    opt: AddTriangle,
) !void {
    try draw_commands.append(.{
        .cmd = .{
            .triangle = .{
                .p1 = transform.transformPoint(p1),
                .p2 = transform.transformPoint(p2),
                .p3 = transform.transformPoint(p3),
                .color = imgui.sdl.convertColor(color),
                .thickness = opt.thickness,
            },
        },
        .depth = opt.depth,
    });
}

pub const FillTriangle = struct {
    depth: f32 = 0.5,
};
pub fn addTriangleFilled(
    p1: sdl.PointF,
    p2: sdl.PointF,
    p3: sdl.PointF,
    color: sdl.Color,
    opt: FillTriangle,
) !void {
    try draw_commands.append(.{
        .cmd = .{
            .triangle_fill = .{
                .p1 = transform.transformPoint(p1),
                .p2 = transform.transformPoint(p2),
                .p3 = transform.transformPoint(p3),
                .color = imgui.sdl.convertColor(color),
            },
        },
        .depth = opt.depth,
    });
}

pub const AddCircle = struct {
    thickness: f32 = 1.0,
    num_segments: u32 = 0,
    depth: f32 = 0.5,
};
pub fn addCircle(
    center: sdl.PointF,
    radius: f32,
    color: sdl.Color,
    opt: AddCircle,
) !void {
    const scale = transform.getScale();
    try draw_commands.append(.{
        .cmd = .{
            .circle = .{
                .p = transform.transformPoint(center),
                .radius = radius * scale.x,
                .color = imgui.sdl.convertColor(color),
                .thickness = opt.thickness,
                .num_segments = opt.num_segments,
            },
        },
        .depth = opt.depth,
    });
}

pub const FillCircle = struct {
    num_segments: u32 = 0,
    depth: f32 = 0.5,
};
pub fn addCircleFilled(
    center: sdl.PointF,
    radius: f32,
    color: sdl.Color,
    opt: FillCircle,
) !void {
    const scale = transform.getScale();
    try draw_commands.append(.{
        .cmd = .{
            .circle_fill = .{
                .p = transform.transformPoint(center),
                .radius = radius * scale.x,
                .color = imgui.sdl.convertColor(color),
                .num_segments = opt.num_segments,
            },
        },
        .depth = opt.depth,
    });
}

pub const AddNgon = struct {
    thickness: f32 = 1.0,
    depth: f32 = 0.5,
};
pub fn addNgon(
    center: sdl.PointF,
    radius: f32,
    color: sdl.Color,
    num_segments: u32,
    opt: AddNgon,
) !void {
    const scale = transform.getScale();
    try draw_commands.append(.{
        .cmd = .{
            .ngon = .{
                .p = transform.transformPoint(center),
                .radius = radius * scale.x,
                .color = imgui.sdl.convertColor(color),
                .thickness = opt.thickness,
                .num_segments = num_segments,
            },
        },
        .depth = opt.depth,
    });
}

pub const FillNgon = struct {
    depth: f32 = 0.5,
};
pub fn addNgonFilled(
    center: sdl.PointF,
    radius: f32,
    color: sdl.Color,
    num_segments: u32,
    opt: FillNgon,
) !void {
    const scale = transform.getScale();
    try draw_commands.append(.{
        .cmd = .{
            .ngon_fill = .{
                .p = transform.transformPoint(center),
                .radius = radius * scale.x,
                .color = imgui.sdl.convertColor(color),
                .num_segments = num_segments,
            },
        },
        .depth = opt.depth,
    });
}

pub const AddBezierCubic = struct {
    thickness: f32 = 1.0,
    num_segments: u32 = 0,
    depth: f32 = 0.5,
};
pub fn addBezierCubic(
    p1: sdl.PointF,
    p2: sdl.PointF,
    p3: sdl.PointF,
    p4: sdl.PointF,
    color: sdl.Color,
    opt: AddBezierCubic,
) !void {
    try draw_commands.append(.{
        .cmd = .{
            .bezier_cubic = .{
                .p1 = transform.transformPoint(p1),
                .p2 = transform.transformPoint(p2),
                .p3 = transform.transformPoint(p3),
                .p4 = transform.transformPoint(p4),
                .color = imgui.sdl.convertColor(color),
                .thickness = opt.thickness,
                .num_segments = opt.num_segments,
            },
        },
        .depth = opt.depth,
    });
}

pub const AddBezierQuadratic = struct {
    thickness: f32 = 1.0,
    num_segments: u32 = 0,
    depth: f32 = 0.5,
};
pub fn addBezierQuadratic(
    p1: sdl.PointF,
    p2: sdl.PointF,
    p3: sdl.PointF,
    color: sdl.Color,
    opt: AddBezierQuadratic,
) !void {
    try draw_commands.append(.{
        .cmd = .{
            .bezier_quadratic = .{
                .p1 = transform.transformPoint(p1),
                .p2 = transform.transformPoint(p2),
                .p3 = transform.transformPoint(p3),
                .color = imgui.sdl.convertColor(color),
                .thickness = opt.thickness,
                .num_segments = opt.num_segments,
            },
        },
        .depth = opt.depth,
    });
}

pub const AddPoly = struct {
    thickness: f32 = 1.0,
    depth: f32 = 0.5,
};
pub fn addConvexPoly(poly: ConvexPoly, color: sdl.Color, opt: AddPoly) !void {
    if (!poly.finished) return error.PathNotFinished;
    try draw_commands.append(.{
        .cmd = .{
            .convex_polygon = .{
                .points = poly.points,
                .color = imgui.sdl.convertColor(color),
                .thickness = opt.thickness,
                .transform = transform,
            },
        },
        .depth = opt.depth,
    });
}

pub const FillPoly = struct {
    depth: f32 = 0.5,
};
pub fn addConvexPolyFilled(poly: ConvexPoly, opt: FillPoly) !void {
    if (!poly.finished) return error.PathNotFinished;
    try draw_commands.append(.{
        .cmd = .{
            .convex_polygon_fill = .{
                .points = poly.points,
                .texture = poly.texture,
                .transform = transform,
            },
        },
        .depth = opt.depth,
    });
}

pub const ConvexPoly = struct {
    texture: ?sdl.Texture,
    points: std.ArrayList(sdl.Vertex),
    finished: bool = false,

    pub fn begin(allocator: std.mem.Allocator, texture: ?sdl.Texture) ConvexPoly {
        return .{
            .texture = texture,
            .points = std.ArrayList(sdl.Vertex).init(allocator),
        };
    }

    pub fn end(self: *ConvexPoly) void {
        self.finished = true;
    }

    pub fn deinit(self: *ConvexPoly) void {
        self.points.deinit();
        self.* = undefined;
    }

    pub fn reset(self: *ConvexPoly, texture: ?sdl.Texture) void {
        self.texture = texture;
        self.points.clearRetainingCapacity();
        self.finished = false;
    }

    pub fn addPoint(self: *ConvexPoly, p: sdl.Vertex) !void {
        try self.cmd.points.append(p);
    }

    pub fn addNPoints(self: *ConvexPoly, ps: []sdl.Vertex) !void {
        try self.cmd.points.appendSlice(ps);
    }
};

pub const AddPath = struct {
    depth: f32 = 0.5,
};
pub fn addPath(path: Path, opt: AddPath) !void {
    if (!path.finished) return error.PathNotFinished;
    var rpath = path.path;
    rpath.transform = transform;
    try draw_commands.append(.{
        .cmd = .{ .path = rpath },
        .depth = opt.depth,
    });
}

pub const Path = struct {
    path: dc.PathCmd,
    finished: bool = false,

    /// Begin definition of path
    pub fn begin(allocator: std.mem.Allocator) Path {
        return .{
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
        self.path.deinit();
        self.* = undefined;
    }

    pub fn reset(self: *Path) void {
        self.path.cmds.clearRetainingCapacity();
        self.finished = false;
    }

    pub fn lineTo(self: *Path, pos: sdl.PointF) !void {
        try self.path.cmds.append(.{ .line_to = .{ .p = pos } });
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
                .p = pos,
                .radius = radius,
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
    ) !void {
        try self.path.cmds.append(.{
            .bezier_cubic_to = .{
                .p2 = p2,
                .p3 = p3,
                .p4 = p4,
                .num_segments = opt.num_segments,
            },
        });
    }
    pub fn bezierQuadraticCurveTo(
        self: *Path,
        p2: sdl.PointF,
        p3: sdl.PointF,
        opt: BezierCurveTo,
    ) !void {
        try self.path.cmds.append(.{
            .bezier_quadratic_to = .{
                .p2 = p2,
                .p3 = p3,
                .num_segments = opt.num_segments,
            },
        });
    }

    /// NOTE: Rectangle is always axis-aligned
    pub const Rect = struct {
        rounding: f32 = 0,
    };
    pub fn rect(
        self: *Path,
        r: sdl.RectangleF,
        opt: Rect,
    ) !void {
        const pmin = sdl.PointF{ .x = r.x, .y = r.y };
        const pmax = sdl.PointF{
            .x = pmin.x + r.width,
            .y = pmin.y + r.height,
        };
        try self.path.cmds.append(.{
            .rect = .{
                .pmin = pmin,
                .pmax = pmax,
                .rounding = opt.rounding,
            },
        });
    }
};
