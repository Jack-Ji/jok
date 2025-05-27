const std = @import("std");
const assert = std.debug.assert;
const panic = std.debug.panic;
const Build = std.Build;
const ResolvedTarget = Build.ResolvedTarget;
const OptimizeMode = std.builtin.OptimizeMode;
const builtin = @import("builtin");

pub fn build(b: *Build) void {
    if (b.option(bool, "skipbuild", "skip all build jobs, false by default.")) |skip| {
        if (skip) return;
    }

    // Get skipped examples' names
    var skipped_examples = std.StringHashMap(bool).init(b.allocator);
    if (b.option(
        []const u8,
        "skip",
        "skip given demos when building `examples`. e.g. \"particle_life,intersection_2d\"",
    )) |s| {
        var it = std.mem.splitScalar(u8, s, ',');
        while (it.next()) |name| skipped_examples.put(name, true) catch unreachable;
    }

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Add test suits
    const tests = b.addTest(.{
        .name = "all",
        .root_source_file = b.path("src/jok.zig"),
    });
    const test_step = b.step("test", "run tests");
    test_step.dependOn(&b.addRunArtifact(tests).step);

    // Add examples
    const examples = [_]struct { name: []const u8, opt: ExampleOptions }{
        .{ .name = "hello", .opt = .{} },
        .{ .name = "imgui_demo", .opt = .{} },
        .{ .name = "sprite_benchmark", .opt = .{ .preload_path = "examples/assets" } },
        .{ .name = "cube_benchmark", .opt = .{ .preload_path = "examples/assets" } },
        .{ .name = "sprite_sheet", .opt = .{ .preload_path = "examples/assets" } },
        .{ .name = "sprite_scene_2d", .opt = .{ .preload_path = "examples/assets" } },
        .{ .name = "sprite_scene_3d", .opt = .{ .preload_path = "examples/assets" } },
        .{ .name = "particle_2d", .opt = .{ .preload_path = "examples/assets" } },
        .{ .name = "particle_3d", .opt = .{ .preload_path = "examples/assets" } },
        .{ .name = "animation_2d", .opt = .{ .preload_path = "examples/assets" } },
        .{ .name = "animation_3d", .opt = .{ .preload_path = "examples/assets" } },
        .{ .name = "primitive_2d", .opt = .{ .preload_path = "examples/assets" } },
        .{ .name = "meshes_and_lighting", .opt = .{} },
        .{ .name = "intersection_2d", .opt = .{} },
        .{ .name = "solar_system", .opt = .{} },
        .{ .name = "font_demo", .opt = .{} },
        .{ .name = "skybox", .opt = .{ .preload_path = "examples/assets" } },
        .{ .name = "particle_life", .opt = .{ .use_nfd = true, .support_web = false } },
        .{ .name = "audio_demo", .opt = .{ .preload_path = "examples/assets" } },
        .{ .name = "easing", .opt = .{} },
        .{ .name = "svg", .opt = .{ .preload_path = "examples/assets" } },
        .{ .name = "cp_demo", .opt = .{ .use_cp = true } },
        .{ .name = "blending", .opt = .{ .preload_path = "examples/assets" } },
        .{ .name = "pathfind", .opt = .{} },
        .{ .name = "post_processing", .opt = .{ .preload_path = "examples/assets" } },
        .{ .name = "isometric", .opt = .{ .preload_path = "examples/assets" } },
        .{ .name = "conway_life", .opt = .{} },
        .{ .name = "tiled", .opt = .{ .preload_path = "examples/assets" } },
        .{ .name = "generative_art_1", .opt = .{} },
        .{ .name = "generative_art_2", .opt = .{} },
        .{ .name = "generative_art_3", .opt = .{} },
        .{ .name = "generative_art_4", .opt = .{} },
        .{ .name = "generative_art_5", .opt = .{} },
        .{ .name = "hotreload", .opt = .{ .plugins = &.{ "plugin_hot", "plugin" }, .support_web = false } },
    };
    const build_examples = b.step("examples", "compile and install all examples");
    for (examples) |ex| addExample(b, ex.name, target, optimize, skipped_examples, build_examples, ex.opt);
}

const ExampleOptions = struct {
    plugins: []const []const u8 = &.{},
    use_cp: bool = false,
    use_nfd: bool = false,
    support_web: bool = true,
    preload_path: ?[]const u8 = null,
};

