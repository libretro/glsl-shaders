#version 130

/*
    Blur fill v1.10 by fishku
    Copyright (C) 2023-2024
    Public domain license (CC0)

    This shader preset allows cropping the image on any side, and filling the
    cropped area with a blurred version of the input image borders.
    This is useful for certain games that do not render a full image to maintain
    the overall aspect ratio and to avoid burn-in.

    The preset also allows you to extend the original content to a larger
    screen. It's recommended to set the video scaling options as follows:
    - Turn integer scaling OFF
    - Set aspect ratio to FULL
    The shader will then take over and handle the proper scaling and aspect
    ratio of the input.

    The preset comes in three variants which differ only in the strength of the
    blur.
    Since the blur strength in the dual filter blur depends on the input
    resolution, and because there is currently no mechanism to set resolution
    based on user parameters, the three variants provide different sampling
    resolutions which affect the strength of the blur.
    Additionally to the resolution, a blur radius parameter controls the
    strength of the blur.

    Changelog:
    v1.10: Port from Slang to GLSL with minor optimizations.
    v1.9: Add shift option from input transform library.
    v1.8: Add overscale option from crop and scale library.
    v1.7: Refactor for new scaling library. Add rotation support.
    v1.6: Optimize. Update to new Pixel AA version. Tune default blur strength.
    v1.5: Add anti-aliased interpolation for non-integer scaling.
    v1.4: Fix scaling bugs.
    v1.3: Reduce shimmering artifacts.
    v1.2: Fix scaling bugs.
    v1.1: Fix bug with glcore driver.
    v1.0: Initial release.
*/

#if defined(VERTEX)

#if __VERSION__ >= 130
#define COMPAT_VARYING out
#define COMPAT_ATTRIBUTE in
#else
#define COMPAT_VARYING varying
#define COMPAT_ATTRIBUTE attribute
#endif

#ifdef GL_ES
#define COMPAT_PRECISION mediump
#else
#define COMPAT_PRECISION
#endif

COMPAT_ATTRIBUTE vec4 VertexCoord;
COMPAT_ATTRIBUTE vec4 TexCoord;
COMPAT_VARYING vec4 TEX0;

uniform mat4 MVPMatrix;

uniform COMPAT_PRECISION vec2 OrigInputSize;
uniform COMPAT_PRECISION vec2 OrigTextureSize;

uniform COMPAT_PRECISION vec2 InputSize;
uniform COMPAT_PRECISION vec2 TextureSize;

uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION int Rotation;

COMPAT_VARYING vec2 tx_coord;
COMPAT_VARYING vec2 tx_per_px;
COMPAT_VARYING vec2 tx_to_uv;
COMPAT_VARYING vec4 input_corners;

#ifdef PARAMETER_UNIFORM
// From input transform library, scaling section
uniform COMPAT_PRECISION float FORCE_ASPECT_RATIO;
uniform COMPAT_PRECISION float ASPECT_H;
uniform COMPAT_PRECISION float ASPECT_V;
uniform COMPAT_PRECISION float FORCE_INTEGER_SCALING_H;
uniform COMPAT_PRECISION float FORCE_INTEGER_SCALING_V;
uniform COMPAT_PRECISION float OVERSCALE;
// From input transform library, cropping section
uniform COMPAT_PRECISION float OS_CROP_TOP;
uniform COMPAT_PRECISION float OS_CROP_BOTTOM;
uniform COMPAT_PRECISION float OS_CROP_LEFT;
uniform COMPAT_PRECISION float OS_CROP_RIGHT;
// From input transform library, moving section
uniform COMPAT_PRECISION float SHIFT_H;
uniform COMPAT_PRECISION float SHIFT_V;
uniform COMPAT_PRECISION float CENTER_AFTER_CROPPING;
#else
#define WHATEVER 0.0
// TODO
#endif

/*
The following code is copied from:
    Input transformation library v1.2 by fishku

See the original file for a full description.
*/

vec2 get_rotated_size(vec2 x, int rotation) {
    switch (rotation) {
        case 0:
        case 2:
        default:
            return x;
        case 1:
        case 3:
            return x.yx;
    }
}

vec4 get_rotated_crop(vec4 crop, int rotation) {
    switch (rotation) {
        case 0:
        default:
            return crop;
        case 1:
            return crop.yzwx;
        case 2:
            return crop.zwxy;
        case 3:
            return crop.wxyz;
    }
}

