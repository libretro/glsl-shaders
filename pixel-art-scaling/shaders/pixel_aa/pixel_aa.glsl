#version 130

/*
    Pixel AA by fishku
    Copyright (C) 2023-2025
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
    v1.10: Fix bug with precision specifiers causing trouble on certain compilers.
    v1.9: Sync GLSL version with Slang version 1.9.
    v1.7: Clean up. Optimize through precision specifiers and separate
          linearization.
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
#pragma parameter PIX_AA_SETTINGS "=== Pixel AA v1.10 settings ===" 0.0 0.0 1.0 1.0
#pragma parameter PIX_AA_SHARP "Pixel AA sharpening amount" 1.5 0.0 2.0 0.05
#pragma parameter PIX_AA_SUBPX "Enable subpixel AA" 0.0 0.0 1.0 1.0
#pragma parameter PIX_AA_SUBPX_ORIENTATION "Subpixel layout (0=RGB, 1=RGB vert., 2=BGR, 3=BGR vert.)" 0.0 0.0 3.0 1.0
// clang-format on

#ifdef GL_ES
#define PREC_LOW lowp
#define PREC_MED mediump
#define PREC_HIGH highp
#else
#define PREC_LOW
#define PREC_MED
#define PREC_HIGH
#endif

#if defined(VERTEX)

uniform PREC_HIGH mat4 MVPMatrix;
uniform PREC_HIGH vec2 TextureSize;
uniform PREC_HIGH vec2 InputSize;
uniform PREC_HIGH vec2 OutputSize;
uniform PREC_LOW int Rotation;

uniform PREC_MED float PIX_AA_SHARP;
uniform PREC_MED float PIX_AA_SUBPX_ORIENTATION;

in PREC_HIGH vec4 VertexCoord;
in PREC_HIGH vec4 TexCoord;

out PREC_HIGH vec2 tx_coord;
out PREC_MED vec2 tx_to_uv;
out PREC_MED vec2 trans_lb;
out PREC_MED vec2 trans_ub;
out PREC_MED vec2 sub_tx_offset;
out PREC_MED float trans_slope;

void calculate_pixel_aa_params(PREC_MED vec2 tx_per_px, PREC_MED float sharpness,
                               PREC_LOW int subpx_orientation, PREC_LOW int rotation,
                               inout PREC_MED vec2 trans_lb, inout PREC_MED vec2 trans_ub,
                               inout PREC_MED float trans_slope,
                               inout PREC_MED vec2 sub_tx_offset) {
    PREC_MED float sharpness_upper = min(1.0, sharpness);
    trans_lb = sharpness_upper * (0.5 - 0.5 * tx_per_px);
    trans_ub = 1.0 - sharpness_upper * (1.0 - (0.5 + 0.5 * tx_per_px));
    trans_slope = max(1.0, sharpness);

    // Subpixel sampling: Shift the sampling by 1/3rd of an output pixel for
    // each subpixel, assuming that the output size is at monitor
    // resolution.
    // Compensate for possible rotation of the screen in certain cores.
    const PREC_MED vec4 rot_corr = vec4(1.0, 0.0, -1.0, 0.0);
    sub_tx_offset = tx_per_px / 3.0 *
                    vec2(rot_corr[(rotation + subpx_orientation) % 4],
                         rot_corr[(rotation + subpx_orientation + 3) % 4]);
}

void main() {
    gl_Position = MVPMatrix * VertexCoord;
    tx_coord = TexCoord.xy * TextureSize;
    tx_to_uv = 1.0 / TextureSize;

    calculate_pixel_aa_params(InputSize / OutputSize, PIX_AA_SHARP, int(PIX_AA_SUBPX_ORIENTATION),
                              Rotation, trans_lb, trans_ub, trans_slope, sub_tx_offset);
}

#elif defined(FRAGMENT)

#ifdef GL_ES
#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif
#endif

uniform PREC_LOW sampler2D Texture;

uniform PREC_LOW float PIX_AA_SUBPX;

in PREC_HIGH vec2 tx_coord;
in PREC_MED vec2 tx_to_uv;
in PREC_MED vec2 trans_lb;
in PREC_MED vec2 trans_ub;
in PREC_MED vec2 sub_tx_offset;
in PREC_MED float trans_slope;

out PREC_LOW vec4 FragColor;

// Similar to smoothstep, but has a configurable slope at x = 0.5.
// Original smoothstep has a slope of 1.5 at x = 0.5
PREC_MED vec2 slopestep(PREC_MED vec2 edge0, PREC_MED vec2 edge1, PREC_MED vec2 x,
                        PREC_MED float slope) {
    x = clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0);
    vec2 s = sign(x - 0.5);
    vec2 o = (1.0 + s) * 0.5;
    return o - 0.5 * s * pow(2.0 * (o - s * x), vec2(slope));
}

PREC_LOW vec3 pixel_aa(PREC_LOW sampler2D tex, PREC_HIGH vec2 tx_coord, PREC_MED vec2 tx_to_uv,
                       PREC_MED vec2 trans_lb, PREC_MED vec2 trans_ub, PREC_MED float trans_slope) {
    PREC_MED vec2 period = floor(tx_coord - 0.5);
    PREC_MED vec2 phase = tx_coord - 0.5 - period;

    PREC_MED vec2 offset = slopestep(trans_lb, trans_ub, phase, trans_slope);

    return texture(tex, (period + 0.5 + offset) * tx_to_uv).rgb;
}

PREC_LOW vec3 pixel_aa_subpx(PREC_LOW sampler2D tex, PREC_HIGH vec2 tx_coord,
                             PREC_MED vec2 sub_tx_offset, PREC_MED vec2 tx_to_uv,
                             PREC_MED vec2 trans_lb, PREC_MED vec2 trans_ub,
                             PREC_MED float trans_slope) {
    PREC_LOW vec3 res;
    PREC_MED vec2 period, phase, offset;

    // Red
    period = floor(tx_coord - sub_tx_offset - 0.5);
    phase = tx_coord - sub_tx_offset - 0.5 - period;
    offset = slopestep(trans_lb, trans_ub, phase, trans_slope);
    res.r = texture(tex, (period + 0.5 + offset) * tx_to_uv).r;
    // Green
    period = floor(tx_coord - 0.5);
    phase = tx_coord - 0.5 - period;
    offset = slopestep(trans_lb, trans_ub, phase, trans_slope);
    res.g = texture(tex, (period + 0.5 + offset) * tx_to_uv).g;
    // Blue
    period = floor(tx_coord + sub_tx_offset - 0.5);
    phase = tx_coord + sub_tx_offset - 0.5 - period;
    offset = slopestep(trans_lb, trans_ub, phase, trans_slope);
    res.b = texture(tex, (period + 0.5 + offset) * tx_to_uv).b;

    return res;
}

void main() {
    FragColor.rgb = PIX_AA_SUBPX < 0.5
                        ? pixel_aa(Texture, tx_coord, tx_to_uv, trans_lb, trans_ub, trans_slope)
                        : pixel_aa_subpx(Texture, tx_coord, sub_tx_offset, tx_to_uv, trans_lb,
                                         trans_ub, trans_slope);
    FragColor.rgb = pow(FragColor.rgb, vec3(1.0 / 2.2));
}

#endif
