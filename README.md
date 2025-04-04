[![build](/../../actions/workflows/windows_native.yml/badge.svg)](/../../actions/workflows/windows_native.yml) [![build](/../../actions/workflows/linux_native.yml/badge.svg)](/../../actions/workflows/linux_native.yml) [![build](/../../actions/workflows/macos_native.yml/badge.svg)](/../../actions/workflows/macos_native.yml) [![build](/../../actions/workflows/webassembly.yml/badge.svg)](/../../actions/workflows/webassembly.yml) [![build](/../../actions/workflows/windows_cross.yml/badge.svg)](/../../actions/workflows/windows_cross.yml) [![build](/../../actions/workflows/linux_cross.yml/badge.svg)](/../../actions/workflows/linux_cross.yml)


# jok
A minimal 2d/3d game framework for zig.

## What you need?
* [Zig Compiler](https://ziglang.org/download/) (Master branch always targets latest zig, use tagged release if you wanna stick to stable version)
* SDL2 Library
* Any code editor you like (consider using [zls](https://github.com/zigtools/zls) for your own favor)

## Features
* Friendly build system, very easy to setup new project
* Able to cross-compile between Windows and Linux (thanks to [ziglang](https://ziglang.org))
* Excellent rendering performance (thanks to SDL2's [geometry rendering](https://wiki.libsdl.org/SDL2/SDL_RenderGeometryRaw))
* Fully integrated Dear-ImGui
* Asset system (via [physfs](https://github.com/icculus/physfs), supports fs/zip/7zip/iso etc)
* Plugin System (register/unregister/hot-reloading)
* 2D batch system
* 2D primitives (line/rectangle/quad/triangle/circle/ellipse/bezier-curve/convex-polygon/concave-polygon/polyline/custom-path)
* 2D sprite rendering (scale/rotate/blending/flipping/depth)
* 2D sprite sheet generation/save/load
* 2D animation system
* 2D particle system
* 2D scene management
* 2D physics system (via [chipmunk](https://chipmunk-physics.net/), optional)
* 3D batch system
* 3D skybox rendering
* 3D mesh rendering (gouraud/flat shading)
* 3D glTF 2.0 support
* 3D rigid/skeleton animation rendering/blending
* 3D lighting effect (Blinn-Phong model by default, customizable)
* 3D sprite/billboard rendering
* 3D particle system
* 3D scene management
* TrueType support, atlas generation/save/load
* SVG loading/rendering
* Sound/Music playing/mixing
* Tiled editor support (tmx/tsx loading/rendering)
* Misc little utils, such as easing/timer/signal system

## Supported platforms
* Windows
* Linux
* MacOS
* WebAssembly

TIPS: To eliminate console terminal on Windows platform, override `exe.subsystem` with `.Windows` in your build script.

## How to start?

1. Add *jok* as your project's dependency

   Add jok dependency to your build.zig.zon, with following command:
    ```bash
    zig fetch --save git+https://github.com/jack-ji/jok.git
    ```

2. Use *jok*'s build script to add build step

    In your `build.zig`, add:
    ```zig
    const std = @import("std");
    const jok = @import("jok");
    
    pub fn build(b: *std.Build) void {
        const target = b.standardTargetOptions(.{});
        const optimize = b.standardOptimizeOption(.{});
        const exe = jok.createDesktopApp(
            b,
            "mygame",
            "src/main.zig",
            target,
            optimize,
            .{},
        );
        const install_cmd = b.addInstallArtifact(exe, .{});
        b.getInstallStep().dependOn(&install_cmd.step);
    
        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(&install_cmd.step);
    
        const run_step = b.step("run", "Run game");
        run_step.dependOn(&run_cmd.step);
    }
    ```

    If you want to add emscripten support for your project, the build script needs more care:
    ```zig
    const std = @import("std");
    const jok = @import("jok");
    
    pub fn build(b: *std.Build) void {
        const target = b.standardTargetOptions(.{});
        const optimize = b.standardOptimizeOption(.{});

        if (!target.result.cpu.arch.isWasm()) {
            const exe = jok.createDesktopApp(
                    b,
                    "mygame",
                    "src/main.zig",
                    target,
                    optimize,
                    .{},
            );
            const install_cmd = b.addInstallArtifact(exe, .{});
            b.getInstallStep().dependOn(&install_cmd.step);

            const run_cmd = b.addRunArtifact(exe);
            run_cmd.step.dependOn(&install_cmd.step);

            const run_step = b.step("run", "Run game");
            run_step.dependOn(&run_cmd.step);
        } else {
            const webapp = createWeb(
                    b,
                    "mygame",
                    "src/main.zig",
                    target,
                    optimize,
                    .{
                        .preload_path = "optional/relative/path/to/your/assets",
                        .shell_file_path = "optional/relative/path/to/your/shell",
                    },
            );
            b.getInstallStep().dependOn(&webapp.emlink.step);

            const run_step = b.step("run", "Run game");
            run_step.dependOn(&webapp.emrun.step);
        }
    }
    ```

3. Install SDL2 library:

    * Windows Platform
    
        Download SDL2 library from [here](https://libsdl.org/), extract into your hard drive, and create file `.build_config/sdl.json` in your project directory:
        ```json
        {
          "x86_64-windows-gnu": {
            "include": "D:/SDL2-2.28.5/x86_64-w64-mingw32/include",
            "libs": "D:/SDL2-2.28.5/x86_64-w64-mingw32/lib",
            "bin": "D:/SDL2-2.28.5/x86_64-w64-mingw32/bin"
          }
        }
        ```
        If you have multiple projects, you can config path to a global `sdl.json` using environment variable, defaults to `SDL_CONFIG_PATH`.
    
    * Linux Platform
    
        Debian/Ubuntu:
        ```bash
        sudo apt install libsdl2-dev
        ```
    
        Fedora/CentOS:
        ```bash
        sudo yum install SDL2-devel
        ```
    
    * MacOS
    
        ```bash
        brew install sdl2
        ```

4. Write some code!

    You may import and use jok now, here's skeleton of your `src/main.zig`:
    ```zig
    const std = @import("std");
    const jok = @import("jok");
    
    pub fn init(ctx: jok.Context) !void {
        // your init code
    }
    
    pub fn event(ctx: jok.Context, e: jok.Event) !void {
        // your event processing code
    }
    
    pub fn update(ctx: jok.Context) !void {
        // your game state updating code
    }
    
    pub fn draw(ctx: jok.Context) !void {
        // your drawing code
    }
    
    pub fn quit(ctx: jok.Context) void {
        // your deinit code
    }

    pub fn getMemory() ?*const anyopaque {
        // OPTIONAL: return memory of your game
    }
    
    pub fn reloadMemory(mem: ?*const anyopaque) void {
        // OPTIONAL: restore memory of your game
    }
    ```
    
    Noticed yet? That's right, you don't need to write main function, `jok` got your back.
    The game is deemed as a separate package to `jok`'s runtime as a matter of fact.  Your
    only responsibility is to provide 5 public functions: 
    * init - initialize your game, run only once
    * event - process events happened between frames (keyboard/mouse/controller etc)
    * update - logic update between frames
    * draw - render your screen here (60 fps by default)
    * quit - do something before game is closed

    You can customize some setup settings (window width/height, fps, debug level etc), by 
    defining some public constants using predefined names (they're all prefixed with`jok_`).
    Checkout [`src/config.zig`](https://github.com/Jack-Ji/jok/blob/main/src/config.zig).
    Most of which are still modifiable at runtime.
    
    The other 2 optional public functions are only needed when you'are writing a plugin:
    * getMemory - get memory of you plugin, called when plugin is updated
    * reloadMemory - reload memory of your plugin, called when plugin is updated

    For more detail of plugin's usage, check example `hotreload`.
    
    Now, compile and run your game using command `zig build run`, have fun!
    Please let me know if you have any issue or developed something interesting with this little framework.

## NOTE
**Jok** is short for **joke**, which is about how overly-complicated modern graphics programming has become.
People are gradually forgetting lots of computing techniques used to deliver amazing games on simple machines.
With so many tools, engines and computing resources at hand, however, gamedev is not as fun as it used to be. 
**Jok** is an offort trying to bring the joy back, it's being developed in the spirit of retro-machines of
1990s (especially PS1), which implies following limitations:

* Custom vertex/fragment shader is not possible
* Only support [affine texture mapping](https://en.wikipedia.org/wiki/Texture_mapping#Affine_texture_mapping)
* No [depth buffer](https://en.wikipedia.org/wiki/Z-buffering)

The limitations demand developers to be both creative and careful about game's design.

## Third-Party Libraries
* [SDL2](https://www.libsdl.org) (zlib license)
* [physfs](https://github.com/icculus/physfs) (zlib license)
* [zig-gamedev](https://github.com/zig-gamedev/zig-gamedev) (MIT license)
* [chipmunk](https://chipmunk-physics.net/) (MIT license)
* [stb headers](https://github.com/nothings/stb) (MIT license)
* [nanosvg](https://github.com/memononen/nanosvg) (zlib license)
* [nativefiledialog](https://github.com/mlabbe/nativefiledialog) (zlib license)

## Built-in Fonts
* [Classic Console Neue](http://webdraft.hu/fonts/classic-console/) (MIT license)

## Games made in jok
* [A Bobby Carrot Game Clone](https://github.com/TheWaWaR/bobby-carrot)
