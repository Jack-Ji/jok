# zpool v0.9.0 - Generic pool & handle implementation

Based on [Andre Weissflog's "Handles Are The Better Pointers"](https://floooh.github.io/2018/06/17/handles-vs-pointers.html)

Exposing API resources using pools and handles is a common way to avoid exposing
implementation details to calling code and providing some insulation against
stale references in data structures maintained by the caller.

When the caller is provided a handle instead of an opaque pointer, the API
implementation is free to move resources around, replace them, and even discard
them.

```zig
Pool(index_bits: u8, cycle_bits: u8, TResource: type, TColumns: type)
Handle(index_bits: u8, cycle_bits: u8, TResource: type)
```

The generic `Pool` type has configurable bit distribution for the
`Handle`'s `index`/`cycle` fields, and supports multiple columns of data to 
be indexed by a handle, using `std.MultiArrayList` to store all of the pool
data in a single memory allocation.  The `TResource` parameter ensures the pool
and handle types can be distinct types even when other parameters are the same.

## Getting started

Copy `zpool` folder to a `libs` subdirectory of the root of your project.

Then in your `build.zig` add:

```zig
const std = @import("std");
const zpool = @import("libs/zpool/build.zig");

pub fn build(b: *std.Build) void {
    ...
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});

    const zpool_pkg = zpool.package(b, target, optimize, .{});

    zpool_pkg.link(exe);
}
```

Now in your code you may import and use `zpool`:

```zig
const Pool = @import("zpool").Pool;

const ImagePtr  = graphics.Image;
const ImageInfo = graphics.ImageInfo;

pub const ImagePool = Pool(16, 16, ImagePtr, struct {
    ptr: ImagePtr,
    info: ImageInfo,
});
pub const ImageHandle = ImagePool.Handle;
```

```zig
var imagePool = ImagePool.initMaxCapacity(allocator);
defer pool.deinit();
```

```zig
pub fn acquireImage(info: ImageInfo) !ImageHandle {
    const handle : ImageHandle = try imagePool.add(.{
        .ptr = graphics.createImage(info),
        .info = info,
    });
    return handle;
}

pub fn drawImage(handle: ImageHandle) !void {
    // get the stored ImagePtr
    const ptr : ImagePtr = try imagePool.getColumn(handle, .ptr);
    graphics.drawImage(ptr);
}

pub fn resizeImage(handle: ImageHandle, width: u16, height: u16) !void {
    // get a pointer to the stored ImageInfo
    const info : *ImageInfo = try imagePool.getColumnPtr(handle, .info);
    const old_width = info.width;
    const old_height = info.height;
    const old_pixels = // allocate memory to store old pixels

    // get the stored ImagePtr
    const ptr = try imagePool.getColumn(handle, .ptr);
    graphics.readPixels(ptr, old_pixels);

    const new_pixels = // allocate memory to store new pixels

    super_eagle.resizeImage(
        old_width, old_height, old_pixels,
        new_width, new_height, new_pixels);

    graphics.writePixels(ptr, new_width, new_height, new_pixels);

    // update the stored ImageInfo
    info.width = new_width;
    info.height = new_height;
}

```
