# jok
A minimal 2d/3d game framework for zig.

## What you need?
* [Latest nominated zig compiler](https://machengine.org/docs/zig-version/)
* SDL library
* Any code editor you like (consider using [zls](https://github.com/zigtools/zls) for your own favor)

## Features
* Friendly build system, very easy to setup new project
* Able to cross-compile between Windows and Linux (thanks to [ziglang](https://ziglang.org))
* Excellent rendering performance (thanks to SDL2's [geometry rendering](https://wiki.libsdl.org/SDL2/SDL_RenderGeometryRaw))
* Fully integrated Dear-ImGui
* Asset system (via [physfs](https://github.com/icculus/physfs), supports fs/zip/7zip/iso etc)
* 2D batch system
* 2D vector graphics (line/rectangle/quad/triangle/circle/bezier-curve/convex-polygon/polyline/custom-path)
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
* Friendly easing system
* TrueType support, atlas generation/save/load
* SVG loading/rendering
* Sound/Music playing/mixing
* Tiled editor support (tmx/tsx loading/rendering)

## Supported platforms
* Windows
* Linux
* MacOS (?)

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
    
        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(&install_cmd.step);
    
        const run_step = b.step("run", "Run game");
        run_step.dependOn(&run_cmd.step);
    }
    ```

3. Install SDL2 library:

    * Windows Platform
    
        Download SDL library from [here](https://libsdl.org/), extract into your hard drive, and create file `.build_config/sdl.json` in your project directory:
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

    NOTE: most settings're still customizable through SDL2's api in runtime. Remember, you can always
    resort to `SDL` directly if you're not totally happy with `jok`'s working style.
    
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
