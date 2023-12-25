#version 110

#pragma parameter compo "S-Video/Composite" 1.0 0.0 1.0 1.0

/*
NTSC-mini DariusG 2023

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 2 of the License, or (at your option)
any later version.
*/

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
uniform COMPAT_PRECISION float compo;
uniform COMPAT_PRECISION float rainbow;

#else
#define compo 1.0
#define rainbow 1.0
#endif

const mat3 YIQ2RGB = mat3(1.000, 1.000, 1.000,
                          0.956,-0.272,-1.106,
                          0.621,-0.647, 1.703);

const mat3 RGBYIQ = mat3(0.299, 0.596, 0.211,
                         0.587,-0.274,-0.523,
                         0.114,-0.322, 0.312);
#define pi23 3.1415926/2.0

void main()
{
vec2 ps = vec2(SourceSize.z, 0.0);
// predict the half res. x after this pass (/2.0 the x freq)
float pattern = vTexCoord.x*SourceSize.x/2.0+vTexCoord.y*SourceSize.y;
if (rainbow == 1.0) pattern = vTexCoord.x/2.0*SourceSize.x;

float phase = pattern*pi23;
vec3 c00 = COMPAT_TEXTURE(Source,vTexCoord).rgb;
// I-Q should have half bandwidth than Y
vec3 c01 = COMPAT_TEXTURE(Source,vTexCoord+ps).rgb;
c00 = vec3(c00.r,c01.gb*0.5+c00.gb*0.5);

c00 *= RGBYIQ;
vec3 osc = vec3(0.0);

// tweak to adjust for pinkish tint 
if (compo == 1.0) osc = vec3(1.0,1.0*cos(phase),1.0*sin(phase));
if (compo == 0.0) osc = vec3(1.0,2.0*cos(phase),2.0*sin(phase));
c00 *= osc;

// send compo as 1 signal combined
float res = dot(c00,vec3(1.0));

// true luma-chroma s-video (send chroma as 1 signal)
c00.yz = vec2(dot(c00.yz,vec2(1.0)));

if (compo == 1.0) FragColor.rgb = vec3(res);
else FragColor.rgb = c00;

}
#endif
