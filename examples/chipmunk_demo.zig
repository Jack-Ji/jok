const std = @import("std");
const sdl = @import("sdl");
const jok = @import("jok");
const cp = jok.deps.chipmunk;

var rng: std.rand.Xoshiro256 = undefined;
var world: cp.World = undefined;

pub fn init(ctx: *jok.Context) anyerror!void {
    std.log.info("game init", .{});

    rng = std.rand.DefaultPrng.init(
        @intCast(u64, std.time.timestamp()),
    );

    const size = ctx.getFramebufferSize();

    world = try cp.World.init(ctx.allocator, .{
        .gravity = .{ .x = 0, .y = 600 },
    });

    const dynamic_body: cp.World.ObjectOption.BodyProperty = .{
        .dynamic = .{
            .position = .{
                .x = @intToFloat(f32, size.w) / 2,
                .y = 10,
            },
        },
    };
    const physics: cp.World.ObjectOption.ShapeProperty.Physics = .{
        .weight = .{ .mass = 1 },
        .elasticity = 0.5,
    };
    var i: u32 = 0;
    while (i < 300) : (i += 1) {
        const t = rng.random().intRangeAtMost(u32, 0, 30);
        if (t < 10) {
            _ = try world.addObject(.{
                .body = dynamic_body,
                .shapes = &.{
                    .{
                        .circle = .{
                            .radius = 15,
                            .physics = physics,
                        },
                    },
                },
            });
        } else if (t < 20) {
            _ = try world.addObject(.{
                .body = dynamic_body,
                .shapes = &.{
                    .{
                        .box = .{
                            .width = 30,
                            .height = 30,
                            .physics = physics,
                        },
                    },
                },
            });
        } else {
            _ = try world.addObject(.{
                .body = dynamic_body,
                .shapes = &.{
                    .{
                        .polygon = .{
                            .verts = &[_]cp.c.cpVect{
                                .{ .x = 0, .y = 0 },
                                .{ .x = 30, .y = 0 },
                                .{ .x = 35, .y = 25 },
                                .{ .x = 30, .y = 50 },
                            },
                            .physics = physics,
                        },
                    },
                },
            });
        }
    }
    _ = try world.addObject(.{
        .body = .{
            .kinematic = .{
                .position = .{ .x = 400, .y = 400 },
                .angular_velocity = std.math.pi / 4.0,
            },
        },
        .shapes = &[_]cp.World.ObjectOption.ShapeProperty{
            .{
                .segment = .{
                    .a = .{ .x = -100, .y = 0 },
                    .b = .{ .x = 100, .y = 0 },
                    .radius = 10,
                    .physics = .{
                        .weight = .{ .mass = 0 },
                        .elasticity = 1.0,
                    },
                },
            },
        },
    });
    _ = try world.addObject(.{
        .body = .global_static,
        .shapes = &[_]cp.World.ObjectOption.ShapeProperty{
            .{
                .segment = .{
                    .a = .{ .x = 250, .y = 450 },
                    .b = .{ .x = 700, .y = 350 },
                    .radius = 10,
                    .physics = .{
                        .elasticity = 1.0,
                    },
                },
            },
        },
    });
    _ = try world.addObject(.{
        .body = .global_static,
        .shapes = &[_]cp.World.ObjectOption.ShapeProperty{
            .{
                .segment = .{
                    .a = .{ .x = 0, .y = 0 },
                    .b = .{ .x = 0, .y = @intToFloat(f32, size.h) },
                    .physics = .{
                        .elasticity = 1.0,
                    },
                },
            },
            .{
                .segment = .{
                    .a = .{ .x = 0, .y = @intToFloat(f32, size.h) },
                    .b = .{ .x = @intToFloat(f32, size.w), .y = @intToFloat(f32, size.h) },
                    .physics = .{
                        .elasticity = 1.0,
                    },
                },
            },
            .{
                .segment = .{
                    .a = .{ .x = @intToFloat(f32, size.w), .y = 0 },
                    .b = .{ .x = @intToFloat(f32, size.w), .y = @intToFloat(f32, size.h) },
                    .physics = .{
                        .elasticity = 1.0,
                    },
                },
            },
        },
    });
}

pub fn event(ctx: *jok.Context, e: sdl.Event) anyerror!void {
    _ = ctx;
    _ = e;
}

pub fn update(ctx: *jok.Context) anyerror!void {
    world.update(ctx.delta_tick);
}

pub fn draw(ctx: *jok.Context) anyerror!void {
    try world.debugDraw(ctx.renderer);
}

pub fn quit(ctx: *jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});
    world.deinit();
}
