#version 130

// See the main shader file for copyright and other information.

// clang-format off
#pragma parameter AUTH_GBC_SETTINGS "=== Authentic GBC v2.2 settings ===" 0.0 0.0 1.0 1.0
#pragma parameter AUTH_GBC_BRIG "Add brightness" 0.6 0.0 1.0 0.05
#pragma parameter AUTH_GBC_BLUR "Anti-banding smoothing" 0.3 0.0 1.0 0.05
#pragma parameter AUTH_GBC_SUBPX "Enable subpixel rendering" 0.0 0.0 1.0 1.0
#pragma parameter AUTH_GBC_SUBPX_ORIENTATION "Subpixel layout (0=RGB, 1=RGB vert., 2=BGR, 3=BGR vert.)" 0.0 0.0 3.0 1.0
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
uniform PREC_HIGH vec2 OrigInputSize;
uniform PREC_HIGH vec2 TextureSize;
uniform PREC_HIGH vec2 InputSize;
uniform PREC_HIGH vec2 OutputSize;
uniform PREC_LOW int Rotation;

uniform PREC_MED float AUTH_GBC_BRIG;
uniform PREC_MED float AUTH_GBC_BLUR;
uniform PREC_MED float AUTH_GBC_SUBPX;
uniform PREC_MED float AUTH_GBC_SUBPX_ORIENTATION;

in PREC_HIGH vec4 VertexCoord;
in PREC_HIGH vec4 TexCoord;

out PREC_MED vec4 lcd_subpx_rect1;
out PREC_MED vec4 lcd_subpx_rect2;
out PREC_HIGH vec2 tx_coord;
out PREC_MED vec2 subpx_offset_in_px;
out PREC_MED vec2 tx_to_px;
out PREC_MED vec2 tx_to_uv;
out PREC_MED vec2 tx_orig_offs;
out PREC_MED float eff_blur_in_px;

void calculate_lcd_params(PREC_HIGH vec2 source_size, PREC_HIGH vec2 output_size,
                          PREC_LOW int rotation, PREC_MED float use_subpx,
                          PREC_LOW int subpx_orientation, PREC_MED float brightness_boost,
                          PREC_HIGH vec2 tex_coord, inout PREC_MED vec4 lcd_subpx_rect1,
                          inout PREC_MED vec4 lcd_subpx_rect2,
                          inout PREC_MED vec2 subpx_offset_in_px, inout PREC_MED vec2 tx_coord,
                          inout PREC_MED vec2 tx_to_px, inout PREC_MED vec2 tx_orig_offs) {
    const PREC_MED vec4 rot_corr = vec4(1.0, 0.0, -1.0, 0.0);
    subpx_offset_in_px = use_subpx / 3.0 *
                         vec2(rot_corr[(rotation + subpx_orientation) % 4],
                              rot_corr[(rotation + subpx_orientation + 3) % 4]);

    tx_coord = tex_coord * source_size;
    tx_to_px = output_size / source_size;

    // As determined by counting pixels on a photo.
    const PREC_MED vec2 subpx_ratio = vec2(0.296, 0.910);
    const PREC_MED vec2 notch_ratio = vec2(0.115, 0.166);

    // Scale the subpixel and notch sizes with the brightness parameter.
    // The maximally bright numbers are chosen manually.
    PREC_MED vec2 lcd_subpx_size_in_px =
        tx_to_px * mix(subpx_ratio, vec2(0.75, 0.93), brightness_boost);
    PREC_MED vec2 notch_size_in_px =
        tx_to_px * mix(notch_ratio, vec2(0.29, 0.17), brightness_boost);
    lcd_subpx_rect1 = vec4(vec2(0.0), lcd_subpx_size_in_px - vec2(0.0, notch_size_in_px.y));
    lcd_subpx_rect2 =
        vec4(notch_size_in_px.x, lcd_subpx_size_in_px.y - notch_size_in_px.y, lcd_subpx_size_in_px);

    tx_orig_offs = (tx_to_px - lcd_subpx_size_in_px) * 0.5;
}

