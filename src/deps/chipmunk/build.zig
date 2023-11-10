const std = @import("std");

pub fn link(exe: *std.build.LibExeObjStep) void {
    var flags = std.ArrayList([]const u8).init(std.heap.page_allocator);
    defer flags.deinit();
    if (exe.optimize != .Debug) {
        flags.append("-DNDEBUG") catch unreachable;
    }
    flags.append("-DCP_USE_DOUBLES=0") catch unreachable;
    flags.append("-Wno-return-type-c-linkage") catch unreachable;
    flags.append("-fno-sanitize=undefined") catch unreachable;

    exe.addIncludePath(.{ .path = comptime thisDir() ++ "/c/include" });
    exe.addCSourceFiles(.{
        .files = &.{
            comptime thisDir() ++ "/c/src/chipmunk.c",
            comptime thisDir() ++ "/c/src/cpArbiter.c",
            comptime thisDir() ++ "/c/src/cpArray.c",
            comptime thisDir() ++ "/c/src/cpBBTree.c",
            comptime thisDir() ++ "/c/src/cpBody.c",
            comptime thisDir() ++ "/c/src/cpCollision.c",
            comptime thisDir() ++ "/c/src/cpConstraint.c",
            comptime thisDir() ++ "/c/src/cpDampedRotarySpring.c",
            comptime thisDir() ++ "/c/src/cpDampedSpring.c",
            comptime thisDir() ++ "/c/src/cpGearJoint.c",
            comptime thisDir() ++ "/c/src/cpGrooveJoint.c",
            comptime thisDir() ++ "/c/src/cpHashSet.c",
            comptime thisDir() ++ "/c/src/cpHastySpace.c",
            comptime thisDir() ++ "/c/src/cpMarch.c",
            comptime thisDir() ++ "/c/src/cpPinJoint.c",
            comptime thisDir() ++ "/c/src/cpPivotJoint.c",
            comptime thisDir() ++ "/c/src/cpPolyline.c",
            comptime thisDir() ++ "/c/src/cpPolyShape.c",
            comptime thisDir() ++ "/c/src/cpRatchetJoint.c",
            comptime thisDir() ++ "/c/src/cpRobust.c",
            comptime thisDir() ++ "/c/src/cpRotaryLimitJoint.c",
            comptime thisDir() ++ "/c/src/cpShape.c",
            comptime thisDir() ++ "/c/src/cpSimpleMotor.c",
            comptime thisDir() ++ "/c/src/cpSlideJoint.c",
            comptime thisDir() ++ "/c/src/cpSpace.c",
            comptime thisDir() ++ "/c/src/cpSpaceComponent.c",
            comptime thisDir() ++ "/c/src/cpSpaceDebug.c",
            comptime thisDir() ++ "/c/src/cpSpaceHash.c",
            comptime thisDir() ++ "/c/src/cpSpaceQuery.c",
            comptime thisDir() ++ "/c/src/cpSpaceStep.c",
            comptime thisDir() ++ "/c/src/cpSpatialIndex.c",
            comptime thisDir() ++ "/c/src/cpSweep1D.c",
        },
        .flags = flags.items,
    });
}

fn thisDir() []const u8 {
    return std.fs.path.dirname(@src().file) orelse ".";
}
