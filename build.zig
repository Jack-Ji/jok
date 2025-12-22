const std = @import("std");
const assert = std.debug.assert;
const Build = std.Build;
const ResolvedTarget = Build.ResolvedTarget;
const OptimizeMode = std.builtin.OptimizeMode;
const builtin = @import("builtin");

pub fn build(b: *Build) void {
    if (b.option(bool, "skipbuild", "skip all build jobs, false by default.")) |skip| {
        if (skip) return;
    }

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Add test suits
    const jok = getJokLibrary(b, target, optimize, .{
        .dep_name = null,
    });
    const root = b.createModule(.{
        .root_source_file = b.path("src/jok.zig"),
        .target = target,
        .optimize = optimize,
    });
    root.link_libc = true;
    root.linkLibrary(jok.artifact);
    root.addImport("sdl", getSdlModule(b, target, optimize));
    const tests = b.addTest(.{
        .name = "all",
        .root_module = root,
    });
    const test_step = b.step("test", "run tests");
    test_step.dependOn(&b.addRunArtifact(tests).step);

    // Add examples
    const examples = [_]struct { name: []const u8, opt: ExampleOptions }{
        .{ .name = "hello", .opt = .{} },
        .{ .name = "zgui_demo", .opt = .{} },
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
        .{ .name = "particle_life", .opt = .{ .support_web = false } },
        .{ .name = "audio_demo", .opt = .{ .preload_path = "examples/assets" } },
        .{ .name = "easing", .opt = .{} },
        .{ .name = "svg", .opt = .{ .preload_path = "examples/assets" } },
        .{ .name = "blending", .opt = .{ .preload_path = "examples/assets" } },
        .{ .name = "pathfind", .opt = .{} },
        .{ .name = "isometric", .opt = .{ .preload_path = "examples/assets" } },
        .{ .name = "conway_life", .opt = .{} },
        .{ .name = "tiled", .opt = .{ .preload_path = "examples/assets" } },
        .{ .name = "2048", .opt = .{} },
        .{ .name = "hotreload", .opt = .{ .plugin = "plugin", .support_web = false } },
        .{ .name = "generative_art_1", .opt = .{} },
        .{ .name = "generative_art_2", .opt = .{} },
        .{ .name = "generative_art_3", .opt = .{} },
        .{ .name = "generative_art_4", .opt = .{} },
        .{ .name = "generative_art_5", .opt = .{} },
    };
    const build_examples = b.step("examples", "compile and install all examples");
    for (examples) |ex| addExample(b, ex.name, target, optimize, build_examples, ex.opt);

    setupDocs(b, target, optimize);
}

const ExampleOptions = struct {
    plugin: ?[]const u8 = null,
    support_web: bool = true,
    preload_path: ?[]const u8 = null,
};

