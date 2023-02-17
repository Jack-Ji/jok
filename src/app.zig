const std = @import("std");
const builtin = @import("builtin");
const sdl = @import("sdl");
const jok = @import("jok");
const config = jok.config;
const game = @import("game");

// Validate exposed game api
comptime {
    if (!@hasDecl(game, "init") or
        !@hasDecl(game, "event") or
        !@hasDecl(game, "update") or
        !@hasDecl(game, "draw") or
        !@hasDecl(game, "quit"))
    {
        @compileError(
            \\You must provide following 5 public api in your game code:
            \\    pub fn init(ctx: *jok.Context) !void
            \\    pub fn event(ctx: *jok.Context, e: sdl.Event) !void
            \\    pub fn update(ctx: *jok.Context) !void
            \\    pub fn draw(ctx: *jok.Context) !void
            \\    pub fn quit(ctx: *jok.Context) void
        );
    }
    switch (@typeInfo(@typeInfo(@TypeOf(game.init)).Fn.return_type.?)) {
        .ErrorUnion => |info| if (info.payload != void) {
            @compileError("`init` must return !void");
        },
        else => @compileError("`init` must return !void"),
    }
    switch (@typeInfo(@typeInfo(@TypeOf(game.event)).Fn.return_type.?)) {
        .ErrorUnion => |info| if (info.payload != void) {
            @compileError("`event` must return !void");
        },
        else => @compileError("`init` must return !void"),
    }
    switch (@typeInfo(@typeInfo(@TypeOf(game.update)).Fn.return_type.?)) {
        .ErrorUnion => |info| if (info.payload != void) {
            @compileError("`update` must return !void");
        },
        else => @compileError("`update` must return !void"),
    }
    switch (@typeInfo(@typeInfo(@TypeOf(game.draw)).Fn.return_type.?)) {
        .ErrorUnion => |info| if (info.payload != void) {
            @compileError("`draw` must return !void");
        },
        else => @compileError("`draw` must return !void"),
    }
    switch (@typeInfo(@typeInfo(@TypeOf(game.quit)).Fn.return_type.?)) {
        .Void => {},
        else => @compileError("`quit` must return void"),
    }
}

/// Options for zig executable
pub const std_options = struct {
    pub const log_level = if (@hasDecl(game, "jok_log_level"))
        game.jok_log_level
    else
        std.log.default_level;
};

pub fn main() !void {
    // Init setup configurations and memory allocator
    config.init(game);
    const AllocatorType = std.heap.GeneralPurposeAllocator(.{
        .safety = if (@hasDecl(game, "jok_mem_leak_checks") and
            game.jok_mem_leak_checks) true else false,
        .verbose_log = if (@hasDecl(game, "jok_mem_detail_logs") and
            game.jok_mem_detail_logs) true else false,
        .enable_memory_limit = true,
    });
    var gpa: ?AllocatorType = null;
    var allocator = if (config.jok_allocator) |a| a else BLK: {
        gpa = AllocatorType{};
        break :BLK gpa.?.allocator();
    };
    defer if (gpa) |*a| {
        if (a.deinit()) {
            @panic("jok: memory leaks happened!");
        }
    };

    // Init application context
    var ctx = try jok.Context.init(allocator);
    defer ctx.deinit();

    // Init game object
    try game.init(&ctx);
    defer game.quit(&ctx);

    // Start Game loop
    var last_time = ctx.seconds;
    while (!ctx.quit) {
        ctx.tick(game.event, game.update, game.draw);

        if (ctx.seconds - last_time > 1 and config.jok_framestat_display) {
            last_time = ctx.seconds;
            var buf: [128]u8 = undefined;
            const txt = std.fmt.bufPrintZ(
                &buf,
                "{s} | {d}x{d} | FPS: {d:.1}, {s} | CPU: {d:.1}ms | MEM: {:.3} | RD: {s} | OPT: {s}",
                .{
                    config.jok_window_title,
                    ctx.getWindowSize().w,
                    ctx.getWindowSize().h,
                    ctx.fps,
                    config.jok_fps_limit.str(),
                    ctx.average_cpu_time,
                    std.fmt.fmtIntSizeBin(if (gpa) |a| a.total_requested_bytes else 0),
                    ctx.getRendererName(),
                    @tagName(builtin.mode),
                },
            ) catch unreachable;
            sdl.c.SDL_SetWindowTitle(ctx.window.ptr, txt.ptr);
        }
    }
}
