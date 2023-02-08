const std = @import("std");
const builtin = @import("builtin");
const Sdk = @import("src/deps/sdl/Sdk.zig");
const stb = @import("src/deps/stb/build.zig");
const imgui = @import("src/deps/imgui/build.zig");
const chipmunk = @import("src/deps/chipmunk/build.zig");
const nfd = @import("src/deps/nfd/build.zig");
const zmath = @import("src/deps/zmath/build.zig");
const zmesh = @import("src/deps/zmesh/build.zig");
const znoise = @import("src/deps/znoise/build.zig");
const zaudio = @import("src/deps/zaudio/build.zig");
const zphysics = @import("src/deps/zphysics/build.zig");
const ztracy = @import("src/deps/ztracy/build.zig");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const assets_install = b.addInstallDirectory(.{
        .source_dir = "examples/assets",
        .install_dir = .bin,
        .install_subdir = "assets",
    });
    const examples = [_]struct { name: []const u8, opt: BuildOptions }{
        .{ .name = "hello", .opt = .{} },
        .{ .name = "imgui_demo", .opt = .{} },
        //.{ .name = "chipmunk_demo", .opt = .{ .link_chipmunk = true } },
        .{ .name = "sprite_sheet", .opt = .{} },
        .{ .name = "sprite_scene", .opt = .{} },
        .{ .name = "sprite_benchmark", .opt = .{} },
        .{ .name = "particle_2d", .opt = .{} },
        .{ .name = "particle_3d", .opt = .{} },
        .{ .name = "animation_2d", .opt = .{} },
        .{ .name = "sprite_scene_3d", .opt = .{} },
        .{ .name = "terran_generation", .opt = .{} },
        .{ .name = "intersection_2d", .opt = .{} },
        .{ .name = "affine_texture", .opt = .{} },
        .{ .name = "solar_system", .opt = .{} },
        .{ .name = "font_demo", .opt = .{} },
        .{ .name = "skybox", .opt = .{} },
        .{ .name = "benchmark_3d", .opt = .{} },
        .{ .name = "particle_life", .opt = .{ .link_nfd = true } },
        .{ .name = "zaudio_demo", .opt = .{ .link_zaudio = true } },
        .{ .name = "audio_synthesize_demo", .opt = .{} },
        .{ .name = "hypocycloids", .opt = .{} },
    };
    const build_examples = b.step("examples", "compile and install all examples");
    inline for (examples) |demo| {
        const exe = createGame(
            b,
            demo.name,
            "examples/" ++ demo.name ++ ".zig",
            target,
            optimize,
            demo.opt,
        );
        const install_cmd = b.addInstallArtifact(exe);
        const run_cmd = exe.run();
        run_cmd.step.dependOn(&install_cmd.step);
        run_cmd.step.dependOn(&assets_install.step);
        run_cmd.cwd = "zig-out/bin";
        const run_step = b.step(
            demo.name,
            "run example " ++ demo.name,
        );
        run_step.dependOn(&run_cmd.step);
        build_examples.dependOn(&install_cmd.step);
    }
}

pub const BuildOptions = struct {
    link_chipmunk: bool = false,
    link_nfd: bool = false,
    link_zaudio: bool = false,
    link_zphysics: bool = false,
    link_ztracy: bool = false,
};

/// Create game executable
pub fn createGame(
    b: *std.Build,
    name: []const u8,
    root_file: []const u8,
    target: std.zig.CrossTarget,
    optimize: std.builtin.Mode,
    opt: BuildOptions,
) *std.build.LibExeObjStep {
    // Initialize jok module
    const bos = b.addOptions();
    bos.addOption(bool, "use_chipmunk", opt.link_chipmunk);
    bos.addOption(bool, "use_nfd", opt.link_nfd);
    bos.addOption(bool, "use_zaudio", opt.link_zaudio);
    bos.addOption(bool, "use_zphysics", opt.link_zphysics);
    bos.addOption(bool, "use_ztracy", opt.link_ztracy);
    const sdl_sdk = Sdk.init(b, null);
    const zmath_pkg = zmath.package(b, .{});
    const zmesh_pkg = zmesh.package(b, .{});
    const znoise_pkg = znoise.package(b, .{});
    const zaudio_pkg = zaudio.package(b, .{});
    const zphysics_pkg = zphysics.package(b, .{});
    const ztracy_pkg = ztracy.package(b, .{});
    const jok = b.createModule(.{
        .source_file = .{ .path = thisDir() ++ "/src/jok.zig" },
        .dependencies = &.{
            .{ .name = "build_options", .module = bos.createModule() },
            .{ .name = "sdl", .module = sdl_sdk.getWrapperModule() },
            .{ .name = "zgui", .module = imgui.getZguiModule(b) },
            .{ .name = "zmath", .module = zmath_pkg.module },
            .{ .name = "zmesh", .module = zmesh_pkg.module },
            .{ .name = "znoise", .module = znoise_pkg.module },
            .{ .name = "zaudio", .module = zaudio_pkg.module },
            .{ .name = "zphysics", .module = zphysics_pkg.module },
            .{ .name = "ztracy", .module = ztracy_pkg.module },
        },
    });

    // Initialize executable
    const exe = b.addExecutable(.{
        .name = name,
        .root_source_file = .{ .path = thisDir() ++ "/src/app.zig" },
        .target = target,
        .optimize = optimize,
    });
    exe.addModule("sdl", sdl_sdk.getWrapperModule());
    exe.addModule("jok", jok);
    exe.addModule("game", b.createModule(.{
        .source_file = .{ .path = root_file },
        .dependencies = &.{
            .{ .name = "sdl", .module = sdl_sdk.getWrapperModule() },
            .{ .name = "jok", .module = jok },
        },
    }));

    // Link libraries
    sdl_sdk.link(exe, .dynamic);
    stb.link(exe);
    imgui.link(exe);
    zmesh.link(exe, zmesh_pkg.options);
    znoise.link(exe);
    if (opt.link_chipmunk) {
        chipmunk.link(exe);
    }
    if (opt.link_nfd) {
        nfd.link(exe);
    }
    if (opt.link_zaudio) {
        zaudio.link(exe);
    }
    if (opt.link_zphysics) {
        zphysics.link(exe, zphysics_pkg.options);
    }
    if (opt.link_ztracy) {
        ztracy.link(exe, ztracy_pkg.options);
    }

    return exe;
}

inline fn thisDir() []const u8 {
    return comptime std.fs.path.dirname(@src().file) orelse ".";
}
