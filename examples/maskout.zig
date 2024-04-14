const std = @import("std");
const jok = @import("jok");
const sdl = jok.sdl;
const font = jok.font;
const zmath = jok.zmath;
const imgui = jok.imgui;
const j2d = jok.j2d;

pub fn init(ctx: jok.Context) !void {
    std.log.info("game init", .{});
    _ = ctx;
}

pub fn event(ctx: jok.Context, e: sdl.Event) !void {
    _ = ctx;
    _ = e;
}

pub fn update(ctx: jok.Context) !void {
    _ = ctx;
}

pub fn draw(ctx: jok.Context) !void {
    ctx.clear(null);

    const csz = ctx.getCanvasSize();
    const center_x = csz.x / 2;
    const center_y = csz.y / 2;

    {
        j2d.begin(.{ .blend_method = .overwrite });
        defer j2d.end();

        try j2d.circleFilled(
            .{ .x = center_x, .y = center_y },
            200 * (1.0 + @sin(ctx.seconds())),
            sdl.Color.white,
            .{},
        );
    }

    {
        j2d.begin(.{ .blend_method = .modulate });
        defer j2d.end();

        var i: u32 = 0;
        while (i < 100) : (i += 1) {
            const row = @as(f32, @floatFromInt(i / 10)) - 5;
            const col = @as(f32, @floatFromInt(i % 10)) - 5;
            const offset_origin = jok.zmath.f32x4(row * 50, col * 50, 0, 1);
            const rotate_m = jok.zmath.matFromAxisAngle(
                jok.zmath.f32x4(center_x, center_y, 1, 0),
                ctx.seconds(),
            );
            const translate_m = jok.zmath.translation(center_x, center_y, 0);
            const offset_transformed = jok.zmath.mul(jok.zmath.mul(offset_origin, rotate_m), translate_m);

            j2d.getTransform().setToIdentity();
            j2d.getTransform().scale(.{
                .x = (1.3 + std.math.sin(ctx.seconds())) * ctx.getDpiScale(),
                .y = (1.3 + std.math.sin(ctx.seconds())) * ctx.getDpiScale(),
            });
            j2d.getTransform().rotateByOrigin(ctx.seconds());
            j2d.getTransform().translate(.{
                .x = offset_transformed[0],
                .y = offset_transformed[1],
            });
            try j2d.rectFilledMultiColor(
                .{ .x = -10, .y = -10, .width = 20, .height = 20 },
                sdl.Color.white,
                sdl.Color.red,
                sdl.Color.green,
                sdl.Color.blue,
                .{},
            );
        }
    }
}

pub fn quit(ctx: jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});
}
