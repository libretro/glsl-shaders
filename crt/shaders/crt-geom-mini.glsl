#version 110

// This program is free software; you can redistribute it and/or modify it
// under the terms of the GNU General Public License as published by the Free
// Software Foundation; either version 2 of the License, or (at your option)
// any later version.

#pragma parameter CURV "CRT-Geom Curvature" 1.0 0.0 1.0 1.0
#pragma parameter SCAN "CRT-Geom Scanline Weight" 0.2 0.1 0.6 0.05
#pragma parameter MASK "CRT-Geom Dotmask Strength" 0.2 0.0 0.5 0.05
#pragma parameter LUM "CRT-Geom Luminance" 0.1 0.0 0.5 0.01
#pragma parameter INTERL "CRT-Geom Interlacing Simulation" 1.0 0.0 1.0 1.0
#pragma parameter SAT "CRT-Geom Saturation" 1.1 0.0 2.0 0.05
#pragma parameter LANC "Filter profile: Accurate/Fast" 0.0 0.0 1.0 1.0

#define PI 3.1415926535897932384626433

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
COMPAT_ATTRIBUTE vec4 COLOR;
COMPAT_ATTRIBUTE vec4 TexCoord;
COMPAT_VARYING vec4 COL0;
COMPAT_VARYING vec4 TEX0;
COMPAT_VARYING vec2 scale;
COMPAT_VARYING vec2 warpp;
COMPAT_VARYING vec2 warppm;
COMPAT_VARYING vec2 warp;
COMPAT_VARYING float fragpos;
COMPAT_VARYING float omega;

vec4 _oPosition1; 
uniform mat4 MVPMatrix;
uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;

// compatibility #defines
#define vTexCoord TEX0.xy
#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float SIZE;

#else
#define SIZE     1.0         
#endif

void main()
{
    gl_Position = MVPMatrix * VertexCoord;
    TEX0.xy = TexCoord.xy;
    scale = TextureSize.xy/InputSize.xy;
    warpp = TEX0.xy*scale;   
    fragpos = warpp.x*OutputSize.x*PI;
    warp = warpp*2.0-1.0;   
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

uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;
uniform sampler2D Texture;
COMPAT_VARYING vec4 TEX0;
COMPAT_VARYING vec2 scale;
COMPAT_VARYING float fragpos;
COMPAT_VARYING vec2 warpp;
COMPAT_VARYING vec2 warppm;
COMPAT_VARYING vec2 warp;
COMPAT_VARYING float omega;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float SCAN;
uniform COMPAT_PRECISION float MASK;
uniform COMPAT_PRECISION float CURV;
uniform COMPAT_PRECISION float LUM;
uniform COMPAT_PRECISION float SAT;
uniform COMPAT_PRECISION float INTERL;
uniform COMPAT_PRECISION float LANC;

#else
#define SCAN  0.3      
#define MASK  0.6
#define CURV  1.0
#define LUM 0.0
#define SAT 1.0
#define INTERL 1.0
#define LANC 0.0
#endif

float scan(float pos, vec3 color)
    {
    float wid = SCAN + 0.15 * max(max(color.r,color.g),color.b);
    float weight = pos / wid;
    return  (LUM + (0.15 + SCAN)) * exp2(-weight * weight ) / wid;
    }

vec2 Warp(vec2 pos)
{
    pos = warp;
    pos *= vec2(1.0+pos.y*pos.y*0.031, 1.0+pos.x*pos.x*0.05);
    pos = pos*0.5+0.5;
    return pos;
}

void main()
{
    vec2 pos;
    if (CURV == 1.0) pos = Warp(warpp);
    else pos = vTexCoord;

    vec2 corn   = min(pos,1.0-pos); // This is used to mask the rounded
         corn.x = 0.0001/corn.x;  // corners later on

    if (CURV == 1.0) pos /= scale;

// Lanczos 2
    // Source position in fractions of a texel
    vec2 src_pos = pos*SourceSize.xy;
    // Source bottom left texel centre
    vec2 src_centre = floor(src_pos - 0.5) + 0.5;
    // f is position. f.x runs left to right, y bottom to top, z right to left, w top to bottom
    vec4 f; 
    f.xy = src_pos - src_centre;
    f.zw = 1.0 - f.xy;
    // Calculate weights in x and y in parallel.
    // These polynomials are piecewise approximation of Lanczos kernel
    // Calculator here: https://gist.github.com/going-digital/752271db735a07da7617079482394543
    vec4 l2_w0_o3, l2_w1_o3;
    if (LANC == 0.0)
     {l2_w0_o3 = (((1.5672) * f - 2.6445) * f + 0.0837) * f + 0.9976;
      l2_w1_o3 = (((-0.7389) * f + 1.3652) * f - 0.6295) * f - 0.0004;}
    else  {l2_w0_o3 = (-1.1828) * f + 1.1298;
           l2_w1_o3 = (0.0858) * f - 0.0792;}

    vec4 w1_2  = l2_w0_o3;
    vec2 w12   = w1_2.xy + w1_2.zw;
    vec4 wedge = l2_w1_o3 * vec4 (w12.yx, w12.yx);

    // Calculate texture read positions. tc12 uses bilinear interpolation to do 4 reads in 1.
    vec2 tc12 = SourceSize.zw * (src_centre + w1_2.zw / w12);
    vec2 tc0  = SourceSize.zw * (src_centre - 1.0);
    vec2 tc3  = SourceSize.zw * (src_centre + 2.0);
    
    // Sharpening adjustment
    float sum = wedge.x + wedge.y + wedge.z + wedge.w + w12.x * w12.y;    
    wedge /= sum;

    vec3 res = vec3(
        COMPAT_TEXTURE(Source, vec2(tc12.x, tc0.y)).rgb * wedge.y +
        COMPAT_TEXTURE(Source, vec2(tc0.x, tc12.y)).rgb * wedge.x +
        COMPAT_TEXTURE(Source, tc12.xy).rgb * (w12.x * w12.y) +
        COMPAT_TEXTURE(Source, vec2(tc3.x, tc12.y)).rgb * wedge.z +
        COMPAT_TEXTURE(Source, vec2(tc12.x, tc3.y)).rgb * wedge.w
    );

    float fp = fract(src_pos.y-0.5);
    if (InputSize.y > 400.0) fp = fract(src_pos.y/2.0-0.5);

    if (INTERL == 1.0 && InputSize.y > 400.0) 
    {
    fp = mod(float(FrameCount),2.0) <1.0 ? 0.5+fp:fp;
    }

    float scn  = scan(fp,res) + scan(1.0-fp,res);
    float msk  = MASK*sin(fragpos)+1.0-MASK;
    res *= sqrt(scn*msk);

    float l = dot(vec3(0.29, 0.6, 0.11), res);
    res  = mix(vec3(l), res, SAT);

if (corn.y <= corn.x && CURV == 1.0 || corn.x < 0.0001 && CURV == 1.0 ) res = vec3(0.0);

    FragColor = vec4(res,1.0);
}

#endif
