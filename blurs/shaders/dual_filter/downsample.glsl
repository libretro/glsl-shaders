/*
    Dual Filter Blur & Bloom v1.1 by fishku
    Copyright (C) 2023
    Public domain license (CC0)

    The dual filter blur implementation follows the notes of the SIGGRAPH 2015 talk here:
    https://community.arm.com/cfs-file/__key/communityserver-blogs-components-weblogfiles/00-00-00-20-66/siggraph2015_2D00_mmg_2D00_marius_2D00_notes.pdf
    Dual filtering is a fast large-radius blur that approximates a Gaussian blur. It is closely
    related to the popular blur filter by Kawase, but runs faster at equal quality.

    How it works: Any number of downsampling passes are chained with the same number of upsampling
    passes in an hourglass configuration. Both types of resampling passes exploit bilinear
    interpolation with carefully chosen coordinates and weights to produce a smooth output.
    There are just 5 + 8 = 13 texture samples per combined down- and upsampling pass.
    The effective blur radius increases with the number of passes.

    This implementation adds a configurable blur strength which can diminish or accentuate the
    effect compared to the reference implementation, equivalent to strength 1.0.
    A blur strength above 3.0 may lead to artifacts, especially on presets with fewer passes.

    The bloom filter applies a thresholding operation, then blurs the input to varying degrees.
    The scene luminance is estimated using a feedback pass with variable update speed.
    The final pass screen blends a tonemapped bloom value with the original input, with the bloom
    intensity controlled by the scene luminance (a.k.a. eye adaption).

    Changelog:
    v1.1: Added bloom functionality.
    v1.0: Initial release.
*/

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

uniform mat4 MVPMatrix;
uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;

// compatibility #defines
#define vTexCoord TEX0.xy
#define SourceSize vec4(TextureSize, 1.0 / TextureSize)
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

void main() {
  gl_Position = MVPMatrix * VertexCoord;
  TEX0.xy = TexCoord.xy;
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
COMPAT_VARYING vec4 TEX0;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize)
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float BLUR_RADIUS;
#else
#define BLUR_RADIUS 1.0
#endif

vec3 downsample(sampler2D tex, vec2 coord, vec2 offset) {
  // The offset should be 1 source pixel size which equals 0.5 output pixel
  // sizes in the default configuration.
  return (COMPAT_TEXTURE(tex, coord - offset).rgb +                    //
          COMPAT_TEXTURE(tex, coord + vec2(offset.x, -offset.y)).rgb + //
          COMPAT_TEXTURE(tex, coord).rgb * 4.0 +                       //
          COMPAT_TEXTURE(tex, coord + offset).rgb +                    //
          COMPAT_TEXTURE(tex, coord - vec2(offset.x, -offset.y)).rgb) *
         0.125;
}

vec3 upsample(sampler2D tex, vec2 coord, vec2 offset) {
  // The offset should be 0.5 source pixel sizes which equals 1 output pixel
  // size in the default configuration.
  return (COMPAT_TEXTURE(tex, coord + vec2(0.0, -offset.y * 2.0)).rgb +
          (COMPAT_TEXTURE(tex, coord + vec2(-offset.x, -offset.y)).rgb +
           COMPAT_TEXTURE(tex, coord + vec2(offset.x, -offset.y)).rgb) *
              2.0 +
          COMPAT_TEXTURE(tex, coord + vec2(-offset.x * 2.0, 0.0)).rgb +
          COMPAT_TEXTURE(tex, coord + vec2(offset.x * 2.0, 0.0)).rgb +
          (COMPAT_TEXTURE(tex, coord + vec2(-offset.x, offset.y)).rgb +
           COMPAT_TEXTURE(tex, coord + vec2(offset.x, offset.y)).rgb) *
              2.0 +
          COMPAT_TEXTURE(tex, coord + vec2(0.0, offset.y * 2.0)).rgb) /
         12.0;
}

void main() {
  vec2 offset = SourceSize.zw * BLUR_RADIUS;
  FragColor = vec4(downsample(Source, vTexCoord, offset), 1.0);
}

#endif
