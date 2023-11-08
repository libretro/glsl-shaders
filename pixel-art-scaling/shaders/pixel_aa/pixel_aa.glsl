// layout(push_constant) uniform Push {
//     vec4 SourceSize;
//     vec4 OutputSize;
//     uint Rotation;
//     float PIX_AA_SHARP;
//     float PIX_AA_GAMMA;
//     float PIX_AA_SUBPX;
//     float PIX_AA_SUBPX_BGR;
// }
// param;

/*
    Pixel AA v1.3 by fishku
    Copyright (C) 2023
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
    v1.3: Account for screen rotation in subpixel sampling.
    v1.2: Optimize and simplify algorithm. Enable sharpness < 1.0. Fix subpixel
          sampling bug.
    v1.1: Better subpixel sampling.
    v1.0: Initial release.
*/

// clang-format off
#pragma parameter PIX_AA_SETTINGS "=== Pixel AA v1.3 settings ===" 0.0 0.0 1.0 1.0
#pragma parameter PIX_AA_SHARP "Pixel AA sharpening amount" 1.5 0.0 2.0 0.05
#pragma parameter PIX_AA_GAMMA "Enable gamma-correct blending" 1.0 0.0 1.0 1.0
#pragma parameter PIX_AA_SUBPX "Enable subpixel AA" 0.0 0.0 1.0 1.0
#pragma parameter PIX_AA_SUBPX_BGR "Use BGR subpx. instead of RGB" 0.0 0.0 1.0 1.0
// clang-format on

#if defined(VERTEX)

#if __VERSION__ >= 130
#define COMPAT_VARYING out
#define COMPAT_ATTRIBUTE in
#define COMPAT_TEXTURE texture
#else
#define COMPAT_VARYING varying
#define COMPAT_ATTRIBUTE attribute
#define COMPAT_TEXTURE texture2D
#endif

#ifdef GL_ES
#define COMPAT_PRECISION mediump
#else
#define COMPAT_PRECISION
#endif

COMPAT_ATTRIBUTE vec4 VertexCoord;
COMPAT_ATTRIBUTE vec4 TexCoord;

COMPAT_VARYING vec2 tx_coord;
COMPAT_VARYING vec2 tx_per_px;
COMPAT_VARYING vec2 tx_to_uv;

uniform mat4 MVPMatrix;
uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;

// compatibility #defines
#define SourceSize vec4(TextureSize, 1.0 / TextureSize)
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

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

#if __VERSION__ >= 130
#define COMPAT_VARYING in
#define COMPAT_TEXTURE texture
out COMPAT_PRECISION vec4 FragColor;
#else
#define COMPAT_VARYING varying
#define FragColor gl_FragColor
#define COMPAT_TEXTURE texture2D
#endif

uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;
uniform sampler2D Texture;

COMPAT_VARYING vec2 tx_coord;
COMPAT_VARYING vec2 tx_per_px;
COMPAT_VARYING vec2 tx_to_uv;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize)
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

// Similar to smoothstep, but has a configurable slope at x = 0.5.
// Original smoothstep has a slope of 1.5 at x = 0.5
vec2 slopestep(vec2 edge0, vec2 edge1, vec2 x, float slope) {
  x = clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0);
  vec2 s = sign(x - 0.5);
  vec2 o = (1.0 + s) * 0.5;
  return o - 0.5 * s * pow(2.0 * (o - s * x), vec2(slope));
}

vec3 to_lin(vec3 x) { return pow(x, vec3(2.2)); }

vec3 to_srgb(vec3 x) { return pow(x, vec3(1.0 / 2.2)); }

// Function to get a single sample using the "pixel AA" method.
// Params:
// tx_coord: Coordinate in source pixel (texel) coordinates
vec3 sample_aa(sampler2D tex, vec2 tx_per_px, vec2 tx_to_uv, vec2 tx_coord,
               float sharpness, bool gamma_correct) {
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
  vec2 offset =
      slopestep(min(1.0, sharpness) * (0.5 - 0.5 * tx_per_px),
                1.0 - min(1.0, sharpness) * (1.0 - (0.5 + 0.5 * tx_per_px)),
                phase, max(1.0, sharpness));

  // With gamma correct blending, we have to do 4 taps and interpolate
  // manually. Without it, we can make use of a single tap using bilinear
  // interpolation. The offsets are shifted back to the texel center before
  // sampling.
  if (gamma_correct) {
    return to_srgb(mix(
        mix(to_lin(COMPAT_TEXTURE(tex, (period + 0.5) * tx_to_uv).rgb),
            to_lin(
                COMPAT_TEXTURE(tex, (period + vec2(1.5, 0.5)) * tx_to_uv).rgb),
            offset.x),
        mix(to_lin(
                COMPAT_TEXTURE(tex, (period + vec2(0.5, 1.5)) * tx_to_uv).rgb),
            to_lin(COMPAT_TEXTURE(tex, (period + 1.5) * tx_to_uv).rgb),
            offset.x),
        offset.y));
  } else {
    return COMPAT_TEXTURE(tex, (period + 0.5 + offset) * tx_to_uv).rgb;
  }
}

// Function to get a pixel value, taking into consideration possible subpixel
// interpolation.
vec4 pixel_aa(sampler2D tex, vec2 tx_per_px, vec2 tx_to_uv, vec2 tx_coord,
              float sharpness, bool gamma_correct, bool sample_subpx,
              bool subpx_bgr, int rotation) {
  if (sample_subpx) {
    // Subpixel sampling: Shift the sampling by 1/3rd of an output pixel for
    // each subpixel, assuming that the output size is at monitor
    // resolution.
    // Compensate for possible rotation of the screen in certain cores.
    vec2 rotation_correction[4];
    rotation_correction[0] = vec2(1.0, 0.0);
    rotation_correction[1] = vec2(0.0, 1.0);
    rotation_correction[2] = vec2(-1.0, 0.0);
    rotation_correction[3] = vec2(0.0, -1.0);
    vec2 sub_tx_offset =
        tx_per_px / 3.0 *
        rotation_correction[mod(rotation + int(subpx_bgr) * 2, 4)];
    vec3 res;
    for (int i = 0; i < 3; ++i) {
      res[i] = sample_aa(tex, tx_per_px, tx_to_uv,
                         tx_coord + sub_tx_offset * (float(i) - 1.0),
                         sharpness, gamma_correct)[i];
    }
    return vec4(res, 1.0);
  } else {
    return vec4(
        sample_aa(tex, tx_per_px, tx_to_uv, tx_coord, sharpness, gamma_correct),
        1.0);
  }
 return vec4(0.0);
}

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float PIX_AA_SHARP;
uniform COMPAT_PRECISION float PIX_AA_GAMMA;
uniform COMPAT_PRECISION float PIX_AA_SUBPX;
uniform COMPAT_PRECISION float PIX_AA_SUBPX_BGR;
#else
#define PIX_AA_SHARP 1.5
#define PIX_AA_GAMMA 1.0
#define PIX_AA_SUBPX 0.0
#define PIX_AA_SUBPX_BGR 0.0
#endif

void main() {
  FragColor = pixel_aa(Source, tx_per_px, tx_to_uv, tx_coord, PIX_AA_SHARP,
                       PIX_AA_GAMMA > 0.5, PIX_AA_SUBPX > 0.5,
                       PIX_AA_SUBPX_BGR > 0.5, 0);
}

#endif
