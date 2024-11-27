const std = @import("std");
const assert = std.debug.assert;
const panic = std.debug.panic;
const Build = std.Build;
const ResolvedTarget = Build.ResolvedTarget;
const builtin = @import("builtin");

pub fn build(b: *Build) void {
    if (b.option(bool, "skipbuild", "skip all build jobs, false by default.")) |skip| {
        if (skip) return;
    }

    // Get skipped examples' names
    var skiped_examples = std.StringHashMap(bool).init(b.allocator);
    if (b.option(
        []const u8,
        "skip",
        "skip given demos when building `examples`. e.g. \"particle_life,intersection_2d\"",
    )) |s| {
        var it = std.mem.splitScalar(u8, s, ',');
        while (it.next()) |name| skiped_examples.put(name, true) catch unreachable;
    }

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
        .{ .name = "sprite_benchmark", .opt = .{ .dep_name = null } },
        .{ .name = "cube_benchmark", .opt = .{ .dep_name = null } },
        .{ .name = "sprite_sheet", .opt = .{ .dep_name = null } },
        .{ .name = "sprite_scene_2d", .opt = .{ .dep_name = null } },
        .{ .name = "sprite_scene_3d", .opt = .{ .dep_name = null } },
        .{ .name = "particle_2d", .opt = .{ .dep_name = null } },
        .{ .name = "particle_3d", .opt = .{ .dep_name = null } },
        .{ .name = "animation_2d", .opt = .{ .dep_name = null } },
        .{ .name = "animation_3d", .opt = .{ .dep_name = null } },
        .{ .name = "meshes_and_lighting", .opt = .{ .dep_name = null } },
        .{ .name = "intersection_2d", .opt = .{ .dep_name = null } },
        .{ .name = "solar_system", .opt = .{ .dep_name = null } },
        .{ .name = "font_demo", .opt = .{ .dep_name = null } },
        .{ .name = "skybox", .opt = .{ .dep_name = null } },
        .{ .name = "particle_life", .opt = .{ .dep_name = null, .use_nfd = true } },
        .{ .name = "audio_demo", .opt = .{ .dep_name = null } },
        .{ .name = "easing", .opt = .{ .dep_name = null } },
        .{ .name = "svg", .opt = .{ .dep_name = null } },
        .{ .name = "cp_demo", .opt = .{ .dep_name = null, .use_cp = true } },
        .{ .name = "blending", .opt = .{ .dep_name = null } },
        .{ .name = "pathfind", .opt = .{ .dep_name = null } },
        .{ .name = "post_processing", .opt = .{ .dep_name = null } },
        .{ .name = "isometric", .opt = .{ .dep_name = null } },
        .{ .name = "conway_life", .opt = .{ .dep_name = null } },
        .{ .name = "tiled", .opt = .{ .dep_name = null } },
        .{ .name = "generative_art_1", .opt = .{ .dep_name = null } },
        .{ .name = "generative_art_2", .opt = .{ .dep_name = null } },
        .{ .name = "generative_art_3", .opt = .{ .dep_name = null } },
        .{ .name = "generative_art_4", .opt = .{ .dep_name = null } },
        .{ .name = "generative_art_5", .opt = .{ .dep_name = null } },
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
        if (skiped_examples.get(demo.name) == null) {
            build_examples.dependOn(&install_cmd.step);
        }
    }
}

pub const BuildOptions = struct {
    dep_name: ?[]const u8 = "jok",
    no_audio: bool = false,
    use_cp: bool = false,
    use_nfd: bool = false,
    use_ztracy: bool = false,
    enable_ztracy: bool = false,
};

