//! Lighting system for 3D rendering.
//!
//! This module provides lighting calculations for 3D scenes including:
//! - Directional lights (sun-like, parallel rays)
//! - Point lights (omnidirectional, with attenuation)
//! - Spot lights (cone-shaped, with falloff)
//! - Phong/Blinn-Phong shading model
//! - Ambient, diffuse, and specular components
//!
//! The lighting calculations use the Blinn-Phong reflection model for
//! realistic light-material interactions.

const std = @import("std");
const assert = std.debug.assert;
const math = std.math;
const jok = @import("../jok.zig");
const zmath = jok.vendor.zmath;

/// Light source types and their parameters
pub const Light = union(enum) {
    /// Directional light (like the sun) with parallel rays
    directional: struct {
        ambient: zmath.Vec = zmath.f32x4s(0.1),
        diffuse: zmath.Vec = zmath.f32x4s(0.8),
        specular: zmath.Vec = zmath.f32x4s(0.5),
        direction: zmath.Vec = zmath.f32x4(0, -1, -1, 0),
    },
    /// Point light with omnidirectional emission and distance attenuation
    point: struct {
        ambient: zmath.Vec = zmath.f32x4s(0.1),
        diffuse: zmath.Vec = zmath.f32x4s(0.8),
        specular: zmath.Vec = zmath.f32x4s(0.5),
        position: zmath.Vec = zmath.f32x4(1, 1, 1, 1),
        constant: f32 = 1.0,
        attenuation_linear: f32 = 0.5,
        attenuation_quadratic: f32 = 0.3,
    },
    /// Spot light with cone-shaped emission and angular falloff
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

/// Lighting configuration for rendering
pub const LightingOption = struct {
    /// Maximum number of lights supported
    const max_light_num = 32;

    /// Array of light sources
    lights: [max_light_num]Light = [_]Light{.{ .directional = .{} }} ** max_light_num,

    /// Number of active lights
    lights_num: u32 = 1,

    /// Material shininess factor (higher = more focused specular highlights)
    shininess: f32 = 4,

    /// Optional custom lighting calculation function
    light_calc_fn: ?*const fn (
        material_color: jok.ColorF,
        eye_pos: zmath.Vec,
        vertex_pos: zmath.Vec,
        normal: zmath.Vec,
        opt: LightingOption,
    ) jok.ColorF = null,
};

/// Calculate the final color of a vertex with lighting applied
/// Uses the Blinn-Phong shading model with ambient, diffuse, and specular components
pub fn calcLightColor(
    material_color: jok.ColorF,
    eye_pos: zmath.Vec,
    vertex_pos: zmath.Vec,
    normal: zmath.Vec,
    opt: LightingOption,
) jok.ColorF {
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
            const diffuse = zmath.max(dns, zmath.f32x4s(0)) * _diffuse;
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
    assert(math.approxEqAbs(f32, eye_pos[3], 1.0, math.floatEps(f32)));
    assert(math.approxEqAbs(f32, vertex_pos[3], 1.0, math.floatEps(f32)));
    assert(math.approxEqAbs(f32, normal[3], 0, math.floatEps(f32)));
    const raw_color = zmath.f32x4(
        material_color.r,
        material_color.g,
        material_color.b,
        0,
    );

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
        .r = final_color[0],
        .g = final_color[1],
        .b = final_color[2],
        .a = material_color.a,
    };
}