void main() {
    gl_Position = MVPMatrix * VertexCoord;

    // Given coordinates in original "LCD" texel coord. system, multiply by this to get UV in
    // [0, 1] to sample from source pass.
    tx_to_uv = 1.0 / OrigInputSize * InputSize / TextureSize;

    calculate_lcd_params(OrigInputSize, OutputSize, Rotation, AUTH_GBC_SUBPX,
                         int(AUTH_GBC_SUBPX_ORIENTATION), AUTH_GBC_BRIG,
                         TexCoord.xy * TextureSize / InputSize, lcd_subpx_rect1, lcd_subpx_rect2,
                         subpx_offset_in_px, tx_coord, tx_to_px, tx_orig_offs);

    // Blur strength is isotropic, so use the dimension that is most limiting.
    eff_blur_in_px = AUTH_GBC_BLUR * min(tx_to_px.x, tx_to_px.y) * 0.5;
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

in PREC_MED vec4 lcd_subpx_rect1;
in PREC_MED vec4 lcd_subpx_rect2;
in PREC_HIGH vec2 tx_coord;
in PREC_MED vec2 subpx_offset_in_px;
in PREC_MED vec2 tx_to_px;
in PREC_MED vec2 tx_to_uv;
in PREC_MED vec2 tx_orig_offs;
in PREC_MED float eff_blur_in_px;

out PREC_LOW vec4 FragColor;

PREC_MED float intersect_blurred_rect_area(PREC_MED vec4 px_square, PREC_MED vec4 rect,
                                           PREC_MED float blur) {
    PREC_MED vec4 range = (rect.zw - rect.xy).xyxy;
    PREC_MED vec4 linear = clamp(px_square - rect.xyxy, vec4(0.0), range);

    // Early out: If blur is very small, return perfectly sharp rectangle intersection area.
    if (blur < 1.0e-6) {
        return (linear.z - linear.x) * (linear.w - linear.y);
    }

    PREC_MED vec4 center = (0.5 * (rect.xy + rect.zw)).xyxy;
    PREC_MED vec4 dist_to_center = abs(px_square - center);
    PREC_MED vec4 blur_vec = vec4(blur);

    PREC_MED vec4 x_n =
        max(0.5 * (max(range, blur_vec) + blur_vec) - dist_to_center, vec4(0.0)) / blur_vec;
    // Quartic polynomial fit to function:
    // x / 2 + exp(-x ^ 2 / 2) / sqrt(2 * pi) + x / 2 * erf(x / sqrt(2));
    // Subject to y(0) = 0, y'(0) = 0, y(1) = 1/2, y'(1) = 1
    const PREC_MED vec3 c = vec3(-0.3635, 0.727, 0.1365);
    PREC_MED vec4 x_n2 = x_n * x_n;
    PREC_MED vec4 poly = (c.xxxx * x_n2 + c.yyyy * x_n + c.zzzz) * x_n2 * min(range, blur_vec);
    // Exploit point symmetry around center
    PREC_MED vec4 transition = mix(poly, range - poly, step(center, px_square));

    // Determine if we are in the linear or transitional part.
    PREC_MED vec4 res = mix(linear, transition, step(0.5 * (range - blur_vec), dist_to_center));
    return (res.z - res.x) * (res.w - res.y);
}

PREC_MED float subpx_coverage(PREC_MED vec4 px_square, PREC_MED vec2 subpx_orig) {
    // To render the "notch" present in the original subpixels, compose two rectangles.
    return intersect_blurred_rect_area(px_square, subpx_orig.xyxy + lcd_subpx_rect1,
                                       eff_blur_in_px) +
           intersect_blurred_rect_area(px_square, subpx_orig.xyxy + lcd_subpx_rect2,
                                       eff_blur_in_px);
}

PREC_MED vec3 pixel_color(PREC_MED vec2 tx_orig) {
    return vec3(subpx_coverage(vec4(-subpx_offset_in_px - 0.5, -subpx_offset_in_px + 0.5),
                               tx_orig + vec2(tx_orig_offs.x - tx_to_px.x / 3.0, tx_orig_offs.y)),
                subpx_coverage(vec4(vec2(-0.5), vec2(0.5)), tx_orig + tx_orig_offs),
                subpx_coverage(vec4(subpx_offset_in_px - 0.5, subpx_offset_in_px + 0.5),
                               tx_orig + vec2(tx_orig_offs.x + tx_to_px.x / 3.0, tx_orig_offs.y)));
}

void main() {
    // Figure out four nearest texels in source texture and sample them.
    PREC_MED vec2 tx_coord_i;
    PREC_MED vec2 tx_coord_f = modf(tx_coord, tx_coord_i);
    PREC_MED vec2 tx_coord_off = step(vec2(0.5), tx_coord_f) * 2.0 - 1.0;
    PREC_MED vec2 tx_coord_offs[4] =
        vec2[](vec2(0.0), vec2(tx_coord_off.x, 0.0), vec2(0.0, tx_coord_off.y), tx_coord_off);

    PREC_LOW vec3 samples[4] =
        vec3[](texture(Texture, (tx_coord_i + tx_coord_offs[0] + 0.5) * tx_to_uv).rgb,
               texture(Texture, (tx_coord_i + tx_coord_offs[1] + 0.5) * tx_to_uv).rgb,
               texture(Texture, (tx_coord_i + tx_coord_offs[2] + 0.5) * tx_to_uv).rgb,
               texture(Texture, (tx_coord_i + tx_coord_offs[3] + 0.5) * tx_to_uv).rgb);

    // Single pass version: Apply linearization.
    samples[0] = pow(samples[0], vec3(2.2));
    samples[1] = pow(samples[1], vec3(2.2));
    samples[2] = pow(samples[2], vec3(2.2));
    samples[3] = pow(samples[3], vec3(2.2));

    // The four nearest texels define a set of vector graphics which are rasterized.
    // The coordinate origin is shifted to px_coord = tx_coord * tx_to_px.
    PREC_LOW vec3 res = pixel_color((tx_coord_offs[0] - tx_coord_f) * tx_to_px) * samples[0] +
                        pixel_color((tx_coord_offs[1] - tx_coord_f) * tx_to_px) * samples[1] +
                        pixel_color((tx_coord_offs[2] - tx_coord_f) * tx_to_px) * samples[2] +
                        pixel_color((tx_coord_offs[3] - tx_coord_f) * tx_to_px) * samples[3];

    FragColor = vec4(pow(res, vec3(1.0 / 2.2)), 1.0);
}

#endif
