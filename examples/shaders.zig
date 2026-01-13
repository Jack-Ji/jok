const std = @import("std");
const builtin = @import("builtin");
const jok = @import("jok");
const j2d = jok.j2d;
const j3d = jok.j3d;
const zgui = jok.vendor.zgui;
const physfs = jok.vendor.physfs;

pub const jok_window_size = jok.config.WindowSize.maximized;

var batchpool_2d: j2d.BatchPool(64, false) = undefined;
var image: jok.Texture = undefined;
var shader_param: ShaderParam = undefined;
var shader_default: jok.PixelShader = undefined;
var shader_chromaticberration: jok.PixelShader = undefined;
var shader_dissolve: jok.PixelShader = undefined;
var shader_lighting: jok.PixelShader = undefined;
var shader_water: jok.PixelShader = undefined;
var shader_ocean: jok.PixelShader = undefined;
var shader_choice: ShaderChoice = .default;

const ShaderChoice = enum {
    default,
    chromaticberration,
    dissolve,
    lighting,
    water,
    ocean,

    fn getShader(s: ShaderChoice) jok.PixelShader {
        return switch (s) {
            .default => shader_default,
            .chromaticberration => shader_chromaticberration,
            .dissolve => shader_dissolve,
            .lighting => shader_lighting,
            .water => shader_water,
            .ocean => shader_ocean,
        };
    }
};

const ShaderParam = extern struct {
    resolution: jok.Point,
    cursor: jok.Point,
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

    shader_default = try ctx.loadShader(
        if (ctx.cfg().jok_enable_physfs)
            switch (builtin.os.tag) {
                .windows => "shaders/default.dxil",
                .macos => "shaders/default.msl",
                .linux => "shaders/default.spv",
                else => unreachable,
            }
        else switch (builtin.os.tag) {
            .windows => "assets/shaders/default.dxil",
            .macos => "assets/shaders/default.msl",
            .linux => "assets/shaders/default.spv",
            else => unreachable,
        },
        null,
        null,
    );

    shader_chromaticberration = try ctx.loadShader(
        if (ctx.cfg().jok_enable_physfs)
            switch (builtin.os.tag) {
                .windows => "shaders/chromaticberration.dxil",
                .macos => "shaders/chromaticberration.msl",
                .linux => "shaders/chromaticberration.spv",
                else => unreachable,
            }
        else switch (builtin.os.tag) {
            .windows => "assets/shaders/chromaticberration.dxil",
            .macos => "assets/shaders/chromaticberration.msl",
            .linux => "assets/shaders/chromaticberration.spv",
            else => unreachable,
        },
        null,
        null,
    );

    shader_dissolve = try ctx.loadShader(
        if (ctx.cfg().jok_enable_physfs)
            switch (builtin.os.tag) {
                .windows => "shaders/dissolve.dxil",
                .macos => "shaders/dissolve.msl",
                .linux => "shaders/dissolve.spv",
                else => unreachable,
            }
        else switch (builtin.os.tag) {
            .windows => "assets/shaders/dissolve.dxil",
            .macos => "assets/shaders/dissolve.msl",
            .linux => "assets/shaders/dissolve.spv",
            else => unreachable,
        },
        null,
        null,
    );

    shader_lighting = try ctx.loadShader(
        if (ctx.cfg().jok_enable_physfs)
            switch (builtin.os.tag) {
                .windows => "shaders/lighting.dxil",
                .macos => "shaders/lighting.msl",
                .linux => "shaders/lighting.spv",
                else => unreachable,
            }
        else switch (builtin.os.tag) {
            .windows => "assets/shaders/lighting.dxil",
            .macos => "assets/shaders/lighting.msl",
            .linux => "assets/shaders/lighting.spv",
            else => unreachable,
        },
        null,
        null,
    );

    shader_water = try ctx.loadShader(
        if (ctx.cfg().jok_enable_physfs)
            switch (builtin.os.tag) {
                .windows => "shaders/water.dxil",
                .macos => "shaders/water.msl",
                .linux => "shaders/water.spv",
                else => unreachable,
            }
        else switch (builtin.os.tag) {
            .windows => "assets/shaders/water.dxil",
            .macos => "assets/shaders/water.msl",
            .linux => "assets/shaders/water.spv",
            else => unreachable,
        },
        null,
        null,
    );

    shader_ocean = try ctx.loadShader(
        if (ctx.cfg().jok_enable_physfs)
            switch (builtin.os.tag) {
                .windows => "shaders/ocean.dxil",
                .macos => "shaders/ocean.msl",
                .linux => "shaders/ocean.spv",
                else => unreachable,
            }
        else switch (builtin.os.tag) {
            .windows => "assets/shaders/ocean.dxil",
            .macos => "assets/shaders/ocean.msl",
            .linux => "assets/shaders/ocean.spv",
            else => unreachable,
        },
        null,
        null,
    );
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
    shader_default.destroy();
    shader_chromaticberration.destroy();
    shader_dissolve.destroy();
    shader_lighting.destroy();
    shader_water.destroy();
    image.destroy();
    batchpool_2d.deinit();
}