/// Helper for creating examples
fn addExample(
    b: *Build,
    name: []const u8,
    target: ResolvedTarget,
    optimize: std.builtin.Mode,
    skipped: std.StringHashMap(bool),
    examples: *Build.Step,
    opt: ExampleOptions,
) void {
    if (!target.result.cpu.arch.isWasm()) {
        const assets_install = b.addInstallDirectory(.{
            .source_dir = b.path("examples/assets"),
            .install_dir = .bin,
            .install_subdir = "assets",
        });

        const exe = createDesktopApp(
            b,
            name,
            b.fmt("examples/{s}.zig", .{name}),
            target,
            optimize,
            .{
                .dep_name = null,
                .use_cp = opt.use_cp,
                .use_nfd = opt.use_nfd,
                .link_dynamic = opt.plugins.len != 0,
            },
        );

        const install_cmd = b.addInstallArtifact(exe, .{});
        b.step(name, b.fmt("compile {s}", .{name})).dependOn(&install_cmd.step);

        // Create plugins
        for (opt.plugins) |pname| {
            const plugin = createPlugin(
                b,
                pname,
                b.fmt("examples/{s}.zig", .{pname}),
                target,
                optimize,
                .{ .dep_name = null, .link_dynamic = true },
            );
            const install_plugin = b.addInstallArtifact(
                plugin,
                .{ .dest_dir = .{ .override = .{ .bin = {} } } },
            );
            b.step(pname, b.fmt("compile plugin {s}", .{pname})).dependOn(&install_plugin.step);
            install_cmd.step.dependOn(&install_plugin.step);
        }

        // Capable of running
        if (target.query.isNative()) {
            const run_cmd = b.addRunArtifact(exe);
            run_cmd.step.dependOn(&install_cmd.step);
            run_cmd.step.dependOn(&assets_install.step);
            run_cmd.cwd = b.path("zig-out/bin");
            b.step(b.fmt("run-{s}", .{name}), b.fmt("run {s}", .{name})).dependOn(&run_cmd.step);
        }
        if (skipped.get(name) == null) examples.dependOn(&install_cmd.step);
    } else if (opt.support_web) {
        const webapp = createWeb(
            b,
            name,
            b.fmt("examples/{s}.zig", .{name}),
            target,
            optimize,
            .{
                .dep_name = null,
                .preload_path = opt.preload_path,
                .use_cp = opt.use_cp,
            },
        );
        b.step(name, b.fmt("compile {s}", .{name})).dependOn(&webapp.emlink.step);
        b.step(b.fmt("run-{s}", .{name}), b.fmt("run {s}", .{name})).dependOn(&webapp.emrun.step);
        if (skipped.get("hotreload") == null) examples.dependOn(&webapp.emlink.step);
    }
}

pub const Dependency = struct {
    name: []const u8,
    mod: *Build.Module,
};

pub const AppOptions = struct {
    dep_name: ?[]const u8 = "jok",
    additional_deps: []const Dependency = &.{},
    no_audio: bool = false,
    use_cp: bool = false,
    use_nfd: bool = false,
    link_dynamic: bool = false,
};

/// Create desktop application (windows/linux/macos)
pub fn createDesktopApp(
    b: *Build,
    name: []const u8,
    game_root: []const u8,
    target: ResolvedTarget,
    optimize: std.builtin.Mode,
    opt: AppOptions,
) *Build.Step.Compile {
    assert(target.result.os.tag == .windows or target.result.os.tag == .linux or target.result.os.tag == .macos);
    const sdk = CrossSDL.init(b);
    const jok = getJokLibrary(b, target, optimize, .{
        .dep_name = opt.dep_name,
        .no_audio = opt.no_audio,
        .use_cp = opt.use_cp,
        .use_nfd = opt.use_nfd,
        .link_dynamic = opt.link_dynamic,
    });

    // Create game module
    const game = b.createModule(.{
        .root_source_file = b.path(game_root),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "jok", .module = jok.module },
        },
    });
    for (opt.additional_deps) |d| {
        game.addImport(d.name, d.mod);
    }

    // Create root module
    const builder = getJokBuilder(b, opt.dep_name);
    const root = b.createModule(.{
        .root_source_file = builder.path("src/entrypoints/app.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "jok", .module = jok.module },
            .{ .name = "game", .module = game },
        },
    });

    // Create executable
    const exe = builder.addExecutable(.{
        .name = name,
        .root_module = root,
    });
    sdk.link(exe, .dynamic);
    exe.linkLibrary(jok.artifact);

    // Install jok library
    if (opt.link_dynamic) {
        const install_jok = b.addInstallArtifact(jok.artifact, .{ .dest_dir = .{ .override = .{ .bin = {} } } });
        exe.addLibraryPath(.{ .cwd_relative = "." });
        exe.step.dependOn(&install_jok.step);
    }

    return exe;
}

