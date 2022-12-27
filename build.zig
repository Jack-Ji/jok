const std = @import("std");
const builtin = @import("builtin");
const sdlsdk = @import("src/deps/sdl/Sdk.zig");
const stb = @import("src/deps/stb/build.zig");
const imgui = @import("src/deps/imgui/build.zig");
const chipmunk = @import("src/deps/chipmunk/build.zig");
const nfd = @import("src/deps/nfd/build.zig");
const zmesh = @import("src/deps/zmesh/build.zig");
const znoise = @import("src/deps/znoise/build.zig");
const zaudio = @import("src/deps/zaudio/build.zig");
const zphysics = @import("src/deps/zphysics/build.zig");
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
        .{ .name = "sprite_scene", .opt = .{} },
        .{ .name = "sprite_benchmark", .opt = .{} },
        .{ .name = "particle_2d", .opt = .{} },
        .{ .name = "animation_2d", .opt = .{} },
        .{ .name = "primitive_2d", .opt = .{ .link_imgui = true } },
        .{ .name = "primitive_3d", .opt = .{ .link_imgui = true } },
        .{ .name = "terran_generation", .opt = .{ .link_imgui = true } },
        .{ .name = "affline_texture", .opt = .{ .link_imgui = true } },
        .{ .name = "solar_system", .opt = .{} },
        .{ .name = "font_demo", .opt = .{} },
        .{ .name = "skybox", .opt = .{ .link_imgui = true } },
        .{ .name = "benchmark_3d", .opt = .{ .link_imgui = true } },
        .{ .name = "particle_life", .opt = .{ .link_imgui = true, .link_nfd = true } },
        .{ .name = "zaudio_demo", .opt = .{ .link_zaudio = true } },
        .{ .name = "audio_synthesize_demo", .opt = .{} },
        .{ .name = "software_rasterizer", .opt = .{ .link_imgui = true } },
        .{ .name = "hypocycloids", .opt = .{} },
    };
    const build_examples = b.step("examples", "compile and install all examples");
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
    link_zaudio: bool = false,
    link_zphysics: bool = false,
    link_ztracy: bool = false,
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
    const exe = b.addExecutable(name, thisDir() ++ "/src/app.zig");
    const exe_options = b.addOptions();
    exe.addOptions("build_options", exe_options);
    exe.setTarget(target);
    exe.setBuildMode(mode);

    // Link must-have dependencies
    const sdl = sdlsdk.init(exe.builder);
    sdl.link(exe, .dynamic);
    stb.link(exe);
    zmesh.link(exe, zmesh.BuildOptionsStep.init(b, .{}));
    znoise.link(exe);

    // Link optional dependencies and set comptime flags
    if (opt.link_imgui) {
        imgui.link(exe);
    }
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
    exe_options.addOption(bool, "use_imgui", opt.link_imgui);
    exe_options.addOption(bool, "use_chipmunk", opt.link_chipmunk);
    exe_options.addOption(bool, "use_nfd", opt.link_nfd);
    exe_options.addOption(bool, "use_zaudio", opt.link_zaudio);
    exe_options.addOption(bool, "use_zphysics", opt.link_zphysics);
    exe_options.addOption(bool, "use_ztracy", opt.link_ztracy);

    // Add packages
    const jok = std.build.Pkg{
        .name = "jok",
        .source = .{ .path = thisDir() ++ "/src/jok.zig" },
        .dependencies = &[_]std.build.Pkg{
            sdl.getWrapperPackage("sdl"),
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

inline fn thisDir() []const u8 {
    return comptime std.fs.path.dirname(@src().file) orelse ".";
}
