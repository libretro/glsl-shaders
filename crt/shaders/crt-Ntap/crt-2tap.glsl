/*
    crt-2tap v1.0 by fishku
    Copyright (C) 2023-2026
    Public domain license (CC0)

    Lightweight dynamic scanline shader with exact vertical box filtering.

    Horizontal interpolation uses two neighboring texels from each source row
    through a single bilinear tap. A normalized smooth-sign function transforms
    the interpolation coordinate. Sampled colors are squared before vertical
    filtering and square-root encoded afterwards to approximate linear-light
    blending without an extra pass.

    Each output pixel is treated as a box in source-texel space. The two rows
    surrounding its center are sampled separately. Each row's color and beam
    pattern are extended periodically through the half-space on its side of
    their shared boundary, then integrated analytically over the box.
*/

// clang-format off
#pragma parameter CRT2TAP_SETTINGS "=== CRT-2tap v1.0 settings ===" 0.0 0.0 1.0 1.0
#pragma parameter MIN_THICK "Scanline thickness of dark pixels" 0.1 0.0 1.2 0.05
#pragma parameter MAX_THICK "Scanline thickness of bright pixels" 0.95 0.0 1.2 0.05
#pragma parameter H_SMOOTH "Horizontal smoothing" 0.8 0.0 1.0 0.05
#pragma parameter V_SMOOTH "Vertical smoothing" 1.0 0.5 4.0 0.05
#pragma parameter SUBPX_POS "Scanline subpixel position" 0.0 -0.5 0.5 0.01
#pragma parameter THICK_FALLOFF "Reduction / increase of thinner scanlines" 0.45 0.2 2.0 0.05
// clang-format on

#ifdef GL_ES
#define PREC_HIGH highp
#define PREC_MED mediump
#else
#define PREC_HIGH
#define PREC_MED
#endif

#if defined(VERTEX)

#if __VERSION__ >= 130
#define COMPAT_ATTRIBUTE in
#define COMPAT_VARYING out
#else
#define COMPAT_ATTRIBUTE attribute
#define COMPAT_VARYING varying
#endif

COMPAT_ATTRIBUTE PREC_HIGH vec4 VertexCoord;
COMPAT_ATTRIBUTE PREC_HIGH vec4 TexCoord;
COMPAT_VARYING PREC_HIGH vec4 TEX0;

uniform PREC_HIGH mat4 MVPMatrix;
uniform PREC_HIGH vec2 OrigInputSize;
uniform PREC_HIGH vec2 TextureSize;
uniform PREC_HIGH vec2 InputSize;

#ifdef PARAMETER_UNIFORM
uniform PREC_MED float SUBPX_POS;
#else
#define SUBPX_POS 0.0
#endif

void main() {
    gl_Position = MVPMatrix * VertexCoord;
    PREC_HIGH vec2 normalized_coord = TexCoord.xy * TextureSize / InputSize;
    TEX0.xy = normalized_coord * OrigInputSize - vec2(0.5, SUBPX_POS);
    TEX0.zw = InputSize / (TextureSize * OrigInputSize);
}

#elif defined(FRAGMENT)

#if __VERSION__ >= 130
#define COMPAT_VARYING in
#define COMPAT_TEXTURE texture
out vec4 FragColor;
#else
#define COMPAT_VARYING varying
#define COMPAT_TEXTURE texture2D
#define FragColor gl_FragColor
#endif

#ifdef GL_ES
#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#undef PREC_HIGH
#define PREC_HIGH mediump
#endif
#endif

COMPAT_VARYING PREC_HIGH vec4 TEX0;

uniform PREC_HIGH vec2 OrigInputSize;
uniform PREC_HIGH vec2 OutputSize;
uniform sampler2D Texture;

