const std = @import("std");
const sdl = @import("sdl");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const tests = b.addTest(.{
        .name = "all",
        .root_source_file = b.path("src/jok.zig"),
    });
    const test_step = b.step("test", "run tests");
    test_step.dependOn(&b.addRunArtifact(tests).step);

    const assets_install = b.addInstallDirectory(.{
        .source_dir = b.path("examples/assets"),
        .install_dir = .bin,
        .install_subdir = "assets",
    });
    const examples = [_]struct { name: []const u8, opt: BuildOptions }{
        .{ .name = "hello", .opt = .{ .dep_name = null } },
        .{ .name = "imgui_demo", .opt = .{ .dep_name = null } },
        .{ .name = "sprite_sheet", .opt = .{ .dep_name = null } },
        .{ .name = "sprite_scene", .opt = .{ .dep_name = null } },
        .{ .name = "sprite_benchmark", .opt = .{ .dep_name = null } },
        .{ .name = "particle_2d", .opt = .{ .dep_name = null } },
        .{ .name = "particle_3d", .opt = .{ .dep_name = null } },
        .{ .name = "animation_2d", .opt = .{ .dep_name = null } },
        .{ .name = "sprite_scene_3d", .opt = .{ .dep_name = null } },
        .{ .name = "meshes_and_lighting", .opt = .{ .dep_name = null } },
        .{ .name = "intersection_2d", .opt = .{ .dep_name = null } },
        .{ .name = "affine_texture", .opt = .{ .dep_name = null } },
        .{ .name = "solar_system", .opt = .{ .dep_name = null } },
        .{ .name = "font_demo", .opt = .{ .dep_name = null } },
        .{ .name = "skybox", .opt = .{ .dep_name = null } },
        .{ .name = "benchmark_3d", .opt = .{ .dep_name = null } },
        .{ .name = "particle_life", .opt = .{ .dep_name = null, .use_nfd = true } },
        .{ .name = "audio_demo", .opt = .{ .dep_name = null } },
        .{ .name = "easing", .opt = .{ .dep_name = null } },
        .{ .name = "gltf", .opt = .{ .dep_name = null } },
        .{ .name = "svg", .opt = .{ .dep_name = null } },
        .{ .name = "cp_demo", .opt = .{ .dep_name = null, .use_cp = true } },
        .{ .name = "blending", .opt = .{ .dep_name = null } },
        .{ .name = "pathfind", .opt = .{ .dep_name = null } },
        .{ .name = "post_processing", .opt = .{ .dep_name = null } },
        .{ .name = "isometric", .opt = .{ .dep_name = null } },
        .{ .name = "conway_life", .opt = .{ .dep_name = null } },
        .{ .name = "generative_art_1", .opt = .{ .dep_name = null } },
        .{ .name = "generative_art_2", .opt = .{ .dep_name = null } },
        .{ .name = "generative_art_3", .opt = .{ .dep_name = null } },
    };
    const build_examples = b.step("examples", "compile and install all examples");
    inline for (examples) |demo| {
        const exe = createDesktopApp(
            b,
            demo.name,
            "examples/" ++ demo.name ++ ".zig",
            target,
            optimize,
            demo.opt,
        );
        const install_cmd = b.addInstallArtifact(exe, .{});
        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(&install_cmd.step);
        run_cmd.step.dependOn(&assets_install.step);
        run_cmd.cwd = b.path("zig-out/bin");
        const run_step = b.step(
            demo.name,
            "compile & run example " ++ demo.name,
        );
        run_step.dependOn(&run_cmd.step);
        build_examples.dependOn(&install_cmd.step);
    }
}

pub const BuildOptions = struct {
    dep_name: ?[]const u8 = "jok",
    sdl_config_env: []const u8 = "SDL_CONFIG_PATH",
    use_cp: bool = false,
    use_nfd: bool = false,
    use_ztracy: bool = false,
    enable_ztracy: bool = false,
};

