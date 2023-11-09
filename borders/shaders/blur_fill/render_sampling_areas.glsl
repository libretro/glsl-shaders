#version 130

// See compose.slang for copyright and other information.

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
  input_size =
      input_size - (center_after_cropping > 0.5
                        ? vec2(crop.y + crop.w, crop.x + crop.z)
                        : 2.0 * vec2(min(crop.y, crop.w), min(crop.x, crop.z)));

  force_integer_scaling = get_rotated_size(force_integer_scaling, rotation);
  float scale_x, scale_y;
  if (output_size.x / (input_size.x * aspect.x) <
      output_size.y / (input_size.y * aspect.y)) {
    // Scale will be limited by width. Calc x scale, then derive y scale
    // using aspect ratio.
    scale_x =
        mix(output_size.x / input_size.x,
            output_size.y * aspect.x / (input_size.y * aspect.y), overscale);
    if (force_integer_scaling.x > 0.5 && scale_x > 1.0) {
      scale_x = floor(scale_x);
    }
    scale_y = scale_x * aspect.y / aspect.x;
    if (force_integer_scaling.y > 0.5 && scale_y > 1.0) {
      scale_y = floor(scale_y);
    }
  } else {
    // Scale will be limited by height.
    scale_y =
        mix(output_size.y / input_size.y,
            output_size.x * aspect.y / (input_size.x * aspect.x), overscale);
    if (force_integer_scaling.y > 0.5 && scale_y > 1.0) {
      scale_y = floor(scale_y);
    }
    scale_x = scale_y * aspect.x / aspect.y;
    if (force_integer_scaling.x > 0.5 && scale_x > 1.0) {
      scale_x = floor(scale_x);
    }
  }
  return output_size.xy / vec2(scale_x, scale_y);
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

// From pixel input to unit output space.
// Version where scale is passed in.
vec2 i2o(vec2 x, vec2 input_size, vec4 crop, vec2 shift, int rotation,
         float center_after_cropping, vec2 scale_o2i) {
  return (x - get_input_center(input_size, crop, shift, rotation,
                               center_after_cropping)) /
             scale_o2i +
         0.49999;
}

// Version that computes scale.
vec2 i2o(vec2 x, vec2 input_size, vec2 output_size, vec4 crop, vec2 shift,
         int rotation, float center_after_cropping, float force_aspect_ratio,
         vec2 aspect, vec2 force_integer_scaling, float overscale,
         bool output_size_is_final_viewport_size) {
  return i2o(x, input_size, crop, shift, rotation, center_after_cropping,
             get_scale_o2i(input_size, output_size, crop, rotation,
                           center_after_cropping, force_aspect_ratio, aspect,
                           force_integer_scaling, overscale,
                           output_size_is_final_viewport_size));
}

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
COMPAT_VARYING vec4 TEX0;

COMPAT_VARYING vec2 tx_coord;
COMPAT_VARYING vec4 input_corners;

uniform mat4 MVPMatrix;
uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;

uniform COMPAT_PRECISION vec2 PassPrev3TextureSize;
uniform COMPAT_PRECISION vec2 PassPrev3InputSize;
#define OriginalInputSize PassPrev3InputSize
#define OriginalInputPOTSize PassPrev3TextureSize
uniform COMPAT_PRECISION int Rotation;

uniform COMPAT_PRECISION vec2 FinalViewportSize; // ??????????

// compatibility #defines
#define vTexCoord TEX0.xy
#define SourceSize vec4(TextureSize, 1.0 / TextureSize)
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
// Own settings
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

