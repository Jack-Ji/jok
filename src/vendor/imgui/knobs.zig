const gui = @import("main.zig");

pub const KnobFlags = packed struct(u32) {
    no_title: bool = false,
    no_input: bool = false,
    value_tooltip: bool = false,
    drag_horizontal: bool = false,
    drag_vertical: bool = false,
    logarithmic: bool = false,
    always_clamp: bool = false,
    _padding: u25 = 0,
};

pub const KnobVariant = packed struct(u32) {
    tick: bool = false,
    dot: bool = false,
    wiper: bool = false,
    wiper_only: bool = false,
    wiper_dot: bool = false,
    stepped: bool = false,
    space: bool = false,
    _padding: u25 = 0,
};

//---------------------------------------------------------------------------------------------------------------------|
fn KnobTypeGen(comptime T: type) type {
    const cfmt = switch (T) {
        f32 => "%.3f",
        i32 => "%i",
        else => {
            @panic("Unsupported Knob Type");
        },
    };

    return struct {
        v: *T,
        v_min: T,
        v_max: T,
        speed: f32 = 0,
        comptime cfmt: [:0]const u8 = cfmt,
        variant: KnobVariant = .{ .tick = true }, // an enum
        size: f32 = 0,
        flags: KnobFlags = .{},
        steps: i32 = 10,
        angle_min: f32 = -1,
        angle_max: f32 = -1,
    };
}

/// Remarks:
/// - angle_min and angle_max works in radian with the starting position at the right side of the circle
/// - steps only affects the visuals for stepped KnobVariant
pub fn knob(
    label: [*:0]const u8,
    args: KnobTypeGen(f32),
) bool {
    return zknobs_Knob(label, args.v, args.v_min, args.v_max, args.speed, args.cfmt, args.variant, args.size, args.flags, args.steps, args.angle_min, args.angle_max);
}

/// Remarks:
/// - angle_min and angle_max works in radian with the starting position at the right side of the circle
/// - steps only affects the visuals for stepped KnobVariant
pub fn knobInt(
    label: [*:0]const u8,
    args: KnobTypeGen(i32),
) bool {
    return zknobs_KnobInt(label, args.v, args.v_min, args.v_max, args.speed, args.cfmt, args.variant, args.size, args.flags, args.steps, args.angle_min, args.angle_max);
}

//---------------------------------------------------------------------------------------------------------------------|
extern fn zknobs_Knob(
    label: [*:0]const u8,
    v: *f32,
    v_min: f32,
    v_max: f32,
    speed: f32,
    cfmt: [*:0]const u8,
    variant: KnobVariant,
    size: f32,
    flags: KnobFlags,
    steps: c_int,
    angle_min: f32,
    angle_max: f32,
) bool;

extern fn zknobs_KnobInt(
    label: [*:0]const u8,
    v: *c_int,
    v_min: c_int,
    v_max: c_int,
    speed: f32,
    cfmt: [*:0]const u8,
    variant: KnobVariant,
    size: f32,
    flags: KnobFlags,
    steps: c_int,
    angle_min: f32,
    angle_max: f32,
) bool;
