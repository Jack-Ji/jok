const std = @import("std");
const builtin = @import("builtin");
const sdlsdk = @import("src/deps/sdl/Sdk.zig");
const miniaudio = @import("src/deps/miniaudio/build.zig");
const stb = @import("src/deps/stb/build.zig");
const imgui = @import("src/deps/imgui/build.zig");
const chipmunk = @import("src/deps/chipmunk/build.zig");
const nfd = @import("src/deps/nfd/build.zig");
const zmesh = @import("src/deps/zmesh/build.zig");
const znoise = @import("src/deps/znoise/build.zig");
const zbullet = @import("src/deps/zbullet/build.zig");
const znetwork = @import("src/deps/znetwork/build.zig");
const ztracy = @import("src/deps/ztracy/build.zig");

pub fn build(b: *std.build.Builder) void {
    const mode = b.standardReleaseOptions();
    const target = b.standardTargetOptions(.{
        .default_target = .{
            // Prefer compatibility over performance here
            // Make your own choice
            .cpu_model = .baseline,
        },
    });

    const assets_install = b.addInstallDirectory(.{
        .source_dir = "examples/assets",
        .install_dir = .bin,
        .install_subdir = "assets",
    });
    const examples = [_]struct { name: []const u8, opt: BuildOptions }{
        .{ .name = "hello", .opt = .{} },
        .{ .name = "imgui_demo", .opt = .{ .link_imgui = true } },
        .{ .name = "chipmunk_demo", .opt = .{ .link_chipmunk = true } },
        .{ .name = "sprite_sheet", .opt = .{} },
        .{ .name = "particle_2d", .opt = .{} },
        .{ .name = "animation_2d", .opt = .{} },
        .{ .name = "primitive_2d", .opt = .{ .link_imgui = true } },
        .{ .name = "sprite_benchmark", .opt = .{} },
        .{ .name = "font_demo", .opt = .{} },
        .{ .name = "audio_demo", .opt = .{} },
        .{ .name = "audio_synthesize_demo", .opt = .{} },
        .{ .name = "basic_3d", .opt = .{ .link_zmesh = true } },
        .{ .name = "benchmark_3d", .opt = .{ .link_zmesh = true } },
    };
    const build_examples = b.step("build_examples", "compile and install all examples");
    inline for (examples) |demo| {
        const exe = createGame(
            b,
            demo.name,
            "examples/" ++ demo.name ++ ".zig",
            target,
            mode,
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
    link_imgui: bool = false,
    link_chipmunk: bool = false,
    link_nfd: bool = false,
    link_zmesh: bool = false,
    link_znoise: bool = false,
    link_zbullet: bool = false,
    link_znetwork: bool = false,
    link_ztracy: bool = false,
    enable_tracy: bool = false,
};

/// Create game executable
pub fn createGame(
    b: *std.build.Builder,
    name: []const u8,
    root_file: []const u8,
    target: std.zig.CrossTarget,
    mode: std.builtin.Mode,
    opt: BuildOptions,
) *std.build.LibExeObjStep {
    const exe = b.addExecutable(name, comptime thisDir() ++ "/src/app.zig");
    const exe_options = b.addOptions();
    exe.addOptions("build_options", exe_options);
    exe.setTarget(target);
    exe.setBuildMode(mode);

    // Link must dependencies
    const sdl = sdlsdk.init(exe.builder);
    sdl.link(exe, .dynamic);
    miniaudio.link(exe);
    stb.link(exe);

    // Link optional dependencies
    const zmesh_opt = zmesh.BuildOptionsStep.init(b, .{});
    const ztracy_opt = ztracy.BuildOptionsStep.init(b, .{ .enable_ztracy = opt.enable_tracy });
    if (opt.link_imgui) imgui.link(exe);
    if (opt.link_chipmunk) chipmunk.link(exe);
    if (opt.link_nfd) nfd.link(exe);
    if (opt.link_zmesh) zmesh.link(exe, zmesh_opt);
    if (opt.link_znoise) znoise.link(exe);
    if (opt.link_zbullet) zbullet.link(exe);
    if (opt.link_znetwork) znetwork.link(exe);
    if (opt.link_ztracy) ztracy.link(exe, ztracy_opt);

    // Add packages
    const jok = std.build.Pkg{
        .name = "jok",
        .source = .{ .path = comptime thisDir() ++ "/src/jok.zig" },
        .dependencies = &[_]std.build.Pkg{
            sdl.getWrapperPackage("sdl"),
            zmesh_opt.getPkg(),
        },
    };
    const game = std.build.Pkg{
        .name = "game",
        .source = .{ .path = root_file },
        .dependencies = &[_]std.build.Pkg{
            jok,
            sdl.getWrapperPackage("sdl"),
        },
    };
    exe.addPackage(game);
    exe.addPackage(sdl.getWrapperPackage("sdl"));
    return exe;
}

fn thisDir() []const u8 {
    return std.fs.path.dirname(@src().file) orelse ".";
}
