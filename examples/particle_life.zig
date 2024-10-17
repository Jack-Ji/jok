/// Ported from https://github.com/hunar4321/particle-life
const std = @import("std");
const math = std.math;
const jok = @import("jok");
const imgui = jok.imgui;
const nfd = jok.nfd;
const j2d = jok.j2d;

pub const jok_window_size = jok.config.WindowSize{
    .custom = .{ .width = 1200, .height = 800 },
};

// Image positions
const xshift = 50;
const yshift = 50;
const length = 70;
const anchor = 0;
const p1x = anchor + xshift;
const p1y = anchor + yshift;
const p2x = anchor + length + xshift;
const p2y = anchor + yshift;
const p3x = anchor + length + xshift;
const p3y = anchor + length + yshift;
const p4x = anchor + xshift;
const p4y = anchor + length + yshift;
const rr = 8;

// Simulation parameters
var number_r: i32 = 500;
var number_g: i32 = 500;
var number_w: i32 = 500;
var number_b: i32 = 500;
var power_rr: f32 = 0;
var power_rg: f32 = 0;
var power_rw: f32 = 0;
var power_rb: f32 = 0;
var power_gr: f32 = 0;
var power_gg: f32 = 0;
var power_gw: f32 = 0;
var power_gb: f32 = 0;
var power_wr: f32 = 0;
var power_wg: f32 = 0;
var power_ww: f32 = 0;
var power_wb: f32 = 0;
var power_br: f32 = 0;
var power_bg: f32 = 0;
var power_bw: f32 = 0;
var power_bb: f32 = 0;
var v_rr: f32 = 180;
var v_rg: f32 = 180;
var v_rw: f32 = 180;
var v_rb: f32 = 180;
var v_gr: f32 = 180;
var v_gg: f32 = 180;
var v_gw: f32 = 180;
var v_gb: f32 = 180;
var v_wr: f32 = 180;
var v_wg: f32 = 180;
var v_ww: f32 = 180;
var v_wb: f32 = 180;
var v_br: f32 = 180;
var v_bg: f32 = 180;
var v_bw: f32 = 180;
var v_bb: f32 = 180;
var viscosity: f32 = 0.5;
var force_variance: f32 = 0.8;
var radius_variance: f32 = 0.6;
var bounded = true;
var show_model = false;

// Particle groups by color
var green: ?std.ArrayList(Point) = null;
var red: ?std.ArrayList(Point) = null;
var white: ?std.ArrayList(Point) = null;
var blue: ?std.ArrayList(Point) = null;

// Random generator
var rand_gen: std.Random.DefaultPrng = undefined;
var rand: std.Random = undefined;

const Point = struct {
    // position
    x: f32 = 0,
    y: f32 = 0,

    // velocity
    vx: f32 = 0,
    vy: f32 = 0,

    // color,
    color: jok.Color = jok.Color.black,

    fn draw(p: Point) !void {
        try j2d.circleFilled(
            .{ .x = p.x, .y = p.y },
            3,
            p.color,
            .{},
        );
    }
};

// Get random number in range [a, b]
inline fn randomRange(comptime T: type, a: T, b: T) T {
    switch (T) {
        f32 => return rand.float(f32) * (b - a) + a,
        i32 => return rand.intRangeAtMost(i32, a, b),
        else => unreachable,
    }
}

// Draw all points from given group
inline fn drawPoints(points: std.ArrayList(Point)) !void {
    for (points.items) |p| {
        try p.draw();
    }
}

// Generate a number of single colored points
fn createPoints(allocator: std.mem.Allocator, n: i32, r: u8, g: u8, b: u8) !std.ArrayList(Point) {
    var ps = try std.ArrayList(Point).initCapacity(
        allocator,
        @intCast(n),
    );
    var i: i32 = 0;
    while (i < n) : (i += 1) {
        ps.appendAssumeCapacity(.{
            .x = randomRange(f32, 200, 1000),
            .y = randomRange(f32, 50, 750),
            .color = jok.Color.rgb(r, g, b),
        });
    }
    return ps;
}

