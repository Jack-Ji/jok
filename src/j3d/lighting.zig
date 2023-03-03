/// Common types related to lighting
const std = @import("std");
const assert = std.debug.assert;
const math = std.math;
const jok = @import("../jok.zig");
const sdl = jok.sdl;
const zmath = jok.zmath;

/// Lighting options
pub const Light = union(enum) {
    directional: struct {
        ambient: zmath.Vec = zmath.f32x4s(0.1),
        diffuse: zmath.Vec = zmath.f32x4s(0.8),
        specular: zmath.Vec = zmath.f32x4s(0.5),
        direction: zmath.Vec = zmath.f32x4(0, -1, -1, 0),
    },
    point: struct {
        ambient: zmath.Vec = zmath.f32x4s(0.1),
        diffuse: zmath.Vec = zmath.f32x4s(0.8),
        specular: zmath.Vec = zmath.f32x4s(0.5),
        position: zmath.Vec = zmath.f32x4(1, 1, 1, 1),
        constant: f32 = 1.0,
        attenuation_linear: f32 = 0.5,
        attenuation_quadratic: f32 = 0.3,
    },
    spot: struct {
        ambient: zmath.Vec = zmath.f32x4s(0.1),
        diffuse: zmath.Vec = zmath.f32x4s(0.9),
        specular: zmath.Vec = zmath.f32x4s(0.8),
        position: zmath.Vec = zmath.f32x4(3, 3, 3, 1),
        direction: zmath.Vec = zmath.f32x4(-1, -1, -1, 0),
        constant: f32 = 1.0,
        attenuation_linear: f32 = 0.01,
        attenuation_quadratic: f32 = 0.001,
        inner_cutoff: f32 = 0.95,
        outer_cutoff: f32 = 0.85,
    },
};

pub const LightingOption = struct {
    const max_light_num = 32;
    lights: [max_light_num]Light = [_]Light{.{ .directional = .{} }} ** max_light_num,
    lights_num: u32 = 1,
    shininess: f32 = 4,

    // Calculate color of light source
    light_calc_fn: ?*const fn (
        material_color: sdl.Color,
        eye_pos: zmath.Vec,
        vertex_pos: zmath.Vec,
        normal: zmath.Vec,
        opt: LightingOption,
    ) sdl.Color = null,
};

/// Calculate tint color of vertex according to lighting paramters
pub fn calcLightColor(
    material_color: sdl.Color,
    eye_pos: zmath.Vec,
    vertex_pos: zmath.Vec,
    normal: zmath.Vec,
    opt: LightingOption,
) sdl.Color {
    const S = struct {
        inline fn calcColor(
            raw_color: zmath.Vec,
            shininess: f32,
            light_dir: zmath.Vec,
            eye_dir: zmath.Vec,
            _normal: zmath.Vec,
            _ambient: zmath.Vec,
            _diffuse: zmath.Vec,
            _specular: zmath.Vec,
        ) zmath.Vec {
            const dns = zmath.dot3(_normal, light_dir);
            var diffuse = zmath.max(dns, zmath.f32x4s(0)) * _diffuse;
            var specular = zmath.f32x4s(0);
            if (dns[0] > 0) {
                // Calculate reflect ratio (Blinn-Phong model)
                const halfway_dir = zmath.normalize3(eye_dir + light_dir);
                const s = math.pow(f32, zmath.max(
                    zmath.dot3(_normal, halfway_dir),
                    zmath.f32x4s(0),
                )[0], shininess);
                specular = zmath.f32x4s(s) * _specular;
            }
            return raw_color * (_ambient + diffuse + specular);
        }
    };

    if (opt.lights_num == 0) return material_color;
    assert(math.approxEqAbs(f32, eye_pos[3], 1.0, math.f32_epsilon));
    assert(math.approxEqAbs(f32, vertex_pos[3], 1.0, math.f32_epsilon));
    assert(math.approxEqAbs(f32, normal[3], 0, math.f32_epsilon));
    const ts = zmath.f32x4s(1.0 / 255.0);
    const raw_color = zmath.f32x4(
        @intToFloat(f32, material_color.r),
        @intToFloat(f32, material_color.g),
        @intToFloat(f32, material_color.b),
        0,
    ) * ts;

    var final_color = zmath.f32x4s(0);
    for (opt.lights[0..opt.lights_num]) |ul| {
        switch (ul) {
            .directional => |light| {
                const light_dir = zmath.normalize3(-light.direction);
                const eye_dir = zmath.normalize3(eye_pos - vertex_pos);
                final_color += S.calcColor(
                    raw_color,
                    opt.shininess,
                    light_dir,
                    eye_dir,
                    normal,
                    light.ambient,
                    light.diffuse,
                    light.specular,
                );
            },
            .point => |light| {
                const light_dir = zmath.normalize3(light.position - vertex_pos);
                const eye_dir = zmath.normalize3(eye_pos - vertex_pos);
                const distance = zmath.length3(light.position - vertex_pos)[0];
                const attenuation = 1.0 / (light.constant +
                    light.attenuation_linear * distance +
                    light.attenuation_quadratic * distance * distance);
                final_color += S.calcColor(
                    raw_color,
                    opt.shininess,
                    light_dir,
                    eye_dir,
                    normal,
                    light.ambient,
                    light.diffuse,
                    light.specular,
                ) * zmath.f32x4s(attenuation);
            },
            .spot => |light| {
                const eye_dir = zmath.normalize3(eye_pos - vertex_pos);
                const distance = zmath.length3(light.position - vertex_pos)[0];
                const attenuation = 1.0 / (light.constant +
                    light.attenuation_linear * distance +
                    light.attenuation_quadratic * distance * distance);
                const light_dir = zmath.normalize3(light.position - vertex_pos);
                const theta = zmath.dot3(light_dir, zmath.normalize3(-light.direction))[0];
                assert(light.inner_cutoff > light.outer_cutoff);
                const epsilon = light.inner_cutoff - light.outer_cutoff;
                assert(epsilon > 0);
                const intensity = zmath.f32x4s(math.clamp((theta - light.outer_cutoff) / epsilon, 0.0, 1.0));
                final_color += S.calcColor(
                    raw_color,
                    opt.shininess,
                    light_dir,
                    eye_dir,
                    normal,
                    light.ambient,
                    light.diffuse * intensity,
                    light.specular * intensity,
                ) * zmath.f32x4s(attenuation);
            },
        }
    }

    final_color = zmath.clamp(
        final_color,
        zmath.f32x4s(0),
        zmath.f32x4s(1),
    );
    return .{
        .r = @floatToInt(u8, final_color[0] * 255),
        .g = @floatToInt(u8, final_color[1] * 255),
        .b = @floatToInt(u8, final_color[2] * 255),
        .a = material_color.a,
    };
}
