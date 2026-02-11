const std = @import("std");
const builtin = @import("builtin");
const jok = @import("jok");
const geom = jok.geom;
const j2d = jok.j2d;
const j3d = jok.j3d;
const zgui = jok.vendor.zgui;
const physfs = jok.vendor.physfs;

pub const jok_window_size = jok.config.WindowSize.maximized;

var batchpool_2d: j2d.BatchPool(64, false) = undefined;
var image: jok.Texture = undefined;
var shader_param: ShaderParam = undefined;
var shaders: [@typeInfo(ShaderChoice).@"enum".fields.len]jok.PixelShader = undefined;
var shader_choice: ShaderChoice = .default;

const ShaderChoice = enum(u8) {
    default,
    chromaticberration,
    dissolve,
    lighting,
    water,
    ocean,

    fn getPath(s: ShaderChoice, cfg: jok.config.Config) [:0]const u8 {
        const prefix = if (cfg.jok_enable_physfs) "shaders/" else "assets/shaders/";
        const name = switch (s) {
            .default => "default",
            .chromaticberration => "chromaticberration",
            .dissolve => "dissolve",
            .lighting => "lighting",
            .water => "water",
            .ocean => "ocean",
        };
        const suffix = switch (builtin.os.tag) {
            .linux => ".spv",
            .windows => ".dxil",
            .macos => ".msl",
            else => unreachable,
        };
        return zgui.formatZ("{s}{s}{s}", .{ prefix, name, suffix });
    }

    fn getShader(s: ShaderChoice) jok.PixelShader {
        return shaders[@intFromEnum(s)];
    }
};

const ShaderParam = extern struct {
    resolution: geom.Point,
    cursor: geom.Point,
    time: f32,
    padding: [3]f32 = undefined,
};

pub fn init(ctx: jok.Context) !void {
    std.log.info("game init", .{});

    try physfs.mount("assets", "", true);

    batchpool_2d = try @TypeOf(batchpool_2d).init(ctx);

    image = try ctx.loadTexture(
        if (ctx.cfg().jok_enable_physfs)
            "shaders/jok.jpg"
        else
            "assets/shaders/jok.jpg",
        .static,
        false,
    );
    const info = try image.query();
    try ctx.setCanvasSize(.{ .width = info.width, .height = info.height });

    const type_info = @typeInfo(ShaderChoice);
    for (0..type_info.@"enum".fields.len) |i| {
        const shader_type: ShaderChoice = @enumFromInt(i);
        shaders[i] = try ctx.loadShader(
            shader_type.getPath(ctx.cfg()),
            null,
            null,
        );
    }
}

pub fn event(ctx: jok.Context, e: jok.Event) !void {
    _ = ctx;
    _ = e;
}

pub fn update(ctx: jok.Context) !void {
    _ = ctx;
}

pub fn draw(ctx: jok.Context) !void {
    try ctx.renderer().clear(.rgb(77, 77, 77));

    if (zgui.begin("Control Panel", .{ .flags = .{
        .always_auto_resize = true,
    } })) {
        _ = zgui.comboFromEnum("shader", &shader_choice);
    }
    zgui.end();

    const shader = shader_choice.getShader();
    const mouse = jok.io.getMouseState(ctx);
    shader_param = .{
        .resolution = ctx.getCanvasSize().toPoint(),
        .cursor = mouse.pos,
        .time = ctx.seconds(),
    };
    try shader.setUniform(0, shader_param);

    var b = try batchpool_2d.new(.{ .shader = shader });
    defer b.submit();
    try b.image(image, .origin, .{});
}

pub fn quit(ctx: jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});
    for (shaders) |s| s.destroy();
    image.destroy();
    batchpool_2d.deinit();
}
