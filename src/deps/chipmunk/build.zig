const std = @import("std");

pub fn link(exe: *std.Build.Step.Compile) void {
    var flags = std.ArrayList([]const u8).init(std.heap.page_allocator);
    defer flags.deinit();
    if (exe.root_module.optimize.? != .Debug) {
        flags.append("-DNDEBUG") catch unreachable;
    }
    flags.append("-DCP_USE_DOUBLES=0") catch unreachable;
    flags.append("-Wno-return-type-c-linkage") catch unreachable;
    flags.append("-fno-sanitize=undefined") catch unreachable;

    exe.addIncludePath(.{ .path = thisDir() ++ "/c/include" });
    exe.addCSourceFiles(.{
        .root = .{ .path = thisDir() },
        .files = &.{
            "c/src/chipmunk.c",
            "c/src/cpArbiter.c",
            "c/src/cpArray.c",
            "c/src/cpBBTree.c",
            "c/src/cpBody.c",
            "c/src/cpCollision.c",
            "c/src/cpConstraint.c",
            "c/src/cpDampedRotarySpring.c",
            "c/src/cpDampedSpring.c",
            "c/src/cpGearJoint.c",
            "c/src/cpGrooveJoint.c",
            "c/src/cpHashSet.c",
            "c/src/cpHastySpace.c",
            "c/src/cpMarch.c",
            "c/src/cpPinJoint.c",
            "c/src/cpPivotJoint.c",
            "c/src/cpPolyline.c",
            "c/src/cpPolyShape.c",
            "c/src/cpRatchetJoint.c",
            "c/src/cpRobust.c",
            "c/src/cpRotaryLimitJoint.c",
            "c/src/cpShape.c",
            "c/src/cpSimpleMotor.c",
            "c/src/cpSlideJoint.c",
            "c/src/cpSpace.c",
            "c/src/cpSpaceComponent.c",
            "c/src/cpSpaceDebug.c",
            "c/src/cpSpaceHash.c",
            "c/src/cpSpaceQuery.c",
            "c/src/cpSpaceStep.c",
            "c/src/cpSpatialIndex.c",
            "c/src/cpSweep1D.c",
        },
        .flags = flags.items,
    });
}

inline fn thisDir() []const u8 {
    return comptime std.fs.path.dirname(@src().file) orelse ".";
}
