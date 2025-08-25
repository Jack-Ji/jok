const std = @import("std");
const assert = std.debug.assert;
const jok = @import("../../jok.zig");
pub const c = @import("c.zig");

pub const Error = error{
    OutOfMemory,
};

pub const Filter = struct {
    group: usize = 0,
    categories: u32 = ~@as(u32, 0),
    mask: u32 = ~@as(u32, 0),
};

pub const Object = struct {
    /// Object's physics body, null means using global static
    body: ?*c.cpBody,

    /// Object's shape
    shapes: []*c.cpShape,

    /// Filter info
    filter: Filter,
};

pub const World = struct {
    /// Memory allocator
    allocator: std.mem.Allocator,

    /// Timing
    fixed_dt: f32,
    accumulator: f32,

    /// Physics world object
    space: *c.cpSpace,

    /// Objects in the world
    objects: std.array_list.Managed(Object),

    /// Internal debug rendering
    debug: ?*PhysicsDebug = null,

    /// Init chipmunk world
    pub const CollisionCallback = struct {
        type_a: ?c.cpCollisionType = null,
        type_b: ?c.cpCollisionType = null,
        begin_func: c.cpCollisionBeginFunc = null,
        pre_solve_func: c.cpCollisionPreSolveFunc = null,
        post_solve_func: c.cpCollisionPostSolveFunc = null,
        separate_func: c.cpCollisionSeparateFunc = null,
        user_data: c.cpDataPointer = null,
    };
    pub const InitOption = struct {
        fixed_dt: f32 = 1.0 / 60.0,
        gravity: c.cpVect = c.cpvzero,
        dumping: f32 = 1.0,
        iteration: u32 = 10,
        user_data: c.cpDataPointer = null,
        collision_callbacks: []CollisionCallback = &.{},
        prealloc_objects_num: u32 = 100,
        enable_debug_draw: bool = true,
    };
    pub fn init(allocator: std.mem.Allocator, opt: InitOption) !World {
        const space = c.cpSpaceNew();
        if (space == null) return error.OutOfMemory;

        c.cpSpaceSetGravity(space, opt.gravity);
        c.cpSpaceSetDamping(space, opt.dumping);
        c.cpSpaceSetIterations(space, @intCast(opt.iteration));
        c.cpSpaceSetUserData(space, opt.user_data);
        for (opt.collision_callbacks) |cb| {
            var handler: *c.cpCollisionHandler = undefined;
            if (cb.type_a != null and cb.type_b != null) {
                handler = c.cpSpaceAddCollisionHandler(space, cb.type_a.?, cb.type_b.?);
            } else if (cb.type_a != null) {
                handler = c.cpSpaceAddWildcardHandler(space, cb.type_a.?);
            } else {
                handler = c.cpSpaceAddDefaultCollisionHandler(space);
            }
            handler.beginFunc = cb.begin_func;
            handler.preSolveFunc = cb.pre_solve_func;
            handler.postSolveFunc = cb.post_solve_func;
            handler.separateFunc = cb.separate_func;
            handler.userData = cb.user_data;
        }

        var self = World{
            .allocator = allocator,
            .fixed_dt = opt.fixed_dt,
            .accumulator = 0,
            .space = space.?,
            .objects = try std.array_list.Managed(Object).initCapacity(
                allocator,
                opt.prealloc_objects_num,
            ),
        };
        if (opt.enable_debug_draw) {
            self.debug = try PhysicsDebug.init(allocator, 6400000);
        }

        return self;
    }

    pub fn deinit(self: World) void {
        c.cpSpaceEachShape(self.space, postShapeFree, self.space);
        c.cpSpaceEachConstraint(self.space, postConstraintFree, self.space);
        c.cpSpaceEachBody(self.space, postBodyFree, self.space);
        c.cpSpaceFree(self.space);
        for (self.objects.items) |o| {
            self.allocator.free(o.shapes);
        }
        self.objects.deinit();
        if (self.debug) |dbg| dbg.deinit();
    }

    fn shapeFree(space: ?*c.cpSpace, shape: ?*anyopaque, unused: ?*anyopaque) callconv(.c) void {
        _ = unused;
        c.cpSpaceRemoveShape(space, @ptrCast(shape));
        c.cpShapeFree(@ptrCast(shape));
    }

    fn postShapeFree(shape: ?*c.cpShape, user_data: ?*anyopaque) callconv(.c) void {
        _ = c.cpSpaceAddPostStepCallback(
            @ptrCast(user_data),
            shapeFree,
            shape,
            null,
        );
    }

    fn constraintFree(space: ?*c.cpSpace, constraint: ?*anyopaque, unused: ?*anyopaque) callconv(.c) void {
        _ = unused;
        c.cpSpaceRemoveConstraint(space, @ptrCast(constraint));
        c.cpConstraintFree(@ptrCast(constraint));
    }

    fn postConstraintFree(constraint: ?*c.cpConstraint, user_data: ?*anyopaque) callconv(.c) void {
        _ = c.cpSpaceAddPostStepCallback(
            @ptrCast(user_data),
            constraintFree,
            constraint,
            null,
        );
    }

    fn bodyFree(space: ?*c.cpSpace, body: ?*anyopaque, unused: ?*anyopaque) callconv(.c) void {
        _ = unused;
        c.cpSpaceRemoveBody(space, @ptrCast(body));
        c.cpBodyFree(@ptrCast(body));
    }

    fn postBodyFree(body: ?*c.cpBody, user_data: ?*anyopaque) callconv(.c) void {
        _ = c.cpSpaceAddPostStepCallback(
            @ptrCast(user_data),
            bodyFree,
            body,
            null,
        );
    }

    /// Add object to world
    pub const ObjectOption = struct {
        pub const BodyProperty = union(enum) {
            dynamic: struct {
                position: c.cpVect,
                velocity: c.cpVect = c.cpvzero,
                angular_velocity: f32 = 0,
            },
            kinematic: struct {
                position: c.cpVect,
                velocity: c.cpVect = c.cpvzero,
                angular_velocity: f32 = 0,
            },
            static: struct {
                position: c.cpVect,
            },
            global_static,
        };
        pub const ShapeProperty = union(enum) {
            pub const Weight = union(enum) {
                mass: f32,
                density: f32,
            };
            pub const Physics = struct {
                weight: Weight = .{ .mass = 1 },
                elasticity: f32 = 0.1,
                friction: f32 = 0.7,
                is_sensor: bool = false,
            };

            segment: struct {
                a: c.cpVect,
                b: c.cpVect,
                radius: f32 = 0,
                physics: Physics = .{},
            },
            box: struct {
                width: f32,
                height: f32,
                radius: f32 = 0,
                physics: Physics = .{},
            },
            circle: struct {
                radius: f32,
                offset: c.cpVect = c.cpvzero,
                physics: Physics = .{},
            },
            polygon: struct {
                verts: []const c.cpVect,
                transform: c.cpTransform = c.cpTransformIdentity,
                radius: f32 = 0,
                physics: Physics = .{},
            },
        };

        body: BodyProperty = .global_static,
        shapes: []const ShapeProperty,
        filter: Filter = .{},
        never_rotate: bool = false,
        user_data: ?*anyopaque = null,
    };
    pub fn addObject(self: *World, opt: ObjectOption) !u32 {
        assert(opt.shapes.len > 0);

        // Create physics body
        var use_global_static = false;
        const body = switch (opt.body) {
            .dynamic => |prop| blk: {
                const bd = c.cpBodyNew(0, 0).?;
                c.cpBodySetPosition(bd, prop.position);
                c.cpBodySetVelocity(bd, prop.velocity);
                c.cpBodySetAngularVelocity(bd, prop.angular_velocity);
                break :blk bd;
            },
            .kinematic => |prop| blk: {
                const bd = c.cpBodyNewKinematic().?;
                c.cpBodySetPosition(bd, prop.position);
                c.cpBodySetVelocity(bd, prop.velocity);
                c.cpBodySetAngularVelocity(bd, prop.angular_velocity);
                break :blk bd;
            },
            .static => |prop| blk: {
                const bd = c.cpBodyNewStatic().?;
                c.cpBodySetPosition(bd, prop.position);
                break :blk bd;
            },
            .global_static => blk: {
                const bd = c.cpSpaceGetStaticBody(self.space).?;
                use_global_static = true;
                break :blk bd;
            },
        };
        if (opt.body != .global_static) {
            _ = c.cpSpaceAddBody(self.space, body);
        }
        errdefer {
            c.cpSpaceRemoveBody(self.space, body);
            c.cpBodyFree(body);
        }

        // Create shapes
        var shapes = try self.allocator.alloc(*c.cpShape, opt.shapes.len);
        for (opt.shapes, 0..) |s, i| {
            shapes[i] = switch (s) {
                .segment => |prop| blk: {
                    const shape = c.cpSegmentShapeNew(body, prop.a, prop.b, prop.radius).?;
                    initPhysicsOfShape(shape, prop.physics);
                    break :blk shape;
                },
                .box => |prop| blk: {
                    assert(opt.body != .global_static);
                    const shape = c.cpBoxShapeNew(body, prop.width, prop.height, prop.radius).?;
                    initPhysicsOfShape(shape, prop.physics);
                    break :blk shape;
                },
                .circle => |prop| blk: {
                    assert(opt.body != .global_static);
                    const shape = c.cpCircleShapeNew(body, prop.radius, prop.offset).?;
                    initPhysicsOfShape(shape, prop.physics);
                    break :blk shape;
                },
                .polygon => |prop| blk: {
                    const shape = c.cpPolyShapeNew(
                        body,
                        @intCast(prop.verts.len),
                        prop.verts.ptr,
                        prop.transform,
                        prop.radius,
                    ).?;
                    initPhysicsOfShape(shape, prop.physics);
                    break :blk shape;
                },
            };
            _ = c.cpSpaceAddShape(self.space, shapes[i]);
            c.cpShapeSetFilter(shapes[i], .{
                .group = @intCast(opt.filter.group),
                .categories = @intCast(opt.filter.categories),
                .mask = @intCast(opt.filter.mask),
            });
        }
        errdefer {
            for (shapes) |s| {
                c.cpSpaceRemoveShape(self.space, s);
                c.cpShapeFree(s);
            }
            self.allocator.free(shapes);
        }

        // Prevent rotation if needed
        if (opt.never_rotate) {
            c.cpBodySetMoment(body, std.math.floatMax(f32));
        }

        // Append to object array
        try self.objects.append(.{
            .body = if (use_global_static) null else body,
            .shapes = shapes,
            .filter = opt.filter,
        });

        // Set user data of body/shapes, equal to
        // Index/id of object by default.
        const ud = opt.user_data orelse @as(
            ?*anyopaque,
            @ptrFromInt(self.objects.items.len - 1),
        );
        if (!use_global_static) {
            c.cpBodySetUserData(body, ud);
        }
        for (shapes) |s| {
            c.cpShapeSetUserData(s, ud);
        }

        return @intCast(self.objects.items.len - 1);
    }

    fn initPhysicsOfShape(shape: *c.cpShape, phy: ObjectOption.ShapeProperty.Physics) void {
        switch (phy.weight) {
            .mass => |m| c.cpShapeSetMass(shape, m),
            .density => |d| c.cpShapeSetDensity(shape, d),
        }
        c.cpShapeSetElasticity(shape, phy.elasticity);
        c.cpShapeSetFriction(shape, phy.friction);
        c.cpShapeSetSensor(shape, @as(u8, @intFromBool(phy.is_sensor)));
    }

    /// Update world
    pub fn update(self: *World, delta_tick: f32) void {
        self.accumulator += delta_tick;
        while (self.accumulator > self.fixed_dt) : (self.accumulator -= self.fixed_dt) {
            c.cpSpaceStep(self.space, self.fixed_dt);
        }
    }

    /// Debug draw
    pub fn debugDraw(self: World, renderer: jok.Renderer) !void {
        if (self.debug) |dbg| {
            dbg.clear();
            c.cpSpaceDebugDraw(self.space, &dbg.space_draw_option);
            try dbg.draw(renderer);
        }
    }
};

