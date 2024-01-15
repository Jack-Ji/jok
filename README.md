# jok
A minimal 2d/3d game framework for zig.

## What you need?
* **Latest** [zig compiler](https://ziglang.org/download/)
* SDL library
* Any code editor you like (consider using [zls](https://github.com/zigtools/zls) for your own favor)

## Features
* Friendly build system, very easy to setup new project
* Able to cross-compile between Windows and Linux (thanks to [ziglang](https://ziglang.org))
* Excellent rendering performance (thanks to SDL2's [geometry rendering](https://wiki.libsdl.org/SDL2/SDL_RenderGeometryRaw))
* Fully integrated Dear-ImGui
* 2D vector graphics (line/rectangle/quad/triangle/circle/bezier-curve/convex-polygon/polyline/custom-path)
* 2D sprite rendering (scale/rotate/blending/flipping/depth)
* 2D sprite sheet generation/save/load
* 2D animation system
* 2D particle system
* 2D scene management
* 2D physics system (via [chipmunk](https://chipmunk-physics.net/))
* 3D skybox rendering
* 3D mesh rendering (gouraud/flat shading)
* 3D glTF 2.0 support
* 3D rigid/skeleton animation rendering/blending
* 3D lighting effect (Blinn-Phong model by default, customizable)
* 3D sprite/billboard rendering
* 3D particle system
* 3D scene management
* Friendly easing system
* Font loading/rendering (TrueType)
* SVG loading/rendering
* Sound/Music playing/mixing

## How to start?
Copy or clone repo (recursively) to `lib` subdirectory of the root of your project.  Install SDL2 library:

1. Windows Platform
Download SDL library from [here](https://libsdl.org/), extract into your hard drive, and create file `.build_config\sdl.json` in project directory:
```json
{
  "x86_64-windows-gnu": {
    "include": "D:/SDL2-2.28.5/x86_64-w64-mingw32/include",
    "libs": "D:/SDL2-2.28.5/x86_64-w64-mingw32/lib",
    "bin": "D:/SDL2-2.28.5/x86_64-w64-mingw32/bin"
  }
}
```

2. Linux Platform
Debian/Ubuntu:
```bash
sudo apt install libsdl2-dev
```

Fedora:
```bash
sudo yum install SDL2-devel
```

3. MacOS
```bash
brew install sdl2
```

Then in your `build.zig` add:

```zig
const std = @import("std");
const jok = @import("lib/jok/build.zig");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const exe = jok.createGame(
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

Now in your code you may import and use jok:

```zig
const std = @import("std");
const jok = @import("jok");
const sdl = jok.sdl;
const j2d = jok.j2d;
const j3d = jok.j3d;

pub fn init(ctx: jok.Context) !void {
    // your init code
}

pub fn event(ctx: jok.Context, e: sdl.Event) !void {
    // your event processing code
}

pub fn update(ctx: jok.Context) !void {
    // your game state updating code
}

pub fn draw(ctx: jok.Context) !void {
  // your 2d drawing
  {
      try j2d.begin(.{});
      // ......
      try j2d.end();
  }

  // your 3d drawing
  {
      try j3d.begin(.{});
      // ......
      try j3d.end();
  }
}

pub fn quit(ctx: jok.Context) void {
    // your deinit code
}
```

Now you can compile and run your game using command `zig build run`, have fun! Please let me know if you have any issue or developed something
interesting with this little framework.

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

## Supported platforms
* Windows
* Linux
* MacOS (?)

TIPS: To eliminate console terminal on Windows platform, override `exe.subsystem` with `.Windows` in your build script.

## NOTE
**Jok** is actually short for **joke**, which is about how overly-complicated modern graphics programming has become.
People are gradually forgetting lots of computing techniques used to deliver amazing games on simple machines.
With so many tools, engines and computing resources at hand, however, gamedev is not as fun as it used to be. 
In a word, the project is an offort trying to bring the joy of gamedev back, it's being developed in the spirit of 
retro-machines of 1990s (especially SNES/PS1), which implies following limitations:

* Custom vertex/fragment shader is not possible
* Only support [affine texture mapping](https://en.wikipedia.org/wiki/Texture_mapping#Affine_texture_mapping)
* No [depth buffer](https://en.wikipedia.org/wiki/Z-buffering)

The limitations demand developers to be both creative and careful about game's design, which can lead to
very awesome product in my opinion. Like old saying: "Constraints breed creativity".

## Third-Party Libraries
* [SDL2](https://www.libsdl.org) (zlib license)
* [zig-gamedev](https://github.com/michal-z/zig-gamedev) (MIT license)
* [chipmunk](https://chipmunk-physics.net/) (MIT license)
* [stb headers](https://github.com/nothings/stb) (MIT license)
* [nanosvg](https://github.com/memononen/nanosvg) (zlib license)
* [nativefiledialog](https://github.com/mlabbe/nativefiledialog) (zlib license)

## Built-in Fonts
* [Classic Console Neue](http://webdraft.hu/fonts/classic-console/) (MIT license)

## Games made in jok
* [A Bobby Carrot Game Clone](https://github.com/TheWaWaR/bobby-carrot)
