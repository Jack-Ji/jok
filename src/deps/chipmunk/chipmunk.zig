const std = @import("std");
const assert = std.debug.assert;
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
    /// object's physics body, null means using global static
    body: ?*c.cpBody,

    /// object's shape
    shapes: []*c.cpShape,

    /// filter info
    filter: Filter,
};

pub const World = struct {

    /// memory allocator
    allocator: std.mem.Allocator,

    /// timing
    fixed_dt: f32,
    accumulator: f32,

    /// physics world object
    space: *c.cpSpace,

    /// objects in the world
    objects: std.ArrayList(Object),

    /// internal debug rendering
    debug: ?*PhysicsDebug = null,

    /// init chipmunk world
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
        var space = c.cpspaceNew();
        if (space == null) return error.OutOfMemory;

        c.cpspaceSetGravity(space, opt.gravity);
        c.cpspaceSetDamping(space, opt.dumping);
        c.cpspaceSetIterations(space, @intCast(c_int, opt.iteration));
        c.cpspaceSetUserData(space, opt.user_data);
        for (opt.collision_callbacks) |cb| {
            var handler: *c.cpCollisionHandler = undefined;
            if (cb.type_a != null and cb.type_b != null) {
                handler = c.cpspaceAddCollisionHandler(space, cb.type_a.?, cb.type_b.?);
            } else if (cb.type_a != null) {
                handler = c.cpspaceAddWildcardHandler(space, cb.type_a.?);
            } else {
                handler = c.cpspaceAddDefaultCollisionHandler(space);
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
            .objects = try std.ArrayList(Object).initCapacity(
                allocator,
                opt.prealloc_objects_num,
            ),
        };
        if (opt.enable_debug_draw) {
            self.debug = try PhysicsDebug.init(allocator, 64000);
        }

        return self;
    }

    pub fn deinit(self: World) void {
        c.cpspaceEachShape(self.space, postShapeFree, self.space);
        c.cpspaceEachConstraint(self.space, postConstraintFree, self.space);
        c.cpspaceEachBody(self.space, postBodyFree, self.space);
        c.cpspaceFree(self.space);
        for (self.objects.items) |o| {
            self.allocator.free(o.shapes);
        }
        self.objects.deinit();
        if (self.debug) |dbg| dbg.deinit();
    }

    fn shapeFree(space: ?*c.cpSpace, shape: ?*anyopaque, unused: ?*anyopaque) callconv(.C) void {
        _ = unused;
        c.cpspaceRemoveShape(space, @ptrCast(?*c.cpShape, shape));
        c.cpshapeFree(@ptrCast(?*c.cpShape, shape));
    }

    fn postShapeFree(shape: ?*c.cpShape, user_data: ?*anyopaque) callconv(.C) void {
        _ = c.cpspaceAddPostStepCallback(
            @ptrCast(?*c.cpSpace, user_data),
            shapeFree,
            shape,
            null,
        );
    }

    fn constraintFree(space: ?*c.cpSpace, constraint: ?*anyopaque, unused: ?*anyopaque) callconv(.C) void {
        _ = unused;
        c.cpspaceRemoveConstraint(space, @ptrCast(?*c.cpConstraint, constraint));
        c.cpconstraintFree(@ptrCast(?*c.cpConstraint, constraint));
    }

    fn postConstraintFree(constraint: ?*c.cpConstraint, user_data: ?*anyopaque) callconv(.C) void {
        _ = c.cpspaceAddPostStepCallback(
            @ptrCast(?*c.cpSpace, user_data),
            constraintFree,
            constraint,
            null,
        );
    }

    fn bodyFree(space: ?*c.cpSpace, body: ?*anyopaque, unused: ?*anyopaque) callconv(.C) void {
        _ = unused;
        c.cpspaceRemoveBody(space, @ptrCast(?*c.cpBody, body));
        c.cpbodyFree(@ptrCast(?*c.cpBody, body));
    }

    fn postBodyFree(body: ?*c.cpBody, user_data: ?*anyopaque) callconv(.C) void {
        _ = c.cpspaceAddPostStepCallback(
            @ptrCast(?*c.cpSpace, user_data),
            bodyFree,
            body,
            null,
        );
    }

    /// add object to world
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
            global_static: u8,
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
                transform: c.cpTransform = c.cptransformIdentity,
                radius: f32 = 0,
                physics: Physics = .{},
            },
        };

        body: BodyProperty = .{.global_static},
        shapes: []const ShapeProperty,
        filter: Filter = .{},
        never_rotate: bool = false,
        user_data: ?*anyopaque = null,
    };
    pub fn addObject(self: *World, opt: ObjectOption) !u32 {
        assert(opt.shapes.len > 0);

        // create physics body
        var use_global_static = false;
        var body = switch (opt.body) {
            .dynamic => |prop| blk: {
                var bd = c.cpbodyNew(0, 0).?;
                c.cpbodySetPosition(bd, prop.position);
                c.cpbodySetVelocity(bd, prop.velocity);
                c.cpbodySetAngularVelocity(bd, prop.angular_velocity);
                break :blk bd;
            },
            .kinematic => |prop| blk: {
                var bd = c.cpbodyNewKinematic().?;
                c.cpbodySetPosition(bd, prop.position);
                c.cpbodySetVelocity(bd, prop.velocity);
                c.cpbodySetAngularVelocity(bd, prop.angular_velocity);
                break :blk bd;
            },
            .static => |prop| blk: {
                var bd = c.cpbodyNewStatic().?;
                c.cpbodySetPosition(bd, prop.position);
                break :blk bd;
            },
            .global_static => blk: {
                var bd = c.cpspaceGetStaticBody(self.space).?;
                use_global_static = true;
                break :blk bd;
            },
        };
        if (opt.body != .global_static) {
            _ = c.cpspaceAddBody(self.space, body);
        }
        errdefer {
            c.cpspaceRemoveBody(self.space, body);
            c.cpbodyFree(body);
        }

        // create shapes
        var shapes = try self.allocator.alloc(*c.cpShape, opt.shapes.len);
        for (opt.shapes) |s, i| {
            shapes[i] = switch (s) {
                .segment => |prop| blk: {
                    var shape = c.cpsegmentShapeNew(body, prop.a, prop.b, prop.radius).?;
                    initPhysicsOfShape(shape, prop.physics);
                    break :blk shape;
                },
                .box => |prop| blk: {
                    assert(opt.body != .global_static);
                    var shape = c.cpboxShapeNew(body, prop.width, prop.height, prop.radius).?;
                    initPhysicsOfShape(shape, prop.physics);
                    break :blk shape;
                },
                .circle => |prop| blk: {
                    assert(opt.body != .global_static);
                    var shape = c.cpcircleShapeNew(body, prop.radius, prop.offset).?;
                    initPhysicsOfShape(shape, prop.physics);
                    break :blk shape;
                },
                .polygon => |prop| blk: {
                    var shape = c.cppolyShapeNew(
                        body,
                        @intCast(c_int, prop.verts.len),
                        prop.verts.ptr,
                        prop.transform,
                        prop.radius,
                    ).?;
                    initPhysicsOfShape(shape, prop.physics);
                    break :blk shape;
                },
            };
            _ = c.cpspaceAddShape(self.space, shapes[i]);
            c.cpshapeSetFilter(shapes[i], .{
                .group = @intCast(usize, opt.filter.group),
                .categories = @intCast(c_uint, opt.filter.categories),
                .mask = @intCast(c_uint, opt.filter.mask),
            });
        }
        errdefer {
            for (shapes) |s| {
                c.cpspaceRemoveShape(self.space, s);
                c.cpshapeFree(s);
            }
            self.allocator.free(shapes);
        }

        // prevent rotation if needed
        if (opt.never_rotate) {
            c.cpbodySetMoment(body, std.math.f32_max);
        }

        // append to object array
        try self.objects.append(.{
            .body = if (use_global_static) null else body,
            .shapes = shapes,
            .filter = opt.filter,
        });

        // set user data of body/shapes, equal to
        // index/id of object by default.
        var ud = opt.user_data orelse @intToPtr(
            *allowzero anyopaque,
            self.objects.items.len - 1,
        );
        if (!use_global_static) {
            c.cpbodySetUserData(body, ud);
        }
        for (shapes) |s| {
            c.cpshapeSetUserData(s, ud);
        }

        return @intCast(u32, self.objects.items.len - 1);
    }

    fn initPhysicsOfShape(shape: *c.cpShape, phy: ObjectOption.ShapeProperty.Physics) void {
        switch (phy.weight) {
            .mass => |m| c.cpshapeSetMass(shape, m),
            .density => |d| c.cpshapeSetDensity(shape, d),
        }
        c.cpshapeSetElasticity(shape, phy.elasticity);
        c.cpshapeSetFriction(shape, phy.friction);
        c.cpshapeSetSensor(shape, @as(u8, @boolToInt(phy.is_sensor)));
    }

    /// update world
    pub fn update(self: *World, delta_tick: f32) void {
        self.accumulator += delta_tick;
        while (self.accumulator > self.fixed_dt) : (self.accumulator -= self.fixed_dt) {
            c.cpspaceStep(self.space, self.fixed_dt);
        }
    }

    /// debug draw
    pub fn debugDraw(self: World) void {
        if (self.debug) |dbg| {
            dbg.clear();
            c.cpSpaceDebugDraw(self.space, &dbg.space_draw_option);
        }
    }
};