// Interaction between 2 particle groups
fn interaction(
    g1: std.ArrayList(Point),
    g2: std.ArrayList(Point),
    _g: f32,
    radius: f32,
) void {
    // Gravity coefficient
    const g = _g / -100;

    // Loop through first group of points
    for (g1.items) |*p1| {
        // Force acting on particle
        var fx: f32 = 0;
        var fy: f32 = 0;

        // Loop through second group of points
        for (g2.items) |*p2| {
            // Calculate distance between points
            const dx = p1.x - p2.x;
            const dy = p1.y - p2.y;
            const r = math.sqrt(dx * dx + dy * dy);

            // Calculate force in given bounds
            if (r < radius and r > 0) {
                fx += dx / r;
                fy += dy / r;
            }
        }

        // Calculate new velocity
        p1.vx = (p1.vx + (fx * g)) * (1.0 - viscosity);
        p1.vy = (p1.vy + (fy * g)) * (1.0 - viscosity);

        // Update position based on velocity
        p1.x += p1.vx;
        p1.y += p1.vy;

        // Checking for canvas bounds
        if (bounded) {
            if (p1.x < 0) {
                p1.vx *= -1;
                p1.x = 0;
            }
            if (p1.x > jok_window_size.custom.width) {
                p1.vx *= -1;
                p1.x = jok_window_size.custom.width;
            }
            if (p1.y < 0) {
                p1.vy *= -1;
                p1.y = 0;
            }
            if (p1.y > jok_window_size.custom.height) {
                p1.vy *= -1;
                p1.y = jok_window_size.custom.height;
            }
        }
    }
}

// Generate new sets of points
fn restart(allocator: std.mem.Allocator) !void {
    if (green) |g| {
        g.deinit();
        green = null;
    }
    if (red) |g| {
        g.deinit();
        red = null;
    }
    if (white) |g| {
        g.deinit();
        white = null;
    }
    if (blue) |g| {
        g.deinit();
        blue = null;
    }

    if (number_g > 0) {
        green = try createPoints(allocator, number_g, 100, 250, 10);
    }
    if (number_r > 0) {
        red = try createPoints(allocator, number_r, 250, 10, 100);
    }
    if (number_w > 0) {
        white = try createPoints(allocator, number_w, 250, 250, 250);
    }
    if (number_b > 0) {
        blue = try createPoints(allocator, number_b, 100, 100, 250);
    }
}

// Generate initial simulation paramters
fn randomnizeSimulation() void {
    // GREEN
    power_gg = randomRange(f32, -100, 100) * force_variance;
    power_gr = randomRange(f32, -100, 100) * force_variance;
    power_gw = randomRange(f32, -100, 100) * force_variance;
    power_gb = randomRange(f32, -100, 100) * force_variance;
    v_gg = randomRange(f32, 10, 500) * radius_variance;
    v_gr = randomRange(f32, 10, 500) * radius_variance;
    v_gw = randomRange(f32, 10, 500) * radius_variance;
    v_gb = randomRange(f32, 10, 500) * radius_variance;

    // RED
    power_rg = randomRange(f32, -100, 100) * force_variance;
    power_rr = randomRange(f32, -100, 100) * force_variance;
    power_rw = randomRange(f32, -100, 100) * force_variance;
    power_rb = randomRange(f32, -100, 100) * force_variance;
    v_rg = randomRange(f32, 10, 500) * radius_variance;
    v_rr = randomRange(f32, 10, 500) * radius_variance;
    v_rw = randomRange(f32, 10, 500) * radius_variance;
    v_rb = randomRange(f32, 10, 500) * radius_variance;

    // WHITE
    power_wg = randomRange(f32, -100, 100) * force_variance;
    power_wr = randomRange(f32, -100, 100) * force_variance;
    power_ww = randomRange(f32, -100, 100) * force_variance;
    power_wb = randomRange(f32, -100, 100) * force_variance;
    v_wg = randomRange(f32, 10, 500) * radius_variance;
    v_wr = randomRange(f32, 10, 500) * radius_variance;
    v_ww = randomRange(f32, 10, 500) * radius_variance;
    v_wb = randomRange(f32, 10, 500) * radius_variance;

    // BLUE
    power_bg = randomRange(f32, -100, 100) * force_variance;
    power_br = randomRange(f32, -100, 100) * force_variance;
    power_bw = randomRange(f32, -100, 100) * force_variance;
    power_bb = randomRange(f32, -100, 100) * force_variance;
    v_bg = randomRange(f32, 10, 500) * radius_variance;
    v_br = randomRange(f32, 10, 500) * radius_variance;
    v_bw = randomRange(f32, 10, 500) * radius_variance;
    v_bb = randomRange(f32, 10, 500) * radius_variance;
}