void main() {
  gl_Position = MVPMatrix * VertexCoord;
  TEX0.xy = TexCoord.xy;
  vec4 crop = vec4(OS_CROP_TOP, OS_CROP_LEFT, OS_CROP_BOTTOM, OS_CROP_RIGHT);
  vec2 scale_o2i = get_scale_o2i(
      OriginalInputSize, FinalViewportSize.xy, crop, Rotation,
      CENTER_AFTER_CROPPING, FORCE_ASPECT_RATIO, vec2(ASPECT_H, ASPECT_V),
      vec2(FORCE_INTEGER_SCALING_H, FORCE_INTEGER_SCALING_V), OVERSCALE,
      /* output_size_is_final_viewport_size = */ true);
  vec2 shift = vec2(SHIFT_H, SHIFT_V);
  tx_coord = o2i(vTexCoord, OriginalInputSize, crop, shift, Rotation,
                 CENTER_AFTER_CROPPING, scale_o2i);
  input_corners = get_input_corners(OriginalInputSize, crop, Rotation);
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

uniform COMPAT_PRECISION vec2 PassPrev3TextureSize;
uniform COMPAT_PRECISION vec2 PassPrev3InputSize;
#define OriginalInputSize PassPrev3InputSize
#define OriginalInputPOTSize PassPrev3TextureSize
uniform COMPAT_PRECISION int Rotation;

uniform sampler2D Texture;
COMPAT_VARYING vec4 TEX0;

COMPAT_VARYING vec2 tx_coord;
COMPAT_VARYING vec4 input_corners;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize)
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
// Own settings
uniform COMPAT_PRECISION float EXTEND_H;
uniform COMPAT_PRECISION float EXTEND_V;
uniform COMPAT_PRECISION float MIRROR_BLUR;
uniform COMPAT_PRECISION float SAMPLE_SIZE;
// From input transform library, moving section
uniform COMPAT_PRECISION float SHIFT_H;
uniform COMPAT_PRECISION float SHIFT_V;
uniform COMPAT_PRECISION float CENTER_AFTER_CROPPING;
#else
#define WHATEVER 0.0
#endif

float min_of_vec4(vec4 i) { return min(min(i.x, i.y), min(i.z, i.w)); }

int argmin(vec4 i) {
  vec4 m = vec4(min_of_vec4(i));
  vec4 ma = step(i, m) * vec4(0.0, -1.0, -2.0, -3.0);
  return -int(min_of_vec4(ma));
}

// Returns a coordinate in [0, w) when repeating that interval (and optionally
// mirroring).
float mirrored_repeat(float w, float x) {
  float phase = mod(x, w);
  if (MIRROR_BLUR < 0.5) {
    return phase;
  }
  int period = int(x / w);
  return period % 2 == 1 != x > 0.0 ? phase : w - phase;
}

float extend_left(vec2 coord, vec4 input_corners) {
  return input_corners.x +
         mirrored_repeat(SAMPLE_SIZE, coord.x - input_corners.x);
}

float extend_right(vec2 coord, vec4 input_corners) {
  return input_corners.z -
         mirrored_repeat(SAMPLE_SIZE, input_corners.z - coord.x);
}

float extend_top(vec2 coord, vec4 input_corners) {
  return input_corners.y +
         mirrored_repeat(SAMPLE_SIZE, coord.y - input_corners.y);
}

float extend_bottom(vec2 coord, vec4 input_corners) {
  return input_corners.w -
         mirrored_repeat(SAMPLE_SIZE, input_corners.w - coord.y);
}