#ifdef PARAMETER_UNIFORM
uniform PREC_MED float MIN_THICK;
uniform PREC_MED float MAX_THICK;
uniform PREC_MED float H_SMOOTH;
uniform PREC_MED float V_SMOOTH;
uniform PREC_MED float THICK_FALLOFF;
#else
#define MIN_THICK 0.1
#define MAX_THICK 0.95
#define H_SMOOTH 0.8
#define V_SMOOTH 1.0
#define THICK_FALLOFF 0.45
#endif

PREC_HIGH vec3 get_beam_width(PREC_HIGH vec3 signal) {
    PREC_HIGH vec3 shaped_signal = pow(clamp(signal, 0.0, 1.0), vec3(THICK_FALLOFF));
    return min(mix(vec3(MIN_THICK), vec3(MAX_THICK), shaped_signal), vec3(1.0));
}

PREC_HIGH vec3 get_beam_prefix(PREC_HIGH float y, PREC_HIGH vec3 width) {
    PREC_HIGH float cell = floor(y);
    PREC_HIGH float phase = y - cell;
    return cell * width + clamp(vec3(phase - 0.5) + 0.5 * width, vec3(0.0), width);
}

PREC_HIGH float get_sample_x(PREC_HIGH float src_x, PREC_HIGH float tx_to_uv_x) {
    PREC_HIGH float src_x_int = floor(src_x);
    PREC_HIGH float src_x_fract = src_x - src_x_int;
    PREC_HIGH float h_slope = mix(6.0, 1.0, H_SMOOTH);
    PREC_HIGH float x = 2.0 * src_x_fract - 1.0;
    PREC_HIGH float src_x_offset =
        0.5 + 0.5 * h_slope * x * inversesqrt(1.0 + (h_slope * h_slope - 1.0) * x * x);
    return (src_x_int + src_x_offset + 0.5) * tx_to_uv_x;
}

void main() {
    PREC_HIGH vec2 src_coord = TEX0.xy;
    PREC_HIGH vec2 tx_to_uv = TEX0.zw;
    PREC_HIGH float sample_x = get_sample_x(src_coord.x, tx_to_uv.x);

    PREC_HIGH float src_y = src_coord.y;
    PREC_HIGH float row0 = floor(src_y - 0.5);
    PREC_HIGH float row1 = row0 + 1.0;
    PREC_HIGH float row0_center = row0 + 0.5;
    PREC_HIGH float sample_y0 = row0_center * tx_to_uv.y;
    PREC_HIGH float sample_y1 = sample_y0 + tx_to_uv.y;

    PREC_HIGH vec3 signal0 = COMPAT_TEXTURE(Texture, vec2(sample_x, sample_y0)).rgb;
    PREC_HIGH vec3 signal1 = COMPAT_TEXTURE(Texture, vec2(sample_x, sample_y1)).rgb;
    PREC_HIGH vec3 linear0 = signal0 * signal0;
    PREC_HIGH vec3 linear1 = signal1 * signal1;

    PREC_HIGH float filter_height = OrigInputSize.y / OutputSize.y * V_SMOOTH;
    PREC_HIGH float inv_filter_height = 1.0 / filter_height;
    PREC_HIGH float pixel_lb = src_y - 0.5 * filter_height;
    PREC_HIGH float pixel_ub = src_y + 0.5 * filter_height;

    PREC_HIGH vec3 width0 = get_beam_width(signal0);
    PREC_HIGH vec3 width1 = get_beam_width(signal1);
    PREC_HIGH float boundary = row0_center + 0.5;
    PREC_HIGH float split = clamp(boundary, pixel_lb, pixel_ub);
    PREC_HIGH vec3 area0 = get_beam_prefix(split, width0) - get_beam_prefix(pixel_lb, width0);
    PREC_HIGH vec3 area1 = get_beam_prefix(pixel_ub, width1) - get_beam_prefix(split, width1);

    FragColor.rgb = sqrt((linear0 * area0 + linear1 * area1) * inv_filter_height);
}

#endif
