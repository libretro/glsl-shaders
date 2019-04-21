#version 130

// license:BSD-3-Clause
// copyright-holders:Ryan Holtz,ImJezze
//-----------------------------------------------------------------------------
// Downsample Effect
//-----------------------------------------------------------------------------

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
COMPAT_VARYING vec4 TexCoord01;
COMPAT_VARYING vec4 TexCoord23;

const vec2 Coord0Offset = vec2(-0.5, -0.5);
const vec2 Coord1Offset = vec2( 0.5, -0.5);
const vec2 Coord2Offset = vec2(-0.5,  0.5);
const vec2 Coord3Offset = vec2( 0.5,  0.5);

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
	vec2 HalfTargetTexelDims = 0.5 * SourceSize.zw;

	TexCoord01.xy = TexCoord.xy + Coord0Offset * HalfTargetTexelDims;
	TexCoord01.zw = TexCoord.xy + Coord1Offset * HalfTargetTexelDims;
	TexCoord23.xy = TexCoord.xy + Coord2Offset * HalfTargetTexelDims;
	TexCoord23.zw = TexCoord.xy + Coord3Offset * HalfTargetTexelDims;
}

#elif defined(FRAGMENT)

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

#if __VERSION__ >= 130
#define COMPAT_VARYING in
#define COMPAT_TEXTURE texture
out COMPAT_PRECISION vec4 FragColor;
#else
#define COMPAT_VARYING varying
#define FragColor gl_FragColor
#define COMPAT_TEXTURE texture2D
#endif

uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;
uniform sampler2D Texture;
COMPAT_VARYING vec4 TEX0;
COMPAT_VARYING vec4 TexCoord01;
COMPAT_VARYING vec4 TexCoord23;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

#define DiffuseSampler Source

void main()
{
	vec3 texel0 = COMPAT_TEXTURE(DiffuseSampler, TexCoord01.xy).rgb;
	vec3 texel1 = COMPAT_TEXTURE(DiffuseSampler, TexCoord01.zw).rgb;
	vec3 texel2 = COMPAT_TEXTURE(DiffuseSampler, TexCoord23.xy).rgb;
	vec3 texel3 = COMPAT_TEXTURE(DiffuseSampler, TexCoord23.zw).rgb;

	vec3 outTexel = (texel0 + texel1 + texel2 + texel3) / 4.0;

    FragColor = vec4(outTexel, 1.0);
} 
#endif
