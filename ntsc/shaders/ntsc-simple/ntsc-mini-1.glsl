#version 110

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
uniform COMPAT_PRECISION float FIR_GAIN;

#else
#define FIR_GAIN 1.0
#endif
const mat3 YIQ2RGB = mat3(1.000, 1.000, 1.000,
                          0.956,-0.272,-1.106,
                          0.621,-0.647, 1.703);

void main()
{
vec2 ps = vec2(SourceSize.z, 0.0);

// FIR gaussian moving average calculated at https://fiiir.com/
vec3 c40 = COMPAT_TEXTURE(Source,vTexCoord-4.0*ps).rgb*0.011002004494348790;
float phase40 = ((vTexCoord.x*SourceSize.x+vTexCoord.y*SourceSize.y)-4.0)*3.1415926*0.6666;
c40.yz *= vec2(cos(phase40),sin(phase40));

vec3 c30 = COMPAT_TEXTURE(Source,vTexCoord-3.0*ps).rgb*0.043175145021758329;
float phase30 = ((vTexCoord.x*SourceSize.x+vTexCoord.y*SourceSize.y)-3.0)*3.1415926*0.6666;
c30.yz *= vec2(cos(phase30),sin(phase30));

vec3 c20 = COMPAT_TEXTURE(Source,vTexCoord-2.0*ps).rgb*0.114643519437383018;
float phase20 = ((vTexCoord.x*SourceSize.x+vTexCoord.y*SourceSize.y)-2.0)*3.1415926*0.6666;
c20.yz *= vec2(cos(phase20),sin(phase20));

vec3 c10 = COMPAT_TEXTURE(Source,vTexCoord-ps).rgb*0.205977096991565828;
float phase10 = ((vTexCoord.x*SourceSize.x+vTexCoord.y*SourceSize.y)-1.0)*3.1415926*0.6666;
c10.yz *= vec2(cos(phase10),sin(phase10));

vec3 c00 = COMPAT_TEXTURE(Source,vTexCoord).rgb*0.250404468109888034;
float phase = ((vTexCoord.x*SourceSize.x+vTexCoord.y*SourceSize.y))*3.1415926*0.6666;
c00.yz *= vec2(cos(phase),sin(phase));

vec3 c01 = COMPAT_TEXTURE(Source,vTexCoord+ps).rgb*0.205977096991565828;
float phase01 = ((vTexCoord.x*SourceSize.x+vTexCoord.y*SourceSize.y)+1.0)*3.1415926*0.6666;
c01.yz *= vec2(cos(phase01),sin(phase01));

vec3 c02 = COMPAT_TEXTURE(Source,vTexCoord+2.0*ps).rgb*0.114643519437383018;
float phase02 = ((vTexCoord.x*SourceSize.x+vTexCoord.y*SourceSize.y)+2.0)*3.1415926*0.6666;
c02.yz *= vec2(cos(phase02),sin(phase02));

vec3 c03 = COMPAT_TEXTURE(Source,vTexCoord+3.0*ps).rgb*0.043175145021758329;
float phase03 = ((vTexCoord.x*SourceSize.x+vTexCoord.y*SourceSize.y)+3.0)*3.1415926*0.6666;
c03.yz *= vec2(cos(phase03),sin(phase03));

vec3 c04 = COMPAT_TEXTURE(Source,vTexCoord+4.0*ps).rgb*0.011002004494348790;
float phase04 = ((vTexCoord.x*SourceSize.x+vTexCoord.y*SourceSize.y)+4.0)*3.1415926*0.6666;
c04.yz *= vec2(cos(phase04),sin(phase04));

vec3 res = c40+c30+c20+c10+c00+c01+c02+c03+c04;
res *= YIQ2RGB;
FragColor.rgb = res;
}
#endif