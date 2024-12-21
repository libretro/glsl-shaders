#version 130

/*
    Pixel AA by fishku
    Copyright (C) 2023-2024
    Public domain license (CC0)

    Features:
    - Sharp upscaling with anti-aliasing
    - Subpixel upscaling
    - Sharpness can be controlled
    - Gamma correct blending
    - Integer scales result in pixel-perfect scaling
    - Can use bilinear filtering for max. performance

    Inspired by:
    https://www.shadertoy.com/view/MlB3D3
    by d7samurai
    and:
    https://www.youtube.com/watch?v=d6tp43wZqps
    by t3ssel8r

    With sharpness = 1.0, using the same gamma-correct blending, and disabling
    subpixel anti-aliasing, results are identical to the "pixellate" shader.

    Changelog:
    v1.7: Clean up, minor optimizations
    v1.6: Add "fast" version for low-end devices.
    v1.5: Optimize for embedded devices.
    v1.4: Enable subpixel sampling for all four pixel layout orientations,
          including rotated screens.
    v1.3: Account for screen rotation in subpixel sampling.
    v1.2: Optimize and simplify algorithm. Enable sharpness < 1.0. Fix subpixel
          sampling bug.
    v1.1: Better subpixel sampling.
    v1.0: Initial release.
*/

// clang-format off
#pragma parameter PIX_AA_SETTINGS "=== Pixel AA v1.7 settings ===" 0.0 0.0 1.0 1.0
#pragma parameter PIX_AA_SHARP "Pixel AA sharpening amount" 1.5 0.0 2.0 0.05
#pragma parameter PIX_AA_GAMMA "Enable gamma-correct blending" 1.0 0.0 1.0 1.0
#pragma parameter PIX_AA_SUBPX "Enable subpixel AA" 0.0 0.0 1.0 1.0
#pragma parameter PIX_AA_SUBPX_ORIENTATION "Subpixel layout (0=RGB, 1=RGB vert., 2=BGR, 3=BGR vert.)" 0.0 0.0 3.0 1.0
// clang-format on

#if defined(VERTEX)

#ifdef GL_ES
#define COMPAT_PRECISION mediump
#else
#define COMPAT_PRECISION
#endif

uniform mat4 MVPMatrix;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;

in vec4 VertexCoord;
in vec4 TexCoord;

out vec2 tx_coord;
out vec2 tx_per_px;
out vec2 tx_to_uv;

void main() {
  gl_Position = MVPMatrix * VertexCoord;
  tx_coord = TexCoord.xy * TextureSize;
  tx_per_px = InputSize / OutputSize;
  tx_to_uv = 1.0 / TextureSize;
}

#elif defined(FRAGMENT)

#ifdef GL_ES
#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif
#define COMPAT_PRECISION mediump
#else
#define COMPAT_PRECISION
#endif

uniform COMPAT_PRECISION int Rotation;
uniform sampler2D Texture;

in vec2 tx_coord;
in vec2 tx_per_px;
in vec2 tx_to_uv;

out COMPAT_PRECISION vec4 FragColor;

// Similar to smoothstep, but has a configurable slope at x = 0.5.
// Original smoothstep has a slope of 1.5 at x = 0.5
vec2 slopestep(vec2 edge0, vec2 edge1, vec2 x, float slope) {
  x = clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0);
  vec2 s = sign(x - 0.5);
  vec2 o = (1.0 + s) * 0.5;
  return o - 0.5 * s * pow(2.0 * (o - s * x), vec2(slope));
}

vec3 to_lin(vec3 x) { return pow(x, vec3(2.2)); }
vec4 to_lin(vec4 x) { return pow(x, vec4(2.2)); }
vec3 to_srgb(vec3 x) { return pow(x, vec3(1.0 / 2.2)); }