fn saveSettings() !void {
    const path = try nfd.saveFileDialog("txt", "model.txt");
    if (path) |p| {
        defer p.deinit();

        var realpath = p.path;
        if (!std.mem.endsWith(u8, p.path, ".txt")) {
            realpath = imgui.formatZ("{s}.txt", .{p.path});
        }

        var f = try std.fs.cwd().createFile(realpath, .{});
        defer f.close();

        try std.fmt.format(
            f.writer(),
            "{d:.5} {d:.5} {d:.5} {d:.5} {d:.5} {d:.5} {d:.5} {d:.5} {d:.5} {d:.5} {d:.5} {d:.5} {d:.5} {d:.5} {d:.5} {d:.5} {d:.5} {d:.5} {d:.5} {d:.5}",
            .{
                number_r, number_g, number_w, number_b,
                power_rr, power_rg, power_rw, power_rb,
                power_gr, power_gg, power_gw, power_gb,
                power_wr, power_wg, power_ww, power_wb,
                power_br, power_bg, power_bw, power_bb,
            },
        );
        try std.fmt.format(
            f.writer(),
            " {d:.5} {d:.5} {d:.5} {d:.5} {d:.5} {d:.5} {d:.5} {d:.5} {d:.5} {d:.5} {d:.5} {d:.5} {d:.5} {d:.5} {d:.5} {d:.5} {d:.5}",
            .{
                v_rr,      v_rg, v_rw, v_rb,
                v_gr,      v_gg, v_gw, v_gb,
                v_wr,      v_wg, v_ww, v_wb,
                v_br,      v_bg, v_bw, v_bb,
                viscosity,
            },
        );
    }
}

fn loadSettings(allocator: std.mem.Allocator) !void {
    const path = try nfd.openFileDialog("txt", null);
    if (path) |p| {
        defer p.deinit();

        const content = try std.fs.cwd().readFileAlloc(allocator, p.path, 1024);
        defer allocator.free(content);

        var floats = try std.ArrayList(f32).initCapacity(allocator, 37);
        defer floats.deinit();
        var it = std.mem.splitScalar(u8, content, ' ');
        while (it.next()) |t| {
            try floats.append(try std.fmt.parseFloat(f32, t));
        }

        if (floats.items.len != 37) {
            std.log.err("Invalid format", .{});
            return;
        }

        number_r = @intFromFloat(floats.items[0]);
        number_g = @intFromFloat(floats.items[1]);
        number_w = @intFromFloat(floats.items[2]);
        number_b = @intFromFloat(floats.items[3]);
        power_rr = floats.items[4];
        power_rg = floats.items[5];
        power_rw = floats.items[6];
        power_rb = floats.items[7];
        power_gr = floats.items[8];
        power_gg = floats.items[9];
        power_gw = floats.items[10];
        power_gb = floats.items[11];
        power_wr = floats.items[12];
        power_wg = floats.items[13];
        power_ww = floats.items[14];
        power_wb = floats.items[15];
        power_br = floats.items[16];
        power_bg = floats.items[17];
        power_bw = floats.items[18];
        power_bb = floats.items[19];
        v_rr = floats.items[20];
        v_rg = floats.items[21];
        v_rw = floats.items[22];
        v_rb = floats.items[23];
        v_gr = floats.items[24];
        v_gg = floats.items[25];
        v_gw = floats.items[26];
        v_gb = floats.items[27];
        v_wr = floats.items[28];
        v_wg = floats.items[29];
        v_ww = floats.items[30];
        v_wb = floats.items[31];
        v_br = floats.items[32];
        v_bg = floats.items[33];
        v_bw = floats.items[34];
        v_bb = floats.items[35];
        viscosity = floats.items[36];

        try restart(allocator);
    }
}

