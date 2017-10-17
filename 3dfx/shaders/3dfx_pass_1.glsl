// "LeiFX" shader - Pixel filtering process
// 
// 	Copyright (C) 2013-2014 leilei
// 
// This program is free software; you can redistribute it and/or modify it
// under the terms of the GNU General Public License as published by the Free
// Software Foundation; either version 2 of the License, or (at your option)
// any later version.

#define		FILTCAP		0.04	// filtered pixel should not exceed this 
#define		FILTCAPG	(FILTCAP / 2.0)
#define		LEIFX_PIXELWIDTH	0.50

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
precision COMPAT_PRECISION float;
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
#define saturate(c) clamp(c, 0.0, 1.0)
#define lerp(c) mix(c)
#define mul(a,b) (b*a)
#define fmod(c) mod(c)
#define frac(c) fract(c)
#define tex2D(c,d) COMPAT_TEXTURE(c,d)
#define float2 vec2
#define float3 vec3
#define float4 vec4
#define int2 ivec2
#define int3 ivec3
#define int4 ivec4
#define bool2 bvec2
#define bool3 bvec3
#define bool4 bvec4
#define float2x2 mat2x2
#define float3x3 mat3x3
#define float4x4 mat4x4
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define outsize vec4(OutputSize, 1.0 / OutputSize)

void main()
{
	float3 outcolor = tex2D(Source, vTexCoord).rgb;
	
	float2 pixel;

	pixel.x = SourceSize.z;
	pixel.y = SourceSize.w;

	float3 pixel1 = tex2D(Source, vTexCoord + float2((pixel.x), 0.0)).rgb;
	float3 pixel2 = tex2D(Source, vTexCoord + float2(-pixel.x, 0.0)).rgb;
	float3 pixelblend;
	
// New filter
	{
		float3 pixeldiff;
		float3 pixelmake;		
		float3 pixeldiffleft;

		pixelmake.rgb = float3(0.0);
		pixeldiff.rgb = pixel2.rgb- outcolor.rgb;

		pixeldiffleft.rgb = pixel1.rgb - outcolor.rgb;

		if (pixeldiff.r > FILTCAP) 		pixeldiff.r = FILTCAP;
		if (pixeldiff.g > FILTCAPG) 		pixeldiff.g = FILTCAPG;
		if (pixeldiff.b > FILTCAP) 		pixeldiff.b = FILTCAP;

		if (pixeldiff.r < -FILTCAP) 		pixeldiff.r = -FILTCAP;
		if (pixeldiff.g < -FILTCAPG) 		pixeldiff.g = -FILTCAPG;
		if (pixeldiff.b < -FILTCAP) 		pixeldiff.b = -FILTCAP;

		if (pixeldiffleft.r > FILTCAP) 		pixeldiffleft.r = FILTCAP;
		if (pixeldiffleft.g > FILTCAPG) 	pixeldiffleft.g = FILTCAPG;
		if (pixeldiffleft.b > FILTCAP) 		pixeldiffleft.b = FILTCAP;

		if (pixeldiffleft.r < -FILTCAP) 	pixeldiffleft.r = -FILTCAP;
		if (pixeldiffleft.g < -FILTCAPG) 	pixeldiffleft.g = -FILTCAPG;
		if (pixeldiffleft.b < -FILTCAP) 	pixeldiffleft.b = -FILTCAP;

		pixelmake.rgb = (pixeldiff.rgb / 4.0) + (pixeldiffleft.rgb / 16.0);
		outcolor.rgb = (outcolor.rgb + pixelmake.rgb);
	}	
	
   FragColor = vec4(outcolor, 1.0);
} 
#endif
