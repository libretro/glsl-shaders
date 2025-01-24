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

COMPAT_VARYING COMPAT_PRECISION_HIGHP vec2 passCoords;
COMPAT_VARYING COMPAT_PRECISION_HIGHP vec2 c05;
COMPAT_VARYING COMPAT_PRECISION_HIGHP vec2 dc;

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
    c05 = (screenCoords + vec2(+0.0, +0.0)) / TextureSize;
    passCoords = c05;
    dc = vec2(1.0) / TextureSize;
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

COMPAT_VARYING COMPAT_PRECISION_HIGHP vec2 passCoords;
COMPAT_VARYING COMPAT_PRECISION_HIGHP vec2 c05;
COMPAT_VARYING COMPAT_PRECISION_HIGHP vec2 dc;

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

const COMPAT_PRECISION_LOWP float STEP = 0.5 / float(SEARCH_MAX_DISTANCE);
const COMPAT_PRECISION_LOWP float HSTEP = (STEP * 0.5);

COMPAT_PRECISION_LOWP float quickPackBools2(bvec2 values) {
    return dot(vec2(values), vec2(0.5, 0.25));
}

COMPAT_PRECISION_LOWP float quickPackFloats2(COMPAT_PRECISION_LOWP vec2 values) {
    return dot(floor(values * vec2(12.0) + vec2(0.5)), vec2(0.0625, 0.00390625));
}

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

COMPAT_PRECISION_LOWP int fetchPattern(COMPAT_PRECISION_LOWP float value) {
    return int(value * 8.0 + 0.5) - 4;
}

COMPAT_PRECISION_LOWP vec2 walk(
    COMPAT_PRECISION_LOWP sampler2D previousPass,
    COMPAT_PRECISION_HIGHP vec2 baseCoords,
    COMPAT_PRECISION_HIGHP vec2 direction,
    COMPAT_PRECISION_LOWP vec2 results,
    COMPAT_PRECISION_LOWP int continuePattern
) {
    COMPAT_PRECISION_LOWP vec2 result = vec2(0.0, 0.0);
    for (COMPAT_PRECISION_LOWP int i = 1; i <= SEARCH_MAX_DISTANCE; i++) {
        COMPAT_PRECISION_HIGHP vec2 coords = baseCoords + direction * float(i);
        COMPAT_PRECISION_LOWP int currentPattern = fetchPattern(COMPAT_TEXTURE(previousPass, coords).x);

        if (currentPattern == 3) {
            result.y = results.x;
        } else if (currentPattern == 4) {
            result.y = results.y;
        }

        if (currentPattern == 3 || currentPattern == 4) {
            result.x += HSTEP;
        } else if (currentPattern == continuePattern) {
            result.x += STEP;
        }

        if (currentPattern != continuePattern) { break; }
    }
    return result;
}

COMPAT_PRECISION_LOWP float blendWeights(COMPAT_PRECISION_LOWP vec2 d1, COMPAT_PRECISION_LOWP vec2 d2) {
    const float MAX_DOUBLE_DISTANCE = float(SEARCH_MAX_DISTANCE) * STEP;
    const float MAX_DISTANCE = STEP * float(SEARCH_MAX_DISTANCE / 2) + HSTEP;

    COMPAT_PRECISION_LOWP float result = 0.0;

    COMPAT_PRECISION_LOWP float totalDistance = d1.x + d2.x;
    COMPAT_PRECISION_LOWP float d1Ratio = d1.x / totalDistance;

    if (totalDistance <= EPSILON) {
        result = 0.0;
    } else if (totalDistance <= MAX_DOUBLE_DISTANCE) {
        result = (d1.x < d2.x) ? mix(d1.y, 0.0, 2.0 * d1Ratio) : mix(0.0, d2.y, (d1Ratio - 0.5) * 2.0);
    } else if (d1.x <= MAX_DISTANCE) {
        result = mix(d1.y, 0.0, d1.x / MAX_DISTANCE);
    } else if (d2.x <= MAX_DISTANCE) {
        result = mix(d2.y, 0.0, d2.x / MAX_DISTANCE);
    }

    return result;
}