/// Create desktop application (windows/linux/macos)
pub fn createDesktopApp(
    b: *Build,
    name: []const u8,
    root_file: []const u8,
    target: ResolvedTarget,
    optimize: std.builtin.Mode,
    opt: BuildOptions,
) *Build.Step.Compile {
    assert(target.result.os.tag == .windows or target.result.os.tag == .linux or target.result.os.tag == .macos);

    // Initialize jok
    const jok = initJok(b, target, optimize, opt);

    // Initialize sdl2 sdk
    const sdk = CrossSDL.init(b);

    // Create executable
    const builder = getJokBuilder(b, opt);
    const exe = builder.addExecutable(.{
        .name = name,
        .root_source_file = builder.path("src/app.zig"),
        .target = target,
        .optimize = optimize,
    });
    exe.root_module.addImport("jok", jok.module);
    exe.root_module.addImport("game", builder.createModule(.{
        .root_source_file = b.path(root_file),
        .imports = &.{
            .{ .name = "jok", .module = jok.module },
        },
    }));
    exe.linkLibrary(jok.lib);
    sdk.link(exe, .dynamic);

    return exe;
}

// Create jok module and library
fn initJok(
    b: *Build,
    target: ResolvedTarget,
    optimize: std.builtin.Mode,
    opt: BuildOptions,
) struct {
    module: *Build.Module,
    lib: *Build.Step.Compile,
} {
    const builder = getJokBuilder(b, opt);

    // Create module
    const bos = builder.addOptions();
    bos.addOption(bool, "no_audio", opt.no_audio);
    bos.addOption(bool, "use_cp", opt.use_cp);
    bos.addOption(bool, "use_nfd", opt.use_nfd);
    bos.addOption(bool, "use_ztracy", opt.use_ztracy);
    const zgui = builder.dependency("zgui", .{
        .target = target,
        .optimize = optimize,
        .use_wchar32 = true,
        .use_32bit_draw_idx = true,
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
    const module = builder.createModule(.{
        .root_source_file = builder.path("src/jok.zig"),
        .imports = &.{
            .{ .name = "build_options", .module = bos.createModule() },
            .{ .name = "zgui", .module = zgui.module("root") },
            .{ .name = "zmath", .module = zmath.module("root") },
            .{ .name = "zmesh", .module = zmesh.module("root") },
            .{ .name = "znoise", .module = znoise.module("root") },
        },
    });
    if (!opt.no_audio) {
        module.addImport("zaudio", zaudio.module("root"));
    }
    if (opt.use_ztracy) {
        module.addImport("ztracy", ztracy.module("root"));
    }

    // Create library
    const lib = builder.addStaticLibrary(.{
        .name = "jok",
        .root_source_file = builder.path("src/jok.zig"),
        .target = target,
        .optimize = optimize,
    });
    lib.linkLibrary(zgui.artifact("imgui"));
    lib.linkLibrary(zmesh.artifact("zmesh"));
    lib.linkLibrary(znoise.artifact("FastNoiseLite"));
    if (!opt.no_audio) {
        lib.linkLibrary(zaudio.artifact("miniaudio"));
    }
    if (opt.use_ztracy) {
        lib.linkLibrary(ztracy.artifact("tracy"));
    }
    injectVendorLibraries(builder, lib, target, optimize, opt);

    return .{ .module = module, .lib = lib };
}

// Compile vendor libraries into artifact
fn injectVendorLibraries(
    b: *Build,
    bin: *Build.Step.Compile,
    target: ResolvedTarget,
    optimize: std.builtin.Mode,
    opt: BuildOptions,
) void {
    // Setup path to common libraries
    const system_sdk = b.dependency("system_sdk", .{});
    switch (target.result.os.tag) {
        .windows => {
            bin.addIncludePath(b.path("src/vendor/sdl/c/windows"));
        },
        .macos => {
            bin.addFrameworkPath(system_sdk.path("macos12/System/Library/Frameworks"));
            bin.addSystemIncludePath(system_sdk.path("macos12/usr/include"));
            bin.addLibraryPath(system_sdk.path("macos12/usr/lib"));
            bin.addIncludePath(b.path("src/vendor/sdl/c/macos"));
        },
        .linux => {
            bin.addSystemIncludePath(system_sdk.path("linux/include"));
            bin.addSystemIncludePath(system_sdk.path("linux/include/wayland"));
            if (target.result.cpu.arch.isX86()) {
                bin.addLibraryPath(system_sdk.path("linux/lib/x86_64-linux-gnu"));
            } else {
                bin.addLibraryPath(system_sdk.path("linux/lib/aarch64-linux-gnu"));
            }
            bin.addIncludePath(b.path("src/vendor/sdl/c/linux"));
        },
        else => {},
    }

    // libc is always required
    bin.linkLibC();

    // dear-imgui backend
    bin.addCSourceFiles(.{
        .files = &.{
            "src/vendor/imgui/c/imgui_impl_sdl2.cpp",
            "src/vendor/imgui/c/imgui_impl_sdlrenderer2.cpp",
        },
        .flags = &.{"-fno-sanitize=undefined"},
    });

    // miniaudio
    if (!opt.no_audio) {
        bin.addCSourceFile(.{
            .file = b.path("src/vendor/miniaudio/c/miniaudio_impl_sdl2.c"),
            .flags = &.{
                "-DMA_ENABLE_CUSTOM",
                "-std=c99",
                "-fno-sanitize=undefined",
                if (target.result.os.tag == .macos) "-DMA_NO_RUNTIME_LINKING" else "",
            },
        });
    }

    // stb headers
    bin.addCSourceFile(.{
        .file = b.path("src/vendor/stb/c/stb_wrapper.c"),
        .flags = &.{
            "-Wno-return-type-c-linkage",
            "-fno-sanitize=undefined",
        },
    });

    // nanosvg
    bin.addCSourceFile(.{
        .file = b.path("src/vendor/svg/c/wrapper.c"),
        .flags = &.{
            "-Wno-return-type-c-linkage",
            "-fno-sanitize=undefined",
        },
    });

    // physfs
    bin.addCSourceFiles(.{
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
        bin.linkSystemLibrary("advapi32");
        bin.linkSystemLibrary("shell32");
    } else if (target.result.os.tag == .macos) {
        bin.addCSourceFiles(.{
            .files = &.{
                "src/vendor/physfs/c/physfs_platform_apple.m",
            },
            .flags = &.{
                "-Wno-return-type-c-linkage",
                "-fno-sanitize=undefined",
            },
        });
        bin.linkSystemLibrary("objc");
        bin.linkFramework("IOKit");
        bin.linkFramework("Foundation");
    } else if (target.result.os.tag == .linux) {
        bin.linkSystemLibrary("pthread");
    } else unreachable;

    // chipmunk
    if (opt.use_cp) {
        bin.addIncludePath(b.path("src/vendor/chipmunk/c/include"));
        bin.addCSourceFiles(.{
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
        if (bin.rootModuleTarget().os.tag == .windows) {
            bin.linkSystemLibrary("shell32");
            bin.linkSystemLibrary("ole32");
            bin.linkSystemLibrary("uuid"); // needed by MinGW
        } else if (target.result.os.tag == .macos) {
            bin.linkFramework("AppKit");
        } else if (bin.rootModuleTarget().os.tag == .linux) {
            bin.linkSystemLibrary("atk-1.0");
            bin.linkSystemLibrary("gdk-3");
            bin.linkSystemLibrary("gtk-3");
            bin.linkSystemLibrary("glib-2.0");
            bin.linkSystemLibrary("gobject-2.0");
        } else unreachable;
        bin.addIncludePath(b.path("src/vendor/nfd/c/include"));
        bin.addCSourceFile(.{
            .file = b.path("src/vendor/nfd/c/nfd_common.c"),
            .flags = flags.items,
        });

        if (target.result.os.tag == .windows) {
            bin.addCSourceFile(.{
                .file = b.path("src/vendor/nfd/c/nfd_win.cpp"),
                .flags = flags.items,
            });
        } else if (target.result.os.tag == .macos) {
            bin.addCSourceFile(.{
                .file = b.path("src/vendor/nfd/c/nfd_cocoa.m"),
                .flags = flags.items,
            });
        } else if (target.result.os.tag == .linux) {
            bin.addCSourceFile(.{
                .file = b.path("src/vendor/nfd/c/nfd_gtk.c"),
                .flags = flags.items,
            });
        } else unreachable;
    }
}

// Get jok's own builder from project's
fn getJokBuilder(b: *Build, opt: BuildOptions) *Build {
    return if (opt.dep_name) |dep|
        b.dependency(dep, .{ .skipbuild = true }).builder
    else
        b;
}

// Sdk for cross-compile-link SDL2
const CrossSDL = struct {
    const Sdk = @This();
    const host_system = builtin.target;
    const Step = Build.Step;
    const LazyPath = Build.LazyPath;
    const GeneratedFile = Build.GeneratedFile;
    const Compile = Build.Step.Compile;
    const sdl2_config_env = "SDL_CONFIG_PATH";
    const sdl2_symbol_definitions = @embedFile("stubs/libSDL2.def");

    builder: *Build,
    sdl_config_path: []const u8,
    prepare_sources: *PrepareStubSourceStep,

    /// Creates a instance of the Sdk and initializes internal steps.
    pub fn init(b: *Build) *Sdk {
        const sdk = b.allocator.create(Sdk) catch @panic("out of memory");

        const env_sdl_path: ?[]u8 = std.process.getEnvVarOwned(b.allocator, sdl2_config_env) catch null;
        const sdl_config_path = env_sdl_path orelse std.fs.path.join(
            b.allocator,
            &[_][]const u8{ b.pathFromRoot(".build_config"), "sdl.json" },
        ) catch @panic("OOM");

        sdk.* = .{
            .builder = b,
            .sdl_config_path = sdl_config_path,
            .prepare_sources = undefined,
        };
        sdk.prepare_sources = PrepareStubSourceStep.create(sdk);

        return sdk;
    }

    fn linkLinuxCross(sdk: *Sdk, exe: *Compile) !void {
        const build_linux_sdl_stub = sdk.builder.addSharedLibrary(.{
            .name = "SDL2",
            .target = exe.root_module.resolved_target.?,
            .optimize = exe.root_module.optimize.?,
        });
        build_linux_sdl_stub.addAssemblyFile(sdk.prepare_sources.getStubFile());
        exe.linkLibrary(build_linux_sdl_stub);
    }

    fn linkWindows(
        sdk: *Sdk,
        exe: *Compile,
        linkage: std.builtin.LinkMode,
        paths: Paths,
    ) !void {
        exe.addIncludePath(.{ .cwd_relative = paths.include });
        exe.addLibraryPath(.{ .cwd_relative = paths.libs });

        const lib_name = "SDL2";
        if (exe.root_module.resolved_target.?.result.abi == .msvc) {
            exe.linkSystemLibrary2(lib_name, .{ .use_pkg_config = .no });
        } else {
            const file_name = try std.fmt.allocPrint(sdk.builder.allocator, "lib{s}.{s}", .{
                lib_name,
                if (linkage == .static) "a" else "dll.a",
            });
            defer sdk.builder.allocator.free(file_name);

            const lib_path = try std.fs.path.join(sdk.builder.allocator, &[_][]const u8{ paths.libs, file_name });
            defer sdk.builder.allocator.free(lib_path);

            exe.addObjectFile(.{ .cwd_relative = lib_path });

            if (linkage == .static) {
                const static_libs = [_][]const u8{
                    "setupapi",
                    "user32",
                    "gdi32",
                    "winmm",
                    "imm32",
                    "ole32",
                    "oleaut32",
                    "shell32",
                    "version",
                    "uuid",
                };
                for (static_libs) |lib| exe.linkSystemLibrary(lib);
            }
        }

        if (linkage == .dynamic and exe.kind == .exe) {
            const dll_name = try std.fmt.allocPrint(sdk.builder.allocator, "{s}.dll", .{lib_name});
            defer sdk.builder.allocator.free(dll_name);

            const dll_path = try std.fs.path.join(sdk.builder.allocator, &[_][]const u8{ paths.bin, dll_name });
            defer sdk.builder.allocator.free(dll_path);

            const install_bin = sdk.builder.addInstallBinFile(.{ .cwd_relative = dll_path }, dll_name);
            exe.step.dependOn(&install_bin.step);
        }
    }

    fn linkMacOS(exe: *Compile) !void {
        exe.linkSystemLibrary("sdl2");

        exe.linkFramework("Cocoa");
        exe.linkFramework("CoreAudio");
        exe.linkFramework("Carbon");
        exe.linkFramework("Metal");
        exe.linkFramework("QuartzCore");
        exe.linkFramework("AudioToolbox");
        exe.linkFramework("ForceFeedback");
        exe.linkFramework("GameController");
        exe.linkFramework("CoreHaptics");
        exe.linkSystemLibrary("iconv");
    }

    /// Links SDL2 to the given exe and adds required installs if necessary.
    /// **Important:** The target of the `exe` must already be set, otherwise the Sdk will do the wrong thing!
    pub fn link(
        sdk: *Sdk,
        exe: *Compile,
        linkage: std.builtin.LinkMode,
    ) void {
        const b = sdk.builder;
        const target = exe.root_module.resolved_target.?;
        const is_native = target.query.isNativeOs();

        if (target.result.os.tag == .linux) {
            if (!is_native) {
                linkLinuxCross(sdk, exe) catch |err| {
                    panic("Failed to link SDL2 for Linux cross-compilation: {s}", .{@errorName(err)});
                };
            } else {
                exe.linkSystemLibrary("sdl2");
            }
        } else if (target.result.os.tag == .windows) {
            const paths = getPaths(sdk, sdk.sdl_config_path, target) catch |err| {
                panic("Failed to get paths for SDL2: {s}", .{@errorName(err)});
            };

            linkWindows(sdk, exe, linkage, paths) catch |err| {
                panic("Failed to link SDL2 for Windows: {s}", .{@errorName(err)});
            };
        } else if (target.result.isDarwin()) {
            if (!host_system.os.tag.isDarwin()) {
                panic("Cross-compilation not supported for SDL2 on macOS", .{});
            }
            linkMacOS(exe) catch |err| {
                panic("Failed to link SDL2 for macOS: {s}", .{@errorName(err)});
            };
        } else {
            const triple_string = target.query.zigTriple(b.allocator) catch |err| {
                panic("Failed to get target triple: {s}", .{@errorName(err)});
            };
            defer b.allocator.free(triple_string);
            std.log.warn("Linking SDL2 for {s} is not tested, linking might fail!", .{triple_string});
            exe.linkSystemLibrary("sdl2");
        }
    }

    const Paths = struct {
        include: []const u8,
        libs: []const u8,
        bin: []const u8,
    };

    const GetPathsError = error{
        FileNotFound,
        InvalidJson,
        InvalidTarget,
        MissingTarget,
    };

    fn printPathsErrorMessage(sdk: *Sdk, config_path: []const u8, target_local: ResolvedTarget, err: GetPathsError) !void {
        const writer = std.io.getStdErr().writer();
        const target_name = try tripleName(sdk.builder.allocator, target_local);
        defer sdk.builder.allocator.free(target_name);

        const lib_name = "SDL2";
        const download_url = "https://github.com/libsdl-org/SDL/releases";
        switch (err) {
            GetPathsError.FileNotFound => {
                try writer.print("Could not auto-detect {s} sdk configuration. Please provide {s} with the following contents filled out:\n", .{ lib_name, config_path });
                try writer.print("{{\n  \"{s}\": {{\n", .{target_name});
                try writer.writeAll(
                    \\    "include": "<path to sdk>/include",
                    \\    "libs": "<path to sdk>/lib",
                    \\    "bin": "<path to sdk>/bin"
                    \\  }
                    \\}
                    \\
                );
                try writer.print(
                    \\
                    \\You can obtain a {s} sdk for Windows from {s}
                    \\
                , .{ lib_name, download_url });
            },
            GetPathsError.MissingTarget => {
                try writer.print("{s} is missing a SDK definition for {s}. Please add the following section to the file and fill the paths:\n", .{ config_path, target_name });
                try writer.print("  \"{s}\": {{\n", .{target_name});
                try writer.writeAll(
                    \\  "include": "<path to sdk>/include",
                    \\  "libs": "<path to sdk>/lib",
                    \\  "bin": "<path to sdk>/bin"
                    \\}
                );
                try writer.print(
                    \\
                    \\You can obtain a {s} sdk for Windows from {s}
                    \\
                , .{ lib_name, download_url });
            },
            GetPathsError.InvalidJson => {
                try writer.print("{s} contains invalid JSON. Please fix that file!\n", .{config_path});
            },
            GetPathsError.InvalidTarget => {
                try writer.print("{s} contains an invalid zig triple. Please fix that file!\n", .{config_path});
            },
        }
    }

    fn getPaths(sdk: *Sdk, config_path: []const u8, target_local: ResolvedTarget) GetPathsError!Paths {
        const json_data = std.fs.cwd().readFileAlloc(sdk.builder.allocator, config_path, 1 << 20) catch |err| switch (err) {
            error.FileNotFound => {
                printPathsErrorMessage(sdk, config_path, target_local, GetPathsError.FileNotFound) catch |e| {
                    panic("Failed to print error message: {s}", .{@errorName(e)});
                };
                return GetPathsError.FileNotFound;
            },
            else => |e| {
                std.log.err("Failed to read config file: {s}", .{@errorName(e)});
                return GetPathsError.FileNotFound;
            },
        };
        defer sdk.builder.allocator.free(json_data);

        const parsed = std.json.parseFromSlice(std.json.Value, sdk.builder.allocator, json_data, .{}) catch {
            printPathsErrorMessage(sdk, config_path, target_local, GetPathsError.InvalidJson) catch |e| {
                panic("Failed to print error message: {s}", .{@errorName(e)});
            };
            return GetPathsError.InvalidJson;
        };
        defer parsed.deinit();

        var root_node = parsed.value.object;
        var config_iterator = root_node.iterator();
        while (config_iterator.next()) |entry| {
            const config_target = sdk.builder.resolveTargetQuery(
                std.Target.Query.parse(.{ .arch_os_abi = entry.key_ptr.* }) catch {
                    std.log.err("Invalid target in config file: {s}", .{entry.key_ptr.*});
                    return GetPathsError.InvalidTarget;
                },
            );

            if (target_local.result.cpu.arch != config_target.result.cpu.arch)
                continue;
            if (target_local.result.os.tag != config_target.result.os.tag)
                continue;
            if (target_local.result.abi != config_target.result.abi)
                continue;

            const node = entry.value_ptr.*.object;

            return Paths{
                .include = sdk.builder.allocator.dupe(u8, node.get("include").?.string) catch @panic("out of memory"),
                .libs = sdk.builder.allocator.dupe(u8, node.get("libs").?.string) catch @panic("out of memory"),
                .bin = sdk.builder.allocator.dupe(u8, node.get("bin").?.string) catch @panic("out of memory"),
            };
        }

        printPathsErrorMessage(sdk, config_path, target_local, GetPathsError.MissingTarget) catch |e| {
            panic("Failed to print error message: {s}", .{@errorName(e)});
        };
        return GetPathsError.MissingTarget;
    }

    const PrepareStubSourceStep = struct {
        const Self = @This();

        step: Step,
        sdk: *Sdk,

        assembly_source: GeneratedFile,

        pub fn create(sdk: *Sdk) *PrepareStubSourceStep {
            const psss = sdk.builder.allocator.create(Self) catch @panic("out of memory");

            psss.* = .{
                .step = Step.init(
                    .{
                        .id = .custom,
                        .name = "Prepare SDL2 stub sources",
                        .owner = sdk.builder,
                        .makeFn = make,
                    },
                ),
                .sdk = sdk,
                .assembly_source = .{ .step = &psss.step },
            };

            return psss;
        }

        pub fn getStubFile(self: *Self) LazyPath {
            return .{ .generated = .{ .file = &self.assembly_source } };
        }

        fn make(step: *Step, make_opt: Build.Step.MakeOptions) !void {
            _ = make_opt;
            const self: *Self = @fieldParentPtr("step", step);

            var cache = CacheBuilder.init(self.sdk.builder, "sdl");

            cache.addBytes(sdl2_symbol_definitions);

            var dirpath = try cache.createAndGetDir();
            defer dirpath.dir.close();

            var file = try dirpath.dir.createFile("sdl.S", .{});
            defer file.close();

            var writer = file.writer();
            try writer.writeAll(".text\n");

            var iter = std.mem.splitScalar(u8, sdl2_symbol_definitions, '\n');
            while (iter.next()) |line| {
                const sym = std.mem.trim(u8, line, " \r\n\t");
                if (sym.len == 0)
                    continue;
                try writer.print(".global {s}\n", .{sym});
                try writer.writeAll(".align 4\n");
                try writer.print("{s}:\n", .{sym});
                try writer.writeAll("  .byte 0\n");
            }

            self.assembly_source.path = try std.fs.path.join(self.sdk.builder.allocator, &[_][]const u8{
                dirpath.path,
                "sdl.S",
            });
        }
    };

    fn tripleName(allocator: std.mem.Allocator, target_local: ResolvedTarget) ![]u8 {
        const arch_name = @tagName(target_local.result.cpu.arch);
        const os_name = @tagName(target_local.result.os.tag);
        const abi_name = @tagName(target_local.result.abi);

        return std.fmt.allocPrint(allocator, "{s}-{s}-{s}", .{ arch_name, os_name, abi_name });
    }

    const CacheBuilder = struct {
        const Self = @This();

        builder: *Build,
        hasher: std.crypto.hash.Sha1,
        subdir: ?[]const u8,

        pub fn init(builder: *Build, subdir: ?[]const u8) Self {
            return Self{
                .builder = builder,
                .hasher = std.crypto.hash.Sha1.init(.{}),
                .subdir = if (subdir) |s|
                    builder.dupe(s)
                else
                    null,
            };
        }

        pub fn addBytes(self: *Self, bytes: []const u8) void {
            self.hasher.update(bytes);
        }

        pub fn addFile(self: *Self, file: LazyPath) !void {
            const path = file.getPath(self.builder);

            const data = try std.fs.cwd().readFileAlloc(self.builder.allocator, path, 1 << 32); // 4 GB
            defer self.builder.allocator.free(data);

            self.addBytes(data);
        }

        fn createPath(self: *Self) ![]const u8 {
            var hash: [20]u8 = undefined;
            self.hasher.final(&hash);

            const path = if (self.subdir) |subdir|
                try std.fmt.allocPrint(
                    self.builder.allocator,
                    "{s}/{s}/o/{}",
                    .{
                        self.builder.cache_root.path.?,
                        subdir,
                        std.fmt.fmtSliceHexLower(&hash),
                    },
                )
            else
                try std.fmt.allocPrint(
                    self.builder.allocator,
                    "{s}/o/{}",
                    .{
                        self.builder.cache_root.path.?,
                        std.fmt.fmtSliceHexLower(&hash),
                    },
                );

            return path;
        }

        pub const DirAndPath = struct {
            dir: std.fs.Dir,
            path: []const u8,
        };
        pub fn createAndGetDir(self: *Self) !DirAndPath {
            const path = try self.createPath();
            return DirAndPath{
                .path = path,
                .dir = try std.fs.cwd().makeOpenPath(path, .{}),
            };
        }

        pub fn createAndGetPath(self: *Self) ![]const u8 {
            const path = try self.createPath();
            try std.fs.cwd().makePath(path);
            return path;
        }
    };
};
