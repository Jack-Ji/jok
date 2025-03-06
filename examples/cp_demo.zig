const std = @import("std");
const jok = @import("jok");
const cp = jok.cp;

var rng: std.Random.Xoshiro256 = undefined;
var world: cp.World = undefined;

pub fn init(ctx: jok.Context) !void {
    std.log.info("game init", .{});

    rng = std.Random.DefaultPrng.init(
        @intCast(std.time.timestamp()),
    );

    const size = ctx.getCanvasSize();

    world = try cp.World.init(ctx.allocator(), .{
        .gravity = .{ .x = 0, .y = 600 },
    });

    const dynamic_body: cp.World.ObjectOption.BodyProperty = .{
        .dynamic = .{
            .position = .{
                .x = size.getWidthFloat() / 2,
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
                .position = .{ .x = 100, .y = 400 },
                .angular_velocity = std.math.pi,
            },
        },
        .shapes = &[_]cp.World.ObjectOption.ShapeProperty{
            .{
                .segment = .{
                    .a = .{ .x = -100, .y = 0 },
                    .b = .{ .x = 200, .y = 0 },
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
        .body = .{
            .kinematic = .{
                .position = .{ .x = 600, .y = 500 },
                .angular_velocity = -std.math.pi / 2.0,
            },
        },
        .shapes = &[_]cp.World.ObjectOption.ShapeProperty{
            .{
                .segment = .{
                    .a = .{ .x = -200, .y = 0 },
                    .b = .{ .x = 200, .y = 0 },
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
                    .b = .{ .x = 0, .y = size.getHeightFloat() },
                    .physics = .{
                        .elasticity = 1.0,
                    },
                },
            },
            .{
                .segment = .{
                    .a = .{ .x = 0, .y = size.getHeightFloat() },
                    .b = .{ .x = size.getWidthFloat(), .y = size.getHeightFloat() },
                    .physics = .{
                        .elasticity = 1.0,
                    },
                },
            },
            .{
                .segment = .{
                    .a = .{ .x = size.getWidthFloat(), .y = 0 },
                    .b = .{ .x = size.getWidthFloat(), .y = size.getHeightFloat() },
                    .physics = .{
                        .elasticity = 1.0,
                    },
                },
            },
        },
    });
}

pub fn event(ctx: jok.Context, e: jok.Event) !void {
    _ = ctx;
    _ = e;
}

pub fn update(ctx: jok.Context) !void {
    world.update(ctx.deltaSeconds());
}

pub fn draw(ctx: jok.Context) !void {
    try ctx.renderer().clear(.none);
    ctx.displayStats(.{});
    try world.debugDraw(ctx.renderer());
}

pub fn quit(ctx: jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});
    world.deinit();
}
