#version 110

// crt-m7 shader
// this shader was written to push my old HTC One m7 as much as it gets
// on a 2012/13 GPU of around 57 gflops and GLES 2.0.
// Written by DariusG Aug/2023

// This program is free software; you can redistribute it and/or modify it
// under the terms of the GNU General Public License as published by the Free
// Software Foundation; either version 2 of the License, or (at your option)
// any later version.


#pragma parameter scanline "Scanline Strength" 0.75 0.0 1.0 0.05
#pragma parameter SIZE "Mask Type" 1.0 0.666 1.0 0.3333
#pragma parameter cspace "Color Space: RGB, Trinitron PAL" 0.0 0.0 1.0 1.0

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

const mat3 TRIN = mat3(
1.17870044,  -0.1317718,  -0.00688924,
0.04251778,  0.97897526,  -0.0177807,
0.0312456 ,  0.05239924,  1.01142244
);

float vign()
{
    vec2 vpos = warpp;
    vpos *= warppm;    
    float vig = vpos.x * vpos.y * 50.0;
    vig = min(sqrt(vig), 1.0); 
   
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
    p.x = mix( p.x , vTexCoord.x, 0.4);

    vec3 res = COMPAT_TEXTURE(Source,p).rgb;

// crt-Geom-like pixel luminance influence on scanline
    float lum = 2.0+dot(vec3(0.666),res);
    float scan = pow(scanline,lum); // 2 + lum (max 2), more 'lum' leads to less 'scan'.
    
    if (InputSize.x < 400.0)
    res *= 0.4+(scan*sin(pos.y*omega)+1.0-scan)/(0.8+0.15*lum);
    
    res *= 0.4+(0.3*sin(fragpos)+0.7)/(0.8+0.15*lum);
    
    if (cspace !=0.0)
    {
    res *= TRIN;
    }   
// Corners cut
    vec2 c = warpp;
    vec2 corn   = min(c, warppm);    
    corn.x = 0.000333/corn.x;          
   
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

    res *= vign();
    // Output to screen
    FragColor = vec4(res,1.0);
}
#endif
