/*
	PowerVR2 buffer shader

    Authors: leilei
 
    This program is free software; you can redistribute it and/or modify it
    under the terms of the GNU General Public License as published by the Free
    Software Foundation; either version 2 of the License, or (at your option)
    any later version.
*/

#define HW 1.00

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
uniform int FrameDirection;
uniform int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;

void main()
{
    gl_Position = MVPMatrix * VertexCoord;
    COL0 = COLOR;
    TEX0.xy = TexCoord.xy;
// Paste vertex contents here:

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

uniform int FrameDirection;
uniform int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;
uniform sampler2D Texture;
COMPAT_VARYING vec4 TEX0;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy
#define texture(c, d) COMPAT_TEXTURE(c, d)
#define FixedSize vec2(640, 480)
#define SourceSize vec4(FixedSize, 1.0 / FixedSize) //either TextureSize or InputSize
#define outsize vec4(TextureSize, 1.0 / TextureSize)


float dithertable[16] = {
	16,4,13,1,   
	8,12,5,9,
	14,2,15,3,
	6,10,7,11		
};



#pragma parameter INTERLACED "PVR - Interlace smoothing" 1.00 0.00 1.00 1.0
#pragma parameter VGASIGNAL "PVR - VGA signal loss" 0.00 0.00 1.00 1.0
#pragma parameter LUMBOOST "PVR - Luminance gain" 0.35 0.00 1.00 0.01

#ifdef PARAMETER_UNIFORM
uniform float INTERLACED;
uniform float VGASIGNAL;
uniform float LUMBOOST;
#else
#define	INTERLACED 1
#define	VGASIGNAL 0
#define LUMBOOST 0
#endif

#define LUM_R (76.0f/255.0f)
#define LUM_G (150.0f/255.0f)
#define LUM_B (28.0f/255.0f)

void main()
{
	float blue;
	
	vec2 texcoord  = vTexCoord;
	vec2 texcoord2  = vTexCoord;
	texcoord2.x *= TextureSize.x;
	texcoord2.y *= TextureSize.y;
	vec4 color = texture(Source, texcoord);
	float fc = mod(float(FrameCount), 2.0);

	// Blend vertically for composite mode
	if (bool(INTERLACED))
	{
	int taps = int(8);
	float tap = 0.62/taps;
	vec2 texcoord4  = vTexCoord;
	texcoord4.x = texcoord4.x;
	texcoord4.y = texcoord4.y + ((tap*(taps/2))/480.0f);
	vec4 blur1 = texture(Source, texcoord4);
	int bl;
	vec4 ble;

	for (bl=0;bl<taps;bl++)
		{
			texcoord4.y += (tap  / 480.0f);
			ble.rgb += texture(Source, texcoord4).rgb / taps;
		}

        	color.rgb = color.rgb * 0.25 + ( ble.rgb * 0.75);
	}

	// Some games use a luminance boost (JSR etc)
	if (bool(LUMBOOST))
	{
		color.rgb += (((color.r * LUM_R) + (color.g * LUM_G) + (color.b * LUM_B)) * LUMBOOST);
	}

	// Dither. ALWAYS do this for 16bpp
	int ditdex = 	int(mod(texcoord2.x, 4.0)) * 4 + int(mod(texcoord2.y, 4.0)); 	
	int yeh = 0;
	float ohyes;
	vec4 how;

	for (yeh=ditdex; yeh<(ditdex+16); yeh++) 	ohyes =  ((((dithertable[yeh-15]) - 1) * 0.1));
	color.rb -= (ohyes / 128);
	color.g -= (ohyes / 128);
	{
	vec4 reduct;		// 16 bits per pixel (5-6-5)
	reduct.r = 32;
	reduct.g = 64;	
	reduct.b = 32;
	how = color;
  	how = pow(how, vec4(1.0f, 1.0f, 1.0f, 1.0f));  	how *= reduct;  	how = floor(how);	how = how / reduct;  	how = pow(how, vec4(1.0f, 1.0f, 1.0f, 1.0f));
	}

	color.rb = how.rb;
	color.g = how.g;

	// There's a bit of a precision drop involved in the RGB565ening for VGA
	// I'm not sure why that is. it's exhibited on PVR1 and PVR3 hardware too
	if (INTERLACED == 0)
	{
		if (mod(color.r*32, 2.0)>0) color.r -= 0.023;
		if (mod(color.g*64, 2.0)>0) color.g -= 0.01;
		if (mod(color.b*32, 2.0)>0) color.b -= 0.023;
	}


	// RGB565 clamp

	color.rb = round(color.rb * 32)/32;
	color.g = round(color.g * 64)/64;

	// VGA Signal Loss, which probably is very wrong but i tried my best
	if (bool(VGASIGNAL))
	{

	int taps = 32;
	float tap = 12.0f/taps;
	vec2 texcoord4  = vTexCoord;
	texcoord4.x = texcoord4.x + (2.0f/640.0f);
	texcoord4.y = texcoord4.y;
	vec4 blur1 = texture(Source, texcoord4);
	int bl;
	vec4 ble;
	for (bl=0;bl<taps;bl++)
		{
			float e = 1;
			if (bl>=3)
			e=0.35f;
			texcoord4.x -= (tap  / 640);
			ble.rgb += (texture(Source, texcoord4).rgb * e) / (taps/(bl+1));
		}

        	color.rgb += ble.rgb * 0.015;

		//color.rb += (4.0f/255.0f);
		color.g += (9.0f/255.0f);
	}

   	FragColor = vec4(color);
} 
#endif