fn updateGui(ctx: jok.Context) !void {
    if (imgui.begin("Settings", .{})) {
        if (imgui.button("START/RESTART", .{})) {
            try restart(ctx.allocator());
        }
        if (imgui.button("Randomize", .{})) {
            randomnizeSimulation();
            try restart(ctx.allocator());
        }
        if (imgui.button("Save Model", .{})) {
            try saveSettings();
        }
        if (imgui.button("Load Model", .{})) {
            try loadSettings(ctx.allocator());
        }
        _ = imgui.sliderFloat(
            "Viscosity/Friction",
            .{ .v = &viscosity, .min = 0, .max = 1 },
        );
        _ = imgui.checkbox("Bounded", .{ .v = &bounded });
        _ = imgui.checkbox("Show Model", .{ .v = &show_model });

        imgui.separator();
        _ = imgui.sliderInt(
            "GREEN:",
            .{ .v = &number_g, .min = 0, .max = 3000 },
        );
        _ = imgui.sliderFloat(
            "green x green:",
            .{ .v = &power_gg, .min = -100, .max = 100 },
        );
        _ = imgui.sliderFloat(
            "green x red:",
            .{ .v = &power_gr, .min = -100, .max = 100 },
        );
        _ = imgui.sliderFloat(
            "green x white:",
            .{ .v = &power_gw, .min = -100, .max = 100 },
        );
        _ = imgui.sliderFloat(
            "green x blue:",
            .{ .v = &power_gb, .min = -100, .max = 100 },
        );
        _ = imgui.sliderFloat(
            "radius g x g:",
            .{ .v = &v_gg, .min = 10, .max = 500 },
        );
        _ = imgui.sliderFloat(
            "radius g x r:",
            .{ .v = &v_gr, .min = 10, .max = 500 },
        );
        _ = imgui.sliderFloat(
            "radius g x w:",
            .{ .v = &v_gw, .min = 10, .max = 500 },
        );
        _ = imgui.sliderFloat(
            "radius g x b:",
            .{ .v = &v_gb, .min = 10, .max = 500 },
        );

        imgui.separator();
        _ = imgui.sliderInt(
            "RED:",
            .{ .v = &number_r, .min = 0, .max = 3000 },
        );
        _ = imgui.sliderFloat(
            "red x green:",
            .{ .v = &power_rg, .min = -100, .max = 100 },
        );
        _ = imgui.sliderFloat(
            "red x red:",
            .{ .v = &power_rr, .min = -100, .max = 100 },
        );
        _ = imgui.sliderFloat(
            "red x white:",
            .{ .v = &power_rw, .min = -100, .max = 100 },
        );
        _ = imgui.sliderFloat(
            "red x blue:",
            .{ .v = &power_rb, .min = -100, .max = 100 },
        );
        _ = imgui.sliderFloat(
            "radius r x g:",
            .{ .v = &v_rg, .min = 10, .max = 500 },
        );
        _ = imgui.sliderFloat(
            "radius r x r:",
            .{ .v = &v_rr, .min = 10, .max = 500 },
        );
        _ = imgui.sliderFloat(
            "radius r x w:",
            .{ .v = &v_rw, .min = 10, .max = 500 },
        );
        _ = imgui.sliderFloat(
            "radius r x b:",
            .{ .v = &v_rb, .min = 10, .max = 500 },
        );

        imgui.separator();
        _ = imgui.sliderInt(
            "WHITE:",
            .{ .v = &number_w, .min = 0, .max = 3000 },
        );
        _ = imgui.sliderFloat(
            "white x green:",
            .{ .v = &power_wg, .min = -100, .max = 100 },
        );
        _ = imgui.sliderFloat(
            "white x red:",
            .{ .v = &power_wr, .min = -100, .max = 100 },
        );
        _ = imgui.sliderFloat(
            "white x white:",
            .{ .v = &power_ww, .min = -100, .max = 100 },
        );
        _ = imgui.sliderFloat(
            "white x blue:",
            .{ .v = &power_wb, .min = -100, .max = 100 },
        );
        _ = imgui.sliderFloat(
            "radius w x g:",
            .{ .v = &v_wg, .min = 10, .max = 500 },
        );
        _ = imgui.sliderFloat(
            "radius w x r:",
            .{ .v = &v_wr, .min = 10, .max = 500 },
        );
        _ = imgui.sliderFloat(
            "radius w x w:",
            .{ .v = &v_ww, .min = 10, .max = 500 },
        );
        _ = imgui.sliderFloat(
            "radius w x b:",
            .{ .v = &v_wb, .min = 10, .max = 500 },
        );

        imgui.separator();
        _ = imgui.sliderInt(
            "BLUE:",
            .{ .v = &number_b, .min = 0, .max = 3000 },
        );
        _ = imgui.sliderFloat(
            "blue x green:",
            .{ .v = &power_bg, .min = -100, .max = 100 },
        );
        _ = imgui.sliderFloat(
            "blue x red:",
            .{ .v = &power_br, .min = -100, .max = 100 },
        );
        _ = imgui.sliderFloat(
            "blue x white:",
            .{ .v = &power_bw, .min = -100, .max = 100 },
        );
        _ = imgui.sliderFloat(
            "blue x blue:",
            .{ .v = &power_bb, .min = -100, .max = 100 },
        );
        _ = imgui.sliderFloat(
            "radius b x g:",
            .{ .v = &v_bg, .min = 10, .max = 500 },
        );
        _ = imgui.sliderFloat(
            "radius b x r:",
            .{ .v = &v_br, .min = 10, .max = 500 },
        );
        _ = imgui.sliderFloat(
            "radius b x w:",
            .{ .v = &v_bw, .min = 10, .max = 500 },
        );
        _ = imgui.sliderFloat(
            "radius b x b:",
            .{ .v = &v_bb, .min = 10, .max = 500 },
        );
    }
    imgui.end();
}

