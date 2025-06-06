#version 130

/*
    This is a port of the Slang pixel_aa_xform shader to GLSL.
    See the main shader file for copyright and other information.

    Based on the input transformation library v1.4 by fishku (inlined).
*/

// clang-format off
// Pixel AA parameters
#pragma parameter PIX_AA_SETTINGS "=== Pixel AA v1.10 settings ===" 0.0 0.0 1.0 1.0
#pragma parameter PIX_AA_SHARP "Pixel AA sharpening amount" 1.5 0.0 2.0 0.05
#pragma parameter PIX_AA_SUBPX "Enable subpixel AA" 0.0 0.0 1.0 1.0
#pragma parameter PIX_AA_SUBPX_ORIENTATION "Subpixel layout (0=RGB, 1=RGB vert., 2=BGR, 3=BGR vert.)" 0.0 0.0 3.0 1.0

// Scaling parameters
#pragma parameter SCALING_SETTINGS "= Scaling parameters =" 0.0 0.0 1.0 1.0
#pragma parameter FORCE_ASPECT_RATIO "Force aspect ratio" 1.0 0.0 1.0 1.0
#pragma parameter ASPECT_H "Horizontal aspect ratio before crop (0 = unchanged)" 0.0 0.0 256.0 1.0
#pragma parameter ASPECT_V "Vertical aspect ratio before crop (0 = unchanged)" 0.0 0.0 256.0 1.0
#pragma parameter FORCE_INTEGER_SCALING_H "Force integer scaling horizontally" 0.0 0.0 1.0 1.0
#pragma parameter FORCE_INTEGER_SCALING_V "Force integer scaling vertically" 0.0 0.0 1.0 1.0
#pragma parameter OVERSCALE "Overscale (0 = full image, 1 = full screen)" 0.0 -4.0 8.0 0.05

// Cropping parameters
#pragma parameter CROPPING_SETTINGS "= Cropping parameters =" 0.0 0.0 1.0 1.0
#pragma parameter OS_CROP_TOP "Overscan crop top" 0.0 0.0 1024.0 1.0
#pragma parameter OS_CROP_BOTTOM "Overscan crop bottom" 0.0 0.0 1024.0 1.0
#pragma parameter OS_CROP_LEFT "Overscan crop left" 0.0 0.0 1024.0 1.0
#pragma parameter OS_CROP_RIGHT "Overscan crop right" 0.0 0.0 1024.0 1.0

// Moving parameters
#pragma parameter MOVING_SETTINGS "= Moving parameters =" 0.0 0.0 1.0 1.0
#pragma parameter SHIFT_H "Horizontal shift" 0.0 -2048.0 2048.0 1.0
#pragma parameter SHIFT_V "Vertical shift" 0.0 -2048.0 2048.0 1.0
#pragma parameter CENTER_AFTER_CROPPING "Center cropped area" 1.0 0.0 1.0 1.0
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
uniform PREC_HIGH vec2 OrigTextureSize;
uniform PREC_HIGH vec2 InputSize;
uniform PREC_HIGH vec2 TextureSize;
uniform PREC_HIGH vec2 OutputSize;
uniform PREC_LOW int Rotation;

// Pixel AA parameters
uniform PREC_MED float PIX_AA_SHARP;
uniform PREC_LOW float PIX_AA_SUBPX;
uniform PREC_MED float PIX_AA_SUBPX_ORIENTATION;

// Input transform parameters - scaling section
uniform PREC_LOW float FORCE_ASPECT_RATIO;
uniform PREC_HIGH float ASPECT_H;
uniform PREC_HIGH float ASPECT_V;
uniform PREC_LOW float FORCE_INTEGER_SCALING_H;
uniform PREC_LOW float FORCE_INTEGER_SCALING_V;
uniform PREC_MED float OVERSCALE;

// Input transform parameters - cropping section
uniform PREC_HIGH float OS_CROP_TOP;
uniform PREC_HIGH float OS_CROP_BOTTOM;
uniform PREC_HIGH float OS_CROP_LEFT;
uniform PREC_HIGH float OS_CROP_RIGHT;

