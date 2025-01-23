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
#pragma parameter BLEND_MAX_SHARPNESS "Max sharpness" 0.5 0.0 1.0

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

COMPAT_VARYING COMPAT_PRECISION_HIGHP vec2 screenCoords;
COMPAT_VARYING COMPAT_PRECISION_HIGHP vec2 c05;
COMPAT_VARYING COMPAT_PRECISION_HIGHP vec2 c06;
COMPAT_VARYING COMPAT_PRECISION_HIGHP vec2 c09;
COMPAT_VARYING COMPAT_PRECISION_HIGHP vec2 c10;

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float BLEND_MIN_CONTRAST_EDGE;
uniform COMPAT_PRECISION float BLEND_MAX_CONTRAST_EDGE;
uniform COMPAT_PRECISION float BLEND_MIN_SHARPNESS;
uniform COMPAT_PRECISION float BLEND_MAX_SHARPNESS;
uniform COMPAT_PRECISION float EDGE_MIN_VALUE;
#else
#define BLEND_MIN_CONTRAST_EDGE 0.0
#define BLEND_MAX_CONTRAST_EDGE 0.5
#define BLEND_MIN_SHARPNESS 0.0
#define BLEND_MAX_SHARPNESS 0.50
#define EDGE_MIN_VALUE 0.05
#endif

#define USE_DYNAMIC_BLEND 1
#define STATIC_BLEND_SHARPNESS 1.0
#define EDGE_USE_FAST_LUMA 0

COMPAT_PRECISION_LOWP float luma(COMPAT_PRECISION_LOWP vec3 v) {
#if EDGE_USE_FAST_LUMA
    COMPAT_PRECISION_LOWP float result = v.g;
#else
    COMPAT_PRECISION_LOWP float result = dot(v, vec3(0.299, 0.587, 0.114));
#endif
  return result;
}

struct Pixels {
    COMPAT_PRECISION_LOWP vec3 p0;
    COMPAT_PRECISION_LOWP vec3 p1;
    COMPAT_PRECISION_LOWP vec3 p2;
    COMPAT_PRECISION_LOWP vec3 p3;
};

struct Pattern {
    Pixels pixels;
    bool triangle;
    COMPAT_PRECISION_LOWP vec2 coords;
};

COMPAT_PRECISION_LOWP vec3 triangle(COMPAT_PRECISION_LOWP vec2 pxCoords) {
    COMPAT_PRECISION_LOWP vec3 ws = vec3(0.0);
    ws.x = pxCoords.y - pxCoords.x;
    ws.y = 1.0 - ws.x;
    ws.z = (pxCoords.y - ws.x) / (ws.y + EPSILON);
    return ws;
}

COMPAT_PRECISION_LOWP vec3 quad(COMPAT_PRECISION_LOWP vec2 pxCoords) {
    return vec3(pxCoords.x, pxCoords.x, pxCoords.y);
}

COMPAT_PRECISION_LOWP float linearStep(COMPAT_PRECISION_LOWP float edge0, COMPAT_PRECISION_LOWP float edge1, COMPAT_PRECISION_LOWP float t) {
    return clamp((t - edge0) / (edge1 - edge0 + EPSILON), 0.0, 1.0);
}

COMPAT_PRECISION_LOWP float sharpness(COMPAT_PRECISION_LOWP float l1, COMPAT_PRECISION_LOWP float l2) {
#if USE_DYNAMIC_BLEND
    COMPAT_PRECISION_LOWP float lumaDiff = abs(l1 - l2);
    COMPAT_PRECISION_LOWP float contrast = linearStep(BLEND_MIN_CONTRAST_EDGE, BLEND_MAX_CONTRAST_EDGE, lumaDiff);
    COMPAT_PRECISION_LOWP float result = mix(BLEND_MIN_SHARPNESS * 0.5, BLEND_MAX_SHARPNESS * 0.5, contrast);
#else
    COMPAT_PRECISION_LOWP float result = STATIC_BLEND_SHARPNESS * 0.5;
#endif
  return result;
}

bool hasDiagonal(COMPAT_PRECISION_LOWP float a, COMPAT_PRECISION_LOWP float b, COMPAT_PRECISION_LOWP float c, COMPAT_PRECISION_LOWP float d) {
    return distance(a, d) * 2.0 + EDGE_MIN_VALUE < distance(b, c);
}

COMPAT_PRECISION_LOWP vec3 blend(COMPAT_PRECISION_LOWP vec3 a, COMPAT_PRECISION_LOWP vec3 b, COMPAT_PRECISION_LOWP float t) {
    COMPAT_PRECISION_LOWP float sharpness = sharpness(luma(a), luma(b));
    return mix(a, b, linearStep(sharpness, 1.0 - sharpness, t));
}

Pattern pattern0(Pixels pixels, COMPAT_PRECISION_LOWP vec2 pxCoords) {
    return Pattern(pixels, false, pxCoords);
}

Pattern pattern1(Pixels pixels, COMPAT_PRECISION_LOWP vec2 pxCoords) {
    Pattern result;
    if (pxCoords.y > pxCoords.x) {
        result.pixels = Pixels(pixels.p0, pixels.p2, pixels.p2, pixels.p3);
        result.coords = vec2(pxCoords.x, pxCoords.y);
    } else {
        result.pixels = Pixels(pixels.p0, pixels.p1, pixels.p1, pixels.p3);
        result.coords = vec2(pxCoords.y, pxCoords.x);
    }
    result.triangle = true;
    return result;
}

void main() {
    COMPAT_PRECISION_LOWP vec3 t05 = COMPAT_TEXTURE(Texture, c05).rgb;
    COMPAT_PRECISION_LOWP vec3 t06 = COMPAT_TEXTURE(Texture, c06).rgb;
    COMPAT_PRECISION_LOWP vec3 t09 = COMPAT_TEXTURE(Texture, c09).rgb;
    COMPAT_PRECISION_LOWP vec3 t10 = COMPAT_TEXTURE(Texture, c10).rgb;

    COMPAT_PRECISION_LOWP float l05 = luma(t05);
    COMPAT_PRECISION_LOWP float l06 = luma(t06);
    COMPAT_PRECISION_LOWP float l09 = luma(t09);
    COMPAT_PRECISION_LOWP float l10 = luma(t10);

    Pixels pixels = Pixels(t05, t06, t09, t10);

    bool d05_10 = hasDiagonal(l05, l06, l09, l10);
    bool d06_09 = hasDiagonal(l06, l05, l10, l09);

    COMPAT_PRECISION_LOWP vec2 pxCoords = fract(screenCoords);

    if (d06_09) {
        pixels = Pixels(pixels.p1, pixels.p0, pixels.p3, pixels.p2);
        pxCoords.x = 1.0 - pxCoords.x;
    }

    Pattern pattern;

    if (d05_10 || d06_09) {
        pattern = pattern1(pixels, pxCoords);
    } else {
        pattern = pattern0(pixels, pxCoords);
    }

    COMPAT_PRECISION_LOWP vec3 weights = pattern.triangle ? triangle(pattern.coords) : quad(pattern.coords);

    COMPAT_PRECISION_LOWP vec3 final = blend(
        blend(pattern.pixels.p0, pattern.pixels.p1, weights.x),
        blend(pattern.pixels.p2, pattern.pixels.p3, weights.y),
        weights.z
    );

    FragColor = vec4(final, 1.0);
}
#endif
