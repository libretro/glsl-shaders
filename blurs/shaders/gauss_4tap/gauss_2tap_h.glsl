/*
    Gauss-4tap v1.1 by fishku
    Copyright (C) 2023-2024
    Public domain license (CC0)

    Simple two-pass Gaussian blur filter which does two taps per pass.
    Idea based on:
    https://www.rastergrid.com/blog/2010/09/efficient-gaussian-blur-with-linear-sampling/

    Changelog:
    v1.1: Implement mirrored_repeat programmatically to work around GLSL
          limitations. Minor optimizations.
    v1.0: Initial release.
*/

// clang-format off
#pragma parameter GAUSS_4TAP_SETTINGS "=== Gauss-4tap v1.1 settings ===" 0.0 0.0 1.0 1.0
#pragma parameter SIGMA "Gaussian filtering sigma" 1.0 0.0 2.0 0.05
// clang-format on

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
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;

COMPAT_VARYING vec2 in_size_normalized;
COMPAT_VARYING vec2 mirror_min;
COMPAT_VARYING vec2 mirror_max;
COMPAT_VARYING vec2 offset;

#define vTexCoord TEX0.xy

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
    gl_Position = MVPMatrix * VertexCoord;
    TEX0.xy = TexCoord.xy;
    in_size_normalized = InputSize / TextureSize;
    mirror_min = 0.5 / TextureSize;
    mirror_max = (InputSize - 0.5) / TextureSize;
    offset = vec2(get_offset(SIGMA) / TextureSize.x, 0.0);
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

uniform sampler2D Texture;
COMPAT_VARYING vec4 TEX0;

COMPAT_VARYING vec2 in_size_normalized;
COMPAT_VARYING vec2 mirror_min;
COMPAT_VARYING vec2 mirror_max;
COMPAT_VARYING vec2 offset;

#define Source Texture
#define vTexCoord TEX0.xy

vec2 mirror_repeat(vec2 coord) {
    vec2 doubled = mod(coord, 2.0 * in_size_normalized);
    vec2 mirror = step(in_size_normalized, doubled);
    return clamp(mix(doubled, 2.0 * in_size_normalized - doubled, mirror), mirror_min,
                 mirror_max);
}

void main() {
    FragColor =
        0.5 * (COMPAT_TEXTURE(Source, mirror_repeat(vTexCoord - offset)) +
               COMPAT_TEXTURE(Source, mirror_repeat(vTexCoord + offset)));
}

#endif
