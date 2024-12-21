#version 130

// See main shader file for copyright and other information.

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

PREC_MED vec2 slopestep(PREC_MED vec2 edge0, PREC_MED vec2 edge1, PREC_MED vec2 x,
                        PREC_MED float slope) {
    x = clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0);
    vec2 s = sign(x - 0.5);
    vec2 o = (1.0 + s) * 0.5;
    return o - 0.5 * s * pow(2.0 * (o - s * x), vec2(slope));
}

PREC_LOW vec3 pixel_aa(PREC_LOW sampler2D tex, PREC_MED vec2 tx_per_px, PREC_MED vec2 tx_to_uv,
                       PREC_MED vec2 tx_coord, PREC_MED float sharpness, bool sample_subpx,
                       PREC_LOW int subpx_orientation, PREC_LOW int screen_rotation) {
    PREC_MED float sharpness_upper = min(1.0, sharpness);
    PREC_MED vec2 sharp_lb = sharpness_upper * (0.5 - 0.5 * tx_per_px);
    PREC_MED vec2 sharp_ub = 1.0 - sharpness_upper * (1.0 - (0.5 + 0.5 * tx_per_px));
    PREC_MED float sharpness_lower = max(1.0, sharpness);

    PREC_MED vec2 period, phase, offset;
    if (sample_subpx) {
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
        period = floor(tx_coord - 0.5);
        phase = tx_coord - 0.5 - period;

        offset = slopestep(sharp_lb, sharp_ub, phase, sharpness_lower);

        return texture(tex, (period + 0.5 + offset) * tx_to_uv).rgb;
    }
}

void main() {
    FragColor.rgb = pixel_aa(Texture, tx_per_px, tx_to_uv, tx_coord, PIX_AA_SHARP,
                             PIX_AA_SUBPX > 0.5, int(PIX_AA_SUBPX_ORIENTATION), Rotation);
}

#endif
