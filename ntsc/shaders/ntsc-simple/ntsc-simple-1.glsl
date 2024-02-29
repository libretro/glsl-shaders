#version 110

/*
   Simple composite-video (more like RF) like shader by DariusG 2023
   
   This program is free software; you can redistribute it and/or modify it
   under the terms of the GNU General Public License as published by the Free
   Software Foundation; either version 2 of the License, or (at your option)
   any later version.
*/

#pragma parameter ntsc_bri "NTSC Brightness" 1.0 0.0 2.0 0.01
#pragma parameter ntsc_hue "NTSC Hue" -0.2 -2.0 2.0 0.05

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

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float WHATEVER;
#else
#define WHATEVER 0.0
#endif

void main()
{
    gl_Position = MVPMatrix * VertexCoord;
    TEX0.xy = TexCoord.xy*1.0001;
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
uniform COMPAT_PRECISION float ntsc_bri;
uniform COMPAT_PRECISION float ntsc_hue;
uniform COMPAT_PRECISION float animate_afacts;
uniform COMPAT_PRECISION float x_mod;

#else
#define ntsc_bri 1.0
#define ntsc_hue 0.0
#define animate_afacts 1.0
#define x_mod 0.0
#endif


#define TAU  6.28318530717958647693
#define PI 3.1415926


// Colorspace conversion matrix for RGB-to-YUV
// All modern CRTs use YUV instead of YIQ
const mat3 RGBYUV = mat3(0.299, 0.587, 0.114,
                        -0.299, -0.587, 0.886, 
                         0.701, -0.587, -0.114);

void main()
{
    float phase = floor(vTexCoord.x*SourceSize.x)*PI*x_mod - mod(floor(vTexCoord.y*SourceSize.y),2.0)*PI; 
    phase += ntsc_hue;
    vec3 YUV = COMPAT_TEXTURE(Source,vTexCoord).rgb; 
    
     YUV = YUV*RGBYUV;
    
    if (animate_afacts == 1.0) phase += PI*sin(mod(float(FrameCount+1),2.0));
    float signal = ntsc_bri*YUV.x + 0.5*(YUV.y*sin(phase) + YUV.z*cos(phase)) ;   
    FragColor = vec4(vec3(signal), 1.0);
    
}
#endif