fn renderSimulation() !void {
    j2d.begin(.{});
    defer j2d.end();

    if (number_w > 0) try drawPoints(white.?);
    if (number_r > 0) try drawPoints(red.?);
    if (number_g > 0) try drawPoints(green.?);
    if (number_b > 0) try drawPoints(blue.?);
    if (show_model) {
        try j2d.circleFilled(
            .{ .x = xshift, .y = yshift },
            150,
            jok.Color.black,
            .{},
        );

        try j2d.line(
            .{ .x = p1x, .y = p1y - 10 },
            .{ .x = p2x, .y = p2y - 10 },
            jok.Color.rgb(
                @intFromFloat(150 - power_gr),
                @intFromFloat(150 + power_gr),
                150,
            ),
            .{
                .thickness = 5,
            },
        );
        try j2d.line(
            .{ .x = p1x, .y = p1y + 10 },
            .{ .x = p2x, .y = p2y + 10 },
            jok.Color.rgb(
                @intFromFloat(150 - power_rg),
                @intFromFloat(150 + power_rg),
                150,
            ),
            .{
                .thickness = 5,
            },
        );
        try j2d.line(
            .{ .x = p3x, .y = p3y - 10 },
            .{ .x = p1x, .y = p1y - 10 },
            jok.Color.rgb(
                @intFromFloat(150 - power_gw),
                @intFromFloat(150 + power_gw),
                150,
            ),
            .{
                .thickness = 5,
            },
        );
        try j2d.line(
            .{ .x = p3x, .y = p3y + 10 },
            .{ .x = p1x, .y = p1y + 10 },
            jok.Color.rgb(
                @intFromFloat(150 - power_wg),
                @intFromFloat(150 + power_wg),
                150,
            ),
            .{
                .thickness = 5,
            },
        );

        try j2d.line(
            .{ .x = p4x - 10, .y = p4y },
            .{ .x = p1x - 10, .y = p1y },
            jok.Color.rgb(
                @intFromFloat(150 - power_gb),
                @intFromFloat(150 + power_gb),
                150,
            ),
            .{
                .thickness = 5,
            },
        );
        try j2d.line(
            .{ .x = p4x + 10, .y = p4y },
            .{ .x = p1x + 10, .y = p1y },
            jok.Color.rgb(
                @intFromFloat(150 - power_bg),
                @intFromFloat(150 + power_bg),
                150,
            ),
            .{
                .thickness = 5,
            },
        );

        try j2d.line(
            .{ .x = p2x - 10, .y = p2y },
            .{ .x = p3x - 10, .y = p3y },
            jok.Color.rgb(
                @intFromFloat(150 - power_rw),
                @intFromFloat(150 + power_rw),
                150,
            ),
            .{
                .thickness = 5,
            },
        );
        try j2d.line(
            .{ .x = p2x + 10, .y = p2y },
            .{ .x = p3x + 10, .y = p3y },
            jok.Color.rgb(
                @intFromFloat(150 - power_wr),
                @intFromFloat(150 + power_wr),
                150,
            ),
            .{
                .thickness = 5,
            },
        );

        try j2d.line(
            .{ .x = p2x, .y = p2y - 10 },
            .{ .x = p4x, .y = p4y - 10 },
            jok.Color.rgb(
                @intFromFloat(150 - power_rb),
                @intFromFloat(150 + power_rb),
                150,
            ),
            .{
                .thickness = 5,
            },
        );
        try j2d.line(
            .{ .x = p2x, .y = p2y + 10 },
            .{ .x = p4x, .y = p4y + 10 },
            jok.Color.rgb(
                @intFromFloat(150 - power_br),
                @intFromFloat(150 + power_br),
                150,
            ),
            .{
                .thickness = 5,
            },
        );

        try j2d.line(
            .{ .x = p3x, .y = p3y - 10 },
            .{ .x = p4x, .y = p4y - 10 },
            jok.Color.rgb(
                @intFromFloat(150 - power_wb),
                @intFromFloat(150 + power_wb),
                150,
            ),
            .{
                .thickness = 5,
            },
        );
        try j2d.line(
            .{ .x = p3x, .y = p3y + 10 },
            .{ .x = p4x, .y = p4y + 10 },
            jok.Color.rgb(
                @intFromFloat(150 - power_bw),
                @intFromFloat(150 + power_bw),
                150,
            ),
            .{
                .thickness = 5,
            },
        );

        try j2d.circle(
            .{ .x = p1x - 20, .y = p1y - 20 },
            rr + 20,
            jok.Color.rgb(
                @intFromFloat(150 - power_gg),
                @intFromFloat(150 + power_gg),
                150,
            ),
            .{
                .thickness = 2,
            },
        );
        try j2d.circle(
            .{ .x = p2x + 20, .y = p2y - 20 },
            rr + 20,
            jok.Color.rgb(
                @intFromFloat(150 - power_rr),
                @intFromFloat(150 + power_rr),
                150,
            ),
            .{
                .thickness = 2,
            },
        );
        try j2d.circle(
            .{ .x = p3x + 20, .y = p3y + 20 },
            rr + 20,
            jok.Color.rgb(
                @intFromFloat(150 - power_ww),
                @intFromFloat(150 + power_ww),
                150,
            ),
            .{
                .thickness = 2,
            },
        );
        try j2d.circle(
            .{ .x = p4x - 20, .y = p4y + 20 },
            rr + 20,
            jok.Color.rgb(
                @intFromFloat(150 - power_bb),
                @intFromFloat(150 + power_bb),
                150,
            ),
            .{
                .thickness = 2,
            },
        );

        try j2d.circleFilled(
            .{ .x = p1x, .y = p1y },
            rr,
            jok.Color.rgb(100, 250, 10),
            .{},
        );
        try j2d.circleFilled(
            .{ .x = p2x, .y = p2y },
            rr,
            jok.Color.rgb(250, 10, 100),
            .{},
        );
        try j2d.circleFilled(
            .{ .x = p3x, .y = p3y },
            rr,
            jok.Color.rgb(250, 250, 250),
            .{},
        );
        try j2d.circleFilled(
            .{ .x = p4x, .y = p4y },
            rr,
            jok.Color.rgb(100, 100, 250),
            .{},
        );
    }
}

