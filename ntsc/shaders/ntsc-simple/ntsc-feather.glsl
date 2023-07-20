#version 110

/*
   Simple S-video like shader by DariusG 2023
   This program is free software; you can redistribute it and/or modify it
   under the terms of the GNU General Public License as published by the Free
   Software Foundation; either version 2 of the License, or (at your option)
   any later version.
*/

#define iTime float(FrameCount)
#define pi 3.141592
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

void main()
{
    gl_Position = MVPMatrix * VertexCoord;
    TEX0.xy = TexCoord.xy;
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

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float GLITCH;

#else
#define GLITCH 0.1
#endif


const mat3 rgb2yuv = mat3(0.299,-0.14713, 0.615,
                           0.587,-0.28886,-0.51499,
                           0.114, 0.436  ,-0.10001);

const mat3 yuv2rgb = mat3(1.0, 1.0, 1.0,
                 0.0,-0.39465,2.03211,
                 1.13983,-0.58060,0.0);

void main()
{
vec2 pos = vTexCoord;

vec3 res = texture2D(Source,pos).rgb;

vec3 leftp = texture2D(Source,pos-vec2(SourceSize.z,0.0)).rgb;
vec3 rightp = texture2D(Source,pos+vec2(SourceSize.z,0.0)).rgb;
vec3 dither = (leftp+rightp)/2.0;

res = rgb2yuv*res; dither =rgb2yuv*dither;
res =dither*0.49+res*0.51; //just keep a tiny evidence of dither

vec3 check = texture2D(Source, pos + vec2(SourceSize.z,0.0)).rgb; 
check = rgb2yuv*check;

float lum_diff= abs(check.r-res.r); 
float chr_diff= abs(check.g-res.g); 

//flicker on luma/chroma difference
res +=lum_diff*abs(sin(iTime))*0.1;
res +=chr_diff*abs(sin(iTime))*0.1;

res = yuv2rgb*res;
FragColor = vec4(res,1.0);
}
#endif