/// Create test executable (windows/linux/macos)
pub fn createTest(
    b: *Build,
    name: []const u8,
    root_source_file: []const u8,
    target: ResolvedTarget,
    optimize: std.builtin.Mode,
    opt: AppOptions,
) *Build.Step.Compile {
    assert(target.result.os.tag == .windows or target.result.os.tag == .linux or target.result.os.tag == .macos);
    const sdk = CrossSDL.init(b);
    const jok = getJokLibrary(b, target, optimize, .{
        .dep_name = opt.dep_name,
        .no_audio = opt.no_audio,
        .use_cp = opt.use_cp,
        .use_nfd = opt.use_nfd,
        .link_dynamic = opt.link_dynamic,
    });

    // Create module to be used for testing
    const module = b.createModule(.{
        .root_source_file = b.path(root_source_file),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "jok", .module = jok.module },
        },
    });
    for (opt.additional_deps) |d| {
        module.addImport(d.name, d.mod);
    }

    // Create test executable
    const builder = getJokBuilder(b, opt.dep_name);
    const test_exe = builder.addTest(.{
        .name = name,
        .root_module = module,
    });
    sdk.link(test_exe, .dynamic);
    test_exe.linkLibrary(jok.artifact);

    // Install jok library
    if (opt.link_dynamic) {
        const install_jok = b.addInstallArtifact(jok.artifact, .{ .dest_dir = .{ .override = .{ .bin = {} } } });
        test_exe.addLibraryPath(.{ .cwd_relative = "." });
        test_exe.step.dependOn(&install_jok.step);
    }

    return test_exe;
}

/// Create plugin
pub fn createPlugin(
    b: *Build,
    name: []const u8,
    plugin_root: []const u8,
    target: ResolvedTarget,
    optimize: std.builtin.Mode,
    opt: AppOptions,
) *Build.Step.Compile {
    assert(target.result.os.tag == .windows or target.result.os.tag == .linux or target.result.os.tag == .macos);
    assert(opt.link_dynamic);
    const sdk = CrossSDL.init(b);
    const jok = getJokLibrary(b, target, optimize, .{
        .dep_name = opt.dep_name,
        .no_audio = opt.no_audio,
        .use_cp = opt.use_cp,
        .use_nfd = opt.use_nfd,
        .link_dynamic = opt.link_dynamic,
    });

    // Create plugin module
    const plugin = b.createModule(.{
        .root_source_file = b.path(plugin_root),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "jok", .module = jok.module },
        },
    });
    for (opt.additional_deps) |d| {
        plugin.addImport(d.name, d.mod);
    }

    // Create root module
    const builder = getJokBuilder(b, opt.dep_name);
    const root = b.createModule(.{
        .root_source_file = builder.path("src/entrypoints/plugin.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "jok", .module = jok.module },
            .{ .name = "plugin", .module = plugin },
        },
    });

    // Create shared library
    const lib = b.addSharedLibrary(.{
        .name = name,
        .root_module = root,
    });
    sdk.link(lib, .dynamic);
    lib.linkLibrary(jok.artifact);

    // Install jok library
    const install_jok = b.addInstallArtifact(jok.artifact, .{ .dest_dir = .{ .override = .{ .bin = {} } } });
    lib.addLibraryPath(.{ .cwd_relative = "." });
    lib.step.dependOn(&install_jok.step);

    return lib;
}

pub const WebOptions = struct {
    dep_name: ?[]const u8 = "jok",
    additional_deps: []const Dependency = &.{},
    shell_file_path: ?[]const u8 = null,
    preload_path: ?[]const u8 = null,
    no_audio: bool = false,
    use_cp: bool = false,
};