// Input transform parameters - moving section
uniform PREC_HIGH float SHIFT_H;
uniform PREC_HIGH float SHIFT_V;
uniform PREC_LOW float CENTER_AFTER_CROPPING;

in PREC_HIGH vec4 VertexCoord;
in PREC_HIGH vec4 TexCoord;

out PREC_HIGH vec4 input_corners;
out PREC_HIGH vec2 tx_coord;
out PREC_MED vec2 tx_per_px;
out PREC_MED vec2 sub_tx_offset;
out PREC_MED vec2 trans_lb;
out PREC_MED vec2 trans_ub;
out PREC_MED float trans_slope;

// Rotation utility functions (from rotation.inc)
PREC_HIGH vec2 get_rotated_size(PREC_HIGH vec2 x, PREC_LOW int rotation) {
    if (rotation == 1 || rotation == 3) {
        return x.yx;
    }
    return x;
}

PREC_HIGH vec4 get_rotated_crop(PREC_HIGH vec4 crop, PREC_LOW int rotation) {
    if (rotation == 1) {
        return crop.yzwx;
    } else if (rotation == 2) {
        return crop.zwxy;
    } else if (rotation == 3) {
        return crop.wxyz;
    }
    return crop;
}

PREC_HIGH vec2 get_rotated_vector(PREC_HIGH vec2 x, PREC_LOW int rotation) {
    if (rotation == 1) {
        return vec2(-x.y, x.x);
    } else if (rotation == 2) {
        return -x;
    } else if (rotation == 3) {
        return vec2(x.y, -x.x);
    }
    return x;
}

// Get 2 corners of input in texel space, spanning the input image.
// corners.x and .y define the top-left corner, corners.z and .w define the
// bottom-right corner.
PREC_HIGH vec4 get_input_corners(PREC_HIGH vec2 input_size, PREC_HIGH vec4 crop,
                                 PREC_LOW int rotation) {
    crop = get_rotated_crop(crop, rotation);
    return vec4(crop.y, crop.x, input_size.x - crop.w, input_size.y - crop.z);
}

// Get adjusted center in input pixel (texel) coordinate system.
// Crop is in input pixels (texels).
// Shift is in output pixels.
PREC_HIGH vec2 get_input_center(PREC_HIGH vec2 input_size,
                                PREC_HIGH vec2 output_size,
                                PREC_MED vec2 scale_i2o, PREC_HIGH vec4 crop,
                                PREC_HIGH vec2 shift, PREC_LOW int rotation,
                                PREC_LOW float center_after_cropping) {
    crop = get_rotated_crop(crop, rotation);
    shift = get_rotated_vector(shift, rotation);
    // If input and output sizes have different parity, shift by 1/2 of an
    // output pixel to avoid having input pixel (texel) edges on output pixel
    // centers, which leads to all sorts of issues.
    return 0.5 * (input_size + center_after_cropping *
                                   vec2(crop.y - crop.w, crop.x - crop.z)) +
           (0.5 * mod(input_size + output_size, 2.0) - shift) / scale_i2o;
}

