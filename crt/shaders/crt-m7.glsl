#version 110

// crt-m7 shader
// this shader was written to push my old HTC One m7 as much as it gets
// on a 2012/13 GPU of around 57 gflops and GLES 2.0.
// Written by DariusG Aug/2023

// This program is free software; you can redistribute it and/or modify it
// under the terms of the GNU General Public License as published by the Free
// Software Foundation; either version 2 of the License, or (at your option)
// any later version.


#pragma parameter scanline "Scanline Strength" 0.8 0.0 1.0 0.05
#pragma parameter SIZE "Mask Type: Coarse/Fine" 1.0 0.666 1.0 0.3333
#pragma parameter cspace "Color Space: RGB, PAL,NTSC-U,NTSC-J" 2.0 0.0 3.0 1.0

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
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float SIZE;

#else
#define SIZE     1.0      
   
#endif

void main()
{
    gl_Position = MVPMatrix * VertexCoord;
    TEX0.xy = TexCoord.xy;

// pass stuff on vertex and gain a truckload of fps    
    scale = SourceSize.xy/InputSize.xy;
    fragpos = TEX0.x*OutputSize.x*scale.x*PI*SIZE;
    warpp = TEX0.xy*scale;   
    warppm = 1.0-warpp;   
    warp = warpp*2.0-1.0;   
    omega = SourceSize.y*2.0*PI; 
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
uniform COMPAT_PRECISION float scanline;
uniform COMPAT_PRECISION float cspace;

#else
#define scanline  0.75      
#define cspace  0.0

#endif

vec2 Warp(vec2 pos)
{
    pos *= vec2 (1.0 + pos.y*pos.y*0.0275, 
                 1.0 + pos.x*pos.x*0.045 );
    pos = pos * 0.5 +0.5;
    return pos;
}

const mat3 PAL = mat3(
0.9792,  -0.0141, 0.0305,
-0.0139, 0.9992,  0.0129,
-0.0054, -0.0042, 1.1353

);

const mat3 NTSC = mat3(
0.8870,  0.0451,  0.0566,
-0.0800, 1.0368,  0.0361,
0.0053,  -0.1196, 1.2320

);

const mat3 NTSC_J = mat3(
0.7203,  0.1344 , 0.1233,
-0.1051, 1.0305,  0.0637,
0.0127 , -0.0743, 1.3545

);

float vign()
{
    vec2 vpos = warpp;
    vpos *= warppm;    
    float vig = vpos.x * vpos.y * 45.0;

    // desmos calc. equal to pow(vig,0.2)
    // remove expensive pow functions for speed up

    vig = min(0.52+sqrt(vig*0.2544), 1.0); 
   
    return vig;
}


void main()
{
    vec2 pos = Warp(warp)/scale; 

// Quilez Scaling
     vec2 p = pos * TextureSize;
     vec2 i = floor(p) + 0.5;
     vec2 f = p - i;
    p = (i + 4.0*f*f*f)*SourceSize.zw;
    p.x = mix(p.x, pos.x, 0.2);

    vec3 res = COMPAT_TEXTURE(Source,p).rgb;

// crt-Geom-like pixel luminance influence on scanline
    float wid = 2.0+dot(vec3(0.666),res);
    
    res *= res;
    float scan = pow(scanline,wid); // 2 + wid (max 2), more 'wid' leads to less 'scan'.
    
    if (InputSize.y < 400.0)
    res *= 0.4+(scan*sin(pos.y*omega-1.5)+1.0-scan)/(0.8+0.15*wid);
    
    res *= 0.4+(0.4*sin(fragpos)+0.6)/(0.8+0.15*wid);
    
    if (cspace == 1.0) res *= PAL; 
    if (cspace == 2.0) res *= NTSC; 
    if (cspace == 3.0) res *= NTSC_J; 

    if (cspace != 0.0) res = clamp(res,0.0,1.0);
// Corners cut
    vec2 c = warpp;
    vec2 corn   = min(c, warppm);    
    corn.x = 0.0005/corn.x;          
  
   res *= vign();
   res = sqrt(res);

   if (corn.y <= corn.x || corn.x < 0.0001)
    res = vec3(0.0);

// GLES fix
#if defined GL_ES
    vec2 bordertest = p;
    if ( bordertest.x > 0.0001 && bordertest.x < 0.9999 && bordertest.y > 0.0001 && bordertest.y < 0.9999)
        res = res;
    else
        res = vec3(0.0);
#endif
    
    // Output to screen
    FragColor = vec4(res,1.0);
}
#endif