/// Debug draw
const PhysicsDebug = struct {
    const draw_alpha = 0.6;

    allocator: std.mem.Allocator,
    max_vertex_num: u32,
    vattribs: std.array_list.Managed(jok.Vertex),
    vindices: std.array_list.Managed(u32),
    space_draw_option: c.cpSpaceDebugDrawOptions,

    fn init(allocator: std.mem.Allocator, max_vertex_num: u32) !*PhysicsDebug {
        var debug = try allocator.create(PhysicsDebug);
        debug.allocator = allocator;
        debug.max_vertex_num = max_vertex_num;
        debug.vattribs = try .initCapacity(allocator, 1000);
        debug.vindices = try .initCapacity(allocator, 3000);
        debug.space_draw_option = .{
            .drawCircle = drawCircle,
            .drawSegment = drawSegment,
            .drawFatSegment = drawFatSegment,
            .drawPolygon = drawPolygon,
            .drawDot = drawDot,
            .flags = c.CP_SPACE_DEBUG_DRAW_SHAPES | c.CP_SPACE_DEBUG_DRAW_CONSTRAINTS | c.CP_SPACE_DEBUG_DRAW_COLLISION_POINTS,
            .shapeOutlineColor = .{
                .r = 0.2,
                .g = 0.91,
                .b = 0.84,
                .a = draw_alpha,
            }, // Outline color
            .colorForShape = drawColorForShape,
            .constraintColor = .{ .r = 0, .g = 0.75, .b = 0, .a = draw_alpha }, // Constraint color
            .collisionPointColor = .{ .r = 1, .g = 0, .b = 0, .a = draw_alpha }, // Collision color
            .data = debug,
        };
        return debug;
    }

    fn deinit(debug: *PhysicsDebug) void {
        debug.vattribs.deinit();
        debug.vindices.deinit();
        debug.allocator.destroy(debug);
    }

    fn clear(debug: *PhysicsDebug) void {
        debug.vattribs.clearRetainingCapacity();
        debug.vindices.clearRetainingCapacity();
    }

    fn draw(debug: *PhysicsDebug, renderer: jok.Renderer) !void {
        try renderer.drawTriangles(null, debug.vattribs.items, debug.vindices.items);
    }

    fn addVertices(debug: *PhysicsDebug, vcount: u32, indices: []const u32) []jok.Vertex {
        assert((@as(u32, @intCast(debug.vattribs.items.len)) + vcount) <= debug.max_vertex_num);
        const base_index = debug.vattribs.items.len;
        debug.vattribs.resize(debug.vattribs.items.len + @as(usize, @intCast(vcount))) catch unreachable;
        debug.vindices.resize(debug.vindices.items.len + indices.len) catch unreachable;
        for (debug.vindices.items[debug.vindices.items.len - indices.len ..], 0..) |*idx, i| {
            idx.* = indices[i] + @as(u32, @intCast(base_index));
        }
        return debug.vattribs.items[debug.vattribs.items.len - @as(usize, @intCast(vcount)) ..];
    }

    fn cpPosToPoint(pos: c.cpVect) jok.Point {
        return .{
            .x = @floatCast(pos.x),
            .y = @floatCast(pos.y),
        };
    }

    fn cpColorToRGBA(color: c.cpSpaceDebugColor) jok.ColorF {
        //return .{
        //    .r = @floatToInt(u8, @round(color.r * 255)),
        //    .g = @floatToInt(u8, @round(color.g * 255)),
        //    .b = @floatToInt(u8, @round(color.b * 255)),
        //    .a = @floatToInt(u8, @round(color.a * 255)),
        //};
        _ = color;
        return .{
            .r = 1,
            .g = 1,
            .b = 0,
            .a = 0.5,
        };
    }

    fn drawCircle(
        pos: c.cpVect,
        angle: c.cpFloat,
        radius: c.cpFloat,
        outline_color: c.cpSpaceDebugColor,
        fill_color: c.cpSpaceDebugColor,
        data: c.cpDataPointer,
    ) callconv(.c) void {
        _ = outline_color;
        var debug = @as(*PhysicsDebug, @ptrCast(@alignCast(data)));
        // Zig fmt: off
        const vs = debug.addVertices(
            20,
            &[_]u32{
                0, 1,  2,  0, 2,  3,  0, 3,  4,  0, 4,  5,  0, 5,  6,
                0, 6,  7,  0, 7,  8,  0, 8,  9,  0, 9,  10, 0, 10, 11,
                0, 11, 12, 0, 12, 13, 0, 13, 14, 0, 14, 15, 0, 15, 16,
                0, 16, 17, 0, 17, 18, 0, 18, 19,
            },
        );
        const theta = std.math.tau / 19.0;
        vs[0] = .{
            .pos = cpPosToPoint(pos),
            .color = cpColorToRGBA(fill_color),
        };
        for (vs[1..], 0..) |_, i| {
            const offset_x = @cos(angle + theta * @as(f32, @floatFromInt(i))) * radius;
            const offset_y = @sin(angle + theta * @as(f32, @floatFromInt(i))) * radius;
            vs[i + 1] = .{
                .pos = .{ .x = pos.x + offset_x, .y = pos.y + offset_y },
                .color = cpColorToRGBA(fill_color),
            };
        }
    }

    fn drawSegment(
        a: c.cpVect,
        b: c.cpVect,
        color: c.cpSpaceDebugColor,
        data: c.cpDataPointer,
    ) callconv(.c) void {
        drawFatSegment(a, b, 2, color, color, data);
    }

    fn drawFatSegment(
        _a: c.cpVect,
        _b: c.cpVect,
        radius: c.cpFloat,
        outline_color: c.cpSpaceDebugColor,
        fill_color: c.cpSpaceDebugColor,
        data: c.cpDataPointer,
    ) callconv(.c) void {
        _ = outline_color;
        var debug = @as(*PhysicsDebug, @ptrCast(@alignCast(data)));

        // Make sure a is on left of b
        var a = _a;
        var b = _b;
        if (a.x > b.x) {
            std.mem.swap(c.cpVect, &a, &b);
        }
        const angle = std.math.atan2(b.y - a.y, b.x - a.x);

        const vs = debug.addVertices(
            14,
            &[_]u32{ 0, 1, 2, 0, 2, 3, 0, 3, 4, 0, 4, 5, 0, 5, 6, 7, 8, 9, 7, 9, 10, 7, 10, 11, 7, 11, 12, 7, 12, 13, 1, 6, 13, 6, 13, 8 },
        );
        const theta = std.math.pi / 5.0;
        vs[0] = .{
            .pos = cpPosToPoint(a),
            .color = cpColorToRGBA(fill_color),
        };
        vs[7] = .{
            .pos = cpPosToPoint(b),
            .color = cpColorToRGBA(fill_color),
        };
        for (vs[1..7], 0..) |_, i| {
            const offset_x = @cos(angle + std.math.pi / 2.0 + theta * @as(f32, @floatFromInt(i))) * radius;
            const offset_y = @sin(angle + std.math.pi / 2.0 + theta * @as(f32, @floatFromInt(i))) * radius;
            vs[i + 1] = .{
                .pos = .{ .x = a.x + offset_x, .y = a.y + offset_y },
                .color = cpColorToRGBA(fill_color),
            };
        }
        for (vs[8..], 0..) |_, i| {
            const offset_x = @cos(angle - std.math.pi / 2.0 + theta * @as(f32, @floatFromInt(i))) * radius;
            const offset_y = @sin(angle - std.math.pi / 2.0 + theta * @as(f32, @floatFromInt(i))) * radius;
            vs[8 + i] = .{
                .pos = .{ .x = b.x + offset_x, .y = b.y + offset_y },
                .color = cpColorToRGBA(fill_color),
            };
        }
    }

    fn drawPolygon(
        _count: c_int,
        verts: [*c]const c.cpVect,
        radius: c.cpFloat,
        outline_color: c.cpSpaceDebugColor,
        fill_color: c.cpSpaceDebugColor,
        data: c.cpDataPointer,
    ) callconv(.c) void {
        _ = radius;
        _ = outline_color;
        var debug = @as(*PhysicsDebug, @ptrCast(@alignCast(data)));
        const count = @as(u32, @intCast(_count));
        const max_poly_vertex = 64;
        const max_poly_indices = 3 * (max_poly_vertex - 2);
        var indexes: [max_poly_indices]u32 = undefined;
        assert(count < max_poly_vertex);

        // Polygon fill triangles.
        var i: u32 = 0;
        while (i < count - 2) : (i += 1) {
            indexes[3 * i + 0] = 0;
            indexes[3 * i + 1] = i + 1;
            indexes[3 * i + 2] = i + 2;
        }

        const vs = debug.addVertices(count, indexes[0 .. 3 * (count - 2)]);
        i = 0;
        while (i < count) : (i += 1) {
            vs[i] = .{
                .pos = cpPosToPoint(verts[i]),
                .color = cpColorToRGBA(fill_color),
            };
        }
    }

    fn drawDot(
        size: c.cpFloat,
        pos: c.cpVect,
        color: c.cpSpaceDebugColor,
        data: c.cpDataPointer,
    ) callconv(.c) void {
        drawCircle(
            pos,
            0,
            size / 2,
            color,
            color,
            data,
        );
    }

    fn drawColorForShape(
        shape: ?*c.cpShape,
        data: c.cpDataPointer,
    ) callconv(.c) c.cpSpaceDebugColor {
        _ = data;
        if (c.cpShapeGetSensor(shape) == 1) {
            return .{ .r = 1, .g = 1, .b = 1, .a = draw_alpha };
        } else {
            const body = c.cpShapeGetBody(shape);
            if (c.cpBodyIsSleeping(body) == 1) {
                return .{ .r = 0.35, .g = 0.43, .b = 0.46, .a = draw_alpha };
            } else {
                return .{ .r = 1, .g = 1, .b = 0, .a = draw_alpha };
            }
        }
    }
};
