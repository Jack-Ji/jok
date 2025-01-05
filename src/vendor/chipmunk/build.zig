const std = @import("std");

pub fn inject(mod: *std.Build.Module, dir: std.Build.LazyPath) void {
    mod.addIncludePath(dir.path(mod.owner, "c/include"));
    mod.addCSourceFiles(.{
        .root = dir,
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
        .flags = &.{
            if (mod.optimize.? == .Debug) "" else "-DNDEBUG",
            "-DCP_USE_DOUBLES=0",
            "-Wno-return-type-c-linkage",
            "-fno-sanitize=undefined",
        },
    });
}
