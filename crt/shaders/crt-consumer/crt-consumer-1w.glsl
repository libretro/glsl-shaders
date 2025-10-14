#version 110

/*
    crt-consumer-1w, A simple CRT shader by metallic 77.

    This program is free software; you can redistribute it and/or modify it
    under the terms of the GNU General Public License as published by the Free
    Software Foundation; either version 2 of the License, or (at your option)
    any later version.
    
*/
#pragma parameter u_sharp "Reverse Sharpness" 0.25 0.0 0.5 0.01
#pragma parameter u_warp "Curvature" 0.04 0.0 0.15 0.01
#pragma parameter u_overscanx "Overscan Horiz." 0.3 0.3 2.0 0.05
#pragma parameter u_overscany "Overscan Vertic." 0.3 0.3 2.0 0.05
#pragma parameter u_scan "Scanlines Strength" 0.35 0.0 1.0 0.05
#pragma parameter u_mask "Mask Strength" 0.25 0.0 1.0 0.05
#pragma parameter u_wid "Mask Fine/Coarse" 2.0 2.0 3.0 1.0
#pragma parameter u_deconv "De-Convergence Horiz." 0.3 -2.0 2.0 0.05
#pragma parameter u_brightb "Bright Boost" 1.35 1.0 2.0 0.05
#pragma parameter u_vignette "Vignette" 0.15 0.0 0.5 0.01

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
COMPAT_VARYING vec2 TEX0;
COMPAT_VARYING vec2 ogl2pos;
COMPAT_VARYING vec2 invdims;
COMPAT_VARYING vec2 maskpos;
COMPAT_VARYING vec2 scale;
COMPAT_VARYING vec2 barrel;

uniform mat4 MVPMatrix;
uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float u_deconv;
uniform COMPAT_PRECISION float u_wid;
uniform COMPAT_PRECISION float u_warp;
uniform COMPAT_PRECISION float u_overscanx;
uniform COMPAT_PRECISION float u_overscany;
#else
#define u_deconv 0.5
#define u_wid 2.0
#define u_warp 0.05
#define u_overscanx 0.3
#define u_overscany 0.3

#endif

void main()
{
    gl_Position = MVPMatrix * VertexCoord;
    TEX0 = TexCoord.xy*1.0001;
    ogl2pos = TEX0.xy*TextureSize;
    invdims = u_deconv/TextureSize;
    scale = TextureSize/InputSize;
    maskpos = TEX0.xy*scale*OutputSize.xy*2.0/u_wid;
    barrel = vec2(1.0-u_warp*u_overscanx, 1.0-u_warp*u_overscany);

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
COMPAT_VARYING vec2 TEX0;
COMPAT_VARYING vec2 ogl2pos;
COMPAT_VARYING vec2 invdims;
COMPAT_VARYING vec2 maskpos;
COMPAT_VARYING vec2 scale;
COMPAT_VARYING vec2 barrel;

#define Source Texture
#define vTexCoord TEX0.xy

uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float u_brightb;
uniform COMPAT_PRECISION float u_scan;
uniform COMPAT_PRECISION float u_vignette;
uniform COMPAT_PRECISION float u_warp;
uniform COMPAT_PRECISION float u_mask;
uniform COMPAT_PRECISION float u_sharp;

#else
#define u_brightb 1.25
#define u_scan 0.3
#define u_vignette 0.1
#define u_warp 0.1
#define u_mask 0.3
#define u_sharp 0.15

#endif

#define PI 3.14159265358979323846 
#define TAU 6.2831852
#define pixel 1.0/TextureSize

vec3 toLinear(vec3 c) { return c * c; }
vec3 toGamma(vec3 c) { return sqrt(c); }

void main() {
    // uv in [0,1]
    vec2 uv = TEX0*scale;
    // keep "crt frame" stable regardless of overscan
    vec2 pos = uv;
    // --- Barrel warp ---
    // normalized coords centered at 0
    vec2 n = uv * 2.0 - 1.0;
    // polynomial warp
    float rsq = dot(n, n);
    n *= 1.0 + u_warp*rsq*1.5;
    n -= n*(barrel*u_warp);
    n *= barrel;
    uv = (n + 1.0) * 0.5;
    vec2 corn   = min(pos, 1.0-pos); // This is used to mask the rounded
         corn.x = 0.0012/corn.x;   // corners later on 

    uv /= scale;
    
    // pixel size for subpixel offsets
    float px = invdims.x;
    // chroma separation: shift R and B horizontally by +/- small amounts
    vec2 offR = vec2(  px, 0.0);
    vec2 offB = vec2(- px, 0.0);
    vec2 dx = vec2(pixel.x, 0.0);

    // fetch center (G), left/right for R/B
    vec3 colG = COMPAT_TEXTURE(Texture, uv).rgb;
    vec3 colR = COMPAT_TEXTURE(Texture, uv + offR).rgb;
    vec3 colB = COMPAT_TEXTURE(Texture, uv + offB).rgb;

    // reconstruct approximate RGB (we sampled full RGB for each tap,
    // but treat them as subpixel contributions)
    vec3 col = vec3(colR.r, colG.g, colB.b);
    vec3 sharpl  = COMPAT_TEXTURE(Texture, uv      -dx).rgb*(-u_sharp);
    vec3 sharpl2 = COMPAT_TEXTURE(Texture, uv - 2.0*dx).rgb*(u_sharp*0.1);
    vec3 sharpr  = COMPAT_TEXTURE(Texture, uv     + dx).rgb*(-u_sharp);
    vec3 sharpr2 = COMPAT_TEXTURE(Texture, uv + 2.0*dx).rgb*(u_sharp*0.1);
    
    col = col*(1.0 + u_sharp*1.8) + sharpl+sharpr+sharpl2+sharpr2;

    // --- Scanlines / Mask ---
    float scan = 0.5*sin((uv.y*TextureSize.y-0.25)*TAU)+0.5;
    float mask = 0.5*sin((maskpos.x)*PI)+0.5;
    col *= mix(1.0, scan, u_scan);
    col *= mix(u_brightb, mask, u_mask);


    // --- Vignette ---
    float vig = 1.0 - u_vignette * pow(length(n), 1.5);
    col *= vig;
if (u_warp > 0.0){  
if (corn.y <= corn.x || corn.x < 0.0001)
    col = vec3(0.0);}
    FragColor = vec4(col, 1.0);
}
#endif