/// Helper for creating examples
fn addExample(
    b: *Build,
    name: []const u8,
    target: ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
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
            },
        );

        const install_cmd = b.addInstallArtifact(exe, .{});
        b.step(name, b.fmt("compile {s}", .{name})).dependOn(&install_cmd.step);

        // Create plugin
        if (opt.plugin) |pname| {
            const plugin_mod = b.createModule(.{
                .root_source_file = b.path(b.fmt("examples/{s}.zig", .{pname})),
                .target = target,
                .optimize = optimize,
            });
            const plugin_lib = b.addLibrary(.{
                .linkage = .dynamic,
                .name = pname,
                .root_module = plugin_mod,
            });
            const install_plugin = b.addInstallArtifact(
                plugin_lib,
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
        examples.dependOn(&install_cmd.step);
    } else if (opt.support_web) {
        const webapp = createWebApp(
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
        examples.dependOn(&webapp.emlink.step);
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
    root.linkLibrary(jok.artifact);

    // Create executable
    const exe = builder.addExecutable(.{
        .name = name,
        .root_module = root,
    });

    return exe;
}

pub const WebOptions = struct {
    dep_name: ?[]const u8 = "jok",
    additional_deps: []const Dependency = &.{},
    shell_file_path: ?[]const u8 = null,
    preload_path: ?[]const u8 = null,
};

/// Create web application (windows/linux/macos)
pub fn createWebApp(
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
    root.linkLibrary(jok.artifact);

    // Create wasm object file
    const lib = builder.addLibrary(.{
        .name = name,
        .root_module = root,
    });

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
};
fn getJokLibrary(b: *Build, target: ResolvedTarget, optimize: std.builtin.OptimizeMode, opt: JokOptions) struct {
    module: *Build.Module,
    artifact: *Build.Step.Compile,
} {
    const builder = getJokBuilder(b, opt.dep_name);
    const jokmod = builder.createModule(.{
        .root_source_file = builder.path("src/jok.zig"),
        .target = target,
        .optimize = optimize,
    });
    jokmod.addImport("sdl", getSdlModule(builder, target, optimize));

    const libmod = builder.createModule(.{
        .root_source_file = builder.path("src/jok.zig"),
        .target = target,
        .optimize = optimize,
    });
    libmod.addImport("sdl", getSdlModule(builder, target, optimize));
    @import("src/vendor/physfs/build.zig").inject(libmod);
    @import("src/vendor/stb/build.zig").inject(libmod);
    @import("src/vendor/svg/build.zig").inject(libmod);
    @import("src/vendor/zgui/build.zig").inject(libmod);
    @import("src/vendor/zaudio/build.zig").inject(libmod);
    @import("src/vendor/zmath/build.zig").inject(libmod);
    @import("src/vendor/zmesh/build.zig").inject(libmod);
    @import("src/vendor/zobj/build.zig").inject(libmod);
    @import("src/vendor/znoise/build.zig").inject(libmod);

    var lib: *Build.Step.Compile = undefined;
    if (target.result.cpu.arch.isWasm()) {
        lib = builder.addLibrary(.{ .name = "jok", .root_module = libmod });

        // Setup emscripten when necessary
        const em = Emscripten.init(b, builder.dependency("emsdk", .{}));
        em.possibleSetup(&lib.step);

        // Add the Emscripten system include seach path
        libmod.addCMacro("__WINT_TYPE__", "unsigned int");
        jokmod.addCMacro("__WINT_TYPE__", "unsigned int");
        libmod.addSystemIncludePath(em.path(&.{ "upstream", "emscripten", "cache", "sysroot", "include" }));
        jokmod.addSystemIncludePath(em.path(&.{ "upstream", "emscripten", "cache", "sysroot", "include" }));
    } else {
        lib = builder.addLibrary(.{
            .linkage = .static,
            .name = "jok",
            .root_module = libmod,
        });

        const sdl_dep = builder.dependency("sdl", .{ .target = target, .optimize = optimize });
        const sdl_lib = sdl_dep.artifact("SDL3");
        libmod.linkLibrary(sdl_lib);
    }

    return .{ .module = jokmod, .artifact = lib };
}

// Get jok's own builder from project's
fn getJokBuilder(b: *Build, dep_name: ?[]const u8) *Build {
    return if (dep_name) |dep| b.dependency(dep, .{ .skipbuild = true }).builder else b;
}

// Get module for SDL3 headers
fn getSdlModule(b: *Build, target: Build.ResolvedTarget, optimize: OptimizeMode) *Build.Module {
    const sdl_dep = b.dependency("sdl", .{});
    const tc = b.addTranslateC(.{
        .root_source_file = sdl_dep.path("include/SDL3/SDL.h"),
        .target = target,
        .optimize = optimize,
    });
    tc.addIncludePath(sdl_dep.path("include"));
    tc.defineCMacro("SDL_DISABLE_OLD_NAMES", null);
    if (target.result.cpu.arch.isWasm()) {
        // Setup emscripten when necessary
        const em = Emscripten.init(b, b.dependency("emsdk", .{}));
        em.possibleSetup(&tc.step);

        // Add the Emscripten system include seach path
        tc.defineCMacro("__WINT_TYPE__", "unsigned int");
        tc.addSystemIncludePath(em.path(&.{ "upstream", "emscripten", "cache", "sysroot", "include" }));
    }
    return tc.createModule();
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
    fn possibleSetup(sdk: *Sdk, step: *Build.Step) void {
        const dot_emsc_path = sdk.path(&.{".emscripten"}).getPath(sdk.builder);
        const dot_emsc_exists = !std.meta.isError(std.fs.accessAbsolute(dot_emsc_path, .{}));
        if (!dot_emsc_exists) {
            const emsdk_install = sdk.createEmsdkStep();
            emsdk_install.addArgs(&.{ "install", "latest" });
            const emsdk_activate = sdk.createEmsdkStep();
            emsdk_activate.addArgs(&.{ "activate", "latest" });
            emsdk_activate.step.dependOn(&emsdk_install.step);
            step.dependOn(&emsdk_activate.step);
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
        release_use_lto: bool = true,
        use_filesystem: bool = true,
        use_emmalloc: bool = false,
        extra_args: []const []const u8 = &.{},
    };
    fn link(sdk: *Sdk, opt: EmLinkOptions) *Build.Step.InstallDir {
        const emcc_path = sdk.path(&.{ "upstream", "emscripten", "emcc" }).getPath(sdk.builder);
        const emcc = sdk.builder.addSystemCommand(&.{emcc_path});
        emcc.setName("emcc");
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
        }
        emcc.addArg("-sUSE_SDL=3");
        emcc.addArg("-sINITIAL_MEMORY=128mb");
        emcc.addArg("-sALLOW_MEMORY_GROWTH=1");
        emcc.addArg("-sMAXIMUM_MEMORY=2gb");
        emcc.addArg("-sERROR_ON_UNDEFINED_SYMBOLS=0");
        if (opt.shell_file_path) |p| emcc.addPrefixedFileArg("--shell-file=", p);
        if (opt.preload_path) |p| {
            emcc.addArg("--preload-file");
            emcc.addArg(sdk.builder.fmt("{s}@/", .{sdk.builder.pathFromRoot(p)}));
        }
        if (!opt.use_filesystem) emcc.addArg("-sNO_FILESYSTEM=1");
        if (opt.use_emmalloc) emcc.addArg("-sMALLOC='emmalloc'");
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
