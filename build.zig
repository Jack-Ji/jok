const std = @import("std");
const builtin = @import("builtin");
const Sdk = @import("src/deps/sdl/Sdk.zig");
const stb = @import("src/deps/stb/build.zig");
const imgui = @import("src/deps/imgui/build.zig");
const chipmunk = @import("src/deps/chipmunk/build.zig");
const nfd = @import("src/deps/nfd/build.zig");
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
        .{ .name = "chipmunk_demo", .opt = .{ .link_chipmunk = true } },
        .{ .name = "sprite_sheet", .opt = .{} },
        .{ .name = "sprite_scene", .opt = .{} },
        .{ .name = "sprite_benchmark", .opt = .{} },
        .{ .name = "particle_2d", .opt = .{} },
        .{ .name = "particle_3d", .opt = .{} },
        .{ .name = "animation_2d", .opt = .{} },
        .{ .name = "primitive_2d", .opt = .{} },
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
    const exe = b.addExecutable(.{
        .name = name,
        .root_source_file = .{ .path = thisDir() ++ "/src/app.zig" },
        .target = target,
        .optimize = optimize,
    });
    const exe_options = b.addOptions();
    exe.addOptions("build_options", exe_options);

    // Link must-have dependencies
    const sdk = Sdk.init(exe.builder, null);
    sdk.link(exe, .dynamic);
    stb.link(exe);
    zmesh.link(exe, zmesh.BuildOptionsStep.init(b, .{}));
    znoise.link(exe);
    imgui.link(exe);

    // Link optional dependencies and set comptime flags
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
        zphysics.link(exe, zphysics.BuildOptionsStep.init(b, .{}));
    }
    if (opt.link_ztracy) {
        ztracy.link(exe, ztracy.BuildOptionsStep.init(b, .{}));
    }
    exe_options.addOption(bool, "use_chipmunk", opt.link_chipmunk);
    exe_options.addOption(bool, "use_nfd", opt.link_nfd);
    exe_options.addOption(bool, "use_zaudio", opt.link_zaudio);
    exe_options.addOption(bool, "use_zphysics", opt.link_zphysics);
    exe_options.addOption(bool, "use_ztracy", opt.link_ztracy);

    // Add modules
    const jok = getJokModule(b);
    const game = b.createModule(.{
        .source_file = .{ .path = root_file },
        .dependencies = &.{
            .{ .name = "jok", .module = jok },
            .{ .name = "sdl", .module = sdk.getWrapperModule() },
        },
    });
    exe.addModule("sdl", sdk.getWrapperModule());
    exe.addModule("jok", jok);
    exe.addModule("game", game);
    return exe;
}

pub fn getJokModule(b: *std.Build) *std.Build.Module {
    return b.createModule(.{
        .source_file = .{ .path = thisDir() ++ "/src/jok.zig" },
    });
}

inline fn thisDir() []const u8 {
    return comptime std.fs.path.dirname(@src().file) orelse ".";
}