pub fn init(ctx: jok.Context) !void {
    std.log.info("game init", .{});

    rand_gen = std.Random.DefaultPrng.init(
        @intCast(std.time.timestamp()),
    );
    rand = rand_gen.random();

    try restart(ctx.allocator());
}

pub fn event(ctx: jok.Context, e: jok.Event) !void {
    _ = ctx;
    _ = e;
}

pub fn update(ctx: jok.Context) !void {
    _ = ctx;
}

pub fn draw(ctx: jok.Context) !void {
    try ctx.renderer().clear(null);
    ctx.displayStats(.{});

    if (number_w > 0) {
        interaction(white.?, green.?, power_wg, v_wg);
        interaction(white.?, red.?, power_wr, v_wr);
        interaction(white.?, white.?, power_ww, v_ww);
        interaction(white.?, blue.?, power_wb, v_wb);
    }
    if (number_r > 0) {
        interaction(red.?, green.?, power_rg, v_rg);
        interaction(red.?, red.?, power_rr, v_rr);
        interaction(red.?, white.?, power_rw, v_rw);
        interaction(red.?, blue.?, power_rb, v_rb);
    }
    if (number_g > 0) {
        interaction(green.?, green.?, power_gg, v_gg);
        interaction(green.?, red.?, power_gr, v_gr);
        interaction(green.?, white.?, power_gw, v_gw);
        interaction(green.?, blue.?, power_gb, v_gb);
    }
    if (number_b > 0) {
        interaction(blue.?, green.?, power_bg, v_bg);
        interaction(blue.?, red.?, power_br, v_br);
        interaction(blue.?, white.?, power_bw, v_bw);
        interaction(blue.?, blue.?, power_bb, v_bb);
    }
    try updateGui(ctx);
    try renderSimulation();
}

pub fn quit(ctx: jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});

    if (green) |g| g.deinit();
    if (red) |g| g.deinit();
    if (white) |g| g.deinit();
    if (blue) |g| g.deinit();
}
