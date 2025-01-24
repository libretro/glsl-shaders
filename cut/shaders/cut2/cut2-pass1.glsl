/*
 * Cheap Upscaling Triangulation
 *
 * Copyright (c) Filippo Scognamiglio 2025
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
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

#ifdef GL_ES
#ifdef GL_FRAGMENT_PRECISION_HIGH
#define COMPAT_PRECISION_HIGHP highp
#else
#define COMPAT_PRECISION_HIGHP mediump
#endif
#define COMPAT_PRECISION_MEDIUMP mediump
#define COMPAT_PRECISION_LOWP lowp
#else
#define COMPAT_PRECISION_HIGHP
#define COMPAT_PRECISION_MEDIUMP
#define COMPAT_PRECISION_LOWP
#endif

COMPAT_ATTRIBUTE vec4 VertexCoord;
COMPAT_ATTRIBUTE vec4 TexCoord;

COMPAT_VARYING COMPAT_PRECISION_HIGHP vec2 screenCoords;
COMPAT_VARYING COMPAT_PRECISION_HIGHP vec2 passCoords;
COMPAT_VARYING COMPAT_PRECISION_HIGHP vec2 c05;
COMPAT_VARYING COMPAT_PRECISION_HIGHP vec2 c06;
COMPAT_VARYING COMPAT_PRECISION_HIGHP vec2 c09;
COMPAT_VARYING COMPAT_PRECISION_HIGHP vec2 c10;

uniform mat4 MVPMatrix;
uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;

void main()
{
    COMPAT_PRECISION_HIGHP vec2 coords = TexCoord.xy * 1.00001;
    screenCoords = coords * TextureSize - vec2(0.5);
    c05 = (screenCoords + vec2(+0.0, +0.0)) / TextureSize;
    c06 = (screenCoords + vec2(+1.0, +0.0)) / TextureSize;
    c09 = (screenCoords + vec2(+0.0, +1.0)) / TextureSize;
    c10 = (screenCoords + vec2(+1.0, +1.0)) / TextureSize;
    passCoords = c05;
    gl_Position = MVPMatrix * VertexCoord;
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

#ifdef GL_ES
#ifdef GL_FRAGMENT_PRECISION_HIGH
#define COMPAT_PRECISION_HIGHP highp
#else
#define COMPAT_PRECISION_HIGHP mediump
#endif
#define COMPAT_PRECISION_MEDIUMP mediump
#define COMPAT_PRECISION_LOWP lowp
#else
#define COMPAT_PRECISION_HIGHP
#define COMPAT_PRECISION_MEDIUMP
#define COMPAT_PRECISION_LOWP
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

#define EPSILON 0.02

uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;
uniform sampler2D Texture;
uniform sampler2D PassPrev2Texture;
uniform COMPAT_PRECISION vec2 PassPrev2TextureSize;

COMPAT_VARYING COMPAT_PRECISION_HIGHP vec2 screenCoords;
COMPAT_VARYING COMPAT_PRECISION_HIGHP vec2 passCoords;
COMPAT_VARYING COMPAT_PRECISION_HIGHP vec2 c05;
COMPAT_VARYING COMPAT_PRECISION_HIGHP vec2 c06;
COMPAT_VARYING COMPAT_PRECISION_HIGHP vec2 c09;
COMPAT_VARYING COMPAT_PRECISION_HIGHP vec2 c10;

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float BLEND_MIN_CONTRAST_EDGE;
uniform COMPAT_PRECISION float BLEND_MAX_CONTRAST_EDGE;
uniform COMPAT_PRECISION float BLEND_MIN_SHARPNESS;
uniform COMPAT_PRECISION float BLEND_MAX_SHARPNESS;
uniform COMPAT_PRECISION float SOFT_EDGES_SHARPENING_AMOUNT;
#else
#define BLEND_MIN_CONTRAST_EDGE 0.0
#define BLEND_MAX_CONTRAST_EDGE 0.5
#define BLEND_MIN_SHARPNESS 0.0
#define BLEND_MAX_SHARPNESS 0.7
#define SOFT_EDGES_SHARPENING_AMOUNT 1.0
#endif

#define USE_DYNAMIC_BLEND 1
#define STATIC_BLEND_SHARPNESS 0.0
#define EDGE_USE_FAST_LUMA 0
#define SOFT_EDGES_SHARPENING 1
#define EDGE_MIN_VALUE 0.025

COMPAT_PRECISION_LOWP float luma(COMPAT_PRECISION_LOWP vec3 v) {
    return v.g;
}

struct Pixels {
    COMPAT_PRECISION_LOWP vec3 p0;
    COMPAT_PRECISION_LOWP vec3 p1;
    COMPAT_PRECISION_LOWP vec3 p2;
    COMPAT_PRECISION_LOWP vec3 p3;
};

struct ShapeWeights {
    COMPAT_PRECISION_LOWP vec3 weights;
    COMPAT_PRECISION_LOWP vec3 midPoints;
};

struct Pattern {
    Pixels pixels;
    COMPAT_PRECISION_LOWP vec3 weights;
    COMPAT_PRECISION_LOWP vec3 midPoints;
    COMPAT_PRECISION_LOWP vec3 baseSharpness;
};

struct Flags {
    bool flip;
    bool triangle;
    COMPAT_PRECISION_LOWP vec4 edgeWeight;
};

COMPAT_PRECISION_LOWP vec2 quickUnpackFloats2(COMPAT_PRECISION_LOWP float value) {
    COMPAT_PRECISION_LOWP vec2 result = vec2(0.0);
    COMPAT_PRECISION_LOWP float current = value;

    current *= 16.0;
    result.x = floor(current);
    current -= result.x;

    current *= 16.0;
    result.y = floor(current);
    current -= result.y;

    return result / 12.0;
}

bvec2 quickUnpackBools2(COMPAT_PRECISION_LOWP float value) {
    COMPAT_PRECISION_LOWP vec2 result = vec2(0.0);
    COMPAT_PRECISION_LOWP float current = value;

    current *= 2.0;
    result.x = floor(current);
    current -= result.x;

    current *= 2.0;
    result.y = floor(current);
    current -= result.y;

    return greaterThan(result, vec2(0.5));
}

Flags parseFlags(COMPAT_PRECISION_LOWP vec3 flagsPixel) {
    Flags flags;
    flags.edgeWeight = clamp(
        vec4(quickUnpackFloats2(flagsPixel.y + 0.001953125), quickUnpackFloats2(flagsPixel.z + 0.001953125)),
        EPSILON,
        1.0 - EPSILON
    );
    bvec2 boolFlags = quickUnpackBools2(flagsPixel.x + 0.125);
    flags.triangle = boolFlags.x;
    flags.flip = boolFlags.y;
    return flags;
}

COMPAT_PRECISION_LOWP float linearStep(COMPAT_PRECISION_LOWP float edge0, COMPAT_PRECISION_LOWP float edge1, COMPAT_PRECISION_LOWP float t) {
    return clamp((t - edge0) / (edge1 - edge0), 0.0, 1.0);
}

COMPAT_PRECISION_LOWP float sharpness(COMPAT_PRECISION_LOWP float l1, COMPAT_PRECISION_LOWP float l2) {
#if USE_DYNAMIC_BLEND
    COMPAT_PRECISION_LOWP float blendDiffInv = 1.0 / (BLEND_MAX_CONTRAST_EDGE - BLEND_MIN_CONTRAST_EDGE);
    COMPAT_PRECISION_LOWP float lumaDiff = abs(l1 - l2);
    COMPAT_PRECISION_LOWP float contrast = clamp((lumaDiff - BLEND_MIN_CONTRAST_EDGE) * blendDiffInv, 0.0, 1.0);
    COMPAT_PRECISION_LOWP float result = mix(BLEND_MIN_SHARPNESS * 0.5, BLEND_MAX_SHARPNESS * 0.5, contrast);
#else
    COMPAT_PRECISION_LOWP float result = STATIC_BLEND_SHARPNESS * 0.5;
#endif
  return result;
}

COMPAT_PRECISION_LOWP float adjustMidpoint(COMPAT_PRECISION_LOWP float x, COMPAT_PRECISION_LOWP float midPoint) {
    COMPAT_PRECISION_LOWP float result = 0.0;
    result += clamp(x / midPoint, 0.0, 1.0);
    result += clamp((x - midPoint) / (1.0 - midPoint), 0.0, 1.0);
    return 0.5 * result;
}

COMPAT_PRECISION_LOWP vec3 blend(COMPAT_PRECISION_LOWP vec3 a, COMPAT_PRECISION_LOWP vec3 b, COMPAT_PRECISION_LOWP float t, COMPAT_PRECISION_LOWP float midPoint, COMPAT_PRECISION_LOWP float baseSharpness) {
    COMPAT_PRECISION_LOWP float sharpness = baseSharpness * sharpness(luma(a), luma(b));
    COMPAT_PRECISION_LOWP float nt = adjustMidpoint(t, midPoint);
    nt = clamp((nt - sharpness) / (1.0 - 2.0 * sharpness), 0.0 , 1.0);
    return mix(a, b, nt);
}

Pattern pattern(Pixels pixels, COMPAT_PRECISION_LOWP vec4 edgeWeights, bool triangle, COMPAT_PRECISION_LOWP vec2 pxCoords) {
    Pattern result;

    bool firstTriangle = triangle && pxCoords.x + pxCoords.y <= 1.0;
    bool secondTriangle = triangle && !firstTriangle;

    COMPAT_PRECISION_LOWP vec2 midPoints = vec2(0.0);

    if (secondTriangle) {
        pxCoords = vec2(1.0 - pxCoords.y, 1.0 - pxCoords.x);
        pixels = Pixels(pixels.p3, pixels.p1, pixels.p2, pixels.p0);
        edgeWeights = vec4(1.0) - edgeWeights.yxwz;
    }

    if (triangle) {
        COMPAT_PRECISION_LOWP float coordsSum = pxCoords.x + pxCoords.y;
        midPoints = vec2(
        edgeWeights.x * edgeWeights.w * coordsSum / (edgeWeights.w * pxCoords.x + edgeWeights.x * pxCoords.y),
        0.5 + 0.5 * clamp(-edgeWeights.x + edgeWeights.y - edgeWeights.z + edgeWeights.w, -1.0, 1.0)
        );
        pxCoords = vec2(coordsSum, pxCoords.y / coordsSum);
    } else {
        midPoints = vec2(
        mix(edgeWeights.x, edgeWeights.z, pxCoords.y),
        mix(edgeWeights.w, edgeWeights.y, pxCoords.x)
        );
    }

    result.weights = pxCoords.xxy;
    result.midPoints = midPoints.xxy;
    result.baseSharpness = vec3(1.0, 1.0, float(!triangle));
    result.pixels = Pixels(
        pixels.p0,
        pixels.p1,
        triangle ? pixels.p0 : pixels.p2,
        triangle ? pixels.p2 : pixels.p3
    );

    return result;
}

void main() {
    COMPAT_PRECISION_LOWP vec3 t05 = COMPAT_TEXTURE(PassPrev2Texture, c05).rgb;
    COMPAT_PRECISION_LOWP vec3 t06 = COMPAT_TEXTURE(PassPrev2Texture, c06).rgb;
    COMPAT_PRECISION_LOWP vec3 t09 = COMPAT_TEXTURE(PassPrev2Texture, c09).rgb;
    COMPAT_PRECISION_LOWP vec3 t10 = COMPAT_TEXTURE(PassPrev2Texture, c10).rgb;

    COMPAT_PRECISION_LOWP vec3 flagsPixel = COMPAT_TEXTURE(Texture, passCoords).xyz;
    Flags flags = parseFlags(flagsPixel);
    Pixels pixels = Pixels(t05, t06, t09, t10);

    COMPAT_PRECISION_LOWP vec2 pxCoords = fract(screenCoords);
    COMPAT_PRECISION_LOWP vec4 edges = flags.edgeWeight;

    if (flags.flip) {
        pixels = Pixels(pixels.p1, pixels.p0, pixels.p3, pixels.p2);
        pxCoords.x = 1.0 - pxCoords.x;
    }

    Pattern pattern = pattern(pixels, edges, flags.triangle, pxCoords);

    COMPAT_PRECISION_LOWP vec3 final = blend(
        blend(pattern.pixels.p0, pattern.pixels.p1, pattern.weights.x, pattern.midPoints.x, pattern.baseSharpness.x),
        blend(pattern.pixels.p2, pattern.pixels.p3, pattern.weights.y, pattern.midPoints.y, pattern.baseSharpness.y),
        pattern.weights.z,
        pattern.midPoints.z,
        pattern.baseSharpness.z
    );

    FragColor = vec4(final.rgb, 1.0);
}
#endif
