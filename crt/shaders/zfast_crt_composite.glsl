/*
    zfast_crt - A very simple CRT shader.

    Copyright (C) 2017 Greg Hogan (SoltanGris42)
	edited by metallic 77.

    This program is free software; you can redistribute it and/or modify it
    under the terms of the GNU General Public License as published by the Free
    Software Foundation; either version 2 of the License, or (at your option)
    any later version.

*/

//For testing compilation 
//#define FRAGMENT
//#define VERTEX
#define pi 3.14159
// Compatibility #ifdefs needed for parameters
#ifdef GL_ES
#define COMPAT_PRECISION mediump
#else
#define COMPAT_PRECISION
#endif

// Parameter lines go here:
#pragma parameter blurx "Convergence X-Axis" 0.45 -1.0 1.0 0.05
#pragma parameter blury "Convergence Y-Axis" -0.25 -1.0 1.0 0.05
#pragma parameter HIGHSCANAMOUNT1 "Scanline Amount (Low)" 0.3 0.0 1.0 0.05
#pragma parameter HIGHSCANAMOUNT2 "Scanline Amount (High)" 0.2 0.0 1.0 0.05
#pragma parameter MASK_DARK "Mask Effect Amount" 0.25 0.0 1.0 0.05
#pragma parameter MASK_FADE "Mask/Scanline Fade" 0.8 0.0 1.0 0.05
#pragma parameter sat "Saturation" 1.1 0.0 3.0 0.05

#ifdef PARAMETER_UNIFORM
// All parameter floats need to have COMPAT_PRECISION in front of them
uniform COMPAT_PRECISION float blurx;
uniform COMPAT_PRECISION float blury;
uniform COMPAT_PRECISION float HIGHSCANAMOUNT1;
uniform COMPAT_PRECISION float HIGHSCANAMOUNT2;
uniform COMPAT_PRECISION float MASK_DARK;
uniform COMPAT_PRECISION float MASK_FADE;
uniform COMPAT_PRECISION float sat;
#else
#define blurx 0.35
#define blury -0.15
#define HIGHSCANAMOUNT1  0.30
#define HIGHSCANAMOUNT2  0.20
#define MASK_DARK 0.25
#define MASK_FADE 0.8
#define sat 1.0
#endif

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
COMPAT_VARYING float maskFade;

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
	TEX0.xy = TexCoord.xy*1.0001;
	maskFade = 0.3333*MASK_FADE;
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
// in variables go here as COMPAT_VARYING whatever
COMPAT_VARYING float maskFade;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy
#define texture(c, d) COMPAT_TEXTURE(c, d)
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

void main()
{
	COMPAT_PRECISION vec2 pos = TEX0.xy;	

	COMPAT_PRECISION vec3 sample1 = COMPAT_TEXTURE(Source,vec2(pos.x + blurx/1000.0, pos.y - blury/1000.0)).rgb;
	COMPAT_PRECISION vec3 sample2 = COMPAT_TEXTURE(Source,pos).rgb;
	COMPAT_PRECISION vec3 sample3 = COMPAT_TEXTURE(Source,vec2(pos.x - blurx/1000.0, pos.y + blury/1000.0)).rgb;
	
	COMPAT_PRECISION vec3 colour = vec3 (sample1.r*0.5+sample2.r*0.5, sample1.g*0.25 + sample2.g*0.5 + sample3.g*0.25, sample2.b*0.5 + sample3.b*0.5);
    	COMPAT_PRECISION float lum = colour.r*0.4 + colour.g*0.4 + colour.b*0.2;
		
    	COMPAT_PRECISION vec3 lumweight=vec3(0.3,0.6,0.1);
    	COMPAT_PRECISION float gray = dot(colour,lumweight);
    	COMPAT_PRECISION vec3 graycolour = vec3(gray);

	//Gamma-like
	colour*=mix(0.2,1.0,lum);    
    
	COMPAT_PRECISION float SCANAMOUNT = mix(HIGHSCANAMOUNT1,HIGHSCANAMOUNT2,lum);
	COMPAT_PRECISION float scanLine =  SCANAMOUNT * sin(2.0*pi*pos.y*TextureSize.y);
	
	COMPAT_PRECISION float whichmask = fract((gl_FragCoord.x*1.0001)*-0.4999);
	COMPAT_PRECISION float mask = 1.0 + float(whichmask < 0.5) * -MASK_DARK;

	//Gamma-like 
	colour*=mix(2.0,1.0,lum);    
	
	colour = vec3(mix(graycolour,colour.rgb,sat));

	colour.rgb *= mix(mask*(1.0-scanLine), 1.0-scanLine, dot(colour.rgb,vec3(maskFade)));
	FragColor.rgb = colour.rgb;
} 
#endif