void main() {
    COMPAT_PRECISION_LOWP vec4 previousPassPixel = COMPAT_TEXTURE(Texture, passCoords);
    COMPAT_PRECISION_LOWP int pattern = fetchPattern(previousPassPixel.x);

    COMPAT_PRECISION_LOWP vec2 resultN = vec2(0.0, 0.0);
    COMPAT_PRECISION_LOWP vec2 resultS = vec2(0.0, 0.0);
    COMPAT_PRECISION_LOWP vec2 resultW = vec2(0.0, 0.0);
    COMPAT_PRECISION_LOWP vec2 resultE = vec2(0.0, 0.0);

    if (pattern == 1 || pattern == 3 || pattern == 4) {
        resultN = walk(Texture, passCoords, vec2(0.0, -dc.y), vec2(-1.0, +1.0), 1);
        resultS = walk(Texture, passCoords, vec2(0.0, +dc.y), vec2(+1.0, -1.0), 1);
    }
    if (pattern == 2 || pattern == 3 || pattern == 4) {
        resultW = walk(Texture, passCoords, vec2(-dc.x, 0.0), vec2(-1.0, +1.0), 2);
        resultE = walk(Texture, passCoords, vec2(+dc.x, 0.0), vec2(+1.0, -1.0), 2);
    }
    COMPAT_PRECISION_LOWP vec4 edgesWeights[4];

    if (pattern == 1) {
        edgesWeights[0] = vec4(resultN, resultS + vec2(STEP, 0.0));
        edgesWeights[2] = vec4(resultN + vec2(STEP, 0.0), resultS);
    } else if (pattern == 2) {
        edgesWeights[3] = vec4(resultW, resultE + vec2(STEP, 0.0));
        edgesWeights[1] = vec4(resultW + vec2(STEP, 0.0), resultE);
    } else if (pattern == 3) {
        edgesWeights[0] = vec4(resultN, vec2(HSTEP, 1.0));
        edgesWeights[2] = vec4(vec2(HSTEP, -1.0), resultS);
        edgesWeights[3] = vec4(resultW, vec2(HSTEP, 1.0));
        edgesWeights[1] = vec4(vec2(HSTEP, -1.0), resultE);
    } else if (pattern == 4) {
        edgesWeights[0] = vec4(resultN, vec2(HSTEP, -1.0));
        edgesWeights[2] = vec4(vec2(HSTEP, 1.0), resultS);
        edgesWeights[3] = vec4(resultW, vec2(HSTEP, -1.0));
        edgesWeights[1] = vec4(vec2(HSTEP, 1.0), resultE);
    }
    COMPAT_PRECISION_LOWP vec4 edges = vec4(
        blendWeights(edgesWeights[0].xy, edgesWeights[0].zw),
        blendWeights(edgesWeights[1].xy, edgesWeights[1].zw),
        blendWeights(edgesWeights[2].xy, edgesWeights[2].zw),
        blendWeights(edgesWeights[3].xy, edgesWeights[3].zw)
    );

#if SOFT_EDGES_SHARPENING
    COMPAT_PRECISION_LOWP vec4 softEdges = 2.0 * SOFT_EDGES_SHARPENING_AMOUNT * vec4(
        quickUnpackFloats2(previousPassPixel.y + 0.001953125) - vec2(0.5),
        quickUnpackFloats2(previousPassPixel.z + 0.001953125) - vec2(0.5)
    );

    edges = clamp(edges + softEdges, min(edges, softEdges), max(edges, softEdges));
#endif

    COMPAT_PRECISION_LOWP int originalPattern = pattern >= 0 ? pattern : -pattern;
    if (originalPattern == 3) {
        edges = vec4(-edges.x, edges.w, -edges.z, edges.y);
    }

    FragColor = vec4(
        quickPackBools2(bvec2(originalPattern >= 3, originalPattern == 3)),
        quickPackFloats2(edges.xy * 0.5 + vec2(0.5)),
        quickPackFloats2(edges.zw * 0.5 + vec2(0.5)),
        1.0
    );
}

#endif