/// debug draw
const PhysicsDebug = struct {
    const draw_alpha = 0.6;
    const draw_color = c.cpSpaceDebugColor{ .r = 1, .g = 1, .b = 0, .a = draw_alpha };

    allocator: std.mem.Allocator,
    max_vertex_num: u32,
    max_index_num: u32,
    vattribs: std.ArrayList(f32),
    vindices: std.ArrayList(u32),
    space_draw_option: c.cpSpaceDebugDrawOptions,

    fn init(allocator: std.mem.Allocator, max_vertex_num: u32) !*PhysicsDebug {
        var debug = try allocator.create(PhysicsDebug);

        // basic setup
        debug.allocator = allocator;
        debug.max_vertex_num = max_vertex_num;
        debug.max_index_num = max_vertex_num * 4;
        debug.vattribs = std.ArrayList(f32).initCapacity(allocator, 1000) catch unreachable;
        debug.vindices = std.ArrayList(u32).initCapacity(allocator, 1000) catch unreachable;
        // init chipmunk debug draw option
        debug.space_draw_option = .{
            .drawCircle = drawCircle,
            .drawSegment = drawSegment,
            .drawFatSegment = drawFatSegment,
            .drawPolygon = drawPolygon,
            .drawDot = drawDot,
            .flags = c.cpc.CP_SPACE_DEBUG_DRAW_SHAPES | c.cpc.CP_SPACE_DEBUG_DRAW_CONSTRAINTS | c.cpc.CP_SPACE_DEBUG_DRAW_COLLISION_POINTS,
            .shapeOutlineColor = .{
                .r = 0.2,
                .g = 0.91,
                .b = 0.84,
                .a = draw_alpha,
            }, // outline color
            .colorForShape = drawColorForShape,
            .constraintColor = .{ .r = 0, .g = 0.75, .b = 0, .a = draw_alpha }, // constraint color
            .collisionPointColor = .{ .r = 1, .g = 0, .b = 0, .a = draw_alpha }, // collision color
            .data = debug,
        };
        return debug;
    }

    fn deinit(debug: *PhysicsDebug) void {
        debug.vattribs.deinit();
        debug.vindices.deinit();
        debug.program.deinit();
        debug.vertex_array.deinit();
        debug.allocator.destroy(debug);
    }

    fn clear(debug: *PhysicsDebug) void {
        debug.vattribs.clearRetainingCapacity();
        debug.vindices.clearRetainingCapacity();
    }

    fn pushVertexes(debug: *PhysicsDebug, vcount: u32, indices: []const u32) []f32 {
        assert((@intCast(u32, debug.vattribs.items.len) + vcount) / 13 <= debug.max_vertex_num);
        assert(@intCast(u32, debug.vindices.items.len) + indices.len <= debug.max_index_num);
        const base = @intCast(u32, debug.vattribs.items.len / 13);
        debug.vattribs.resize(debug.vattribs.items.len + @intCast(usize, vcount) * 13) catch unreachable;
        for (indices) |i| {
            debug.vindices.append(i + base) catch unreachable;
        }
        return debug.vattribs.items[debug.vattribs.items.len - @intCast(usize, vcount) * 13 ..];
    }

    fn setVertexAttrib(
        vs: []f32,
        index: u32,
        pos_x: f32,
        pos_y: f32,
        u: f32,
        v: f32,
        radius: f32,
        fill_color: c.cpSpaceDebugColor,
        outline_color: c.cpSpaceDebugColor,
    ) void {
        _ = fill_color; // TODO: c-abi issue, need fix

        const i = index * 13;
        assert(i + 13 <= @intCast(u32, vs.len));
        vs[i] = pos_x;
        vs[i + 1] = pos_y;
        vs[i + 2] = u;
        vs[i + 3] = v;
        vs[i + 4] = radius;
        vs[i + 5] = draw_color.r;
        vs[i + 6] = draw_color.g;
        vs[i + 7] = draw_color.b;
        vs[i + 8] = draw_color.a;
        vs[i + 9] = outline_color.r;
        vs[i + 10] = outline_color.g;
        vs[i + 11] = outline_color.b;
        vs[i + 12] = outline_color.a;
    }

    fn drawCircle(
        pos: c.cpVect,
        angle: c.cpFloat,
        radius: c.cpFloat,
        outline_color: c.cpSpaceDebugColor,
        fill_color: c.cpSpaceDebugColor,
        data: c.cpDataPointer,
    ) callconv(.C) void {
        var debug = @ptrCast(*PhysicsDebug, @alignCast(@alignOf(*PhysicsDebug), data));
        const vs = debug.pushVertexes(4, &[_]u32{ 0, 1, 2, 0, 2, 3 });
        const pos_x = @floatCast(f32, pos.x);
        const pos_y = @floatCast(f32, pos.y);
        const r = @floatCast(f32, radius);
        setVertexAttrib(vs, 0, pos_x, pos_y, -1, -1, r, fill_color, outline_color);
        setVertexAttrib(vs, 1, pos_x, pos_y, -1, 1, r, fill_color, outline_color);
        setVertexAttrib(vs, 2, pos_x, pos_y, 1, 1, r, fill_color, outline_color);
        setVertexAttrib(vs, 3, pos_x, pos_y, 1, -1, r, fill_color, outline_color);

        drawSegment(
            pos,
            c.cpvadd(pos, c.cpvmult(c.cpvforangle(angle), 0.75 * radius)),
            outline_color,
            data,
        );
    }

    fn drawSegment(
        a: c.cpVect,
        b: c.cpVect,
        color: c.cpSpaceDebugColor,
        data: c.cpDataPointer,
    ) callconv(.C) void {
        drawFatSegment(a, b, 0, color, color, data);
    }

    fn drawFatSegment(
        a: c.cpVect,
        b: c.cpVect,
        radius: c.cpFloat,
        outline_color: c.cpSpaceDebugColor,
        fill_color: c.cpSpaceDebugColor,
        data: c.cpDataPointer,
    ) callconv(.C) void {
        var debug = @ptrCast(*PhysicsDebug, @alignCast(@alignOf(*PhysicsDebug), data));
        const vs = debug.pushVertexes(8, &[_]u32{ 0, 1, 2, 1, 2, 3, 2, 3, 4, 3, 4, 5, 4, 5, 6, 5, 6, 7 });
        const a_pos_x = @floatCast(f32, a.x);
        const a_pos_y = @floatCast(f32, a.y);
        const b_pos_x = @floatCast(f32, b.x);
        const b_pos_y = @floatCast(f32, b.y);
        const t = c.cpvnormalize(c.cpvsub(b, a));
        const t_u = @floatCast(f32, t.x);
        const t_v = @floatCast(f32, t.y);
        const r = @floatCast(f32, radius);
        setVertexAttrib(vs, 0, a_pos_x, a_pos_y, -t_u + t_v, -t_u - t_v, r, fill_color, outline_color);
        setVertexAttrib(vs, 1, a_pos_x, a_pos_y, -t_u - t_v, t_u - t_v, r, fill_color, outline_color);
        setVertexAttrib(vs, 2, a_pos_x, a_pos_y, -0 + t_v, -t_u + 0, r, fill_color, outline_color);
        setVertexAttrib(vs, 3, a_pos_x, a_pos_y, -0 - t_v, t_u + 0, r, fill_color, outline_color);
        setVertexAttrib(vs, 4, b_pos_x, b_pos_y, 0 + t_v, -t_u - 0, r, fill_color, outline_color);
        setVertexAttrib(vs, 5, b_pos_x, b_pos_y, 0 - t_v, t_u - 0, r, fill_color, outline_color);
        setVertexAttrib(vs, 6, b_pos_x, b_pos_y, t_u + t_v, -t_u + t_v, r, fill_color, outline_color);
        setVertexAttrib(vs, 7, b_pos_x, b_pos_y, t_u - t_v, t_u + t_v, r, fill_color, outline_color);
    }

    fn drawPolygon(
        _count: c_int,
        verts: [*c]const c.cpVect,
        radius: c.cpFloat,
        outline_color: c.cpSpaceDebugColor,
        fill_color: c.cpSpaceDebugColor,
        data: c.cpDataPointer,
    ) callconv(.C) void {
        var debug = @ptrCast(*PhysicsDebug, @alignCast(@alignOf(*PhysicsDebug), data));
        const count = @intCast(u32, _count);
        const max_poly_vertex = 64;
        const max_poly_indices = 3 * ((5 * max_poly_vertex) - 2);
        var indexes: [max_poly_indices]u32 = undefined;

        // Polygon fill triangles.
        var i: u32 = 0;
        while (i < count - 2) : (i += 1) {
            indexes[3 * i + 0] = 0;
            indexes[3 * i + 1] = 4 * (i + 1);
            indexes[3 * i + 2] = 4 * (i + 2);
        }

        // Polygon outline triangles.
        const cursor = indexes[@intCast(u32, 3 * (count - 2))..];
        i = 0;
        while (i < count) : (i += 1) {
            const j = (i + 1) % count;
            cursor[12 * i + 0] = 4 * i + 0;
            cursor[12 * i + 1] = 4 * i + 1;
            cursor[12 * i + 2] = 4 * i + 2;
            cursor[12 * i + 3] = 4 * i + 0;
            cursor[12 * i + 4] = 4 * i + 2;
            cursor[12 * i + 5] = 4 * i + 3;
            cursor[12 * i + 6] = 4 * i + 0;
            cursor[12 * i + 7] = 4 * i + 3;
            cursor[12 * i + 8] = 4 * j + 0;
            cursor[12 * i + 9] = 4 * i + 3;
            cursor[12 * i + 10] = 4 * j + 0;
            cursor[12 * i + 11] = 4 * j + 1;
        }

        const inset = -c.cpfmax(0, 2 - radius);
        const outset = radius + 1;
        const r = outset - inset;
        const vs = debug.pushVertexes(4 * count, &indexes);
        i = 0;
        while (i < count) : (i += 1) {
            const v0 = verts[i];
            const v_prev = verts[(i + (count - 1)) % count];
            const v_next = verts[(i + (count + 1)) % count];

            const n1 = c.cpvnormalize(c.cpvrperp(c.cpvsub(v0, v_prev)));
            const n2 = c.cpvnormalize(c.cpvrperp(c.cpvsub(v_next, v0)));
            const of = c.cpvmult(c.cpvadd(n1, n2), 1.0 / (c.cpvdot(n1, n2) + 1.0));
            const v = c.cpvadd(v0, c.cpvmult(of, inset));

            setVertexAttrib(vs, 4 * i, v.x, v.y, 0, 0, 0, fill_color, outline_color);
            setVertexAttrib(vs, 4 * i + 1, v.x, v.y, n1.x, n1.y, r, fill_color, outline_color);
            setVertexAttrib(vs, 4 * i + 2, v.x, v.y, of.x, of.y, r, fill_color, outline_color);
            setVertexAttrib(vs, 4 * i + 3, v.x, v.y, n2.x, n2.y, r, fill_color, outline_color);
        }
    }

    fn drawDot(
        size: c.cpFloat,
        pos: c.cpVect,
        color: c.cpSpaceDebugColor,
        data: c.cpDataPointer,
    ) callconv(.C) void {
        var debug = @ptrCast(*PhysicsDebug, @alignCast(@alignOf(*PhysicsDebug), data));
        const vs = debug.pushVertexes(4, &[_]u32{ 0, 1, 2, 0, 2, 3 });
        const pos_x = @floatCast(f32, pos.x);
        const pos_y = @floatCast(f32, pos.y);
        const r = size * 0.5;
        setVertexAttrib(vs, 0, pos_x, pos_y, -1, -1, r, color, color);
        setVertexAttrib(vs, 1, pos_x, pos_y, -1, 1, r, color, color);
        setVertexAttrib(vs, 2, pos_x, pos_y, 1, 1, r, color, color);
        setVertexAttrib(vs, 3, pos_x, pos_y, 1, -1, r, color, color);
    }

    fn drawColorForShape(
        shape: ?*c.cpShape,
        data: c.cpDataPointer,
    ) callconv(.C) c.cpSpaceDebugColor {
        _ = data;
        if (c.cpshapeGetSensor(shape) == 1) {
            return .{ .r = 1, .g = 1, .b = 1, .a = draw_alpha };
        } else {
            var body = c.cpshapeGetBody(shape);
            if (c.cpbodyIsSleeping(body) == 1) {
                return .{ .r = 0.35, .g = 0.43, .b = 0.46, .a = draw_alpha };
            } else {
                return .{ .r = 1, .g = 1, .b = 0, .a = draw_alpha };
            }
        }
    }
};
