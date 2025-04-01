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

#pragma parameter BLEND_MIN_CONTRAST_EDGE "Min contrast edge strength" 0.0 0.0 1.0
#pragma parameter BLEND_MAX_CONTRAST_EDGE "Max contrast edge strength" 0.5 0.0 1.0
#pragma parameter BLEND_MIN_SHARPNESS "Min sharpness" 0.0 0.0 1.0
#pragma parameter BLEND_MAX_SHARPNESS "Max sharpness" 0.7 0.0 1.0
#pragma parameter SOFT_EDGES_SHARPENING_AMOUNT "Soft edges sharpening" 1.0 0.0 1.0

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

COMPAT_VARYING COMPAT_PRECISION_HIGHP vec2 c01;
COMPAT_VARYING COMPAT_PRECISION_HIGHP vec2 c02;
COMPAT_VARYING COMPAT_PRECISION_HIGHP vec2 c04;
COMPAT_VARYING COMPAT_PRECISION_HIGHP vec2 c05;
COMPAT_VARYING COMPAT_PRECISION_HIGHP vec2 c06;
COMPAT_VARYING COMPAT_PRECISION_HIGHP vec2 c07;
COMPAT_VARYING COMPAT_PRECISION_HIGHP vec2 c08;
COMPAT_VARYING COMPAT_PRECISION_HIGHP vec2 c09;
COMPAT_VARYING COMPAT_PRECISION_HIGHP vec2 c10;
COMPAT_VARYING COMPAT_PRECISION_HIGHP vec2 c11;
COMPAT_VARYING COMPAT_PRECISION_HIGHP vec2 c13;
COMPAT_VARYING COMPAT_PRECISION_HIGHP vec2 c14;

uniform mat4 MVPMatrix;
uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;

