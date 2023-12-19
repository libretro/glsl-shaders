#version 110

/*
NTSC-mini DariusG 2023

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 2 of the License, or (at your option)
any later version.
*/
#pragma parameter rainbow "Rainbow Effect" 0.0 0.0 1.0 1.0
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
#define vTexCoord TEX0.xy
#define Source Texture
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float rainbow;
uniform COMPAT_PRECISION float compo;

#else
#define rainbow 1.0
#define compo 1.0
#endif
const mat3 YIQ2RGB = mat3(1.000, 1.000, 1.000,
                          0.956,-0.272,-1.106,
                          0.621,-0.647, 1.703);
#define pi23 2.09439506667

void main()
{
vec2 ps = vec2(SourceSize.z, 0.0);
float pattern = vTexCoord.x*SourceSize.x+vTexCoord.y*SourceSize.y;
if (compo == 1.0 && rainbow == 1.0) pattern = vTexCoord.x*SourceSize.x;

// FIR moving average calculated at https://fiiir.com/
vec3 c30 = COMPAT_TEXTURE(Source,vTexCoord-3.0*ps).rgb*0.019775776609144702;
float phase30 = (pattern-3.0)*pi23;
c30.yz *= vec2(cos(phase30),sin(phase30));

vec3 c20 = COMPAT_TEXTURE(Source,vTexCoord-2.0*ps).rgb*0.101190476190476164;
float phase20 = (pattern-2.0)*pi23;
c20.yz *= vec2(cos(phase20),sin(phase20));

vec3 c10 = COMPAT_TEXTURE(Source,vTexCoord-ps).rgb*0.230224223390855270;
float phase10 = (pattern-1.0)*pi23;
c10.yz *= vec2(cos(phase10),sin(phase10));

vec3 c00 = COMPAT_TEXTURE(Source,vTexCoord).rgb*0.297619047619047616;
float phase = pattern*pi23;
c00.yz *= vec2(cos(phase),sin(phase));

vec3 c01 = COMPAT_TEXTURE(Source,vTexCoord+ps).rgb*0.230224223390855270;
float phase01 = (pattern+1.0)*pi23;
c01.yz *= vec2(cos(phase01),sin(phase01));

vec3 c02 = COMPAT_TEXTURE(Source,vTexCoord+2.0*ps).rgb*0.101190476190476164;
float phase02 = (pattern+2.0)*pi23;
c02.yz *= vec2(cos(phase02),sin(phase02));

vec3 c03 = COMPAT_TEXTURE(Source,vTexCoord+3.0*ps).rgb*0.019775776609144702;
float phase03 = (pattern+3.0)*pi23;
c03.yz *= vec2(cos(phase03),sin(phase03));

vec3 res = c30+c20+c10+c00+c01+c02+c03;
res *= YIQ2RGB;
//float l = dot(vec3(0.3,0.6,0.1),res);
//res *= mix(1.45,1.05,l);
FragColor.rgb = res;
}
#endif
