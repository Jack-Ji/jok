# jok
A minimal game framework you can joke about.

## What you need?
* zig compiler (latest version)
* SDL library
* Any code editor you like

## How to start?
Copy `jok` folder or clone repo (recursively) into `libs` subdirectory of the root of your project.
Install SDL2 library, please refer to [docs of SDL2.zig](https://github.com/MasterQ32/SDL.zig).
Then in your `build.zig` add:

```zig
const std = @import("std");
const jok = @import("libs/jok/build.zig");

pub fn build(b: *std.build.Builder) void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();
    const exe = jok.createGame(
        b, 
        "mygame",
        "src/main.zig",
        target,
        mode,
        .{},
    );
    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run game");
    run_step.dependOn(&run_cmd.step);
}
```

Now in your code you may import and use jok:

```zig
const std = @import("std");
const jok = @import("jok");

pub const jok_window_width = 100;
pub const jok_window_height = 50;

pub fn init(ctx: *jok.Context) anyerror!void {
    // your init code
}

pub fn loop(ctx: *jok.Context) anyerror!void {
    // your game loop
}

pub fn quit(ctx: *jok.Context) void {
    // your deinit code
}
```

Noticed yet? That's right, you don't need to write main function, `jok` got your back.
The game is deemed as a separate package to `jok`'s runtime as a matter of fact. 
Your responsibility is to provide 3 pub functions: `init/loop/quit`, that's all (pretty much).

Of course, you can customize some setup settings, such as width/height/title/position of window,
which is given by defining some constants using predefined names (they're all prefixed with `jok_`).
Checkout `src\config.zig` to see available options.

## What's supported platforms?
Theoretically anywhere SDL2 can run. But I'm focusing on PC platforms for now.
Some optional vendor libraries are confined to certain platforms, use at your own needs.

## Why would we joke about it?
It's way too minimal (perhaps), you can't write shaders ([might change in the future](https://gist.github.com/icculus/f731224bef3906e4c5e8cbed6f98bb08)). 
If you want to achieve something fancy, you ought to resort to some clever art tricks or algorithms.
Welcome to old golden time of 90s. Or, you can choose other more powerful/modern libraries/engines.

## Third-Party Libraries
* [SDL2](https://www.libsdl.org) (zlib license)
* [stb headers](https://github.com/nothings/stb) (MIT license)
* [zig-gamedev](https://github.com/michal-z/zig-gamedev) (MIT license)
* [dear-imgui](https://github.com/ocornut/imgui) (MIT license)
* [chipmunk](https://chipmunk-physics.net/) (MIT license)
* [nativefiledialog](https://github.com/mlabbe/nativefiledialog) (zlib license)
