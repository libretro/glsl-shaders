/*
    zfast_lcd_standard - A very simple LCD shader meant to be used at 1080p
		on the raspberry pi 3.
		
    Copyright (C) 2017 Greg Hogan (SoltanGris42)

    This program is free software; you can redistribute it and/or modify it
    under the terms of the GNU General Public License as published by the Free
    Software Foundation; either version 2 of the License, or (at your option)
    any later version.


Notes:  This shader just does nearest neighbor scaling of the game and then
		darkens the border pixels to imitate an LCD screen. You can change the
		amount of darkening and the thickness of the borders.  You can also 
		do basic gamma adjustment.
		
*/

//For testing compilation 
//#define FRAGMENT
//#define VERTEX
//#define GBAGAMMA 

//Some drivers don't return black with texture coordinates out of bounds
//SNES Classic is too slow to black these areas out when using fullscreen
//overlays.  But you can uncomment the below to black them out if necessary

#define BLACK_OUT_BORDER

#pragma parameter BORDERMULT "Border Multiplier" 14.0 -40.0 40.0 1.0
#pragma parameter GBAGAMMA "GBA Gamma Hack" 1.0 0.0 1.0 1.0

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

/* COMPATIBILITY
   - GLSL compilers
*/

COMPAT_ATTRIBUTE vec4 VertexCoord;
COMPAT_ATTRIBUTE vec4 COLOR;
COMPAT_ATTRIBUTE vec4 TexCoord;
COMPAT_VARYING vec4 COL0;
COMPAT_VARYING vec4 TEX0;
varying COMPAT_PRECISION vec2 invSize;

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
uniform COMPAT_PRECISION float BORDERMULT;
uniform COMPAT_PRECISION float GBAGAMMA;
#else
#define BORDERMULT 14.0
#define GBAGAMMA 1.0
#endif

void main()
{
	TEX0 = TexCoord;
	gl_Position = MVPMatrix * VertexCoord;
	invSize = 1.0/TextureSize;
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
varying COMPAT_PRECISION vec2 invSize;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float BORDERMULT;
uniform COMPAT_PRECISION float GBAGAMMA;
#else
#define BORDERMULT 14.0
#define GBAGAMMA 1.0
#endif

void main()
{
	COMPAT_PRECISION vec2 texcoordInPixels = TEX0.xy * TextureSize.xy;
	COMPAT_PRECISION vec2 centerCoord = floor(texcoordInPixels.xy)+vec2(0.5,0.5);
	COMPAT_PRECISION vec2 distFromCenter = abs(centerCoord - texcoordInPixels);

	COMPAT_PRECISION float Y = max(distFromCenter.x,(distFromCenter.y));

	Y=Y*Y;
	COMPAT_PRECISION float YY = Y*Y;
	COMPAT_PRECISION float YYY = YY*Y;

	COMPAT_PRECISION float LineWeight = YY - 2.7*YYY;
	LineWeight = 1.0 - BORDERMULT*LineWeight;

	COMPAT_PRECISION vec3 colour = COMPAT_TEXTURE(Texture, invSize*centerCoord).rgb*LineWeight;

//#if defined(GBAGAMMA)
//	//colour.rgb = pow(colour.rgb, vec3(1.35));
//	colour.rgb*=0.6+0.4*(colour.rgb); //fake gamma because the pi is too slow!
//#endif
	if (GBAGAMMA > 0.5)
		colour.rgb*=0.6+0.4*(colour.rgb); //fake gamma because the pi is too slow!
		
	FragColor = vec4(colour.rgb , 1.0);
}
#endif