// Scaling from input to output space.
PREC_MED vec2 get_scale_i2o(
    PREC_HIGH vec2 input_size, PREC_HIGH vec2 output_size, PREC_HIGH vec4 crop,
    PREC_LOW int rotation, PREC_LOW float center_after_cropping,
    PREC_LOW float force_aspect_ratio, PREC_HIGH vec2 aspect,
    PREC_LOW vec2 force_integer_scaling, PREC_MED float overscale) {
    crop = get_rotated_crop(crop, rotation);
    aspect = get_rotated_size(aspect, rotation);
    // Aspect ratio before cropping.
    // Corrected for forced aspect ratio.
    aspect = (force_aspect_ratio < 0.5
                  ? output_size * input_size.yx
                  : (aspect.x < 0.5 || aspect.y < 0.5
                         ? vec2(1.0)
                         : vec2(aspect.x, aspect.y) * input_size.yx));
    // Pixels in input coord. space, after cropping.
    input_size = input_size -
                 (center_after_cropping > 0.5
                      ? vec2(crop.y + crop.w, crop.x + crop.z)
                      : 2.0 * vec2(min(crop.y, crop.w), min(crop.x, crop.z)));

    force_integer_scaling = get_rotated_size(force_integer_scaling, rotation);
    PREC_MED vec2 scale;
    if (output_size.x / (input_size.x * aspect.x) <
        output_size.y / (input_size.y * aspect.y)) {
        // Scale will be limited by width. Calc x scale, then derive y scale
        // using aspect ratio.
        scale.x = mix(output_size.x / input_size.x,
                      output_size.y * aspect.x / (input_size.y * aspect.y),
                      overscale);
        if (force_integer_scaling.x > 0.5 && scale.x > 1.0) {
            scale.x = floor(scale.x);
        }
        scale.y = scale.x * aspect.y / aspect.x;
        if (force_integer_scaling.y > 0.5 && scale.y > 1.0) {
            scale.y = floor(scale.y);
        }
    } else {
        // Scale will be limited by height.
        scale.y = mix(output_size.y / input_size.y,
                      output_size.x * aspect.y / (input_size.x * aspect.x),
                      overscale);
        if (force_integer_scaling.y > 0.5 && scale.y > 1.0) {
            scale.y = floor(scale.y);
        }
        scale.x = scale.y * aspect.x / aspect.y;
        if (force_integer_scaling.x > 0.5 && scale.x > 1.0) {
            scale.x = floor(scale.x);
        }
    }
    return scale;
}

PREC_HIGH vec2 transform(PREC_HIGH vec2 x, PREC_HIGH vec2 input_center,
                         PREC_MED vec2 scale, PREC_HIGH vec2 output_center) {
    return (x - input_center) * scale + output_center;
}

void main() {
    gl_Position = MVPMatrix * VertexCoord;

    PREC_HIGH vec4 crop =
        vec4(OS_CROP_TOP, OS_CROP_LEFT, OS_CROP_BOTTOM, OS_CROP_RIGHT);
    PREC_MED vec2 scale_i2o = get_scale_i2o(
        OrigInputSize, OutputSize, crop, Rotation, CENTER_AFTER_CROPPING,
        FORCE_ASPECT_RATIO, vec2(ASPECT_H, ASPECT_V),
        vec2(FORCE_INTEGER_SCALING_H, FORCE_INTEGER_SCALING_V), OVERSCALE);
    PREC_HIGH vec2 shift = vec2(SHIFT_H, SHIFT_V);
    PREC_HIGH vec2 input_center =
        get_input_center(OrigInputSize, OutputSize, scale_i2o, crop, shift,
                         Rotation, CENTER_AFTER_CROPPING);
    tx_coord = transform(TexCoord.xy * TextureSize / InputSize, vec2(0.5),
                         OutputSize / scale_i2o, input_center);
    tx_per_px = 1.0 / scale_i2o;
    input_corners = get_input_corners(OrigInputSize, crop, Rotation);

    // Pixel AA parameter calculation (inlined from shared.inc)
    PREC_MED float sharpness_upper = min(1.0, PIX_AA_SHARP);
    trans_lb = sharpness_upper * (0.5 - 0.5 * tx_per_px);
    trans_ub = 1.0 - sharpness_upper * (1.0 - (0.5 + 0.5 * tx_per_px));
    trans_slope = max(1.0, PIX_AA_SHARP);

    // Subpixel sampling: Shift the sampling by 1/3rd of an output pixel for
    // each subpixel, assuming that the output size is at monitor
    // resolution.
    // Compensate for possible rotation of the screen in certain cores.
    const PREC_MED vec4 rot_corr = vec4(1.0, 0.0, -1.0, 0.0);
    sub_tx_offset =
        tx_per_px / 3.0 *
        vec2(rot_corr[(Rotation + int(PIX_AA_SUBPX_ORIENTATION)) % 4],
             rot_corr[(Rotation + int(PIX_AA_SUBPX_ORIENTATION) + 3) % 4]);
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
uniform PREC_HIGH vec2 OrigTextureSize;
uniform PREC_LOW float PIX_AA_SUBPX;

in PREC_HIGH vec4 input_corners;
in PREC_HIGH vec2 tx_coord;
in PREC_MED vec2 tx_per_px;
in PREC_MED vec2 sub_tx_offset;
in PREC_MED vec2 trans_lb;
in PREC_MED vec2 trans_ub;
in PREC_MED float trans_slope;

out PREC_LOW vec4 FragColor;

// Returns y in [0, 1]
// l: lower center point of transition
// u: upper center point of transition
// s: transition width
PREC_MED vec2 trapezoid(PREC_HIGH vec2 x, PREC_HIGH vec2 l, PREC_HIGH vec2 u,
                        PREC_MED vec2 s) {
    return clamp((s + u - l - abs(2.0 * x - u - l)) / (2.0 * s), 0.0, 1.0);
}

// Similar to smoothstep, but has a configurable slope at x = 0.5.
// Original smoothstep has a slope of 1.5 at x = 0.5
PREC_MED vec2 slopestep(PREC_MED vec2 edge0, PREC_MED vec2 edge1,
                        PREC_MED vec2 x, PREC_MED float slope) {
    x = clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0);
    PREC_MED vec2 s = sign(x - 0.5);
    PREC_MED vec2 o = (1.0 + s) * 0.5;
    return o - 0.5 * s * pow(2.0 * (o - s * x), vec2(slope));
}

