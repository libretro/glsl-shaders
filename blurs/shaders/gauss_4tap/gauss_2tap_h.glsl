/*
    Gauss-4tap v1.0 by fishku
    Copyright (C) 2023
    Public domain license (CC0)

    Simple two-pass Gaussian blur filter which does two taps per pass.
    Idea based on:
    https://www.rastergrid.com/blog/2010/09/efficient-gaussian-blur-with-linear-sampling/

    Changelog:
    v1.0: Initial release.
*/

// clang-format off
#pragma parameter GAUSS_4TAP_SETTINGS "=== Gauss-4tap v1.0 settings ===" 0.0 0.0 1.0 1.0
#pragma parameter SIGMA "Gaussian filtering sigma" 1.0 0.0 2.0 0.05
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
uniform COMPAT_PRECISION float SIGMA;
#else
#define SIGMA 1.0
#endif

// Finds the offset so that two samples drawn with linear filtering at that
// offset from a central pixel, multiplied with 1/2 each, sum up to a 3-sample
// approximation of the Gaussian sampled at pixel centers.
float get_offset(float sigma) {
  // Weight at x = 0 evaluates to 1 for all values of sigma.
  float w = exp(-1.0 / (sigma * sigma));
  return 2.0 * w / (2.0 * w + 1.0);
}

void main() {
  vec2 offset = vec2(get_offset(SIGMA) * SourceSize.z, 0.0);
  FragColor = 0.5 * (COMPAT_TEXTURE(Source, vTexCoord - offset) +
                     COMPAT_TEXTURE(Source, vTexCoord + offset));
}
#endif
