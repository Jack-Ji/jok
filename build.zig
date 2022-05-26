const std = @import("std");
const builtin = @import("builtin");

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
        .{ .name = "sprite_benchmark", .opt = .{} },
        .{ .name = "font_demo", .opt = .{} },
        .{ .name = "basic_3d", .opt = .{ .link_zmesh = true } },
    };
    const build_examples = b.step("build_examples", "compile and install all examples");
    inline for (examples) |demo| {
        const exe = b.addExecutable(
            demo.name,
            "examples/" ++ demo.name ++ ".zig",
        );
        exe.setBuildMode(mode);
        exe.setTarget(target);
        link(exe, demo.opt);
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
    link_zmesh: bool = false,
    link_znoise: bool = false,
    link_zbullet: bool = false,
    link_znetwork: bool = false,
    link_ztracy: bool = false,
    link_imgui: bool = false,
    link_chipmunk: bool = false,
    link_nfd: bool = false,
    enable_tracy: bool = false,
};

/// Add jok framework to executable
pub fn link(exe: *std.build.LibExeObjStep, opt: BuildOptions) void {
    const sdl = @import("src/deps/sdl/Sdk.zig").init(exe.builder);

    // Build and link dependencies
    sdl.link(exe, .dynamic);
    @import("src/deps/miniaudio/build.zig").link(exe);
    @import("src/deps/stb/build.zig").link(exe);
    if (opt.link_zmesh) {
        @import("src/deps/zmesh/build.zig").link(exe);
    }
    if (opt.link_znoise) {
        @import("src/deps/znoise/build.zig").link(exe);
    }
    if (opt.link_zbullet) {
        @import("src/deps/zbullet/build.zig").link(exe);
    }
    if (opt.link_znetwork) {
        @import("src/deps/znetwork/build.zig").link(exe);
    }
    if (opt.link_ztracy) {
        @import("src/deps/ztracy/build.zig").link(exe, opt.enable_tracy, .{});
    }
    if (opt.link_imgui) {
        @import("src/deps/imgui/build.zig").link(exe);
    }
    if (opt.link_chipmunk) {
        @import("src/deps/chipmunk/build.zig").link(exe);
    }
    if (opt.link_nfd) {
        @import("src/deps/nfd/build.zig").link(exe);
    }

    // Add package
    exe.addPackage(.{
        .name = "jok",
        .path = .{ .path = comptime thisDir() ++ "/src/jok.zig" },
        .dependencies = &[_]std.build.Pkg{
            sdl.getWrapperPackage("sdl"),
        },
    });
    exe.addPackage(sdl.getWrapperPackage("sdl"));
}

fn thisDir() []const u8 {
    return std.fs.path.dirname(@src().file) orelse ".";
}