/// Create desktop application
pub fn createDesktopApp(
    b: *std.Build,
    name: []const u8,
    root_file: []const u8,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.Mode,
    opt: BuildOptions,
) *std.Build.Step.Compile {
    const builder = if (opt.dep_name) |dep|
        b.dependency(dep, .{}).builder
    else
        b;

    // Find sdl build config and create sdk
    const env_sdl_path: ?[]u8 = std.process.getEnvVarOwned(b.allocator, opt.sdl_config_env) catch null;
    const sdl_config_path = env_sdl_path orelse std.fs.path.join(
        b.allocator,
        &[_][]const u8{ b.pathFromRoot(".build_config"), "sdl.json" },
    ) catch @panic("OOM");
    const sdl_sdk = sdl.init(builder, .{ .maybe_config_path = sdl_config_path });

    // Initialize jok module
    const bos = builder.addOptions();
    bos.addOption(bool, "use_cp", opt.use_cp);
    bos.addOption(bool, "use_nfd", opt.use_nfd);
    bos.addOption(bool, "use_ztracy", opt.use_ztracy);
    const zgui = builder.dependency("zgui", .{
        .target = target,
        .optimize = optimize,
    });
    const zaudio = builder.dependency("zaudio", .{
        .target = target,
        .optimize = optimize,
    });
    const zmath = builder.dependency("zmath", .{
        .target = target,
        .optimize = optimize,
    });
    const zmesh = builder.dependency("zmesh", .{
        .target = target,
        .optimize = optimize,
    });
    const znoise = builder.dependency("znoise", .{
        .target = target,
        .optimize = optimize,
    });
    const ztracy = builder.dependency("ztracy", .{
        .target = target,
        .optimize = optimize,
    });
    const jok = builder.createModule(.{
        .root_source_file = builder.path("src/jok.zig"),
        .imports = &.{
            .{ .name = "build_options", .module = bos.createModule() },
            .{ .name = "sdl", .module = sdl_sdk.getWrapperModule() },
            .{ .name = "zgui", .module = zgui.module("root") },
            .{ .name = "zaudio", .module = zaudio.module("root") },
            .{ .name = "zmath", .module = zmath.module("root") },
            .{ .name = "zmesh", .module = zmesh.module("root") },
            .{ .name = "znoise", .module = znoise.module("root") },
        },
    });
    if (opt.use_ztracy) {
        jok.addImport("ztracy", ztracy.module("root"));
    }

    // Create executable
    const exe = builder.addExecutable(.{
        .name = name,
        .root_source_file = builder.path("src/app.zig"),
        .target = target,
        .optimize = optimize,
    });
    exe.root_module.addImport("jok", jok);
    exe.root_module.addImport("game", builder.createModule(.{
        .root_source_file = b.path(root_file),
        .imports = &.{
            .{ .name = "jok", .module = jok },
        },
    }));
    sdl_sdk.link(exe, .dynamic, .SDL2);
    exe.linkLibrary(zgui.artifact("imgui"));
    exe.linkLibrary(zaudio.artifact("miniaudio"));
    exe.linkLibrary(zmesh.artifact("zmesh"));
    exe.linkLibrary(znoise.artifact("FastNoiseLite"));
    if (opt.use_ztracy) {
        exe.linkLibrary(ztracy.artifact("tracy"));
    }
    injectVendorLibraries(builder, exe, target, optimize, opt);

    return exe;
}