vec2 get_rotated_vector(vec2 x, int rotation) {
    switch (rotation) {
        case 0:
        default:
            return x;
        case 1:
            return vec2(-x.y, x.x);
        case 2:
            return -x;
        case 3:
            return vec2(x.y, -x.x);
    }
}

// Get 2 corners of input in texel space, spanning the input image.
// corners.x and .y define the top-left corner, corners.z and .w define the
// bottom-right corner.
vec4 get_input_corners(vec2 input_size, vec4 crop, int rotation) {
    crop = get_rotated_crop(crop, rotation);
    return vec4(crop.y, crop.x, input_size.x - crop.w, input_size.y - crop.z);
}

// Get adjusted center in input pixel coordinate system.
vec2 get_input_center(vec2 input_size, vec4 crop, vec2 shift, int rotation,
                      float center_after_cropping) {
    crop = get_rotated_crop(crop, rotation);
    shift = get_rotated_vector(shift, rotation);
    return (center_after_cropping > 0.5
                ? 0.5 * vec2(crop.y + input_size.x - crop.w,
                             crop.x + input_size.y - crop.z)
                : vec2(0.49999) * input_size) -
           shift;
}

// Scaling from unit output to pixel input space.
vec2 get_scale_o2i(vec2 input_size, vec2 output_size, vec4 crop, int rotation,
                   float center_after_cropping, float force_aspect_ratio,
                   vec2 aspect, vec2 force_integer_scaling, float overscale,
                   bool output_size_is_final_viewport_size) {
    crop = get_rotated_crop(crop, rotation);
    if (output_size_is_final_viewport_size) {
        output_size = get_rotated_size(output_size, rotation);
    }
    aspect = get_rotated_size(aspect, rotation);
    // Aspect ratio before cropping.
    // lambda_1 * input_pixels.x, lambda_2 * input_pixels.y,
    // possibly corrected for forced aspect ratio
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
    float scale_x, scale_y;
    if (output_size.x / (input_size.x * aspect.x) <
        output_size.y / (input_size.y * aspect.y)) {
        // Scale will be limited by width. Calc x scale, then derive y scale
        // using aspect ratio.
        scale_x = mix(output_size.x / input_size.x,
                      output_size.y * aspect.x / (input_size.y * aspect.y),
                      overscale);
        if (force_integer_scaling.x > 0.5 && scale_x > 1.0) {
            scale_x = floor(scale_x);
        }
        scale_y = scale_x * aspect.y / aspect.x;
        if (force_integer_scaling.y > 0.5 && scale_y > 1.0) {
            scale_y = floor(scale_y);
        }
    } else {
        // Scale will be limited by height.
        scale_y = mix(output_size.y / input_size.y,
                      output_size.x * aspect.y / (input_size.x * aspect.x),
                      overscale);
        if (force_integer_scaling.y > 0.5 && scale_y > 1.0) {
            scale_y = floor(scale_y);
        }
        scale_x = scale_y * aspect.x / aspect.y;
        if (force_integer_scaling.x > 0.5 && scale_x > 1.0) {
            scale_x = floor(scale_x);
        }
    }
    return output_size / vec2(scale_x, scale_y);
}

// From unit output to pixel input space.
// coord_in_input_space = o2i(coord_in_output_space)
// This is used to sample from the input texture in the output pass.
// Version where scale is passed in.
vec2 o2i(vec2 x, vec2 input_size, vec4 crop, vec2 shift, int rotation,
         float center_after_cropping, vec2 scale_o2i) {
    return (x - 0.49999) * scale_o2i + get_input_center(input_size, crop, shift,
                                                        rotation,
                                                        center_after_cropping);
}

// Version that computes scale.
vec2 o2i(vec2 x, vec2 input_size, vec2 output_size, vec4 crop, vec2 shift,
         int rotation, float center_after_cropping, float force_aspect_ratio,
         vec2 aspect, vec2 force_integer_scaling, float overscale,
         bool output_size_is_final_viewport_size) {
    return o2i(x, input_size, crop, shift, rotation, center_after_cropping,
               get_scale_o2i(input_size, output_size, crop, rotation,
                             center_after_cropping, force_aspect_ratio, aspect,
                             force_integer_scaling, overscale,
                             output_size_is_final_viewport_size));
}

