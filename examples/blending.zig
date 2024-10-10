const std = @import("std");
const jok = @import("jok");
const sdl = jok.sdl;
const physfs = jok.physfs;
const font = jok.font;
const j2d = jok.j2d;

pub const jok_window_size = jok.config.WindowSize{
    .custom = .{ .width = 800, .height = 750 },
};

var target: sdl.Texture = undefined;
var src: sdl.Texture = undefined;
var dst: sdl.Texture = undefined;
const blends = [_]struct {
    blend: jok.BlendMethod,
    pos: sdl.PointF,
    name: [:0]const u8,
}{
    .{ .blend = .none, .pos = .{ .x = 40, .y = 20 }, .name = @tagName(jok.BlendMethod.none) },
    .{ .blend = .blend, .pos = .{ .x = 188, .y = 20 }, .name = @tagName(jok.BlendMethod.blend) },
    .{ .blend = .additive, .pos = .{ .x = 336, .y = 20 }, .name = @tagName(jok.BlendMethod.additive) },
    .{ .blend = .modulate, .pos = .{ .x = 484, .y = 20 }, .name = @tagName(jok.BlendMethod.modulate) },
    .{ .blend = .multiply, .pos = .{ .x = 632, .y = 20 }, .name = @tagName(jok.BlendMethod.multiply) },
    .{ .blend = .pd_src, .pos = .{ .x = 114, .y = 190 }, .name = @tagName(jok.BlendMethod.pd_src) },
    .{ .blend = .pd_src_atop, .pos = .{ .x = 262, .y = 190 }, .name = @tagName(jok.BlendMethod.pd_src_atop) },
    .{ .blend = .pd_src_over, .pos = .{ .x = 410, .y = 190 }, .name = @tagName(jok.BlendMethod.pd_src_over) },
    .{ .blend = .pd_src_in, .pos = .{ .x = 558, .y = 190 }, .name = @tagName(jok.BlendMethod.pd_src_in) },
    .{ .blend = .pd_src_out, .pos = .{ .x = 114, .y = 320 }, .name = @tagName(jok.BlendMethod.pd_src_out) },
    .{ .blend = .pd_dst, .pos = .{ .x = 262, .y = 320 }, .name = @tagName(jok.BlendMethod.pd_dst) },
    .{ .blend = .pd_dst_atop, .pos = .{ .x = 410, .y = 320 }, .name = @tagName(jok.BlendMethod.pd_dst_atop) },
    .{ .blend = .pd_dst_over, .pos = .{ .x = 558, .y = 320 }, .name = @tagName(jok.BlendMethod.pd_dst_over) },
    .{ .blend = .pd_dst_in, .pos = .{ .x = 114, .y = 450 }, .name = @tagName(jok.BlendMethod.pd_dst_in) },
    .{ .blend = .pd_dst_out, .pos = .{ .x = 262, .y = 450 }, .name = @tagName(jok.BlendMethod.pd_dst_out) },
    .{ .blend = .pd_xor, .pos = .{ .x = 410, .y = 450 }, .name = @tagName(jok.BlendMethod.pd_xor) },
    .{ .blend = .pd_lighter, .pos = .{ .x = 558, .y = 450 }, .name = @tagName(jok.BlendMethod.pd_lighter) },
    .{ .blend = .pd_clear, .pos = .{ .x = 114, .y = 580 }, .name = @tagName(jok.BlendMethod.pd_clear) },
};

pub fn init(ctx: jok.Context) !void {
    std.log.info("game init", .{});

    try physfs.mount("assets", "", true);

    target = try jok.utils.gfx.createTextureAsTarget(ctx, .{ .blend_mode = .blend });
    src = try jok.utils.gfx.createTextureFromFile(ctx, "images/source.png", .static, false);
    dst = try jok.utils.gfx.createTextureFromFile(ctx, "images/dest.png", .static, false);
}

pub fn event(ctx: jok.Context, e: sdl.Event) !void {
    _ = ctx;
    _ = e;
}

pub fn update(ctx: jok.Context) !void {
    _ = ctx;
}

pub fn draw(ctx: jok.Context) !void {
    ctx.clear(sdl.Color.rgb(170, 170, 170));

    // draw dest
    j2d.begin(.{
        .offscreen_target = target,
        .offscreen_clear_color = sdl.Color.rgba(0, 0, 0, 0),
    });
    for (blends) |b| {
        try j2d.image(dst, b.pos, .{});
    }
    j2d.end();

    // draw source
    for (blends) |b| {
        j2d.begin(.{
            .offscreen_target = target,
            .blend_method = b.blend,
        });
        try j2d.image(src, b.pos, .{});
        j2d.end();
    }

    // draw labels
    {
        j2d.begin(.{});
        defer j2d.end();

        try j2d.image(target, .{ .x = 0, .y = 0 }, .{});

        for (blends) |b| {
            try j2d.text(
                .{
                    .atlas = try font.DebugFont.getAtlas(ctx, 16),
                    .pos = .{ .x = b.pos.x, .y = b.pos.y + 112 },
                    .tint_color = sdl.Color.white,
                },
                "{s}",
                .{b.name},
            );
        }

        try j2d.rectRounded(
            .{ .x = 20, .y = 20, .width = 760, .height = 160 },
            sdl.Color.red,
            .{},
        );

        try j2d.text(
            .{
                .atlas = try font.DebugFont.getAtlas(ctx, 20),
                .pos = .{ .x = 520, .y = 155 },
                .tint_color = sdl.Color.red,
            },
            "Regular blending options",
            .{},
        );

        try j2d.rectRounded(
            .{ .x = 100, .y = 190, .width = 600, .height = 530 },
            sdl.Color.red,
            .{},
        );

        try j2d.text(
            .{
                .atlas = try font.DebugFont.getAtlas(ctx, 20),
                .pos = .{ .x = 370, .y = 690 },
                .tint_color = sdl.Color.red,
            },
            "Porter/Duff compositing options",
            .{},
        );
    }
}

pub fn quit(ctx: jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});

    src.destroy();
    dst.destroy();
}
