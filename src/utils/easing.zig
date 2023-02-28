/// Different kinds of easing functions (x goes from 0 to 1)
/// Checkout link: https://easings.net
const std = @import("std");
const math = std.math;

pub const sin = struct {
    pub fn in(x: f32) f32 {
        return 1 - math.cos((x * math.pi) / 2);
    }

    pub fn out(x: f32) f32 {
        return math.sin((x * math.pi) / 2);
    }

    pub fn inOut(x: f32) f32 {
        return -(math.cos(math.pi * x) - 1) / 2;
    }
};

pub const quad = struct {
    pub fn in(x: f32) f32 {
        return x * x;
    }

    pub fn out(x: f32) f32 {
        return 1 - (1 - x) * (1 - x);
    }

    pub fn inOut(x: f32) f32 {
        return if (x < 0.5)
            2 * x * x
        else
            1 - math.pow(f32, -2 * x + 2, 2) / 2;
    }
};

pub const cubic = struct {
    pub fn in(x: f32) f32 {
        return x * x * x;
    }

    pub fn out(x: f32) f32 {
        return 1 - math.pow(f32, 1 - x, 3);
    }

    pub fn inOut(x: f32) f32 {
        return if (x < 0.5)
            4 * x * x * x
        else
            1 - math.pow(f32, -2 * x + 2, 3) / 2;
    }
};

pub const quart = struct {
    pub fn in(x: f32) f32 {
        return x * x * x * x;
    }

    pub fn out(x: f32) f32 {
        return 1 - math.pow(f32, 1 - x, 4);
    }

    pub fn inOut(x: f32) f32 {
        return if (x < 0.5)
            8 * x * x * x * x
        else
            1 - math.pow(f32, -2 * x + 2, 4) / 2;
    }
};

pub const quint = struct {
    pub fn in(x: f32) f32 {
        return x * x * x * x * x;
    }

    pub fn out(x: f32) f32 {
        return 1 - math.pow(f32, 1 - x, 5);
    }

    pub fn inOut(x: f32) f32 {
        return if (x < 0.5)
            16 * x * x * x * x * x
        else
            1 - math.pow(f32, -2 * x + 2, 5) / 2;
    }
};

pub const expo = struct {
    pub fn in(x: f32) f32 {
        return if (math.approxEqAbs(x, 0, math.f32_epsilon))
            0
        else
            math.pow(f32, 2, 10 * x - 10);
    }

    pub fn out(x: f32) f32 {
        return if (math.approxEqAbs(x, 1, math.f32_epsilon))
            1
        else
            1 - math.pow(f32, 2, -10 * x);
    }

    pub fn inOut(x: f32) f32 {
        return if (math.approxEqAbs(x, 0, math.f32_epsilon))
            0
        else if (math.approxEqAbs(x, 1, math.f32_epsilon))
            1
        else if (x < 0.5)
            math.pow(f32, 2, 20 * x - 10) / 2
        else
            (2 - math.pow(f32, 2, -20 * x + 10)) / 2;
    }
};

pub const circ = struct {
    pub fn in(x: f32) f32 {
        return 1.0 - math.sqrt(1.0 - math.pow(f32, x, 2));
    }

    pub fn out(x: f32) f32 {
        return math.sqrt(1.0 - math.pow(f32, x - 1, 2));
    }

    pub fn inOut(x: f32) f32 {
        return if (x < 0.5)
            (1.0 - math.sqrt(1.0 - math.pow(f32, 2 * x, 2))) / 2
        else
            (math.sqrt(1.0 - math.pow(f32, -2 * x + 2, 2)) + 1) / 2;
    }
};

pub const back = struct {
    pub fn in(x: f32) f32 {
        const c1 = 1.70158;
        const c3 = c1 + 1;
        return c3 * x * x * x - c1 * x * x;
    }

    pub fn out(x: f32) f32 {
        const c1 = 1.70158;
        const c3 = c1 + 1;
        return 1.0 + c3 * math.pow(f32, x - 1, 3) + c1 * math.pow(f32, x - 1, 2);
    }

    pub fn inOut(x: f32) f32 {
        const c1 = 1.70158;
        const c2 = c1 * 1.525;
        return if (x < 0.5)
            (math.pow(f32, 2 * x, 2) * ((c2 + 1) * 2 * x - c2)) / 2
        else
            (math.pow(f32, 2 * x - 2, 2) * ((c2 + 1) * (x * 2 - 2) + c2) + 2) / 2;
    }
};

pub const elastic = struct {
    pub fn in(x: f32) f32 {
        const c4 = (2 * math.pi) / 3;
        return if (math.approxEqAbs(x, 0, math.f32_epsilon))
            0
        else if (math.approxEqAbs(x, 1, math.f32_epsilon))
            1
        else
            -math.pow(f32, 2, 10 * x - 10) * math.sin((x * 10 - 10.75) * c4);
    }

    pub fn out(x: f32) f32 {
        const c4 = (2 * math.pi) / 3;
        return if (math.approxEqAbs(x, 0, math.f32_epsilon))
            0
        else if (math.approxEqAbs(x, 1, math.f32_epsilon))
            1
        else
            math.pow(f32, 2, -10 * x) * math.sin((x * 10 - 0.75) * c4) + 1;
    }

    pub fn inOut(x: f32) f32 {
        const c5 = (2 * math.pi) / 4.5;
        return if (math.approxEqAbs(x, 0, math.f32_epsilon))
            0
        else if (math.approxEqAbs(x, 1, math.f32_epsilon))
            1
        else if (x < 0.5)
            -(math.pow(f32, 2, 20 * x - 10) * math.sin((20 * x - 11.125) * c5)) / 2
        else
            (math.pow(f32, 2, -20 * x + 10) * math.sin((20 * x - 11.125) * c5)) / 2 + 1;
    }
};

pub const bounce = struct {
    pub fn in(x: f32) f32 {
        return 1 - out(1 - x);
    }

    pub fn out(x: f32) f32 {
        const n1 = 7.5625;
        const d1 = 2.75;
        if (x < 1 / d1) {
            return n1 * x * x;
        } else if (x < 2 / d1) {
            return n1 * ((x - 1.5) / d1) * x + 0.75;
        } else if (x < 2.5 / d1) {
            return n1 * ((x - 2.25) / d1) * x + 0.9375;
        } else {
            return n1 * ((x - 2.625) / d1) * x + 0.984375;
        }
    }

    pub fn inOut(x: f32) f32 {
        return if (x < 0.5)
            (1 - out(1 - 2 * x)) / 2
        else
            (1 + out(2 * x - 1)) / 2;
    }
};