void main()
{
    COMPAT_PRECISION_HIGHP vec2 coords = TexCoord.xy * 1.00001;
    COMPAT_PRECISION_HIGHP vec2 screenCoords = coords * TextureSize - vec2(0.5);
    c01 = (screenCoords + vec2(+0.0, -1.0)) / TextureSize;
    c02 = (screenCoords + vec2(+1.0, -1.0)) / TextureSize;
    c04 = (screenCoords + vec2(-1.0, +0.0)) / TextureSize;
    c05 = (screenCoords + vec2(+0.0, +0.0)) / TextureSize;
    c06 = (screenCoords + vec2(+1.0, +0.0)) / TextureSize;
    c07 = (screenCoords + vec2(+2.0, +0.0)) / TextureSize;
    c08 = (screenCoords + vec2(-1.0, +1.0)) / TextureSize;
    c09 = (screenCoords + vec2(+0.0, +1.0)) / TextureSize;
    c10 = (screenCoords + vec2(+1.0, +1.0)) / TextureSize;
    c11 = (screenCoords + vec2(+2.0, +1.0)) / TextureSize;
    c13 = (screenCoords + vec2(+0.0, +2.0)) / TextureSize;
    c14 = (screenCoords + vec2(+1.0, +2.0)) / TextureSize;
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

COMPAT_VARYING COMPAT_PRECISION_HIGHP vec2 c01;
COMPAT_VARYING COMPAT_PRECISION_HIGHP vec2 c02;
COMPAT_VARYING COMPAT_PRECISION_HIGHP vec2 c04;
COMPAT_VARYING COMPAT_PRECISION_HIGHP vec2 c05;
COMPAT_VARYING COMPAT_PRECISION_HIGHP vec2 c06;
COMPAT_VARYING COMPAT_PRECISION_HIGHP vec2 c07;
COMPAT_VARYING COMPAT_PRECISION_HIGHP vec2 c08;
COMPAT_VARYING COMPAT_PRECISION_HIGHP vec2 c09;
COMPAT_VARYING COMPAT_PRECISION_HIGHP vec2 c10;
COMPAT_VARYING COMPAT_PRECISION_HIGHP vec2 c11;
COMPAT_VARYING COMPAT_PRECISION_HIGHP vec2 c13;
COMPAT_VARYING COMPAT_PRECISION_HIGHP vec2 c14;

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
#define STATIC_BLEND_SHARPNESS 0.00
#define EDGE_USE_FAST_LUMA 0
#define EDGE_MIN_VALUE 0.025
#define SOFT_EDGES_SHARPENING 1
#define SEARCH_MIN_CONTRAST 0.5
#define SEARCH_MAX_DISTANCE 8

COMPAT_PRECISION_LOWP float maxOf(COMPAT_PRECISION_LOWP vec4 values) {
    return max(max(values.x, values.y), max(values.z, values.w));
}

COMPAT_PRECISION_LOWP float minOf(COMPAT_PRECISION_LOWP vec4 values) {
    return min(min(values.x, values.y), min(values.z, values.w));
}

COMPAT_PRECISION_LOWP float luma(COMPAT_PRECISION_LOWP vec3 v) {
#if EDGE_USE_FAST_LUMA
  COMPAT_PRECISION_LOWP float result = v.g;
#else
  COMPAT_PRECISION_LOWP float result = dot(v, vec3(0.299, 0.587, 0.114));
#endif
  return result;
}

COMPAT_PRECISION_LOWP float quickPackBools2(bvec2 values) {
    return dot(vec2(values), vec2(0.5, 0.25));
}

COMPAT_PRECISION_LOWP float quickPackFloats2(COMPAT_PRECISION_LOWP vec2 values) {
    return dot(floor(values * vec2(12.0) + vec2(0.5)), vec2(0.0625, 0.00390625));
}

struct Quad {
    COMPAT_PRECISION_LOWP vec4 scores;
    COMPAT_PRECISION_LOWP float localContrast;
};

Quad quad(COMPAT_PRECISION_LOWP vec4 values) {
    COMPAT_PRECISION_LOWP vec4 edges = values.xyzx - values.ywwz;

    Quad result;
    result.scores = vec4(
        abs(edges.x + edges.z),
        abs(edges.w + edges.y),
        max(abs(edges.x - edges.y), abs(edges.w - edges.z)),
        max(abs(edges.x + edges.w), abs(edges.y + edges.z))
    );
    result.localContrast = maxOf(values) - minOf(values);
    return result;
}

COMPAT_PRECISION_LOWP int computePattern(COMPAT_PRECISION_LOWP vec4 scores, COMPAT_PRECISION_LOWP vec4 neighborsScores) {
    bool isDiagonal = max(scores.z, scores.w) > max(scores.x, scores.y);

    scores += 0.25 * neighborsScores;

    COMPAT_PRECISION_LOWP int result = 0;
    if (!isDiagonal) {
        if (scores.x > scores.y + EDGE_MIN_VALUE) {
            result = 1;
        } else if (scores.y > scores.x + EDGE_MIN_VALUE) {
            result = 2;
        }
    } else {
        if (scores.z > scores.w + EDGE_MIN_VALUE) {
            result = 3;
        } else if (scores.w > scores.z + EDGE_MIN_VALUE) {
            result = 4;
        }
    }

    return result;
}

COMPAT_PRECISION_LOWP int findPattern(Quad quad) {
    return computePattern(quad.scores, vec4(0.0));
}

COMPAT_PRECISION_LOWP int findPattern(Quad quads[5]) {
    COMPAT_PRECISION_LOWP vec4 scores = quads[0].scores;
    COMPAT_PRECISION_LOWP vec4 adjustments = vec4(0.0);
    adjustments += quads[1].scores;
    adjustments += quads[2].scores;
    adjustments += quads[3].scores;
    adjustments += quads[4].scores;
    return computePattern(scores, adjustments);
}

COMPAT_PRECISION_LOWP float softEdgeWeight(COMPAT_PRECISION_LOWP float a, COMPAT_PRECISION_LOWP float b, COMPAT_PRECISION_LOWP float c, COMPAT_PRECISION_LOWP float d) {
    COMPAT_PRECISION_LOWP float result = 0.0;
    result += clamp((abs(b - c) / (abs(a - c) + EPSILON)), 0.0, 1.0);
    result -= clamp((abs(c - b) / (abs(b - d) + EPSILON)), 0.0, 1.0);
    return clamp(2.0 * result, -1.0, 1.0);
}

void main() {
    COMPAT_PRECISION_LOWP vec3 t01 = COMPAT_TEXTURE(Texture, c01).rgb;
    COMPAT_PRECISION_LOWP vec3 t02 = COMPAT_TEXTURE(Texture, c02).rgb;
    COMPAT_PRECISION_LOWP vec3 t04 = COMPAT_TEXTURE(Texture, c04).rgb;
    COMPAT_PRECISION_LOWP vec3 t05 = COMPAT_TEXTURE(Texture, c05).rgb;
    COMPAT_PRECISION_LOWP vec3 t06 = COMPAT_TEXTURE(Texture, c06).rgb;
    COMPAT_PRECISION_LOWP vec3 t07 = COMPAT_TEXTURE(Texture, c07).rgb;
    COMPAT_PRECISION_LOWP vec3 t08 = COMPAT_TEXTURE(Texture, c08).rgb;
    COMPAT_PRECISION_LOWP vec3 t09 = COMPAT_TEXTURE(Texture, c09).rgb;
    COMPAT_PRECISION_LOWP vec3 t10 = COMPAT_TEXTURE(Texture, c10).rgb;
    COMPAT_PRECISION_LOWP vec3 t11 = COMPAT_TEXTURE(Texture, c11).rgb;
    COMPAT_PRECISION_LOWP vec3 t13 = COMPAT_TEXTURE(Texture, c13).rgb;
    COMPAT_PRECISION_LOWP vec3 t14 = COMPAT_TEXTURE(Texture, c14).rgb;

    COMPAT_PRECISION_LOWP float l01 = luma(t01);
    COMPAT_PRECISION_LOWP float l02 = luma(t02);
    COMPAT_PRECISION_LOWP float l04 = luma(t04);
    COMPAT_PRECISION_LOWP float l05 = luma(t05);
    COMPAT_PRECISION_LOWP float l06 = luma(t06);
    COMPAT_PRECISION_LOWP float l07 = luma(t07);
    COMPAT_PRECISION_LOWP float l08 = luma(t08);
    COMPAT_PRECISION_LOWP float l09 = luma(t09);
    COMPAT_PRECISION_LOWP float l10 = luma(t10);
    COMPAT_PRECISION_LOWP float l11 = luma(t11);
    COMPAT_PRECISION_LOWP float l13 = luma(t13);
    COMPAT_PRECISION_LOWP float l14 = luma(t14);

    Quad quads[5];
    quads[0] = quad(vec4(l05, l06, l09, l10));
    quads[1] = quad(vec4(l01, l02, l05, l06));
    quads[2] = quad(vec4(l06, l07, l10, l11));
    quads[3] = quad(vec4(l09, l10, l13, l14));
    quads[4] = quad(vec4(l04, l05, l08, l09));

    COMPAT_PRECISION_LOWP int pattern = findPattern(quads);

    COMPAT_PRECISION_LOWP vec4 neighborContrasts = max(
        vec4(quads[0].localContrast),
        vec4(quads[1].localContrast, quads[2].localContrast, quads[3].localContrast, quads[4].localContrast)
    );

    COMPAT_PRECISION_LOWP vec4 mainValues = vec4(l05, l06, l09, l10);
    COMPAT_PRECISION_LOWP vec4 mainEdges = abs(mainValues.xyzx - mainValues.ywwz);
    bvec4 neighborConnections = greaterThanEqual(mainEdges, SEARCH_MIN_CONTRAST * neighborContrasts);

    COMPAT_PRECISION_LOWP ivec4 neighborPatterns = ivec4(
        findPattern(quads[1]),
        findPattern(quads[2]),
        findPattern(quads[3]),
        findPattern(quads[4])
    );
    neighborPatterns *= ivec4(neighborConnections);

    bool vertical = any(equal(neighborPatterns.xz, ivec2(1)));
    bool horizontal = any(equal(neighborPatterns.yw, ivec2(2)));
    bool corner = vertical && horizontal;
    bool opposite = any(equal(neighborPatterns, ivec4(pattern == 3 ? 4 : 3)));
    bool isTriangle = pattern >= 3;

    bool reject = (isTriangle && (opposite || corner)) || !any(neighborConnections);

    COMPAT_PRECISION_LOWP vec4 result = vec4(0.0);

#if SOFT_EDGES_SHARPENING
    COMPAT_PRECISION_LOWP vec4 softEdges = vec4(
        softEdgeWeight(l04, l05, l06, l07),
        softEdgeWeight(l02, l06, l10, l14),
        softEdgeWeight(l08, l09, l10, l11),
        softEdgeWeight(l01, l05, l09, l13)
    );

    COMPAT_PRECISION_LOWP float softEdgesStrength = dot(abs(softEdges), vec4(1.0));
    reject = reject || softEdgesStrength > 2.0;

    result.y = quickPackFloats2(softEdges.xy * 0.5 + vec2(0.5));
    result.z = quickPackFloats2(softEdges.zw * 0.5 + vec2(0.5));
#endif

    if (reject) {
        pattern = -pattern;
    }

    result.x = float(pattern + 4) / 8.0;
    FragColor = result;
}

#endif
