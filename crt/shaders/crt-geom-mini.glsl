#version 110

/*
   CRT-Geom replica by DariusG 2024-2026.
   This shader should run well on gpu's with around 100 gflops.
   
   Permission is hereby granted, free of charge, to any person obtaining a copy
   of this software and associated documentation files (the "Software"), to deal
   in the Software without restriction, including without limitation the rights
   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
   copies of the Software, and to permit persons to whom the Software is
   furnished to do so, subject to the following conditions:

   The above copyright notice and this permission notice shall be included in
   all copies or substantial portions of the Software.

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
   THE SOFTWARE.
*/

#pragma parameter CURVATURE "CRTGeom Curvature Toggle" 1.0 0.0 1.0 1.0
#pragma parameter curve_amount "CRTGeom Curvature Amount" 0.15 0.0 0.5 0.01
#pragma parameter cornersize "CRTGeom Corner Size" 0.05 0.005 0.3 0.005
#pragma parameter DOTMASK "CRTGeom Dot Mask Strength" 0.3 0.0 1.0 0.1
#pragma parameter scanline_weight "CRTGeom Scanline Weight" 0.3 0.1 0.5 0.05
#pragma parameter interlace_detect "CRTGeom Interlacing Simulation" 1.0 0.0 1.0 1.0

#ifndef PARAMETER_UNIFORM
#define CURVATURE 1.0
#define curve_amount 0.15
#define cornersize 0.03
#define DOTMASK 0.3
#define scanline_weight 0.3
#define interlace_detect 1.0
#endif

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
COMPAT_VARYING vec2 one;
COMPAT_VARYING float mod_factor;
COMPAT_VARYING vec2 ilfac;
COMPAT_VARYING vec2 ilvec;
COMPAT_VARYING vec2 scale;

uniform mat4 MVPMatrix;
uniform vec2 TextureSize;
uniform vec2 InputSize;
uniform vec2 OutputSize;
uniform int FrameCount;

#ifdef PARAMETER_UNIFORM
uniform float interlace_detect;
#endif

void main()
{
    gl_Position = VertexCoord.x * MVPMatrix[0] + VertexCoord.y * MVPMatrix[1] + VertexCoord.z * MVPMatrix[2] + VertexCoord.w * MVPMatrix[3];
    TEX0.xy = TexCoord.xy * 1.0001;

    // Pre-calculate fixed scale and interlacing offset
    scale = TextureSize.xy / InputSize.xy;
    ilfac = vec2(1.0, clamp(floor(InputSize.y / 200.0), 1.0, 2.0));
    ilvec = vec2(0.0, (ilfac.y * interlace_detect > 1.5) ? mod(float(FrameCount), 2.0) : 0.0);
    
    one = ilfac / TextureSize.xy;
    mod_factor = TexCoord.x * OutputSize.x * scale.x;
}

#elif defined(FRAGMENT)
#if __VERSION__ >= 130
#define COMPAT_VARYING in
#define COMPAT_TEXTURE texture
out vec4 FragColor;
#else
#define COMPAT_VARYING varying
#define FragColor gl_FragColor
#define COMPAT_TEXTURE texture2D
#endif

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

uniform sampler2D Texture;
uniform vec2 TextureSize;

COMPAT_VARYING vec4 TEX0;
COMPAT_VARYING vec2 one;
COMPAT_VARYING float mod_factor;
COMPAT_VARYING vec2 ilfac;
COMPAT_VARYING vec2 ilvec;
COMPAT_VARYING vec2 scale;

#ifdef PARAMETER_UNIFORM
uniform float CURVATURE;
uniform float curve_amount;
uniform float cornersize;
uniform float DOTMASK;
uniform float scanline_weight;
#endif

#define TEX2D(c) (COMPAT_TEXTURE(Texture, (c)))

// Warp logic for consistency with the new corner trick
vec2 simple_warp(vec2 pos)
{
    pos = pos * 2.0 - 1.0;
    pos *= vec2(1.0 + (pos.y * pos.y) * (curve_amount * 0.2), 
                1.0 + (pos.x * pos.x) * (curve_amount * 0.3));
    return pos * 0.5 + 0.5;
}

vec4 scanlineWeights(float distance, vec4 color)
{

    float wid = 0.3 + 0.1 * dot(color.rgb, vec3(0.3, 0.6, 0.1));
    float w = distance / wid;
    return vec4((0.1 + scanline_weight) * exp(-w * w) / wid);
}

void main()
{
    // Geometry logic with Corner Trick
    vec2 vpos = TEX0.xy * scale;
    vec2 xy = (CURVATURE > 0.5) ? simple_warp(vpos) : vpos;

    // --- CORNER TRICK START ---
    vec2 corn = min(xy, 1.0 - xy); 
    if (CURVATURE > 0.5) {
        corn.x = (cornersize * 0.001) / corn.x; // Use reciprocal for hyperbolic curve
    }
    // --- CORNER TRICK END ---

    xy /= scale;

    // Hard boundary check
    if (xy.y < 0.0 || xy.y > 1.0 || xy.x < 0.0 || xy.x > 1.0) {
        FragColor = vec4(0.0);
        return;
    }

    vec2 ratio_scale = (xy * TextureSize - vec2(0.5) + ilvec) / ilfac;
    vec2 uv_ratio = fract(ratio_scale);
    xy = (floor(ratio_scale) * ilfac + vec2(0.5) - ilvec) / TextureSize;

    // Catmull Filtering
    float FF = uv_ratio.x * uv_ratio.x;
    vec4 lobes = vec4(FF * uv_ratio.x, FF, uv_ratio.x, 1.0);
    vec4 InvX;
    InvX.x = dot(vec4(-0.5, 1.0, -0.5, 0.0), lobes);
    InvX.y = dot(vec4( 1.5,-2.5,  0.0, 1.0), lobes);
    InvX.z = dot(vec4(-1.5, 2.0,  0.5, 0.0), lobes);
    InvX.w = dot(vec4( 0.5,-0.5,  0.0, 0.0), lobes);

    vec4 col  = mat4(TEX2D(xy + vec2(-one.x, 0.0)), 
                     TEX2D(xy), 
                     TEX2D(xy + vec2(one.x, 0.0)), 
                     TEX2D(xy + vec2(2.0 * one.x, 0.0))) * InvX;
                     
    vec4 col2 = mat4(TEX2D(xy + vec2(-one.x, one.y)), 
                     TEX2D(xy + vec2(0.0, one.y)), 
                     TEX2D(xy + one), 
                     TEX2D(xy + vec2(2.0 * one.x, one.y))) * InvX;

    vec4 weights  = scanlineWeights(uv_ratio.y, col);
    vec4 weights2 = scanlineWeights(1.0 - uv_ratio.y, col2);

    vec3 res = (col * weights + col2 * weights2).rgb;


    vec3 dotMask = mix(vec3(1.0, 1.0 - DOTMASK, 1.0), 
                       vec3(1.0 - DOTMASK, 1.0, 1.0 - DOTMASK), 
                       floor(mod(mod_factor, 2.0)));
    res *= dotMask;

    res = sqrt(clamp(res, 0.0, 1.0));
    // Apply corner mask (if corn.y is less than the reciprocal x, black out)
    if (CURVATURE > 0.5 && corn.y <= corn.x || corn.x < 0.00001) res = vec3(0.0);

    FragColor = vec4(res, 1.0);
}
#endif