// This function samples in a very specific way which is the foundation for
// blurring later.
// - If the sample coordinate is outside of the cropped input, Either black is
// returned if blur extension is turned off, or a repeated pattern from the
// sampling frame band is returned.
// - If the coordinate is inside the cropped input and within the frame band
// given by SAMPLE_SIZE, the original texture sample is returned.
// - If the coordinate is further inside than the frame band, a mirrored
// repeating sample is returned. The side of the frame that is sampled is given
// by the one that is closest to the sampled point.
vec3 sample_mirrored_frame(sampler2D tex, vec2 tx_coord, vec4 input_corners) {
  vec2 extend_fill = get_rotated_size(vec2(EXTEND_H, EXTEND_V), Rotation);
  vec2 inv_OriginalInputSize = 1.0 / OriginalInputSize;
  if (tx_coord.x < input_corners.x) {
    if (extend_fill.x < 0.5) {
      return vec3(0.0);
    }
    if (tx_coord.y < input_corners.y) {
      // Top left corner extension
      if (extend_fill.y < 0.5) {
        return vec3(0.0);
      }
      return COMPAT_TEXTURE(tex, vec2(extend_left(tx_coord, input_corners),
                                      extend_top(tx_coord, input_corners)) *
                                     inv_OriginalInputSize)
          .rgb;
    } else if (tx_coord.y < input_corners.w) {
      // Left extension
      return COMPAT_TEXTURE(
                 tex, vec2(extend_left(tx_coord, input_corners), tx_coord.y) *
                          inv_OriginalInputSize)
          .rgb;
    } else {
      // Bottom left corner extension
      if (extend_fill.y < 0.5) {
        return vec3(0.0);
      }
      return COMPAT_TEXTURE(tex, vec2(extend_left(tx_coord, input_corners),
                                      extend_bottom(tx_coord, input_corners)) *
                                     inv_OriginalInputSize)
          .rgb;
    }
  } else if (tx_coord.x < input_corners.z) {
    if (tx_coord.y < input_corners.y) {
      if (extend_fill.y < 0.5) {
        return vec3(0.0);
      }
      // Top extension
      return COMPAT_TEXTURE(
                 tex, vec2(tx_coord.x, extend_top(tx_coord, input_corners)) *
                          inv_OriginalInputSize)
          .rgb;
    } else if (tx_coord.y < input_corners.w) {
      vec4 inner_corners = input_corners + vec4(SAMPLE_SIZE, SAMPLE_SIZE,
                                                -SAMPLE_SIZE, -SAMPLE_SIZE);
      if (any(lessThan(tx_coord, inner_corners.xy)) ||
          any(greaterThanEqual(tx_coord, inner_corners.zw))) {
        // In frame band
        return COMPAT_TEXTURE(tex, tx_coord * inv_OriginalInputSize).rgb;
      }
      // Innermost -- mirrored repeat sampling from nearest side
      vec4 distances =
          vec4(tx_coord.x - inner_corners.x, inner_corners.z - tx_coord.x,
               tx_coord.y - inner_corners.y, inner_corners.w - tx_coord.y);
      switch (argmin(distances)) {
      case 0:
        // left
        return COMPAT_TEXTURE(
                   tex, vec2(extend_left(tx_coord, input_corners), tx_coord.y) *
                            inv_OriginalInputSize)
            .rgb;
      case 1:
        // right
        return COMPAT_TEXTURE(tex, vec2(extend_right(tx_coord, input_corners),
                                        tx_coord.y) *
                                       inv_OriginalInputSize)
            .rgb;
      case 2:
        // top
        return COMPAT_TEXTURE(
                   tex, vec2(tx_coord.x, extend_top(tx_coord, input_corners)) *
                            inv_OriginalInputSize)
            .rgb;
      case 3:
      default:
        // bottom
        return COMPAT_TEXTURE(
                   tex,
                   vec2(tx_coord.x, extend_bottom(tx_coord, input_corners)) *
                       inv_OriginalInputSize)
            .rgb;
      }
    } else {
      if (extend_fill.y < 0.5) {
        return vec3(0.0);
      }
      // Bottom extension
      return COMPAT_TEXTURE(
                 tex, vec2(tx_coord.x, extend_bottom(tx_coord, input_corners)) *
                          inv_OriginalInputSize)
          .rgb;
    }
  } else {
    if (extend_fill.x < 0.5) {
      return vec3(0.0);
    }
    if (tx_coord.y < input_corners.y) {
      // Top right corner extension
      if (extend_fill.y < 0.5) {
        return vec3(0.0);
      }
      return COMPAT_TEXTURE(tex, vec2(extend_right(tx_coord, input_corners),
                                      extend_top(tx_coord, input_corners)) *
                                     inv_OriginalInputSize)
          .rgb;
    } else if (tx_coord.y < input_corners.w) {
      // Right extension
      return COMPAT_TEXTURE(
                 tex, vec2(extend_right(tx_coord, input_corners), tx_coord.y) *
                          inv_OriginalInputSize)
          .rgb;
    } else {
      // Bottom right corner extension
      if (extend_fill.y < 0.5) {
        return vec3(0.0);
      }
      return COMPAT_TEXTURE(tex, vec2(extend_right(tx_coord, input_corners),
                                      extend_bottom(tx_coord, input_corners)) *
                                     inv_OriginalInputSize)
          .rgb;
    }
  }
}

void main() {
  FragColor = vec4(sample_mirrored_frame(Source, tx_coord, input_corners), 1.0);
  // FragColor = vec4(1.0, 0.0, 1.0, 1.0);
}

#endif
