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

// Blends the original full-resolution scene with the blurred output of post shaders to create bloom.

// Parameter lines go here:
#pragma parameter BloomPower "Bloom Power" 1.0 0.0 10.0 0.1
#pragma parameter BloomScalar "Bloom Scalar" 0.1 0.0 1.0 0.05
#pragma parameter CRTMask_Scale "CRT Mask Scale" 0.25 0.0 0.5 0.01
#pragma parameter Tuning_Satur "Saturation" 1.0 0.0 1.0 0.05
#pragma parameter Tuning_Mask_Brightness "Mask Brightness" 0.5 0.0 1.0 0.05
#pragma parameter Tuning_Mask_Opacity "Mask Opacity" 0.3 0.0 1.0 0.05
//#pragma parameter Tuning_Overscan "Overscan" 0.95 0.0 1.0 0.05
//#pragma parameter Tuning_Barrel "Barrel Distortion" 0.25 0.0 1.0 0.05
#pragma parameter mask_toggle "Mask Toggle" 1.0 0.0 1.0 1.0

#define half4 vec4
#define half3 vec3
#define half2 vec2
#define half float
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
uniform sampler2D Texture;
uniform sampler2D Pass2Texture;
#define CRTPASS Pass2Texture
uniform sampler2D shadowMaskSampler;
COMPAT_VARYING vec4 TEX0;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutputSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
// All parameter floats need to have COMPAT_PRECISION in front of them
uniform COMPAT_PRECISION float BloomPower;
uniform COMPAT_PRECISION float BloomScalar;
//uniform COMPAT_PRECISION float Tuning_Overscan;
//uniform COMPAT_PRECISION float Tuning_Barrel;
uniform COMPAT_PRECISION float mask_toggle;
uniform COMPAT_PRECISION float CRTMask_Scale;
uniform COMPAT_PRECISION float Tuning_Satur;
uniform COMPAT_PRECISION float Tuning_Mask_Brightness;
uniform COMPAT_PRECISION float Tuning_Mask_Opacity;
#else
#define BloomPower 1.0
#define BloomScalar 0.1
//#define Tuning_Overscan 0.95
//#define Tuning_Barrel 0.25
#define mask_toggle 1.0
#define CRTMask_Scale 0.25
#define Tuning_Satur 1.0
#define Tuning_Mask_Brightness 0.5
#define Tuning_Mask_Opacity 0.34
#endif

half4 SampleCRT(sampler2D shadowMaskSampler, sampler2D compFrameSampler, half2 uv)
{
	half2 ScaledUV = uv;
//	ScaledUV *= UVScalar;
//	ScaledUV += UVOffset;

	half2 scanuv = fract(uv / CRTMask_Scale * 100.0);
	vec4 phosphor_grid;
	half3 scantex = tex2D(shadowMaskSampler, scanuv).rgb;
	
	scantex += Tuning_Mask_Brightness;			// adding looks better
	scantex = lerp(vec3(1,1,1), scantex, Tuning_Mask_Opacity);
/*  // commenting this to move to present shader
	// Apply overscan after scanline sampling is done.
	half2 overscanuv = (ScaledUV * Tuning_Overscan) - ((Tuning_Overscan - 1.0) * 0.5);
	
	// Curve UVs for composite texture inwards to garble things a bit.
	overscanuv = overscanuv - half2(0.5,0.5);
	half rsq = (overscanuv.x*overscanuv.x) + (overscanuv.y*overscanuv.y);
	overscanuv = overscanuv + (overscanuv * (Tuning_Barrel * rsq)) + half2(0.5,0.5);
*/
	half2 overscanuv = uv;
	half3 comptex = tex2D(compFrameSampler, overscanuv).rgb;

	half4 emissive = half4(comptex * scantex, 1);
	half desat = dot(half4(0.299, 0.587, 0.114, 0.0), emissive);
	emissive = lerp(half4(desat,desat,desat,1.0), emissive, Tuning_Satur);
	
	return emissive;
}

// Apply power to brightness while preserving color
// TODO: Clamp ActLuma to very small number to prevent (zero) division by zero when a component is zero?
half4 ColorPow(half4 InColor, half InPower)
{
	// This method preserves color better.
	half4 RefLuma = half4(0.299, 0.587, 0.114, 0.0);
	half ActLuma = dot(InColor, RefLuma);
	half4 ActColor = InColor / ActLuma;
	half PowLuma = pow(ActLuma, InPower);
	half4 PowColor = ActColor * PowLuma;
	return PowColor;
}

void main()
{
	vec2 fragcoord = (vTexCoord * (SourceSize.xy / InputSize.xy)) * (InputSize.xy / SourceSize.xy);
	vec2 overscanuv = fragcoord;
	vec4 PreBloom = vec4(0.0);
	/*
	// Apply overscan after scanline sampling is done.
	half2 overscanuv = (vTexCoord * Tuning_Overscan) - ((Tuning_Overscan - 1.0) * 0.5);
	
	// Curve UVs for composite texture inwards to garble things a bit.
	overscanuv = overscanuv - half2(0.5, 0.5);
	half rsq = (overscanuv.x*overscanuv.x) + (overscanuv.y*overscanuv.y);
	overscanuv = overscanuv + (overscanuv * (Tuning_Barrel * rsq)) + half2(0.5, 0.5);
	vec4 PreBloom = vec4(0.0);
	// Mask effect cancels curvature due to righteous moire
	overscanuv = (mask_toggle > 0.5) ? fragcoord : overscanuv; */
	PreBloom = (mask_toggle > 0.5) ? SampleCRT(shadowMaskSampler, CRTPASS, overscanuv) : COMPAT_TEXTURE(CRTPASS, overscanuv);

	vec4 Blurred = COMPAT_TEXTURE(Source, overscanuv);
   FragColor = vec4(PreBloom + (ColorPow(Blurred, BloomPower) * BloomScalar));//vec4(mix(PreBloom, Blurred, mixfactor));
} 
#endif
