const std = @import("std");
const builtin = @import("builtin");
const jok = @import("jok");
const physfs = jok.physfs;
const font = jok.font;
const j2d = jok.j2d;

pub const jok_window_size = jok.config.WindowSize{
    .custom = .{ .width = 800, .height = 750 },
};

var batchpool: j2d.BatchPool(64, false) = undefined;
var target: jok.Texture = undefined;
var src: jok.Texture = undefined;
var dst: jok.Texture = undefined;
const blends = [_]struct {
    blend: jok.BlendMode,
    pos: jok.Point,
    name: [:0]const u8,
}{
    .{ .blend = .none, .pos = .{ .x = 40, .y = 20 }, .name = @tagName(jok.BlendMode.none) },
    .{ .blend = .blend, .pos = .{ .x = 188, .y = 20 }, .name = @tagName(jok.BlendMode.blend) },
    .{ .blend = .additive, .pos = .{ .x = 336, .y = 20 }, .name = @tagName(jok.BlendMode.additive) },
    .{ .blend = .modulate, .pos = .{ .x = 484, .y = 20 }, .name = @tagName(jok.BlendMode.modulate) },
    .{ .blend = .multiply, .pos = .{ .x = 632, .y = 20 }, .name = @tagName(jok.BlendMode.multiply) },
    .{ .blend = .pd_src, .pos = .{ .x = 114, .y = 190 }, .name = @tagName(jok.BlendMode.pd_src) },
    .{ .blend = .pd_src_atop, .pos = .{ .x = 262, .y = 190 }, .name = @tagName(jok.BlendMode.pd_src_atop) },
    .{ .blend = .pd_src_over, .pos = .{ .x = 410, .y = 190 }, .name = @tagName(jok.BlendMode.pd_src_over) },
    .{ .blend = .pd_src_in, .pos = .{ .x = 558, .y = 190 }, .name = @tagName(jok.BlendMode.pd_src_in) },
    .{ .blend = .pd_src_out, .pos = .{ .x = 114, .y = 320 }, .name = @tagName(jok.BlendMode.pd_src_out) },
    .{ .blend = .pd_dst, .pos = .{ .x = 262, .y = 320 }, .name = @tagName(jok.BlendMode.pd_dst) },
    .{ .blend = .pd_dst_atop, .pos = .{ .x = 410, .y = 320 }, .name = @tagName(jok.BlendMode.pd_dst_atop) },
    .{ .blend = .pd_dst_over, .pos = .{ .x = 558, .y = 320 }, .name = @tagName(jok.BlendMode.pd_dst_over) },
    .{ .blend = .pd_dst_in, .pos = .{ .x = 114, .y = 450 }, .name = @tagName(jok.BlendMode.pd_dst_in) },
    .{ .blend = .pd_dst_out, .pos = .{ .x = 262, .y = 450 }, .name = @tagName(jok.BlendMode.pd_dst_out) },
    .{ .blend = .pd_xor, .pos = .{ .x = 410, .y = 450 }, .name = @tagName(jok.BlendMode.pd_xor) },
    .{ .blend = .pd_lighter, .pos = .{ .x = 558, .y = 450 }, .name = @tagName(jok.BlendMode.pd_lighter) },
    .{ .blend = .pd_clear, .pos = .{ .x = 114, .y = 580 }, .name = @tagName(jok.BlendMode.pd_clear) },
};

pub fn init(ctx: jok.Context) !void {
    std.log.info("game init", .{});

    if (!builtin.cpu.arch.isWasm()) {
        try physfs.mount("assets", "", true);
    }

    batchpool = try @TypeOf(batchpool).init(ctx);

    target = try ctx.renderer().createTarget(.{ .blend_mode = .blend });
    src = try ctx.renderer().createTextureFromFile(ctx.allocator(), "images/source.png", .static, false);
    dst = try ctx.renderer().createTextureFromFile(ctx.allocator(), "images/dest.png", .static, false);
}

pub fn event(ctx: jok.Context, e: jok.Event) !void {
    _ = ctx;
    _ = e;
}

pub fn update(ctx: jok.Context) !void {
    _ = ctx;
}

pub fn draw(ctx: jok.Context) !void {
    try ctx.renderer().clear(.rgb(170, 170, 170));

    // draw dest
    var batch = try batchpool.new(.{
        .offscreen_target = target,
        .offscreen_clear_color = .none,
    });
    for (blends) |b| {
        try batch.image(dst, b.pos, .{});
    }
    batch.submit();

    // draw source
    for (blends) |b| {
        batch = try batchpool.new(.{
            .offscreen_target = target,
            .blend_mode = b.blend,
        });
        try batch.image(src, b.pos, .{});
        batch.submit();
    }

    // draw labels
    {
        batch = try batchpool.new(.{});
        defer batch.submit();

        try batch.image(target, .{ .x = 0, .y = 0 }, .{});

        for (blends) |b| {
            try batch.text(
                "{s}",
                .{b.name},
                .{
                    .atlas = try font.DebugFont.getAtlas(ctx, 16),
                    .pos = .{ .x = b.pos.x, .y = b.pos.y + 112 },
                    .tint_color = .white,
                },
            );
        }

        try batch.rectRounded(
            .{ .x = 20, .y = 20, .width = 760, .height = 160 },
            .red,
            .{},
        );

        try batch.text(
            "Regular blending options",
            .{},
            .{
                .atlas = try font.DebugFont.getAtlas(ctx, 20),
                .pos = .{ .x = 520, .y = 155 },
                .tint_color = .red,
            },
        );

        try batch.rectRounded(
            .{ .x = 100, .y = 190, .width = 600, .height = 530 },
            .red,
            .{},
        );

        try batch.text(
            "Porter/Duff compositing options",
            .{},
            .{
                .atlas = try font.DebugFont.getAtlas(ctx, 20),
                .pos = .{ .x = 370, .y = 690 },
                .tint_color = .red,
            },
        );
    }
}

pub fn quit(ctx: jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});

    src.destroy();
    dst.destroy();
    batchpool.deinit();
}