// Function to get a pixel value, taking into consideration possible subpixel
// interpolation.
PREC_LOW vec3 pixel_aa(PREC_LOW sampler2D tex, PREC_HIGH vec2 tx_coord,
                       PREC_MED vec2 tx_to_uv, PREC_MED vec2 trans_lb,
                       PREC_MED vec2 trans_ub, PREC_MED float trans_slope) {
    // The offset for interpolation is a periodic function with
    // a period length of 1 texel.
    // The input coordinate is shifted so that the center of the texel
    // aligns with the start of the period.
    // First, get the period and phase.
    PREC_MED vec2 period = floor(tx_coord - 0.5);
    PREC_MED vec2 phase = tx_coord - 0.5 - period;
    // The function starts at 0, then starts transitioning at
    // 0.5 - 0.5 / pixels_per_texel, then reaches 0.5 at 0.5,
    // Then reaches 1 at 0.5 + 0.5 / pixels_per_texel.
    // For sharpness values < 1.0, blend to bilinear filtering.
    PREC_MED vec2 offset = slopestep(trans_lb, trans_ub, phase, trans_slope);

    // When the input is in linear color space, we can make use of a single tap
    // using bilinear interpolation. The offsets are shifted back to the texel
    // center before sampling.
    return texture(tex, (period + 0.5 + offset) * tx_to_uv).rgb;
}

PREC_LOW vec3 pixel_aa_subpx(PREC_LOW sampler2D tex, PREC_HIGH vec2 tx_coord,
                             PREC_MED vec2 sub_tx_offset,
                             PREC_MED vec2 tx_to_uv, PREC_MED vec2 trans_lb,
                             PREC_MED vec2 trans_ub,
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
    PREC_MED vec2 tx_to_uv = 1.0 / OrigTextureSize;

    FragColor.rgb =
        PIX_AA_SUBPX < 0.5
            ? pixel_aa(Texture, tx_coord, tx_to_uv, trans_lb, trans_ub,
                       trans_slope)
            : pixel_aa_subpx(Texture, tx_coord, sub_tx_offset, tx_to_uv,
                             trans_lb, trans_ub, trans_slope);

    // Blend with background.
    PREC_MED vec2 w =
        trapezoid(tx_coord, input_corners.xy, input_corners.zw, tx_per_px);
    FragColor.rgb *= w.x * w.y;

    // Gamma correct output.
    FragColor.rgb = pow(FragColor.rgb, vec3(1.0 / 2.2));
}

#endif