// Function to get a pixel value, taking into consideration possible subpixel
// interpolation.
vec4 pixel_aa(sampler2D tex, vec2 tx_per_px, vec2 tx_to_uv, vec2 tx_coord,
              float sharpness, bool gamma_correct, bool sample_subpx,
              int subpx_orientation, int screen_rotation) {
  float sharpness_upper = min(1.0, sharpness);
  vec2 sharp_lb = sharpness_upper * (0.5 - 0.5 * tx_per_px);
  vec2 sharp_ub = 1.0 - sharpness_upper * (1.0 - (0.5 + 0.5 * tx_per_px));
  float sharpness_lower = max(1.0, sharpness);

  if (sample_subpx) {
    // Subpixel sampling: Shift the sampling by 1/3rd of an output pixel for
    // each subpixel, assuming that the output size is at monitor
    // resolution.
    // Compensate for possible rotation of the screen in certain cores.
    const vec4 rot_corr = vec4(1.0, 0.0, -1.0, 0.0);
    vec2 sub_tx_offset =
        tx_per_px / 3.0 *
        vec2(rot_corr[(screen_rotation + subpx_orientation) % 4],
             rot_corr[(screen_rotation + subpx_orientation + 3) % 4]);

    vec3 res;
    vec2 period, phase, offset;

    if (gamma_correct) {
      vec4 samples;
      // Red
      period = floor(tx_coord - sub_tx_offset - 0.5);
      phase = tx_coord - sub_tx_offset - 0.5 - period;
      offset = slopestep(sharp_lb, sharp_ub, phase, sharpness_lower);
      samples = vec4(texture(tex, (period + 0.5) * tx_to_uv).r,
                     texture(tex, (period + vec2(1.5, 0.5)) * tx_to_uv).r,
                     texture(tex, (period + vec2(0.5, 1.5)) * tx_to_uv).r,
                     texture(tex, (period + 1.5) * tx_to_uv).r);
      samples = to_lin(samples);
      res.r = mix(mix(samples.x, samples.y, offset.x),
                  mix(samples.z, samples.w, offset.x), offset.y);
      // Green
      period = floor(tx_coord - 0.5);
      phase = tx_coord - 0.5 - period;
      offset = slopestep(sharp_lb, sharp_ub, phase, sharpness_lower);
      samples = vec4(texture(tex, (period + 0.5) * tx_to_uv).g,
                     texture(tex, (period + vec2(1.5, 0.5)) * tx_to_uv).g,
                     texture(tex, (period + vec2(0.5, 1.5)) * tx_to_uv).g,
                     texture(tex, (period + 1.5) * tx_to_uv).g);
      samples = to_lin(samples);
      res.g = mix(mix(samples.x, samples.y, offset.x),
                  mix(samples.z, samples.w, offset.x), offset.y);
      // Blue
      period = floor(tx_coord + sub_tx_offset - 0.5);
      phase = tx_coord + sub_tx_offset - 0.5 - period;
      offset = slopestep(sharp_lb, sharp_ub, phase, sharpness_lower);
      samples = vec4(texture(tex, (period + 0.5) * tx_to_uv).b,
                     texture(tex, (period + vec2(1.5, 0.5)) * tx_to_uv).b,
                     texture(tex, (period + vec2(0.5, 1.5)) * tx_to_uv).b,
                     texture(tex, (period + 1.5) * tx_to_uv).b);
      samples = to_lin(samples);
      res.b = mix(mix(samples.x, samples.y, offset.x),
                  mix(samples.z, samples.w, offset.x), offset.y);

      res = to_srgb(res);
    } else {
      // Red
      period = floor(tx_coord - sub_tx_offset - 0.5);
      phase = tx_coord - sub_tx_offset - 0.5 - period;
      offset = slopestep(sharp_lb, sharp_ub, phase, sharpness_lower);
      res.r = texture(tex, (period + 0.5 + offset) * tx_to_uv).r;
      // Green
      period = floor(tx_coord - 0.5);
      phase = tx_coord - 0.5 - period;
      offset = slopestep(sharp_lb, sharp_ub, phase, sharpness_lower);
      res.g = texture(tex, (period + 0.5 + offset) * tx_to_uv).g;
      // Blue
      period = floor(tx_coord + sub_tx_offset - 0.5);
      phase = tx_coord + sub_tx_offset - 0.5 - period;
      offset = slopestep(sharp_lb, sharp_ub, phase, sharpness_lower);
      res.b = texture(tex, (period + 0.5 + offset) * tx_to_uv).b;
    }

    return vec4(res, 1.0);
  } else {
    // The offset for interpolation is a periodic function with
    // a period length of 1 texel.
    // The input coordinate is shifted so that the center of the texel
    // aligns with the start of the period.
    // First, get the period and phase.
    vec2 period = floor(tx_coord - 0.5);
    vec2 phase = tx_coord - 0.5 - period;
    // The function starts at 0, then starts transitioning at
    // 0.5 - 0.5 / pixels_per_texel, then reaches 0.5 at 0.5,
    // Then reaches 1 at 0.5 + 0.5 / pixels_per_texel.
    // For sharpness values < 1.0, blend to bilinear filtering.
    vec2 offset = slopestep(sharp_lb, sharp_ub, phase, sharpness_lower);

    // With gamma correct blending, we have to do 4 taps and interpolate
    // manually. Without it, we can make use of a single tap using bilinear
    // interpolation. The offsets are shifted back to the texel center before
    // sampling.
    if (gamma_correct) {
      return vec4(
          to_srgb(mix(
              mix(to_lin(texture(tex, (period + 0.5) * tx_to_uv).rgb),
                  to_lin(
                      texture(tex, (period + vec2(1.5, 0.5)) * tx_to_uv).rgb),
                  offset.x),
              mix(to_lin(
                      texture(tex, (period + vec2(0.5, 1.5)) * tx_to_uv).rgb),
                  to_lin(texture(tex, (period + 1.5) * tx_to_uv).rgb),
                  offset.x),
              offset.y)),
          1.0);
    } else {
      return texture(tex, (period + 0.5 + offset) * tx_to_uv);
    }
  }
}

uniform COMPAT_PRECISION float PIX_AA_SHARP;
uniform COMPAT_PRECISION float PIX_AA_GAMMA;
uniform COMPAT_PRECISION float PIX_AA_SUBPX;
uniform COMPAT_PRECISION float PIX_AA_SUBPX_ORIENTATION;

void main() {
  FragColor = pixel_aa(Texture, tx_per_px, tx_to_uv, tx_coord, PIX_AA_SHARP,
                       PIX_AA_GAMMA > 0.5, PIX_AA_SUBPX > 0.5,
                       int(PIX_AA_SUBPX_ORIENTATION), Rotation);
}

#endif
