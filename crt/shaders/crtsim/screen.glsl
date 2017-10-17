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

#define half4 vec4
#define half3 vec3
#define half2 vec2
#define half float
#define lerp(a, b, c) mix(a, b, c)
#define tex2D(a, b) COMPAT_TEXTURE(a, b)
#define mul(a, b) (b * a)
#define saturate(c) clamp(c, 0.0, 1.0)

#define CRTMask_Scale 0.25
#define Tuning_Satur 1.0
#define Tuning_Mask_Brightness 0.5
#define Tuning_Mask_Opacity 0.34

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
// out variables go here as COMPAT_VARYING whatever

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
uniform sampler2D shadowMaskSampler;
COMPAT_VARYING vec4 TEX0;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutputSize vec4(OutputSize, 1.0 / OutputSize)

half4 SampleCRT(sampler2D shadowMaskSampler, sampler2D compFrameSampler, half2 uv)
{
	half2 ScaledUV = uv;
//	ScaledUV *= UVScalar;
//	ScaledUV += UVOffset;

	half2 scanuv = fract(uv / CRTMask_Scale * 10.0);
	vec4 phosphor_grid;
	half3 scantex = tex2D(shadowMaskSampler, scanuv).rgb;
	
	scantex += Tuning_Mask_Brightness;			// adding looks better
	scantex = lerp(ivec3(1,1,1), scantex, Tuning_Mask_Opacity);
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
	emissive = lerp(half4(desat,desat,desat,1), emissive, Tuning_Satur);
	
	return emissive;
}

void main()
{
	vec2 fragcoord = (vTexCoord * (SourceSize.xy / InputSize.xy)) * (InputSize.xy / SourceSize.xy);
	FragColor = vec4(SampleCRT(shadowMaskSampler, Source, fragcoord));
} 
#endif