fn injectVendorLibraries(
    b: *std.Build,
    exe: *std.Build.Step.Compile,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.Mode,
    opt: BuildOptions,
) void {
    // libc is required
    exe.linkLibC();

    // imgui
    if (exe.rootModuleTarget().os.tag == .windows) {
        exe.addIncludePath(b.path("src/vendor/imgui/c/SDL2/windows"));
    } else if (target.result.os.tag == .macos) {
        exe.addIncludePath(b.path("src/vendor/imgui/c/SDL2/macos"));
    } else if (target.result.os.tag == .linux) {
        exe.addIncludePath(b.path("src/vendor/imgui/c/SDL2/linux"));
    } else unreachable;
    exe.addIncludePath(b.path("deps/zgui/libs/imgui"));
    exe.addIncludePath(b.path("src/vendor/imgui/c"));
    exe.addCSourceFiles(.{
        .files = &.{
            "src/vendor/imgui/c/imgui_impl_sdl2.cpp",
            "src/vendor/imgui/c/imgui_impl_sdlrenderer2.cpp",
        },
        .flags = &.{"-fno-sanitize=undefined"},
    });

    // miniaudio
    exe.addIncludePath(b.path("deps/zaudio/libs/miniaudio"));
    exe.addCSourceFile(.{
        .file = b.path("src/vendor/miniaudio/c/miniaudio_impl_sdl2.c"),
        .flags = &.{
            "-DMA_ENABLE_CUSTOM",
            "-std=c99",
            "-fno-sanitize=undefined",
            if (target.result.os.tag == .macos) "-DMA_NO_RUNTIME_LINKING" else "",
        },
    });

    // stb headers
    exe.addCSourceFile(.{
        .file = b.path("src/vendor/stb/c/stb_wrapper.c"),
        .flags = &.{
            "-Wno-return-type-c-linkage",
            "-fno-sanitize=undefined",
        },
    });

    // nanosvg
    exe.addCSourceFile(.{
        .file = b.path("src/vendor/svg/c/wrapper.c"),
        .flags = &.{
            "-Wno-return-type-c-linkage",
            "-fno-sanitize=undefined",
        },
    });

    // physfs
    exe.addCSourceFiles(.{
        .files = &.{
            "src/vendor/physfs/c/physfs.c",
            "src/vendor/physfs/c/physfs_byteorder.c",
            "src/vendor/physfs/c/physfs_unicode.c",
            "src/vendor/physfs/c/physfs_platform_posix.c",
            "src/vendor/physfs/c/physfs_platform_unix.c",
            "src/vendor/physfs/c/physfs_platform_windows.c",
            "src/vendor/physfs/c/physfs_platform_ogc.c",
            "src/vendor/physfs/c/physfs_platform_os2.c",
            "src/vendor/physfs/c/physfs_platform_qnx.c",
            "src/vendor/physfs/c/physfs_platform_android.c",
            "src/vendor/physfs/c/physfs_platform_playdate.c",
            "src/vendor/physfs/c/physfs_archiver_dir.c",
            "src/vendor/physfs/c/physfs_archiver_unpacked.c",
            "src/vendor/physfs/c/physfs_archiver_grp.c",
            "src/vendor/physfs/c/physfs_archiver_hog.c",
            "src/vendor/physfs/c/physfs_archiver_7z.c",
            "src/vendor/physfs/c/physfs_archiver_mvl.c",
            "src/vendor/physfs/c/physfs_archiver_qpak.c",
            "src/vendor/physfs/c/physfs_archiver_wad.c",
            "src/vendor/physfs/c/physfs_archiver_csm.c",
            "src/vendor/physfs/c/physfs_archiver_zip.c",
            "src/vendor/physfs/c/physfs_archiver_slb.c",
            "src/vendor/physfs/c/physfs_archiver_iso9660.c",
            "src/vendor/physfs/c/physfs_archiver_vdf.c",
            "src/vendor/physfs/c/physfs_archiver_lec3d.c",
        },
        .flags = &.{
            "-Wno-return-type-c-linkage",
            "-fno-sanitize=undefined",
        },
    });
    if (target.result.os.tag == .windows) {
        exe.linkSystemLibrary("advapi32");
        exe.linkSystemLibrary("shell32");
    } else if (target.result.os.tag == .macos) {
        exe.addCSourceFiles(.{
            .files = &.{
                "src/vendor/physfs/c/physfs_platform_apple.m",
            },
            .flags = &.{
                "-Wno-return-type-c-linkage",
                "-fno-sanitize=undefined",
            },
        });
        if (b.lazyDependency("system_sdk", .{})) |system_sdk| {
            exe.addFrameworkPath(system_sdk.path("macos12/System/Library/Frameworks"));
            exe.addSystemIncludePath(system_sdk.path("macos12/usr/include"));
            exe.addLibraryPath(system_sdk.path("macos12/usr/lib"));
        }
        exe.linkSystemLibrary("objc");
        exe.linkFramework("IOKit");
        exe.linkFramework("Foundation");
    } else if (target.result.os.tag == .linux) {
        exe.linkSystemLibrary("pthread");
    } else unreachable;

    // chipmunk
    if (opt.use_cp) {
        exe.addIncludePath(b.path("src/vendor/chipmunk/c/include"));
        exe.addCSourceFiles(.{
            .files = &.{
                "src/vendor/chipmunk/c/src/chipmunk.c",
                "src/vendor/chipmunk/c/src/cpArbiter.c",
                "src/vendor/chipmunk/c/src/cpArray.c",
                "src/vendor/chipmunk/c/src/cpBBTree.c",
                "src/vendor/chipmunk/c/src/cpBody.c",
                "src/vendor/chipmunk/c/src/cpCollision.c",
                "src/vendor/chipmunk/c/src/cpConstraint.c",
                "src/vendor/chipmunk/c/src/cpDampedRotarySpring.c",
                "src/vendor/chipmunk/c/src/cpDampedSpring.c",
                "src/vendor/chipmunk/c/src/cpGearJoint.c",
                "src/vendor/chipmunk/c/src/cpGrooveJoint.c",
                "src/vendor/chipmunk/c/src/cpHashSet.c",
                "src/vendor/chipmunk/c/src/cpHastySpace.c",
                "src/vendor/chipmunk/c/src/cpMarch.c",
                "src/vendor/chipmunk/c/src/cpPinJoint.c",
                "src/vendor/chipmunk/c/src/cpPivotJoint.c",
                "src/vendor/chipmunk/c/src/cpPolyline.c",
                "src/vendor/chipmunk/c/src/cpPolyShape.c",
                "src/vendor/chipmunk/c/src/cpRatchetJoint.c",
                "src/vendor/chipmunk/c/src/cpRobust.c",
                "src/vendor/chipmunk/c/src/cpRotaryLimitJoint.c",
                "src/vendor/chipmunk/c/src/cpShape.c",
                "src/vendor/chipmunk/c/src/cpSimpleMotor.c",
                "src/vendor/chipmunk/c/src/cpSlideJoint.c",
                "src/vendor/chipmunk/c/src/cpSpace.c",
                "src/vendor/chipmunk/c/src/cpSpaceComponent.c",
                "src/vendor/chipmunk/c/src/cpSpaceDebug.c",
                "src/vendor/chipmunk/c/src/cpSpaceHash.c",
                "src/vendor/chipmunk/c/src/cpSpaceQuery.c",
                "src/vendor/chipmunk/c/src/cpSpaceStep.c",
                "src/vendor/chipmunk/c/src/cpSpatialIndex.c",
                "src/vendor/chipmunk/c/src/cpSweep1D.c",
            },
            .flags = &.{
                if (optimize == .Debug) "" else "-DNDEBUG",
                "-DCP_USE_DOUBLES=0",
                "-Wno-return-type-c-linkage",
                "-fno-sanitize=undefined",
            },
        });
    }

    // native file dialog
    if (opt.use_nfd) {
        var flags = std.ArrayList([]const u8).init(b.allocator);
        defer flags.deinit();
        flags.append("-Wno-return-type-c-linkage") catch unreachable;
        flags.append("-fno-sanitize=undefined") catch unreachable;
        if (exe.rootModuleTarget().os.tag == .windows) {
            exe.linkSystemLibrary("shell32");
            exe.linkSystemLibrary("ole32");
            exe.linkSystemLibrary("uuid"); // needed by MinGW
        } else if (target.result.os.tag == .macos) {
            exe.linkFramework("AppKit");
        } else if (exe.rootModuleTarget().os.tag == .linux) {
            exe.linkSystemLibrary("atk-1.0");
            exe.linkSystemLibrary("gdk-3");
            exe.linkSystemLibrary("gtk-3");
            exe.linkSystemLibrary("glib-2.0");
            exe.linkSystemLibrary("gobject-2.0");
        } else unreachable;
        exe.addIncludePath(b.path("src/vendor/nfd/c/include"));
        exe.addCSourceFile(.{
            .file = b.path("src/vendor/nfd/c/nfd_common.c"),
            .flags = flags.items,
        });

        if (target.result.os.tag == .windows) {
            exe.addCSourceFile(.{
                .file = b.path("src/vendor/nfd/c/nfd_win.cpp"),
                .flags = flags.items,
            });
        } else if (target.result.os.tag == .macos) {
            exe.addCSourceFile(.{
                .file = b.path("src/vendor/nfd/c/nfd_cocoa.m"),
                .flags = flags.items,
            });
        } else if (target.result.os.tag == .linux) {
            exe.addCSourceFile(.{
                .file = b.path("src/vendor/nfd/c/nfd_gtk.c"),
                .flags = flags.items,
            });
        } else unreachable;
    }
}
