#version 130

// Gendither
// 
// 	Copyright (C) 2013-2014 leilei
//  adapted for slang format by hunterk
// 
// This program is free software; you can redistribute it and/or modify it
// under the terms of the GNU General Public License as published by the Free
// Software Foundation; either version 2 of the License, or (at your option)
// any later version.

// This table is a lazy jailbar pattern
int erroredtable[16] = int[](
	0,1,0,1,   
	16,15,16,15,
	0,1,0,1,   
	16,15,16,15
);

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
out mediump vec4 FragColor;
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
#define outsize vec4(OutputSize, 1.0 / OutputSize)

void main()
{
	vec3 final = COMPAT_TEXTURE(Source, vTexCoord).rgb;	
	vec2 ditheu = vTexCoord.xy * SourceSize.xy;

	// Dither
	int ditdex = 	int(mod(ditheu.x, 4.0)) * 4 + int(mod(ditheu.y, 4.0)); // 4x4!
	ivec3 color;
	ivec3 colord;
	color.r = int(final.r) * 224;
	color.g = int(final.g) * 224;
	color.b = int(final.b) * 224;
	int yeh = 0;
	int ohyes = 0;


	// looping through a lookup table matrix
	for (yeh=ditdex; yeh<(ditdex+16); yeh++) ohyes = erroredtable[yeh-15];

	colord.r = color.r + ohyes;
	colord.g = color.g + ohyes;
	colord.b = color.b + ohyes;
	final.rgb += float(colord.rgb) * 0.003921568627451; // divide by 255, i don't trust em

	// Reduce color depth
	float why = 1.0;
	vec3 reduceme = vec3(1.0);
	float radooct = 4.4;	// 32 is usually the proper value // 4.4 was eyeballed

	reduceme.r = pow(final.r, why);  
	reduceme.r *= radooct;	
	reduceme.r = floor(reduceme.r);
	reduceme.r /= radooct; 
	reduceme.r = pow(reduceme.r, why);

	reduceme.g = pow(final.g, why);  
	reduceme.g *= radooct;		
	reduceme.g = floor(reduceme.g);	
	reduceme.g /= radooct;	
	reduceme.g = pow(reduceme.g, why);

	reduceme.b = pow(final.b, why);  
	reduceme.b *= radooct;	
	reduceme.b = floor(reduceme.b);	
	reduceme.b /= radooct;	
	reduceme.b = pow(reduceme.b, why);

	// Brightness cap
	reduceme.rgb = clamp(reduceme.rgb, vec3(0.0), vec3(0.875));
	
   FragColor = vec4(reduceme.rgb, 1.0);
} 
#endif