void main() {
    gl_Position = MVPMatrix * VertexCoord;
    TEX0.xy = TexCoord.xy;

    vec4 crop = vec4(OS_CROP_TOP, OS_CROP_LEFT, OS_CROP_BOTTOM, OS_CROP_RIGHT);
    vec2 scale_o2i = get_scale_o2i(
        OrigInputSize, OutputSize, crop, Rotation, CENTER_AFTER_CROPPING,
        FORCE_ASPECT_RATIO, vec2(ASPECT_H, ASPECT_V),
        vec2(FORCE_INTEGER_SCALING_H, FORCE_INTEGER_SCALING_V), OVERSCALE,
        /* output_size_is_final_viewport_size = */ false);
    vec2 shift = vec2(SHIFT_H, SHIFT_V);
    tx_coord = o2i(TEX0.xy * TextureSize / InputSize, OrigInputSize, crop,
                   shift, Rotation, CENTER_AFTER_CROPPING, scale_o2i);
    tx_per_px = scale_o2i / OutputSize;
    tx_to_uv = 1.0 / OrigTextureSize;
    input_corners = get_input_corners(OrigInputSize, crop, Rotation);
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

uniform COMPAT_PRECISION vec2 OrigTextureSize;

uniform COMPAT_PRECISION vec2 InputSize;
uniform COMPAT_PRECISION vec2 TextureSize;

uniform COMPAT_PRECISION vec2 PassPrev7TextureSize;
#define TiledSizePOT PassPrev7TextureSize
uniform COMPAT_PRECISION vec2 PassPrev7InputSize;
#define TiledSize PassPrev7InputSize

uniform COMPAT_PRECISION int Rotation;

uniform sampler2D PassPrev11Texture;
#define SRGBInput PassPrev11Texture
uniform sampler2D PassPrev7Texture;
#define Tiled PassPrev7Texture
uniform sampler2D Texture;
#define Blurred Texture

COMPAT_VARYING vec4 TEX0;

COMPAT_VARYING vec2 tx_coord;
COMPAT_VARYING vec2 tx_per_px;
COMPAT_VARYING vec2 tx_to_uv;
COMPAT_VARYING vec4 input_corners;

#ifdef PARAMETER_UNIFORM
// Own Settings
uniform COMPAT_PRECISION float FILL_GAMMA;
// From input transform library, scaling section
uniform COMPAT_PRECISION float FORCE_INTEGER_SCALING_H;
uniform COMPAT_PRECISION float FORCE_INTEGER_SCALING_V;
// From dual filter blur
uniform COMPAT_PRECISION float BLUR_RADIUS;
// From pixel AA
uniform COMPAT_PRECISION float PIX_AA_SHARP;
uniform COMPAT_PRECISION float PIX_AA_SUBPX;
uniform COMPAT_PRECISION float PIX_AA_SUBPX_ORIENTATION;
#else
#define WHATEVER 0.0
#endif

/*
The following code is copied from:
    Pixel AA v1.5 by fishku
See the original file for a full description.

There are the following modifications:
- Remove code for gamma correction.
*/

// Similar to smoothstep, but has a configurable slope at x = 0.5.
// Original smoothstep has a slope of 1.5 at x = 0.5
vec2 slopestep(vec2 edge0, vec2 edge1, vec2 x, float slope) {
    x = clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0);
    vec2 s = sign(x - 0.5);
    vec2 o = (1.0 + s) * 0.5;
    return o - 0.5 * s * pow(2.0 * (o - s * x), vec2(slope));
}

float to_lin(float x) { return pow(x, 2.2); }
vec3 to_lin(vec3 x) { return pow(x, vec3(2.2)); }

float to_srgb(float x) { return pow(x, 1.0 / 2.2); }
vec3 to_srgb(vec3 x) { return pow(x, vec3(1.0 / 2.2)); }