/// Create web application (windows/linux/macos)
pub fn createWeb(
    b: *Build,
    name: []const u8,
    game_root: []const u8,
    target: ResolvedTarget,
    optimize: std.builtin.Mode,
    opt: WebOptions,
) struct {
    emlink: *Build.Step.InstallDir,
    emrun: *Build.Step.Run,
} {
    assert(target.result.cpu.arch.isWasm() and target.result.os.tag == .emscripten);
    const jok = getJokLibrary(b, target, optimize, .{
        .dep_name = opt.dep_name,
        .no_audio = opt.no_audio,
        .use_cp = opt.use_cp,
    });

    // Create game module
    const game = b.createModule(.{
        .root_source_file = b.path(game_root),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "jok", .module = jok.module },
        },
    });
    for (opt.additional_deps) |d| {
        game.addImport(d.name, d.mod);
    }

    // Create root module
    const builder = getJokBuilder(b, opt.dep_name);
    const root = b.createModule(.{
        .root_source_file = builder.path("src/entrypoints/web.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "jok", .module = jok.module },
            .{ .name = "game", .module = game },
        },
    });

    // Create wasm object file
    const lib = builder.addStaticLibrary(.{
        .name = name,
        .root_module = root,
    });
    lib.linkLibrary(jok.artifact);

    // Link using emcc
    const em = Emscripten.init(b, builder.dependency("emsdk", .{}));
    const link_step = em.link(.{
        .lib_main = lib,
        .target = target,
        .optimize = optimize,
        .shell_file_path = if (opt.shell_file_path) |p|
            b.path(p)
        else
            builder.path("src/entrypoints/shell.html"),
        .preload_path = opt.preload_path,
        .extra_args = &.{"-sSTACK_SIZE=4MB"},
    });

    // Special run step to run the build result via emrun
    const run = em.run(name);
    run.step.dependOn(&link_step.step);

    return .{ .emlink = link_step, .emrun = run };
}

// Create jok library
pub const JokOptions = struct {
    dep_name: ?[]const u8 = "jok",
    no_audio: bool = false,
    use_cp: bool = false,
    use_nfd: bool = false,
    link_dynamic: bool = false,
};
fn getJokLibrary(b: *Build, target: ResolvedTarget, optimize: std.builtin.Mode, opt: JokOptions) struct {
    module: *Build.Module,
    artifact: *Build.Step.Compile,
} {
    const builder = getJokBuilder(b, opt.dep_name);
    const bos = builder.addOptions();
    bos.addOption(bool, "no_audio", opt.no_audio);
    bos.addOption(bool, "use_cp", opt.use_cp);
    bos.addOption(bool, "use_nfd", opt.use_nfd);
    bos.addOption(bool, "link_dynamic", opt.link_dynamic);
    const jokmod = builder.createModule(.{
        .root_source_file = builder.path("src/jok.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "build_options", .module = bos.createModule() },
        },
    });

    const libmod = builder.createModule(.{
        .target = target,
        .optimize = optimize,
    });
    @import("src/vendor/system_sdk/build.zig").inject(libmod, builder.path("src/vendor/system_sdk"));
    @import("src/vendor/imgui/build.zig").inject(libmod, builder.path("src/vendor/imgui"));
    @import("src/vendor/physfs/build.zig").inject(libmod, builder.path("src/vendor/physfs"));
    @import("src/vendor/sdl/build.zig").inject(libmod, builder.path("src/vendor/sdl"));
    @import("src/vendor/stb/build.zig").inject(libmod, builder.path("src/vendor/stb"));
    @import("src/vendor/svg/build.zig").inject(libmod, builder.path("src/vendor/svg"));
    @import("src/vendor/zmath/build.zig").inject(libmod, builder.path("src/vendor/zmath"));
    @import("src/vendor/zmesh/build.zig").inject(libmod, builder.path("src/vendor/zmesh"));
    @import("src/vendor/zobj/build.zig").inject(libmod, builder.path("src/vendor/zobj"));
    @import("src/vendor/znoise/build.zig").inject(libmod, builder.path("src/vendor/znoise"));
    if (!opt.no_audio) @import("src/vendor/zaudio/build.zig").inject(libmod, builder.path("src/vendor/zaudio"));
    if (opt.use_cp) @import("src/vendor/chipmunk/build.zig").inject(libmod, builder.path("src/vendor/chipmunk"));
    if (opt.use_nfd) @import("src/vendor/nfd/build.zig").inject(libmod, builder.path("src/vendor/nfd"));

    var lib: *Build.Step.Compile = undefined;
    if (target.result.cpu.arch.isWasm()) {
        lib = builder.addStaticLibrary(.{ .name = "jok", .root_module = libmod });

        // Setup emscripten when necessary
        const em = Emscripten.init(b, builder.dependency("emsdk", .{}));
        em.possibleSetup(lib);

        // Add the Emscripten system include seach path
        lib.addSystemIncludePath(em.path(&.{ "upstream", "emscripten", "cache", "sysroot", "include" }));
    } else {
        lib = if (opt.link_dynamic)
            builder.addSharedLibrary(.{ .name = "jok", .root_module = libmod })
        else
            builder.addStaticLibrary(.{ .name = "jok", .root_module = libmod });
        CrossSDL.init(b).link(lib, .dynamic);
    }

    return .{ .module = jokmod, .artifact = lib };
}

