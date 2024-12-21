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
#pragma parameter PIX_AA_SETTINGS "=== Pixel AA v1.7 settings ===" 0.0 0.0 1.0 1.0
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

uniform PREC_MED mat4 MVPMatrix;
uniform PREC_MED vec2 OutputSize;
uniform PREC_MED vec2 TextureSize;
uniform PREC_MED vec2 InputSize;

in PREC_MED vec4 VertexCoord;
in PREC_MED vec4 TexCoord;

out PREC_MED vec2 tx_coord;
out PREC_MED vec2 tx_per_px;
out PREC_MED vec2 tx_to_uv;

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
#endif

uniform PREC_LOW int Rotation;
uniform PREC_LOW sampler2D Texture;

uniform PREC_MED float PIX_AA_SHARP;
uniform PREC_LOW float PIX_AA_GAMMA;
uniform PREC_LOW float PIX_AA_SUBPX;
uniform PREC_MED float PIX_AA_SUBPX_ORIENTATION;

in PREC_MED vec2 tx_coord;
in PREC_MED vec2 tx_per_px;
in PREC_MED vec2 tx_to_uv;

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

// Function to get a pixel value, taking into consideration possible subpixel
// interpolation.
PREC_LOW vec3 pixel_aa(PREC_LOW sampler2D tex, PREC_MED vec2 tx_per_px, PREC_MED vec2 tx_to_uv,
                       PREC_MED vec2 tx_coord, PREC_MED float sharpness, bool sample_subpx,
                       PREC_LOW int subpx_orientation, PREC_LOW int screen_rotation) {
    PREC_MED float sharpness_upper = min(1.0, sharpness);
    PREC_MED vec2 sharp_lb = sharpness_upper * (0.5 - 0.5 * tx_per_px);
    PREC_MED vec2 sharp_ub = 1.0 - sharpness_upper * (1.0 - (0.5 + 0.5 * tx_per_px));
    PREC_MED float sharpness_lower = max(1.0, sharpness);

    PREC_MED vec2 period, phase, offset;
    if (sample_subpx) {
        // Subpixel sampling: Shift the sampling by 1/3rd of an output pixel for
        // each subpixel, assuming that the output size is at monitor
        // resolution.
        // Compensate for possible rotation of the screen in certain cores.
        const vec4 rot_corr = vec4(1.0, 0.0, -1.0, 0.0);
        PREC_MED vec2 sub_tx_offset = tx_per_px / 3.0 *
                                      vec2(rot_corr[(screen_rotation + subpx_orientation) % 4],
                                           rot_corr[(screen_rotation + subpx_orientation + 3) % 4]);

        PREC_LOW vec3 res;

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

        return res;
    } else {
        // The offset for interpolation is a periodic function with
        // a period length of 1 texel.
        // The input coordinate is shifted so that the center of the texel
        // aligns with the start of the period.
        // First, get the period and phase.
        period = floor(tx_coord - 0.5);
        phase = tx_coord - 0.5 - period;
        // The function starts at 0, then starts transitioning at
        // 0.5 - 0.5 / pixels_per_texel, then reaches 0.5 at 0.5,
        // Then reaches 1 at 0.5 + 0.5 / pixels_per_texel.
        // For sharpness values < 1.0, blend to bilinear filtering.
        offset = slopestep(sharp_lb, sharp_ub, phase, sharpness_lower);

        // When the input is in linear color space, we can make use of a single tap
        // using bilinear interpolation. The offsets are shifted back to the texel
        // center before sampling.
        return texture(tex, (period + 0.5 + offset) * tx_to_uv).rgb;
    }
}

void main() {
    FragColor.rgb = pow(pixel_aa(Texture, tx_per_px, tx_to_uv, tx_coord, PIX_AA_SHARP,
                                 PIX_AA_SUBPX > 0.5, int(PIX_AA_SUBPX_ORIENTATION), Rotation),
                        vec3(1.0 / 2.2));
}

#endif
