#version 110

/*
   Simple S-video like shader by DariusG 2023
   
   This program is free software; you can redistribute it and/or modify it
   under the terms of the GNU General Public License as published by the Free
   Software Foundation; either version 2 of the License, or (at your option)
   any later version.
*/

#pragma parameter NTSC_sat "NTSC SATURATION" 1.0 0.0 4.0 0.05
#pragma parameter NTSC_bri "NTSC BRIGHTNESS" 1.0 0.0 2.0 0.05
#pragma parameter FRINGING "NTSC FRINGING" 0.15 0.0 1.0 0.05
#pragma parameter ARTIFACTING "NTSC ARTIFACTING" 0.25 0.0 1.0 0.05

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
uniform COMPAT_PRECISION float NTSC_sat;
uniform COMPAT_PRECISION float NTSC_bri;
uniform COMPAT_PRECISION float FRINGING;
uniform COMPAT_PRECISION float ARTIFACTING;

#else
#define NTSC_sat 1.0
#define NTSC_bri 1.0
#define FRINGING 1.0
#define ARTIFACTING 1.0
#endif


#define TAU  6.28318530717958647693
#define PI 3.1415926

const mat3 RGBYIQ = mat3(0.299, 0.596, 0.211,
                             0.587,-0.274,-0.523,
                             0.114,-0.322, 0.312);

void main()
{
   
mat3 mix_mat = mat3(NTSC_bri  , FRINGING      , FRINGING, 
                   ARTIFACTING, 2.0 * NTSC_sat, 0.0, 
                   ARTIFACTING, 0.0           , 2.0 * NTSC_sat);


    float phase = (vTexCoord.x*SourceSize.x+vTexCoord.y*SourceSize.y) * PI/2.0;
    vec3 YIQ = COMPAT_TEXTURE(Source,vTexCoord).rgb; 
    YIQ = YIQ*RGBYIQ; 
    vec3 signal = vec3(YIQ.x, cos(phase)*YIQ.y,  YIQ.z*sin(phase) );   
    FragColor = vec4(signal*mix_mat, 1.0);
    
}
#endif
