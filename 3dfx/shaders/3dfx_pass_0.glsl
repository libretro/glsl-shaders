// "LeiFX" shader - "dither" and reduction process
// 
// 	Copyright (C) 2013-2014 leilei
// 
// This program is free software; you can redistribute it and/or modify it
// under the terms of the GNU General Public License as published by the Free
// Software Foundation; either version 2 of the License, or (at your option)
// any later version.

// This table came from the wikipedia article about Ordered Dithering. NOT MAME.  Just to clarify.
//int erroredtable[16] = {
//	16,4,13,1,   
//	8,12,5,9,
//	14,2,15,3,
//	6,10,7,11		
//};

#define DITHERAMOUNT		0.5 // was 0.33f
#define DITHERBIAS		-1.0  // 0 to 16, biases the value of the dither up.  - was 8

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

// Parameter lines go here:
#pragma parameter LEIFX_LINES "LeiFX Line Intensity" 0.05 0.00 1.00 0.01
#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float LEIFX_LINES;
#else
#define LEIFX_LINES 0.05
#endif

float erroredtable0 = 16.0;
float erroredtable1 = 4.0;
float erroredtable2 = 13.0;
float erroredtable3 = 1.0;
float erroredtable4 = 8.0;
float erroredtable5 = 12.0;
float erroredtable6 = 5.0;
float erroredtable7 = 9.0;
float erroredtable8 = 14.0;
float erroredtable9 = 2.0;
float erroredtable10 = 15.0;
float erroredtable11 = 3.0;
float erroredtable12 = 6.0;
float erroredtable13 = 10.0;
float erroredtable14 = 7.0;
float erroredtable15 = 11.0;

void main()
{
// Paste fragment contents here:

	float2 res;
	float3 outcolor = COMPAT_TEXTURE(Source, vTexCoord).rgb;
	res.x = SourceSize.x;
	res.y = SourceSize.y;
	
	float2 ditheu = vTexCoord.xy * res.xy;

	ditheu.x = vTexCoord.x * res.x;
	ditheu.y = vTexCoord.y * res.y;

	// Dither. Total rewrite.
	// NOW, WHAT PIXEL AM I!??

	float ditdex = 	(mod(ditheu.x, 4.0)) * 4.0 + (mod(ditheu.y, 4.0)); // 4x4!
	vec3 color;
	vec3 colord;
	color.r = outcolor.r * 255.0;
	color.g = outcolor.g * 255.0;
	color.b = outcolor.b * 255.0;
	float yeh = 0.0;
	float ohyes = 0.0;
	
//	for (yeh=ditdex; yeh<(ditdex+16); yeh++) ohyes = pow(erroredtable[yeh-15], 0.72f);
	if (yeh++==ditdex) ohyes = float(erroredtable0);
	else if (yeh++==ditdex) ohyes = float(erroredtable1);
	else if (yeh++==ditdex) ohyes = float(erroredtable2);
	else if (yeh++==ditdex) ohyes = float(erroredtable3);
	else if (yeh++==ditdex) ohyes = float(erroredtable4);
	else if (yeh++==ditdex) ohyes = float(erroredtable5);
	else if (yeh++==ditdex) ohyes = float(erroredtable6);
	else if (yeh++==ditdex) ohyes = float(erroredtable7);
	else if (yeh++==ditdex) ohyes = float(erroredtable8);
	else if (yeh++==ditdex) ohyes = float(erroredtable9);
	else if (yeh++==ditdex) ohyes = float(erroredtable10);
	else if (yeh++==ditdex) ohyes = float(erroredtable11);
	else if (yeh++==ditdex) ohyes = float(erroredtable12);
	else if (yeh++==ditdex) ohyes = float(erroredtable13);
	else if (yeh++==ditdex) ohyes = float(erroredtable14);
	else if (yeh++==ditdex) ohyes = float(erroredtable15);
	
	// Adjust the dither thing
	ohyes = 17.0 - (ohyes - 1.0); // invert
	ohyes *= DITHERAMOUNT;
	ohyes += DITHERBIAS;

	colord.r = color.r + ohyes;
	colord.g = color.g + (ohyes / 2.0);
	colord.b = color.b + ohyes;
	outcolor.rgb = colord.rgb * 0.003921568627451; // divide by 255, i don't trust em
	
	//
	// Reduce to 16-bit color
	//

	float3 why = float3(1.0);
	float3 reduceme = float3(1.0);
	float radooct = 32.0;	// 32 is usually the proper value

	reduceme.r = pow(outcolor.r, why.r);  
	reduceme.r *= radooct;	
	reduceme.r = (floor(reduceme.r));	
	reduceme.r /= radooct; 
	reduceme.r = pow(reduceme.r, why.r);

	reduceme.g = pow(outcolor.g, why.g);  
	reduceme.g *= radooct * 2.0;	
	reduceme.g = (floor(reduceme.g));	
	reduceme.g /= radooct * 2.0; 
	reduceme.g = pow(reduceme.g, why.g);

	reduceme.b = pow(outcolor.b, why.b);  
	reduceme.b *= radooct;	
	reduceme.b = (floor(reduceme.b));	
	reduceme.b /= radooct; 
	reduceme.b = pow(reduceme.b, why.b);

	outcolor.rgb = reduceme.rgb;

	// Add the purple line of lineness here, so the filter process catches it and gets gammaed.
	{
		float leifx_linegamma = (LEIFX_LINES / 10.0);
		float horzline1 = 	(mod(ditheu.y, 	2.0));
		if (horzline1 < 1.0)	leifx_linegamma = 0.0;
	
		outcolor.r += leifx_linegamma;
		outcolor.b += leifx_linegamma;	
	}
	
   FragColor = vec4(outcolor, 1.0);
} 
#endif
