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
    const root = b.createModule(.{
        .root_source_file = b.path("src/jok.zig"),
        .target = target,
        .optimize = optimize,
    });
    const tests = b.addTest(.{
        .name = "all",
        .root_module = root,
    });
    tests.linkLibC();
    tests.addIncludePath(b.dependency("sdl", .{}).path("include"));
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
    };
    const build_examples = b.step("examples", "compile and install all examples");
    for (examples) |ex| addExample(b, ex.name, target, optimize, skipped_examples, build_examples, ex.opt);

    setupDocs(b, target, optimize);
}

const ExampleOptions = struct {
    use_nfd: bool = false,
    support_web: bool = true,
    preload_path: ?[]const u8 = null,
};

/// Helper for creating examples
fn addExample(
    b: *Build,
    name: []const u8,
    target: ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
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
                .use_nfd = opt.use_nfd,
            },
        );

        const install_cmd = b.addInstallArtifact(exe, .{});
        b.step(name, b.fmt("compile {s}", .{name})).dependOn(&install_cmd.step);

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
            },
        );
        b.step(name, b.fmt("compile {s}", .{name})).dependOn(&webapp.emlink.step);
        b.step(b.fmt("run-{s}", .{name}), b.fmt("run {s}", .{name})).dependOn(&webapp.emrun.step);
        if (skipped.get("hotreload") == null) examples.dependOn(&webapp.emlink.step);
    }
}

/// Generate docs of framework
fn setupDocs(b: *std.Build, target: ResolvedTarget, optimize: std.builtin.OptimizeMode) void {
    const jok = getJokLibrary(b, target, optimize, .{
        .dep_name = null,
    });
    const lib = b.addLibrary(.{
        .root_module = jok.module,
        .name = "jok",
    });
    const docs = b.addInstallDirectory(.{
        .source_dir = lib.getEmittedDocs(),
        .install_dir = .{ .prefix = {} },
        .install_subdir = "docs",
    });
    const docs_step = b.step("docs", "generate documentation");
    docs_step.dependOn(&docs.step);
}

pub const Dependency = struct {
    name: []const u8,
    mod: *Build.Module,
};

pub const AppOptions = struct {
    dep_name: ?[]const u8 = "jok",
    additional_deps: []const Dependency = &.{},
    no_audio: bool = false,
    use_nfd: bool = false,
};

/// Create desktop application (windows/linux/macos)
pub fn createDesktopApp(
    b: *Build,
    name: []const u8,
    game_root: []const u8,
    target: ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    opt: AppOptions,
) *Build.Step.Compile {
    assert(target.result.os.tag == .windows or target.result.os.tag == .linux or target.result.os.tag == .macos);
    const jok = getJokLibrary(b, target, optimize, .{
        .dep_name = opt.dep_name,
        .no_audio = opt.no_audio,
        .use_nfd = opt.use_nfd,
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
    exe.linkLibrary(jok.artifact);

    return exe;
}

/// Create test executable (windows/linux/macos)
pub fn createTest(
    b: *Build,
    name: []const u8,
    root_source_file: []const u8,
    target: ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    opt: AppOptions,
) *Build.Step.Compile {
    assert(target.result.os.tag == .windows or target.result.os.tag == .linux or target.result.os.tag == .macos);
    const jok = getJokLibrary(b, target, optimize, .{
        .dep_name = opt.dep_name,
        .no_audio = opt.no_audio,
        .use_nfd = opt.use_nfd,
    });

    // Create module to be used for testing
    const builder = getJokBuilder(b, opt.dep_name);
    const root = b.createModule(.{
        .root_source_file = b.path(root_source_file),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "jok", .module = jok.module },
        },
    });
    for (opt.additional_deps) |d| {
        root.addImport(d.name, d.mod);
    }

    // Create test executable
    const test_exe = builder.addTest(.{
        .name = name,
        .root_module = root,
    });
    test_exe.linkLibrary(jok.artifact);

    return test_exe;
}

pub const WebOptions = struct {
    dep_name: ?[]const u8 = "jok",
    additional_deps: []const Dependency = &.{},
    shell_file_path: ?[]const u8 = null,
    preload_path: ?[]const u8 = null,
    no_audio: bool = false,
};

/// Create web application (windows/linux/macos)
pub fn createWeb(
    b: *Build,
    name: []const u8,
    game_root: []const u8,
    target: ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    opt: WebOptions,
) struct {
    emlink: *Build.Step.InstallDir,
    emrun: *Build.Step.Run,
} {
    assert(target.result.cpu.arch.isWasm() and target.result.os.tag == .emscripten);
    const jok = getJokLibrary(b, target, optimize, .{
        .dep_name = opt.dep_name,
        .no_audio = opt.no_audio,
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
    const lib = builder.addLibrary(.{
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
    use_nfd: bool = false,
};
fn getJokLibrary(b: *Build, target: ResolvedTarget, optimize: std.builtin.OptimizeMode, opt: JokOptions) struct {
    module: *Build.Module,
    artifact: *Build.Step.Compile,
} {
    const builder = getJokBuilder(b, opt.dep_name);
    const bos = builder.addOptions();
    bos.addOption(bool, "no_audio", opt.no_audio);
    bos.addOption(bool, "use_nfd", opt.use_nfd);
    const jokmod = builder.createModule(.{
        .root_source_file = builder.path("src/jok.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "build_options", .module = bos.createModule() },
        },
    });
    jokmod.addIncludePath(builder.dependency("sdl", .{}).path("include"));

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
    if (opt.use_nfd) @import("src/vendor/nfd/build.zig").inject(libmod, builder.path("src/vendor/nfd"));

    var lib: *Build.Step.Compile = undefined;
    if (target.result.cpu.arch.isWasm()) {
        lib = builder.addLibrary(.{ .name = "jok", .root_module = libmod });

        // Setup emscripten when necessary
        const em = Emscripten.init(b, builder.dependency("emsdk", .{}));
        em.possibleSetup(lib);

        // Add the Emscripten system include seach path
        lib.addSystemIncludePath(em.path(&.{ "upstream", "emscripten", "cache", "sysroot", "include" }));
    } else {
        lib = builder.addLibrary(.{
            .linkage = .static,
            .name = "jok",
            .root_module = libmod,
        });

        const sdl_dep = builder.dependency("sdl", .{
            .target = target,
            .optimize = optimize,
        });
        const sdl_lib = sdl_dep.artifact("SDL3");
        libmod.linkLibrary(sdl_lib);
    }

    return .{ .module = jokmod, .artifact = lib };
}

// Get jok's own builder from project's
fn getJokBuilder(b: *Build, dep_name: ?[]const u8) *Build {
    return if (dep_name) |dep| b.dependency(dep, .{ .skipbuild = true }).builder else b;
}

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
        emcc.addArg("-sUSE_SDL=3");
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
