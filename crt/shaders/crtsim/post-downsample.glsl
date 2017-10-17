#version 130

//////////////////////////////////////////////////////////////////////////
//
// CC0 1.0 Universal (CC0 1.0)
// Public Domain Dedication 
//
// To the extent possible under law, J. Kyle Pittman has waived all
// copyright and related or neighboring rights to this implementation
// of CRT simulation. This work is published from the United States.
//
// For more information, please visit
// https://creativecommons.org/publicdomain/zero/1.0/
//
//////////////////////////////////////////////////////////////////////////

// Multi-purpose code used for both downsampling and upsampling the full-resolution output image.

// Parameter lines go here:
#pragma parameter bloom_scale_down "Downsample Bloom Scale" 0.004 0.0 0.03 0.001

#define half4 vec4
#define half3 vec3
#define half2 vec2
#define half float
#define float2 vec2
#define lerp(a, b, c) mix(a, b, c)
#define tex2D(a, b) COMPAT_TEXTURE(a, b)
#define mul(a, b) (b * a)
#define saturate(c) clamp(c, 0.0, 1.0)

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

void main()
{
    gl_Position = MVPMatrix * VertexCoord;
    COL0 = COLOR;
    TEX0.xy = TexCoord.xy;
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
uniform sampler2D OrigTexture;
#define PreBloomBufferSampler OrigTexture
COMPAT_VARYING vec4 TEX0;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutputSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
// All parameter floats need to have COMPAT_PRECISION in front of them
uniform COMPAT_PRECISION float bloom_scale_down;
#else
#define bloom_scale_down 0.004
#endif

const COMPAT_PRECISION float2 Poisson0 = float2(0.000000, 0.000000);
const COMPAT_PRECISION float2 Poisson1 = float2(0.000000, 1.000000);
const COMPAT_PRECISION float2 Poisson2 = float2(0.000000, -1.000000);
const COMPAT_PRECISION float2 Poisson3 = float2(-0.866025, 0.500000);
const COMPAT_PRECISION float2 Poisson4 = float2(-0.866025, -0.500000);
const COMPAT_PRECISION float2 Poisson5 = float2(0.866025, 0.500000);
const COMPAT_PRECISION float2 Poisson6 = float2(0.866025, -0.500000);

const float InvNumSamples = 0.1428571428571429; //<- 1.0 / number of Poisson samples

void main()
{
	vec4 bloom = vec4(0.0);
	vec2 BloomScale = vec2(bloom_scale_down);
	bloom += tex2D(PreBloomBufferSampler, vTexCoord + (Poisson0 * BloomScale));
	bloom += tex2D(PreBloomBufferSampler, vTexCoord + (Poisson1 * BloomScale));
	bloom += tex2D(PreBloomBufferSampler, vTexCoord + (Poisson2 * BloomScale));
	bloom += tex2D(PreBloomBufferSampler, vTexCoord + (Poisson3 * BloomScale));
	bloom += tex2D(PreBloomBufferSampler, vTexCoord + (Poisson4 * BloomScale));
	bloom += tex2D(PreBloomBufferSampler, vTexCoord + (Poisson5 * BloomScale));
	bloom += tex2D(PreBloomBufferSampler, vTexCoord + (Poisson6 * BloomScale));
	bloom *= InvNumSamples;

   FragColor = vec4(bloom);
} 
#endif