// Function to get a pixel value, taking into consideration possible subpixel
// interpolation.
vec4 pixel_aa(sampler2D tex, float sharpness, bool sample_subpx,
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

        // Red
        period = floor(tx_coord - sub_tx_offset - 0.5);
        phase = tx_coord - sub_tx_offset - 0.5 - period;
        offset = slopestep(sharp_lb, sharp_ub, phase, sharpness_lower);
        res.r = to_srgb(mix(
            mix(to_lin(COMPAT_TEXTURE(tex, (period + 0.5) * tx_to_uv).r),
                to_lin(COMPAT_TEXTURE(tex, (period + vec2(1.5, 0.5)) * tx_to_uv)
                           .r),
                offset.x),
            mix(to_lin(COMPAT_TEXTURE(tex, (period + vec2(0.5, 1.5)) * tx_to_uv)
                           .r),
                to_lin(COMPAT_TEXTURE(tex, (period + 1.5) * tx_to_uv).r),
                offset.x),
            offset.y));
        // Green
        period = floor(tx_coord - 0.5);
        phase = tx_coord - 0.5 - period;
        offset = slopestep(sharp_lb, sharp_ub, phase, sharpness_lower);
        res.g = to_srgb(mix(
            mix(to_lin(COMPAT_TEXTURE(tex, (period + 0.5) * tx_to_uv).g),
                to_lin(COMPAT_TEXTURE(tex, (period + vec2(1.5, 0.5)) * tx_to_uv)
                           .g),
                offset.x),
            mix(to_lin(COMPAT_TEXTURE(tex, (period + vec2(0.5, 1.5)) * tx_to_uv)
                           .g),
                to_lin(COMPAT_TEXTURE(tex, (period + 1.5) * tx_to_uv).g),
                offset.x),
            offset.y));
        // Blue
        period = floor(tx_coord + sub_tx_offset - 0.5);
        phase = tx_coord + sub_tx_offset - 0.5 - period;
        offset = slopestep(sharp_lb, sharp_ub, phase, sharpness_lower);
        res.b = to_srgb(mix(
            mix(to_lin(COMPAT_TEXTURE(tex, (period + 0.5) * tx_to_uv).b),
                to_lin(COMPAT_TEXTURE(tex, (period + vec2(1.5, 0.5)) * tx_to_uv)
                           .b),
                offset.x),
            mix(to_lin(COMPAT_TEXTURE(tex, (period + vec2(0.5, 1.5)) * tx_to_uv)
                           .b),
                to_lin(COMPAT_TEXTURE(tex, (period + 1.5) * tx_to_uv).b),
                offset.x),
            offset.y));

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
        // interpolation. The offsets are shifted back to the texel center
        // before sampling.
        return vec4(
            to_srgb(mix(
                mix(to_lin(COMPAT_TEXTURE(tex, (period + 0.5) * tx_to_uv).rgb),
                    to_lin(COMPAT_TEXTURE(tex,
                                          (period + vec2(1.5, 0.5)) * tx_to_uv)
                               .rgb),
                    offset.x),
                mix(to_lin(COMPAT_TEXTURE(tex,
                                          (period + vec2(0.5, 1.5)) * tx_to_uv)
                               .rgb),
                    to_lin(COMPAT_TEXTURE(tex, (period + 1.5) * tx_to_uv).rgb),
                    offset.x),
                offset.y)),
            1.0);
    }
}

void main() {
    if (any(lessThan(tx_coord, input_corners.xy)) ||
        any(greaterThanEqual(tx_coord, input_corners.zw))) {
        if (BLUR_RADIUS > 0.0) {
            // Sample blur.
            FragColor = vec4(COMPAT_TEXTURE(Blurred, TEX0.xy).rgb, 1.0);
        } else {
            // Sample tiled pattern.
            // Do a perfectly sharp (nearest neighbor) resampling.
            FragColor =
                vec4(COMPAT_TEXTURE(Tiled, (floor(TEX0.xy * TextureSize /
                                                  InputSize * TiledSize) +
                                            0.5) /
                                               TiledSizePOT)
                         .rgb,
                     1.0);
        }
        // Adjust background brightness and delinearize in one step.
        FragColor.rgb = pow(FragColor.rgb, vec3(FILL_GAMMA / 2.2));
    } else {
        // Sample original.
        if (FORCE_INTEGER_SCALING_H > 0.5 && FORCE_INTEGER_SCALING_V > 0.5) {
            // Do a perfectly sharp (nearest neighbor) sampling.
            // In this case, we can sample the sRGB input directly.
            FragColor = vec4(COMPAT_TEXTURE(SRGBInput, (floor(tx_coord) + 0.5) /
                                                           OrigTextureSize)
                                 .rgb,
                             1.0);
        } else {
            // Do a sharp anti-aliased interpolation.
            // Do a forced gamma correction and interpolate sRGB values to work
            // around some platforms not supporting float FBOs.
            // On platforms where the linear colors are stored intermediately,
            // quantization errors occur. The only way around this is to do more
            // computations in-memory before writing out quantized values.
            // This carries a certain performance cost and may be fixed in the
            // future.
            FragColor = pixel_aa(SRGBInput, PIX_AA_SHARP, PIX_AA_SUBPX > 0.5,
                                 int(PIX_AA_SUBPX_ORIENTATION), Rotation);
        }
    }
}

#endif