// Get jok's own builder from project's
fn getJokBuilder(b: *Build, dep_name: ?[]const u8) *Build {
    return if (dep_name) |dep| b.dependency(dep, .{ .skipbuild = true }).builder else b;
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
    fn init(b: *Build) *Sdk {
        const sdk = b.allocator.create(Sdk) catch @panic("OOM");

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
        const mod = sdk.builder.createModule(.{
            .target = exe.root_module.resolved_target.?,
            .optimize = exe.root_module.optimize.?,
        });
        const build_linux_sdl_stub = sdk.builder.addSharedLibrary(.{
            .name = "SDL2",
            .root_module = mod,
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
    fn link(
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
        } else if (target.result.os.tag.isDarwin()) {
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
                .include = sdk.builder.allocator.dupe(u8, node.get("include").?.string) catch @panic("OOM"),
                .libs = sdk.builder.allocator.dupe(u8, node.get("libs").?.string) catch @panic("OOM"),
                .bin = sdk.builder.allocator.dupe(u8, node.get("bin").?.string) catch @panic("OOM"),
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

        fn create(sdk: *Sdk) *PrepareStubSourceStep {
            const psss = sdk.builder.allocator.create(Self) catch @panic("OOM");

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

        fn getStubFile(self: *Self) LazyPath {
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

        fn init(builder: *Build, subdir: ?[]const u8) Self {
            return Self{
                .builder = builder,
                .hasher = std.crypto.hash.Sha1.init(.{}),
                .subdir = if (subdir) |s|
                    builder.dupe(s)
                else
                    null,
            };
        }

        fn addBytes(self: *Self, bytes: []const u8) void {
            self.hasher.update(bytes);
        }

        fn addFile(self: *Self, file: LazyPath) !void {
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

        const DirAndPath = struct {
            dir: std.fs.Dir,
            path: []const u8,
        };
        fn createAndGetDir(self: *Self) !DirAndPath {
            const path = try self.createPath();
            return DirAndPath{
                .path = path,
                .dir = try std.fs.cwd().makeOpenPath(path, .{}),
            };
        }

        fn createAndGetPath(self: *Self) ![]const u8 {
            const path = try self.createPath();
            try std.fs.cwd().makePath(path);
            return path;
        }
    };
};

// Sdk for compile and link using emscripten
const Emscripten = struct {
    const Sdk = @This();

    builder: *Build,
    emsdk: *Build.Dependency,

    fn init(b: *Build, emsdk: *Build.Dependency) *Sdk {
        const sdk = b.allocator.create(Sdk) catch @panic("OOM");
        sdk.* = .{ .builder = b, .emsdk = emsdk };
        return sdk;
    }

    // One-time setup of the Emscripten SDK (runs 'emsdk install + activate'). If the
    // SDK had to be setup, a run step will be returned which should be added
    // as dependency to the sokol library (since this needs the emsdk in place),
    // if the emsdk was already setup, null will be returned.
    // NOTE: ideally this would go into a separate emsdk-zig package
    // NOTE 2: the file exists check is a bit hacky, it would be cleaner
    // to build an on-the-fly helper tool which takes care of the SDK
    // setup and just does nothing if it already happened
    // NOTE 3: this code works just fine when the SDK version is updated in build.zig.zon
    // since this will be cloned into a new zig cache directory which doesn't have
    // an .emscripten file yet until the one-time setup.
    fn possibleSetup(sdk: *Sdk, lib: *Build.Step.Compile) void {
        const dot_emsc_path = sdk.path(&.{".emscripten"}).getPath(sdk.builder);
        const dot_emsc_exists = !std.meta.isError(std.fs.accessAbsolute(dot_emsc_path, .{}));
        if (!dot_emsc_exists) {
            const emsdk_install = sdk.createEmsdkStep();
            emsdk_install.addArgs(&.{ "install", "latest" });
            const emsdk_activate = sdk.createEmsdkStep();
            emsdk_activate.addArgs(&.{ "activate", "latest" });
            emsdk_activate.step.dependOn(&emsdk_install.step);
            lib.step.dependOn(&emsdk_activate.step);
        }
    }

    // for wasm32-emscripten, need to run the Emscripten linker from the Emscripten SDK
    // NOTE: ideally this would go into a separate emsdk-zig package
    const EmLinkOptions = struct {
        lib_main: *Build.Step.Compile, // the actual Zig code must be compiled to a static link library
        target: Build.ResolvedTarget,
        optimize: OptimizeMode,
        shell_file_path: ?Build.LazyPath = null,
        preload_path: ?[]const u8 = null,
        release_use_closure: bool = false,
        release_use_lto: bool = true,
        use_emmalloc: bool = false,
        use_offset_converter: bool = true, // needed for @returnAddress builtin used by Zig allocators
        extra_args: []const []const u8 = &.{},
    };
    fn link(sdk: *Sdk, opt: EmLinkOptions) *Build.Step.InstallDir {
        const emcc_path = sdk.path(&.{ "upstream", "emscripten", "emcc" }).getPath(sdk.builder);
        const emcc = sdk.builder.addSystemCommand(&.{emcc_path});
        emcc.setName("emcc"); // hide emcc path
        if (opt.optimize == .Debug) {
            emcc.addArg("-sASSERTIONS");
            emcc.addArgs(&.{ "-Og", "-sSAFE_HEAP=1", "-sSTACK_OVERFLOW_CHECK=1" });
        } else {
            emcc.addArg("-sASSERTIONS=0");
            if (opt.optimize == .ReleaseSmall) {
                emcc.addArg("-Oz");
            } else {
                emcc.addArg("-O3");
            }
            if (opt.release_use_lto) emcc.addArg("-flto");
            if (opt.release_use_closure) emcc.addArgs(&.{ "--closure", "1" });
        }
        emcc.addArg("-sUSE_SDL=2");
        emcc.addArg("-sINITIAL_MEMORY=128mb");
        emcc.addArg("-sALLOW_MEMORY_GROWTH=1");
        emcc.addArg("-sMAXIMUM_MEMORY=2gb");
        if (opt.shell_file_path) |p| emcc.addPrefixedFileArg("--shell-file=", p);
        if (opt.preload_path) |p| {
            emcc.addArg("--preload-file");
            emcc.addArg(sdk.builder.fmt("{s}@/", .{sdk.builder.pathFromRoot(p)}));
        }
        if (opt.use_emmalloc) emcc.addArg("-sMALLOC='emmalloc'");
        if (opt.use_offset_converter) emcc.addArg("-sUSE_OFFSET_CONVERTER");
        for (opt.extra_args) |arg| emcc.addArg(arg);

        // add the main lib, and then scan for library dependencies and add those too
        emcc.addArtifactArg(opt.lib_main);

        for (opt.lib_main.getCompileDependencies(false)) |item| {
            if (item.kind == .lib) {
                emcc.addArtifactArg(item);
            }
        }
        emcc.addArg("-o");
        const out_file = emcc.addOutputFileArg(sdk.builder.fmt("{s}.html", .{opt.lib_main.name}));

        // the emcc linker creates 3 output files (.html, .wasm and .js)
        const install = sdk.builder.addInstallDirectory(.{
            .source_dir = out_file.dirname(),
            .install_dir = .prefix,
            .install_subdir = "web",
        });
        install.step.dependOn(&emcc.step);

        return install;
    }

    // build a run step which uses the emsdk emrun command to run a build target in the browser
    // NOTE: ideally this would go into a separate emsdk-zig package
    fn run(sdk: *Sdk, name: []const u8) *Build.Step.Run {
        const emrun_path = sdk.builder.findProgram(&.{"emrun"}, &.{}) catch
            sdk.path(&.{ "upstream", "emscripten", "emrun" }).getPath(sdk.builder);
        return sdk.builder.addSystemCommand(&.{ emrun_path, sdk.builder.fmt("{s}/web/{s}.html", .{ sdk.builder.install_path, name }) });
    }

    fn createEmsdkStep(sdk: *Sdk) *Build.Step.Run {
        if (builtin.os.tag == .windows) {
            return sdk.builder.addSystemCommand(&.{sdk.path(&.{"emsdk.bat"}).getPath(sdk.builder)});
        } else {
            const step = sdk.builder.addSystemCommand(&.{"bash"});
            step.addArg(sdk.path(&.{"emsdk"}).getPath(sdk.builder));
            return step;
        }
    }

    // helper function to build a LazyPath from the emsdk root and provided path components
    fn path(sdk: *Sdk, subPaths: []const []const u8) Build.LazyPath {
        return sdk.emsdk.path(sdk.builder.pathJoin(subPaths));
    }
};
