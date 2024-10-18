pub const cpFloat = f32;
pub fn cpfmax(arg_a: cpFloat, arg_b: cpFloat) callconv(.C) cpFloat {
    const a = arg_a;
    const b = arg_b;
    return if (a > b) a else b;
}
pub fn cpfmin(arg_a: cpFloat, arg_b: cpFloat) callconv(.C) cpFloat {
    const a = arg_a;
    const b = arg_b;
    return if (a < b) a else b;
}
pub fn cpfabs(arg_f: cpFloat) callconv(.C) cpFloat {
    const f = arg_f;
    return if (f < @as(cpFloat, @floatFromInt(@as(c_int, 0)))) -f else f;
}
pub fn cpfclamp(arg_f: cpFloat, arg_min: cpFloat, arg_max: cpFloat) callconv(.C) cpFloat {
    const f = arg_f;
    const min = arg_min;
    const max = arg_max;
    return cpfmin(cpfmax(f, min), max);
}
pub fn cpfclamp01(arg_f: cpFloat) callconv(.C) cpFloat {
    const f = arg_f;
    return cpfmax(0.0, cpfmin(f, 1.0));
}
pub fn cpflerp(arg_f1: cpFloat, arg_f2: cpFloat, arg_t: cpFloat) callconv(.C) cpFloat {
    const f1 = arg_f1;
    const f2 = arg_f2;
    const t = arg_t;
    return (f1 * (1.0 - t)) + (f2 * t);
}
pub fn cpflerpconst(arg_f1: cpFloat, arg_f2: cpFloat, arg_d: cpFloat) callconv(.C) cpFloat {
    const f1 = arg_f1;
    const f2 = arg_f2;
    const d = arg_d;
    return f1 + cpfclamp(f2 - f1, -d, d);
}
pub const cpHashValue = usize;
pub const cpCollisionID = u32;
pub const cpBool = u8;
pub const cpDataPointer = ?*anyopaque;
pub const cpCollisionType = usize;
pub const cpGroup = usize;
pub const cpBitmask = c_uint;
pub const cpTimestamp = c_uint;
pub const struct_cpVect = extern struct {
    x: cpFloat = @import("std").mem.zeroes(cpFloat),
    y: cpFloat = @import("std").mem.zeroes(cpFloat),
};
pub const cpVect = struct_cpVect;
pub const struct_cpTransform = extern struct {
    a: cpFloat = @import("std").mem.zeroes(cpFloat),
    b: cpFloat = @import("std").mem.zeroes(cpFloat),
    c: cpFloat = @import("std").mem.zeroes(cpFloat),
    d: cpFloat = @import("std").mem.zeroes(cpFloat),
    tx: cpFloat = @import("std").mem.zeroes(cpFloat),
    ty: cpFloat = @import("std").mem.zeroes(cpFloat),
};
pub const cpTransform = struct_cpTransform;
pub const struct_cpMat2x2 = extern struct {
    a: cpFloat = @import("std").mem.zeroes(cpFloat),
    b: cpFloat = @import("std").mem.zeroes(cpFloat),
    c: cpFloat = @import("std").mem.zeroes(cpFloat),
    d: cpFloat = @import("std").mem.zeroes(cpFloat),
};
pub const cpMat2x2 = struct_cpMat2x2;
pub const struct_cpArray = opaque {};
pub const cpArray = struct_cpArray;
pub const struct_cpHashSet = opaque {};
pub const cpHashSet = struct_cpHashSet;
pub const struct_cpBody = opaque {};
pub const cpBody = struct_cpBody;
pub const struct_cpShape = opaque {};
pub const cpShape = struct_cpShape;
pub const struct_cpCircleShape = opaque {};
pub const cpCircleShape = struct_cpCircleShape;
pub const struct_cpSegmentShape = opaque {};
pub const cpSegmentShape = struct_cpSegmentShape;
pub const struct_cpPolyShape = opaque {};
pub const cpPolyShape = struct_cpPolyShape;
pub const struct_cpConstraint = opaque {};
pub const cpConstraint = struct_cpConstraint;
pub const struct_cpPinJoint = opaque {};
pub const cpPinJoint = struct_cpPinJoint;
pub const struct_cpSlideJoint = opaque {};
pub const cpSlideJoint = struct_cpSlideJoint;
pub const struct_cpPivotJoint = opaque {};
pub const cpPivotJoint = struct_cpPivotJoint;
pub const struct_cpGrooveJoint = opaque {};
pub const cpGrooveJoint = struct_cpGrooveJoint;
pub const struct_cpDampedSpring = opaque {};
pub const cpDampedSpring = struct_cpDampedSpring;
pub const struct_cpDampedRotarySpring = opaque {};
pub const cpDampedRotarySpring = struct_cpDampedRotarySpring;
pub const struct_cpRotaryLimitJoint = opaque {};
pub const cpRotaryLimitJoint = struct_cpRotaryLimitJoint;
pub const struct_cpRatchetJoint = opaque {};
pub const cpRatchetJoint = struct_cpRatchetJoint;
pub const struct_cpGearJoint = opaque {};
pub const cpGearJoint = struct_cpGearJoint;
pub const struct_cpSimpleMotorJoint = opaque {};
pub const cpSimpleMotorJoint = struct_cpSimpleMotorJoint;
pub const struct_cpArbiter = opaque {};
pub const cpArbiter = struct_cpArbiter;
pub const struct_cpSpace = opaque {};
pub const cpSpace = struct_cpSpace;
pub const cpCollisionBeginFunc = ?*const fn (?*cpArbiter, ?*cpSpace, cpDataPointer) callconv(.C) cpBool;
pub const cpCollisionPreSolveFunc = ?*const fn (?*cpArbiter, ?*cpSpace, cpDataPointer) callconv(.C) cpBool;
pub const cpCollisionPostSolveFunc = ?*const fn (?*cpArbiter, ?*cpSpace, cpDataPointer) callconv(.C) void;
pub const cpCollisionSeparateFunc = ?*const fn (?*cpArbiter, ?*cpSpace, cpDataPointer) callconv(.C) void;
pub const struct_cpCollisionHandler = extern struct {
    typeA: cpCollisionType = @import("std").mem.zeroes(cpCollisionType),
    typeB: cpCollisionType = @import("std").mem.zeroes(cpCollisionType),
    beginFunc: cpCollisionBeginFunc = @import("std").mem.zeroes(cpCollisionBeginFunc),
    preSolveFunc: cpCollisionPreSolveFunc = @import("std").mem.zeroes(cpCollisionPreSolveFunc),
    postSolveFunc: cpCollisionPostSolveFunc = @import("std").mem.zeroes(cpCollisionPostSolveFunc),
    separateFunc: cpCollisionSeparateFunc = @import("std").mem.zeroes(cpCollisionSeparateFunc),
    userData: cpDataPointer = @import("std").mem.zeroes(cpDataPointer),
};
pub const cpCollisionHandler = struct_cpCollisionHandler;
const struct_unnamed_3 = extern struct {
    pointA: cpVect = @import("std").mem.zeroes(cpVect),
    pointB: cpVect = @import("std").mem.zeroes(cpVect),
    distance: cpFloat = @import("std").mem.zeroes(cpFloat),
};
pub const struct_cpContactPointSet = extern struct {
    count: c_int = @import("std").mem.zeroes(c_int),
    normal: cpVect = @import("std").mem.zeroes(cpVect),
    points: [2]struct_unnamed_3 = @import("std").mem.zeroes([2]struct_unnamed_3),
};
pub const cpContactPointSet = struct_cpContactPointSet;
pub const cpvzero: cpVect = cpVect{
    .x = 0.0,
    .y = 0.0,
};
pub fn cpv(x: cpFloat, y: cpFloat) callconv(.C) cpVect {
    const v: cpVect = cpVect{
        .x = x,
        .y = y,
    };
    return v;
}
pub fn cpveql(v1: cpVect, v2: cpVect) callconv(.C) cpBool {
    return @as(cpBool, @intFromBool((v1.x == v2.x) and (v1.y == v2.y)));
}
pub fn cpvadd(v1: cpVect, v2: cpVect) callconv(.C) cpVect {
    return cpv(v1.x + v2.x, v1.y + v2.y);
}
pub fn cpvsub(v1: cpVect, v2: cpVect) callconv(.C) cpVect {
    return cpv(v1.x - v2.x, v1.y - v2.y);
}
pub fn cpvneg(v: cpVect) callconv(.C) cpVect {
    return cpv(-v.x, -v.y);
}
pub fn cpvmult(v: cpVect, s: cpFloat) callconv(.C) cpVect {
    return cpv(v.x * s, v.y * s);
}
pub fn cpvdot(v1: cpVect, v2: cpVect) callconv(.C) cpFloat {
    return (v1.x * v2.x) + (v1.y * v2.y);
}
pub fn cpvcross(v1: cpVect, v2: cpVect) callconv(.C) cpFloat {
    return (v1.x * v2.y) - (v1.y * v2.x);
}
pub fn cpvperp(v: cpVect) callconv(.C) cpVect {
    return cpv(-v.y, v.x);
}
pub fn cpvrperp(v: cpVect) callconv(.C) cpVect {
    return cpv(v.y, -v.x);
}
pub fn cpvproject(v1: cpVect, v2: cpVect) callconv(.C) cpVect {
    return cpvmult(v2, cpvdot(v1, v2) / cpvdot(v2, v2));
}
pub fn cpvforangle(a: cpFloat) callconv(.C) cpVect {
    return cpv(cosf(a), sinf(a));
}
pub fn cpvtoangle(v: cpVect) callconv(.C) cpFloat {
    return atan2f(v.y, v.x);
}
pub fn cpvrotate(v1: cpVect, v2: cpVect) callconv(.C) cpVect {
    return cpv((v1.x * v2.x) - (v1.y * v2.y), (v1.x * v2.y) + (v1.y * v2.x));
}
pub fn cpvunrotate(v1: cpVect, v2: cpVect) callconv(.C) cpVect {
    return cpv((v1.x * v2.x) + (v1.y * v2.y), (v1.y * v2.x) - (v1.x * v2.y));
}
pub fn cpvlengthsq(v: cpVect) callconv(.C) cpFloat {
    return cpvdot(v, v);
}
pub fn cpvlength(v: cpVect) callconv(.C) cpFloat {
    return sqrtf(cpvdot(v, v));
}
pub fn cpvlerp(v1: cpVect, v2: cpVect, t: cpFloat) callconv(.C) cpVect {
    return cpvadd(cpvmult(v1, 1.0 - t), cpvmult(v2, t));
}
pub fn cpvnormalize(v: cpVect) callconv(.C) cpVect {
    return cpvmult(v, 1.0 / (cpvlength(v) + 0.000000000000000000000000000000000000011754943508222875));
}
pub fn cpvslerp(v1: cpVect, v2: cpVect, t: cpFloat) callconv(.C) cpVect {
    const dot: cpFloat = cpvdot(cpvnormalize(v1), cpvnormalize(v2));
    const omega: cpFloat = acosf(cpfclamp(dot, -1.0, 1.0));
    if (@as(f64, @floatCast(omega)) < 0.001) {
        return cpvlerp(v1, v2, t);
    } else {
        const denom: cpFloat = 1.0 / sinf(omega);
        return cpvadd(cpvmult(v1, sinf((1.0 - t) * omega) * denom), cpvmult(v2, sinf(t * omega) * denom));
    }
    return @import("std").mem.zeroes(cpVect);
}
pub fn cpvslerpconst(v1: cpVect, v2: cpVect, a: cpFloat) callconv(.C) cpVect {
    const dot: cpFloat = cpvdot(cpvnormalize(v1), cpvnormalize(v2));
    const omega: cpFloat = acosf(cpfclamp(dot, -1.0, 1.0));
    return cpvslerp(v1, v2, cpfmin(a, omega) / omega);
}
pub fn cpvclamp(v: cpVect, len: cpFloat) callconv(.C) cpVect {
    return if (cpvdot(v, v) > (len * len)) cpvmult(cpvnormalize(v), len) else v;
}
pub fn cpvlerpconst(arg_v1: cpVect, arg_v2: cpVect, arg_d: cpFloat) callconv(.C) cpVect {
    const v1 = arg_v1;
    const v2 = arg_v2;
    const d = arg_d;
    return cpvadd(v1, cpvclamp(cpvsub(v2, v1), d));
}
pub fn cpvdist(v1: cpVect, v2: cpVect) callconv(.C) cpFloat {
    return cpvlength(cpvsub(v1, v2));
}
pub fn cpvdistsq(v1: cpVect, v2: cpVect) callconv(.C) cpFloat {
    return cpvlengthsq(cpvsub(v1, v2));
}
pub fn cpvnear(v1: cpVect, v2: cpVect, dist: cpFloat) callconv(.C) cpBool {
    return @as(cpBool, @intFromBool(cpvdistsq(v1, v2) < (dist * dist)));
}
pub fn cpMat2x2New(arg_a: cpFloat, arg_b: cpFloat, arg_c: cpFloat, arg_d: cpFloat) callconv(.C) cpMat2x2 {
    const a = arg_a;
    const b = arg_b;
    const c = arg_c;
    const d = arg_d;
    const m: cpMat2x2 = cpMat2x2{
        .a = a,
        .b = b,
        .c = c,
        .d = d,
    };
    return m;
}
pub fn cpMat2x2Transform(arg_m: cpMat2x2, arg_v: cpVect) callconv(.C) cpVect {
    const m = arg_m;
    const v = arg_v;
    return cpv((v.x * m.a) + (v.y * m.b), (v.x * m.c) + (v.y * m.d));
}
pub const struct_cpBB = extern struct {
    l: cpFloat = @import("std").mem.zeroes(cpFloat),
    b: cpFloat = @import("std").mem.zeroes(cpFloat),
    r: cpFloat = @import("std").mem.zeroes(cpFloat),
    t: cpFloat = @import("std").mem.zeroes(cpFloat),
};
pub const cpBB = struct_cpBB;
pub fn cpBBNew(l: cpFloat, b: cpFloat, r: cpFloat, t: cpFloat) callconv(.C) cpBB {
    const bb: cpBB = cpBB{
        .l = l,
        .b = b,
        .r = r,
        .t = t,
    };
    return bb;
}
pub fn cpBBNewForExtents(c: cpVect, hw: cpFloat, hh: cpFloat) callconv(.C) cpBB {
    return cpBBNew(c.x - hw, c.y - hh, c.x + hw, c.y + hh);
}
pub fn cpBBNewForCircle(p: cpVect, r: cpFloat) callconv(.C) cpBB {
    return cpBBNewForExtents(p, r, r);
}
pub fn cpBBIntersects(a: cpBB, b: cpBB) callconv(.C) cpBool {
    return @as(cpBool, @intFromBool((((a.l <= b.r) and (b.l <= a.r)) and (a.b <= b.t)) and (b.b <= a.t)));
}
pub fn cpBBContainsBB(bb: cpBB, other: cpBB) callconv(.C) cpBool {
    return @as(cpBool, @intFromBool((((bb.l <= other.l) and (bb.r >= other.r)) and (bb.b <= other.b)) and (bb.t >= other.t)));
}
pub fn cpBBContainsVect(bb: cpBB, v: cpVect) callconv(.C) cpBool {
    return @as(cpBool, @intFromBool((((bb.l <= v.x) and (bb.r >= v.x)) and (bb.b <= v.y)) and (bb.t >= v.y)));
}
pub fn cpBBMerge(a: cpBB, b: cpBB) callconv(.C) cpBB {
    return cpBBNew(cpfmin(a.l, b.l), cpfmin(a.b, b.b), cpfmax(a.r, b.r), cpfmax(a.t, b.t));
}
pub fn cpBBExpand(bb: cpBB, v: cpVect) callconv(.C) cpBB {
    return cpBBNew(cpfmin(bb.l, v.x), cpfmin(bb.b, v.y), cpfmax(bb.r, v.x), cpfmax(bb.t, v.y));
}
pub fn cpBBCenter(arg_bb: cpBB) callconv(.C) cpVect {
    const bb = arg_bb;
    return cpvlerp(cpv(bb.l, bb.b), cpv(bb.r, bb.t), 0.5);
}
pub fn cpBBArea(arg_bb: cpBB) callconv(.C) cpFloat {
    const bb = arg_bb;
    return (bb.r - bb.l) * (bb.t - bb.b);
}
pub fn cpBBMergedArea(arg_a: cpBB, arg_b: cpBB) callconv(.C) cpFloat {
    const a = arg_a;
    const b = arg_b;
    return (cpfmax(a.r, b.r) - cpfmin(a.l, b.l)) * (cpfmax(a.t, b.t) - cpfmin(a.b, b.b));
}
pub fn cpBBSegmentQuery(arg_bb: cpBB, arg_a: cpVect, arg_b: cpVect) callconv(.C) cpFloat {
    const bb = arg_bb;
    const a = arg_a;
    const b = arg_b;
    const delta: cpVect = cpvsub(b, a);
    const tmin: cpFloat = -__builtin_inff();
    const tmax: cpFloat = __builtin_inff();
    if (delta.x == 0.0) {
        if ((a.x < bb.l) or (bb.r < a.x)) return __builtin_inff();
    } else {
        const t1: cpFloat = (bb.l - a.x) / delta.x;
        const t2: cpFloat = (bb.r - a.x) / delta.x;
        tmin = cpfmax(tmin, cpfmin(t1, t2));
        tmax = cpfmin(tmax, cpfmax(t1, t2));
    }
    if (delta.y == 0.0) {
        if ((a.y < bb.b) or (bb.t < a.y)) return __builtin_inff();
    } else {
        const t1: cpFloat = (bb.b - a.y) / delta.y;
        const t2: cpFloat = (bb.t - a.y) / delta.y;
        tmin = cpfmax(tmin, cpfmin(t1, t2));
        tmax = cpfmin(tmax, cpfmax(t1, t2));
    }
    if (((tmin <= tmax) and (0.0 <= tmax)) and (tmin <= 1.0)) {
        return cpfmax(tmin, 0.0);
    } else {
        return __builtin_inff();
    }
    return @import("std").mem.zeroes(cpFloat);
}
pub fn cpBBIntersectsSegment(arg_bb: cpBB, arg_a: cpVect, arg_b: cpVect) callconv(.C) cpBool {
    const bb = arg_bb;
    const a = arg_a;
    const b = arg_b;
    return @as(cpBool, @intFromBool(cpBBSegmentQuery(bb, a, b) != __builtin_inff()));
}
pub fn cpBBClampVect(bb: cpBB, v: cpVect) callconv(.C) cpVect {
    return cpv(cpfclamp(v.x, bb.l, bb.r), cpfclamp(v.y, bb.b, bb.t));
}
pub fn cpBBWrapVect(bb: cpBB, v: cpVect) callconv(.C) cpVect {
    const dx: cpFloat = cpfabs(bb.r - bb.l);
    const modx: cpFloat = fmodf(v.x - bb.l, dx);
    const x: cpFloat = if (modx > 0.0) modx else modx + dx;
    const dy: cpFloat = cpfabs(bb.t - bb.b);
    const mody: cpFloat = fmodf(v.y - bb.b, dy);
    const y: cpFloat = if (mody > 0.0) mody else mody + dy;
    return cpv(x + bb.l, y + bb.b);
}
pub fn cpBBOffset(bb: cpBB, v: cpVect) callconv(.C) cpBB {
    return cpBBNew(bb.l + v.x, bb.b + v.y, bb.r + v.x, bb.t + v.y);
}
pub const cpTransformIdentity: cpTransform = cpTransform{
    .a = 1.0,
    .b = 0.0,
    .c = 0.0,
    .d = 1.0,
    .tx = 0.0,
    .ty = 0.0,
};
pub fn cpTransformNew(arg_a: cpFloat, arg_b: cpFloat, arg_c: cpFloat, arg_d: cpFloat, arg_tx: cpFloat, arg_ty: cpFloat) callconv(.C) cpTransform {
    const a = arg_a;
    const b = arg_b;
    const c = arg_c;
    const d = arg_d;
    const tx = arg_tx;
    const ty = arg_ty;
    const t: cpTransform = cpTransform{
        .a = a,
        .b = b,
        .c = c,
        .d = d,
        .tx = tx,
        .ty = ty,
    };
    return t;
}
pub fn cpTransformNewTranspose(arg_a: cpFloat, arg_c: cpFloat, arg_tx: cpFloat, arg_b: cpFloat, arg_d: cpFloat, arg_ty: cpFloat) callconv(.C) cpTransform {
    const a = arg_a;
    const c = arg_c;
    const tx = arg_tx;
    const b = arg_b;
    const d = arg_d;
    const ty = arg_ty;
    const t: cpTransform = cpTransform{
        .a = a,
        .b = b,
        .c = c,
        .d = d,
        .tx = tx,
        .ty = ty,
    };
    return t;
}
pub fn cpTransformInverse(arg_t: cpTransform) callconv(.C) cpTransform {
    const t = arg_t;
    const inv_det: cpFloat = @as(cpFloat, @floatCast(1.0 / @as(f64, @floatCast((t.a * t.d) - (t.c * t.b)))));
    return cpTransformNewTranspose(t.d * inv_det, -t.c * inv_det, ((t.c * t.ty) - (t.tx * t.d)) * inv_det, -t.b * inv_det, t.a * inv_det, ((t.tx * t.b) - (t.a * t.ty)) * inv_det);
}
pub fn cpTransformMult(arg_t1: cpTransform, arg_t2: cpTransform) callconv(.C) cpTransform {
    const t1 = arg_t1;
    const t2 = arg_t2;
    return cpTransformNewTranspose((t1.a * t2.a) + (t1.c * t2.b), (t1.a * t2.c) + (t1.c * t2.d), ((t1.a * t2.tx) + (t1.c * t2.ty)) + t1.tx, (t1.b * t2.a) + (t1.d * t2.b), (t1.b * t2.c) + (t1.d * t2.d), ((t1.b * t2.tx) + (t1.d * t2.ty)) + t1.ty);
}
pub fn cpTransformPoint(arg_t: cpTransform, arg_p: cpVect) callconv(.C) cpVect {
    const t = arg_t;
    const p = arg_p;
    return cpv(((t.a * p.x) + (t.c * p.y)) + t.tx, ((t.b * p.x) + (t.d * p.y)) + t.ty);
}
pub fn cpTransformVect(arg_t: cpTransform, arg_v: cpVect) callconv(.C) cpVect {
    const t = arg_t;
    const v = arg_v;
    return cpv((t.a * v.x) + (t.c * v.y), (t.b * v.x) + (t.d * v.y));
}
pub fn cpTransformbBB(arg_t: cpTransform, arg_bb: cpBB) callconv(.C) cpBB {
    const t = arg_t;
    const bb = arg_bb;
    const center: cpVect = cpBBCenter(bb);
    const hw: cpFloat = @as(cpFloat, @floatCast(@as(f64, @floatCast(bb.r - bb.l)) * 0.5));
    const hh: cpFloat = @as(cpFloat, @floatCast(@as(f64, @floatCast(bb.t - bb.b)) * 0.5));
    const a: cpFloat = t.a * hw;
    const b: cpFloat = t.c * hh;
    const d: cpFloat = t.b * hw;
    const e: cpFloat = t.d * hh;
    const hw_max: cpFloat = cpfmax(cpfabs(a + b), cpfabs(a - b));
    const hh_max: cpFloat = cpfmax(cpfabs(d + e), cpfabs(d - e));
    return cpBBNewForExtents(cpTransformPoint(t, center), hw_max, hh_max);
}
pub fn cpTransformTranslate(arg_translate: cpVect) callconv(.C) cpTransform {
    const translate = arg_translate;
    return cpTransformNewTranspose(@as(cpFloat, @floatCast(1.0)), @as(cpFloat, @floatCast(0.0)), translate.x, @as(cpFloat, @floatCast(0.0)), @as(cpFloat, @floatCast(1.0)), translate.y);
}
pub fn cpTransformScale(arg_scaleX: cpFloat, arg_scaleY: cpFloat) callconv(.C) cpTransform {
    const scaleX = arg_scaleX;
    const scaleY = arg_scaleY;
    return cpTransformNewTranspose(scaleX, @as(cpFloat, @floatCast(0.0)), @as(cpFloat, @floatCast(0.0)), @as(cpFloat, @floatCast(0.0)), scaleY, @as(cpFloat, @floatCast(0.0)));
}
pub fn cpTransformRotate(arg_radians: cpFloat) callconv(.C) cpTransform {
    const radians = arg_radians;
    const rot: cpVect = cpvforangle(radians);
    return cpTransformNewTranspose(rot.x, -rot.y, @as(cpFloat, @floatCast(0.0)), rot.y, rot.x, @as(cpFloat, @floatCast(0.0)));
}
pub fn cpTransformRigid(arg_translate: cpVect, arg_radians: cpFloat) callconv(.C) cpTransform {
    const translate = arg_translate;
    const radians = arg_radians;
    const rot: cpVect = cpvforangle(radians);
    return cpTransformNewTranspose(rot.x, -rot.y, translate.x, rot.y, rot.x, translate.y);
}
pub fn cpTransformRigidInverse(arg_t: cpTransform) callconv(.C) cpTransform {
    const t = arg_t;
    return cpTransformNewTranspose(t.d, -t.c, (t.c * t.ty) - (t.tx * t.d), -t.b, t.a, (t.tx * t.b) - (t.a * t.ty));
}
pub fn cpTransformWrap(arg_outer: cpTransform, arg_inner: cpTransform) callconv(.C) cpTransform {
    const outer = arg_outer;
    const inner = arg_inner;
    return cpTransformMult(cpTransformInverse(outer), cpTransformMult(inner, outer));
}
pub fn cpTransformWrapInverse(arg_outer: cpTransform, arg_inner: cpTransform) callconv(.C) cpTransform {
    const outer = arg_outer;
    const inner = arg_inner;
    return cpTransformMult(outer, cpTransformMult(inner, cpTransformInverse(outer)));
}
pub fn cpTransformOrtho(arg_bb: cpBB) callconv(.C) cpTransform {
    const bb = arg_bb;
    return cpTransformNewTranspose(@as(cpFloat, @floatCast(2.0 / @as(f64, @floatCast(bb.r - bb.l)))), @as(cpFloat, @floatCast(0.0)), -(bb.r + bb.l) / (bb.r - bb.l), @as(cpFloat, @floatCast(0.0)), @as(cpFloat, @floatCast(2.0 / @as(f64, @floatCast(bb.t - bb.b)))), -(bb.t + bb.b) / (bb.t - bb.b));
}
pub fn cpTransformBoneScale(arg_v0: cpVect, arg_v1: cpVect) callconv(.C) cpTransform {
    const v0 = arg_v0;
    const v1 = arg_v1;
    const d: cpVect = cpvsub(v1, v0);
    return cpTransformNewTranspose(d.x, -d.y, v0.x, d.y, d.x, v0.y);
}
pub fn cpTransformAxialScale(arg_axis: cpVect, arg_pivot: cpVect, arg_scale: cpFloat) callconv(.C) cpTransform {
    const axis = arg_axis;
    const pivot = arg_pivot;
    const scale = arg_scale;
    const A: cpFloat = @as(cpFloat, @floatCast(@as(f64, @floatCast(axis.x * axis.y)) * (@as(f64, @floatCast(scale)) - 1.0)));
    const B: cpFloat = @as(cpFloat, @floatCast(@as(f64, @floatCast(cpvdot(axis, pivot))) * (1.0 - @as(f64, @floatCast(scale)))));
    return cpTransformNewTranspose(((scale * axis.x) * axis.x) + (axis.y * axis.y), A, axis.x * B, A, (axis.x * axis.x) + ((scale * axis.y) * axis.y), axis.y * B);
}
pub const cpSpatialIndexBBFunc = ?*const fn (?*anyopaque) callconv(.C) cpBB;
pub const cpSpatialIndexIteratorFunc = ?*const fn (?*anyopaque, ?*anyopaque) callconv(.C) void;
pub const cpSpatialIndexQueryFunc = ?*const fn (?*anyopaque, ?*anyopaque, cpCollisionID, ?*anyopaque) callconv(.C) cpCollisionID;
pub const cpSpatialIndexSegmentQueryFunc = ?*const fn (?*anyopaque, ?*anyopaque, ?*anyopaque) callconv(.C) cpFloat;
pub const cpSpatialIndexClass = struct_cpSpatialIndexClass;
pub const struct_cpSpatialIndex = extern struct {
    klass: [*c]cpSpatialIndexClass = @import("std").mem.zeroes([*c]cpSpatialIndexClass),
    bbfunc: cpSpatialIndexBBFunc = @import("std").mem.zeroes(cpSpatialIndexBBFunc),
    staticIndex: [*c]cpSpatialIndex = @import("std").mem.zeroes([*c]cpSpatialIndex),
    dynamicIndex: [*c]cpSpatialIndex = @import("std").mem.zeroes([*c]cpSpatialIndex),
};
pub const cpSpatialIndex = struct_cpSpatialIndex;
pub const cpSpatialIndexDestroyImpl = ?*const fn ([*c]cpSpatialIndex) callconv(.C) void;
pub const cpSpatialIndexCountImpl = ?*const fn ([*c]cpSpatialIndex) callconv(.C) c_int;
pub const cpSpatialIndexEachImpl = ?*const fn ([*c]cpSpatialIndex, cpSpatialIndexIteratorFunc, ?*anyopaque) callconv(.C) void;
pub const cpSpatialIndexContainsImpl = ?*const fn ([*c]cpSpatialIndex, ?*anyopaque, cpHashValue) callconv(.C) cpBool;
pub const cpSpatialIndexInsertImpl = ?*const fn ([*c]cpSpatialIndex, ?*anyopaque, cpHashValue) callconv(.C) void;
pub const cpSpatialIndexRemoveImpl = ?*const fn ([*c]cpSpatialIndex, ?*anyopaque, cpHashValue) callconv(.C) void;
pub const cpSpatialIndexReindexImpl = ?*const fn ([*c]cpSpatialIndex) callconv(.C) void;
pub const cpSpatialIndexReindexObjectImpl = ?*const fn ([*c]cpSpatialIndex, ?*anyopaque, cpHashValue) callconv(.C) void;
pub const cpSpatialIndexReindexQueryImpl = ?*const fn ([*c]cpSpatialIndex, cpSpatialIndexQueryFunc, ?*anyopaque) callconv(.C) void;
pub const cpSpatialIndexQueryImpl = ?*const fn ([*c]cpSpatialIndex, ?*anyopaque, cpBB, cpSpatialIndexQueryFunc, ?*anyopaque) callconv(.C) void;
pub const cpSpatialIndexSegmentQueryImpl = ?*const fn ([*c]cpSpatialIndex, ?*anyopaque, cpVect, cpVect, cpFloat, cpSpatialIndexSegmentQueryFunc, ?*anyopaque) callconv(.C) void;
pub const struct_cpSpatialIndexClass = extern struct {
    destroy: cpSpatialIndexDestroyImpl = @import("std").mem.zeroes(cpSpatialIndexDestroyImpl),
    count: cpSpatialIndexCountImpl = @import("std").mem.zeroes(cpSpatialIndexCountImpl),
    each: cpSpatialIndexEachImpl = @import("std").mem.zeroes(cpSpatialIndexEachImpl),
    contains: cpSpatialIndexContainsImpl = @import("std").mem.zeroes(cpSpatialIndexContainsImpl),
    insert: cpSpatialIndexInsertImpl = @import("std").mem.zeroes(cpSpatialIndexInsertImpl),
    remove: cpSpatialIndexRemoveImpl = @import("std").mem.zeroes(cpSpatialIndexRemoveImpl),
    reindex: cpSpatialIndexReindexImpl = @import("std").mem.zeroes(cpSpatialIndexReindexImpl),
    reindexObject: cpSpatialIndexReindexObjectImpl = @import("std").mem.zeroes(cpSpatialIndexReindexObjectImpl),
    reindexQuery: cpSpatialIndexReindexQueryImpl = @import("std").mem.zeroes(cpSpatialIndexReindexQueryImpl),
    query: cpSpatialIndexQueryImpl = @import("std").mem.zeroes(cpSpatialIndexQueryImpl),
    segmentQuery: cpSpatialIndexSegmentQueryImpl = @import("std").mem.zeroes(cpSpatialIndexSegmentQueryImpl),
};
pub const struct_cpSpaceHash = opaque {};
pub const cpSpaceHash = struct_cpSpaceHash;
pub extern fn cpSpaceHashAlloc() ?*cpSpaceHash;
pub extern fn cpSpaceHashInit(hash: ?*cpSpaceHash, celldim: cpFloat, numcells: c_int, bbfunc: cpSpatialIndexBBFunc, staticIndex: [*c]cpSpatialIndex) [*c]cpSpatialIndex;
pub extern fn cpSpaceHashNew(celldim: cpFloat, cells: c_int, bbfunc: cpSpatialIndexBBFunc, staticIndex: [*c]cpSpatialIndex) [*c]cpSpatialIndex;
pub extern fn cpSpaceHashResize(hash: ?*cpSpaceHash, celldim: cpFloat, numcells: c_int) void;
pub const struct_cpBBTree = opaque {};
pub const cpBBTree = struct_cpBBTree;
pub extern fn cpBBTreeAlloc() ?*cpBBTree;
pub extern fn cpBBTreeInit(tree: ?*cpBBTree, bbfunc: cpSpatialIndexBBFunc, staticIndex: [*c]cpSpatialIndex) [*c]cpSpatialIndex;
pub extern fn cpBBTreeNew(bbfunc: cpSpatialIndexBBFunc, staticIndex: [*c]cpSpatialIndex) [*c]cpSpatialIndex;
pub extern fn cpBBTreeOptimize(index: [*c]cpSpatialIndex) void;
pub const cpBBTreeVelocityFunc = ?*const fn (?*anyopaque) callconv(.C) cpVect;
pub extern fn cpBBTreeSetVelocityFunc(index: [*c]cpSpatialIndex, func: cpBBTreeVelocityFunc) void;
pub const struct_cpSweep1D = opaque {};
pub const cpSweep1D = struct_cpSweep1D;
pub extern fn cpSweep1DAlloc() ?*cpSweep1D;
pub extern fn cpSweep1DInit(sweep: ?*cpSweep1D, bbfunc: cpSpatialIndexBBFunc, staticIndex: [*c]cpSpatialIndex) [*c]cpSpatialIndex;
pub extern fn cpSweep1DNew(bbfunc: cpSpatialIndexBBFunc, staticIndex: [*c]cpSpatialIndex) [*c]cpSpatialIndex;
pub extern fn cpSpatialIndexFree(index: [*c]cpSpatialIndex) void;
pub extern fn cpSpatialIndexCollideStatic(dynamicIndex: [*c]cpSpatialIndex, staticIndex: [*c]cpSpatialIndex, func: cpSpatialIndexQueryFunc, data: ?*anyopaque) void;
pub fn cpSpatialIndexDestroy(arg_index: [*c]cpSpatialIndex) callconv(.C) void {
    const index = arg_index;
    if (index.*.klass != null) {
        index.*.klass.*.destroy.?(index);
    }
}
pub fn cpSpatialIndexCount(arg_index: [*c]cpSpatialIndex) callconv(.C) c_int {
    const index = arg_index;
    return index.*.klass.*.count.?(index);
}
pub fn cpSpatialIndexEach(arg_index: [*c]cpSpatialIndex, arg_func: cpSpatialIndexIteratorFunc, arg_data: ?*anyopaque) callconv(.C) void {
    const index = arg_index;
    const func = arg_func;
    const data = arg_data;
    index.*.klass.*.each.?(index, func, data);
}
pub fn cpSpatialIndexContains(arg_index: [*c]cpSpatialIndex, arg_obj: ?*anyopaque, arg_hashid: cpHashValue) callconv(.C) cpBool {
    const index = arg_index;
    const obj = arg_obj;
    const hashid = arg_hashid;
    return index.*.klass.*.contains.?(index, obj, hashid);
}
pub fn cpSpatialIndexInsert(arg_index: [*c]cpSpatialIndex, arg_obj: ?*anyopaque, arg_hashid: cpHashValue) callconv(.C) void {
    const index = arg_index;
    const obj = arg_obj;
    const hashid = arg_hashid;
    index.*.klass.*.insert.?(index, obj, hashid);
}
pub fn cpSpatialIndexRemove(arg_index: [*c]cpSpatialIndex, arg_obj: ?*anyopaque, arg_hashid: cpHashValue) callconv(.C) void {
    const index = arg_index;
    const obj = arg_obj;
    const hashid = arg_hashid;
    index.*.klass.*.remove.?(index, obj, hashid);
}
pub fn cpSpatialIndexReindex(arg_index: [*c]cpSpatialIndex) callconv(.C) void {
    const index = arg_index;
    index.*.klass.*.reindex.?(index);
}
pub fn cpSpatialIndexReindexObject(arg_index: [*c]cpSpatialIndex, arg_obj: ?*anyopaque, arg_hashid: cpHashValue) callconv(.C) void {
    const index = arg_index;
    const obj = arg_obj;
    const hashid = arg_hashid;
    index.*.klass.*.reindexObject.?(index, obj, hashid);
}
pub fn cpSpatialIndexQuery(arg_index: [*c]cpSpatialIndex, arg_obj: ?*anyopaque, arg_bb: cpBB, arg_func: cpSpatialIndexQueryFunc, arg_data: ?*anyopaque) callconv(.C) void {
    const index = arg_index;
    const obj = arg_obj;
    const bb = arg_bb;
    const func = arg_func;
    const data = arg_data;
    index.*.klass.*.query.?(index, obj, bb, func, data);
}
pub fn cpSpatialIndexSegmentQuery(arg_index: [*c]cpSpatialIndex, arg_obj: ?*anyopaque, arg_a: cpVect, arg_b: cpVect, arg_t_exit: cpFloat, arg_func: cpSpatialIndexSegmentQueryFunc, arg_data: ?*anyopaque) callconv(.C) void {
    const index = arg_index;
    const obj = arg_obj;
    const a = arg_a;
    const b = arg_b;
    const t_exit = arg_t_exit;
    const func = arg_func;
    const data = arg_data;
    index.*.klass.*.segmentQuery.?(index, obj, a, b, t_exit, func, data);
}
pub fn cpSpatialIndexReindexQuery(arg_index: [*c]cpSpatialIndex, arg_func: cpSpatialIndexQueryFunc, arg_data: ?*anyopaque) callconv(.C) void {
    const index = arg_index;
    const func = arg_func;
    const data = arg_data;
    index.*.klass.*.reindexQuery.?(index, func, data);
}
pub extern fn cpArbiterGetRestitution(arb: ?*const cpArbiter) cpFloat;
pub extern fn cpArbiterSetRestitution(arb: ?*cpArbiter, restitution: cpFloat) void;
pub extern fn cpArbiterGetFriction(arb: ?*const cpArbiter) cpFloat;
pub extern fn cpArbiterSetFriction(arb: ?*cpArbiter, friction: cpFloat) void;
pub extern fn cpArbiterGetSurfaceVelocity(arb: ?*cpArbiter) cpVect;
pub extern fn cpArbiterSetSurfaceVelocity(arb: ?*cpArbiter, vr: cpVect) void;
pub extern fn cpArbiterGetUserData(arb: ?*const cpArbiter) cpDataPointer;
pub extern fn cpArbiterSetUserData(arb: ?*cpArbiter, userData: cpDataPointer) void;
pub extern fn cpArbiterTotalImpulse(arb: ?*const cpArbiter) cpVect;
pub extern fn cpArbiterTotalKE(arb: ?*const cpArbiter) cpFloat;
pub extern fn cpArbiterIgnore(arb: ?*cpArbiter) cpBool;
pub extern fn cpArbiterGetShapes(arb: ?*const cpArbiter, a: [*c]?*cpShape, b: [*c]?*cpShape) void;
pub extern fn cpArbiterGetBodies(arb: ?*const cpArbiter, a: [*c]?*cpBody, b: [*c]?*cpBody) void;
pub extern fn cpArbiterGetContactPointSet(arb: ?*const cpArbiter) cpContactPointSet;
pub extern fn cpArbiterSetContactPointSet(arb: ?*cpArbiter, set: [*c]cpContactPointSet) void;
pub extern fn cpArbiterIsFirstContact(arb: ?*const cpArbiter) cpBool;
pub extern fn cpArbiterIsRemoval(arb: ?*const cpArbiter) cpBool;
pub extern fn cpArbiterGetCount(arb: ?*const cpArbiter) c_int;
pub extern fn cpArbiterGetNormal(arb: ?*const cpArbiter) cpVect;
pub extern fn cpArbiterGetPointA(arb: ?*const cpArbiter, i: c_int) cpVect;
pub extern fn cpArbiterGetPointB(arb: ?*const cpArbiter, i: c_int) cpVect;
pub extern fn cpArbiterGetDepth(arb: ?*const cpArbiter, i: c_int) cpFloat;
pub extern fn cpArbiterCallWildcardBeginA(arb: ?*cpArbiter, space: ?*cpSpace) cpBool;
pub extern fn cpArbiterCallWildcardBeginB(arb: ?*cpArbiter, space: ?*cpSpace) cpBool;
pub extern fn cpArbiterCallWildcardPreSolveA(arb: ?*cpArbiter, space: ?*cpSpace) cpBool;
pub extern fn cpArbiterCallWildcardPreSolveB(arb: ?*cpArbiter, space: ?*cpSpace) cpBool;
pub extern fn cpArbiterCallWildcardPostSolveA(arb: ?*cpArbiter, space: ?*cpSpace) void;
pub extern fn cpArbiterCallWildcardPostSolveB(arb: ?*cpArbiter, space: ?*cpSpace) void;
pub extern fn cpArbiterCallWildcardSeparateA(arb: ?*cpArbiter, space: ?*cpSpace) void;
pub extern fn cpArbiterCallWildcardSeparateB(arb: ?*cpArbiter, space: ?*cpSpace) void;
pub const CP_BODY_TYPE_DYNAMIC: c_int = 0;
pub const CP_BODY_TYPE_KINEMATIC: c_int = 1;
pub const CP_BODY_TYPE_STATIC: c_int = 2;
pub const enum_cpBodyType = c_uint;
pub const cpBodyType = enum_cpBodyType;
pub const cpBodyVelocityFunc = ?*const fn (?*cpBody, cpVect, cpFloat, cpFloat) callconv(.C) void;
pub const cpBodyPositionFunc = ?*const fn (?*cpBody, cpFloat) callconv(.C) void;
pub extern fn cpBodyAlloc() ?*cpBody;
pub extern fn cpBodyInit(body: ?*cpBody, mass: cpFloat, moment: cpFloat) ?*cpBody;
pub extern fn cpBodyNew(mass: cpFloat, moment: cpFloat) ?*cpBody;
pub extern fn cpBodyNewKinematic() ?*cpBody;
pub extern fn cpBodyNewStatic() ?*cpBody;
pub extern fn cpBodyDestroy(body: ?*cpBody) void;
pub extern fn cpBodyFree(body: ?*cpBody) void;
pub extern fn cpBodyActivate(body: ?*cpBody) void;
pub extern fn cpBodyActivateStatic(body: ?*cpBody, filter: ?*cpShape) void;
pub extern fn cpBodySleep(body: ?*cpBody) void;
pub extern fn cpBodySleepWithGroup(body: ?*cpBody, group: ?*cpBody) void;
pub extern fn cpBodyIsSleeping(body: ?*const cpBody) cpBool;
pub extern fn cpBodyGetType(body: ?*cpBody) cpBodyType;
pub extern fn cpBodySetType(body: ?*cpBody, @"type": cpBodyType) void;
pub extern fn cpBodyGetSpace(body: ?*const cpBody) ?*cpSpace;
pub extern fn cpBodyGetMass(body: ?*const cpBody) cpFloat;
pub extern fn cpBodySetMass(body: ?*cpBody, m: cpFloat) void;
pub extern fn cpBodyGetMoment(body: ?*const cpBody) cpFloat;
pub extern fn cpBodySetMoment(body: ?*cpBody, i: cpFloat) void;
pub extern fn cpBodyGetPosition(body: ?*const cpBody) cpVect;
pub extern fn cpBodySetPosition(body: ?*cpBody, pos: cpVect) void;
pub extern fn cpBodyGetCenterOfGravity(body: ?*const cpBody) cpVect;
pub extern fn cpBodySetCenterOfGravity(body: ?*cpBody, cog: cpVect) void;
pub extern fn cpBodyGetVelocity(body: ?*const cpBody) cpVect;
pub extern fn cpBodySetVelocity(body: ?*cpBody, velocity: cpVect) void;
pub extern fn cpBodyGetForce(body: ?*const cpBody) cpVect;
pub extern fn cpBodySetForce(body: ?*cpBody, force: cpVect) void;
pub extern fn cpBodyGetAngle(body: ?*const cpBody) cpFloat;
pub extern fn cpBodySetAngle(body: ?*cpBody, a: cpFloat) void;
pub extern fn cpBodyGetAngularVelocity(body: ?*const cpBody) cpFloat;
pub extern fn cpBodySetAngularVelocity(body: ?*cpBody, angularVelocity: cpFloat) void;
pub extern fn cpBodyGetTorque(body: ?*const cpBody) cpFloat;
pub extern fn cpBodySetTorque(body: ?*cpBody, torque: cpFloat) void;
pub extern fn cpBodyGetRotation(body: ?*const cpBody) cpVect;
pub extern fn cpBodyGetUserData(body: ?*const cpBody) cpDataPointer;
pub extern fn cpBodySetUserData(body: ?*cpBody, userData: cpDataPointer) void;
pub extern fn cpBodySetVelocityUpdateFunc(body: ?*cpBody, velocityFunc: cpBodyVelocityFunc) void;
pub extern fn cpBodySetPositionUpdateFunc(body: ?*cpBody, positionFunc: cpBodyPositionFunc) void;
pub extern fn cpBodyUpdateVelocity(body: ?*cpBody, gravity: cpVect, damping: cpFloat, dt: cpFloat) void;
pub extern fn cpBodyUpdatePosition(body: ?*cpBody, dt: cpFloat) void;
pub extern fn cpBodyLocalToWorld(body: ?*const cpBody, point: cpVect) cpVect;
pub extern fn cpBodyWorldToLocal(body: ?*const cpBody, point: cpVect) cpVect;
pub extern fn cpBodyApplyForceAtWorldPoint(body: ?*cpBody, force: cpVect, point: cpVect) void;
pub extern fn cpBodyApplyForceAtLocalPoint(body: ?*cpBody, force: cpVect, point: cpVect) void;
pub extern fn cpBodyApplyImpulseAtWorldPoint(body: ?*cpBody, impulse: cpVect, point: cpVect) void;
pub extern fn cpBodyApplyImpulseAtLocalPoint(body: ?*cpBody, impulse: cpVect, point: cpVect) void;
pub extern fn cpBodyGetVelocityAtWorldPoint(body: ?*const cpBody, point: cpVect) cpVect;
pub extern fn cpBodyGetVelocityAtLocalPoint(body: ?*const cpBody, point: cpVect) cpVect;
pub extern fn cpBodyKineticEnergy(body: ?*const cpBody) cpFloat;
pub const cpBodyShapeIteratorFunc = ?*const fn (?*cpBody, ?*cpShape, ?*anyopaque) callconv(.C) void;
pub extern fn cpBodyEachShape(body: ?*cpBody, func: cpBodyShapeIteratorFunc, data: ?*anyopaque) void;
pub const cpBodyConstraintIteratorFunc = ?*const fn (?*cpBody, ?*cpConstraint, ?*anyopaque) callconv(.C) void;
pub extern fn cpBodyEachConstraint(body: ?*cpBody, func: cpBodyConstraintIteratorFunc, data: ?*anyopaque) void;
pub const cpBodyArbiterIteratorFunc = ?*const fn (?*cpBody, ?*cpArbiter, ?*anyopaque) callconv(.C) void;
pub extern fn cpBodyEachArbiter(body: ?*cpBody, func: cpBodyArbiterIteratorFunc, data: ?*anyopaque) void;
pub const struct_cpPointQueryInfo = extern struct {
    shape: ?*const cpShape = @import("std").mem.zeroes(?*const cpShape),
    point: cpVect = @import("std").mem.zeroes(cpVect),
    distance: cpFloat = @import("std").mem.zeroes(cpFloat),
    gradient: cpVect = @import("std").mem.zeroes(cpVect),
};
pub const cpPointQueryInfo = struct_cpPointQueryInfo;
pub const struct_cpSegmentQueryInfo = extern struct {
    shape: ?*const cpShape = @import("std").mem.zeroes(?*const cpShape),
    point: cpVect = @import("std").mem.zeroes(cpVect),
    normal: cpVect = @import("std").mem.zeroes(cpVect),
    alpha: cpFloat = @import("std").mem.zeroes(cpFloat),
};
pub const cpSegmentQueryInfo = struct_cpSegmentQueryInfo;
pub const struct_cpShapeFilter = extern struct {
    group: cpGroup = @import("std").mem.zeroes(cpGroup),
    categories: cpBitmask = @import("std").mem.zeroes(cpBitmask),
    mask: cpBitmask = @import("std").mem.zeroes(cpBitmask),
};
pub const cpShapeFilter = struct_cpShapeFilter;
pub const CP_SHAPE_FILTER_ALL: cpShapeFilter = cpShapeFilter{
    .group = @as(cpGroup, @bitCast(@as(c_long, @as(c_int, 0)))),
    .categories = ~@as(cpBitmask, @bitCast(@as(c_int, 0))),
    .mask = ~@as(cpBitmask, @bitCast(@as(c_int, 0))),
};
pub const CP_SHAPE_FILTER_NONE: cpShapeFilter = cpShapeFilter{
    .group = @as(cpGroup, @bitCast(@as(c_long, @as(c_int, 0)))),
    .categories = ~~@as(cpBitmask, @bitCast(@as(c_int, 0))),
    .mask = ~~@as(cpBitmask, @bitCast(@as(c_int, 0))),
};
pub fn cpShapeFilterNew(arg_group: cpGroup, arg_categories: cpBitmask, arg_mask: cpBitmask) callconv(.C) cpShapeFilter {
    const group = arg_group;
    const categories = arg_categories;
    const mask = arg_mask;
    const filter: cpShapeFilter = cpShapeFilter{
        .group = group,
        .categories = categories,
        .mask = mask,
    };
    return filter;
}
pub extern fn cpShapeDestroy(shape: ?*cpShape) void;
pub extern fn cpShapeFree(shape: ?*cpShape) void;
pub extern fn cpShapeCacheBB(shape: ?*cpShape) cpBB;
pub extern fn cpShapeUpdate(shape: ?*cpShape, transform: cpTransform) cpBB;
pub extern fn cpShapePointQuery(shape: ?*const cpShape, p: cpVect, out: [*c]cpPointQueryInfo) cpFloat;
pub extern fn cpShapeSegmentQuery(shape: ?*const cpShape, a: cpVect, b: cpVect, radius: cpFloat, info: [*c]cpSegmentQueryInfo) cpBool;
pub extern fn cpShapesCollide(a: ?*const cpShape, b: ?*const cpShape) cpContactPointSet;
pub extern fn cpShapeGetSpace(shape: ?*const cpShape) ?*cpSpace;
pub extern fn cpShapeGetBody(shape: ?*const cpShape) ?*cpBody;
pub extern fn cpShapeSetBody(shape: ?*cpShape, body: ?*cpBody) void;
pub extern fn cpShapeGetMass(shape: ?*cpShape) cpFloat;
pub extern fn cpShapeSetMass(shape: ?*cpShape, mass: cpFloat) void;
pub extern fn cpShapeGetDensity(shape: ?*cpShape) cpFloat;
pub extern fn cpShapeSetDensity(shape: ?*cpShape, density: cpFloat) void;
pub extern fn cpShapeGetMoment(shape: ?*cpShape) cpFloat;
pub extern fn cpShapeGetArea(shape: ?*cpShape) cpFloat;
pub extern fn cpShapeGetCenterOfGravity(shape: ?*cpShape) cpVect;
pub extern fn cpShapeGetBB(shape: ?*const cpShape) cpBB;
pub extern fn cpShapeGetSensor(shape: ?*const cpShape) cpBool;
pub extern fn cpShapeSetSensor(shape: ?*cpShape, sensor: cpBool) void;
pub extern fn cpShapeGetElasticity(shape: ?*const cpShape) cpFloat;
pub extern fn cpShapeSetElasticity(shape: ?*cpShape, elasticity: cpFloat) void;
pub extern fn cpShapeGetFriction(shape: ?*const cpShape) cpFloat;
pub extern fn cpShapeSetFriction(shape: ?*cpShape, friction: cpFloat) void;
pub extern fn cpShapeGetSurfaceVelocity(shape: ?*const cpShape) cpVect;
pub extern fn cpShapeSetSurfaceVelocity(shape: ?*cpShape, surfaceVelocity: cpVect) void;
pub extern fn cpShapeGetUserData(shape: ?*const cpShape) cpDataPointer;
pub extern fn cpShapeSetUserData(shape: ?*cpShape, userData: cpDataPointer) void;
pub extern fn cpShapeGetCollisionType(shape: ?*const cpShape) cpCollisionType;
pub extern fn cpShapeSetCollisionType(shape: ?*cpShape, collisionType: cpCollisionType) void;
pub extern fn cpShapeGetFilter(shape: ?*const cpShape) cpShapeFilter;
pub extern fn cpShapeSetFilter(shape: ?*cpShape, filter: cpShapeFilter) void;
pub extern fn cpCircleShapeAlloc() ?*cpCircleShape;
pub extern fn cpCircleShapeInit(circle: ?*cpCircleShape, body: ?*cpBody, radius: cpFloat, offset: cpVect) ?*cpCircleShape;
pub extern fn cpCircleShapeNew(body: ?*cpBody, radius: cpFloat, offset: cpVect) ?*cpShape;
pub extern fn cpCircleShapeGetOffset(shape: ?*const cpShape) cpVect;
pub extern fn cpCircleShapeGetRadius(shape: ?*const cpShape) cpFloat;
pub extern fn cpSegmentShapeAlloc() ?*cpSegmentShape;
pub extern fn cpSegmentShapeInit(seg: ?*cpSegmentShape, body: ?*cpBody, a: cpVect, b: cpVect, radius: cpFloat) ?*cpSegmentShape;
pub extern fn cpSegmentShapeNew(body: ?*cpBody, a: cpVect, b: cpVect, radius: cpFloat) ?*cpShape;
pub extern fn cpSegmentShapeSetNeighbors(shape: ?*cpShape, prev: cpVect, next: cpVect) void;
pub extern fn cpSegmentShapeGetA(shape: ?*const cpShape) cpVect;
pub extern fn cpSegmentShapeGetB(shape: ?*const cpShape) cpVect;
pub extern fn cpSegmentShapeGetNormal(shape: ?*const cpShape) cpVect;
pub extern fn cpSegmentShapeGetRadius(shape: ?*const cpShape) cpFloat;
pub extern fn cpPolyShapeAlloc() ?*cpPolyShape;
pub extern fn cpPolyShapeInit(poly: ?*cpPolyShape, body: ?*cpBody, count: c_int, verts: [*c]const cpVect, transform: cpTransform, radius: cpFloat) ?*cpPolyShape;
pub extern fn cpPolyShapeInitRaw(poly: ?*cpPolyShape, body: ?*cpBody, count: c_int, verts: [*c]const cpVect, radius: cpFloat) ?*cpPolyShape;
pub extern fn cpPolyShapeNew(body: ?*cpBody, count: c_int, verts: [*c]const cpVect, transform: cpTransform, radius: cpFloat) ?*cpShape;
pub extern fn cpPolyShapeNewRaw(body: ?*cpBody, count: c_int, verts: [*c]const cpVect, radius: cpFloat) ?*cpShape;
pub extern fn cpBoxShapeInit(poly: ?*cpPolyShape, body: ?*cpBody, width: cpFloat, height: cpFloat, radius: cpFloat) ?*cpPolyShape;
pub extern fn cpBoxShapeInit2(poly: ?*cpPolyShape, body: ?*cpBody, box: cpBB, radius: cpFloat) ?*cpPolyShape;
pub extern fn cpBoxShapeNew(body: ?*cpBody, width: cpFloat, height: cpFloat, radius: cpFloat) ?*cpShape;
pub extern fn cpBoxShapeNew2(body: ?*cpBody, box: cpBB, radius: cpFloat) ?*cpShape;
pub extern fn cpPolyShapeGetCount(shape: ?*const cpShape) c_int;
pub extern fn cpPolyShapeGetVert(shape: ?*const cpShape, index: c_int) cpVect;
pub extern fn cpPolyShapeGetRadius(shape: ?*const cpShape) cpFloat;
pub const cpConstraintPreSolveFunc = ?*const fn (?*cpConstraint, ?*cpSpace) callconv(.C) void;
pub const cpConstraintPostSolveFunc = ?*const fn (?*cpConstraint, ?*cpSpace) callconv(.C) void;
pub extern fn cpConstraintDestroy(constraint: ?*cpConstraint) void;
pub extern fn cpConstraintFree(constraint: ?*cpConstraint) void;
pub extern fn cpConstraintGetSpace(constraint: ?*const cpConstraint) ?*cpSpace;
pub extern fn cpConstraintGetBodyA(constraint: ?*const cpConstraint) ?*cpBody;
pub extern fn cpConstraintGetBodyB(constraint: ?*const cpConstraint) ?*cpBody;
pub extern fn cpConstraintGetMaxForce(constraint: ?*const cpConstraint) cpFloat;
pub extern fn cpConstraintSetMaxForce(constraint: ?*cpConstraint, maxForce: cpFloat) void;
pub extern fn cpConstraintGetErrorBias(constraint: ?*const cpConstraint) cpFloat;
pub extern fn cpConstraintSetErrorBias(constraint: ?*cpConstraint, errorBias: cpFloat) void;
pub extern fn cpConstraintGetMaxBias(constraint: ?*const cpConstraint) cpFloat;
pub extern fn cpConstraintSetMaxBias(constraint: ?*cpConstraint, maxBias: cpFloat) void;
pub extern fn cpConstraintGetCollideBodies(constraint: ?*const cpConstraint) cpBool;
pub extern fn cpConstraintSetCollideBodies(constraint: ?*cpConstraint, collideBodies: cpBool) void;
pub extern fn cpConstraintGetPreSolveFunc(constraint: ?*const cpConstraint) cpConstraintPreSolveFunc;
pub extern fn cpConstraintSetPreSolveFunc(constraint: ?*cpConstraint, preSolveFunc: cpConstraintPreSolveFunc) void;
pub extern fn cpConstraintGetPostSolveFunc(constraint: ?*const cpConstraint) cpConstraintPostSolveFunc;
pub extern fn cpConstraintSetPostSolveFunc(constraint: ?*cpConstraint, postSolveFunc: cpConstraintPostSolveFunc) void;
pub extern fn cpConstraintGetUserData(constraint: ?*const cpConstraint) cpDataPointer;
pub extern fn cpConstraintSetUserData(constraint: ?*cpConstraint, userData: cpDataPointer) void;
pub extern fn cpConstraintGetImpulse(constraint: ?*cpConstraint) cpFloat;
pub extern fn cpConstraintIsPinJoint(constraint: ?*const cpConstraint) cpBool;
pub extern fn cpPinJointAlloc() ?*cpPinJoint;
pub extern fn cpPinJointInit(joint: ?*cpPinJoint, a: ?*cpBody, b: ?*cpBody, anchorA: cpVect, anchorB: cpVect) ?*cpPinJoint;
pub extern fn cpPinJointNew(a: ?*cpBody, b: ?*cpBody, anchorA: cpVect, anchorB: cpVect) ?*cpConstraint;
pub extern fn cpPinJointGetAnchorA(constraint: ?*const cpConstraint) cpVect;
pub extern fn cpPinJointSetAnchorA(constraint: ?*cpConstraint, anchorA: cpVect) void;
pub extern fn cpPinJointGetAnchorB(constraint: ?*const cpConstraint) cpVect;
pub extern fn cpPinJointSetAnchorB(constraint: ?*cpConstraint, anchorB: cpVect) void;
pub extern fn cpPinJointGetDist(constraint: ?*const cpConstraint) cpFloat;
pub extern fn cpPinJointSetDist(constraint: ?*cpConstraint, dist: cpFloat) void;
pub extern fn cpConstraintIsSlideJoint(constraint: ?*const cpConstraint) cpBool;
pub extern fn cpSlideJointAlloc() ?*cpSlideJoint;
pub extern fn cpSlideJointInit(joint: ?*cpSlideJoint, a: ?*cpBody, b: ?*cpBody, anchorA: cpVect, anchorB: cpVect, min: cpFloat, max: cpFloat) ?*cpSlideJoint;
pub extern fn cpSlideJointNew(a: ?*cpBody, b: ?*cpBody, anchorA: cpVect, anchorB: cpVect, min: cpFloat, max: cpFloat) ?*cpConstraint;
pub extern fn cpSlideJointGetAnchorA(constraint: ?*const cpConstraint) cpVect;
pub extern fn cpSlideJointSetAnchorA(constraint: ?*cpConstraint, anchorA: cpVect) void;
pub extern fn cpSlideJointGetAnchorB(constraint: ?*const cpConstraint) cpVect;
pub extern fn cpSlideJointSetAnchorB(constraint: ?*cpConstraint, anchorB: cpVect) void;
pub extern fn cpSlideJointGetMin(constraint: ?*const cpConstraint) cpFloat;
pub extern fn cpSlideJointSetMin(constraint: ?*cpConstraint, min: cpFloat) void;
pub extern fn cpSlideJointGetMax(constraint: ?*const cpConstraint) cpFloat;
pub extern fn cpSlideJointSetMax(constraint: ?*cpConstraint, max: cpFloat) void;
pub extern fn cpConstraintIsPivotJoint(constraint: ?*const cpConstraint) cpBool;
pub extern fn cpPivotJointAlloc() ?*cpPivotJoint;
pub extern fn cpPivotJointInit(joint: ?*cpPivotJoint, a: ?*cpBody, b: ?*cpBody, anchorA: cpVect, anchorB: cpVect) ?*cpPivotJoint;
pub extern fn cpPivotJointNew(a: ?*cpBody, b: ?*cpBody, pivot: cpVect) ?*cpConstraint;
pub extern fn cpPivotJointNew2(a: ?*cpBody, b: ?*cpBody, anchorA: cpVect, anchorB: cpVect) ?*cpConstraint;
pub extern fn cpPivotJointGetAnchorA(constraint: ?*const cpConstraint) cpVect;
pub extern fn cpPivotJointSetAnchorA(constraint: ?*cpConstraint, anchorA: cpVect) void;
pub extern fn cpPivotJointGetAnchorB(constraint: ?*const cpConstraint) cpVect;
pub extern fn cpPivotJointSetAnchorB(constraint: ?*cpConstraint, anchorB: cpVect) void;
pub extern fn cpConstraintIsGrooveJoint(constraint: ?*const cpConstraint) cpBool;
pub extern fn cpGrooveJointAlloc() ?*cpGrooveJoint;
pub extern fn cpGrooveJointInit(joint: ?*cpGrooveJoint, a: ?*cpBody, b: ?*cpBody, groove_a: cpVect, groove_b: cpVect, anchorB: cpVect) ?*cpGrooveJoint;
pub extern fn cpGrooveJointNew(a: ?*cpBody, b: ?*cpBody, groove_a: cpVect, groove_b: cpVect, anchorB: cpVect) ?*cpConstraint;
pub extern fn cpGrooveJointGetGrooveA(constraint: ?*const cpConstraint) cpVect;
pub extern fn cpGrooveJointSetGrooveA(constraint: ?*cpConstraint, grooveA: cpVect) void;
pub extern fn cpGrooveJointGetGrooveB(constraint: ?*const cpConstraint) cpVect;
pub extern fn cpGrooveJointSetGrooveB(constraint: ?*cpConstraint, grooveB: cpVect) void;
pub extern fn cpGrooveJointGetAnchorB(constraint: ?*const cpConstraint) cpVect;
pub extern fn cpGrooveJointSetAnchorB(constraint: ?*cpConstraint, anchorB: cpVect) void;
pub extern fn cpConstraintIsDampedSpring(constraint: ?*const cpConstraint) cpBool;
pub const cpDampedSpringForceFunc = ?*const fn (?*cpConstraint, cpFloat) callconv(.C) cpFloat;
pub extern fn cpDampedSpringAlloc() ?*cpDampedSpring;
pub extern fn cpDampedSpringInit(joint: ?*cpDampedSpring, a: ?*cpBody, b: ?*cpBody, anchorA: cpVect, anchorB: cpVect, restLength: cpFloat, stiffness: cpFloat, damping: cpFloat) ?*cpDampedSpring;
pub extern fn cpDampedSpringNew(a: ?*cpBody, b: ?*cpBody, anchorA: cpVect, anchorB: cpVect, restLength: cpFloat, stiffness: cpFloat, damping: cpFloat) ?*cpConstraint;
pub extern fn cpDampedSpringGetAnchorA(constraint: ?*const cpConstraint) cpVect;
pub extern fn cpDampedSpringSetAnchorA(constraint: ?*cpConstraint, anchorA: cpVect) void;
pub extern fn cpDampedSpringGetAnchorB(constraint: ?*const cpConstraint) cpVect;
pub extern fn cpDampedSpringSetAnchorB(constraint: ?*cpConstraint, anchorB: cpVect) void;
pub extern fn cpDampedSpringGetRestLength(constraint: ?*const cpConstraint) cpFloat;
pub extern fn cpDampedSpringSetRestLength(constraint: ?*cpConstraint, restLength: cpFloat) void;
pub extern fn cpDampedSpringGetStiffness(constraint: ?*const cpConstraint) cpFloat;
pub extern fn cpDampedSpringSetStiffness(constraint: ?*cpConstraint, stiffness: cpFloat) void;
pub extern fn cpDampedSpringGetDamping(constraint: ?*const cpConstraint) cpFloat;
pub extern fn cpDampedSpringSetDamping(constraint: ?*cpConstraint, damping: cpFloat) void;
pub extern fn cpDampedSpringGetSpringForceFunc(constraint: ?*const cpConstraint) cpDampedSpringForceFunc;
pub extern fn cpDampedSpringSetSpringForceFunc(constraint: ?*cpConstraint, springForceFunc: cpDampedSpringForceFunc) void;
pub extern fn cpConstraintIsDampedRotarySpring(constraint: ?*const cpConstraint) cpBool;
pub const cpDampedRotarySpringTorqueFunc = ?*const fn (?*struct_cpConstraint, cpFloat) callconv(.C) cpFloat;
pub extern fn cpDampedRotarySpringAlloc() ?*cpDampedRotarySpring;
pub extern fn cpDampedRotarySpringInit(joint: ?*cpDampedRotarySpring, a: ?*cpBody, b: ?*cpBody, restAngle: cpFloat, stiffness: cpFloat, damping: cpFloat) ?*cpDampedRotarySpring;
pub extern fn cpDampedRotarySpringNew(a: ?*cpBody, b: ?*cpBody, restAngle: cpFloat, stiffness: cpFloat, damping: cpFloat) ?*cpConstraint;
pub extern fn cpDampedRotarySpringGetRestAngle(constraint: ?*const cpConstraint) cpFloat;
pub extern fn cpDampedRotarySpringSetRestAngle(constraint: ?*cpConstraint, restAngle: cpFloat) void;
pub extern fn cpDampedRotarySpringGetStiffness(constraint: ?*const cpConstraint) cpFloat;
pub extern fn cpDampedRotarySpringSetStiffness(constraint: ?*cpConstraint, stiffness: cpFloat) void;
pub extern fn cpDampedRotarySpringGetDamping(constraint: ?*const cpConstraint) cpFloat;
pub extern fn cpDampedRotarySpringSetDamping(constraint: ?*cpConstraint, damping: cpFloat) void;
pub extern fn cpDampedRotarySpringGetSpringTorqueFunc(constraint: ?*const cpConstraint) cpDampedRotarySpringTorqueFunc;
pub extern fn cpDampedRotarySpringSetSpringTorqueFunc(constraint: ?*cpConstraint, springTorqueFunc: cpDampedRotarySpringTorqueFunc) void;
pub extern fn cpConstraintIsRotaryLimitJoint(constraint: ?*const cpConstraint) cpBool;
pub extern fn cpRotaryLimitJointAlloc() ?*cpRotaryLimitJoint;
pub extern fn cpRotaryLimitJointInit(joint: ?*cpRotaryLimitJoint, a: ?*cpBody, b: ?*cpBody, min: cpFloat, max: cpFloat) ?*cpRotaryLimitJoint;
pub extern fn cpRotaryLimitJointNew(a: ?*cpBody, b: ?*cpBody, min: cpFloat, max: cpFloat) ?*cpConstraint;
pub extern fn cpRotaryLimitJointGetMin(constraint: ?*const cpConstraint) cpFloat;
pub extern fn cpRotaryLimitJointSetMin(constraint: ?*cpConstraint, min: cpFloat) void;
pub extern fn cpRotaryLimitJointGetMax(constraint: ?*const cpConstraint) cpFloat;
pub extern fn cpRotaryLimitJointSetMax(constraint: ?*cpConstraint, max: cpFloat) void;
pub extern fn cpConstraintIsRatchetJoint(constraint: ?*const cpConstraint) cpBool;
pub extern fn cpRatchetJointAlloc() ?*cpRatchetJoint;
pub extern fn cpRatchetJointInit(joint: ?*cpRatchetJoint, a: ?*cpBody, b: ?*cpBody, phase: cpFloat, ratchet: cpFloat) ?*cpRatchetJoint;
pub extern fn cpRatchetJointNew(a: ?*cpBody, b: ?*cpBody, phase: cpFloat, ratchet: cpFloat) ?*cpConstraint;
pub extern fn cpRatchetJointGetAngle(constraint: ?*const cpConstraint) cpFloat;
pub extern fn cpRatchetJointSetAngle(constraint: ?*cpConstraint, angle: cpFloat) void;
pub extern fn cpRatchetJointGetPhase(constraint: ?*const cpConstraint) cpFloat;
pub extern fn cpRatchetJointSetPhase(constraint: ?*cpConstraint, phase: cpFloat) void;
pub extern fn cpRatchetJointGetRatchet(constraint: ?*const cpConstraint) cpFloat;
pub extern fn cpRatchetJointSetRatchet(constraint: ?*cpConstraint, ratchet: cpFloat) void;
pub extern fn cpConstraintIsGearJoint(constraint: ?*const cpConstraint) cpBool;
pub extern fn cpGearJointAlloc() ?*cpGearJoint;
pub extern fn cpGearJointInit(joint: ?*cpGearJoint, a: ?*cpBody, b: ?*cpBody, phase: cpFloat, ratio: cpFloat) ?*cpGearJoint;
pub extern fn cpGearJointNew(a: ?*cpBody, b: ?*cpBody, phase: cpFloat, ratio: cpFloat) ?*cpConstraint;
pub extern fn cpGearJointGetPhase(constraint: ?*const cpConstraint) cpFloat;
pub extern fn cpGearJointSetPhase(constraint: ?*cpConstraint, phase: cpFloat) void;
pub extern fn cpGearJointGetRatio(constraint: ?*const cpConstraint) cpFloat;
pub extern fn cpGearJointSetRatio(constraint: ?*cpConstraint, ratio: cpFloat) void;
pub const struct_cpSimpleMotor = opaque {};
pub const cpSimpleMotor = struct_cpSimpleMotor;
pub extern fn cpConstraintIsSimpleMotor(constraint: ?*const cpConstraint) cpBool;
pub extern fn cpSimpleMotorAlloc() ?*cpSimpleMotor;
pub extern fn cpSimpleMotorInit(joint: ?*cpSimpleMotor, a: ?*cpBody, b: ?*cpBody, rate: cpFloat) ?*cpSimpleMotor;
pub extern fn cpSimpleMotorNew(a: ?*cpBody, b: ?*cpBody, rate: cpFloat) ?*cpConstraint;
pub extern fn cpSimpleMotorGetRate(constraint: ?*const cpConstraint) cpFloat;
pub extern fn cpSimpleMotorSetRate(constraint: ?*cpConstraint, rate: cpFloat) void;
pub extern fn cpSpaceAlloc() ?*cpSpace;
pub extern fn cpSpaceInit(space: ?*cpSpace) ?*cpSpace;
pub extern fn cpSpaceNew() ?*cpSpace;
pub extern fn cpSpaceDestroy(space: ?*cpSpace) void;
pub extern fn cpSpaceFree(space: ?*cpSpace) void;
pub extern fn cpSpaceGetIterations(space: ?*const cpSpace) c_int;
pub extern fn cpSpaceSetIterations(space: ?*cpSpace, iterations: c_int) void;
pub extern fn cpSpaceGetGravity(space: ?*const cpSpace) cpVect;
pub extern fn cpSpaceSetGravity(space: ?*cpSpace, gravity: cpVect) void;
pub extern fn cpSpaceGetDamping(space: ?*const cpSpace) cpFloat;
pub extern fn cpSpaceSetDamping(space: ?*cpSpace, damping: cpFloat) void;
pub extern fn cpSpaceGetIdleSpeedThreshold(space: ?*const cpSpace) cpFloat;
pub extern fn cpSpaceSetIdleSpeedThreshold(space: ?*cpSpace, idleSpeedThreshold: cpFloat) void;
pub extern fn cpSpaceGetSleepTimeThreshold(space: ?*const cpSpace) cpFloat;
pub extern fn cpSpaceSetSleepTimeThreshold(space: ?*cpSpace, sleepTimeThreshold: cpFloat) void;
pub extern fn cpSpaceGetCollisionSlop(space: ?*const cpSpace) cpFloat;
pub extern fn cpSpaceSetCollisionSlop(space: ?*cpSpace, collisionSlop: cpFloat) void;
pub extern fn cpSpaceGetCollisionBias(space: ?*const cpSpace) cpFloat;
pub extern fn cpSpaceSetCollisionBias(space: ?*cpSpace, collisionBias: cpFloat) void;
pub extern fn cpSpaceGetCollisionPersistence(space: ?*const cpSpace) cpTimestamp;
pub extern fn cpSpaceSetCollisionPersistence(space: ?*cpSpace, collisionPersistence: cpTimestamp) void;
pub extern fn cpSpaceGetUserData(space: ?*const cpSpace) cpDataPointer;
pub extern fn cpSpaceSetUserData(space: ?*cpSpace, userData: cpDataPointer) void;
pub extern fn cpSpaceGetStaticBody(space: ?*const cpSpace) ?*cpBody;
pub extern fn cpSpaceGetCurrentTimeStep(space: ?*const cpSpace) cpFloat;
pub extern fn cpSpaceIsLocked(space: ?*cpSpace) cpBool;
pub extern fn cpSpaceAddDefaultCollisionHandler(space: ?*cpSpace) [*c]cpCollisionHandler;
pub extern fn cpSpaceAddCollisionHandler(space: ?*cpSpace, a: cpCollisionType, b: cpCollisionType) [*c]cpCollisionHandler;
pub extern fn cpSpaceAddWildcardHandler(space: ?*cpSpace, @"type": cpCollisionType) [*c]cpCollisionHandler;
pub extern fn cpSpaceAddShape(space: ?*cpSpace, shape: ?*cpShape) ?*cpShape;
pub extern fn cpSpaceAddBody(space: ?*cpSpace, body: ?*cpBody) ?*cpBody;
pub extern fn cpSpaceAddConstraint(space: ?*cpSpace, constraint: ?*cpConstraint) ?*cpConstraint;
pub extern fn cpSpaceRemoveShape(space: ?*cpSpace, shape: ?*cpShape) void;
pub extern fn cpSpaceRemoveBody(space: ?*cpSpace, body: ?*cpBody) void;
pub extern fn cpSpaceRemoveConstraint(space: ?*cpSpace, constraint: ?*cpConstraint) void;
pub extern fn cpSpaceContainsShape(space: ?*cpSpace, shape: ?*cpShape) cpBool;
pub extern fn cpSpaceContainsBody(space: ?*cpSpace, body: ?*cpBody) cpBool;
pub extern fn cpSpaceContainsConstraint(space: ?*cpSpace, constraint: ?*cpConstraint) cpBool;
pub const cpPostStepFunc = ?*const fn (?*cpSpace, ?*anyopaque, ?*anyopaque) callconv(.C) void;
pub extern fn cpSpaceAddPostStepCallback(space: ?*cpSpace, func: cpPostStepFunc, key: ?*anyopaque, data: ?*anyopaque) cpBool;
pub const cpSpacePointQueryFunc = ?*const fn (?*cpShape, cpVect, cpFloat, cpVect, ?*anyopaque) callconv(.C) void;
pub extern fn cpSpacePointQuery(space: ?*cpSpace, point: cpVect, maxDistance: cpFloat, filter: cpShapeFilter, func: cpSpacePointQueryFunc, data: ?*anyopaque) void;
pub extern fn cpSpacePointQueryNearest(space: ?*cpSpace, point: cpVect, maxDistance: cpFloat, filter: cpShapeFilter, out: [*c]cpPointQueryInfo) ?*cpShape;
pub const cpSpaceSegmentQueryFunc = ?*const fn (?*cpShape, cpVect, cpVect, cpFloat, ?*anyopaque) callconv(.C) void;
pub extern fn cpSpaceSegmentQuery(space: ?*cpSpace, start: cpVect, end: cpVect, radius: cpFloat, filter: cpShapeFilter, func: cpSpaceSegmentQueryFunc, data: ?*anyopaque) void;
pub extern fn cpSpaceSegmentQueryFirst(space: ?*cpSpace, start: cpVect, end: cpVect, radius: cpFloat, filter: cpShapeFilter, out: [*c]cpSegmentQueryInfo) ?*cpShape;
pub const cpSpaceBBQueryFunc = ?*const fn (?*cpShape, ?*anyopaque) callconv(.C) void;
pub extern fn cpSpaceBBQuery(space: ?*cpSpace, bb: cpBB, filter: cpShapeFilter, func: cpSpaceBBQueryFunc, data: ?*anyopaque) void;
pub const cpSpaceShapeQueryFunc = ?*const fn (?*cpShape, [*c]cpContactPointSet, ?*anyopaque) callconv(.C) void;
pub extern fn cpSpaceShapeQuery(space: ?*cpSpace, shape: ?*cpShape, func: cpSpaceShapeQueryFunc, data: ?*anyopaque) cpBool;
pub const cpSpaceBodyIteratorFunc = ?*const fn (?*cpBody, ?*anyopaque) callconv(.C) void;
pub extern fn cpSpaceEachBody(space: ?*cpSpace, func: cpSpaceBodyIteratorFunc, data: ?*anyopaque) void;
pub const cpSpaceShapeIteratorFunc = ?*const fn (?*cpShape, ?*anyopaque) callconv(.C) void;
pub extern fn cpSpaceEachShape(space: ?*cpSpace, func: cpSpaceShapeIteratorFunc, data: ?*anyopaque) void;
pub const cpSpaceConstraintIteratorFunc = ?*const fn (?*cpConstraint, ?*anyopaque) callconv(.C) void;
pub extern fn cpSpaceEachConstraint(space: ?*cpSpace, func: cpSpaceConstraintIteratorFunc, data: ?*anyopaque) void;
pub extern fn cpSpaceReindexStatic(space: ?*cpSpace) void;
pub extern fn cpSpaceReindexShape(space: ?*cpSpace, shape: ?*cpShape) void;
pub extern fn cpSpaceReindexShapesForBody(space: ?*cpSpace, body: ?*cpBody) void;
pub extern fn cpSpaceUseSpatialHash(space: ?*cpSpace, dim: cpFloat, count: c_int) void;
pub extern fn cpSpaceStep(space: ?*cpSpace, dt: cpFloat) void;
pub const struct_cpSpaceDebugColor = extern struct {
    r: f32 = @import("std").mem.zeroes(f32),
    g: f32 = @import("std").mem.zeroes(f32),
    b: f32 = @import("std").mem.zeroes(f32),
    a: f32 = @import("std").mem.zeroes(f32),
};
pub const cpSpaceDebugColor = struct_cpSpaceDebugColor;
pub const cpSpaceDebugDrawCircleImpl = ?*const fn (cpVect, cpFloat, cpFloat, cpSpaceDebugColor, cpSpaceDebugColor, cpDataPointer) callconv(.C) void;
pub const cpSpaceDebugDrawSegmentImpl = ?*const fn (cpVect, cpVect, cpSpaceDebugColor, cpDataPointer) callconv(.C) void;
pub const cpSpaceDebugDrawFatSegmentImpl = ?*const fn (cpVect, cpVect, cpFloat, cpSpaceDebugColor, cpSpaceDebugColor, cpDataPointer) callconv(.C) void;
pub const cpSpaceDebugDrawPolygonImpl = ?*const fn (c_int, [*c]const cpVect, cpFloat, cpSpaceDebugColor, cpSpaceDebugColor, cpDataPointer) callconv(.C) void;
pub const cpSpaceDebugDrawDotImpl = ?*const fn (cpFloat, cpVect, cpSpaceDebugColor, cpDataPointer) callconv(.C) void;
pub const cpSpaceDebugDrawColorForShapeImpl = ?*const fn (?*cpShape, cpDataPointer) callconv(.C) cpSpaceDebugColor;
pub const CP_SPACE_DEBUG_DRAW_SHAPES: c_int = 1;
pub const CP_SPACE_DEBUG_DRAW_CONSTRAINTS: c_int = 2;
pub const CP_SPACE_DEBUG_DRAW_COLLISION_POINTS: c_int = 4;
pub const enum_cpSpaceDebugDrawFlags = c_uint;
pub const cpSpaceDebugDrawFlags = enum_cpSpaceDebugDrawFlags;
pub const struct_cpSpaceDebugDrawOptions = extern struct {
    drawCircle: cpSpaceDebugDrawCircleImpl = @import("std").mem.zeroes(cpSpaceDebugDrawCircleImpl),
    drawSegment: cpSpaceDebugDrawSegmentImpl = @import("std").mem.zeroes(cpSpaceDebugDrawSegmentImpl),
    drawFatSegment: cpSpaceDebugDrawFatSegmentImpl = @import("std").mem.zeroes(cpSpaceDebugDrawFatSegmentImpl),
    drawPolygon: cpSpaceDebugDrawPolygonImpl = @import("std").mem.zeroes(cpSpaceDebugDrawPolygonImpl),
    drawDot: cpSpaceDebugDrawDotImpl = @import("std").mem.zeroes(cpSpaceDebugDrawDotImpl),
    flags: cpSpaceDebugDrawFlags = @import("std").mem.zeroes(cpSpaceDebugDrawFlags),
    shapeOutlineColor: cpSpaceDebugColor = @import("std").mem.zeroes(cpSpaceDebugColor),
    colorForShape: cpSpaceDebugDrawColorForShapeImpl = @import("std").mem.zeroes(cpSpaceDebugDrawColorForShapeImpl),
    constraintColor: cpSpaceDebugColor = @import("std").mem.zeroes(cpSpaceDebugColor),
    collisionPointColor: cpSpaceDebugColor = @import("std").mem.zeroes(cpSpaceDebugColor),
    data: cpDataPointer = @import("std").mem.zeroes(cpDataPointer),
};
pub const cpSpaceDebugDrawOptions = struct_cpSpaceDebugDrawOptions;
pub extern fn cpSpaceDebugDraw(space: ?*cpSpace, options: [*c]cpSpaceDebugDrawOptions) void;
pub extern const cpVersionString: [*c]const u8;
pub extern fn cpMomentForCircle(m: cpFloat, r1: cpFloat, r2: cpFloat, offset: cpVect) cpFloat;
pub extern fn cpAreaForCircle(r1: cpFloat, r2: cpFloat) cpFloat;
pub extern fn cpMomentForSegment(m: cpFloat, a: cpVect, b: cpVect, radius: cpFloat) cpFloat;
pub extern fn cpAreaForSegment(a: cpVect, b: cpVect, radius: cpFloat) cpFloat;
pub extern fn cpMomentForPoly(m: cpFloat, count: c_int, verts: [*c]const cpVect, offset: cpVect, radius: cpFloat) cpFloat;
pub extern fn cpAreaForPoly(count: c_int, verts: [*c]const cpVect, radius: cpFloat) cpFloat;
pub extern fn cpCentroidForPoly(count: c_int, verts: [*c]const cpVect) cpVect;
pub extern fn cpMomentForBox(m: cpFloat, width: cpFloat, height: cpFloat) cpFloat;
pub extern fn cpMomentForBox2(m: cpFloat, box: cpBB) cpFloat;
pub extern fn cpConvexHull(count: c_int, verts: [*c]const cpVect, result: [*c]cpVect, first: [*c]c_int, tol: cpFloat) c_int;
pub fn cpClosetPointOnSegment(p: cpVect, a: cpVect, b: cpVect) callconv(.C) cpVect {
    const delta: cpVect = cpvsub(a, b);
    const t: cpFloat = cpfclamp01(cpvdot(delta, cpvsub(p, b)) / cpvlengthsq(delta));
    return cpvadd(b, cpvmult(delta, t));
}
pub extern fn acosf(__x: f32) f32;
pub extern fn cosf(__x: f32) f32;
pub extern fn asinf(__x: f32) f32;
pub extern fn sinf(__x: f32) f32;
pub extern fn atan2f(__y: f32, __x: f32) f32;
pub extern fn sqrtf(__x: f32) f32;
pub extern fn fmodf(__x: f32, __y: f32) f32;
pub const __builtin_inff = @import("std").zig.c_builtins.__builtin_inff;
