/*
    zfast_crt - A very simple CRT shader.

    Copyright (C) 2017 Greg Hogan (SoltanGris42)
	edited by metallic 77.

    This program is free software; you can redistribute it and/or modify it
    under the terms of the GNU General Public License as published by the Free
    Software Foundation; either version 2 of the License, or (at your option)
    any later version.

*/



// Compatibility #ifdefs needed for parameters
#ifdef GL_ES
#define COMPAT_PRECISION mediump
#else
#define COMPAT_PRECISION
#endif

// Parameter lines go here:
#pragma parameter blurx "Convergence X-Axis" 0.45 -2.0 2.0 0.05
#pragma parameter blury "Convergence Y-Axis" -0.15 -2.0 2.0 0.05
#pragma parameter HIGHSCANAMOUNT1 "Scanline Amount (Dark)" 0.4 0.0 1.0 0.05
#pragma parameter HIGHSCANAMOUNT2 "Scanline Amount (Bright)" 0.3 0.0 1.0 0.05
#pragma parameter MASK_DARK "Mask Effect Amount" 0.3 0.0 1.0 0.05
#pragma parameter MASK_FADE "Mask/Scanline Fade" 0.7 0.0 1.0 0.05
#pragma parameter sat "Saturation" 1.0 0.0 2.0 0.05
#pragma parameter FLICK "Flicker" 10.0 0.0 50.0 1.0

#define pi 3.14159

#ifdef PARAMETER_UNIFORM
// All parameter floats need to have COMPAT_PRECISION in front of them
uniform COMPAT_PRECISION float blurx;
uniform COMPAT_PRECISION float blury;
uniform COMPAT_PRECISION float HIGHSCANAMOUNT1;
uniform COMPAT_PRECISION float HIGHSCANAMOUNT2;
uniform COMPAT_PRECISION float MASK_DARK;
uniform COMPAT_PRECISION float MASK_FADE;
uniform COMPAT_PRECISION float sat;
uniform COMPAT_PRECISION float FLICK;

#else

#define blurx 0.45
#define blury -0.15
#define HIGHSCANAMOUNT1  0.30
#define HIGHSCANAMOUNT2  0.20
#define MASK_DARK 0.3
#define MASK_FADE 0.8
#define sat 1.0
#define FLICK 0.0

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
COMPAT_VARYING float omega;

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
	omega = 2.0*pi*TextureSize.y;
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
COMPAT_VARYING float omega;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy
#define texture(c, d) COMPAT_TEXTURE(c, d)
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

#define blur_y blury/(TextureSize.y*2.0)
#define blur_x blurx/(TextureSize.x*2.0)
#define iTimer (float(FrameCount)*2.0)
#define flicker FLICK/1000.0


void main()
{
	 vec2 pos = TEX0.xy;	
	 float cent = floor(TEX0.y*TextureSize.y)+0.5;
     float ycoord = cent*SourceSize.w; 
     pos = vec2(TEX0.x,ycoord);
	 vec3 sample1 = sin(iTimer)*flicker + COMPAT_TEXTURE(Source,vec2(pos.x + blur_x, pos.y - blur_y)).rgb;
	 vec3 sample2 =                0.5*COMPAT_TEXTURE(Source,pos).rgb;
	 vec3 sample3 = sin(iTimer)*flicker + COMPAT_TEXTURE(Source,vec2(pos.x - blur_x, pos.y + blur_y)).rgb;
	
	 vec3 colour = vec3 (sample1.r*0.5  + sample2.r, 
		                 sample1.g*0.25 + sample2.g + sample3.g*0.25, 
		                                  sample2.b + sample3.b*0.5);
    
     vec3 lumweight=vec3(0.22,0.71,0.07);
     float lum = dot(colour,lumweight);
   
     vec3 graycolour = vec3(lum);
     colour = vec3(mix(graycolour,colour.rgb,sat));

	 float SCANAMOUNT = mix(HIGHSCANAMOUNT1,HIGHSCANAMOUNT2,max(max(colour.r,colour.g),colour.b));
	
	 float scanLine = SCANAMOUNT * sin(fract(TEX0.y*TextureSize.y)*3.14159)+1.0-SCANAMOUNT;
	  	
	 if (InputSize.y > 400.0) scanLine = 1.0;

	 float whichmask = fract(gl_FragCoord.x*0.4999);
	 float mask = 1.0 + float(whichmask < 0.5) * -MASK_DARK;

	 colour *= colour;
	colour.rgb *= mix(mask*scanLine, scanLine, dot(colour.rgb,vec3(maskFade)));
	colour = sqrt(colour);
	FragColor.rgb = colour.rgb;
} 
#endif
